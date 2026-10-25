extends SceneTree
## Seeded engine fixtures. These do not replace browser or human play tests.
const BALANCE = preload("res://scripts/balance.gd")
const MAIN = preload("res://scenes/main.tscn")
const SEEDS := [7, 42, 314159]
const ROUTE := [Vector2(100, 190), Vector2(860, 190), Vector2(860, 490), Vector2(100, 490)]
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
    if not value:
        failures.append(label)
    print(("PASS " if value else "FAIL ") + label)

func _initialize() -> void:
    call_deferred("run")

func _release_input() -> void:
    for action in ["move_left", "move_right", "move_up", "move_down"]:
        Input.action_release(action)

func _move(direction: Vector2) -> void:
    _release_input()
    if absf(direction.x) > 8.0:
        Input.action_press("move_right" if direction.x > 0 else "move_left")
    if absf(direction.y) > 8.0:
        Input.action_press("move_down" if direction.y > 0 else "move_up")

func _new_game(seed_value: int) -> Node2D:
    var game: Node2D = MAIN.instantiate()
    # The fixture checks gameplay. It does not inspect rendered art.
    game.visible = false
    root.add_child(game)
    game.rng.seed = seed_value
    return game

func _fixture(seed_value: int, moving: bool) -> Dictionary:
    var game := _new_game(seed_value)
    await process_frame
    game.start()
    var waypoint := 0
    var choice := 0
    var maximum_mobs := 0
    var maximum_elites := 0
    var limit := int(BALANCE.ROUND_SECONDS * 60.0) + 180
    for frame in limit:
        if game.state in ["won", "lost"]:
            break
        if game.state == "upgrade":
            game.choose_upgrade(choice % 3)
            choice += 1
        if moving:
            var direction: Vector2 = ROUTE[waypoint] - game.player.position
            if direction.length() < 16:
                waypoint = (waypoint + 1) % ROUTE.size()
                direction = ROUTE[waypoint] - game.player.position
            _move(direction)
        else:
            _release_input()
        maximum_mobs = maxi(maximum_mobs, game.mobs.size())
        var elites := 0
        for mob in game.mobs:
            if is_instance_valid(mob) and not mob.is_queued_for_deletion() and mob.elite:
                elites += 1
        maximum_elites = maxi(maximum_elites, elites)
        await physics_frame
    _release_input()
    var outcome := {"seed": seed_value, "policy": "circuit-upgrades" if moving else "idle", "state": game.state, "elapsed": snappedf(game.elapsed, 0.01), "health": snappedf(game.player.health, 0.1), "kills": game.kills, "upgrades": game.upgrades.size(), "max_mobs": maximum_mobs, "max_elites": maximum_elites}
    check(game.state in ["won", "lost"], "fixture reaches an outcome: %s/%s" % [seed_value, outcome.policy])
    check(maximum_mobs <= BALANCE.MAX_MOBS and maximum_elites <= BALANCE.MAX_ELITES, "live pressure caps: %s/%s" % [seed_value, outcome.policy])
    game.queue_free()
    await process_frame
    print("BALANCE_FIXTURE ", JSON.stringify(outcome))
    return outcome

func _restart_fixture() -> void:
    var game := _new_game(42)
    await process_frame
    game.start()
    game.elapsed = 65.0
    var mob: Node2D = game.spawn_mob()
    game.gems.append(Vector2(200, 200))
    game.xp = 3
    game.level = 4
    game.kills = 8
    game.upgrades.append(1)
    game.gun.damage = 8
    game.gun.interval = 0.14
    game.player.health = 10
    game.player.speed = 300
    game.restart()
    check(game.elapsed == 0 and game.spawn_clock == 0 and game.kills == 0 and game.xp == 0 and game.level == 1 and game.upgrades.is_empty(), "restart clears round counters and upgrades")
    check(game.mobs.is_empty() and game.gems.is_empty() and (mob == null or mob.is_queued_for_deletion()), "restart removes prior-wave enemies and XP")
    check(game.player.health == BALANCE.PLAYER_HEALTH and game.player.speed == BALANCE.PLAYER_SPEED and game.gun.interval == BALANCE.GUN_INTERVAL and game.gun.damage == BALANCE.GUN_DAMAGE and game.gun.cooldown == 0, "restart restores profile defaults")
    var new_mob: Node2D = game.spawn_mob()
    check(new_mob != null and not new_mob.elite and is_equal_approx(new_mob.speed, BALANCE.enemy_speed(0)) and new_mob.health == BALANCE.NORMAL_HEALTH, "restart returns to first-wave pressure")
    game.elapsed = 65.0
    for index in BALANCE.MAX_MOBS + 20:
        game.spawn_mob()
    var elites := 0
    for live_mob in game.mobs:
        elites += int(live_mob.elite)
    check(game.mobs.size() == BALANCE.MAX_MOBS and game.spawn_mob() == null and elites <= BALANCE.MAX_ELITES, "forced spawn fixture enforces enemy and elite hard caps")
    game.queue_free()
    await process_frame

