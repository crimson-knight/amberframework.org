---
title: "Routes"
section: "guides/routing"
order: 20
description: "Define Amber V2 paths, resources, namespaces, and constraints"
---

# Routes

Define routes inside `Amber::Server.configure` and attach each group to a named
pipeline:

```crystal
Amber::Server.configure do
  routes :web do
    get "/posts", PostsController, :index
    get "/posts/:id", PostsController, :show
    post "/posts", PostsController, :create
    patch "/posts/:id", PostsController, :update
    delete "/posts/:id", PostsController, :destroy
  end
end
```

Dynamic segments such as `:id` are available through `params` in the action.
Amber also supports `put`, `options`, `head`, `trace`, and `connect` route
macros.

## Resource routes

`resources` creates conventional routes for `index`, `new`, `create`, `show`,
`edit`, `update`, and `destroy`:

```crystal
routes :web do
  resources "/posts", PostsController
  resources "/profiles", ProfilesController, only: [:show, :edit, :update]
  resources "/events", EventsController, except: [:destroy]
end
```

Only declare actions implemented by the controller; missing resource actions
fail during compilation.

## Scopes and namespaces

A scope on `routes` prefixes the complete group. Nested `namespace` blocks add
another path segment:

```crystal
routes :api, "/api" do
  namespace "/v1" do
    resources "/posts", Api::PostsController, only: [:index, :show]
  end
end
```

## Segment constraints

Constrain a dynamic segment with a regular expression when a route must reject
non-matching values:

```crystal
routes :web do
  get "/orders/:id", OrdersController, :show, {"id" => /\d+/}
end
```

Amber CLI V2 does not expose the V1 `amber routes` command. Confirm routing with
request specs and the compiler rather than copying the old command or its route
matrix screenshot.
