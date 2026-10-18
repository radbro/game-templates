import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from zipfile import ZipFile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import package


class ReleasePackageTests(unittest.TestCase):
    def test_review_assets_stay_out_of_source_folder_and_zip(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / 'templates/phaser-test'
            source.mkdir(parents=True)
            (source / 'index.html').write_text('Playable public game')
            for name in ['.local-assets', '.review-assets', 'review-assets']:
                private = source / name
                private.mkdir()
                (private / 'unreleased.png').write_bytes(b'Private art candidate')
            for name in ['LICENSE', 'CREDITS.md']:
                (root / name).write_text('Public notice')
            entry = {'id': 'phaser-test', 'path': 'templates/phaser-test'}
            with patch.object(package, 'ROOT', root), \
                    patch.object(package, 'DIST', root / 'dist'), \
                    patch.object(package, 'prepare'), \
                    patch.object(package, 'templates', return_value=[entry]):
                package.package()
            output = root / 'dist/phaser-test'
            self.assertTrue((output / 'index.html').is_file())
            self.assertFalse(list(output.rglob('unreleased.png')))
            with ZipFile(root / 'dist/phaser-test-source.zip') as archive:
                self.assertIn('index.html', archive.namelist())
                self.assertFalse(any('unreleased.png' in name for name in archive.namelist()))

    def test_direct_browser_zip_excludes_local_review_files(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'index.html').write_text('Public browser build')
            private = root / '.local-assets'
            private.mkdir()
            (private / 'unreleased.png').write_bytes(b'Private art candidate')
            output = root.parent / (root.name + '.zip')
            try:
                package.zip_folder(root, output)
                with ZipFile(output) as archive:
                    self.assertEqual(archive.namelist(), ['index.html'])
            finally:
                output.unlink(missing_ok=True)
