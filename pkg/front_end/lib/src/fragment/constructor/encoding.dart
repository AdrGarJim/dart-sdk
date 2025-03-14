// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../../api_prototype/lowering_predicates.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/constructor_tearoff_lowering.dart';
import '../../kernel/internal_ast.dart';
import '../../kernel/kernel_helper.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_extension_type_declaration_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_member_builder.dart';
import '../../type_inference/type_schema.dart';
import 'body_builder_context.dart';
import 'declaration.dart';

class RegularConstructorEncoding {
  late final Constructor _constructor;

  late final Procedure? _constructorTearOff;

  final bool _isExternal;

  final bool _isEnumConstructor;

  Statement? bodyInternal;

  RegularConstructorEncoding(
      {required bool isExternal, required bool isEnumConstructor})
      : _isExternal = isExternal,
        _isEnumConstructor = isEnumConstructor;

  Member get readTarget =>
      _constructorTearOff ??
      // The case is need to ensure that the upper bound is [Member] and not
      // [GenericFunction].
      _constructor as Member;

  Reference get readTargetReference =>
      (_constructorTearOff ?? _constructor).reference;

  Member get invokeTarget => _constructor;

  Reference get invokeTargetReference => _constructor.reference;

  void registerFunctionBody(Statement value) {
    function.body = value..parent = function;
  }

  void registerNoBodyConstructor() {
    if (!_isExternal) {
      registerFunctionBody(new EmptyStatement());
    }
  }

  FunctionNode get function => _constructor.function;

