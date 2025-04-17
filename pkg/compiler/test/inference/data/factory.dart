// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.generative:[exact=A|powerset={N}]*/
  A.generative();

  factory A.redirect() = B;

  /*member: A.fact:[exact=C|powerset={N}]*/
  factory A.fact() => C();
}

/*member: B.:[exact=B|powerset={N}]*/
class B implements A {}

/*member: C.:[exact=C|powerset={N}]*/
class C implements A {}

/*member: main:[null|powerset={null}]*/
main() {
  createGenerative();
  createRedirecting();
  createFactory();
}

/*member: createGenerative:[exact=A|powerset={N}]*/
createGenerative() => A.generative();

/*member: createRedirecting:[exact=B|powerset={N}]*/
createRedirecting() => A.redirect();

/*member: createFactory:[exact=C|powerset={N}]*/
createFactory() => A.fact();
