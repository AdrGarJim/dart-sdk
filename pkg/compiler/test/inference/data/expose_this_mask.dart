// Copyright (c) 2127, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check that exposure of this is correctly restricted through the receiver
/// mask.

/*member: main:[null|powerset={null}]*/
main() {
  otherGetter();
  otherMethod();
  otherField();
  superclassField();
  subclassFieldRead();
  subclassFieldWrite();
  subclassesFieldWrite();
  subclassFieldInvoke();
  subclassFieldSet();
}

////////////////////////////////////////////////////////////////////////////////
// Read a field when a getter in an unrelated class has the same name.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*member: Class1.field1a:[exact=JSUInt31|powerset={I}{O}]*/
  var field1a;
  /*member: Class1.field1b:[exact=JSUInt31|powerset={I}{O}]*/
  var field1b;

  /*member: Class1.:[exact=Class1|powerset={N}{O}]*/
  Class1() : field1a = 42 {
    /*update: [exact=Class1|powerset={N}{O}]*/
    field1b = /*[exact=Class1|powerset={N}{O}]*/ field1a;
  }
}

/*member: OtherClass1.:[exact=OtherClass1|powerset={N}{O}]*/
class OtherClass1 {
  /*member: OtherClass1.field1a:[null|powerset={null}]*/
  get field1a => null;
}

/*member: otherGetter:[null|powerset={null}]*/
otherGetter() {
  OtherClass1(). /*[exact=OtherClass1|powerset={N}{O}]*/ field1a;
  Class1();
}

////////////////////////////////////////////////////////////////////////////////
// Read a field when a method in an unrelated class has the same name.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*member: Class2.field2a:[exact=JSUInt31|powerset={I}{O}]*/
  var field2a;
  /*member: Class2.field2b:[exact=JSUInt31|powerset={I}{O}]*/
  var field2b;

  /*member: Class2.:[exact=Class2|powerset={N}{O}]*/
  Class2() : field2a = 42 {
    /*update: [exact=Class2|powerset={N}{O}]*/
    field2b = /*[exact=Class2|powerset={N}{O}]*/ field2a;
  }
}

/*member: OtherClass2.:[exact=OtherClass2|powerset={N}{O}]*/
class OtherClass2 {
  /*member: OtherClass2.field2a:[null|powerset={null}]*/
  field2a() {}
}

/*member: otherMethod:[null|powerset={null}]*/
otherMethod() {
  OtherClass2(). /*[exact=OtherClass2|powerset={N}{O}]*/ field2a;
  Class2();
}

////////////////////////////////////////////////////////////////////////////////
// Read a field when a field in an unrelated class has the same name.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*member: Class3.field3a:[exact=JSUInt31|powerset={I}{O}]*/
  var field3a;
  /*member: Class3.field3b:[exact=JSUInt31|powerset={I}{O}]*/
  var field3b;

  /*member: Class3.:[exact=Class3|powerset={N}{O}]*/
  Class3() : field3a = 42 {
    /*update: [exact=Class3|powerset={N}{O}]*/
    field3b = /*[exact=Class3|powerset={N}{O}]*/ field3a;
  }
}

/*member: OtherClass3.:[exact=OtherClass3|powerset={N}{O}]*/
class OtherClass3 {
  /*member: OtherClass3.field3a:[null|powerset={null}]*/
  var field3a;
}

/*member: otherField:[null|powerset={null}]*/
otherField() {
  OtherClass3();
  Class3();
}

////////////////////////////////////////////////////////////////////////////////
// Read a field when a field in the superclass has the same name.
////////////////////////////////////////////////////////////////////////////////

/*member: SuperClass5.:[exact=SuperClass5|powerset={N}{O}]*/
class SuperClass5 {
  /*member: SuperClass5.field5a:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field5a;
}

class Class5 extends SuperClass5 {
  /*member: Class5.field5a:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field5a;
  /*member: Class5.field5b:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field5b;

  /*member: Class5.:[exact=Class5|powerset={N}{O}]*/
  Class5() : field5a = 42 {
    /*update: [exact=Class5|powerset={N}{O}]*/
    field5b = /*[exact=Class5|powerset={N}{O}]*/ field5a;
  }
}

/*member: superclassField:[null|powerset={null}]*/
superclassField() {
  SuperClass5();
  Class5();
}

////////////////////////////////////////////////////////////////////////////////
// Read a field when a field in a subclass has the same name.
////////////////////////////////////////////////////////////////////////////////

class Class4 {
  /*member: Class4.field4a:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field4a;
  /*member: Class4.field4b:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field4b;

  /*member: Class4.:[exact=Class4|powerset={N}{O}]*/
  Class4() : field4a = 42 {
    /*update: [subclass=Class4|powerset={N}{O}]*/
    field4b = /*[subclass=Class4|powerset={N}{O}]*/ field4a;
  }
}

