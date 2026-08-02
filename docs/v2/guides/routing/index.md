---
title: "Routing"
section: "guides"
order: 100
is_section: true
description: "Connect Amber V2 pipelines, paths, and controller actions"
---

# Routing

Amber compiles the routes in `config/routes.cr`. Each route selects a pipeline,
matches an HTTP method and path, then dispatches to a controller action.

The generated V2 web application starts with separate `web` and `static`
pipelines. Keep that separation: request/session behavior belongs to the web
pipeline, while files under `public/` are served through the static pipeline.

- [Pipelines](pipelines.md) — compose request handlers in execution order.
- [Routes](routes.md) — map paths, resources, namespaces, and constraints.

Routes are compile-time application structure. Amber CLI V2 does not currently
publish the retired `amber routes` command, so `config/routes.cr`, request specs,
and compiler errors are the source of truth for the beta.
