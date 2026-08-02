# Amber V2 preview validation report

Date: August 2, 2026

Branch: `agent/v2-experience-preview`

Release state: **LOCAL PREVIEW — NOT PUSHED, NOT MERGED, NOT RELEASED, NOT DEPLOYED**

This report records current preview evidence. It does not grant release
approval, replace clean-machine installation proof, or authorize publication.

## Brand and homepage proof

The active hero uses the original-studio Amber treatment requested by the
owner: a warm smile, blush accents, soft cel shading, and an open palm-up
invitation instead of a grabbing or overly serious pose. The generated edit is
versioned as `public/assets/characters/amber-hero-inviting-studio.webp`; the
source image and edit method are recorded in `ASSET_PROVENANCE.md`.

The homepage also includes a dedicated Grant spotlight. Its copy identifies
Grant as an ecosystem preview and states that the V2 core web template does not
install an ORM. Amber's Way now presents the six framework principles:
Productivity, Performance, Happiness, Humility, Respect, and Trust.

Desktop and true 390-by-844 browser checks found no page-level horizontal
overflow in the homepage, Grant spotlight, or Amber's Way. The compact mobile
navigation and full-width mobile actions remained inside the viewport.

## Terminal-to-application proof

The homepage demonstration begins with a full-width terminal, types user input
in irregular human-like bursts, prints system output at a steady cadence, and
then contracts while the generated application browser expands. It contains 12
observable lines covering:

- Homebrew tap and install commands;
- Amber CLI download and installation feedback;
- `amber new my_app` with Crystal dependency resolution and compilation;
- the generated file summary; and
- `amber watch`, the listening URL, and the ready state.

The listening URL receives a reverse highlight before the browser preview
opens. The browser content matches the authoritative V2 CLI web template in
`amber_cli-v2-beta/src/amber_cli/commands/new.cr`, including its heading,
description, and three next-step items. Replay restores the initial state.

At 1280 CSS pixels, the completed split measured 621 pixels for the terminal
and 529 pixels for the app preview. The automated interaction check observed
all 12 lines, no overflow, and an unchanged page scroll position (`0` before
and after the complete animation).

## Documentation inheritance and navigation proof

V2 now explicitly inherits from V1.4.1. Inherited pages are labeled `Carried`,
while V2-authored pages are labeled `New` or `Updated`. The sidebar uses native
collapsible sections, opens only the active documentation branch, and does not
create its own scrolling region. A rendered inherited desktop page measured an
equal sidebar `scrollHeight` and `clientHeight` of 1608 pixels.

The Markdown preprocessor resolves relative links against the physical source
page, preserves the V2 URL namespace for inherited pages, handles directory
index links and anchors, and renders GitBook-style hints and code tabs without
swallowing content following a code block. Automated tests cover all authored
V2 Markdown links.

`docs/v2/_deleted.yml` removes obsolete material from V2 navigation.
`docs/v2/_replacements.yml` maps superseded pages to their current
destinations. The version timeline names replacements, and direct deprecated
V2 URLs redirect to them. Browser proof includes:

- `/docs/v2/guides/installation` to the V2 installation guide;
- `/docs/v2/examples/crystal-debug` to V2 troubleshooting; and
- Granite querying to the Grant query guide.

A source-file sweep of every page actually inherited into V2 found zero
remaining matches for the known stale contracts: Granite, Jennifer, Webpack,
Node.js, npm, yarn, retired Amber CLI commands, Redis session configuration,
Slang, Kilt, Heroku, Dokku, and the old DigitalOcean guide. Rendered V2 docs
also contain no third-party image URLs. These focused checks reduce known
drift; they are not a substitute for a human semantic review of every carried
page.

## V2-authored guide proof

The preview replaces or supplements stale V1 material with source-backed V2
guides for:

- controllers, sessions, request/response objects, `halt!`, and `respond_with`;
- routes, pipelines, and the generated route contract;
- ECR views and the assets emitted by the current web template;
- `Amber::Mailer::Base` and current memory/SMTP configuration;
- hand-authored sockets with generated channels; and
- portable binary deployment behind a reverse proxy, including production
  environment variables and a systemd example.

Browser checks of the six primary replacement guides found their expected
headings and `Updated` status, no horizontal overflow, and no remote images.
The routing guide does not present the retired `amber routes` command as an
available V2 workflow.

## Page tools and code presentation proof

Each documentation page provides a `Page tools` menu with:

- Copy as Markdown;
- View as Markdown;
- Open in Claude; and
- Open in ChatGPT.

The raw Markdown endpoint returned `200 OK`, `text/plain; charset=utf-8`, and
an inline content disposition. The browser exercised the menu, verified both
AI links carry a prefilled `q` prompt with the absolute raw-page URL, and
observed the copy control change to `Copied`. On a local preview, that raw URL
is not reachable by a hosted AI service; public-origin proof remains a release
gate.

The dependency-free local syntax highlighter applies Amber/Crystal token
colors without adding third-party runtime assets. A rendered schema guide
contained 16 highlighted blocks, including 64 keyword, 118 constant, 20
string, and 10 function tokens, with no horizontal page overflow.

## Automated checks

Passed:

```text
crystal tool format --check [changed Crystal source and specs]
crystal spec
# 40 examples, 0 failures, 0 errors, 0 pending
scripts/check_v2_beta_docs.sh
scripts/check_v2_site_launch.sh
scripts/check_v2_preview.sh
git diff --check
crystal build src/amberframework.cr -o /tmp/amberframework-v2-feedback-preview-final4
```

The test suite locks documentation inheritance, replacement redirects,
source-aware relative links, GitBook code-tab conversion, authored-link
resolution, known-stale-token exclusion, and the absence of remote images in
rendered V2 documentation.

## Browser and privacy proof

The final local binary was audited at `http://127.0.0.1:3212` at 1280 pixels
wide and at a true 390-by-844 mobile viewport. The homepage, replacement
guides, inherited documentation, deployment material, Grant spotlight, and
Amber's Way produced no page-level horizontal overflow. Mobile documentation
used the collapsed `Browse documentation` control instead of the desktop
sidebar. Browser error and warning logs were empty.

Runtime assets remain local. The preview adds no analytics, cookies, external
fonts, third-party scripts, or third-party documentation images.

## Still required before any release

- **EXECUTION GATE:** Run the documented Amber CLI install, project generation,
  compile, spec, and serve flow on clean supported macOS and Linux machines.
  Static documentation and site checks do not prove that release path.
- **HUMAN DOC REVIEW:** Review every carried V1 page for meaning, not only the
  known stale-token set, and correct any remaining V2 behavioral drift.
- **PUBLIC-ORIGIN PROOF:** Verify raw Markdown and both AI deep links from the
  final hosted origin; localhost is not reachable by the hosted assistants.
- **SEPARATE PREVIEW GATES:** Grant, Gemma, native applications, and other
  ecosystem components still need their own support and graduation evidence.
- **OWNER APPROVAL:** Final art, copy, documentation, installation proof,
  release versioning, merge, publication, and deployment all remain subject to
  explicit owner approval.

No release action has been taken from this branch.
