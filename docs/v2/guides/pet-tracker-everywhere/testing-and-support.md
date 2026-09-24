---
title: "Testing and support"
section: "guides/pet-tracker-everywhere"
order: 100
description: "Check Pet Tracker source, packages, Android and iOS runtimes, and the remaining beta gates"
---

# Testing and support

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

I like confidence ladders. We start with the shared rules, then prove the web
process, native packages, an emulator or simulator, a fresh process, and real
hardware. Each rung answers a different question.

## Where the examples go

The source tree and historical commands below refer to a beta.3 generated
consumer. Application files are relative to that generated project root; the
commands were evaluated with its pre-release dependency pins.

## Historical preview checks

These commands describe the September 20 evaluation of a generated consumer.
They require the pre-release dependency pins described above and are not
instructions for released Amber or `amber_cli`.

**Historical preview commands — illustrative only:**

```text
crystal spec
crystal build src/pet_tracker_web.cr -o bin/pet-tracker-web

bash mobile/android/android.sh doctor
bash mobile/android/android.sh build
bash mobile/android/android.sh test emulator-5554

bash mobile/ios/ios.sh doctor
bash mobile/ios/ios.sh build
bash mobile/ios/ios.sh test <simulator-udid>
```

The web runtime check should request `/`, submit `/pets` with the page’s CSRF
token, follow the redirect, and find the new card. It should also request the
stylesheet and all three portraits rather than treating a successful Crystal
compile as browser proof.

The Android `test` action runs host-unit tests, builds and inspects both ABIs and
release packages, installs the app and test APKs, enables CheckJNI, drives the
native form, and records logs, UI XML, a screenshot, process IDs, and package
evidence. Its final launch must use a new process and restore the saved Mabel
record.

The iOS `test` action cross-compiles Crystal for the selected simulator,
generates the Xcode project, builds the application, types into both native
fields, saves Mabel, terminates the app, launches it again, and captures the
restored screen. Passing that run proves simulator behavior and cold-launch
storage; it does not prove signing or a physical iPhone.

## Android OS range evaluated by the preview

The evaluated Pet Tracker template declares:

| Setting | Value | Meaning |
|---|---:|---|
| Minimum SDK | API 31 | Android 12 is the oldest installable runtime |
| Target SDK | API 35 | Android 15 behavior rules apply to the package |
| Compile SDK | API 35 | The generated Gradle host compiles against Android 15 APIs |
| Packaged ABIs | ARM64 and x86_64 | Physical ARM phones and the gated emulator architecture |

AssetPipeline’s beta validation range is API 31 through API 36. The release
matrix exercises the floor, the generated target, and the newest declared
runtime instead of claiming that a single emulator proves the range.

| Runtime | Current evidence boundary |
|---|---|
| API 31 / Android 12 | AssetPipeline and generated-consumer runtime proof exists; it remains the minimum beta floor. |
| API 32–34 | Inside the declared runtime range. They do not replace the floor/target/newest release lanes. |
| API 35 / Android 15 | Preview template compile/target level and Pet Tracker’s emulator evaluation. |
| API 36 / Android 16 | AssetPipeline compatibility lane; the current generated Pet Tracker still compiles and targets API 35. Migrating those values is a separate gate. |
| API 37 and newer | Not part of this support claim. It enters the matrix only after toolchain and runtime work is reviewed. |

“Supported” here means the target is in Amber’s framework-beta gate after the
published consumer and CI rows below pass. It does not mean every Android API
or service is implemented.

## iOS OS range

The generated host declares iOS 16.1 as its minimum deployment version. The
current Pet Tracker runtime proof covers one iPhone 17 Pro simulator running
iOS 26.5. It does not establish every runtime between those versions. Minimum-
version simulator coverage, a physical iPhone, signed archive inspection, and
accessibility remain separate gates.

## Keep the evidence separate

