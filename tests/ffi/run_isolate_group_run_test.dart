// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests IsolateGroup.runSync - what works, what doesn't.
//
// VMOptions=--experimental-shared-data
// VMOptions=--experimental-shared-data --use-slow-path
// VMOptions=--experimental-shared-data --use-slow-path --stacktrace-every=100
// VMOptions=--experimental-shared-data --dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--experimental-shared-data --test_il_serialization
// VMOptions=--experimental-shared-data --profiler --profile_vm=true
// VMOptions=--experimental-shared-data --profiler --profile_vm=false

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import 'dart:concurrent';
import 'dart:isolate';

import "package:expect/expect.dart";

var foo = 42;
var foo_no_initializer;

@pragma('vm:shared')
var shared_foo_no_initializer;

final foo_final = 1234;

@pragma('vm:never-inline')
updateFoo() {
  foo = 56;
}

@pragma('vm:never-inline')
updateFooNoInitializer() {
  foo_no_initializer = 78;
}

main() {
  Expect.equals(42, IsolateGroup.runSync(() => 42));

  Expect.listEquals([1, 2, 3], IsolateGroup.runSync(() => [1, 2, 3]));

  Expect.equals(1234, IsolateGroup.runSync(() => foo_final));

  IsolateGroup.runSync(() {
    shared_foo_no_initializer = 2345;
  });
  Expect.equals(2345, IsolateGroup.runSync(() => shared_foo_no_initializer));

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        throw "error";
      });
    },
    (e) => e == "error",
    'Expect thrown error',
  );

  // Documenting current limitations.
  Expect.notEquals(() {
    IsolateGroup.runSync(() {
      return Isolate.current;
    });
  }, Isolate.current);

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        print('42');
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error printing',
  );

  updateFoo();
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        return foo;
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error accessing',
  );

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        foo = 123;
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error accessing',
  );
  Expect.equals(foo, 56);

  updateFooNoInitializer();
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        return foo_no_initializer;
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error accessing',
  );

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        foo_no_initializer = 456;
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error accessing',
  );
  Expect.equals(foo_no_initializer, 78);

  print("All tests completed :)");
}
