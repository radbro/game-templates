Original prompt: Publish official sample game templates based on our assets. Start with Phaser and Godot. Continue to add assets for new templates.

- Added the Phaser courier level and a fixed-step simulation.
- Added keyboard and multi-touch controls, start, pause, restart, and fullscreen.
- Added source atlas loading. The parent prepares shared assets and the local Phaser vendor file.
- Verification is in progress. No publication has occurred in this implementation task.

- Nine Node rule tests pass. They cover fixed-step timing, start and pause, walls, bounds, collection and return, hazards, hop, timeout, reset state, and invalid time.
- `node --check main.mjs` passes. The file diagnostics tool reports zero errors.
- Ran the original develop-web-game browser client with installed Google Chrome through an external loader.
- First WebGL canvas capture was black. Changed the renderer to Phaser.CANVAS. Removed an unnecessary snapshot call.
- Inspected `evidence/client-canvas/shot-0.png`. The image shows a collected cell and the Radcat hop. The scene and HUD are readable. No console error file was produced.
- Visual verdict: pass, score 94. The source kit, character, and interaction targets remain clear.
- Parent task owns full touch, sandbox, and win/loss browser checks and publication.
