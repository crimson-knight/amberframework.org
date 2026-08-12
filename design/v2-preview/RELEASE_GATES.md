# Amber V2 website release gates

Status: **BETA.4 PUBLISHED — PUBLIC ORIGIN VERIFIED**

The checked items below record the approved public-beta experience. The
component versions, generated application, production image, and public origin
must be re-proven for every release. The active beta.4 evidence and remaining
gates are tracked in `RELEASE_PROOF_BETA4.md`; `RELEASE_PROOF.md` is the
historical beta.2/CLI 2.0.3 launch record.

Every gate must pass and the owner must explicitly approve the rendered proof.
A green automated check does not authorize a production merge or deployment.

## Approval

- [x] Owner has reviewed desktop and mobile screenshots.
- [x] Owner has reviewed every generated character asset.
- [x] Owner has approved the chibi Amber primary mark, supporting crystal motif, and typography.
- [x] Owner has approved the background-worker character direction or its
      omission.
- [x] Owner explicitly says the branch may merge and deploy.

## Product accuracy

- [x] `web` is presented as the default Amber CLI application type.
- [x] `native` is presented as a preview, including its platform boundary.
- [x] Installation commands have been executed from a clean environment.
- [x] The generated web app builds, tests, starts, and serves its CSS.
- [x] The homepage's generated-app browser matches the current CLI template.
- [x] The released CLI generator is canonical, and automated checks compare the
      homepage proof with the generated starter's identifying content.
- [x] Documentation distinguishes the current embedded-template behavior from
      any proposed remote template channel.
- [x] Grant and Gemma claims match their actual preview boundaries.

## Privacy and ownership

- [x] No analytics, tag manager, tracking pixel, or marketing form is loaded.
- [x] The application creates no cookies or browser storage; any hosting-edge
      security cookie is disclosed accurately.
- [x] No runtime font, script, stylesheet, image, or embed is fetched from a
      third-party host.
- [x] Font files and licenses are stored with the site.
- [x] The privacy page says plainly what the site does and does not collect.

## Rendering and interaction

- [x] Markdown tables keep table semantics and have an overflow wrapper.
- [x] Code blocks have one padding owner and use terminal chrome only for
      commands; files and output use labeled editor components.
- [x] Documentation version controls remain inside their containers.
- [x] Keyboard, focus, menu, reduced-motion, and contrast checks pass.
- [x] Desktop and mobile pages have no unexpected horizontal overflow.
- [x] The terminal demo can replay and reveals a local-app browser preview.
- [x] At desktop width the terminal keeps one width, begins centered, and moves
      left while the browser grows from its former right edge; both transitions
      end together without snapping.
- [x] Homepage hero, navigation, and character callout remain stable during
      pointer movement at an ultrawide viewport.
- [x] Application-type backgrounds and calls to action work with pointer,
      keyboard focus, and centered mobile scroll state.
- [x] Unchanged inherited V1 pages keep internal links in V2 and intentionally
      have no badge; only new or updated material is labeled.
- [x] Every retired V2 page has a working replacement or explicit unavailable
      state; mapped legacy URLs redirect to the replacement.
- [x] V2 deployment guidance is reproduced from a clean production build and
      runtime configuration check.
- [x] Copy/View Markdown plus Claude, ChatGPT, and Gemini handoff links are
      checked in release QA.
- [x] Crystal-field and card effects remain decorative and pointer-safe.

## Proof artifact

The proof handoff must include:

- branch and commit SHA;
- exact validation commands and results;
- desktop and mobile screenshots of homepage, docs, blog, character page,
  Amber's Way, and privacy page;
- external-request inventory showing first-party assets only;
- explicit list of remaining `PROPOSED`, `PREVIEW`, and `UNKNOWN` decisions.
