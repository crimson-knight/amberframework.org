---
title: "Respond With"
section: "guides/controllers"
order: 40
description: "Negotiate HTML, JSON, text, XML, and JavaScript responses in Amber V2, with an explicit Markdown route"
---

# Respond With

Use `respond_with` when one controller action can return more than one content
type. Amber selects a response from the path extension or the request's
`Accept` header.

**File: `src/controllers/status_controller.cr` — add this action inside
`StatusController`.**

```crystal
class StatusController < ApplicationController
  def show
    respond_with do
      html render("show.ecr")
      json({status: "ok"}.to_json)
      text "ok"
      xml "<status>ok</status>"
    end
  end
end
```

Supported helpers and emitted media types are:

| Helper | Media type |
|---|---|
| `html` | `text/html` |
| `json` | `application/json; charset=utf-8` |
| `text` | `text/plain` |
| `xml` | `application/xml` |
| `js` | `text/javascript` |

Each helper accepts a string, a zero-argument block returning a string, or—for
HTML—rendered ECR output. If Amber cannot match any available response, it
returns `406 Response Not Acceptable`.

Amber `2.0.0-beta.5` does not ship a `markdown` responder helper. When the
application publishes Markdown, keep that representation explicit until a
tagged framework release includes it.

**File: `src/controllers/status_controller.cr` — add this second action inside
`StatusController`.**

```crystal
def show_markdown
  response.content_type = "text/markdown; charset=utf-8"
  "# Status\n\nOK\n"
end
```

**File: `config/routes.cr` — register the action inside the existing `routes
:web` block.**

```crystal
get "/status", StatusController, :show
get "/status.md", StatusController, :show_markdown
```

**File: `src/views/status/show.ecr` — create the HTML representation referenced
by `render("show.ecr")`.**

```ecr
<p>Status: ok</p>
```

**Run from: the application root while `amber watch` is running.**

```bash
curl -H 'Accept: application/json' http://127.0.0.1:3000/status
curl http://127.0.0.1:3000/status.json
curl http://127.0.0.1:3000/status.md
```

Keep serialization explicit. For typed request parsing and structured API
errors, use the [Schema API](../schema-api/index.md).
