---
title: "Beta Support"
section: ""
order: 15
description: "Supported platforms and feature boundaries for Amber 2.0.0-beta.2"
---

# Amber V2 Beta Support

“Release-gated” means the documented installation, generation, dependency,
spec, build, launch, homepage, and static-asset checks are repeated on that
platform before the beta is published.

## Platform matrix

| Surface | Status |
|---|---|
| Apple Silicon macOS | Supported and release-gated |
| x86_64 Linux | Supported and release-gated |
| Homebrew via `amberframework/amber_cli` | Supported |
| Direct CLI release archives | Supported |
| Intel macOS, Linux ARM64, Windows | Not release-gated |

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
