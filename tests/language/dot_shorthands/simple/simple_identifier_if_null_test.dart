// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in an if-null `??` expression.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';
import 'package:expect/expect.dart';

Color colorTest(Color? color) => color ?? .blue;

void noContextLHSContextColor(Color? color) {
  color ?? .blue;
}

Integer integerTest(Integer? integer) => integer ?? .one;

void noContextLHSContextInteger(Integer? integer) {
  integer ?? .one;
}

IntegerExt integerExtTest(IntegerExt? integer) => integer ?? .one;

void noContextLHSContextIntegerExt(IntegerExt? integer) {
  integer ?? .one;
}

IntegerMixin integerMixinTest(IntegerMixin? integer) =>
    integer ?? .mixinOne;

void noContextLHSContextIntegerMixin(IntegerMixin? integer) {
  integer ?? .mixinOne;
}

void main() {
  // Enum
  Expect.equals(colorTest(null), Color.blue);
  Expect.equals(colorTest(Color.red), Color.red);

  noContextLHSContextColor(null);
  noContextLHSContextColor(Color.red);

  // Class
  Expect.equals(integerTest(null), Integer.one);
  Expect.equals(integerTest(Integer.two), Integer.two);

  noContextLHSContextInteger(null);
  noContextLHSContextInteger(Integer.one);

  Integer possiblyNullableInteger = .nullable ?? Integer.one;

  // Extension type
  Expect.equals(integerExtTest(null), IntegerExt.one);
  Expect.equals(integerExtTest(IntegerExt.two), IntegerExt.two);

  noContextLHSContextIntegerExt(null);
  noContextLHSContextIntegerExt(IntegerExt.one);

  IntegerExt possiblyNullableIntegerExt = .nullable ?? IntegerExt.one;
  IntegerExt possiblyNullableIntegerExt2 = .one ?? IntegerExt.one;

  // Mixin
  Expect.equals(integerMixinTest(null), IntegerMixin.mixinOne);
  Expect.equals(integerMixinTest(IntegerMixin.mixinTwo), IntegerMixin.mixinTwo);

  noContextLHSContextIntegerMixin(null);
  noContextLHSContextIntegerMixin(IntegerMixin.mixinOne);

  IntegerMixin possiblyNullableIntegerMixin = .mixinNullable ?? IntegerMixin.mixinOne;
}
