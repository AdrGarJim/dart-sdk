// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../../base/identifiers.dart';
import '../../base/problems.dart' show unexpected, unhandled;
import '../../base/scope.dart';
import '../../builder/builder.dart';
import '../../builder/constructor_reference_builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/function_builder.dart';
import '../../builder/member_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../codes/cfe_codes.dart';
import '../../dill/dill_extension_type_member_builder.dart';
import '../../dill/dill_member_builder.dart';
import '../../fragment/fragment.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/constructor_tearoff_lowering.dart';
import '../../kernel/kernel_helper.dart';
import '../../source/name_scheme.dart';
import '../../source/redirecting_factory_body.dart';
import '../../source/source_factory_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../../source/source_loader.dart'
    show CompilationPhaseForProblemReporting, SourceLoader;
import '../../source/source_member_builder.dart';
import '../../source/source_type_parameter_builder.dart';
import '../../type_inference/inference_helper.dart';
import '../../type_inference/type_inferrer.dart';
import '../../type_inference/type_schema.dart';

class FactoryEncoding implements InferredTypeListener {
  late final Procedure _procedure;
  late final Procedure? _tearOff;

  final FactoryFragment _fragment;

  AsyncMarker _asyncModifier;

  final List<SourceNominalParameterBuilder>? typeParameters;

  final TypeBuilder returnType;

  DelayedDefaultValueCloner? _delayedDefaultValueCloner;

  List<DartType>? _redirectionTypeArguments;

  FreshTypeParameters? _tearOffTypeParameters;

  final ConstructorReferenceBuilder? _redirectionTarget;

  FactoryEncoding(
    this._fragment, {
    required this.typeParameters,
    required this.returnType,
    required ConstructorReferenceBuilder? redirectionTarget,
  })  : _redirectionTarget = redirectionTarget,
        _asyncModifier = redirectionTarget != null
            ? AsyncMarker.Sync
            : _fragment.asyncModifier;

