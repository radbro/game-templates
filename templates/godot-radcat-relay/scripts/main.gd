extends Node3D
## A short collect-and-return round. The saved scene owns the course layout.
@export var round_seconds := 60.0
var state := "ready"
var time_left := 60.0
var collected := 0
var total_pickups := 0
var damage_cooldown := 0.0
var result_sent := false
var bridge_callbacks: Array[JavaScriptObject] = []
var bridge_window: JavaScriptObject
var status_label: Label
var message_label: Label
var start_button: Button
var pause_button: Button
@onready var player = $Player

func _ready() -> void:
    _bind_input()
    total_pickups = $Pickups.get_child_count()
    time_left = round_seconds
    for pickup in $Pickups.get_children():
        pickup.body_entered.connect(_collect.bind(pickup))
    _build_hud()
    _build_end_walls()
    _install_bridge()
    player.enabled = false
    _update_hud()
    _send_ready()

func _bind_input() -> void:
    var keys := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "hop": [KEY_SPACE], "pause_round": [KEY_P, KEY_ESCAPE], "restart_round": [KEY_R]}
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key in keys[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action, event)

func _build_end_walls() -> void:
    for z in [-11.0, 11.0]:
        var wall := StaticBody3D.new()
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(16, 2, 0.5)
        collider.shape = shape
        wall.add_child(collider)
        wall.position = Vector3(0, 0.5, z)
        add_child(wall)

func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("restart_round"):
        restart()
    if Input.is_action_just_pressed("pause_round"):
        toggle_pause()
    if state == "playing":
        time_left = maxf(0.0, time_left - delta)
        damage_cooldown = maxf(0.0, damage_cooldown - delta)
        for hazard in $Hazards.get_children():
            if hazard.overlaps_body(player):
                hit_hazard()
        if collected == total_pickups and player.position.distance_to($Gate.position) < 1.5:
            finish("won")
        elif time_left <= 0.0:
            finish("lost")
    _update_hud()
    _publish_state()

func start() -> void:
    if state == "ready":
        state = "playing"
        player.enabled = true

func restart() -> void:
    for action in ["move_left", "move_right", "move_up", "move_down"]:
        Input.action_release(action)
    player.position = Vector3(0, 0.05, 8)
    player.velocity = Vector3.ZERO
    player.hop_remaining = 0.0
    player.hop_cooldown = 0.0
    collected = 0
    result_sent = false
    damage_cooldown = 0.0
    time_left = round_seconds
    for pickup in $Pickups.get_children():
        pickup.visible = true
        pickup.set_meta("collected", false)
    state = "playing"
    player.enabled = true

func toggle_pause() -> void:
    if state in ["playing", "paused"]:
        state = "paused" if state == "playing" else "playing"
        player.enabled = state == "playing"
        if not player.enabled:
            for action in ["move_left", "move_right", "move_up", "move_down"]:
                Input.action_release(action)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
        toggle_pause()

func _collect(body: Node3D, pickup: Area3D) -> void:
    if body == player and state == "playing" and not pickup.get_meta("collected", false):
        collected += 1
        pickup.set_meta("collected", true)
        pickup.hide()

func hit_hazard() -> void:
    if damage_cooldown > 0.0 or player.hop_remaining > 0.0:
        return
    time_left = maxf(0.0, time_left - 5.0)
    damage_cooldown = 1.5

func finish(outcome: String) -> void:
    if state in ["won", "lost"]:
        return
    state = outcome
    player.enabled = false
    if not result_sent:
        result_sent = true
        _post_message({"type": "radbro:game-result", "game": "godot-radcat-relay", "status": "clear" if outcome == "won" else "gameover", "score": collected * 100 + ceili(time_left)})

func _build_hud() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $HUD.add_child(root)
    var top := PanelContainer.new()
    top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 16
    top.offset_right = -16
    top.offset_top = 12
    top.offset_bottom = 122
    root.add_child(top)
    var column := VBoxContainer.new()
    top.add_child(column)
    var title := Label.new()
    title.text = "RADCAT RELAY"
    title.add_theme_font_size_override("font_size", 26)
    column.add_child(title)
    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 20)
    column.add_child(status_label)
    message_label = Label.new()
    message_label.add_theme_font_size_override("font_size", 16)
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(message_label)
    var actions := HBoxContainer.new()
    actions.position = Vector2(20, 135)
    root.add_child(actions)
    start_button = _button("Start relay", start)
    actions.add_child(start_button)
    pause_button = _button("Pause [P]", toggle_pause)
    actions.add_child(pause_button)
    actions.add_child(_button("Restart [R]", restart))
    var pad := Node2D.new()
    root.add_child(pad)
    var pad_specs := [["Left", "move_left"], ["Up", "move_up"], ["Down", "move_down"], ["Right", "move_right"], ["HOP [Space]", "hop"]]
    for index in pad_specs.size():
        var spec: Array = pad_specs[index]
        var button := TouchScreenButton.new()
        button.action = spec[1]
        button.passby_press = true
        var width := 172 if index == 4 else 72
        var image := Image.create(width, 60, false, Image.FORMAT_RGBA8)
        image.fill(Color(0.10, 0.14, 0.17))
        button.texture_normal = ImageTexture.create_from_image(image)
        image.fill(Color(0.24, 0.48, 0.47))
        button.texture_pressed = ImageTexture.create_from_image(image)
        var text := Label.new()
        text.text = spec[0]
        text.size = Vector2(width, 60)
        text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        text.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(text)
        pad.add_child(button)
    var layout_pad := func():
        for index in pad.get_child_count():
            var y: float = root.size.y - (160 if index == 4 and root.size.x < 560 else 90)
            pad.get_child(index).position = Vector2(root.size.x - 190 if index == 4 else 18 + index * 76, y)
    root.resized.connect(layout_pad)
    layout_pad.call_deferred()
    var credit := Label.new()
    credit.text = "Radbro assets · radbro.fun/assets"
    credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    credit.offset_left = -280
    credit.offset_top = -24
    root.add_child(credit)

