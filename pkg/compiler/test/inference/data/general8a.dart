// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: foo:Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/
foo(
  /*Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/ x,
) {
  return x;
}

/*member: bar:[null|powerset={null}]*/
bar(
  /*Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/ x,
) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

/*member: main:[null|powerset={null}]*/
main() {
  bar(foo(false));
  bar(foo(foo(false)));
}
