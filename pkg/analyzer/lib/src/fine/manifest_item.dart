// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:meta/meta.dart';

class ClassItem extends InterfaceItem<ClassElementImpl2> {
  ClassItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.supertype,
    required super.mixins,
    required super.interfaces,
    required super.interface,
  });

  factory ClassItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ClassElementImpl2 element,
  }) {
    return context.withTypeParameters(element.typeParameters2, (
      typeParameters,
    ) {
      return ClassItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
        interface: ManifestInterface.empty(),
      );
    });
  }

  factory ClassItem.read(SummaryDataReader reader) {
    return ClassItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: InstanceItemFieldItem.readMap(reader),
      declaredGetters: InstanceItemGetterItem.readMap(reader),
      declaredSetters: InstanceItemSetterItem.readMap(reader),
      declaredMethods: InstanceItemMethodItem.readMap(reader),
      declaredConstructors: InterfaceItemConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      interface: ManifestInterface.read(reader),
    );
  }
}

class EnumItem extends InterfaceItem<EnumElementImpl2> {
  EnumItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.interface,
    required super.supertype,
    required super.mixins,
    required super.interfaces,
  });

  factory EnumItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required EnumElementImpl2 element,
  }) {
    return context.withTypeParameters(element.typeParameters2, (
      typeParameters,
    ) {
      return EnumItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        interface: ManifestInterface.empty(),
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
      );
    });
  }

  factory EnumItem.read(SummaryDataReader reader) {
    return EnumItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: InstanceItemFieldItem.readMap(reader),
      declaredGetters: InstanceItemGetterItem.readMap(reader),
      declaredSetters: InstanceItemSetterItem.readMap(reader),
      declaredMethods: InstanceItemMethodItem.readMap(reader),
      declaredConstructors: InterfaceItemConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      interface: ManifestInterface.read(reader),
    );
  }
}

/// The item for [ExtensionElementImpl2].
class ExtensionItem<E extends ExtensionElementImpl2> extends InstanceItem<E> {
  final ManifestType extendedType;

  ExtensionItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required this.extendedType,
  });

  factory ExtensionItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ExtensionElementImpl2 element,
  }) {
    return context.withTypeParameters(element.typeParameters2, (
      typeParameters,
    ) {
      return ExtensionItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        extendedType: element.extendedType.encode(context),
      );
    });
  }

  factory ExtensionItem.read(SummaryDataReader reader) {
    return ExtensionItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: InstanceItemFieldItem.readMap(reader),
      declaredGetters: InstanceItemGetterItem.readMap(reader),
      declaredSetters: InstanceItemSetterItem.readMap(reader),
      declaredMethods: InstanceItemMethodItem.readMap(reader),
      declaredConstructors: InterfaceItemConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      extendedType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, E element) {
    context.addTypeParameters(element.typeParameters2);
    return super.match(context, element) &&
        extendedType.match(context, element.extendedType);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    extendedType.write(sink);
  }
}

class ExtensionTypeItem extends InterfaceItem<ExtensionTypeElementImpl2> {
  ExtensionTypeItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.interface,
    required super.supertype,
    required super.mixins,
    required super.interfaces,
  });

  factory ExtensionTypeItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ExtensionTypeElementImpl2 element,
  }) {
    return context.withTypeParameters(element.typeParameters2, (
      typeParameters,
    ) {
      return ExtensionTypeItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        interface: ManifestInterface.empty(),
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
      );
    });
  }

  factory ExtensionTypeItem.read(SummaryDataReader reader) {
    return ExtensionTypeItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: InstanceItemFieldItem.readMap(reader),
      declaredGetters: InstanceItemGetterItem.readMap(reader),
      declaredSetters: InstanceItemSetterItem.readMap(reader),
      declaredMethods: InstanceItemMethodItem.readMap(reader),
      declaredConstructors: InterfaceItemConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      interface: ManifestInterface.read(reader),
    );
  }
}

