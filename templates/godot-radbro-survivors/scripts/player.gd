# Adapted from GDQuest player.gd, MIT. See ../upstream/LICENSE.txt.
extends CharacterBody2D
signal health_depleted
signal damaged
const BALANCE = preload("res://scripts/balance.gd")
var health := BALANCE.PLAYER_HEALTH
var max_health := BALANCE.PLAYER_HEALTH
var speed := BALANCE.PLAYER_SPEED
var hurt_clock := 0.0
var direction := Vector2.ZERO
var arena := Rect2(40, 150, 880, 380)
var active := false
var mobs: Array = []
var visual: Node2D

func _physics_process(delta: float) -> void:
    if not active:
        return
    hurt_clock = maxf(0.0, hurt_clock - delta)
    direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()
    position = position.clamp(arena.position, arena.end)
    visual.moving = velocity.length() > 0.0
    visual.face_direction(direction)
    var overlapping_mobs := 0
    for mob in mobs:
        if is_instance_valid(mob) and position.distance_to(mob.position) < 24:
            overlapping_mobs += 1
    if overlapping_mobs:
        health = maxf(0.0, health - BALANCE.CONTACT_DPS * overlapping_mobs * delta)
        if hurt_clock <= 0:
            hurt_clock = 0.3
            damaged.emit()
        if health <= 0.0:
            health_depleted.emit()
