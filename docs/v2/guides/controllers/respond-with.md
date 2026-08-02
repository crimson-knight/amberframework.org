---
title: "Respond With"
section: "guides/controllers"
order: 40
description: "Negotiate HTML, JSON, text, XML, and JavaScript responses in Amber V2"
---

# Respond With

Use `respond_with` when one controller action can return more than one content
type. Amber selects a response from the path extension or the request's
`Accept` header.

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

```bash
curl -H 'Accept: application/json' http://127.0.0.1:3000/status
curl http://127.0.0.1:3000/status.json
```

Keep serialization explicit. For typed request parsing and structured API
errors, use the [Schema API](../schema-api/index.md).
