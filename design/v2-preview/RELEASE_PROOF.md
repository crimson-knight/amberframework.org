# Amber V2 public-beta release proof

Date: August 10, 2026 (America/New_York)

Status: **READY TO DEPLOY — PREDEPLOYMENT PROOF COMPLETE**

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
- Amber CLI merge commit: `2c512cbceee822d41d2cbce86de294533ee214ae`
- Amber CLI pull request: <https://github.com/amberframework/amber_cli/pull/33>
- Amber CLI release: <https://github.com/amberframework/amber_cli/releases/tag/v2.0.3>
- Amber CLI release workflow: <https://github.com/amberframework/amber_cli/actions/runs/31451405352>
- Amber CLI cross-platform dry run: <https://github.com/amberframework/amber_cli/actions/runs/31450525578>
- Homebrew validation fix: <https://github.com/amberframework/homebrew-amber_cli/pull/5>
- Homebrew macOS/Linux install proof: <https://github.com/amberframework/homebrew-amber_cli/actions/runs/31451864810>
- Production host: DigitalOcean App Platform, application
  `03366d70-743c-469c-842f-d25b44b146b0`, auto-deploying `master`

The website merge commit and DigitalOcean deployment identifier are appended
after the production deployment reaches a successful state.

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
