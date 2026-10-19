import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import build_survivors_review as review


class SurvivorsReviewTests(unittest.TestCase):
    def study(self, root):
        study = root / 'study'
        records = []

        def write(relative, data):
            path = study / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            record = {'path': relative, 'sha256': hashlib.sha256(data).hexdigest()}
            records.append(record)
            return record

        hero = write('review/assets/native-hero/sprites/base/head.png', b'Exact original image bytes')
        write('review/source-hashes.json', json.dumps({'files': [
            {'copy': 'assets/native-hero/sprites/base/head.png', 'sha256': hero['sha256']}
        ]}).encode())
        kit = write('native/enemy.png', b'Original enemy bytes')
        write('review/kit-hashes.json', json.dumps({'files': [kit]}).encode())
        write('manifest.json', json.dumps({'reviewOnly': True, 'published': False, 'files': records}).encode())
        return study

    def test_modified_source_fails_before_creating_project(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            study = self.study(root)
            (study / 'native/enemy.png').write_bytes(b'Unexpected change')
            output = root / 'output'
            with self.assertRaisesRegex(ValueError, 'hash mismatch'):
                review.stage_project(study, output)
            self.assertFalse(output.exists())

    def test_review_export_is_separate_from_release_project(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            study = self.study(root)
            source = root / 'templates' / review.TEMPLATE
            source.mkdir(parents=True)
            preset = 'name="Web"\ninclude_filter="assets/*.txt"\nexclude_filter="review-art/*,review-art/**,tests/*"\n'
            (source / 'export_presets.cfg').write_text(preset)
            (source / 'game.gd').write_text('Public game code')
            stale = source / '.local-assets'
            stale.mkdir()
            (stale / 'unused.png').write_bytes(b'Do not import unrelated review art')
            with patch.object(review, 'ROOT', root):
                receipt = review.stage_project(study, root / 'review-project')
            output = root / 'review-project'
            self.assertTrue(receipt['reviewOnly'])
            self.assertFalse(receipt['published'])
            self.assertEqual((output / 'review-art/native-kit/enemy.png').read_bytes(), b'Original enemy bytes')
            self.assertIn('custom_features="art_review"', (output / 'export_presets.cfg').read_text())
            self.assertIn('include_filter="review-art/**,', (output / 'export_presets.cfg').read_text())
            self.assertNotIn('review-art/*,review-art/**,', (output / 'export_presets.cfg').read_text())
            self.assertFalse((output / '.local-assets').exists())
            self.assertFalse((source / 'review-art').exists())
            self.assertEqual((source / 'export_presets.cfg').read_text(), preset)

    def test_source_paths_cannot_escape_study(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            study = self.study(root)
            (root / 'outside.png').write_bytes(b'Not in this study')
            with self.assertRaisesRegex(ValueError, 'Invalid review source'):
                review.checked_path(study, '../outside.png')
