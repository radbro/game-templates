# Private render data. Public builds do not contain the review-art directory.
extends RefCounted
const ROOT := "res://review-art/"
var styles: Dictionary = {}
var calibration: Dictionary = {}

func _init() -> void:
    if not (OS.has_feature("art_review") or "--art-review" in OS.get_cmdline_user_args()):
        return
    calibration = read_json(ROOT + "calibration.json")
    if calibration.is_empty():
        return
    var native_pack := read_json(ROOT + "native-hero/pack.json")
    var illustrated_pack := read_json(ROOT + "illustrated-hero/source-manifest.json")
    if native_pack.get("schema") != "radbro-paperdoll-v1" or illustrated_pack.get("frames", []).size() != 16:
        return
    var native_textures: Dictionary = {}
    var all_parts: Array = native_pack.base.parts.duplicate()
    for item in native_pack.items:
        all_parts.append_array(item.parts)
    for part in all_parts:
        var texture := read_texture(ROOT + "native-hero/" + part.image)
        if texture == null:
            return
        native_textures[part.image] = texture
    var illustrated_textures: Dictionary = {}
    for frame in illustrated_pack.frames:
        var texture := read_texture(ROOT + "illustrated-hero/" + frame.filename)
        if texture == null:
            return
        illustrated_textures[frame.filename] = texture
    var native_enemy := read_enemy("native")
    var illustrated_enemy := read_enemy("illustrated")
    if native_enemy.is_empty() or illustrated_enemy.is_empty():
        return
    styles = {
        "native": {"pack": native_pack, "textures": native_textures, "enemy": native_enemy},
        "illustrated": {"pack": illustrated_pack, "textures": illustrated_textures, "enemy": illustrated_enemy},
    }

func read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}

func read_texture(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        return load(path) as Texture2D
    if not FileAccess.file_exists(path):
        return null
    var image := Image.load_from_file(path)
    return null if image == null or image.is_empty() else ImageTexture.create_from_image(image)

func read_enemy(style: String) -> Dictionary:
    var kit := read_json(ROOT + style + "-kit/pack.json")
    if not kit.has("enemy"):
        return {}
    var enemy: Dictionary = kit.enemy.duplicate(true)
    var texture := read_texture(ROOT + style + "-kit/" + enemy.image)
    if texture == null or enemy.get("frames", []).is_empty():
        return {}
    var visible_height := float(enemy.get("maxVisibleHeight", 0.0))
    for frame in enemy.frames:
        var rect: Dictionary = frame.frame
        if float(rect.x) < 0 or float(rect.y) < 0 or float(rect.x + rect.w) > texture.get_width() or float(rect.y + rect.h) > texture.get_height():
            return {}
        if frame.has("visibleBounds"):
            visible_height = maxf(visible_height, float(frame.visibleBounds[3] - frame.visibleBounds[1]))
    if visible_height <= 0:
        return {}
    enemy["texture"] = texture
    enemy["display_scale"] = 32.0 / visible_height
    return enemy
