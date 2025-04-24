// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:front_end/src/base/local_scope.dart';
import 'package:front_end/src/base/messages.dart';
import 'package:front_end/src/builder/property_builder.dart';
import 'package:front_end/src/fragment/method/encoding.dart';
import 'package:front_end/src/source/source_loader.dart';
import 'package:front_end/src/source/source_method_builder.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/transformations/flags.dart';
import 'package:kernel/type_environment.dart';

import '../base/modifiers.dart' show Modifiers;
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/constructor/declaration.dart';
import '../fragment/fragment.dart';
import '../fragment/method/declaration.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/member_covariance.dart';
import '../kernel/type_algorithms.dart';
import '../kernel/utils.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_member_builder.dart';
import 'source_property_builder.dart';
import 'source_type_parameter_builder.dart';
import 'type_parameter_scope_builder.dart';

class SourceEnumBuilder extends SourceClassBuilder {
  final int startOffset;
  final int endOffset;

  final ClassDeclaration _introductory;

  final List<EnumElementFragment> _enumElements;

  final TypeBuilder _underscoreEnumTypeBuilder;

  late final NamedTypeBuilder objectType;

  late final NamedTypeBuilder listType;

  late final NamedTypeBuilder selfType;

  SourceConstructorBuilderImpl? synthesizedDefaultConstructorBuilder;

  late final _EnumValuesFieldDeclaration _enumValuesFieldDeclaration;

  SourceEnumBuilder.internal(
      {required String name,
      required List<SourceNominalParameterBuilder>? typeParameters,
      required TypeBuilder underscoreEnumTypeBuilder,
      required LookupScope typeParameterScope,
      required DeclarationNameSpaceBuilder nameSpaceBuilder,
      required List<EnumElementFragment> enumElements,
      required SourceLibraryBuilder libraryBuilder,
      required Uri fileUri,
      required this.startOffset,
      required int nameOffset,
      required this.endOffset,
      required IndexedClass? indexedClass,
      required ClassDeclaration classDeclaration})
      : _underscoreEnumTypeBuilder = underscoreEnumTypeBuilder,
        _introductory = classDeclaration,
        _enumElements = enumElements,
        super(
            modifiers: Modifiers.empty,
            name: name,
            typeParameters: typeParameters,
            typeParameterScope: typeParameterScope,
            nameSpaceBuilder: nameSpaceBuilder,
            libraryBuilder: libraryBuilder,
            fileUri: fileUri,
            nameOffset: nameOffset,
            indexedClass: indexedClass,
            introductory: classDeclaration);

  factory SourceEnumBuilder(
      {required String name,
      required List<SourceNominalParameterBuilder>? typeParameters,
      required TypeBuilder underscoreEnumTypeBuilder,
      required List<TypeBuilder>? interfaceBuilders,
      required List<EnumElementFragment> enumElements,
      required SourceLibraryBuilder libraryBuilder,
      required Uri fileUri,
      required int startOffset,
      required int nameOffset,
      required int endOffset,
      required IndexedClass? indexedClass,
      required LookupScope typeParameterScope,
      required DeclarationNameSpaceBuilder nameSpaceBuilder,
      required ClassDeclaration classDeclaration}) {
    SourceEnumBuilder enumBuilder = new SourceEnumBuilder.internal(
        name: name,
        typeParameters: typeParameters,
        underscoreEnumTypeBuilder: underscoreEnumTypeBuilder,
        typeParameterScope: typeParameterScope,
        nameSpaceBuilder: nameSpaceBuilder,
        enumElements: enumElements,
        libraryBuilder: libraryBuilder,
        fileUri: fileUri,
        startOffset: startOffset,
        nameOffset: nameOffset,
        endOffset: endOffset,
        indexedClass: indexedClass,
        classDeclaration: classDeclaration);
    return enumBuilder;
  }

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    super.buildScopes(coreLibrary);
    _createSynthesizedMembers(coreLibrary);

