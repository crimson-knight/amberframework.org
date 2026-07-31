---
title: "Stimulus Integration"
section: "guides/assets"
order: 20
description: "Building interactive UIs with Stimulus and the Asset Pipeline"
---

# Stimulus Integration

> **Preview ecosystem guide:** Asset Pipeline is not part of the Amber 2.0.0-beta.1
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

The Asset Pipeline provides first-class support for Stimulus, the modest JavaScript framework from Hotwire. It automatically detects controllers, handles imports, and registers them with the Stimulus application.

## Basic Setup

### Configure Stimulus

```crystal
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"]
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

  # Add Stimulus framework
  import_map.add_import(
    "@hotwired/stimulus",
    "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
    preload: true
  )

  # Add controllers
  import_map.add_import("HelloController", "hello_controller.js")
  import_map.add_import("DropdownController", "dropdown_controller.js")

  import_maps << import_map
end
```

### Render in Layout

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

## Automatic Controller Detection

Controllers ending with "Controller" are automatically detected and registered:

```crystal
# These are detected as Stimulus controllers
import_map.add_import("HelloController", "hello_controller.js")
import_map.add_import("DropdownController", "dropdown_controller.js")
import_map.add_import("UserProfileController", "user_profile_controller.js")

# This is NOT detected (no "Controller" suffix)
import_map.add_import("utils", "utils.js")
```

### Name Conversion

PascalCase controller names are converted to kebab-case for registration:

| Import Name | Registered As | HTML Data Attribute |
|-------------|---------------|---------------------|
| `HelloController` | `hello` | `data-controller="hello"` |
| `DropdownController` | `dropdown` | `data-controller="dropdown"` |
| `UserProfileController` | `user-profile` | `data-controller="user-profile"` |

## Writing Controllers

### Basic Controller

```javascript
// src/javascript/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "output"]

  greet() {
    const name = this.nameTarget.value || "World"
    this.outputTarget.textContent = `Hello, ${name}!`
  }
}
```

### Using in HTML

```html
<div data-controller="hello">
  <input data-hello-target="name" type="text" placeholder="Your name">
  <button data-action="click->hello#greet">Greet</button>
  <span data-hello-target="output"></span>
</div>
```

### Controller with Values

```javascript
// src/javascript/countdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    seconds: { type: Number, default: 60 }
  }
  static targets = ["display"]

  connect() {
    this.start()
  }

  start() {
    this.remaining = this.secondsValue
    this.timer = setInterval(() => this.tick(), 1000)
  }

  tick() {
    this.remaining--
    this.displayTarget.textContent = this.remaining
    if (this.remaining <= 0) {
      clearInterval(this.timer)
      this.dispatch("finished")
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
```

```html
<div data-controller="countdown" data-countdown-seconds-value="30">
  Time remaining: <span data-countdown-target="display">30</span>
</div>
```

## Custom Initialization

Add custom JavaScript alongside Stimulus initialization:

```crystal
custom_js = <<-JS
  // Global utilities
  window.formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  };

  // App initialization
  document.addEventListener('DOMContentLoaded', () => {
    console.log('Application ready');
  });

  // Custom event handlers
  document.addEventListener('stimulus:ready', () => {
    console.log('All controllers registered');
  });
JS

front_loader.render_stimulus_initialization_script(custom_js)
```

## Multiple Applications

Create separate Stimulus applications for different areas:

```crystal
front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  # Main application
  main_map = AssetPipeline::ImportMap.new("main")
  main_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  main_map.add_import("UserController", "user_controller.js")
  import_maps << main_map

  # Admin application
  admin_map = AssetPipeline::ImportMap.new("admin")
  admin_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  admin_map.add_import("AdminController", "admin_controller.js")
  admin_map.add_import("ChartController", "chart_controller.js")
  import_maps << admin_map
end

# Render for different pages
main_html = front_loader.render_stimulus_initialization_script("", "main", "mainApp")
admin_html = front_loader.render_stimulus_initialization_script("", "admin", "adminApp")
```

## Combining with Libraries

### Chart.js Integration

```crystal
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")
import_map.add_import("ChartController", "chart_controller.js")
```

```javascript
// src/javascript/chart_controller.js
import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static values = {
    type: { type: String, default: "line" },
    data: Object
  }

  connect() {
    this.chart = new Chart(this.element, {
      type: this.typeValue,
      data: this.dataValue
    })
  }

  disconnect() {
    this.chart.destroy()
  }
}
```

### Debouncing with Lodash

```crystal
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm")
import_map.add_import("SearchController", "search_controller.js")
```

```javascript
// src/javascript/search_controller.js
import { Controller } from "@hotwired/stimulus"
import { debounce } from "lodash"

export default class extends Controller {
  static targets = ["input", "results"]

  initialize() {
    this.search = debounce(this.search, 300).bind(this)
  }

  search() {
    const query = this.inputTarget.value
    fetch(`/search?q=${encodeURIComponent(query)}`)
      .then(response => response.json())
      .then(data => this.displayResults(data))
  }

  displayResults(data) {
    this.resultsTarget.innerHTML = data.map(item =>
      `<li>${item.name}</li>`
    ).join('')
  }
}
```

## Generated Output

The Asset Pipeline generates clean, optimized output:

```html
<script type="importmap">
{
  "imports": {
    "@hotwired/stimulus": "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
    "HelloController": "/javascript/hello_controller.js",
    "DropdownController": "/javascript/dropdown_controller.js"
  }
}
</script>
<link rel="modulepreload" href="https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm">

<script type="module">
import { Application } from "@hotwired/stimulus";

import HelloController from "HelloController";
import DropdownController from "DropdownController";

const application = Application.start();

// Custom initialization code here

application.register("hello", HelloController);
application.register("dropdown", DropdownController);
</script>
```

## Duplicate Removal

If you have existing Stimulus code, the Asset Pipeline automatically removes duplicates:

```crystal
# Your existing code with manual imports
existing_js = <<-JS
  import { Application } from "@hotwired/stimulus";
  import HelloController from "HelloController";

  const application = Application.start();
  application.register("hello", HelloController);

  // This custom code is kept
  console.log('App ready');
JS

# Asset Pipeline removes duplicate imports/registrations
result = front_loader.render_stimulus_initialization_script(existing_js)
```

## Best Practices

### 1. One Controller Per Feature

```javascript
// Good: Single responsibility
// dropdown_controller.js - handles dropdowns
// modal_controller.js - handles modals

// Avoid: God controller
// application_controller.js - handles everything
```

### 2. Use Targets Over querySelector

```javascript
// Good: Stimulus targets
static targets = ["input", "output"]

this.inputTarget.value
this.outputTarget.textContent = "Hello"

// Avoid: Manual DOM queries
document.querySelector('.input').value
```

### 3. Use Values for Configuration

```javascript
// Good: Configurable via HTML
static values = {
  url: String,
  delay: { type: Number, default: 300 }
}

// HTML: data-fetch-url-value="/api/data"

// Avoid: Hardcoded values
const url = "/api/data"
```

### 4. Dispatch Events for Communication

```javascript
// Controller A
this.dispatch("selected", { detail: { item: this.item } })

// Controller B
static targets = ["container"]
itemSelected(event) {
  console.log(event.detail.item)
}

// HTML
// data-action="controller-a:selected->controller-b#itemSelected"
```
