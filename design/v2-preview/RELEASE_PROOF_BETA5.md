# Amber V2 beta.5 / CLI 2.0.6 release proof

Date: August 13, 2026 (America/New_York)

Status: **FRAMEWORK AND CLI PUBLISHED — WEBSITE RELEASE IN PROGRESS**

This document is the live gate for executable request and response schemas,
CBOR/COSE support, and the coordinated generated-application update. A check is
recorded only after it has run against the canonical release commit.

## Version contract

| Component | Version | Canonical source |
| --- | --- | --- |
| Amber Framework | `2.0.0-beta.5` | [published prerelease](https://github.com/amberframework/amber/releases/tag/v2.0.0-beta.5) from `76954f0e2edc10d568e7ffcea3faa94b2aa476d2` |
| Amber CLI | `2.0.6` | [published release](https://github.com/amberframework/amber_cli/releases/tag/v2.0.6) from `1cba58bdfad27ce1731e73a55002460594958571` |
| Asset Pipeline | `0.37.0` | released manifest-backed static-asset compiler |
| Supported application type | `web` | ECR, Grant, SQLite, Micrate, local static assets |
| Preview application types | `native` | macOS, iOS, and Android remain preview |

## Executed validation

### Amber Framework 2.0.0-beta.5

- [x] [Framework PR 1408](https://github.com/amberframework/amber/pull/1408)
      merged into `v2-dev` as `76954f0e2edc10d568e7ffcea3faa94b2aa476d2`.
- [x] Local complete framework suite: 2,402 examples, 0 failures.
- [x] Deprecated `params.validation` compatibility remains executable and emits
      migration warnings rather than breaking an upgraded application.
- [x] GitHub macOS, GitHub Linux, and CircleCI passed on the final candidate.
- [x] Post-merge `v2-dev` CI passed before the prerelease tag was created.
- [x] The published tag and release target the canonical merge commit.

### Amber CLI 2.0.6 and fresh application

- [x] [CLI PR 38](https://github.com/amberframework/amber_cli/pull/38)
      merged into `main` as `1cba58bdfad27ce1731e73a55002460594958571`.
- [x] Local CLI suite: 412 examples, 0 failures.
- [x] The generated Pet scaffold binds executable schemas to HTML create/update
      actions and returns ECR field errors with HTTP 422.
- [x] A clean generated app installed Amber `2.0.0-beta.5`, built assets,
      migrated SQLite, ran 12 application specs, compiled, booted, and completed
      persisted create/read/PATCH behavior.
- [x] The same smoke proved fingerprinted CSS, JavaScript, SVG, favicon, SRI,
      immutable caching, MIME types, URL rewriting, and gzip behavior.
- [x] Pull-request and post-merge checks passed on Apple Silicon macOS, Linux
      x86_64, Linux ARM64, and Windows x86_64.
- [x] Release-workflow dry run
      [31725064889](https://github.com/amberframework/amber_cli/actions/runs/31725064889)
      built and smoke-tested all three published archive targets.
- [x] The live release workflow uploads all three archives and checksum files,
      then successfully notifies the Homebrew tap.
- [x] Homebrew installs `2.0.6` and completes its generated-app validation on
      each platform in the tap matrix.

### Website and documentation

- [x] Current installation, support, migration, CLI, web-template, Pet Tracker,
      schema, CBOR/COSE, OpenAPI, and performance pages name the released
      framework and CLI pair.
- [x] Historical beta.4 router measurements remain labeled beta.4 rather than
      being silently relabeled as beta.5 evidence.
- [x] The release catalog includes the published beta.5 and CLI 2.0.6 notes.
- [x] Website specs, documentation audits, asset checks, and production image
      build pass on the final dependency lock.
- [x] Desktop and mobile browser proof passes for the homepage, installation,
      web template, Pet Tracker, schema, migration, performance, blog, and
      releases pages.
- [ ] The website PR merges from an all-green reviewed commit.
- [ ] The canonical website commit is deployed and the public origin is
      verified independently.

## Publication order

1. **Complete:** merge framework PR 1408 and publish Amber `2.0.0-beta.5`.
2. **Complete:** merge CLI PR 38, publish `2.0.6`, upload archives and
   checksums, and complete the Homebrew handoff.
3. **Pending:** finish the site release proof, merge the website, deploy the
   canonical commit, and verify the public origin.

## Remaining boundaries

- **SUPPORTED:** ECR web applications, executable request/response schemas,
  JSON, opt-in CBOR and COSE, Grant with SQLite/PostgreSQL/MySQL, Micrate
  migrations, and manifest-backed local static assets.
- **COMPATIBLE:** the deprecated `params.validation` API remains functional
  during the V2 migration window.
- **PREVIEW:** native generation, generated authentication and API resources,
  and Gemma attachments/storage.
- **UNKNOWN:** V2 GA date and final graduation criteria for preview surfaces.