    Iterator<MemberBuilder> constructorIterator =
        nameSpace.filteredConstructorIterator(includeDuplicates: false);
    while (constructorIterator.moveNext()) {
      MemberBuilder constructorBuilder = constructorIterator.current;
      if (constructorBuilder is ConstructorBuilder &&
          !constructorBuilder.isConst) {
        libraryBuilder.addProblem(messageEnumNonConstConstructor,
            constructorBuilder.fileOffset, noLength, fileUri);
      }
    }
  }

  void _createSynthesizedMembers(LibraryBuilder coreLibrary) {
    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    objectType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("Object"), const NullabilityBuilder.omitted(),
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected);
    selfType = new NamedTypeBuilderImpl(new SyntheticTypeName(name, fileOffset),
        const NullabilityBuilder.omitted(),
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected,
        fileUri: fileUri,
        charOffset: fileOffset);
    listType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("List"), const NullabilityBuilder.omitted(),
        arguments: <TypeBuilder>[selfType],
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected);

    // metadata class E extends _Enum {
    //   const E(int index, String name) : super(index, name);
    //   static const E id0 = const E(0, 'id0');
    //   ...
    //   static const E id${n-1} = const E(n - 1, 'idn-1');
    //   static const List<E> values = const <E>[id0, ..., id${n-1}];
    //   String _enumToString() {
    //     return "E.${_Enum::_name}";
    //   }
    // }

    LibraryName libraryName = indexedClass != null
        ? new LibraryName(indexedClass!.library.reference)
        : libraryBuilder.libraryName;

    NameScheme staticFieldNameScheme = new NameScheme(
        isInstanceMember: false,
        containerName: new ClassName(name),
        containerType: ContainerType.Class,
        libraryName: libraryName);

    Reference? constructorReference;
    Reference? tearOffReference;
    Reference? toStringReference;
    if (indexedClass != null) {
      constructorReference =
          indexedClass!.lookupConstructorReference(new Name(""));
      tearOffReference = indexedClass!.lookupGetterReference(
          new Name(constructorTearOffName(""), indexedClass!.library));
      toStringReference = indexedClass!.lookupGetterReference(
          new Name("_enumToString", coreLibrary.library));
    }

    FieldReference valuesReferences = new FieldReference(
        "values", staticFieldNameScheme, indexedClass,
        fieldIsLateWithLowering: false, isExternal: false);

    Builder? customValuesDeclaration =
        nameSpace.lookupLocalMember("values", setter: false);
    if (customValuesDeclaration != null) {
      // Retrieve the earliest declaration for error reporting.
      while (customValuesDeclaration?.next != null) {
        customValuesDeclaration = customValuesDeclaration?.next;
      }
      libraryBuilder.addProblem(
          messageEnumContainsValuesDeclaration,
          customValuesDeclaration!.fileOffset,
          customValuesDeclaration.fullNameForErrors.length,
          fileUri);
    }

    for (String restrictedInstanceMemberName in const [
      "index",
      "hashCode",
      "=="
    ]) {
      Builder? customIndexDeclaration = nameSpace
          .lookupLocalMember(restrictedInstanceMemberName, setter: false);
      if (customIndexDeclaration is MemberBuilder &&
          !customIndexDeclaration.isAbstract &&
          !customIndexDeclaration.isEnumElement) {
        // Retrieve the earliest declaration for error reporting.
        while (customIndexDeclaration?.next != null) {
          // Coverage-ignore-block(suite): Not run.
          customIndexDeclaration = customIndexDeclaration?.next;
        }
        libraryBuilder.addProblem(
            templateEnumContainsRestrictedInstanceDeclaration
                .withArguments(restrictedInstanceMemberName),
            customIndexDeclaration!.fileOffset,
            customIndexDeclaration.fullNameForErrors.length,
            fileUri);
      }
    }

    _enumValuesFieldDeclaration =
        new _EnumValuesFieldDeclaration(this, valuesReferences, listType);

    SourcePropertyBuilder valuesBuilder = new SourcePropertyBuilder.forField(
        fileUri: fileUri,
        fileOffset: fileOffset,
        name: "values",
        libraryBuilder: libraryBuilder,
        declarationBuilder: this,
        nameScheme: staticFieldNameScheme,
        fieldDeclaration: _enumValuesFieldDeclaration,
        modifiers:
            Modifiers.Const | Modifiers.Static | Modifiers.HasInitializer,
        references: valuesReferences);
    _enumValuesFieldDeclaration.builder = valuesBuilder;

    if (customValuesDeclaration != null) {
      customValuesDeclaration.next = valuesBuilder;
      nameSpaceBuilder.checkTypeParameterConflict(libraryBuilder,
          valuesBuilder.name, valuesBuilder, valuesBuilder.fileUri);
    } else {
      nameSpace.addLocalMember("values", valuesBuilder, setter: false);
      nameSpaceBuilder.checkTypeParameterConflict(libraryBuilder,
          valuesBuilder.name, valuesBuilder, valuesBuilder.fileUri);
    }

    // The default constructor is added if no generative or unnamed factory
    // constructors are declared.
    bool needsSynthesizedDefaultConstructor = true;
    Iterator<MemberBuilder> iterator = nameSpace.unfilteredConstructorIterator;
    while (iterator.moveNext()) {
      MemberBuilder constructorBuilder = iterator.current;
      if (constructorBuilder is! FactoryBuilder ||
          constructorBuilder.name == "") {
        needsSynthesizedDefaultConstructor = false;
        break;
      }
    }
    if (needsSynthesizedDefaultConstructor) {
      FormalParameterBuilder nameFormalParameterBuilder =
          new FormalParameterBuilder(
              FormalParameterKind.requiredPositional,
              Modifiers.empty,
              libraryBuilder.loader.target.stringType,
              "#name",
              fileOffset,
              fileUri: fileUri,
              hasImmediatelyDeclaredInitializer: false);

      FormalParameterBuilder indexFormalParameterBuilder =
          new FormalParameterBuilder(
              FormalParameterKind.requiredPositional,
              Modifiers.empty,
              libraryBuilder.loader.target.intType,
              "#index",
              fileOffset,
              fileUri: fileUri,
              hasImmediatelyDeclaredInitializer: false);

      ConstructorDeclaration constructorDeclaration =
          new DefaultEnumConstructorDeclaration(
              returnType:
                  libraryBuilder.loader.inferableTypes.addInferableType(),
              formals: [
                indexFormalParameterBuilder,
                nameFormalParameterBuilder
              ],
              fileUri: fileUri,
              fileOffset: fileOffset,
              lookupScope: _introductory.compilationUnitScope);
      synthesizedDefaultConstructorBuilder = new SourceConstructorBuilderImpl(
          modifiers: Modifiers.Const,
          name: "",
          libraryBuilder: libraryBuilder,
          declarationBuilder: this,
          fileUri: fileUri,
          fileOffset: fileOffset,
          constructorReference: constructorReference,
          tearOffReference: tearOffReference,
          nameScheme: new NameScheme(
              isInstanceMember: false,
              containerName: new ClassName(name),
              containerType: ContainerType.Class,
              libraryName: libraryName),
          introductory: constructorDeclaration);
      synthesizedDefaultConstructorBuilder!
          .registerInitializedField(valuesBuilder);
      nameSpace.addConstructor("", synthesizedDefaultConstructorBuilder!);
      nameSpaceBuilder.checkTypeParameterConflict(
          libraryBuilder,
          synthesizedDefaultConstructorBuilder!.name,
          synthesizedDefaultConstructorBuilder!,
          synthesizedDefaultConstructorBuilder!.fileUri);
    }

    SourceMethodBuilder toStringBuilder = new SourceMethodBuilder(
        name: "_enumToString",
        fileUri: fileUri,
        fileOffset: fileOffset,
        libraryBuilder: libraryBuilder,
        declarationBuilder: this,
        nameScheme: new NameScheme(
            isInstanceMember: true,
            containerName: new ClassName(name),
            containerType: ContainerType.Class,
            libraryName: new LibraryName(coreLibrary.library.reference)),
        introductory: new _EnumToStringMethodDeclaration(this,
            libraryBuilder.loader.target.stringType, _underscoreEnumTypeBuilder,
            fileUri: fileUri, fileOffset: fileOffset),
        augmentations: const [],
        isStatic: false,
        modifiers: Modifiers.empty,
        reference: toStringReference,
        tearOffReference: null);
    nameSpace.addLocalMember(toStringBuilder.name, toStringBuilder,
        setter: false);
    nameSpaceBuilder.checkTypeParameterConflict(libraryBuilder,
        toStringBuilder.name, toStringBuilder, toStringBuilder.fileUri);

    selfType.bind(libraryBuilder, this);

    if (name == "values") {
      libraryBuilder.addProblem(
          messageEnumWithNameValues, this.fileOffset, name.length, fileUri);
    }
  }

  @override
  bool get isEnum => true;

  @override
  TypeBuilder? get mixedInTypeBuilder => null;

  @override
  Class build(LibraryBuilder coreLibrary) {
    int elementIndex = 0;
    for (EnumElementFragment enumElement in _enumElements) {
      if (!enumElement.builder.isDuplicate) {
        enumElement.declaration.elementIndex = elementIndex++;
      } else {
        enumElement.declaration.elementIndex = -1;
      }
    }

    bindCoreType(coreLibrary, objectType);
    bindCoreType(coreLibrary, listType);

    Class cls = super.build(coreLibrary);
    cls.isEnum = true;

    // The super initializer for the synthesized default constructor is
    // inserted here if the enum's supertype is _Enum to preserve the legacy
    // behavior or having the old-style enum constants built in the outlines.
    // Other constructors are handled in [BodyBuilder.finishConstructor] as
    // they are processed via the pipeline for constructor parsing and
    // building.
    if (identical(this.supertypeBuilder, _underscoreEnumTypeBuilder)) {
      if (synthesizedDefaultConstructorBuilder != null) {
        Constructor constructor =
            synthesizedDefaultConstructorBuilder!.invokeTarget as Constructor;
        ClassBuilder objectClass = objectType.declaration as ClassBuilder;
        ClassBuilder enumClass =
            _underscoreEnumTypeBuilder.declaration as ClassBuilder;
        MemberBuilder? superConstructor = enumClass.findConstructorOrFactory(
            "", fileOffset, fileUri, libraryBuilder);
        if (superConstructor == null ||
            superConstructor is! ConstructorBuilder) {
          // Coverage-ignore-block(suite): Not run.
          // TODO(ahe): Ideally, we would also want to check that [Object]'s
          // unnamed constructor requires no arguments. But that information
          // isn't always available at this point, and it's not really a
          // situation that can happen unless you start modifying the SDK
          // sources. (We should add a correct message. We no longer depend on
          // Object here.)
          libraryBuilder.addProblem(
              messageNoUnnamedConstructorInObject,
              objectClass.fileOffset,
              objectClass.name.length,
              objectClass.fileUri);
        } else {
          constructor.initializers.add(new SuperInitializer(
              superConstructor.invokeTarget as Constructor,
              new Arguments.forwarded(
                  constructor.function, libraryBuilder.library))
            ..parent = constructor);
        }
        synthesizedDefaultConstructorBuilder = null;
      }
    }

    return cls;
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return new EnumBodyBuilderContext(this);
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    for (EnumElementFragment enumElement in _enumElements) {
      enumElement.declaration.inferType(classHierarchy);
    }
    _enumValuesFieldDeclaration.inferType(classHierarchy);

    super.buildOutlineExpressions(classHierarchy, delayedDefaultValueCloners);
  }
}

