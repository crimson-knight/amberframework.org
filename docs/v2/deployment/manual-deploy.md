---
title: "Manual Binary Deployment"
section: "deployment"
order: 10
description: "Compile an Amber V2 application and run it as an unprivileged Linux service"
---

# Manual Binary Deployment

This example keeps compilation and runtime responsibilities explicit. Adjust
paths, the service user, and the target name for your application.

## Build the release artifact

Amber CLI `2.0.6` builds and checks application assets after installing shards
and before compiling the binary. These are build-time commands; the running web
process only reads the finished manifest and files.

```bash
shards install --production
amber assets build
amber assets check
crystal spec
shards build my_app --release
file bin/my_app
```

For an existing app using the explicit migration wrapper, replace the two
`amber assets` lines with `crystal run scripts/build_assets.cr` and its manifest
verification. Neither path may start the HTTP process or make a warm-up request
to create release files.

Copy `bin/my_app`, `config/`, and the built `public/` artifact to one new release
directory. If your application reads other files at runtime, include them
deliberately. Do not copy development secrets or a local database.

User uploads are runtime data, not release assets. Keep them on a persistent
mounted volume or in object storage and leave them out of the directory replaced
by each deployment. Back up local uploads independently. The application release
may be read-only after its authored assets have been built.

For a manifest-enabled application, confirm the release contains both
`public/assets/manifest.json` and every fingerprinted file it names. Include the
deterministic `.gz` companions. Do not copy only files that changed; a release
directory is a complete unit.

**File: `config/environments/production.yml` — configure only the fallback for
unfingerprinted files; Amber applies immutable caching to fingerprinted names.**

```yaml
static:
  headers:
    Cache-Control: "no-cache"
```

## Configure the process

Store secrets in the host or deployment platform's secret manager. A minimal
environment is:

```bash
AMBER_ENV=production
AMBER_SERVER_HOST=0.0.0.0
AMBER_SERVER_PORT=3000
AMBER_SERVER_SECRET_KEY_BASE=replace-with-a-long-random-secret
```

`AMBER_SERVER_PORT` overrides `server.port` from
`config/environments/production.yml`. Add `DATABASE_URL` only when the
application has a configured database adapter.

## Example systemd unit

```ini
[Unit]
Description=my_app Amber service
After=network.target

[Service]
Type=simple
User=my_app
Group=my_app
WorkingDirectory=/srv/my_app
EnvironmentFile=/etc/my_app.env
ExecStart=/srv/my_app/bin/my_app
Restart=on-failure
RestartSec=3
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

The environment file should be readable only by the service administrator and
service account. Terminate TLS in a reverse proxy or managed ingress and proxy
to `127.0.0.1:3000` when the proxy runs on the same host.

## Verify before shifting traffic

```bash
curl --fail --show-error http://127.0.0.1:3000/
```

Confirm the expected page, logs, restart behavior, and any persistence or file
storage dependencies before sending production traffic. Keep each binary,
configuration, generated asset manifest, and generated public assets together
as one immutable release. Roll back by switching traffic to the complete prior
release; never combine an older manifest with newer asset files.

For a manifest-enabled release, inspect the rendered HTML, copy one CSS,
JavaScript, image, font, and binary URL, and request each directly. Verify:

- the response body matches the built file;
- CSS and local JavaScript dependencies point at existing fingerprinted URLs;
- `Content-Type` matches the manifest, including `font/woff2`, `image/avif`,
  `application/wasm`, and other deployed formats;
- fingerprinted URLs return
  `Cache-Control: public, max-age=31536000, immutable`;
- HTML and `manifest.json` do not receive immutable caching;
- gzip clients receive valid compressed bytes with the original media type and
  `Vary: Accept-Encoding`; and
- conditional requests and byte ranges still work.

Keep the prior release directory until its HTML can no longer send clients to
its asset URLs. A database rollback is a separate decision: do not reverse a
non-backward-compatible migration merely because the binary or assets roll back.
