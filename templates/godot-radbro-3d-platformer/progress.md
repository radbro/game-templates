Original prompt: Adapt Kenney's 3D Platformer in parallel. Use Radclaw assets. Prepare both a playable game and an editable public source template. Keep art direction choices reviewable.

## Implemented

- Pinned Kenney commit 3fa8a04b1c01ab23db43123d4ce814a34c3fc7f0.
- Retained MIT notices, CC0 art declaration, SIL OFL font notice and engine notices.
- Kept the released Radcat GLB intact. No draft art is included.
- Kept controller movement separate from all imported model animation tracks.
- Built a six-island course with physical double jumps, coins, a falling island and a finish.
- Added ready, playing, paused, won and lost states. Restart restores the course.
- Added keyboard, existing gamepad mappings and simultaneous touch controls.
- Used Compatibility and a single-thread web export. Applied the pinned opaque-origin guard.
- Added read-only text state and parent frame ready/result messages.

## Verification

- Root source checks pass: asset hashes, Python/JS syntax, Python tests and nine JS tests.
- Godot 4.6.2 import and export complete with no errors.
- Headless smoke passes: 17 bones, 35 morphs, four motions, real movement and double jump,
  third-jump limit, pause, actual coin/platform/flag contacts, loss and reset.
- The fixed-fps headless test disables its dummy audio mixer. This avoids an engine teardown leak.
- Chromium keyboard play crosses all five gaps and wins with all six coins.
- Browser screenshots show the complete Radcat character, course, controls and result.
- Chromium CDP touch contacts move and jump together. Pause freezes the player, timer and coins.
- Camera rotation, fall loss and restart pass in Chromium.
- An opaque-origin iframe starts, moves and collects a coin. Ready messages reach its parent.
- No browser page errors or console errors occurred.
- Touch buttons use 120 by 110 logical pixels for smaller screens.
- The export excludes all private art folder aliases as well as tests.
- A negative PCK test inserted temporary sentinels into all four private-art aliases.
  None entered the final PCK. Nine required notices and metadata files are present.
- UPSTREAM.json records SHA-256 for byte-identical retained upstream files and the Radcat GLB.

## Integration handoff

The parent owns templates.json and root build/package integration.
Use this folder's template.json as its registry snippet.
Run this folder's prepare.py until the root registry includes this template.
Keep generated assets, .godot caches, web exports and evidence out of source commits.
The local server needs CORS for an opaque iframe. Use scripts/serve.py.
A plain python http.server passes direct play but cannot serve opaque iframe fetches.

## Remaining art and release work

- Compare the directions in ART_REQUESTS.md with the user.
- Release new art through Radclaw before adding it to public packs.
- Review local playable proof before public publication.
- Physical phones, physical gamepads, Safari, Firefox and live hosting remain untested.

## Source size pass

Plan: remove unused upstream scenes, scripts, sounds and the large skybox.
Keep all files referenced by the current scene, all notices, provenance and editable course meshes.
The smoke and browser tests already protect the current gameplay. Rerun them after deletion.

Source size pass complete: removed unreferenced upstream files. Import and smoke still pass.
The original font notice and two byte-identical upstream scripts retain their original trailing whitespace.

A clean cache rebuild removed stale generated UID warnings after unused files were deleted.
Clear this project's .godot cache after removing or renaming imported resources.
Import again before export. Keep the browser console check in the release gate.
