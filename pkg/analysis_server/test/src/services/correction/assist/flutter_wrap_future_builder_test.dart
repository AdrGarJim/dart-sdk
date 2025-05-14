// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapFutureBuilderTest);
  });
}

@reflectiveTest
class FlutterWrapFutureBuilderTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_FUTURE_BUILDER;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_aroundBuilder() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  ^Builder(
    builder: (context) => Text(''),
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_aroundFutureBuilder() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Future<int> s) {
  ^FutureBuilder(
    future: s,
    builder: (context, snapshot) => Text(''),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

void f(Future<int> s) {
  FutureBuilder(
    future: future,
    builder: (context, asyncSnapshot) {
      return FutureBuilder(
        future: s,
        builder: (context, snapshot) => Text(''),
      );
    }
  );
}
''');
  }

  Future<void> test_aroundText() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  ^Text('a');
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

void f() {
  FutureBuilder(
    future: future,
    builder: (context, asyncSnapshot) {
      return Text('a');
    }
  );
}
''');
  }

  Future<void> test_trailingComma_disabled() async {
    // No analysis options.
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const ^Text('hi');
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, asyncSnapshot) {
        return const Text('hi');
      }
    );
  }
}
''');
  }

  Future<void> test_trailingComma_enabled() async {
    createAnalysisOptionsFile(lints: [LintNames.require_trailing_commas]);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const ^Text('hi');
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, asyncSnapshot) {
        return const Text('hi');
      },
    );
  }
}
''');
  }
}
