---
title: "Webpack to ESM Migration"
section: "migration-guide"
order: 10
description: "Replace Webpack bundling with native ESM modules and import maps"
---

# Migrating from Webpack to ESM

> **Two distinct paths:** Amber `2.0.0-beta.3` supports browser-native ESM,
> import maps, and locally served CSS and JavaScript without an additional
> shard. The Asset Pipeline steps later in this page are an optional ecosystem
> preview, not part of the beta web-app release gate. Confirm its current
> compatibility before adding it.

Amber 2.0 removes Webpack from the generated baseline. An application can move
its reviewed browser-ready CSS and JavaScript under `public/`, map local ES
modules in the ECR layout, and eliminate Node and npm when no remaining source
asset requires their build tools. Start with the supported [Import Maps
guide](../guides/assets/import-maps/) before deciding whether the separate
Asset Pipeline preview adds value.

## Where the examples go

Run migration commands from the application root. The supported baseline keeps
browser-ready JavaScript in `public/js/`, CSS in `public/css/`, and import-map
tags in `src/views/layouts/application.ecr`. The optional Asset Pipeline path
keeps editable JavaScript in `src/javascript/`, generated output in
`public/javascript/`, and loader configuration in `config/application.cr`,
which the released V2 template loads directly.

## Why Migrate?

| Aspect | Webpack | Optional Asset Pipeline preview |
|--------|---------|----------------|
| Build time | 10-60+ seconds | None |
| Configuration | Complex webpack.config.js | Simple Crystal code |
| Dependencies | npm, node_modules | CDN or local files |
| Debugging | Source maps required | Native browser tools |
| Hot reload | Requires HMR plugin | Built-in browser support |

## Optional Asset Pipeline preview path

The remaining steps evaluate `amberframework/asset_pipeline`. They are not
required for the supported local-module pattern above.

### 1. Add Asset Pipeline Shard

```yaml
# shard.yml
dependencies:
  asset_pipeline:
    github: amberframework/asset_pipeline
    version: ~> 0.36.0
```

```bash
shards install
```

### 2. Configure Asset Pipeline

**File: `config/application.cr` — keep `require "amber"`, then append this
configuration.**

```crystal
require "asset_pipeline"

JS_SOURCE_PATH = Path["src/javascript"]
JS_OUTPUT_PATH = Path["public/javascript"]

FRONT_LOADER = AssetPipeline::FrontLoader.new(
  js_source_path: JS_SOURCE_PATH,
  js_output_path: JS_OUTPUT_PATH
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

  # Add your dependencies here (see Step 4)

  import_maps << import_map
end
```

### 3. Update Layout

**Before (Webpack):**
```slang
doctype html
html
  head
    title My App
    / Webpack bundle
    script src="/dist/bundle.js"
  body
    == content
```

**After (Asset Pipeline):**
```ecr
<!doctype html>
<html>
  <head>
    <title>My App</title>
    <%= FRONT_LOADER.render_import_map_tag %>
  </head>
  <body>
    <%= content %>
    <%= FRONT_LOADER.render_stimulus_initialization_script %>
  </body>
</html>
```

### 4. Migrate Dependencies

Find your npm dependencies and replace with CDN imports:

**package.json (before):**
```json
{
  "dependencies": {
    "@hotwired/stimulus": "^3.2.2",
    "jquery": "^3.7.1",
    "lodash": "^4.17.21",
    "chart.js": "^4.4.0"
  }
}
```

**Asset Pipeline (after):**
```crystal
# config/application.cr
import_map.add_import(
  "@hotwired/stimulus",
  "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
  preload: true
)

import_map.add_import(
  "jquery",
  "https://cdn.jsdelivr.net/npm/jquery@3.7.1/+esm"
)

import_map.add_import(
  "lodash",
  "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm"
)

import_map.add_import(
  "chart.js",
  "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm"
)
```

### 5. Migrate JavaScript Files

Move and update your JavaScript:

**Before (`src/assets/javascripts/application.js`):**
```javascript
// Webpack imports
import { Application } from "@hotwired/stimulus"
import HelloController from "./controllers/hello_controller"

const app = Application.start()
app.register("hello", HelloController)
```

**After (`src/javascript/controllers/hello_controller.js`):**
```javascript
// Native ESM - same syntax, no bundler
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  greet() {
    this.outputTarget.textContent = "Hello!"
  }
}
```

The Asset Pipeline handles Stimulus initialization automatically.

### 6. Register Controllers

```crystal
# config/application.cr
import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

import_map.add_import(
  "@hotwired/stimulus",
  "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
  preload: true
)

# Register your Stimulus controllers
import_map.add_import("HelloController", "controllers/hello_controller.js")
import_map.add_import("DropdownController", "controllers/dropdown_controller.js")
import_map.add_import("ModalController", "controllers/modal_controller.js")

# Or auto-discover controllers
Dir.glob("#{JS_SOURCE_PATH}/controllers/*_controller.js").each do |file|
  name = File.basename(file, ".js")
    .split("_")
    .map(&.capitalize)
    .join
    .gsub("Controller", "Controller")  # Ensure "Controller" suffix

  import_map.add_import(name, "controllers/#{File.basename(file)}")
end
```

