#!/usr/bin/env python3
"""Verify imported source hashes and keep the upstream artwork unchanged."""
import hashlib
import json
from pathlib import Path

project = Path(__file__).resolve().parents[1]
audit = json.loads((project / 'SOURCE_AUDIT.json').read_text())
for item in audit['files']:
    path = project / item['path']
    assert path.is_file(), item['path']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], item['path']
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
print(f"Source audit passed: {len(audit['files'])} imported files; upstream PNG bytes preserved.")
