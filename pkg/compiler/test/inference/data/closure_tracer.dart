// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: testFunctionStatement:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testFunctionStatement() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: testFunctionExpression:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testFunctionExpression() {
  var res;
  var closure = /*[exact=JSUInt31|powerset={I}{O}]*/
      (/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: staticField:[null|subclass=Closure|powerset={null}{N}{O}]*/
var staticField;

/*member: testStoredInStatic:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStoredInStatic() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  staticField = closure;
  staticField(42);
  return res;
}

class A {
  /*member: A.field:[subclass=Closure|powerset={N}{O}]*/
  var field;
  /*member: A.:[exact=A|powerset={N}{O}]*/
  A(this. /*[subclass=Closure|powerset={N}{O}]*/ field);

  /*member: A.foo:[exact=JSUInt31|powerset={I}{O}]*/
  static foo(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => topLevel3 = a;
}

/*member: testStoredInInstance:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStoredInInstance() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  var a = A(closure);
  a.field /*invoke: [exact=A|powerset={N}{O}]*/ (42);
  return res;
}

/*member: testStoredInMapOfList:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStoredInMapOfList() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic, dynamic>{'foo': 1};

  b
      /*update: Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {foo: [exact=JSUInt31|powerset={I}{O}], bar: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {null}{I}{G})}, powerset: {N}{O})*/
      ['bar'] =
      a;

  b
  /*Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {foo: [exact=JSUInt31|powerset={I}{O}], bar: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {null}{I}{G})}, powerset: {N}{O})*/
  ['bar']
  /*Container([null|exact=JSExtendableArray|powerset={null}{I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {null}{I}{G})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfList:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStoredInListOfList() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO}), length: 3, powerset: {I}{G})*/
      [1] =
      a;

  b
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO}), length: 3, powerset: {I}{G})*/
  [1]
  /*Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfListUsingInsert:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStoredInListOfListUsingInsert() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b.
  /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO}), length: null, powerset: {I}{G})*/
  insert(1, a);

  b /*Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO}), length: null, powerset: {I}{G})*/ [1]
  /*Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfListUsingAdd:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStoredInListOfListUsingAdd() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b.
  /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO}), length: null, powerset: {I}{G})*/
  add(a);

  b
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO}), length: null, powerset: {I}{G})*/
  [3]
  /*Union([exact=JSExtendableArray|powerset={I}{G}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{GO})*/
  [0](42);
  return res;
}

/*member: testStoredInRecord:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStoredInRecord() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  final a = (3, closure);

  a. /*[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}{O}], [subclass=Closure|powerset={N}{O}]], powerset: {N}{O})]*/ $2(
    42,
  );
  return res;
}

/*member: foo:[null|powerset={null}]*/
foo(/*[subclass=Closure|powerset={N}{O}]*/ closure) {
  closure(42);
}

/*member: testPassedInParameter:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testPassedInParameter() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => res = a;
  foo(closure);
  return res;
}

/*member: topLevel1:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
var topLevel1;
/*member: foo2:[exact=JSUInt31|powerset={I}{O}]*/
foo2(/*[exact=JSUInt31|powerset={I}{O}]*/ a) => topLevel1 = a;

/*member: testStaticClosure1:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStaticClosure1() {
  var a = foo2;
  a(42);
  return topLevel1;
}

/*member: topLevel2:Union(null, [exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O})*/
var topLevel2;

/*member: bar:Union([exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
bar(
  /*Union([exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/ a,
) => topLevel2 = a;

/*member: testStaticClosure2:Union(null, [exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O})*/
testStaticClosure2() {
  var a = bar;
  a(42);
  var b = bar;
  b(2.5);
  return topLevel2;
}

/*member: topLevel3:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
var topLevel3;

/*member: testStaticClosure3:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
testStaticClosure3() {
  var a = A.foo;
  a(42);
  return topLevel3;
}

/*member: topLevel4:Union(null, [exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O})*/
var topLevel4;

