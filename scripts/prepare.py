#!/usr/bin/env python3
"""Copy verified packs into each engine project. No network access is required."""
import argparse
import json
import shutil
from pathlib import Path
from catalog import ROOT, verify


def templates():
    return json.loads((ROOT / 'templates.json').read_text())['templates']


def prepare(template_id=None):
    verify()
    selected = [item for item in templates() if template_id is None or item['id'] == template_id]
    if not selected:
        raise ValueError(f'Unknown template: {template_id}')
    for item in selected:
        project = (ROOT / item['path']).resolve()
        if project.parent != ROOT / 'templates' or project.name != item['id']:
            raise ValueError('Template must be a direct child of templates/.')
        target = project / 'assets'
        if target.is_symlink():
            raise ValueError('Generated assets folder must not be a symlink.')
        if target.exists():
            shutil.rmtree(target)
        for pack_id in item['assets']:
            source = (ROOT / 'assets' / pack_id).resolve()
            if source.parent != ROOT / 'assets':
                raise ValueError('Invalid pack path.')
            for relative in item['assetFiles'][pack_id]:
                path = (source / relative).resolve()
                if not path.is_relative_to(source):
                    raise ValueError('Invalid asset file path.')
                destination = target / pack_id / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(path, destination)
        print(f"Prepared {item['id']}.")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('template', nargs='?')
    prepare(parser.parse_args().template)
