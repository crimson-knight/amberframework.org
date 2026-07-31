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
  blog/2026/07/31/amber-2-beta-2.md
)

for file in "${files[@]}"; do
  test -s "$file"
done

forbidden='crimson-knight/(amber|grant|gemma)|amberframework/amber-cli|brew tap crimson-knight|brew install amber-v2|brew install amber-cli|template: slang|\.slang|branch: (master|v2-dev)|version: ~> 2\.0\.0|Crystal 1\.10'
if grep -Ein "$forbidden" "${files[@]}"; then
  echo "V2 beta onboarding docs contain a stale install, dependency, or template instruction" >&2
  exit 1
fi

grep -F 'brew tap amberframework/amber_cli' docs/v2/getting-started/installation.md
grep -F 'brew install amber_cli' docs/v2/getting-started/installation.md
grep -F '2.0.0-beta.2' docs/v2/cli/new.md
grep -F 'Amber CLI' docs/v2/cli/index.md
grep -F '2.0.2' docs/v2/getting-started/installation.md

echo "Amber V2 beta onboarding documentation checks passed"
