# Adapted from GDQuest gun.gd, MIT. Targets the nearest live enemy.
extends Node2D
const BULLET = preload("res://scripts/bullet_2d.gd")
var mobs: Array = []
var projectiles: Node2D
var cooldown := 0.0
var interval := 0.45
var damage := 1
var shots := 0
var active := false

func _physics_process(delta: float) -> void:
    if not active:
        return
    cooldown -= delta
    var target: Node2D = null
    var distance := 440.0
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
    projectiles.add_child(new_bullet)
    shots += 1

func _draw() -> void:
    draw_line(Vector2(12, -11), Vector2(28, -11), Color("9de3d0"), 7)
    draw_circle(Vector2(12, -11), 5, Color("496f83"))
