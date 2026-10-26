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
| Sound on or off | M | Sound button |

The four TouchScreenButton pads support simultaneous contacts.
The blaster uses nearest-target aim. Contact with sentries reduces health.
The round ends when health reaches zero or the survival timer completes.
Restart clears enemies, XP, upgrades, and projectiles.

## Edit

- `scripts/balance.gd`: round duration, spawn cadence, enemy pressure, and initial player/weapon values.
- `scripts/game.gd`: round state, upgrades, arena, audio hooks, and UI.
- `scripts/player.gd`: movement speed, health, contact damage, and bounds.
- `scripts/gun.gd`: target range, fire interval, and damage.
- `scripts/mob.gd`: enemy health, pursuit, and original geometric sentry drawing.
- `scripts/bullet_2d.gd`: projectile speed, range, and swept collision.
- `scripts/character.gd`: published Radcat animation and optional layered paperdoll adapter.

The default Radcat retains its 320-pixel frame grid and source timing.
It displays in a 70-pixel rectangle. Do not relabel it as the native 64-pixel Radbro pack.
The arena uses a fixed 960 by 640 logical viewport with proportional browser scaling.

## Released Radbro art

Both native and illustrated Radbro art now ship with this template. Press T or use Style to change the full look during the same round. Ground, enemies, weapon, shots, XP, effects, and hero change together. Positions, health, upgrades, and clocks stay the same. Native is the default.

The released pack is `assets/radbro-survivors-dual-style-v1`. It includes its own permission notice, publication approval, source hashes, 56 Aseprite editor files, illustrated raster originals, and prompts. The source ZIP includes those files. The Web export excludes the `source/` editor files.

Open this project normally in Godot 4.6.2. No `--art-review` flag or external Radclaw folder is needed. Run `prepare-assets.py` from this folder if you cloned the repository. Packaged source ZIPs already include the selected assets.

## Optional private Radbro proof

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
It exports both released Radbro styles. Radcat remains a licensed fallback if the released pack is removed.
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
- Audio: eight original procedural cues and an original eight-second backing phrase. The source code is MIT. No external recordings or samples are used.
- Released dual-style pack: Radbro Community Game Asset Permission. Keep its LICENSE.txt and publication.json.
- Additional local paperdoll candidates: private review only. Their approval remains separate.

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

## Switch art inside the local Godot game

The isolated local review build can switch between Native and Illustrated art.
Press T or select the visible Style button while you play.
The button also works during pause and an upgrade choice.
The switch changes the hero and all current sentries. New sentries use the selected style.
It keeps the same player, enemy, projectile, and weapon nodes.
It does not reset positions, health, XP, upgrades, timers, damage, fire rate, or random state.
The same toggle also changes the floor, gun, in-flight projectiles, XP, and feedback.
Game rules and UI geometry stay the same.

This feature requires the `art_review` export feature or the `--art-review` native argument.
It also requires both complete private packs in the isolated project's `review-art/` directory.
The public source project must not contain that directory.
Without the flag and complete data, the game keeps the published Radcat default.
It hides the Style button. T then has no effect.
The older native `--radbro-review` paperdoll proof remains available separately.

The parent build script supplies this private contract:

- `review-art/calibration.json`: exact study calibration and source records.
- `review-art/native-hero/pack.json`: current native paperdoll pack with relative PNG planes.
- `review-art/illustrated-hero/source-manifest.json`: original 16 walk frames and their relative PNG files.
- `review-art/native-kit/pack.json`: native enemy metadata and image.
- `review-art/illustrated-kit/pack.json`: illustrated enemy metadata and original image.

Imported PNGs load through Godot's resource loader. Native raw files use an image fallback.
The native hero keeps its separate planes, source frame durations, hide rules, and complete-stack mirror.
The default comparison uses the base character without equipment.
The illustrated hero uses its four real directional walk frames at 240 ms per frame.
The optional `animation-kit` supplies a separate four-direction idle loop with brief blinks. Without that local pack, idle holds the first walk pose. The original walk PNGs stay unchanged.
Its display anchor is one common (256,512) baseline. The source metadata stays unchanged.
Both hero renderers use a constant target scale from the saved calibration.
The enemy renderer uses one constant clip scale and the declared per-frame floor anchors.
The illustrated enemy still has source body-shape drift. Registration does not repair its pixels.
The native enemy uses one fixed floor anchor. Neither style changes game collision or damage ranges.

The browser snapshot adds `art_style`, `available_art_styles`, and `player.facing`.
Player and enemy node IDs help verify that the toggle preserves live entities.

Run this regression test in the isolated review project:

```sh
godot --headless --path build/local-review/survivors-project --fixed-fps 60 --script tests/art-styles.gd -- --art-review
```

