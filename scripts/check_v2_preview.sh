#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "Amber V2 preview check failed: $1" >&2
  exit 1
}

test -s design/v2-preview/EXPERIENCE_BRIEF.md
test -s design/v2-preview/RELEASE_GATES.md
test -s design/v2-preview/ASSET_PROVENANCE.md
test -s design/v2-preview/TEMPLATE_DELIVERY_STRATEGY.md
grep -F 'APPROVED FOR PUBLIC BETA' design/v2-preview/EXPERIENCE_BRIEF.md >/dev/null
grep -F 'Owner explicitly says the branch may merge and deploy.' design/v2-preview/RELEASE_GATES.md >/dev/null
grep -F 'OFFLINE DELIVERY IMPLEMENTED; REMOTE CHANNEL PROPOSED' design/v2-preview/TEMPLATE_DELIVERY_STRATEGY.md >/dev/null

for asset in \
  app/assets/brand/amber-crystal.svg \
  app/assets/brand/crys-mascot.svg \
  app/assets/brand/claude-icon-rounded.svg \
  app/assets/brand/openai-symbol-2025.svg \
  app/assets/characters/amber-hero-desk-transparent-higgsfield.webp \
  app/assets/characters/amber-hero-desk-desktop-higgsfield.webp \
  app/assets/characters/amber-hero-desk-mobile-higgsfield.webp \
  app/assets/characters/amber-frontier-higgsfield.webp \
  app/assets/characters/grant-records-warehouse-higgsfield.webp \
  app/assets/characters/gemma-file-logistics-higgsfield.webp \
  app/assets/characters/amber-id-original-studio.webp \
  app/assets/characters/grant-id-original-studio.webp \
  app/assets/characters/gemma-id-original-studio.webp \
  app/assets/characters/amber-chibi-original-studio.webp \
  app/assets/characters/amber-chibi-hero-mark-v2.webp \
  app/assets/blog/amber-new-website-character-2026.webp \
  app/assets/fonts/Manrope-Variable.woff2 \
  app/assets/fonts/Fraunces-Variable.woff2 \
  app/assets/fonts/Fraunces-Italic-Variable.woff2 \
  app/assets/fonts/OFL-Manrope.txt \
  app/assets/fonts/OFL-Fraunces.txt; do
  test -s "$asset" || fail "missing local asset: $asset"
done

grep -F '@font-face' app/assets/css/amber-brand.css >/dev/null
grep -F '../fonts/Manrope-Variable.woff2' app/assets/css/amber-brand.css >/dev/null
grep -F 'stylesheet_link_tag("css/amber-brand.css")' src/views/layouts/application.ecr >/dev/null
grep -F 'javascript_importmap_tag(' src/views/layouts/application.ecr >/dev/null
grep -F '{"amber/site" => "js/amber-site.js"}' src/views/layouts/application.ecr >/dev/null
grep -F '<script type="module">import "amber/site";</script>' src/views/layouts/application.ecr >/dev/null
grep -F 'data-no-tracking="true"' src/views/layouts/application.ecr >/dev/null
grep -F 'We do not track you.' src/views/home/privacy.ecr >/dev/null
grep -F 'No analytics.' src/views/home/privacy.ecr >/dev/null
grep -F 'No application cookies.' src/views/home/privacy.ecr >/dev/null
grep -F "Cloudflare's <code>__cf_bm</code>" src/views/home/privacy.ecr >/dev/null
grep -F 'get "/privacy"' config/routes.cr >/dev/null

if rg -n -i 'googletagmanager|google-analytics|fonts\.googleapis|fonts\.gstatic|\bgtag\s*\(|\bdataLayer\b' \
  src/views app/assets/css/amber-brand.css app/assets/js/amber-site.js; then
  fail "analytics or externally hosted fonts remain in the active preview"
fi

if rg -n -i '<(script|img)[^>]+src="https?://|<link[^>]+rel="(stylesheet|icon|apple-touch-icon|preload|modulepreload)"[^>]+href="https?://|url\([^)]*https?://|@import[^;]*https?://' \
  src/views app/assets/css/amber-brand.css; then
  fail "a third-party runtime asset is referenced"
fi

if rg -n -i '^image:\s+https?://' blog/posts.yml; then
  fail "blog metadata still references a remote image"
fi

if rg -n 'amber-laptop-hero\.webp|amber-id\.webp|grant-id\.webp|gemma-id\.webp|amber-chibi\.webp' \
  src/views blog/posts.yml; then
  fail "the comparison-only character set is still referenced by the active preview"
fi

if rg -n 'document\.cookie|localStorage|sessionStorage|indexedDB' app/assets/js/amber-site.js; then
  fail "preview JavaScript persists visitor data"
