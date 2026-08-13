---
title: "Webpack to ESM Migration"
section: "migration-guide"
order: 10
description: "Move a working Webpack application to browser ESM and Amber's build-time asset manifest"
---

# Migrating from Webpack to ESM

Amber V2 does not require Webpack, Node.js, npm, or a JavaScript framework. A
server-rendered application can use browser-native ESM and import maps. Removing
a working build tool is still a migration, not a prerequisite for upgrading the
Amber runtime.

> **Release boundary:** Amber `2.0.0-beta.5`, Amber CLI `2.0.6`, and
> asset_pipeline `0.37.0` support the manifest contract below. Keep the existing
> build whenever the application still needs Sass,
> TypeScript, JSX, Vue single-file components, PostCSS, or another compiler.

## Decide what Webpack currently owns

Before changing files, record:

- every JavaScript entry point and dynamic chunk;
- every imported stylesheet, image, font, and source map;
- TypeScript, JSX, Sass, PostCSS, or other transformations;
- environment-variable substitutions and compile-time flags;
- development proxy and hot-module behavior;
- public paths, CSP requirements, and CDN behavior; and
- the command and artifact used by the current production deployment.

Run the existing test, build, and browser smoke checks and keep that result as
the rollback baseline. Do not delete `package.json`, the lockfile, Webpack
configuration, or the last known-good artifact yet.

## Choose the smallest migration

| Existing application | First move |
|---|---|
| Browser-ready JavaScript and CSS | Move them to the authored asset tree and use the manifest compiler |
| A few replaceable npm packages | Prefer local reviewed ESM, or pin deliberate external ESM URLs |
| TypeScript, JSX, Sass, or PostCSS | Keep that compiler; send its browser-ready output into the asset tree |
| A large SPA | Keep its build and migrate server-rendered Amber pages independently |

The Asset Pipeline build is fast and deterministic, but it is still a build.
Its job is content addressing and reference rewriting, not source-language
transpilation.

## Target file map

```text
my_app/
├── shard.yml
├── config/assets.cr
├── scripts/build_assets.cr                        # only for older CLI build environments
├── app/assets/
│   ├── stylesheets/app.css
│   ├── javascript/
│   │   ├── app.js
│   │   └── controllers/hello_controller.js
│   ├── images/
│   └── fonts/
├── public/assets/manifest.json                    # generated
└── src/views/layouts/application.ecr
```

Source control owns `app/assets/`. The compiler owns `public/assets/`. Runtime
uploads belong in neither location.

## 1. Add the released compiler

**File: `shard.yml` — add the compatible official Asset Pipeline release under
the existing `dependencies:` key.**

```yaml
dependencies:
  asset_pipeline:
    github: amberframework/asset_pipeline
    version: 0.37.0
```

**Run from: the application root.**

```bash
shards install
```

## 2. Configure the resolver and optional build wrapper

**File: `config/assets.cr` — create the runtime resolver configuration.**

```crystal
Amber::Assets.configure(
  manifest_path: "public/assets/manifest.json"
)
```

**File: `scripts/build_assets.cr` — create this complete file only when the
build environment cannot run Amber CLI `2.0.6`.**

```crystal
require "asset_pipeline/static_assets"

AssetPipeline::StaticAssets::Compiler.new(
  source_root: Path["app/assets"],
  output_root: Path["public/assets"],
  public_path: "/assets"
).build
```

Amber CLI `2.0.6` exposes the same compiler as `amber assets build` and verifies
its output with `amber assets check`. Do not load compiler construction from
`config/assets.cr`; the running app needs the resolver, not build tooling.

## 3. Move one vertical slice

Start with one page rather than every asset.

**Before: for example `src/assets/javascripts/hello_controller.js`.**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  greet() {
    this.element.textContent = "Hello!"
  }
}
```

**After: `app/assets/javascript/controllers/hello_controller.js` — move the
browser-ready module here without changing its behavior.**

If it imports a local module with `./` or `../`, keep that relative import. The
compiler fingerprints the dependency and rewrites static imports, exports,
dynamic imports, and source-map references. Bare names such as
`@hotwired/stimulus` remain for the import map.

**File: `app/assets/javascript/app.js` — create the browser entry point that
starts Stimulus and registers the migrated controller.**

```javascript
import { Application } from "@hotwired/stimulus"
import HelloController from "hello-controller"

const application = Application.start()
application.register("hello", HelloController)
```

**File: `app/assets/stylesheets/app.css` — move browser-ready CSS here.**

```css
@font-face {
  font-family: "Manrope";
  src: url("../fonts/Manrope-Variable.woff2") format("woff2");
  font-display: swap;
}

