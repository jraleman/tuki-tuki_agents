extends Node

## One finite synthesized track supplies both audible beats and the game clock.

const RATE := 22050
const LEAD_IN := 3.0
const TAIL := 0.35
var player: AudioStreamPlayer
var finished := false
var _last_position := 0.0
var _length := 0.0
var _paused := false
var _cached_id := ""
var _cached_stream: AudioStreamWAV
var _cues: Dictionary = {}


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "SongClock"
	player.bus = "Music"
	player.volume_db = -7.0
	player.finished.connect(_on_finished)
	add_child(player)


## Reuse the selected song on replay without retaining every song's PCM.
func start(song: Dictionary) -> void:
	stop()
	if _cached_id != str(song["id"]):
		_cached_stream = render(song)
		_cached_id = str(song["id"])
	player.stream = _cached_stream
	_length = _cached_stream.get_length()
	_last_position = 0.0
	finished = false
	player.play()


## Mixer interpolation and output compensation follow the audible, not frame, clock.
func song_time_ms() -> float:
	if not _paused and not get_tree().paused and player.playing:
		var audible := player.get_playback_position() \
			+ AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		_last_position = maxf(_last_position, audible)
	return (_last_position - LEAD_IN) * 1000.0


## Hold the exact musical position across the shared pause/settings overlays.
func set_paused(value: bool) -> void:
	if value:
		song_time_ms()
	_paused = value
	player.stream_paused = value


## Leaving the scene releases its own playback; no global music survives the game.
func stop() -> void:
	if player != null:
		player.stop()
	_paused = false


## Cached voices feed the framework's bounded SFX pool.
func cue(result: String) -> AudioStreamWAV:
	if not _cues.has(result):
		var frequency: float = {
			"PERFECT": 800.0, "GREAT": 600.0, "GOOD": 400.0, "MISS": 200.0,
		}[result]
		_cues[result] = _stream(_tone(frequency, 0.12))
	return _cues[result]


## This preserves the web prototype's synthesized kick, hat and melodic accents.
static func render(song: Dictionary) -> AudioStreamWAV:
	var beat := 60.0 / float(song["bpm"])
	var loop := PackedByteArray()
	var loop_samples := ceili(16.0 * beat * RATE)
	loop.resize(loop_samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(song["seed"])
	for index in loop_samples:
		var t := float(index) / RATE
		var beat_number := int(t / beat)
		var phase := fmod(t, beat)
		var kick := sin(TAU * (45.0 * phase + 1.8 * (1.0 - exp(-phase * 28.0)))) \
			* exp(-phase * 24.0) * 0.52
		var half_phase := fmod(t, beat * 0.5)
		var hat := rng.randf_range(-1.0, 1.0) * exp(-half_phase * 100.0) * 0.13
		var clap := 0.0
		if beat_number % 4 in [1, 3]:
			clap = rng.randf_range(-1.0, 1.0) * exp(-phase * 38.0) * 0.2
		var melody := 0.0
		if beat_number % 8 == 7:
			melody = (sin(TAU * 220.0 * phase) + sin(TAU * 330.0 * phase) * 0.4) \
				* exp(-phase * 8.0) * 0.14
		var sample := clampf(kick + hat + clap + melody, -1.0, 1.0)
		loop.encode_s16(index * 2, roundi(sample * 32767.0))
	var bytes := PackedByteArray()
	bytes.resize(roundi(LEAD_IN * RATE) * 2)
	var count_in := _tone(660.0, 0.07)
	for second in 3:
		for index in count_in.size():
			bytes.encode_s16((second * RATE + index) * 2, roundi(count_in[index] * 32767.0))
	var remaining := roundi(float(song["duration"]) * RATE) * 2
	while remaining > 0:
		var count := mini(remaining, loop.size())
		bytes.append_array(loop.slice(0, count))
		remaining -= count
	var silence := PackedByteArray()
	silence.resize(roundi(TAIL * RATE) * 2)
	bytes.append_array(silence)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream


static func _tone(frequency: float, seconds: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(roundi(seconds * RATE))
	for index in samples.size():
		var t := float(index) / RATE
		samples[index] = sin(TAU * frequency * t) * exp(-t * 26.0) * 0.25
	return samples


static func _stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in samples.size():
		bytes.encode_s16(index * 2, roundi(samples[index] * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream


func _on_finished() -> void:
	_last_position = _length
	finished = true
