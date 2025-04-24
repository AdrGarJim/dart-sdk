// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for working with the "active" Dart SDK that a given analysis
/// server process is running on.
///
/// These are copied from the dartdev package's 'lib/src/sdk.dart'.
library;

import 'dart:io';

import 'package:path/path.dart' as path;

final Sdk sdk = Sdk._instance;

/// A utility class for finding and referencing paths within the Dart SDK.
class Sdk {
  static final Sdk _instance = _createSingleton();

  /// Path to SDK directory.
  final String sdkPath;

  final bool _runFromBuildRoot;

  factory Sdk() => _instance;

  Sdk._(this.sdkPath, bool runFromBuildRoot)
    : _runFromBuildRoot = runFromBuildRoot;

  /// Path to the 'dart' executable in the Dart SDK.
  String get dart {
    var basename = path.basename(Platform.executable);
    // It's possible that `Platform.executable` won't include the '.exe'
    // extension on Windows (e.g., launching `dart` from `cmd.exe` where `dart`
    // is on the `PATH`). Append '.exe' in this case so the
    // `checkArtifactExists` check won't fail.
    if (Platform.isWindows && !basename.endsWith('.exe')) {
      basename += '.exe';
    }
    return path.absolute(
      _runFromBuildRoot ? sdkPath : path.absolute(sdkPath, 'bin'),
      basename,
    );
  }

  static bool _checkArtifactExists(String path) {
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }

  static Sdk _createSingleton() {
    // Find SDK path.
    (String, bool)? trySDKPath(String executablePath) {
      // The common case, and how cli_util.dart computes the Dart SDK directory,
      // [path.dirname] called twice on Platform.executable. We confirm by
      // asserting that the directory `./bin/snapshots/` exists in this directory:
      var sdkPath = path.absolute(path.dirname(path.dirname(executablePath)));
      var snapshotsDir = path.join(sdkPath, 'bin', 'snapshots');
      var runFromBuildRoot = false;
      var type = FileSystemEntity.typeSync(snapshotsDir);
      if (type != FileSystemEntityType.directory &&
          type != FileSystemEntityType.link) {
        // This is the less common case where the user is in
        // the checked out Dart SDK, and is executing `dart` via:
        // ./out/ReleaseX64/dart ... or in google3.
        sdkPath = path.absolute(path.dirname(executablePath));
        snapshotsDir = sdkPath;
        runFromBuildRoot = true;
      }

      // Try to locate the DartDev snapshot to determine if we're able to find
      // the SDK snapshots with this SDK path. This is meant to handle
      // non-standard SDK layouts that can involve symlinks (e.g., Brew
      // installations, google3 tests, etc).
      if (!_checkArtifactExists(
        path.join(snapshotsDir, 'dartdev.dart.snapshot'),
      )) {
        return null;
      }
      return (sdkPath, runFromBuildRoot);
    }

    var (sdkPath, runFromBuildRoot) =
        trySDKPath(Platform.resolvedExecutable) ??
        trySDKPath(Platform.executable)!;

    return Sdk._(sdkPath, runFromBuildRoot);
  }
}
