extends RefCounted

## Records real audible-clock input; only one labelled lesson deliberately misses.

signal keycap_requested(text: String)

const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
var _local := false
var _next_note := 0
var _releases: Array[InputEventKey] = []


func configure(variant: String) -> bool:
	_local = variant == "local"
	_next_note = 0
	return variant in ["solo", "local"]


func duration() -> float:
	return 26.0


func steps() -> Array[Dictionary]:
	return [
		{"time": 0.0, "title": "Four front targets. One beat.",
			"body": "Arrows travel toward you. Wait for the count-in, then match the front targets."},
		{"time": 5.0, "title": "Two dancers, independent lanes" if _local else "A S W D follows the arrows",
			"body": "P1: A S W D. P2: arrow keys. Both dancers play the same chart."
				if _local else "A is left, S down, W up and D right. Tap when each arrow meets its target."},
		{"time": 10.0, "title": "Accurate taps stack your combo",
			"body": "Perfect: 22 ms. Great: 64 ms. Good: 106 ms. Consecutive hits multiply your score."},
		{"time": 14.8, "title": "Let one pass: the combo breaks",
			"body": "Watch P1 miss one note. Wrong presses also break combo and reduce accuracy."},
		{"time": 20.0, "title": "Recover and keep dancing",
			"body": "The next hit starts a new combo. The full song ends the round, not a lives pool."},
	]


func settings_overrides() -> Dictionary:
	return {
		Options.MODE_KEY: 1, Options.DIFFICULTY_KEY: 0, Options.OFFSET_KEY: 0.0,
		Options.SCROLL_KEY: 1.0, Options.SFX_KEY: false, Options.BACKGROUND_KEY: true,
		"ui/scale": 1.0,
	}


func configure_session(session: Node) -> void:
	if _local:
		session.call("configure_multiplayer", 0, 1)
	else:
		session.call("configure_single_player")
	session.call("set_level", "tutorial_basic")


func start(scene: Node) -> void:
	scene.call("_on_dance_requested", 0, 1)


func update(scene: Node, _time: float, _delta: float) -> void:
	_release_keys()
	if not bool(scene.get("_round_active")):
		return
	var state: RefCounted = scene.get("_state")
	var notes: Array = state.get("notes")
	var audio: Node = scene.get("_audio")
	var now := float(audio.call("song_time_ms"))
	while _next_note < notes.size() and float(notes[_next_note]["time"]) <= now:
		var lane := int(notes[_next_note]["lane"])
		for player in (state.get("players") as Array).size():
			if player == 0 and _next_note == 10:
				continue
			_press(Options.ACTIONS[player][lane], player)
		_next_note += 1


func validate_finished(scene: Node) -> bool:
	_release_keys()
	var state: RefCounted = scene.get("_state")
	var one: Dictionary = state.call("stats", 0)
	var valid := int(one["hits"]) >= 15 and int(one["misses"]) == 1
	if _local:
		var two: Dictionary = state.call("stats", 1)
		valid = valid and int(two["hits"]) >= 15 and int(two["misses"]) == 0
	return valid


func _press(action: StringName, player: int) -> void:
	for source in InputMap.action_get_events(action):
		if source is InputEventKey:
			var event := source.duplicate() as InputEventKey
			event.pressed = true
			event.echo = false
			Input.parse_input_event(event)
			_releases.append(event)
			keycap_requested.emit("P%d %s" % [player + 1, Settings.control_key_label(action)])
			return
	push_error("The walkthrough could not resolve the keyboard action %s." % action)


func _release_keys() -> void:
	for press in _releases:
		var release := press.duplicate() as InputEventKey
		release.pressed = false
		Input.parse_input_event(release)
	_releases.clear()