class SubClass4 extends Class4 {
  /*member: SubClass4.field4a:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field4a;

  /*member: SubClass4.:[exact=SubClass4|powerset={N}{O}]*/
  SubClass4() : field4a = 42;
}

/*member: subclassFieldRead:[null|powerset={null}]*/
subclassFieldRead() {
  Class4();
  SubClass4();
}

////////////////////////////////////////////////////////////////////////////////
// Write to a field when a field in a subclass has the same name.
////////////////////////////////////////////////////////////////////////////////

class Class6 {
  /*member: Class6.field6a:[exact=JSUInt31|powerset={I}{O}]*/
  var field6a;
  /*member: Class6.field6b:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field6b;

  /*member: Class6.:[exact=Class6|powerset={N}{O}]*/
  Class6() : field6a = 42 {
    /*update: [subclass=Class6|powerset={N}{O}]*/
    field6b = /*[subclass=Class6|powerset={N}{O}]*/ field6a;
  }
}

class SubClass6 extends Class6 {
  /*member: SubClass6.field6b:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field6b;

  /*member: SubClass6.:[exact=SubClass6|powerset={N}{O}]*/
  SubClass6() : field6b = 42;

  /*member: SubClass6.access:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  get access => super.field6b;
}

/*member: subclassFieldWrite:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
subclassFieldWrite() {
  Class6();
  return SubClass6(). /*[exact=SubClass6|powerset={N}{O}]*/ access;
}

////////////////////////////////////////////////////////////////////////////////
// Write to a field when a field in only one of the subclasses has the same
// name.
////////////////////////////////////////////////////////////////////////////////

class Class9 {
  /*member: Class9.field9a:[exact=JSUInt31|powerset={I}{O}]*/
  var field9a;
  /*member: Class9.field9b:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field9b;

  /*member: Class9.:[exact=Class9|powerset={N}{O}]*/
  Class9() : field9a = 42 {
    /*update: [subclass=Class9|powerset={N}{O}]*/
    field9b = /*[subclass=Class9|powerset={N}{O}]*/ field9a;
  }
}

class SubClass9a extends Class9 {
  /*member: SubClass9a.field9b:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field9b;

  /*member: SubClass9a.:[exact=SubClass9a|powerset={N}{O}]*/
  SubClass9a() : field9b = 42;

  /*member: SubClass9a.access:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  get access => super.field9b;
}

/*member: SubClass9b.:[exact=SubClass9b|powerset={N}{O}]*/
class SubClass9b extends Class9 {}

/*member: subclassesFieldWrite:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
subclassesFieldWrite() {
  Class9();
  SubClass9b();
  return SubClass9a(). /*[exact=SubClass9a|powerset={N}{O}]*/ access;
}

////////////////////////////////////////////////////////////////////////////////
// Invoke a field when a field in one of the subclasses has the same name.
////////////////////////////////////////////////////////////////////////////////

class Class7 {
  /*member: Class7.field7a:[exact=JSUInt31|powerset={I}{O}]*/
  var field7a;
  /*member: Class7.field7b:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field7b;

  /*member: Class7.:[exact=Class7|powerset={N}{O}]*/
  Class7() : field7a = 42 {
    field7b /*invoke: [subclass=Class7|powerset={N}{O}]*/ (
      /*[subclass=Class7|powerset={N}{O}]*/ field7a,
    );
  }
}

class SubClass7 extends Class7 {
  /*member: SubClass7.field7b:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field7b;

  /*member: SubClass7.:[exact=SubClass7|powerset={N}{O}]*/
  SubClass7() : field7b = 42;
}

/*member: subclassFieldInvoke:[null|powerset={null}]*/
subclassFieldInvoke() {
  Class7();
  SubClass7();
}

////////////////////////////////////////////////////////////////////////////////
// Invoke a method when a method in one of the subclasses has the same name.
////////////////////////////////////////////////////////////////////////////////

abstract class Class8 {
  /*member: Class8.field8:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field8;

  /*member: Class8.:[subclass=Class8|powerset={N}{O}]*/
  Class8() {
    /*invoke: [subclass=Class8|powerset={N}{O}]*/
    method8();
  }

  method8();
}

/*member: SubClass8a.:[exact=SubClass8a|powerset={N}{O}]*/
class SubClass8a extends Class8 {
  /*member: SubClass8a.method8:[null|powerset={null}]*/
  method8() {
    /*update: [exact=SubClass8a|powerset={N}{O}]*/
    field8 = 42;
  }
}

/*member: SubClass8b.:[exact=SubClass8b|powerset={N}{O}]*/
class SubClass8b extends Class8 {
  /*member: SubClass8b.method8:[null|powerset={null}]*/
  method8() {}
}

/*member: subclassFieldSet:[null|powerset={null}]*/
subclassFieldSet() {
  SubClass8a();
  SubClass8b();
}
