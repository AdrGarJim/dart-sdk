// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class EnumElementFragment implements Fragment {
  final List<MetadataBuilder>? metadata;

  @override
  final String name;
  final int nameOffset;
  final Uri fileUri;

  final ConstructorReferenceBuilder? constructorReferenceBuilder;

  final LookupScope enclosingScope;
  final DeclarationFragment enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  Token? _argumentsBeginToken;

  SourcePropertyBuilder? _builder;

  EnumElementDeclaration? _declaration;

  final TypeBuilder type = new InferableTypeBuilder();

  EnumElementFragment({
    required this.metadata,
    required this.name,
    required this.nameOffset,
    required this.fileUri,
    required this.constructorReferenceBuilder,
    required Token? argumentsBeginToken,
    required this.enclosingScope,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  }) : _argumentsBeginToken = argumentsBeginToken;

  @override
  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourcePropertyBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  EnumElementDeclaration get declaration {
    assert(
        _declaration != null, "Declaration has not been computed for $this.");
    return _declaration!;
  }

  void set declaration(EnumElementDeclaration value) {
    assert(_declaration == null,
        "Declaration has already been computed for $this.");
    _declaration = value;
  }

  /// Returns the token for begin of the constructor arguments of this enum
  /// element, if any.
  ///
  /// This can only be called once and will hand over the responsibility of
  /// the token to the caller.
  Token? get argumentsBeginToken {
    Token? token = _argumentsBeginToken;
    _argumentsBeginToken = null;
    return token;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}

class _EnumElementClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;
  final EnumElementFragment _fragment;

  Covariance? _covariance;

  _EnumElementClassMember(this._builder, this._fragment);

  @override
  bool get forSetter => false;

  @override
  int get charOffset => _fragment.nameOffset;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  Uri get fileUri => _fragment.fileUri;

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
    return other is _EnumElementClassMember &&
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
  bool get isSynthesized => false;

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

class _EnumElementFragmentBodyBuilderContext extends BodyBuilderContext {
  final EnumElementFragment _fragment;

  _EnumElementFragmentBodyBuilderContext(
      this._fragment,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      {required bool isDeclarationInstanceMember})
      : super(libraryBuilder, declarationBuilder,
            isDeclarationInstanceMember: isDeclarationInstanceMember);

  @override
  // Coverage-ignore(suite): Not run.
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameOffset => _fragment.nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameLength => _fragment.name.length;

