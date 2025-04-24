// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        Constructor,
        Field,
        FunctionNode,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        ProcedureStubKind;
import 'package:kernel/canonical_name.dart';

import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/member_builder.dart';
import '../builder/method_builder.dart';
import '../builder/property_builder.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart' show ClassMembersBuilder;
import '../kernel/member_covariance.dart';
import 'dill_builder_mixins.dart';
import 'dill_class_builder.dart';
import 'dill_library_builder.dart';

abstract class DillMemberBuilder extends MemberBuilderImpl {
  @override
  final DillLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder? declarationBuilder;

  DillMemberBuilder(this.libraryBuilder, this.declarationBuilder);

  Member get member;

  @override
  int get fileOffset => member.fileOffset;

  @override
  Uri get fileUri => member.fileUri;

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  String get name => member.name.text;

  @override
  Name get memberName => member.name;

  @override
  bool get isAbstract => member.isAbstract;

  @override
  bool get isSynthetic {
    final Member member = this.member;
    return member is Constructor && member.isSynthetic;
  }
}

class DillFieldBuilder extends DillMemberBuilder
    with DillFieldBuilderMixin
    implements PropertyBuilder {
  final Field field;

  DillFieldBuilder(this.field, super.libraryBuilder,
      [super.declarationBuilder]);

  @override
  Member get member => field;

  @override
  Member? get readTarget => field;

  @override
  Reference get readTargetReference => field.getterReference;

  @override
  Member? get writeTarget => field.hasSetter ? field : null;

  @override
  Reference? get writeTargetReference => field.setterReference;

  @override
  bool get hasConstField => field.isConst;

  @override
  bool get isStatic => field.isStatic;

  @override
  Iterable<Reference> get exportedMemberReferences =>
      [field.getterReference, if (field.hasSetter) field.setterReference!];

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => field.isEnumElement;

  @override
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  SetterQuality get setterQuality =>
      field.hasSetter ? SetterQuality.Implicit : SetterQuality.Absent;
}

abstract class _DillProcedureBuilder extends DillMemberBuilder {
  final Procedure _procedure;

  _DillProcedureBuilder(this._procedure, super.libraryBuilder,
      [super.declarationBuilder]);

  @override
  bool get isStatic => _procedure.isStatic;

  @override
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];
}

class DillGetterBuilder extends _DillProcedureBuilder
    with DillGetterBuilderMixin
    implements PropertyBuilder {
  DillGetterBuilder(super.procedure, super.libraryBuilder,
      [super.declarationBuilder])
      : assert(procedure.kind == ProcedureKind.Getter);

  @override
  Member get member => _procedure;

  @override
  Member get readTarget => _procedure;

  @override
  Reference get readTargetReference => _procedure.reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => _procedure.isExternal
      ? GetterQuality.External
      : _procedure.isAbstract
          ? GetterQuality.Abstract
          : GetterQuality.Concrete;

  @override
  SetterQuality get setterQuality => SetterQuality.Absent;
}

class DillSetterBuilder extends _DillProcedureBuilder
    with DillSetterBuilderMixin
    implements PropertyBuilder {
  DillSetterBuilder(super.procedure, super.libraryBuilder,
      [super.declarationBuilder])
      : assert(procedure.kind == ProcedureKind.Setter);

  @override
  Member get member => _procedure;

  @override
  Member get writeTarget => _procedure;

  @override
  Reference get writeTargetReference => _procedure.reference;

  @override
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Absent;

  @override
  SetterQuality get setterQuality => _procedure.isExternal
      ? SetterQuality.External
      : _procedure.isAbstract
          ? SetterQuality.Abstract
          : SetterQuality.Concrete;
}

class DillMethodBuilder extends _DillProcedureBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  DillMethodBuilder(super.procedure, super.libraryBuilder,
      [super.declarationBuilder])
      : assert(procedure.kind == ProcedureKind.Method);

  @override
  Member get member => _procedure;

  @override
  Member get readTarget => _procedure;

  @override
  Reference get readTargetReference => _procedure.reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  Reference get invokeTargetReference => _procedure.reference;
}

class DillOperatorBuilder extends _DillProcedureBuilder
    with DillOperatorBuilderMixin
    implements MethodBuilder {
  DillOperatorBuilder(super.procedure, super.libraryBuilder,
      [super.declarationBuilder])
      : assert(procedure.kind == ProcedureKind.Operator);
  @override
  Member get member => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;
}

class DillFactoryBuilder extends _DillProcedureBuilder
    with DillFactoryBuilderMixin
    implements FactoryBuilder {
  final Procedure? _factoryTearOff;

  DillFactoryBuilder(super.procedure, this._factoryTearOff,
      super.libraryBuilder, DillClassBuilder super.declarationBuilder);

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => _procedure;

  @override
  Member? get readTarget => _factoryTearOff ?? _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference =>
      (_factoryTearOff ?? _procedure).reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  FunctionNode get function => _procedure.function;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => _procedure.isConst;
}

class DillConstructorBuilder extends DillMemberBuilder
    with DillConstructorBuilderMixin
    implements ConstructorBuilder {
  final Constructor constructor;
  final Procedure? _constructorTearOff;

  DillConstructorBuilder(this.constructor, this._constructorTearOff,
      super.libraryBuilder, ClassBuilder super.declarationBuilder);

  @override
  FunctionNode get function => constructor.function;

  @override
  Constructor get member => constructor;

  @override
  Member get readTarget => _constructorTearOff ?? constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference =>
      (_constructorTearOff ?? constructor).reference;

  @override
  Constructor get invokeTarget => constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => constructor.reference;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => constructor.isConst;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [constructor.reference];
}

class DillClassMember extends BuilderClassMember {
  @override
  final DillMemberBuilder memberBuilder;

  Covariance? _covariance;

  @override
  final ClassMemberKind memberKind;

  DillClassMember(this.memberBuilder, this.memberKind);

  @override
  bool get isSourceDeclaration => false;

  @override
  bool get isExtensionTypeMember {
    Member member = memberBuilder.member;
    return member.isExtensionTypeMember;
  }

  @override
  bool get isInternalImplementation {
    Member member = memberBuilder.member;
    return member.isInternalImplementation;
  }

  @override
  bool get isNoSuchMethodForwarder {
    Member member = memberBuilder.member;
    return member is Procedure &&
        member.stubKind == ProcedureStubKind.NoSuchMethodForwarder;
  }

  @override
  bool get isSynthesized {
    Member member = memberBuilder.member;
    return member is Procedure && member.isSynthetic;
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) => memberBuilder.member;

  @override
  Member? getTearOff(ClassMembersBuilder membersBuilder) {
    Member? readTarget = memberBuilder.readTarget;
    return readTarget != memberBuilder.invokeTarget ? readTarget : null;
  }

  @override
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??=
        new Covariance.fromMember(memberBuilder.member, forSetter: forSetter);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void inferType(ClassMembersBuilder hierarchy) {
    // Do nothing; this is only for source members.
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerOverrideDependency(
      ClassMembersBuilder membersBuilder, Set<ClassMember> overriddenMembers) {
    // Do nothing; this is only for source members.
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is DillClassMember && memberBuilder == other.memberBuilder;
  }

  @override
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    Member member = getMember(membersBuilder);
    if (member is Procedure &&
        member.stubKind == ProcedureStubKind.RepresentationField) {
      return new TypeDeclarationInstanceMemberResult(
          getMember(membersBuilder), memberKind,
          isDeclaredAsField: true);
    }
    return super.getMemberResult(membersBuilder);
  }

  @override
  String toString() => 'DillClassMember($memberBuilder,forSetter=${forSetter})';
}
