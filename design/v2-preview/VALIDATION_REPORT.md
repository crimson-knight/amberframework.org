# Amber V2 preview validation report

Date: August 3, 2026

Branch: `agent/v2-experience-preview`

Release state: **LOCAL PREVIEW — NOT PUSHED, NOT MERGED, NOT RELEASED, NOT DEPLOYED**

This report records current preview evidence. It does not grant release
approval, replace clean-machine installation proof, or authorize publication.

## Version facts

The website, Amber repository, and CLI sources currently support a beta—not an
unpublished release candidate:

- the website and generated application pin Amber `2.0.0-beta.2`;
- Amber CLI is `2.0.2` and accepts Crystal `>= 1.20.0, < 2.0`;
- the verified Amber tags include `v2.0.0-beta.1` and `v2.0.0-beta.2`; and
- no `v2.0.0-rc.3` tag was found in the local release sources.

The homepage therefore says **V2 beta** and **ready for beta testing**. It does
not advertise RC3 or put an internal owner-approval warning in public copy.

## Brand and responsive hero proof

The active hero uses the Higgsfield-refined transparent Amber desk set recorded
in `ASSET_PROVENANCE.md`. It preserves the playful expression, blush, inviting
hand, desk, laptop, mug, notebook, and papers while removing the rectangular
room background and loose floating crystals. Responsive `<picture>` sources
provide wide, desktop, and mobile crops; the code-native crystal field shows
through behind the alpha image.

The live browser loaded:

- `amber-hero-desk-transparent-higgsfield.webp` at desktop and ultrawide sizes;
- `amber-hero-desk-mobile-higgsfield.webp` at a true mobile viewport; and
- cache-revisioned CSS and JavaScript URLs so a previous preview stylesheet
  cannot silently override new markup.

The primary identity now uses the 1254-by-1254 transparent
`amber-chibi-hero-mark-v2.webp`: full-body, playful original-studio Amber,
feet shoulder-width, one hand at her hip, and one clear peace sign. It appears
in the navigation, footer, homepage support summary, Amber's Way, docs guide
note, and design-system distribution page. The older faceted crystal remains a
supporting motif rather than the standalone primary mark. `webpinfo` confirmed
the alpha channel, and every rendered copy loaded at its expected natural size.

At 1280 CSS pixels, the corrected hero measured 760 pixels tall with zero page
overflow. At a 2560-by-1100 override (2545 CSS pixels after the scrollbar), the
hero art measured 1121 by 752 pixels and stayed anchored to the lower-right
edge. Repeated pointer moves left the navigation and Amber callout dimensions
unchanged and produced zero horizontal overflow. The fixed full-page dot layer,
hero image mask, and navigation backdrop filter that contributed to the prior
large composited surfaces are no longer active.

At a true 390-by-844 override (375 CSS pixels after the scrollbar), the browser
selected the 1250-by-1208 mobile source. The hero art and callout stayed inside
the 375-pixel page with zero overflow. The mobile menu occupied 347 pixels from
left 14 to right 361, changed its accessible name between Open and Close, and
also produced zero overflow.

## Terminal-to-application proof

The homepage first-run demonstration now has fixed window geometry rather than
snapping between layouts. At the ultrawide viewport:

- the 1200-pixel stage began with a 622.91-pixel terminal centered at x 1272.5;
- the collapsed browser began at x 1581.42, immediately beside the terminal's
  former right edge at x 1583.95;
- the completed terminal moved to x 689.5 without changing width;
- the browser completed at x 1328.42 with a 16.02-pixel gap; and
- both terminal movement and browser growth used the same 760 ms easing window.

The localhost cue displays a pointer, moves it onto the URL, and runs the
`pointer-ping` ring for 620 ms. Browser interaction confirmed the URL's active
state and the pseudo-element animation.

All 12 terminal outputs completed, the generated browser opened without
changing page scroll position, and the stage produced zero horizontal overflow.
The browser content now matches the authoritative inline writer in Amber CLI
`NewCommand`, including:

```text
Welcome to my_app!
Your Amber V2 application is running successfully.

Getting Started
- Edit this page: src/views/home/index.ecr
- Add routes: config/routes.cr
- Add a controller: amber generate controller Posts
```

At mobile width, the terminal and application preview stack at the same
345-pixel content width. The finished stage measured 363 pixels wide and
produced zero page overflow.

## Application frontier proof

The application-type section begins on the web state. Keyboard focus on the
native CTA changed `data-active-application` to `native`, brought the native
scene to opacity 1, and revealed the native CTA at opacity 1. Returning focus to
web restores the supported web treatment.

At mobile width, the center observer exposed the web CTA while the web card
occupied the focus band, then changed to native and exposed the native CTA when
the native card moved into the band. The native background transitioned with
that state and neither stacked card caused horizontal overflow.

The copy identifies macOS, iOS, and Android as the current generated native
targets and keeps Linux native UI bindings explicitly in frontier status. It
does not present native as release-gated with the web beta.

## Character responsibility proof

