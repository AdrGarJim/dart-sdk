// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

/*member: Foo.:[exact=Foo|powerset=0]*/
class Foo {
  /*member: Foo._#Foo#x#AI:[sentinel|exact=JSUInt31|powerset=2]*/
  /*member: Foo.x:[exact=JSUInt31|powerset=0]*/
  late int /*[exact=Foo|powerset=0]*/ /*update: [exact=Foo|powerset=0]*/ x = 42;
}

/*member: main:[null|powerset=1]*/
void main() {
  makeLive(test(Foo()));
}

@pragma('dart2js:noInline')
/*member: test:[exact=JSUInt31|powerset=0]*/
int test(Foo /*[exact=Foo|powerset=0]*/ foo) =>
    foo. /*[exact=Foo|powerset=0]*/ x;
