#!/usr/bin/env python3
"""Check pinned source, public assets, review isolation, and optional release PCK."""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]


def audit(pck=None):
    upstream = json.loads((PROJECT / 'UPSTREAM.json').read_text())
    assert upstream['upstreamAssetsIncluded'] is False
    for record in upstream['sourceFiles'].values():
        data = (PROJECT / record['snapshot']).read_bytes()
        assert hashlib.sha256(data).hexdigest() == record['sha256']
    allowed = {'.png', '.json', '.txt', '.md', '.aseprite', '.lua'}
    public = PROJECT / 'assets'
    for path in public.rglob('*'):
        if path.is_file() and path.suffix != '.import':
            assert path.relative_to(public).parts[0] in {'radcat-motion-v2', 'radbro-survivors-dual-style-v1'}, path
            assert path.suffix in allowed, path
    preset = (PROJECT / 'export_presets.cfg').read_text()
    assert '.local-assets/*' in preset and 'tests/*' in preset
    assert 'variant/thread_support=false' in preset
    if pck:
        packed = Path(pck).read_bytes()
        assert b'.local-assets' not in packed
        assert b'radbro-survivors-dual-style-v1/calibration.json' in packed
        assert b'radbro-survivors-dual-style-v1/publication.json' in packed
        assert b'pack.json' in packed and b'idle-sheet' in packed
        # Mount the PCK in an empty project. Provenance text can mention editor
        # paths even when those files are correctly absent from the pack.
        godot = os.environ.get('GODOT') or shutil.which('godot') or '/Applications/Godot.app/Contents/MacOS/Godot'
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            (project / 'project.godot').write_text('config_version=5\n')
            shutil.copy2(PROJECT / 'tests/export-audit.gd', project / 'audit.gd')
            result = subprocess.run([godot, '--headless', '--path', str(project), '--script', 'res://audit.gd', '--', str(Path(pck).resolve())], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
            if result.returncode or re.search(r'(^|\n)(?:SCRIPT )?ERROR:', result.stdout):
                raise ValueError(result.stdout)
            assert 'SURVIVORS_EXPORT_AUDIT PASS' in result.stdout
            print(result.stdout.strip())
    print('Pinned source hashes, released style paths, export exclusions, and optional PCK audit passed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pck', type=Path)
    audit(parser.parse_args().pck)
