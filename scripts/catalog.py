#!/usr/bin/env python3
"""Check file identity. Use --write only after reviewing an asset change."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'assets/catalog.json'


def snapshot():
    packs = []
    for folder in sorted((ROOT / 'assets').iterdir()):
        if not folder.is_dir():
            continue
        metadata = json.loads((folder / 'pack.json').read_text())
        if metadata['id'] != folder.name or not (folder / 'LICENSE.txt').is_file():
            raise ValueError(f'Invalid pack ID or missing license: {folder.name}')
        files = []
        for path in sorted(folder.rglob('*')):
            if path.is_symlink():
                raise ValueError(f'Pack contains a symlink: {path}')
            if path.is_file():
                data = path.read_bytes()
                files.append({'path': path.relative_to(ROOT).as_posix(), 'bytes': len(data),
                              'sha256': hashlib.sha256(data).hexdigest()})
        if 'runtimeSha256' in metadata:
            model = folder / f'{folder.name}.glb'
            if hashlib.sha256(model.read_bytes()).hexdigest() != metadata['runtimeSha256']:
                raise ValueError(f'Published model changed: {model.name}')
        packs.append({**metadata, 'files': files})
    return {'schemaVersion': 1, 'packs': packs}


def verify():
    actual = snapshot()
    if actual != json.loads(CATALOG.read_text()):
        raise ValueError('Asset catalog mismatch. Review the source, license, and file changes.')
    return actual


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.write:
        CATALOG.write_text(json.dumps(snapshot(), indent=2) + '\n')
        print('Wrote asset catalog. Review this diff before release.')
    else:
        catalog = verify()
        print(f"Verified {len(catalog['packs'])} packs and all file hashes.")
