# Amber V2 preview validation report

Date: August 1, 2026

Branch: `agent/v2-experience-preview`

Release state: **LOCAL PREVIEW — NOT PUSHED, NOT MERGED, NOT DEPLOYED**

This report records technical proof. It does not grant release approval.

## Automated checks

Passed:

```text
crystal tool format --check config/routes.cr src/controllers/docs_controller.cr \
  src/controllers/home_controller.cr src/services/markdown_preprocessor.cr \
  spec/services/markdown_preprocessor_spec.cr
crystal spec
# 30 examples, 0 failures, 0 errors, 0 pending
scripts/check_v2_beta_docs.sh
scripts/check_v2_site_launch.sh
scripts/check_v2_preview.sh
git diff --check
crystal build src/amberframework.cr -o /tmp/amberframework-v2-preview-final
```

The Markdown integration test renders the real `docs/v2/beta-support.md` file,
requires at least one semantic table, and requires one accessible overflow
wrapper for every rendered table.

## Desktop browser proof

Viewport checked: 1280 by 720 CSS pixels.

- Homepage, personnel directory, all three character pages, blog index, all
  eight blog articles, Amber's Way, privacy, design system, beta support,
  installation, and native preview routes rendered without horizontal
  overflow or broken images.
- Homepage terminal replay changed from zero visible lines and a waiting app
  preview to nine visible lines and the generated app revealed.
- Crystal-field scroll state changed in response to scrolling.
- Beta support rendered two semantic tables inside two `.table-scroll`
  wrappers.
- Installation rendered eight terminal-style `.code-window` blocks. The outer
  `pre` padding was `0`; the inner code element was the single padding owner.
- The documentation version selector measured 217 pixels wide inside its
  270-pixel sidebar.
- Browser error log was empty.

## Runtime privacy proof

The browser inventory found no cross-origin stylesheet, script, or image on any
audited route. Fonts reported loaded from the local stylesheet. JavaScript
contains no cookie, local storage, session storage, or IndexedDB use.

Direct response-header checks for `/`, the installation guide, and `/privacy`
returned `200 OK` and no `Set-Cookie` header.

## Mobile-breakpoint proof

An isolated macOS headless Chrome profile rendered the homepage and beta
support guide at a confirmed 500-pixel CSS viewport, which activates the
phone/tablet rules:

- the compact Menu control stayed inside the header;
- hero copy, both actions, and all three proof chips stayed inside the page;
- the desktop documentation sidebar became the collapsed “Browse
  documentation” control;
- the version timeline stayed inside the content column; and
- both support tables remained inside their horizontal `.table-scroll`
  regions without creating page-level overflow.

The browser's macOS headless backend enforces a 500-pixel minimum CSS viewport.
Its attempted 390-pixel bitmap was a crop of that 500-pixel layout, so it was
discarded as invalid proof rather than misreported as a site defect.

## Still required before release

- **UNKNOWN:** A narrower 390-pixel device viewport and touch interaction still
  need real-device or device-emulation proof. The 500-pixel breakpoint is
  rendered evidence, but it is not a substitute for the smallest target.
- **PROPOSED:** Background-worker character name and art direction remain open.
- **PREVIEW:** Grant, Gemma, Asset Pipeline, and native platform boundaries
  still require their own graduation gates.
- **OWNER APPROVAL:** Character assets, crystal mark, typography, final copy,
  desktop/mobile proof, merge, and deployment remain unchecked.
