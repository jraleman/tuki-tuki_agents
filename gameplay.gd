extends GameShell

## Song-ended DDR gameplay inside the shared menus, pause, HUD, results and sharing.

const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")
const Chart = preload("res://games/tuki-tuki_agents/rhythm/chart.gd")
const State = preload("res://games/tuki-tuki_agents/rhythm/rhythm_state.gd")
const Sound = preload("res://games/tuki-tuki_agents/audio/rhythm_audio.gd")
const Stage = preload("res://games/tuki-tuki_agents/world/rhythm_stage.gd")
const Briefing = preload("res://games/tuki-tuki_agents/ui/song_briefing.gd")

var _state := State.new()
var _song: Dictionary = {}
var _difficulty := 1
var _mode := 0
var _scroll_speed := 1.0
var _offset_ms := 0.0
var _sfx_enabled := true
var _background_enabled := true
var _song_time_ms := -Sound.LEAD_IN * 1000.0
var _completed := false
var _reward_claimed := false
var _audio: Sound
var _stage: Stage
var _briefing: Briefing
var _stage_container: SubViewportContainer
var _stage_viewport: SubViewport
var _pads_root: HBoxContainer
var _pad_buttons: Array[Button] = []
var _accuracy_labels: Array[Label] = []
var _feedback_labels: Array[Label] = []
var _feedback_time := [0.0, 0.0]
var _touches: Dictionary = {}
var _last_count := -1
var _ui_pixels := 0.0
var _capture_inset := 0.0


func _ready() -> void:
	AudioManager.stop_music(0.0)
	super()


func _exit_tree() -> void:
	if _audio != null:
		_audio.stop()


## Stable save and catalog identity is independent of the historical folder name.
func game_id() -> String:
	return Options.GAME_ID


func _load_round_settings() -> void:
	super()
	var level := GameSession.selected_level()
	_song = Data.song(str(level["id"]))
	var preferred := Settings.tunable_choice(Options.DIFFICULTY_KEY)
	_difficulty = preferred if _song["difficulties"].has(preferred) \
		else int(_song["difficulties"][0])
	_mode = Settings.tunable_choice(Options.MODE_KEY)
	_scroll_speed = Settings.tunable(Options.SCROLL_KEY)
	_offset_ms = Settings.tunable(Options.OFFSET_KEY)
	_sfx_enabled = Settings.tunable_bool(Options.SFX_KEY)
	_background_enabled = Settings.tunable_bool(Options.BACKGROUND_KEY)


func _build_playfield() -> void:
	_stage_container = SubViewportContainer.new()
	_stage_container.name = "RhythmStage"
	_stage_container.stretch = true
	_stage_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_playfield.add_child(_stage_container)
	_stage_viewport = SubViewport.new()
	_stage_viewport.own_world_3d = true
	_stage_viewport.gui_disable_input = true
	_stage_viewport.msaa_3d = Viewport.MSAA_2X
	_stage_container.add_child(_stage_viewport)
	_stage = Stage.new()
	_stage_viewport.add_child(_stage)
	Store.equipped_changed.connect(_on_cosmetic_changed)
	_audio = Sound.new()
	add_child(_audio)
	_briefing = Briefing.new()
	_briefing.name = "SongBriefing"
	_hud.add_child(_briefing)
	_briefing.start_requested.connect(_on_dance_requested)
	_briefing.setup_requested.connect(_return_to_setup)
	_briefing.settings_requested.connect(_open_settings)
	_build_pads()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_callout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(_layout_stage)
	(_player_one_card.get_parent() as Control).resized.connect(_layout_stage)
	_hint.item_rect_changed.connect(_layout_stage)
	(_hint.get_parent().get_parent() as Control).item_rect_changed.connect(_layout_stage)
	_layout_stage()
	AudioManager.attach_ui_sounds(_briefing)


func _begin_first_round() -> void:
	_round_active = false
	_pads_root.hide()
	_briefing.configure(_song, Settings.tunable_choice(Options.DIFFICULTY_KEY),
		_mode, not GameSession.is_single_player())


func _reset_round_state() -> void:
	_briefing.hide()
	_touches.clear()
	_completed = false
	_reward_claimed = false
	_last_count = -1
	_song_time_ms = -Sound.LEAD_IN * 1000.0 - _offset_ms
	_state.configure(Chart.generate(_song, _difficulty), float(_song["duration"]),
		GameSession.player_count())
	var characters: Array[Dictionary] = []
	for player in _active_player_indices():
		characters.append(GameSession.character_for_player(player))
	_stage.configure(characters, float(_song["bpm"]))
	_apply_cosmetics()
	_apply_stage_preferences()
	_pads_root.show()
	for player in 2:
		_feedback_time[player] = 0.0
		_feedback_labels[player].text = ""
		(_accuracy_labels[player].get_parent() as Control).visible = player < characters.size()
	_audio.start(_song)
	_refresh_player_readouts()
	_layout_stage()


