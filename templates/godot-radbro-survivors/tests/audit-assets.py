#!/usr/bin/env python3
"""Check pinned source, public assets, review isolation, and optional release PCK."""
import argparse
import hashlib
import json
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]


def audit(pck=None):
    upstream = json.loads((PROJECT / 'UPSTREAM.json').read_text())
    assert upstream['upstreamAssetsIncluded'] is False
    for record in upstream['sourceFiles'].values():
        data = (PROJECT / record['snapshot']).read_bytes()
        assert hashlib.sha256(data).hexdigest() == record['sha256']
    allowed = {'.png', '.json', '.txt'}
    public = PROJECT / 'assets'
    for path in public.rglob('*'):
        if path.is_file() and path.suffix != '.import':
            assert path.relative_to(public).parts[0] == 'radcat-motion-v2', path
            assert path.suffix in allowed, path
    preset = (PROJECT / 'export_presets.cfg').read_text()
    assert '.local-assets/*' in preset and 'tests/*' in preset
    assert 'variant/thread_support=false' in preset
    if pck:
        packed = Path(pck).read_bytes()
        assert b'.local-assets' not in packed
        assert b'sprites/base/' not in packed and b'sprites/items/' not in packed
        assert b'pack.json' in packed and b'idle-sheet' in packed
    print('Pinned source hashes, default asset paths, export exclusions, and optional PCK audit passed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pck', type=Path)
    audit(parser.parse_args().pck)
