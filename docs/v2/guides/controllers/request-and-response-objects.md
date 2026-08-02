---
title: "Request & Response Objects"
section: "guides/controllers"
order: 20
description: "Read HTTP requests and construct responses in Amber V2 controllers"
---

# Request & Response Objects

Every Amber controller delegates `request` and `response` to the current
`HTTP::Server::Context`. Use Amber's controller helpers for ordinary rendering,
redirects, and negotiated responses; reach for the underlying Crystal objects
when you need a header, method, resource, or status directly.

## Request

`request` is Crystal's `HTTP::Request` with Amber routing extensions.

```crystal
class DiagnosticsController < ApplicationController
  def show
    method = request.method
    resource = request.resource
    user_agent = request.headers["User-Agent"]?
    query = request.query

    respond_with do
      json({method: method, resource: resource, user_agent: user_agent, query: query}.to_json)
    end
  end
end
```

Common controller-level helpers include:

| Helper | Result |
|---|---|
| `get?`, `post?`, `put?`, `patch?`, `delete?`, `head?` | Whether the request uses that HTTP method |
| `params` | Amber route, query, and form parameters |
| `format` | The requested response format inferred from the path or headers |
| `port` | The request port |
| `requested_url` | The parsed request URL |
| `cookies` | Amber's cookie store |
| `session`, `flash` | The current session and flash stores |

The raw request body is an `IO`. A parser or [request
schema](../schema-api/index.md) is usually a better boundary for JSON or form
input than manually reading the stream in each action.

## Response

`response` is Crystal's `HTTP::Server::Response`. Its most useful direct
properties are `status_code`, `headers`, and `content_type`.

```crystal
class HealthController < ApplicationController
  def show
    response.headers["Cache-Control"] = "no-store"
    set_response(
      body: "ok",
      status_code: 200,
      content_type: "text/plain"
    )
  end
end
```

For content negotiation, prefer `respond_with`:

```crystal
respond_with do
  html render("show.ecr")
  json({status: "ok"}.to_json)
  text "ok"
end
```

Use `halt!` when the pipeline must stop with a plain response:

```crystal
halt!(403, "forbidden") unless authorized?
```

Use the redirect helper rather than setting a `Location` header by hand:

```crystal
redirect_to location: "/login", status: 302
```

For the upstream object APIs, see Crystal's `HTTP::Request` and
`HTTP::Server::Response` reference. Amber-specific helpers and schema
integration should remain the first choice when they express the intent.
