#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "Amber V2 preview check failed: $1" >&2
  exit 1
}

test -s design/v2-preview/EXPERIENCE_BRIEF.md
test -s design/v2-preview/RELEASE_GATES.md
test -s design/v2-preview/ASSET_PROVENANCE.md
grep -F 'PREVIEW — NOT APPROVED FOR RELEASE' design/v2-preview/EXPERIENCE_BRIEF.md >/dev/null
grep -F 'Owner explicitly says the branch may merge and deploy.' design/v2-preview/RELEASE_GATES.md >/dev/null

for asset in \
  public/assets/brand/amber-crystal.svg \
  public/assets/characters/amber-hero-inviting-studio.webp \
  public/assets/characters/amber-id-original-studio.webp \
  public/assets/characters/grant-id-original-studio.webp \
  public/assets/characters/gemma-id-original-studio.webp \
  public/assets/characters/amber-chibi-original-studio.webp \
  public/assets/fonts/Manrope-Variable.woff2 \
  public/assets/fonts/Fraunces-Variable.woff2 \
  public/assets/fonts/Fraunces-Italic-Variable.woff2 \
  public/assets/fonts/OFL-Manrope.txt \
  public/assets/fonts/OFL-Fraunces.txt; do
  test -s "$asset" || fail "missing local asset: $asset"
done

grep -F '@font-face' public/assets/css/amber-brand.css >/dev/null
grep -F '/assets/fonts/Manrope-Variable.woff2' public/assets/css/amber-brand.css >/dev/null
grep -F 'data-no-tracking="true"' src/views/layouts/application.ecr >/dev/null
grep -F 'We do not track you.' src/views/home/privacy.ecr >/dev/null
grep -F 'No analytics.' src/views/home/privacy.ecr >/dev/null
grep -F 'No cookies.' src/views/home/privacy.ecr >/dev/null
grep -F 'get "/privacy"' config/routes.cr >/dev/null

if rg -n -i 'googletagmanager|google-analytics|fonts\.googleapis|fonts\.gstatic|\bgtag\s*\(|\bdataLayer\b' \
  src/views public/assets/css/amber-brand.css public/assets/js/amber-site.js; then
  fail "analytics or externally hosted fonts remain in the active preview"
fi

if rg -n -i '<(script|img)[^>]+src="https?://|<link[^>]+rel="(stylesheet|icon|apple-touch-icon|preload|modulepreload)"[^>]+href="https?://|url\([^)]*https?://|@import[^;]*https?://' \
  src/views public/assets/css/amber-brand.css; then
  fail "a third-party runtime asset is referenced"
fi

if rg -n -i '^image:\s+https?://' blog/posts.yml; then
  fail "blog metadata still references a remote image"
fi

if rg -n 'amber-laptop-hero\.webp|amber-id\.webp|grant-id\.webp|gemma-id\.webp|amber-chibi\.webp' \
  src/views blog/posts.yml; then
  fail "the comparison-only character set is still referenced by the active preview"
fi

if rg -n 'document\.cookie|localStorage|sessionStorage|indexedDB' public/assets/js/amber-site.js; then
  fail "preview JavaScript persists visitor data"
fi

grep -F 'amber new my_app' src/views/home/index.ecr >/dev/null
grep -F 'web is the default' src/views/home/index.ecr >/dev/null
grep -F 'amber new field_app --type native' src/views/home/index.ecr >/dev/null
grep -F 'Not release-gated with the web beta' src/views/home/index.ecr >/dev/null
grep -F '/assets/characters/amber-hero-inviting-studio.webp' src/views/home/index.ecr >/dev/null
grep -F 'Grant keeps the records straight.' src/views/home/index.ecr >/dev/null
grep -F 'The core web template does not install an ORM by default' src/views/home/index.ecr >/dev/null
grep -F '/docs/v2/guides/models/grant' src/views/home/index.ecr >/dev/null
grep -F '/assets/characters/amber-id-original-studio.webp' src/views/home/characters.ecr >/dev/null
grep -F '/assets/characters/grant-id-original-studio.webp' src/views/home/characters.ecr >/dev/null
grep -F '/assets/characters/gemma-id-original-studio.webp' src/views/home/characters.ecr >/dev/null
grep -F '/assets/characters/amber-chibi-original-studio.webp' src/views/docs/show.ecr >/dev/null

grep -F 'class="table-scroll"' src/services/markdown_preprocessor.cr >/dev/null
grep -F 'class="code-window"' src/services/markdown_preprocessor.cr >/dev/null
grep -F '.docs-content table {' public/assets/css/amber-brand.css >/dev/null
grep -F 'display: table;' public/assets/css/amber-brand.css >/dev/null
grep -F '.docs-content pre code,' public/assets/css/amber-brand.css >/dev/null

grep -F 'data-terminal-demo' src/views/home/index.ecr >/dev/null
grep -F 'data-terminal-mode="typed"' src/views/home/index.ecr >/dev/null
grep -F 'data-terminal-url' src/views/home/index.ecr >/dev/null
grep -F 'terminalDemo.classList.add('"'"'is-browser-open'"'"')' public/assets/js/amber-site.js >/dev/null
grep -F 'data-crystal-field' src/views/home/index.ecr >/dev/null
grep -F 'prefers-reduced-motion' public/assets/css/amber-brand.css >/dev/null
grep -F 'IntersectionObserver' public/assets/js/amber-site.js >/dev/null
grep -F 'data-open-docs-ai="claude"' src/views/docs/show.ecr >/dev/null
grep -F 'data-open-docs-ai="chatgpt"' src/views/docs/show.ecr >/dev/null
grep -F 'View as Markdown' src/views/docs/show.ecr >/dev/null
grep -F 'code.language-crystal' public/assets/js/amber-site.js >/dev/null
grep -F '.token-keyword' public/assets/css/amber-brand.css >/dev/null
grep -F 'max-height: none;' public/assets/css/amber-brand.css >/dev/null
grep -F 'class="nav-group' src/views/docs/_sidebar.ecr >/dev/null
grep -F 'replacement-link' src/views/docs/_version_timeline.ecr >/dev/null
grep -F 'version_id: @version_id, page_path: source_path' src/controllers/docs_controller.cr >/dev/null

echo "Amber V2 preview release-boundary, privacy, asset, table, code-window, and interaction checks passed"
