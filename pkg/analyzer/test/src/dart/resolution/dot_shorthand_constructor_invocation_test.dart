// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandConstructorInvocationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DotShorthandConstructorInvocationResolutionTest
    extends PubPackageResolutionTest {
  test_abstract_instantiation() async {
    await assertErrorsInCode(
      r'''
Function getFunction() {
  return .new();
}
''',
      [error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 34, 6)],
    );
  }

  test_abstract_instantiation_factory() async {
    await assertNoErrorsInCode(r'''
void main() async {
  var iter = [1, 2];
  await for (var x in .fromIterable(iter)) {
    print(x);
  }
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: fromIterable
    element: ConstructorMember
      baseElement: dart:async::@fragment::dart:async/stream.dart::@class::Stream::@constructor::fromIterable#element
      substitution: {T: int}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: iter
        correspondingParameter: ParameterMember
          baseElement: dart:async::@fragment::dart:async/stream.dart::@class::Stream::@constructor::fromIterable::@parameter::data#element
          substitution: {T: int}
        element: iter@26
        staticType: List<int>
    rightParenthesis: )
  staticType: Stream<int>
''');
  }

  test_chain_method() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
  C method() => C(1);
}

void main() {
  C c = .new(1).method();
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibraryFragment>::@class::C::@constructor::new#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_chain_property() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
  C get property => C(1);
}

void main() {
  C c = .new(1).property;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibraryFragment>::@class::C::@constructor::new#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_const_assert() async {
    await assertNoErrorsInCode(r'''
class C {
  final int x;
  const C.named(this.x);
}

class CAssert {
  const CAssert.regular(C ctor)
    : assert(ctor == const .named(1));
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: C
''');
  }

  test_const_inConstantContext() async {
    await assertNoErrorsInCode(r'''
class C {
  final int x;
  const C.named(this.x);
}

void main() {
  const C c = .named(1);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_const_keyword() async {
    await assertNoErrorsInCode(r'''
class C {
  final int x;
  const C.named(this.x);
}

void main() {
  C c = const .named(1);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_const_nonConst_constructor() async {
    await assertErrorsInCode(
      r'''
class C {
  final int x;
  C.named(this.x);
}

void main() {
  C c = const .named(1);
  print(c);
}
''',
      [error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 69, 5)],
    );
  }

  test_const_nonConst_method() async {
    await assertErrorsInCode(
      r'''
class C {
  static C fn() => C.named(1);
  final int x;
  C.named(this.x);
}

void main() {
  C c = const .fn(1);
  print(c);
}
''',
      [error(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, 107, 2)],
    );
  }

  test_constructor_named() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C.named(this.x);
}

void main() {
  C c = .named(1);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_constructor_named_futureOr() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

class C<T> {
  T value;
  C.id(this.value);
}

void main() async {
  FutureOr<C?>? c = .id(2);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: id
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::C::@constructor::id#element
      substitution: {T: dynamic}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibraryFragment>::@class::C::@constructor::id::@parameter::value#element
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: C<dynamic>
''');
  }

  test_enum_constructor() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.named();

  const E.named();
}

void f() {
  E e = .named();
  print(e);
}
''',
      [
        error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          65,
          5,
        ),
      ],
    );
  }

  test_equality() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C.named(this.x);
}

void main() {
  C lhs = C.named(2);
  bool b = lhs == .named(1);
  print(b);
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: C
''');
  }

  test_equality_inferTypeParameters() async {
    await assertNoErrorsInCode('''
void main() {
  bool x = <int>[] == .filled(2, '2');
  print(x);
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: filled
    element: ConstructorMember
      baseElement: dart:core::<fragment>::@class::List::@constructor::filled#element
      substitution: {E: String}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        correspondingParameter: ParameterMember
          baseElement: dart:core::<fragment>::@class::List::@constructor::filled::@parameter::length#element
          substitution: {E: String}
        staticType: int
      SimpleStringLiteral
        literal: '2'
    rightParenthesis: )
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: List<String>
''');
  }

  test_equality_pattern() async {
    await assertNoErrorsInCode(r'''
class C {
  final int x;
  const C.named(this.x);
}

void main() {
  C c = C.named(1);
  if (c case == const .named(2)) print('ok');
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_nested_invocation() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static C member() => C(1);
  T x;
  C(this.x);
}

void main() {
  C<C> c = .new(.member());
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::C::@constructor::new#element
      substitution: {T: C<dynamic>}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DotShorthandInvocation
        period: .
        memberName: SimpleIdentifier
          token: member
          element: <testLibraryFragment>::@class::C::@method::member#element
          staticType: C<dynamic> Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
          substitution: {T: C<dynamic>}
        staticInvokeType: C<dynamic> Function()
        staticType: C<dynamic>
    rightParenthesis: )
  staticType: C<C<dynamic>>
''');
  }

  test_nested_property() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static C get member => C(1);
  T x;
  C(this.x);
}

void main() {
  C<C> c = .new(.member);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::C::@constructor::new#element
      substitution: {T: C<dynamic>}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DotShorthandPropertyAccess
        period: .
        propertyName: SimpleIdentifier
          token: member
          element: <testLibraryFragment>::@class::C::@getter::member#element
          staticType: C<dynamic>
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
          substitution: {T: C<dynamic>}
        staticType: C<dynamic>
    rightParenthesis: )
  staticType: C<C<dynamic>>
''');
  }

  test_new() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
}

void main() {
  C c = .new(1);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibraryFragment>::@class::C::@constructor::new#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_postfixOperator() async {
    await assertErrorsInCode(
      r'''
class C {}

void main() {
  C c = .new()++;
  print(c);
}
''',
      [
        error(CompileTimeErrorCode.DOT_SHORTHAND_UNDEFINED_INVOCATION, 35, 3),
        error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 40, 2),
      ],
    );
  }

  test_prefixOperator() async {
    await assertErrorsInCode(
      r'''
class C {}

void main() {
  C c = ++.new();
  print(c);
}
''',
      [
        error(CompileTimeErrorCode.DOT_SHORTHAND_UNDEFINED_INVOCATION, 37, 3),
        error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 41, 1),
      ],
    );
  }

  test_requiredParameters_missing() async {
    await assertErrorsInCode(
      r'''
class C {
  int x;
  C({required this.x});
}

void main() {
  C c = .new();
  print(c);
}
''',
      [error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 69, 3)],
    );
  }

  test_typeParameters() async {
    await assertErrorsInCode(
      r'''
class C {
  C();
}

void main() {
  C c = .new<int>();
  print(c);
}
''',
      [
        error(
          CompileTimeErrorCode
              .WRONG_NUMBER_OF_TYPE_ARGUMENTS_DOT_SHORTHAND_CONSTRUCTOR,
          46,
          5,
        ),
      ],
    );
  }

  test_typeParameters_const() async {
    await assertErrorsInCode(
      r'''
class C {
  const C();
}

void main() {
  C c = const .new<int>();
  print(c);
}
''',
      [
        error(
          CompileTimeErrorCode
              .WRONG_NUMBER_OF_TYPE_ARGUMENTS_DOT_SHORTHAND_CONSTRUCTOR,
          58,
          5,
        ),
      ],
    );
  }

  test_typeParameters_missingContext() async {
    await assertErrorsInCode(
      r'''
void main() {
  var c = const .new<int>();
  print(c);
}
''',
      [error(CompileTimeErrorCode.DOT_SHORTHAND_MISSING_CONTEXT, 24, 17)],
    );
  }
}
