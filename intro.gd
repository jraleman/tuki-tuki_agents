extends MenuScreen

## A finite, unscored demonstration uses the real arrows, champions and audio clock.

const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")
const State = preload("res://games/tuki-tuki_agents/rhythm/rhythm_state.gd")
const Stage = preload("res://games/tuki-tuki_agents/world/rhythm_stage.gd")
const Sound = preload("res://games/tuki-tuki_agents/audio/rhythm_audio.gd")
const DEMO_SONG := {
	"id": "tuki_tuki_intro", "bpm": 100, "duration": 9.6, "seed": 100,
}
const CARDS := [
	"Synthesized count-in. Three beats to get ready.",
	"Left / down / up / right. Match each arrow at the front targets.",
	"P1 and P2 follow the same beat on independent lanes.",
	"Four fictional champions. Five original synthesized songs. Find your rhythm.",
]
const CUE_TIMES := [-3.0, 0.0, 2.4, 6.0]

@export_file("*.tscn") var next_scene := "res://scenes/menus/main_menu.tscn"
var _state := State.new()
var _still_state := State.new()
var _stage: Stage
var _audio: Sound
var _stage_container: SubViewportContainer
var _frame: MarginContainer
var _column: VBoxContainer
var _title: Label
var _card: Label
var _identity: Label
var _progress: ProgressBar
var _skip: Button
var _next_note := 0
var _card_index := -1
var _finished := false


func _ready() -> void:
	AudioManager.stop_music(0.0)
	_build_ui()
	var chart: Array[Dictionary] = []
	for index in 12:
		chart.append({"time": index * 600.0, "lane": index % 4})
	_state.configure(chart, DEMO_SONG["duration"], 2)
	_still_state.configure(chart, DEMO_SONG["duration"], 2)
	_stage.configure([Data.CHARACTERS[0], Data.CHARACTERS[1]], DEMO_SONG["bpm"])
	var outfits: Array[Dictionary] = []
	var shoes: Array[Dictionary] = []
	for player in 2:
		outfits.append(Store.equipped_item(Options.GAME_ID, Options.OUTFIT_SLOTS[player]))
		shoes.append(Store.equipped_item(Options.GAME_ID, Options.SHOE_SLOTS[player]))
	_stage.set_cosmetics(outfits, shoes)
	_audio = Sound.new()
	add_child(_audio)
	Settings.changed.connect(_on_setting_changed)
	_apply_preferences()
	_audio.start(DEMO_SONG)
	first_focus = _skip
	margins = _frame
	super()
	_present_demo(-Sound.LEAD_IN * 1000.0)


func _exit_tree() -> void:
	if _audio != null:
		_audio.stop()


func _process(_delta: float) -> void:
	if not _finished:
		_present_demo(_audio.song_time_ms())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("skip") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()


func _present_demo(time_ms: float) -> void:
	var seconds := time_ms * 0.001
	_progress.value = seconds + Sound.LEAD_IN
	var index := 0
	for cue in CUE_TIMES.size():
		if seconds >= float(CUE_TIMES[cue]):
			index = cue
	if index != _card_index:
		_card_index = index
		_card.text = CARDS[index]
		AudioManager.request_caption(CARDS[index])
	while _next_note < _state.notes.size() \
			and float(_state.notes[_next_note]["time"]) <= time_ms:
		var note := _state.notes[_next_note]
		for player in 2:
			_state.hit(player, int(note["lane"]), float(note["time"]))
			_stage.feedback(player, int(note["lane"]), "PERFECT")
		_next_note += 1
	_state.advance(time_ms)
	if Settings.reduced_motion_enabled():
		_stage.present(_still_state, -1400.0, 1.0)
	else:
		_stage.present(_state, time_ms, 1.0)
	if seconds >= float(DEMO_SONG["duration"]) or _audio.finished:
		_finish()


func _on_setting_changed(key: String, _value: Variant) -> void:
	if key.begins_with("accessibility/") or key == Options.BACKGROUND_KEY:
		_apply_preferences()


func _apply_preferences() -> void:
	_stage.reduced_motion = Settings.reduced_motion_enabled()
	_stage.intense_effects = Settings.visual_effects_enabled()
	_stage.background_effects = Settings.tunable_bool(Options.BACKGROUND_KEY)
	if _stage.reduced_motion or not _stage.intense_effects or not _stage.background_effects:
		_stage.clear_effects()


func _on_skip_pressed() -> void:
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	_audio.stop()
	_stage.stop()
	# Keyboard Skip can arrive before the studio-to-intro fade has finished.
	if Router.is_transitioning():
		await Router.transition_finished
	Router.goto(next_scene)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("101326")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame = MarginContainer.new()
	add_child(_frame)
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column = VBoxContainer.new()
	_frame.add_child(_column)
	_title = Label.new()
	_title.text = "TUKI TUKI"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color("f6ce46"))
	_column.add_child(_title)
	_identity = Label.new()
	_identity.text = "P1 / María     P2 / Carlos     DEMONSTRATION"
	_identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(_identity)
	_stage_container = SubViewportContainer.new()
	_stage_container.stretch = true
	_stage_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_stage_container)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.msaa_3d = Viewport.MSAA_2X
	_stage_container.add_child(viewport)
	_stage = Stage.new()
	viewport.add_child(_stage)
	_card = Label.new()
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(_card)
	_progress = ProgressBar.new()
	_progress.max_value = Sound.LEAD_IN + float(DEMO_SONG["duration"])
	_progress.show_percentage = false
	_column.add_child(_progress)
	_skip = Button.new()
	_skip.text = "Skip intro"
	_skip.pressed.connect(_on_skip_pressed)
	_column.add_child(_skip)


func _on_layout_changed(logical: Vector2) -> void:
	if _frame == null:
		return
	var unit := maxf(1.0, logical.y / maxf(1.0, float(get_window().size.y)))
	unit *= float(Settings.get_value("ui/scale"))
	_title.add_theme_font_size_override("font_size", roundi(36.0 * unit))
	_identity.add_theme_font_size_override("font_size", roundi(16.0 * unit))
	_card.add_theme_font_size_override("font_size", roundi(20.0 * unit))
	_skip.add_theme_font_size_override("font_size", roundi(18.0 * unit))
	_skip.custom_minimum_size.y = 44.0 * unit
	_stage_container.custom_minimum_size.y = 120.0 * unit
	_progress.custom_minimum_size.y = 8.0 * unit
	_column.add_theme_constant_override("separation", roundi(10.0 * unit))
