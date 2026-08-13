---
title: "amber watch"
section: "cli"
order: 30
description: "Rebuild and restart an Amber V2 application during development"
---

# `amber watch`

**Run from: the generated application root beside `shard.yml`.**

```bash
amber watch
```

The default V2 watch configuration rebuilds when Crystal source, environment
YAML, ECR views, or authored assets change. It builds assets first, creates
`bin/`, builds the app target, runs it, and restarts after matching files
change.

```yaml
watch:
  run:
    build_commands:
      - mkdir -p bin
      - crystal build ./src/my_app.cr -o bin/my_app
    run_commands:
      - bin/my_app
    include:
      - ./config/**/*.cr
      - ./config/environments/*.yml
      - ./src/**/*.cr
      - ./src/**/*.ecr
      - ./app/assets/**/*
```

Use environment variables normally:

```bash
AMBER_SERVER_PORT=8080 amber watch
```

Stop the watcher with `Ctrl-C`. If a rebuild fails, run the printed build
command directly to get the complete compiler error.

## Asset-aware watch cycle

CLI `2.0.6` runs the same build-time compiler as `amber assets build` before
application compilation. A deleted asset, missing CSS image/font reference,
missing local JavaScript dependency, or invalid manifest entry therefore stops
the rebuild instead of becoming a browser 404.
