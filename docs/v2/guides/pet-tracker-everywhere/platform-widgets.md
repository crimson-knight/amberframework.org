---
title: "Platform widgets"
section: "guides/pet-tracker-everywhere"
order: 40
description: "See which shared controls Pet Tracker generates today and where platform-specific interactions can grow"
---

# Platform widgets

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

Pet Tracker’s first useful lesson is pleasantly small: you do not need separate
web, iOS, and Android components to make a real shared screen. The generated view uses
`UI::Form`, `UI::TextField`, `UI::Button`, `UI::Image`, `UI::ListView`, and
`UI::Card`. The renderer gives those descriptions the controls that belong on
its platform.

## Where the examples go

The generated widget composition lives in
`src/views/pet/pet_tracker_screen.cr`. Web request translation lives in
`src/platform/web/pet_controller.cr`; native callback translation lives in
`src/platform/ios/app.cr` and `src/platform/android/app.cr`.

## Use the shared control until the interaction must differ

The generated adoption action is one `UI::Button`:

```crystal
label = pet.adopted ? "Mark as waiting" : "Mark as adopted"
toggle = UI::Button.new(label, type: UI::Button::Type::Submit) do
  @on_toggle_adopted.try(&.call(pet.id))
end
toggle.test_id = "toggle-pet-#{pet.id}"
```

On web, the surrounding `UI::Form` submits an HTTP request. On iOS and Android,
the button callback invokes the proc supplied by the host. The app keeps one
intent, one test identity, and one state transition while each adapter handles
its own event system.

That is the generated baseline I want you to trust before reaching for an
override. A platform-specific widget earns its place when it improves the
platform experience without moving product rules out of the shared app.

## A future swipe-action adaptation

> **Proposed:** template `0.1.0-beta.3` does not generate a widget registry,
> swipe actions, `UI::WidgetRoute`, or platform override wiring. The adaptation
> below is a design direction and must be implemented and validated in AssetPipeline
> before it can be copied into Pet Tracker.

A later release can let one shared intent resolve to a familiar presentation:
visible actions on desktop web and macOS, touch actions on mobile web, and
native swipe actions on iOS or Android. That release needs all of the following:

1. a public AssetPipeline route/override API;
2. app and active-screen context supplied by every renderer;
3. a shared fallback when a target has no specialized widget;
4. web keyboard and focus behavior;
5. iOS, macOS, and Android gesture, accessibility, and device proof;
6. generator files and specs that install the wiring automatically.

Until those gates pass, keep the generated adoption button. It already proves
the important monolith boundary: the screen and state transition are shared,
and the delivery mechanism belongs to the host.
