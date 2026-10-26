import hashlib
import importlib.util
import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import catalog


class AssetTests(unittest.TestCase):
    def test_survivors_release_keeps_both_styles_and_their_source_bytes(self):
        pack_id = 'radbro-survivors-dual-style-v1'
        folder = ROOT / 'assets' / pack_id
        approval = json.loads((folder / 'publication.json').read_text())
        self.assertTrue(approval['approved'])
        self.assertIn('source template', approval['scope'])
        provenance = json.loads((folder / 'provenance.json').read_text())
        self.assertEqual(provenance['runtimeFileCount'], 60)
        self.assertFalse(provenance['sourcePixelsModified'])
        for record in provenance['files']:
            self.assertEqual(hashlib.sha256((folder / record['path']).read_bytes()).hexdigest(), record['sha256'])
        templates = json.loads((ROOT / 'templates.json').read_text())['templates']
        game = next(item for item in templates if item['id'] == 'godot-radbro-survivors')
        selected = set(game['assetFiles'][pack_id])
        self.assertTrue({'LICENSE.txt', 'publication.json', 'calibration.json', 'animation-kit/idle-sheet.png'} <= selected)
        self.assertEqual(len(list((folder / 'source/native-hero').glob('*.aseprite'))), 53)
        self.assertTrue(all(record['path'] in selected for record in provenance['files']))

    def test_catalog_records_all_bytes_and_licenses(self):
        data = catalog.verify()
        self.assertEqual(len(data['packs']), 4)
        for pack in data['packs']:
            self.assertTrue(any(f['path'].endswith('/LICENSE.txt') for f in pack['files']))

    def test_changed_asset_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            pack = root / 'assets' / 'test'
            pack.mkdir(parents=True)
            (pack / 'pack.json').write_text('{"id":"test"}')
            (pack / 'LICENSE.txt').write_text('Test permission')
            (pack / 'tile.svg').write_text('original')
            target = root / 'assets' / 'catalog.json'
            with patch.object(catalog, 'ROOT', root), patch.object(catalog, 'CATALOG', target):
                target.write_text(json.dumps(catalog.snapshot()))
                catalog.verify()
                (pack / 'tile.svg').write_text('changed')
                with self.assertRaisesRegex(ValueError, 'catalog mismatch'):
                    catalog.verify()

    def test_sprite_frames_fit_png_and_keep_source_timing(self):
        folder = ROOT / 'assets/radcat-motion-v2/sprites'
        for name, frames, duration in [('idle', 6, 300), ('walk', 6, 120), ('hop', 7, 140)]:
            png = (folder / f'{name}-sheet.png').read_bytes()
            self.assertEqual(png[:8], b'\x89PNG\r\n\x1a\n')
            width, height = struct.unpack('>II', png[16:24])
            metadata = json.loads((folder / f'{name}-sheet.json').read_text())
            self.assertEqual(len(metadata['frames']), frames)
            for frame in metadata['frames'].values():
                rect = frame['frame']
                self.assertLessEqual(rect['x'] + rect['w'], width)
                self.assertLessEqual(rect['y'] + rect['h'], height)
                self.assertEqual((rect['w'], rect['h']), (320, 320))
                self.assertEqual(frame['duration'], duration)

    def test_arena_can_be_rebuilt_without_art_changes(self):
        spec = importlib.util.spec_from_file_location('arena', ROOT / 'scripts/build-arena.py')
        arena = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(arena)
        with tempfile.TemporaryDirectory() as temp, patch.object(arena, 'PACK', Path(temp)):
            arena.build()
            for generated in Path(temp).iterdir():
                self.assertEqual(generated.read_bytes(),
                                 (ROOT / 'assets/relay-arena-2d' / generated.name).read_bytes())

    def test_vendor_has_no_unrecorded_changes(self):
        data = json.loads((ROOT / 'third-party.json').read_text())
        for vendor in data.values():
            for record in vendor['files']:
                content = (ROOT / record['path']).read_bytes()
                self.assertEqual(hashlib.sha256(content).hexdigest(), record['sha256'])

    def test_each_template_includes_its_asset_notices(self):
        data = json.loads((ROOT / 'templates.json').read_text())
        for template in data['templates']:
            for pack in template['assets']:
                self.assertIn('LICENSE.txt', template['assetFiles'][pack])
                for name in template['assetFiles'][pack]:
                    self.assertTrue((ROOT / 'assets' / pack / name).is_file())


if __name__ == '__main__':
    unittest.main()
