extends SceneTree

## Real briefing, rebound input, pause/settings, song ending and simultaneous seats.

const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
const Sound = preload("res://games/tuki-tuki_agents/audio/rhythm_audio.gd")
const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")
var _failures := PackedStringArray()
var _settings: Node
var _session: Node
var _store: Node
var _achievements: Node
var _old_values: Dictionary = {}
var _save_timer: Timer
var _timer_mode := Node.PROCESS_MODE_INHERIT


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_settings = get_root().get_node("Settings")
	_session = get_root().get_node("GameSession")
	_store = get_root().get_node("Store")
	_achievements = get_root().get_node("AchievementManager")
	if not GameCatalog.select(Options.GAME_ID):
		printerr("The native Tuki Tuki manifest was not discovered.")
		quit(1)
		return
	if "--expect-release" in OS.get_cmdline_user_args():
		_test_release_contract()
	_save_timer = _settings.get("_save_timer") as Timer
	_timer_mode = _save_timer.process_mode
	_save_timer.process_mode = Node.PROCESS_MODE_DISABLED
	for option in Options.TUNABLES:
		_old_values[option["key"]] = _settings.call("get_value", option["key"])
	for key in [Settings.REDUCED_MOTION_KEY, Settings.VISUAL_EFFECTS_KEY]:
		_old_values[key] = _settings.call("get_value", key)
	_set_option(Settings.REDUCED_MOTION_KEY, false)
	_set_option(Settings.VISUAL_EFFECTS_KEY, true)
	var old_store: Dictionary = _store.call("export_save", Options.GAME_ID)
	var old_achievements: Dictionary = _achievements.call("export_save", Options.GAME_ID)
	_expect(int(_store.call("erase_save", Options.GAME_ID)) == OK,
		"The cosmetic fixture must start with a clean game wallet.")
	_expect(int(_achievements.call("erase_save", Options.GAME_ID)) == OK,
		"The achievement fixture must start with no game unlocks.")
	_set_option(Options.MODE_KEY, 1)
	_set_option(Options.DIFFICULTY_KEY, 0)
	_set_option(Options.OFFSET_KEY, 0.0)
	_set_option(Options.SCROLL_KEY, 1.0)
	_set_option(Options.SFX_KEY, false)
	_session.call("configure_single_player")
	_session.call("set_level", "tutorial_basic")
	_session.call("set_character_for_player", 0, "rodriguez_barquisimeto")
	await _test_rewards()
	await _test_feature_previews()
	await _test_gallery()
	await _test_intro()
	_session.call("configure_single_player")
	_session.call("set_level", "tutorial_basic")
	_session.call("set_character_for_player", 0, "rodriguez_barquisimeto")
	await _test_solo()
	await _test_multiplayer()
	_expect(int(_store.call("import_save", Options.GAME_ID, old_store)) == OK,
		"The cosmetic fixture must restore the original wallet and equipment.")
	_expect(int(_achievements.call("import_save", Options.GAME_ID, old_achievements)) == OK,
		"The achievement fixture must restore the original unlocks.")
	for key: String in _old_values:
		_set_option(key, _old_values[key])
	_save_timer.stop()
	_save_timer.process_mode = _timer_mode
	paused = false
	for node in get_root().find_children("*", "AudioStreamPlayer", true, false):
		var player := node as AudioStreamPlayer
		player.stop()
		player.stream = null
	# Stopped playbacks release on the mixer thread, not the scene frame.
	await create_timer(0.15, true, false, true).timeout
	if _failures.is_empty():
		print("Tuki Tuki gameplay tests passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)


func _test_rewards() -> void:
	var game := await _new_game()
	if game == null:
		return
	game.call("_on_dance_requested", 0, 1)
	await process_frame
	var audio: Node = game.get("_audio")
	audio.call("set_paused", true)
	var before := int(_store.call("points", Options.GAME_ID))
	_expect(int(game.call("_round_points_earned", 0, 0)) < 0,
		"An unfinished song must decline the payout without consuming eligibility.")
	game.call("_award_round_achievements", 0, 0)
	_expect((_achievements.call("export_save", Options.GAME_ID) as Dictionary).is_empty(),
		"An unfinished song must not earn achievements.")
	var state: RefCounted = game.get("_state")
	for note: Dictionary in state.get("notes"):
		audio.set("_last_position", Sound.LEAD_IN + float(note["time"]) * 0.001)
		var event := InputEventAction.new()
		event.action = Options.ACTIONS[0][int(note["lane"])]
		event.pressed = true
		game.call("_handle_gameplay_input", event)
	audio.set("_last_position", Sound.LEAD_IN + 60.11)
	game.call("_update_round", 0.0, 0.0)
	var stats: Dictionary = state.call("stats", 0)
	_expect(float(stats["accuracy"]) == 100.0 and int(stats["streak"]) >= 25,
		"The reward fixture must complete a real chart through the lane adapter.")
	var expected := int(_store.call("default_round_points", Options.GAME_ID, {
		"single_player": true, "player_one_score": stats["score"], "player_two_score": 0,
	}))
	_expect(int(_store.call("points", Options.GAME_ID)) == before + expected,
		"A completed song must bank the declared score-based Beat Tokens.")
	for id in [Options.FIRST_SONG, Options.FLOW_COMBO, Options.PRECISION]:
		_expect(bool(_achievements.call("is_unlocked", id)),
			"A real completed perfect chart must earn %s." % id)
	game.call("_end_round")
	_expect(int(_store.call("points", Options.GAME_ID)) == before + expected,
		"Repeated result settlement must not pay the same song twice.")
	game.call("_on_play_again_pressed")
	await process_frame
	game.call("_end_round")
	_expect(int(_store.call("points", Options.GAME_ID)) == before + expected,
		"Abandoning a replay must not pay its completion bonus.")
	_expect(bool(_achievements.call("is_unlocked", Options.PRECISION)),
		"Later incomplete or inaccurate songs must not revoke achievements.")
	game.free()
	await process_frame


func _test_feature_previews() -> void:
	var packed := load(GameCatalog.current().character_preview_scene_path) as PackedScene
	var preview := packed.instantiate() as Control
	get_root().add_child(preview)
	preview.size = Vector2(640, 420)
	for player in 2:
		for character in Data.CHARACTERS:
			preview.call("configure", {"character": character, "player_index": player})
			var rig: Node = preview.get("_rig")
			_expect(str(rig.get("character_id")) == str(character["id"])
				and rig.get_script() == load(Options.ROOT + "world/champion_rig.gd"),
				"Every setup choice must draw the actual gameplay champion rig.")
	_store.call("add_points", Options.GAME_ID, 160)
	for item: Dictionary in [Options.STORE_ITEMS[1], Options.STORE_ITEMS[5]]:
		_expect(bool(_store.call("purchase", Options.GAME_ID, item["id"])),
			"The shared store must sell the declared original cosmetic.")
	# Purchases automatically wear the first matching default slot.
	_store.call("equip", Options.GAME_ID, Options.DEFAULT_OUTFIT["id"], Options.OUTFIT_SLOTS[0])
	_store.call("equip", Options.GAME_ID, Options.DEFAULT_SHOES["id"], Options.SHOE_SLOTS[0])
	_session.call("configure_multiplayer", 0, 1)
	_session.call("set_level", "tutorial_basic")
	var game := await _new_game()
	if game == null:
		preview.free()
		return
	game.call("_on_dance_requested", 0, 1)
	await process_frame
	game.call("open_pause_menu")
	var audio: Node = game.get("_audio")
	var held := float(audio.call("song_time_ms"))
	var state: RefCounted = game.get("_state")
	var stats: Dictionary = state.call("totals")
	_expect(bool(_store.call("equip", Options.GAME_ID,
		Options.STORE_ITEMS[1]["id"], Options.OUTFIT_SLOTS[1])),
		"A purchased outfit must equip into P2's slot.")
	_expect(bool(_store.call("equip", Options.GAME_ID,
		Options.STORE_ITEMS[5]["id"], Options.SHOE_SLOTS[0])),
		"A purchased shoe must equip into P1's slot.")
	var dancers: Array = (game.get("_stage") as Node).get("_dancers")
	_expect(str((dancers[0] as Node).get("outfit_id")) == str(Options.DEFAULT_OUTFIT["id"])
		and str((dancers[1] as Node).get("outfit_id")) == str(Options.STORE_ITEMS[1]["id"])
		and str((dancers[0] as Node).get("shoes_id")) == str(Options.STORE_ITEMS[5]["id"])
		and str((dancers[1] as Node).get("shoes_id")) == str(Options.DEFAULT_SHOES["id"]),
		"Live wardrobe updates must keep both kinds and both players independent.")
	var shirt := (dancers[1] as Node).get_node("Shirt") as MeshInstance3D
	_expect((shirt.material_override as StandardMaterial3D).albedo_color
		== Options.STORE_ITEMS[1]["color"], "The equipped outfit must change the real mesh.")
	var first_shoes: Array = (dancers[0] as Node).get("_shoes")
	var second_shoes: Array = (dancers[1] as Node).get("_shoes")
	_expect(((first_shoes[0] as MeshInstance3D).mesh as BoxMesh).size.y
		> ((second_shoes[0] as MeshInstance3D).mesh as BoxMesh).size.y,
		"Normalized shop items must resolve game-owned shoe geometry by stable id.")
	_expect(game.get("_state") == state and state.call("totals") == stats
		and float(audio.call("song_time_ms")) == held,
		"Equipping from pause must preserve note resolution, scores and musical position.")
	var preview_rig: Node = preview.get("_rig")
	_expect(str(preview_rig.get("outfit_id")) == str(Options.STORE_ITEMS[1]["id"]),
		"The existing P2 setup preview must also wear the live equipped outfit.")
	_set_option(Settings.REDUCED_MOTION_KEY, true)
	_expect(not preview.is_processing() and preview_rig.get("rotation") == Vector3.ZERO,
		"Live reduced motion must park the setup preview.")
	_set_option(Settings.REDUCED_MOTION_KEY, false)
	(game.get("_pause_menu") as Node).call("resume")
	game.free()
	preview.free()
	await process_frame


func _test_gallery() -> void:
	var before_store: Dictionary = _store.call("export_save", Options.GAME_ID)
	var before_unlocks: Dictionary = _achievements.call("export_save", Options.GAME_ID)
	var packed := load("res://scenes/menus/gallery.tscn") as PackedScene
	var gallery := packed.instantiate()
	gallery.set("game_context_id", Options.GAME_ID)
	get_root().add_child(gallery)
	await process_frame
	await process_frame
	var buttons: Array = gallery.get("_buttons")
	for index in Options.GALLERY_EXHIBITS.size():
		_expect(not (buttons[index] as Button).disabled,
			"Every gallery model must remain freely viewable.")
		gallery.call("_on_exhibit_pressed", index)
		await process_frame
		var stage: Node = gallery.get("_stage")
		var camera: Camera3D = stage.get("_camera")
		var before := camera.position
		stage.call("set_view", 0.4, 0.1, 1.2)
		_expect(camera.position != before
			and (stage.get("_subject") as Node).get_child_count() > 0,
			"Each real exhibit must support inspection rather than a placeholder picture.")
	_expect(_store.call("export_save", Options.GAME_ID) == before_store
		and _achievements.call("export_save", Options.GAME_ID) == before_unlocks,
		"The free gallery must neither spend tokens nor write progression.")
	gallery.free()
	await process_frame


func _test_intro() -> void:
	var before_store: Dictionary = _store.call("export_save", Options.GAME_ID)
	var before_unlocks: Dictionary = _achievements.call("export_save", Options.GAME_ID)
	var router := get_root().get_node("Router")
	var routes: Array[String] = []
	var on_route := func(path: String) -> void: routes.append(path)
	router.connect("scene_changed", on_route)
	var packed := load(GameCatalog.current().intro_scene_path) as PackedScene
	for ending in ["timeout", "skip", "cancel", "entry_cancel"]:
		var intro := packed.instantiate()
		get_root().add_child(intro)
		current_scene = intro
		await process_frame
		var audio: Node = intro.get("_audio")
		audio.call("set_paused", true)
		audio.set("_last_position", Sound.LEAD_IN + 3.0)
		intro.call("_process", 0.0)
		var state: RefCounted = intro.get("_state")
		_expect(int(state.call("stats", 0)["hits"]) > 0
			and state.call("stats", 0)["hits"] == state.call("stats", 1)["hits"],
			"The opening must demonstrate real independent rhythm lanes without a round.")
		_set_option(Settings.REDUCED_MOTION_KEY, true)
		intro.call("_process", 0.0)
		var stage: Node = intro.get("_stage")
		var arrows: Array = stage.get("_arrows")
		var position := (arrows[0] as Node3D).position
		audio.set("_last_position", Sound.LEAD_IN + 4.0)
		intro.call("_process", 0.0)
		_expect((arrows[0] as Node3D).position == position
			and bool(stage.get("reduced_motion")),
			"Reduced motion must freeze decorative opening arrows without freezing its clock.")
		_set_option(Settings.REDUCED_MOTION_KEY, false)
		var before := routes.size()
		if ending == "entry_cancel":
			router.set("_busy", true)
		if ending == "timeout":
			intro.call("_present_demo", 9600.0)
		elif ending in ["cancel", "entry_cancel"]:
			var event := InputEventAction.new()
			event.action = &"ui_cancel"
			event.pressed = true
			intro.call("_unhandled_input", event)
		else:
			intro.call("_on_skip_pressed")
		intro.call("_on_skip_pressed")
		_expect(bool(intro.get("_finished"))
			and not (audio.get("player") as AudioStreamPlayer).playing,
			"Every opening exit must stop its own synthesized playback immediately.")
		if ending == "entry_cancel":
			_expect(routes.size() == before,
				"Skipping during entry must wait for the existing router transition.")
			router.set("_busy", false)
			router.emit_signal("transition_finished", Options.ROOT + "intro.tscn")
		await create_timer(0.8, true, false, true).timeout
		_expect(routes.size() == before + 1 and routes.back()
			== "res://scenes/menus/main_menu.tscn",
			"Timeout and all Skip/Cancel paths must route to the title exactly once.")
		if current_scene != null:
			var menu := current_scene
			current_scene = null
			menu.free()
		await process_frame
	router.disconnect("scene_changed", on_route)
	_expect(_store.call("export_save", Options.GAME_ID) == before_store
		and _achievements.call("export_save", Options.GAME_ID) == before_unlocks,
		"The opening's demonstration hits must never pay tokens or unlock achievements.")


func _test_release_contract() -> void:
	_expect(OS.has_feature(Options.GAME_ID), "A release must carry its standalone feature tag.")
	_expect(GameCatalog.all().size() == 1, "A standalone release must ship only Tuki Tuki.")
	_expect(ProjectSettings.get_setting_with_override("application/config/name") == "Tuki Tuki",
		"The exported project identity must use the Tuki Tuki feature override.")
	_expect(OS.get_user_data_dir().get_file() == "Tuki Tuki",
		"A standalone release must isolate its player saves.")
	_expect(DirAccess.get_directories_at("res://games") == PackedStringArray(["tuki-tuki_agents"]),
		"Other games must not be hidden inside the standalone pack.")
	_expect(not ResourceLoader.exists(Options.ROOT + "tests/gameplay_test.gd")
		and not ResourceLoader.exists(Options.ROOT + "tools/tutorial_driver.gd"),
		"Tests and recording tools must not ship with the game.")
	var manifest := GameCatalog.current()
	for path: String in [
		manifest.tutorial_video_path, manifest.tutorial_poster_path,
		manifest.local_tutorial_video_path, manifest.local_tutorial_poster_path,
	]:
		_expect(load(path) != null, "Standalone walkthrough media must remain loadable: %s" % path)


func _test_solo() -> void:
	var game := await _new_game()
	if game == null:
		return
	var briefing: Control = game.get("_briefing")
	_expect(briefing.visible and not bool(game.get("_round_active")),
		"The set list must open without burning musical time behind the story.")
	briefing.call("_change_section", 0)
	var pages: Array = briefing.get("_pages")
	for index in range(1, pages.size()):
		briefing.call("_turn_page", 1)
	_expect(str((briefing.get("_page_title") as Label).text).contains("The Streets Call"),
		"Next must reach the final original story chapter.")
	briefing.call("_turn_page", -1)
	_expect(int(briefing.get("_page")) == pages.size() - 2, "Previous must navigate the story.")
	briefing.call("_change_section", 2)
	_expect(str((briefing.get("_page_title") as Label).text).contains("María"),
		"Champion biographies must remain readable.")
	(briefing.get("_start") as Button).pressed.emit()
	await process_frame
	await process_frame
	_expect(bool(game.get("_round_active")) and not briefing.visible,
		"Dance must start the native song and hide the briefing.")
	_expect((game.get_node("%RoundTimer") as Timer).is_stopped(),
		"Songs must not be cut short by the shell's arcade timer.")
	_set_option(Options.SCROLL_KEY, 2.0)
	_expect(float(game.get("_scroll_speed")) == 1.0, "Scroll changes apply only next song.")
	_set_option(Options.SCROLL_KEY, 1.0)
	var audio: Node = game.get("_audio")
	var event := InputEventAction.new()
	event.action = Options.SETTINGS_ACTION
	event.pressed = true
	game.call("_unhandled_input", event)
	await process_frame
	var menu: Node = game.get("_pause_menu")
	_expect(paused and menu.get("_settings_overlay") != null,
		"F1 must open the shared Settings overlay through pause.")
	var held := float(audio.call("song_time_ms"))
	await create_timer(0.08, true, false, true).timeout
	_expect(float(audio.call("song_time_ms")) == held, "Settings must not consume song time.")
	var settings_overlay: Node = menu.get("_settings_overlay")
	_expect(str(settings_overlay.get("game_context_id")) == Options.GAME_ID,
		"Settings must expose this game's options and controls.")
	settings_overlay.call("go_back")
	await process_frame
	menu.call("resume")
	await process_frame
	var binding := "controls/tuki_tuki_p1_left"
	var original := int(_settings.call("binding_keycode", binding))
	_expect(bool(_settings.call("set_binding_key", binding, KEY_J, Options.GAME_ID)),
		"Native lane bindings must be rebindable.")
	(audio.get("player") as AudioStreamPlayer).seek(Sound.LEAD_IN)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_J
	press.keycode = KEY_J
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var state: RefCounted = game.get("_state")
	_expect(int(state.call("stats", 0)["hits"]) == 1, "The rebound key must judge the lane.")
	press.echo = true
	Input.parse_input_event(press)
	await process_frame
	_expect(int(state.call("stats", 0)["attempts"]) == 1, "Key repeat must not judge twice.")
	press.echo = false
	press.pressed = false
	Input.parse_input_event(press)
	_settings.call("set_binding_key", binding, original, Options.GAME_ID)
	var player := audio.get("player") as AudioStreamPlayer
	player.seek(player.stream.get_length() - 0.02)
	await create_timer(0.06).timeout
	_expect(bool(game.get("_completed")) and (game.get_node("%RoundOver") as Control).visible,
		"The actual song clock must settle the song and shared results.")
	_expect(int(game.call("_player_stats", 1)["score"]) == 0,
		"The shell's hidden second-seat report must remain valid in a solo song.")
	game.call("_on_play_again_pressed")
	await process_frame
	_expect(bool(game.get("_round_active")) and int(game.get("_scores")[0]) == 0,
		"Replay must rearm the chart and clear scores.")
	_expect(float(audio.call("song_time_ms")) < -2800.0, "Replay must restart the audio timeline.")
	_set_option(Options.OFFSET_KEY, -200.0)
	game.call("_on_play_again_pressed")
	# Hold exact boundary samples rather than adding an unpredictable mix interval.
	audio.call("set_paused", true)
	audio.set("_last_position", Sound.LEAD_IN + 59.94)
	game.call("_update_round", 0.0, 0.0)
	_expect(bool(game.get("_round_active")),
		"Negative calibration must not stop music before its declared length.")
	audio.set("_last_position", Sound.LEAD_IN + 60.1)
	game.call("_update_round", 0.0, 0.0)
	_expect(not bool(game.get("_round_active")),
		"Completion must settle after both the audio and shifted note windows finish.")
	_set_option(Options.OFFSET_KEY, 0.0)
	game.free()
	await process_frame


func _test_multiplayer() -> void:
	_session.call("configure_multiplayer", 0, 1)
	_session.call("set_level", "tutorial_basic")
	_session.call("set_character_for_player", 1, "carlos_maracaibo")
	var game := await _new_game()
	if game == null:
		return
	game.call("_on_dance_requested", 0, 1)
	await process_frame
	var audio: Node = game.get("_audio")
	var player := audio.get("player") as AudioStreamPlayer
	player.seek(Sound.LEAD_IN)
	for seat in 2:
		var event := InputEventAction.new()
		event.action = Options.ACTIONS[seat][0]
		event.pressed = true
		game.call("_handle_gameplay_input", event)
	var state: RefCounted = game.get("_state")
	_expect(state.call("stats", 0)["hits"] == 1 and state.call("stats", 1)["hits"] == 1,
		"Both humans must be able to hit the same chart note independently.")
	player.seek(Sound.LEAD_IN + 1.2)
	var buttons: Array = game.get("_pad_buttons")
	for seat in 2:
		var touch := InputEventScreenTouch.new()
		touch.index = seat + 7
		touch.position = (buttons[seat * 4 + 1] as Button).get_global_rect().get_center()
		touch.pressed = true
		game.call("_input", touch)
	_expect(state.call("stats", 0)["hits"] == 2 and state.call("stats", 1)["hits"] == 2,
		"Independent touch contacts must judge both dancers without stealing a pad.")
	_expect((game.get("_touches") as Dictionary).size() == 2,
		"Simultaneous touch contacts must remain independent.")
	game.call("open_pause_menu")
	_expect((game.get("_touches") as Dictionary).is_empty(), "Pausing must clear held contacts.")
	(game.get("_pause_menu") as Node).call("resume")
	await process_frame
	_set_option(Options.BACKGROUND_KEY, false)
	var stage: Node = game.get("_stage")
	_expect(not bool(stage.get("background_effects")), "Background effects must apply live.")
	game.call("_set_reduced_motion_enabled", true)
	_expect(bool(stage.get("reduced_motion")), "Reduced motion must reach the actual 3D stage.")
	game.call("_set_intense_effects_enabled", false)
	_expect(not bool(stage.get("intense_effects")), "Intense-effects preference must reach 3D.")
	var before := int(_store.call("points", Options.GAME_ID))
	audio.call("set_paused", true)
	audio.set("_last_position", Sound.LEAD_IN + 60.11)
	game.call("_update_round", 0.0, 0.0)
	_expect(bool(_achievements.call("is_unlocked", Options.LOCAL_BATTLE))
		and int(_store.call("points", Options.GAME_ID)) > before,
		"A completed two-human chart must award its shared payout and local achievement.")
	game.free()
	await process_frame


func _new_game() -> Node:
	var packed := load(Options.ROOT + "gameplay.tscn") as PackedScene
	if packed == null:
		_expect(false, "The native gameplay scene must load.")
		return null
	var game := packed.instantiate()
	get_root().add_child(game)
	await process_frame
	await process_frame
	return game


func _set_option(key: String, value: Variant) -> void:
	_settings.call("set_value", key, value)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
