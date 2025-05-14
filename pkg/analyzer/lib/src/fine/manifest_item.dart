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

class ClassItem extends InterfaceItem {
  ClassItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.supertype,
    required super.interfaces,
    required super.mixins,
    required super.members,
  });

  factory ClassItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ClassElementImpl2 element,
  }) {
    return context.withTypeParameters(
      element.typeParameters2,
      (typeParameters) {
        return ClassItem(
          id: id,
          metadata: ManifestMetadata.encode(context, element.metadata2),
          typeParameters: typeParameters,
          supertype: element.supertype?.encode(context),
          mixins: element.mixins.encode(context),
          interfaces: element.interfaces.encode(context),
          members: {},
        );
      },
    );
  }

  factory ClassItem.read(SummaryDataReader reader) {
    return ClassItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      members: InstanceItem._readMembers(reader),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.class_);
    super.write(sink);
  }
}

/// The item for [InstanceElementImpl2].
sealed class InstanceItem extends TopLevelItem {
  final List<ManifestTypeParameter> typeParameters;
  final Map<LookupName, InstanceItemMemberItem> members;

  InstanceItem({
    required super.id,
    required super.metadata,
    required this.typeParameters,
    required this.members,
  });

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    typeParameters.writeList(sink);
    sink.writeMap(
      members,
      writeKey: (name) => name.write(sink),
      writeValue: (member) => member.write(sink),
    );
  }

  static Map<LookupName, InstanceItemMemberItem> _readMembers(
    SummaryDataReader reader,
  ) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => InstanceItemMemberItem.read(reader),
    );
  }
}

class InstanceItemGetterItem extends InstanceItemMemberItem {
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
    required GetterElement2OrMember element,
  }) {
    return InstanceItemGetterItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
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
  bool match(
    MatchContext context,
    covariant GetterElement2OrMember element,
  ) {
    return super.match(context, element) &&
        returnType.match(context, element.returnType);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.instanceGetter);
    super.write(sink);
    returnType.write(sink);
  }
}

sealed class InstanceItemMemberItem extends ManifestItem {
  final bool isStatic;

  InstanceItemMemberItem({
    required super.id,
    required super.metadata,
    required this.isStatic,
  });

  factory InstanceItemMemberItem.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestItemKind2.values);
    switch (kind) {
      case _ManifestItemKind2.instanceGetter:
        return InstanceItemGetterItem.read(reader);
      case _ManifestItemKind2.instanceMethod:
        return InstanceItemMethodItem.read(reader);
      case _ManifestItemKind2.interfaceConstructor:
        return InterfaceItemConstructorItem.read(reader);
    }
  }

  @override
  bool match(
    MatchContext context,
    covariant ExecutableElement2OrMember element,
  ) {
    return super.match(context, element) && element.isStatic == isStatic;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isStatic);
  }
}

class InstanceItemMethodItem extends InstanceItemMemberItem {
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
    required MethodElement2OrMember element,
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
  bool match(
    MatchContext context,
    covariant MethodElement2OrMember element,
  ) {
    return super.match(context, element) &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.instanceMethod);
    super.write(sink);
    functionType.writeNoTag(sink);
  }
}

/// The item for [InterfaceElementImpl2].
sealed class InterfaceItem extends InstanceItem {
  final ManifestType? supertype;
  final List<ManifestType> interfaces;
  final List<ManifestType> mixins;

  InterfaceItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.members,
    required this.supertype,
    required this.interfaces,
    required this.mixins,
  });

  @override
  bool match(MatchContext context, covariant InterfaceElementImpl2 element) {
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
  }
}

class InterfaceItemConstructorItem extends InstanceItemMemberItem {
  final bool isConst;
  final bool isFactory;
  final ManifestFunctionType functionType;

  InterfaceItemConstructorItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.isConst,
    required this.isFactory,
    required this.functionType,
  });

  factory InterfaceItemConstructorItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ConstructorElementImpl2 element,
  }) {
    // TODO(scheglov): initializers
    return InterfaceItemConstructorItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      isStatic: false,
      isConst: element.isConst,
      isFactory: element.isFactory,
      functionType: element.type.encode(context),
    );
  }

  factory InterfaceItemConstructorItem.read(SummaryDataReader reader) {
    return InterfaceItemConstructorItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      isConst: reader.readBool(),
      isFactory: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  @override
  bool match(
    MatchContext context,
    covariant ConstructorElementImpl2 element,
  ) {
    return super.match(context, element) &&
        isConst == element.isConst &&
        isFactory == element.isFactory &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.interfaceConstructor);
    super.write(sink);
    sink.writeBool(isConst);
    sink.writeBool(isFactory);
    functionType.writeNoTag(sink);
  }
}

