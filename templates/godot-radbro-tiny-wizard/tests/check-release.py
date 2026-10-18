#!/usr/bin/env python3
"""Inspect a Godot 4.6.2 PCK v3. Check release exclusions and runtime notices."""
import argparse
import struct

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pack')
args = parser.parse_args()
with open(args.pack, 'rb') as stream:
    assert stream.read(4) == b'GDPC'
    assert struct.unpack('<I', stream.read(4))[0] == 3, 'Review the parser for a new PCK format.'
    stream.seek(32)
    directory_offset = struct.unpack('<Q', stream.read(8))[0]
    stream.seek(directory_offset)
    count = struct.unpack('<I', stream.read(4))[0]
    paths = []
    for _ in range(count):
        length = struct.unpack('<I', stream.read(4))[0]
        path = stream.read(length).rstrip(b'\0').decode()
        paths.append(path)
        stream.read(36)
for path in paths:
    for forbidden in ['.local-assets/', 'local-assets/', '.review-assets/', 'review-assets/', 'radbro-private-canary']:
        assert forbidden not in path, path
assert 'CREDITS.txt' in paths
assert any(path.endswith('idle-sheet.json') for path in paths)
assert any(path.endswith('SPRITE-PERMISSION.txt') for path in paths)
assert sum(path.endswith('LICENSE_ASSETS.txt') for path in paths) == 2
print(f'Release pack passed: {count} entries; private paths excluded; notices and animation metadata included.')
