// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineValueTest);
  });
}

@reflectiveTest
class InlineValueTest extends AbstractLspAnalysisServerTest {
  late TestCode code;

  /// Whether to enable the inlineValuesProperties experiment flag in the
  /// client configuration passed during initialization.
  bool experimentalInlineValuesProperties = false;

  Future<void> test_parameter_declaration() async {
    code = TestCode.parse(r'''
void f(int /*[0*/aaa/*0]*/, int /*[1*/bbb/*1]*/) {
  ^
  aaa + bbb;
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_parameter_read() async {
    code = TestCode.parse(r'''
void f(int aaa, int bbb) {
  ^/*[0*/aaa/*0]*/ + /*[1*/bbb/*1]*/;
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_parameter_write() async {
    code = TestCode.parse(r'''
void f(int aaa, int bbb, int ccc) {
  /*[0*/aaa/*0]*/++;
  /*[1*/bbb/*1]*/ = 1;
  /*[2*/ccc/*2]*/ += 1;
  ^
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_parameters_scope() async {
    // We should only get the parameters declared in the current function.
    code = TestCode.parse(r'''
void f(int aaa, int bbb, int ccc) {
  void b(int /*[0*/aaa/*0]*/, int /*[1*/bbb/*1]*/) {

    var _ = (aaa, bbb, ccc) => null;
    var _ = () {
      var aaa = 1, bbb = 1, ccc = 1;
    };

    ^
  }
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_property_experimentDisabled() async {
    code = TestCode.parse(r'''
void f(String /*[0*/s/*0]*/) {
  print(s.length); // No inline value, experiment not enabled
  ^
}
''');

    await verify_values(
      code,
      // The parameter is a variable even though this test is about properties.
      ofType: InlineValueVariableLookup,
    );
  }

  Future<void> test_property_getter() async {
    experimentalInlineValuesProperties = true;

    code = TestCode.parse(r'''
void f(String /*[0*/s/*0]*/) {
  print(/*[1*/s.length/*1]*/);
  print(/*[2*/s.length.isEven/*2]*/);
  ^
}
''');

    await verify_values(
      code,
      ofTypes: {
        0: InlineValueVariableLookup,
        1: InlineValueEvaluatableExpression,
        2: InlineValueEvaluatableExpression,
      },
    );
  }

  Future<void> test_property_getter_enum_value_excluded() async {
    experimentalInlineValuesProperties = true;

    code = TestCode.parse(r'''
enum MyEnum {
  one,
}

void f(MyEnum x) {
  print(/*[0*/x/*0]*/ == MyEnum.one); // MyEnum.one excluded
  print(/*[1*/MyEnum.one.index/*1]*/);
  ^
}
''');

    await verify_values(
      code,
      ofTypes: {
        0: InlineValueVariableLookup,
        1: InlineValueEvaluatableExpression,
      },
    );
  }

  Future<void> test_property_getter_enum_values_excluded() async {
    experimentalInlineValuesProperties = true;

    code = TestCode.parse(r'''
enum MyEnum {
  one,
}

void f() {
  print(MyEnum.values); // MyEnum.values excluded
  print(/*[0*/MyEnum.values.length/*0]*/);
  ^
}
''');

    await verify_values(code, ofType: InlineValueEvaluatableExpression);
  }

  Future<void> test_property_method() async {
    experimentalInlineValuesProperties = true;

    code = TestCode.parse(r'''
class A {
  void x() {}
}
void f(A /*[0*/a/*0]*/) {
  a.x(); // No value for methods.
  ^
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_property_method_targets() async {
    experimentalInlineValuesProperties = true;

    code = TestCode.parse(r'''
class A {
  String x(int a) => a.toString();
}
void f(A /*[0*/a/*0]*/, int b) {
  // No value for length because the expression contains a method call.
  a.x(b).length;

  // No value for either length of isEven because the expression contains a
  // method call.
  a.x(/*[1*/b/*1]*/).length.isEven;
  ^
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_property_setter() async {
    experimentalInlineValuesProperties = true;

    code = TestCode.parse(r'''
class A {
  int? x;
}
void f(A /*[0*/a/*0]*/) {
  a.x = 1; // No value for setters.
  ^
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_scope_method_inNestedFunction() async {
    code = TestCode.parse(r'''
class A {
  void method() {
    void inner() {
      var [!valueVar!] = 1;
      ^
    }
    var noValueVar = 1;
  }
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_scope_method_notInNestedFunction() async {
    code = TestCode.parse(r'''
class A {
  void method() {
    void inner() {
      var noValueVar = 1;
    }
    var [!valueVar!] = 1;
    ^
  }
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_scope_topLevelFunction_inNestedFunction() async {
    code = TestCode.parse(r'''
void top() {
  void inner() {
    var [!valueVar!] = 1;
    ^
  }
  var noValueVar = 1;
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_scope_topLevelFunction_notInNestedFunction() async {
    code = TestCode.parse(r'''
void top() {
  void inner() {
    var noValueVar = 1;
  }
  var [!valueVar!] = 1;
  ^
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_variable_declaration() async {
    code = TestCode.parse(r'''
void f() {
  int /*[0*/aaa/*0]*/ = 1;
  int /*[1*/bbb/*1]*/ = 1, /*[2*/ccc/*2]*/ = 1;
  ^
  aaa + bbb;
  ccc;
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_variable_propertyAccess() async {
    code = TestCode.parse(r'''
void f(int /*[0*/aaa/*0]*/) {
  aaa.isEven; // No inline value for var because it's in a property access.
  ^
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_variable_read() async {
    code = TestCode.parse(r'''
void f() {
  int aaa = 1;
  int bbb = 1, ccc = 1;
  ^/*[0*/aaa/*0]*/ + /*[1*/bbb/*1]*/ + /*[2*/ccc/*2]*/;
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_variable_write() async {
    code = TestCode.parse(r'''
void f() {
  int aaa = 0, bbb = 0, ccc = 0;
  /*[0*/aaa/*0]*/ = 1;
  /*[1*/bbb/*1]*/++;
  /*[2*/ccc/*2]*/ += 1;
  ^
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  Future<void> test_variables_scope() async {
    // We should not get the top-levels or the nested functions.
    code = TestCode.parse(r'''
var aaa = 1;
var bbb = 1;

void f() {
  int /*[0*/aaa/*0]*/ = 0, /*[1*/ccc/*1]*/ = 0;

  var _ = (aaa, bbb, ccc) => null;
  var _ = () {
    var aaa = 1, bbb = 1, ccc = 1;
  };

  ^
}
''');

    await verify_values(code, ofType: InlineValueVariableLookup);
  }

  /// Verifies [code] produces values at the marked ranges.
  ///
  /// The [ofTypes] contains the kind of value to be expected for the range with
  /// the same index. If a range is not included in [ofTypes] then [ofType] is
  /// used instead.
  Future<void> verify_values(
    TestCode code, {
    Type? ofType,
    Map<int, Type>? ofTypes,
  }) async {
    await provideConfig(initialize, {
      if (experimentalInlineValuesProperties)
        'experimentalInlineValuesProperties': true,
    });
    await openFile(mainFileUri, code.code);
    await initialAnalysis;

    var actualValues = await getInlineValues(
      mainFileUri,
      visibleRange: rangeOfWholeContent(code.code),
      stoppedAt: code.position.position,
    );

    var expectedValues = code.ranges.ranges.mapIndexed((index, range) {
      return switch (ofTypes?[index] ?? ofType) {
        const (InlineValueVariableLookup) => InlineValue.t3(
          InlineValueVariableLookup(caseSensitiveLookup: true, range: range),
        ),
        const (InlineValueEvaluatableExpression) => InlineValue.t1(
          InlineValueEvaluatableExpression(range: range),
        ),
        _ => throw 'No type provided for range $index',
      };
    });

    expect(actualValues, unorderedEquals(expectedValues));
  }
}
