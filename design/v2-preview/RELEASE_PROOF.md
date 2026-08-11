# Amber V2 public-beta release proof

Date: August 10, 2026 (America/New_York)

Status: **PUBLIC BETA LIVE — PRODUCTION VERIFIED**

## Owner approval

The owner explicitly approved the desktop and mobile direction, generated
character assets, playful Amber identity, typography, background-worker
omission, copy iteration, release merge, and production deployment.

## Version contract

| Component | Public-beta version or boundary |
| --- | --- |
| Amber Framework | `2.0.0-beta.2` |
| Amber CLI | `2.0.3` |
| Crystal | `>= 1.20.0, < 2.0` |
| Supported application type | `web` |
| Preview/frontier application types | native macOS/iOS/Android; Linux UI frontier |

## Source and release records

- Website release branch: `agent/v2-public-beta`
- Website pull request: <https://github.com/crimson-knight/amberframework.org/pull/7>
- Website production merge: `a589ba5f6f2b86431b4523fdeb809868a87e2397`
- Amber CLI merge commit: `2c512cbceee822d41d2cbce86de294533ee214ae`
- Amber CLI pull request: <https://github.com/amberframework/amber_cli/pull/33>
- Amber CLI release: <https://github.com/amberframework/amber_cli/releases/tag/v2.0.3>
- Amber CLI release workflow: <https://github.com/amberframework/amber_cli/actions/runs/31451405352>
- Amber CLI cross-platform dry run: <https://github.com/amberframework/amber_cli/actions/runs/31450525578>
- Homebrew validation fix: <https://github.com/amberframework/homebrew-amber_cli/pull/5>
- Homebrew macOS/Linux install proof: <https://github.com/amberframework/homebrew-amber_cli/actions/runs/31451864810>
- Production host: DigitalOcean App Platform, application
  `03366d70-743c-469c-842f-d25b44b146b0`, auto-deploying `master`
- Verified launch deployment: `df5ab350-7b01-4ad4-b73f-3661b48b9f0c`

## Executed validation

### Amber CLI

- 406 examples passed locally.
- Crystal formatter, beta contract, and both CLI binary builds passed.
- A clean generated web app installed dependencies, passed its specs and
  generator checks, built, started, and served its homepage, CSS, and import map.
- Pull request checks passed on macOS and Ubuntu.
- Release-binary jobs repeat the generated-app smoke test on macOS ARM64 and
  Linux x86_64 before publishing checksummed archives.
- The trusted Homebrew formula is version 2.0.3. Its corrected validation
  installed, generated, tested, built, started, and probed the app on both
  supported platforms.
- This Apple Silicon Mac upgraded through the fully qualified formula and the
  installed 2.0.3 binary passed the full generated-app smoke test.

### Website and documentation

- 40 examples passed with no failures, errors, or pending examples.
- `check_v2_beta_docs.sh`, `check_v2_site_launch.sh`, and
  `check_v2_preview.sh` passed.
- A production-mode site binary built successfully.
- The release diff passed whitespace validation.
- Version, Homebrew-install, asset, view, import-map, preview-boundary,
  benchmark-evidence, privacy, and placeholder-language audits passed.

### Browser proof

The release candidate was checked at 1280-pixel desktop width and 390 by 844
mobile width. Reviewed routes included:

- `/`
- `/docs/v2/getting-started/installation`
- `/blog/2026/08/10/amber-v2-public-beta`
- `/characters/amber`
- `/amber-way`
- `/privacy`

The checked pages had no broken images or unexpected horizontal overflow. The
mobile menu and documentation selector remained contained, code blocks aligned
consistently, Copy as Markdown reported success, the terminal waited until it
crossed the viewport midpoint and completed all 10 outputs, and the generated
browser opened. Every observed runtime asset used the site origin.

### Public-origin proof

DigitalOcean marked deployment `df5ab350-7b01-4ad4-b73f-3661b48b9f0c`
`ACTIVE` after building the release image and starting Amber
`2.0.0-beta.2` in production.

Production browser checks at 390 by 844 covered the homepage, Amber's Way, V2
index, installation, beta support, `respond_with`, views, import maps, Asset
Pipeline boundary, performance, web template, Webpack migration, release post,
Amber character page, and privacy page. Six primary routes were repeated at
1280-pixel desktop width. The final checks found no broken image and no
page-level horizontal overflow.

The live terminal began with zero completed lines in `waiting` state while its
top edge was below the 400-pixel viewport midpoint. After crossing the trigger,
all 10 outputs completed and the generated-app browser opened. The live asset
inventory contained only `amberframework.org` hosts.

At 390-pixel width, the expanded documentation menu stayed between x=15 and
x=375. Claude and ChatGPT handoff links contained the public Amber raw-Markdown
URL. That raw endpoint returned HTTP 200, `text/plain; charset=utf-8`, and the
published 2.0.3 installation guide.

The production edge set a necessary Cloudflare `__cf_bm` security cookie. The
live privacy page discloses that boundary and says accurately that the Amber
application does not read it or use it for analytics, ads, or profiles.

## Privacy inventory

- No application analytics, tracking pixel, tag manager, marketing form,
  advertising library, or third-party embed.
- No application cookie or browser storage.
- Fonts, scripts, stylesheets, and images served from the site origin.
- Necessary hosting/CDN security cookies, including a possible Cloudflare
  `__cf_bm` cookie, are disclosed; the Amber application does not read or use
  them for analytics, ads, or profiles.

## Remaining decisions

- **PROPOSED:** Signed remote-template delivery and cache design.
- **PREVIEW:** Native applications, Grant, Gemma, Asset Pipeline, and
  persistence/authentication integrations.
- **UNKNOWN:** V2 GA date, final preview graduation criteria, and any future
  background-worker character.

These items are deliberately outside the supported web public-beta contract.

## August 11 documentation and platform addendum

- Linux ARM64 passed a real GitHub-hosted ARM64 generated-app job. The next CLI
  release matrix also built, smoke-tested, archived, checksummed, and uploaded
  the `linux-arm64` artifact in a manual dry run. CLI 2.0.3 still requires the
  documented source installation on ARM64.
- Windows x86_64 exposed a controller-relative ECR path defect in the released
  beta.2 framework. The fix merged through
  [amberframework/amber#1402](https://github.com/amberframework/amber/pull/1402),
  and the candidate dependency passed generation, dependency installation,
  request specs, and native application compilation on `windows-latest`.
  Windows remains outside the beta release gate, and beta.2 is not described as
  Windows-compatible.
- [amberframework/amber_cli#34](https://github.com/amberframework/amber_cli/pull/34)
  merged the Linux ARM64 release target and the ongoing Linux ARM64/Windows
  generated-application CI contract.
- The documentation now distinguishes terminal commands from editor content,
  removes unchanged-content badges, normalizes Crystal code labels, adds a
  Gemini handoff, publishes an AI knowledge bundle, and supplies a complete Pet
  Tracker first-app guide with an exact file or working directory for every
  example.
- The website now includes inspectable Showcase and Sponsors & Contributors
  pages. The published benchmark remains linked to its workload and limitations.
- Current local verification: 44 examples, 0 failures; all three V2 audit
  scripts and JavaScript syntax validation passed. Browser QA covered YAML
  editor highlighting, inherited-guide badge behavior, the single-line New
  badge, all three assistant handoffs, Pet Tracker labels, and the two new
  public pages.
