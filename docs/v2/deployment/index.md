---
title: "Deployment"
section: ""
order: 60
is_section: true
description: "Build and run an Amber V2 web application without relying on obsolete platform buildpacks"
---

# Deployment

Deploy Amber V2 as a compiled Crystal executable. The beta does not publish a
verified one-click recipe for Heroku, Dokku, DigitalOcean, or another hosting
vendor. Those V1 pages depended on old Crystal versions, Webpack or Node asset
builds, bundled database commands, Redis defaults, and retired buildpacks, so
they are not carried into V2.

The portable deployment contract is:

1. install production shard dependencies;
2. run the test suite;
3. compile the application target in release mode;
4. provide production configuration through environment variables;
5. run the binary behind a TLS-terminating reverse proxy or managed ingress.

```bash
shards install --production
crystal spec
shards build my_app --release
```

The generated target writes `bin/my_app`. Build on the same operating-system
and CPU family used by the runtime unless you have deliberately configured a
cross-compilation toolchain.

## Required runtime configuration

```bash
export AMBER_ENV=production
export AMBER_SERVER_HOST=0.0.0.0
export AMBER_SERVER_PORT=3000
export AMBER_SERVER_SECRET_KEY_BASE="replace-with-a-long-random-secret"
./bin/my_app
```

Set `DATABASE_URL` to the production database selected by the application. The
default V2 web template includes Grant and SQLite; PostgreSQL and MySQL apps
include their selected driver instead. Never commit the production secret or
database credentials or inject them into a container image.

Run migrations as an explicit release step before starting code that requires
the new schema:

```bash
AMBER_ENV=production DATABASE_URL="..." amber database migrate
```

## Platform checklist

- Route external HTTPS traffic through a reverse proxy or managed ingress.
- Forward to the port in `AMBER_SERVER_PORT`; do not run the process as root to
  bind directly to ports 80 or 443.
- Preserve termination signals so the process can shut down cleanly.
- Capture standard output and standard error with the platform log service.
- Restart failed processes with the platform supervisor.
- Back up and prove restore before applying production migrations.

Continue with [Manual binary deployment](manual-deploy/) for a concrete Linux
service example.
