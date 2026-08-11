#!/usr/bin/env bash
set -euo pipefail

test -s public/assets/brand/amber-crystal.svg
test -s public/assets/characters/amber-hero-desk-transparent-higgsfield.webp
test -s public/assets/characters/amber-frontier-higgsfield.webp
test -s public/assets/characters/amber-id-original-studio.webp
test -s public/assets/characters/amber-chibi-hero-mark-v2.webp
test -s public/assets/css/amber-brand.css
test -s public/assets/js/amber-site.js
test -s docs/v2/guides/web-template/index.md
test -s docs/v2/guides/pet-tracker/index.md
test -s docs/v2/guides/ai-assistants/index.md
test -s src/views/home/showcase.ecr
test -s src/views/home/sponsors.ecr

grep -F 'version: 2.0.0-beta.2' shard.yml
grep -F 'version: 2.0.0-beta.2' docs/v2/getting-started/installation.md
grep -F 'brew install amberframework/amber_cli/amber_cli' src/views/home/index.ecr
grep -F 'Installed amber and amber-lsp' src/views/home/index.ecr
grep -F 'amber new my_app' src/views/home/index.ecr
grep -F 'Test V2 beta' src/views/layouts/_nav.ecr
grep -F "menuButton.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');" public/assets/js/amber-site.js
grep -F 'data-version-select' src/views/docs/_version_selector.ecr
grep -F 'inherits_from: v1.4.1' docs/versions.yml
grep -F 'V2 keeps framework concepts that still apply' docs/v2/guides/index.md
grep -F 'Run `amber routes` from the project root' docs/v2/guides/routing/routes.md
grep -F 'The V1 guide' docs/v2/guides/controllers/sessions.md
grep -F 'HTTP::Server::Response' docs/v2/guides/controllers/request-and-response-objects.md
grep -F 'guides/controllers/params.md: guides/schema-api' docs/v2/_replacements.yml
grep -F 'Web is the default.' docs/v2/guides/web-template/index.md
grep -F 'respond_with' docs/v2/guides/views/index.md
grep -F 'type="importmap"' docs/v2/guides/assets/import-maps.md
grep -F '21,795 requests/second' docs/v2/guides/performance.md
grep -F '"median": 21795.0' public/benchmarks/amber-v2-round22-summary.json
grep -F 'PROPOSED — NOT IMPLEMENTED' design/v2-preview/TEMPLATE_DELIVERY_STRATEGY.md
grep -F '.code-window' public/assets/css/amber-brand.css
grep -F '.table-scroll' public/assets/css/amber-brand.css
grep -F 'padding: 1.15rem 1.25rem;' public/assets/css/amber-brand.css
grep -F 'data-open-docs-ai="gemini"' src/views/docs/show.ecr
grep -F 'get "/docs/v2/knowledge.md"' config/routes.cr
grep -F 'documentation_markdown' src/controllers/docs_controller.cr
grep -F 'documentation_json' src/controllers/docs_controller.cr
grep -F 'View JSON' src/views/docs/show.ecr
grep -F 'get "/showcase"' config/routes.cr
grep -F 'get "/sponsors"' config/routes.cr
grep -F 'white-space: nowrap;' public/assets/css/amber-brand.css
grep -F 'get "/blog/feed.xml"' config/routes.cr
grep -F 'post "/mcp"' config/routes.cr
grep -F 'href="/performance"' src/views/home/index.ecr
grep -F 'amber-v2-site-websocket-2026-08-11.json' src/views/home/performance.ecr

for sprite in productivity performance happiness humility respect trust; do
  test -s "public/assets/characters/way-sprites/${sprite}-a.webp"
  test -s "public/assets/characters/way-sprites/${sprite}-b.webp"
done

if rg -n 'Carried forward' src/views docs/v2; then
  echo "Unchanged documentation should be represented by the absence of a change badge" >&2
  exit 1
fi

if find src/views -type f -name '*.slang' | grep -q .; then
  echo "Amber V2 site must use ECR views only" >&2
  exit 1
fi

if rg -n '/dist/main\.bundle|application\.slang|render\("[^\"]+\.slang"\)|amberframework/amber:1\.3\.2' \
  Dockerfile config src README.md; then
  echo "Amber V2 site still references a legacy Slang, Webpack, or Amber 1 runtime" >&2
  exit 1
fi

if rg -n 'owner proofing|Owner approval|PROPOSED — NOT APPROVED|generic centered welcome|Amber advertisement' \
  src/views docs/v2; then
  echo "Amber V2 public copy still contains internal proofing or placeholder language" >&2
  exit 1
fi

if rg -n '/opt/homebrew/bin/amber' src/views docs/v2; then
  echo "Cross-platform public copy must not claim a macOS-only install path" >&2
  exit 1
fi

if rg -n 'code\s*\{[^}]*padding:.*!important|pre code\s*\{[^}]*padding:\s*0' public/assets/css/amber-brand.css; then
  echo "Code-block padding has multiple competing owners" >&2
  exit 1
fi

if rg -n '^```ruby$' docs; then
  echo "Documentation code fences must identify Crystal examples as Crystal" >&2
  exit 1
fi

./scripts/check_v2_preview.sh

echo "Amber V2 site preview checks passed"
