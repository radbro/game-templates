#!/usr/bin/env python3
"""Package the sources and build a static demo site from a completed Godot export."""
import shutil
from html import escape
from catalog import ROOT
from package import package, zip_folder
from prepare import templates
from patch_godot_web import patch


def build():
    entries = templates()
    for item in entries:
        if item['id'].startswith('godot-'):
            for name in ['index.html', 'index.js', 'index.wasm', 'index.pck']:
                if not (ROOT / 'build' / item['id'] / name).is_file():
                    raise ValueError(f"Export {item['id']} first. Missing {name}.")
    package()
    site = ROOT / 'dist/site'
    if site.exists():
        shutil.rmtree(site)
    site.mkdir(parents=True)
    cards = []
    for number, item in enumerate(entries, 1):
        template_id = item['id']
        title = escape(item['title'])
        cards.append(f'<article class="card"><span class="number">{number:02d} / {escape(item["engine"])} / {escape(item["genre"])}</span>'
                     f'<h2>{title}</h2><p>{escape(item.get("description", item["genre"]))}</p>'
                     f'<a class="play" href="{template_id}/index.html">Play {title} →</a><div class="links">'
                     f'<a href="{template_id}-source.zip" download>Download source ZIP</a>'
                     f'<a href="{template_id}-web.zip" download>Download web build</a></div></article>')
        destination = site / template_id
        source = ROOT / 'dist' / template_id
        if template_id.startswith('godot-'):
            shutil.copytree(ROOT / 'build' / template_id, destination)
            patch(destination)
            for name in ['GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
                shutil.copy2(ROOT / 'licenses' / name, destination / name)
            for notice in source.rglob('*'):
                name = notice.name.lower()
                is_notice = name.startswith(('credits', 'license', 'copying', 'copyright'))
                is_notice = is_notice or name in {'ofl.txt', 'notice', 'notice.txt', 'upstream.json', 'source_audit.json'}
                if notice.is_file() and is_notice:
                    target = destination / notice.relative_to(source)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(notice, target)
            for pack_id in item['assets']:
                for name in ['LICENSE.txt', 'pack.json', 'SPRITE-PERMISSION.txt']:
                    notice = source / 'assets' / pack_id / name
                    if notice.is_file():
                        target = destination / 'assets' / pack_id / name
                        target.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(notice, target)
        else:
            shutil.copytree(source, destination)
        output = site / f'{template_id}-web.zip'
        zip_folder(destination, output)
        shutil.copy2(output, ROOT / 'dist' / output.name)
    page = (ROOT / 'site.html').read_text()
    if page.count('<!-- TEMPLATE_CARDS -->') != 1:
        raise ValueError('The demo page needs one template card marker.')
    (site / 'index.html').write_text(page.replace('<!-- TEMPLATE_CARDS -->', '\n'.join(cards)))
    for name in ['GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
        shutil.copy2(ROOT / 'licenses' / name, site / name)
    for item in entries:
        path = ROOT / 'dist' / f"{item['id']}-source.zip"
        shutil.copy2(path, site / path.name)
    (site / '.nojekyll').touch()
    print(f'Built {site}')


if __name__ == '__main__':
    build()