/// The item for [InstanceElementImpl2].
sealed class InstanceItem<E extends InstanceElementImpl2>
    extends TopLevelItem<E> {
  final List<ManifestTypeParameter> typeParameters;

  /// The names of duplicate or otherwise conflicting members.
  /// Such names will not be added to `declaredXyz` maps.
  final Map<LookupName, ManifestItemId> declaredConflicts;

  final Map<LookupName, InstanceItemFieldItem> declaredFields;
  final Map<LookupName, InstanceItemGetterItem> declaredGetters;
  final Map<LookupName, InstanceItemSetterItem> declaredSetters;
  final Map<LookupName, InstanceItemMethodItem> declaredMethods;
  final Map<LookupName, InterfaceItemConstructorItem> declaredConstructors;
  final Map<LookupName, ManifestItemId> inheritedConstructors;

  InstanceItem({
    required super.id,
    required super.metadata,
    required this.typeParameters,
    required this.declaredConflicts,
    required this.declaredFields,
    required this.declaredGetters,
    required this.declaredSetters,
    required this.declaredMethods,
    required this.declaredConstructors,
    required this.inheritedConstructors,
  });

  void addDeclaredConstructor(
    LookupName lookupName,
    InterfaceItemConstructorItem item,
  ) {
    var baseName = lookupName.asBaseName;
    if (declaredConflicts.containsKey(baseName)) {
      return;
    }

    var hasConflict = () {
      // Constructors conflict with constructors.
      if (declaredConstructors.containsKey(lookupName)) {
        return true;
      }
      // Constructors conflict with static properties and methods.
      return declaredGetters[lookupName]?.isStatic ??
          declaredSetters[lookupName]?.isStatic ??
          declaredMethods[lookupName]?.isStatic ??
          false;
    }();
    if (hasConflict) {
      _makeNameConflict(lookupName);
      return;
    }

    declaredConstructors[lookupName] = item;
  }

  void addDeclaredGetter(LookupName lookupName, InstanceItemGetterItem item) {
    var baseName = lookupName.asBaseName;
    if (declaredConflicts.containsKey(baseName)) {
      return;
    }

    var hasConflict = () {
      // Getters conflict with methods and getters.
      if (declaredGetters.containsKey(lookupName) ||
          declaredMethods.containsKey(lookupName)) {
        return true;
      }
      // Static getters conflict with constructors.
      if (item.isStatic && declaredConstructors.containsKey(lookupName)) {
        return true;
      }
      // Instance / static getters conflict with static / instance setter.
      var lookupNameSetter = '${lookupName.asString}='.asLookupName;
      if (declaredSetters[lookupNameSetter] case var setter?) {
        if (setter.isStatic != item.isStatic) {
          return true;
        }
      }
      return false;
    }();
    if (hasConflict) {
      _makeNameConflict(lookupName);
      return;
    }

    declaredGetters[lookupName] = item;
  }

  void addDeclaredMethod(LookupName lookupName, InstanceItemMethodItem item) {
    var baseName = lookupName.asBaseName;
    if (declaredConflicts.containsKey(baseName)) {
      return;
    }

    var hasConflict = () {
      // Methods conflict with methods and properties.
      if (declaredGetters.containsKey(lookupName) ||
          declaredSetters.containsKey(lookupName.methodToSetter) ||
          declaredMethods.containsKey(lookupName)) {
        return true;
      }
      // Static methods conflict with constructors.
      if (item.isStatic && declaredConstructors.containsKey(lookupName)) {
        return true;
      }
      return false;
    }();
    if (hasConflict) {
      _makeNameConflict(lookupName);
      return;
    }

    declaredMethods[lookupName] = item;
  }

  void addDeclaredSetter(LookupName lookupName, InstanceItemSetterItem item) {
    var baseName = lookupName.asBaseName;
    if (declaredConflicts.containsKey(baseName)) {
      return;
    }

    var hasConflict = () {
      var lookupNameGetter = lookupName.setterToGetter;
      // Setters conflict with setters and methods.
      if (declaredSetters.containsKey(lookupName) ||
          declaredMethods.containsKey(lookupNameGetter)) {
        return true;
      }
      // Static setters conflict with constructors.
      if (item.isStatic && declaredConstructors.containsKey(lookupNameGetter)) {
        return true;
      }
      // Instance / static setters conflict with static / instance getter.
      if (declaredGetters[lookupNameGetter] case var getter?) {
        if (getter.isStatic != item.isStatic) {
          return true;
        }
      }
      return false;
    }();
    if (hasConflict) {
      _makeNameConflict(lookupName);
      return;
    }

    declaredSetters[lookupName] = item;
  }

  void addInheritedConstructor(LookupName lookupName, ManifestItemId id) {
    // Inherited constructors exist only for class type aliases.
    // So, not conflicts checking it required.
    inheritedConstructors[lookupName] = id;
  }

  void beforeUpdatingMembers() {
    declaredConflicts.clear();
    declaredFields.clear();
    declaredGetters.clear();
    declaredSetters.clear();
    declaredMethods.clear();
    declaredConstructors.clear();
    inheritedConstructors.clear();
  }

  ManifestItemId? getConstructorId(LookupName name) {
    return declaredConstructors[name]?.id ??
        inheritedConstructors[name] ??
        declaredConflicts[name];
  }

  ManifestItemId? getDeclaredFieldId(LookupName name) {
    return declaredFields[name]?.id ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredGetterId(LookupName name) {
    return declaredGetters[name]?.id ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredMethodId(LookupName name) {
    return declaredMethods[name]?.id ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredSetterId(LookupName name) {
    return declaredSetters[name]?.id ?? declaredConflicts[name];
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    typeParameters.writeList(sink);
    declaredConflicts.write(sink);
    declaredFields.write(sink);
    declaredGetters.write(sink);
    declaredSetters.write(sink);
    declaredMethods.write(sink);
    declaredConstructors.write(sink);
    inheritedConstructors.write(sink);
  }

  void _makeNameConflict(LookupName lookupName2) {
    var id = ManifestItemId.generate();
    for (var lookupName in lookupName2.relatedNames) {
      declaredConflicts[lookupName] = id;
      declaredFields.remove(lookupName);
      declaredGetters.remove(lookupName);
      declaredSetters.remove(lookupName);
      declaredMethods.remove(lookupName);
      declaredConstructors.remove(lookupName);
      inheritedConstructors.remove(lookupName);
    }
  }
}

class InstanceItemFieldItem extends InstanceItemMemberItem<FieldElementImpl2> {
  final ManifestType type;
  final ManifestNode? constInitializer;

  InstanceItemFieldItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.type,
    required this.constInitializer,
  });

  factory InstanceItemFieldItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required FieldElementImpl2 element,
  }) {
    return InstanceItemFieldItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      isStatic: element.isStatic,
      type: element.type.encode(context),
      constInitializer: element.constantInitializer2?.expression.encode(
        context,
      ),
    );
  }

  factory InstanceItemFieldItem.read(SummaryDataReader reader) {
    return InstanceItemFieldItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      type: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }

  @override
  bool match(MatchContext context, FieldElementImpl2 element) {
    return super.match(context, element) &&
        type.match(context, element.type) &&
        constInitializer.match(
          context,
          element.constantInitializer2?.expression,
        );
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    type.write(sink);
    constInitializer.writeOptional(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.getter);
  }

  static Map<LookupName, InstanceItemFieldItem> readMap(
    SummaryDataReader reader,
  ) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => InstanceItemFieldItem.read(reader),
    );
  }
}

