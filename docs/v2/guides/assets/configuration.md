---
title: "Configuration"
section: "guides/assets"
order: 30
description: "Asset Pipeline configuration and deployment options"
---

# Configuration

> **Preview ecosystem guide:** Asset Pipeline is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

This guide covers Asset Pipeline configuration options, environment setup, and deployment best practices.

## FrontLoader Options

### Basic Configuration

```crystal
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"]
) do |import_maps|
  # Import map configuration
end
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `js_source_path` | Path | - | Source directory for JavaScript files |
| `js_output_path` | Path | - | Output directory for processed files |
| `clear_cache_upon_change` | Bool | `true` | Auto-clear cache when files change |

### Cache Clearing

```crystal
# Automatic cache clearing (default)
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"]
)

# Disable for debugging
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: false
)
```

## Directory Structure

### Recommended Layout

```
my_app/
├── src/
│   └── javascript/
│       ├── controllers/
│       │   ├── application_controller.js
│       │   ├── dropdown_controller.js
│       │   └── modal_controller.js
│       ├── services/
│       │   └── api_service.js
│       └── utils/
│           └── helpers.js
├── public/
│   └── javascript/
│       └── (generated files)
└── config/
    └── initializers/
        └── assets.cr
```

### Initializer Setup

```crystal
# config/initializers/assets.cr
require "asset_pipeline"

JS_SOURCE_PATH = Path["src/javascript"]
JS_OUTPUT_PATH = Path["public/javascript"]

FRONT_LOADER = AssetPipeline::FrontLoader.new(
  js_source_path: JS_SOURCE_PATH,
  js_output_path: JS_OUTPUT_PATH
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

  # Stimulus
  import_map.add_import(
    "@hotwired/stimulus",
    "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
    preload: true
  )

  # Controllers
  Dir.glob("#{JS_SOURCE_PATH}/controllers/*_controller.js").each do |file|
    name = File.basename(file, ".js").split("_").map(&.capitalize).join
    import_map.add_import(name, "controllers/#{File.basename(file)}")
  end

  import_maps << import_map
end
```

## Environment Configuration

### Development vs Production

```crystal
ENVIRONMENT = ENV["AMBER_ENV"]? || "development"

FRONT_LOADER = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: ENVIRONMENT == "development"
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

  # Always include Stimulus
  import_map.add_import(
    "@hotwired/stimulus",
    "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
    preload: true
  )

  # Environment-specific configuration
  case ENVIRONMENT
  when "development"
    # Development tools
    import_map.add_import("DebugController", "controllers/debug_controller.js")
  when "production"
    # Production analytics
    import_map.add_import("AnalyticsController", "controllers/analytics_controller.js")
  end

  import_maps << import_map
end
```

### Feature Flags

```crystal
FEATURES = {
  "new_checkout"       => ENV["FEATURE_NEW_CHECKOUT"]? == "true",
  "advanced_analytics" => ENV["FEATURE_ANALYTICS"]? == "true"
}

FRONT_LOADER = AssetPipeline::FrontLoader.new(...) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

  # Base imports
  import_map.add_import("@hotwired/stimulus", "...", preload: true)

  # Feature-flagged imports
  if FEATURES["new_checkout"]
    import_map.add_import("NewCheckoutController", "controllers/new_checkout_controller.js")
    import_map.add_import("stripe", "https://js.stripe.com/v3/")
  else
    import_map.add_import("LegacyCheckoutController", "controllers/legacy_checkout_controller.js")
  end

  if FEATURES["advanced_analytics"]
    import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
    import_map.add_import("AnalyticsController", "controllers/analytics_controller.js")
  end

  import_maps << import_map
end
```

## CDN Configuration

### Using Subresource Integrity (SRI)

For production, consider using SRI hashes:

```crystal
# Add integrity checks for CDN resources
import_map.add_import(
  "@hotwired/stimulus",
  "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm"
)

# In your layout, add integrity attribute manually if needed
# <script src="..." integrity="sha384-..." crossorigin="anonymous">
```

### Fallback Strategy

```crystal
production_js = <<-JS
  // CDN fallback strategy
  window.loadWithFallback = async (primary, fallback) => {
    try {
      return await import(primary);
    } catch (e) {
      console.warn(`Failed to load ${primary}, trying fallback`);
      return await import(fallback);
    }
  };
JS

FRONT_LOADER.render_initialization_script(production_js)
```

## Layout Integration

### ECR Template

```ecr
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= page_title %></title>
    <%= FRONT_LOADER.render_import_map_tag %>
    <link rel="stylesheet" href="/css/application.css">
  </head>
  <body>
    <header><%= render_partial "layouts/_navigation" %></header>
    <main><%= content %></main>
    <footer><%= render_partial "layouts/_footer" %></footer>
  </body>
</html>

    / Stimulus initialization at end of body
    == FRONT_LOADER.render_stimulus_initialization_script
```

### ECR Template

```erb
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title><%= page_title %></title>

  <%= FRONT_LOADER.render_import_map_tag %>
  <link rel="stylesheet" href="/css/application.css">
</head>
<body>
  <main>
    <%= content %>
  </main>

  <%= FRONT_LOADER.render_stimulus_initialization_script %>
</body>
</html>
```

## Deployment

### Docker Configuration

```dockerfile
FROM crystallang/crystal:latest

WORKDIR /app

# Copy source
COPY . .

# Install dependencies
RUN shards install --production

# Build application
RUN crystal build src/app.cr -o bin/app --release

# JavaScript files are served directly (no build step needed)
# public/javascript/ contains your source files

EXPOSE 3000
CMD ["./bin/app"]
```

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name myapp.com;

    # Serve static JavaScript with caching
    location /javascript/ {
        alias /var/www/myapp/public/javascript/;
        expires 1y;
        add_header Cache-Control "public, immutable";

        # Enable CORS for CDN resources
        add_header Access-Control-Allow-Origin *;
    }

    # Proxy to Crystal app
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install Crystal
        uses: crystal-lang/install-crystal@v1

      - name: Install dependencies
        run: shards install --production

      - name: Build
        run: crystal build src/app.cr -o bin/app --release

      - name: Deploy
        run: |
          # JavaScript files are ready to serve
          # No npm/webpack build step needed
          rsync -avz public/ $DEPLOY_HOST:/var/www/myapp/public/
          rsync -avz bin/app $DEPLOY_HOST:/var/www/myapp/bin/
```

## Performance Tips

### 1. Preload Critical Resources

```crystal
# Preload essential libraries
import_map.add_import("@hotwired/stimulus", "...", preload: true)
import_map.add_import("ApplicationController", "...", preload: true)

# Don't preload optional features
import_map.add_import("ChartController", "...")  # No preload
```

### 2. Use CDN for Libraries

```crystal
# Good: CDN with global caching
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm")

# Less optimal: Self-hosted (unless you have specific requirements)
import_map.add_import("lodash", "/vendor/lodash.js")
```

### 3. Lazy Load Non-Critical Features

```javascript
// Load chart library only when needed
export default class extends Controller {
  async showChart() {
    const { Chart } = await import("chart.js/auto")
    new Chart(this.element, this.config)
  }
}
```

### 4. Monitor Bundle Size

Keep track of what you're importing. ESM modules from CDNs are tree-shakeable, but be mindful of large dependencies.
