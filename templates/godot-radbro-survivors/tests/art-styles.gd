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
        "projectiles": game.projectiles.get_children().map(func(p): return {"id": p.get_instance_id(), "position": p.position, "distance": p.travelled_distance, "active": p.active, "speed": p.speed, "damage": p.damage, "rotation": p.rotation}),
    }
func run() -> void:
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var has_review: bool = game.available_art_styles == ["native", "illustrated"]
    var requested_review: bool = OS.has_feature("art_review") or "--art-review" in OS.get_cmdline_user_args()
    if requested_review and not has_review:
        check(false, "explicit art review requires both complete style packs")
        quit(1)
        return
    if not has_review:
        check(game.art_style == "radcat", "missing review data keeps published Radcat")
        check(game.available_art_styles == ["radcat"] and not game.style_button.visible, "no dead style control without two complete review packs")
        var before: Dictionary = gameplay_snapshot()
        game.toggle_art_style()
        check(gameplay_snapshot() == before, "unavailable toggle is a no-op")
        game.effects.emit_effect("hit", Vector2(100, 100))
        check(game.effects.events.is_empty() and game.effects.event_counts.is_empty(), "public fallback does not create private-look effects")
        check(game.art_data.styles.is_empty(), "public fallback does not load private look assets")
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
        game.effects.emit_effect("hit", mob.position)
        check(game.projectiles.get_child_count() == 1 and game.effects.events.size() == 2, "fixture has an in-flight bullet and active muzzle/hit feedback")
        var effect_id: int = game.effects.get_instance_id()
        var effect_events: Array = game.effects.events.duplicate(true)
        var effect_counts: Dictionary = game.effects.event_counts.duplicate()
        var effect_clock: float = game.effects.elapsed
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
        check(game.projectiles.get_children().all(func(p): return p.art_style == "illustrated") and game.gun.art_style == "illustrated", "in-flight bullets and gun switch immediately")
        check(game.effects.art_style == "illustrated" and game.effects.get_instance_id() == effect_id and game.effects.events == effect_events and game.effects.event_counts == effect_counts and game.effects.elapsed == effect_clock, "active effects restyle without replacing events or resetting their ages")
        check(game.art_data.styles.native.look.get("ground") != null and game.art_data.styles.native.look.has("icons"), "native floor and icons load from the existing kit")
        if FileAccess.file_exists("res://review-art/look-kit/pack.json"):
            check(game.art_data.styles.illustrated.look.get("ground") != null, "optional illustrated ground loads when supplied")
        else:
            check(game.art_style == "illustrated", "missing optional illustrated ground keeps the style available")
        check(game.player.visual.facing == "up" and game.player.visual.scale.x > 0, "illustrated art uses real up frames without horizontal reflection")
        check(mob.enemy_art.frames[2].has("anchor"), "illustrated enemy keeps explicit per-frame registration")
        var new_mob = game.spawn_mob()
        check(new_mob.art_style == "illustrated", "new enemies inherit the selected style")
        before = gameplay_snapshot()
        game.style_button.pressed.emit()
        check(game.art_style == "native" and game.mobs.all(func(m): return m.art_style == "native"), "Style button changes all current enemies back to native")
        check(gameplay_snapshot() == before, "button preserves the same running game")
        check(game.effects.art_style == "native" and game.effects.events == effect_events and game.projectiles.get_children().all(func(p): return p.art_style == "native"), "button restyles existing FX and bullets back to native")
        game.player.visual.clock = 120
        game.player.visual.clip = "walk"
        check(game.player.visual.paperdoll_frame() == 5, "native layer clock retains the 120ms walk phases")
        game.toggle_pause()
        before = gameplay_snapshot()
        game.toggle_art_style()
        check(gameplay_snapshot() == before and game.state == "paused", "style can change while paused without resuming")
        var frozen_events: Array = game.effects.events.duplicate(true)
        var frozen_clock: float = game.effects.elapsed
        for frame in 6: await physics_frame
        check(game.effects.events == frozen_events and game.effects.elapsed == frozen_clock, "paused effects freeze ages and lifetimes")
        game.state = "upgrade"
        before = gameplay_snapshot()
        game.toggle_art_style()
        check(gameplay_snapshot() == before and game.state == "upgrade", "style preserves an open upgrade choice")
        for frame in 6: await physics_frame
        check(game.effects.events == frozen_events and game.effects.elapsed == frozen_clock, "upgrade effects stay frozen")
        var snapshot: Dictionary = JSON.parse_string(game.state_text())
        check(snapshot.art_style == "native" and snapshot.available_art_styles == ["native", "illustrated"] and snapshot.player.facing == "up", "browser state exposes available styles and facing")
        check(snapshot.visual_style.floor == "native" and snapshot.active_fx.emitted.muzzle == 1 and snapshot.active_fx.events.size() == 2 and snapshot.projectiles[0].art_style == "native", "browser render state exposes ground, live bullet styles and effect counters")
        game.state = "paused"
        game.toggle_pause()
        game.effects._physics_process(0.05)
        check(game.effects.elapsed > frozen_clock and game.effects.events[0].age > frozen_events[0].age, "resumed effects continue from frozen ages")
        for outcome in ["won", "lost"]:
            game.state = outcome
            game._set_active(false)
            var outcome_events: Array = game.effects.events.duplicate(true)
            var outcome_clock: float = game.effects.elapsed
            for frame in 4: await physics_frame
            check(game.effects.events == outcome_events and game.effects.elapsed == outcome_clock, "effects freeze on " + outcome)
        game.state = "paused"
        game.toggle_pause()
        for index in game.effects.MAX_EVENTS + 20:
            game.effects.emit_effect("pickup", Vector2(100, 200))
        check(game.effects.events.size() == game.effects.MAX_EVENTS, "effect count has a fixed upper bound")
        game.effects._physics_process(1.0)
        check(game.effects.events.is_empty() and game.effects.event_counts.pickup > 0, "expired effects clear while proof counters remain")
        game.effects.emit_effect("upgrade", Vector2(200, 200))
        game.restart()
        check(game.effects.events.is_empty() and game.effects.event_counts.is_empty() and game.effects.elapsed == 0.0, "restart clears all feedback events and counters")
    print("ART_STYLES ", "PASS" if failures.is_empty() else failures)
    quit(0 if failures.is_empty() else 1)
