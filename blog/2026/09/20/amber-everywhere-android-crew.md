# A preview of Amber Everywhere on Android

> **Preview — engineering evaluation, not a released feature.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web-first Pet Tracker walkthrough linked below. They do not include the remote-template or native target commands shown here. This preview uses pre-release Amber `2.0.0-beta.2+ab90eae910a4` (commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3`) and `asset_pipeline` commit `2aa345bb8f6254554775634d07053cbed09ffe91`, outside the [supported beta path](/docs/v2/beta-support). No command on this page is a runnable public workflow.

Hey, Amber here.

We have been evaluating how one Crystal application and view tree could serve
the web, Android, and iOS. Pet Tracker is our preview project for that work.
The template generated web, Android, and iOS targets from shared application
rules and a shared `PetTrackerScreen`. This is an engineering experiment; the
native generators and their dependency pins are not part of released Amber.

## One application, different hosts

The experiment puts application rules under `src/app` and shared screen
composition under `src/views`. A web controller translates HTTP requests; the
Android and iOS hosts translate native events and lifecycle callbacks. The
hosts can use their platform's controls and storage while the product rules
stay in one place.

Shared code does not make each platform's event model identical. Web still
uses URLs, forms, CSS, and browser history. Android and iOS use native input,
resources, and application lifecycles.

## What the evaluation covered

The beta.3 template targets the pre-release Amber and `asset_pipeline` commits
named above. Its local evaluation covered a web consumer, Android API 35
rendering, input, package inspection, and cold-process restoration. It also
covered an iOS 26.5 simulator run with input and state restoration. These are
local preview results, not support claims for released Amber.

API 31 and API 36 Pet Tracker runs, a physical Android phone, a physical
iPhone, signed Apple archives, accessibility checks, and remote CI remain
open. The template includes iOS in this preview; macOS is still **Proposed**.
The [testing and support page](/docs/v2/guides/pet-tracker-everywhere/testing-and-support)
lists the evidence and remaining gates.

## Planned remote-template interface

The published beta.3 manifest pins its archive with SHA-256
`c69c13076f30f66b5a40da41b71120b6b74c56ec01e36efc9e84bc7d22e1d5e4`; the
archive digest is
`bb20cdd5475cd583cd19c1bc57fe8ca7b87889eb97243c3821a4e5c7ead93933`. The
command below is the planned interface for evaluating the template. Released
`amber_cli` `2.0.6` does not recognize these options.

**Planned command — illustrative only, not copy-and-run instructions:**

```text
amber new pet_tracker \
  --type hybrid \
  --targets web,android,ios \
  --template-manifest https://amberframework.org/templates/pet-tracker/0.1.0-beta.3/manifest.json \
  --template-manifest-sha256 c69c13076f30f66b5a40da41b71120b6b74c56ec01e36efc9e84bc7d22e1d5e4 \
  --template-version 0.1.0-beta.3 \
  --no-deps
```

The preview implementation also evaluated adding Android or iOS to an
existing web project. The planned `amber target add` interface would preserve
the web sources and dependencies while adding target-specific hosts. Neither
command is available in the released CLI.

## The supported path today

You can build a supported Amber web application today with Amber framework
`2.0.0-beta.5` and `amber_cli` `2.0.6`. Start with
[`amber new my_app --type web`](/docs/v2/getting-started/), then follow the
[supported Pet Tracker walkthrough](/docs/v2/guides/pet-tracker) for Grant,
Micrate, ECR, request specs, and an HTML and JSON response from one action.

The multi-target guide remains a separate
[Pet Tracker everywhere preview](/docs/v2/guides/pet-tracker-everywhere/).
Its published archive is useful for inspection, but its pre-release dependency
pins put it outside the supported path. We can move the commands into a future
release only after the public CLI and dependency gates pass.
