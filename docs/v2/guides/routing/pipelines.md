---
title: "Pipelines"
section: "guides/routing"
order: 10
description: "Compose Amber V2 request handlers in a deliberate order"
---

# Pipelines

A pipeline is the ordered set of `HTTP::Handler`-compatible pipes applied to a
group of routes. The V2 web template generates this configuration.

**File: `config/routes.cr` — this is the generated baseline. Edit the existing
pipelines in place; do not create a second `Amber::Server.configure` block only
to change their order.**

```crystal
Amber::Server.configure do
  pipeline :web do
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Logger.new
    plug Amber::Pipe::Session.new
    plug Amber::Pipe::Flash.new
    plug Amber::Pipe::CSRF.new
  end

  pipeline :static do
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Static.new("./public")
  end

  routes :web do
    get "/", HomeController, :index
  end

  routes :static do
    get "/*", Amber::Controller::Static, :index
  end
end
```

Order is behavior. `Session` must run before `Flash`, and error handling should
wrap work that can fail. Add authentication, rate limiting, or application
headers deliberately to only the pipelines that need them.

## A protected pipeline

Define a second pipeline when a route group needs additional handling.

**File: `config/routes.cr` — add both the `:admin` pipeline and its route group
inside the existing `Amber::Server.configure` block.**

```crystal
Amber::Server.configure do
  pipeline :admin do
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Logger.new
    plug Amber::Pipe::Session.new
    plug Amber::Pipe::Flash.new
    plug AuthenticateAdmin.new
    plug Amber::Pipe::CSRF.new
  end

  routes :admin, "/admin" do
    get "/", AdminController, :index
  end
end
```

Custom pipes implement `call(context)` and invoke the next handler when the
request should continue. Put `AuthenticateAdmin` in its own source file, for
example `src/pipes/authenticate_admin.cr`, and require that file from the
application before `config/routes.cr` is compiled. A pipe that finalizes a
response can stop the chain.
