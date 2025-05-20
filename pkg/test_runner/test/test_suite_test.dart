// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unnecessary_string_escapes

import 'package:expect/expect.dart';
import 'package:test_runner/src/test_file.dart';

import 'utils.dart';

void main() {
  testNnbdRequirements();
  testVmOptions();
}

void testNnbdRequirements() {
  // Note: The backslashes are to avoid the test_runner thinking these are
  // Requirements markers for this file itself.
  var testFiles = [
    createTestFile(source: "", path: "none_test.dart"),
    createTestFile(source: "/\/ Requirements=nnbd", path: "nnbd_test.dart"),
    createTestFile(
        source: "/\/ Requirements=nnbd-legacy", path: "legacy_test.dart"),
    createTestFile(
        source: "/\/ Requirements=nnbd-weak", path: "weak_test.dart"),
    createTestFile(
        source: "/\/ Requirements=nnbd-strong", path: "strong_test.dart"),
  ];

  expectTestCases([], testFiles,
      ["language/none_test", "language/nnbd_test", "language/strong_test"]);

  expectTestCases(["--nnbd=legacy"], testFiles,
      ["language/none_test", "language/legacy_test"]);

  expectTestCases(["--nnbd=weak"], testFiles,
      ["language/none_test", "language/nnbd_test", "language/weak_test"]);

  expectTestCases(["--nnbd=strong"], testFiles,
      ["language/none_test", "language/nnbd_test", "language/strong_test"]);
}

void testVmOptions() {
  // Note: The backslashes are to avoid the test_runner thinking these are
  // Requirements markers for this file itself.
  var testFiles = [
    createTestFile(source: "", path: "vm_no_options_test.dart"),
    createTestFile(
        source: "/\/ VMOptions=--a", path: "vm_one_option_test.dart"),
    createTestFile(
        source: "/\/ VMOptions=--a --b\n/\/ VMOptions=--c",
        path: "vm_options_test.dart"),
  ];

  expectTestCases(
      [],
      testFiles,
      [
        "language/vm_no_options_test",
        "language/vm_one_option_test",
        "language/vm_options_test/0",
        "language/vm_options_test/1",
      ]);
}

void expectTestCases(List<String> options, List<TestFile> testFiles,
    List<String> expectedCaseNames,
    {String suite = "language"}) {
  var configuration = makeConfiguration(options, suite);
  var testSuite = makeTestSuite(configuration, testFiles, suite);

  var testCaseNames = <String>[];
  testSuite.findTestCases((testCase) {
    testCaseNames.add(testCase.displayName);
  }, {});

  Expect.listEquals(expectedCaseNames, testCaseNames);
}
