# Adapted from GDQuest mob.gd, MIT. Original slime art is not included.
extends CharacterBody2D
signal died(location: Vector2)
var player: Node2D
var speed := 53.0
var health := 2
var active := true
var elite := false
var hurt := 0.0
var art_style := "radcat"
var enemy_art: Dictionary = {}
var art_clock := 0.0

func set_art_style(style: String, data: RefCounted) -> void:
    art_style = style
    enemy_art = data.styles[style].enemy if data.styles.has(style) else {}
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if style == "illustrated" else CanvasItem.TEXTURE_FILTER_NEAREST
    queue_redraw()

func _physics_process(delta: float) -> void:
    if not active or not is_instance_valid(player):
        return
    var direction := global_position.direction_to(player.global_position)
    velocity = direction * speed
    move_and_slide()
    art_clock += delta * 1000.0
    hurt = maxf(0, hurt - delta)
    queue_redraw()

func take_damage(amount: int = 1) -> void:
    health -= amount
    hurt = 0.12
    if health <= 0:
        died.emit(position)
        queue_free()

func _draw() -> void:
    if not enemy_art.is_empty():
        _draw_review_enemy()
        return
    # Original geometric sentry. Replace this node with a released enemy pack.
    var tint := Color("ffb45b") if elite else Color("ef697d")
    if hurt > 0:
        tint = Color.WHITE
    draw_circle(Vector2(0, 9), 15, Color(0, 0, 0, 0.25))
    draw_style_box(_body(tint), Rect2(-13, -18, 26, 28))
    draw_rect(Rect2(-9, -11, 18, 8), Color("17293d"))
    draw_circle(Vector2(-5, -7), 2, Color("f5e9a5"))
    draw_circle(Vector2(5, -7), 2, Color("f5e9a5"))
    draw_line(Vector2(-7, 10), Vector2(-11, 16), tint, 4)
    draw_line(Vector2(7, 10), Vector2(11, 16), tint, 4)

func _body(tint: Color) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = tint
    box.corner_radius_top_left = 5
    box.corner_radius_top_right = 5
    return box

func _draw_review_enemy() -> void:
    var duration := 0.0
    for frame in enemy_art.frames:
        duration += float(frame.duration)
    var time := fmod(art_clock, duration)
    var current: Dictionary = enemy_art.frames[0]
    for frame in enemy_art.frames:
        current = frame
        time -= float(frame.duration)
        if time < 0:
            break
    var rect: Dictionary = current.frame
    var anchor: Dictionary = current.get("anchor", enemy_art.anchor)
    var factor: float = enemy_art.display_scale
    draw_circle(Vector2(0, 2), 13, Color(0, 0, 0, 0.25))
    draw_texture_rect_region(enemy_art.texture, Rect2(-float(anchor.x) * factor, -float(anchor.y) * factor, float(rect.w) * factor, float(rect.h) * factor), Rect2(rect.x, rect.y, rect.w, rect.h), Color(1.7, 1.7, 1.7) if hurt > 0 else Color.WHITE)
    if elite:
        # Preserve the elite warning when a raster replaces the original orange sentry.
        draw_arc(Vector2(0, -17), 19, PI, TAU, 16, Color("ffb45b"), 2)
