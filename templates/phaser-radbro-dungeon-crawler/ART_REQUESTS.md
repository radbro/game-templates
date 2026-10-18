# Dungeon Crawler art requests

Status: playable baseline. No new art was generated for this port.
The current public build uses the released Radcat pack and CC0 dungeon art.
The user will choose the next art direction after side-by-side game previews.

## Comparison set

Use the same first room, camera, enemy count, light, and movement route for each option.
Record the source run, manifest revision, license state, and PNG hashes.
Capture idle, left and right travel, vertical travel, throwing, damage, and chest interaction.
Do not label mirrored views as new directions.

| Option | Character | Environment | Main question |
| --- | --- | --- | --- |
| A: current public baseline | Released Radcat render sprites | Retained 16-pixel 0x72 dungeon | Is the rendered character and pixel room mix acceptable? |
| B: native pixel character | Radclaw 64-pixel Radbro paperdoll, local review only | Same dungeon, integer scale | Do proportions and separate equipment read clearly at play scale? |
| C: unified pixel world | Same approved native pixel character | New Radclaw dungeon tiles and enemies | Is one shared palette and grid worth the extra art work? |

Use B and C only in ignored local proofs until release approval and permissions are recorded.
Read the live pack. Do not assume an old rig revision.
Preserve the shared frame clock, floor anchor, layer order, hiding rules, and full-stack mirror.
Use one whole-character view when a pack has one view.

## Priority 1: identity and directional movement

- Compare a Radbro native sprite against the current Radcat scale.
- Make genuine front, rear, and side locomotion if the chosen design needs those views.
- Keep the 64 by 64 source canvas and X=32, Y=60 floor anchor when using that rig.
- Add a short throw or cast pose. Do not substitute a wave or hop.
- Add a hit reaction and defeat state with readable silhouette.

## Priority 2: Radbro dungeon objects

- Three chest states: closed, opening, and open.
- One 16-pixel floor and wall set that supports all original room joins.
- One enemy with idle, movement, hit, and defeat states.
- A knife or spell projectile. Keep its hitbox readable at 2x display scale.
- A clear exit portal with locked and unlocked states.

## Priority 3: feedback and sound

- Small throw, hit, coin, and exit effects.
- Short sound cues with explicit redistribution permission.
- A muted state for browser startup and embedded play.

## Acceptance evidence

Compare source references and runtime output at native size and in the game.
Check identity, palette, silhouette, foot sliding, equipment timing, and attack alignment.
Keep source masters, hashes, timing, notices, and the user's art choice with each released version.
The result must work in both a finished game and a public source template.
