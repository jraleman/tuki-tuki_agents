extends SceneTree

## Each set-list entry must yield real finite PCM, rather than a missing media URL.

const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")
const Sound = preload("res://games/tuki-tuki_agents/audio/rhythm_audio.gd")
var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for song in Data.SONGS:
		var stream := Sound.render(song)
		_expect(absf(stream.get_length() - (
			Sound.LEAD_IN + float(song["duration"]) + Sound.TAIL)) < 0.001,
			"Every track must include its full song, count-in and judgement tail.")
		var data := stream.data
		var energy := 0.0
		var start := roundi(Sound.LEAD_IN * Sound.RATE)
		for index in range(start, start + Sound.RATE, 31):
			energy += absf(float(data.decode_s16(index * 2)))
		_expect(energy > 10000.0, "The synthesized song must actually contain audible samples.")
		var tail := data.slice(data.size() - 200)
		_expect(tail.count(0) == tail.size(), "A finite silent tail must follow each song.")
		var lead_silence := data.slice(roundi(0.5 * Sound.RATE) * 2,
			roundi(0.9 * Sound.RATE) * 2)
		_expect(lead_silence.count(0) == lead_silence.size(),
			"Count-in tones must leave a clear gap before the next count.")
	var sound := Sound.new()
	get_root().add_child(sound)
	sound.start(Data.SONGS[4])
	await create_timer(0.08).timeout
	var before := sound.song_time_ms()
	sound.set_paused(true)
	var held := sound.song_time_ms()
	await create_timer(0.08).timeout
	_expect(sound.song_time_ms() == held, "Pausing must hold the audio clock exactly.")
	sound.set_paused(false)
	await create_timer(0.08).timeout
	_expect(sound.song_time_ms() > before, "Resuming must advance the same audio clock.")
	var first_stream := sound.player.stream
	sound.start(Data.SONGS[4])
	_expect(sound.player.stream == first_stream and sound.song_time_ms() < -2900.0,
		"Replay must reuse PCM but restart the count-in and clock.")
	sound.stop()
	sound.free()
	await create_timer(0.05).timeout
	if _failures.is_empty():
		print("Tuki Tuki audio tests passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
