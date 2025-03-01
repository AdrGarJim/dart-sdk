// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateExtensionGetterTest);
    defineReflectiveTests(CreateExtensionMethodTest);
    defineReflectiveTests(CreateExtensionOperatorTest);
    defineReflectiveTests(CreateExtensionSetterTest);
  });
}

@reflectiveTest
class CreateExtensionGetterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_EXTENSION_GETTER;

  @FailingTest(reason: 'Should not be a fix because it will conflict with a')
  Future<void> test_conflicting_setter() async {
    await resolveTestCode('''
class A {
  void set a(int value) {}
}
void f() {
  A().a;
}
''');
    await assertNoFix();
  }

  Future<void> test_contextType() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test;
}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test;
}

extension on String {
  int get test => null;
}
''');
  }

  Future<void> test_contextType_no() async {
    await resolveTestCode('''
void f() {
  ''.test;
}
''');
    await assertHasFix('''
void f() {
  ''.test;
}

extension on String {
  get test => null;
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['null']);
  }

  Future<void> test_existingExtension_contextType() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test;
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test;
}

extension on String {
  int get test => null;
}
''');
  }

  Future<void> test_existingExtension_generic_matching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test;
}

extension E<T> on Iterable<T> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test;
}

extension E<T> on Iterable<T> {
  get test => null;
}
''');
  }

  Future<void> test_existingExtension_generic_notMatching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test;
}

extension E<K, V> on Map<K, V> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test;
}

extension on List<int> {
  get test => null;
}

extension E<K, V> on Map<K, V> {}
''');
  }

  Future<void> test_existingExtension_hasMethod() async {
    await resolveTestCode('''
void f() {
  ''.test;
}

extension E on String {
  // ignore:unused_element
  void foo() {}
}
''');
    await assertHasFix('''
void f() {
  ''.test;
}

extension E on String {
  get test => null;

  // ignore:unused_element
  void foo() {}
}
''');
  }

  Future<void> test_existingExtension_notGeneric_matching() async {
    await resolveTestCode('''
void f() {
  ''.test;
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  ''.test;
}

extension on String {
  get test => null;
}
''');
  }

  Future<void> test_existingExtension_notGeneric_notMatching() async {
    await resolveTestCode('''
void f() {
  ''.test;
}

extension on int {}
''');
    await assertHasFix('''
void f() {
  ''.test;
}

extension on String {
  get test => null;
}

extension on int {}
''');
  }

  Future<void> test_nullableTargetType() async {
    await resolveTestCode('''
void f(int? p) {
  int _ = p.test;
}
''');
    await assertHasFix('''
void f(int? p) {
  int _ = p.test;
}

extension on int? {
  int get test => null;
}
''');
  }

  Future<void> test_parameterType() async {
    await resolveTestCode('''
void f<T>(T t) {
  int _ = t.test;
}
''');
    await assertHasFix('''
void f<T>(T t) {
  int _ = t.test;
}

extension <T> on T {
  int get test => null;
}
''');
  }

  Future<void> test_parent_nothing() async {
    await resolveTestCode('''
void f() {
  test;
}
''');
    await assertNoFix();
  }

  Future<void> test_parent_prefixedIdentifier() async {
    await resolveTestCode('''
void f(String a) {
  a.test;
}
''');
    await assertHasFix('''
void f(String a) {
  a.test;
}

extension on String {
  get test => null;
}
''');
  }

  Future<void> test_parent_propertyAccess_cascade() async {
    await resolveTestCode('''
void f(String a) {
  a..test;
}
''');
    await assertHasFix('''
void f(String a) {
  a..test;
}

extension on String {
  get test => null;
}
''');
  }

  Future<void> test_targetType_hasTypeArguments() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test;
}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test;
}

extension on List<int> {
  get test => null;
}
''');
  }
}

@reflectiveTest
class CreateExtensionMethodTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_EXTENSION_METHOD;

  Future<void> test_arguments() async {
    await resolveTestCode('''
void f() {
  ''.test(0, 1.2);
}
''');
    await assertHasFix('''
void f() {
  ''.test(0, 1.2);
}

extension on String {
  void test(int i, double d) {}
}
''');
  }

  Future<void> test_contextType() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test();
}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test();
}

extension on String {
  int test() {}
}
''');
  }

  Future<void> test_contextType_no() async {
    await resolveTestCode('''
