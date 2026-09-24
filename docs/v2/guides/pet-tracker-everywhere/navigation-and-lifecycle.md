---
title: "Navigation and lifecycle"
section: "guides/pet-tracker-everywhere"
order: 50
description: "Prove Pet Tracker survives web requests and mobile process boundaries before adding more screens"
---

# Navigation and lifecycle

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

Pet Tracker has one screen on purpose. Before we add a navigation stack, we can
prove the harder foundation: the same screen rebuilds correctly across an HTTP
request and completely new iOS and Android processes.

## Where the examples go

Web routes live in `src/pet_tracker_web.cr` after the generator substitutes
your project name. Native lifecycle wiring lives under `src/platform`; the
runtime proofs are `mobile/ios/ios.sh` and `mobile/android/android.sh`.

## Web owns URLs and request history

The generated server maps these routes:

| Request | Action |
|---|---|
| `GET /` | render the shared Pet Tracker screen |
| `POST /pets` | validate and save, then redirect to `/` |
| `POST /pets/:id/details` | show the selected pet's details on `/` |
| `POST /pets/:id/toggle-adopted` | toggle state, then redirect to `/` |

Each response builds a fresh `UI::ScreenContext::Web` and renders
`PetTrackerScreen`. Browser history and reload behavior stay normal because
the web adapter uses real URLs, redirects, and CSRF-protected forms.

## Android rebuilds from application state

The generated native entrypoint registers one lifecycle callback:

```crystal
UI::Android::Application.on_lifecycle do |event|
  App::Android.load if event.foreground?
end

UI::Android::Application.configure { |_route| App::Android.screen }
```

The first foreground event starts the storage read. While it is pending, the
screen shows “Loading your pets…”. When the callback finishes, the app stores
the result and calls `UI::Android::Application.invalidate`. Android then asks
for the screen again and receives a new native view tree.

No Activity, Android View, or JNI handle is stored in the shared
`PetTracker::Store`.

## Prove a cold process, not a warm redraw

`bash mobile/android/android.sh test emulator-5554` performs the lifecycle
check in three stages:

1. install the app from a clean state, type Mabel, tap Save, and verify the new
   card exists;
2. force-stop the package, start a distinct process, and verify the exact
   starter pets plus Mabel were restored;
3. start the application once more, capture its native UI and process ID, and
   reject JNI or Crystal runtime failures.

The script requires an explicit ADB serial. A missing device, a failed native
assertion, an unchanged process boundary, or a missing artifact is a failure.

## iOS restores the same screen

`bash mobile/ios/ios.sh test <simulator-udid>` enters Mabel, saves her through
the shared store, terminates the app, and launches it again. The generated
Swift bridge reloads `pet-tracker.snapshot.v1` from `UserDefaults` before it
mounts the UIKit tree, so the restored card comes from a new application
process rather than an in-memory redraw.

## What macOS still needs

AssetPipeline already has AppKit renderer work, but this remote Pet Tracker
bundle does not generate a production macOS host yet. To add it to the
framework beta, the host must:

1. initialize Crystal and its renderer before mounting the screen;
2. load the same `PetTrackerScreen` and packaged image identities;
3. translate native input into the same application operations;
4. persist and restore the snapshot through the platform service;
5. release stale native objects during rerender and teardown;
6. prove fresh-process restoration on supported OS versions;
7. produce an inspectable archive from a clean generated project.

That list is the acceptance contract for adding a `macos` scope to the remote
template. [Testing and support](testing-and-support/) keeps the platform matrix
and its evidence in one place.
