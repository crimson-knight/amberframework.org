#!/usr/bin/env bash
set -euo pipefail

files=(
  blog/2026/07/31/amber-2-beta-2.md
  blog/2026/08/10/amber-v2-public-beta.md
)

while IFS= read -r file; do
  files+=("$file")
done < <(find docs/v2 -type f -name '*.md' -print | sort)

for file in "${files[@]}"; do
  test -s "$file"
done

forbidden='crimson-knight/(amber|gemma)|amberframework/amber-cli|brew tap crimson-knight|brew install (amber-v2|amber-cli)|template: slang|branch: (master|v2-dev)|version: ~> 2\.0\.0|Crystal 1\.10'
if rg -n -i -e "$forbidden" "${files[@]}"; then
  echo "V2 beta onboarding docs contain a stale install, dependency, or template instruction" >&2
  exit 1
fi

rg -F 'brew install amberframework/amber_cli/amber_cli' docs/v2/getting-started/installation.md
rg -F 'amber new my_app' docs/v2/index.md
rg -F 'not release-gated with the V2 web beta' docs/v2/guides/native-preview/index.md
rg -F '2.0.0-beta.5' docs/v2/cli/new.md
rg -F 'Amber CLI' docs/v2/cli/index.md
rg -F '2.0.6' docs/v2/getting-started/installation.md
rg -F 'asset_pipeline `0.37.0`' docs/v2/guides/assets/index.md
rg -F 'amber assets check' docs/v2/getting-started/index.md
rg -F 'use the latest stable Crystal release' docs/v2/getting-started/installation.md
rg -F '| ARM64 Linux | Verified on GitHub-hosted ARM64 Linux | `linux-arm64` archive | Yes |' docs/v2/beta-support.md
rg -F '| Windows x86-64 | Verified in GitHub Actions | None | No |' docs/v2/beta-support.md

if rg -n 'brew tap amberframework/amber_cli|brew (install|upgrade|uninstall) amber_cli' "${files[@]}"; then
  echo "V2 beta onboarding docs must use the fully qualified trusted formula" >&2
  exit 1
fi

if rg -n '^```ruby$' docs; then
  echo "Documentation code fences must identify Crystal examples as Crystal" >&2
  exit 1
fi

rg -F 'Build a Pet Tracker' docs/v2/guides/pet-tracker/index.md
rg -F 'Download the Amber V2 documentation knowledge bundle' docs/v2/guides/ai-assistants/index.md

if rg -q '^- cli/(index|new|generate|watch)\.md$' docs/v2/_deleted.yml; then
  echo "Published V2 CLI guides must not be listed as deleted" >&2
  exit 1
fi

# DocsScanner overlays V2 pages on inherited V1 content. This focused spec is
# the source of truth for the complete resolved corpus, including pages that do
# not physically live under docs/v2.
CRYSTAL_CACHE_DIR="${CRYSTAL_CACHE_DIR:-/tmp/amberframework_site_crystal_cache}" \
  crystal spec spec/services/docs_scanner_spec.cr

echo "Amber V2 beta onboarding documentation checks passed"
