extends CharacterBody3D
## Adapted from Kenney's MIT starter. The body moves; the intact model animates.
signal coin_collected(coins: int)
signal fell
@export var view: Node3D
@export var movement_speed := 6.0
@export var jump_strength := 8.0
var enabled := false
var coins := 0
var jumps_left := 2
var animation: AnimationPlayer
@onready var model: Node3D = $Character

func _ready() -> void:
    animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
    for motion in ["idle", "walk", "jog"]:
        animation.get_animation(motion).loop_mode = Animation.LOOP_LINEAR
    play_motion("idle")

func _physics_process(delta: float) -> void:
    if not enabled:
        return
    if is_on_floor() and velocity.y <= 0:
        jumps_left = 2
    var direction := Vector3(Input.get_axis("move_left", "move_right"), 0, Input.get_axis("move_forward", "move_back"))
    direction = direction.limit_length().rotated(Vector3.UP, view.rotation.y)
    velocity.x = move_toward(velocity.x, direction.x * movement_speed, 35 * delta)
    velocity.z = move_toward(velocity.z, direction.z * movement_speed, 35 * delta)
    velocity.y -= 22 * delta
    if Input.is_action_just_pressed("jump"):
        jump()
    move_and_slide()
    if direction.length() > 0.1:
        model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), delta * 15)
    play_motion("hop" if not is_on_floor() else ("jog" if direction.length() > 0.1 else "idle"))
    if position.y < -8:
        fell.emit()

func jump() -> void:
    if enabled and jumps_left > 0:
        jumps_left -= 1
        velocity.y = jump_strength
        animation.stop()
        play_motion("hop")
        Audio.play("res://sounds/jump.ogg")

func play_motion(motion: String) -> void:
    if animation.current_animation != motion:
        animation.play(motion, 0.1)

func collect_coin() -> bool:
    if not enabled:
        return false
    coins += 1
    coin_collected.emit(coins)
    return true
