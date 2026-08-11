---
title: "Getting Started"
section: ""
order: 20
is_section: true
description: "Create, test, build, and run the supported Amber V2 beta web app"
---

# Build Your First Amber V2 Web App

Complete [Installation](installation/) first. This walkthrough stays inside the
release-gated web path: Grant, Micrate, and SQLite are included; no database
server, Node.js process, or preview generator is required.

## Create the project

```bash
amber new my_app --type web
cd my_app
```

Dependencies install automatically. If you used `--no-deps`, run `shards
install` now.

The generated project uses ECR, typed environment YAML, Grant, SQLite, and
static routes. Its `shard.yml` pins Amber `2.0.0-beta.3` from
`amberframework/amber` and the reviewed Grant V2 commit.

## Prove the clean scaffold works

```bash
crystal spec
crystal build src/my_app.cr -o bin/my_app
amber watch
```

Open <http://127.0.0.1:3000>. Also load
<http://127.0.0.1:3000/css/app.css>; this catches a missing static route that a
homepage-only check would miss.

## Understand the generated files

```text
my_app/
├── .amber.yml
├── shard.yml
├── config/
│   ├── application.cr
│   ├── database.cr
│   ├── routes.cr
│   ├── environments/
│   └── initializers/
├── public/css/app.css
├── public/js/app.js
├── spec/controllers/home_controller_spec.cr
└── src/
    ├── my_app.cr
    ├── controllers/
    └── views/
        ├── home/index.ecr
        └── layouts/application.ecr
```

For the complete file-by-file contract, including the intentionally empty
extension directories, read the [V2 web template guide](../guides/web-template/).

`.amber.yml` records CLI metadata. `config/environments/*.yml` uses nested V2
sections such as `server`, `database`, `session`, and `logging`. Environment
variables override values, for example:

```bash
AMBER_SERVER_PORT=8080 amber watch
```

## Add a page

Generate a controller with ECR views:

```bash
amber generate controller Posts index show
```

The generator leaves request specs pending until routes exist. Add routes to
the generated `routes :web` block:

```crystal
get "/posts", PostsController, :index
get "/posts/:id", PostsController, :show
```

Then enable the matching request specs and run:

```bash
crystal tool format
crystal spec
```

## Add a typed request schema

```bash
amber generate schema Post title:string:required body:text
```

The Schema API is built into Amber core. See [Schema API](../guides/schema-api/)
for validation and controller integration.

## Add a persisted resource

Generate the Grant model, request schema, controller, ECR views, request and
model specs, Micrate migration, and resource route together:

```bash
amber generate scaffold Pet name:string:required species:string:required adopted:bool
amber database migrate
AMBER_ENV=test amber database migrate
crystal spec
```

Open <http://127.0.0.1:3000/pets/new>. The complete file map and create/update
journey are in [Build a Pet Tracker](../guides/pet-tracker/).

## Know the beta boundary

Model, scaffold, and migration generators are part of the supported web path.
Generated API resources and authentication remain preview, and native
generation has a separate platform matrix. Read [Beta support](../beta-support/)
before using those surfaces.