class InstanceItemGetterItem extends InstanceItemMemberItem<GetterElementImpl> {
  final ManifestType returnType;

  InstanceItemGetterItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.returnType,
  });

  factory InstanceItemGetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElementImpl element,
  }) {
    return InstanceItemGetterItem(
      id: id,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      isStatic: element.isStatic,
      returnType: element.returnType.encode(context),
    );
  }

  factory InstanceItemGetterItem.read(SummaryDataReader reader) {
    return InstanceItemGetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      returnType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, GetterElementImpl element) {
    return super.match(context, element) &&
        returnType.match(context, element.returnType);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    returnType.write(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.getter);
  }

  static Map<LookupName, InstanceItemGetterItem> readMap(
    SummaryDataReader reader,
  ) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => InstanceItemGetterItem.read(reader),
    );
  }
}

sealed class InstanceItemMemberItem<E extends AnnotatableElementImpl>
    extends ManifestItem<E> {
  final bool isStatic;

  InstanceItemMemberItem({
    required super.id,
    required super.metadata,
    required this.isStatic,
  });

  @override
  bool match(MatchContext context, E element) {
    if (!super.match(context, element)) {
      return false;
    }

    switch (element) {
      case FieldElementImpl2 element:
        if (element.isStatic != isStatic) {
          return false;
        }
      case ExecutableElementImpl2 element:
        if (element.isStatic != isStatic) {
          return false;
        }
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isStatic);
  }

  void writeKind(BufferedSink sink);

  void writeWithKind(BufferedSink sink) {
    writeKind(sink);
    write(sink);
  }

  static InstanceItemMemberItem<AnnotatableElementImpl> read(
    SummaryDataReader reader,
  ) {
    var kind = reader.readEnum(_InstanceItemMemberItemKind.values);
    switch (kind) {
      case _InstanceItemMemberItemKind.field:
        return InstanceItemFieldItem.read(reader);
      case _InstanceItemMemberItemKind.getter:
        return InstanceItemGetterItem.read(reader);
      case _InstanceItemMemberItemKind.method:
        return InstanceItemMethodItem.read(reader);
      case _InstanceItemMemberItemKind.setter:
        return InstanceItemSetterItem.read(reader);
      case _InstanceItemMemberItemKind.constructor:
        return InterfaceItemConstructorItem.read(reader);
    }
  }
}

