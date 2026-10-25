extends SceneTree
var game: Node2D
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
    if not value: failures.append(label)
    print(('PASS ' if value else 'FAIL ') + label)
func _initialize() -> void:
    call_deferred('run')
func run() -> void:
    game = load('res://scenes/main.tscn').instantiate()
    root.add_child(game)
    await process_frame
    check(game.state == 'ready', 'starts at ready')
    var visual_id: int = game.player.visual.get_instance_id()
    var starting_style: String = game.art_style
    game.toggle_art_style()
    game.toggle_art_style()
    check(game.player.visual.get_instance_id() == visual_id and game.art_style == starting_style, 'art toggle preserves the player visual node')
    game.start()
    var origin: Vector2 = game.player.position
    Input.action_press('move_right')
    for frame in 20: await physics_frame
    Input.action_release('move_right')
    check(game.player.position.x > origin.x + 30, 'keyboard movement')
    game.player.position = Vector2(920, 340)
    Input.action_press('move_right')
    for frame in 5: await physics_frame
    Input.action_release('move_right')
    check(game.player.position.x <= 920, 'arena bounds')
    game.restart()
    game.spawn_clock = 1000
    var mob = game.spawn_mob()
    mob.position = game.player.position + Vector2(85, 0)
    mob.speed = 0
    for frame in 90: await physics_frame
    check(game.kills >= 1 and game.gun.shots >= 2, 'autoaim projectiles kill enemy')
    check(game.gems.size() >= 1 or game.xp >= 1, 'kill drops or collects XP')
    game.gems.clear()
    game.xp = 0
    for i in 4: game.gems.append(game.player.position)
    for frame in 3: await physics_frame
    check(game.state == 'upgrade' and game.level == 2, 'XP triggers paused upgrade')
    if game.available_art_styles.size() == 2:
        check(['muzzle', 'hit', 'defeat', 'pickup', 'upgrade'].all(func(kind): return game.effects.event_counts.get(kind, 0) > 0), 'combat and XP emit all five feedback kinds')
    var time: float = game.elapsed
    for frame in 5: await physics_frame
    check(game.elapsed == time, 'upgrade freezes round')
    game.choose_upgrade(0)
    check(game.state == 'playing' and game.gun.interval < 0.45, 'rapid fire choice resumes')
    game.state = 'upgrade'
    game.choose_upgrade(1)
    check(game.gun.damage == 2, 'power choice')
    game.player.health = 50
    game.state = 'upgrade'
    game.choose_upgrade(2)
    check(game.player.speed == 202 and game.player.health == 80, 'speed and heal choice')
    game.toggle_pause()
    time = game.elapsed
    for frame in 10: await physics_frame
    check(game.state == 'paused' and game.elapsed == time, 'pause freezes clock')
    game.toggle_pause()
    check(game.state == 'playing', 'resume')
    mob = game.spawn_mob()
    mob.speed = 0
    mob.position = game.player.position
    game.player.health = 0.1
    for frame in 5: await physics_frame
    check(game.state == 'lost', 'contact damage causes game over')
    game.restart()
    check(game.player.health == 100 and game.level == 1 and game.kills == 0, 'restart clears round')
    check(game.effects.events.is_empty() and game.effects.event_counts.is_empty(), 'restart clears bounded visual feedback')
    game.elapsed = game.round_seconds - 0.02
    for frame in 5: await physics_frame
    check(game.state == 'won', 'survival timer wins')
    if '--radbro-review' in OS.get_cmdline_user_args():
        var visual = game.player.visual
        check(visual.using_paperdoll, 'private paperdoll loads')
        visual.equip(['pirate', 'blue-shades', 'nobody'])
        var ids: Array = visual.parts.map(func(p): return p.id)
        check('base-eye-left' not in ids and 'base-eye-right' not in ids, 'equipment occludes base eyes')
        visual.clip = 'walk'
        visual.clock = 120
        check(visual.paperdoll_frame() == 5, 'shared variable frame clock')
        check(visual.parts.size() > 10, 'equipment stays layered')
    print('SURVIVORS_SMOKE ', 'PASS' if failures.is_empty() else failures)
    game.queue_free()
    await process_frame
    OS.delay_msec(150)
    await process_frame
    quit(0 if failures.is_empty() else 1)
