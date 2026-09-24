---
title: "Themes, layout, and accessibility"
section: "guides/pet-tracker-everywhere"
order: 60
description: "Carry Pet Tracker semantics across responsive web, iOS, and Android"
---

# Themes, layout, and accessibility

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

A shared view should describe meaning before it describes pixels. Pet Tracker
uses one heading, form, list, status, image label, and action contract. Web can
arrange those pieces with CSS; iOS and Android render native controls from the
same tree.

## Where the examples go

The generated screen keeps semantic properties in
`src/views/pet/pet_tracker_screen.cr`. Browser layout stays in
`app/assets/stylesheets/pet-tracker.css`; native portrait packaging stays in
`config/android_assets.yml` and `mobile/ios/Assets.xcassets`.

## Start with the semantics the generator already uses

This is the generated field shape:

```crystal
name = UI::TextField.new(
  placeholder: "Enter a name",
  name: web?(context) ? "name" : nil,
  text: context.params["name"]? || @name,
) { |value| @on_name_change.try(&.call(value)) }
name.accessibility_label = "Pet name"
name.test_id = "pet-name"
```

The visible label, accessibility label, field name, current value, and stable
test identity travel together. The web renderer turns them into labeled HTML
and the native renderers turn them into platform text controls. The generated
header uses `accessibility_role = :header`, and every portrait carries a
pet-specific label.

## Let the browser rearrange the same view

The complete stylesheet in [Images, brand, and color](images-and-resources/)
uses a two-column grid above 840 pixels and a single column below it. The Crystal
screen does not branch for mobile web. That keeps desktop web and mobile web on
one route, one view tree, and one form contract.

Native window size is a separate concern. A phone, tablet, resizable macOS
window, and narrow browser do not become the same platform because their widths
match. Each native renderer must report its real environment and adapt layout
without changing the shared product state.

## Give native controls the same visual roles

CSS cannot style an installed native view. The generated shared screen keeps
the palette as `UI::Color` values as well as CSS custom properties, then uses
those colors in its native branch:

**File: `src/views/pet/pet_tracker_screen.cr`.**

```crystal
PET_CREAM = UI::Color.new(r: 1.0, g: 0.976, b: 0.937)
PET_PAPER = UI::Color.new(r: 1.0, g: 0.992, b: 0.976)
PET_ORANGE = UI::Color.new(r: 0.957, g: 0.478, b: 0.086)
PET_INK = UI::Color.new(r: 0.129, g: 0.098, b: 0.078)

unless web?(context)
  screen.fill_horizontal = true
  screen.background = PET_CREAM
end
```

The native form uses a vertical stack with a paper background and Amber action.
Android renders the explicit status surfaces shown in the mock. iOS uses
system card surfaces and semantic status text in this beta while preserving the
same hierarchy, labels, portraits, and touch targets.

This is the useful kind of platform branch. The screen, field identities,
callbacks, validation, pet list, and resource names remain shared. The branch
only chooses the container and surface properties that fit the host’s event and
layout system.

## Keep three axes separate

- The compile target selects a renderer and native bridge.
- Runtime window or viewport size selects an adaptive arrangement.
- User settings select appearance, text scale, contrast, motion, locale, and
  assistive behavior.

The current mobile candidates prove native control rendering, input,
persistence, and packaged portraits on an API 35 emulator and an iOS 26.5
simulator. The web proof covers responsive CSS, real requests, CSRF, and public
assets. Those are separate tests because they answer separate questions.

## Validate before promoting a component

Check long translated labels, large text, right-to-left layout, light and dark
appearance, reduced motion, keyboard operation, focus order, screen-reader
labels, error announcements, phone and tablet widths, and rotation or window
resizing. A screenshot proves one visual state; it does not prove input,
semantics, lifecycle, or saved state.

> **Preview:** UIKit now has a generated Pet Tracker host and simulator proof.
> UIKit hosting-warning cleanup and physical-iPhone accessibility remain open.
> AppKit still needs its generated host and complete runtime proof.