func _activate_round() -> void:
	_announcement.hide()
	_time_caption.text = "SONG"
	_time_progress.max_value = float(_song["duration"])
	AudioManager.request_caption("Three-beat count-in. Follow the front arrow targets.")


func _update_round(delta: float, _time_left: float) -> void:
	var audible_ms := _audio.song_time_ms()
	_song_time_ms = audible_ms - _offset_ms
	_apply_judgements(_state.advance(_song_time_ms), false)
	_stage.present(_state, _song_time_ms, _scroll_speed)
	var elapsed := maxf(0.0, _song_time_ms * 0.001)
	var remaining := maxf(0.0, float(_song["duration"]) - elapsed)
	_time_label.text = "%d:%02d" % [int(remaining) / 60, int(remaining) % 60]
	_time_progress.value = elapsed
	if _song_time_ms < 0.0:
		var count := ceili(-_song_time_ms / 1000.0)
		if count != _last_count:
			_callout.text = "READY / %d" % count
			_last_count = count
	else:
		_callout.text = "%s / %s / %d BPM" % [
			_song["title"], Data.DIFFICULTIES[_difficulty], _song["bpm"],
		]
	for player in _active_player_indices():
		_feedback_time[player] = maxf(0.0, float(_feedback_time[player]) - delta)
		if _feedback_time[player] <= 0.0:
			_feedback_labels[player].text = ""
	if _audio.finished or (
		audible_ms >= _state.duration_ms
		and _song_time_ms > _state.duration_ms + State.GOOD_MS
	):
		_apply_judgements(_state.advance(_state.duration_ms + State.GOOD_MS + 1.0), false)
		_completed = true
		_end_round()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed(Options.SETTINGS_ACTION):
		get_viewport().set_input_as_handled()
		_open_settings()
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		open_pause_menu()
		return
	super(event)


func _input(event: InputEvent) -> void:
	if not _round_active or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if not event.pressed:
			_touches.erase(event.index)
			return
		for index in _pad_buttons.size():
			var button := _pad_buttons[index]
			if button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
				_touches[event.index] = index
				_hit_lane(index / 4, index % 4)
				get_viewport().set_input_as_handled()
				return


func _handle_gameplay_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for player in _active_player_indices():
		for lane in 4:
			if event.is_action_pressed(Options.ACTIONS[player][lane]):
				get_viewport().set_input_as_handled()
				_hit_lane(player, lane)
				return


func _hit_lane(player: int, lane: int) -> void:
	if not _round_active or get_tree().paused:
		return
	var time_ms := _audio.song_time_ms() - _offset_ms
	if time_ms < -State.GOOD_MS:
		return
	_apply_judgements(_state.advance(time_ms), false)
	_apply_judgements([_state.hit(player, lane, time_ms)], true)
	_stage.present(_state, time_ms, _scroll_speed)


func _apply_judgements(events: Array[Dictionary], play_sound: bool) -> void:
	for event in events:
		var player := int(event["player"])
		var lane := int(event["lane"])
		var result := str(event["result"])
		var stats := _state.stats(player)
		_scores[player] = int(stats["score"])
		_streaks[player] = int(stats["combo"])
		_best_streaks[player] = int(stats["streak"])
		_feedback_labels[player].text = "%s +%d / x%d" % [
			result, event["points"], stats["combo"],
		]
		_feedback_labels[player].add_theme_color_override("font_color",
			Color("f6ce46") if result == "PERFECT" else _player_color(player))
		_feedback_time[player] = 0.7
		_stage.feedback(player, lane, result)
		if play_sound and _sfx_enabled:
			AudioManager.play_sfx(_audio.cue(result), -10.0)
		if play_sound:
			AudioManager.request_caption("%s: %s" % [_player_name(player), result])
	if not events.is_empty():
		_update_scores()
		_update_streaks()
		_refresh_player_readouts()


func _finish_round() -> void:
	_audio.stop()
	_stage.stop()
	_touches.clear()
	_pads_root.hide()
	_round_elapsed = maxf(0.0, minf(_song_time_ms * 0.001, float(_song["duration"])))


