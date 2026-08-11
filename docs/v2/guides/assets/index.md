---
title: "Asset Pipeline"
section: "guides"
order: 30
is_section: true
description: "Evaluate the preview Asset Pipeline with an explicit Amber V2 file-by-file setup"
---

# Asset Pipeline

> **Preview ecosystem guide:** Asset Pipeline is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Confirm a compatible official release before adding it
> to an application.

The separate Asset Pipeline project explores higher-level management of native
browser ESM modules and import maps. Amber's supported beta starter does not
require it. Begin with local modules in the [Import Maps](import-maps/) guide,
then evaluate this preview only when fingerprinting or generated import maps
earn the extra dependency.

## What this guide changes

Complete the steps from the root of an Amber V2 web application. Each example
names its destination and whether to create, edit, or run it. The completed
example adds these files and edits:

**Files changed by this guide:**

```text
my_app/
├── shard.yml                                      # edit
├── config/application.cr                          # edit
├── src/javascript/hello_controller.js             # create
├── src/views/home/index.ecr                       # edit
└── src/views/layouts/application.ecr              # edit
```

`public/javascript/` is generated output. Do not hand-edit files there.

## 1. Add the dependency

**File: `shard.yml` — add this entry under the existing `dependencies:` key.**

```yaml
dependencies:
  amber:
    github: amberframework/amber
    version: 2.0.0-beta.2
  asset_pipeline:
    github: amberframework/asset_pipeline
    version: ~> 0.36.0
```

Keep any other dependencies already present. YAML must contain only one
top-level `dependencies:` key.

**Run from: the application root, beside `shard.yml`.**

```bash
shards install
```

This creates or updates `shard.lock`. If dependency resolution fails, stop
here: the preview Asset Pipeline release is not compatible with the versions
selected by the application.

## 2. Configure the loader

**File: `config/application.cr` — keep the existing `require "amber"`, then
append this complete block.**

```crystal
require "asset_pipeline"

FRONT_LOADER = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"]
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

The released V2 web template loads `config/application.cr` directly. Its empty
`config/initializers/` directory is reserved for future generator output and is
not the documented loading boundary for this beta. Source JavaScript lives in
`src/javascript/`; Asset Pipeline writes browser-facing files to
`public/javascript/` when the layout renders the map.

## 3. Edit the application layout

**File: `src/views/layouts/application.ecr` — add the import-map call inside
`<head>`, after the stylesheet link.**

```ecr
<link rel="stylesheet" href="/css/app.css">
<%= FRONT_LOADER.render_import_map_tag %>
```

**File: `src/views/layouts/application.ecr` — add the initialization call just
before the closing `</body>` tag.**

```ecr
<%= content %>
<%= FRONT_LOADER.render_stimulus_initialization_script %>
</body>
```

Remove the starter's hand-authored `<script type="importmap">` and
`<script type="module">import "app";</script>` tags if they are still present.
A document must not contain competing import maps for the same module graph.

## 4. Create a Stimulus controller

**File: `src/javascript/hello_controller.js` — create this complete file.**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  greet() {
    this.outputTarget.textContent = "Hello from Stimulus!"
  }
}
```

The import-map key ends in `Controller`, so the generated initialization script
registers it as `hello`.

## 5. Use the controller in a view

**File: `src/views/home/index.ecr` — add this element inside the page's existing
main content. Do not replace the application layout.**

```ecr
<section data-controller="hello">
  <button type="button" data-action="click->hello#greet">Greet</button>
  <span data-hello-target="output" aria-live="polite"></span>
</section>
```

## 6. Verify the complete path

**Run from: the application root.**

```bash
crystal spec
amber watch
```

Open `http://127.0.0.1:3000/`, click **Greet**, and confirm that “Hello from
Stimulus!” appears next to the button. In the browser's network panel, confirm
that the Stimulus module and a fingerprinted file under `/javascript/` both
load successfully.

If the page reports that `FRONT_LOADER` is undefined, confirm that the file is
`config/application.cr` and that its configuration appears after
`require "amber"`. If the controller does not connect, confirm that the import
name is exactly `HelloController` and that only one import map is rendered on
the page.

## What Asset Pipeline adds

- native ESM modules without a JavaScript bundler;
- generated import maps and module-preload links;
- fingerprinted browser-facing JavaScript files;
- Stimulus controller imports and registration;
- cache clearing when source files change.

It does not decide the structure of your ECR views or CSS. Keep application
markup in `src/views/`, styling in `public/css/`, and behavior in
`src/javascript/`.

## Next steps

- [Import Maps](import-maps/) — the supported dependency-free V2 baseline
- [Stimulus Integration](stimulus/) — add more controllers without losing the
  file boundary
- [Configuration](configuration/) — change paths and cache behavior safely
- [Webpack migration](../../migration-guide/webpack-to-esm/) — move an Amber
  1.x application in reviewable stages
