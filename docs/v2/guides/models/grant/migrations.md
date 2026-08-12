---
title: "Migrations"
section: "guides/models/grant"
order: 15
description: "Create, apply, inspect, roll back, and ship Micrate SQL migrations with Amber V2"
---

# Database Migrations

Amber CLI `2.0.5` ships Micrate inside the `amber` executable. A generated web
application does not need a second migration binary or a Micrate shard entry.
Migration files belong under `db/migrations/` and database commands run from
the application root.

## Generate a migration

**Run from: the application root beside `shard.yml`.**

```bash
amber generate migration AddBirthdayToPets
```

**Generated file: `db/migrations/<timestamp>_add_birthday_to_pets.sql`.**

```sql
-- Migration: add_birthday_to_pets
-- Created: 2026-08-11 20:00:00 UTC

-- +micrate Up
-- Add SQL to apply the migration here.

-- +micrate Down
-- Add SQL to roll the migration back here.
```

The timestamp is part of the migration version. Keep it in the filename and
commit the file once; do not rename an applied migration.

## Write both directions

**File: `db/migrations/<timestamp>_add_birthday_to_pets.sql` — replace the two
placeholder comments.**

```sql
-- +micrate Up
ALTER TABLE pets ADD COLUMN birthday DATE;

-- +micrate Down
ALTER TABLE pets DROP COLUMN birthday;
```

Write SQL for the database selected when the application was generated. SQL
features differ across SQLite, PostgreSQL, and MySQL; test both directions on
the same engine and major version used in production. In particular, older
SQLite versions support fewer `ALTER TABLE` operations and may require a table
rebuild migration.

## Apply development and test separately

**Run from: the application root.**

```bash
amber database migrate
AMBER_ENV=test amber database migrate
```

The command reads `config/environments/development.yml` by default and
`config/environments/test.yml` when `AMBER_ENV=test`. `DATABASE_URL` overrides
that file for CLI operations.

For SQLite, the first migration creates the database file. For PostgreSQL or
MySQL, create the database first when it does not already exist:

**Run from: the application root for a PostgreSQL or MySQL database.**

```bash
amber database create
amber database migrate
```

## Inspect and reverse

**Run from: the application root.**

```bash
amber database status
amber database version
amber database rollback
amber database redo
```

- `status` lists applied and pending files.
- `version` prints the latest applied migration version.
- `rollback` runs the latest applied Down section once.
- `redo` rolls back and reapplies the latest migration.

Use rollback and redo while developing a new migration. Once a migration has
been applied in a shared environment, add a new corrective migration instead
of rewriting its history.

## Seed data

**File: `db/seeds.cr` — application-owned seed program.**

```crystal
require "../config/*"
require "../src/models/**"

Pet.create(name: "Miso", species: "Cat", adopted: false)
```

**Run from: the application root after migrations.**

```bash
amber database seed
```

Keep production seed behavior idempotent or explicitly one-time. A seed is
ordinary application code; it is not tracked as a migration version.

## Release workflow

Before deploying an application with schema changes:

1. Back up the production database and prove the restore path.
2. Apply the migration to a production-shaped staging database.
3. Run request and model specs against the migrated test database.
4. Review locks, table rewrites, and compatibility with the currently running
   application version.
5. Apply migrations as an explicit release step before starting code that
   requires the new schema.

The default SQLite workflow is excellent for local development and small
single-host applications. Choose PostgreSQL or MySQL when the deployment needs
independent database scaling, multiple application hosts, or operational
features provided by those servers.