func _button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(118, 42)
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(callback)
    return button

func _update_hud() -> void:
    $Camera3D.size = clampf(get_viewport().get_visible_rect().size.x * 37.3 / 960.0, 24.0, 37.3)
    status_label.text = "Energy %d / %d    Time %02d    %s" % [collected, total_pickups, ceili(time_left), state.to_upper()]
    var instructions := "WASD / arrows / touch: move. Hop over red pads. Each hit costs 5 seconds."
    if state == "won":
        instructions = "Relay complete! You returned all energy. Select Restart to play again."
    elif state == "lost":
        instructions = "Time ended. Select Restart to try again."
    elif state == "paused":
        instructions = "Round paused. Select Resume or press P to continue."
    elif collected == total_pickups:
        instructions = "All energy collected. Return to the gate at the start."
    message_label.text = instructions
    start_button.visible = state == "ready"
    pause_button.text = "Resume [P]" if state == "paused" else "Pause [P]"
    pause_button.disabled = state not in ["playing", "paused"]

func state_text() -> String:
    var remaining: Array = []
    for pickup in $Pickups.get_children():
        if not pickup.get_meta("collected", false):
            remaining.append({"x": pickup.position.x, "z": pickup.position.z})
    return JSON.stringify({"game": "radcat-relay-godot", "state": state, "time_left": snappedf(time_left, 0.01), "collected": collected, "total": total_pickups, "player": {"x": snappedf(player.position.x, 0.01), "y": snappedf(player.position.y, 0.01), "z": snappedf(player.position.z, 0.01), "hopping": player.hop_remaining > 0.0}, "pickups": remaining, "gate": {"x": 0, "z": 8}, "coordinates": "+x right, +z toward start, +y up"})

func _install_bridge() -> void:
    if not OS.has_feature("web"):
        return
    bridge_window = JavaScriptBridge.get_interface("window")
    # Retain the callback for the lifetime of the scene.
    var callback := JavaScriptBridge.create_callback(_browser_snapshot)
    bridge_callbacks.append(callback)
    bridge_window.set("__radcatSnapshot", callback)
    JavaScriptBridge.eval("window.render_game_to_text = function() { window.__radcatSnapshot(); return window.__radcatState; }; window.advanceTime = function(ms) { return new Promise(function(resolve) { setTimeout(function() { resolve(window.render_game_to_text()); }, Math.max(0, Math.min(Number(ms) || 0, 60000))); }); };", true)
    var ready_callback := JavaScriptBridge.create_callback(_browser_ready)
    bridge_callbacks.append(ready_callback)
    bridge_window.set("__radcatReady", ready_callback)
    JavaScriptBridge.eval("window.addEventListener('message', function(event) { if (event.source === window.parent && event.data && event.data.type === 'radbro:game-ready-request') { window.__radcatReady(); } });", true)
    _publish_state()

func _send_ready() -> void:
    _post_message({"type": "radbro:game-ready", "game": "godot-radcat-relay", "title": "Radcat Relay", "objective": "Collect four energy pickups. Return to the gate before time ends.", "hint": "Hop over red pads.", "controls": ["WASD or arrows: move", "Space: hop", "P or Escape: pause", "R: restart", "Touch: hold a direction and tap Hop"], "viewport": {"width": int(get_viewport().get_visible_rect().size.x), "height": int(get_viewport().get_visible_rect().size.y)}})

func _browser_ready(_arguments: Array) -> void:
    _send_ready()

func _post_message(payload: Dictionary) -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.parent.postMessage(" + JSON.stringify(payload) + ", '*');", true)

func _browser_snapshot(_arguments: Array) -> void:
    _publish_state()

func _publish_state() -> void:
    if bridge_window != null:
        bridge_window.set("__radcatState", state_text())
