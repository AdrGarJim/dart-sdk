// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: Base.:[subclass=Base|powerset={N}]*/
abstract class Base {}

/*member: Child1.:[exact=Child1|powerset={N}]*/
class Child1 extends Base {}

/*member: Child2.:[exact=Child2|powerset={N}]*/
class Child2 extends Base {}

/*member: trivial:Value([exact=JSBool|powerset={I}], value: true, powerset: {I})*/
bool trivial(/*[exact=JSBool|powerset={I}]*/ x) => true;

/*member: either:Union([exact=Child1|powerset={N}], [exact=Child2|powerset={N}], powerset: {N})*/
Base either =
    DateTime.now()
                . /*[exact=DateTime|powerset={N}]*/ millisecondsSinceEpoch /*invoke: [subclass=JSInt|powerset={I}]*/ >
            0
        ? Child2()
        : Child1();

/*member: test1:Union(null, [exact=Child1|powerset={N}], [exact=Child2|powerset={N}], powerset: {null}{N})*/
test1() {
  Base child = either;
  if (trivial(child is Child1 && true)) return child;
  return null;
}

/*member: test2:Union(null, [exact=Child1|powerset={N}], [exact=Child2|powerset={N}], powerset: {null}{N})*/
test2() {
  Base child = either;
  if (child is Child1 || trivial(child is Child1 && true)) return child;
  return null;
}

/*member: test3:[null|exact=Child2|powerset={null}{N}]*/
test3() {
  Base child = either;
  if (trivial(child is Child1 && true) && child is Child2) return child;
  return null;
}

/*member: test4:[null|exact=Child2|powerset={null}{N}]*/
test4() {
  Base child = either;
  if (child is Child2 && trivial(child is Child1 && true)) return child;
  return null;
}

/*member: test5:Union(null, [exact=Child1|powerset={N}], [exact=Child2|powerset={N}], powerset: {null}{N})*/
test5() {
  Base child = either;
  if ((child is Child1 && true) /*invoke: [exact=JSBool|powerset={I}]*/ ==
      false)
    return child;
  return null;
}

/*member: test6:Union(null, [exact=Child1|powerset={N}], [exact=Child2|powerset={N}], powerset: {null}{N})*/
test6() {
  Base child = either;
  if (trivial(child is Child1 ? false : true)) return child;
  return null;
}

/*member: test7:Union(null, [exact=Child1|powerset={N}], [exact=Child2|powerset={N}], powerset: {null}{N})*/
test7() {
  Base child = either;
  if (trivial(trivial(child is Child1 && true))) return child;
  return null;
}

/*member: main:[null|powerset={null}]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
}