class ManifestAnnotation {
  final ManifestNode ast;

  ManifestAnnotation({
    required this.ast,
  });

  factory ManifestAnnotation.read(SummaryDataReader reader) {
    return ManifestAnnotation(
      ast: ManifestNode.read(reader),
    );
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

sealed class ManifestItem {
  /// The unique identifier of this item.
  final ManifestItemId id;
  final ManifestMetadata metadata;

  ManifestItem({
    required this.id,
    required this.metadata,
  });

  @mustCallSuper
  bool match(MatchContext context, AnnotatableElement element) {
    return metadata.match(context, element.effectiveMetadata);
  }

  void write(BufferedSink sink) {
    id.write(sink);
    metadata.write(sink);
  }
}

class ManifestMetadata {
  final List<ManifestAnnotation> annotations;

  ManifestMetadata({
    required this.annotations,
  });

  factory ManifestMetadata.encode(
    EncodeContext context,
    MetadataImpl metadata,
  ) {
    return ManifestMetadata(
      annotations: metadata.annotations.map((annotation) {
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

class TopLevelFunctionItem extends TopLevelItem {
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
  bool match(
    MatchContext context,
    covariant TopLevelFunctionElementImpl element,
  ) {
    return super.match(context, element) &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelFunction);
    super.write(sink);
    functionType.writeNoTag(sink);
  }
}

class TopLevelGetterItem extends TopLevelItem {
  final ManifestType returnType;
  final ManifestNode? constInitializer;

  TopLevelGetterItem({
    required super.id,
    required super.metadata,
    required this.returnType,
    required this.constInitializer,
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
      constInitializer: element.constInitializer?.encode(context),
    );
  }

  factory TopLevelGetterItem.read(SummaryDataReader reader) {
    return TopLevelGetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      returnType: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }

  @override
  bool match(
    MatchContext context,
    covariant GetterElementImpl element,
  ) {
    return super.match(context, element) &&
        returnType.match(context, element.returnType) &&
        constInitializer.match(context, element.constInitializer);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelGetter);
    super.write(sink);
    returnType.write(sink);
    constInitializer.writeOptional(sink);
  }
}

sealed class TopLevelItem extends ManifestItem {
  TopLevelItem({
    required super.id,
    required super.metadata,
  });

  factory TopLevelItem.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestItemKind.values);
    switch (kind) {
      case _ManifestItemKind.class_:
        return ClassItem.read(reader);
      case _ManifestItemKind.topLevelFunction:
        return TopLevelFunctionItem.read(reader);
      case _ManifestItemKind.topLevelGetter:
        return TopLevelGetterItem.read(reader);
      case _ManifestItemKind.topLevelSetter:
        return TopLevelSetterItem.read(reader);
    }
  }
}

class TopLevelSetterItem extends TopLevelItem {
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
  bool match(
    MatchContext context,
    covariant SetterElementImpl element,
  ) {
    return super.match(context, element) &&
        valueType.match(context, element.formalParameters[0].type);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelSetter);
    super.write(sink);
    valueType.write(sink);
  }
}

enum _ManifestItemKind {
  class_,
  topLevelFunction,
  topLevelGetter,
  topLevelSetter,
}

enum _ManifestItemKind2 {
  instanceGetter,
  instanceMethod,
  interfaceConstructor,
}

extension _AnnotatableElementExtension on AnnotatableElement {
  MetadataImpl get effectiveMetadata {
    if (this case PropertyAccessorElement2OrMember accessor) {
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

extension _GetterElementImplExtension on GetterElementImpl {
  Expression? get constInitializer {
    if (isSynthetic) {
      var variable = variable3!;
      if (variable.isConst) {
        return variable.constantInitializer2?.expression;
      }
    }
    return null;
  }
}

extension _PropertyAccessExtension on PropertyAccessorElement2OrMember {
  MetadataImpl get thisOrVariableMetadata {
    if (isSynthetic) {
      return variable3!.metadata2;
    } else {
      return metadata2;
    }
  }
}
