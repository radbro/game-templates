extends SceneTree
## Run with: godot --headless --path . --script tests/smoke.gd
var failures: Array[String] = []
var game

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func frames(count: int) -> void:
    for index in count:
        await physics_frame
        await process_frame

func touch(index: int, position: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.position = position
    event.pressed = pressed
    root.push_input(event, true)

func run() -> void:
    root.size = Vector2i(960, 720)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await frames(3)
    check(game.state == "ready", "The round must wait for Start.")
    check(game.player.animation_player != null, "The full import must contain AnimationPlayer.")
    var motions: PackedStringArray = game.player.animation_player.get_animation_list()
    for motion in ["idle", "walk", "jog", "hop"]:
        check(motions.has(motion), "Missing imported motion: " + motion)
        if motion != "hop":
            check(game.player.animation_player.get_animation(motion).loop_mode == Animation.LOOP_LINEAR, "Movement and idle motions must loop.")
    var skeletons: Array[Node] = game.player.model.find_children("*", "Skeleton3D", true, false)
    check(skeletons.size() == 1 and skeletons[0].get_bone_count() == 17, "Preserve all 17 imported bones.")
    var morphs := 0
    for mesh in game.player.model.find_children("*", "MeshInstance3D", true, false):
        morphs += mesh.mesh.get_blend_shape_count()
    check(morphs >= 35, "Preserve imported morph targets.")
    game.start()
    var initial_x: float = game.player.position.x
    Input.action_press("move_right")
    await frames(20)
    Input.action_release("move_right")
    check(game.player.position.x > initial_x + 1.0, "Keyboard movement must move the collision body.")
    check(game.player.animation_player.current_animation == "jog", "Movement must play the imported jog motion.")
    game.restart()
    touch(0, Vector2(282, 660), true)
    await frames(12)
    touch(1, Vector2(850, 660), true)
    await frames(3)
    check(game.player.position.x > 0.8 and game.player.hop_remaining > 0.0, "Two touch contacts must move and hop together.")
    touch(0, Vector2(282, 660), false)
    touch(1, Vector2(850, 660), false)
    game.toggle_pause()
    var paused_time: float = game.time_left
    var paused_position: Vector3 = game.player.position
    await frames(5)
    check(game.time_left == paused_time and game.player.position == paused_position, "Pause must freeze movement and timer.")
    game.toggle_pause()
    # Test fixtures place the player. The shipped game has no teleport control.
    game.player.position = Vector3(0, 0.05, 4.4)
    await frames(3)
    Input.action_press("move_up")
    await frames(30)
    Input.action_release("move_up")
    check(game.player.position.z > 3.6, "The barrier must block the player body.")
    game.player.position = Vector3(7, 0.05, 8)
    await frames(2)
    Input.action_press("move_right")
    await frames(30)
    Input.action_release("move_right")
    check(game.player.position.x < 7.5, "The boundary wall must block the player body.")
    game.restart()
    game.player.position = Vector3(-5, 0.05, 0)
    await frames(4)
    check(game.time_left < 56 and game.damage_cooldown > 0, "An unprotected hazard hit must cost five seconds.")
    game.restart()
    game.player.hop()
    game.player.position = Vector3(-5, 0.05, 0)
    await frames(4)
    check(game.time_left > 59 and game.damage_cooldown == 0, "Hop must protect the player from hazards.")
    check(game.player.animation_player.current_animation == "hop", "Hop must play the imported hop motion.")
    game.restart()
    for pickup in game.get_node("Pickups").get_children():
        game.player.position = pickup.position + Vector3(0, 0.05, 0)
        await frames(4)
    check(game.collected == 4, "Actual Area3D contacts must collect all four pickups.")
    check(game.state == "playing", "Pickups alone must not win the round.")
    game.player.position = Vector3(0, 0.05, 8)
    await frames(4)
    check(game.state == "won", "Returning all energy to the gate must win.")
    game.restart()
    check(game.collected == 0 and game.time_left == game.round_seconds, "Restart must reset score and timer.")
    for pickup in game.get_node("Pickups").get_children():
        check(pickup.visible, "Restart must restore pickup visuals.")
    game.time_left = 0.01
    await frames(3)
    check(game.state == "lost", "Timer expiry must lose the round.")
    var snapshot: Dictionary = JSON.parse_string(game.state_text())
    check(snapshot["state"] == "lost" and snapshot["total"] == 4, "Text state must report the actual outcome.")
    if failures.is_empty():
        print("PASS: import (17 bones, %d morphs, four motions), input, multi-touch, animation, pause, barriers, walls, hazards, hop, pickup contacts, gate win, restart, timeout, state text." % morphs)
    game.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
