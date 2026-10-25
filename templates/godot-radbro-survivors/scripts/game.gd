# Spawn and health-depleted flow adapted from GDQuest game.gd (MIT).
extends Node2D
const PLAYER = preload("res://scripts/player.gd")
const MOB = preload("res://scripts/mob.gd")
const GUN = preload("res://scripts/gun.gd")
const CHARACTER = preload("res://scripts/character.gd")
const ART_STYLES = preload("res://scripts/art_styles.gd")
const EFFECTS = preload("res://scripts/effects.gd")
const BALANCE = preload("res://scripts/balance.gd")
const AUDIO = preload("res://scripts/audio.gd")
@export var round_seconds := BALANCE.ROUND_SECONDS
var state := "ready"
var elapsed := 0.0
var spawn_clock := 0.0
var kills := 0
var xp := 0
var level := 1
var upgrades: Array = []
var mobs: Array = []
var gems: Array[Vector2] = []
var player: CharacterBody2D
var gun: Node2D
var projectiles: Node2D
var effects: Node2D
var hud: Label
var message: Label
var action: Button
var pause_button: Button
var choices: HBoxContainer
var overlay: PanelContainer
var callbacks: Array = []
var browser: JavaScriptObject
var rng := RandomNumberGenerator.new()
var art_data: RefCounted
var art_style := "radcat"
var available_art_styles: Array[String] = ["radcat"]
var style_button: Button
var credit_label: Label
var audio: Node
var sound_button: Button
var wave_label: Label
var announced_wave := 0
var wave_notice := 0.0

func _ready() -> void:
    rng.seed = 314159
    _inputs()
    audio = Node.new()
    audio.set_script(AUDIO)
    add_child(audio)
    effects = Node2D.new()
    effects.name = "VisualEffects"
    effects.set_script(EFFECTS)
    effects.z_index = 4
    add_child(effects)
    projectiles = Node2D.new()
    add_child(projectiles)
    player = CharacterBody2D.new()
    player.name = "Player"
    player.set_script(PLAYER)
    player.position = Vector2(480, 340)
    player.visual = Node2D.new()
    player.visual.set_script(CHARACTER)
    player.add_child(player.visual)
    player.mobs = mobs
    player.health_depleted.connect(_on_player_health_depleted)
    player.damaged.connect(_on_player_damaged)
    add_child(player)
    gun = Node2D.new()
    gun.set_script(GUN)
    gun.mobs = mobs
    gun.projectiles = projectiles
    gun.effects = effects
    gun.audio = audio
    player.add_child(gun)
    art_data = ART_STYLES.new()
    if art_data.styles.has("native") and art_data.styles.has("illustrated"):
        available_art_styles = ["native", "illustrated"]
        _set_art_style("native")
    elif player.visual.using_paperdoll:
        art_style = "native-local"
        available_art_styles = ["native-local"]
    _ui()
    _install_bridge()
    _update_hud()

func _inputs() -> void:
    var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN]}
    for name in bindings:
        if not InputMap.has_action(name):
            InputMap.add_action(name)
            for key in bindings[name]:
                var event := InputEventKey.new()
                event.physical_keycode = key
                InputMap.action_add_event(name, event)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_ENTER, KEY_SPACE:
                if state == "ready": start()
            KEY_P, KEY_ESCAPE: toggle_pause()
            KEY_R: restart()
            KEY_T: toggle_art_style()
            KEY_M: toggle_sound()
            KEY_1: choose_upgrade(0)
            KEY_2: choose_upgrade(1)
            KEY_3: choose_upgrade(2)
            KEY_F:
                if OS.has_feature("web"):
                    JavaScriptBridge.eval("if(document.fullscreenElement){document.exitFullscreen().catch(function(){})}else if(document.fullscreenEnabled){document.getElementById('canvas').requestFullscreen().catch(function(){})}", true)

func start() -> void:
    state = "playing"
    _set_active(true)
    _announce_wave()
    _update_hud()

func restart() -> void:
    for mob in mobs:
        if is_instance_valid(mob): mob.queue_free()
    mobs.clear()
    for projectile in projectiles.get_children(): projectile.queue_free()
    gems.clear()
    effects.clear()
    audio.restart()
    elapsed = 0
    spawn_clock = 0
    kills = 0
    xp = 0
    level = 1
    upgrades.clear()
    announced_wave = 0
    wave_notice = 0.0
    player.position = Vector2(480, 340)
    player.health = BALANCE.PLAYER_HEALTH
    player.speed = BALANCE.PLAYER_SPEED
    player.hurt_clock = 0.0
    player.visual.hurt_remaining = 0.0
    gun.interval = BALANCE.GUN_INTERVAL
    gun.damage = BALANCE.GUN_DAMAGE
    gun.cooldown = 0
    gun.shots = 0
    start()

