// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;

import '../api_prototype/lowering_predicates.dart';
import '../base/combinator.dart' show CombinatorBuilder;
import '../base/configuration.dart' show Configuration;
import '../base/export.dart';
import '../base/identifiers.dart' show Identifier;
import '../base/import.dart';
import '../base/modifiers.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/synthesized_type_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import 'offset_map.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart';
import 'type_parameter_scope_builder.dart';

abstract class BuilderFactoryResult {
  String? get name;

  bool get isPart;

  String? get partOfName;

  Uri? get partOfUri;

  /// The part directives in this compilation unit.
  List<Part> get parts;

  List<Import> get imports;

  List<Export> get exports;

  List<MetadataBuilder>? get metadata;

  TypeScope get typeScope;

  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications);

  void collectUnboundTypeParameters(
      SourceLibraryBuilder libraryBuilder,
      Map<NominalParameterBuilder, SourceLibraryBuilder> nominalParameters,
      Map<StructuralParameterBuilder, SourceLibraryBuilder>
          structuralParameters);

  int finishNativeMethods();

  void registerUnresolvedStructuralParameters(
      List<StructuralParameterBuilder> unboundTypeParameters);

  List<LibraryPart> get libraryParts;
}

abstract class BuilderFactory {
  void beginClassOrNamedMixinApplicationHeader();

  /// Registers that this builder is preparing for a class declaration with the
  /// given [name] and [typeParameters] located at [nameOffset].
  void beginClassDeclaration(
      String name, int nameOffset, List<TypeParameterFragment>? typeParameters);

  void beginClassBody();

  void endClassDeclaration(String name);

  void endClassDeclarationForParserRecovery(
      List<TypeParameterFragment>? typeParameters);

  /// Registers that this builder is preparing for a mixin declaration with the
  /// given [name] and [typeParameters] located at [nameOffset].
  void beginMixinDeclaration(
      String name, int nameOffset, List<TypeParameterFragment>? typeParameters);

  void beginMixinBody();

  void endMixinDeclaration(String name);

  void endMixinDeclarationForParserRecovery(
      List<TypeParameterFragment>? typeParameters);

  /// Registers that this builder is preparing for a named mixin application
  /// with the given [name] and [typeParameters] located [charOffset].
  void beginNamedMixinApplication(
      String name, int charOffset, List<TypeParameterFragment>? typeParameters);

  void endNamedMixinApplication(String name);

  void endNamedMixinApplicationForParserRecovery(
      List<TypeParameterFragment>? typeParameters);

  void beginEnumDeclarationHeader(String name);

  /// Registers that this builder is preparing for an enum declaration with
  /// the given [name] and [typeParameters] located at [nameOffset].
  void beginEnumDeclaration(
      String name, int nameOffset, List<TypeParameterFragment>? typeParameters);

  void beginEnumBody();

  void endEnumDeclaration(String name);

  void endEnumDeclarationForParserRecovery(
      List<TypeParameterFragment>? typeParameters);

  void beginExtensionOrExtensionTypeHeader();

  /// Registers that this builder is preparing for an extension declaration with
  /// the given [name] and [typeParameters] located [charOffset].
  void beginExtensionDeclaration(String? name, int charOffset,
      List<TypeParameterFragment>? typeParameters);

  void beginExtensionBody();

  void endExtensionDeclaration(String? name);

  /// Registers that this builder is preparing for an extension type declaration
  /// with the given [name] and [typeParameters] located at [nameOffset].
  void beginExtensionTypeDeclaration(
      String name, int nameOffset, List<TypeParameterFragment>? typeParameters);

  void beginExtensionTypeBody();

  void endExtensionTypeDeclaration(String name);

  void beginFactoryMethod();

  void endFactoryMethodForParserRecovery();

  void beginFunctionType();

  void endFunctionType();

  void beginConstructor();

  void endConstructorForParserRecovery(
      List<TypeParameterFragment>? typeParameters);

  void beginStaticMethod();

  void endStaticMethodForParserRecovery(
      List<TypeParameterFragment>? typeParameters);

  void beginInstanceMethod();

  void endInstanceMethodForParserRecovery(
      List<TypeParameterFragment>? typeParameters);

  void beginTopLevelMethod();

  void endTopLevelMethodForParserRecovery(
      List<TypeParameterFragment>? typeParameters);

  void beginTypedef();

  void endTypedef();

  void endTypedefForParserRecovery(List<TypeParameterFragment>? typeParameters);

  void checkStacks();

  void addScriptToken(int charOffset);

