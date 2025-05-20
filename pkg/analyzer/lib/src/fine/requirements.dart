// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/requirement_failure.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:meta/meta.dart';

/// When [withFineDependencies], this variable might be set to accumulate
/// requirements for the analysis result being computed.
RequirementsManifest? globalResultRequirements;

/// Whether fine-grained dependencies feature is enabled.
///
/// This cannot be `const` because we change it in tests.
bool withFineDependencies = false;

@visibleForTesting
class ExportRequirement {
  final Uri fragmentUri;
  final Uri exportedUri;
  final List<ExportRequirementCombinator> combinators;
  final Map<LookupName, ManifestItemId> exportedIds;

  ExportRequirement({
    required this.fragmentUri,
    required this.exportedUri,
    required this.combinators,
    required this.exportedIds,
  });

  factory ExportRequirement.read(SummaryDataReader reader) {
    return ExportRequirement(
      fragmentUri: reader.readUri(),
      exportedUri: reader.readUri(),
      combinators: reader.readTypedList(
        () => ExportRequirementCombinator.read(reader),
      ),
      exportedIds: reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => ManifestItemId.read(reader),
      ),
    );
  }

  ExportFailure? isSatisfied({required LinkedElementFactory elementFactory}) {
    var libraryElement = elementFactory.libraryOfUri(exportedUri);
    var libraryManifest = libraryElement?.manifest;
    if (libraryManifest == null) {
      return ExportLibraryMissing(uri: exportedUri);
    }

    // Every now exported ID must be previously exported.
    var actualCount = 0;
    var declaredTopEntries = <MapEntry<LookupName, TopLevelItem>>[
      ...libraryManifest.declaredClasses.entries,
      ...libraryManifest.declaredEnums.entries,
      ...libraryManifest.declaredMixins.entries,
      ...libraryManifest.declaredGetters.entries,
      ...libraryManifest.declaredSetters.entries,
      ...libraryManifest.declaredFunctions.entries,
    ];
    for (var topEntry in declaredTopEntries) {
      var name = topEntry.key;
      if (name.isPrivate) {
        continue;
      }

      if (!_passCombinators(name)) {
        continue;
      }

      actualCount++;
      var actualId = topEntry.value.id;
      var expectedId = exportedIds[topEntry.key];
      if (actualId != expectedId) {
        return ExportIdMismatch(
          fragmentUri: fragmentUri,
          exportedUri: exportedUri,
          name: name,
          expectedId: expectedId,
          actualId: actualId,
        );
      }
    }

    // Every now previously ID must be now exported.
    if (exportedIds.length != actualCount) {
      return ExportCountMismatch(
        fragmentUri: fragmentUri,
        exportedUri: exportedUri,
        actualCount: actualCount,
        requiredCount: exportedIds.length,
      );
    }

    return null;
  }

  void write(BufferedSink sink) {
    sink.writeUri(fragmentUri);
    sink.writeUri(exportedUri);
    sink.writeList(combinators, (combinator) => combinator.write(sink));
    sink.writeMap(
      exportedIds,
      writeKey: (lookupName) => lookupName.write(sink),
      writeValue: (id) => id.write(sink),
    );
  }

  bool _passCombinators(LookupName lookupName) {
    var baseName = lookupName.asBaseName;
    for (var combinator in combinators) {
      switch (combinator) {
        case ExportRequirementHideCombinator():
          if (combinator.hiddenBaseNames.contains(baseName)) {
            return false;
          }
        case ExportRequirementShowCombinator():
          if (!combinator.shownBaseNames.contains(baseName)) {
            return false;
          }
      }
    }
    return true;
  }
}

@visibleForTesting
sealed class ExportRequirementCombinator {
  ExportRequirementCombinator();

  factory ExportRequirementCombinator.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ExportRequirementCombinatorKind.values);
    switch (kind) {
      case _ExportRequirementCombinatorKind.hide:
        return ExportRequirementHideCombinator.read(reader);
      case _ExportRequirementCombinatorKind.show:
        return ExportRequirementShowCombinator.read(reader);
    }
  }

  void write(BufferedSink sink);
}

