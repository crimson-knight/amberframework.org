---
title: "Amber 2.0 Beta"
section: ""
order: 10
is_section: true
description: "Install, verify, and evaluate Amber 2.0.0-beta.2"
---

# Amber 2.0 Beta

Amber `2.0.0-beta.2` is available for evaluation. This is a prerelease: expect
breaking changes and do not treat it as a production-support promise.

The release-gated first-run path is a server-rendered ECR web application
created by the standalone Amber CLI. It includes routing, controllers, typed
configuration, sessions, static files, tests, and a development watcher without
requiring a database.

```bash
brew install amberframework/amber_cli/amber_cli
amber new my_app --type web
cd my_app
crystal spec
amber watch
```

Start with [Installation](getting-started/installation/) for the platform
matrix, checksums, and troubleshooting, then follow the
[web-app walkthrough](getting-started/). The
[web template reference](guides/web-template/) explains every generated layer
and its release boundary.

## What is in the framework beta

- MVC controllers and ECR views
- routing, pipelines, constraints, and named routes
- typed request schemas and validation
- memory-backed jobs, sessions, and WebSocket pub/sub
- mailer APIs
- typed YAML configuration with environment-variable overrides
- standalone CLI and diagnostics LSP

## What is preview

Persistence/authentication resource generators, Grant integration, Gemma file
attachments, the separate asset pipeline, and native-app generation have useful
code and documentation, but they are not part of the beta web-app release gate.
They may require unpublished or moving dependencies. Preview pages are labeled
so new users do not mistake them for the zero-setup path.

See [Beta support](beta-support/) for the exact platform and generator matrix.

## Migrating

Amber V2 removes Kilt and Slang, stops bundling database drivers, adopts typed
configuration, and extracts the CLI from the framework repository. Existing
apps should follow the [migration guide](migration-guide/) and pin the beta
instead of a moving development branch.

## Help

- [Discord](https://discord.gg/vwvP5zakSn)
- [Framework issues](https://github.com/amberframework/amber/issues)
- [CLI issues](https://github.com/amberframework/amber_cli/issues)
- [Homebrew issues](https://github.com/amberframework/homebrew-amber_cli/issues)