Run the same test in the public project without private packs to check the Radcat fallback.
The native test proves node and gameplay-state preservation at the instant of each switch.
Browser, touch, and final Web export checks remain separate verification steps.
Private draft art must stay out of all public source ZIPs and PCKs.


## Matching local full looks

Native uses the existing private ground and icon PNGs from `native-kit`.
The floor repeats its 64px tile. XP and projectile regions keep their original PNG bytes.
Visible alpha extents set their display sizes. The source cells stay untrimmed.
The gun, trail, and feedback use crisp original Godot shapes.

Illustrated uses the optional `review-art/look-kit/pack.json` contract:

```json
{"ground":{"image":"illustrated-ground.png","worldTileSize":128,"repeat":"mirrored alternate tiles"}}
```

The loader reads that PNG once. The renderer alternates X and Y reflections at draw time.
Partial tiles are cropped at the arena border. The source PNG is not edited.
If the optional ground is absent, the style uses a quiet original floor drawing.
Hero and enemy review still work. No new public asset dependency is added.
The illustrated gun, projectile, XP, glow, and wisps use original Godot drawing code.
Both styles keep the same bullet speed, damage, collision, range, and fire interval.

One `VisualEffects` node owns short muzzle, hit, defeat, pickup, and upgrade events.
The active list has a hard limit of 64 events. Lifetimes range from 0.18 to 0.52 seconds.
The effects use deterministic geometry. They never consume the gameplay random generator.
A style switch redraws existing effects and bullets immediately.
It preserves their node IDs, event IDs, positions, ages, remaining lifetimes, and counters.
Effects freeze during pause, upgrade selection, victory, and defeat.
They resume with the round. Restart clears the list and counters.
The public Radcat fallback keeps its original floor, gun, projectile, and XP look.
It does not emit these private-look effects.

The browser snapshot keeps render evidence in these fields:

- `visual_style`: floor, loaded ground state, mirror mode, gun, and projectile style.
- `projectiles`: live node IDs, style, position, and travelled distance.
- `active_fx`: current style, bounded count, clock, active event IDs/kinds/ages, and emitted counts.

Emitted counts remain after an effect fades. Restart resets them.
This lets real-input browser tests prove that each feedback hook ran.
These fields do not add a debug interface to the game.

The updated art regression test checks in-flight bullets, active effect restyling,
state preservation, pause/upgrade/outcome freeze, resume, the event bound, expiry,
restart cleanup, and the public fallback.
An explicit `--art-review` test fails if both private style packs do not load.
Run the editor import before native tests after preparing or restaging assets.
Headless checks do not replace final browser, touch, sandbox, or physical-device proof.


## Release candidate controls and profile

Sound starts after the first Start or Restart action. Press M or tap Sound to mute.
Mute stays selected after restart. Pause and upgrade selection freeze the backing track.
Win and loss stop the backing and play their original outcome cues.
The audio node limits simultaneous voices to eight. It throttles repeated short cues.
No game sound uses an external recording. Original note data and synthesis are in `scripts/audio.gd`.

Edit `scripts/balance.gd` to tune the profile. The three waves begin at 0, 30, and 60 seconds.
Each new wave has a visible announcement and a sound cue.
The profile raises spawn pressure and movement speed. It limits live enemies to 70 and elites to six.
The blaster starts with a 320px target range and a 0.50 second fire interval.
XP progression and the three upgrade choices retain their original rules.
Contact damage adds a brief character outline and an original hurt cue.

For the full local animation review, add `--animation-pack ../radclaw/runs/2026-10-25-survivors-idle`
to the root `scripts/build_survivors_review.py` command.
The imported atlas contains 16 dedicated idle poses. It does not replace any walk PNG.
The raw generated rows have unequal spacing. Explicit frame rectangles keep each complete pose.
Per-frame floor anchors register the feet. A common scale preserves body proportions.
The native paperdoll keeps its source layers, clips, durations, and frame grid.
The illustrated animation is included in the released dual-style pack. Historical draft metadata remains unchanged inside its source records. Publication approval is in the pack publication.json.

Additional optional engine checks: `tests/audio.gd`, `tests/balance.gd`, and `tests/release.gd`.
Use `--fixed-fps 60` for the seeded balance fixtures. They use the actual game scene and real input actions.
The browser audio and motion check is `tests/release-browser.mjs`.
Engine Dummy-driver checks do not prove browser output or physical speakers.


## Radbro game-page integration

The Web preset includes a small host bridge in `html/head_include`. It reports ready, objective, hint, and controls after the engine boots. It answers `radbro:game-ready-request` from the embedding page. A real win sends one `radbro:game-result` with `status: clear`. A loss sends `status: gameover`. Score is the sentry kill count. Restart resets the result guard. Pause, upgrades, and art changes do not submit another result.

Keep the host bridge with the normal Web preset when you export this template. The game remains playable outside Radbro.
