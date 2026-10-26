# Survivors publication, 2026-10-26

The user approved the game and source with both art styles and the toggle. The approval record is in `assets/radbro-survivors-dual-style-v1/publication.json`. It applies to the exact copied files. Historical Radclaw draft records remain unchanged.

## Included release

- Both complete looks load by default. No private folder or review flag is needed.
- T and Style change the hero, enemy, ground, weapon, shots, XP, and effects during the same run.
- Dedicated illustrated idle and blink, original walk art, native layers and timing stay intact.
- The source includes56 Aseprite masters, original illustrated raster images, prompts, provenance and permission.
- All60 game asset files retain their recorded source hashes.
- The playable PCK excludes private draft folders and editor sources.
- The Web export sends ready, objective, hint, controls, and one genuine result per round to the host.

The GitHub workflow now imports, tests, and exports all four registered Godot projects before it packages the six templates. It checks Godot error text as well as process exit codes. The former Relay-only export could not build the expanded catalog from a clean checkout.

## Verification and release paths

Source: https://github.com/radbro/game-templates/tree/main/templates/godot-radbro-survivors

Demo path: https://radbro.github.io/game-templates/godot-radbro-survivors/index.html

The official game listing requires a signed-in creator before creation. An admin review token can approve the listing after creation. It cannot create an owned game. Publication evidence and exact final live URLs are recorded under ignored `evidence/survivors-publication/`.

Root checks cover24 Python tests and17 JavaScript tests. Native checks cover gameplay, both complete styles, audio, seeded balance, release state, and host-result deduplication. Browser checks cover both art styles, real controls and outcomes, pause, upgrades, audio graph output, touch, and opaque iframes. The standard game client screenshot passed visual inspection. Fresh source-ZIP checks verify the same game and all copied source hashes.

Physical speakers, physical touch devices, Safari, and Firefox remain outside this proof. The audio graph uses an explicit test-only virtual sink because this machine's Chromium output device stalls even for a plain oscillator. Product audio uses the normal browser output.

## Source and runtime notices

Keep the asset pack LICENSE.txt, source provenance, and publication record with the source. Keep the root MIT code notice and GDQuest MIT notice. GDQuest noncommercial art is excluded. Keep the Godot license and copyright notices with the browser build. New art revisions need a new pack version. Do not overwrite these released source bytes.
