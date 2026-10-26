extends SceneTree
var game: Node2D
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
    if not value: failures.append(label)
    print(("PASS " if value else "FAIL ") + label)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    check(not game.audio.unlocked and game.audio.snapshot().active_voices == 0, "ready screen has no autoplay")
    game.start()
    check(game.audio.unlocked and game.audio.round_active and game.audio.played.wave == 1, "Start unlocks sound and plays the first-wave cue")
    game.spawn_clock = 1000
    var mob: Node2D = game.spawn_mob()
    mob.position = game.player.position + Vector2(85, 0)
    mob.speed = 0
    for frame in 100: await physics_frame
    check(game.audio.played.fire >= 2 and game.audio.played.hit >= 2 and game.kills >= 1, "real gun and hit hooks play sound")
    game.toggle_pause()
    var elapsed: float = game.elapsed
    var backing: float = game.audio.backing_clock
    var animation: Dictionary = game.player.visual.animation_state()
    for frame in 10: await physics_frame
    check(game.elapsed == elapsed and game.audio.backing_clock == backing and game.player.visual.animation_state() == animation, "pause freezes round, backing and character animation")
    game.toggle_sound()
    check(not game.audio.enabled and game.audio.snapshot().active_voices == 0, "Sound control mutes active voices")
    game.toggle_pause()
    check(game.audio.round_active and not game.audio.snapshot().backing_playing, "muted resume stays quiet")
    game.restart()
    check(not game.audio.enabled and game.audio.round_active, "restart retains mute preference")
    game.toggle_sound()
    check(game.audio.enabled and game.audio.snapshot().backing_playing, "unmute restores backing after muted restart")
    game.spawn_clock = 1000
    game.gun.active = false
    mob = game.spawn_mob()
    mob.position = game.player.position
    mob.speed = 0
    for frame in 3: await physics_frame
    check(game.player.health < 100 and game.audio.played.hurt > 0 and game.player.visual.hurt_remaining > 0, "contact damage plays sound and visual feedback")
    game.gems.clear()
    for index in 4: game.gems.append(game.player.position)
    for frame in 3: await physics_frame
    check(game.state == "upgrade" and game.audio.played.pickup > 0 and game.audio.played.upgrade > 0 and not game.audio.snapshot().backing_playing, "XP and upgrade cues play while backing stays paused")
    game.choose_upgrade(0)
    game.gun.active = false
    var waves_played: int = game.audio.played.wave
    game.elapsed = 30
    for frame in 2: await physics_frame
    check(game.announced_wave == 2 and game.wave_label.text.begins_with("WAVE 2") and game.audio.played.wave == waves_played + 1, "second wave has a visible cue and plays sound")
    for frame in 30: await physics_frame
    game.elapsed = 60
    for frame in 2: await physics_frame
    check(game.announced_wave == 3 and game.audio.played.wave == waves_played + 2, "third wave plays its sound cue")
    game.player.health = 0.01
    mob.position = game.player.position
    for frame in 3: await physics_frame
    check(game.state == "lost" and game.audio.played.loss > 0 and not game.audio.snapshot().backing_playing, "defeat stops backing and plays its outcome cue")
    check(game.last_result == {"status": "gameover", "score": game.kills}, "defeat records the real result once")
    var result: Dictionary = game.last_result.duplicate()
    game._report_result("clear")
    check(game.last_result == result, "duplicate outcome does not replace the result")
    game.restart()
    check(game.last_result.is_empty(), "restart clears the prior result")
    game.elapsed = game.round_seconds - 0.02
    for frame in 3: await physics_frame
    check(game.state == "won" and game.audio.played.win > 0 and not game.audio.snapshot().backing_playing, "victory stops backing and plays its outcome cue")
    check(game.last_result == {"status": "clear", "score": game.kills}, "victory records its clear result")
    if game.available_art_styles == ["native", "illustrated"]:
        check(game.player.visual.has_illustrated_idle(), "dedicated illustrated idle loads with both styles")
        game._set_art_style("illustrated")
        var visual: Node2D = game.player.visual
        visual.moving = false
        visual.clip = "idle"
        for direction in ["down", "right", "up", "left"]:
            visual.facing = direction
            visual.clock = 0
            check(visual.illustrated_idle_frame() == 0, "idle starts in neutral pose: " + direction)
            visual.clock = 850
            check(visual.illustrated_idle_frame() == 2, "idle has a brief blink or settling phase: " + direction)
            visual.clock = 1600
            check(visual.illustrated_idle_frame() == 0, "idle loops without stepping: " + direction)
        visual.clock = 850
        var clock: float = visual.clock
        game.toggle_art_style()
        game.toggle_art_style()
        check(visual.clock == clock and visual.animation_state().source == "generated-idle", "style comparison preserves the shared idle clock")
        visual.moving = true
        visual._process(0.01)
        check(visual.animation_state().source == "original-walk" and visual.clip == "walk", "movement returns to unchanged original walk art")
        visual.moving = false
        visual._process(0.01)
        check(visual.animation_state().source == "generated-idle" and visual.clip == "idle", "stopping returns to the dedicated idle clip")
    else:
        check(not game.player.visual.has_illustrated_idle() and game.art_style == "radcat", "public fallback has no private idle dependency")
    game.queue_free()
    await process_frame
    OS.delay_msec(150)
    await process_frame
    print("SURVIVORS_RELEASE ", "PASS" if failures.is_empty() else failures)
    quit(0 if failures.is_empty() else 1)