func toggle_pause() -> void:
    if state == "playing":
        state = "paused"
        _set_active(false)
    elif state == "paused":
        start()
    _update_hud()

func toggle_art_style() -> void:
    if available_art_styles.size() < 2:
        return
    _set_art_style("illustrated" if art_style == "native" else "native")

func toggle_sound() -> void:
    audio.set_enabled(not audio.enabled)
    _update_hud()

func _announce_wave() -> void:
    var current := BALANCE.wave_number(elapsed)
    if current == announced_wave:
        return
    announced_wave = current
    wave_notice = 2.0
    audio.play_event("wave")

func _set_art_style(style: String) -> void:
    if not art_data.styles.has(style):
        return
    # Only visual data changes. Keep every gameplay node, clock, and resource.
    art_style = style
    player.visual.set_art_style(style, art_data)
    gun.set_art_style(style, art_data)
    effects.set_art_style(style)
    for projectile in projectiles.get_children():
        projectile.set_art_style(style, art_data)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if style == "native" else CanvasItem.TEXTURE_FILTER_LINEAR
    queue_redraw()
    for mob in mobs:
        if is_instance_valid(mob):
            mob.set_art_style(style, art_data)
    if style_button != null:
        _update_hud()

func _set_active(value: bool) -> void:
    audio.set_round_active(value)
    effects.active = value
    player.active = value
    gun.active = value
    player.visual.set_process(value)
    for mob in mobs:
        if is_instance_valid(mob): mob.active = value
    for projectile in projectiles.get_children(): projectile.active = value

func _physics_process(delta: float) -> void:
    if state != "playing":
        return
    elapsed += delta
    wave_notice = maxf(0.0, wave_notice - delta)
    if elapsed >= round_seconds:
        state = "won"
        _set_active(false)
        audio.play_event("win")
        _update_hud()
        return
    _announce_wave()
    spawn_clock -= delta
    if spawn_clock <= 0:
        spawn_mob()
        spawn_clock = BALANCE.spawn_interval(elapsed)
    for index in range(gems.size() - 1, -1, -1):
        var distance := gems[index].distance_to(player.position)
        if distance < 95:
            gems[index] = gems[index].move_toward(player.position, delta * 250)
        if distance < 23:
            effects.emit_effect("pickup", gems[index])
            audio.play_event("pickup")
            gems.remove_at(index)
            xp += 1
            if xp >= BALANCE.xp_threshold(level):
                xp -= BALANCE.xp_threshold(level)
                level += 1
                state = "upgrade"
                effects.emit_effect("upgrade", player.position + Vector2(0, -24))
                _set_active(false)
                audio.play_event("upgrade")
                break
    _update_hud()
    queue_redraw()

func spawn_mob() -> CharacterBody2D:
    if mobs.size() >= BALANCE.MAX_MOBS:
        return null
    var new_mob := CharacterBody2D.new()
    new_mob.set_script(MOB)
    var side := rng.randi_range(0, 3)
    var points := [Vector2(25, rng.randf_range(150, 540)), Vector2(935, rng.randf_range(150, 540)), Vector2(rng.randf_range(40, 920), 130), Vector2(rng.randf_range(40, 920), 550)]
    new_mob.position = points[side]
    new_mob.player = player
    new_mob.set_art_style(art_style, art_data)
    var elites := mobs.filter(func(m): return is_instance_valid(m) and not m.is_queued_for_deletion() and m.elite).size()
    var chance := BALANCE.elite_chance(elapsed)
    new_mob.elite = chance > 0.0 and elites < BALANCE.MAX_ELITES and rng.randf() < chance
    new_mob.speed = BALANCE.enemy_speed(elapsed, new_mob.elite)
    new_mob.health = BALANCE.enemy_health(new_mob.elite)
    new_mob.died.connect(_mob_died.bind(new_mob))
    add_child(new_mob)
    mobs.append(new_mob)
    return new_mob

func _mob_died(location: Vector2, mob: Node2D) -> void:
    kills += 1
    gems.append(location)
    effects.emit_effect("defeat", location + Vector2(0, -14))
    mobs.erase(mob)