  void addLibraryDirective(
      {required String? libraryName,
      required List<MetadataBuilder>? metadata,
      required bool isAugment});

  void addPart(OffsetMap offsetMap, Token partKeyword,
      List<MetadataBuilder>? metadata, String uri, int charOffset);

  void addPartOf(List<MetadataBuilder>? metadata, String? name, String? uri,
      int uriOffset);

  void addImport(
      {OffsetMap? offsetMap,
      Token? importKeyword,
      required List<MetadataBuilder>? metadata,
      required bool isAugmentationImport,
      required String uri,
      required List<Configuration>? configurations,
      required String? prefix,
      required List<CombinatorBuilder>? combinators,
      required bool deferred,
      required int charOffset,
      required int prefixCharOffset,
      required int uriOffset});

  void addExport(
      OffsetMap offsetMap,
      Token exportKeyword,
      List<MetadataBuilder>? metadata,
      String uri,
      List<Configuration>? configurations,
      List<CombinatorBuilder>? combinators,
      int charOffset,
      int uriOffset);

  void addClass(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<TypeParameterFragment>? typeParameters,
      required TypeBuilder? supertype,
      required List<TypeBuilder>? mixins,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset,
      required int supertypeOffset});

  void addEnum(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Identifier identifier,
      required List<TypeParameterFragment>? typeParameters,
      required List<TypeBuilder>? mixins,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int endOffset});

  void addEnumElement(
      {required List<MetadataBuilder>? metadata,
      required String name,
      required int nameOffset,
      required ConstructorReferenceBuilder? constructorReferenceBuilder,
      required Token? argumentsBeginToken});

  void addExtensionDeclaration(
      {required OffsetMap offsetMap,
      required Token beginToken,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier? identifier,
      required List<TypeParameterFragment>? typeParameters,
      required TypeBuilder onType,
      required int startOffset,
      required int nameOrExtensionOffset,
      required int endOffset});

  void addExtensionTypeDeclaration(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<TypeParameterFragment>? typeParameters,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int endOffset});

  void addMixinDeclaration(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<TypeParameterFragment>? typeParameters,
      required List<TypeBuilder>? supertypeConstraints,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset});

  void addNamedMixinApplication(
      {required List<MetadataBuilder>? metadata,
      required String name,
      required List<TypeParameterFragment>? typeParameters,
      required Modifiers modifiers,
      required TypeBuilder? supertype,
      required List<TypeBuilder> mixins,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset});

  void addFunctionTypeAlias(
      List<MetadataBuilder>? metadata,
      String name,
      List<TypeParameterFragment>? typeParameters,
      TypeBuilder type,
      int nameOffset);

  void addClassMethod(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Identifier identifier,
      required String name,
      required TypeBuilder? returnType,
      required List<FormalParameterBuilder>? formals,
      required List<TypeParameterFragment>? typeParameters,
      required Token? beginInitializers,
      required int startOffset,
      required int endOffset,
      required int nameOffset,
      required int formalsOffset,
      required Modifiers modifiers,
      required bool inConstructor,
      required bool isStatic,
      required bool isConstructor,
      required bool forAbstractClassOrMixin,
      required bool isExtensionMember,
      required bool isExtensionTypeMember,
      required AsyncMarker asyncModifier,
      required String? nativeMethodName,
      required ProcedureKind? kind});

  void addConstructor(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required ConstructorName constructorName,
      required List<TypeParameterFragment>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required Token? beginInitializers,
      required bool forAbstractClassOrMixin});

  void addPrimaryConstructor(
      {required OffsetMap offsetMap,
      required Token beginToken,
      required String? name,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int? nameOffset,
      required int formalsOffset,
      required bool isConst});

  void addPrimaryConstructorField(
      {required List<MetadataBuilder>? metadata,
      required TypeBuilder type,
      required String name,
      required int nameOffset});

  void addFactoryMethod(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<FormalParameterBuilder>? formals,
      required ConstructorReferenceBuilder? redirectionTarget,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier});

  ConstructorName computeAndValidateConstructorName(
      DeclarationFragmentImpl enclosingDeclaration, Identifier identifier,
      {isFactory = false});

  void addMethod(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<TypeParameterFragment>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember,
      required bool isOperator});

  void addGetter(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<TypeParameterFragment>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember});

  void addSetter(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<TypeParameterFragment>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember});

  void addFields(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      Modifiers modifiers,
      bool isTopLevel,
      TypeBuilder? type,
      List<FieldInfo> fieldInfos);

  FormalParameterBuilder addFormalParameter(
      List<MetadataBuilder>? metadata,
      FormalParameterKind kind,
      Modifiers modifiers,
      TypeBuilder type,
      String name,
      bool hasThis,
      bool hasSuper,
      int charOffset,
      Token? initializerToken,
      {bool lowerWildcard = false});

  ConstructorReferenceBuilder addConstructorReference(TypeName name,
      List<TypeBuilder>? typeArguments, String? suffix, int charOffset);

  ConstructorReferenceBuilder? addUnnamedConstructorReference(
      List<TypeBuilder>? typeArguments, Identifier? suffix, int charOffset);

  TypeBuilder addNamedType(
      TypeName typeName,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      int charOffset,
      {required InstanceTypeParameterAccessState instanceTypeParameterAccess});

  FunctionTypeBuilder addFunctionType(
      TypeBuilder returnType,
      List<StructuralParameterBuilder>? structuralParameterBuilders,
      List<FormalParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri fileUri,
      int charOffset,
      {required bool hasFunctionFormalParameterSyntax});

  TypeBuilder addVoidType(int charOffset);

  InferableTypeBuilder addInferableType();

  TypeParameterFragment addNominalParameter(List<MetadataBuilder>? metadata,
      String name, TypeBuilder? bound, int charOffset, Uri fileUri,
      {required TypeParameterKind kind});

  StructuralParameterBuilder addStructuralParameter(
      List<MetadataBuilder>? metadata,
      String name,
      TypeBuilder? bound,
      int charOffset,
      Uri fileUri);

  void registerUnboundStructuralParameters(
      List<StructuralParameterBuilder> parameterBuilders);
}

