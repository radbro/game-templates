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

## Survivors in-game art comparison

The local review build now switches native and illustrated Radbro art during a real Godot round.
The Style button supports mouse and touch. The T key uses the same switch.
The hero and current sentries change together. New sentries use the selected style.
The arena, effects, movement, damage, and upgrade rules stay the same.

The engine regression suite passes 13 review checks and five fallback checks.
It checks object identity, positions, health, XP, upgrades, projectiles, random state, and clocks.
The normal gameplay smoke also passes in the review build and the public fallback.

Chromium passed 25 comparison checks with zero console or page errors.
One real-input round survived 90.02 seconds, defeated 123 sentries, and chose six upgrades.
The test changed styles 34 times during combat and upgrade selection.
Pause and outcome checks compared every exposed gameplay field before and after the switch.
Real touch input changed the style and held two movement controls at once.
Both the review build and public fallback booted inside an opaque iframe.
The standard web-game client also ran with both styles. Their screenshots were inspected.

The comparison builder verified 56 unchanged source files against the Radclaw study records.
Godot pack inspection found zero review files in the public PCK.
The local review PCK contains the selected private art and its import receipt.
All six source ZIPs and six web ZIPs pass their package checks.
The extracted Survivors source ZIP passes fresh Godot import, gameplay smoke, and fallback checks.
The root checks pass 16 Python tests and 17 JavaScript tests.

Only the local served game uses the review PCK. Download ZIP hashes stay unchanged by that overlay.
The art remains unpublished. Final art choice, physical devices, Safari, and Firefox remain unverified.
The illustrated hero holds its first walk pose while idle. It has no separate idle clip yet.
See [the local build command](parallel-games.md#play-both-styles-in-survivors).
Evidence: ignored `evidence/survivors-art-toggle/` and `build/local-review/` logs.

## Full-look comparison, 2026-10-19

The same Style button now changes ground tiles, weapons, live shots, XP, and effects.
Native art uses the existing Radclaw tile and icon atlas unchanged.
Illustrated art uses a new imagegen slate tile with alternating reflected tiles.
Original Godot drawing code supplies muzzle, hit, defeat, pickup, and upgrade feedback.
The effect queue has a limit of 64 events. It freezes with the round and clears on restart.

Fresh Godot imports passed without engine errors.
The local review passed 28 art checks and 18 gameplay checks.
The public fallback passed seven art checks and 17 gameplay checks.
The extracted source ZIP also passed fresh import, gameplay, and fallback checks.

Chromium passed 34 final comparison checks with no console or page errors.
One real-input round won at 90.02 seconds with 122 kills, six upgrades, and 34 style changes.
All five feedback event types occurred in that round.
Live shots and effect ages survived a paused style change.
Touch movement, touch style changes, and opaque iframe play passed.
The standard game client ran in both styles. Their gameplay captures were inspected.
The first reflected-floor export had gaps. The corrected export passed a 1482-point floor coverage check.
No sampled floor gap or spill below the arena remained.

The importer verified 58 unchanged source files, including the new illustrated ground.
The public PCK has zero review files. The web ZIP contains that public PCK.
All 12 release ZIPs pass entry, notice, and path checks.
The root checks pass 19 Python tests and 17 JavaScript tests.
Only the local served game uses the full-look review PCK.
The illustrated idle limit and physical-device/browser limits above still apply.
Evidence: ignored `evidence/survivors-full-look/`.

## Survivors release preparation, 2026-10-25

This update supersedes the earlier idle, sound, and balance limits for Survivors. Other game limits remain unchanged.

The illustrated hero now has a dedicated four-direction idle atlas with breathing and a short blink. All 60 imported draft files match their Radclaw source hashes. Original walk PNGs and native source layers remain unchanged. Runtime rectangles use the generated atlas's uneven row spacing. Explicit floor anchors keep the feet stable.

The game adds eight original procedural cues and an eight-second backing phrase. Start unlocks sound. M and the Sound button mute it. Pause and upgrade selection freeze backing. Restart keeps mute selected. Hurt feedback and wave announcements use bounded original code. The tuned profile uses a 320px range, 0.50 second base fire interval, three escalating waves, 70 live enemies, and six elites at most.

The engine balance suite passes 26 checks across seven complete rounds. The integrated public release suite passes 15 checks. The private release suite passes 30 checks, including all four idle views, timing, style-clock preservation, and walk/idle transitions. Cue checks assert accepted playback, not only requests. Native tests allow a real mixer cycle before exit.

Chromium passes 38 comparison checks and 18 audio/animation checks with no console or page errors. A moving run wins at 90.02 seconds with 148 kills, seven upgrades, 36 style changes, and 73.4 health. An idle run loses at 31.35 seconds. Real keyboard, simultaneous touch, pause, upgrades, outcomes, and opaque iframe play pass. The standard game client runs both styles and its screenshots pass visual inspection.

Browser audio proof uses an explicit virtual sink. This machine's normal Chromium device also stalls a plain oscillator. The virtual sink measures actual graph PCM and verifies mute, pause, resume, and outcome cues. It does not prove physical speaker audibility. No virtual sink setting is shipped in the product.

Root checks pass 23 Python tests and 17 JavaScript tests. All 12 public ZIPs pass package checks. The public PCK has zero private review files. Separate ignored local source and web ZIPs keep both review styles together. Their notices identify unpublished art. See [release review notes](survivors-release.md) for artifact paths and remaining decisions.

Evidence: ignored `evidence/survivors-release/`, `build/local-review/`, and `dist/survivors-release/`. No public publication or final art selection is claimed.