| Gate | What it establishes |
|---|---|
| Template verification | downloaded bytes match the documented version and digest |
| Fresh dependency install | another project can resolve the pinned or released dependencies |
| Shared specs | platform-free rules and snapshot serialization work |
| Web runtime | real routes, CSRF, form input, HTML, CSS, and portraits work |
| Native host-unit tests | host policy and service queues behave before device installation |
| Cross-compile and link | Crystal and foreign symbols build for each selected ABI or architecture |
| Package inspection | resources, permissions, native libraries, debug symbols, and metadata are present |
| Emulator or simulator | the real renderer mounts and handles input and lifecycle events |
| Cold-process relaunch | saved state survives after the original application process is gone |
| Physical device | keyboard, touch, accessibility, memory, backgrounding, and signing work on hardware |
| Remote CI | a machine outside the development workstation reproduces the result |
| Published consumer | released CLI, template, and dependencies work without local overrides |

A package build cannot stand in for a renderer test. An emulator cannot stand
in for a physical device. A local commit pin cannot stand in for a published
dependency constraint.

<a id="preview-evidence-from-september-20-2026"></a>

## Preview evidence from September 20, 2026

The evidence below was refreshed on **September 20, 2026** from the exact
generated consumer for template `0.1.0-beta.3`, manifest
`c69c13076f30f66b5a40da41b71120b6b74c56ec01e36efc9e84bc7d22e1d5e4`,
archive `bb20cdd5475cd583cd19c1bc57fe8ca7b87889eb97243c3821a4e5c7ead93933`.
Its template lock records `web`, `android`, and `ios`. The host was an ARM64 Mac
running macOS 26.5.2, Crystal 1.21.0, and Xcode 26.6. Android runtime proof used the API 35
Google APIs ARM64 image `AE3A.240806.043` and package
`com.example.pet.tracker.preview`. It passed 13 first-run instrumentation
tests, one exact-state restoration test, and a third cold application launch
with distinct process IDs. The generated app preserved the evidence under
`build/android-test-evidence`. This is emulator evidence; the physical-phone
row stays open.

iOS runtime proof used the iPhone 17 Pro simulator on iOS 26.5. Its generated
UI test found the shared title and paw artwork, typed Mabel and Dog, saved the
new card, terminated the app, launched a fresh process, and found Mabel again.
The result bundle includes the restored native screen. This is simulator
evidence; it also records a UIKit hosting-hierarchy runtime warning. Warning
cleanup, physical-iPhone, signed-archive, and accessibility rows stay open.

Those runs also check the visual contract used throughout this guide. Android
keeps the cream canvas, orange action, paper form and cards, portraits, colored
status pills, and full-width vertical form. iOS keeps the same hierarchy,
portraits, cream canvas, and orange action while using system card surfaces and
semantic status text. Web keeps the same identity in its wider two-column
layout.

| Surface | Verified locally | Still open |
|---|---|---|
| Preview artifact delivery | The beta.3 manifest and archive are served from this site's HTTPS origin with documented hashes | a released CLI and released dependencies that can consume the preview format |
| Web | fresh dependency install, shared specs, binary build, real HTML/CSS/images, CSRF form submission, and new pet rendering | repeat from the published origin in remote CI |
| Android package | ARM64 and x86_64 Crystal libraries, debug/release APKs, release AAB, images, JNI symbols, and package inspection | released dependency constraints and remote matrix |
| Android runtime | exact-manifest API 35 device suite, native input, portrait, adoption action, restoration test, and cold-process relaunch | API 31 and 36 Pet Tracker runs, physical phone, TalkBack and large-text pass |
| iOS | exact-manifest XcodeGen host, iOS 26.5 simulator render/input, asset catalog, save, termination, relaunch, and exact-state restoration | UIKit hosting-warning cleanup, minimum-version simulator, physical iPhone, signed archive inspection, VoiceOver/large-text pass, and remote CI |
| macOS | AssetPipeline reference implementation only | generated production host, package, lifecycle/accessibility run, and add-target command |

## Remaining Apple graduation checks

The preview iOS host rendered `PetTrackerScreen`, edited and saved Mabel,
packaged all three portraits, and survived a cold simulator process. The
evaluated attachment also left hashes under `src/app`, `src/views`, and the
existing web target unchanged. Remaining gates include a signed archive, a physical iPhone,
accessibility, warning cleanup, and remote CI. macOS still needs its production
host and the same runtime evidence.

When both rows pass, run one clean four-target generation from the published
template. Record the exact CLI, template digest, Amber and AssetPipeline
versions, Xcode and Android toolchains, simulator/emulator images, and physical
devices. That record is the evidence behind the framework-beta support table.
