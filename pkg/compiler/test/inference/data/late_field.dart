// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

/*member: Foo.:[exact=Foo|powerset={N}]*/
class Foo {
  /*member: Foo._#Foo#x#AI:[sentinel|exact=JSUInt31|powerset={late}{I}]*/
  /*member: Foo.x:[exact=JSUInt31|powerset={I}]*/
  late int /*[exact=Foo|powerset={N}]*/ /*update: [exact=Foo|powerset={N}]*/ x =
      42;
}

/*member: main:[null|powerset={null}]*/
void main() {
  makeLive(test(Foo()));
}

@pragma('dart2js:noInline')
/*member: test:[exact=JSUInt31|powerset={I}]*/
int test(Foo /*[exact=Foo|powerset={N}]*/ foo) =>
    foo. /*[exact=Foo|powerset={N}]*/ x;
