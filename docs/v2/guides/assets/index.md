---
title: "Asset Pipeline"
section: "guides"
order: 30
is_section: true
description: "Build and serve fingerprinted Amber V2 assets with exact file and deployment boundaries"
---

# Asset Pipeline

> **Supported web path:** Amber `2.0.0-beta.4`, Amber CLI `2.0.5`, and
> asset_pipeline `0.37.0` are release-gated together. A new CLI web application
> already contains every file and command shown below.

Asset Pipeline turns application-authored CSS, JavaScript, images, fonts, and
other static files into one deterministic release artifact. It preserves each
logical path, adds a SHA-256 content fingerprint to the emitted filename, writes
subresource-integrity metadata, rewrites local CSS `url(...)` references, and
records the result in `public/assets/manifest.json`.

The important boundary is build time. A production process must never compile
assets on its first request or require a writable application directory.

## Where the examples go

Complete these steps from the application root, the directory containing
`shard.yml`.

**Reference file map:**

```text
my_app/
├── shard.yml                                      # dependency versions
├── config/assets.cr                               # runtime manifest resolver
├── scripts/build_assets.cr                        # create for an existing app
├── app/assets/                                    # authored source; edit
│   ├── stylesheets/app.css
│   ├── javascript/app.js
│   ├── images/amber-mark.svg
│   ├── fonts/Manrope-Variable.woff2
│   └── files/getting-started.pdf
├── public/assets/                                 # generated; never hand-edit
│   ├── manifest.json
│   └── ...fingerprinted files...
└── src/views/layouts/application.ecr              # edit
```

`app/assets/` belongs to source control. `public/assets/` is build output. Build
and deploy the entire output directory together; a manifest from one build must
never be paired with files from another.

Every non-hidden regular file discovered below `app/assets/` is copied or
compiled and fingerprinted, including CSS; JavaScript and source maps; JSON, web
manifests, XML, text, HTML, and CSV; SVG, PNG, JPEG, GIF, WebP, AVIF, and icons;
WOFF, WOFF2, TTF, OTF, and EOT fonts; PDF, ZIP, and WebAssembly; and common audio
and video formats. An unknown extension is still fingerprinted and recorded as
`application/octet-stream`. Dotfiles and files inside dot-directories are
ignored; symlinks and references may not escape the source root.

Compressible text, JSON-family formats (including web manifests), XML, SVG, and
WebAssembly also receive deterministic `.gz` companions. The manifest verifier
checks that each companion expands to the recorded bytes.

## 1. Confirm the compiler dependency

**File: `shard.yml` — generated apps already contain this entry. Add it under
the existing `dependencies:` key only when upgrading an older app.**

```yaml
dependencies:
  asset_pipeline:
    github: amberframework/asset_pipeline
    version: 0.37.0
```

Keep the Amber, Grant, database-driver, and other existing entries. Do not add a
second top-level `dependencies:` key.

**Run from: the application root.**

```bash
shards install
```

## 2. Configure the runtime resolver

**File: `config/assets.cr` — create this complete file.**

```crystal
Amber::Assets.configure(
  manifest_path: "public/assets/manifest.json"
)
```

**File: `scripts/build_assets.cr` — create this complete build wrapper for an
existing pre-2.0.5 application. New CLI applications use `amber assets`.**

```crystal
require "asset_pipeline/static_assets"

manifest = AssetPipeline::StaticAssets::Compiler.new(
  source_root: Path["app/assets"],
  output_root: Path["public/assets"],
  public_path: "/assets"
).build
puts "Built #{manifest.assets.size} assets"
```

**Run from: the application root, before compiling or packaging the app.**

```bash
crystal run scripts/build_assets.cr
```

This command is the build boundary. Run it in development after authored assets
change and in every release build. It emits the fingerprinted tree and
`public/assets/manifest.json`; it does not wait for an HTTP request.

Amber CLI `2.0.5` exposes this compiler as `amber assets build` and adds
`amber assets check` for strict manifest verification. Use those commands in a
generated app. Keep the wrapper only when migrating an older app that cannot
yet invoke the new CLI in its build environment.

## 3. Add authored assets

**File: `app/assets/stylesheets/app.css` — create or move the application
stylesheet here.**

```css
@font-face {
  font-family: "Manrope";
  src: url("../fonts/Manrope-Variable.woff2") format("woff2");
  font-display: swap;
}

.brand-mark {
  background: url("../images/amber-mark.svg") center / contain no-repeat;
}
```

**Files referenced by that stylesheet — place the real bytes at these paths.**