@visibleForTesting
final class ExportRequirementHideCombinator
    extends ExportRequirementCombinator {
  final Set<BaseName> hiddenBaseNames;

  ExportRequirementHideCombinator({required this.hiddenBaseNames});

  factory ExportRequirementHideCombinator.read(SummaryDataReader reader) {
    return ExportRequirementHideCombinator(
      hiddenBaseNames: reader.readBaseNameSet(),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ExportRequirementCombinatorKind.hide);
    sink.writeBaseNameIterable(hiddenBaseNames);
  }
}

@visibleForTesting
final class ExportRequirementShowCombinator
    extends ExportRequirementCombinator {
  final Set<BaseName> shownBaseNames;

  ExportRequirementShowCombinator({required this.shownBaseNames});

  factory ExportRequirementShowCombinator.read(SummaryDataReader reader) {
    return ExportRequirementShowCombinator(
      shownBaseNames: reader.readBaseNameSet(),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ExportRequirementCombinatorKind.show);
    sink.writeBaseNameIterable(shownBaseNames);
  }
}

/// Requirements for [InstanceElementImpl2].
///
/// If [InterfaceElementImpl2], there are additional requirements in form
/// of [InterfaceItemRequirements].
class InstanceItemRequirements {
  final Map<LookupName, ManifestItemId?> requestedFields;
  final Map<LookupName, ManifestItemId?> requestedGetters;
  final Map<LookupName, ManifestItemId?> requestedSetters;
  final Map<LookupName, ManifestItemId?> requestedMethods;

  InstanceItemRequirements({
    required this.requestedFields,
    required this.requestedGetters,
    required this.requestedSetters,
    required this.requestedMethods,
  });

  factory InstanceItemRequirements.empty() {
    return InstanceItemRequirements(
      requestedFields: {},
      requestedGetters: {},
      requestedSetters: {},
      requestedMethods: {},
    );
  }

