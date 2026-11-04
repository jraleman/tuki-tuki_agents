extends SceneTree

## Require real rendered lanes and usable native controls from portrait to ultrawide.

const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Tuki Tuki stage_view_test requires a real graphics window.")
		quit(1)
		return
	GameCatalog.select(Options.GAME_ID)
	var settings := get_root().get_node("Settings")
	var save_timer := settings.get("_save_timer") as Timer
	var timer_mode := save_timer.process_mode
	save_timer.process_mode = Node.PROCESS_MODE_DISABLED
	var old_difficulty: Variant = settings.call("get_value", Options.DIFFICULTY_KEY)
	var old_mode: Variant = settings.call("get_value", Options.MODE_KEY)
	var session := get_root().get_node("GameSession")
	var packed := load(Options.ROOT + "gameplay.tscn") as PackedScene
	for multiplayer in [false, true]:
		if multiplayer:
			session.call("configure_multiplayer", 0, 1)
		else:
			session.call("configure_single_player")
		session.call("set_level", "tutorial_basic")
		var game := packed.instantiate()
		get_root().add_child(game)
		await process_frame
		await _check_briefing(game, multiplayer)
		game.call("_on_dance_requested", 0, 1)
		await process_frame
		game.call("set_process", false)
		(game.get("_audio") as Node).call("set_paused", true)
		(game.get("_stage") as Node).call("present", game.get("_state"), -1700.0, 1.0)
		for size in [Vector2i(1280, 720), Vector2i(480, 800), Vector2i(1920, 720)]:
			await _check_stage(game, size, multiplayer)
		game.free()
	settings.call("set_value", Options.DIFFICULTY_KEY, old_difficulty)
	settings.call("set_value", Options.MODE_KEY, old_mode)
	save_timer.stop()
	save_timer.process_mode = timer_mode
	await process_frame
	if _failures.is_empty():
		print("Tuki Tuki rendered stage tests passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)


func _check_briefing(game: Node, multiplayer: bool) -> void:
	var briefing: Control = game.get("_briefing")
	for size in [Vector2i(1280, 720), Vector2i(480, 800)]:
		get_root().size = size
		game.call("_begin_first_round")
		for frame in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var panel := briefing.get("_panel") as Control
		var logical: Rect2 = game.call("get_viewport_rect")
		_expect(logical.encloses(panel.get_global_rect()),
			"The scrolling song briefing must stay inside the viewport.")
		var scroll := briefing.get("_scroll") as ScrollContainer
		var title := (briefing.get("_song_label") as Control).get_parent().get_child(0) as Control
		_expect(scroll.get_global_rect().encloses(title.get_global_rect()),
			"The opening briefing must not scroll past its headline.")
		_capture("tuki-%s-briefing-%dx%d.png" % [
			"local" if multiplayer else "solo", size.x, size.y,
		])
		var start := briefing.get("_start") as Button
		start.grab_focus()
		for frame in 3:
			await process_frame
		_expect(panel.get_global_rect().encloses(start.get_global_rect()),
			"Keyboard focus must scroll the Dance button into view.")


func _check_stage(game: Node, size: Vector2i, multiplayer: bool) -> void:
	get_root().size = size
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var stage := game.get("_stage") as Node3D
	var viewport := game.get("_stage_viewport") as SubViewport
	var image := viewport.get_texture().get_image()
	var colorful := 0
	for y in range(0, image.get_height(), 7):
		for x in range(0, image.get_width(), 7):
			var color := image.get_pixel(x, y)
			if maxf(color.r, maxf(color.g, color.b)) \
				- minf(color.r, minf(color.g, color.b)) > 0.2:
				colorful += 1
	_expect(colorful > 100,
		"The Compatibility viewport must render real colored meshes at %s." % size)
	if colorful <= 100:
		print("Layout diagnostics: logical=", game.call("get_viewport_rect"),
			" bounds=", game.call("_playfield_bounds"),
			" stage=", (game.get("_stage_container") as Control).get_global_rect(),
			" hint=", (game.get_node("%Hint") as Control).get_global_rect(),
			" pads=", (game.get("_pads_root") as Control).get_global_rect())
	var camera: Camera3D = stage.get("_camera")
	var rect := Rect2(Vector2.ZERO, Vector2(viewport.size))
	for pad: MeshInstance3D in stage.get("_pads"):
		if pad.visible:
			_expect(rect.has_point(camera.unproject_position(pad.global_position)),
				"Every front target must remain in frame at %s." % size)
	for button: Button in game.get("_pad_buttons"):
		if not button.is_visible_in_tree():
			continue
		var logical_rect: Rect2 = game.call("get_viewport_rect")
		var pixels := float(get_root().size.x) / logical_rect.size.x
		_expect(button.get_global_rect().size.x * pixels >= 44.0
			and button.get_global_rect().size.y * pixels >= 44.0,
			"On-screen pads must retain a usable physical touch area.")
	_capture("tuki-%s-%dx%d.png" % [
		"local" if multiplayer else "solo", size.x, size.y,
	])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _capture(filename: String) -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			var folder := argument.trim_prefix("--capture-dir=")
			var path := folder.path_join(filename)
			_expect(get_root().get_texture().get_image().save_png(path) == OK,
				"The rendered verification image must save successfully.")
