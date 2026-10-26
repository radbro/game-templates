extends SceneTree

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1 or not ProjectSettings.load_resource_pack(args[0]):
        fail("Cannot mount the release PCK")
        return
    var base := "res://assets/radbro-survivors-dual-style-v1/"
    var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "provenance.json"))
    var approval: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "publication.json"))
    if not approval.approved or provenance.runtimeFileCount != 60:
        fail("Release approval or runtime count is invalid")
        return
    for record in provenance.files:
        if record.role == "runtime":
            if not FileAccess.file_exists(base + record.path) and not ResourceLoader.exists(base + record.path):
                fail("Missing runtime file: " + record.path)
                return
    var files: Array[String] = []
    collect("res://", files)
    for path in files:
        if path.begins_with("res://review-art/") or path.begins_with("res://.local-assets/") or path.begins_with(base + "source/"):
            fail("Unexpected private or editor file: " + path)
            return
    if not FileAccess.file_exists(base + "LICENSE.txt"):
        fail("Missing asset permission")
        return
    print("SURVIVORS_EXPORT_AUDIT PASS files=", files.size(), " runtime=60 private=0 editor_sources=0")
    quit()

func collect(folder: String, files: Array[String]) -> void:
    var dir := DirAccess.open(folder)
    assert(dir != null)
    for name in dir.get_files():
        files.append(folder.path_join(name))
    for name in dir.get_directories():
        collect(folder.path_join(name), files)

func fail(message: String) -> void:
    push_error(message)
    quit(1)
