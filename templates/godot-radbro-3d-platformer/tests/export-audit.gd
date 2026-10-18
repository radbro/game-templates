extends SceneTree
## Run from an empty project with --script ABSOLUTE_PATH -- ABSOLUTE_PCK.
## The four private-art folders must contain private-proof-sentinel.txt at export.
func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1 or not ProjectSettings.load_resource_pack(args[0]):
        push_error("Supply one readable PCK path.")
        quit(1)
        return
    var failures := []
    for required in ["CREDITS.txt", "LICENSE.md", "PROJECT-LICENSE.txt", "UPSTREAM-README.md", "GODOT-LICENSE.txt", "GODOT-COPYRIGHT.txt", "fonts/license.txt", "assets/radcat-motion-v2/LICENSE.txt", "assets/radcat-motion-v2/pack.json"]:
        if not FileAccess.file_exists("res://" + required):
            failures.append("Missing distributed notice: " + required)
    for folder in [".local-assets", "local-assets", ".review-assets", "review-assets"]:
        if FileAccess.file_exists("res://" + folder + "/private-proof-sentinel.txt"):
            failures.append("Private art entered export: " + folder)
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("PASS: PCK includes nine required notice/metadata files and excludes private-art sentinels in all four folder aliases.")
    quit(0 if failures.is_empty() else 1)