  @override
  // Coverage-ignore(suite): Not run.
  AugmentSuperTarget? get augmentSuperTarget {
    if (_fragment.builder.isAugmentation) {
      return _fragment.builder.augmentSuperTarget;
    }
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  ConstantContext get constantContext {
    return ConstantContext.inferred;
  }
}

class EnumElementDeclaration
    with FieldDeclarationMixin
    implements FieldDeclaration, Inferable, InferredTypeListener {
  final EnumElementFragment _fragment;

  Field? _field;

  late DartType _type = new InferredType(
      libraryBuilder: builder.libraryBuilder,
      typeBuilder: type,
      inferType: inferType,
      computeType: _computeType,
      fileUri: fileUri,
      name: _fragment.name,
      nameOffset: nameOffset,
      nameLength: _fragment.name.length,
      token: _fragment.argumentsBeginToken);

  late final int elementIndex;

  EnumElementDeclaration(this._fragment) {
    _fragment.declaration = this;
    type.registerInferable(this);
    type.registerInferredTypeListener(this);
  }

  DartType _computeType(ClassHierarchyBase hierarchy, Token? token) {
    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;
    SourceEnumBuilder sourceEnumBuilder =
        builder.declarationBuilder as SourceEnumBuilder;
    _buildElement(
        sourceEnumBuilder,
        sourceEnumBuilder.selfType.build(libraryBuilder, TypeUse.enumSelfType),
        libraryBuilder.loader.coreTypes,
        token);
    return fieldType;
  }

  @override
  bool get isEnumElement => true;

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    throw new UnsupportedError("${runtimeType}.buildErroneousInitializer");
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("${runtimeType}.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("${runtimeType}.buildImplicitInitializer");
  }

  @override
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    throw new UnsupportedError("${runtimeType}.buildInitializer");
  }

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      List<Annotatable> annotatables,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    for (Annotatable annotatable in annotatables) {
      buildMetadataForOutlineExpressions(libraryBuilder,
          _fragment.enclosingScope, bodyBuilderContext, annotatable, metadata,
          fileUri: fileUri, createFileUriExpression: createFileUriExpression);
    }
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new _EnumElementFragmentBodyBuilderContext(
        _fragment, builder.libraryBuilder, builder.declarationBuilder,
        isDeclarationInstanceMember: builder.isDeclarationInstanceMember);
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f, FieldReference references,
      {required List<TypeParameter>? classTypeParameters}) {
    _field = new Field.immutable(dummyName,
        type: _type,
        isFinal: false,
        isConst: true,
        isStatic: true,
        fileUri: fileUri,
        fieldReference: references.fieldReference,
        getterReference: references.fieldGetterReference,
        isEnumElement: true)
      ..fileOffset = nameOffset
      ..fileEndOffset = nameOffset;
    nameScheme
        .getFieldMemberName(FieldNameType.Field, _fragment.name,
            isSynthesized: false)
        .attachMember(_field!);
    f(member: _field!, kind: BuiltMemberKind.Field);
  }

  void _buildElement(SourceEnumBuilder sourceEnumBuilder, DartType selfType,
      CoreTypes coreTypes, Token? token) {
    SourceLibraryBuilder libraryBuilder = sourceEnumBuilder.libraryBuilder;
    DartType inferredFieldType = selfType;

    String constant = _fragment.name;
    String constructorName =
        _fragment.constructorReferenceBuilder?.suffix ?? "";
    String fullConstructorNameForErrors =
        _fragment.constructorReferenceBuilder?.fullNameForErrors ??
            _fragment.name;
    int fileOffset =
        _fragment.constructorReferenceBuilder?.charOffset ?? nameOffset;
    constructorName = constructorName == "new" ? "" : constructorName;
    MemberBuilder? constructorBuilder =
        sourceEnumBuilder.nameSpace.lookupConstructor(constructorName);
    // TODO(CFE Team): Should there be a conversion to an invalid expression
    // instead? That's what happens on classes.
    while (constructorBuilder?.next != null) {
      constructorBuilder = constructorBuilder?.next as MemberBuilder;
    }

    ArgumentsImpl arguments;
    List<Expression> enumSyntheticArguments = <Expression>[
      new IntLiteral(elementIndex),
      new StringLiteral(constant),
    ];
    List<DartType>? typeArguments;
    List<TypeBuilder>? typeArgumentBuilders =
        _fragment.constructorReferenceBuilder?.typeArguments;
    if (typeArgumentBuilders != null) {
      typeArguments = <DartType>[];
      for (TypeBuilder typeBuilder in typeArgumentBuilders) {
        typeArguments.add(
            typeBuilder.build(libraryBuilder, TypeUse.constructorTypeArgument));
      }
    }
    if (libraryBuilder.libraryFeatures.enhancedEnums.isEnabled) {
      // We need to create a BodyBuilder to solve the following: 1) if
      // the arguments token is provided, we'll use the BodyBuilder to
      // parse them and perform inference, 2) if the type arguments
      // aren't provided, but required, we'll use it to infer them, and
      // 3) in case of erroneous code the constructor invocation should
      // be built via a body builder to detect potential errors.
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder,
              sourceEnumBuilder.createBodyBuilderContext(),
              _fragment.enclosingScope,
              fileUri);
      bodyBuilder.constantContext = ConstantContext.inferred;

      if (token != null) {
        arguments = bodyBuilder.parseArguments(token);
        // We pass `true` for [allowFurtherDelays] here because the members of
        // the enums are built before the inference, and the resolution of the
        // redirecting factories can't be completed at this moment and
        // therefore should be delayed to another invocation of
        // [BodyBuilder.performBacklogComputations].
        bodyBuilder.performBacklogComputations();

        arguments.positional.insertAll(0, enumSyntheticArguments);
        arguments.argumentsOriginalOrder?.insertAll(0, enumSyntheticArguments);
      } else {
        arguments = new ArgumentsImpl(enumSyntheticArguments);
      }
      if (typeArguments != null) {
        ArgumentsImpl.setNonInferrableArgumentTypes(arguments, typeArguments);
      } else if (sourceEnumBuilder.cls.typeParameters.isNotEmpty) {
        arguments.types.addAll(new List<DartType>.filled(
            sourceEnumBuilder.cls.typeParameters.length, const UnknownType()));
      }
      setParents(enumSyntheticArguments, arguments);
      if (constructorBuilder == null ||
          constructorBuilder is! SourceConstructorBuilder) {
        assert(
            _field!.initializer == null,
            "Initializer has already been computed for $this: "
            "${_field!.initializer}.");
        _field!.initializer = bodyBuilder.buildUnresolvedError(
            fullConstructorNameForErrors, fileOffset,
            arguments: arguments, kind: UnresolvedKind.Constructor)
          ..parent = _field;
      } else {
        Expression initializer = bodyBuilder.buildStaticInvocation(
            constructorBuilder.invokeTarget, arguments,
            constness: Constness.explicitConst,
            charOffset: nameOffset,
            isConstructorInvocation: true);
        ExpressionInferenceResult inferenceResult = bodyBuilder.typeInferrer
            .inferFieldInitializer(
                bodyBuilder, const UnknownType(), initializer);
        initializer = inferenceResult.expression;
        inferredFieldType = inferenceResult.inferredType;
        assert(
            _field!.initializer == null,
            "Initializer has already been computed for $this: "
            "${_field!.initializer}.");
        _field!.initializer = initializer..parent = _field;
      }
    } else {
      arguments = new ArgumentsImpl(enumSyntheticArguments);
      setParents(enumSyntheticArguments, arguments);
      if (constructorBuilder == null ||
          constructorBuilder is! SourceConstructorBuilder ||
          !constructorBuilder.isConst) {
        // This can only occur if there enhanced enum features are used
        // when they are not enabled.
        assert(libraryBuilder.loader.hasSeenError);
        String text = libraryBuilder.loader.target.context
            .format(
                templateConstructorNotFound
                    .withArguments(fullConstructorNameForErrors)
                    .withLocation(fileUri, fileOffset, noLength),
                Severity.error)
            .plain;
        assert(
            _field!.initializer == null,
            "Initializer has already been computed for $this: "
            "${_field!.initializer}.");
        _field!.initializer = new InvalidExpression(text)
          ..fileOffset = nameOffset
          ..parent = _field;
      } else {
        Expression initializer = new ConstructorInvocation(
            constructorBuilder.invokeTarget as Constructor, arguments,
            isConst: true)
          ..fileOffset = nameOffset;
        assert(
            _field!.initializer == null,
            "Initializer has already been computed for $this: "
            "${_field!.initializer}.");
        _field!.initializer = initializer..parent = _field;
      }
    }
    fieldType = inferredFieldType;
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
  shared.Expression? get initializerExpression =>
      throw new UnsupportedError('${runtimeType}.initializerExpression');

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeDeclaredInstanceField => false;

  @override
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isLate => false;

  @override
  List<ClassMember> get localMembers =>
      [new _EnumElementClassMember(builder, _fragment)];

  @override
  List<ClassMember> get localSetters => const [];

  @override
  Member get readTarget => _field!;

  @override
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get _fieldTypeInternal => _type;

  @override
  bool get isConst => true;

  @override
  // Coverage-ignore(suite): Not run.
  void _setCovariantByClassInternal() {
    _field!.isCovariantByClass = true;
  }

  @override
  void set _fieldTypeInternal(DartType value) {
    _type = value;
    _field?.type = value;
  }

  @override
  DartType get fieldType => _type;

  @override
  SourcePropertyBuilder get builder => _fragment.builder;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  TypeBuilder get type => _fragment.type;

  @override
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  // Coverage-ignore(suite): Not run.
  SetterQuality get setterQuality => SetterQuality.Absent;
}