```text
app/assets/fonts/Manrope-Variable.woff2
app/assets/images/amber-mark.svg
```

The compiler resolves local CSS URLs relative to the stylesheet, fingerprints
the referenced files, and writes their final public URLs into emitted CSS. A
reference to a missing local file fails the build. External, absolute, fragment,
and `data:` URLs pass through unchanged.

**File: `app/assets/javascript/app.js` — move browser-ready ESM here.**

```javascript
const menuButton = document.querySelector("[data-menu-button]")

menuButton?.addEventListener("click", () => {
  const open = menuButton.getAttribute("aria-expanded") !== "true"
  menuButton.setAttribute("aria-expanded", String(open))
})
```

Asset Pipeline fingerprints browser-ready files; it is not a TypeScript, Sass,
or JSX compiler. Keep a necessary upstream compiler as an earlier build stage
and feed its reviewed browser output into `app/assets/`.

## 4. Confirm the configuration load boundary

**File: `src/my_app.cr` — the generated V2 entry point loads every top-level
configuration file with this line. Keep it before controllers and models.**

```crystal
require "../config/*"
```

Replace `my_app` with the application's target name when locating the file. If a
migrated application does not load `config/*`, explicitly require
`../config/assets` from its existing entry point after the file that requires
Amber. Creating `config/assets.cr` without requiring it does nothing.

Amber loads the manifest when an asset helper first resolves a logical path. A
logical path absent from the manifest raises an error instead of silently
producing a broken production URL. Absolute paths, external URLs, fragments,
and `data:` URLs pass through.

## 5. Use logical paths in the layout

**File: `src/views/layouts/application.ecr` — replace literal asset URLs with
manifest-aware helpers.**

```ecr
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%= stylesheet_link_tag("stylesheets/app.css") %>
    <%= favicon_tag("images/amber-mark.svg") %>
    <%= javascript_importmap_tag(
      {"app" => "javascript/app.js"},
      preload: ["javascript/app.js"]
    ) %>
  </head>
  <body>
    <%= content %>
    <script type="module">import "app";</script>
  </body>
</html>
```

Use `asset_path("images/amber-mark.svg")` when no semantic tag helper fits.
`image_tag`, `stylesheet_link_tag`, `javascript_include_tag`, `favicon_tag`, and
`javascript_importmap_tag` resolve logical paths through the same manifest.
`asset_integrity("javascript/app.js")` exposes the recorded SRI value when a
custom tag needs it. Stylesheet, script, and module-preload helpers add the
manifest's integrity value and anonymous CORS mode for logical assets unless the
caller explicitly supplies those attributes.

**File: an ECR view, for example `src/views/home/index.ecr` — refer to the
logical image, not its generated digest.**

```ecr
<%= image_tag("images/amber-mark.svg", alt: "Amber Framework") %>
<a href="<%= asset_path("files/getting-started.pdf") %>">Download the guide</a>
```

Never paste a generated fingerprint into an ECR file. Source code stays stable;
the manifest changes when bytes change.

## 6. Verify the build before launch

**Run from: the application root.**

```bash
amber assets build
amber assets check
crystal spec
crystal build src/my_app.cr -o bin/my_app
amber watch
```

For an upgraded older app using the wrapper, replace the first two lines with
`crystal run scripts/build_assets.cr` and a verification program as shown in
[Configuration](configuration/).

Open a rendered page and verify all of these signals:

1. `public/assets/manifest.json` exists and contains every logical asset used by
   the page;
2. HTML references fingerprinted `/assets/` URLs rather than query versions;
3. emitted CSS references fingerprinted font and image URLs that return `200`;
4. JavaScript, CSS, image, font, and download responses have correct content
   types;
5. editing a source file and rebuilding changes that file's URL; and
6. the compiled application can run with its release directory read-only.

Do not enable year-long immutable caching until the server or reverse proxy
applies it only to fingerprinted output. HTML and `manifest.json` must remain
revalidatable so a deployment can point clients at the new release.

## Authored assets are not uploads

The manifest is for files reviewed and shipped with the application. Files
received from users at runtime have a separate security, persistence, privacy,
and cache lifecycle. Keep uploads outside `app/assets/` and
`public/assets/manifest.json`; use [Gemma storage](../uploads/storage/) or an
application-owned delivery path instead.

## Next steps

- [Configuration](configuration/) — compiler, manifest, and cache boundaries
- [Import Maps](import-maps/) — map local ESM through the manifest
- [Stimulus Integration](stimulus/) — optional controller organization
- [Webpack migration](../../migration-guide/webpack-to-esm/) — migrate in
  reviewable stages without deleting the working build too early
