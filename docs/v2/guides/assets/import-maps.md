---
title: "Import Maps"
section: "guides/assets"
order: 10
description: "Use browser-native import maps and local JavaScript modules without a bundler"
---

# Import Maps

Import maps let the browser resolve a stable module name such as `app` to a
JavaScript file served from your Amber application. The supported V2 baseline
uses the browser feature directly: no Node.js dependency, package manager,
bundler, UI framework, CDN, or Asset Pipeline integration is required.

## Start with one local module

**File: `public/js/app.js` — replace the generated starter module or create this
file if the application predates the V2 web template.**

```javascript
// public/js/app.js
const menuButton = document.querySelector("[data-menu-button]");
const menu = document.querySelector("[data-menu]");

menuButton?.addEventListener("click", () => {
  const open = menuButton.getAttribute("aria-expanded") !== "true";
  menuButton.setAttribute("aria-expanded", String(open));
  menu?.toggleAttribute("data-open", open);
});
```

**File: `src/views/layouts/application.ecr` — place this block immediately
before `</body>`. Replace the existing starter import-map block; do not add a
second import map.**

```ecr
<script type="importmap">
  {
    "imports": {
      "app": "/js/app.js"
    }
  }
</script>
<script type="module">import "app";</script>
```

The import map must appear before the module that uses it. Module scripts are
deferred by the browser, so the document is parsed before `app.js` executes.

## Split behavior by responsibility

Add local modules when the front end becomes large enough to benefit from
separate files.

**Reference structure — create these files under the application-owned
`public/js/` directory:**

```text
public/js/
├── app.js
├── controllers/
│   ├── menu.js
│   └── dialog.js
└── lib/
    └── format-date.js
```

**File: `src/views/layouts/application.ecr` — replace the earlier import-map
block with this expanded map.**

```ecr
<script type="importmap">
  {
    "imports": {
      "app": "/js/app.js",
      "controllers/": "/js/controllers/",
      "lib/": "/js/lib/"
    }
  }
</script>
<script type="module">import "app";</script>
```

**File: `public/js/app.js` — replace its contents with the application entry
point that composes the two controllers.**

```javascript
// public/js/app.js
import {connectMenu} from "controllers/menu.js";
import {connectDialogs} from "controllers/dialog.js";

connectMenu();
connectDialogs();
```

The trailing slash in `"controllers/"` maps every matching module prefix to
the local directory. This keeps imports readable if asset locations change
later.

## Styling stays local too

An import map solves JavaScript module names; it does not replace CSS. Keep the
front-end baseline together and visible.

**Reference structure:**

```text
public/
├── css/app.css
└── js/
    ├── app.js
    └── controllers/menu.js
```

**File: `src/views/layouts/application.ecr` — keep this stylesheet link inside
`<head>`.**

```ecr
<link rel="stylesheet" href="/css/app.css">
```

**File: `public/css/app.css` — use this as a starting layer, then extend it with
the application's components.**

```css
:root {
  --paper: #fffaf3;
  --ink: #241a15;
  --accent: #e96918;
}

.page-shell {
  display: grid;
  width: min(100% - 2rem, 72rem);
  margin-inline: auto;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

This is a complete front-end path: ECR supplies semantic HTML, local CSS owns
the visual system, and local modules add behavior progressively.

## Cache versions deliberately

Static files can use a query version when you need an explicit cache boundary.

**File: `src/views/layouts/application.ecr` — update the existing asset URLs;
do not duplicate the stylesheet or import map.**

```ecr
<link rel="stylesheet" href="/css/app.css?v=2026-08-10">
<script type="importmap">
  {"imports":{"app":"/js/app.js?v=2026-08-10"}}
</script>
```

Change the version when the file changes. Keep every mapped URL local if the
application must work offline or maintain a no-third-party-runtime policy.

## Adding a dependency is a product decision

Import maps can point at remote packages, but they do not make an external
dependency free. A remote module adds availability, integrity, privacy,
compatibility, and release-policy questions. Prefer local application modules
for the supported baseline. If a third-party package earns its place, pin and
self-host the reviewed artifact when practical.

The preview Asset Pipeline ecosystem can generate import maps for larger asset
graphs, but it is not required by the Amber 2.0.0-beta.3 web-app contract. Its
package version, API, and platform support may change independently.

See [Views](../views/) for the complete controller, ECR, and layout boundary.

## Verify the file-to-browser path

**Run from: the application root.**

```bash
crystal spec
amber watch
```

Open a rendered page, use **View Source**, and confirm that it contains one
import map before the module import. Then request `/js/app.js` directly and
confirm that Amber returns the file from `public/js/app.js`. If a nested import
fails, compare its map prefix with the matching directory under `public/js/`.
