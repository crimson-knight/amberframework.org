---
title: "Stimulus Integration"
section: "guides/assets"
order: 20
description: "Add a Stimulus controller through Asset Pipeline with explicit Amber V2 file boundaries"
---

# Stimulus integration

> **Preview ecosystem guide:** Asset Pipeline is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Confirm a compatible official release before adding it
> to an application.

This page extends the working example in the [Asset Pipeline guide](../). It
assumes that `config/application.cr` already defines `FRONT_LOADER` and that
`src/views/layouts/application.ecr` renders both Asset Pipeline tags.

Stimulus keeps behavior next to the feature it controls while Amber keeps HTML
in ECR. The three boundaries are:

**Reference file map:**

```text
config/application.cr                         # maps and registers controllers
src/javascript/controllers/                  # controller behavior
src/views/                                    # data-controller markup
```

## How registration works

Asset Pipeline treats an import-map key ending in `Controller` as a Stimulus
controller. It converts the class-style key to the identifier used in HTML.

| Import-map key | Registered identifier | View attribute |
|---|---|---|
| `HelloController` | `hello` | `data-controller="hello"` |
| `DropdownController` | `dropdown` | `data-controller="dropdown"` |
| `UserProfileController` | `user-profile` | `data-controller="user-profile"` |

The JavaScript filename alone does not trigger registration. The key in
`config/application.cr` must end in `Controller`.

## Add a dropdown controller

### 1. Map the source file

**File: `config/application.cr` — add this call inside the existing
`do |import_maps|` block, before `import_maps << import_map`.**

```crystal
import_map.add_import(
  "DropdownController",
  "controllers/dropdown_controller.js"
)
```

Do not create a second `FRONT_LOADER`. This line extends the `import_map`
created by the loader you already configured.

### 2. Create the controller

**File: `src/javascript/controllers/dropdown_controller.js` — create this
complete file.**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel"]

  connect() {
    this.close()
  }

  toggle() {
    const open = this.buttonTarget.getAttribute("aria-expanded") !== "true"
    this.buttonTarget.setAttribute("aria-expanded", String(open))
    this.panelTarget.hidden = !open
  }

  close() {
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.panelTarget.hidden = true
  }
}
```

### 3. Add the HTML boundary

**File: `src/views/home/index.ecr` — add this section inside the existing page
content. The application layout remains in `src/views/layouts/application.ecr`.**

```ecr
<section data-controller="dropdown">
  <button
    type="button"
    data-dropdown-target="button"
    data-action="click->dropdown#toggle"
    aria-controls="framework-details"
  >
    Framework details
  </button>

  <div id="framework-details" data-dropdown-target="panel">
    Amber renders the document; Stimulus adds this interaction.
  </div>
</section>
```

The identifier in `data-controller`, every `data-action`, and every target
prefix must all be `dropdown`. A mismatch is the most common reason the module
loads but does not connect.

## Pass values from ECR to JavaScript

Use Stimulus values for server-rendered configuration rather than generating
JavaScript source inside ECR.

### 1. Register the controller

**File: `config/application.cr` — add this call next to the other controller
imports inside the existing loader block.**

```crystal
import_map.add_import(
  "CountdownController",
  "controllers/countdown_controller.js"
)
```

### 2. Create the controller

**File: `src/javascript/controllers/countdown_controller.js` — create this
complete file.**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = {
    seconds: { type: Number, default: 60 }
  }

  connect() {
    this.remaining = this.secondsValue
    this.displayTarget.textContent = String(this.remaining)
    this.timer = window.setInterval(() => this.tick(), 1000)
  }

  tick() {
    this.remaining -= 1
    this.displayTarget.textContent = String(this.remaining)

    if (this.remaining <= 0) {
      window.clearInterval(this.timer)
      this.dispatch("finished")
    }
  }

  disconnect() {
    window.clearInterval(this.timer)
  }
}
```

### 3. Supply the value from a view

**File: the ECR view that owns the countdown, for example
`src/views/events/show.ecr` — add this element where the timer should render.**

```ecr
<p
  data-controller="countdown"
  data-countdown-seconds-value="30"
>
  Time remaining:
  <span data-countdown-target="display" aria-live="polite">30</span>
</p>
```

In a real application, escape any user-controlled value before placing it in
an HTML attribute. Keep the controller generic; the ECR view owns the value for
this page.

## Add a third-party module deliberately

Remote modules add availability, privacy, integrity, and release-policy risks.
If a dependency earns its place, pin its version in the same import map as the
controller that uses it.

**File: `config/application.cr` — add both imports inside the existing loader
block. Replace the URL only after reviewing and pinning the chosen artifact.**

```crystal
import_map.add_import(
  "chart.js",
  "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm"
)
import_map.add_import(
  "ChartController",
  "controllers/chart_controller.js"
)
```

**File: `src/javascript/controllers/chart_controller.js` — import the exact
name mapped above.**

```javascript
import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  connect() {
    this.chart = new Chart(this.element, {
      type: "bar",
      data: {
        labels: ["HTML", "JSON"],
        datasets: [{ label: "Responses", data: [8, 5] }]
      }
    })
  }

  disconnect() {
    this.chart.destroy()
  }
}
```

**File: the ECR view that owns the chart, for example
`src/views/reports/show.ecr` — add the canvas inside the page content.**

```ecr
<canvas data-controller="chart" aria-label="Response formats"></canvas>
```

For the supported no-third-party baseline, keep modules local under
`public/js/` and follow [Import Maps](import-maps/) instead.

## Verify a controller end to end

**Run from: the application root.**

```bash
crystal spec
amber watch
```

Open the page containing the controller and verify, in order:

1. the import map contains the controller's class-style key;
2. the mapped JavaScript URL returns `200 OK`;
3. the HTML uses the converted identifier;
4. the interaction works without a browser console error;
5. navigation away from the page does not leave timers or listeners running.

When debugging, trace the same path the browser follows:
`config/application.cr` → the file under `src/javascript/` → the generated URL
under `/javascript/` → the `data-controller` element in the ECR view.
