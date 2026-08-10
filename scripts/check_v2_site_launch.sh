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

grep -F 'version: 2.0.0-beta.2' shard.yml
grep -F 'version: 2.0.0-beta.2' docs/v2/getting-started/installation.md
grep -F 'brew tap amberframework/amber_cli' src/views/home/index.ecr
grep -F 'brew install amber_cli' src/views/home/index.ecr
grep -F 'amber new my_app' src/views/home/index.ecr
grep -F 'Test V2 beta' src/views/layouts/_nav.ecr
grep -F "menuButton.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');" public/assets/js/amber-site.js
grep -F 'data-version-select' src/views/docs/_version_selector.ecr
grep -F 'inherits_from: v1.4.1' docs/versions.yml
grep -F 'V2 carries forward framework concepts that still apply' docs/v2/guides/index.md
grep -F 'Run `amber routes` from the project root' docs/v2/guides/routing/routes.md
grep -F 'The V1 guide' docs/v2/guides/controllers/sessions.md
grep -F 'HTTP::Server::Response' docs/v2/guides/controllers/request-and-response-objects.md
grep -F 'guides/controllers/params.md: guides/schema-api' docs/v2/_replacements.yml
grep -F 'Web is the default.' docs/v2/guides/web-template/index.md
grep -F 'PROPOSED — NOT IMPLEMENTED' design/v2-preview/TEMPLATE_DELIVERY_STRATEGY.md
grep -F '.code-window' public/assets/css/amber-brand.css
grep -F '.table-scroll' public/assets/css/amber-brand.css
grep -F 'padding: 1.15rem 1.25rem;' public/assets/css/amber-brand.css

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

if rg -n 'code\s*\{[^}]*padding:.*!important|pre code\s*\{[^}]*padding:\s*0' public/assets/css/amber-brand.css; then
  echo "Code-block padding has multiple competing owners" >&2
  exit 1
fi

./scripts/check_v2_preview.sh

echo "Amber V2 site preview checks passed"
