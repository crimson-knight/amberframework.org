---
title: "Your first shared view"
section: "guides/pet-tracker-everywhere"
order: 20
description: "Follow the generated PetTrackerScreen into responsive web, UIKit, and Android output"
---

# Your first shared view

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

Let’s open the file that makes this whole experiment useful.

`src/views/pet/pet_tracker_screen.cr` is the Pet Tracker interface. The web
target renders it as semantic HTML. iOS renders it through UIKit, and Android
renders it as native Views. There is no second mobile copy hiding in a platform
folder.

## Where the examples go

The generated shared screen is
`src/views/pet/pet_tracker_screen.cr`. Web, iOS, and Android require that same
file; the snippets below are excerpts from it.

## Find the shared parent first

```text
src/views/pet/pet_tracker_screen.cr
                  │
                  │ PetTrackerScreen#build(context)
                  ▼
              UI::View tree
          ┌────────────┼────────────┐
          ▼            ▼            ▼
         web          iOS        Android
          │            │            │
          ▼            ▼            ▼
        HTML         UIKit      native Views

Future renderer branch from the same parent:
                                  └── macOS / AppKit
```

Platform folders own the small amount of glue needed to deliver events and
state. They do not own a second Pet Tracker screen.

## Build the view in ordinary Crystal

The generated file starts with a `UI::Screen`, then returns a tree of layout
and control objects:

```crystal
class PetTrackerScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    screen = UI::VStack.new(spacing: 24.0, alignment: UI::Alignment::Leading)
    screen.padding = UI::EdgeInsets.new(top: 28.0, trailing: 24.0, bottom: 36.0, leading: 24.0)
    screen.test_id = "pet-tracker-screen"
    unless web?(context)
      screen.fill_horizontal = true
      screen.background = PET_CREAM
    end
    screen << build_header(context)
    screen << build_new_pet_form(context)
    screen << build_pet_list(context)
    screen
  end
end
```

The long constructor calls use the layout produced by `crystal tool format`.
Blocks stay on the constructor line when that is the idiomatic Crystal form.

## Share the fields, adapt the form container

The fields and callback are shared. The container changes because a browser
needs an HTTP form while a native screen needs a touch layout. This excerpt is
from the generated `build_new_pet_form` method:

```crystal
private def build_new_pet_form(context : UI::ScreenContext) : UI::View
  name = UI::TextField.new(
    placeholder: "Enter a name",
    name: web?(context) ? "name" : nil,
    text: context.params["name"]? || @name,
  ) { |value| @on_name_change.try(&.call(value)) }
  name.accessibility_label = "Pet name"
  name.test_id = "pet-name"

  species = UI::TextField.new(
    placeholder: "Select a species",
    name: web?(context) ? "species" : nil,
    text: context.params["species"]? || @species,
  ) { |value| @on_species_change.try(&.call(value)) }
  species.accessibility_label = "Pet species"
  species.accessibility_hint = "Choose Cat, Dog, or Rabbit"
  species.test_id = "pet-species"

  save = UI::Button.new("Save pet", type: UI::Button::Type::Submit) do
    @on_save.try(&.call)
  end
  save.style = UI::ButtonStyle::Prominent
  save.test_id = "save-pet"

  if web?(context)
    form = UI::Form.new(action: "/pets", csrf_token: context.csrf_token)
    form.test_id = "new-pet-form"
    fields = form.add_section(header: "Add a pet")
    fields.fields << UI::Form::Field.new(label: "Name", content: name)
    fields.fields << UI::Form::Field.new(label: "Species", content: species)
    fields.fields << UI::Form::Field.new(content: save)
    return form
  end

  form = UI::VStack.new(spacing: 8.0, alignment: UI::Alignment::Fill)
  form.test_id = "new-pet-form"
  form.fill_horizontal = true
  set_native_content_width(form)
  form.padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
  form.background = PET_PAPER
  form.corner_radius = 16.0
  form.border_width = 1.0
  form.border_color = PET_LINE

  form_title = UI::Label.new("Add a pet")
  form_title.font = UI::Font.new(size: 22.0, weight: :bold)
  form_title.text_color = PET_INK if context.platform == :android
  form_title.accessibility_role = :header
  form_title.fill_horizontal = true
  form_title.text_alignment = UI::Alignment::Leading

  name.fill_horizontal = true
  name.minimum_height = 52.0
  species.fill_horizontal = true
  species.minimum_height = 52.0
  save.fill_horizontal = true
  save.minimum_height = 52.0
  if context.platform == :android
    save.background = PET_ORANGE
    save.foreground_color = PET_WHITE
  end
  save.corner_radius = 10.0

  form << form_title
  form << name
  form << species
  form << save
  form
end
```

The native branch makes each control fill the surface. Android applies the
explicit Pet Tracker action colors; iOS resolves the same prominent action
through its Amber design tokens.

The web renderer uses `action`, `name`, `type`, and the CSRF token for a normal
form submission. iOS and Android use the change and tap callbacks, a vertical
touch layout, and native text controls. Every path uses `pet-name`,
`pet-species`, and `save-pet` as stable test identities.

The native app does not send a pretend HTTP request to itself. Both event paths
call the same shared store and rebuild the same view.

## Size native cards from the real viewport

CSS owns browser breakpoints. Each native host reports its viewport before the
screen builds. The Android adapter turns that report into the width available
inside the screen’s 24-point side padding:

**File: `src/platform/android/app.cr`.**

```crystal
content_width = ((UI::Android::Application.viewport.try(&.content_width) || 360.0) - 48.0).clamp(240.0, 720.0)

PetTrackerScreen.new(
  state: PetTracker.store.snapshot(@@notice),
  native_content_width: content_width,
  # Text and button callbacks are passed here too.
).build(context)
```

The shared card builder applies that width only to native content. Browser
cards stay fluid and let CSS choose one or three columns. A phone rotation or
window change produces a new viewport report and rebuilds the same screen.

## Give resources one identity per platform

The screen also owns the relationship between a pet species and its artwork.
Only the final resource address changes:

```crystal
private def web?(context : UI::ScreenContext) : Bool
  context.platform.to_s.starts_with?("web")
end

private def image_source(context : UI::ScreenContext, species : String) : String
  slug = case species.downcase
         when "cat"    then "mochi-cat"
         when "dog"    then "rocky-dog"
         when "rabbit" then "pip-rabbit"
         else               return ""
         end

  return "/assets/pets/#{slug}.webp" if web?(context)
  context.platform == :android ? "pet-tracker/#{slug}" : "pet-tracker-#{slug}"
end
```

The browser receives a public URL. Android resolves `pet-tracker/...` through
`config/android_assets.yml`; iOS resolves `pet-tracker-...` through its Xcode
asset catalog. [Images, brand, and color](images-and-resources/) lists every
generated file and includes the complete CSS.

## Keep state shape shared, not process memory

The web server and installed mobile apps run in different processes. They use
the same `PetSummary`, `PetTrackerState`, and `PetTracker::Store` contract, but
they do not magically share RAM.

The generated tutorial keeps web state in the server process and persists each
native snapshot through its platform storage bridge. A production app can put a Grant
repository or authenticated API behind the same screen. That change belongs
in the application layer; the view does not need to move.

Continue with [Forms and actions](forms-and-actions/) to trace a browser submit
and native taps through the exact generated files.
