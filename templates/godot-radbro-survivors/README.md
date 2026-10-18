# Radbro Survivors

Survive a 90-second arena run. Your blaster aims and fires automatically.
Defeat sentries. Collect green XP. Select one of three upgrades each level.
The arena pauses while you choose. Three waves increase enemy speed and spawn rate.

This is a small adaptation of GDQuest's completed 2D tutorial project.
It reuses MIT movement, pursuit, shooting, range, spawn, and health logic.
Read [UPSTREAM.json](UPSTREAM.json) for the pinned source and file hashes.
The original GDQuest images and models are not included.
Their CC BY-NC-SA license does not cover this game's Radcat assets.

The temporary default hero is the published, licensed Radcat sprite pack.
The title stays Radbro Survivors. The local Radbro paperdoll is a separate art review.
No new permission is assigned to that draft art.

## Run

Use Godot 4.6.2 with its matching Web export templates.
From the repository root:

```sh
python3 templates/godot-radbro-survivors/prepare-assets.py
/Applications/Godot.app/Contents/MacOS/Godot --path templates/godot-radbro-survivors
```

Open `project.godot` in the editor to change the game.
A packaged source download must include its `assets/` directory.
It then opens directly without the root repository.
`prepare-assets.py` checks packaged files when the shared pack is absent.

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Start | Enter or Space | Start survival |
| Move | WASD or arrows | Hold one or two arrow pads |
| Upgrade | 1, 2, or 3 | Select an upgrade |
| Pause or resume | P or Escape | Pause or Resume |
| Restart | R | Restart |
| Fullscreen | F | Browser fullscreen controls |

The four TouchScreenButton pads support simultaneous contacts.
The blaster uses nearest-target aim. Contact with sentries reduces health.
The round ends when health reaches zero or the survival timer completes.
Restart clears enemies, XP, upgrades, and projectiles.

## Edit

- `scripts/game.gd`: round duration, spawn rate, upgrades, arena, and UI.
- `scripts/player.gd`: movement speed, health, contact damage, and bounds.
- `scripts/gun.gd`: target range, fire interval, and damage.
- `scripts/mob.gd`: enemy health, pursuit, and original geometric sentry drawing.
- `scripts/bullet_2d.gd`: projectile speed, range, and swept collision.
- `scripts/character.gd`: published Radcat animation and optional layered paperdoll adapter.

The default Radcat retains its 320-pixel frame grid and source timing.
It displays in a 70-pixel rectangle. Do not relabel it as the native 64-pixel Radbro pack.
The arena uses a fixed 960 by 640 logical viewport with proportional browser scaling.

## Private Radbro proof

Use only the local Radclaw review run. This command copies hash-checked runtime bytes into ignored `.local-assets/radbro/`:

```sh
python3 templates/godot-radbro-survivors/prepare-assets.py --review-pack /Users/tacopaco/workspace/fun/code/radclaw/runs/2026-10-17-radbro-paperdoll
/Applications/Godot.app/Contents/MacOS/Godot --path templates/godot-radbro-survivors -- --radbro-review
```

The adapter reads the actual pack rig. The current run is `radbro64-front-v2`.
It keeps 64 by 64 frames, floor anchor (32,60), variable frame durations, and untrimmed atlases.
It uses one clock for all planes. It applies slot selection and hide rules.
It sorts by z, then part ID. It mirrors the complete stack once.
Equipment remains separate at runtime. It does not flatten the outfit.
The default idle and walk clips run during gameplay.
The clip resolver also supports the pack's jog and one-shot wave definitions.
These clips have no gameplay action yet.

The Web preset excludes `.local-assets/`.
It exports the licensed Radcat default even when private review files exist.
Do not remove the exclusion or package private files into public source ZIPs.
Read the root Radclaw workflow before any character release.

## Verify and export

Run from the template folder:

```sh
godot --headless --editor --import --quit
godot --headless --fixed-fps 60 --script tests/smoke.gd
godot --headless --fixed-fps 60 --script tests/smoke.gd -- --radbro-review
mkdir -p ../../build/godot-radbro-survivors
godot --headless --export-release Web ../../build/godot-radbro-survivors/index.html
```

The private smoke option needs the local import first.
The smoke test checks movement, bounds, aiming, projectile damage, XP, all upgrades, pause, health loss, restart, and victory.
It uses direct state fixtures to reach outcomes. It is not a full balance test.

Apply the root `scripts/patch_godot_web.py` guard before opaque iframe tests.
Use the Compatibility renderer and the single-thread Web preset.
Keep Godot license notices with the export.

The browser exposes `window.render_game_to_text()`.
It reports current gameplay state as JSON text.
`window.advanceTime(ms)` waits for real engine time and returns that text.
It does not skip to outcomes or teleport the player.
Coordinates start at the top left. X increases right. Y increases down.
The player position is its floor anchor.

## Art and license audit

- GDQuest code: MIT. The exact original license is in `upstream/LICENSE.txt`.
- GDQuest art: omitted in full. No upstream textures, models, sounds, or fonts were downloaded.
- Radcat: use its `LICENSE.txt`, `SPRITE-PERMISSION.txt`, and `pack.json`.
- Sentries, arena, XP, projectiles, UI: original Godot drawing code under the repository MIT code license.
- Font: Godot's built-in default font. Keep the engine notices.
- Audio: none in this prototype.
- Local paperdoll: private review only. No public license or art release approval.

See [ART_REQUESTS.md](ART_REQUESTS.md) for the next Radclaw briefs.

## Optional browser and comparison checks

Use an existing Playwright install. Do not add a game dependency for this test.
Serve the patched Web build with the root CORS server. Then run the browser check:

```sh
python3 scripts/serve.py --directory build/godot-radbro-survivors --port 8781
```

In a second terminal, run from the repository root:

```sh
NODE_PATH=/Users/tacopaco/.codex/node_modules node templates/godot-radbro-survivors/tests/browser.mjs
```

The browser test uses actual keyboard and simultaneous CDP touch events.
It runs a circuit, selects upgrades, and reaches a real win or loss.
It also starts the game inside an opaque sandbox iframe.
It does not force a victory. Balance and physical touch-device testing remain separate checks.

To capture the same short native movement route with each character:

```sh
godot --path templates/godot-radbro-survivors --fixed-fps 60 --script tests/capture.gd
godot --path templates/godot-radbro-survivors --fixed-fps 60 --script tests/capture.gd -- --radbro-review
```

The captures go to the ignored root `evidence/survivors/` folder.
Keep the Radbro review capture local until its art release is approved.
