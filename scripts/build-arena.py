#!/usr/bin/env python3
"""Build the original Relay Arena 2D pack. No source art is read."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'assets/relay-arena-2d'
ART = {
    'ground': '<rect width="64" height="64" rx="6" fill="#203e46"/><path d="M0 32h64M32 0v64" stroke="#2b5057"/><circle cx="8" cy="8" r="2" fill="#49737a"/>',
    'wall': '<rect x="2" y="12" width="60" height="48" rx="8" fill="#10262f"/><rect x="2" y="4" width="60" height="44" rx="8" fill="#638286" stroke="#a9cebf" stroke-width="2"/><path d="M12 16h40M12 22h40" stroke="#d6e2bb" stroke-width="3"/><path d="m14 36 8-8m10 8 8-8m8 8 6-6" stroke="#2c515b" stroke-width="5"/>',
    'energy': '<ellipse cx="32" cy="54" rx="18" ry="6" fill="#10262f" opacity=".6"/><path d="m32 5 21 13v26L32 56 11 44V18Z" fill="#bbef48" stroke="#ecffd0" stroke-width="3"/><path d="m35 14-14 21h11l-3 15 15-23H33Z" fill="#244347"/>',
    'gate': '<ellipse cx="64" cy="85" rx="56" ry="8" fill="#10262f" opacity=".7"/><path d="M16 80V20Q16 8 28 8h72q12 0 12 12v60" fill="none" stroke="#638286" stroke-width="14"/><path d="M16 80V20Q16 8 28 8h72q12 0 12 12v60" fill="none" stroke="#c8f765" stroke-width="4"/><path d="m48 36 18 14-18 14m18-28 18 14-18 14" fill="none" stroke="#f4ffc4" stroke-width="5"/><rect x="8" y="76" width="112" height="8" rx="4" fill="#c8f765"/>',
    'hazard': '<ellipse cx="32" cy="53" rx="27" ry="8" fill="#10262f"/><circle cx="32" cy="30" r="23" fill="#9b3b42" stroke="#ffb879" stroke-width="3"/><path d="m32 10 7 14 16 6-16 6-7 15-7-15-16-6 16-6Z" fill="#ff7868"/><circle cx="32" cy="30" r="6" fill="#fff0bf"/>',
    'beacon': '<ellipse cx="32" cy="55" rx="19" ry="6" fill="#10262f"/><path d="M23 51V20h18v31Z" fill="#638286" stroke="#c2d8c9" stroke-width="2"/><circle cx="32" cy="18" r="11" fill="#76d7ed" stroke="#e1ffff" stroke-width="3"/><path d="M17 50h30v7H17Z" fill="#b9eb50"/>',
}

def build():
    PACK.mkdir(parents=True, exist_ok=True)
    for name, art in ART.items():
        width, height = (128, 96) if name == 'gate' else (64, 64)
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-label="Relay arena {name}">{art}</svg>\n'
        (PACK / f'{name}.svg').write_text(svg)
    print(f'Built {len(ART)} original SVG assets.')

if __name__ == '__main__':
    build()
