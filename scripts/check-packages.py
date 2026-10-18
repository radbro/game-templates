#!/usr/bin/env python3
"""Check portable ZIP entries, licenses, and unpacked source identity."""
from zipfile import ZipFile
from catalog import ROOT
from prepare import templates
from package import IGNORED


def check_zip(path, entry, asset_ids, godot=False):
    with ZipFile(path) as archive:
        names = archive.namelist()
        if entry not in names or 'LICENSE.code.txt' not in names or 'CREDITS.md' not in names:
            raise ValueError(f'Missing entry or code notice: {path.name}')
        for name in names:
            parts = name.split('/')
            if name.startswith('/') or '..' in parts or any(p in IGNORED for p in parts):
                raise ValueError(f'Invalid or local-only ZIP entry: {name}')
        for pack_id in asset_ids:
            name = f'assets/{pack_id}/LICENSE.txt'
            if archive.read(name) != (ROOT / 'assets' / pack_id / 'LICENSE.txt').read_bytes():
                raise ValueError(f'Missing or changed asset notice: {pack_id}')
        if 'phaser-' in path.name and 'assets/radcat-motion-v2/SPRITE-PERMISSION.txt' not in names:
            raise ValueError('Missing sprite permission notice.')
        if godot:
            for name in ['GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
                target = name if entry == 'index.html' else f'licenses/{name}'
                if archive.read(target) != (ROOT / 'licenses' / name).read_bytes():
                    raise ValueError(f'Missing or changed engine notice: {name}')
    print(f'Checked {path.name}: {len(names)} files, entry, notices, and paths.')


for item in templates():
    path = ROOT / 'dist' / f"{item['id']}-source.zip"
    check_zip(path, item['entry'], item['assets'], item['id'].startswith('godot-'))
for item in templates():
    web = ROOT / 'dist' / f"{item['id']}-web.zip"
    check_zip(web, 'index.html', item['assets'], item['id'].startswith('godot-'))
