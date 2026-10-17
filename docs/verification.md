# Release verification

Release: v0.1.1. Date: 2026-10-17.

## Source and asset checks

`python3 scripts/check.py` runs 18 unit tests and source syntax checks.
Nine Node tests check the Phaser rules.
Nine Python tests check pack identity, sprite timing, licenses, vendor bytes,
repeatable arena generation, and the Godot web runtime guard.

The two original GLBs match the published Radbro runtime hashes.
The Radcat source archive also matches its published hash.
`assets/catalog.json` records the included file bytes.
The source PNG and animation JSON files retain their published bytes.

## Godot engine checks

Godot 4.6.2 imports both GLBs.
The gameplay smoke checks 17 bones, 35 morph targets, four animations,
movement, multi-touch, pause, barriers, walls, hazard damage, hop protection,
pickup contacts, the return gate, restart, timeout, and state JSON.
The Compatibility, single-thread Web release export builds successfully.

The packaged web runtime includes one documented PWA callback guard.
The guard avoids querying an unavailable service-worker API in an opaque iframe.
The normal-origin callback remains unchanged.
See [Hosting](hosting.md) and the web build's `godot-runtime-patch.json`.

## Browser checks

`tests/browser-smoke.mjs` checks the packaged demo site.
The local browser is Google Chrome on macOS.
The workflow is configured to repeat these checks with Chromium on Linux.
The first hosted job could not start because GitHub reported an organization billing lock.
Linux CI has not passed for this release.

- Phaser: fullscreen entry and Escape exit, full keyboard route, all five cells, gate success, pause, restart, timeout, and frozen terminal state.
- Godot: full keyboard route, all four cells, hop, gate success, pause, restart, hazard loss, and frozen terminal movement.
- Both games: start and pause with the real touchscreen API in a 390-pixel touch context.
- Both games: simultaneous touch movement and hop.
- Both games: startup ready message, ready-request reply, and one result per completed run.
- Both games: load inside `allow-scripts allow-pointer-lock` with an opaque origin.
- Browser run: no page errors, failed resources, or console errors.

These checks use browser touch input. They do not prove physical-phone performance.

## Package checks

`python3 scripts/check-packages.py` checks all three release ZIPs.
It checks each entry point, full asset notices, code notice, engine notices,
and absence of local engine caches or test evidence.
The source ZIPs include their gameplay tests.
The Phaser source ZIP is also a static browser build.
The Godot source ZIP is an editor project.
The Godot web ZIP contains the exported runtime.

## Remaining limits

Physical iOS and Android devices have not been tested.
Safari and Firefox have not been tested in this release.
The Godot browser game needs WebGL 2.
The samples have no audio pack, multiplayer, persistence, or editor plug-ins.
Unity and Unreal templates are not part of this release.
Each future engine needs its own editable project and export proof.

## Publication proof

The public repository is `radbro/game-templates`.
Release `v0.1.1` contains both source ZIPs, the Godot web ZIP, the asset catalog,
and `SHA256SUMS`. The public download hashes match the local release files.

GitHub Pages serves the tested static files from the separate `codex/site` branch.
The Pages build and deployment passed.
The source tree on `main` keeps generated builds ignored.
The initial custom verification workflow could not start because of the billing lock.
Do not treat that blocked run as a passed Linux check.

After the billing lock is resolved, change Pages to the `workflow` build type
and run `Verify templates and publish demos` to restore the automatic release path.

Release `v0.1.1` adds explicit Escape handling for Phaser fullscreen exit.
The original `v0.1.0` downloads remain available.