void f() {
  ''.test();
}
''');
    await assertHasFix('''
void f() {
  ''.test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_existingExtension_contextType() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test();
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test();
}

extension on String {
  int test() {}
}
''');
  }

  Future<void> test_existingExtension_generic_matching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test();
}

extension E<T> on Iterable<T> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test();
}

extension E<T> on Iterable<T> {
  void test() {}
}
''');
  }

  Future<void> test_existingExtension_generic_matching2() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test();
}

extension E<T extends Iterable<int>> on T {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test();
}

extension E<T extends Iterable<int>> on T {
  void test() {}
}
''');
  }

  Future<void> test_existingExtension_generic_notMatching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test();
}

extension E<K, V> on Map<K, V> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test();
}

extension on List<int> {
  void test() {}
}

extension E<K, V> on Map<K, V> {}
''');
  }

  Future<void> test_existingExtension_generic_notMatching2() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test();
}

extension E<T extends Iterable<int>> on Iterable<T> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test();
}

extension on List<int> {
  void test() {}
}

extension E<T extends Iterable<int>> on Iterable<T> {}
''');
  }

  Future<void> test_existingExtension_hasMethod() async {
    await resolveTestCode('''
void f() {
  ''.test();
}

extension E on String {
  // ignore:unused_element
  void foo() {}
}
''');
    await assertHasFix('''
void f() {
  ''.test();
}

extension E on String {
  // ignore:unused_element
  void foo() {}

  void test() {}
}
''');
  }

  Future<void> test_existingExtension_notGeneric_matching() async {
    await resolveTestCode('''
