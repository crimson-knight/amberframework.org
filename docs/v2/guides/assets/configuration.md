---
title: "Configuration"
section: "guides/assets"
order: 30
description: "Configure Asset Pipeline paths and cache behavior in an Amber V2 application"
---

# Asset Pipeline configuration

> **Preview ecosystem guide:** Asset Pipeline is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Confirm a compatible official release before adding it
> to an application.

This page extends the working setup from [Asset Pipeline](../). Complete that
guide first. Every relative path below is resolved from the application root,
the directory that contains `shard.yml`.

## Configuration boundary

Keep the loader in the file that the released V2 web template loads at boot.

**File: `config/application.cr` — place the loader after `require "amber"` and
`require "asset_pipeline"`. Replace the earlier `FRONT_LOADER` definition; do
not create a second loader.**

```crystal
FRONT_LOADER = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: true
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new(
    "application",
    Path["/javascript"]
  )

  import_map.add_import(
    "@hotwired/stimulus",
    "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
    preload: true
  )
  import_map.add_import("HelloController", "hello_controller.js")

  import_maps << import_map
end
```

The initializer uses three distinct path concepts:

| Setting | Example | Owns |
|---|---|---|
| `js_source_path` | `src/javascript` | Files you edit |
| `js_output_path` | `public/javascript` | Generated files Amber serves |
| public asset base path | `/javascript` | URLs written into the import map |

Do not point `js_source_path` and `js_output_path` at the same directory. Cache
clearing can remove and recreate the output directory.

## Recommended file layout

**Reference structure — create source subdirectories only when the application
needs them.**

```text
my_app/
├── config/application.cr
├── src/javascript/
│   ├── controllers/
│   │   ├── dropdown_controller.js
│   │   └── modal_controller.js
│   ├── services/
│   │   └── api_service.js
│   └── application.js
└── public/javascript/                       # generated; do not edit
```

When a source file moves into a subdirectory, update its import-map destination
to match.

**File: `config/application.cr` — add these calls inside the existing
`do |import_maps|` block, before `import_maps << import_map`.**

```crystal
import_map.add_import(
  "DropdownController",
  "controllers/dropdown_controller.js"
)
import_map.add_import(
  "ModalController",
  "controllers/modal_controller.js"
)
import_map.add_import("ApiService", "services/api_service.js")
```

**Files created by those entries:**

```text
src/javascript/controllers/dropdown_controller.js
src/javascript/controllers/modal_controller.js
src/javascript/services/api_service.js
```

An import name ending in `Controller` participates in generated Stimulus
registration. `ApiService` remains an ordinary ESM import.

## Cache behavior

`clear_cache_upon_change` defaults to `true`. Keep that default in development
while source files are changing.

If you need to preserve the output directory during a focused debugging
session, change only the option on the existing loader.

**File: `config/application.cr` — edit the existing `FRONT_LOADER` arguments.**

```crystal
FRONT_LOADER = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: false
) do |import_maps|
  # Keep the existing import-map configuration here.
end
```

This fragment is not a complete replacement for the initializer: retain the
real import-map entries from your application. Re-enable cache clearing after
debugging so stale generated files do not mask source changes.

## Layout boundary

The loader is configured in Crystal, but its output belongs in the document
layout.

**File: `src/views/layouts/application.ecr` — render the map inside `<head>` and
the initialization script immediately before `</body>`.**

```ecr
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/css/app.css">
    <%= FRONT_LOADER.render_import_map_tag %>
  </head>
  <body>
    <%= content %>
    <%= FRONT_LOADER.render_stimulus_initialization_script %>
  </body>
</html>
```

This is a complete layout example. Preserve any application-specific metadata,
navigation, and accessibility landmarks when applying it to an existing file.
Remove the V2 starter's manual import-map tags so only one import map controls
the page.

## Development and production

Keep the module graph identical across environments whenever possible. If
cache behavior must differ, calculate the option once and pass it to the same
loader.

**File: `config/application.cr` — define this value above the existing loader,
then use it for `clear_cache_upon_change`.**

```crystal
clear_asset_cache = ENV["AMBER_ENV"]? != "production"

FRONT_LOADER = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: clear_asset_cache
) do |import_maps|
  # Keep the existing import-map configuration here.
end
```

Treat this as an alternative to the earlier loader definition, not an
additional constant. The fixed `true` value is still the least ambiguous
preview setup while evaluating the dependency locally.

## Deployment boundary

There is no npm or Webpack build. The Crystal application still must render the
layout so the loader can produce the browser-facing files. Do not deploy an
empty `public/javascript/` directory and assume a separate JavaScript build will
fill it.

For a container or release image, build the Crystal application as usual, start
it with a writable `public/javascript/` path, request one page that renders the
application layout, and then verify the generated asset URL. If the production
filesystem is read-only, generate the files in a build stage or choose the
supported hand-authored import-map baseline instead of this preview.

## Verify after every configuration change

**Run from: the application root.**

```bash
crystal spec
amber watch
```

Then open a page using `src/views/layouts/application.ecr` and verify all three
signals:

1. the page source contains one `<script type="importmap">`;
2. its local controller URL begins with `/javascript/`;
3. that URL returns `200 OK` and contains the controller source.

If one signal fails, inspect `config/application.cr`, the matching file under
`src/javascript/`, and the generated directory under `public/javascript/` in
that order.
