// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generates the file `api.txt`, which describes this package's public API.
library;

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tool/api.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

Future<void> main() async {
  await GeneratedContent.generateAll(analyzerTestingPkgPath, allTargets);
}

/// The path to the `analyzer_testing` package.
final String analyzerTestingPkgPath = normalize(
  join(pkg_root.packageRoot, 'analysis_server_plugin'),
);
