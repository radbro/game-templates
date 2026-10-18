# Use the Radclaw asset workflow

Radclaw is the source project for new character art and animation.
This repository supplies engine projects and portable game builds.
Start new packs from the character work in Radclaw.
Choose a game that demonstrates each pack's useful features.

## Author in Radclaw

1. Select the original character or NFT references.
2. Keep the original source bytes, source URLs, trait names, and hashes.
3. Write a short design brief before making the asset.
4. Make editable source files and runtime exports.
5. Build a local review page with a playable proof.
6. Check source identity, motion, timing, alignment, and export bytes.
7. Record technical results and art review state separately.
8. Keep draft work in the ignored Radclaw run folder.

For pixel art, draw on the native grid.
Use Aseprite layers, frame tags, and native exports.
Use source portraits to guide the drawing.
Keep inferred anatomy and simplified details in the source notes.

For 3D art, keep the reference, provider output, Blender source, rig, and motion files.
Check the provider's accepted parameters before submitting a new generation job.
Check the saved GLB in Blender and in the target engine.
Keep full imported character scenes and their bone and morph tracks.
Move a separate game controller for movement and collision.

## Current pixel contract

The recent character and equipment trials use this common layout:

| Field | Value |
| --- | --- |
| Canvas | 64 by 64 pixels |
| Floor anchor | X=32, Y=60 |
| Frames | 28 |
| Atlas columns | 8 |
| Atlas size | 512 by 256 pixels |
| Idle | 4 frames, 1100 ms, loop |
| Walk | 8 frames, 960 ms, loop |
| Jog | 8 frames, 560 ms, loop |
| Wave | 8 frames, 1340 ms, play once |

Read each frame duration from the pack metadata.
Idle and wave have different durations within each clip.
Use nearest-neighbor display and integer scales for pixel previews.
Keep transparent pixels and untrimmed frame rectangles.
Return to locomotion after a one-shot gesture.
Mirroring one view does not create a new side or rear view.

This contract applies to the new native pixel packs.
Keep the published Radcat sprite pack's own dimensions and clip names.
A wave animation must not stand in for a hop animation.

## Modular Radbro equipment

The paperdoll contract is `radbro-paperdoll-v1`.
The current local revision is 2 and uses rig `radbro64-front-v2`.
Read the live pack before importing it. Do not assume that an older rig is current.
Read the actual `pack.json` for item IDs, slots, parts, and presets.

Use one clock and one frame index for the entire character.
Select at most one item in each slot.
Apply `hideBaseParts` and `hidesSlots` before drawing.
Merge the base parts with the selected item parts.
Sort parts by `z`, then by part ID.
Draw every part at the same floor anchor.
Mirror the complete stack once for left travel.

Keep shirts as separate far-sleeve, torso, and near-sleeve planes.
Keep held items attached to the matching hand pose.
Do not center or trim each item separately.
Do not flatten the runtime equipment into one fixed outfit.

A preset can represent only part of an NFT's traits.
Keep its matched and unconverted trait lists.
Show the missing traits in review tools.
Do not label a partial preset as an exact NFT reconstruction.

## Consume a pack in an engine

1. Select a specific Radclaw run and manifest revision.
2. Verify the manifest's file hashes before copying files.
3. Copy the runtime contract and required runtime files into a local engine proof.
4. Preserve the editable source or its source download reference.
5. Check engine import, animation timing, and source appearance.
6. Check equipment changes while the character idles, walks, jogs, and gestures.
7. Check keyboard and simultaneous touch controls.
8. Check the engine export in a restricted iframe.
9. Record engine and device limits in the review evidence.

Technical checks do not approve art for release.
The current pixel character and paperdoll trials are local review candidates.
They are not public template dependencies yet.
Keep their source records and review flags intact.
A published pack needs explicit release approval and its full permission notices.
Retain the source pack's license when importing it.
The root code license does not replace an asset or collection license.

After release approval, use [the asset packaging steps](adding-assets.md).
Register the released pack in `assets/catalog.json` and select its files in `templates.json`.
Verify public file hashes after publication.

## Next template work

Prioritize the modular Radbro equipment proof.
It already has a base character, separate trait items, and NFT presets.
The next engine proof should equip items during movement and preserve layer timing.
Then connect those items to a small game's pickup and equipment rules.

Use the shared pixel cast for a character-switching template.
Keep each collection's source and permission records with its pack.
Use the 3D reference, rig, and motion process for later 3D templates.
Add environment, effects, audio, and UI packs to meet the needs of those games.
