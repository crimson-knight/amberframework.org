---
title: "Asset Pipeline"
section: "guides"
order: 30
is_section: true
description: "Modern JavaScript asset management with ESM modules and import maps"
---

# Asset Pipeline

> **Preview ecosystem guide:** Asset Pipeline is not part of the Amber 2.0.0-beta.1
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

Amber 2.0 introduces a modern Asset Pipeline that replaces Webpack with native browser ESM modules and import maps. This provides a faster, simpler development experience without complex build tooling.

## Why Asset Pipeline?

In Amber 1.x, Webpack was required for JavaScript bundling. This created issues:

- Slow initial build times
- Complex configuration
- Node.js dependency
- Difficult debugging of bundled code

Amber 2.0 solves this with:

- Native ESM modules - no bundler required
- Import maps for dependency management
- Stimulus integration out of the box
- Automatic cache clearing
- CDN support for libraries

## Quick Start

### 1. Add the Shard

```yaml
# shard.yml
dependencies:
  asset_pipeline:
    github: amberframework/asset_pipeline
    version: ~> 0.36.0
```

### 2. Configure FrontLoader

```crystal
# config/initializers/assets.cr
require "asset_pipeline"

FRONT_LOADER = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"]
) do |import_maps|
  # Create application import map
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

  # Add Stimulus
  import_map.add_import(
    "@hotwired/stimulus",
    "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js",
    preload: true
  )

  # Add controllers
  import_map.add_import("HelloController", "hello_controller.js")

  import_maps << import_map
end
```

### 3. Add to Layout

```ecr
<!doctype html>
<html>
  <head>
    <title>My Amber App</title>
    <%= FRONT_LOADER.render_import_map_tag %>
  </head>
  <body>
    <%= content %>
    <%= FRONT_LOADER.render_stimulus_initialization_script %>
  </body>
</html>
```

### 4. Create a Controller

```javascript
// src/javascript/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  greet() {
    this.outputTarget.textContent = "Hello from Stimulus!"
  }
}
```

### 5. Use in HTML

```html
<div data-controller="hello">
  <button data-action="click->hello#greet">Greet</button>
  <span data-hello-target="output"></span>
</div>
```

## Features

### ESM Modules

Write modern JavaScript without transpilation:

```javascript
// Native ES modules
import { format } from "date-fns"
import MyService from "./services/my_service.js"

export default class MyController {
  connect() {
    console.log(format(new Date(), "yyyy-MM-dd"))
  }
}
```

### Import Maps

Manage dependencies without npm:

```crystal
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
```

### Stimulus Integration

Automatic controller detection and registration:

```crystal
# Controllers ending in "Controller" are auto-registered
import_map.add_import("DropdownController", "dropdown_controller.js")
import_map.add_import("ModalController", "modal_controller.js")

# Generates:
# - import statements
# - Application.start()
# - controller registrations
FRONT_LOADER.render_stimulus_initialization_script
```

### Automatic Cache Clearing

Cache is automatically cleared when files change:

```crystal
# Enabled by default
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"]
)

# To disable (for debugging)
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: false
)
```

## Benefits Over Webpack

| Feature | Webpack | Asset Pipeline |
|---------|---------|----------------|
| Build time | Slow | None |
| Configuration | Complex | Minimal |
| Debugging | Source maps needed | Native browser tools |
| Dependencies | npm/node_modules | CDN or local |
| Hot reload | Requires HMR setup | Browser handles it |

## Next Steps

- [Import Maps](import-maps/) - Managing JavaScript dependencies
- [Stimulus Integration](stimulus/) - Building interactive UIs
- [Configuration](configuration/) - Advanced configuration options

## Migration from Webpack

If you used Webpack in Amber 1.x, see the [Migration Guide](../../migration-guide/webpack-to-esm/) for step-by-step migration instructions.
