"""Module extension pinning the bazelisk binaries the runner-image
macro layers in. bazelisk is a single static Go binary; at runtime it
reads `USE_BAZEL_VERSION` (set by `bazel_runner_image(bazel_version=…)`)
and fetches that bazel over TLS."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

# https://github.com/bazelbuild/bazelisk/releases/tag/v1.25.0
_BAZELISK_VERSION = "1.25.0"
_BAZELISK_SHA256 = {
    "amd64": "fd8fdff418a1758887520fa42da7e6ae39aefc788cf5e7f7bb8db6934d279fc4",
    "arm64": "4c8d966e40ac2c4efcc7f1a5a5cceef2c0a2f16b957e791fa7a867cce31e8fcb",
}

def _bazelisk_impl(_mctx):
    for arch, sha in _BAZELISK_SHA256.items():
        http_file(
            name = "bazelisk_" + arch,
            urls = ["https://github.com/bazelbuild/bazelisk/releases/download/v{v}/bazelisk-linux-{a}".format(
                v = _BAZELISK_VERSION,
                a = arch,
            )],
            sha256 = sha,
            downloaded_file_path = "bazelisk",
            executable = True,
        )

bazelisk = module_extension(implementation = _bazelisk_impl)
