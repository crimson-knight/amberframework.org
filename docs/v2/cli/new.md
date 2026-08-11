---
title: "amber new"
section: "cli"
order: 10
description: "Create the supported Amber V2 beta web application"
---

# `amber new`

```bash
amber new NAME [options]
```

## Options

| Option | Default | Meaning |
|---|---|---|
| `--type web|native` | `web` | Web is supported; native is preview |
| `-d`, `--database pg|mysql|sqlite` | `sqlite` | Selects the driver, connection, and environment URLs |
| `-t`, `--template ecr` | `ecr` | Amber V2 supports ECR only |
| `--no-deps` | off | Skip automatic `shards install` |
| `-y`, `--assume-yes` | off | Disable interactive prompts |

`NAME` may be a simple name, relative path, absolute path, or `.`. For a path,
the final component becomes the project name. Paths containing spaces are
rejected.

```bash
amber new my_app
amber new my_app --type web
amber new projects/admin --type web -d sqlite
amber new /tmp/amber_smoke --type web --no-deps
amber new . --type web
```

The first two commands generate the same web application. Omitting `--type`
is the recommended first run; the explicit form is useful in automation.

## Web template contract

The generated web app contains:

- `amberframework/amber` pinned to `2.0.0-beta.3`
- Grant pinned to the reviewed V2 commit
- SQLite by default, or the selected PostgreSQL/MySQL driver
- `config/database.cr` and typed per-environment database URLs
- Micrate-powered database commands in the compiled CLI
- Crystal `>= 1.20.0, < 2.0`
- ECR layout and homepage
- typed development, test, and production YAML
- web, API, and static pipelines plus routes
- homepage request spec and `bin/` build directory
- no attachment shard, personal Amber fork, moving framework branch, or
  unselected database driver

The database option installs a complete persistence choice. SQLite is the
zero-server first run; PostgreSQL and MySQL require their matching server.

## After generation

```bash
cd my_app
# Needed only when --no-deps was used:
shards install
crystal spec
crystal build src/my_app.cr -o bin/my_app
amber generate scaffold Pet name:string:required species:string:required adopted:bool
amber database migrate
amber watch
```

Verify both `/` and `/css/app.css`.

`--type native` remains available for contributors and early adopters, but it
is not part of the Amber V2 beta install/build guarantee. Read the [native
preview guide](../guides/native-preview/) before evaluating it.
