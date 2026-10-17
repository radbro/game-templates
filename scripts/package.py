#!/usr/bin/env python3
"""Create portable source ZIPs. Godot also needs a web export to play in a browser."""
import hashlib
import json
import shutil
import zipfile
from pathlib import Path
from catalog import ROOT
from prepare import prepare, templates

DIST = ROOT / 'dist'
IGNORED = {'.omx', '.godot', 'evidence', '__pycache__'}


def zip_folder(folder, output):
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(folder.rglob('*')):
            if not path.is_file() or any(part in IGNORED for part in path.relative_to(folder).parts):
                continue
            if path.suffix in {'.import', '.uid', '.pyc'} or path.name == 'progress.md':
                continue
            info = zipfile.ZipInfo(path.relative_to(folder).as_posix(), date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())


def package():
    prepare()
    DIST.mkdir(exist_ok=True)
    artifacts = []
    for item in templates():
        folder = DIST / item['id']
        if folder.exists():
            shutil.rmtree(folder)
        shutil.copytree(ROOT / item['path'], folder,
                        ignore=shutil.ignore_patterns('.omx', '.godot', '*.import', 'evidence', '__pycache__', 'progress.md'))
        shutil.copy2(ROOT / 'LICENSE', folder / 'LICENSE.code.txt')
        shutil.copy2(ROOT / 'CREDITS.md', folder / 'CREDITS.md')
        if item['id'].startswith('godot-'):
            shutil.copytree(ROOT / 'licenses', folder / 'licenses', dirs_exist_ok=True)
        output = DIST / f"{item['id']}-source.zip"
        zip_folder(folder, output)
        artifacts.append({'file': output.name, 'bytes': output.stat().st_size,
                          'sha256': hashlib.sha256(output.read_bytes()).hexdigest()})
    (DIST / 'downloads.json').write_text(json.dumps(artifacts, indent=2) + '\n')
    print(json.dumps(artifacts, indent=2))


if __name__ == '__main__':
    package()
