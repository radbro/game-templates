extends QuiverCharacterVisual
## A single published Radcat view. Horizontal travel mirrors the whole sprite.
## Weapon direction stays independent from the character artwork.

var sprite: Sprite2D
var clips: Dictionary = {}
var clip := "idle"
var clock := 0.0
var frame_index := 0
@onready var weapon = $DistanceWeapon

func _ready() -> void:
	$Head.hide()
	$Body.hide()
	$Hat.hide()
	$Shadow.hide()
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.position = Vector2(-53.333, -100)
	sprite.scale = Vector2.ONE / 3.0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	for name in ["idle", "walk"]:
		var path: String = "res://assets/radcat-motion-v2/sprites/" + name + "-sheet"
		var metadata = JSON.parse_string(FileAccess.get_file_as_string(path + ".json"))
		clips[name] = {"texture": load(path + ".png"), "frames": metadata.frames.values()}
	_set_clip("idle")

func _set_clip(next: String) -> void:
	clip = next
	clock = 0.0
	frame_index = 0
	sprite.texture = clips[clip].texture
	sprite.region_enabled = true
	_apply_frame()

func _apply_frame() -> void:
	var rect: Dictionary = clips[clip].frames[frame_index].frame
	sprite.region_rect = Rect2(rect.x, rect.y, rect.w, rect.h)

func _process(delta: float) -> void:
	clock += delta * 1000.0
	var frames: Array = clips[clip].frames
	while clock >= float(frames[frame_index].duration):
		clock -= float(frames[frame_index].duration)
		frame_index = (frame_index + 1) % frames.size()
	_apply_frame()

func update_visual(action: QuiverCharacterAction) -> void:
	var next := "walk" if action.moving_direction.length() > 0 else "idle"
	if sprite == null:
		return
	if next != clip:
		_set_clip(next)
	if action.moving_direction.x != 0:
		sprite.flip_h = action.moving_direction.x < 0
	if action.aiming_direction.length() > 0:
		weapon.shoot_direction = action.aiming_direction.normalized()

func _on_head_animation_finished() -> void:
	pass
