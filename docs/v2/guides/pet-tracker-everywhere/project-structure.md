---
title: "Project structure"
section: "guides/pet-tracker-everywhere"
order: 10
description: "See how generated Pet Tracker source stays shared while web and native hosts adapt it"
---

# Project structure

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

Open the generated Pet Tracker and you can see the whole product at once.
`src/app` owns the rules. `src/views` owns the interface. `src/platform`
connects those shared pieces to HTTP or native events. `mobile` contains the
host project that boots the compiled native library.

## Where the examples go

The tree below is the output of the pinned Pet Tracker generator. Open it from
the generated application root.

```text
pet_tracker/
│
├── src/                                      one application parent
│   ├── app/
│   │   └── pets/pet_store.cr                 shared values and rules
│   │
│   ├── views/
│   │   └── pet/pet_tracker_screen.cr         shared UI::Screen
│   │
│   ├── platform/                             event-system adapters
│   │   ├── web/pet_controller.cr             Amber HTTP + CSRF
│   │   ├── android/
│   │   │   ├── app.cr                        native callbacks + storage
│   │   │   └── configuration.cr              public Android configuration
│   │   └── ios/app.cr                        UIKit callbacks + storage
│   │
│   └── pet_tracker_web.cr                    web entrypoint
│
├── app/assets/                               editable authored resources
│   ├── images/pets/                          paw, Mochi, Rocky, and Pip
│   └── stylesheets/pet-tracker.css           responsive web layout
│
├── public/assets/                            immediately runnable web copies
├── config/
│   ├── native.yml                            target metadata and capabilities
│   └── android_assets.yml                    logical native image catalog
│
├── mobile/                                   platform-host parent
│   ├── android/                              Activity, Gradle, tests, scripts
│   └── ios/                                  XcodeGen, Swift host, UI test
│
├── spec/counter_spec.cr                      shared rule and snapshot specs
├── .amber-template.lock.json                 new-project template lock
└── shard.yml                                 immutable beta dependency pins
```

The mobile folders are not separate apps. Each host loads a Crystal library
built from its adapter and displays the tree returned by `PetTrackerScreen`.

## The shared parent is the product

All event paths point back to the same center:

```text
web request ──────┐
Android callback ─┼─→ PetTracker::Store ─→ PetTrackerScreen
iOS callback ─────┘
```

The web controller creates `UI::ScreenContext::Web`, supplies the CSRF token,
and passes the built tree to `UI::Web::Renderer`. The Android and iOS
entrypoints create native screen contexts, supply text and button callbacks,
and give the same built tree to their native renderers.

Those adapters stay small because they own delivery details, not duplicated
product screens.

## Resources have one logical identity

The authored portraits live once under `app/assets/images/pets`. Web serves
them as `/assets/pets/*.webp`. Android's resource compiler reads
`config/android_assets.yml` and maps them to these logical names:

```text
pet-tracker/mochi-cat
pet-tracker/rocky-dog
pet-tracker/pip-rabbit
pet-tracker/paw-mark
```

`PetTrackerScreen#image_source` chooses the browser path or logical native name
from `context.platform`. iOS packages the same portraits in
`mobile/ios/Assets.xcassets`. Card composition stays shared.

## Add-target ownership

The planned `amber target add ios` and `amber target add android` commands
would attach hosts to a web project while leaving `src/app`, `src/views`, web
source, and dependency files alone. The preview bundle is designed to write
only target-scoped files marked for the selected command.

The pre-release implementation wrote a target lock with the exact template and
archive digests, then extended `.amber-template.lock.json`. Its collision
checks stopped the operation before files were published.

## Where macOS joins

iOS is already a sibling under the same `mobile` parent. macOS remains the
proposed desktop-native target:

```text
mobile/
├── android/                                  included in the preview bundle
├── ios/                                      included in the preview bundle
└── macos/                                    proposed AppKit host
```

The macOS generator must compile the existing `src/app` and `src/views` files.
It must not create `ios/views`, `macos/views`, or another Pet Tracker screen.
That file-ownership rule is part of the four-target acceptance test.

## Entry-point boundaries

Each binary requires only what it needs. The web process loads Amber's server,
controller, session, CSRF, static-file pipe, and HTML renderer. Android and iOS
load their native UI and storage bridges. A future macOS library will load
AppKit services.

Keep server credentials, jobs, mailers, and database startup out of mobile
binaries. Keep Activity, JNI, UIKit, AppKit, and Objective-C bridge code out of
the web process. The shared app and view source between those boundaries is the
monolith.
