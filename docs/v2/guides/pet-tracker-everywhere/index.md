---
title: "Preview: Pet Tracker everywhere"
section: "guides"
order: 6
is_section: true
description: "Preview the planned shared-view generator for web, iOS, and Android"
---

# Preview: Pet Tracker everywhere

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

Hey, Amber here. This page records an engineering preview of one Pet Tracker
view rendered by web, iOS, and Android hosts. The example explores how one
application model could cross those platform boundaries.

Pet Tracker has one Crystal view tree. On the web, Amber turns it into HTML and
lets CSS use the extra room on a desktop. On iOS and Android, AssetPipeline
turns the same tree into native controls. The form, pet cards, labels, image
identities, and application rules stay together.

<figure class="pet-tracker-mockup pet-tracker-mockup-wide">
  <img src="/assets/images/guides/pet-tracker/target-comparison-5630b6871949e4dbb09fcc6ec9354ae6.webp" alt="Pet Tracker shown as one warm orange and cream interface on desktop web, mobile web, iOS, and Android beneath Amber’s primary character mark" loading="eager">
  <figcaption><strong>Design reference — not a runtime screenshot.</strong> Template <code>0.1.0-beta.3</code> follows this composition: desktop web gets the wider form-and-card grid, while mobile web, iOS, and Android keep the compact form and horizontal pet cards. The evaluated iOS renderer used system card surfaces and semantic status text instead of the mock’s colored status pills. Species remained editable text while a shared picker was still being completed.</figcaption>
</figure>

The figure uses a fingerprinted asset URL from the generated asset manifest.
Markdown does not execute ECR's `asset_path` helper; [Images, brand, and
color](images-and-resources/) explains how to refresh these URLs when a source
image changes.

The released Amber `2.0.0-beta.5` framework and `amber_cli` `2.0.6` support
web applications, including the Grant and ECR first-app walkthrough at
[Build a Pet Tracker](../pet-tracker/). They do not support the remote template
options, hybrid project type, or native target commands described in this
preview. The experiment below generated web, iOS, and Android from one
pre-release template. A macOS Pet Tracker host remains **Proposed**.

