# Tiny Wizard implementation record

Date: 2026-10-18.
Branch: codex/radbro-tiny-wizard.
Local preview: http://127.0.0.1:8782.
This is a local proof. No push, public publication, or radbro.fun submission was made.

## Implemented

The actual pinned Tiny Wizard source and its core are vendored.
The game uses Quiver's character, collision damage, bullets, weapons, enemy behavior,
inventory, pickup actions, health items, room art, and doors.
The new small campaign has two waves, a key-gated north exit, victory, loss,
restart, pause, keyboard, mouse aiming, and simultaneous touch movement/aiming.
The violet pickup equips the upstream upgraded projectile.
A Credits button shows source, license, and change notices in the game.

The default player uses the published Radcat idle and walk sprite bytes.
Frame rectangles and durations come from the original JSON.
One view is mirrored for horizontal travel.
No private Radclaw candidate or generated character art was imported.
The required future art and comparison format are in ART_REQUESTS.md.

## Verified locally

- Godot 4.6.2 editor import and main-scene run: no script or engine errors.
- All 58 GDScript files: --check-only passes.
- Headless smoke: actual projectile collision damages an enemy.
- Headless smoke: two waves, key requirement, inventory pickup, win, loss, and pause pass.
- Chrome with WebGL 2: keyboard movement, pause/resume, restart, pointer shooting,
  two waves, key pickup, north-door victory, and the violet weapon pickup pass.
- Chrome CDP Input.dispatchTouchEvent: two simultaneous fingers move and fire.
  Releasing them clears both touch IDs.
- Chrome restricted iframe: boots at opaque origin null with only
  allow-scripts and allow-pointer-lock. No same-origin permission is granted.
- Separate Chrome play: enemy contact reaches loss with zero health.
- Screenshot inspection: room boundaries, player silhouette, enemies, pickups,
  HUD, controls, pause, victory, and loss are visible. No character is stretched.
- Portrait screenshot: full room remains visible. Small text limits portrait use.
  Landscape is recommended.
- Source audit: 182 imported files. Upstream PNG bytes stay unchanged.
- PCK release inspection: 376 entries. Credits, both Quiver asset notices,
  Radcat permission, and animation metadata are included.
- Four nested export canaries are excluded. Tested aliases: .local-assets,
  local-assets, .review-assets, and review-assets.
- Repository scripts/check.py: asset checks, Python/JavaScript syntax,
  Python tests, and nine JavaScript tests pass.

Evidence is ignored under evidence/tiny-wizard/.
The web preset uses Compatibility and one thread.
The existing pinned Godot opaque-origin PWA guard is applied after export.
The local server is scripts/serve.py. It supplies CORS headers for sandbox tests.

## Limits

This is not a final art direction or art release approval.
No physical touch device, Safari, Firefox, controller, or live host was tested.
The upstream multi-room sample remains available but is not the supported Radbro entry.
The small room and all retained third-party assets still need the user's art selection.
New 64 by 64 modular pixel art needs a separate adapter and engine proof after approval.
The parent must integrate template.json, build the portable source ZIP,
add the game to the catalog, and select its publication target.

## Source completeness correction

The first lane commit omitted 51 upstream media files.
An unanchored assets/ ignore pattern matched nested upstream asset folders.
Local files masked that omission during the first engine checks.
The template now ignores only /assets/ at its root.
The 51 audited upstream media and editor icon files are tracked with unchanged bytes.
check-source.py now checks Git index paths and bytes when it runs in this repository.
Use --git-index to require that check explicitly.
Outside Git, the source ZIP still uses the mandatory file hash audit.
A fresh staged Git archive and a separately extracted portable ZIP both pass
source hashes, clean Godot editor import, and headless collision/game-loop smoke.
Those checks reject any ERROR text even when Godot exits with code zero.
No private files, import caches, or generated root assets were staged.