func _configure_mode_ui() -> void:
	super()
	_time_caption.text = "SONG"
	_hint.text = "Match the four front targets. Esc / Space pauses. F1 opens Settings."
	_callout.text = str(_song.get("title", "Tuki Tuki"))
	if _pad_buttons.is_empty():
		return
	for player in 2:
		for lane in 4:
			var action: StringName = Options.ACTIONS[player][lane]
			_pad_buttons[player * 4 + lane].text = "%s\n%s" % [
				Options.SYMBOLS[lane], Settings.control_key_label(action),
			]


func _round_totals() -> Dictionary:
	return _state.totals()


func _populate_score_screen(result_text: String, result_color: Color) -> void:
	super(result_text, result_color)
	_game_accuracy_stat.text = "%d%%" % roundi(float(_state.totals()["accuracy"]))


func _share_payload() -> Dictionary:
	var payload := super()
	var accuracy := roundi(float(_state.totals()["accuracy"]))
	payload["accuracy_value"] = accuracy
	payload["accuracy"] = "%d%%" % accuracy
	return payload


func _player_stats(player_index: int) -> Dictionary:
	# The shell also populates the hidden second-seat card in solo rounds.
	if player_index >= _state.players.size():
		return super(player_index)
	var stats := _state.stats(player_index)
	stats["score"] = _scores[player_index]
	stats["details"] = [
		{"label": "Perfect", "value": str(stats["perfect"])},
		{"label": "Great", "value": str(stats["great"])},
		{"label": "Good", "value": str(stats["good"])},
	]
	return stats


func _describe_round_outcome(player_one_total: int, player_two_total: int) -> Dictionary:
	var outcome := super(player_one_total, player_two_total)
	if GameSession.is_single_player():
		outcome["result"] = "SONG COMPLETE" if _completed else "SONG ENDED"
	outcome["subtitle"] = "%s / %s / %d BPM" % [
		_song["title"], Data.DIFFICULTIES[_difficulty], _song["bpm"],
	]
	return outcome


func _round_highlight_summary() -> String:
	return "Best combo x%d / %s / %s" % [
		_best_streaks.max(), "Local Battle" if not GameSession.is_single_player()
		else ("Story" if _mode == 0 else "Practice"), _song["genre"],
	]


## Only a completed song earns currency, once, through the shared wallet.
func _round_points_earned(player_one_total: int, player_two_total: int) -> int:
	if not _completed or _reward_claimed:
		return -1
	_reward_claimed = true
	return super(player_one_total, player_two_total)


func _award_round_achievements(_player_one_total: int, _player_two_total: int) -> void:
	if not _completed:
		return
	_unlock_round_achievement(Options.FIRST_SONG)
	for player in _state.players.size():
		var stats := _state.stats(player)
		if int(stats["streak"]) >= 25:
			_unlock_round_achievement(Options.FLOW_COMBO)
		if float(stats["accuracy"]) >= 90.0:
			_unlock_round_achievement(Options.PRECISION)
	if not GameSession.is_single_player() and _state.players.size() == 2 \
			and int(_state.stats(0)["hits"]) > 0 and int(_state.stats(1)["hits"]) > 0:
		_unlock_round_achievement(Options.LOCAL_BATTLE)


func _on_cosmetic_changed(id: String, _slot: String, _item: String) -> void:
	if id == game_id():
		_apply_cosmetics()


func _apply_cosmetics() -> void:
	if _stage == null:
		return
	var outfits: Array[Dictionary] = []
	var shoes: Array[Dictionary] = []
	for player in _active_player_indices():
		outfits.append(Store.equipped_item(game_id(), Options.OUTFIT_SLOTS[player]))
		shoes.append(Store.equipped_item(game_id(), Options.SHOE_SLOTS[player]))
	_stage.set_cosmetics(outfits, shoes)


## Hold playback explicitly as the framework pauses the rest of the scene tree.
func open_pause_menu() -> void:
	if _audio != null:
		_audio.set_paused(true)
	_touches.clear()
	super()


func _on_pause_closed() -> void:
	super()
	_audio.set_paused(false)
	if _briefing.visible:
		_load_round_settings()
		_briefing.configure(_song, Settings.tunable_choice(Options.DIFFICULTY_KEY),
			_mode, not GameSession.is_single_player())


func _set_reduced_motion_enabled(value: bool) -> void:
	super(value)
	_apply_stage_preferences()


func _set_intense_effects_enabled(value: bool) -> void:
	super(value)
	_apply_stage_preferences()


func _on_game_setting_changed(key: String, _value: Variant) -> void:
	if key == Options.SFX_KEY:
		_sfx_enabled = Settings.tunable_bool(key)
	if key == Options.BACKGROUND_KEY:
		_background_enabled = Settings.tunable_bool(key)
		_apply_stage_preferences()