class _EnumToStringMethodDeclaration implements MethodDeclaration {
  static const String _enumToStringName = "_enumToString";

  final SourceEnumBuilder _enumBuilder;
  final TypeBuilder _stringTypeBuilder;
  final TypeBuilder _underscoreEnumTypeBuilder;

  final Uri _fileUri;
  final int _fileOffset;
  late final Procedure _procedure;

  _EnumToStringMethodDeclaration(this._enumBuilder, this._stringTypeBuilder,
      this._underscoreEnumTypeBuilder,
      {required Uri fileUri, required int fileOffset})
      : _fileUri = fileUri,
        _fileOffset = fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  void becomeNative(SourceLoader loader) {
    // TODO: implement becomeNative
  }

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      SourceMethodBuilder methodBuilder,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    Name toStringName =
        new Name(_enumToStringName, classHierarchy.coreTypes.coreLibrary);
    Member? superToString = _enumBuilder.cls.superclass != null
        ? classHierarchy.getDispatchTarget(
            _enumBuilder.cls.superclass!, toStringName)
        : null;
    Procedure? toStringSuperTarget = superToString is Procedure &&
            // Coverage-ignore(suite): Not run.
            superToString.enclosingClass != classHierarchy.coreTypes.objectClass
        ? superToString
        : null;

