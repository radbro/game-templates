import hashlib
import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class SourceAuditTests(unittest.TestCase):
    def test_audited_upstream_files_are_present_and_tracked(self):
        tracked = set(subprocess.check_output(
            ['git', 'ls-files', '-z', '--', 'templates'], cwd=ROOT
        ).decode().split('\0'))
        for audit in sorted((ROOT / 'templates').glob('*/SOURCE_AUDIT.json')):
            for record in json.loads(audit.read_text())['files']:
                path = audit.parent / record['path']
                with self.subTest(path=path.relative_to(ROOT)):
                    self.assertTrue(path.is_file(), 'Audited source file is missing')
                    self.assertIn(path.relative_to(ROOT).as_posix(), tracked,
                                  'A local ignored file cannot supply a source release')
                    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),
                                     record['sha256'])
