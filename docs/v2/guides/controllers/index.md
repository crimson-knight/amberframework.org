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

Generate a controller with the standalone V2 CLI:

```bash
amber generate controller Posts index show
```

The generator writes Crystal controller code and ECR views, but it deliberately
does not guess routes. Add the routes your application actually exposes:

```crystal
Amber::Server.configure do
  routes :web do
    get "/posts", PostsController, :index
    get "/posts/:id", PostsController, :show
  end
end
```

## Actions and views

Controllers inherit from the generated `ApplicationController`:

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
