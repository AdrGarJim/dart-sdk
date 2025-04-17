// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we are analyzing field parameters correctly.

class A {
  /*member: A.dynamicField:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  final dynamicField;

  /*member: A.:[exact=A|powerset={N}]*/
  A() : dynamicField = 42;

  /*member: A.bar:[exact=A|powerset={N}]*/
  A.bar(
    this. /*Value([exact=JSString|powerset={I}], value: "foo", powerset: {I})*/ dynamicField,
  );
}

/*member: main:[null|powerset={null}]*/
main() {
  A();
  A.bar('foo');
}