/*member: testStaticClosure4Helper:Union([exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
testStaticClosure4Helper(
  /*Union([exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/ a,
) => topLevel4 = a;

/*member: testStaticClosure4:Union(null, [exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O})*/
testStaticClosure4() {
  var a = testStaticClosure4Helper;
  // Test calling the static after tearing it off.
  testStaticClosure4Helper(2.5);
  a(42);
  return topLevel4;
}

/*member: bar1:[subclass=Closure|powerset={N}{O}]*/
int Function(int, [int]) bar1(
  int /*[exact=JSUInt31|powerset={I}{O}]*/ a,
) => /*[subclass=JSInt|powerset={I}{O}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ /*prod.[subclass=JSInt|powerset={I}{O}]*/
      b, [
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ /*prod.[subclass=JSInt|powerset={I}{O}]*/
          c =
          17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}{O}]*/ +
        c;
/*member: bar2:[subclass=Closure|powerset={N}{O}]*/
int Function(int, [int]) bar2(
  int /*[exact=JSUInt31|powerset={I}{O}]*/ a,
) => /*[subclass=JSInt|powerset={I}{O}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ /*prod.[subclass=JSInt|powerset={I}{O}]*/
      b, [
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ /*prod.[subclass=JSInt|powerset={I}{O}]*/
          c =
          17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}{O}]*/ +
        c;
/*member: bar3:[subclass=Closure|powerset={N}{O}]*/
int Function(int, [int]) bar3(
  int /*[exact=JSUInt31|powerset={I}{O}]*/ a,
) => /*[subclass=JSPositiveInt|powerset={I}{O}]*/
    (
      int /*[exact=JSUInt31|powerset={I}{O}]*/ b, [
      int /*[exact=JSUInt31|powerset={I}{O}]*/ c = 17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ +
        b /*invoke: [subclass=JSUInt32|powerset={I}{O}]*/ +
        c;
/*member: bar4:[subclass=Closure|powerset={N}{O}]*/
num Function(int, [int]) bar4(
  int /*[exact=JSUInt31|powerset={I}{O}]*/ a,
) => /*[subclass=JSNumber|powerset={I}{O}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ /*prod.[subclass=JSInt|powerset={I}{O}]*/
      b, [
      dynamic /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ c,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}{O}]*/ +
        c;
/*member: bar5:[subclass=Closure|powerset={N}{O}]*/
num Function(int, [int]) bar5(
  int /*[exact=JSUInt31|powerset={I}{O}]*/ a,
) => /*[subclass=JSNumber|powerset={I}{O}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ /*prod.[subclass=JSInt|powerset={I}{O}]*/
      b, [
      num? /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ /*prod.[null|subclass=JSNumber|powerset={null}{I}{O}]*/
      c,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}{O}]*/ +
        (c ?? 0);

/*member: testFunctionApply:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
testFunctionApply() {
  return Function.apply(bar1(10), [20]);
}

/*member: testFunctionApplyNoDefault:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
testFunctionApplyNoDefault() {
  Function.apply(bar4(10), [30]);
  return Function.apply(bar5(10), [30]);
}

/*member: testRecordFunctionApply:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
testRecordFunctionApply() {
  final rec = (bar2(10), bar3(10));
  (rec. /*[Record(RecordShape(2), [[subclass=Closure|powerset={N}{O}], [subclass=Closure|powerset={N}{O}]], powerset: {N}{O})]*/ $2)(
    2,
    3,
  );
  return Function.apply(
    rec. /*[Record(RecordShape(2), [[subclass=Closure|powerset={N}{O}], [subclass=Closure|powerset={N}{O}]], powerset: {N}{O})]*/ $1,
    [20],
  );
}

/*member: main:[null|powerset={null}]*/
main() {
  testFunctionStatement();
  testFunctionExpression();
  testStoredInStatic();
  testStoredInInstance();
  testStoredInMapOfList();
  testStoredInListOfList();
  testStoredInListOfListUsingInsert();
  testStoredInListOfListUsingAdd();
  testStoredInRecord();
  testPassedInParameter();
  testStaticClosure1();
  testStaticClosure2();
  testStaticClosure3();
  testStaticClosure4();
  testFunctionApply();
  testFunctionApplyNoDefault();
  testRecordFunctionApply();
}
