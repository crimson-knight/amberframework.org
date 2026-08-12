---
title: "Amber CLI"
section: ""
order: 30
is_section: true
description: "Standalone Amber V2 CLI installation and command reference"
---

# Amber CLI

Amber CLI `2.0.5` is the standalone project generator, development watcher,
generator suite, database tool, and diagnostics LSP for Amber V2.

```bash
brew install amberframework/amber_cli/amber_cli
amber --version
```

The fully qualified command follows Homebrew's tap-trust model. The formula is
`amber_cli`; the executable is `amber`.

## Supported quick start

**Run from: a parent directory where `my_app/` can be created. Commands after
`cd my_app` run from the generated application root.**

```bash
amber new my_app --type web
cd my_app
shards install
amber assets check
amber generate scaffold Pet name:string:required species:string:required adopted:bool
amber database migrate
crystal spec
amber watch
```

## Commands

| Command | Beta status | Purpose |
|---|---|---|
| [`new`](new/) | Supported for web | Create web or preview native apps |
| [`generate`](generate/) | Mixed | Generate core or preview components |
| [`watch`](watch/) | Supported | Rebuild and restart the app |
| `routes` | Supported | List configured routes |
| `pipelines` | Supported | Inspect pipelines |
| `database` | Supported | Migrate, inspect, roll back, redo, and seed the generated database |
| `assets` | Supported | Build or verify the fingerprinted asset manifest |
| `setup:lsp` | Available | Configure the bundled diagnostics LSP |

Use `amber --help` and `amber COMMAND --help` for the installed version's exact
syntax.

## Asset commands

Run these from an Amber CLI `2.0.5` application root:

```bash
amber assets build
amber assets check
```

`build` fingerprints `app/assets/` into `public/assets/` and writes the manifest.
`check` verifies the manifest, emitted bytes, digests, SRI metadata, MIME types,
and precompressed files without changing them. `amber new` performs the first
build, and `amber watch` rebuilds assets before recompiling the application when
authored files change.
