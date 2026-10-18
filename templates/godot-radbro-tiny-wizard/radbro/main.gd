extends Node2D
## A small campaign built from Quiver's actual room, character, weapon and item systems.

const PLAYER = preload("res://tiny_wizard/player/player_character.tscn")
const ROOM = preload("res://tiny_wizard/room/room.tscn")
const RED_FLY = preload("res://tiny_wizard/enemies/red_fly/red_fly.tscn")
const BLACK_FLY = preload("res://tiny_wizard/enemies/black_fly/black_fly.tscn")
const KEY = preload("res://tiny_wizard/items/key/key.tscn")
const HEART = preload("res://tiny_wizard/items/hearts/full_heart.tscn")
const UPGRADE = preload("res://tiny_wizard/items/violet_arrow/violet_arrow.tscn")

var player: QuiverCharacter
var room: Room
var phase := "playing"
var wave := 0
var remaining := 0
var hud: Label
var banner: Label
var pause_button: Button
var touch_ids: Dictionary = {}
var key_spawned := false
var credits: PanelContainer
var shots := 0
var elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	room = ROOM.instantiate()
	room.position = Vector2(0, 110)
	room.hide_left_door = true
	room.hide_right_door = true
	room.hide_down_door = true
	room.hide_up_door = false
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(room)
	room.update_doors()
	room.door_entered.connect(_door_entered)
	player = PLAYER.instantiate()
	player.position = Vector2(512, 500)
	player.character_stats = player.character_stats.duplicate()
	player.inventory = player.inventory.duplicate(true)
	player.physics_stats = player.physics_stats.duplicate()
	player.physics_stats.max_speed = 260.0
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.character_stats.died.connect(func(): _finish("lost"))
	player.get_node("Visual/DistanceWeapon").shoot_delay = 0.22
	player.shoot.connect(func(): shots += 1)
	_create_ui()
	_spawn_item(HEART, Vector2(210, 480))
	_spawn_item(UPGRADE, Vector2(810, 480))
	_start_wave()

func _start_wave() -> void:
	wave += 1
	remaining = 3 if wave == 1 else 4
	for i in range(remaining):
		var enemy: QuiverCharacter = (RED_FLY if i % 2 == 0 else BLACK_FLY).instantiate()
		enemy.position = Vector2(260 + i * 145, 200 + (i % 2) * 90)
		enemy.character_stats = enemy.character_stats.duplicate()
		enemy.character_stats.max_life = 2 if wave == 1 else 3
		enemy.physics_stats = enemy.physics_stats.duplicate()
		enemy.physics_stats.max_speed = 105.0
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.tree_exited.connect(_enemy_removed)
		room.get_node("Enemies").add_child(enemy)
	room.enter_room()

func _enemy_removed() -> void:
	if phase != "playing" or not is_inside_tree():
		return
	remaining -= 1
	if remaining == 0:
		if wave == 1:
			_start_wave.call_deferred()
		else:
			key_spawned = true
			_spawn_item.call_deferred(KEY, Vector2(512, 365))

func _spawn_item(scene: PackedScene, location: Vector2) -> void:
	var item = scene.instantiate()
	item.position = location
	item.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(item)

func _door_entered(direction: Vector2) -> void:
	if direction == Vector2.UP and phase == "playing" and remaining == 0 and player.inventory.get_item_amount("Key") > 0:
		player.inventory.remove_item("Key")
		_finish("won")

func _finish(result: String) -> void:
	if phase == "won" or phase == "lost":
		return
	phase = result
	get_tree().paused = true
	banner.text = "VAULT CLEARED\nThe Radbro relic is safe.\nPress R or Restart." if result == "won" else "RUN ENDED\nKeep moving. Aim before the swarm closes.\nPress R or Restart."
	banner.show()
	pause_button.disabled = true

func toggle_pause() -> void:
	if phase in ["won", "lost"]:
		return
	credits.hide()
	get_tree().paused = not get_tree().paused
	phase = "paused" if get_tree().paused else "playing"
	banner.text = "PAUSED\nPress P, Escape, or Resume."
	banner.visible = get_tree().paused
	pause_button.text = "Resume" if get_tree().paused else "Pause"
	_clear_touch()

func restart() -> void:
	phase = "restarting"
	_clear_touch()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _process(delta: float) -> void:
	if phase == "playing":
		elapsed += delta
	if is_instance_valid(player):
		var key_count = player.inventory.get_item_amount("Key")
		var goal := "Clear two waves" if not key_spawned else ("Take the key" if key_count == 0 else "Escape through the north door")
		if phase == "won":
			goal = "Vault cleared"
		hud.text = "RADBRO / TINY WIZARD     %d / %d HP     WAVE %d / 2     %d ENEMIES\n%s   |   WASD move · arrows aim · mouse hold fires · R restart" % [player.character_stats.current_life, player.character_stats.max_life, wave, remaining, goal]
		if key_spawned and key_count > 0:
			room.open_door(Room.Direction.UP)
		elif key_spawned:
			room.close_door(Room.Direction.UP)
	elif phase == "lost":
		hud.text = "RADBRO / TINY WIZARD     0 / 6 HP     WAVE %d / 2\nRun ended. Press R or Restart." % wave
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.radbroState=" + JSON.stringify(state()), true)

