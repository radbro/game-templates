extends Area3D
## Kenney coin motion and contact collection, with reset support.
var time := 0.0
var grabbed := false
var base_y := 0.0
func _ready() -> void:
    base_y = position.y
func _on_body_entered(body: Node3D) -> void:
    if not grabbed and body.has_method("collect_coin") and body.collect_coin():
        Audio.play("res://sounds/coin.ogg")
        grabbed = true
        hide()
func _process(delta: float) -> void:
    rotate_y(2 * delta)
    time += delta
    position.y = base_y + sin(time * 5) * 0.12
func reset() -> void:
    grabbed = false
    show()
