// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' show M;

/// A dynamic module can apply an exposed mixin.
void main() async {
  final o = (await helper.load('entry1.dart')) as M;
  Expect.equals(3, o.method1());
  Expect.equals('*3 2', o.method2());
  helper.done();
}
