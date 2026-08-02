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

```bash
shards install --production
crystal spec
shards build my_app --release
file bin/my_app
```

Copy `bin/my_app`, `config/`, and `public/` to the runtime host. If your
application reads other files at runtime, include them deliberately. Do not copy
development secrets or a local database.

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
`config/environments/production.yml`. Add `AMBER_DATABASE_URL` only when the
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
storage dependencies before sending production traffic. Roll back by restoring
the previous binary and configuration together.
