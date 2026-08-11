# Amber V2 public-beta validation report

Date: August 10, 2026

Branch: `agent/v2-public-beta`

Release state: **READY TO DEPLOY — OWNER APPROVED, ALL PREDEPLOYMENT GATES PASSED**

This report records the evidence behind the Amber V2 public beta. The final
deployment identifiers and public-origin checks are recorded in
`RELEASE_PROOF.md` after production finishes deploying.

## Release contract

- Framework: Amber `2.0.0-beta.2`
- Generator: Amber CLI `2.0.3`
- Crystal: `>= 1.20.0, < 2.0`
- Supported beta application type: `web`
- Preview application type: `native` on macOS, iOS, and Android
- Frontier native target: Linux UI bindings

The homepage, installation guide, CLI guide, beta-support page, generated web
starter, and release automation use this same contract. The trusted macOS and
Linux Homebrew command is:

```sh
brew install amberframework/amber_cli/amber_cli
```

The signed remote-template channel described in
`TEMPLATE_DELIVERY_STRATEGY.md` remains **PROPOSED — NOT IMPLEMENTED**. Amber
CLI 2.0.3 ships the verified starter in the CLI itself, so generation works
without downloading executable template content from another service.

## CLI and generated-app proof

Amber CLI pull request 33 passed all required checks before merge:

- Crystal latest on macOS and Ubuntu;
- the full integration suite;
- platform-specific macOS and Ubuntu tests;
- documentation generation; and
- release-binary builds for macOS ARM64 and Linux x86_64.

Local verification passed 406 examples, formatting, the beta contract check,
both CLI binary builds, and a clean generated-web-app smoke test. That smoke
test installed the generated app's dependencies, ran its specs, exercised its
generators, built and started it, and fetched its homepage, stylesheet, and
import map.

The public release workflow repeats the clean generated-app smoke test inside
both release jobs before it creates checksummed archives. Its macOS job also
rejects retired OpenSSL linkage. Release workflow 31451405352 passed and
published both archives and their SHA-256 checksum files.

The trusted Homebrew formula was updated to 2.0.3. Validation workflow
31451864810 installed it, generated the branded application, ran specs, built,
started, and probed the app successfully on both macOS and Linux. A formula
upgrade and the full generated-app smoke test also passed on a local Apple
Silicon Mac using `/opt/homebrew/opt/amber_cli/bin/amber`.

The released CLI generator is authoritative. The website's small browser proof
is a presentation of the same generated welcome content and is checked for the
exact identifying copy:

```text
my_app                                      Amber V2 beta

Amber V2 · Web application
Your new idea starts here.

my_app is running. Your first route, view, and locally served CSS and JavaScript
are ready to shape.

Server rendered · Crystal powered · Ready to customize
First edits · Make it yours.
```

## Documentation review

The V2 documentation now provides a complete first-run path for macOS and
Linux: install the CLI, verify the installed version, generate the default web
application, install dependencies, run specs, start the server, and make the
first route and view changes.

The documentation explicitly explains Amber's coding beliefs instead of only
describing surface features. It includes:

- `respond_with` examples for HTML and JSON responses;
- controller, view, partial, layout, stylesheet, and JavaScript organization;
- complete ECR rendering examples;
- local ESM and import-map usage without Node or a front-end framework;
- an optional Asset Pipeline preview, clearly separated from the supported
  local-asset path; and
- a reproducible, caveated one-vCPU benchmark report rather than an unsupported
  round-number claim.

V2 explicitly inherits still-correct V1.4.1 pages. Carried pages are labeled,
retired pages have mapped replacements, relative Markdown links stay inside the
V2 namespace, and the documentation selector remains contained at mobile
width. Copy/View Markdown and AI handoff controls are visible on every guide.

## Brand and generated-starter proof

The active visual system uses the playful original-studio Amber direction: the
chibi Amber primary mark, a faceted crystal as the supporting motif, the warm
amber palette, locally hosted fonts, friendly terminal chrome, and restrained
crystal-field effects.

Amber CLI 2.0.3 transfers that language into a generated web app using
locally-served CSS and JavaScript. The generated starter includes the brand
palette, crystal motif, app-status treatment, responsive layout, semantic HTML,
an import map, and a small local JavaScript entrypoint. It does not require a
Node or Webpack runtime.

The homepage demo does not begin while the terminal merely peeks into view. It
stays in a `waiting` state until its top edge crosses the viewport midpoint,
then runs all 10 outputs and opens the generated-app browser. At desktop width
the terminal keeps one width while moving left and the browser grows from its
former right edge on the same timing curve.

The application chooser begins on the supported web state. Its native state
uses a code-native platform map built from the Amber crystal geometry and
device silhouettes; the unrelated cinematic hover image is no longer wired to
the page. Pointer focus, keyboard focus, and centered mobile scrolling all
select the matching background and call to action.

## Character and product-boundary proof

Amber, Grant, and Gemma include selectable responsibility translations for
Rails, Django, Phoenix, and Laravel. Every character page says that the mapping
compares responsibilities, not API compatibility.

- Amber owns the connected HTTP, routing, controller, presentation,
  interaction, configuration, and application surface.
- Grant represents the persistence preview and does not claim to own queues or
  a background-worker runtime.
- Gemma represents the attachment and upload preview.

Native applications, Grant, Gemma, persistence/authentication integrations,
and the Asset Pipeline remain explicitly labeled preview or frontier work. They
are not presented as graduating with the web beta.

## Rendering, accessibility, and privacy proof

Browser checks covered the homepage, documentation, launch post, character
page, Amber's Way, and privacy page at 1280-pixel desktop width and a true
390-by-844 mobile viewport. The checked pages had no broken images or unexpected
horizontal overflow. The mobile navigation changed its accessible Open/Close
name, the V2 documentation selector stayed inside its container, and code
blocks used one padding owner with terminal-window chrome.

All observed site assets were served from the site origin, including fonts,
stylesheets, JavaScript, and images. The application loads no analytics, tag
manager, tracking pixel, marketing form, advertising library, or third-party
embed. It creates no application cookies or browser storage. The privacy page
accurately discloses that the hosting/CDN security layer may set a necessary
edge-security cookie such as Cloudflare's `__cf_bm`; Amber does not read that
cookie or use it for analytics, ads, or user profiles.

## Automated site checks

The release candidate passed:

```text
crystal spec
# 40 examples, 0 failures, 0 errors, 0 pending

scripts/check_v2_beta_docs.sh
scripts/check_v2_site_launch.sh
scripts/check_v2_preview.sh
git diff --check
shards build amberframework
```

The checks enforce the version and installation contract, documentation
coverage, generated welcome content, responsive brand assets, terminal trigger
and motion behavior, application focus states, character responsibility
boundaries, first-party privacy claims, and the explicitly proposed
remote-template plan.

## Remaining after the public-beta launch

- **PROPOSED:** Design and security review for the signed remote-template
  channel before implementation.
- **PREVIEW:** Separate graduation evidence for native applications, Grant,
  Gemma, Asset Pipeline, and persistence/authentication integrations.
- **UNKNOWN:** Amber V2 GA date and final compatibility graduations.
- **REPEAT AT GA:** Clean macOS/Linux install proof, the full docs review, and
  public-origin browser QA against the final GA artifacts.
