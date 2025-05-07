// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  simpleDo();
  doNull();
  doNotNull();
  doNullFalse();
  doNotNullTrue();
  doUnion();
}

////////////////////////////////////////////////////////////////////////////////
/// Simple int based do-while loop.
////////////////////////////////////////////////////////////////////////////////

/*member: simpleDo:[null|powerset={null}]*/
simpleDo() {
  var i = 0;
  do {
    i = i /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ + 1;
  } while (i /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ < 10);
  i. /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ abs();
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with null test.
////////////////////////////////////////////////////////////////////////////////

/*member: doNull:[exact=JSString|powerset={I}]*/
doNull() {
  var o;
  do {
    o = o. /*invoke: [null|exact=JSString|powerset={null}{I}]*/ toString();
  } while (o == null);
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with not-null test.
////////////////////////////////////////////////////////////////////////////////

/*member: doNotNull:[exact=JSString|powerset={I}]*/
doNotNull() {
  var o = '';
  do {
    o = o. /*invoke: [exact=JSString|powerset={I}]*/ toString();
  } while (o /*invoke: [exact=JSString|powerset={I}]*/ != null);
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with null test known to be false.
////////////////////////////////////////////////////////////////////////////////

/*member: doNullFalse:[exact=JSString|powerset={I}]*/
doNullFalse() {
  var o = '';
  do {
    o = o. /*invoke: [exact=JSString|powerset={I}]*/ toString();
  } while (o /*invoke: [exact=JSString|powerset={I}]*/ == null);
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with not-null test known to be true.
////////////////////////////////////////////////////////////////////////////////

/*member: doNotNullTrue:[exact=JSString|powerset={I}]*/
doNotNullTrue() {
  var o = null;
  do {
    o = o. /*invoke: [null|exact=JSString|powerset={null}{I}]*/ toString();
  } while (o != null);
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with not-null test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}]*/
class Class1 {
  /*member: Class1.field:[null|exact=Class2|powerset={null}{N}]*/
  var field;
}

/*member: Class2.:[exact=Class2|powerset={N}]*/
class Class2 {
  /*member: Class2.field:[null|exact=Class1|powerset={null}{N}]*/
  var field;
}

/*member: _doUnion:Union(null, [exact=Class1|powerset={N}], [exact=Class2|powerset={N}], powerset: {null}{N})*/
_doUnion(/*[exact=Class1|powerset={N}]*/ o) {
  do {
    o = o. /*Union(null, [exact=Class1|powerset={N}], [exact=Class2|powerset={N}], powerset: {null}{N})*/ field;
  } while (o != null);
  return o;
}

/*member: doUnion:[null|powerset={null}]*/
doUnion() {
  var c1 = Class1();
  var c2 = Class2();
  c1. /*update: [exact=Class1|powerset={N}]*/ field = c2;
  c2. /*update: [exact=Class2|powerset={N}]*/ field = c1;
  _doUnion(c1);
}
