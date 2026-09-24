---
title: "Forms and actions"
section: "guides/pet-tracker-everywhere"
order: 25
description: "Trace the generated Pet Tracker form through Amber HTTP, UIKit, and Android callbacks"
---

# Forms and actions

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

The shared form has one purpose and three honest delivery paths. A browser sends
an HTTP request. iOS and Android call native callbacks. All end up in
`PetTracker::Store`, then build `PetTrackerScreen` again.

## Where the examples go

- web adapter: `src/platform/web/pet_controller.cr`;
- iOS adapter: `src/platform/ios/app.cr`;
- Android adapter: `src/platform/android/app.cr`;
- shared form: `src/views/pet/pet_tracker_screen.cr`.

```text
                         PetTrackerScreen
                         Save pet intent
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        browser POST       iOS tap       Android tap
              │               │               │
     WebPetController       native callbacks  │
              │               │               │
              └──────── PetTracker::Store ────┘
                              │
                              ▼
                    rebuild the shared screen
```

## Web: let Amber handle the request

The generated web adapter lives at
`src/platform/web/pet_controller.cr`. Its create action reads the submitted
fields, calls the shared store, then redirects:

```crystal
def create
  PetTracker.store.save(params["name"]?.to_s, params["species"]?.to_s)
  redirect_to "/"
rescue error : ArgumentError
  @error_message = error.message || "Please check the pet details"
  response.status_code = 422
  page
end
```

The screen’s `UI::Form` gives the renderer everything it needs for the HTTP
side: `/pets`, named inputs, a submit button, and a CSRF token. The controller
does not rebuild those fields in ECR. It asks `PetTrackerScreen` to render and
places that result in the page shell.

The adoption button follows the same path through
`POST /pets/:id/toggle-adopted`.

## Android: keep typed values in the native host

The native adapter lives at `src/platform/android/app.cr`. It keeps the two
field values, supplies callbacks to the shared screen, and saves through the
same store:

```crystal
PetTrackerScreen.new(
  state: PetTracker.store.snapshot(@@notice),
  name: @@name,
  species: @@species,
  on_name_change: ->(value : String) { @@name = value },
  on_species_change: ->(value : String) { @@species = value },
  on_save: -> {
    begin
      PetTracker.store.save(@@name, @@species)
      @@name = ""
      @@species = ""
      persist
    rescue error : ArgumentError
      @@notice = error.message || "Please check the pet details"
    end
    UI::Android::Application.invalidate
  },
  on_toggle_adopted: ->(id : Int64) {
    PetTracker.store.toggle_adopted(id)
    persist
    UI::Android::Application.invalidate
  },
)
```

The Save callback validates through the shared store, persists the new snapshot
through Android’s storage bridge, clears the fields, and invalidates the native
view. Invalidation asks the renderer to build `PetTrackerScreen` again with
current state.

## iOS: use the same callbacks through UIKit

`src/platform/ios/app.cr` supplies the same name, species, and save callbacks.
Its invalidation callback crosses the C ABI into `PetTrackerBridge.swift`,
stores the serialized snapshot in `UserDefaults`, and asks SwiftUI to mount the
new UIKit tree. The shared form does not know which native host called it.

There is no local web server between the Android button and the application.
The controller responsibility still exists: translate an input event, call
application code, choose the next state, and render.

## Test the behavior people can observe

The generated checks cover all paths:

- `crystal spec` proves save, adoption, and snapshot round trips without a
  platform dependency;
- the web acceptance run submits a real CSRF-protected form and sees the new
  pet in the next response;
- Android instrumentation types into native fields, taps Save, and finds the
  new card in the rendered view tree;
- the Android lifecycle run kills the process, launches a new one, and proves
  the saved pet was restored;
- the iOS UI test repeats the input and save journey, terminates the app, and
  finds the restored card after a fresh simulator launch.

That last check matters. A successful tap only proves the current process
changed. The cold-process check proves the generator wired storage and startup
restoration together.

Continue with [Platform services](platform-services/) to see the shared store
and the point where a real database or API can replace the tutorial adapter.
