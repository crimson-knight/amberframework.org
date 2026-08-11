# Amber V2 can remember things now

We found a funny gap in Amber V2's supposedly complete first application: the
web template had routes, controllers, ECR, typed configuration, CSS, and
JavaScript—but no database. The Pet Tracker tutorial had to keep its animals in
an in-memory array because the default application could not persist them.

Amber `2.0.0-beta.3` and Amber CLI `2.0.4` close that gap. A new web application
now includes Grant ORM, Micrate-powered database commands, and SQLite by
default. The supported tutorial creates a real Pet, stores it, edits it, and
reads the updated record back.

## Build the database-backed Pet Tracker

```bash
brew install amberframework/amber_cli/amber_cli
amber new pet_tracker
cd pet_tracker
amber generate scaffold Pet name:string:required species:string:required adopted:bool
amber database migrate
amber watch
```

Open <http://127.0.0.1:3000/pets/new>. No database server is required: SQLite
stores the development database under `db/`. Pass `-d pg` or `-d mysql` to
`amber new` when the application should use a server database instead.

## What the scaffold actually creates

The scaffold is a complete application boundary, not a pile of disconnected
snippets:

- `src/models/pet.cr` contains the Grant model;
- `src/schemas/pet_schema.cr` validates create and update input;
- `src/controllers/pet_controller.cr` owns HTML CRUD actions;
- `src/views/pet/` contains index, show, new, edit, and shared form ECR;
- `db/migrations/` contains reversible Micrate SQL;
- `spec/models/` and `spec/controllers/` contain the generated checks;
- `config/routes.cr` receives the Pet resource routes.

The generated form includes CSRF protection, chooses create or edit from the
model's persisted state, and uses `_method=PATCH` for updates. Required model
fields also expose nil-safe form readers so a brand-new record can render
before it has received input.

## The database command is part of the CLI

Micrate is compiled into the standalone `amber` executable. Applications do
not need a second migration command or another moving dependency.

```bash
amber database migrate
amber database status
amber database rollback
amber database redo
amber database seed
```

Development and test use separate URLs. Run
`AMBER_ENV=test amber database migrate` before tests that need the schema, and
set `DATABASE_URL` in production rather than committing credentials.

## This is now a release test

The release gate no longer stops after a homepage compiles. It generates the
Pet scaffold, migrates development and test, runs the generated specs, builds
and boots the application, submits the create form, reads the stored Pet,
submits the edit form, and verifies the updated value.

That journey runs on Apple Silicon macOS, x86-64 Linux, and ARM64 Linux.
Windows x86-64 compiles and tests the same generated database-backed app in CI;
it remains outside the release gate until it has a supported CLI archive.

Start with [Build a Pet Tracker](/docs/v2/guides/pet-tracker/), inspect the
[web-template contract](/docs/v2/guides/web-template/), and use the
[migration guide](/docs/v2/guides/models/grant/migrations/) when the schema
needs to change.
