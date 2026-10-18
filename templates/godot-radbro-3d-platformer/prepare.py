#!/usr/bin/env python3
"""Copy the released pack after its registered checks pass."""
import json, shutil, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from catalog import verify
verify()
item = json.loads(Path(__file__).with_name('template.json').read_text())
for pack, files in item['assetFiles'].items():
    for relative in files:
        source = ROOT / 'assets' / pack / relative
        target = Path(__file__).parent / 'assets' / pack / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
print('Prepared ' + item['id'])
