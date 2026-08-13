---
title: "Sessions"
section: "guides/controllers"
order: 10
description: "Use Amber V2 sessions and flash messages safely"
---

# Sessions

Amber exposes `session` and `flash` directly inside a controller. Amber CLI's
V2 web template enables the session and flash pipes in this order.

**File: `config/routes.cr` — keep this order inside the generated `pipeline
:web` block.**

```crystal
pipeline :web do
  plug Amber::Pipe::Error.new
  plug Amber::Pipe::Logger.new
  plug Amber::Pipe::Session.new
  plug Amber::Pipe::Flash.new
  plug Amber::Pipe::CSRF.new
end
```

Keep `Session` before `Flash`: flash messages are serialized through the
session after the request.

## Generated configuration

The web template writes the following section to each environment YAML file.

**Files: `config/environments/development.yml`,
`config/environments/test.yml`, and `config/environments/production.yml` — edit
the existing `session:` section in each environment rather than adding a
duplicate key.**

```yaml
session:
  key: my_app.session
  store: signed_cookie
  adapter: memory
  expires: 0
```

The V2 session store uses the configured adapter for session values and an
encrypted cookie for the session identifier. The built-in `memory` adapter is
useful for local development and tests, but its data is process-local. Choose a
shared custom adapter before running multiple application processes or before
depending on sessions that must survive a restart. See [Session
Adapters](../adapters/sessions.md).

Production also requires a long `AMBER_SERVER_SECRET_KEY_BASE`; Amber uses it
to protect cookies. Do not commit a production secret to the YAML file.

## Read, write, and delete values

Session keys accept strings or symbols. Values are stored as strings.

**File: `src/controllers/logins_controller.cr` — place these actions inside
`LoginsController`, then register their routes in `config/routes.cr`.**

```crystal
class LoginsController < ApplicationController
  def create
    # Replace this lookup with your application's authentication logic.
    user_id = "42"
    session[:current_user_id] = user_id

    # Regenerate an adapter-backed session ID after authentication to prevent
    # session fixation. This is a no-op for a cookie-only store.
    context.regenerate_session!

    flash.notice = "Welcome back."
    redirect_to location: "/", status: 302
  end

  def destroy
    session.delete(:current_user_id)
    flash[:notice] = "You have signed out."
    redirect_to location: "/", status: 302
  end
end
```

**File: the controller action that needs the authenticated identity — use the
optional lookup where absence is expected.**

```crystal
if user_id = session[:current_user_id]?
  # Load the user through the persistence layer selected by the application.
end
```

Keep session payloads small and non-sensitive. Store a stable identifier, not
an entire model or authorization policy, and verify authorization again on
every protected request.

## Flash messages

Flash values are intended for the next request. Reading a value marks it for
removal; `keep` carries it forward, while `now` makes a value available only in
the current request.

**File: the controller action that sets the message.**

```crystal
flash[:error] = "Please correct the highlighted fields."
flash.keep(:error)
flash.now(:notice, "The preview was not saved.")
```

**File: `src/views/layouts/_flash.ecr` — create this reusable partial, then
render it from `src/views/layouts/application.ecr`.**

```ecr
<% flash.each do |name, message| %>
  <div class="flash flash-<%= name %>"><%= message %></div>
<% end %>
```

**File: `src/views/layouts/application.ecr` — add this call where global
messages should appear.**

```ecr
<%= render(partial: "layouts/_flash.ecr") %>
```

The V1 guide's inline Redis configuration is not a V2 configuration contract.
Implement and register a session adapter instead, then select it with the
`session.adapter` setting.
