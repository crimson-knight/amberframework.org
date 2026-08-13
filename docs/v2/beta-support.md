---
title: "Beta Support"
section: ""
order: 20
description: "Supported platforms and feature boundaries for Amber 2.0.0-beta.5"
---

# Amber V2 Beta Support

**Status checked August 13, 2026.** Amber Framework `2.0.0-beta.5` and Amber
CLI `2.0.6` are the coordinated database-backed web beta. Amber `1.5.0`
remains the stable framework line.

“Beta” describes the V2 framework release, not an expectation that ordinary
web applications will be repeatedly rewritten. The supported path includes
routing, controllers, ECR, typed configuration, request schemas, Grant ORM,
Micrate migrations, SQLite, WebSockets, jobs, mailer, local CSS, and
browser-native modules. The release gate includes fingerprinted CSS,
JavaScript, images, fonts, SRI, caching, and compression. Generated
authentication, generated API resources, Gemma attachments, and native
applications keep separate preview boundaries.

## What each platform signal means

- **Web compile** means CI built Amber CLI, generated the database-backed web
  app, installed dependencies, generated the Pet scaffold, applied its test
  migration, ran specs, and compiled the application.
- **Install artifact** means the current CLI release publishes a ready-to-use
  archive or Homebrew package for that target.
- **Release-gated** means the supported installation, generation, dependency,
  migration, spec, build, launch, HTML form, create, update, and static-asset
  sequence must pass before release.

One signal does not silently imply the others.

## Platform matrix

| Platform | Database-backed web compile | CLI 2.0.6 install artifact | Beta release gate |
|---|---|---|---|
| Apple Silicon macOS | Verified | Homebrew and `darwin-arm64` archive | Yes |
| x86-64 Linux | Verified | Homebrew or `linux-x86_64` archive | Yes |
| ARM64 Linux | Verified on GitHub-hosted ARM64 Linux | `linux-arm64` archive | Yes |
| Windows x86-64 | Verified in GitHub Actions | None | No |
| Intel macOS | Not currently verified | None | No |

The [Amber CLI 2.0.6 pull request](https://github.com/amberframework/amber_cli/pull/38)
is the current platform evidence stream. Windows installs the SQLite native library,
builds the CLI, generates the same Grant application, applies the test
migration, runs its specs, and compiles the executable. It remains outside the
release gate only because CLI `2.0.6` does not publish a Windows archive.

## Application and generator matrix

| Command or surface | Status |
|---|---|
| `amber new APP --type web` | Supported; ECR, Grant, and SQLite default |
| homepage, fingerprinted CSS/JS/images/fonts, SRI, caching, compression | Release-gated |
| `amber assets build` and `amber assets check` | Supported and release-gated |
| `amber generate model` | Supported; Grant model, spec, and migration |
| `amber generate scaffold` | Supported; model, schema, HTML CRUD, ECR views, specs, route, migration |
| `amber generate migration` | Supported; Micrate Up/Down SQL |
| `amber database` | Supported; create, drop, migrate, status, version, rollback, redo, seed |
| controller, schema, job, mailer, channel generators | Supported |
| `amber generate api` and `amber generate auth` | Preview |
| `amber new APP --type native` | Preview |
| Grant guides | Supported default web model layer |
| Asset Pipeline guides | Supported web path |
| Gemma guides | Preview ecosystem material |

“Preview” means code can be evaluated, but it is not part of the web release
gate and may require additional design or production review. Preview does not
mean that the entire framework or a generated web application is unstable.

## Persistence contract

A generated web application contains:

- Grant pinned to the reviewed V2 commit;
- exactly one selected driver: SQLite, PostgreSQL, or MySQL;
- `config/database.cr` registering the `primary` connection;
- separate development, test, and production database URLs;
- Micrate inside the compiled CLI rather than as a second app command;
- model and scaffold generators that write reversible SQL under
  `db/migrations/`.

The release smoke test uses SQLite and exercises a real create and update
through the generated ECR forms. This proves the default integration, not every
query, database feature, or production topology. PostgreSQL and MySQL users
must test against the server versions they deploy.

## Versions

- Amber V2 framework beta: `2.0.0-beta.5` — published August 13, 2026
- Amber CLI: `2.0.6` — published August 13, 2026
- Asset Pipeline: `0.37.0` — published August 12, 2026
- Grant: reviewed commit pinned by Amber CLI `2.0.6`
- Micrate: `0.16.0-beta.1`, embedded and pinned by Amber CLI `2.0.6`
- Amber stable framework: `1.5.0` — published August 1, 2026
- Crystal: `>= 1.20.0, < 2.0`

Generated applications pin the framework prerelease exactly. Do not replace it
with `v2-dev`, `master`, or a personal Amber fork when following the supported
path. See the human-readable [release notes](/releases), the
[Pet Tracker](guides/pet-tracker/) acceptance journey, and the
[V1-to-V2 migration guide](migration-guide/) for the smallest safe upgrade.