    if (toStringSuperTarget != null) {
      // Coverage-ignore-block(suite): Not run.
      _procedure.transformerFlags |= TransformerFlag.superCalls;
      _procedure.function.body = new ReturnStatement(new SuperMethodInvocation(
          toStringName, new Arguments([]), toStringSuperTarget))
        ..parent = _procedure.function;
    } else {
      ClassBuilder enumClass =
          _underscoreEnumTypeBuilder.declaration as ClassBuilder;
      MemberBuilder? nameFieldBuilder =
          enumClass.lookupLocalMember("_name") as MemberBuilder?;
      assert(nameFieldBuilder != null);
      Field nameField = nameFieldBuilder!.readTarget as Field;

      _procedure.function.body = new ReturnStatement(new StringConcatenation([
        new StringLiteral("${_enumBuilder.cls.demangledName}."),
        new InstanceGet.byReference(
            InstanceAccessKind.Instance, new ThisExpression(), nameField.name,
            interfaceTargetReference: nameField.getterReference,
            resultType: nameField.getterType),
      ]))
        ..parent = _procedure.function;
    }
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference reference,
      required Reference? tearOffReference,
      required List<TypeParameter>? classTypeParameters}) {
    FunctionNode function = new FunctionNode(
        new EmptyStatement()..fileOffset = _fileOffset,
        returnType:
            _stringTypeBuilder.build(libraryBuilder, TypeUse.returnType))
      ..fileOffset = _fileOffset
      ..fileEndOffset = _fileOffset;
    _procedure = new Procedure(
        nameScheme.getDeclaredName(_enumToStringName).name,
        ProcedureKind.Method,
        function,
        fileUri: fileUri,
        reference: reference)
      ..fileOffset = _fileOffset
      ..fileEndOffset = _fileOffset
      ..transformerFlags |= TransformerFlag.superCalls;
    f(kind: BuiltMemberKind.Method, member: _procedure);
  }

  @override
  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  BodyBuilderContext createBodyBuilderContext(SourceMethodBuilder builder) {
    throw new UnsupportedError("$runtimeType.createBodyBuilderContext");
  }

  @override
  void createEncoding(
      ProblemReporting problemReporting,
      SourceMethodBuilder builder,
      MethodEncodingStrategy encodingStrategy,
      List<NominalParameterBuilder> unboundNominalParameters) {
    throw new UnsupportedError("$runtimeType.createEncoding");
  }

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    throw new UnsupportedError("$runtimeType.createFormalParameterScope");
  }

  @override
  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder enclosingClassBuilder,
      Set<ClassMember>? overrideDependencies) {}

  @override
  Uri get fileUri => _fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formals => null;

  @override
  // Coverage-ignore(suite): Not run.
  FunctionNode get function => _procedure.function;

  @override
  VariableDeclaration getFormalParameter(int index) {
    throw new UnsupportedError("$runtimeType.getFormalParameter");
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    throw new UnsupportedError("$runtimeType.getTearOffParameter");
  }

  @override
  Procedure get invokeTarget => _procedure;

  @override
  bool get isOperator => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  Procedure? get readTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder get returnType =>
      throw new UnsupportedError("$runtimeType.returnType");

  @override
  // Coverage-ignore(suite): Not run.
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  // Coverage-ignore(suite): Not run.
  VariableDeclaration? get thisVariable => null;
}