class NominalParameterCopy {
  final List<NominalParameterBuilder> newParameterBuilders;
  final List<TypeBuilder> newTypeArguments;
  final Map<NominalParameterBuilder, TypeBuilder> substitutionMap;
  final Map<NominalParameterBuilder, NominalParameterBuilder>
      newToOldParameterMap;

  NominalParameterCopy(this.newParameterBuilders, this.newTypeArguments,
      this.substitutionMap, this.newToOldParameterMap);

  /// Creates a [NominalParameterCopy] object containing a copy of
  /// [oldParameterBuilders], adding any newly created parameters in
  /// [unboundNominalParameters] for later processing.
  ///
  /// This is used for adding copies of class type parameters to factory
  /// methods and unnamed mixin applications, and for adding copies of
  /// extension type parameters to extension instance methods.
  static NominalParameterCopy? copyTypeParameters(
      List<NominalParameterBuilder> unboundNominalParameters,
      List<NominalParameterBuilder>? oldParameterBuilders,
      {required TypeParameterKind kind,
      required InstanceTypeParameterAccessState instanceTypeParameterAccess}) {
    if (oldParameterBuilders == null || oldParameterBuilders.isEmpty) {
      return null;
    }

    List<TypeBuilder> newTypeArguments = [];
    Map<NominalParameterBuilder, TypeBuilder> substitutionMap =
        new Map.identity();
    Map<NominalParameterBuilder, NominalParameterBuilder> newToOldVariableMap =
        new Map.identity();

    List<NominalParameterBuilder> newVariableBuilders =
        <NominalParameterBuilder>[];
    for (NominalParameterBuilder oldVariable in oldParameterBuilders) {
      NominalParameterBuilder newVariable = new NominalParameterBuilder(
          oldVariable.name, oldVariable.fileOffset, oldVariable.fileUri,
          kind: kind,
          variableVariance: oldVariable.parameter.isLegacyCovariant
              ? null
              :
              // Coverage-ignore(suite): Not run.
              oldVariable.variance,
          isWildcard: oldVariable.isWildcard);
      newVariableBuilders.add(newVariable);
      newToOldVariableMap[newVariable] = oldVariable;
      unboundNominalParameters.add(newVariable);
    }
    for (int i = 0; i < newVariableBuilders.length; i++) {
      NominalParameterBuilder oldVariableBuilder = oldParameterBuilders[i];
      TypeBuilder newTypeArgument =
          new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
              newVariableBuilders[i], const NullabilityBuilder.omitted(),
              instanceTypeParameterAccess: instanceTypeParameterAccess);
      substitutionMap[oldVariableBuilder] = newTypeArgument;
      newTypeArguments.add(newTypeArgument);

      if (oldVariableBuilder.bound != null) {
        newVariableBuilders[i].bound = new SynthesizedTypeBuilder(
            oldVariableBuilder.bound!, newToOldVariableMap, substitutionMap);
      }
    }
    return new NominalParameterCopy(newVariableBuilders, newTypeArguments,
        substitutionMap, newToOldVariableMap);
  }

  /// Creates a [SynthesizedTypeBuilder] for [typeBuilder] in the context of
  /// [newParameterBuilders].
  TypeBuilder createInContext(TypeBuilder typeBuilder) {
    return new SynthesizedTypeBuilder(
        typeBuilder, newToOldParameterMap, substitutionMap);
  }
}

