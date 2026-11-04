extends RefCounted

## Seeded charts keep replays stable and simultaneous local battles fair.

const DENSITY := [0.3, 0.5, 0.7, 0.9]


## All times are audible-song milliseconds, independent of visual scroll speed.
static func generate(song: Dictionary, difficulty: int) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	if not song["difficulties"].has(difficulty):
		push_error("Tuki Tuki: selected song has no difficulty %d." % difficulty)
		return notes
	var rng := RandomNumberGenerator.new()
	rng.seed = int(song["seed"])
	var beat_ms := 60000.0 / float(song["bpm"])
	var beats := ceili(float(song["duration"]) * 1000.0 / beat_ms)
	for beat in beats:
		if str(song["id"]) == "tutorial_basic":
			if beat % 2 == 0:
				notes.append({"time": beat * beat_ms, "lane": (beat / 2) % 4})
			continue
		var lane := rng.randi_range(0, 3)
		var chance := rng.randf()
		var chord := rng.randf()
		var rapid := rng.randf()
		if beat == 0 or chance < float(DENSITY[difficulty]):
			notes.append({"time": beat * beat_ms, "lane": lane})
		if difficulty >= 2 and beat % 4 == 0 and chord < 0.4:
			notes.append({"time": beat * beat_ms, "lane": (lane + 2) % 4})
		if difficulty == 3 and rapid < 0.3:
			var time := (beat + 0.25) * beat_ms
			if time < float(song["duration"]) * 1000.0:
				notes.append({"time": time, "lane": (lane + 1) % 4})
	notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["time"]) == float(b["time"]):
			return int(a["lane"]) < int(b["lane"])
		return float(a["time"]) < float(b["time"])
	)
	return notes
