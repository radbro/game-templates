#!/usr/bin/env python3
"""Prepare released Radcat files and audit immutable upstream assets."""
import hashlib
import json
import shutil
from pathlib import Path

PROJECT = Path(__file__).resolve().parent
REPO = PROJECT.parents[1]

def prepare():
    upstream = json.loads((PROJECT / 'UPSTREAM.json').read_text())
    for item in upstream['files']:
        path = PROJECT / item['path']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], path
    source = REPO / 'assets/radcat-motion-v2'
    if not source.exists():
        audit = json.loads((PROJECT / 'ASSET_AUDIT.json').read_text())
        for item in audit['files']:
            path = PROJECT / item['path']
            assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], path
        print('Audited the prepared source ZIP assets. No network access was used.')
        return
    # The root catalog verifies hashes for all released pack files.
    import sys
    sys.path.insert(0, str(REPO / 'scripts'))
    from catalog import verify
    verify()
    target = PROJECT / 'assets/radcat-motion-v2'
    target.mkdir(parents=True, exist_ok=True)
    files = ['pack.json', 'LICENSE.txt', 'SPRITE-PERMISSION.txt']
    for clip in ['idle', 'walk']:
        files += [f'sprites/{clip}-sheet.png', f'sprites/{clip}-sheet.json']
    for relative in files:
        out = target / relative
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / relative, out)
    print('Prepared released Radcat sprites. Audited pinned Ourcade art hashes.')

if __name__ == '__main__':
    prepare()
