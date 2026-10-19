Original prompt: Build Radbro Survivors from the GDQuest completed 2D template. Use Radclaw assets. Support a public game and source template. Keep unapproved art private. Add art comparisons later.

2026-10-18 facing fix: The published Radcat sheets face left. Reverse their horizontal mirroring for right travel and the initial idle pose. Keep the private paperdoll facing rule unchanged. Verify the engine smoke and both travel directions in the rebuilt local browser game.

2026-10-18: Pinned GDQuest source at 940f23e54e0207cc1135c2f6dc7fdd1ce5b52127. Kept five exact MIT logic snapshots and the original license. Downloaded no upstream art. Adapted movement, pursuit, shooting, projectile range, spawn and health flow. Added a 90-second loop, three waves, XP, rapid fire/power/speed-heal choices, pause, restart, touch pads and browser state bridge.

Default art uses the published Radcat idle and walk sprites. Original Godot drawing supplies arena, sentries and effects. Private paperdoll import is hash-checked and ignored. Current live rig is radbro64-front-v2. Local adapter keeps a shared clock, native 64px frames, anchor, slot rules, hides and z/id order.

Headless smoke passes movement, bounds, projectiles, kill XP, three upgrades, pause/resume, damage loss, restart and survival win. Private smoke also passes raw image load, eye hiding, shared clock and layered equipment. First XP test was corrected because the gem had already been collected; the assertion now accepts a dropped or collected gem.

Remaining verification: web controls, real browser touch, iframe, visual inspection, release pack audit, root checks and commit.

Final local proof, 2026-10-18:
- Godot 4.6.2 editor import and script parse: clean.
- Native smoke: 15 gameplay checks passed. The private mode adds four paperdoll checks. The Radclaw import verified all 32 copied files against its manifest.
- Web export: Compatibility renderer, single-thread, no extensions. All private alias directories are excluded. The PCK byte audit found no private paperdoll paths. Pinned source snapshots match SHA-256 records. No upstream art was downloaded.
- Standard skill browser client: ran twice with movement and firing. Inspected both screenshots. Replaced unsupported arrow glyphs with ASCII touch labels. Final layout readability score: 93. This is not art release approval.
- Full Chromium play: real input survived 90.02 seconds, defeated 125 sentries, fired 218 shots, reached level 7 and selected six upgrades. Final health: 100. Keyboard movement, pause freeze, restart, simultaneous two-contact CDP touch, XP and upgrade choices passed. Console/page errors: none during the full gameplay checks.
- Initial iframe checks timed out with an about:blank host. The final harness uses an HTTP test host and the root CORS server. The final opaque iframe boots the licensed default and starts with keyboard input. No allow-same-origin permission. Console/page errors: zero.
- Native comparison capture: inspected the 64px layered Radbro outfit in the same arena. Review capture stays in ignored evidence. The release default stays Radcat. The native caption identifies private art review.
- Root scripts/check.py: 9 Python tests and 9 JavaScript gameplay tests passed. Python and JavaScript syntax passed.

Local launch: python3 scripts/serve.py --directory build/godot-radbro-survivors --port 8781. URL: http://127.0.0.1:8781/.
Evidence: ignored evidence/survivors/browser/, evidence/survivors/iframe-final/, radbro-review.png and radcat-default.png. The final browser outcome is in browser/outcome.json.

Handoff limits and next work:
- Parent must integrate template.json into the shared registry and package source plus generated default assets. This lane did not edit shared catalog or build scripts.
- No push, deployment, or public release occurred.
- No physical phone/tablet, Safari, Firefox, installed app, or live host proof.
- This is a small prototype. The observed run is not a broad balance test. Audio and finished environment/enemy art remain absent.
- Final Radbro art direction and release permission remain user decisions. ART_REQUESTS.md has comparison briefs. Keep .local-assets and all review aliases out of source packages and Web PCKs.

Facing fix verified: Godot import, native gameplay smoke, web export, 13 Python checks, 17 JavaScript checks and all 12 package checks pass. Standard browser client screenshots show right travel at x579 facing right and left travel at x423 facing left. No browser errors were recorded. The local hub build and both download ZIPs are updated.