class _EnumValuesFieldDeclaration implements FieldDeclaration {
  static const String name = "values";

  final SourceEnumBuilder _sourceEnumBuilder;
  final FieldReference fieldReference;

  SourcePropertyBuilder? _builder;

  DartType _type = const DynamicType();

  Field? _field;

  @override
  final TypeBuilder type;

  _EnumValuesFieldDeclaration(
      this._sourceEnumBuilder, this.fieldReference, this.type);

  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourcePropertyBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    throw new UnsupportedError('${runtimeType}.buildErroneousInitializer');
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError('${runtimeType}.buildImplicitDefaultValue');
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError('${runtimeType}.buildImplicitInitializer');
  }

  @override
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    throw new UnsupportedError('${runtimeType}.buildInitializer');
  }

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      List<Annotatable> annotatables,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    List<Expression> values = <Expression>[];
    for (EnumElementFragment enumElement in _sourceEnumBuilder._enumElements) {
      enumElement.declaration.inferType(classHierarchy);
      if (!enumElement.builder.isDuplicate) {
        values.add(new StaticGet(enumElement.declaration.readTarget));
      }
    }

    _field!.initializer = new ListLiteral(values,
        typeArgument: instantiateToBounds(
            _sourceEnumBuilder.rawType(Nullability.nonNullable),
            classHierarchy.coreTypes.objectClass),
        isConst: true)
      ..parent = _field;
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f, FieldReference references,
      {required List<TypeParameter>? classTypeParameters}) {
    fieldType = type.build(libraryBuilder, TypeUse.fieldType);
    _field = new Field.immutable(dummyName,
        type: _type,
        isFinal: false,
        isConst: true,
        isStatic: true,
        fileUri: builder.fileUri,
        fieldReference: references.fieldReference,
        getterReference: references.fieldGetterReference,
        isEnumElement: false)
      ..fileOffset = builder.fileOffset
      ..fileEndOffset = builder.fileOffset;
    nameScheme
        .getFieldMemberName(FieldNameType.Field, name, isSynthesized: false)
        .attachMember(_field!);
    f(member: _field!, kind: BuiltMemberKind.Field);
  }

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder) {}

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      Set<ClassMember>? getterOverrideDependencies,
      Set<ClassMember>? setterOverrideDependencies) {
    inferType(membersBuilder.hierarchyBuilder);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> getExportedMemberReferences(FieldReference references) {
    return [references.fieldGetterReference];
  }

  @override
  bool get hasInitializer => true;

  @override
  bool get hasSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeDeclaredInstanceField => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isLate => false;

  @override
  List<ClassMember> get localMembers => [new _EnumValuesClassMember(builder)];

  @override
  List<ClassMember> get localSetters => const [];

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  Member get readTarget => _field!;

  @override
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get fieldType => _type;

  @override
  void set fieldType(DartType value) {
    _type = value;
    _field
        // Coverage-ignore(suite): Not run.
        ?.type = value;
  }

  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    return _type;
  }

  @override
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  // Coverage-ignore(suite): Not run.
  SetterQuality get setterQuality => SetterQuality.Absent;
}

