# Native screenshot capture for local art comparison. Not included in Web export.
extends SceneTree
func _initialize() -> void:
    call_deferred('run')
func run() -> void:
    var game = load('res://scenes/main.tscn').instantiate()
    root.add_child(game)
    await process_frame
    game.start()
    game.spawn_clock = 1000
    var review := '--radbro-review' in OS.get_cmdline_user_args()
    if review:
        game.player.visual.equip(['pirate', 'cross', 'blue-bandana', 'nobody', 'blue-shades'])
    Input.action_press('move_right')
    for frame in 35: await physics_frame
    Input.action_release('move_right')
    await RenderingServer.frame_post_draw
    var suffix := 'radbro-review' if review else 'radcat-default'
    var folder := ProjectSettings.globalize_path('res://../../evidence/survivors')
    DirAccess.make_dir_recursive_absolute(folder)
    root.get_texture().get_image().save_png(folder + '/' + suffix + '.png')
    print('Saved local comparison: ', suffix)
    quit()