.hero {
  background: url("../images/hero.webp") center / cover no-repeat;
}
```

Place the real font and image at the referenced relative paths. Local CSS
`url(...)` and `@import` values are rewritten to fingerprinted URLs while query
strings and fragments are preserved. Root-relative, external, protocol-relative,
fragment, `data:`, and `blob:` references remain unchanged.

Asset Pipeline does not invent responsive images. Generate real widths and
formats first, store each variant under `app/assets/images/`, and write a
`srcset` or `<picture>` that names real logical files.

**Run from: the application root after the source files and every referenced
font and image exist.**

```bash
amber assets build
amber assets check
```

Stop on a missing-reference error. Do not replace it with a raw path merely to
make the build pass.

## 4. Load the configuration and update the layout

**File: the application entry point, for example `src/my_app.cr` — keep the
generated configuration wildcard or explicitly require the asset file.**

```crystal
require "../config/*"
```

Creating `config/assets.cr` is not enough if a migrated entry point never
requires it. The configuration wildcard must appear before controllers and
models; otherwise require `../config/assets` after the file that loads Amber.

**File: `src/views/layouts/application.ecr` — replace the selected page's raw
asset tags with manifest-aware helpers.**

```ecr
<head>
  <%= stylesheet_link_tag("stylesheets/app.css") %>
  <%= javascript_importmap_tag(
    {
      "app" => "javascript/app.js",
      "hello-controller" => "javascript/controllers/hello_controller.js",
      "@hotwired/stimulus" => "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm"
    },
    preload: [
      "javascript/app.js",
      "javascript/controllers/hello_controller.js"
    ]
  ) %>
</head>
<body>
  <%= content %>
  <script type="module">import "app";</script>
</body>
```

Use only one import map. Local values are strict logical manifest paths;
external URLs pass through. Prefer a reviewed self-hosted copy under
`app/assets/javascript/vendor/` when availability or privacy cannot depend on a
third party.

## 5. Keep necessary source compilers

When Webpack still compiles TypeScript, Sass, or another source language, keep
that stage and give it a separate intermediate directory outside
`public/assets/`. Then copy or generate the browser-ready result into
`app/assets/` before the manifest build.

For example, a release sequence may be:

```bash
npm ci
npm run build:browser-source
amber assets build
amber assets check
crystal spec
shards build my_app --release
```

The exact npm script is application-owned. Pin its toolchain and check its
output; do not claim “no Node” until no retained source file requires it.

## 6. Verify before removing Webpack

**Run from: the application root.**

```bash
amber assets build
amber assets check
crystal spec
amber watch
```

For every migrated page verify:

1. the manifest contains its JavaScript, CSS, images, fonts, and other files;
2. all HTML and rewritten CSS/JavaScript references use fingerprinted paths;
3. response bytes and content types are correct;
4. CSP, module imports, source maps, interactions, and reduced-motion behavior
   still work;
5. editing each asset class changes its URL after a rebuild;
6. the runtime succeeds with the release directory read-only; and
7. the prior complete release can still be started.

Only after all Webpack-owned transformations have replacements should you
remove its tags, configuration, dependency manifest, lockfile, and generated
directory in one reviewable change. Keep the repository history and prior
release artifact as rollback evidence.

## Deploy and roll back atomically

Build assets before the application binary. Package the binary, configuration,
`public/assets/manifest.json`, and every emitted asset as one release. Publish
the manifest last during a build, but switch traffic only after the whole
release verifies.

Fingerprint URLs may receive `public, max-age=31536000, immutable`. HTML,
manifest files, and unhashed legacy URLs must revalidate. Do not delete the
prior release's assets while clients may still request its HTML.

Rollback means switching to the complete prior release—not rendering an old
layout against a new manifest. During a staged migration, routing separate pages
to their existing Webpack tags and new manifest tags is safer than a runtime
conditional that mixes two asset graphs in one document.

## Troubleshooting

### A logical asset is missing

Compare the helper or import-map value with the path relative to `app/assets/`,
then rebuild. Do not paste a generated digest or raw `/assets/` URL into source.

### A local import fails

Use a relative specifier (`./` or `../`) for a local module imported by another
source module, or map a bare name in the one document import map. Confirm the
emitted JavaScript contains the dependency's fingerprinted URL.

### A font or background image fails

Resolve the source URL relative to the CSS file, not the project root. Confirm
the target is inside `app/assets/`, present in the manifest, and served with the
manifest's content type.

### A remote module reports CORS or CSP errors

Fix the selected provider and application security policy, or self-host the
reviewed ESM artifact. Do not add a blanket cross-origin response header to all
self-hosted assets; same-origin modules do not need one.
