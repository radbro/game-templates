extends Node3D
## Kenney's falling platform. Delay gives the player time to jump.
var falling := false
var fall_velocity := 0.0
var delay := 0.45
var start_position: Vector3
func _ready() -> void:
    start_position = position
func _physics_process(delta: float) -> void:
    if falling:
        delay -= delta
        if delay <= 0:
            fall_velocity += 15 * delta
            position.y -= fall_velocity * delta
func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player") and not falling:
        falling = true
        Audio.play("res://sounds/fall.ogg")
func reset() -> void:
    position = start_position
    falling = false
    fall_velocity = 0
    delay = 0.45
