extends SceneTree
var failures: Array[String] = []
var game
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)
func frames(count: int) -> void:
    for frame in count:
        await physics_frame
        await process_frame
func run() -> void:
    root.size = Vector2i(960, 720)
    # Dummy audio has no wall-clock mixer in fixed-fps headless runs.
    root.get_node("Audio").set_process(false)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await frames(5)
    check(game.state == "ready", "Start must wait for player action.")
    var skeletons = game.player.model.find_children("*", "Skeleton3D", true, false)
    check(skeletons.size() == 1 and skeletons[0].get_bone_count() == 17, "Keep all 17 Radcat bones.")
    var morphs := 0
    for mesh in game.player.model.find_children("*", "MeshInstance3D", true, false):
        morphs += mesh.mesh.get_blend_shape_count()
    check(morphs >= 35, "Keep at least 35 Radcat morph targets.")
    for motion in ["idle", "walk", "jog", "hop"]:
        check(game.player.animation.has_animation(motion), "Keep motion " + motion)
    game.start()
    await frames(30)
    check(game.player.is_on_floor(), "Player must land on first island.")
    Input.action_press("move_forward")
    await frames(10)
    Input.action_release("move_forward")
    check(game.player.position.z < 0.5, "Movement must advance the collision body.")
    check(game.player.animation.current_animation == "jog", "Travel must use imported jog animation.")
    game.player.jump()
    await frames(8)
    check(game.player.jumps_left == 1 and game.player.position.y > 0.9, "First jump must rise.")
    game.player.jump()
    check(game.player.jumps_left == 0, "Second jump consumes the remaining jump.")
    game.player.velocity.y = 1
    game.player.jump()
    check(game.player.velocity.y == 1, "Third jump must be blocked.")
    game.toggle_pause()
    var before: Vector3 = game.player.position
    var elapsed: float = game.elapsed
    var coin_y: float = game.coins[0].position.y
    await frames(10)
    check(game.player.position == before and game.elapsed == elapsed and game.coins[0].position.y == coin_y, "Pause must freeze player, time and world.")
    game.toggle_pause()
    game.restart()
    game.player.position = Vector3(0, 1.2, -18)
    game.player.velocity = Vector3.ZERO
    await frames(20)
    check(game.falling.falling, "Landing must trigger the falling platform.")
    await frames(45)
    check(game.falling.position.y < -0.2, "Triggered platform must fall.")
    game.restart()
    check(not game.falling.falling and game.falling.position.y > 0.5, "Restart must restore the platform.")
    for coin in game.coins:
        game.player.position = Vector3(0, coin.base_y - 0.2, coin.position.z)
        game.player.velocity = Vector3.ZERO
        await frames(3)
    check(game.player.coins == 6, "Actual Area contacts must collect all coins.")
    check(game.state == "playing", "Coins alone must not finish the game.")
    game.player.position = Vector3(0, 1.6, -31)
    await frames(4)
    check(game.state == "won", "Flag contact with six coins must win.")
    game.restart()
    check(game.player.coins == 0 and game.coins[0].visible, "Restart must restore coins.")
    game.player.position.y = -9
    await frames(2)
    check(game.state == "lost", "Falling must show loss state.")
    game.restart()
    var snapshot: Dictionary = JSON.parse_string(game.state_text())
    check(snapshot.state == "playing" and snapshot.total == 6, "Text state must report actual restart.")
    if failures.is_empty():
        print("PASS: 17 bones, %d morphs, four motions, movement, physical double jump, third-jump block, pause, falling-platform contacts/reset, six coin contacts, finish, loss, restart and text state." % morphs)
    for sound in root.get_node("Audio").get_children():
        sound.stop()
        sound.stream = null
    await create_timer(0.1).timeout
    game.queue_free()
    await frames(3)
    game = null
    quit(0 if failures.is_empty() else 1)
