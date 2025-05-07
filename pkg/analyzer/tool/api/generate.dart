// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generates the file `api.txt`, which describes the analyzer public API.
library;

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tool/api.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

Future<void> main() async {
  await GeneratedContent.generateAll(analyzerPkgPath, allTargets);
}

/// The path to the `analyzer` package.
final String analyzerPkgPath = normalize(
  join(pkg_root.packageRoot, 'analyzer'),
);
