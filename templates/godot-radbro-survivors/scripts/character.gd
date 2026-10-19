# Published Radcat sprites by default. Optional local paperdoll uses one shared clock.
extends Node2D
var moving := false
var clock := 0.0
var clip := "idle"
var pack: Dictionary = {}
var parts: Array = []
var equipped: Array = []
var textures: Dictionary = {}
var local_root := "res://.local-assets/radbro/"
var using_paperdoll := false
var art_style := "radcat"
var art_data: RefCounted
var facing := "right"
var horizontal_direction := 1.0

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    if "--radbro-review" in OS.get_cmdline_user_args() and FileAccess.file_exists(local_root + "pack.json"):
        pack = JSON.parse_string(FileAccess.get_file_as_string(local_root + "pack.json"))
        using_paperdoll = pack.get("schema") == "radbro-paperdoll-v1"
        if using_paperdoll:
            art_style = "native-local"
            equip(pack.defaults)
    if not using_paperdoll:
        for name in ["idle", "walk"]:
            textures[name] = load("res://assets/radcat-motion-v2/sprites/" + name + "-sheet.png")
    face_horizontal(1.0)

func set_art_style(style: String, data: RefCounted) -> void:
    if not data.styles.has(style):
        return
    art_data = data
    art_style = style
    using_paperdoll = style == "native"
    if using_paperdoll:
        pack = data.styles.native.pack
        textures = data.styles.native.textures
        equip([])
    else:
        textures = data.styles.illustrated.textures
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if using_paperdoll else CanvasItem.TEXTURE_FILTER_LINEAR
    _apply_facing()
    queue_redraw()

func face_direction(direction: Vector2) -> void:
    if direction == Vector2.ZERO:
        return
    if direction.x != 0:
        horizontal_direction = direction.x
    if absf(direction.x) >= absf(direction.y):
        facing = "left" if direction.x < 0 else "right"
    else:
        facing = "up" if direction.y < 0 else "down"
    _apply_facing()

func face_horizontal(direction: float) -> void:
    face_direction(Vector2(direction, 0))

func _apply_facing() -> void:
    # Illustrated art has true left frames. Radcat's published sheet faces left.
    var mirrored := false
    if art_style != "illustrated":
        mirrored = horizontal_direction < 0.0 if using_paperdoll else horizontal_direction > 0.0
    scale.x = -absf(scale.x) if mirrored else absf(scale.x)

func equip(ids: Array) -> void:
    # Last selected item wins in each slot. Apply hides before merging and sorting.
    var by_slot: Dictionary = {}
    for id in ids:
        for item in pack.items:
            if item.id == id:
                by_slot[item.slot] = item
    var hidden_slots: Array = []
    var hidden_parts: Array = []
    for item in by_slot.values():
        hidden_slots.append_array(item.get("hidesSlots", []))
    equipped = []
    for slot in by_slot:
        if slot not in hidden_slots:
            equipped.append(by_slot[slot])
            hidden_parts.append_array(by_slot[slot].get("hideBaseParts", []))
    parts = []
    for part in pack.base.parts:
        if part.id not in hidden_parts:
            parts.append(part)
    for item in equipped:
        parts.append_array(item.parts)
    parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.z < b.z or (a.z == b.z and a.id < b.id))
    if art_style == "native-local":
        for part in parts:
            textures[part.image] = ImageTexture.create_from_image(Image.load_from_file(local_root + part.image))

func _process(delta: float) -> void:
    var next_clip := "walk" if moving else "idle"
    if next_clip != clip:
        clip = next_clip
        clock = 0
    clock += delta * 1000.0
    queue_redraw()

func paperdoll_frame() -> int:
    var spec: Dictionary = pack.clips[0]
    for candidate in pack.clips:
        if candidate.name == clip:
            spec = candidate
    var duration := 0.0
    for index in range(int(spec.from), int(spec.to) + 1):
        duration += float(pack.frames[index].duration)
    var time := fmod(clock, duration) if spec.loop else minf(clock, duration - 0.01)
    for index in range(int(spec.from), int(spec.to) + 1):
        time -= float(pack.frames[index].duration)
        if time < 0:
            return index
    return int(spec.to)

func _draw() -> void:
    draw_circle(Vector2(0, 2), 15, Color(0, 0, 0, 0.26))
    if art_style == "illustrated":
        var manifest: Dictionary = art_data.styles.illustrated.pack
        var index := int(clock / float(manifest.frameDurationMs)) % 4 if moving else 0
        var filename := "walk_%s-%02d.png" % [facing, index]
        var anchor: Dictionary = art_data.calibration.illustrated.displayAnchor
        var factor := 56.0 / float(art_data.calibration.illustrated.visibleHeight)
        draw_texture_rect(textures[filename], Rect2(-float(anchor.x) * factor, -float(anchor.y) * factor, 512 * factor, 512 * factor), false)
    elif using_paperdoll:
        var frame: Dictionary = pack.frames[paperdoll_frame()].frame
        var factor := 1.0
        if art_style == "native":
            factor = 56.0 / float(art_data.calibration.native.outfitCalibration.base.visibleHeight)
        for part in parts:
            draw_texture_rect_region(textures[part.image], Rect2(-float(pack.anchor.x) * factor, -float(pack.anchor.y) * factor, float(pack.frameSize.w) * factor, float(pack.frameSize.h) * factor), Rect2(frame.x, frame.y, frame.w, frame.h))
    elif textures.has(clip):
        var duration := 300.0 if clip == "idle" else 120.0
        var index := int(clock / duration) % 6
        draw_texture_rect_region(textures[clip], Rect2(-35, -62, 70, 70), Rect2(index * 320, 0, 320, 320))
