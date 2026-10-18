#!/usr/bin/env python3
"""Verify imported source hashes and keep the upstream artwork unchanged."""
import argparse
import hashlib
import subprocess
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--git-index', action='store_true', help='Require every audited source file and its exact bytes in the Git index.')
args = parser.parse_args()
project = Path(__file__).resolve().parents[1]
repository = project.parents[1]
check_index = args.git_index or (repository / '.git').exists()
tracked = set()
if check_index:
    tracked = set(subprocess.check_output(['git', 'ls-files'], cwd=repository, text=True).splitlines())
audit = json.loads((project / 'SOURCE_AUDIT.json').read_text())
for item in audit['files']:
    path = project / item['path']
    assert path.is_file(), item['path']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], item['path']
    if check_index:
        relative = path.relative_to(repository).as_posix()
        assert relative in tracked, f"Audited file is absent from the Git index: {relative}"
        index_bytes = subprocess.check_output(['git', 'show', ':' + relative], cwd=repository)
        assert hashlib.sha256(index_bytes).hexdigest() == item['sha256'], f"Git index bytes differ: {relative}"
    if path.suffix == '.png':
        assert not item['changed'], f"Upstream art was changed: {item['path']}"
for prefix in ['', 'top-down-shooter-core/']:
    for notice in ['LICENSE.txt', 'LICENSE_ASSETS.txt']:
        assert (project / prefix / notice).is_file()
config = (project / 'export_presets.cfg').read_text()
for alias in ['.local-assets', 'local-assets', '.review-assets', 'review-assets']:
    assert alias + '/*' in config
    assert alias + '/**' in config
assert 'variant/thread_support=false' in config
assert 'gl_compatibility' in (project / 'project.godot').read_text()
print(f"Source audit passed: {len(audit['files'])} imported files; upstream PNG bytes preserved; Git index checked: {check_index}.")
