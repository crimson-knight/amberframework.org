---
title: "Models"
section: "guides"
order: 50
is_section: true
description: "Model-layer choices and release boundaries for Amber V2 applications"
---

# Models in Amber V2

Amber CLI `2.0.5` installs Grant and the selected database driver in the
supported web template. SQLite is the zero-setup default; PostgreSQL and MySQL
are selected with `amber new APP -d pg` or `-d mysql`.

[Grant](grant/) is the supported V2 model layer. The generated `shard.yml` pins
the reviewed Grant commit, `config/database.cr` registers the `primary`
connection, and `amber database` applies [Micrate migrations](grant/migrations/)
under `db/migrations/`.

Generate the first complete model and resource from the application root:

**Run from: the application root beside `shard.yml`.**

```bash
amber generate scaffold Pet name:string:required species:string:required adopted:bool
amber database migrate
```

If you are migrating an Amber 1 application, keep the 1.4.1 documentation open
for the existing Granite or Jennifer code and use the
[Granite-to-Grant guide](../../migration-guide/granite-to-grant/) only after
reviewing its compatibility notice and proving a database restore.
