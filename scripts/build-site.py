#!/usr/bin/env python3
"""Package the sources and build a static demo site from a completed Godot export."""
import shutil
from catalog import ROOT
from package import package, zip_folder
from patch_godot_web import patch


def build():
    exported = ROOT / 'build/godot-radcat-relay'
    for name in ['index.html', 'index.js', 'index.wasm', 'index.pck']:
        if not (exported / name).is_file():
            raise ValueError(f'Export Godot first. Missing {name}.')
    package()
    site = ROOT / 'dist/site'
    if site.exists():
        shutil.rmtree(site)
    site.mkdir(parents=True)
    shutil.copy2(ROOT / 'site.html', site / 'index.html')
    shutil.copytree(ROOT / 'dist/phaser-radcat-courier', site / 'phaser-radcat-courier')
    shutil.copytree(exported, site / 'godot-radcat-relay')
    patch(site / 'godot-radcat-relay')
    for name in ['GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
        shutil.copy2(ROOT / 'licenses' / name, site / name)
        shutil.copy2(ROOT / 'licenses' / name, site / 'godot-radcat-relay' / name)
    shutil.copy2(ROOT / 'CREDITS.md', site / 'godot-radcat-relay/CREDITS.md')
    shutil.copy2(ROOT / 'LICENSE', site / 'godot-radcat-relay/LICENSE.code.txt')
    for pack_id in ['radcat-motion-v2', 'radcat-playground']:
        destination = site / 'godot-radcat-relay/assets' / pack_id
        destination.mkdir(parents=True, exist_ok=True)
        for name in ['LICENSE.txt', 'pack.json']:
            shutil.copy2(ROOT / 'assets' / pack_id / name, destination / name)
    for path in (ROOT / 'dist').glob('*-source.zip'):
        shutil.copy2(path, site / path.name)
    output = site / 'godot-radcat-relay-web.zip'
    zip_folder(site / 'godot-radcat-relay', output)
    shutil.copy2(output, ROOT / 'dist' / output.name)
    (site / '.nojekyll').touch()
    print(f'Built {site}')


if __name__ == '__main__':
    build()
