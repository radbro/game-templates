# Adapted from GDQuest player.gd, MIT. See ../upstream/LICENSE.txt.
extends CharacterBody2D
signal health_depleted
var health := 100.0
var max_health := 100.0
var speed := 180.0
var direction := Vector2.ZERO
var arena := Rect2(40, 150, 880, 380)
var active := false
var mobs: Array = []
var visual: Node2D

func _physics_process(delta: float) -> void:
    if not active:
        return
    direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()
    position = position.clamp(arena.position, arena.end)
    visual.moving = velocity.length() > 0.0
    if direction.x != 0:
        visual.scale.x = -absf(visual.scale.x) if direction.x < 0 else absf(visual.scale.x)
    var overlapping_mobs := 0
    for mob in mobs:
        if is_instance_valid(mob) and position.distance_to(mob.position) < 24:
            overlapping_mobs += 1
    if overlapping_mobs:
        health = maxf(0.0, health - 14.0 * overlapping_mobs * delta)
        if health <= 0.0:
            health_depleted.emit()
