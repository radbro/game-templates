extends SceneTree
## Exercise the vendored systems. This test does not replace browser play checks.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://radbro/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.wave == 1 and game.remaining == 3)
	assert(game.player.character_stats.current_life == 6)
	game.toggle_pause()
	assert(paused and game.phase == "paused")
	game.toggle_pause()
	assert(not paused and game.phase == "playing")
	var target = game.room.get_node("Enemies").get_child(0)
	for enemy in game.room.get_node("Enemies").get_children():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	target.global_position = game.player.position + Vector2(0, -100)
	var weapon = game.player.get_node("Visual/DistanceWeapon")
	weapon.shoot_direction = Vector2.UP
	weapon._shoot_time = 1.0
	weapon.shoot()
	for i in range(30):
		await physics_frame
	assert(target.character_stats.current_life == 1, "The upstream bullet must damage the enemy through collision.")
	for enemy in game.room.get_node("Enemies").get_children():
		enemy.hit(99)
	await process_frame
	await process_frame
	assert(game.wave == 2 and game.remaining == 4)
	for enemy in game.room.get_node("Enemies").get_children():
		enemy.hit(99)
	await process_frame
	await process_frame
	assert(game.key_spawned and game.remaining == 0)
	game._door_entered(Vector2.UP)
	assert(game.phase == "playing", "The door must require a key.")
	var key_item
	for item in game.get_children():
		if item is QuiverPickableItem and item.item.name == "Key":
			key_item = item
	assert(key_item != null)
	key_item.trigger_action(game.player)
	assert(game.player.inventory.get_item_amount("Key") == 1)
	game._door_entered(Vector2.UP)
	assert(game.phase == "won" and paused)
	paused = false
	game.free()
	game = load("res://radbro/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.player.hit(99)
	assert(game.phase == "lost" and paused)
	paused = false
	game.free()
	print("TINY WIZARD SMOKE PASSED: collision damage, two waves, key gate, win, loss, pause.")
	quit(0)