func choose_upgrade(index: int) -> void:
    if state != "upgrade" or index not in [0, 1, 2]:
        return
    match index:
        0: gun.interval = maxf(0.14, gun.interval * 0.78)
        1: gun.damage += 1
        2:
            player.speed = minf(300, player.speed + 22)
            player.health = minf(player.max_health, player.health + 30)
    upgrades.append(index)
    start()

func _on_player_health_depleted() -> void:
    state = "lost"
    _set_active(false)
    audio.play_event("loss")
    _update_hud()

func _on_player_damaged() -> void:
    audio.play_event("hurt")
    player.visual.hurt_remaining = 0.16
    effects.emit_effect("hurt", player.position + Vector2(0, -24))

func _draw() -> void:
    if art_style in ["native", "illustrated"]:
        _draw_review_floor()
        for point in gems:
            _draw_review_xp(point)
        return
    draw_rect(Rect2(20, 130, 920, 420), Color("122d3b"))
    for x in range(20, 941, 40):
        draw_line(Vector2(x, 130), Vector2(x, 550), Color("193847"))
    for y in range(130, 551, 40):
        draw_line(Vector2(20, y), Vector2(940, y), Color("193847"))
    draw_rect(Rect2(20, 130, 920, 420), Color("39717d"), false, 3)
    for point in gems:
        draw_colored_polygon(PackedVector2Array([point + Vector2(0, -7), point + Vector2(5, 0), point + Vector2(0, 7), point + Vector2(-5, 0)]), Color("72f4c5"))

func _draw_review_floor() -> void:
    var look: Dictionary = art_data.styles[art_style].get("look", {})
    var tile: Texture2D = look.get("ground")
    var bounds := Rect2(20, 130, 920, 420)
    if tile != null:
        var size := maxf(16.0, float(look.get("world_tile_size", 64.0)))
        var y := bounds.position.y
        var row := 0
        while y < bounds.end.y:
            var x := bounds.position.x
            var column := 0
            while x < bounds.end.x:
                var extent := Vector2(minf(size, bounds.end.x - x), minf(size, bounds.end.y - y))
                var source_size := Vector2(tile.get_width(), tile.get_height())
                var source_extent := source_size * extent / size
                var source_start := Vector2.ZERO
                var destination := Rect2(Vector2(x, y), extent)
                if look.get("mirror_alternate", false):
                    if column % 2 == 1:
                        source_start.x = source_size.x - source_extent.x
                        destination.size.x = -extent.x
                    if row % 2 == 1:
                        source_start.y = source_size.y - source_extent.y
                        destination.size.y = -extent.y
                draw_texture_rect_region(tile, destination, Rect2(source_start, source_extent))
                x += size
                column += 1
            y += size
            row += 1
    else:
        # Optional look assets can arrive after the hero/enemy review packs.
        draw_rect(bounds, Color("283d32") if art_style == "native" else Color("394640"))
        for y in range(130, 551, 64):
            draw_line(Vector2(20, y), Vector2(940, y), Color(0.65, 0.66, 0.48, 0.06), 1)
    draw_rect(bounds, Color("496a59") if art_style == "native" else Color("7b8067"), false, 2)

func _draw_review_xp(point: Vector2) -> void:
    var look: Dictionary = art_data.styles[art_style].get("look", {})
    if art_style == "native" and look.has("icons") and look.get("regions", {}).has("xp"):
        var icon: Dictionary = look.regions.xp
        var factor := 14.0 / float(icon.visible_height)
        var size: Vector2 = icon.region.size * factor
        draw_texture_rect_region(look.icons, Rect2(point - size / 2.0, size), icon.region)
        return
    if art_style == "illustrated":
        draw_circle(point, 11, Color(0.65, 0.93, 0.57, 0.05))
        draw_circle(point, 8, Color(0.65, 0.93, 0.57, 0.08))
        draw_colored_polygon(PackedVector2Array([point + Vector2(0, -7), point + Vector2(5, 0), point + Vector2(0, 7), point + Vector2(-5, 0)]), Color("b5e69b"))
        draw_colored_polygon(PackedVector2Array([point + Vector2(0, -7), point + Vector2(5, 0), point]), Color("e1efba"))
    else:
        draw_rect(Rect2(point.round() - Vector2(3, 5), Vector2(6, 10)), Color("92efac"))

func _button(text: String, callback: Callable, width: float = 140) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(width, 44)
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(callback)
    return button

