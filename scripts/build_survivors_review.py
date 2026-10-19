#!/usr/bin/env python3
"""Build the local Survivors art comparison without changing release artifacts."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

from catalog import ROOT
from package import IGNORED
from patch_godot_web import patch
from prepare import prepare

TEMPLATE = 'godot-radbro-survivors'


def read_json(path):
    return json.loads(path.read_text())


def checked_path(root, relative):
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        raise ValueError(f'Invalid review source: {relative}')
    return path


def review_files(study):
    """Verify the study record, then its hero copies and selected enemy kits."""
    manifest = read_json(study / 'manifest.json')
    if not manifest.get('reviewOnly') or manifest.get('published'):
        raise ValueError('Expected an unpublished local art study.')
    records = {entry['path']: entry for entry in manifest['files']}

    def verify(relative, expected=None):
        source = checked_path(study, relative)
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        if relative not in records or digest != records[relative]['sha256']:
            raise ValueError(f'Study hash mismatch: {relative}')
        if expected is not None and digest != expected:
            raise ValueError(f'Source hash mismatch: {relative}')
        return source, digest

    calibration, _ = verify('review/source-hashes.json')
    kit_hashes, _ = verify('review/kit-hashes.json')
    files = []
    for entry in read_json(calibration)['files']:
        relative = entry['copy']
        parts = Path(relative).parts
        if len(parts) < 3 or '..' in parts or parts[0] != 'assets' or parts[1] not in {'native-hero', 'illustrated-hero'}:
            raise ValueError(f'Invalid hero destination: {relative}')
        source, digest = verify('review/' + relative, entry['sha256'])
        files.append((source, Path(*parts[1:]), digest))
    for entry in read_json(kit_hashes)['files']:
        parts = Path(entry['path']).parts
        if len(parts) != 2 or parts[0] not in {'native', 'illustrated'}:
            raise ValueError('Invalid kit destination.')
        source, digest = verify(entry['path'], entry['sha256'])
        files.append((source, Path(parts[0] + '-kit') / parts[1], digest))
    files.append((calibration, Path('calibration.json'), verify('review/source-hashes.json')[1]))
    return files


def stage_project(study, project):
    files = review_files(study)  # Validate every file before creating the project.
    if project.exists():
        shutil.rmtree(project)
    shutil.copytree(ROOT / 'templates' / TEMPLATE, project,
                    ignore=shutil.ignore_patterns(*IGNORED, 'review-art', '*.import', '*.uid'))
    receipt = {'reviewOnly': True, 'published': False, 'source': str(study), 'files': []}
    for source, relative, digest in files:
        target = project / 'review-art' / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        receipt['files'].append({'path': relative.as_posix(), 'sha256': digest})
    (project / 'review-art/import-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    preset = (project / 'export_presets.cfg').read_text()
    preset = preset.replace('name="Web"', 'name="Web"\ncustom_features="art_review"', 1)
    preset = preset.replace('include_filter="', 'include_filter="review-art/**,', 1)
    # Only this isolated build may include draft assets.
    preset = preset.replace('review-art/*,review-art/**,', '')
    (project / 'export_presets.cfg').write_text(preset)
    return receipt


def run_godot(godot, project, arguments, log):
    result = subprocess.run([godot, '--headless', '--path', str(project), *arguments],
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    log.write_text(result.stdout)
    if result.returncode or re.search(r'(^|\n)(?:SCRIPT )?ERROR:', result.stdout):
        raise RuntimeError(f'Godot failed. Read {log}.')


def build(study, godot, preview_site=False):
    prepare(TEMPLATE)
    work = ROOT / 'build/local-review'
    work.mkdir(parents=True, exist_ok=True)
    project = work / 'survivors-project'
    output = work / TEMPLATE
    receipt = stage_project(study.resolve(), project)
    output.mkdir(exist_ok=True)
    run_godot(godot, project, ['--editor', '--import'], work / 'import.log')
    run_godot(godot, project, ['--script', 'res://tests/smoke.gd', '--', '--art-review'], work / 'smoke.log')
    run_godot(godot, project, ['--script', 'res://tests/art-styles.gd', '--', '--art-review'], work / 'art-styles.log')
    run_godot(godot, project, ['--export-release', 'Web', str(output / 'index.html')], work / 'export.log')
    patch(output)
    (output / 'LOCAL_ART_REVIEW.json').write_text(json.dumps(receipt, indent=2) + '\n')
    for name in ['GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
        shutil.copy2(ROOT / 'licenses' / name, output / name)
    if preview_site:
        destination = ROOT / 'dist/site' / TEMPLATE
        if not (destination / 'index.html').is_file():
            raise ValueError('Build the public demo site before adding a local preview.')
        # Overlay the local served game only. Download ZIPs and release builds stay intact.
        shutil.copytree(output, destination, dirs_exist_ok=True)
        print(f'Local served comparison: {destination}')
    print(f'Local review build: {output}. No release ZIP was changed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--study', type=Path, required=True, help='Radclaw dual-style run folder')
    parser.add_argument('--godot', default=shutil.which('godot') or '/Applications/Godot.app/Contents/MacOS/Godot')
    parser.add_argument('--preview-site', action='store_true', help='Overlay only the local dist/site game')
    args = parser.parse_args()
    build(args.study, args.godot, args.preview_site)
