# Game template work

The next four games use separate branches and checkouts.
Each game must support a playable web build and an editable source package.
Survivors is the first priority.

| Game | Source and revision | Branch | Local preview port |
| --- | --- | --- | --- |
| Radbro Survivors | [GDQuest](https://github.com/gdquest-demos/getting-started-with-godot-4/tree/940f23e54e0207cc1135c2f6dc7fdd1ce5b52127/2d-project-completed) | `codex/radbro-survivors` | 8781 |
| Radbro Tiny Wizard | [Quiver](https://github.com/quiver-dev/tiny-wizard-demo/tree/a3a75489e8b4e1e43b5a03b9bf954642fe216862) | `codex/radbro-tiny-wizard` | 8782 |
| Radbro 3D Platformer | [Kenney](https://github.com/KenneyNL/Starter-Kit-3D-Platformer/tree/3fa8a04b1c01ab23db43123d4ce814a34c3fc7f0) | `codex/radbro-3d-platformer` | 8783 |
| Radbro Dungeon Crawler | [Ourcade](https://github.com/ourcade/phaser3-dungeon-crawler-starter/tree/186705eb557af3d7042590fc61485a7cbed7b7f0) | `codex/radbro-dungeon-crawler` | 8784 |

Each checkout has the repository name plus the game name as its folder name.
Each agent owns one new directory under `templates/`.
The coordinator owns the shared catalog, packaging scripts, and release integration.
An agent supplies a `template.json` registration record for integration.

## First playable version

1. Import the pinned upstream game code.
2. Keep its copyright notices and license files.
3. Record upstream files, revisions, and modifications.
4. Replace assets that do not permit the intended release.
5. Use the published Radcat pack as the working default character.
6. Add a complete play loop with pause, an outcome, and restart.
7. Test controls, touch input, and a restricted browser iframe.
8. Export a web build and prepare an editable source package.
9. Record the test evidence and remaining art needs.

The project title can use Radbro while the first public-safe proof uses Radcat.
The final character choice remains part of the art review.
Do not describe a local proof as a published game.

## Asset review

Follow [the Radclaw workflow](radclaw-workflow.md).
Use actual current pack metadata instead of copying an older rig description.
The source pack controls the frame grid, anchor, timing, and layer rules.

Private engine proofs must use `.local-assets/` inside the template.
Keep that directory ignored by Git and excluded from release exports.
The source ZIP packager also excludes local review asset directories.
Godot export presets must exclude these files separately.
Source ZIP filtering cannot remove private art already embedded in a `.pck`.

For each new asset request, record:

- The game function and required animations or views.
- The canonical source reference and its hash.
- The native grid or model scale.
- The required runtime and editable formats.
- The candidate comparison and user selection.
- The technical checks and public reuse permission.

Use Radclaw runs to compare native modular pixels, generated pixel results, and 3D results.
Show each candidate at its intended game scale.
Keep source identity, motion quality, gameplay readability, and release permission as separate findings.
User selection of an art direction does not grant rights to unrelated third-party material.

## Upstream asset rules

GDQuest's code uses MIT.
Its original textures and models use CC BY-NC-SA 4.0.
Remove that art from the commercial game and source template.

Tiny Wizard and its pinned core use MIT code and CC BY 4.0 assets.
Retain asset attribution for any included art or audio.

Kenney's platformer uses MIT code and CC0 game assets.
Keep the SIL OFL notice if the Lilita font remains included.

Ourcade's dungeon crawler uses MIT code and credited CC0 asset packs.
Keep the source records for all retained tiles and characters.

## Later commercial games

The retro shooter waits for the purchased files and their included license.
Follow [the commercial game handoff](retro-shooter-handoff.md).
Keep restricted source and raw purchased assets out of this public repository.
