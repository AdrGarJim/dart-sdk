# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the monorepo builders.
"""

load("//lib/dart.star", "dart")
load("//lib/priority.star", "priority")

luci.gitiles_poller(
    name = "dart-gitiles-trigger-monorepo",
    bucket = "ci",
    repo = "https://dart.googlesource.com/monorepo/",
    refs = ["refs/heads/main"],
)

luci.console_view(
    name = "monorepo",
    repo = "https://dart.googlesource.com/monorepo",
    title = "Monorepo Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "flutter-engine",
    repo = "https://dart.googlesource.com/monorepo",
    title = "Dart/Flutter Engine Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "flutter-web",
    repo = "https://dart.googlesource.com/monorepo",
    title = "Dart/Flutter Web Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

dart.ci_sandbox_builder(
    name = "flutter-linux",
    channels = [],
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 180 * time.minute,
    notifies = None,
    priority = priority.normal,
    properties = {
        "$flutter/goma": {"server": "goma.chromium.org"},
        "clobber": False,
        "config_name": "host_linux",
        "environment": "unused",
        "goma_jobs": "200",
    },
    triggered_by = ["dart-gitiles-trigger-monorepo"],
    schedule = "triggered",
)
luci.console_view_entry(
    builder = "flutter-linux",
    short_name = "engine",
    category = "coordinator",
    console_view = "monorepo",
)
luci.console_view_entry(
    builder = "flutter-linux",
    short_name = "engine",
    category = "coordinator",
    console_view = "flutter-engine",
)
dart.try_builder(
    "flutter-linux",
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 180 * time.minute,
    properties = {
        "$flutter/goma": {"server": "goma.chromium.org"},
        "builder_name_suffix": "-try",
        "clobber": False,
        "config_name": "host_linux",
        "environment": "unused",
        "goma_jobs": "200",
    },
    on_cq = False,
    cq_branches = ["main"],
)

dart.ci_sandbox_builder(
    name = "flutter-web",
    channels = [],
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 180 * time.minute,
    notifies = None,
    priority = priority.normal,
    properties = {
        "$flutter/goma": {"server": "goma.chromium.org"},
        "clobber": False,
        "config_name": "web_linux",
        "environment": "unused",
        "goma_jobs": "200",
    },
    triggered_by = ["dart-gitiles-trigger-monorepo"],
    schedule = "triggered",
)
luci.console_view_entry(
    builder = "flutter-web",
    short_name = "web",
    category = "coordinator",
    console_view = "monorepo",
)
luci.console_view_entry(
    builder = "flutter-web",
    short_name = "web",
    category = "coordinator",
    console_view = "flutter-web",
)
dart.try_builder(
    "flutter-web",
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 180 * time.minute,
    properties = {
        "$flutter/goma": {"server": "goma.chromium.org"},
        "builder_name_suffix": "-try",
        "clobber": False,
        "config_name": "web_linux",
        "environment": "unused",
        "goma_jobs": "200",
    },
    on_cq = False,
    cq_branches = ["main"],
)

def monorepo_builder(name, short_name, console):
    dart.ci_sandbox_builder(
        name = name,
        channels = [],
        dimensions = {"pool": "dart.tests"},
        executable = dart.flutter_recipe("engine_v2/builder"),
        execution_timeout = 60 * time.minute,
        notifies = None,
        priority = priority.normal,
        triggered_by = [],
        schedule = None,
    )
    luci.console_view_entry(
        builder = name,
        short_name = short_name,
        category = console,
        console_view = "monorepo",
    )
    luci.console_view_entry(
        builder = name,
        short_name = short_name,
        console_view = console,
    )
    dart.try_builder(
        name,
        bucket = "try.monorepo",
        executable = dart.flutter_recipe("engine_v2/builder"),
        execution_timeout = 60 * time.minute,
        dimensions = {"pool": "dart.tests"},
        on_cq = False,
        cq_branches = [],
    )

monorepo_builder(
    "flutter-linux-android_debug",
    "android-debug",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_profile",
    "android-profile",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_release",
    "android-release",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_debug_arm64",
    "android-debug-arm64",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_profile_arm64",
    "android-profile-arm64",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_release_arm64",
    "android-release-arm64",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_debug_x64",
    "android-debug-x64",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_profile_x64",
    "android-profile-x64",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_release_x64",
    "android-release-x64",
    "flutter-engine",
)
monorepo_builder(
    "flutter-linux-android_debug_x86",
    "android-debug-x86",
    "flutter-engine",
)
monorepo_builder("flutter-linux-host_debug", "debug", "flutter-engine")
monorepo_builder("flutter-linux-host_debug_unopt", "debug-unopt", "flutter-engine")
monorepo_builder("flutter-linux-host_profile", "profile", "flutter-engine")
monorepo_builder("flutter-linux-host_release", "release", "flutter-engine")
monorepo_builder("flutter-linux-wasm_release", "wasm", "flutter-web")

def monorepo_tester(name, short_name, console):
    dart.ci_sandbox_builder(
        name = name,
        channels = [],
        dimensions = {"pool": "dart.tests"},
        executable = dart.flutter_recipe("engine_v2/tester"),
        execution_timeout = 90 * time.minute,
        notifies = None,
        priority = priority.normal,
        triggered_by = [],
        schedule = None,
    )
    luci.console_view_entry(
        builder = name,
        short_name = short_name,
        category = console,
        console_view = "monorepo",
    )
    luci.console_view_entry(
        builder = name,
        short_name = short_name,
        console_view = console,
    )
    dart.try_builder(
        name,
        bucket = "try.monorepo",
        executable = dart.flutter_recipe("engine_v2/tester"),
        execution_timeout = 90 * time.minute,
        dimensions = {"pool": "dart.tests"},
        on_cq = False,
        cq_branches = [],
    )

monorepo_tester("flutter-linux-flutter-plugins", "plugins", "flutter-engine")
monorepo_tester("flutter-linux-framework-coverage", "coverage", "flutter-engine")
monorepo_tester("flutter-linux-framework-tests-libraries", "fl", "flutter-engine")
monorepo_tester("flutter-linux-framework-tests-misc", "fm", "flutter-engine")
monorepo_tester("flutter-linux-framework-tests-slow", "fs", "flutter-engine")
monorepo_tester("flutter-linux-framework-tests-widgets", "fw", "flutter-engine")
monorepo_tester("flutter-linux-tool-tests", "tool", "flutter-engine")
monorepo_tester("flutter-linux-customer-testing", "customer_testing", "flutter-engine")
monorepo_tester("flutter-linux-web-tests-0", "wt0", "flutter-web")
monorepo_tester("flutter-linux-web-tests-1", "wt1", "flutter-web")
monorepo_tester("flutter-linux-web-tests-2", "wt2", "flutter-web")
monorepo_tester("flutter-linux-web-tests-3", "wt3", "flutter-web")
monorepo_tester("flutter-linux-web-tests-4", "wt4", "flutter-web")
monorepo_tester("flutter-linux-web-tests-5", "wt5", "flutter-web")
monorepo_tester("flutter-linux-web-tests-6", "wt6", "flutter-web")
monorepo_tester("flutter-linux-web-tests-7-last", "wt7", "flutter-web")
monorepo_tester("flutter-linux-web-tool-tests", "wtool", "flutter-web")
