# Adapted from GDQuest bullet_2d.gd, MIT. Area contact is now a swept circle test.
extends Node2D
var travelled_distance := 0.0
var speed := 500.0
var damage := 1
var mobs: Array = []
var active := true

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
                body.take_damage(damage)
                queue_free()
                return
    if travelled_distance > 650:
        queue_free()

func _draw() -> void:
    draw_line(Vector2(-12, 0), Vector2.ZERO, Color("67f5d4"), 4)
    draw_circle(Vector2.ZERO, 4, Color("f5f8e6"))
