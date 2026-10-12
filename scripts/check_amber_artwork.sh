#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
import hashlib

retired_hash = 'f4e77bae6ca59765fc6cfd47bbb6053ba6f70efdde11ce7909188560edc1927f'
canonical_hash = '6bc94885aa071d061333d81c9676edcb181067c965aae3341eb72c1188824a5a'
canonical = Path('app/assets/characters/amber-hero-desk-transparent-higgsfield.webp')
if not canonical.is_file() or hashlib.sha256(canonical.read_bytes()).hexdigest() != canonical_hash:
    raise SystemExit('Amber artwork gate: review the canonical workbench artwork identity.')
failures = []
checked = 0
for root in [Path('app/assets'), Path('public/assets')]:
    if root.exists():
        for asset in root.rglob('*'):
            if asset.is_file():
                checked += 1
                if asset.name.startswith('amber-frontier-higgsfield') or hashlib.sha256(asset.read_bytes()).hexdigest() == retired_hash:
                    failures.append(str(asset))
if failures:
    raise SystemExit('Amber artwork gate: remove retired deliverable assets:\n' + '\n'.join(failures))
print(f'Amber artwork gate passed: canonical identity verified; {checked} deliverable files checked.')
PY
