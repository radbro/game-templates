# Add an asset pack

1. Give the pack a stable ID and version.
2. Make a new folder under `assets/`.
3. Record the source and permission in `pack.json`.
4. Include the complete license in `LICENSE.txt`.
5. Add the runtime files and editable source or its source URL.
6. Record scale, axes, origins, animation names, frame timing, and collision needs.
7. Test the pack in one playable template.
8. Run `python3 scripts/catalog.py --write`.
9. Review the source, permission, and hash diff.
10. Select the required files in `templates.json`.
11. Run `python3 scripts/prepare.py`.
12. Run `python3 scripts/check.py`.
13. Test the engine export and browser controls.
14. Include the notices in the release ZIP.

Use a new pack ID for a character revision that changes its appearance or rig.
Keep released character files unchanged.
Use `scripts/build-arena.py` as a small example of a repeatable source generator.
Keep each pack useful without its original game.

# Add a game template

Create `templates/ENGINE-GAME/`.
Include an engine entry point, a short README, and a complete play loop.
Keep game rules and level data easy to change.
Register the project and its asset file list in `templates.json`.
Include start, success, failure, pause, and restart states.
Include keyboard and touch controls for browser games.
Test collisions, scoring, and terminal states.
Test the packaged output without a connection to an asset CDN.
Keep engine caches and generated exports out of Git.

# Next packs and games

These items are planned. They are not included in this release.

| Pack | Assets to add | Template it enables |
| --- | --- | --- |
| Platform course | Ledges, moving platforms, springs, checkpoints | Phaser platformer; Godot obstacle course |
| Arena combat | Enemy sprites, hit effects, projectiles, attack clips | Phaser arena survival; Godot combat room |
| Racing kit | Modular road turns, ramps, barriers, checkpoint arches | Godot time trial |
| Audio kit | Original pickup, impact, hop, start, and finish sounds | Both engines |
| UI kit | Buttons, status bars, score badges, controller prompts | Both engines |

Add one pack with one game that proves its use.
Unity and Unreal are later engine tracks.
Each needs an editable project, its own export proof, and target-device checks.
Do not label an empty editor scaffold as a working template.