  void createNode(
      {required String name,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required Reference? constructorReference,
      required Reference? tearOffReference,
      required Uri fileUri,
      required int startOffset,
      required int fileOffset,
      required int endOffset,
      required bool isSynthetic,
      required bool forAbstractClassOrEnumOrMixin}) {
    _constructor = new Constructor(
        new FunctionNode(_isExternal ? null : new EmptyStatement()),
        name: dummyName,
        fileUri: fileUri,
        reference: constructorReference,
        isSynthetic: isSynthetic)
      ..startFileOffset = startOffset
      ..fileOffset = fileOffset
      ..fileEndOffset = endOffset;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_constructor);
    _constructorTearOff = createConstructorTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        fileUri,
        fileOffset,
        tearOffReference,
        forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin);
  }

  // Coverage-ignore(suite): Not run.
  Member get constructor => _constructor;

  // Coverage-ignore(suite): Not run.
  Procedure? get constructorTearOff => _constructorTearOff;

  List<Initializer> get initializers => _constructor.initializers;

  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required SourceClassBuilder declarationBuilder,
    required Member declarationConstructor,
    required int formalsOffset,
    required bool isConst,
    required TypeBuilder returnType,
    required List<NominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _build(
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        classBuilder: declarationBuilder,
        declarationConstructor: declarationConstructor,
        formalsOffset: formalsOffset,
        isConst: isConst,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
    f(
        member: _constructor,
        tearOff: _constructorTearOff,
        kind: BuiltMemberKind.Constructor);
  }

  bool _hasBeenBuilt = false;

  void _build({
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required SourceClassBuilder classBuilder,
    required Member declarationConstructor,
    required int formalsOffset,
    required bool isConst,
    required TypeBuilder returnType,
    required List<NominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    if (!_hasBeenBuilt) {
      // According to the specification §9.3 the return type of a constructor
      // function is its enclosing class.
      function.asyncMarker = AsyncMarker.Sync;
      buildTypeParametersAndFormals(
          libraryBuilder, function, typeParameters, formals,
          classTypeParameters: null, supportsTypeParameters: false);
      Class enclosingClass = classBuilder.cls;
      List<DartType> typeParameterTypes = <DartType>[];
      for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
        TypeParameter typeParameter = enclosingClass.typeParameters[i];
        typeParameterTypes
            .add(new TypeParameterType.withDefaultNullability(typeParameter));
      }
      InterfaceType type = new InterfaceType(
          enclosingClass, Nullability.nonNullable, typeParameterTypes);
      returnType.registerInferredType(type);
      _constructor.function.fileOffset = formalsOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.function.typeParameters = const <TypeParameter>[];
      _constructor.isConst = isConst;
      _constructor.isExternal = _isExternal;

      if (_constructorTearOff != null) {
        DelayedDefaultValueCloner delayedDefaultValueCloner =
            buildConstructorTearOffProcedure(
                tearOff: _constructorTearOff,
                declarationConstructor: declarationConstructor,
                implementationConstructor: _constructor,
                enclosingDeclarationTypeParameters:
                    classBuilder.cls.typeParameters,
                libraryBuilder: libraryBuilder);
        delayedDefaultValueCloners.add(delayedDefaultValueCloner);
      }

      _hasBeenBuilt = true;
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals) {
        if (formal.type is InferableTypeBuilder &&
            (formal.isInitializingFormal || formal.isSuperInitializingFormal)) {
          formal.variable!.type = const UnknownType();
          needsInference = true;
        } else if (!formal.hasDeclaredInitializer &&
            formal.isSuperInitializingFormal) {
          needsInference = true;
        }
      }
      if (needsInference) {
        libraryBuilder.loader
            .registerConstructorToBeInferred(_constructor, constructorBuilder);
      }
    }
  }

  void prepareInitializers() {
    // For const constructors we parse initializers already at the outlining
    // stage, there is no easy way to make body building stage skip initializer
    // parsing, so we simply clear parsed initializers and rebuild them
    // again.
    // For when doing an experimental incremental compilation they are also
    // potentially done more than once (because it rebuilds the bodies of an old
    // compile), and so we also clear them.
    // Note: this method clears both initializers from the target Kernel node
    // and internal state associated with parsing initializers.
    _constructor.initializers = [];
    //redirectingInitializer = null;
    //superInitializer = null;
  }

  void prependInitializer(Initializer initializer) {
    initializer.parent = _constructor;
    _constructor.initializers.insert(0, initializer);
  }

  void becomeNative() {
    _constructor.isExternal = true;
  }

  VariableDeclaration getFormalParameter(int index) {
    if (_isEnumConstructor) {
      // Skip synthetic parameters for index and name.
      index += 2;
    }
    if (index < function.positionalParameters.length) {
      return function.positionalParameters[index];
    } else {
      index -= function.positionalParameters.length;
      assert(index < function.namedParameters.length);
      return function.namedParameters[index];
    }
  }

  VariableDeclaration? getTearOffParameter(int index) {
    Procedure? constructorTearOff = _constructorTearOff;
    if (constructorTearOff != null) {
      if (index < constructorTearOff.function.positionalParameters.length) {
        return constructorTearOff.function.positionalParameters[index];
      } else {
        index -= constructorTearOff.function.positionalParameters.length;
        if (index < constructorTearOff.function.namedParameters.length) {
          return constructorTearOff.function.namedParameters[index];
        }
      }
    }
    return null;
  }

  bool _hasAddedDefaultValueCloners = false;

  void addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder}) {
    if (!_hasAddedDefaultValueCloners) {
      // If this constructor formals are part of a cyclic dependency this
      // might be called more than once.
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          superTarget, _constructor,
          positionalSuperParameters: positionalSuperParameters ?? const <int>[],
          namedSuperParameters: namedSuperParameters ?? const <String>[],
          isOutlineNode: true,
          libraryBuilder: libraryBuilder));
      if (_constructorTearOff != null) {
        delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
            superTarget, _constructorTearOff,
            positionalSuperParameters:
                positionalSuperParameters ?? const <int>[],
            namedSuperParameters: namedSuperParameters ?? const <String>[],
            isOutlineNode: true,
            libraryBuilder: libraryBuilder));
      }
      _hasAddedDefaultValueCloners = true;
    }
  }

  BodyBuilderContext createBodyBuilderContext(
      SourceConstructorBuilderImpl constructorBuilder,
      ConstructorDeclaration constructorDeclaration) {
    return new ConstructorBodyBuilderContext(
        constructorBuilder, constructorDeclaration, _constructor);
  }
}

class ExtensionTypeConstructorEncoding {
  late final Procedure _constructor;

  late final Procedure? _constructorTearOff;

  final bool _isExternal;

