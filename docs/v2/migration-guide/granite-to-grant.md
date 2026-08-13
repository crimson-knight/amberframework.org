---
title: "Granite to Grant Migration"
section: "migration-guide"
order: 20
description: "Move an existing Granite model layer to the Grant version pinned by Amber CLI 2.0.6"
---

# Migrating from Granite to Grant

Grant is the default model layer in new Amber CLI `2.0.6` web applications.
That does not make an ORM replacement part of the Amber 1-to-2 framework
upgrade. First prove that the existing application can run on Amber
`2.0.0-beta.5` with its current persistence stack. Start this guide only when
moving to Grant is an explicit second decision.

## Establish the safety boundary

Before editing a model:

1. Record the current Crystal, Amber, Granite, driver, and database versions.
2. Run the complete test suite and compile the application binary.
3. Back up the database and restore that backup into a disposable environment.
4. Capture representative reads, writes, validations, associations,
   transactions, callbacks, and error behavior.
5. Choose one low-risk model boundary for the first migration.

Do not run two migration systems against the same schema without one explicit
owner. Amber CLI uses Micrate SQL under `db/migrations/`; keep the application's
existing migration history and decide where new versions will be recorded
before applying anything.

## Pin Grant and one driver

**File: `shard.yml` — add the same reviewed Grant source used by a generated
Amber CLI `2.0.6` application plus the application's database driver.**

```yaml
dependencies:
  grant:
    github: crimson-knight/grant
    commit: 2665a978b43ac608c68cde9243821f8f8f053372
  pg:
    github: will/crystal-pg
    version: 0.30.0
```

The example uses PostgreSQL. Use the SQLite or MySQL dependency from a freshly
generated `2.0.6` app when that is the database being migrated. Do not add all
three drivers.

## Register the Grant connection

**File: `config/database.cr` — register a connection loaded by the app's
existing `require "../config/*"` entry point.**

```crystal
require "grant"
require "grant/adapter/pg"

Grant::Connections << Grant::Adapter::Pg.new(
  name: "primary",
  url: ENV["DATABASE_URL"]? || Amber.settings.database_url
)
```

Use `Grant::Adapter::Sqlite` with `require "grant/adapter/sqlite"` or
`Grant::Adapter::Mysql` with `require "grant/adapter/mysql"` for those drivers.

## Translate one model without changing its table

**Existing Granite file: `src/models/user.cr`.**

```crystal
class User < Granite::Base
  connection pg
  table users

  column id : Int64, primary: true
  column email : String
  column name : String?
  column admin : Bool = false
  column created_at : Time?
  column updated_at : Time?
end
```

**Grant replacement: `src/models/user.cr`.**

```crystal
class User < Grant::Base
  connection primary
  table users

  column id : Int64, primary: true
  column email : String
  column name : String?
  column admin : Bool = false

  timestamps
end
```

Keep `connection primary` and `table users` explicit during a migration. This
matches the supported generator and prevents an inference change from silently
pointing at another connection or table. `timestamps` maps the conventional
`created_at` and `updated_at` columns; verify their exact database types before
removing the previous declarations.

## Preserve schema before changing behavior

An ORM migration does not inherently require a database schema migration. If
the existing table already matches the Grant columns, first make the new model
read and write the existing schema. Add Micrate SQL only for an intentional
schema change.

Write a focused spec against the restored disposable database:

```crystal
user = User.new
user.email = "migration@example.com"
user.admin = false
user.save.should be_true

persisted = User.find(user.id)
persisted.should_not be_nil
persisted.not_nil!.email.should eq("migration@example.com")
```

Then prove update and destroy, required and nullable values, unique constraints,
timestamps, and the error paths used by the application.

## Translate application operations deliberately

Do not perform a global search-and-replace. Convert one behavior at a time and
keep a spec beside it.

```crystal
# Collection
users = User.all.to_a

# Primary-key lookup
user = User.find(params[:id])

# Typed assignment and persistence
user = User.new
user.email = schema.email.not_nil!
user.name = schema.name
user.save

# Delete
user.destroy
```

For filtering, associations, validations, callbacks, transactions, and
security APIs, follow the matching [Grant guides](../guides/models/grant/) and
verify the behavior against the pinned commit. Do not assume a similarly named
Granite method has identical return types, callback order, transaction scope,
or error semantics.

## Decide whether the ORMs may coexist

Coexistence can be useful for a staged migration, but it is not automatic.
Before running Granite and Grant together, prove:

- their connection pools do not compete for lifecycle ownership;
- only one migration system advances the schema;
- a transaction does not falsely imply atomicity across different pools;
- callbacks and validations are not executed twice;
- two classes writing one table agree on types, defaults, timestamps, and
  optimistic-locking behavior;
- application code names which ORM owns each model.

If those conditions are not testable, migrate in a maintenance window or a
separate deployment rather than carrying two active writers.

## Completion gates

For every migrated model, keep evidence for:

- schema compatibility and reversible migration SQL when schema changed;
- representative create, read, update, and destroy operations;
- nullable and required fields on new records;
- validations and database constraints;
- associations and query counts;
- callback order and external side effects;
- transaction rollback behavior;
- production-shaped performance for critical queries.

Only remove Granite after no application file, job, task, or maintenance script
requires it and a restored production backup passes the Grant-backed suite.
