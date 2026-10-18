# Adapted from GDQuest mob.gd, MIT. Original slime art is not included.
extends CharacterBody2D
signal died(location: Vector2)
var player: Node2D
var speed := 53.0
var health := 2
var active := true
var elite := false
var hurt := 0.0

func _physics_process(delta: float) -> void:
    if not active or not is_instance_valid(player):
        return
    var direction := global_position.direction_to(player.global_position)
    velocity = direction * speed
    move_and_slide()
    hurt = maxf(0, hurt - delta)
    queue_redraw()

func take_damage(amount: int = 1) -> void:
    health -= amount
    hurt = 0.12
    if health <= 0:
        died.emit(position)
        queue_free()

func _draw() -> void:
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
