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
        "native": {"pack": native_pack, "textures": native_textures, "enemy": native_enemy, "look": read_look("native")},
        "illustrated": {"pack": illustrated_pack, "textures": illustrated_textures, "enemy": illustrated_enemy, "look": read_look("illustrated")},
    }
    var idle := read_idle()
    if not idle.is_empty():
        styles.illustrated["idle"] = idle

func read_idle() -> Dictionary:
    var folder := ROOT + "animation-kit/"
    var pack := read_json(folder + "pack.json")
    if pack.get("schema") != "radbro-survivors-animation-v1" or float(pack.get("visibleHeight", 0)) <= 0:
        return {}
    var texture := read_texture(folder + str(pack.get("image", "")))
    if texture == null:
        return {}
    for direction in ["down", "right", "up", "left"]:
        var frames: Array = pack.get("clips", {}).get(direction, [])
        if frames.size() != 4:
            return {}
        for frame in frames:
            var rect: Dictionary = frame.get("rect", {})
            if float(frame.get("duration", 0)) <= 0 or not frame.has("anchor"):
                return {}
            if float(rect.get("w", 0)) <= 0 or float(rect.get("h", 0)) <= 0:
                return {}
            if float(rect.x) < 0 or float(rect.y) < 0 or float(rect.x + rect.w) > texture.get_width() or float(rect.y + rect.h) > texture.get_height():
                return {}
    return {"pack": pack, "texture": texture}

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

func read_look(style: String) -> Dictionary:
    var folder := ROOT + ("native-kit/" if style == "native" else "look-kit/")
    var pack := read_json(folder + "pack.json")
    var look: Dictionary = {"world_tile_size": 64.0 if style == "native" else 128.0}
    if pack.get("ground", {}).has("image"):
        var ground: Dictionary = pack.ground
        look["ground"] = read_texture(folder + ground.image)
        look["world_tile_size"] = float(ground.get("worldTileSize", look.world_tile_size))
        look["mirror_alternate"] = str(ground.get("repeat", "")).begins_with("mirrored")
    if style == "native" and pack.get("icons", {}).has("image"):
        var texture := read_texture(folder + pack.icons.image)
        if texture != null:
            var pixels := texture.get_image()
            if pixels.is_compressed():
                pixels.decompress()
            var regions: Dictionary = {}
            for name in pack.icons.regions:
                var rect: Dictionary = pack.icons.regions[name]
                var region := Rect2(rect.x, rect.y, rect.w, rect.h)
                var visible := pixels.get_region(Rect2i(region)).get_used_rect()
                regions[name] = {"region": region, "visible_width": maxf(1.0, visible.size.x), "visible_height": maxf(1.0, visible.size.y)}
            look["icons"] = texture
            look["regions"] = regions
    return look