### 7. Clean Up Webpack

```bash
# Remove Webpack files
rm webpack.config.js
rm -rf node_modules
rm package.json
rm package-lock.json
rm yarn.lock

# Remove Webpack from .gitignore entries
# Edit .gitignore to remove node_modules/, dist/, etc.
```

## Common Migration Patterns

### jQuery

**Webpack:**
```javascript
import $ from "jquery"

$(document).ready(() => {
  $(".dropdown").dropdown()
})
```

**ESM:**
```crystal
# config/application.cr
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/+esm")
```

```javascript
// src/javascript/app.js
import $ from "jquery"

document.addEventListener("DOMContentLoaded", () => {
  $(".dropdown").dropdown()
})
```

### React/Vue/Angular

For complex SPA frameworks, you have options:

**Option 1: Use ESM builds from CDN**
```crystal
# React
import_map.add_import("react", "https://esm.sh/react@18")
import_map.add_import("react-dom", "https://esm.sh/react-dom@18")

# Vue
import_map.add_import("vue", "https://unpkg.com/vue@3/dist/vue.esm-browser.js")
```

**Option 2: Keep Webpack for SPA, use ESM for Amber pages**

You can run both systems:
```crystal
# For Amber-rendered pages
FRONT_LOADER.render_import_map_tag

# For SPA routes, continue serving Webpack bundle
script src="/spa/dist/bundle.js"
```

### Lodash

**Webpack:**
```javascript
import _ from "lodash"
```

**ESM (use lodash-es for tree-shaking):**
```crystal
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm")
```

```javascript
// Import specific functions for smaller bundles
import { debounce, throttle } from "lodash"
```

### TypeScript

TypeScript requires compilation. Options:

1. **Pre-compile TypeScript** to JavaScript, serve ESM
2. **Use esbuild** for fast TypeScript compilation
3. **Keep minimal Webpack** for TypeScript only

```bash
# Option 2: esbuild
npm install -g esbuild

# Compile TypeScript to ESM
esbuild src/typescript/*.ts --outdir=public/javascript --format=esm
```

## Directory Structure Migration

**Before (Webpack):**
```
my_app/
├── src/
│   └── assets/
│       └── javascripts/
│           ├── application.js
│           └── controllers/
├── node_modules/
├── webpack.config.js
├── package.json
└── public/
    └── dist/
        └── bundle.js
```

**After (Asset Pipeline):**
```
my_app/
├── src/
│   └── javascript/
│       ├── controllers/
│       │   ├── hello_controller.js
│       │   └── dropdown_controller.js
│       ├── services/
│       │   └── api_service.js
│       └── utils/
│           └── helpers.js
├── config/
│   └── initializers/
│       └── assets.cr
└── public/
    └── javascript/
        └── (served directly - no build step)
```

## Handling CSS

Asset Pipeline focuses on JavaScript. For CSS, continue using your existing approach:

**Option 1: Plain CSS**
```ecr
<link rel="stylesheet" href="/css/application.css">
```

**Option 2: Sass compilation**
```bash
# Compile Sass separately
sass src/stylesheets:public/css --watch
```

**Option 3: Tailwind CSS**
```bash
# Tailwind CLI (no npm required)
tailwindcss -i src/css/input.css -o public/css/output.css --watch
```

## Testing the Migration

### 1. Check Browser Console

Open browser DevTools and verify:
- No 404 errors for JavaScript files
- Import map loads correctly
- Stimulus controllers connect

### 2. Verify Functionality

Test interactive features:
- Form submissions
- Dropdowns/modals
- Dynamic content loading
- WebSocket connections

### 3. Performance Comparison

```bash
# Before (Webpack build time)
time npm run build

# After (no build!)
# Just save and refresh
```

## Rollback Plan

If issues arise, you can run both systems temporarily:

```crystal
# config/application.cr
FRONT_LOADER = AssetPipeline::FrontLoader.new(...)

# In layout, conditionally use one or the other
if use_new_assets?
  FRONT_LOADER.render_import_map_tag
else
  # Fall back to Webpack bundle
  raw %(<script src="/dist/bundle.js"></script>)
end
```

## Troubleshooting

### "Module not found" errors

Ensure the CDN URL uses ESM format:
```crystal
# Wrong - CommonJS format
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash/lodash.js")

# Correct - ESM format
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm")
```

### Import map not loading

Import map must be in `<head>` before any module scripts:
```ecr
<head>
  <%= FRONT_LOADER.render_import_map_tag %>
  <!-- other head content -->
</head>
```

### Stimulus controllers not connecting

Verify controller naming:
```crystal
# Import name must end with "Controller"
import_map.add_import("HelloController", "controllers/hello_controller.js")  # Correct
import_map.add_import("hello", "controllers/hello_controller.js")            # Wrong
```

### CORS errors

For CDN resources, most major CDNs handle CORS. If self-hosting:
```nginx
location /javascript/ {
  add_header Access-Control-Allow-Origin *;
}
```
