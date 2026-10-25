# Survivors release review, 2026-10-25

The playable game now has a dedicated illustrated idle, original audio, hurt feedback, and a tuned three-wave round. Both Radbro art directions remain available in the local review game. The source code and browser downloads are prepared locally. No new game or draft art has been published.

## Play and compare

Open `http://127.0.0.1:8780/godot-radbro-survivors/index.html`.
Start the round. Press T or use Style to compare the full looks. Press M or use Sound to mute. Mute remains selected after restart. Pause and upgrade selection freeze the backing track. The new idle has four directions, breathing, and a short blink. Original walk frames and native paperdoll bytes stay unchanged.

The raw idle atlas has unequal row spacing. Explicit rectangles use the transparent gaps between rows. Per-frame floor anchors keep the feet in place. No crop, resize, or pixel edit was applied to the source PNG. The original image, prompt, reference hashes, frame metadata, and manifest are in `radclaw/runs/2026-10-25-survivors-idle`.

## Prepared files

| Files | Contents | Location |
| --- | --- | --- |
| `godot-radbro-survivors-source.zip` and `godot-radbro-survivors-web.zip` | Portable code and published Radcat default. No draft Radbro assets. | `dist/` and `dist/site/` |
| `radbro-survivors-local-review-source.zip` and `radbro-survivors-local-review-web.zip` | Same game with both unpublished Radbro looks and the new idle. | `build/local-review/` only |
| `RELEASE.json` and `README.md` | Candidate hashes, test evidence, and release limits. | `dist/survivors-release/` |

The local source ZIP includes the art import receipt, notices, and `REVIEW_ONLY.md`. Run it in Godot 4.6.2 with `--art-review`. Its export preset sets `art_review`. The public source ZIP uses Radcat without any private asset folder. Source ZIPs include editable scripts, scenes, and asset notices. Web ZIPs include Godot engine notices.

The local web overlay changes only the served game. Public download ZIPs retain the public PCK. `scripts/build-site.py` restores the default catalog. Then `scripts/build_survivors_review.py` can restore the local comparison. See [the comparison command](parallel-games.md#play-both-styles-in-survivors).

## Verification

Godot 4.6.2 passed fresh imports, gameplay, art fallback, audio, seeded balance, and release integration checks. The balance fixture passed 26 checks across seven complete rounds. All three seeded idle policies lost. All three moving policies won. The repeated seed produced the same result. These bot outcomes do not establish final human difficulty.

Chromium passed 38 full-look comparison checks and 18 audio/animation checks. It exercised real keyboard input, simultaneous touch input, pause, upgrades, restarts, live style changes, and an opaque sandbox iframe. The moving browser run won at 90.02 seconds with 148 kills, seven upgrades, 36 style changes, and 73.4 health. The idle browser run lost at 31.35 seconds. Both runs reported zero console or page errors.

The audio browser checks used an explicit virtual output sink. Chromium's normal audio device stalls on this machine, including for a plain oscillator. The virtual sink runs the real browser audio graph. It measured nonzero PCM after Start and on defeat, zero output during mute and pause, and restored output on unmute. The product code uses the normal browser output device. Physical speaker audibility remains unverified. See [audio details](survivors-audio.md).

The standard web-game client also ran both styles. Its gameplay captures were inspected. It used the same labelled test-only virtual sink. The final header has a clear gap above the HUD. Both grounds cover the arena. The dedicated idle keeps a stable floor anchor and walk scale. Small generated pose differences remain visible for art review.

Root checks pass 23 Python tests and 17 JavaScript tests. All six source ZIPs and six web ZIPs pass entry, notice, and path checks. Public PCK inspection finds zero review files. Fresh extracted public and local review source projects also pass import and engine checks. The public browser build passes 11 additional keyboard, touch, outcome, and opaque iframe checks.

## Remaining release decisions

The user has kept both directions for comparison. Final art choice and public art release approval remain open. Enemy identity refinements, dedicated attack poses, and upgrade UI art remain in the [art queue](../templates/godot-radbro-survivors/ART_REQUESTS.md). Enemies enter from outside the arena and can cross its border while entering. Physical devices, Safari, Firefox, human sound judgment, and live hosting are outside this proof.

Original synthesis code and note data use MIT. No third-party recording or sample is included. Asset notices remain separate from the code license. The local candidate files do not grant public redistribution rights for draft art.
