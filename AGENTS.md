# Official Radbro game templates

Use short sentences and active voice. Keep each template small and editable.

- Use Radclaw as the source project for new character assets. Read docs/radclaw-workflow.md before adding a character pack.
- Keep local review candidates out of public assets until their release approval and notices are recorded.
- Preserve each source pack's native grid, anchor, frame timing, rig revision, layers, and source hashes.
- Keep code under the root MIT license.
- Keep each asset notice with that pack. The root MIT license does not cover assets.
- Do not copy art from other projects without a recorded source and permission.
- Do not change existing character identity or overwrite released asset versions.
- Do not add dependencies unless the user requests them.
- Run `python3 scripts/prepare.py` before opening a template.
- Run `python3 scripts/check.py` before each commit.
- Run the Godot smoke and web export when Godot code changes.
- Test browser controls, outcomes, real touch input, and a sandboxed iframe before release.
- Record verification limits. A desktop or headless check does not prove a browser build.
- Keep generated builds off main. The separate codex/site branch contains static publication artifacts.
- Keep engine caches, test results, and credentials out of Git.
- Use Git trailers for relevant constraints, tests, and risks in each commit.
