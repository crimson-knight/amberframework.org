---
title: "Amber CLI"
section: ""
order: 30
is_section: true
description: "Standalone Amber V2 CLI installation and command reference"
---

# Amber CLI

Amber CLI `2.0.2` is the standalone project generator, development watcher,
generator suite, database tool, and diagnostics LSP for Amber V2.

```bash
brew install amberframework/amber_cli/amber_cli
amber --version
```

The formula is `amber_cli`; the executable is `amber`.

## Supported quick start

```bash
amber new my_app --type web
cd my_app
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
| `database` | Preview for new apps | Operate an explicitly added persistence stack |
| `setup:lsp` | Available | Configure the bundled diagnostics LSP |

Use `amber --help` and `amber COMMAND --help` for the installed version's exact
syntax.
