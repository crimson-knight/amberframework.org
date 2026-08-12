---
title: "Import Maps"
section: "guides/assets"
order: 10
description: "Map browser-native JavaScript modules through Amber's fingerprinted asset manifest"
---

# Import Maps

Import maps let a browser resolve a stable module name such as `app` to a
JavaScript module. They do not require Node.js, npm, or a bundler. Asset
Pipeline adds a production cache boundary by mapping logical source names to
content-fingerprinted public URLs.

> **Supported web path:** Amber CLI `2.0.5` generates one manifest-aware import
> map for browser-ready local modules. External modules remain an application
> choice with their own availability, privacy, and review boundary.

## Where the examples go

**Reference file map:**

```text
my_app/
├── app/assets/javascript/
│   ├── app.js
│   ├── controllers/menu.js
│   └── lib/format-date.js
├── public/assets/manifest.json                    # generated
└── src/views/layouts/application.ecr
```

Complete the [Asset Pipeline setup](../) first. The examples below extend its
existing compiler and Amber manifest configuration.

## Create the local modules

**File: `app/assets/javascript/controllers/menu.js` — create this complete
module.**

```javascript
export function connectMenu() {
  const button = document.querySelector("[data-menu-button]")
  const menu = document.querySelector("[data-menu]")

  button?.addEventListener("click", () => {
    const open = button.getAttribute("aria-expanded") !== "true"
    button.setAttribute("aria-expanded", String(open))
    menu?.toggleAttribute("data-open", open)
  })
}
```

**File: `app/assets/javascript/lib/format-date.js` — create this complete
module.**

```javascript
export function formatDate(value) {
  return new Intl.DateTimeFormat(document.documentElement.lang).format(value)
}
```

**File: `app/assets/javascript/app.js` — create the application entry point.**

```javascript
import { connectMenu } from "menu-controller"
import { formatDate } from "format-date"

connectMenu()

for (const element of document.querySelectorAll("[data-date]")) {
  element.textContent = formatDate(new Date(element.dataset.date))
}
```

The entry point imports stable names, not generated digest filenames. The ECR
layout owns their mapping.

## Render one manifest-aware import map

**File: `src/views/layouts/application.ecr` — place the import map in `<head>`,
before any module script. Extend the generated import-map helper call; do not
add a second map.**

```ecr
<%= javascript_importmap_tag(
  {
    "app" => "javascript/app.js",
    "menu-controller" => "javascript/controllers/menu.js",
    "format-date" => "javascript/lib/format-date.js"
  },
  preload: [
    "javascript/app.js",
    "javascript/controllers/menu.js"
  ]
) %>
```

**File: `src/views/layouts/application.ecr` — place the module entry point just
before `</body>`.**

```ecr
<%= content %>
<script type="module">import "app";</script>
</body>
```

The helper resolves each application-owned logical path through
`public/assets/manifest.json` and emits fingerprinted URLs. Its `preload` values
are logical asset paths, not import-map keys and not generated filenames.

## Add an external module deliberately

External modules add availability, privacy, integrity, compatibility, and
release-policy concerns. Prefer reviewed local modules. If a remote module earns
its place, pin an exact artifact and put the external URL directly in the same
map; external URLs pass through without a manifest lookup.

**File: `src/views/layouts/application.ecr` — extend the existing map; do not
render another one.**

```ecr
<%= javascript_importmap_tag(
  {
    "app" => "javascript/app.js",
    "chart.js" => "https://cdn.example.invalid/chart.js@REVIEWED_VERSION/+esm"
  },
  preload: ["javascript/app.js"]
) %>
```

The example domain and version marker are intentionally nonfunctional. Replace
them only after reviewing a real provider, exact version, browser format,
license, privacy impact, and outage behavior. Self-host the reviewed module
under `app/assets/javascript/vendor/` when the application must work without a
third-party runtime dependency.

## CSS is part of the same release

An import map solves JavaScript names; it does not load styles. Keep CSS in the
same authored tree and resolve it through the same manifest.

**File: `src/views/layouts/application.ecr` — place this helper in `<head>`.**

```ecr
<%= stylesheet_link_tag("stylesheets/app.css") %>
```

The compiler rewrites local `url(...)` references inside that stylesheet, so
images and fonts receive the same content-addressed release boundary. Do not
append hand-maintained `?v=` values to CSS, JavaScript, images, or fonts. A byte
change creates a new fingerprinted path automatically.

## Build and verify

**Run from: the application root.**

```bash
amber assets build
amber assets check
crystal spec
amber watch
```

Use **View Source** and the browser network panel to confirm:

1. exactly one import map appears before the module entry point;
2. every local mapped value is a fingerprinted `/assets/` URL;
3. every preloaded module is used and returns JavaScript;
4. no source file imports a generated digest filename;
5. there are no module-resolution or CSP errors; and
6. rebuilding after a module edit changes its mapped URL.

If a strict manifest lookup fails, compare the logical value in
`src/views/layouts/application.ecr` with the relative source path below
`app/assets/`, then rebuild. Do not “fix” a missing entry by pasting a raw public
path into the import map.

Continue with [Stimulus integration](stimulus/) for an optional controller
organization pattern.