func run() -> void:
    # Stop once if prepare/import was skipped. Avoid a null-texture error per frame.
    for path in ["res://assets/radcat-motion-v2/sprites/idle-sheet.png", "res://assets/radcat-motion-v2/sprites/walk-sheet.png"]:
        if not load(path) is Texture2D:
            push_error("Run scripts/prepare.py and Godot --headless --editor --import --quit before this test.")
            quit(1)
            return
    check(BALANCE.ROUND_SECONDS == 90 and BALANCE.wave_number(-1) == 1 and BALANCE.wave_number(29.999) == 1 and BALANCE.wave_number(30) == 2 and BALANCE.wave_number(60) == 3 and BALANCE.wave_number(999) == 3, "three bounded wave stages at 30 and 60 seconds")
    check(BALANCE.spawn_interval(30) < BALANCE.spawn_interval(29.999) and BALANCE.spawn_interval(60) < BALANCE.spawn_interval(59.999) and BALANCE.enemy_speed(30) > BALANCE.enemy_speed(29.999) and BALANCE.enemy_speed(60) > BALANCE.enemy_speed(59.999), "each wave increases spawn and movement pressure")
    var bounded := true
    var monotonic := true
    var previous_interval := BALANCE.spawn_interval(-1)
    var previous_speed := BALANCE.enemy_speed(-1)
    for second in range(-1, 181):
        bounded = bounded and BALANCE.spawn_interval(second) >= 0.34 and BALANCE.spawn_interval(second) <= 0.95 and BALANCE.enemy_speed(second, true) <= BALANCE.MAX_ENEMY_SPEED and BALANCE.elite_chance(second) >= 0 and BALANCE.elite_chance(second) <= 0.25
        monotonic = monotonic and BALANCE.spawn_interval(second) <= previous_interval and BALANCE.enemy_speed(second) >= previous_speed
        previous_interval = BALANCE.spawn_interval(second)
        previous_speed = BALANCE.enemy_speed(second)
    check(bounded and BALANCE.elite_chance(29.999) == 0 and BALANCE.elite_chance(30) > 0 and BALANCE.xp_threshold(1) == 4 and BALANCE.xp_threshold(7) == 28, "profile caps and unchanged XP progression")
    check(monotonic, "pressure grows without a later-wave difficulty drop")
    await _restart_fixture()
    var idle_losses := 0
    var moving_wins := 0
    var outcomes: Array = []
    for seed_value in SEEDS:
        var idle: Dictionary = await _fixture(seed_value, false)
        var moving: Dictionary = await _fixture(seed_value, true)
        outcomes.append(idle)
        outcomes.append(moving)
        idle_losses += int(idle.state == "lost")
        moving_wins += int(moving.state == "won")
    check(idle_losses > 0, "idle policy can lose across fixed seeds")
    check(moving_wins > 0, "moving policy with upgrades can win across fixed seeds")
    # Repeat one seed to detect random/global state leaks between rounds.
    var repeat: Dictionary = await _fixture(SEEDS[0], true)
    check(repeat == outcomes[1], "same seeded policy repeats without stale scene state")
    # Fast fixed-FPS fixtures can finish before the audio thread releases WAV playback.
    OS.delay_msec(150)
    await process_frame
    print("SURVIVORS_BALANCE ", "PASS" if failures.is_empty() else failures)
    quit(0 if failures.is_empty() else 1)
