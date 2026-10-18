Original prompt: Build a playable Radbro dungeon crawler and source template from the actual Ourcade starter. Use Radclaw assets. Keep review-only art private.

## Implementation plan

- Pin and preserve upstream source, map, and asset notices.
- Port the original mechanics into a deterministic model.
- Render the model with Phaser 3.90 and released Radcat sprites.
- Add a complete outcome loop, touch controls, and source preparation.
- Test model behavior, browser controls, touch, and a restricted iframe.

## Source intake

- Retrieved pinned Ourcade source. Retained source snapshot for line-by-line comparison.
- Resolved original Git LFS objects and verified each SHA-256 and size before copying.
- Verified 0x72 CC0 statement on the author page. Excluded Faune character art.

## Local playable proof

- Implemented the original map and object positions with the original movement, enemy, chest, knife, and damage rules. Added a complete portal objective.
- Replaced obsolete Parcel tooling with native modules and the existing Phaser 3.90 vendor. No package installation is required.
- Kept released Radcat sprite files unchanged. Added explicit one-view mirroring notes. No private review assets were copied.
- Fixed fixed-step rounding and ready-screen time accumulation. A full deterministic route now reproduces through real browser keyboard events.
- Root check passed: 9 Python tests, 17 JavaScript tests. New model coverage includes walls, cardinal movement, pause, chest rewards, knife pool and collisions, health loss, victory, and time-step parity.
- Chromium browser proof passed: keyboard controls, throw, pause/resume, restart, full win and loss routes, real simultaneous touch movement and attack, touch release, and opaque sandbox iframe. No console errors.
- Full winning route: three chests, four defeated lizards, three hearts, 537 coins, 32.82 simulation seconds.
- Ran the develop-web-game client again after final gameplay fixes. Inspected its gameplay image and JSON state.
- Inspected gameplay, victory, defeat, and mobile browser screenshots. Visual verdict passed at 92/100. The current rendered character and pixel room art mix remains an art-direction choice.
- A copied prepared source project passed its offline asset audit outside the repository.
- Browser evidence stays in ignored evidence/dungeon-crawler/. Compact results are recorded in tests/verification.json.

## Handoff

- Parent must add template.json to the shared templates.json registry. No shared files were edited here.
- Parent must preserve template CREDITS.md when packaging.
- Launch at http://127.0.0.1:8784/templates/phaser-radbro-dungeon-crawler/ .
- See ART_REQUESTS.md for three comparison directions and a prioritized native Radbro/environment/effects list.
- No physical device, Safari, Firefox, or live host proof was made. No push or deployment was made.
