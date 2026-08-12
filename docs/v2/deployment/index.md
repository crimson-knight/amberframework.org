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
2. build and verify application-authored assets;
3. run the test suite;
4. compile the application target in release mode;
5. package the binary, configuration, and public files as one release;
6. provide production configuration through environment variables; and
7. run the binary behind a TLS-terminating reverse proxy or managed ingress.

```bash
shards install --production
amber assets build
amber assets check
crystal spec
shards build my_app --release
```

An existing application upgraded without CLI `2.0.5` can run
`crystal run scripts/build_assets.cr` and its verification wrapper as documented
in [Asset Pipeline](../guides/assets/). Never start the web process to generate
assets and never rely on a first request to populate `public/`.

The generated target writes `bin/my_app`. Build on the same operating-system
and CPU family used by the runtime unless you have deliberately configured a
cross-compilation toolchain.

## Asset release artifact

A manifest-enabled release contains, at minimum:

```text
bin/my_app
config/
public/robots.txt
public/assets/manifest.json
public/assets/...fingerprinted files...
```

The compiler also writes deterministic `.gz` companions for compressible
files. A compatible Amber static handler can select them for clients accepting
gzip while preserving the original content type and `Vary: Accept-Encoding`.
If a reverse proxy handles compression instead, test that the two layers do not
produce conflicting encodings.

Deploy the entire release to a new directory and verify it before shifting
traffic. Fingerprinted URLs can use
`Cache-Control: public, max-age=31536000, immutable`; HTML, the manifest, and
unfingerprinted paths must revalidate. Keep the prior complete release available
for rollback while its HTML may still be cached.

**File: `config/environments/production.yml` — use the typed top-level static
section for the fallback policy on unfingerprinted files.**

```yaml
static:
  headers:
    Cache-Control: "no-cache"
```

Do not put this under the legacy `pipes:` shape in a V2 configuration file.
Amber's static handler overrides the fallback with one-year immutable caching
when the requested filename contains a content fingerprint.

Runtime uploads are not in this artifact. Put them on a persistent mounted
volume or in object storage, with independent backup and access controls. Never
run user-controlled files through the authored-asset compiler.

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
- Start the application with the release directory read-only; only explicit
  runtime-data locations should be writable.
- Request one fingerprinted CSS, JavaScript, image, font, and binary URL and
  verify its bytes, MIME type, compression, and cache headers before shifting
  traffic.

Continue with [Manual binary deployment](manual-deploy/) for a concrete Linux
service example.
