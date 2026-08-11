---
title: "Views"
section: "guides"
order: 80
is_section: true
description: "Render Amber V2 HTML with Crystal ECR templates and explicit response formats"
---

# Views

Amber V2's supported web path renders HTML with Crystal ECR templates. The
convention is deliberately small:

- controllers load resources and declare response formats;
- ECR templates own HTML;
- the application layout owns the document shell and local assets;
- `public/` owns files the browser requests directly.

## Negotiate HTML and JSON in one action

Use `respond_with` when one resource has more than one representation. The
action loads the resource once and makes each public format explicit:

```crystal
class ArticlesController < ApplicationController
  def show
    article = ArticleCatalog.fetch(params["slug"])

    respond_with do
      html { render("show.ecr") }
      json { article.to_json }
    end
  end
end
```

A request with `Accept: text/html` renders the ECR template and layout. A
request with `Accept: application/json` runs only the JSON block. Amber also
recognizes supported path extensions when the route accepts that path. If the
request asks for no available representation, Amber returns `406 Not
Acceptable`.

Keep representation selection in the controller. Do not duplicate resource
loading in separate HTML and JSON actions unless the application behavior is
actually different.

## Generated view structure

A clean web application starts with:

```text
src/views/
├── home/index.ecr
└── layouts/application.ecr
```

As the application grows, group templates by controller and name reusable
partials with a leading underscore:

```text
src/views/
├── articles/
│   ├── _meta.ecr
│   ├── index.ecr
│   └── show.ecr
└── layouts/
    └── application.ecr
```

The application controller selects the default layout:

```crystal
class ApplicationController < Amber::Controller::Base
  LAYOUT = "application.ecr"
end
```

## Render ECR safely

Local variables in the controller action are available to the rendered ECR.
ECR does not automatically escape interpolation, so escape values that can
contain user or external data:

```ecr
<article class="article-shell">
  <p class="eyebrow">Field note</p>
  <h1><%= escape_html(article[:title]) %></h1>
  <p><%= escape_html(article[:summary]) %></p>

  <%= render(partial: "articles/_meta.ecr") %>
</article>
```

The layout receives the completed action template as `content`. That value is
framework-rendered HTML, so it is intentionally inserted without escaping:

```ecr
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/css/app.css">
  </head>
  <body>
    <%= content %>
    <script type="importmap">
      {"imports":{"app":"/js/app.js"}}
    </script>
    <script type="module">import "app";</script>
  </body>
</html>
```

The common rendering forms are:

```crystal
render("show.ecr")
render(partial: "articles/_meta.ecr")
render("card.ecr", layout: false)
render("admin/show.ecr", layout: "admin.ecr")
```

## Front-end boundary

The layout above uses a browser-native import map. The `app` name resolves to a
local ES module served by Amber's static pipeline. The generated baseline needs
no Node.js dependency, package manager, bundler, UI framework, or CDN.

Read [Import maps](../assets/import-maps/) for the complete local-module pattern
and [Web template](../web-template/) for the exact generated project structure.

The V2 CLI generator emits ECR only. Slang, Kilt, Mustache, and Temel examples
on the V1 site remain maintenance references for old applications, not choices
in the supported V2 web template.
