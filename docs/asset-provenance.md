# Asset sources

## Radcat Motion v2

Source: the published Radbro asset library.
The source ZIP hash is `f8a5a2da7679013588ebfeaa2af1f24d279158b96689deb366f36c2bf0959ebd`.
The GLB hash is `eec1127321cb0bbf1be54b2ba0b4bf2535cbebcecf570129bb5275f9172ae54a`.

The repository keeps the published PNG and JSON bytes.
It does not redraw the character or change the source GLB.
The original pack notice stays unchanged.
A separate sprite permission notice covers the PNG and JSON files in this repository.
The source pack contains an editable Blender file and an Aseprite file.
Download that source pack from the URL in `assets/radcat-motion-v2/pack.json`.
The repository includes the runtime files needed by the templates.

Keep the source's 320 by 320 sprite cells and alpha channel.
Use each frame's recorded duration.
Keep the GLB's bone tracks, morph tracks, and cubic interpolation.
Move an outer controller. Do not replace the imported skeleton.

## Radcat Playground

Source: the published Radbro asset library.
The GLB hash is `eda129384abde4f844013cfcac8a0029c5d1ae343f11f6a2a60878e2467ab4f2`.
The model contains nine original procedural props.
Clone and place each named node. Their source origins overlap.
The original source pack contains its Blender generation script.

## Relay Arena 2D

Source: `scripts/build-arena.py` in this repository.
The script reads no external artwork.
It creates six transparent SVG assets from simple shapes.
It uses a shared palette so the pieces fit together.
Run it again to reproduce the same bytes.
The pack includes ground, wall, energy cell, gate, hazard, and beacon assets.

## Verification

`python3 scripts/catalog.py` verifies all local file hashes.
`python3 scripts/prepare.py` copies only selected files into each template.
`python3 scripts/package.py` includes the matching notices in each source ZIP.
Review `assets/catalog.json` before releasing a changed pack.
