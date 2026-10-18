extends QuiverCharacterBehavior

var touch_move := Vector2.ZERO
var touch_aim := Vector2.ZERO

func _physics_process(_delta: float) -> void:
	action.moving_direction = Input.get_vector("player_left", "player_right", "player_up", "player_down")
	if touch_move != Vector2.ZERO:
		action.moving_direction = touch_move
	action.aiming_direction = Input.get_vector("player_shoot_left", "player_shoot_right", "player_shoot_up", "player_shoot_down")
	if touch_aim != Vector2.ZERO:
		action.aiming_direction = touch_aim
	elif Input.is_action_pressed("fire"):
		action.aiming_direction = get_parent().global_position.direction_to(get_global_mouse_position())
	action.shoot = action.aiming_direction.length() > 0