class InstanceItemMethodItem
    extends InstanceItemMemberItem<MethodElementImpl2> {
  final ManifestFunctionType functionType;

  InstanceItemMethodItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.functionType,
  });

  factory InstanceItemMethodItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required MethodElementImpl2 element,
  }) {
    return InstanceItemMethodItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      isStatic: element.isStatic,
      functionType: element.type.encode(context),
    );
  }

  factory InstanceItemMethodItem.read(SummaryDataReader reader) {
    return InstanceItemMethodItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, MethodElementImpl2 element) {
    return super.match(context, element) &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    functionType.writeNoTag(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.method);
  }

  static Map<LookupName, InstanceItemMethodItem> readMap(
    SummaryDataReader reader,
  ) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => InstanceItemMethodItem.read(reader),
    );
  }
}

class InstanceItemSetterItem extends InstanceItemMemberItem<SetterElementImpl> {
  final ManifestType valueType;

  InstanceItemSetterItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.valueType,
  });

  factory InstanceItemSetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required SetterElementImpl element,
  }) {
    return InstanceItemSetterItem(
      id: id,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      isStatic: element.isStatic,
      valueType: element.formalParameters[0].type.encode(context),
    );
  }

  factory InstanceItemSetterItem.read(SummaryDataReader reader) {
    return InstanceItemSetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      valueType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, SetterElementImpl element) {
    return super.match(context, element) &&
        valueType.match(context, element.formalParameters[0].type);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    valueType.write(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.setter);
  }

  static Map<LookupName, InstanceItemSetterItem> readMap(
    SummaryDataReader reader,
  ) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => InstanceItemSetterItem.read(reader),
    );
  }
}

/// The item for [InterfaceElementImpl2].
sealed class InterfaceItem<E extends InterfaceElementImpl2>
    extends InstanceItem<E> {
  final ManifestType? supertype;
  final List<ManifestType> interfaces;
  final List<ManifestType> mixins;
  final ManifestInterface interface;

  InterfaceItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required this.supertype,
    required this.mixins,
    required this.interfaces,
    required this.interface,
  });

  ManifestItemId? getInterfaceMethodId(LookupName name) {
    return interface.map[name];
  }

  @override
  bool match(MatchContext context, E element) {
    context.addTypeParameters(element.typeParameters2);
    return super.match(context, element) &&
        supertype.match(context, element.supertype) &&
        interfaces.match(context, element.interfaces) &&
        mixins.match(context, element.mixins);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    supertype.writeOptional(sink);
    mixins.writeList(sink);
    interfaces.writeList(sink);
    interface.write(sink);
  }
}

