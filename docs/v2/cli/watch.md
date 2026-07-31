---
title: "amber watch"
section: "cli"
order: 30
description: "Rebuild and restart an Amber V2 application during development"
---

# `amber watch`

Run from the generated application root:

```bash
amber watch
```

The default V2 watch configuration rebuilds when Crystal source, environment
YAML, or ECR views change. It creates `bin/`, builds the app target, runs it,
and restarts after matching files change.

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
```

Use environment variables normally:

```bash
AMBER_SERVER_PORT=8080 amber watch
```

Stop the watcher with `Ctrl-C`. If a rebuild fails, run the printed build
command directly to get the complete compiler error.
