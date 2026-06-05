"""fastverk_build — the shared build/CI toolkit.

Two surfaces:

  * **CI generation** — `gitlab_ci` / `gitlab_job` / `gitlab_reference`
    re-exported from rules_gitlab, so a repo loads one toolkit module
    to author `.gitlab-ci.yml` from typed Starlark.
  * **Runner image** — `bazel_runner_image`, a base OCI image that
    layers a pinned bazelisk onto distroless/cc. Per-org runner images
    (e.g. savvi/aion/build) build FROM this, adding their own
    toolchain/auth layers; CI jobs run on the result.
"""

load("@rules_gitlab//gitlab:defs.bzl", _gitlab_ci = "gitlab_ci", _gitlab_job = "gitlab_job", _gitlab_reference = "gitlab_reference")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_load", "oci_push")
load("@rules_pkg//pkg:mappings.bzl", "pkg_attributes", "pkg_files")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

# Re-export the CI-generation surface so consumers depend on one module.
gitlab_ci = _gitlab_ci
gitlab_job = _gitlab_job
gitlab_reference = _gitlab_reference

def bazel_runner_image(
        name,
        bazel_version = None,
        base = "@fastverk_build_distroless_cc",
        repository = None,
        env = None,
        labels = None,
        visibility = None):
    """A base CI runner image: pinned bazelisk on distroless/cc.

    The entrypoint is bazelisk; setting `bazel_version` bakes
    `USE_BAZEL_VERSION` so bazelisk fetches that exact bazel at runtime
    (over TLS — distroless/cc carries ca-certs). The base is minimal by
    design (glibc + ca-certs, no shell/git); extend it with your own
    layers — or override `base` — for jobs that need more. The bazelisk
    binary is selected by target CPU (amd64/arm64).

    Emits `<name>` (oci_image), `<name>_tarball` (oci_load → local
    docker/podman), and, when `repository` is set, `<name>_push`
    (`bazel run :<name>_push -- --tag <sha>`).

    Args:
      name: target name for the image.
      bazel_version: bazel version bazelisk should run (USE_BAZEL_VERSION).
      base: base image label. Defaults to the pinned distroless/cc.
      repository: ghcr-style repo path for push + the default tag.
      env: extra env vars baked into the image.
      labels: OCI labels (dict) to record on the image.
      visibility: bazel visibility for the produced targets.
    """
    env = dict(env or {})
    if bazel_version:
        env["USE_BAZEL_VERSION"] = bazel_version

    # bazelisk → /usr/local/bin/bazelisk (0755), per target CPU.
    pkg_files(
        name = name + "_bin",
        srcs = select({
            "@platforms//cpu:arm64": ["@bazelisk_arm64//file"],
            "//conditions:default": ["@bazelisk_amd64//file"],
        }),
        attributes = pkg_attributes(mode = "0755"),
        prefix = "usr/local/bin",
        visibility = ["//visibility:private"],
    )
    pkg_tar(
        name = name + "_layer",
        srcs = [":" + name + "_bin"],
        visibility = ["//visibility:private"],
    )

    annotations = {}
    if repository:
        annotations["org.opencontainers.image.ref.name"] = repository

    oci_image(
        name = name,
        base = base,
        entrypoint = ["/usr/local/bin/bazelisk"],
        env = env,
        tars = [name + "_layer"],
        labels = labels,
        annotations = annotations,
        visibility = visibility,
    )

    oci_load(
        name = name + "_tarball",
        image = ":" + name,
        repo_tags = [(repository or name) + ":latest"],
        visibility = visibility,
    )

    if repository:
        oci_push(
            name = name + "_push",
            image = ":" + name,
            repository = repository,
            visibility = visibility,
        )