void f() {
  ''.test();
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  ''.test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_existingExtension_notGeneric_notMatching() async {
    await resolveTestCode('''
void f() {
  ''.test();
}

extension on int {}
''');
    await assertHasFix('''
void f() {
  ''.test();
}

extension on String {
  void test() {}
}

extension on int {}
''');
  }

  Future<void> test_nullableTargetType() async {
    await resolveTestCode('''
void f(int? p) {
  int _ = p.test();
}
''');
    await assertHasFix('''
void f(int? p) {
  int _ = p.test();
}

extension on int? {
  int test() {}
}
''');
  }

  Future<void> test_parameters() async {
    await resolveTestCode('''
void f() {
  ''.test(1, '');
}
''');
    await assertHasFix('''
void f() {
  ''.test(1, '');
}

extension on String {
  void test(int i, String s) {}
}
''');
  }

  Future<void> test_parent_nothing() async {
    await resolveTestCode('''
void f() {
  test();
}
''');
    await assertNoFix();
  }

  Future<void> test_parent_prefixedIdentifier() async {
    await resolveTestCode('''
void f(String a) {
  a.test();
}
''');
    await assertHasFix('''
void f(String a) {
  a.test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_target_identifier() async {
    await resolveTestCode('''
void f(String a) {
  a.test();
}
''');
    await assertHasFix('''
void f(String a) {
  a.test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_target_identifier_cascade() async {
    await resolveTestCode('''
void f(String a) {
  a..test();
}
''');
    await assertHasFix('''
void f(String a) {
  a..test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_target_nothing() async {
    await resolveTestCode('''
void f() {
  test();
}
''');
    await assertNoFix();
  }

  Future<void> test_targetType_functionType() async {
    await resolveTestCode('''
void f(void Function(int p) a) {
  a.test();
}
''');
    await assertHasFix('''
void f(void Function(int p) a) {
  a.test();
}

extension on void Function(int p) {
  void test() {}
}
''');
  }

  Future<void> test_targetType_hasTypeArguments() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test();
}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test();
}

extension on List<int> {
  void test() {}
}
''');
  }

  Future<void> test_targetType_prefixed1() async {
    await resolveTestCode('''
import 'dart:math' as math;

void f(math.Random a) {
  a.test();
}
''');
    await assertHasFix('''
import 'dart:math' as math;

void f(math.Random a) {
  a.test();
}

extension on math.Random {
  void test() {}
}
''');
  }

  Future<void> test_targetType_prefixed2() async {
    await resolveTestCode('''
import 'dart:math' as math;

void f(List<math.Random> a) {
  a.test();
}
''');
    await assertHasFix('''
import 'dart:math' as math;

void f(List<math.Random> a) {
  a.test();
}

extension on List<math.Random> {
  void test() {}
}
''');
  }

  Future<void> test_targetType_record() async {
    await resolveTestCode('''
void f((int, String) a) {
  a.test();
}
''');
    await assertHasFix('''
void f((int, String) a) {
  a.test();
}

extension on (int, String) {
  void test() {}
}
''');
  }

  Future<void> test_targetType_typeVariable1() async {
    await resolveTestCode('''
void f<T>(T a) {
  a.test();
}
''');
    await assertHasFix('''
void f<T>(T a) {
  a.test();
}

extension <T> on T {
  void test() {}
}
''');
  }

  Future<void> test_targetType_typeVariable2() async {
    await resolveTestCode('''
void f<T>(List<T> a, T b) {
  a.test(b);
}
''');
    await assertHasFix('''
void f<T>(List<T> a, T b) {
  a.test(b);
}

extension <T> on List<T> {
  void test(T b) {}
}
''');
  }

  Future<void> test_targetType_typeVariable_bound() async {
    await resolveTestCode('''
void f<T extends num>(T a) {
  a.test();
}
''');
    await assertHasFix('''
void f<T extends num>(T a) {
  a.test();
}

extension <T extends num> on T {
  void test() {}
}
''');
  }

  Future<void> test_typeArgument_parameter() async {
    await resolveTestCode('''
void f<T>(T p) {
  ''.test(p);
}
''');
    await assertHasFix('''
void f<T>(T p) {
  ''.test(p);
}

extension on String {
  void test<T>(T p) {}
}
''');
  }

  Future<void> test_typeArgument_return() async {
    await resolveTestCode('''
void f<T>() {
  T _ = ''.test(0, 1.2);
}
''');
    await assertHasFix('''
void f<T>() {
  T _ = ''.test(0, 1.2);
}

extension on String {
  T test<T>(int i, double d) {}
}
''');
  }

  Future<void> test_typeArguments_bounded() async {
    await resolveTestCode('''
void f<T, R extends T>(R target) {
  R _ = target.test();
}
''');
    await assertHasFix('''
void f<T, R extends T>(R target) {
  R _ = target.test();
}

extension <R extends T, T> on R {
  R test() {}
}
''');
  }

  Future<void> test_typeArguments_everywhere() async {
    await resolveTestCode('''
void f<R, T, T2>(T2 target, T value) {
  R _ = target.test(value);
}
''');
    await assertHasFix('''
void f<R, T, T2>(T2 target, T value) {
  R _ = target.test(value);
}

extension <T2> on T2 {
  R test<R, T>(T value) {}
}
''');
  }

  Future<void> test_typeArguments_same() async {
    await resolveTestCode('''
void f<T>(T target) {
  T _ = target.test();
}
''');
    await assertHasFix('''
void f<T>(T target) {
  T _ = target.test();
}

extension <T> on T {
  T test() {}
}
''');
  }
}

@reflectiveTest
class CreateExtensionOperatorTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_EXTENSION_OPERATOR;

  Future<void> test_binary() async {
    await resolveTestCode('''
void f() {
  '' / 1;
}
''');
    await assertHasFix('''
void f() {
  '' / 1;
}

extension on String {
  void operator /(int other) {}
}
''');
  }

  Future<void> test_index_getter() async {
    await resolveTestCode('''
class A {
  void operator []=(String index, bool newValue) {}
}

void f() {
  A()[0];
}
''');
    // Because A already has a []= operator, we don't add a new getter for it.
    await assertNoFix();
  }

  Future<void> test_index_getter_ok() async {
    await resolveTestCode('''
void f() {
  String _ = 0[false];
}
''');
    await assertHasFix('''
void f() {
  String _ = 0[false];
}

extension on int {
  String operator [](bool other) {}
}
''');
  }

  Future<void> test_index_setter() async {
    await resolveTestCode('''
void f() {
  ''[0] = false;
}
''');
    // Because String already has a [] operator, we don't add a new setter for
    // it.
    await assertNoFix();
  }

  Future<void> test_index_setter_ok() async {
    await resolveTestCode('''
void f() {
  0[''] = false;
}
''');
    await assertHasFix('''
void f() {
  0[''] = false;
}

extension on int {
  void operator []=(String index, bool newValue) {}
}
''');
  }

  Future<void> test_nullableTargetType() async {
    await resolveTestCode('''
void f(int? p) {
  p + 0;
}
''');
    await assertHasFix('''
void f(int? p) {
  p + 0;
}

extension on int? {
  void operator +(int other) {}
}
''');
  }

  Future<void> test_returnType() async {
    await resolveTestCode('''
void f() {
  int _ = '' / 1;
}
''');
    await assertHasFix('''
void f() {
  int _ = '' / 1;
}

extension on String {
  int operator /(int other) {}
}
''');
  }

  Future<void> test_typeParameter() async {
    await resolveTestCode('''
void f<T>(T a) {
  a / a;
}
''');
    await assertHasFix('''
void f<T>(T a) {
  a / a;
}

extension <T> on T {
  void operator /(T other) {}
}
''');
  }

  Future<void> test_unary() async {
    await resolveTestCode('''
void f() {
  int _ = ~'';
}
''');
    await assertHasFix('''
void f() {
  int _ = ~'';
}

extension on String {
  int operator ~() {}
}
''');
  }
}

@reflectiveTest
class CreateExtensionSetterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_EXTENSION_SETTER;

  @FailingTest(reason: 'Should not be a fix because it will conflict with a')
  Future<void> test_conflicting_getter() async {
    await resolveTestCode('''
class A {
  int get a() {}
}
void f() {
  A().a = 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_existingExtension() async {
    await resolveTestCode('''
void f() {
  ''.test = 0;
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  ''.test = 0;
}

extension on String {
  set test(int test) {}
}
''');
  }

  Future<void> test_existingExtension_generic_matching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test = 0;
}

extension E<T> on Iterable<T> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test = 0;
}

extension E<T> on Iterable<T> {
  set test(int test) {}
}
''');
  }

  Future<void> test_existingExtension_generic_notMatching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test = 0;
}

extension E<K, V> on Map<K, V> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test = 0;
}

