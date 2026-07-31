---
title: "Import Maps"
section: "guides/assets"
order: 10
description: "Managing JavaScript dependencies with import maps"
---

# Import Maps

> **Preview ecosystem guide:** Asset Pipeline is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

Import maps allow you to control how JavaScript module specifiers are resolved by the browser, enabling you to use bare module names like `import _ from "lodash"` without a bundler.

## Basic Usage

### Creating Import Maps

```crystal
front_loader = AssetPipeline::FrontLoader.new

import_map = front_loader.get_import_map

# Add dependencies from CDN
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")

# Add local modules
import_map.add_import("utils", "/javascript/utils.js")
import_map.add_import("UserService", "/javascript/services/user_service.js")
```

### Preloading Critical Modules

Mark critical modules for preloading to improve page load performance:

```crystal
# Preload essential libraries
import_map.add_import(
  "@hotwired/stimulus",
  "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
  preload: true
)

import_map.add_import(
  "chart.js",
  "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm",
  preload: true
)
```

Generated HTML includes preload hints:

```html
<script type="importmap">{"imports": {...}}</script>
<link rel="modulepreload" href="https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm">
<link rel="modulepreload" href="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm">
```

## Multiple Import Maps

Create different import maps for different sections of your application:

```crystal
front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  # Main application
  app_map = AssetPipeline::ImportMap.new("application")
  app_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  app_map.add_import("UserController", "user_controller.js")
  import_maps << app_map

  # Admin-specific
  admin_map = AssetPipeline::ImportMap.new("admin")
  admin_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  admin_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
  admin_map.add_import("AdminController", "admin_controller.js")
  import_maps << admin_map
end

# Render different maps for different pages
front_loader.render_import_map_tag("application")  # Main pages
front_loader.render_import_map_tag("admin")        # Admin pages
```

## Scoped Imports

Define path-specific module resolution:

```crystal
import_map = front_loader.get_import_map

# Global imports
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm")

# Scoped imports for specific paths
import_map.add_scope("/admin/users", "UserManagementController", "admin/user_management_controller.js")
import_map.add_scope("/admin/analytics", "AnalyticsController", "admin/analytics_controller.js")
```

## Common CDN Sources

### jsdelivr

```crystal
# ESM format (recommended)
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
import_map.add_import("axios", "https://cdn.jsdelivr.net/npm/axios@1.6.0/+esm")
```

### unpkg

```crystal
import_map.add_import("alpinejs", "https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js")
import_map.add_import("vue", "https://unpkg.com/vue@3/dist/vue.esm-browser.js")
```

### esm.sh

```crystal
# React from esm.sh
import_map.add_import("react", "https://esm.sh/react@18")
import_map.add_import("react-dom", "https://esm.sh/react-dom@18")
```

## Popular Libraries

```crystal
# Stimulus (official Hotwire)
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm")

# jQuery
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")

# Chart.js
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")

# Lodash (ESM)
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm")

# Day.js
import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")

# Axios
import_map.add_import("axios", "https://cdn.jsdelivr.net/npm/axios@1.6.0/+esm")
```

## Local Modules

### Organizing Local JavaScript

```
src/javascript/
├── controllers/
│   ├── application_controller.js
│   ├── dropdown_controller.js
│   └── modal_controller.js
├── services/
│   ├── api_service.js
│   └── storage_service.js
└── utils/
    ├── formatting.js
    └── validation.js
```

### Mapping Local Modules

```crystal
import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

# Controllers (auto-detected as Stimulus controllers)
import_map.add_import("DropdownController", "controllers/dropdown_controller.js")
import_map.add_import("ModalController", "controllers/modal_controller.js")

# Services and utilities
import_map.add_import("ApiService", "services/api_service.js")
import_map.add_import("formatters", "utils/formatting.js")
```

## Rendering Import Maps

### Basic Rendering

```crystal
# In your layout
puts front_loader.render_import_map_tag
```

Output:

```html
<script type="importmap">
{
  "imports": {
    "@hotwired/stimulus": "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
    "lodash": "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm",
    "DropdownController": "/javascript/controllers/dropdown_controller.js"
  }
}
</script>
```

### With Initialization Script

```crystal
custom_js = <<-JS
  console.log('Application initialized');

  document.addEventListener('DOMContentLoaded', () => {
    // Initialization code
  });
JS

puts front_loader.render_import_map_tag
puts front_loader.render_initialization_script(custom_js)
```

## Environment Configuration

```crystal
environment = ENV["AMBER_ENV"]? || "development"

import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

case environment
when "development"
  # Development tools
  import_map.add_import("DebugController", "debug_controller.js")
when "production"
  # Production analytics
  import_map.add_import("AnalyticsController", "analytics_controller.js")
end
```

## Best Practices

### 1. Organize by Priority

```crystal
# Core framework first (preload)
import_map.add_import("@hotwired/stimulus", "...", preload: true)

# Essential libraries (preload if critical)
import_map.add_import("jquery", "...", preload: true)

# Utility libraries (load on demand)
import_map.add_import("lodash", "...")
import_map.add_import("dayjs", "...")

# Application controllers
import_map.add_import("NavigationController", "...")
```

### 2. Use ESM Versions

```crystal
# Good: ESM version
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm")

# Avoid: CommonJS version (may not work)
# import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.js")
```

### 3. Pin Versions

```crystal
# Good: Pinned version
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")

# Avoid: Latest (unpredictable)
# import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@latest/+esm")
```
