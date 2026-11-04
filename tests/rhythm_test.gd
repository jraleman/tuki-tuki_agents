extends SceneTree

## Exact timing boundaries, scoring, deterministic charts and complete two-seat songs.

const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")
const Chart = preload("res://games/tuki-tuki_agents/rhythm/chart.gd")
const State = preload("res://games/tuki-tuki_agents/rhythm/rhythm_state.gd")
var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for case: Array in [
		[0.0, "PERFECT"], [22.0, "PERFECT"], [22.001, "GREAT"],
		[64.0, "GREAT"], [64.001, "GOOD"], [106.0, "GOOD"], [106.001, "MISS"],
	]:
		for sign_value in [-1.0, 1.0]:
			_expect(State.evaluate(float(case[0]) * sign_value) == str(case[1]),
				"Timing window failed at %s ms." % (float(case[0]) * sign_value))
	_test_chords_and_misses()
	_test_combo_and_accuracy()
	for song in Data.SONGS:
		var previous_count := 0
		for difficulty: int in song["difficulties"]:
			var chart := Chart.generate(song, difficulty)
			_expect(chart == Chart.generate(song, difficulty), "Replays must retain the chart.")
			_expect(chart.size() >= previous_count, "Higher difficulties must not lose density.")
			previous_count = chart.size()
			var previous := -1.0
			var keys := {}
			for note in chart:
				var time := float(note["time"])
				var key := "%s:%s" % [time, note["lane"]]
				_expect(time >= previous and time < float(song["duration"]) * 1000.0,
					"Chart notes must be ordered and inside their song.")
				_expect(not keys.has(key), "A chart must not duplicate a lane at the same time.")
				keys[key] = true
				previous = time
			_play_complete_song(song, chart)
	_finish()


func _test_chords_and_misses() -> void:
	var state := State.new()
	state.configure([
		{"time": 1000.0, "lane": 0}, {"time": 1000.0, "lane": 2},
		{"time": 1500.0, "lane": 1},
	], 2.0, 2)
	_expect(state.hit(0, 0, 1000.0)["result"] == "PERFECT", "An aligned press must hit.")
	_expect(state.stats(1)["hits"] == 0, "P1 must not consume P2's note.")
	_expect(state.hit(0, 1, 1000.0)["result"] == "MISS", "Wrong lane must miss.")
	_expect(state.visible_notes(0, 1000.0, 500.0).size() == 2,
		"A wrong press must preserve the other chord and future note.")
	_expect(state.advance(1106.0).is_empty(), "A note is still hittable at the Good boundary.")
	var missed := state.advance(1106.01)
	_expect(missed.size() == 3, "All overdue notes must expire independently for each player.")
	_expect(state.advance(1107.0).is_empty(), "Expired notes must not be missed twice.")
	_expect(state.hit(0, 1, 1394.0)["result"] == "GOOD", "Early boundary must remain hittable.")
	_expect(state.hit(1, 1, 1606.0)["result"] == "GOOD", "Late boundary must remain hittable.")
	_expect(state.stats(0)["streak"] == 1, "A miss must reset the live combo, not the best.")


func _test_combo_and_accuracy() -> void:
	var state := State.new()
	var notes: Array[Dictionary] = []
	for index in 25:
		notes.append({"time": 1000.0 + index * 250.0, "lane": index % 4})
	state.configure(notes, 8.0, 1)
	for index in notes.size():
		var note := notes[index]
		var event := state.hit(0, int(note["lane"]), float(note["time"]))
		if index == 0:
			_expect(event["points"] == 110, "The first hit must include its new combo.")
		if index >= 19:
			_expect(event["points"] == 300, "The running prototype's 3x score cap must hold.")
	_expect(state.stats(0)["accuracy"] == 100.0, "Perfect play must have full accuracy.")
	var score := int(state.stats(0)["score"])
	state.hit(0, 0, 7700.0)
	_expect(state.stats(0)["score"] == score and state.stats(0)["combo"] == 0,
		"A ghost press must break combo without inventing score.")
	_expect(is_equal_approx(float(state.stats(0)["accuracy"]), 2500.0 / 26.0),
		"Ghost presses must count against weighted accuracy.")
	var weighted := State.new()
	weighted.configure([
		{"time": 1000.0, "lane": 0}, {"time": 1500.0, "lane": 0},
	], 2.0, 1)
	weighted.hit(0, 0, 1040.0)
	weighted.hit(0, 0, 1600.0)
	_expect(weighted.stats(0)["accuracy"] == 65.0,
		"Great and Good must retain their 80/50 accuracy weights.")
	_expect(weighted.totals()["accuracy"] == 65.0,
		"Combined reports must not replace weighted accuracy with hit rate.")


func _play_complete_song(song: Dictionary, chart: Array[Dictionary]) -> void:
	var state := State.new()
	state.configure(chart, float(song["duration"]), 2)
	for note in chart:
		var time := float(note["time"])
		_expect(state.advance(time).is_empty(), "Aligned autoplay must never drop a note.")
		for player in 2:
			_expect(state.hit(player, int(note["lane"]), time)["result"] == "PERFECT",
				"Every chart must be playable through to the last note.")
	state.advance(state.duration_ms + State.GOOD_MS + 1.0)
	for player in 2:
		var stats := state.stats(player)
		_expect(stats["hits"] == chart.size() and stats["misses"] == 0,
			"A complete song must resolve every note exactly once.")
	_expect(state.stats(0) == state.stats(1), "Identical local play must yield identical scores.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("Tuki Tuki rhythm tests passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)
