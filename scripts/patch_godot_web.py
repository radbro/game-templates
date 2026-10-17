#!/usr/bin/env python3
"""Guard Godot 4.6.2's PWA query in an opaque-origin game iframe."""
import hashlib
import json
from pathlib import Path

# The pinned engine queries this API even when PWA export is disabled.
# Its outer feature check succeeds in Chrome's opaque sandbox, but the getter throws.
# Keep all engine behavior except that unsupported API query.
ORIGINAL = 'function _godot_js_pwa_cb(p_update_cb){if("serviceWorker"in navigator){'
PATCHED = 'function _godot_js_pwa_cb(p_update_cb){if(window.origin!=="null"&&"serviceWorker"in navigator){'


def patch_text(source):
    if source.count(ORIGINAL) != 1:
        raise ValueError('Godot PWA guard changed. Review the engine export before release.')
    return source.replace(ORIGINAL, PATCHED, 1)


def patch(folder):
    loader = Path(folder) / 'index.js'
    original = loader.read_text()
    changed = patch_text(original)
    loader.write_text(changed)
    record = {
        'engine': 'Godot 4.6.2',
        'file': 'index.js',
        'reason': 'Skip the unavailable service-worker API in an opaque-origin sandbox.',
        'source': 'https://github.com/godotengine/godot/blob/4.6.2-stable/platform/web/js/libs/library_godot_os.js',
        'originalSha256': hashlib.sha256(original.encode()).hexdigest(),
        'patchedSha256': hashlib.sha256(changed.encode()).hexdigest(),
    }
    (Path(folder) / 'godot-runtime-patch.json').write_text(json.dumps(record, indent=2) + '\n')
    print('Applied the pinned Godot opaque-origin PWA guard.')