class InterfaceItemConstructorItem
    extends InstanceItemMemberItem<ConstructorElementImpl2> {
  final bool isConst;
  final bool isFactory;
  final ManifestFunctionType functionType;
  final List<ManifestNode> constantInitializers;

  InterfaceItemConstructorItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.isConst,
    required this.isFactory,
    required this.functionType,
    required this.constantInitializers,
  });

  factory InterfaceItemConstructorItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ConstructorElementImpl2 element,
  }) {
    return context.withFormalParameters(element.formalParameters, () {
      return InterfaceItemConstructorItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        isStatic: false,
        isConst: element.isConst,
        isFactory: element.isFactory,
        functionType: element.type.encode(context),
        constantInitializers:
            element.constantInitializers
                .map((initializer) => ManifestNode.encode(context, initializer))
                .toFixedList(),
      );
    });
  }

  factory InterfaceItemConstructorItem.read(SummaryDataReader reader) {
    return InterfaceItemConstructorItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      isConst: reader.readBool(),
      isFactory: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
      constantInitializers: ManifestNode.readList(reader),
    );
  }

  @override
  bool match(MatchContext context, ConstructorElementImpl2 element) {
    return context.withFormalParameters(element.formalParameters, () {
      return super.match(context, element) &&
          isConst == element.isConst &&
          isFactory == element.isFactory &&
          functionType.match(context, element.type) &&
          constantInitializers.match(context, element.constantInitializers);
    });
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isConst);
    sink.writeBool(isFactory);
    functionType.writeNoTag(sink);
    constantInitializers.writeList(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.constructor);
  }

  static Map<LookupName, InterfaceItemConstructorItem> readMap(
    SummaryDataReader reader,
  ) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => InterfaceItemConstructorItem.read(reader),
    );
  }
}

class ManifestAnnotation {
  final ManifestNode ast;

  ManifestAnnotation({required this.ast});

  factory ManifestAnnotation.read(SummaryDataReader reader) {
    return ManifestAnnotation(ast: ManifestNode.read(reader));
  }

  bool match(MatchContext context, ElementAnnotationImpl annotation) {
    return ast.match(context, annotation.annotationAst);
  }

  void write(BufferedSink sink) {
    ast.write(sink);
  }

  static ManifestAnnotation encode(
    EncodeContext context,
    ElementAnnotationImpl annotation,
  ) {
    return ManifestAnnotation(
      ast: ManifestNode.encode(context, annotation.annotationAst),
    );
  }
}

/// Manifest version of `Interface` computed by `InheritanceManager`.
///
/// We store only IDs of the interface members, but not type substitutions,
/// because in order to invoke any of these members, you need an instance
/// of the class for this [InterfaceItem]. And any code that can give such
/// instance will reference the class name, directly as a type annotation, or
/// indirectly by invoking a function that references the class as a return
/// type. So, any such code depends on the header of the class, so includes
/// the type arguments for the class that declares the inherited member.
class ManifestInterface {
  /// The map of names to their IDs in the interface.
  final Map<LookupName, ManifestItemId> map;

  /// Key: IDs of method declarations.
  /// Value: ID assigned last time.
  /// When the same signatures merge, the result is the same.
  Map<ManifestItemIdList, ManifestItemId> combinedIds = {};

  /// We move [combinedIds] into here during building the manifest, so that
  /// we can fill [combinedIds] with new entries.
  Map<ManifestItemIdList, ManifestItemId> combinedIdsTemp = {};

  ManifestInterface({required this.map, required this.combinedIds});

  factory ManifestInterface.empty() {
    return ManifestInterface(map: {}, combinedIds: {});
  }

  factory ManifestInterface.read(SummaryDataReader reader) {
    return ManifestInterface(
      map: reader.readLookupNameToIdMap(),
      combinedIds: reader.readMap(
        readKey: () => ManifestItemIdList.read(reader),
        readValue: () => ManifestItemId.read(reader),
      ),
    );
  }

  void afterUpdate() {
    combinedIdsTemp = {};
  }

  void beforeUpdating() {
    map.clear();
    combinedIdsTemp = combinedIds;
    combinedIds = {};
  }

