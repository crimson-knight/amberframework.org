---
title: "Controllers"
section: "guides"
order: 70
is_section: true
description: "Route Amber V2 requests through controller actions and ECR views"
---

# Controllers

A controller action turns an HTTP request into a response. Amber creates the
controller selected by the router, runs its filters, calls the action, and
finalizes the response through the active pipeline.

**Run from: the application root.**

```bash
amber generate controller Posts index show
```

The generator writes Crystal controller code and ECR views, but it deliberately
does not guess routes. For the command above it creates
`src/controllers/posts_controller.cr`, `src/views/posts/index.ecr`, and
`src/views/posts/show.ecr`.

**File: `config/routes.cr` — add these routes inside the existing
`Amber::Server.configure` block.**

```crystal
Amber::Server.configure do
  routes :web do
    get "/posts", PostsController, :index
    get "/posts/:id", PostsController, :show
  end
end
```

## Actions and views

**File: `src/controllers/posts_controller.cr` — replace the generated action
bodies with the application behavior. Keep the class inside this file.**

```crystal
class PostsController < ApplicationController
  def index
    title = "Recent posts"
    render("index.ecr")
  end

  def show
    post_id = params[:id]
    render("show.ecr")
  end
end
```

Local variables remain available to the ECR template rendered by the action.
Keep request parsing and authorization in explicit boundaries; use the [Schema
API](../schema-api/index.md) when input needs typed validation.

Amber's `resources` macro uses the conventional action names `index`, `new`,
`create`, `show`, `edit`, `update`, and `destroy`. Ordinary actions may use any
name when registered explicitly.

## Controller interfaces

- [Sessions and flash](sessions.md)
- [Request and response objects](request-and-response-objects.md)
- [Routing](../routing/index.md)
- [Schema API](../schema-api/index.md)

V2 web output is ECR. Examples that require `.slang` templates belong to the
V1 documentation and should not be copied into a new V2 application.
