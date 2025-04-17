// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class B {
  call<T>();
}

/*member: C.:[exact=C|powerset={N}]*/
class C implements B {
  /*member: C.call:[null|powerset={null}]*/
  call<T>() => print(T);
}

abstract class A {}

class Wrapper {
  /*member: Wrapper.:[exact=Wrapper|powerset={N}]*/
  Wrapper(
    this. /*[exact=C|powerset={N}]*/ b,
    this. /*[exact=C|powerset={N}]*/ call,
  );
  /*member: Wrapper.b:[exact=C|powerset={N}]*/
  final B b;
  /*member: Wrapper.call:[exact=C|powerset={N}]*/
  final B call;
}

/*member: main:[null|powerset={null}]*/
void main() {
  B b = C();
  b/*invoke: [exact=C|powerset={N}]*/ <A>();
  Wrapper(b, b).b<A> /*invoke: [exact=Wrapper|powerset={N}]*/ ();
  (Wrapper(b, b). /*[exact=Wrapper|powerset={N}]*/ b)<
    A
  > /*invoke: [exact=C|powerset={N}]*/ ();
  Wrapper(b, b).call<A> /*invoke: [exact=Wrapper|powerset={N}]*/ ();
  (Wrapper(b, b). /*[exact=Wrapper|powerset={N}]*/ call)<
    A
  > /*invoke: [exact=C|powerset={N}]*/ ();
}