  void write(BufferedSink sink) {
    map.write(sink);
    sink.writeMap(
      combinedIds,
      writeKey: (key) => key.write(sink),
      writeValue: (id) => id.write(sink),
    );
  }
}

sealed class ManifestItem<E extends AnnotatableElementImpl> {
  /// The unique identifier of this item.
  final ManifestItemId id;
  final ManifestMetadata metadata;

  ManifestItem({required this.id, required this.metadata});

  @mustCallSuper
  bool match(MatchContext context, E element) {
    return metadata.match(context, element.effectiveMetadata);
  }

  @mustCallSuper
  void write(BufferedSink sink) {
    id.write(sink);
    metadata.write(sink);
  }
}

class ManifestMetadata {
  final List<ManifestAnnotation> annotations;

  ManifestMetadata({required this.annotations});

  factory ManifestMetadata.encode(
    EncodeContext context,
    MetadataImpl metadata,
  ) {
    return ManifestMetadata(
      annotations:
          metadata.annotations.map((annotation) {
            return ManifestAnnotation.encode(context, annotation);
          }).toFixedList(),
    );
  }

  factory ManifestMetadata.read(SummaryDataReader reader) {
    return ManifestMetadata(
      annotations: reader.readTypedList(() {
        return ManifestAnnotation.read(reader);
      }),
    );
  }

  bool match(MatchContext context, MetadataImpl metadata) {
    var metadataAnnotations = metadata.annotations;
    if (annotations.length != metadataAnnotations.length) {
      return false;
    }

    for (var i = 0; i < metadataAnnotations.length; i++) {
      if (!annotations[i].match(context, metadataAnnotations[i])) {
        return false;
      }
    }

    return true;
  }

  void write(BufferedSink sink) {
    sink.writeList(annotations, (x) => x.write(sink));
  }
}

class MixinItem extends InterfaceItem<MixinElementImpl2> {
  final List<ManifestType> superclassConstraints;

  MixinItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.supertype,
    required super.interfaces,
    required super.mixins,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredMethods,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.interface,
    required this.superclassConstraints,
  }) : assert(supertype == null),
       assert(mixins.isEmpty),
       assert(superclassConstraints.isNotEmpty);

  factory MixinItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required MixinElementImpl2 element,
  }) {
    return context.withTypeParameters(element.typeParameters2, (
      typeParameters,
    ) {
      return MixinItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        interface: ManifestInterface.empty(),
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
        superclassConstraints: element.superclassConstraints.encode(context),
      );
    });
  }

  factory MixinItem.read(SummaryDataReader reader) {
    return MixinItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: InstanceItemFieldItem.readMap(reader),
      declaredGetters: InstanceItemGetterItem.readMap(reader),
      declaredSetters: InstanceItemSetterItem.readMap(reader),
      declaredMethods: InstanceItemMethodItem.readMap(reader),
      declaredConstructors: InterfaceItemConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      interface: ManifestInterface.read(reader),
      superclassConstraints: ManifestType.readList(reader),
    );
  }

  @override
  bool match(MatchContext context, MixinElementImpl2 element) {
    return super.match(context, element) &&
        superclassConstraints.match(context, element.superclassConstraints);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    superclassConstraints.writeList(sink);
  }
}

class TopLevelFunctionItem extends TopLevelItem<TopLevelFunctionElementImpl> {
  final ManifestFunctionType functionType;

  TopLevelFunctionItem({
    required super.id,
    required super.metadata,
    required this.functionType,
  });

  factory TopLevelFunctionItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required TopLevelFunctionElementImpl element,
  }) {
    return TopLevelFunctionItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      functionType: element.type.encode(context),
    );
  }

  factory TopLevelFunctionItem.read(SummaryDataReader reader) {
    return TopLevelFunctionItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, TopLevelFunctionElementImpl element) {
    return super.match(context, element) &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    functionType.writeNoTag(sink);
  }
}

class TopLevelGetterItem extends TopLevelItem<GetterElementImpl> {
  final ManifestType returnType;

  TopLevelGetterItem({
    required super.id,
    required super.metadata,
    required this.returnType,
  });

