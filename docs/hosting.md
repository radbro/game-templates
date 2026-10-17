# Host a browser game

The Phaser source ZIP is also a browser build.
The Godot source ZIP is an editor project. Export it before hosting.
Use the Godot `-web.zip` release asset for a browser build.

Keep `index.html` at the ZIP root.
Use relative URLs for all code, models, images, and other runtime files.
Serve JavaScript with a JavaScript MIME type.
Serve `.wasm` with `application/wasm`.
Serve `.pck` with `application/octet-stream`.

Use an iframe with `sandbox="allow-scripts allow-pointer-lock"`.
Keep same-origin access disabled.
An opaque iframe origin needs `Access-Control-Allow-Origin: *` on static game files.
The local `scripts/serve.py` includes that header.
GitHub Pages supplies the header for these public demos.

Godot uses a single-threaded Web export and Compatibility rendering.
This removes the need for cross-origin isolation headers.
The browser still needs WebGL 2 for the Godot game.
See [Godot web export requirements](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

The templates send `radbro:game-ready` after loading.
They answer `radbro:game-ready-request` only from their parent window.
A completed run sends one `radbro:game-result` message.
The platform uses `clear` for success and `gameover` for failure.
Internal game states use `won` and `lost`.
A restart permits one result for the next run.
The parent must validate the iframe source and the message payload.
If you change the game slug, change the ready and result game IDs together.

To submit to Radbro, use [the build page](https://radbro.gg/build)
or follow [the current agent guide](https://radbro.gg/skill.md).
An upload still needs an account and normal content review.
The templates contain no keys, upload credentials, or review bypass.

# Pinned Godot web runtime adjustment

Godot 4.6.2 queries the service-worker API even when PWA export is disabled.
Chrome blocks that API in an opaque-origin iframe.
`build-site.py` adds an origin check to that one runtime callback.
It applies the change only to the copied demo and web ZIP.
It keeps the engine and third-party license notices.
`godot-runtime-patch.json` records the original and changed loader hashes.
The patch fails if the expected engine code changes.
Use the packaging script when preparing a Godot build for the Radbro sandbox.
The source editor project and original engine export stay unchanged.
