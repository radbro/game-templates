# Retro shooter handoff

Status: waiting for the purchased project.

Candidate: [Ultimate Retro Shooter Template for Godot 4](https://felixarstudio.itch.io/ultimate-retro-shooter-template).
The author lists a single-user license for commercial and noncommercial games.
The author prohibits sharing the template source and raw assets.
This game needs a separate private project.
It must not become a public source example under the current license.

## Purchase intake

1. Keep the original downloaded archive.
2. Keep the receipt and included license in private storage.
3. Record the archive hash and exact version.
4. Read the included license before importing the project.
5. Check whether the single-user terms cover the intended development workflow.
6. Record every third-party asset and its attribution terms.
7. Keep the purchased files out of the public game template repository.

Do not commit receipt data, account data, or license keys.
The store page currently lists Godot 4.4+ and GDScript.
That does not prove browser export support.

## First technical proof

1. Open the unmodified demo with a matching Godot version.
2. Check movement, weapons, enemies, doors, pickups, and checkpoints.
3. Test the Compatibility renderer and a single-thread web export.
4. Test pointer capture, sound, and input in a restricted iframe.
5. Measure browser load time and frame rate.
6. Write a short failure report before adding new art if the web proof fails.

## Art work

Start with one small room and one enemy.
Compare Radclaw candidates before producing the full set.
The template uses sprite weapons and sprite enemies in a 3D world.
It supports eight directional enemy views.
Current single-view Radbro sheets do not supply those views.

The first asset briefs need a weapon idle/fire/reload set, enemy movement and attack views,
damage and death effects, a room surface kit, pickups, and a readable HUD.
Preserve Radbro identity in every candidate.
Keep editable source, runtime exports, source references, and permission records.

## Release

Publish the finished browser game only after the technical and asset checks pass.
Keep required credits with the browser build.
Do not include purchased source files in a public source download.
Only publish a reusable source example if a separate written license permits it.
