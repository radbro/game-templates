# Initial game prototype checks

Date: 2026-10-18.
Engine: Godot 4.6.2 and Phaser 3.90.0.
Status: local prototypes. No new public release.

## Gameplay

| Game | Checked behavior |
| --- | --- |
| Radbro Survivors | Movement, bounds, automatic fire, damage, waves, XP, three upgrades, pause, defeat, restart, and a 90-second browser win |
| Radbro Tiny Wizard | Upstream bullet collisions, two waves, upgrades, health, key pickup, locked exit, victory, defeat, pause, and restart |
| Radbro Sky Run | Full character rig, double jump, blocked third jump, falling platform, six coins, finish, defeat, camera, pause, and restart |
| Radbro Dungeon Crawler | Original map, roaming enemies, projectile limit, chest loot, damage immunity, exit rules, victory, defeat, pause, and restart |

The game agents checked real keyboard and simultaneous touch input in Chromium.
They checked each game inside an opaque iframe without `allow-same-origin`.
The coordinator repeated direct loading, keyboard input, and opaque iframe loading for all four packaged web builds.
Those integration checks reported zero console or page errors.
The six-game local catalog also passed its narrow viewport check.

## Source and release files

The shared source checks pass 13 Python tests and 17 JavaScript tests.
The package checker validates six source ZIPs and six browser ZIPs.
Each has the expected entry file, source notices, and asset permission files.
Template attribution survives packaging.
Nested license and credit files also accompany the Godot browser builds.

A separate verifier built the four new source ZIPs from a clean Git snapshot.
All three Godot projects passed fresh import and gameplay smoke tests after extraction.
The verifier checked error text as well as exit codes.
Tiny Wizard's 182 audited upstream files match their recorded hashes.
Its ignore rule now preserves the 51 upstream media files that the initial commit omitted.
A shared regression test rejects missing or untracked audited source files.

The coordinator also imported, tested, and exported the integrated Godot projects.
Their logs contain no Godot errors.
Engine inspection found no private review files in the release packs:

- Survivors: 35 resource files.
- Tiny Wizard: 376 resource files.
- Sky Run: 66 resource files.

Godot exports exclude all four local review directory names.
The source packager excludes those names separately.
The Tiny Wizard and platformer lanes also tested nested private-file canaries.
No GDQuest noncommercial images or models are included.

## Art and remaining work

Published Radcat art is the default in every new template.
The Survivors native proof can load the local modular Radbro pack.
That separate check covers frame timing, equipment layers, hide rules, and the current rig.
Its private art is not in the distributed source or browser files.

The user has not selected the final art direction.
New enemy, environment, projectile, and UI work remains in the asset briefs.
Audio, long-run balance, physical devices, Safari, Firefox, and live hosting remain outside this proof.
The paid retro shooter waits for the downloaded project and its included license.

Local evidence is in `evidence/expansion/`.
The individual lane worktrees retain full gameplay routes and screenshots.
The persistent agent handoffs record those paths and the next steps.