  void createNode({
    required String name,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required Reference? procedureReference,
    required Reference? tearOffReference,
  }) {
    _procedure = new Procedure(
        dummyName,
        nameScheme.isExtensionTypeMember
            ? ProcedureKind.Method
            : ProcedureKind.Factory,
        new FunctionNode(null)
          ..asyncMarker = _asyncModifier
          ..dartAsyncMarker = _asyncModifier,
        fileUri: _fragment.fileUri,
        reference: procedureReference)
      ..fileStartOffset = _fragment.startOffset
      ..fileOffset = _fragment.fullNameOffset
      ..fileEndOffset = _fragment.endOffset
      ..isExtensionTypeMember = nameScheme.isExtensionTypeMember;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_procedure);
    _tearOff = createFactoryTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        _fragment.fileUri,
        _fragment.fullNameOffset,
        tearOffReference,
        forceCreateLowering: nameScheme.isExtensionTypeMember)
      ?..isExtensionTypeMember = nameScheme.isExtensionTypeMember;
    returnType.registerInferredTypeListener(this);
  }

  Procedure get procedure => _procedure;

  Procedure? get tearOff => _tearOff;

  @override
  // Coverage-ignore(suite): Not run.
  void onInferredType(DartType type) {
    _procedure.function.returnType = type;
  }

  void set asyncModifier(AsyncMarker newModifier) {
    _asyncModifier = newModifier;
    _procedure.function.asyncMarker = _asyncModifier;
    _procedure.function.dartAsyncMarker = _asyncModifier;
  }

  List<DartType>? get redirectionTypeArguments {
    assert(_redirectionTarget != null);
    return _redirectionTypeArguments;
  }

  void set redirectionTypeArguments(List<DartType>? value) {
    assert(_redirectionTarget != null);
    _redirectionTypeArguments = value;
  }

  void buildOutlineNodes(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required BuildNodesCallback f,
      required bool isConst}) {
    _procedure.function.asyncMarker = _asyncModifier;
    if (_redirectionTarget == null &&
        !_fragment.modifiers.isAbstract &&
        !_fragment.modifiers.isExternal) {
      _procedure.function.body = new EmptyStatement()
        ..parent = _procedure.function;
    }
    buildTypeParametersAndFormals(
        libraryBuilder, _procedure.function, typeParameters, _fragment.formals,
        classTypeParameters: null, supportsTypeParameters: true);
    if (returnType is! InferableTypeBuilder) {
      _procedure.function.returnType =
          returnType.build(libraryBuilder, TypeUse.returnType);
    }
    _procedure.function.fileOffset = _fragment.formalsOffset;
    _procedure.function.fileEndOffset = _procedure.fileEndOffset;
    _procedure.isAbstract = _fragment.modifiers.isAbstract;
    _procedure.isExternal = _fragment.modifiers.isExternal;
    // TODO(johnniwinther): DDC platform currently relies on the ability to
    // patch a const constructor with a non-const patch. Remove this and enforce
    // equal constness on origin and patch.
    _procedure.isConst = isConst;
    _procedure.isStatic = _fragment.modifiers.isStatic;

    if (_redirectionTarget != null) {
      if (_redirectionTarget.typeArguments != null) {
        redirectionTypeArguments = new List<DartType>.generate(
            _redirectionTarget.typeArguments!.length,
            (int i) => _redirectionTarget.typeArguments![i]
                .build(libraryBuilder, TypeUse.redirectionTypeArgument),
            growable: false);
      }
      if (_tearOff != null) {
        _tearOffTypeParameters =
            buildRedirectingFactoryTearOffProcedureParameters(
                tearOff: _tearOff,
                implementationConstructor: _procedure,
                libraryBuilder: libraryBuilder);
      }
    } else {
      if (_tearOff != null) {
        _delayedDefaultValueCloner = buildConstructorTearOffProcedure(
            tearOff: _tearOff,
            declarationConstructor: _procedure,
            implementationConstructor: _procedure,
            libraryBuilder: libraryBuilder);
      }
    }
    f(
        member: _procedure,
        tearOff: _tearOff,
        kind: factoryBuilder.isExtensionTypeMember
            ? (_redirectionTarget != null
                ? BuiltMemberKind.ExtensionTypeRedirectingFactory
                : BuiltMemberKind.ExtensionTypeFactory)
            : (_redirectionTarget != null
                ? BuiltMemberKind.RedirectingFactory
                : BuiltMemberKind.Factory));
  }

  void buildOutlineExpressions(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    if (_delayedDefaultValueCloner != null) {
      delayedDefaultValueCloners.add(_delayedDefaultValueCloner!);
    }
  }

  void inferRedirectionTarget(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    if (_redirectionTarget == null) {
      return;
    }

    RedirectingFactoryTarget? redirectingFactoryTarget =
        _procedure.function.redirectingFactoryTarget;
    if (redirectingFactoryTarget == null) {
      // The error is reported elsewhere.
      return;
    }
    List<DartType>? typeArguments = redirectingFactoryTarget.typeArguments;
    Member? target = redirectingFactoryTarget.target;
    if (typeArguments != null && typeArguments.any((t) => t is UnknownType)) {
      TypeInferrer inferrer = libraryBuilder.loader.typeInferenceEngine
          .createLocalTypeInferrer(
              _fragment.fileUri,
              declarationBuilder.thisType,
              libraryBuilder,
              _fragment.typeParameterScope,
              null);
      InferenceHelper helper = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(libraryBuilder,
              bodyBuilderContext, _fragment.enclosingScope, _fragment.fileUri);
      Builder? targetBuilder = _redirectionTarget.target;

      if (targetBuilder is SourceMemberBuilder) {
        // Ensure that target has been built.
        targetBuilder.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      }
      if (targetBuilder is FunctionBuilder) {
        target = targetBuilder.invokeTarget!;
      }
      // Coverage-ignore(suite): Not run.
      else if (targetBuilder is DillMemberBuilder) {
        target = targetBuilder.invokeTarget!;
      } else {
        unhandled("${targetBuilder.runtimeType}", "buildOutlineExpressions",
            _fragment.fullNameOffset, _fragment.fileUri);
      }

      typeArguments = inferrer.inferRedirectingFactoryTypeArguments(
          helper,
          _procedure.function.returnType,
          _procedure.function,
          _fragment.fullNameOffset,
          target,
          target.function!.computeFunctionType(Nullability.nonNullable));
      if (typeArguments == null) {
        assert(libraryBuilder.loader.assertProblemReportedElsewhere(
            "RedirectingFactoryTarget.buildOutlineExpressions",
            expectedPhase: CompilationPhaseForProblemReporting.outline));
        // Use 'dynamic' for recovery.
        typeArguments = new List<DartType>.filled(
            declarationBuilder.typeParametersCount, const DynamicType(),
            growable: true);
      }

      _procedure.function.body = createRedirectingFactoryBody(
          target, typeArguments, _procedure.function);
      _procedure.function.body!.parent = _procedure.function;
      _procedure.function.redirectingFactoryTarget =
          new RedirectingFactoryTarget(target, typeArguments);
    }

    Set<Procedure> seenTargets = {};
    while (target is Procedure && target.isRedirectingFactory) {
      if (!seenTargets.add(target)) {
        // Cyclic dependency.
        target = null;
        break;
      }
      RedirectingFactoryTarget redirectingFactoryTarget =
          target.function.redirectingFactoryTarget!;
      if (typeArguments != null) {
        Substitution substitution = Substitution.fromPairs(
            target.function.typeParameters, typeArguments);
        typeArguments = redirectingFactoryTarget.typeArguments
            ?.map(substitution.substituteType)
            .toList();
      } else {
        // Coverage-ignore-block(suite): Not run.
        typeArguments = redirectingFactoryTarget.typeArguments;
      }
      target = redirectingFactoryTarget.target;
    }

    if (target is Constructor ||
        target is Procedure &&
            (target.isFactory || target.isExtensionTypeMember)) {
      // Coverage-ignore(suite): Not run.
      typeArguments ??= [];
      if (_tearOff != null) {
        delayedDefaultValueCloners.add(buildRedirectingFactoryTearOffBody(
            _tearOff,
            target!,
            typeArguments,
            _tearOffTypeParameters!,
            libraryBuilder));
      }
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          target!, _procedure,
          libraryBuilder: libraryBuilder, identicalSignatures: false));
    }
  }

  void resolveRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder}) {
    ConstructorReferenceBuilder? redirectionTarget = _redirectionTarget;
    if (redirectionTarget != null) {
      // Compute the immediate redirection target, not the effective.
      List<TypeBuilder>? typeArguments = redirectionTarget.typeArguments;
      Builder? target = redirectionTarget.target;
      if (typeArguments != null && target is MemberBuilder) {
        TypeName redirectionTargetName = redirectionTarget.typeName;
        if (redirectionTargetName.qualifier == null) {
          // Do nothing. This is the case of an identifier followed by
          // type arguments, such as the following:
          //   B<T>
          //   B<T>.named
        } else {
          if (target.name.isEmpty) {
            // Do nothing. This is the case of a qualified
            // non-constructor prefix (for example, with a library
            // qualifier) followed by type arguments, such as the
            // following:
            //   lib.B<T>
          } else if (target.name != redirectionTargetName.name) {
            // Do nothing. This is the case of a qualified
            // non-constructor prefix followed by type arguments followed
            // by a constructor name, such as the following:
            //   lib.B<T>.named
          } else {
            // TODO(cstefantsova,johnniwinther): Handle this in case in
            // ConstructorReferenceBuilder.resolveIn and unify with other
            // cases of handling of type arguments after constructor
            // names.
            libraryBuilder.addProblem(
                messageConstructorWithTypeArguments,
                redirectionTargetName.nameOffset,
                redirectionTargetName.nameLength,
                _fragment.fileUri);
          }
        }
      }

      Builder? targetBuilder = redirectionTarget.target;
      Member? targetNode;
      if (targetBuilder is FunctionBuilder) {
        targetNode = targetBuilder.invokeTarget!;
      } else if (targetBuilder is DillMemberBuilder) {
        targetNode = targetBuilder.invokeTarget!;
      } else if (targetBuilder is AmbiguousBuilder) {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            message: templateDuplicatedDeclarationUse
                .withArguments(redirectionTarget.fullNameForErrors),
            fileOffset: redirectionTarget.charOffset,
            length: noLength,
            fileUri: redirectionTarget.fileUri);
      } else {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            message: templateRedirectionTargetNotFound
                .withArguments(redirectionTarget.fullNameForErrors),
            fileOffset: redirectionTarget.charOffset,
            length: noLength,
            fileUri: redirectionTarget.fileUri);
      }
      if (targetNode != null &&
          targetNode is Constructor &&
          targetNode.enclosingClass.isAbstract) {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            message: templateAbstractRedirectedClassInstantiation
                .withArguments(redirectionTarget.fullNameForErrors),
            fileOffset: redirectionTarget.charOffset,
            length: noLength,
            fileUri: redirectionTarget.fileUri);
        targetNode = null;
      }
      if (targetNode != null &&
          targetNode is Constructor &&
          targetNode.enclosingClass.isEnum) {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            message: messageEnumFactoryRedirectsToConstructor,
            fileOffset: redirectionTarget.charOffset,
            length: noLength,
            fileUri: redirectionTarget.fileUri);
        targetNode = null;
      }
      if (targetNode != null) {
        List<DartType>? typeArguments = redirectionTypeArguments;
        if (typeArguments == null) {
          int typeArgumentCount;
          if (targetBuilder!.isExtensionTypeMember) {
            ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
                targetBuilder.parent as ExtensionTypeDeclarationBuilder;
            typeArgumentCount =
                extensionTypeDeclarationBuilder.typeParametersCount;
          } else {
            typeArgumentCount =
                targetNode.enclosingClass!.typeParameters.length;
          }
          typeArguments =
              new List<DartType>.filled(typeArgumentCount, const UnknownType());
        }
        _setRedirectingFactoryBody(
            libraryBuilder: libraryBuilder,
            target: targetNode,
            typeArguments: typeArguments);
      }
    }
  }

  void _setRedirectingFactoryBody(
      {required SourceLibraryBuilder libraryBuilder,
      required Member target,
      required List<DartType> typeArguments}) {
    if (_procedure.function.body != null) {
      unexpected("null", "${_procedure.function.body.runtimeType}",
          _fragment.fullNameOffset, _fragment.fileUri);
    }

    // Ensure that constant factories only have constant targets/bodies.
    if (_fragment.modifiers.isConst && !target.isConst) {
      // Coverage-ignore-block(suite): Not run.
      libraryBuilder.addProblem(messageConstFactoryRedirectionToNonConst,
          _fragment.fullNameOffset, noLength, _fragment.fileUri);
    }

    _procedure.function.body =
        createRedirectingFactoryBody(target, typeArguments, _procedure.function)
          ..parent = _procedure.function;
    _procedure.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget(target, typeArguments);
  }

  void _addProblemForRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required Message message,
      required int fileOffset,
      required int length,
      required Uri fileUri}) {
    libraryBuilder.addProblem(message, fileOffset, length, fileUri);
    String text = libraryBuilder.loader.target.context
        .format(
            message.withLocation(fileUri, fileOffset, length), Severity.error)
        .plain;
    _setRedirectingFactoryError(message: text);
  }

  void _setRedirectingFactoryError({required String message}) {
    assert(_redirectionTarget != null);

    setBody(createRedirectingFactoryErrorBody(message));
    _procedure.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget.error(message);
    if (_tearOff != null) {
      _tearOff.function.body = createRedirectingFactoryErrorBody(message)
        ..parent = _tearOff.function;
    }
  }

  /// Checks this factory builder if it is for a redirecting factory.
  void checkRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required TypeEnvironment typeEnvironment}) {
    assert(_redirectionTarget != null);

    // Check that factory declaration is not cyclic.
    if (_isCyclicRedirectingFactory(factoryBuilder)) {
      _addProblemForRedirectingFactory(
          libraryBuilder: libraryBuilder,
          message: templateCyclicRedirectingFactoryConstructors
              .withArguments("${factoryBuilder.declarationBuilder.name}"
                  "${_fragment.name == '' ? '' : '.${_fragment.name}'}"),
          fileOffset: _fragment.fullNameOffset,
          length: noLength,
          fileUri: _fragment.fileUri);
      return;
    }

    // The factory type cannot contain any type parameters other than those of
    // its enclosing class, because constructors cannot specify type parameters
    // of their own.
    FunctionType factoryType =
        _procedure.function.computeThisFunctionType(Nullability.nonNullable);
    FunctionType? redirecteeType = _computeRedirecteeType(
        libraryBuilder: libraryBuilder, typeEnvironment: typeEnvironment);
    Map<TypeParameter, DartType> substitutionMap = {};
    for (int i = 0; i < factoryType.typeParameters.length; i++) {
      TypeParameter functionTypeParameter =
          _procedure.function.typeParameters[i];
      substitutionMap[functionTypeParameter] =
          new StructuralParameterType.withDefaultNullability(
              factoryType.typeParameters[i]);
    }
    redirecteeType = redirecteeType != null
        ? substitute(redirecteeType, substitutionMap) as FunctionType
        : null;

    // TODO(hillerstrom): It would be preferable to know whether a failure
    // happened during [_computeRedirecteeType].
    if (redirecteeType == null) {
      return;
    }

    Builder? redirectionTargetBuilder = _redirectionTarget!.target;
    if (redirectionTargetBuilder is SourceFactoryBuilder &&
        redirectionTargetBuilder.redirectionTarget != null) {
      redirectionTargetBuilder.checkRedirectingFactories(typeEnvironment);
      String? errorMessage = redirectionTargetBuilder
          .function.redirectingFactoryTarget?.errorMessage;
      if (errorMessage != null) {
        _setRedirectingFactoryError(message: errorMessage);
      }
    }

    Builder? redirectionTargetParent = _redirectionTarget.target?.parent;
    bool redirectingTargetParentIsEnum = redirectionTargetParent is ClassBuilder
        ? redirectionTargetParent.isEnum
        : false;
    if (!((factoryBuilder.classBuilder?.cls.isEnum ?? false) &&
        (_redirectionTarget.target?.isConstructor ?? false) &&
        redirectingTargetParentIsEnum)) {
      // Check whether [redirecteeType] <: [factoryType].
      FunctionType factoryTypeWithoutTypeParameters =
          factoryType.withoutTypeParameters;
      if (!typeEnvironment.isSubtypeOf(
          redirecteeType,
          factoryTypeWithoutTypeParameters,
          SubtypeCheckMode.withNullabilities)) {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            message: templateIncompatibleRedirecteeFunctionType.withArguments(
                redirecteeType, factoryTypeWithoutTypeParameters),
            fileOffset: _redirectionTarget.charOffset,
            length: noLength,
            fileUri: _redirectionTarget.fileUri);
      }
    } else {
      // Redirection to generative enum constructors is forbidden.
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "RedirectingFactoryBuilder._checkRedirectingFactory: "
          "Redirection to generative enum constructor.",
          expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding));
    }
  }

  // Computes the function type of a given redirection target. Returns [null] if
  // the type of the target could not be computed.
  FunctionType? _computeRedirecteeType(
      {required SourceLibraryBuilder libraryBuilder,
      required TypeEnvironment typeEnvironment}) {
    assert(_redirectionTarget != null);
    ConstructorReferenceBuilder redirectionTarget = _redirectionTarget!;
    Builder? targetBuilder = redirectionTarget.target;
    FunctionNode targetNode;
    if (targetBuilder == null) return null;
    if (targetBuilder is FunctionBuilder) {
      targetNode = targetBuilder.function;
    } else if (targetBuilder is DillExtensionTypeFactoryBuilder) {
      targetNode = targetBuilder.member.function!;
    } else if (targetBuilder is AmbiguousBuilder) {
      // Multiple definitions with the same name: An error has already been
      // issued.
      // TODO(http://dartbug.com/35294): Unfortunate error; see also
      // https://dart-review.googlesource.com/c/sdk/+/85390/.
      return null;
    } else {
      unhandled("${targetBuilder.runtimeType}", "computeRedirecteeType",
          _fragment.fullNameOffset, _fragment.fileUri);
    }

    List<DartType>? typeArguments =
        _procedure.function.redirectingFactoryTarget!.typeArguments;
    FunctionType targetFunctionType =
        targetNode.computeFunctionType(Nullability.nonNullable);
    if (typeArguments != null &&
        targetFunctionType.typeParameters.length != typeArguments.length) {
      _addProblemForRedirectingFactory(
          libraryBuilder: libraryBuilder,
          message: templateTypeArgumentMismatch
              .withArguments(targetFunctionType.typeParameters.length),
          fileOffset: redirectionTarget.charOffset,
          length: noLength,
          fileUri: redirectionTarget.fileUri);
      return null;
    }

    // Compute the substitution of the target class type parameters if
    // [redirectionTarget] has any type arguments.
    FunctionTypeInstantiator? instantiator;
    bool hasProblem = false;
    if (typeArguments != null && typeArguments.length > 0) {
      instantiator = new FunctionTypeInstantiator.fromIterables(
          targetFunctionType.typeParameters, typeArguments);
      for (int i = 0; i < targetFunctionType.typeParameters.length; i++) {
        StructuralParameter typeParameter =
            targetFunctionType.typeParameters[i];
        DartType typeParameterBound =
            instantiator.substitute(typeParameter.bound);
        DartType typeArgument = typeArguments[i];
        // Check whether the [typeArgument] respects the bounds of
        // [typeParameter].
        if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
            SubtypeCheckMode.ignoringNullabilities)) {
          // Coverage-ignore-block(suite): Not run.
          _addProblemForRedirectingFactory(
              libraryBuilder: libraryBuilder,
              message: templateRedirectingFactoryIncompatibleTypeArgument
                  .withArguments(typeArgument, typeParameterBound),
              fileOffset: redirectionTarget.charOffset,
              length: noLength,
              fileUri: redirectionTarget.fileUri);
          hasProblem = true;
        } else {
          if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
              SubtypeCheckMode.withNullabilities)) {
            _addProblemForRedirectingFactory(
                libraryBuilder: libraryBuilder,
                message: templateRedirectingFactoryIncompatibleTypeArgument
                    .withArguments(typeArgument, typeParameterBound),
                fileOffset: redirectionTarget.charOffset,
                length: noLength,
                fileUri: redirectionTarget.fileUri);
            hasProblem = true;
          }
        }
      }
    } else if (typeArguments == null &&
        targetFunctionType.typeParameters.length > 0) {
      // TODO(hillerstrom): In this case, we need to perform type inference on
      // the redirectee to obtain actual type arguments which would allow the
      // following program to type check:
      //
      //    class A<T> {
      //       factory A() = B;
      //    }
      //    class B<T> implements A<T> {
      //       B();
      //    }
      //
      return null;
    }

    // Substitute if necessary.
    targetFunctionType = instantiator == null
        ? targetFunctionType
        : (instantiator.substitute(targetFunctionType.withoutTypeParameters)
            as FunctionType);

    return hasProblem ? null : targetFunctionType;
  }

  static bool _isCyclicRedirectingFactory(SourceFactoryBuilder factory) {
    assert(factory.redirectionTarget != null);
    // We use the [tortoise and hare algorithm]
    // (https://en.wikipedia.org/wiki/Cycle_detection#Tortoise_and_hare) to
    // handle cycles.
    Builder? tortoise = factory;
    Builder? hare = factory.redirectionTarget!.target;
    if (hare == factory) {
      return true;
    }
    while (tortoise != hare) {
      // Hare moves 2 steps forward.
      if (hare is! SourceFactoryBuilder || hare.redirectionTarget == null) {
        return false;
      }
      hare = hare.redirectionTarget!.target;
      if (hare == factory) {
        return true;
      }
      if (hare is! SourceFactoryBuilder || hare.redirectionTarget == null) {
        return false;
      }
      hare = hare.redirectionTarget!.target;
      if (hare == factory) {
        return true;
      }
      // Tortoise moves one step forward. No need to test type of tortoise
      // as it follows hare which already checked types.
      tortoise = (tortoise as SourceFactoryBuilder).redirectionTarget!.target;
    }
    // Cycle found, but original factory doesn't belong to a cycle.
    return false;
  }

  void setBody(Statement value) {
    _procedure.function.body = value..parent = _procedure.function;
  }

  void becomeNative(SourceLoader loader) {
    _procedure.isExternal = true;
  }

  // Coverage-ignore(suite): Not run.
  bool get isNative => _fragment.nativeMethodName != null;

  FunctionNode get function => _procedure.function;

  FormalParameterBuilder? getFormal(Identifier identifier) {
    if (_fragment.formals != null) {
      for (FormalParameterBuilder formal in _fragment.formals!) {
        if (formal.isWildcard &&
            identifier.name == '_' &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
        if (formal.name == identifier.name &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
      }
      // Coverage-ignore(suite): Not run.
      // If we have any formals we should find the one we're looking for.
      assert(false, "$identifier not found in ${_fragment.formals}");
    }
    return null;
  }

  VariableDeclaration? getTearOffParameter(int index) {
    if (_tearOff != null) {
      if (index < _tearOff.function.positionalParameters.length) {
        return _tearOff.function.positionalParameters[index];
      } else {
        index -= _tearOff.function.positionalParameters.length;
        if (index < _tearOff.function.namedParameters.length) {
          return _tearOff.function.namedParameters[index];
        }
      }
    }
    return null;
  }
}
