---
title: "Stimulus Integration"
section: "guides/assets"
order: 20
description: "Add a Stimulus controller through Amber's build-time asset manifest"
---

# Stimulus integration

> **Optional library:** Amber's asset manifest is release-gated. Stimulus is an
> optional third-party dependency, not an Amber requirement; review and pin the
> exact browser artifact your application chooses.

Stimulus can add focused behavior to server-rendered ECR without moving markup
or page ownership into JavaScript. Asset Pipeline fingerprints the local modules
and Amber's manifest-aware import-map helper connects stable module names to
their generated URLs.

Complete [Asset Pipeline](../) first. This page creates and edits:

**Reference file map:**

```text
app/assets/javascript/application.js
app/assets/javascript/controllers/dropdown_controller.js
src/views/layouts/application.ecr
src/views/home/index.ecr
```

## 1. Create the controller

**File: `app/assets/javascript/controllers/dropdown_controller.js` — create
this complete file.**

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

## 2. Start Stimulus and register the controller

**File: `app/assets/javascript/application.js` — create this complete entry
point.**

```javascript
import { Application } from "@hotwired/stimulus"
import DropdownController from "dropdown-controller"

const application = Application.start()
application.register("dropdown", DropdownController)
```

Registration is explicit. A filename ending in `_controller.js` does not make
it register itself, and Asset Pipeline does not inspect application semantics.

## 3. Map the modules in the layout

**File: `src/views/layouts/application.ecr` — place this map in `<head>` before
module scripts. Replace any existing import map rather than adding a second.**

```ecr
<%= javascript_importmap_tag(
  {
    "application" => "javascript/application.js",
    "dropdown-controller" => "javascript/controllers/dropdown_controller.js",
    "@hotwired/stimulus" => "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm"
  },
  preload: [
    "javascript/application.js",
    "javascript/controllers/dropdown_controller.js"
  ]
) %>
```

**File: `src/views/layouts/application.ecr` — start the application immediately
before `</body>`.**

```ecr
<%= content %>
<script type="module">import "application";</script>
</body>
```

The two local values are strict logical paths resolved through the asset
manifest. The exact external HTTPS URL passes through. Pinning a version does
not remove CDN availability, privacy, integrity, or policy risk; to self-host,
place the reviewed browser-ready ESM artifact under
`app/assets/javascript/vendor/` and map that logical path instead.

## 4. Add the ECR markup

**File: `src/views/home/index.ecr` — add this section inside the page content.**

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

The identifier passed to `application.register`, `data-controller`, each
`data-action`, and every target prefix must be `dropdown`.

## Pass server values through HTML

Use Stimulus values or ordinary `data-*` attributes for server-rendered
configuration. Do not generate executable JavaScript from user-controlled ECR
values.

**File: `app/assets/javascript/controllers/countdown_controller.js` — create
the controller.**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = { seconds: { type: Number, default: 60 } }

  connect() {
    this.remaining = this.secondsValue
    this.displayTarget.textContent = String(this.remaining)
    this.timer = window.setInterval(() => this.tick(), 1000)
  }

  tick() {
    this.remaining -= 1
    this.displayTarget.textContent = String(this.remaining)
    if (this.remaining <= 0) window.clearInterval(this.timer)
  }

  disconnect() {
    window.clearInterval(this.timer)
  }
}
```

Then make three matching edits:

1. map `"countdown-controller"` to
   `"javascript/controllers/countdown_controller.js"` in the existing
   `javascript_importmap_tag` call;
2. import it and call `application.register("countdown", CountdownController)`
   in `app/assets/javascript/application.js`; and
3. add the following markup to its owning ECR view.

**File: for example `src/views/events/show.ecr` — add this element where the
timer belongs.**

```ecr
<p data-controller="countdown" data-countdown-seconds-value="30">
  Time remaining:
  <span data-countdown-target="display" aria-live="polite">30</span>
</p>
```

Escape user-controlled attribute values. The view owns the value; the
controller owns reusable behavior.

## Build and verify

**Run from: the application root after every module change.**

```bash
amber assets build
amber assets check
crystal spec
amber watch
```

Verify in order:

1. the manifest contains the application and every controller logical path;
2. the one import map contains fingerprinted local URLs and the intended pinned
   Stimulus URL;
3. every mapped response returns `200` with a JavaScript content type;
4. the controller connects and the keyboard and pointer interaction work;
5. navigation away cleans up timers and listeners; and
6. the browser console contains no import-map, CSP, or module errors.

Trace failures through the actual ownership chain:
`app/assets/javascript/` source → `amber assets build` →
`public/assets/manifest.json` → `src/views/layouts/application.ecr` → the
`data-controller` element.
