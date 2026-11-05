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
	var old_scale: Variant = settings.call("get_value", "ui/scale")
	var old_motion: Variant = settings.call("get_value", Settings.REDUCED_MOTION_KEY)
	settings.call("set_value", Settings.REDUCED_MOTION_KEY, true)
	await _check_feature_views(settings)
	settings.call("set_value", Settings.REDUCED_MOTION_KEY, false)
	settings.call("set_value", "ui/scale", 1.0)
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
	settings.call("set_value", "ui/scale", old_scale)
	settings.call("set_value", Settings.REDUCED_MOTION_KEY, old_motion)
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


func _check_feature_views(settings: Node) -> void:
	var packed := load("res://scenes/menus/gallery.tscn") as PackedScene
	var gallery := packed.instantiate()
	gallery.set("game_context_id", Options.GAME_ID)
	get_root().add_child(gallery)
	var intro := (load(GameCatalog.current().intro_scene_path) as PackedScene).instantiate()
	get_root().add_child(intro)
	intro.call("set_process", false)
	(intro.get("_audio") as Node).call("set_paused", true)
	intro.call("_present_demo", 2100.0)
	for scale in [1.0, 1.5]:
		settings.call("set_value", "ui/scale", scale)
		for size in [Vector2i(1280, 720), Vector2i(480, 800), Vector2i(1920, 720)]:
			get_root().size = size
			intro.hide()
			gallery.show()
			for index in Options.GALLERY_EXHIBITS.size():
				gallery.call("_on_exhibit_pressed", index)
				var preview: Node = gallery.get("_stage")
				preview.call("set_view", 0.0, 0.0, 1.0)
				await _draw_frames()
				_check_model_pixels(preview, "Gallery %d at %s / %.1fx" % [index, size, scale])
				_check_model_framing(preview)
			var viewer := gallery.get_node("%Viewer") as Control
			_expect((gallery as Control).get_viewport_rect().encloses(viewer.get_global_rect()),
				"The gallery's real model area must fit portrait, landscape and enlarged UI.")
			_capture("tuki-gallery-%dx%d-%.1fx.png" % [size.x, size.y, scale])
			gallery.hide()
			intro.show()
			await _draw_frames()
			for field in ["_card", "_skip", "_stage_container"]:
				var control := intro.get(field) as Control
				_expect((intro as Control).get_viewport_rect().encloses(control.get_global_rect()),
					"Intro text, stage and Skip must remain wholly usable at %s / %.1fx."
					% [size, scale])
			var skip := intro.get("_skip") as Control
			var pixels := float(size.x) / (intro as Control).get_viewport_rect().size.x
			_expect(skip.size.y * pixels >= 44.0, "Intro Skip must keep a physical touch target.")
			_capture("tuki-intro-%dx%d-%.1fx.png" % [size.x, size.y, scale])
	intro.free()
	gallery.free()
	settings.call("set_value", "ui/scale", 1.0)
	get_root().size = Vector2i(1280, 720)
	var preview := (load(GameCatalog.current().store_preview_scene_path) as PackedScene) \
		.instantiate() as Control
	get_root().add_child(preview)
	preview.size = Vector2(520, 360)
	var previous := PackedByteArray()
	for item: Dictionary in get_root().get_node("Store").call("items", Options.GAME_ID):
		preview.call("configure", item)
		preview.call("set_preview_running", false)
		await _draw_frames()
		_check_model_pixels(preview, "Store " + str(item["id"]))
		var image := (preview.get("_viewport") as SubViewport).get_texture().get_image()
		_expect(image.get_data() != previous,
			"Different shop cosmetics must produce different actual-model pictures.")
		previous = image.get_data()
	preview.free()
	preview = (load(GameCatalog.current().character_preview_scene_path) as PackedScene) \
		.instantiate() as Control
	get_root().add_child(preview)
	preview.size = Vector2(640, 420)
	for character in GameCatalog.current().characters:
		preview.call("configure", {"character": character, "player_index": 1})
		await _draw_frames()
		_check_model_pixels(preview, "Setup " + str(character["id"]))
		_check_model_framing(preview)
	preview.free()
	await process_frame


func _draw_frames() -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw


func _check_model_pixels(preview: Node, label: String) -> void:
	var image := (preview.get("_viewport") as SubViewport).get_texture().get_image()
	var colored := 0
	for y in range(0, image.get_height(), 7):
		for x in range(0, image.get_width(), 7):
			var color := image.get_pixel(x, y)
			if color.a > 0.1 and maxf(color.r, maxf(color.g, color.b)) \
					- minf(color.r, minf(color.g, color.b)) > 0.12:
				colored += 1
	_expect(colored > 40, label + " must render real colored geometry, not an empty preview.")


func _check_model_framing(preview: Node) -> void:
	var camera: Camera3D = preview.get("_camera")
	var viewport: SubViewport = preview.get("_viewport")
	var rect := Rect2(Vector2.ZERO, Vector2(viewport.size))
	for node in (preview.get("_subject") as Node).find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if not mesh.is_visible_in_tree():
			continue
		for corner in 8:
			_expect(rect.has_point(camera.unproject_position(
				mesh.to_global(mesh.get_aabb().get_endpoint(corner)))),
				"Default gallery and setup framing must retain every visible model extremity.")


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
	for dancer: Node3D in stage.get("_dancers"):
		for y in [0.0, 2.4]:
			_expect(rect.has_point(camera.unproject_position(
				dancer.global_position + Vector3(0, y, 0))),
				"Both champions must remain visible from shoes to head at %s." % size)
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
