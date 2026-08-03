# Amber V2 website release gates

Status: **PROPOSED — NOT ACTIVE**

Every gate must pass and the owner must explicitly approve the rendered proof.
A green automated check does not authorize a production merge or deployment.

## Approval

- [ ] Owner has reviewed desktop and mobile screenshots.
- [ ] Owner has reviewed every generated character asset.
- [ ] Owner has approved the crystal mark and typography.
- [ ] Owner has approved the background-worker character direction or its
      omission.
- [ ] Owner explicitly says the branch may merge and deploy.

## Product accuracy

- [ ] `web` is presented as the default Amber CLI application type.
- [ ] `native` is presented as a preview, including its platform boundary.
- [ ] Installation commands have been executed from a clean environment.
- [ ] The generated web app builds, tests, starts, and serves its CSS.
- [ ] The homepage's generated-app browser matches the current CLI template.
- [ ] One canonical template source feeds both generation and the website
      proof; duplicate template representations cannot drift silently.
- [ ] Documentation distinguishes the current embedded-template behavior from
      any proposed remote template channel.
- [ ] Grant and Gemma claims match their actual preview boundaries.

## Privacy and ownership

- [ ] No analytics, tag manager, tracking pixel, or marketing form is loaded.
- [ ] No cookies or browser storage are created by the site.
- [ ] No runtime font, script, stylesheet, image, or embed is fetched from a
      third-party host.
- [ ] Font files and licenses are stored with the site.
- [ ] The privacy page says plainly what the site does and does not collect.

## Rendering and interaction

- [ ] Markdown tables keep table semantics and have an overflow wrapper.
- [ ] Code blocks have one padding owner and terminal-window chrome.
- [ ] Documentation version controls remain inside their containers.
- [ ] Keyboard, focus, menu, reduced-motion, and contrast checks pass.
- [ ] Desktop and mobile pages have no unexpected horizontal overflow.
- [ ] The terminal demo can replay and reveals a local-app browser preview.
- [ ] At desktop width the terminal keeps one width, begins centered, and moves
      left while the browser grows from its former right edge; both transitions
      end together without snapping.
- [ ] Homepage hero, navigation, and character callout remain stable during
      pointer movement at an ultrawide viewport.
- [ ] Application-type backgrounds and calls to action work with pointer,
      keyboard focus, and centered mobile scroll state.
- [ ] Carried-forward V1 pages are labeled and keep internal links in V2.
- [ ] Every retired V2 page has a working replacement or explicit unavailable
      state; mapped legacy URLs redirect to the replacement.
- [ ] V2 deployment guidance is reproduced from a clean production build and
      runtime configuration check.
- [ ] Copy/View Markdown and both AI handoff links are checked in release QA.
- [ ] Crystal-field and card effects remain decorative and pointer-safe.

## Proof artifact

The proof handoff must include:

- branch and commit SHA;
- exact validation commands and results;
- desktop and mobile screenshots of homepage, docs, blog, character page,
  Amber's Way, and privacy page;
- external-request inventory showing first-party assets only;
- explicit list of remaining `PROPOSED`, `PREVIEW`, and `UNKNOWN` decisions.
