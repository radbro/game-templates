# Adapted from GDQuest gun.gd, MIT. Targets the nearest live enemy.
extends Node2D
const BULLET = preload("res://scripts/bullet_2d.gd")
const BALANCE = preload("res://scripts/balance.gd")
var mobs: Array = []
var projectiles: Node2D
var cooldown := 0.0
var interval := BALANCE.GUN_INTERVAL
var damage := BALANCE.GUN_DAMAGE
var shots := 0
var active := false
var art_style := "radcat"
var art_data: RefCounted
var effects: Node2D
var audio: Node

func set_art_style(style: String, data: RefCounted) -> void:
    art_style = style
    art_data = data
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if style == "native" else CanvasItem.TEXTURE_FILTER_LINEAR
    queue_redraw()

func _physics_process(delta: float) -> void:
    if not active:
        return
    cooldown -= delta
    var target: Node2D = null
    var distance := BALANCE.GUN_RANGE
    for enemy in mobs:
        if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
            var current := global_position.distance_to(enemy.global_position)
            if current < distance:
                target = enemy
                distance = current
    if target:
        look_at(target.global_position)
        if cooldown <= 0:
            shoot()
            cooldown = interval
    queue_redraw()

func shoot() -> void:
    var new_bullet := Node2D.new()
    new_bullet.set_script(BULLET)
    new_bullet.position = global_position + Vector2(28, -11).rotated(rotation)
    new_bullet.rotation = rotation
    new_bullet.damage = damage
    new_bullet.mobs = mobs
    new_bullet.effects = effects
    new_bullet.audio = audio
    new_bullet.set_art_style(art_style, art_data)
    projectiles.add_child(new_bullet)
    shots += 1
    if audio != null:
        audio.play_event("fire")
    if effects != null:
        effects.emit_effect("muzzle", new_bullet.position, rotation)

func _draw() -> void:
    if art_style == "native":
        draw_rect(Rect2(11, -16, 18, 8), Color("456f77"))
        draw_rect(Rect2(25, -14, 8, 4), Color("b4ebbd"))
        draw_rect(Rect2(12, -12, 5, 8), Color("263e4d"))
        draw_line(Vector2(18, -13), Vector2(23, -13), Color("6bf3d1"), 2)
        return
    if art_style == "illustrated":
        draw_line(Vector2(12, -11), Vector2(29, -11), Color("254b43"), 10, true)
        draw_line(Vector2(15, -13), Vector2(29, -13), Color("c4dcb1"), 3, true)
        draw_circle(Vector2(12, -8), 5, Color("527461"))
        draw_circle(Vector2(30, -11), 3, Color("e3e5b1"))
        return
    draw_line(Vector2(12, -11), Vector2(28, -11), Color("9de3d0"), 7)
    draw_circle(Vector2(12, -11), 5, Color("496f83"))
