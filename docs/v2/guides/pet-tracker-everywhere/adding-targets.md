---
title: "Adding targets"
section: "guides/pet-tracker-everywhere"
order: 90
description: "Attach iOS and Android to the shared Pet Tracker without replacing its shared view"
---

# Adding targets

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

Maybe you started Pet Tracker on the web because that was the shortest path to
a useful screen. Good. We can add a host around that screen without making a
second app.

The beta.3 experiment evaluated adding iOS and Android hosts while keeping
shared model, view, and web files intact. The released CLI does not implement
these attachment paths.

## Where the examples go

The planned target commands assume an existing Pet Tracker project root. The
pre-release implementation wrote hosts under `mobile/ios` and `mobile/android`,
native adapters under `src/platform`, and each selection under
`.amber/templates`.

## Planned target attachment shape

The examples show the proposed interface for attaching a mobile target to an
existing web project. They are illustrative only; released `amber_cli` `2.0.6`
does not recognize the remote manifest options or `amber target add`.

**Planned commands — illustrative only, not copy-and-run steps:**

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

In the pre-release implementation, dry-run mode resolved and verified the
template, checked the existing Amber project and native manifest, and listed
destinations without writing.

The corresponding write command was evaluated against that same pre-release
consumer. No released command is available for readers to apply the change.

The evaluated implementation preserves these existing files byte for byte:

- `.amber.yml`, `shard.yml`, and `shard.lock`;
- `src/app` and `src/views`;
- the web controller and entrypoint;
- an existing valid V2 `config/native.yml`.

The evaluated implementation recorded a target lock under `.amber/templates`
and extended the project template lock. It carried forward targets already
recorded by that lock. Evaluation also confirmed that a custom native-manifest
path, an older manifest schema, a symlinked output parent, or an
application-file collision stopped the command before publication.

## What the evaluation exercised

**Historical evaluation commands — illustrative only:**

```text
shards install
amber doctor android
amber build android
amber test android --device emulator-5554

bash mobile/ios/ios.sh doctor
bash mobile/ios/ios.sh build
bash mobile/ios/ios.sh test <simulator-udid>
```

The evaluated Android test command selected one explicit ADB device. Its Pet
Tracker suite enters Mabel through native text fields, saves her, checks the
native pet image, stops the app, starts a different process, and verifies that
Mabel and the restored-state message return.

The iOS suite performs the same product journey through UIKit on the simulator.
It also stops and launches the app before checking the restored Mabel card.

## Proposed remote-version design

In the proposed design, the CLI owns the manifest contract and safe installer.
The remote bundle owns versioned app resources and selected generator
overrides. A later template revision could change Pet Tracker’s screen, CSS,
portraits, or host tests without shipping a CLI binary.

The planned installer checks that the version and manifest digest agree with
the downloaded bytes, then writes those values into the project. An automatic
channel still needs signed metadata, key rotation, revocation, and
conflict-aware updates before it belongs in a supported path.

## What remains for iOS

The evaluation generated an iOS host that built a simulator-targeted Crystal
library, mounted `PetTrackerScreen`, packaged the shared portraits, handled
native input, and restored state after a cold launch. Before this preview could
become supported, it would still need
the current UIKit hosting-hierarchy warning removed, signed archive inspection,
physical-iPhone input and lifecycle proof, VoiceOver and large-text checks, and
a remote CI run from published artifacts.

## What is missing for macOS

The Pet Tracker bundle does not generate a macOS host yet. Its beta gate needs:

1. a current Xcode project and real AppKit host;
2. the production Crystal bridge mounting `PetTrackerScreen`;
3. window, menu, keyboard, focus, resizing, appearance, and termination
   lifecycle wiring;
4. the shared Apple asset catalog and product palette;
5. local storage and cold-relaunch restoration;
6. host-unit, interaction, and accessibility checks;
7. application-bundle inspection, signing configuration, and a clean-machine
   launch;
8. a collision-safe `amber target add macos` bundle scope.

## Proposed four-target acceptance contract

If a macOS host is implemented, a future release test should select
`web,macos,ios,android`, download one pinned Pet Tracker bundle, install
published dependencies, and build every host from the same `src/app` and
`src/views` files. This acceptance contract is not a command the current CLI
can run.

Each host still gets its own proof. Web requests, an Android emulator, an iOS
simulator, and a macOS process are separate gates. We join them through shared
source and conventions; we do not treat one platform’s pass as evidence for
another.
