---
title: "Views"
section: "guides"
order: 80
is_section: true
description: "Render Amber V2 HTML with Crystal ECR templates"
---

# Views

Amber V2's generated web application uses Crystal ECR templates. A clean app
starts with:

```text
src/views/
├── home/index.ecr
└── layouts/application.ecr
```

The application controller selects the layout:

```crystal
class ApplicationController < Amber::Controller::Base
  LAYOUT = "application.ecr"
end
```

Render a template from its matching controller directory:

```crystal
class HomeController < ApplicationController
  def index
    page_title = "Amber V2"
    render("index.ecr")
  end
end
```

The local variable is available to `src/views/home/index.ecr`:

```crystal
<h1><%= page_title %></h1>
```

The layout receives the rendered action body as `content`:

```crystal
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/css/app.css">
  </head>
  <body>
    <%= content %>
    <script src="/js/app.js"></script>
  </body>
</html>
```

Pass `layout: false` for a response that must not use the application layout,
or render a partial with `render(partial: "_item.ecr")`.

The V2 CLI generator emits ECR only. Slang, Kilt, Mustache, and Temel examples
on the V1 site are maintenance references for old applications, not choices in
the new V2 web template. See the [exact generated project](../web-template/)
for asset paths and file structure.
