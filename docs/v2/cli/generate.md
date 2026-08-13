---
title: "amber generate"
section: "cli"
order: 20
description: "Supported and preview generators in the Amber V2 beta"
---

# `amber generate`

**Run from: the generated application root beside `shard.yml`.**

```bash
amber generate TYPE NAME [fields or actions]
```

| Type | Status | Output |
|---|---|---|
| `controller` | Supported | Controller, ECR views, pending route specs |
| `schema` | Supported | Built-in Schema API definition |
| `job` | Supported | Built-in job class |
| `mailer` | Supported | Built-in mailer class |
| `channel` | Supported | WebSocket channel |
| `migration` | Supported | Reversible Micrate SQL migration |
| `model` | Supported | Grant-backed model, spec, and migration |
| `scaffold` | Supported | Grant model, schema, HTML CRUD, ECR views, specs, route, and migration |
| `api` | Preview | Persistence-backed model and controller |
| `auth` | Preview | Requires a compatible persistence/auth stack |

**Run from: the same application root — examples for the core web app.**

```bash
amber generate controller Posts index show
amber generate schema Post title:string:required body:text
amber generate job PublishPost --queue=default --max-retries=3
amber generate mailer Digest --actions=weekly
amber generate channel Updates --topics=posts
amber generate migration CreatePosts
```

Controller routes are intentionally not guessed. Add them to `config/routes.cr`,
then enable the generated pending request specs. Amber V2 generator output is
always ECR, even if a migrated `.amber.yml` still contains a legacy Slang value.

Generated API resources and authentication remain preview and may require
additional application integration. Model, scaffold, and migration generators
use the Grant, selected database driver, and Micrate tooling included in the
supported database-backed web template.

Amber CLI `2.0.6` binds scaffold and API schemas
directly to `create` and `update`, then reads request-local typed values with
`validated_as`. HTML scaffolds re-render their ECR forms on validation failure;
API resources use the framework's structured JSON failure. This is the
released generator path for Amber `2.0.0-beta.5`.
