extends Node3D
## Radbro's compact course uses Kenney's platform and coin scenes.
const GAME := "godot-radbro-3d-platformer"
var state := "ready"
var elapsed := 0.0
var total := 6
var callbacks: Array[JavaScriptObject] = []
var bridge: JavaScriptObject
var status: Label
var hint: Label
var start_button: Button
var pause_button: Button
var coins: Array[Node3D] = []
var falling: Node3D
var finish_gate: Area3D
var result_sent := false
@onready var player = $Player

func _ready() -> void:
    _bind_input()
    _build_course()
    _build_hud()
    player.fell.connect(func(): finish("lost"))
    _set_active(false)
    _install_bridge()
    _send_ready()
    _update_hud()

func _bind_input() -> void:
    var keys := {"move_left": [KEY_A], "move_right": [KEY_D], "move_forward": [KEY_W], "move_back": [KEY_S], "camera_left": [KEY_Q, KEY_LEFT], "camera_right": [KEY_E, KEY_RIGHT], "jump": [KEY_SPACE], "pause_round": [KEY_ESCAPE, KEY_P], "restart_round": [KEY_R], "start_round": [KEY_ENTER]}
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key in keys[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action, event)
    var jump_button := InputEventJoypadButton.new()
    jump_button.button_index = JOY_BUTTON_A
    InputMap.action_add_event("jump", jump_button)
    var pause_event := InputEventJoypadButton.new()
    pause_event.button_index = JOY_BUTTON_START
    InputMap.action_add_event("pause_round", pause_event)

func _build_course() -> void:
    for index in total:
        var platform: Node3D = load("res://objects/platform_falling.tscn" if index == 3 else "res://objects/platform.tscn").instantiate()
        platform.name = "Island%d" % index
        platform.position = Vector3(0, index * 0.2, -index * 6)
        platform.scale = Vector3(2.3, 1, 2)
        $World.add_child(platform)
        if index == 3:
            falling = platform
        var coin: Node3D = load("res://objects/coin.tscn").instantiate()
        coin.position = Vector3(0, index * 0.2 + 0.8, -index * 6)
        $World.add_child(coin)
        coins.append(coin)
        var label := Label3D.new()
        label.text = ["01 / LIFT OFF", "02 / DOUBLE JUMP", "03 / KEEP GOING", "04 / JUMP QUICKLY", "05 / LAST GAP", "06 / HOME"][index]
        label.font_size = 32
        label.pixel_size = 0.007
        label.position = Vector3(0, index * 0.2 + 0.6, -index * 6 - 1.6)
        label.rotation_degrees.x = -65
        label.outline_size = 8
        $World.add_child(label)
    var flag: Node3D = load("res://models/flag.glb").instantiate()
    flag.position = Vector3(1.25, 1.5, -31)
    $World.add_child(flag)
    finish_gate = Area3D.new()
    finish_gate.position = Vector3(0, 2, -31)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(4.5, 3, 1.2)
    collider.shape = shape
    finish_gate.add_child(collider)
    $World.add_child(finish_gate)
    # Clouds use the unmodified CC0 meshes. Keep them below the course.
    for index in 8:
        var cloud: Node3D = load("res://models/cloud.glb").instantiate()
        cloud.position = Vector3(-7 if index % 2 == 0 else 7, -3.5, 3 - index * 5)
        cloud.scale = Vector3(4, 2, 3)
        $World.add_child(cloud)

func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("restart_round"):
        restart()
    if Input.is_action_just_pressed("start_round") and state == "ready":
        start()
    if Input.is_action_just_pressed("pause_round"):
        toggle_pause()
    if state == "playing":
        elapsed += delta
        if player.coins == total and finish_gate.overlaps_body(player):
            finish("won")
    _update_hud()
    if bridge != null:
        bridge.set("__skyRunState", state_text())

func _set_active(active: bool) -> void:
    player.enabled = active
    $World.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
    $View.set_physics_process(active)
    player.animation.speed_scale = 1 if active else 0
    if not active:
        _release_controls()

func _release_controls() -> void:
    for action in ["move_left", "move_right", "move_forward", "move_back", "jump", "camera_left", "camera_right"]:
        Input.action_release(action)

func start() -> void:
    if state == "ready":
        state = "playing"
        _set_active(true)

func restart() -> void:
    _release_controls()
    player.position = Vector3(0, 0.6, 1)
    player.velocity = Vector3.ZERO
    player.jumps_left = 2
    player.coins = 0
    elapsed = 0
    result_sent = false
    for coin in coins:
        coin.reset()
    falling.reset()
    $View.position = player.position
    $View.rotation_degrees = Vector3(-35, 0, 0)
    $View.camera_rotation = $View.rotation_degrees
    state = "playing"
    _set_active(true)

func toggle_pause() -> void:
    if state in ["playing", "paused"]:
        state = "paused" if state == "playing" else "playing"
        _set_active(state == "playing")

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
        toggle_pause()

func finish(outcome: String) -> void:
    if state != "playing":
        return
    state = outcome
    _set_active(false)
    if not result_sent:
        result_sent = true
        _post({"type": "radbro:game-result", "game": GAME, "status": "clear" if state == "won" else "gameover", "score": player.coins * 100, "elapsedSeconds": snappedf(elapsed, 0.01)})

