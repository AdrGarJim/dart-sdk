// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Color {
  final int x;
  Color.red(this.x);
}

void main() {
  Color c = const .red(1);

  // With whitespace
  Color c = const .   red  (1);
}