/// The synthesized type parameters and this formal for an extension instance
/// member.
class SynthesizedExtensionSignature {
  final List<NominalParameterBuilder>? clonedDeclarationTypeParameters;
  final FormalParameterBuilder thisFormal;

  SynthesizedExtensionSignature._(
      this.clonedDeclarationTypeParameters, this.thisFormal);

  factory SynthesizedExtensionSignature(ExtensionBuilder declarationBuilder,
      List<NominalParameterBuilder> unboundNominalParameters,
      {required Uri fileUri, required int fileOffset}) {
    List<NominalParameterBuilder>? clonedDeclarationTypeParameters;

    NominalParameterCopy? nominalVariableCopy =
        NominalParameterCopy.copyTypeParameters(
            unboundNominalParameters, declarationBuilder.typeParameters,
            kind: TypeParameterKind.extensionSynthesized,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Allowed);

    clonedDeclarationTypeParameters = nominalVariableCopy?.newParameterBuilders;

    TypeBuilder thisType = declarationBuilder.onType;
    if (nominalVariableCopy != null) {
      thisType = nominalVariableCopy.createInContext(thisType);
    }

    FormalParameterBuilder thisFormal = new FormalParameterBuilder(
        FormalParameterKind.requiredPositional,
        Modifiers.Final,
        thisType,
        syntheticThisName,
        fileOffset,
        fileUri: fileUri,
        isExtensionThis: true,
        hasImmediatelyDeclaredInitializer: false);
    return new SynthesizedExtensionSignature._(
        clonedDeclarationTypeParameters, thisFormal);
  }
}

/// The synthesized type parameters and this formal for an extension type
/// instance member.
class SynthesizedExtensionTypeSignature {
  final List<NominalParameterBuilder>? clonedDeclarationTypeParameters;
  final FormalParameterBuilder thisFormal;

  SynthesizedExtensionTypeSignature._(
      this.clonedDeclarationTypeParameters, this.thisFormal);

  factory SynthesizedExtensionTypeSignature(
      ExtensionTypeDeclarationBuilder declarationBuilder,
      List<NominalParameterBuilder> unboundNominalParameters,
      {required Uri fileUri,
      required int fileOffset}) {
    List<NominalParameterBuilder>? clonedDeclarationTypeParameters;

    NominalParameterCopy? nominalVariableCopy =
        NominalParameterCopy.copyTypeParameters(
            unboundNominalParameters, declarationBuilder.typeParameters,
            kind: TypeParameterKind.extensionSynthesized,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Allowed);

    clonedDeclarationTypeParameters = nominalVariableCopy?.newParameterBuilders;

    TypeBuilder thisType = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        declarationBuilder, const NullabilityBuilder.omitted(),
        arguments: declarationBuilder.typeParameters != null
            ? new List<TypeBuilder>.generate(
                declarationBuilder.typeParameters!.length,
                (int index) =>
                    new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                        clonedDeclarationTypeParameters![index],
                        const NullabilityBuilder.omitted(),
                        instanceTypeParameterAccess:
                            InstanceTypeParameterAccessState.Allowed))
            : null,
        instanceTypeParameterAccess: InstanceTypeParameterAccessState.Allowed);

    if (nominalVariableCopy != null) {
      thisType = nominalVariableCopy.createInContext(thisType);
    }

    FormalParameterBuilder thisFormal = new FormalParameterBuilder(
        FormalParameterKind.requiredPositional,
        Modifiers.Final,
        thisType,
        syntheticThisName,
        fileOffset,
        fileUri: fileUri,
        isExtensionThis: true,
        hasImmediatelyDeclaredInitializer: false);

    return new SynthesizedExtensionTypeSignature._(
        clonedDeclarationTypeParameters, thisFormal);
  }
}

class FieldInfo {
  final Identifier identifier;
  final Token? initializerToken;
  final Token? beforeLast;
  final int endOffset;

  const FieldInfo(
      this.identifier, this.initializerToken, this.beforeLast, this.endOffset);
}
