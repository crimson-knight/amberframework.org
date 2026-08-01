#!/usr/bin/env bash
set -euo pipefail

test -s public/assets/brand/amber-crystal.svg
test -s public/assets/brand/amber-grant-gemma-hero.webp
test -s public/assets/css/amber-brand.css
test -s public/assets/js/amber-site.js
test -s docs/v2/guides/web-template/index.md

grep -F 'version: 2.0.0-beta.2' shard.yml
grep -F 'version: 2.0.0-beta.2' docs/v2/getting-started/installation.md
grep -F 'brew install amberframework/amber_cli/amber_cli' src/views/home/index.ecr
grep -F 'amber new my_app --type web' src/views/home/index.ecr
grep -F 'Get started with V2' src/views/layouts/_nav.ecr
grep -F 'data-version-select' src/views/docs/_version_selector.ecr
grep -F 'inherits_from: ~' docs/versions.yml
grep -F 'These guides do not inherit Amber 1.4.1 pages.' docs/v2/guides/index.md
grep -F 'Amber CLI `2.0.2` generates the supported Amber V2 beta web application' docs/v2/guides/web-template/index.md
grep -F 'width: 100%;' public/assets/css/amber-brand.css
grep -F '.docs-content pre {' public/assets/css/amber-brand.css
grep -F 'padding: 0;' public/assets/css/amber-brand.css
grep -F '.docs-content pre code {' public/assets/css/amber-brand.css
grep -F 'padding: 1.15rem 1.25rem;' public/assets/css/amber-brand.css

if find src/views -type f -name '*.slang' | grep -q .; then
  echo "Amber V2 site must use ECR views only" >&2
  exit 1
fi

if rg -n 'inherits_from: v1\.4\.1' docs/versions.yml; then
  echo "V2 docs must not silently inherit unreviewed V1 instructions" >&2
  exit 1
fi

if rg -n '/dist/main\.bundle|application\.slang|render\("[^\"]+\.slang"\)|amberframework/amber:1\.3\.2' \
  Dockerfile config src README.md; then
  echo "Amber V2 site still references a legacy Slang, Webpack, or Amber 1 runtime" >&2
  exit 1
fi

if rg -n 'code\s*\{[^}]*padding:.*!important|pre code\s*\{[^}]*padding:\s*0' public/assets/css; then
  echo "Code-block padding has multiple competing owners" >&2
  exit 1
fi

echo "Amber V2 site launch checks passed"
