# Changelog

All notable changes to fastverk_build. The format is loosely
[Keep a Changelog](https://keepachangelog.com/) — version headers
mirror the published bazel-registry entries.

## 0.0.1 — initial toolkit

The shared build/CI toolkit (D14). Two surfaces:

- **CI generation** — re-exports `gitlab_ci` / `gitlab_job` /
  `gitlab_reference` from rules_gitlab 0.2.0, so a repo loads one
  toolkit module to author `.gitlab-ci.yml` from typed Starlark.
- **`bazel_runner_image(name, bazel_version, base, repository, …)`** —
  a base OCI CI runner image layering a pinned bazelisk (1.25.0,
  amd64/arm64 by target CPU) on distroless/cc. `bazel_version` bakes
  `USE_BAZEL_VERSION`. Emits `<name>` / `<name>_tarball` /
  `<name>_push`. Mirrors fastverk's `rust_service_image` layout.
