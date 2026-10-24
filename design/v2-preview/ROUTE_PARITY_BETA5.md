# Route parity: live site against a clean Amber V2 build (2026-10-24)

This record checks that the site's Amber V2 build, rebuilt from a clean checkout
of `master` (`ef9c644`), serves the same responses as the production site at
`https://amberframework.org`. Rerun it before and after any Amber or shard bump.

## Dependency state

| Shard | Pin | Lock checksum |
|---|---|---|
| amber | `amberframework/amber` commit `76954f0e` (tag `v2.0.0-beta.5`, also the head of upstream `v2-dev`) | `git-tree:1d80477a…` |
| asset_pipeline | `amberframework/asset_pipeline` commit `9f54be45` (0.37.0) | `git-tree:47c884c5…` |
| markd | `icyleaf/markd` commit `9db69c0a` (0.6.0) | `git-tree:826f602c…` |

- `shards-alpha install` (Minecart 2025.11.25.8) run with no lock and an empty
  cache regenerates `shard.lock` byte for byte.
- `shards-alpha install --frozen` from an empty `lib/` and an empty cache
  verifies all three checksums before any postinstall step.
- Changing one byte of the amber checksum makes `--frozen` exit 1 with
  `ChecksumMismatch`.

## Build gates (macOS arm64, crystal-alpha 1.21.0 [9c1e8ec64])

| Gate | Result |
|---|---|
| `crystal-alpha spec` | 56 examples, 0 failures, 0 errors, 0 pending; 0 warnings |
| `crystal-alpha build src/amberframework.cr --release --no-debug -Dwithout_mt` | exit 0, 0 errors, 0 warnings (GREEN) |
| `crystal-alpha run scripts/build_assets.cr -- --check` | 61 static assets verified |

## Method

1. `scripts/route_parity/inventory.py <repo>` lists every route: each fixed
   route in `config/routes.cr`, its `.md` and `.json` variants, every character,
   every post in `blog/posts.yml`, every page under `docs/` as HTML and
   Markdown, every file under `public/`, and probes for redirects, the docs
   API, MCP, and 404s (530 requests).
2. `scripts/route_parity/fingerprint.py <inventory> <base-url> [delay]` sends
   each request without following redirects and records the status,
   `Location`, content type, size, and SHA-256 of the body.
3. `scripts/route_parity/compare.py <live> <build> <out>` joins the two runs
   route by route.
4. `scripts/route_parity/decode_cf_email.py <live-body>` reverses Cloudflare's
   email obfuscation so an edge-rewritten page can be compared with the
   origin body.

The local build ran as `AMBER_ENV=production bin/amberframework` after the same
asset and publication steps the `Dockerfile` runs. Live requests were paced at
150 ms and carried the AgentC research User-Agent.

## Result

All 530 routes return the same status and `Location` on both sides. 513 bodies
are byte-identical. The other 17 differ only by edits the Cloudflare edge
makes, so the origin output is identical:

| Routes | Cause | Check |
|---|---|---|
| 14 docs pages | Cloudflare Email Address Obfuscation rewrites addresses and `mailto:` links and injects `email-decode.min.js` | identical after `decode_cf_email.py` |
| `/docs/v1.4.1/guides/controllers`, `/docs/v1.4.1/guides/views` | Cloudflare Automatic HTTPS Rewrites turns one `http://` link into `https://` | only the rewritten link differs |
| `/api/docs/changes/v2` | the same 68 entries in a different order; `DocsScanner.changed_files` returns filesystem order, which differs between the Linux image and macOS | equal as sets |

| Route family | Routes | Same status | Byte-identical |
|---|---|---|---|
| `/docs/*path` | 302 | 302 | 286 |
| static `/*` (`public/`) | 134 | 134 | 134 |
| `/blog/:year/:month/:day/:id` | 26 | 26 | 26 |
| redirect, API, MCP, and 404 probes | 15 | 15 | 14 |
| `/characters/:id` | 9 | 9 | 9 |
| `HomeController#page_markdown` | 9 | 9 | 9 |
| `BlogController#feed` | 3 | 3 | 3 |
| `HomeController#index` | 3 | 3 | 3 |
| Publication pages (pioneers, roadmap, research, release tracker) | 8 | 8 | 8 |
| other `HomeController` pages and their `.json` variants | 16 | 16 | 16 |
| blog index, blog Markdown index, docs index, knowledge bundle, MCP | 5 | 5 | 5 |

Full data: `route_parity_beta5/route-inventory.json` and
`route_parity_beta5/comparison-live-vs-v2-build.json`.

## Notes

- Cloudflare's email obfuscation alters code samples in the documentation:
  `alice@example.com` in a Grant example is served as `[email protected]`
  until JavaScript runs, and readers who copy the code or fetch the Markdown
  render of the HTML see the placeholder. Turning off Email Address
  Obfuscation for the zone, or wrapping the docs body in
  `<!--email_off-->…<!--/email_off-->`, serves the code as written.
- Sorting the result of `DocsScanner.changed_files` would make
  `/api/docs/changes/:version` identical on every host.
