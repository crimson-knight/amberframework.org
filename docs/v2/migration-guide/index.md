---
title: "Migration Guide"
section: ""
order: 80
is_section: true
description: "Upgrade an Amber 1.x application to the Amber 2.0 web-framework core"
---

# Migration Guide: Amber 1.x to 2.0

Start with the smallest possible upgrade. For many Amber 1.x applications that
already use ECR and do not depend on Amber's old bundled integrations, the
first—and sometimes only—application change is the Amber version in
`shard.yml`. V2 is mostly additive framework work, not an invitation to rewrite
your product.

The standalone Amber CLI is independent from this runtime upgrade. Install or
update it when you want V2 generators; an existing application can change its
framework shard without being regenerated.

> Amber `2.0.0-beta.4` release-gates the framework core and the new ECR web
> template with Grant, Micrate, and SQLite. Existing applications do not have
> to replace a working ORM to adopt the framework beta. Gemma, Asset Pipeline,
> generated auth/API resources, and native output remain separate previews.

## Try the direct upgrade first

**File: `shard.yml` — change the existing `amber` dependency version.**

```yaml
dependencies:
  amber:
    github: amberframework/amber
    version: 2.0.0-beta.4
```

Keep the rest of the application's dependencies unchanged for this first pass.

**Run from: the application root, beside `shard.yml`.**

```bash
shards update amber
crystal spec
shards build
```

If those commands pass, launch the application through its normal development
command and smoke-test the routes it actually serves. You do not need to adopt
the Schema API, replace an ORM, remove working front-end tooling, or regenerate
the project merely because V2 offers newer options.

## When the direct upgrade needs a follow-up

The migration remains bounded, but it is not literally one line for every
application. Check the matching row only when the application uses that feature:

| Existing application uses | Follow-up |
|---|---|
| ECR views and public static files | Usually no view-system migration |
| Slang or another Kilt renderer | Convert those templates to ECR |
| Amber's bundled Redis assumptions | Select and verify explicit session and pub/sub adapters |
| Database drivers that arrived through Amber | Declare the application's driver directly |
| Old `YAML.mapping` configuration types | Move those types to `YAML::Serializable` |
| Framework-internal require paths | Replace them with the public Amber entry point or current API |
| A working Webpack or other asset build | Keep it during the framework upgrade; migrate it separately if useful |

This inventory is why the guide contains more than a version edit. It is a map
for the exceptions, not evidence that an ordinary Amber application must be
rebuilt.

## What changes in V2

| Application boundary | Amber 1.x starting point | Amber 2.0 path |
|---|---|---|
| Views | ECR, Slang, or Kilt | ECR for new and generated V2 views |
| JavaScript and CSS | Commonly Webpack-managed | The released manifest fingerprints browser-ready CSS, JS, images, and fonts without a bundler |
| Persistence | Commonly Granite or Jennifer | Existing apps may keep their working ORM; new CLI apps use Grant and a selected driver |
| Sessions | Redis-oriented configuration | Built-in memory adapter or an explicitly registered external adapter |
| WebSocket pub/sub | Redis-oriented configuration | Built-in in-process adapter or an explicitly registered external adapter |
| Request validation | Controller-specific parsing | Optional typed Schema API |
| File attachments | Application-specific integration | No bundled attachment library; Gemma is an ecosystem preview |

## Before changing dependencies in a production application

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

## 1. Restore the framework baseline

After the direct upgrade commands above, resolve any compile errors against the
[V2 routing](../guides/routing/),
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

## 4. Keep an existing persistence migration separate

Amber CLI `2.0.5` installs Grant and SQLite in a newly generated web
application. That default does not require an existing Granite or Jennifer
application to change ORM during the framework upgrade. Keep its current
persistence layer for the first pass, then verify compatibility against the
application's Crystal version, shard versions, and real queries.

If you choose to move to Grant, treat that as a second migration with its own
branch, database backup, restore proof, schema diff, representative reads and
writes, and rollback plan. Do not mix two ORMs unless ownership of connections,
transactions, migrations, and models is explicit. Review the
[model-layer boundary](../guides/models/) and
[Granite-to-Grant guide](granite-to-grant/) first.

## 5. Preserve working assets before replacing tooling

Released CLI `2.0.5` compiles browser-ready files from `app/assets/` into a
fingerprinted `public/assets/` manifest without requiring Node.js or a bundler.
That does not require an existing application to remove a working Webpack
pipeline during the framework upgrade.

If you adopt native ESM and the build-time Asset Pipeline contract, treat it as
its own migration. Compare the complete manifest; rewritten local
CSS and JavaScript dependencies; image, font, and binary bytes and MIME types;
import behavior; cache headers; read-only runtime; and atomic production
deployment before retiring the previous build. The
[Webpack-to-ESM guide](webpack-to-esm/) and [Asset Pipeline guides](../guides/assets/)
describe that independently reviewable migration; existing asset tooling may
remain in place while the framework dependency changes.

## 6. Adopt optional V2 features after the baseline passes

Schema API, jobs, mailers, adapters, and expanded testing helpers can be adopted
independently. Add one application boundary, write or update its specs, and
restore the complete build before moving to the next.

## 7. Migrate request validation action by action

The old `params.validation` API is deprecated, not removed. Existing blocks
continue to compile and run after the V2 framework upgrade:

**File: an existing action under `src/controllers/` — this code may remain
unchanged during the first upgrade pass.**

```crystal
validation = params.validation do
  required(:email) { |value| value.email? }
end
```

Amber plans to retain that API throughout the initial V2 compatibility window
and remove it no earlier than a later minor release such as 2.5. The exact
removal release will be announced separately. A deprecation warning is a prompt
for a gradual migration, not evidence that a V1 application must rewrite all
controllers before adopting V2.

For one action at a time:

1. create its request contract under `src/schemas/`;
2. bind it above the action with `schema :action, SchemaClass`;
3. read typed values with `validated_as(SchemaClass)` or the normalized hash
   with `validated_params`;
4. add `response_schema` when the action returns a machine-readable API
   contract; and
5. prove valid, malformed, unsupported-media, invalid-value, and invalid-response
   behavior before converting the next action.

The declared schema runs automatically before the action. Do not replace the
old validator with a manual `SchemaClass.validate(request)` call; that is not
the V2 controller API. The complete [Schema guide](../guides/schema-api/)
shows the executable request and response path with exact file locations.

## Verification gates

Use observed behavior instead of an estimated migration timeline:

| Gate | Evidence to keep |
|---|---|
| Framework | Dependency resolution, complete specs, and a compiled application binary |
| HTTP | Representative request specs for routes, pipelines, parameters, redirects, and errors |
| Sessions | Login/logout, expiration, rotation, cookie settings, and multi-process behavior where required |
| WebSockets | Subscription, broadcast, reconnect, and cross-process delivery where required |
| Assets | One build manifest; strict CSS, JavaScript, image, font, and binary lookups; rewritten dependency URLs; MIME/cache/compression responses; read-only runtime; and browser smoke tests |
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
