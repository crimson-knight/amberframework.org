---
title: "Migration Guide"
section: ""
order: 80
is_section: true
description: "Upgrade an Amber 1.x application to the Amber 2.0 web-framework core"
---

# Migration Guide: Amber 1.x to 2.0

> Amber `2.0.0-beta.2` release-gates the framework core and ECR web template.
> Grant, Gemma, Asset Pipeline, persistence/auth generators, and native output
> are preview surfaces. Treat their migration guides as separate evaluations,
> not prerequisites for adopting the framework beta.

Migrate the framework core first and preserve working application behavior at
each step. Persistence, front-end tooling, uploads, and native output have their
own release boundaries; changing them at the same time makes a failure harder to
locate and harder to reverse.

## What changes in V2

| Application boundary | Amber 1.x starting point | Amber 2.0 path |
|---|---|---|
| Views | ECR, Slang, or Kilt | ECR for new and generated V2 views |
| JavaScript and CSS | Commonly Webpack-managed | Static files work without a bundler; Asset Pipeline is a separate preview |
| Persistence | Commonly Granite or Jennifer | No ORM or database driver is bundled; choose and verify persistence separately |
| Sessions | Redis-oriented configuration | Built-in memory adapter or an explicitly registered external adapter |
| WebSocket pub/sub | Redis-oriented configuration | Built-in in-process adapter or an explicitly registered external adapter |
| Request validation | Controller-specific parsing | Optional typed Schema API |
| File attachments | Application-specific integration | No bundled attachment library; Gemma is an ecosystem preview |

## Before changing dependencies

Create a migration branch and capture a working baseline:

1. Record the Crystal, Amber, ORM, database-driver, Redis, and asset-tool versions.
2. Run the existing specs and build the application binary.
3. Smoke-test the routes, session behavior, background work, WebSockets, and
   static assets the application actually uses.
4. Back up the database and prove the restore procedure before changing an ORM
   or running a schema migration.
5. List every Slang/Kilt template, Webpack entry point, Redis integration, and
   framework-generated file that will need an explicit decision.

Do not begin by deleting the old asset, persistence, or session configuration.
Keep the last working path available until its replacement has passed the same
checks.

## 1. Update the framework core

Pin the official Amber prerelease in `shard.yml`:

```yaml
dependencies:
  amber:
    github: amberframework/amber
    version: 2.0.0-beta.2
```

Then update dependencies and restore the baseline before adopting optional V2
features:

```bash
shards update
crystal spec
crystal build src/your_app.cr -o bin/your_app
```

Resolve compile errors against the [V2 routing](../guides/routing/),
[controllers](../guides/controllers/), [views](../guides/views/), and
[configuration](../getting-started/) guides. Keep persistence and asset-tool
changes out of this step whenever possible.

## 2. Move generated and legacy views to ECR

Amber V2 removes Kilt and Slang from the supported framework path. Convert one
view boundary at a time, preserve its rendered HTML contract, and run the
request or feature specs that exercise it. New V2 generators emit ECR.

The [Views guide](../guides/views/) documents layouts, partials, helpers, and
escaping behavior for the V2 path.

## 3. Make sessions and pub/sub explicit

Amber V2 includes in-memory session and pub/sub adapters. They keep a clean
application independent of Redis, but their state is local to one process.

Applications that require shared state across processes or hosts must register
and test an external implementation. Redis is not a built-in adapter guarantee;
it is one backend an application can integrate through the adapter interfaces.

Use the [Redis-to-adapters guide](redis-to-adapters/) to inventory the existing
behavior, then verify expiration, logout, session rotation, broadcasts, and
multi-process delivery before switching production traffic.

## 4. Keep persistence as a separate decision

The V2 web template does not install an ORM or database driver. An existing
Granite or Jennifer application may keep its current persistence layer while the
framework core is evaluated, but compatibility depends on that application's
Crystal version, shard versions, and usage. Amber does not make a blanket
compatibility promise for those combinations.

Grant is the V2 ecosystem direction for new persistence work, but its migration
material remains preview. Do not mix two ORMs in a production migration unless
the ownership of connections, transactions, migrations, and models is explicit.
Review the [model-layer boundary](../guides/models/) before using the
[Granite-to-Grant preview guide](granite-to-grant/).

## 5. Preserve working assets before replacing tooling

The supported V2 web application serves CSS, JavaScript, images, and fonts from
`public/` without requiring Node.js or a bundler. That does not require an
existing application to remove a working Webpack pipeline during the framework
upgrade.

If you evaluate native ESM or the separate Asset Pipeline project, treat it as
its own migration. Compare the generated files, import behavior, cache headers,
and production deployment before retiring the previous build. The
[Webpack-to-ESM guide](webpack-to-esm/) and [Asset Pipeline guides](../guides/assets/)
describe preview paths rather than a requirement of the web-framework beta.

## 6. Adopt optional V2 features after the baseline passes

Schema API, jobs, mailers, adapters, and expanded testing helpers can be adopted
independently. Add one application boundary, write or update its specs, and
restore the complete build before moving to the next.

## Verification gates

Use observed behavior instead of an estimated migration timeline:

| Gate | Evidence to keep |
|---|---|
| Framework | Dependency resolution, complete specs, and a compiled application binary |
| HTTP | Representative request specs for routes, pipelines, parameters, redirects, and errors |
| Sessions | Login/logout, expiration, rotation, cookie settings, and multi-process behavior where required |
| WebSockets | Subscription, broadcast, reconnect, and cross-process delivery where required |
| Assets | Production-built CSS and JavaScript, static-file responses, and browser smoke tests |
| Persistence | Database backup/restore proof, migrations, transactions, and representative reads and writes |
| Deployment | A staging build produced through the same commands and configuration used in production |

A migration boundary is complete when its previous behavior is reproduced or an
intentional change is documented and tested—not when a predetermined number of
days has elapsed.

## Getting help

When reporting a migration problem, include the smallest failing example plus
the Crystal version, Amber version, previous Amber version, relevant shard
versions, exact command, and complete output.

- Review the [Amber V2 release notes](https://github.com/amberframework/amber/releases).
- Ask in the [Amber Discord](https://discord.gg/vwvP5zakSn).
- Report framework behavior in the [Amber issue tracker](https://github.com/amberframework/amber/issues).
- Report CLI and generator behavior in the [Amber CLI issue tracker](https://github.com/amberframework/amber_cli/issues).