fi

grep -F 'amber new my_app' src/views/home/index.ecr >/dev/null
grep -F 'web is the default' src/views/home/index.ecr >/dev/null
grep -F 'amber new field_app --type native' src/views/home/index.ecr >/dev/null
grep -F 'Framework beta.4 · Aug 12, 2026 · CLI 2.0.5 · Aug 12, 2026' src/views/home/index.ecr >/dev/null
grep -F 'image_tag("brand/crys-mascot.svg"' src/views/home/index.ecr >/dev/null
grep -F 'Crystal</strong> 1.20+ · latest stable recommended' src/views/home/index.ecr >/dev/null
grep -F 'amber_cli</strong> 2.0.5 · Aug 12' src/views/home/index.ecr >/dev/null
grep -F 'Linux native UI bindings remain frontier work' src/views/home/index.ecr >/dev/null
grep -F 'image_tag("characters/amber-hero-desk-transparent-higgsfield.webp"' src/views/home/index.ecr >/dev/null
grep -F 'asset_path("characters/amber-hero-desk-desktop-higgsfield.webp")' src/views/home/index.ecr >/dev/null
grep -F 'asset_path("characters/amber-hero-desk-mobile-higgsfield.webp")' src/views/home/index.ecr >/dev/null
if rg -n 'amber-frontier-higgsfield\.webp' src/views/home/index.ecr; then
  fail "the off-brand frontier image is still used by the application-type hover state"
fi
grep -F 'class="native-platform-map"' src/views/home/index.ecr >/dev/null
grep -F 'Your new idea' src/views/home/index.ecr >/dev/null
grep -F 'Ready to customize' src/views/home/index.ecr >/dev/null
grep -F 'amber generate controller Posts' src/views/home/index.ecr >/dev/null
grep -F 'Grant keeps the records straight.' src/views/home/index.ecr >/dev/null
grep -F 'Grant is the default V2 relational layer' src/views/home/index.ecr >/dev/null
grep -F '/docs/v2/guides/models/grant' src/views/home/index.ecr >/dev/null
grep -F 'image_tag("characters/amber-id-original-studio.webp"' src/views/home/characters.ecr >/dev/null
grep -F 'image_tag("characters/grant-id-original-studio.webp"' src/views/home/characters.ecr >/dev/null
grep -F 'image_tag("characters/gemma-id-original-studio.webp"' src/views/home/characters.ecr >/dev/null
grep -F 'image_tag("characters/amber-chibi-hero-mark-v2.webp"' src/views/docs/show.ecr >/dev/null
grep -F 'image_tag("brand/claude-icon-rounded.svg"' src/views/docs/show.ecr >/dev/null
grep -F 'image_tag("brand/openai-symbol-2025.svg"' src/views/docs/show.ecr >/dev/null

grep -F 'class="table-scroll"' src/services/markdown_preprocessor.cr >/dev/null
grep -F 'class="code-window code-window-' src/services/markdown_preprocessor.cr >/dev/null
grep -F '.docs-content table {' app/assets/css/amber-brand.css >/dev/null
grep -F 'display: table;' app/assets/css/amber-brand.css >/dev/null
grep -F '.docs-content pre code,' app/assets/css/amber-brand.css >/dev/null

