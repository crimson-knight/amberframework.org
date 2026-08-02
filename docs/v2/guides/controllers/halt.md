---
title: "Halt!"
section: "guides/controllers"
order: 30
description: "Stop Amber V2 pipelines and return early from controller actions"
---

# Halt!

`halt!` sets the current context body, plain-text content type, and status code.
It is most useful in a before filter, where setting context content prevents the
controller action from running:

```crystal
class AdminController < ApplicationController
  before_action do
    only :index do
      halt!(403, "Forbidden") unless session[:admin_id]?
    end
  end

  def index
    render("index.ecr")
  end
end
```

`halt!` marks the request context; it does not raise an exception that escapes
ordinary Crystal control flow. Inside an action, return an explicit response
when later expressions must not run:

```crystal
def show
  unless authorized?
    return set_response(
      body: "Forbidden",
      status_code: 403,
      content_type: "text/plain"
    )
  end

  render("show.ecr")
end
```

Amber's redirect helper sets the `Location` header and uses the same context
response mechanism:

```crystal
redirect_to location: "/login", status: 302
```

The V1 Slang example and its claim that `halt!` interrupts any action like an
exception are not copied into V2.