func _build_hud() -> void:
    var control := Control.new()
    control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    control.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $HUD.add_child(control)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 14)
    panel.custom_minimum_size = Vector2(600, 112)
    control.add_child(panel)
    var box := VBoxContainer.new()
    panel.add_child(box)
    var title := Label.new()
    title.text = "RADBRO SKY RUN"
    title.add_theme_font_override("font", load("res://fonts/lilita_one_regular.ttf"))
    title.add_theme_font_size_override("font_size", 30)
    box.add_child(title)
    status = Label.new()
    box.add_child(status)
    hint = Label.new()
    hint.add_theme_font_size_override("font_size", 16)
    box.add_child(hint)
    var actions := HBoxContainer.new()
    box.add_child(actions)
    start_button = _button("Start [Enter]", start)
    actions.add_child(start_button)
    pause_button = _button("Pause [P]", toggle_pause)
    actions.add_child(pause_button)
    actions.add_child(_button("Restart [R]", restart))
    var specs := [["LEFT", "move_left", Vector2(18, 590)], ["UP", "move_forward", Vector2(140, 478)], ["DOWN", "move_back", Vector2(140, 590)], ["RIGHT", "move_right", Vector2(262, 590)], ["JUMP", "jump", Vector2(790, 590)], ["CAM <", "camera_left", Vector2(672, 478)], ["CAM >", "camera_right", Vector2(800, 478)]]
    for spec in specs:
        var button := TouchScreenButton.new()
        button.action = spec[1]
        button.position = spec[2]
        button.passby_press = true
        var width := 140 if spec[1] == "jump" else 120
        var image := Image.create(width, 110, false, Image.FORMAT_RGBA8)
        image.fill(Color(0.06, 0.15, 0.19, 0.85))
        button.texture_normal = ImageTexture.create_from_image(image)
        image.fill(Color(0.85, 0.48, 0.15))
        button.texture_pressed = ImageTexture.create_from_image(image)
        var label := Label.new()
        label.text = spec[0]
        label.size = Vector2(width, 110)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        button.add_child(label)
        $HUD.add_child(button)
    var credit := Label.new()
    credit.text = "Radcat by Radbro  /  Starter kit by Kenney"
    credit.position = Vector2(16, 160)
    credit.add_theme_font_size_override("font_size", 13)
    credit.add_theme_color_override("font_outline_color", Color(0.06, 0.1, 0.14))
    credit.add_theme_constant_override("outline_size", 5)
    control.add_child(credit)

func _button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(130, 38)
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(callback)
    return button

func _update_hud() -> void:
    if status == null:
        return
    status.text = "COINS %d / %d     TIME %.1f     %s" % [player.coins, total, elapsed, state.to_upper()]
    hint.text = "WASD: move  /  Space twice: double jump  /  Q,E or arrows: camera"
    if state == "ready":
        hint.text = "Collect all six coins. Cross the gaps. Reach the last flag."
    elif state == "paused":
        hint.text = "Paused. Select Resume to continue."
    elif state == "won":
        hint.text = "Course clear! Select Restart for another run."
    elif state == "lost":
        hint.text = "You fell. Select Restart to try again."
    elif player.coins == total:
        hint.text = "All coins collected. Walk to the flag at the end of the island."
    start_button.visible = state == "ready"
    pause_button.text = "Resume [P]" if state == "paused" else "Pause [P]"
    pause_button.disabled = state not in ["playing", "paused"]

func state_text() -> String:
    var remaining := []
    for coin in coins:
        if not coin.grabbed:
            remaining.append({"x": coin.position.x, "y": coin.position.y, "z": coin.position.z})
    return JSON.stringify({"game": GAME, "state": state, "elapsed": snappedf(elapsed, 0.01), "coins": player.coins, "total": total, "player": {"x": snappedf(player.position.x, 0.01), "y": snappedf(player.position.y, 0.01), "z": snappedf(player.position.z, 0.01), "grounded": player.is_on_floor(), "jumpsLeft": player.jumps_left, "motion": player.animation.current_animation}, "remainingCoins": remaining, "fallingPlatform": {"falling": falling.falling, "y": snappedf(falling.position.y, 0.01)}, "finish": {"x": 0, "z": -31}, "cameraYaw": snappedf($View.rotation.y, 0.01), "coordinates": "+X right, -Z course direction, +Y up"})

func _install_bridge() -> void:
    if not OS.has_feature("web"):
        return
    bridge = JavaScriptBridge.get_interface("window")
    var callback := JavaScriptBridge.create_callback(func(_args: Array): bridge.set("__skyRunState", state_text()))
    callbacks.append(callback)
    bridge.set("__skyRunSnapshot", callback)
    JavaScriptBridge.eval("window.render_game_to_text=function(){window.__skyRunSnapshot();return window.__skyRunState;};window.advanceTime=function(ms){return new Promise(function(resolve){setTimeout(function(){resolve(window.render_game_to_text());},Math.max(0,Math.min(Number(ms)||0,60000)));});};", true)
    var ready := JavaScriptBridge.create_callback(func(_args: Array): _send_ready())
    callbacks.append(ready)
    bridge.set("__skyRunReady", ready)
    JavaScriptBridge.eval("window.addEventListener('message',function(e){if(e.source===window.parent&&e.data&&e.data.type==='radbro:game-ready-request')window.__skyRunReady();});", true)

func _send_ready() -> void:
    _post({"type": "radbro:game-ready", "game": GAME, "title": "Radbro Sky Run", "objective": "Collect six coins. Reach the flag. Avoid falling.", "controls": ["WASD: move", "Space twice: double jump", "Q/E or arrows: rotate camera", "P: pause", "R: restart", "Touch: hold direction and tap Jump"], "viewport": {"width": 960, "height": 720}})

func _post(payload: Dictionary) -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.parent.postMessage(" + JSON.stringify(payload) + ", '*');", true)
