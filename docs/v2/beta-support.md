---
title: "Beta Support"
section: ""
order: 15
description: "Supported platforms and feature boundaries for Amber 2.0.0-beta.2"
---

# Amber V2 Beta Support

Platform support has three separate signals:

- **Web compile** means CI built the Amber CLI, generated a clean web app,
  installed its dependencies, ran its specs, and compiled the application on
  that operating system and CPU.
- **Install artifact** means the current CLI release publishes a ready-to-use
  archive or package for that target.
- **Release-gated** means the complete installation, generation, dependency,
  spec, build, launch, homepage, and static-asset sequence must pass on that
  platform before the beta is published.

One signal does not silently imply the others.

## Platform matrix

| Platform | Clean web compile | CLI 2.0.3 install artifact | Beta release gate |
|---|---|---|---|
| Apple Silicon macOS | Verified | Homebrew and `darwin-arm64` archive | Yes |
| x86_64 Linux | Verified | Homebrew or `linux-x86_64` archive | Yes |
| Linux ARM64 | Verified on GitHub-hosted ARM64 Linux | Source build; the next-release workflow now builds and smoke-tests `linux-arm64` | No |
| Intel macOS | Not currently verified | None | No |
| Windows x86_64 | Verified with the candidate render-path fix; released beta.2 still fails on controller-relative ECR path handling | None | No |

The [platform compile pull request](https://github.com/amberframework/amber_cli/pull/34)
is the evidence stream for Linux ARM64 and Windows. The Windows run found a
real framework defect instead of being treated as a green support claim. With
the [render-path fix](https://github.com/amberframework/amber/pull/1402), the
same job now generates the app, installs dependencies, passes its request spec,
and compiles the Windows executable.

Linux ARM64 is supported for the clean web application's source-build path and
compile contract. It is not yet release-gated, and CLI 2.0.3 does not contain a
Linux ARM64 archive. Windows is deliberately not a release gate for this beta.
Its candidate result proves the repair, not compatibility in the released
beta.2 dependency; describe Windows as supported only after the framework fix
ships and that released dependency passes the same job.

## Application and generator matrix

| Command or surface | Status |
|---|---|
| `amber new APP --type web` | Supported |
| ECR views, homepage, static files, specs, build, launch | Release-gated |
| controller, schema, job, mailer, channel generators | Supported core output |
| migration generator | Supported output; applying SQL needs database tooling |
| model, scaffold, API-resource, auth generators | Preview; persistence-backed |
| `amber new APP --type native` | Preview |
| Grant, Gemma, and Asset Pipeline guides | Preview ecosystem material |

“Preview” means the code can be evaluated, but it is not included in the clean
beta web application's compile guarantee. Add preview packages only from their
own compatible official release instructions.

## Versions

- Amber framework: `2.0.0-beta.2`
- Amber CLI: `2.0.3` or newer
- Crystal: `>= 1.20.0, < 2.0`

Generated applications pin the framework prerelease exactly. Do not replace it
with `v2-dev`, `master`, or a personal fork when following the supported path.
