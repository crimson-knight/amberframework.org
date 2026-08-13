---
title: "Amber 2.0 Beta"
section: ""
order: 10
is_section: true
description: "Install, verify, and evaluate Amber 2.0.0-beta.5"
---

# Amber 2.0 Beta

Amber `2.0.0-beta.5` is available for evaluation. The V2 release train remains
a prerelease, but the web path is deliberately backwards compatible and mostly
additive. Pin the exact beta, test upgrades, and do not treat it as a formal
production-support promise.

The release-gated first-run path is a server-rendered ECR web application
created by the standalone Amber CLI. It includes routing, controllers, typed
configuration, sessions, Grant ORM, Micrate migrations, SQLite, fingerprinted
static assets, tests, and a development watcher without requiring a database
server.

**Run from: a parent directory where `my_app/` can be created. Commands after
`cd my_app` run from the generated application root.**

```bash
brew install amberframework/amber_cli/amber_cli
amber new my_app
cd my_app
amber generate scaffold Pet name:string:required species:string:required adopted:bool
amber database migrate
crystal spec
amber watch
```

Web is the default application type. `amber new my_app --type web` is the
explicit equivalent. Native generation is a separate preview surface.

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
- Grant ORM with SQLite by default and PostgreSQL/MySQL options
- Micrate-powered migrations and database maintenance commands
- database-backed model and HTML CRUD scaffold generators
- deterministic CSS, JavaScript, image, font, and file fingerprinting
- manifest-aware ECR helpers, SRI, compression, and immutable asset caching
- standalone CLI and diagnostics LSP

## What is preview

Generated authentication and API resources, Gemma file attachments, and
native-app generation have useful code and documentation, but they are not part
of the beta web-app release gate. Preview pages are labeled so new users do not
mistake them for the supported path.

See [Beta support](beta-support/) for the exact platform and generator matrix.

## Migrating

Amber V2 removes Kilt and Slang, adopts typed configuration, and extracts the
CLI from the framework repository. The new CLI template selects its driver and
Grant explicitly; the framework shard itself remains independent of an ORM.
Existing apps should follow the [migration guide](migration-guide/) and pin the
beta instead of a moving development branch.

## Help

- [Discord](https://discord.gg/vwvP5zakSn)
- [Framework issues](https://github.com/amberframework/amber/issues)
- [CLI issues](https://github.com/amberframework/amber_cli/issues)
- [Homebrew issues](https://github.com/amberframework/homebrew-amber_cli/issues)
