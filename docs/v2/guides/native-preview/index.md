---
title: "Native Application Preview"
section: "guides"
order: 20
description: "Generated platforms, prerequisites, and release boundaries for Amber CLI native applications"
---

# Amber V2 Native Application Preview

Amber CLI can generate a cross-platform native project, but this surface is a
preview. It is **not release-gated with the V2 web beta** and is not covered by
the clean web-template compile guarantee.

**Run from: the parent directory where `field_app/` should be created.**

```bash
amber new field_app --type native
```

The generated project uses Amber V2 application patterns without starting an
HTTP server. Its interface layer is built around Asset Pipeline UI, with
platform hosts and build scripts for desktop and mobile work.

## Platform map

| Target | Generated direction | Preview boundary |
|---|---|---|
| macOS | Native AppKit host | Requires the Apple toolchain and preview dependencies |
| iOS | UIKit host and simulator/device build scripts | Cross-compilation and signing are not part of the web beta gate |
| Android | Android host and NDK build scripts | SDK, NDK, JDK, and device setup are not part of the web beta gate |

## Generated concepts

- `config/native.yml` as the native capability manifest
- Asset Pipeline UI components for platform rendering
- macOS, iOS, and Android host projects and build scripts
- FSDD process-manager structure
- crystal-audio integration points
- platform-oriented accessibility and end-to-end test locations

These are descriptions of generated output, not a promise that every platform
builds from a clean machine today. Platform-specific prerequisites, signing,
cross-compilers, and preview shard compatibility must be proven separately
before native support can graduate.

## Choose the supported first run

For the V2 beta installation and onboarding path, create the default web app:

**Run from: the parent directory where `my_app/` should be created.**

```bash
amber new my_app
cd my_app
crystal spec
amber watch
```

Use native generation when you intend to evaluate the platform work and can
report exact toolchain results. Do not interpret “generated” as “release-gated.”