func state() -> Dictionary:
	return {"phase": phase, "wave": wave, "enemies": remaining, "fireRequests": shots, "seconds": elapsed,
		"hp": player.character_stats.current_life if is_instance_valid(player) else 0,
		"key": player.inventory.get_item_amount("Key") if is_instance_valid(player) else 0,
		"position": [player.position.x, player.position.y] if is_instance_valid(player) else [],
		"touches": touch_ids.size(), "key_spawned": key_spawned,
		"targets": room.get_node("Enemies").get_children().map(func(enemy): return [enemy.global_position.x, enemy.global_position.y]),
		"target_velocities": room.get_node("Enemies").get_children().map(func(enemy): return [enemy.velocity.x, enemy.velocity.y]),
		"weapon": player.get_node("Visual/DistanceWeapon").bullet_scene.resource_path if is_instance_valid(player) else ""}

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart()
		elif event.keycode in [KEY_P, KEY_ESCAPE]:
			toggle_pause()
	if event is InputEventScreenTouch:
		if event.pressed:
			if phase == "playing" and event.position.y > 590:
				touch_ids[event.index] = event.position
		else:
			touch_ids.erase(event.index)
		_update_touch()
	elif event is InputEventScreenDrag and touch_ids.has(event.index):
		touch_ids[event.index] = event.position
		_update_touch()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_touch()
		if phase == "playing":
			toggle_pause()

func _clear_touch() -> void:
	touch_ids.clear()
	if is_instance_valid(player):
		player.behavior.touch_move = Vector2.ZERO
		player.behavior.touch_aim = Vector2.ZERO

func _update_touch() -> void:
	if not is_instance_valid(player):
		return
	player.behavior.touch_move = Vector2.ZERO
	player.behavior.touch_aim = Vector2.ZERO
	for point: Vector2 in touch_ids.values():
		if point.x < 512:
			player.behavior.touch_move = ((point - Vector2(170, 705)) / 70).limit_length()
		else:
			player.behavior.touch_aim = ((point - Vector2(850, 705)) / 70).limit_length()

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color("101b2b")
	panel.position = Vector2.ZERO
	panel.size = Vector2(1024, 105)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(24, 19)
	hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(hud)
	pause_button = _button("Pause", Vector2(785, 65), toggle_pause, layer)
	_button("Restart", Vector2(890, 65), restart, layer)
	banner = Label.new()
	banner.position = Vector2(230, 260)
	banner.size = Vector2(564, 180)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 28)
	banner.add_theme_color_override("font_outline_color", Color("07101c"))
	banner.add_theme_constant_override("outline_size", 20)
	banner.hide()
	layer.add_child(banner)
	for pair in [["MOVE", Vector2(170, 705)], ["AIM + FIRE", Vector2(850, 705)]]:
		var label := Label.new()
		label.text = pair[0] + "\n+"
		label.position = pair[1] - Vector2(65, 30)
		label.size = Vector2(130, 60)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.modulate = Color("9db1ce")
		layer.add_child(label)
	_button("Credits", Vector2(465, 720), _show_credits, layer)
	credits = PanelContainer.new()
	credits.position = Vector2(115, 130)
	credits.size = Vector2(794, 550)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.035, 0.06, 0.98)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	credits.add_theme_stylebox_override("panel", panel_style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	credits.add_child(scroll)
	var content := Label.new()
	content.custom_minimum_size = Vector2(730, 0)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_size_override("font_size", 16)
	content.text = FileAccess.get_file_as_string("res://CREDITS.txt")
	scroll.add_child(content)
	credits.hide()
	layer.add_child(credits)
	var credit := Label.new()
	credit.text = "Quiver code: MIT · Quiver art: CC BY 4.0 · Radcat: Radbro Community Asset Permission"
	credit.position = Vector2(145, 780)
	credit.add_theme_font_size_override("font_size", 13)
	layer.add_child(credit)

func _button(text: String, position_value: Vector2, callback: Callable, layer: CanvasLayer) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position_value
	button.size = Vector2(95, 32)
	button.pressed.connect(callback)
	layer.add_child(button)
	return button

func _show_credits() -> void:
	if phase == "playing":
		toggle_pause()
	credits.visible = not credits.visible
	banner.visible = get_tree().paused and not credits.visible