func _apply_stage_preferences() -> void:
	if _stage == null:
		return
	_stage.reduced_motion = _reduced_motion_enabled
	_stage.intense_effects = _intense_effects_enabled
	_stage.background_effects = _background_enabled
	if _reduced_motion_enabled or not _intense_effects_enabled or not _background_enabled:
		_stage.clear_effects()


func _on_dance_requested(difficulty: int, mode: int) -> void:
	Settings.set_value(Options.DIFFICULTY_KEY, difficulty)
	Settings.set_value(Options.MODE_KEY, mode)
	_start_round_after_transition()


func _open_settings() -> void:
	open_pause_menu()
	if is_instance_valid(_pause_menu):
		_pause_menu.call("_on_settings_pressed")


func _return_to_setup() -> void:
	_audio.stop()
	Router.goto("res://scenes/menus/mode_select.tscn")


func _build_pads() -> void:
	_pads_root = HBoxContainer.new()
	_pads_root.name = "RhythmPads"
	_pads_root.add_theme_constant_override("separation", 40)
	_hud.get_node("Overlay").add_child(_pads_root)
	for player in 2:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_pads_root.add_child(column)
		var accuracy := Label.new()
		accuracy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		accuracy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		accuracy.add_theme_font_size_override("font_size", 20)
		column.add_child(accuracy)
		_accuracy_labels.append(accuracy)
		var feedback := Label.new()
		feedback.custom_minimum_size.y = 32
		feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		feedback.add_theme_font_size_override("font_size", 23)
		column.add_child(feedback)
		_feedback_labels.append(feedback)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		column.add_child(row)
		for lane in 4:
			var button := Button.new()
			button.custom_minimum_size = Vector2(60, 76)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.focus_mode = Control.FOCUS_NONE
			button.add_theme_font_size_override("font_size", 22)
			button.button_down.connect(_on_pad_pressed.bind(player, lane))
			row.add_child(button)
			_pad_buttons.append(button)
	_configure_mode_ui()


func _on_pad_pressed(player: int, lane: int) -> void:
	# Real touch contacts are judged in _input; ignore their emulated mouse press.
	if _touches.is_empty():
		_hit_lane(player, lane)


func _refresh_player_readouts() -> void:
	for player in _state.players.size():
		var stats := _state.stats(player)
		_accuracy_labels[player].text = "P%d / %s / %.1f%%" % [
			player + 1, GameSession.character_for_player(player)["title"], stats["accuracy"],
		]


func _set_capture_inset(bottom: float) -> void:
	_capture_inset = maxf(0.0, bottom)
	_layout_stage()


func _layout_stage() -> void:
	var available := get_viewport_rect().size
	var pixels := available.x / maxf(1.0, get_window().size.x)
	if not is_equal_approx(pixels, _ui_pixels):
		_ui_pixels = pixels
		for label: Label in [
			_player_one_caption, _player_two_caption, _time_caption, _mode_title,
		]:
			label.add_theme_font_size_override("font_size", roundi(14 * pixels))
		for label: Label in [_player_one_score, _player_two_score, _time_label]:
			label.add_theme_font_size_override("font_size", roundi(32 * pixels))
		for label: Label in [_player_one_streak, _player_two_streak, _hint]:
			label.add_theme_font_size_override("font_size", roundi(15 * pixels))
		_callout.add_theme_font_size_override("font_size", roundi(18 * pixels))
		for label in _accuracy_labels:
			label.add_theme_font_size_override("font_size", roundi(15 * pixels))
		for label in _feedback_labels:
			label.add_theme_font_size_override("font_size", roundi(19 * pixels))
			label.custom_minimum_size.y = 28 * pixels
		for button in _pad_buttons:
			button.add_theme_font_size_override("font_size", roundi(18 * pixels))
			button.custom_minimum_size.y = 58 * pixels
	var bounds := _playfield_bounds()
	var top_bar := _player_one_card.get_parent() as Control
	var top := maxf(bounds.position.y, top_bar.get_global_rect().end.y + 12 * pixels)
	var bottom := minf(bounds.end.y, _hint.get_global_rect().position.y - 8 * pixels)
	bottom = minf(bottom, available.y - _capture_inset)
	bounds = Rect2(Vector2(bounds.position.x, top),
		Vector2(bounds.size.x, maxf(1, bottom - top)))
	var pads_height := 120 * pixels
	_stage_container.position = bounds.position
	_stage_container.size = Vector2(bounds.size.x, maxf(1.0, bounds.size.y - pads_height))
	_pads_root.position = Vector2(bounds.position.x, bounds.end.y - pads_height)
	_pads_root.size = Vector2(bounds.size.x, pads_height)
