#!/usr/bin/env python3
"""Install the pinned official Linux editor and web export templates for CI."""
import hashlib
import os
import tempfile
import urllib.request
import zipfile
from pathlib import Path

VERSION = '4.6.2-stable'
FILES = {
    'Godot_v4.6.2-stable_linux.x86_64.zip': '30e6b6d141f0cd5bebd629ad1d0ef1324e60091bb20662d026b402ba58c59937',
    'Godot_v4.6.2-stable_export_templates.tpz': '942366dc4e27e7686a99da4d3cfb1b8ae8d3eb9444f6d8217eef16245b599ef2',
}


def install():
    binary = Path.home() / '.local/bin/godot'
    templates = Path.home() / '.local/share/godot/export_templates/4.6.2.stable'
    binary.parent.mkdir(parents=True, exist_ok=True)
    templates.mkdir(parents=True, exist_ok=True)
    for filename, expected in FILES.items():
        if filename.endswith('.tpz') and all((templates / name).is_file() for name in ['version.txt', 'web_nothreads_release.zip', 'web_nothreads_debug.zip']):
            print('Using cached web templates.')
            continue
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / filename
            digest = hashlib.sha256()
            url = f'https://github.com/godotengine/godot/releases/download/{VERSION}/{filename}'
            print(f'Downloading {filename}', flush=True)
            with urllib.request.urlopen(url, timeout=120) as response, output.open('wb') as destination:
                while chunk := response.read(1024 * 1024):
                    digest.update(chunk)
                    destination.write(chunk)
            if digest.hexdigest() != expected:
                raise ValueError(f'Official release hash mismatch: {filename}')
            with zipfile.ZipFile(output) as archive:
                if filename.endswith('.tpz'):
                    for name in ['version.txt', 'web_nothreads_release.zip', 'web_nothreads_debug.zip']:
                        (templates / name).write_bytes(archive.read(f'templates/{name}'))
                else:
                    binary.write_bytes(archive.read('Godot_v4.6.2-stable_linux.x86_64'))
                    binary.chmod(0o755)
    print(f'Installed {binary}')
    if 'GITHUB_PATH' in os.environ:
        with open(os.environ['GITHUB_PATH'], 'a') as file:
            file.write(str(binary.parent) + '\n')


if __name__ == '__main__':
    install()
