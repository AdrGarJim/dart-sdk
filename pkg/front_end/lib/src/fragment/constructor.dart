// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ConstructorFragment implements Fragment, FunctionFragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charOpenParenOffset;
  final int charEndOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final OmittedTypeBuilder returnType;
  final List<NominalVariableBuilder>? typeParameters;
  final List<FormalParameterBuilder>? formals;
  final String? nativeMethodName;
  final bool forAbstractClassOrMixin;
  Token? _beginInitializers;

  AbstractSourceConstructorBuilder? _builder;

  ConstructorFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charOpenParenOffset,
      required this.charEndOffset,
      required this.modifiers,
      required this.metadata,
      required this.returnType,
      required this.typeParameters,
      required this.formals,
      required this.nativeMethodName,
      required this.forAbstractClassOrMixin,
      required Token? beginInitializers})
      : _beginInitializers = beginInitializers;

  Token? get beginInitializers {
    Token? result = _beginInitializers;
    // Ensure that we don't hold onto the token.
    _beginInitializers = null;
    return result;
  }

  @override
  AbstractSourceConstructorBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(AbstractSourceConstructorBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  FunctionBodyBuildingContext createFunctionBodyBuildingContext() {
    return new _ConstructorBodyBuildingContext(this);
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}

class _ConstructorBodyBuildingContext implements FunctionBodyBuildingContext {
  ConstructorFragment _fragment;

  _ConstructorBodyBuildingContext(this._fragment);

  @override
  // TODO(johnniwinther): This matches what is passed when parsing, but seems
  // odd given that it used to allow 'covariant' modifiers, which shouldn't be
  // allowed on constructors.
  MemberKind get memberKind => MemberKind.NonStaticMethod;

  @override
  bool get shouldBuild =>
      // TODO(johnniwinther): Ensure building of const extension type
      //  constructor body. An error is reported by the parser but we skip
      //  the body here to avoid overwriting the already lowering const
      //  constructor.
      !(_fragment.builder is SourceExtensionTypeConstructorBuilder &&
          _fragment.modifiers.isConst);

  @override
  LocalScope computeFormalParameterScope(LookupScope typeParameterScope) {
    return _fragment.builder.computeFormalParameterScope(typeParameterScope);
  }

  @override
  LookupScope computeTypeParameterScope(LookupScope enclosingScope) {
    return _fragment.builder.computeTypeParameterScope(enclosingScope);
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return _fragment.builder.createBodyBuilderContext(
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
  }

  @override
  InferenceDataForTesting? get inferenceDataForTesting => _fragment
      .builder
      .dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.inferenceData;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _fragment.builder.thisTypeParameters;

  @override
  VariableDeclaration? get thisVariable => _fragment.builder.thisVariable;
}
