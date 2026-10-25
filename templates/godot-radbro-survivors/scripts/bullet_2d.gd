# Adapted from GDQuest bullet_2d.gd, MIT. Area contact is now a swept circle test.
extends Node2D
var travelled_distance := 0.0
var speed := 500.0
var damage := 1
var mobs: Array = []
var active := true
var art_style := "radcat"
var look: Dictionary = {}
var effects: Node2D
var audio: Node

func set_art_style(style: String, data: RefCounted) -> void:
    art_style = style
    look = data.styles[style].get("look", {}) if data != null and data.styles.has(style) else {}
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if style == "native" else CanvasItem.TEXTURE_FILTER_LINEAR
    queue_redraw()

func _physics_process(delta: float) -> void:
    if not active:
        return
    var old := position
    position += Vector2.RIGHT.rotated(rotation) * speed * delta
    travelled_distance += speed * delta
    for body in mobs:
        if is_instance_valid(body) and not body.is_queued_for_deletion():
            var nearest := Geometry2D.get_closest_point_to_segment(body.position, old, position)
            if nearest.distance_to(body.position) < 17:
                if audio != null:
                    audio.play_event("hit")
                if effects != null:
                    effects.emit_effect("hit", body.position + Vector2(0, -14), rotation)
                body.take_damage(damage)
                queue_free()
                return
    if travelled_distance > 650:
        queue_free()

func _draw() -> void:
    if art_style == "native":
        draw_line(Vector2(-24, 0), Vector2(-8, 0), Color("60ddc6"), 2)
        draw_rect(Rect2(-27, -1, 3, 2), Color("4d9e9b"))
        if look.has("icons") and look.get("regions", {}).has("projectile"):
            var icon: Dictionary = look.regions.projectile
            var factor := 16.0 / float(icon.visible_width)
            var size: Vector2 = icon.region.size * factor
            draw_texture_rect_region(look.icons, Rect2(-size / 2.0, size), icon.region)
        else:
            draw_rect(Rect2(-5, -2, 8, 4), Color("d9f8b1"))
        return
    if art_style == "illustrated":
        draw_circle(Vector2.ZERO, 9, Color(0.58, 0.95, 0.68, 0.07))
        draw_circle(Vector2.ZERO, 6, Color(0.64, 0.98, 0.72, 0.15))
        draw_polyline(PackedVector2Array([Vector2(-28, 2), Vector2(-20, -1), Vector2(-12, -2), Vector2(-3, 0)]), Color(0.66, 0.95, 0.68, 0.45), 2.0, true)
        draw_line(Vector2(-13, 0), Vector2.ZERO, Color("c4e9ab"), 3, true)
        draw_circle(Vector2.ZERO, 3, Color("fff0c2"))
        return
    draw_line(Vector2(-12, 0), Vector2.ZERO, Color("67f5d4"), 4)
    draw_circle(Vector2.ZERO, 4, Color("f5f8e6"))