  factory InstanceItemRequirements.read(SummaryDataReader reader) {
    return InstanceItemRequirements(
      requestedFields: reader.readNameToIdMap(),
      requestedGetters: reader.readNameToIdMap(),
      requestedSetters: reader.readNameToIdMap(),
      requestedMethods: reader.readNameToIdMap(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeNameToIdMap(requestedFields);
    sink.writeNameToIdMap(requestedGetters);
    sink.writeNameToIdMap(requestedSetters);
    sink.writeNameToIdMap(requestedMethods);
  }
}

/// Requirements for [InterfaceElementImpl2], in addition to those that
/// we already record as [InstanceItemRequirements].
///
/// Includes all requirements from class-like items: classes, enums,
/// extension types, mixins.
class InterfaceItemRequirements {
  final Map<LookupName, ManifestItemId?> constructors;

  /// These are "methods" in wide meaning: methods, getters, setters.
  final Map<LookupName, ManifestItemId?> methods;

  InterfaceItemRequirements({
    required this.constructors,
    required this.methods,
  });

  factory InterfaceItemRequirements.empty() {
    return InterfaceItemRequirements(constructors: {}, methods: {});
  }

  factory InterfaceItemRequirements.read(SummaryDataReader reader) {
    return InterfaceItemRequirements(
      constructors: reader.readNameToIdMap(),
      methods: reader.readNameToIdMap(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeNameToIdMap(constructors);
    sink.writeNameToIdMap(methods);
  }
}

class RequirementsManifest {
  /// LibraryUri => TopName => ID
  final Map<Uri, Map<LookupName, ManifestItemId?>> topLevels = {};

  /// LibraryUri => TopName => InstanceItemRequirements
  final Map<Uri, Map<LookupName, InstanceItemRequirements>> instances = {};

  /// LibraryUri => TopName => InterfaceItemRequirements
  final Map<Uri, Map<LookupName, InterfaceItemRequirements>> interfaces = {};

  final List<ExportRequirement> exportRequirements = [];

  RequirementsManifest();

  factory RequirementsManifest.read(SummaryDataReader reader) {
    var result = RequirementsManifest();

    result.topLevels.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () => reader.readNameToIdMap(),
      ),
    );

    result.instances.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () {
          return reader.readMap(
            readKey: () => LookupName.read(reader),
            readValue: () => InstanceItemRequirements.read(reader),
          );
        },
      ),
    );

    result.interfaces.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () {
          return reader.readMap(
            readKey: () => LookupName.read(reader),
            readValue: () => InterfaceItemRequirements.read(reader),
          );
        },
      ),
    );

    result.exportRequirements.addAll(
      reader.readTypedList(() => ExportRequirement.read(reader)),
    );

    return result;
  }

  /// Adds requirements to exports from libraries.
  ///
  /// We have already computed manifests for each library.
  void addExports({
    required LinkedElementFactory elementFactory,
    required Set<Uri> libraryUriSet,
  }) {
    for (var libraryUri in libraryUriSet) {
      var libraryElement = elementFactory.libraryOfUri2(libraryUri);
      _addExports(libraryElement);
    }
  }

  /// Returns the first unsatisfied requirement, or `null` if all requirements
  /// are satisfied.
  RequirementFailure? isSatisfied({
    required LinkedElementFactory elementFactory,
    required Map<Uri, LibraryManifest> libraryManifests,
  }) {
    for (var libraryEntry in topLevels.entries) {
      var libraryUri = libraryEntry.key;

      var libraryElement = elementFactory.libraryOfUri(libraryUri);
      var libraryManifest = libraryElement?.manifest;
      if (libraryManifest == null) {
        return LibraryMissing(uri: libraryUri);
      }

      for (var topLevelEntry in libraryEntry.value.entries) {
        var name = topLevelEntry.key;
        var actualId = libraryManifest.getExportedId(name);
        if (topLevelEntry.value != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: topLevelEntry.value,
            actualId: actualId,
          );
        }
      }
    }

    for (var libraryEntry in instances.entries) {
      var libraryUri = libraryEntry.key;

      var libraryElement = elementFactory.libraryOfUri(libraryUri);
      var libraryManifest = libraryElement?.manifest;
      if (libraryManifest == null) {
        return LibraryMissing(uri: libraryUri);
      }

      for (var instanceEntry in libraryEntry.value.entries) {
        var instanceName = instanceEntry.key;
        var requirements = instanceEntry.value;

        var instanceItem =
            libraryManifest.declaredClasses[instanceName] ??
            libraryManifest.declaredEnums[instanceName] ??
            libraryManifest.declaredMixins[instanceName];
        if (instanceItem is! InstanceItem) {
          return TopLevelNotInterface(
            libraryUri: libraryUri,
            name: instanceName,
          );
        }

        for (var fieldEntry in requirements.requestedFields.entries) {
          var name = fieldEntry.key;
          var expectedId = fieldEntry.value;
          var currentId = instanceItem.getDeclaredFieldId(name);
          if (expectedId != currentId) {
            return InstanceFieldIdMismatch(
              libraryUri: libraryUri,
              interfaceName: instanceName,
              fieldName: name,
              expectedId: expectedId,
              actualId: currentId,
            );
          }
        }

        for (var getterEntry in requirements.requestedGetters.entries) {
          var name = getterEntry.key;
          var expectedId = getterEntry.value;
          var currentId = instanceItem.getDeclaredGetterId(name);
          if (expectedId != currentId) {
            return InstanceMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: instanceName,
              methodName: name,
              expectedId: expectedId,
              actualId: currentId,
            );
          }
        }

        for (var setterEntry in requirements.requestedSetters.entries) {
          var name = setterEntry.key;
          var expectedId = setterEntry.value;
          var currentId = instanceItem.getDeclaredSetterId(name);
          if (expectedId != currentId) {
            return InstanceMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: instanceName,
              methodName: name,
              expectedId: expectedId,
              actualId: currentId,
            );
          }
        }

        for (var methodEntry in requirements.requestedMethods.entries) {
          var name = methodEntry.key;
          var expectedId = methodEntry.value;
          var currentId = instanceItem.getDeclaredMethodId(name);
          if (expectedId != currentId) {
            return InstanceMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: instanceName,
              methodName: name,
              expectedId: expectedId,
              actualId: currentId,
            );
          }
        }
      }
    }

    for (var libraryEntry in interfaces.entries) {
      var libraryUri = libraryEntry.key;

      var libraryElement = elementFactory.libraryOfUri(libraryUri);
      var libraryManifest = libraryElement?.manifest;
      if (libraryManifest == null) {
        return LibraryMissing(uri: libraryUri);
      }

      for (var interfaceEntry in libraryEntry.value.entries) {
        var interfaceName = interfaceEntry.key;
        var interfaceItem =
            libraryManifest.declaredClasses[interfaceName] ??
            libraryManifest.declaredEnums[interfaceName] ??
            libraryManifest.declaredMixins[interfaceName];
        if (interfaceItem is! InterfaceItem) {
          return TopLevelNotInterface(
            libraryUri: libraryUri,
            name: interfaceName,
          );
        }

        var constructors = interfaceEntry.value.constructors;
        for (var constructorEntry in constructors.entries) {
          var constructorName = constructorEntry.key;
          var constructorId = interfaceItem.getConstructorId(constructorName);
          var expectedId = constructorEntry.value;
          if (expectedId != constructorId) {
            return InterfaceConstructorIdMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              constructorName: constructorName,
              expectedId: expectedId,
              actualId: constructorId,
            );
          }
        }

        var methods = interfaceEntry.value.methods;
        for (var methodEntry in methods.entries) {
          var methodName = methodEntry.key;
          var methodId = interfaceItem.getInterfaceMethodId(methodName);
          var expectedId = methodEntry.value;
          if (expectedId != methodId) {
            return InstanceMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              methodName: methodName,
              expectedId: expectedId,
              actualId: methodId,
            );
          }
        }
      }
    }

    for (var exportRequirement in exportRequirements) {
      var failure = exportRequirement.isSatisfied(
        elementFactory: elementFactory,
      );
      if (failure != null) {
        return failure;
      }
    }

    return null;
  }

  void notify_interfaceElement_getNamedConstructor({
    required InterfaceElementImpl2 element,
    required String name,
  }) {
    var itemRequirements = _getInterfaceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var constructorName = name.asLookupName;
    var constructorId = item.getConstructorId(constructorName);
    requirements.constructors[constructorName] = constructorId;
  }

  /// This method is invoked by [InheritanceManager3] to notify the collector
  /// that a member with [nameObj] was requested from the [element].
  void notifyInterfaceRequest({
    required InterfaceElementImpl2 element,
    required Name nameObj,
    required ExecutableElement? methodElement,
  }) {
    // Skip private names, cannot be used outside this library.
    if (!nameObj.isPublic) {
      return;
    }

    var itemRequirements = _getInterfaceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var methodName = nameObj.name.asLookupName;
    var methodId = item.getInterfaceMethodId(methodName);
    requirements.methods[methodName] = methodId;

    // Check for consistency between the actual interface and manifest.
    if (methodElement != null) {
      if (methodId == null) {
        var qName = _qualifiedMethodName(element, methodName);
        throw StateError('Expected ID for $qName');
      }
    } else {
      if (methodId != null) {
        var qName = _qualifiedMethodName(element, methodName);
        throw StateError('Expected no ID for $qName');
      }
    }

    requirements.methods[methodName] = methodId;
  }

  /// This method is invoked by an import scope to notify the collector that
  /// the name [nameStr] was requested from [importedLibrary].
  void notifyRequest({
    required LibraryElementImpl importedLibrary,
    required String nameStr,
  }) {
    if (importedLibrary.manifest case var manifest?) {
      var uri = importedLibrary.uri;
      var nameToId = topLevels[uri] ??= {};
      var name = nameStr.asLookupName;
      nameToId[name] = manifest.getExportedId(name);
    }
  }

  void record_classElement_allSubtypes({required ClassElementImpl2 element}) {
    // TODO(scheglov): implement.
  }

  void record_classElement_hasNonFinalField({
    required ClassElementImpl2 element,
  }) {
    // TODO(scheglov): implement.
  }

  void record_classElement_isEnumLike({required ClassElementImpl2 element}) {
    // TODO(scheglov): implement.
  }

  void record_disable(Object target, String method) {
    // TODO(scheglov): implement.
  }

  void record_instanceElement_getField({
    required InstanceElementImpl2 element,
    required String name,
  }) {
    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var fieldName = name.asLookupName;
    var fieldId = item.getDeclaredFieldId(fieldName);
    requirements.requestedFields[fieldName] = fieldId;
  }

  void record_instanceElement_getGetter({
    required InstanceElementImpl2 element,
    required String name,
  }) {
    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var methodName = name.asLookupName;
    var methodId = item.getDeclaredGetterId(methodName);
    requirements.requestedGetters[methodName] = methodId;
  }

  void record_instanceElement_getMethod({
    required InstanceElementImpl2 element,
    required String name,
  }) {
    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var methodName = name.asLookupName;
    var methodId = item.getDeclaredMethodId(methodName);
    requirements.requestedMethods[methodName] = methodId;
  }

  void record_instanceElement_getSetter({
    required InstanceElementImpl2 element,
    required String name,
  }) {
    assert(!name.endsWith('='));
    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var methodName = '$name='.asLookupName;
    var methodId = item.getDeclaredSetterId(methodName);
    requirements.requestedSetters[methodName] = methodId;
  }

  void record_propertyAccessorElement_variable({
    required PropertyAccessorElementImpl2 element,
    required String? name,
  }) {
    if (name == null) {
      return;
    }

    switch (element.enclosingElement) {
      case InstanceElementImpl2 instanceElement:
        record_instanceElement_getField(element: instanceElement, name: name);
      default:
      // TODO(scheglov): support for top-level variables
    }
  }

  /// This method is invoked after linking of a library cycle, to exclude
  /// requirements to the libraries of this same library cycle. We already
  /// link these libraries together, so only requirements to the previous
  /// libraries are interesting.
  void removeReqForLibs(Set<Uri> bundleLibraryUriList) {
    var uriSet = bundleLibraryUriList.toSet();
    exportRequirements.removeWhere((export) {
      return uriSet.contains(export.exportedUri);
    });

    for (var libUri in bundleLibraryUriList) {
      topLevels.remove(libUri);
    }

    for (var libUri in bundleLibraryUriList) {
      interfaces.remove(libUri);
    }
  }

  void write(BufferedSink sink) {
    sink.writeMap(
      topLevels,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (map) => sink.writeNameToIdMap(map),
    );

    sink.writeMap(
      instances,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (nameToInstanceMap) {
        sink.writeMap(
          nameToInstanceMap,
          writeKey: (name) => name.write(sink),
          writeValue: (instance) => instance.write(sink),
        );
      },
    );

    sink.writeMap(
      interfaces,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (nameToInterfaceMap) {
        sink.writeMap(
          nameToInterfaceMap,
          writeKey: (name) => name.write(sink),
          writeValue: (interface) => interface.write(sink),
        );
      },
    );

    sink.writeList(
      exportRequirements,
      (requirement) => requirement.write(sink),
    );
  }

  void _addExports(LibraryElementImpl libraryElement) {
    for (var fragment in libraryElement.fragments) {
      for (var export in fragment.libraryExports) {
        var exportedLibrary = export.exportedLibrary2;

        // If no library, then there is nothing to re-export.
        if (exportedLibrary == null) {
          continue;
        }

        var combinators =
            export.combinators.map((combinator) {
              switch (combinator) {
                case HideElementCombinator():
                  return ExportRequirementHideCombinator(
                    hiddenBaseNames: combinator.hiddenNames.toBaseNameSet(),
                  );
                case ShowElementCombinator():
                  return ExportRequirementShowCombinator(
                    shownBaseNames: combinator.shownNames.toBaseNameSet(),
                  );
              }
            }).toList();

        // SAFETY: every library has the manifest.
        var manifest = exportedLibrary.manifest!;

        var exportedIds = <LookupName, ManifestItemId>{};
        var exportMap = NamespaceBuilder().createExportNamespaceForDirective2(
          export,
        );
        for (var entry in exportMap.definedNames2.entries) {
          var lookupName = entry.key.asLookupName;
          // TODO(scheglov): must always be not null.
          var id = manifest.getExportedId(lookupName);
          if (id != null) {
            exportedIds[lookupName] = id;
          }
        }

        exportRequirements.add(
          ExportRequirement(
            fragmentUri: fragment.source.uri,
            exportedUri: exportedLibrary.uri,
            combinators: combinators,
            exportedIds: exportedIds,
          ),
        );
      }
    }
  }

  _InstanceItemWithRequirements? _getInstanceItem(
    InstanceElementImpl2 element,
  ) {
    var libraryElement = element.library2;
    var manifest = libraryElement.manifest;

    // If we are linking the library, its manifest is not set yet.
    // But then we also don't care about this dependency.
    if (manifest == null) {
      return null;
    }

    // SAFETY: we don't export elements without name.
    var instanceName = element.lookupName!.asLookupName;

    var instancesMap = instances[libraryElement.uri] ??= {};
    var instanceItem =
        manifest.declaredClasses[instanceName] ??
        manifest.declaredEnums[instanceName] ??
        manifest.declaredMixins[instanceName];

    // SAFETY: every instance element must be in the manifest.
    instanceItem as InstanceItem;

    var requirements =
        instancesMap[instanceName] ??= InstanceItemRequirements.empty();
    return _InstanceItemWithRequirements(
      item: instanceItem,
      requirements: requirements,
    );
  }

  _InterfaceItemWithRequirements? _getInterfaceItem(
    InterfaceElementImpl2 element,
  ) {
    var libraryElement = element.library2;
    var manifest = libraryElement.manifest;

    // If we are linking the library, its manifest is not set yet.
    // But then we also don't care about this dependency.
    if (manifest == null) {
      return null;
    }

    // SAFETY: we don't export elements without name.
    var interfaceName = element.lookupName!.asLookupName;

    var interfacesMap = interfaces[libraryElement.uri] ??= {};
    var interfaceItem =
        manifest.declaredClasses[interfaceName] ??
        manifest.declaredEnums[interfaceName] ??
        manifest.declaredMixins[interfaceName];

    // SAFETY: every interface element must be in the manifest.
    interfaceItem as InterfaceItem;

    var requirements =
        interfacesMap[interfaceName] ??= InterfaceItemRequirements.empty();
    return _InterfaceItemWithRequirements(
      item: interfaceItem,
      requirements: requirements,
    );
  }

  String _qualifiedMethodName(
    InterfaceElementImpl2 element,
    LookupName methodName,
  ) {
    return '${element.library2.uri} '
        '${element.displayName}.'
        '${methodName.asString}';
  }
}

enum _ExportRequirementCombinatorKind { hide, show }

class _InstanceItemWithRequirements {
  final InstanceItem item;
  final InstanceItemRequirements requirements;

  _InstanceItemWithRequirements({
    required this.item,
    required this.requirements,
  });
}

class _InterfaceItemWithRequirements {
  final InterfaceItem item;
  final InterfaceItemRequirements requirements;

  _InterfaceItemWithRequirements({
    required this.item,
    required this.requirements,
  });
}

extension _BufferedSinkExtension on BufferedSink {
  void writeNameToIdMap(Map<LookupName, ManifestItemId?> map) {
    writeMap(
      map,
      writeKey: (name) => name.write(this),
      writeValue: (id) => id.writeOptional(this),
    );
  }
}

extension _SummaryDataReaderExtension on SummaryDataReader {
  Map<LookupName, ManifestItemId?> readNameToIdMap() {
    return readMap(
      readKey: () => LookupName.read(this),
      readValue: () => ManifestItemId.readOptional(this),
    );
  }
}