| Part | Preview evidence and current boundary |
|---|---|
| One shared `PetTrackerScreen` | **Preview:** the pinned pre-release template generated the shared screen for web, iOS, and Android in the September 20 evaluation; it is not part of the supported release path |
| Responsive web host | **Preview evidence:** a generated consumer rendered HTML, CSS, images, and a CSRF-protected save using the pre-release dependency pins |
| Android host, package, and runtime | **Preview evidence:** the evaluated template passed API 35 rendering, input, package inspection, and cold-process restoration; API 31/36 consumer runs, a physical phone, and remote CI remain open |
| iOS host and simulator runtime | **Preview evidence:** the evaluated template rendered, accepted input, and restored state on an iOS 26.5 simulator; warning cleanup, a physical iPhone, archive inspection, accessibility, and remote CI remain open |
| Preview template files | **Published for inspection:** [beta.3 manifest](https://amberframework.org/templates/pet-tracker/0.1.0-beta.3/manifest.json) and [beta.3 archive](https://amberframework.org/templates/pet-tracker/0.1.0-beta.3/pet-tracker-0.1.0-beta.3.zip); the released CLI cannot consume this remote-template format |
| macOS Pet Tracker host | **Proposed:** the template does not generate a production macOS host |

[Testing and support](testing-and-support.md#preview-evidence-from-september-20-2026)
records the exact template digests, test environments, observed results, and
open release gates.

## Planned generator shape

The published beta.3 manifest records the exact archive digest. The command
below illustrates the proposed interface; released `amber_cli` `2.0.6` does not
implement these options, so this is not a command to copy and run.

**Planned command — illustrative only, not runnable with released Amber tools:**

```text
amber new pet_tracker \
  --type hybrid \
  --targets web,android,ios \
  --template-manifest "https://amberframework.org/templates/pet-tracker/0.1.0-beta.3/manifest.json" \
  --template-manifest-sha256 c69c13076f30f66b5a40da41b71120b6b74c56ec01e36efc9e84bc7d22e1d5e4 \
  --template-version 0.1.0-beta.3 \
  --no-deps
```

This shape describes planned remote-template support. It depends on the
pre-release Amber and AssetPipeline commits named above, plus CLI features that
are not included in `amber_cli` `2.0.6`.

## Where the examples go

The planned generation shape assumes the directory that should contain the
app. Planned web, iOS, and Android build examples assume a generated application
root. Shared source examples live in `src/app` and `src/views`; each host
adapter lives beneath `src/platform`.

## See what Amber generated

The beta.3 preview bundle describes this file relationship:

```text
pet_tracker/
├── src/
│   ├── app/pets/pet_store.cr                  shared rules and state
│   ├── views/pet/pet_tracker_screen.cr        one shared UI::Screen
│   ├── platform/web/pet_controller.cr         HTTP and CSRF adapter
│   ├── platform/android/app.cr                native callbacks and storage
│   ├── platform/ios/app.cr                    UIKit callbacks and storage
│   └── pet_tracker_web.cr                     web process entrypoint
├── app/assets/
│   ├── images/pets/                           authored Mochi, Rocky, and Pip
│   └── stylesheets/pet-tracker.css            copyable responsive style
├── config/android_assets.yml                  native image-name mapping
├── mobile/android/                            Gradle host and device tests
├── mobile/ios/                                XcodeGen host and UI test
├── spec/counter_spec.cr                       shared store examples
└── .amber-template.lock.json                  exact version and hashes
```

The platform directories do not contain copies of the screen. They translate
their event system into the shared application and ask the shared screen to
build again.

## Meet the shared view

Here is the shape of the generated
`src/views/pet/pet_tracker_screen.cr`. I’m showing the useful center of it; the
generated file also contains the header, image mapping, status text, and
adoption action.

```crystal
class PetTrackerScreen < UI::Screen
  def initialize(
    @state : PetTrackerState = PetTracker.store.snapshot,
    @name : String = "",
    @species : String = "",
    @on_name_change : Proc(String, Nil)? = nil,
    @on_species_change : Proc(String, Nil)? = nil,
    @on_save : Proc(Nil)? = nil,
    @on_toggle_adopted : Proc(Int64, Nil)? = nil,
  )
  end

  def build(context : UI::ScreenContext) : UI::View
    screen = UI::VStack.new(spacing: 24.0, alignment: UI::Alignment::Leading)
    screen.test_id = "pet-tracker-screen"
    screen << build_header(context)
    screen << build_new_pet_form(context)
    screen << build_pet_list(context)
    screen
  end
end
```

That is the monolith boundary. `UI::VStack`, `UI::Form`, `UI::TextField`,
`UI::Button`, `UI::Image`, `UI::ListView`, and `UI::Card` describe the product
once. A renderer chooses HTML or native controls later.

The screen can still make a small platform-aware layout choice. Web receives a
real `UI::Form` with an action and CSRF token. iOS and Android receive a native
`UI::VStack` containing the same fields and save callback. That keeps the
product in one view file while allowing each host to use the event and layout
model it actually has. [Your first shared view](first-shared-view/) shows both
branches together.

## Preview evidence: responsive web

The September 20 consumer check used these commands with the pinned pre-release
dependencies. They document that evaluation only; they are not public setup
instructions.

**Historical preview commands — illustrative only:**

```text
crystal spec
crystal run src/pet_tracker_web.cr
```

In the evaluation, the web process served the app on `localhost:3000`. The
reviewer added a pet, toggled its adoption status, and resized the browser below
840 pixels. The desktop grid folded into the same single-column layout used by
mobile web.

The generated stylesheet is complete and editable at
`app/assets/stylesheets/pet-tracker.css`. Its public copy is served at
`/assets/pet-tracker.css`, so you can change the source, rebuild assets when you
adopt a full asset pipeline, and keep the view free of browser-only layout
decisions. [Images, brand, and color](images-and-resources/) includes the full
copyable CSS and every portrait path.

On the web, the event path is ordinary MVC:

```text
HTML form → WebPetController → PetTracker::Store → PetTrackerScreen → HTML
```

The sample keeps web state in the server process so we can concentrate on the
shared-view boundary. A real app swaps the store for its Grant repository or an
API-backed use case without moving the view.

## Preview evidence: Android

The Android host renders native controls. It also saves its Pet snapshot in
Android storage, so the generated device test can stop the process and prove
that Mabel comes back in a new one.

**Historical preview commands — illustrative only:**

```text
bash mobile/android/android.sh doctor
bash mobile/android/android.sh build
bash mobile/android/android.sh test emulator-5554
```

In the preview implementation, `doctor` checked Crystal, Java, the SDK, NDK,
platform, build tools, and ABI compilers. The evaluated `build` action created
ARM64 and x86_64 Crystal libraries, debug and release APKs, and a release AAB,
then inspected their resources and JNI exports. The `test` action required an
explicit ADB serial; it did not treat a missing device as a pass.

The native event path keeps the same center:

```text
native text/button callback → PetTracker::Store → Android storage
                            → invalidate → PetTrackerScreen → Android Views
```

Web requests and native callbacks are different delivery mechanisms. The
shared store and shared screen are the part we want one copy of.

## Preview evidence: iOS

The evaluated iOS host compiled the shared Crystal view for the simulator,
mounted its UIKit tree in SwiftUI, and stored the Pet snapshot in `UserDefaults`
through the generated bridge.

**Historical preview commands — illustrative only:**

```text
bash mobile/ios/ios.sh doctor
bash mobile/ios/ios.sh build
bash mobile/ios/ios.sh test <simulator-udid>
```

The evaluated UI test typed Mabel and Dog, tapped Save, verified the new card,
terminated the application, launched a fresh process, and verified that Mabel
returned. That is simulator evidence. A signed archive and a physical-iPhone
run remain separate gates.

```text
native text/button callback → PetTracker::Store → iOS storage
                            → invalidate → PetTrackerScreen → UIKit
```

## Add iOS or Android to a Pet Tracker that began on web

The proposed remote-template interface also describes a web-only generation
followed by native attachment. This is a design example, not a released
workflow.

**Planned command — illustrative only:**

```text
amber new pet_tracker \
  --type web \
  --template-manifest "https://amberframework.org/templates/pet-tracker/0.1.0-beta.3/manifest.json" \
  --template-manifest-sha256 c69c13076f30f66b5a40da41b71120b6b74c56ec01e36efc9e84bc7d22e1d5e4 \
  --template-version 0.1.0-beta.3 \
  --no-deps
```

The beta.3 archive describes these generated paths, but released `amber_cli`
`2.0.6` cannot consume the remote manifest or create this project.

The proposed target attachment interface looks like this:

**Planned command — illustrative only:**

```text
amber target add android --dry-run \
  --template-manifest "https://amberframework.org/templates/pet-tracker/0.1.0-beta.3/manifest.json" \
  --template-manifest-sha256 c69c13076f30f66b5a40da41b71120b6b74c56ec01e36efc9e84bc7d22e1d5e4 \
  --template-version 0.1.0-beta.3

amber target add ios --dry-run \
  --template-manifest "https://amberframework.org/templates/pet-tracker/0.1.0-beta.3/manifest.json" \
  --template-manifest-sha256 c69c13076f30f66b5a40da41b71120b6b74c56ec01e36efc9e84bc7d22e1d5e4 \
  --template-version 0.1.0-beta.3
```

The beta.3 implementation was evaluated as an additive patch that preserves
shared source and dependency files. The released CLI does not implement these
commands, and readers cannot apply the patch through the released toolchain.

Read [Adding targets](adding-targets/) for the design contract and the preview
evaluation results.

## Where we go next

This experiment gives the Amber team a shared-view acceptance app to evaluate.
The feature remains outside the supported path until the generator and pinned
dependencies are released and the open platform, accessibility, and remote-CI
gates pass. macOS is still Proposed. See [Testing and support](testing-and-support/)
for the historical results and remaining gates.
