#!/usr/bin/env python3
"""Copy only hash-verified, published Radcat sprites into this project."""
import json
import shutil
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from catalog import verify

verify()
entry = json.loads((PROJECT / 'template.json').read_text())
for pack_id, files in entry['assetFiles'].items():
    for relative in files:
        source = ROOT / 'assets' / pack_id / relative
        target = PROJECT / 'assets' / pack_id / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
print('Prepared published Radcat assets. No private review art was copied.')
