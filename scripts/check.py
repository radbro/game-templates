#!/usr/bin/env python3
"""Run source checks and unit tests. Run engine/browser checks separately."""
import ast
import subprocess
from catalog import ROOT, verify

verify()
for path in sorted(ROOT.rglob('*.py')):
    if any(part in {'build', 'dist', '.godot', '__pycache__'} for part in path.relative_to(ROOT).parts):
        continue
    ast.parse(path.read_text(), filename=str(path))
for path in sorted([*(ROOT / 'templates').rglob('*.mjs'), *(ROOT / 'tests').glob('*.mjs')]):
    subprocess.run(['node', '--check', str(path)], check=True, cwd=ROOT)
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', 'tests', '-v'], check=True, cwd=ROOT)
node_tests = sorted(str(p) for p in (ROOT / 'templates').rglob('*.test.mjs'))
if node_tests:
    subprocess.run(['node', '--test', *node_tests], check=True, cwd=ROOT)
print('Asset checks, Python syntax, JavaScript syntax, and unit tests passed.')