  factory TopLevelGetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElementImpl element,
  }) {
    return TopLevelGetterItem(
      id: id,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      returnType: element.returnType.encode(context),
    );
  }

  factory TopLevelGetterItem.read(SummaryDataReader reader) {
    return TopLevelGetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      returnType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, GetterElementImpl element) {
    return super.match(context, element) &&
        returnType.match(context, element.returnType);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    returnType.write(sink);
  }
}

sealed class TopLevelItem<E extends AnnotatableElementImpl>
    extends ManifestItem<E> {
  TopLevelItem({required super.id, required super.metadata});
}

class TopLevelSetterItem extends TopLevelItem<SetterElementImpl> {
  final ManifestType valueType;

  TopLevelSetterItem({
    required super.id,
    required super.metadata,
    required this.valueType,
  });

  factory TopLevelSetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required SetterElementImpl element,
  }) {
    return TopLevelSetterItem(
      id: id,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      valueType: element.formalParameters[0].type.encode(context),
    );
  }

  factory TopLevelSetterItem.read(SummaryDataReader reader) {
    return TopLevelSetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      valueType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, SetterElementImpl element) {
    return super.match(context, element) &&
        valueType.match(context, element.formalParameters[0].type);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    valueType.write(sink);
  }
}

class TopLevelVariableItem extends TopLevelItem<TopLevelVariableElementImpl2> {
  final ManifestType type;
  final ManifestNode? constInitializer;

  TopLevelVariableItem({
    required super.id,
    required super.metadata,
    required this.type,
    required this.constInitializer,
  });

  factory TopLevelVariableItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required TopLevelVariableElementImpl2 element,
  }) {
    return TopLevelVariableItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      type: element.type.encode(context),
      constInitializer: element.constantInitializer2?.expression.encode(
        context,
      ),
    );
  }

  factory TopLevelVariableItem.read(SummaryDataReader reader) {
    return TopLevelVariableItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      type: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }

  @override
  bool match(MatchContext context, TopLevelVariableElementImpl2 element) {
    return super.match(context, element) &&
        type.match(context, element.type) &&
        constInitializer.match(
          context,
          element.constantInitializer2?.expression,
        );
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    type.write(sink);
    constInitializer.writeOptional(sink);
  }
}

enum _InstanceItemMemberItemKind { field, constructor, method, getter, setter }

extension LookupNameToIdMapExtension on Map<LookupName, ManifestItemId> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension LookupNameToItemMapExtension on Map<LookupName, ManifestItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension SummaryDataReaderExtension on SummaryDataReader {
  Map<LookupName, V> readLookupNameMap<V>({required V Function() readValue}) {
    return readMap(
      readKey: () => LookupName.read(this),
      readValue: () => readValue(),
    );
  }

  Map<LookupName, ManifestItemId> readLookupNameToIdMap() {
    return readLookupNameMap(readValue: () => ManifestItemId.read(this));
  }
}

extension _AnnotatableElementExtension on AnnotatableElementImpl {
  MetadataImpl get effectiveMetadata {
    if (this case PropertyAccessorElementImpl2 accessor) {
      return accessor.thisOrVariableMetadata;
    }
    return metadata2;
  }
}

extension _AstNodeExtension on AstNode {
  ManifestNode encode(EncodeContext context) {
    return ManifestNode.encode(context, this);
  }
}

extension _LookupNameToInstanceItemFieldItemMapExtension
    on Map<LookupName, InstanceItemFieldItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _LookupNameToInstanceItemGetterItemMapExtension
    on Map<LookupName, InstanceItemGetterItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _LookupNameToInstanceItemMethodItemMapExtension
    on Map<LookupName, InstanceItemMethodItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _LookupNameToInstanceItemSetterItemMapExtension
    on Map<LookupName, InstanceItemSetterItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _LookupNameToInterfaceItemConstructorItemMapExtension
    on Map<LookupName, InterfaceItemConstructorItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _PropertyAccessExtension on PropertyAccessorElementImpl2 {
  MetadataImpl get thisOrVariableMetadata {
    if (isSynthetic) {
      return variable3!.metadata2;
    } else {
      return metadata2;
    }
  }
}