  Statement? bodyInternal;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisVariable] holds the synthetically added `this`
  /// parameter.
  VariableDeclaration? _thisVariable;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisTypeParameters] holds the type parameters copied
  /// from the extension/extension type declaration.
  List<TypeParameter>? _thisTypeParameters;

  List<Initializer> initializers = [];

  ExtensionTypeConstructorEncoding({required bool isExternal})
      : _isExternal = isExternal;

  Member get readTarget =>
      _constructorTearOff ?? // Coverage-ignore(suite): Not run.
      _constructor;

  Reference get readTargetReference =>
      (_constructorTearOff ?? // Coverage-ignore(suite): Not run.
              _constructor)
          .reference;

  Member get invokeTarget => _constructor;

  Reference get invokeTargetReference => _constructor.reference;

  void registerFunctionBody(Statement value) {
    function.body = value..parent = function;
  }

  void registerNoBodyConstructor() {
    if (!_hasBuiltBody && !_isExternal) {
      registerFunctionBody(new EmptyStatement());
    }
  }

  FunctionNode get function => _constructor.function;

  void createNode(
      {required String name,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required Reference? constructorReference,
      required Reference? tearOffReference,
      required Uri fileUri,
      required int fileOffset,
      required int endOffset,
      required bool forAbstractClassOrEnumOrMixin}) {
    _constructor = new Procedure(dummyName, ProcedureKind.Method,
        new FunctionNode(_isExternal ? null : new EmptyStatement()),
        fileUri: fileUri, reference: constructorReference)
      ..fileOffset = fileOffset
      ..fileEndOffset = endOffset;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_constructor);
    _constructorTearOff = createConstructorTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        fileUri,
        fileOffset,
        tearOffReference,
        forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
        forceCreateLowering: true)
      ?..isExtensionTypeMember = true;
  }

  // Coverage-ignore(suite): Not run.
  Member get constructor => _constructor;

  // Coverage-ignore(suite): Not run.
  Procedure? get constructorTearOff => _constructorTearOff;

  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required SourceExtensionTypeDeclarationBuilder declarationBuilder,
    required Member declarationConstructor,
    required int fileOffset,
    required int formalsOffset,
    required bool isConst,
    required TypeBuilder returnType,
    required List<NominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _build(
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        declarationConstructor: declarationConstructor,
        fileOffset: fileOffset,
        formalsOffset: formalsOffset,
        isConst: isConst,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
    f(
        member: _constructor,
        tearOff: _constructorTearOff,
        kind: BuiltMemberKind.ExtensionTypeConstructor);
  }

  bool _hasBeenBuilt = false;

  void _build({
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required SourceExtensionTypeDeclarationBuilder declarationBuilder,
    required Member declarationConstructor,
    required int fileOffset,
    required int formalsOffset,
    required bool isConst,
    required TypeBuilder returnType,
    required List<NominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    if (!_hasBeenBuilt) {
      // According to the specification §9.3 the return type of a constructor
      // function is its enclosing class.
      function.asyncMarker = AsyncMarker.Sync;
      buildTypeParametersAndFormals(
          libraryBuilder, function, typeParameters, formals,
          classTypeParameters: null, supportsTypeParameters: true);

      if (declarationBuilder.typeParameters != null) {
        int count = declarationBuilder.typeParameters!.length;
        _thisTypeParameters = new List<TypeParameter>.generate(
            count, (int index) => function.typeParameters[index],
            growable: false);
      }
      List<DartType> typeArguments;
      if (_thisTypeParameters != null) {
        typeArguments = [
          for (TypeParameter parameter in _thisTypeParameters!)
            new TypeParameterType.withDefaultNullability(parameter)
        ];
      } else {
        typeArguments = [];
      }

      ExtensionTypeDeclaration extensionTypeDeclaration =
          declarationBuilder.extensionTypeDeclaration;
      _thisVariable = new VariableDeclarationImpl(syntheticThisName,
          isFinal: true,
          type: new ExtensionType(
              extensionTypeDeclaration, Nullability.nonNullable, typeArguments))
        ..fileOffset = fileOffset
        ..isLowered = true;

      List<DartType> typeParameterTypes = <DartType>[];
      for (int i = 0; i < function.typeParameters.length; i++) {
        TypeParameter typeParameter = function.typeParameters[i];
        typeParameterTypes
            .add(new TypeParameterType.withDefaultNullability(typeParameter));
      }
      ExtensionType type = new ExtensionType(extensionTypeDeclaration,
          Nullability.nonNullable, typeParameterTypes);
      returnType.registerInferredType(type);
      _constructor.function.fileOffset = formalsOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.isConst = isConst;
      _constructor.isExternal = _isExternal;
      _constructor.isStatic = true;
      _constructor.isExtensionTypeMember = true;

      if (_constructorTearOff != null) {
        delayedDefaultValueCloners.add(buildConstructorTearOffProcedure(
            tearOff: _constructorTearOff,
            declarationConstructor: declarationConstructor,
            implementationConstructor: _constructor,
            libraryBuilder: libraryBuilder));
      }

      _hasBeenBuilt = true;
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals) {
        if (formal.type is InferableTypeBuilder &&
            (formal.isInitializingFormal || formal.isSuperInitializingFormal)) {
          formal.variable!.type = const UnknownType();
          needsInference = true;
        } else if (!formal.hasDeclaredInitializer &&
            formal.isSuperInitializingFormal) {
          needsInference = true;
        }
      }
      if (needsInference) {
        libraryBuilder.loader
            .registerConstructorToBeInferred(_constructor, constructorBuilder);
      }
    }
  }

  VariableDeclaration? get thisVariable {
    assert(_thisVariable != null,
        "ProcedureBuilder.thisVariable has not been set.");
    return _thisVariable;
  }

  List<TypeParameter>? get thisTypeParameters {
    // Use [_thisVariable] as marker for whether this type parameters have
    // been computed.
    assert(_thisVariable != null,
        "ProcedureBuilder.thisTypeParameters has not been set.");
    return _thisTypeParameters;
  }

  void prepareInitializers() {
    // For const constructors we parse initializers already at the outlining
    // stage, there is no easy way to make body building stage skip initializer
    // parsing, so we simply clear parsed initializers and rebuild them
    // again.
    // For when doing an experimental incremental compilation they are also
    // potentially done more than once (because it rebuilds the bodies of an old
    // compile), and so we also clear them.
    // Note: this method clears both initializers from the target Kernel node
    // and internal state associated with parsing initializers.
    initializers = [];
    //redirectingInitializer = null;
    //superInitializer = null;
  }

  void prependInitializer(Initializer initializer) {
    initializers.insert(0, initializer);
  }

  VariableDeclaration getFormalParameter(int index) {
    if (index < function.positionalParameters.length) {
      return function.positionalParameters[index];
    } else {
      index -= function.positionalParameters.length;
      assert(index < function.namedParameters.length);
      return function.namedParameters[index];
    }
  }

  VariableDeclaration? getTearOffParameter(int index) {
    Procedure? constructorTearOff = _constructorTearOff;
    if (constructorTearOff != null) {
      if (index < constructorTearOff.function.positionalParameters.length) {
        return constructorTearOff.function.positionalParameters[index];
      } else {
        index -= constructorTearOff.function.positionalParameters.length;
        if (index < constructorTearOff.function.namedParameters.length) {
          return constructorTearOff.function.namedParameters[index];
        }
      }
    }
    return null;
  }

  bool _hasBuiltBody = false;

  void buildBody() {
    if (_hasBuiltBody) {
      return;
    }
    if (!_isExternal) {
      VariableDeclaration thisVariable = this.thisVariable!;
      List<Statement> statements = [thisVariable];
      ExtensionTypeInitializerToStatementConverter visitor =
          new ExtensionTypeInitializerToStatementConverter(
              statements, thisVariable);
      for (Initializer initializer in initializers) {
        initializer.accept(visitor);
      }
      if (function.body != null && function.body is! EmptyStatement) {
        statements.add(function.body!);
      }
      statements.add(new ReturnStatement(new VariableGet(thisVariable)));
      registerFunctionBody(new Block(statements));
    }
    _hasBuiltBody = true;
  }

  BodyBuilderContext createBodyBuilderContext(
      SourceConstructorBuilderImpl constructorBuilder,
      ConstructorDeclaration constructorDeclaration) {
    return new ConstructorBodyBuilderContext(
        constructorBuilder, constructorDeclaration, _constructor);
  }
}