func _ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    var title := Label.new()
    title.position = Vector2(24, 15)
    title.text = "RADBRO SURVIVORS"
    title.add_theme_font_size_override("font_size", 28)
    root.add_child(title)
    sound_button = _button("Sound: On [M]", toggle_sound, 154)
    sound_button.position = Vector2(500, 12)
    root.add_child(sound_button)
    wave_label = Label.new()
    wave_label.position = Vector2(36, 143)
    wave_label.add_theme_font_size_override("font_size", 20)
    wave_label.add_theme_color_override("font_color", Color("fff0b1"))
    root.add_child(wave_label)
    hud = Label.new()
    hud.position = Vector2(24, 61)
    hud.add_theme_font_size_override("font_size", 19)
    root.add_child(hud)
    message = Label.new()
    message.position = Vector2(24, 91)
    message.add_theme_color_override("font_color", Color("9fc4c8"))
    root.add_child(message)
    pause_button = _button("Pause [P]", toggle_pause, 120)
    pause_button.position = Vector2(666, 12)
    root.add_child(pause_button)
    style_button = _button("Style: Native [T]", toggle_art_style, 200)
    style_button.position = Vector2(718, 80)
    style_button.visible = available_art_styles.size() > 1
    root.add_child(style_button)
    var reset := _button("Restart [R]", restart, 140)
    reset.position = Vector2(796, 12)
    root.add_child(reset)
    overlay = PanelContainer.new()
    overlay.position = Vector2(200, 220)
    overlay.size = Vector2(560, 180)
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color("153a4c")
    panel.border_color = Color("6de8c1")
    panel.set_border_width_all(2)
    panel.content_margin_left = 20
    panel.content_margin_right = 20
    panel.content_margin_top = 18
    panel.content_margin_bottom = 18
    overlay.add_theme_stylebox_override("panel", panel)
    root.add_child(overlay)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 18)
    overlay.add_child(column)
    var intro := Label.new()
    intro.name = "Intro"
    intro.text = "Survive 90 seconds. Your blaster fires automatically.\nCollect green XP. Choose an upgrade each level."
    intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(intro)
    action = _button("Start survival [Enter]", start)
    column.add_child(action)
    choices = HBoxContainer.new()
    choices.alignment = BoxContainer.ALIGNMENT_CENTER
    column.add_child(choices)
    for index in 3:
        choices.add_child(_button(["1 · Rapid fire", "2 · Power +1", "3 · Speed + heal"][index], choose_upgrade.bind(index), 160))
    var pad := Node2D.new()
    root.add_child(pad)
    for spec in [["Left", "move_left", 24], ["Up", "move_up", 100], ["Down", "move_down", 176], ["Right", "move_right", 252]]:
        var button := TouchScreenButton.new()
        button.position = Vector2(spec[2], 566)
        button.action = spec[1]
        button.passby_press = true
        var image := Image.create(68, 58, false, Image.FORMAT_RGBA8)
        image.fill(Color("234d60"))
        button.texture_normal = ImageTexture.create_from_image(image)
        image.fill(Color("397e83"))
        button.texture_pressed = ImageTexture.create_from_image(image)
        var label := Label.new()
        label.text = spec[0]
        label.size = Vector2(68, 58)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(label)
        pad.add_child(button)
    credit_label = Label.new()
    credit_label.position = Vector2(370, 576)
    credit_label.add_theme_font_size_override("font_size", 14)
    root.add_child(credit_label)

