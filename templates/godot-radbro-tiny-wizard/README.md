# Radbro Tiny Wizard

A small room shooter built from Quiver's Tiny Wizard and top-down-shooter-core.
The public player uses the published Radcat sprite pack.
The room, enemies, projectiles, and pickups retain Quiver's art.
This is an initial integration. It is not a final art direction.

## Run

From the repository root:

```sh
python3 scripts/prepare.py
python3 templates/godot-radbro-tiny-wizard/radbro/prepare-assets.py
/Applications/Godot.app/Contents/MacOS/Godot --path templates/godot-radbro-tiny-wizard --editor
```

Use Godot 4.6.2. Run `radbro/main.tscn`.
In a portable source ZIP, the public assets are already included.
Open `project.godot` from the unzipped folder. Skip repository preparation there.
The local preparation command works before the root registry contains this project.
The registry entry for integration is `template.json`.
After integration, `python3 scripts/prepare.py godot-radbro-tiny-wizard` replaces both preparation steps.

## Play

- Move with WASD.
- Aim and fire with the arrow keys.
- Hold the left mouse button to aim and fire at the pointer.
- On a touch screen, hold the left MOVE area to move. Hold the right AIM area to fire.
- Pick up the violet weapon to change the upstream projectile.
- Pick up the heart to restore health.
- Clear two waves. Take the key. Leave through the north door.
- Press P or Escape to pause. Press R to restart.
- Use the buttons for pause, restart, and credits.

The touch controls accept simultaneous fingers. They track screen-touch IDs.
Focus loss clears the touch controls and pauses the game.
Use landscape orientation on phones. Portrait keeps the full room but makes text small.

## Build and test

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path templates/godot-radbro-tiny-wizard --script res://tests/smoke.gd
mkdir -p build/godot-radbro-tiny-wizard
/Applications/Godot.app/Contents/MacOS/Godot --headless --path templates/godot-radbro-tiny-wizard --export-release Web
python3 -c 'import sys; sys.path.insert(0, "scripts"); from patch_godot_web import patch; patch("build/godot-radbro-tiny-wizard")'
python3 scripts/serve.py --port 8782 --directory build/godot-radbro-tiny-wizard
```

Install the Godot 4.6.2 web export templates first.
The web preset uses Compatibility and one thread.
It does not require cross-origin isolation.
Apply the repository's pinned Godot PWA guard after each web export.
The local server supplies CORS headers for the opaque iframe test.
Use a sandboxed iframe with `allow-scripts allow-pointer-lock` for the embed check.
Do not grant same-origin access for an app-origin build.
Run browser tests separately from the headless smoke test.
Use an existing Playwright installation with `tests/browser-check.cjs`.
Set `PLAYWRIGHT_MODULE` to its module path if it is outside Node's normal search path.
Run `tests/check-source.py` to verify source and art hashes.
Run `tests/check-release.py build/godot-radbro-tiny-wizard/index.pck` to inspect the release pack.

## Source and permissions

Read `CREDITS.txt`, `UPSTREAM.json`, and `SOURCE_AUDIT.json`.
Both upstream commits are pinned. The permitted source is vendored.
The core directory is not a nested Git repository or a live submodule.
`SOURCE_AUDIT.json` records the upstream Git blob SHA and the current SHA-256 for each imported file.
It identifies changed source and unchanged asset bytes.

Keep both Quiver MIT notices and both CC BY 4.0 asset notices.
Keep the Radcat permission files with its sprites.
The root code license does not cover any art.
The in-game Credits button shows sources, licenses, and changes.

`tiny_wizard/main.tscn` is the retained upstream multi-room sample.
The supported Radbro entry is `radbro/main.tscn`.
The adapter uses upstream character movement, collision, damage, projectiles,
weapons, enemy behavior, inventory, pickup actions, health, room art, and doors.
The new code supplies the small campaign and its interface.

## Asset work

Read `ART_REQUESTS.md` before creating art.
Keep private review candidates in `.local-assets/` and exclude them from release exports.
No private Radclaw paperdoll file is required by this source template.
The current character renders one view. Horizontal travel mirrors it.
It does not provide new rear or side views.
The adapter reads the original Radcat frame rectangles and durations.
It does not substitute wave for hop or alter published sprite pixels.

## Proof limits

Read `progress.md` for the tested engine, browser, controls, and outcomes.
Local browser evidence does not prove physical touch devices, Safari, Firefox,
live moderation, or a radbro.fun submission.