Amber, Grant, and Gemma now include a real selectable responsibility translator
for Ruby on Rails, Django, Phoenix, and Laravel. Selecting a framework changes
the closest Amber responsibility, explanation, and comparison chips in place.
Every page states that the comparison is about responsibility, not API
compatibility.

Grant maps record keeping to the Active Record pattern and ORM responsibility.
His page explicitly says he can cache record and query work but does not own
background jobs, queues, or the worker runtime. Gemma maps attachments, upload
intake, validation, storage, and delivery. Amber maps the connected routing,
controller, presentation, interaction, configuration, and application surface.

The 1800-by-1005 warehouse scenes loaded successfully. Grant's homepage crop
uses a 72% horizontal focal point and keeps his full figure in the 430-pixel
desktop panel and 345-pixel mobile panel. Gemma's responsibility scene uses a
15% source focal point, landing her on the left third line rather than clipping
her at the outer edge. Desktop and 390-by-844 mobile proofs produced zero
horizontal overflow. Each character page also exposes two bottom crew cards;
the cards measured 347 pixels wide in the mobile proof.

## Template delivery finding

Amber CLI `2.0.2` writes the web scaffold from inline methods in
`NewCommand#create_project_structure`; it does not render the separate template
tree or fetch a remote template manifest. Those two local representations have
already drifted. The website now mirrors the executable behavior, and the web
template guide tells users to upgrade the CLI before generating a new app.

The signed remote-template channel in `TEMPLATE_DELIVERY_STRATEGY.md` is
**PROPOSED — NOT IMPLEMENTED**. It requires immutable versions, compatibility
ranges, signatures, digests, safe extraction, a verified cache, a bundled
offline fallback, explicit CLI controls, and clean macOS/Linux proof before it
can be documented as supported behavior.

## Documentation inheritance and navigation proof

V2 explicitly inherits from V1.4.1. Inherited pages are labeled `Carried`,
while V2-authored pages are labeled `New` or `Updated`. The sidebar uses native
collapsible sections, opens only the active documentation branch, and does not
create its own scrolling region.

The documentation banner is 157 pixels tall at desktop and 146 pixels at the
mobile content width, with one page title and one page-state badge. The repeated
version label is removed. Copy as Markdown, View as Markdown, Open in Claude,
and Open in ChatGPT are visible controls rather than a hidden menu. The Claude
and OpenAI identity assets loaded locally at their expected natural dimensions.
At mobile width the four controls form a two-by-two 169-pixel grid with no
overflow. The adjacent note explains why a local preview generates a local raw
Markdown URL and why the hosted origin will generate a public URL.

`docs/v2/_deleted.yml` removes obsolete material from V2 navigation.
`docs/v2/_replacements.yml` maps superseded pages to their current
destinations. The version timeline names replacements, and direct deprecated
V2 URLs redirect to them.

The Markdown preprocessor resolves relative links against the physical source
page, preserves the V2 URL namespace for inherited pages, handles directory
index links and anchors, and renders GitBook-style hints and code tabs without
swallowing content following a code block. Automated tests cover all authored
V2 Markdown links.

## Automated checks

Passed after the crew, docs, dependency, and primary-mark changes:

```text
env CRYSTAL_CACHE_DIR=/tmp/amber_site_v2_feedback2_cache crystal spec
# 40 examples, 0 failures, 0 errors, 0 pending

scripts/check_v2_site_launch.sh
scripts/check_v2_preview.sh
git diff --check
env CRYSTAL_CACHE_DIR=/tmp/amber_site_v2_build_cache shards build amberframework
```

The validation scripts now require the responsive hero files, Higgsfield scene
files, exact generated welcome content, synchronized terminal/browser motion,
application focus states, responsibility translators, cache-revisioned assets,
and the explicitly proposed template-delivery plan.

## Browser and privacy proof

The final local binary was audited at `http://127.0.0.1:3212` at the default
1280-by-720 viewport and a true 390-by-844 mobile override. The homepage,
Grant and Gemma character pages, Amber's Way, documentation, and media page
produced no page-level horizontal overflow. Select interaction changed the
translation title and comparison chips, all required images reported nonzero
natural dimensions, and desktop and mobile screenshots confirmed the focal
positions described above.

Runtime assets remain local. The preview adds no analytics, cookies, external
fonts, third-party scripts, or third-party documentation images.

## Still required before any release

- **EXECUTION GATE:** Run the documented Amber CLI install, project generation,
  compile, spec, and serve flow on clean supported macOS and Linux machines.
  Static documentation and site checks do not prove that release path.
- **HUMAN DOC REVIEW:** Review every carried V1 page for meaning, not only the
  known stale-token set, and correct any remaining V2 behavioral drift.
- **PUBLIC-ORIGIN PROOF:** Verify raw Markdown and both AI deep links from the
  final hosted origin; localhost is not reachable by hosted assistants.
- **SEPARATE PREVIEW GATES:** Grant, Gemma, native applications, and other
  ecosystem components still need their own support and graduation evidence.
- **OWNER APPROVAL:** Final art, copy, documentation, clean-platform
  installation proof, release versioning, merge, publication, and deployment
  still require explicit approval.

No release action has been taken from this branch.