grep -F 'data-terminal-demo' src/views/home/index.ecr >/dev/null
grep -F 'data-terminal-mode="typed"' src/views/home/index.ecr >/dev/null
grep -F 'data-terminal-url' src/views/home/index.ecr >/dev/null
grep -F 'class="demo-pointer"' src/views/home/index.ecr >/dev/null
grep -F 'terminalDemo.classList.add('"'"'is-browser-open'"'"')' app/assets/js/amber-site.js >/dev/null
grep -F "rootMargin: '0px 0px -50% 0px'" app/assets/js/amber-site.js >/dev/null
grep -F "terminalDemo.dataset.terminalState = 'waiting'" app/assets/js/amber-site.js >/dev/null
grep -F 'transition: left 760ms' app/assets/css/amber-brand.css >/dev/null
grep -F 'transition: opacity 760ms ease, transform 760ms' app/assets/css/amber-brand.css >/dev/null
grep -F 'data-crystal-field' src/views/home/index.ecr >/dev/null
grep -F 'data-application-choice="web"' src/views/home/index.ecr >/dev/null
grep -F 'data-application-choice="native"' src/views/home/index.ecr >/dev/null
grep -F 'visibleRatios' app/assets/js/amber-site.js >/dev/null
grep -F 'prefers-reduced-motion' app/assets/css/amber-brand.css >/dev/null
grep -F 'IntersectionObserver' app/assets/js/amber-site.js >/dev/null
grep -F 'data-open-docs-ai="claude"' src/views/docs/show.ecr >/dev/null
grep -F 'data-open-docs-ai="chatgpt"' src/views/docs/show.ecr >/dev/null
grep -F 'data-open-docs-ai="gemini"' src/views/docs/show.ecr >/dev/null
grep -F 'Copy + open Gemini' src/views/docs/show.ecr >/dev/null
grep -F "navigator.clipboard.writeText(prompt)" app/assets/js/amber-site.js >/dev/null
grep -F 'View Markdown' src/views/docs/show.ecr >/dev/null
grep -F 'View JSON' src/views/docs/show.ecr >/dev/null
grep -F 'code.language-crystal' app/assets/js/amber-site.js >/dev/null
grep -F '.token-keyword' app/assets/css/amber-brand.css >/dev/null
grep -F 'max-height: none;' app/assets/css/amber-brand.css >/dev/null
grep -F 'class="nav-group' src/views/docs/_sidebar.ecr >/dev/null
grep -F 'replacement-link' src/views/docs/_version_timeline.ecr >/dev/null
grep -F 'version_id: @version_id, page_path: source_path' src/controllers/docs_controller.cr >/dev/null
grep -F 'The CLI embeds its web scaffold in the executable.' docs/v2/guides/web-template/index.md >/dev/null
grep -F 'updating the CLI changes future projects' docs/v2/guides/web-template/index.md >/dev/null
grep -F 'Grant ORM, Micrate migrations, and SQLite' docs/v2/guides/web-template/index.md >/dev/null
grep -F 'This is a responsibility comparison, not a promise of API compatibility.' src/views/home/character.ecr >/dev/null
grep -F 'data-responsibility-select' src/views/home/character.ecr >/dev/null
grep -F 'data-translation-profile' src/views/home/character.ecr >/dev/null
grep -F 'updateTranslation' app/assets/js/amber-site.js >/dev/null
grep -F 'Active Storage' src/views/home/character.ecr >/dev/null
grep -F 'background jobs and their worker runtime remain a separate' src/views/home/character.ecr >/dev/null
grep -F 'Dependencies must earn their place' src/views/home/amber_way.ecr >/dev/null
grep -F 'respond_with do' src/controllers/home_controller.cr >/dev/null
grep -F 'html { render("amber_way.ecr") }' src/controllers/home_controller.cr >/dev/null
grep -F 'json { page.to_json }' src/controllers/home_controller.cr >/dev/null
grep -F 'request.path.ends_with?(".json")' src/controllers/home_controller.cr >/dev/null
grep -F 'One action.' src/views/home/amber_way.ecr >/dev/null
grep -F 'The filesystem is part of the documentation.' src/views/home/amber_way.ecr >/dev/null
grep -F 'Views should look like the document they create.' src/views/home/amber_way.ecr >/dev/null
grep -F 'Use the web platform before adding a toolchain.' src/views/home/amber_way.ecr >/dev/null
grep -F '21,795' src/views/home/amber_way.ecr >/dev/null
grep -F 'whole HTTP requests per second' src/views/home/amber_way.ecr >/dev/null
grep -F '21,795 requests/second' docs/v2/guides/performance.md >/dev/null
grep -F 'millions of lookups per second' docs/v2/guides/performance.md >/dev/null
grep -F '"median": 21795.0' public/benchmarks/amber-v2-round22-summary.json >/dev/null
grep -F '5,906.72' src/views/home/performance.ecr >/dev/null
grep -F 'Source data: website and WebSockets (JSON)' src/views/home/performance.ecr >/dev/null
grep -F 'Supported web path' docs/v2/guides/assets/index.md >/dev/null
grep -F 'Try the direct upgrade first' docs/v2/migration-guide/index.md >/dev/null
grep -F 'get "/releases"' config/routes.cr >/dev/null
grep -F 'amber-new-website-character-2026.webp' blog/posts.yml >/dev/null
grep -F 'class="post-cover"' src/views/blog/show.ecr >/dev/null
grep -F 'browser-native JavaScript modules' docs/v2/guides/assets/import-maps.md >/dev/null
grep -F 'They do not require Node.js, npm, or a bundler.' docs/v2/guides/assets/import-maps.md >/dev/null

if rg -n 'Solid Queue|Solid Cache|stored queue records' src/views/home design/v2-preview/EXPERIENCE_BRIEF.md; then
  fail "Grant still claims ownership of a Rails cache or background-job system"
fi

echo "Amber V2 preview release-boundary, privacy, asset, template, table, code-window, and interaction checks passed"
