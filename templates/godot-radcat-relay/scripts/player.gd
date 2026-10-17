extends CharacterBody3D
## Move the body. Keep the complete imported animation and morph scene inside it.
@export var speed := 5.5
var hop_remaining := 0.0
var hop_cooldown := 0.0
var enabled := true
var animation_player: AnimationPlayer
@onready var model: Node3D = $Model

func _ready() -> void:
    animation_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
    if animation_player != null:
        for name in animation_player.get_animation_list():
            if name in ["idle", "walk", "jog"]:
                animation_player.get_animation(name).loop_mode = Animation.LOOP_LINEAR
    play_motion("idle")

func _physics_process(delta: float) -> void:
    step(delta)

func step(delta: float) -> void:
    if not enabled:
        velocity = Vector3.ZERO
        play_motion("idle")
        return
    hop_cooldown = maxf(0.0, hop_cooldown - delta)
    hop_remaining = maxf(0.0, hop_remaining - delta)
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    direction = direction.limit_length()
    if Input.is_action_just_pressed("hop"):
        hop()
    velocity.x = direction.x * speed
    velocity.z = direction.y * speed
    velocity.y -= 18.0 * delta
    if is_on_floor() and velocity.y < 0.0:
        velocity.y = 0.0
    move_and_slide()
    model.position.y = 0.72 + sin((1.0 - hop_remaining / 0.65) * PI) * 0.85 if hop_remaining > 0.0 else 0.72
    if direction.length() > 0.1:
        model.rotation.y = atan2(direction.x, direction.y)
    play_motion("hop" if hop_remaining > 0.0 else ("jog" if direction.length() > 0.1 else "idle"))

func hop() -> void:
    if enabled and hop_cooldown <= 0.0:
        hop_remaining = 0.65
        hop_cooldown = 1.0

func play_motion(motion: String) -> void:
    if animation_player == null:
        return
    for animation in animation_player.get_animation_list():
        if animation == motion or animation.ends_with("/" + motion):
            if animation_player.current_animation != animation:
                animation_player.play(animation, 0.1)
            return
