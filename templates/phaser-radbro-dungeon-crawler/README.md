# Radbro Dungeon Crawler

A small, complete dungeon game built from the actual Ourcade starter.
The public default player uses released Radcat sprites.
The game does not include draft Radbro art.

## Run from this repository

Use Python 3 and a browser. No package install or build tool is required.

```sh
python3 templates/phaser-radbro-dungeon-crawler/prepare.py
python3 scripts/serve.py --port 8784
```

Open <http://127.0.0.1:8784/templates/phaser-radbro-dungeon-crawler/>.

## Run a source ZIP

The packaged project includes the prepared runtime assets.
Extract the ZIP. Open a terminal in that folder.

```sh
python3 prepare.py
python3 -m http.server 8784
```

Open <http://127.0.0.1:8784/>. Keep the server running.
Do not open `index.html` through a `file:` URL.

## Play

- Use WASD or arrow keys to move.
- Press Space to throw a knife in the last movement direction.
- Near a closed chest, press Space to open it.
- Use the direction buttons and Throw / Open on touch screens.
- Open three chests. Defeat four lizards. Return to the lime portal.
- Press P to pause. Press R to restart. Press F for fullscreen.

You have three hearts. A hit gives a short grace period.
The source game has one cardinal movement direction at a time.
The directional marker shows the throw direction.
The Radcat sprite uses one view. Left travel mirrors that view.
Up and down travel do not show new character views.

## Edit

- `game-model.mjs` contains game rules and deterministic state.
- `main.mjs` connects Phaser, controls, rendering, and embed messages.
- `upstream/art/tiles/dungeon-01.json` is the original Tiled level.
- `upstream/source/` preserves the original TypeScript for comparison.
- `UPSTREAM.json` pins the source commit and asset hashes.
- `template.json` supplies the root template registry entry.
- `ART_REQUESTS.md` records the next art comparison work.

The port keeps the original room layout, object placements, cardinal enemy wandering,
three-projectile pool, chest interaction, health, and knockback.
It adds a complete exit condition, restart, pause, touch input, and deterministic tests.
It replaces the old Parcel and TypeScript build with native browser modules.
Phaser 3.90.0 is vendored with its MIT notice.
No source asset bytes were edited.

## Assets and license

Code uses MIT. Keep Ourcade's notice in `upstream/LICENSE`.
Dungeon art uses 0x72's CC0 assets. Keep the source record in `CREDITS.md`.
Radcat uses the separate Radbro community permissions in its asset folder.
The root MIT license does not cover Radcat art.
No Legend of Faune character graphics or music are included.

New Radbro art starts in Radclaw. Keep source hashes and motion metadata.
Keep draft packs in an ignored `.local-assets/` folder.
Do not put private candidates in public builds or source ZIPs.
A technical preview does not approve art for release.

## Verify

```sh
node --test templates/phaser-radbro-dungeon-crawler/tests/game-model.test.mjs
python3 scripts/check.py
```

The browser proof uses an existing Playwright runtime. It does not add a dependency.
Set `PLAYWRIGHT_MODULE` to its absolute `playwright/index.mjs` path when needed.

```sh
PLAYWRIGHT_MODULE=/absolute/path/to/playwright/index.mjs \
  node templates/phaser-radbro-dungeon-crawler/tests/browser-smoke.mjs
```

The proof uses real keyboard events for the complete win and loss routes.
It also checks real simultaneous Chromium touch events and a restricted iframe.
Browser screenshots and results go to the ignored repository `evidence/` folder.
No physical device, Safari, Firefox, or live host check has been made.
