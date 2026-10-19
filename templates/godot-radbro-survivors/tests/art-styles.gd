extends SceneTree
var game: Node2D
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
    if not value: failures.append(label)
    print(("PASS " if value else "FAIL ") + label)
func _initialize() -> void:
    call_deferred("run")
func gameplay_snapshot() -> Dictionary:
    return {
        "player_id": game.player.get_instance_id(), "visual_id": game.player.visual.get_instance_id(),
        "player_position": game.player.position, "health": game.player.health,
        "direction": game.player.direction, "speed": game.player.speed,
        "state": game.state, "time": game.elapsed, "spawn_clock": game.spawn_clock,
        "xp": game.xp, "level": game.level, "kills": game.kills, "gems": game.gems.duplicate(),
        "upgrades": game.upgrades.duplicate(), "fire_interval": game.gun.interval,
        "damage": game.gun.damage, "shots": game.gun.shots, "cooldown": game.gun.cooldown,
        "hero_clock": game.player.visual.clock, "hero_clip": game.player.visual.clip,
        "facing": game.player.visual.facing, "rng": game.rng.state,
        "mobs": game.mobs.map(func(m): return {"id": m.get_instance_id(), "position": m.position, "health": m.health, "clock": m.art_clock, "hurt": m.hurt, "active": m.active}),
        "projectiles": game.projectiles.get_children().map(func(p): return {"id": p.get_instance_id(), "position": p.position, "distance": p.travelled_distance, "active": p.active}),
    }
func run() -> void:
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var has_review: bool = game.available_art_styles == ["native", "illustrated"]
    if not has_review:
        check(game.art_style == "radcat", "missing review data keeps published Radcat")
        check(game.available_art_styles == ["radcat"] and not game.style_button.visible, "no dead style control without two complete review packs")
        var before: Dictionary = gameplay_snapshot()
        game.toggle_art_style()
        check(gameplay_snapshot() == before, "unavailable toggle is a no-op")
        game.player.visual.face_horizontal(1)
        check(game.player.visual.scale.x < 0, "published left-facing Radcat mirrors for right travel")
        game.player.visual.face_horizontal(-1)
        check(game.player.visual.scale.x > 0, "published Radcat keeps source facing for left travel")
    else:
        check(game.art_style == "native" and game.style_button.visible, "local review starts with native and visible Style button")
        check(game.player.visual.parts.size() == 11 and game.player.visual.equipped.is_empty(), "native comparison uses separate base planes")
        game.start()
        game.spawn_clock = 100
        game.elapsed = 23.5
        game.xp = 3
        game.level = 2
        game.kills = 5
        game.upgrades = [0, 1]
        game.gems.append(Vector2(130, 220))
        var mob = game.spawn_mob()
        mob.position = Vector2(250, 280)
        mob.health = 4
        mob.art_clock = 375
        mob.hurt = 0.05
        game.gun.shoot()
        game.player.visual.clock = 370
        game.player.visual.clip = "walk"
        game.player.visual.moving = true
        game.player.visual.face_direction(Vector2.UP)
        var before: Dictionary = gameplay_snapshot()
        var event := InputEventKey.new()
        event.pressed = true
        event.physical_keycode = KEY_T
        game._unhandled_key_input(event)
        check(game.art_style == "illustrated" and mob.art_style == "illustrated", "T changes hero and existing enemy art")
        check(gameplay_snapshot() == before, "T preserves nodes, positions, resources, timers, animation clocks and facing")
        check(game.player.visual.facing == "up" and game.player.visual.scale.x > 0, "illustrated art uses real up frames without horizontal reflection")
        check(mob.enemy_art.frames[2].has("anchor"), "illustrated enemy keeps explicit per-frame registration")
        var new_mob = game.spawn_mob()
        check(new_mob.art_style == "illustrated", "new enemies inherit the selected style")
        before = gameplay_snapshot()
        game.style_button.pressed.emit()
        check(game.art_style == "native" and game.mobs.all(func(m): return m.art_style == "native"), "Style button changes all current enemies back to native")
        check(gameplay_snapshot() == before, "button preserves the same running game")
        game.player.visual.clock = 120
        game.player.visual.clip = "walk"
        check(game.player.visual.paperdoll_frame() == 5, "native layer clock retains the 120ms walk phases")
        game.toggle_pause()
        before = gameplay_snapshot()
        game.toggle_art_style()
        check(gameplay_snapshot() == before and game.state == "paused", "style can change while paused without resuming")
        game.state = "upgrade"
        before = gameplay_snapshot()
        game.toggle_art_style()
        check(gameplay_snapshot() == before and game.state == "upgrade", "style preserves an open upgrade choice")
        var snapshot: Dictionary = JSON.parse_string(game.state_text())
        check(snapshot.art_style == "native" and snapshot.available_art_styles == ["native", "illustrated"] and snapshot.player.facing == "up", "browser state exposes available styles and facing")
    print("ART_STYLES ", "PASS" if failures.is_empty() else failures)
    quit(0 if failures.is_empty() else 1)
