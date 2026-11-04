extends SceneTree

## Real briefing, rebound input, pause/settings, song ending and simultaneous seats.

const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
const Sound = preload("res://games/tuki-tuki_agents/audio/rhythm_audio.gd")
var _failures := PackedStringArray()
var _settings: Node
var _session: Node
var _old_values: Dictionary = {}
var _save_timer: Timer
var _timer_mode := Node.PROCESS_MODE_INHERIT


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_settings = get_root().get_node("Settings")
	_session = get_root().get_node("GameSession")
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
	_set_option(Options.MODE_KEY, 1)
	_set_option(Options.DIFFICULTY_KEY, 0)
	_set_option(Options.OFFSET_KEY, 0.0)
	_set_option(Options.SCROLL_KEY, 1.0)
	_set_option(Options.SFX_KEY, false)
	_session.call("configure_single_player")
	_session.call("set_level", "tutorial_basic")
	_session.call("set_character_for_player", 0, "rodriguez_barquisimeto")
	await _test_solo()
	await _test_multiplayer()
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
