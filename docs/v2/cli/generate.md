---
title: "amber generate"
section: "cli"
order: 20
description: "Supported and preview generators in the Amber V2 beta"
---

# `amber generate`

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
| `migration` | Supported output | SQL migration; applying it needs DB tooling |
| `model` | Preview | Grant-backed model and migration |
| `scaffold` | Preview | Persistence-backed CRUD resource |
| `api` | Preview | Persistence-backed model and controller |
| `auth` | Preview | Requires a compatible persistence/auth stack |

Examples for the core web app:

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

Preview generators print a warning. They may write useful files, but the clean
web app does not include the dependencies needed to compile them.
