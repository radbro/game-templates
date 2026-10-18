#!/usr/bin/env python3
"""Copy the published default pack. Private art is an explicit native-only option."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

PROJECT = Path(__file__).resolve().parent
ROOT = PROJECT.parents[1]
FILES = ['LICENSE.txt', 'SPRITE-PERMISSION.txt', 'pack.json', 'sprites/animation-manifest.json', 'sprites/idle-sheet.json', 'sprites/idle-sheet.png', 'sprites/walk-sheet.json', 'sprites/walk-sheet.png']


def prepare():
    target = PROJECT / 'assets/radcat-motion-v2'
    source = ROOT / 'assets/radcat-motion-v2'
    if source.exists():
        import sys
        sys.path.insert(0, str(ROOT / 'scripts'))
        from catalog import verify
        verify()
        for name in FILES:
            destination = target / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source / name, destination)
    else:
        for name in FILES:
            if not (target / name).is_file():
                raise ValueError(f'Missing packaged default asset: {name}')
    return target


def import_review(source):
    pack = json.loads((source / 'pack.json').read_text())
    manifest = json.loads((source / 'manifest.json').read_text())
    if not pack.get('reviewOnly') or pack.get('published'):
        raise ValueError('This option is only for the named local review pack.')
    parts = pack['base']['parts'] + [part for item in pack['items'] for part in item['parts']]
    files = ['pack.json'] + sorted({part['image'] for part in parts})
    target = PROJECT / '.local-assets/radbro'
    receipt = {'source': str(source), 'rig': pack['rig'], 'reviewOnly': True, 'published': False, 'files': {}}
    for name in files:
        data = (source / name).read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if name not in manifest['files'] or digest != manifest['files'][name]['sha256']:
            raise ValueError(f'Hash mismatch: {name}')
        destination = target / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        receipt['files'][name] = digest
    (target / 'import-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(f'Imported private native review: {pack["rig"]}; {len(files)} hash-checked files')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--review-pack', type=Path)
    args = parser.parse_args()
    prepare()
    if args.review_pack:
        import_review(args.review_pack.resolve())
    print('Prepared Radbro Survivors default assets.')
