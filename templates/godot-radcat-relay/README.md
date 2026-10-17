# Radcat Relay

Collect four energy pickups. Return to the gate before the timer ends.
Move around the striped barriers. Hop over the red hazard pads.
A hazard hit removes five seconds. A hop lasts 0.65 seconds.
The hop cooldown is one second.

## Open the project

Use Godot 4.6.2. Install its matching Web export templates.
Run this command from the repository root:

```sh
python3 scripts/prepare.py godot-radcat-relay
```

Open `project.godot` in Godot. Run the main scene.
The first import can take several seconds.
Run the prepare command again after you change a shared asset pack.
Then let Godot import the copied files again.

For a release source ZIP, extract it and open its `project.godot` directly.
The ZIP already contains its asset files and engine notices.

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | WASD or arrow keys | Hold a direction button |
| Hop | Space | Hop button |
| Pause or resume | P or Escape | Pause or Resume button |
| Restart | R | Restart button |

Touch buttons support more than one contact. Hold a direction and tap Hop.
The round also pauses when the application loses focus.
Use the Resume button to continue.

## Change the game

- Open `scenes/main.tscn` to move pickups, barriers, hazards, the gate, or scenery.
- Change `round_seconds` on the main node to set the timer.
- Change `speed` on the Player node to set movement speed.
- Use `scenes/player.tscn` to change the collision body or model scale.
- Use `scripts/kit_piece.gd` to select one named part of the playground model.
- Keep the whole Radcat model instance. Its AnimationPlayer, 17 bones, and 35 morph targets remain in the import.

The outer CharacterBody3D owns movement and collision.
The inner model owns animation and rotation.
The supplied model faces positive Z. Its model offset places the feet on the floor.
The hop changes the model height. The collision body stays on the ground.
The game blocks hazard damage while the hop is active.

## Check gameplay

Run these commands from this folder. Replace `godot` with your Godot executable path if needed.

```sh
godot --headless --editor --import --quit
godot --headless --fixed-fps 60 --script tests/smoke.gd
```

The smoke test checks imported bones, morphs, and animation names.
It checks input movement, motion playback, pause, barrier collision, and wall collision.
It also checks hazard damage, hop protection, pickup contacts, the return gate, restart, and timeout.
The test uses player placement as a test fixture.
The shipped game has no teleport or win shortcut.

## Export for the web

Run this command from this folder:

```sh
mkdir -p ../../build/godot-radcat-relay
godot --headless --export-release Web ../../build/godot-radcat-relay/index.html
```

The preset uses the Compatibility renderer and the single-thread Web variant.
It does not need SharedArrayBuffer or cross-origin isolation headers.
Serve the output folder through HTTP for local tests.
Use HTTPS for public hosting.
Run the root `scripts/build-site.py` after export to make the sandbox-ready web ZIP.
It adds a small guard for Godot 4.6.2's service-worker query in opaque iframes.
See the root hosting guide for the patch and its recorded hashes.
Include the engine notices described in the root credits when you distribute an export.

The browser exposes two test functions:

```js
JSON.parse(window.render_game_to_text());
JSON.parse(await window.advanceTime(250));
```

`render_game_to_text` returns current round and player state as JSON text.
`advanceTime` returns a Promise. It waits for real engine time, then returns that text.
It does not set the outcome or teleport the player.
The JSON coordinates use positive X to the right, positive Z toward the gate, and positive Y up.

## Asset credit

Character and playground assets: Radbro, <https://radbro.fun/assets>.
Keep the asset permission notices with distributed assets.
The repository code license does not replace the asset permission notices.
