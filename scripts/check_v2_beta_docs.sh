#!/usr/bin/env bash
set -euo pipefail

files=(
  docs/v2/index.md
  docs/v2/beta-support.md
  docs/v2/getting-started/index.md
  docs/v2/getting-started/installation.md
  docs/v2/cli/index.md
  docs/v2/cli/new.md
  docs/v2/cli/generate.md
  docs/v2/cli/watch.md
  docs/v2/guides/web-template/index.md
  docs/v2/guides/pet-tracker/index.md
  docs/v2/guides/ai-assistants/index.md
  docs/v2/guides/native-preview/index.md
  blog/2026/07/31/amber-2-beta-2.md
  blog/2026/08/10/amber-v2-public-beta.md
)

for file in "${files[@]}"; do
  test -s "$file"
done

forbidden='crimson-knight/(amber|gemma)|amberframework/amber-cli|brew tap crimson-knight|brew install (amber-v2|amber-cli)|template: slang|\.slang|branch: (master|v2-dev)|version: ~> 2\.0\.0|Crystal 1\.10'
if grep -Ein "$forbidden" "${files[@]}"; then
  echo "V2 beta onboarding docs contain a stale install, dependency, or template instruction" >&2
  exit 1
fi

grep -F 'brew install amberframework/amber_cli/amber_cli' docs/v2/getting-started/installation.md
grep -F 'amber new my_app' docs/v2/index.md
grep -F 'not release-gated with the V2 web beta' docs/v2/guides/native-preview/index.md
grep -F '2.0.0-beta.3' docs/v2/cli/new.md
grep -F 'Amber CLI' docs/v2/cli/index.md
grep -F '2.0.4' docs/v2/getting-started/installation.md
grep -F 'use the latest stable Crystal release' docs/v2/getting-started/installation.md

if rg -n 'brew tap amberframework/amber_cli|brew (install|upgrade|uninstall) amber_cli' "${files[@]}"; then
  echo "V2 beta onboarding docs must use the fully qualified trusted formula" >&2
  exit 1
fi

if rg -n '^```ruby$' docs; then
  echo "Documentation code fences must identify Crystal examples as Crystal" >&2
  exit 1
fi

grep -F 'Build a Pet Tracker' docs/v2/guides/pet-tracker/index.md
grep -F 'Download the Amber V2 documentation knowledge bundle' docs/v2/guides/ai-assistants/index.md

if grep -Eq '^- cli/(index|new|generate|watch)\.md$' docs/v2/_deleted.yml; then
  echo "Published V2 CLI guides must not be listed as deleted" >&2
  exit 1
fi

echo "Amber V2 beta onboarding documentation checks passed"
