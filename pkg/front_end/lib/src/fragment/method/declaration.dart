// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../../base/local_scope.dart';
import '../../base/messages.dart';
import '../../base/scope.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/hierarchy/class_member.dart';
import '../../kernel/hierarchy/members_builder.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_method_builder.dart';
import '../fragment.dart';
import 'body_builder_context.dart';
import 'encoding.dart';

abstract class MethodDeclaration {
  Uri get fileUri;

  List<FormalParameterBuilder>? get formals;

  List<FormalParameterBuilder>? get formalsForTesting;

  FunctionNode get function;

  Procedure get invokeTarget;

  bool get isOperator;

  List<MetadataBuilder>? get metadata;

  Procedure? get readTarget;

  TypeBuilder get returnType;

  List<TypeParameter>? get thisTypeParameters;

  VariableDeclaration? get thisVariable;

  List<NominalParameterBuilder>? get typeParametersForTesting;

  void becomeNative(SourceLoader loader);

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      SourceMethodBuilder methodBuilder,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression});

  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference reference,
      required Reference? tearOffReference,
      required List<TypeParameter>? classTypeParameters});

  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment);

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  int computeDefaultTypes(ComputeDefaultTypeContext context);

  BodyBuilderContext createBodyBuilderContext(SourceMethodBuilder builder);

  void createEncoding(
      ProblemReporting problemReporting,
      SourceMethodBuilder builder,
      MethodEncodingStrategy encodingStrategy,
      List<NominalParameterBuilder> unboundNominalParameters);

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder enclosingClassBuilder,
      Set<ClassMember>? overrideDependencies);

  VariableDeclaration getFormalParameter(int index);

  VariableDeclaration? getTearOffParameter(int index);
}

class MethodDeclarationImpl implements MethodDeclaration {
  final MethodFragment _fragment;
  late final MethodEncoding _encoding;

  MethodDeclarationImpl(this._fragment) {
    _fragment.declaration = this;
  }

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  // TODO: implement formals
  List<FormalParameterBuilder>? get formals => _encoding.formals;

  // Coverage-ignore(suite): Not run.
  @override
  List<FormalParameterBuilder>? get formalsForTesting =>
      _encoding.formalsForTesting;

  @override
  FunctionNode get function => _encoding.function;

  @override
  Procedure get invokeTarget => _encoding.invokeTarget;

  @override
  bool get isOperator => _fragment.isOperator;

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  Procedure? get readTarget => _encoding.readTarget;

  @override
  TypeBuilder get returnType => _fragment.returnType;

  @override
  List<TypeParameter>? get thisTypeParameters => _encoding.thisTypeParameters;

  @override
  VariableDeclaration? get thisVariable => _encoding.thisVariable;

  // Coverage-ignore(suite): Not run.
  @override
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _encoding.clonedAndDeclaredTypeParameters;

  @override
  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader);
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
    _encoding.buildOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        declarationBuilder,
        createBodyBuilderContext(methodBuilder),
        annotatable,
        isClassInstanceMember: isClassInstanceMember,
        createFileUriExpression: createFileUriExpression);
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference reference,
      required Reference? tearOffReference,
      required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(libraryBuilder, nameScheme, f,
        reference: reference,
        tearOffReference: tearOffReference,
        isAbstractOrExternal:
            _fragment.modifiers.isAbstract || _fragment.modifiers.isExternal,
        classTypeParameters: classTypeParameters);
  }

  @override
  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment) {
    _encoding.checkTypes(libraryBuilder, typeEnvironment);
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    _encoding.checkVariance(sourceClassBuilder, typeEnvironment);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    return _encoding.computeDefaultTypes(context);
  }

  @override
  BodyBuilderContext createBodyBuilderContext(SourceMethodBuilder builder) {
    return new MethodFragmentBodyBuilderContext(
        _fragment, this, builder.libraryBuilder, builder.declarationBuilder,
        isDeclarationInstanceMember: builder.isDeclarationInstanceMember);
  }

  @override
  void createEncoding(
      ProblemReporting problemReporting,
      SourceMethodBuilder builder,
      MethodEncodingStrategy encodingStrategy,
      List<NominalParameterBuilder> unboundNominalParameters) {
    _encoding = encodingStrategy.createMethodEncoding(
        builder, _fragment, unboundNominalParameters);
    _fragment.typeParameterNameSpace.addTypeParameters(
        problemReporting, _encoding.clonedAndDeclaredTypeParameters,
        ownerName: _fragment.name, allowNameConflict: true);
    returnType.registerInferredTypeListener(_encoding);
  }

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    return _encoding.createFormalParameterScope(typeParameterScope);
  }

  @override
  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder enclosingClassBuilder,
      Set<ClassMember>? overrideDependencies) {
    if (overrideDependencies != null) {
      membersBuilder.inferMethodType(enclosingClassBuilder, _encoding.function,
          returnType, _fragment.declaredFormals, overrideDependencies,
          name: _fragment.name,
          fileUri: fileUri,
          nameOffset: _fragment.nameOffset,
          nameLength: _fragment.name.length);
    }
    _encoding.ensureTypes(
        enclosingClassBuilder.libraryBuilder, membersBuilder.hierarchyBuilder);
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _encoding.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _encoding.getTearOffParameter(index);
  }
}