extension on List<int> {
  set test(int test) {}
}

extension E<K, V> on Map<K, V> {}
''');
  }

  Future<void> test_existingExtension_hasMethod() async {
    await resolveTestCode('''
void f() {
  ''.test = 0;
}

extension E on String {
  // ignore:unused_element
  void foo() {}
}
''');
    await assertHasFix('''
void f() {
  ''.test = 0;
}

extension E on String {
  set test(int test) {}

  // ignore:unused_element
  void foo() {}
}
''');
  }

  Future<void> test_existingExtension_notGeneric_matching() async {
    await resolveTestCode('''
void f() {
  ''.test = 0;
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  ''.test = 0;
}

extension on String {
  set test(int test) {}
}
''');
  }

  Future<void> test_existingExtension_notGeneric_notMatching() async {
    await resolveTestCode('''
void f() {
  ''.test = 0;
}

extension on int {}
''');
    await assertHasFix('''
void f() {
  ''.test = 0;
}

extension on String {
  set test(int test) {}
}

extension on int {}
''');
  }

  Future<void> test_nullableTargetType() async {
    await resolveTestCode('''
void f(int? p) {
  p.test = 0;
}
''');
    await assertHasFix('''
void f(int? p) {
  p.test = 0;
}

extension on int? {
  set test(int test) {}
}
''');
  }

  Future<void> test_parent_nothing() async {
    await resolveTestCode('''
void f() {
  test = 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_parent_prefixedIdentifier() async {
    await resolveTestCode('''
void f(String a) {
  a.test = 0;
}
''');
    await assertHasFix('''
void f(String a) {
  a.test = 0;
}

extension on String {
  set test(int test) {}
}
''');
  }

  Future<void> test_parent_propertyAccess_cascade() async {
    await resolveTestCode('''
void f(String a) {
  a..test = 0;
}
''');
    await assertHasFix('''
void f(String a) {
  a..test = 0;
}

extension on String {
  set test(int test) {}
}
''');
  }

  Future<void> test_targetType_hasTypeArguments() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test = 0;
}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test = 0;
}

extension on List<int> {
  set test(int test) {}
}
''');
  }

  Future<void> test_typeParameter() async {
    await resolveTestCode('''
void f<T>(T a) {
  a.test = 0;
}
''');
    await assertHasFix('''
void f<T>(T a) {
  a.test = 0;
}

extension <T> on T {
  set test(int test) {}
}
''');
  }
}
