extends RefCounted

## Node-free note judgement, misses, combos and statistics for one shared chart.

const PERFECT_MS := 22.0
const GREAT_MS := 64.0
const GOOD_MS := 106.0
const BASE_SCORE := {"PERFECT": 100, "GREAT": 80, "GOOD": 50, "MISS": 0}
var notes: Array[Dictionary] = []
var players: Array[Dictionary] = []
var duration_ms := 0.0
var _first_pending: Array[int] = []


## Each human owns a resolution buffer; neither can consume the other's notes.
func configure(chart: Array[Dictionary], duration: float, player_count: int) -> void:
	assert(player_count in [1, 2], "Tuki Tuki supports one or two local dancers.")
	notes = chart.duplicate(true)
	duration_ms = duration * 1000.0
	players.clear()
	_first_pending.clear()
	for player in player_count:
		var resolved := PackedByteArray()
		resolved.resize(notes.size())
		players.append({
			"score": 0, "combo": 0, "best_combo": 0,
			"PERFECT": 0, "GREAT": 0, "GOOD": 0, "MISS": 0,
			"weight": 0, "resolved": resolved,
		})
		_first_pending.append(0)


## Inclusive windows retain the original Perfect/Great/Good/Miss vocabulary.
static func evaluate(error_ms: float) -> String:
	var difference := absf(error_ms)
	if difference <= PERFECT_MS:
		return "PERFECT"
	if difference <= GREAT_MS:
		return "GREAT"
	if difference <= GOOD_MS:
		return "GOOD"
	return "MISS"


## Expire every overdue note exactly once, including across long rendering stalls.
func advance(time_ms: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for player in players.size():
		var resolved: PackedByteArray = players[player]["resolved"]
		var index := _first_pending[player]
		while index < notes.size() and float(notes[index]["time"]) < time_ms - GOOD_MS:
			if resolved[index] == 0:
				resolved[index] = 1
				events.append(_record(player, index, "MISS"))
			index += 1
		players[player]["resolved"] = resolved
		_first_pending[player] = index
	return events


## A wrong press breaks combo but never removes a future or wrong-lane note.
func hit(player: int, lane: int, time_ms: float) -> Dictionary:
	assert(player >= 0 and player < players.size() and lane >= 0 and lane < 4)
	var resolved: PackedByteArray = players[player]["resolved"]
	var nearest := -1
	var distance := GOOD_MS + 1.0
	for index in range(_first_pending[player], notes.size()):
		var note := notes[index]
		var difference := float(note["time"]) - time_ms
		if difference > GOOD_MS:
			break
		if resolved[index] != 0 or int(note["lane"]) != lane:
			continue
		if absf(difference) <= GOOD_MS and absf(difference) < distance:
			nearest = index
			distance = absf(difference)
	if nearest < 0:
		var event := _record(player, -1, "MISS")
		event["lane"] = lane
		return event
	resolved[nearest] = 1
	players[player]["resolved"] = resolved
	return _record(player, nearest, evaluate(distance))


## The view receives unresolved notes only, rather than owning any judgement state.
func visible_notes(player: int, time_ms: float, lookahead_ms: float) -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	var resolved: PackedByteArray = players[player]["resolved"]
	for index in range(_first_pending[player], notes.size()):
		var note := notes[index]
		if float(note["time"]) > time_ms + lookahead_ms:
			break
		if resolved[index] == 0:
			visible.append(note)
	return visible


## Weighted accuracy includes wrong presses, so spamming cannot improve it.
func stats(player: int) -> Dictionary:
	var state := players[player]
	var hits := int(state["PERFECT"]) + int(state["GREAT"]) + int(state["GOOD"])
	var attempts := hits + int(state["MISS"])
	return {
		"score": state["score"], "combo": state["combo"], "streak": state["best_combo"],
		"hits": hits, "misses": state["MISS"], "attempts": attempts,
		"accuracy": 100.0 * int(state["weight"]) / (attempts * 100.0) if attempts > 0 else 0.0,
		"perfect": state["PERFECT"], "great": state["GREAT"], "good": state["GOOD"],
	}


## Shared results and share cards use the same weighting as each dancer's HUD.
func totals() -> Dictionary:
	var hits := 0
	var attempts := 0
	var weight := 0
	for player in players.size():
		var values := stats(player)
		hits += int(values["hits"])
		attempts += int(values["attempts"])
		weight += int(players[player]["weight"])
	return {
		"hits": hits, "attempts": attempts,
		"accuracy": float(weight) / attempts if attempts > 0 else 0.0,
	}


func _record(player: int, index: int, result: String) -> Dictionary:
	var state := players[player]
	state[result] = int(state[result]) + 1
	state["combo"] = 0 if result == "MISS" else int(state["combo"]) + 1
	state["best_combo"] = maxi(int(state["best_combo"]), int(state["combo"]))
	var base := int(BASE_SCORE[result])
	var points := floori(base * (1.0 + minf(float(state["combo"]) / 10.0, 2.0)))
	state["score"] = int(state["score"]) + points
	state["weight"] = int(state["weight"]) + base
	return {
		"player": player, "lane": int(notes[index]["lane"]) if index >= 0 else -1,
		"result": result, "points": points, "note": index,
	}
