// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: foo:[exact=JSUInt31|powerset={I}{O}]*/
foo() {
  var a = [1, 2, 3];
  return a
      . /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 3, powerset: {I}{G})*/ first;
}

/*member: main:[null|powerset={null}]*/
main() {
  foo();
}
