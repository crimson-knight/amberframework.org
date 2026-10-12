# Amber V2 roadmap publication

Owner requested publication of the reviewed roadmap, Pioneers, research and release-process pages, plus continuing repository release tracking. Proposal: https://github.com/amberframework/amber/issues/1412.

## Prepared and exercised

- Canonical HTML, Markdown and JSON routes for `/roadmap`, `/pioneers`, `/research` and `/release-tracker` returned HTTP 200 from the running production-mode application.
- `crystal-alpha build --release --no-debug -Dwithout_mt`: GREEN, zero errors and zero warnings. Application specs: 56 passing examples. Collector behavior: 13 passing tests, including incomplete fetch, wrong roster, tag movement, artifact corruption and unchanged-content checks.
- The collector queried all nine declared public repositories. Releases include prereleases, full resolved source commits and GitHub-reported asset digests. Branch activity is distinct from published release availability. Crystal Alpha tracks `incremental-compilation`; website implementation activity tracks changes under `src/`.
- Pioneers, roadmap, research and tracker checked at widths 320, 390, 736 and 1024 in both themes: no document overflow or intake fields. Research image loading settled successfully. Pioneers idea selection and copying its assistant request worked; roadmap chapter navigation advanced the scrolling map. Browser console checks found zero warnings/errors.
- Existing artwork, launch, beta-documentation and retained-research validators passed. New page-specific illustration SHA-256: `b5f1c250d0278cce8adb1dca646ecc23d0ad9563dbb475473c706be999deb3c5`. The retired artwork is excluded by a source/generated-asset identity gate.
- Runtime dependencies use exact commits and Minecart-generated tree hashes. CI and deployment bootstrap images, Python, Actions and additional build packages carry immutable pins and checksums. Application compilation uses the verified Crystal Alpha fork and frozen Minecart dependencies.

## Release behavior

The existing website refresh workflow checks the roster hourly, manually and on `ecosystem-release` repository dispatch. It publishes only a complete validated projection and preserves last-success freshness on collection failure. Unchanged content retains its bundle identity. Mutable static resources revalidate; fingerprinted assets retain immutable caching. Generated refreshes reuse the application compilation layer.

Refresh workflow installation, remote CI, deployment ACTIVE status, public-origin readback and a real post-merge refresh must be verified before reporting this publication complete. The previous active deployment is `c65f5503-3741-47d1-819d-7c3397dffbb6` in DigitalOcean App `03366d70-743c-469c-842f-d25b44b146b0`.

## Remaining ecosystem work

Issue-to-feature reconciliation, shared cross-repository release manifests, a unified documentation/tutorial/tool bundle, required GitHub contribution enforcement, packaged business-template capacity profiles and native/application-MCP graduation remain explicit release-contract work. Release metadata does not promote those features automatically.

## Crystal review rubric

MAJOR 1, 2: fixed — package manifest contains official package metadata and dependency pins; application settings remain in their existing configuration APIs.
MAJOR 3, 4, 6, 7, 9, 13, 15a, 15b, 14: n/a — this change introduces no incoming Crystal JSON parsing, casts, library logging/environment behavior, new persistence or jobs.
MAJOR 5, 10, 11, 12: fixed — Alpha toolchain, exercised representation specs/runtime routes, formatted Crystal changes and frozen hash-verified lockfile.
MAJOR 8: fixed — new `Publication::ServePublicPageController` uses statement-shaped AED names.
The installed Crystal formatter accepts `.cr`; direct ECR input reports unsupported syntax. ECR changes were checked by the active feedback gate, compiled through their callers and rendered in the running site.