func _update_hud() -> void:
    sound_button.text = "Sound: %s [M]" % ("On" if audio.enabled else "Off")
    wave_label.visible = wave_notice > 0 and state in ["playing", "paused"]
    wave_label.text = ["WAVE 1 · Find your footing", "WAVE 2 · Sentry surge", "WAVE 3 · Hold the line"][BALANCE.wave_number(elapsed) - 1]
    hud.text = "HP %03d    %02d:%02d left    Wave %d / 3    Kills %d    Level %d · XP %d/%d" % [ceili(player.health), int(maxf(0, round_seconds - elapsed)) / 60, int(maxf(0, round_seconds - elapsed)) % 60, BALANCE.wave_number(elapsed), kills, level, xp, BALANCE.xp_threshold(level)]
    message.text = "Move through XP. Keep clear of the sentries."
    if available_art_styles.size() > 1:
        style_button.text = "Style: %s [T]" % art_style.capitalize()
        message.text = "PRIVATE ART REVIEW · T or Style swaps the full game look."
        credit_label.text = "Same round · T: art style · M: sound · F: fullscreen\n" + ("Native: crisp tiles + sparks · one mirrored hero view" if art_style == "native" else ("Illustrated: idle + blink · soft trails + wisps" if player.visual.has_illustrated_idle() else "Illustrated: soft trails + wisps · idle holds a pose"))
    else:
        credit_label.text = "WASD / arrows / touch · M: sound · F: fullscreen\nGDQuest MIT logic · " + ("Radbro paperdoll: PRIVATE ART REVIEW" if player.visual.using_paperdoll else "Radbro assets · Radcat preview hero")
    overlay.visible = state != "playing"
    action.visible = state in ["ready", "paused", "won", "lost"]
    choices.visible = state == "upgrade"
    pause_button.disabled = state not in ["playing", "paused"]
    pause_button.text = "Resume [P]" if state == "paused" else "Pause [P]"
    var intro: Label = overlay.get_child(0).get_node("Intro")
    match state:
        "ready": pass
        "paused":
            intro.text = "SURVIVAL PAUSED\nResume when you are ready."
            action.text = "Resume survival"
        "upgrade": intro.text = "LEVEL %d — CHOOSE AN UPGRADE\nThe arena pauses while you choose." % level
        "won", "lost":
            intro.text = ("SURVIVED!" if state == "won" else "RUN ENDED") + "\n%d sentries defeated · Level %d · Restart to play again." % [kills, level]
            action.visible = false

func state_text() -> String:
    var enemies: Array = []
    for mob in mobs:
        if is_instance_valid(mob): enemies.append({"node_id": mob.get_instance_id(), "art_style": mob.art_style, "x": snappedf(mob.position.x, 0.1), "y": snappedf(mob.position.y, 0.1), "health": mob.health})
    return JSON.stringify({"game": "radbro-survivors", "state": state, "audio": audio.snapshot(), "animation": player.visual.animation_state(), "art_style": art_style, "available_art_styles": available_art_styles, "visual_style": {"floor": art_style, "ground_texture_loaded": art_data.styles.get(art_style, {}).get("look", {}).get("ground") != null, "ground_mirror_alternate": art_data.styles.get(art_style, {}).get("look", {}).get("mirror_alternate", false), "gun": gun.art_style, "projectile_style": art_style}, "active_fx": effects.snapshot(), "projectiles": projectiles.get_children().filter(func(p): return not p.is_queued_for_deletion()).map(func(p): return {"node_id": p.get_instance_id(), "art_style": p.art_style, "x": snappedf(p.position.x, 0.1), "y": snappedf(p.position.y, 0.1), "distance": snappedf(p.travelled_distance, 0.1)}), "elapsed": snappedf(elapsed, 0.01), "duration": round_seconds, "wave": BALANCE.wave_number(elapsed), "player": {"node_id": player.get_instance_id(), "facing": player.visual.facing, "x": snappedf(player.position.x, 0.1), "y": snappedf(player.position.y, 0.1), "health": snappedf(player.health, 0.1), "speed": player.speed, "paperdoll": player.visual.using_paperdoll}, "kills": kills, "level": level, "xp": xp, "xp_next": BALANCE.xp_threshold(level), "gems": gems.map(func(p: Vector2) -> Dictionary: return {"x": p.x, "y": p.y}), "enemies": enemies, "shots": gun.shots, "damage": gun.damage, "fire_interval": gun.interval, "upgrades": upgrades, "coordinates": "origin top-left; +x right; +y down; player position is floor anchor"})

func _install_bridge() -> void:
    if not OS.has_feature("web"): return
    browser = JavaScriptBridge.get_interface("window")
    var callback := JavaScriptBridge.create_callback(func(_args: Array): browser.set("__survivorsState", state_text()))
    callbacks.append(callback)
    browser.set("__survivorsSnapshot", callback)
    JavaScriptBridge.eval("window.render_game_to_text=function(){window.__survivorsSnapshot();return window.__survivorsState};window.advanceTime=function(ms){return new Promise(function(resolve){setTimeout(function(){resolve(window.render_game_to_text())},Math.max(0,Math.min(Number(ms)||0,60000)))})};", true)
    JavaScriptBridge.eval("window.parent.postMessage({type:'radbro:game-ready',game:'godot-radbro-survivors',title:'Radbro Survivors',controls:['WASD / arrows / touch: move','P: pause','R: restart','1 / 2 / 3: upgrade','T / Style: switch local review art when available','M / Sound: mute or unmute']},'*')", true)
