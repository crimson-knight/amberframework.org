---
title: "Pipelines"
section: "guides/routing"
order: 10
description: "Compose Amber V2 request handlers in a deliberate order"
---

# Pipelines

A pipeline is the ordered set of `HTTP::Handler`-compatible pipes applied to a
group of routes. The V2 web template generates this configuration:

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

Define a second pipeline when a route group needs additional handling:

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
request should continue. A pipe that finalizes a response can stop the chain.