class _EnumValuesClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;

  Covariance? _covariance;

  _EnumValuesClassMember(this._builder);

  @override
  bool get forSetter => false;

  @override
  int get charOffset => _builder.fileOffset;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _builder.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullName {
    String className = declarationBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}";
  }

  @override
  String get fullNameForErrors => _builder.fullNameForErrors;

  @override
  // Coverage-ignore(suite): Not run.
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??= forSetter
        ? new Covariance.fromMember(getMember(membersBuilder),
            forSetter: forSetter)
        : const Covariance.empty();
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    inferType(membersBuilder);
    return forSetter
        ?
        // Coverage-ignore(suite): Not run.
        _builder.writeTarget!
        : _builder.readTarget!;
  }

  @override
  // Coverage-ignore(suite): Not run.
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    return new StaticMemberResult(getMember(membersBuilder), memberKind,
        isDeclaredAsField: true,
        fullName: '${declarationBuilder.name}.${_builder.memberName.text}');
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member? getTearOff(ClassMembersBuilder membersBuilder) => null;

  @override
  bool get hasDeclarations => false;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    _builder.inferFieldType(membersBuilder.hierarchyBuilder);
  }

  @override
  ClassMember get interfaceMember => this;

  @override
  bool get isAbstract => false;

  @override
  bool get isDuplicate => _builder.isDuplicate;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isInternalImplementation => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNoSuchMethodForwarder => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool isObjectMember(ClassBuilder objectClass) {
    return declarationBuilder == objectClass;
  }

  @override
  bool get isProperty => true;

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is _EnumValuesClassMember &&
        // Coverage-ignore(suite): Not run.
        _builder == other._builder;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => true;

  @override
  bool get isSynthesized => true;

  @override
  // Coverage-ignore(suite): Not run.
  ClassMemberKind get memberKind => ClassMemberKind.Getter;

  @override
  Name get name => _builder.memberName;

  @override
  // Coverage-ignore(suite): Not run.
  void registerOverrideDependency(
      ClassMembersBuilder membersBuilder, Set<ClassMember> overriddenMembers) {
    _builder.registerGetterOverrideDependency(
        membersBuilder, overriddenMembers);
  }

  @override
  String toString() => '$runtimeType($fullName)';
}
