# Radcat Courier — Phaser

Collect five energy cells. Return to the lime gate. Hop over hazards.
The route ends when the timer expires or you lose three lives.

## Run

Run these commands from the repository root:

```sh
python3 scripts/prepare.py
python3 -m http.server 8080
```

Open <http://localhost:8080/templates/phaser-radcat-courier/>.
Use a local HTTP server. ES modules cannot load from `file://`.
The runtime uses the local Phaser 3.90 vendor file. It does not use a CDN.

For a release source ZIP, extract it. Run `python3 -m http.server 8080`
in that folder. Open <http://localhost:8080>. Its assets are already included.

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | WASD or arrow keys | Direction buttons |
| Hop | Space | Hop button |
| Start | Enter | Start route button |
| Pause or resume | P | Pause or Resume button |
| Restart | R | Restart button |
| Fullscreen | F; Escape to exit | Browser control |

The hop lasts 0.98 seconds. Hazards cannot hit Radcat during a hop.
A hit returns Radcat to the gate. Collected cells stay collected.
The game pauses when the window loses focus.

## Make a new game

1. Edit `LEVEL` in `game-model.mjs` to set walls, cells, hazards, and the timer.
2. Keep the spawn and the cells outside the walls.
3. Edit `main.mjs` to change the scene and the game text.
4. Replace kit images in the shared asset folder. Keep source credits.
5. Run the tests. Play the route with a keyboard and touch controls.

`game-model.mjs` contains the game rules. `main.mjs` displays the state with Phaser.
Both normal play and `window.advanceTime(ms)` use the same fixed-step simulation.
`window.render_game_to_text()` reports the visible game state for browser checks.
The test hook does not move the player or change the rules.

## Test

Run these commands from this template folder:

```sh
node --test tests/*.test.mjs
node --check main.mjs
```

## Share

Use the repository export script to include the prepared assets and local engine.
Upload the exported ZIP as a static game build. Keep `index.html` at the ZIP root.
Keep the game inside the platform's sandboxed iframe.

Character assets are by [Radbro](https://radbro.fun/assets).
The character license differs from the source code license.
Keep the supplied asset notices when you share a build.
