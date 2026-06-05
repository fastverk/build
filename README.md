# fastverk_build

The shared fastverk build/CI toolkit. One module to author CI from
Starlark and to build a base Bazel runner image.

## Surfaces

| Symbol | What |
|---|---|
| `gitlab_ci` / `gitlab_job` / `gitlab_reference` | Generate a `.gitlab-ci.yml` from typed Starlark (re-exported from `rules_gitlab`; deterministic YAML, schema-validated, `write_source_files` write-back). |
| `bazel_runner_image(name, bazel_version, …)` | A base OCI CI runner image: a pinned bazelisk on distroless/cc. Per-org images build FROM this. |
| `github_actions_runner_image(name, bazel_version, …)` | Shared fastverk GitHub Actions linux runner image surface, published separately from the generic Bazel runner. |

## CI generation

```python
load("@fastverk_build//build:defs.bzl", "gitlab_ci", "gitlab_job")

gitlab_ci(
    name = "ci",
    stages = ["test"],
    jobs = {"test": gitlab_job(stage = "test", script = ["bazel test //..."])},
    write_to = ".gitlab-ci.yml",
)
```

`bazel run :ci.update` writes the file; `bazel test :ci.update` checks
it's current; `:ci_validate` schema-checks it. See `rules_gitlab` for
the full `gitlab_ci` API.

## Runner image

```python
load("@fastverk_build//build:defs.bzl", "bazel_runner_image", "github_actions_runner_image")

bazel_runner_image(
    name = "runner",
    bazel_version = "7.4.1",                     # baked as USE_BAZEL_VERSION
    repository = "ghcr.io/fastverk/bazel-runner",
)

github_actions_runner_image(
    name = "gha_runner",
    bazel_version = "7.4.1",
)
```

- `bazel run :runner_tarball` loads it into the local docker/podman daemon.
- `bazel run :runner_push -- --tag <sha>` pushes to the registry.

The base is intentionally minimal (distroless/cc — glibc + ca-certs, no
shell or git). bazelisk fetches the pinned bazel at runtime over TLS.
For jobs needing git/toolchains, layer them on or override `base`; this
is the **base** image other runner images build FROM (e.g.
`savvi/aion/build`).

The GitHub Actions wrapper is a named publishing surface for the shared
fastverk linux runner image. Hosted macOS jobs remain separate where CI
needs platform coverage.

## Install

```python
bazel_dep(name = "fastverk_build", version = "0.0.1")
```
