# Amber V2 beta.4 / CLI 2.0.5 release proof

Date: August 12, 2026 (America/New_York)

Status: **PUBLISHED — PUBLIC ORIGIN VERIFIED**

This document is the live gate for the manifest-backed asset release. A check
is recorded only after it has run against the clean release branches. The
August 10 beta.2 launch evidence remains in `RELEASE_PROOF.md`.

## Version contract

| Component | Candidate version | Candidate source |
| --- | --- | --- |
| asset_pipeline | `0.37.0` | [published release](https://github.com/amberframework/asset_pipeline/releases/tag/v0.37.0) from `9f54be45515324d43f5ea02cdf745a7e2c344137` |
| Amber Framework | `2.0.0-beta.4` | [published prerelease](https://github.com/amberframework/amber/releases/tag/v2.0.0-beta.4) from `a2128cdb4fef07025e0cc1c1578d4c807ae6c274` |
| Amber CLI | `2.0.5` | [published release](https://github.com/amberframework/amber_cli/releases/tag/v2.0.5) from `f872ae618bc7a09922ceecb30c2d514e011bb8e7` |
| Supported application type | `web` | ECR, Grant, SQLite, Micrate, local static assets |
| Preview application types | `native` | macOS, iOS, and Android remain preview |

## Clean release scope

- [x] asset_pipeline was rebuilt from current `main`; the clean release is
      [PR 14](https://github.com/amberframework/asset_pipeline/pull/14).
- [x] Amber was rebuilt from current `v2-dev`; the clean release is
      [PR 1407](https://github.com/amberframework/amber/pull/1407).
- [x] Oversized or incorrectly targeted drafts 13 and 1406 were closed without
      merging.
- [x] Amber CLI changes remain isolated in
      [PR 37](https://github.com/amberframework/amber_cli/pull/37).
- [x] asset_pipeline `0.37.0` and Amber `2.0.0-beta.4` were published from
      their canonical merged commits.
- [x] Amber CLI `2.0.5` was merged and published from its canonical all-green
      commit with three archives and matching checksum files.
- [x] The website release branch was committed, reviewed, and merged in
      [site PR 17](https://github.com/crimson-knight/amberframework.org/pull/17).

## Executed validation

### asset_pipeline 0.37.0

- [x] Local complete web suite: 2,071 examples, 0 failures, 66 explicitly
      pending native visual probes.
- [x] Focused deterministic compiler contract: 8 examples, 0 failures.
- [x] GitHub CI: Linux and macOS on Crystal 1.10.1 and latest.
- [x] GitHub CI: Windows static-asset discovery and compilation.
- [x] Tests restore their fixture mutations, so a green suite leaves the
      checkout unchanged.

### Amber Framework 2.0.0-beta.4

- [x] Local complete suite: 2,350 examples, 0 failures.
- [x] Local beta.4 release contract and public server compile gate.
- [x] GitHub and CircleCI checks pass on the final candidate.

### Amber CLI 2.0.5 and fresh application

- [x] Local CLI suite: 410 examples, 0 failures.
- [x] CLI beta contract and production CLI binary build.
- [x] A clean application generated four fingerprinted assets, installed the
      candidate dependencies, ran specs, generated and migrated Pet CRUD, built
      a production binary, booted, and completed create/update requests.
- [x] Live asset responses proved CSS/JavaScript/SVG MIME types, SRI links,
      immutable fingerprint caching, gzip negotiation, and local CSS URL
      rewriting.
- [x] macOS release-binary smoke passes in GitHub Actions.
- [x] x86_64 Linux release-binary smoke passes in GitHub Actions.
- [x] ARM64 Linux generated application compiles and runs its smoke contract.
- [x] Windows x86_64 generates all four authored assets, installs dependencies,
      compiles the web application, boots it, and serves its fingerprinted
      assets.
- [x] Homebrew installs 2.0.5 and completes its generated-app launch probe on
      Apple Silicon macOS, x86_64 Linux, and ARM64 Linux. The fingerprint-aware
      launch contract landed in
      [tap PR 7](https://github.com/amberframework/homebrew-amber_cli/pull/7),
      and the canonical `main` run passed on all three platforms.

### Website and documentation

- [x] The website uses `app/assets/` as source and generated
      `public/assets/` output as the framework reference implementation.
- [x] V2 guides give a file path or working directory for every authored code
      example and distinguish terminal commands from editor content.
- [x] Asset guides cover images, fonts, arbitrary files, CSS and JavaScript
      reference rewriting, integrity, compression, caching, verification, and
      the upload boundary.
- [x] Site specs and all three V2 audit scripts pass on the final dependency
      lock.
- [x] Production Docker image builds and serves the final candidate.
- [x] Desktop and mobile browser proof covers homepage, installation, asset
      guide, web-template guide, Amber's Way, blog, and release pages.
- [x] Public-origin asset inventory, all three CLI downloads, dated release
      notes, page-level Markdown and JSON, and Claude, ChatGPT, and Gemini
      handoffs are verified after deployment. The full V2 documentation bundle
      was corrected and live-server gated in
      [site PR 18](https://github.com/crimson-knight/amberframework.org/pull/18),
      then downloaded successfully from `/docs/v2/knowledge.md` on the public
      origin.

## Publication order

1. **Complete:** merge and release asset_pipeline `0.37.0`.
2. **Complete:** merge `v2-dev` and publish Amber `2.0.0-beta.4` as a prerelease.
3. **Complete:** replace candidate pins with the two released versions, rerun
   the fresh-app matrix, merge Amber CLI, and publish `2.0.5` plus checksums.
4. **Complete:** synchronize the release catalog, lock the site to published
   versions, run Docker/browser proof, merge the website, and verify the public
   origin.

## Remaining boundaries

- **SUPPORTED:** ECR web applications, Grant with SQLite/PostgreSQL/MySQL,
  Micrate migrations, and manifest-backed local static assets.
- **PREVIEW:** native generation, generated authentication and API resources,
  and Gemma attachments/storage.
- **PROPOSED:** independently downloadable signed remote templates.
- **UNKNOWN:** V2 GA date and final graduation criteria for preview surfaces.
