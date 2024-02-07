# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
CQs for the dart Gerrit host.
"""

load("//lib/dart.star", "dart")

luci.cq(
    submit_max_burst = 2,
    submit_burst_delay = 8 * time.minute,
    status_host = "chromium-cq-status.appspot.com",
)

def default_verifiers():
    return [
        luci.cq_tryjob_verifier(
            builder = "presubmit-try",
            disable_reuse = True,
        ),
    ]

DART_GERRIT = "https://dart-review.googlesource.com/"

def sdk_cq_groups():
    for branch in dart.branches:
        luci.cq_group(
            name = "sdk-%s" % branch,
            watch = cq.refset(
                DART_GERRIT + "sdk",
                refs = ["refs/heads/%s" % branch],
            ),
            allow_submit_with_open_deps = True,
            tree_status_host = "dart-status.appspot.com",
            retry_config = cq.RETRY_NONE,
            verifiers = None,
        )

sdk_cq_groups()

luci.cq_group(
    name = "sdk-infra-config",
    watch = cq.refset(DART_GERRIT + "sdk", refs = ["refs/heads/infra/config"]),
    allow_submit_with_open_deps = True,
    tree_status_host = "dart-status.appspot.com",
    retry_config = cq.RETRY_NONE,
    verifiers = default_verifiers(),
)

def basic_cq(repository, extra_verifies = []):
    luci.cq_group(
        name = repository,
        watch = cq.refset(DART_GERRIT + repository, refs = ["refs/heads/main"]),
        allow_submit_with_open_deps = True,
        tree_status_host = "dart-status.appspot.com",
        retry_config = cq.RETRY_NONE,
        verifiers = default_verifiers() + extra_verifies,
    )

basic_cq("dart_ci")
basic_cq("dart-docker", [
    luci.cq_tryjob_verifier(
        builder = "docker-try",
    ),
])
basic_cq("deps")
basic_cq("flute")
basic_cq("homebrew-dart", [
    luci.cq_tryjob_verifier(
        builder = "homebrew-try",
    ),
])
basic_cq("recipes")

def empty_cq(repository):
    luci.cq_group(
        name = repository,
        watch = cq.refset(DART_GERRIT + repository, refs = ["refs/heads/main"]),
        allow_submit_with_open_deps = True,
        tree_status_host = "dart-status.appspot.com",
        retry_config = cq.RETRY_NONE,
        verifiers = None,
    )

empty_cq("monorepo")

luci.list_view(
    name = "cq",
    title = "SDK CQ Console",
)
