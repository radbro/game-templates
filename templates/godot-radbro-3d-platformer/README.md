# Radbro Sky Run

Collect six coins. Reach the last flag. Cross the gaps with a double jump.
The fourth island falls after you land. Falling ends the run.
Restart restores the coins, platforms and camera.

This is a source adaptation of Kenney's 3D Platformer starter kit.
`UPSTREAM.json` records the exact commit and changes.
The published Radcat Motion v2 character comes from Radclaw.
No draft character pack is included.

## Run

Use Godot 4.6.2 and its matching Web export templates.
From the repository root, run:

```sh
python3 templates/godot-radbro-3d-platformer/prepare.py
```

Open this folder's `project.godot`. Run its main scene.
The root prepare command can replace this local command after registry integration.
A packaged source ZIP already includes its required asset files.

| Action | Keyboard | Gamepad | Touch |
| --- | --- | --- | --- |
| Move | WASD | Left stick | Direction pad |
| Jump twice | Space twice | A or B twice | Jump twice |
| Rotate camera | Q/E or left/right arrows | Right stick | CAM buttons |
| Camera tilt | Up/down arrows | Right stick | Use default tilt |
| Zoom | Plus/minus | Triggers | Use default zoom |
| Start | Enter or Start button | Start button on screen | Start button |
| Pause | P or Escape | Start | Pause button |
| Restart | R | Restart button on screen | Restart button |

Touch controls accept simultaneous contacts. Hold UP and tap JUMP.
The run pauses when the app loses focus.
Use Resume to continue. Touch controls scale with the 960 by 720 viewport.

## Edit

Change the six-island layout in `scripts/main.gd::_build_course`.
The course uses Kenney's platform and coin scenes in `objects/`.
`objects/platform_falling.gd` supplies the delayed fall and reset.
Change movement speed and jump strength on `objects/player.tscn`.
`scripts/view.gd` retains Kenney's camera follow, rotation and zoom.
The controller uses units per second. It does not scale speed by the frame rate.
If you remove imported resources, clear this project's generated `.godot` cache.
Then import and export again. Check the browser console for stale UID warnings.

Keep the complete Radcat GLB instance inside the CharacterBody3D.
The body owns movement and collision. The model owns visual rotation and animation.
Keep all 17 bones, 35 morph targets and all four source animation clips.
The hop clip is the jump visual. Physical velocity controls the real jump.
Do not stretch the model during takeoff or landing.

## Verify

From the repository root:

```sh
python3 scripts/check.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path templates/godot-radbro-3d-platformer --editor --import --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path templates/godot-radbro-3d-platformer --fixed-fps 60 --script tests/smoke.gd
```

The smoke test uses placement fixtures for coin and finish contacts.
It checks full character import, motion playback, movement, both physical jumps,
the third-jump limit, pause, falling-platform contacts, finish, loss and reset.
The headless test disables the dummy audio mixer. Browser checks use sound normally.
The shipped game has no teleport or forced-win command.

## Web export

The project uses Compatibility and the single-thread Web variant.
It does not require cross-origin isolation headers.
From this folder:

```sh
mkdir -p ../../build/godot-radbro-3d-platformer
godot --headless --export-release Web ../../build/godot-radbro-3d-platformer/index.html
```

Run the root `patch_godot_web.patch` helper on that output folder.
The guard fixes Godot 4.6.2's service-worker query in an opaque-origin iframe.
Keep the generated runtime-patch hash record with the export.
Serve exports through HTTP locally and HTTPS in production.
Use the root `scripts/serve.py` for local iframe checks. It supplies the required CORS header.
Include `CREDITS.txt`, engine notices and asset notices in distributed builds.
The export preset also includes those notices in its PCK.

The browser supplies read-only `render_game_to_text()` state.
`advanceTime(ms)` waits for real engine time and returns the state as JSON text.
It never teleports the player or changes the outcome.
State coordinates use +X right, -Z down the course and +Y up.
The game posts `radbro:game-ready` and one `radbro:game-result` per run.
It answers the parent frame's `radbro:game-ready-request` message.

Run the browser scripts with an existing Playwright installation:

```sh
GAME_URL=http://127.0.0.1:8783 node templates/godot-radbro-3d-platformer/tests/browser-route.mjs
GAME_URL=http://127.0.0.1:8783 node templates/godot-radbro-3d-platformer/tests/browser-controls.mjs
```

Set `PLAYWRIGHT_MODULE` to an absolute module URL if Playwright is outside local module lookup.
Run both commands from the repository root. Start `scripts/serve.py` first.
`browser-controls.mjs` writes a test-only `sandbox.html` into the ignored export folder.
The export preset excludes `.local-assets`, `local-assets`, `.review-assets` and `review-assets`.
Keep all private art in those excluded folders.

## Licenses and art

Code is MIT. Included Kenney game assets are CC0.
The font is SIL OFL. Radcat has its own Radbro permission notice.
Read `CREDITS.txt`, `UPSTREAM-README.md`, and each license file.
`ART_REQUESTS.md` lists future art comparisons. These are requests, not approved assets.