2026-10-18 local real-game art toggle:
- Added scripts/art_styles.gd to load both private hero and enemy packs once. Loading requires art_review or --art-review plus complete calibration, hero data and enemy data. The main source project does not receive review-art files.
- Added T and a visible Style button to the actual Godot survival game. Switching updates render data on the same hero and sentry nodes. New sentries inherit the selected style. Ground, projectiles, XP and UI stay shared.
- Kept native layers, hide rules, z/id order, source timings and shared character clock. The comparison defaults to the base outfit. Illustrated art uses real down/right/up/left frames; idle holds phase zero. Both styles keep constant calibrated scales. Illustrated enemy registration uses its declared per-frame anchors.
- Kept the published Radcat facing correction and older --radbro-review local proof path. Missing or disabled review data hides the Style button and leaves T as a no-op.
- Browser state adds art_style, available_art_styles, facing and live node IDs.
- Default Godot editor import and original gameplay smoke passed before the regression addition. Fallback art tests then passed five checks, including Radcat facing and unavailable-toggle behavior.
- Isolated review import passed. Thirteen art regression checks passed. They cover key/button toggles; existing/new sentry art; exact player/mob/projectile node and gameplay-state preservation; animation clocks; up-facing; pause; upgrade state; and browser state fields. Updated review smoke passed sixteen gameplay checks.
- Parent owns isolated asset staging, public/private export separation, Web build, browser/touch/sandbox proof and shared root checks. This lane did not claim those checks or commit changes.
- Known art limits remain: native has one mirrored view; illustrated has four walk phases, no true idle/hurt/attack, and enemy body-shape drift. Art review approval remains separate from this engine feature.

Final in-game style proof: 25 Chromium checks pass. A 90.02-second round won with 123 kills, six upgrades and 34 style changes. Real touch, paused state, outcomes and opaque iframe pass. The standard skill client ran and screenshots were inspected for both styles. Root checks: 16 Python and 17 JavaScript tests. All 12 release ZIPs pass package checks. Fresh source-ZIP import/smoke/fallback pass. Public PCK has zero review files. The local hub at port8780 now overlays the review PCK; release export and ZIPs remain separate. Physical devices, Safari, Firefox and a true illustrated idle clip remain outside this proof.


2026-10-19 matching full looks:
- Extended the existing Style/T toggle to the floor, gun, live bullets/trails, XP, and feedback. Hero/enemy rules and all gameplay resources stay unchanged.
- Native look reads the existing private 64px ground and 32px icon atlas without pixel edits. Visible icon extents set display size. Illustrated look optionally loads look-kit/pack.json and the original ground PNG. The floor uses 128 world-pixel cells with alternating X/Y reflections and clipped partial edge tiles.
- Added one bounded VisualEffects node. It draws original Godot muzzle, hit, defeat, pickup and upgrade feedback. No new image generation or dependency. Event lifetimes are 0.18–0.52 seconds; active count is capped at 64. Deterministic shapes do not consume game RNG.
- Live bullets and active events restyle immediately without replacement, timer reset or age reset. Pause, upgrade, won and lost states freeze effect ages. Resume continues them. Restart clears events and emitted counters.
- Snapshot uses stable visual_style, active_fx and projectiles fields. active_fx includes emitted counts and active event IDs/kinds/ages. Counters survive expiry and reset on restart. Public fallback emits no private-look effects and loads no private look data.
- Clean isolated editor import passed. Review art regression passed 28 assertions. Review gameplay smoke passed 18 assertions, including all five feedback hooks. Clean default import passed. Default art fallback passed seven assertions. Default gameplay smoke passed seventeen assertions. An earlier direct run followed asset restaging without an editor import; it emitted texture-loader errors. Repeating the required import removed those diagnostics. Do not treat a passing assertion list with loader errors as a clean run.
- Parent owns art source/generation, hash-checked importer, exports, browser/touch/sandbox proof, shared checks and integration. This lane did not commit or publish assets.


Full-look tile correction: the first illustrated Web screenshot exposed gaps and a bottom-edge spill. The reflected destination rectangles had an extra origin offset. Godot normalizes negative destination extents at the same cell origin. Removed both destination-origin shifts; kept partial mirrored source starts. Repeated the isolated editor import, 28 art checks and 18 review gameplay checks with no engine errors. Parent must re-export and inspect floor coverage and the arena/control border before claiming visual completion. Headless tests alone did not detect this draw-placement fault.

Parent full-look integration proof, 2026-10-19: Built both exports with fresh imports and zero engine errors. The initial reflected tile placement left checkerboard gaps; removed the extra destination offsets, re-exported, and inspected both final gameplay captures. The corrected floor passes1482 samples with zero holes or below-arena spill. Final browser proof:34 checks, 90.02-second win,122 kills, six upgrades,34 style changes, all five FX event types, live shot/FX restyling, pause/touch/opaque iframe. Standard skill client ran for both styles. Public PCK contains zero review files. Fresh source ZIP import, gameplay and fallback pass. All12 ZIPs pass. Root checks:19 Python+17 JavaScript. New illustrated ground remains an unchanged PNG in the ignored Radclaw full-look run;58 source files verified during import. Physical devices, Safari, Firefox, true illustrated idle and final art approval remain outside this proof.
