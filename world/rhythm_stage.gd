extends Node3D

## Compatibility-renderer stage; pooled arrows and effects never own game rules.

const State = preload("res://games/tuki-tuki_agents/rhythm/rhythm_state.gd")
const Models = preload("res://games/tuki-tuki_agents/world/rhythm_models.gd")
const Rig = preload("res://games/tuki-tuki_agents/world/champion_rig.gd")
const COLORS := Models.LANE_COLORS
const ROTATIONS := Models.LANE_ROTATIONS
const TARGET_Z := 3.0
const TRAVEL := 22.0
const POOL_SIZE := 128
var reduced_motion := false
var intense_effects := true
var background_effects := true
var _camera: Camera3D
var _arrow_mesh: ArrayMesh
var _materials: Array[StandardMaterial3D] = []
var _arrows: Array[MeshInstance3D] = []
var _pads: Array[MeshInstance3D] = []
var _dancers: Array[Rig] = []
var _bursts: Array[Dictionary] = []
var _pad_energy: Array[float] = []
var _player_count := 1
var _beat := 0.0
var _active := false


func _ready() -> void:
	Models.light_world(self)
	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = 50.0
	_camera.current = true
	add_child(_camera)
	Models.build_venue(self)
	_arrow_mesh = Models.arrow_mesh()
	for color in COLORS:
		_materials.append(Models.material(color, 0.32))
	for index in POOL_SIZE:
		var arrow := MeshInstance3D.new()
		arrow.mesh = _arrow_mesh
		arrow.visible = false
		add_child(arrow)
		_arrows.append(arrow)
	for player in 2:
		for lane in 4:
			var pad := MeshInstance3D.new()
			pad.mesh = _arrow_mesh
			pad.rotation.y = ROTATIONS[lane]
			pad.scale = Vector3(1.13, 0.7, 1.13)
			pad.material_override = Models.material(COLORS[lane].darkened(0.4), 0.1)
			add_child(pad)
			_pads.append(pad)
			_pad_energy.append(0.0)
		for lane in 5:
			var line := Models.box(self, Vector3(0.025, 0.025, TRAVEL),
				Vector3.ZERO, Color("324966"))
			line.name = "Lane_%d_%d" % [player, lane]
	for index in 32:
		var particle := Models.box(self, Vector3.ONE * 0.09, Vector3.ZERO, COLORS[index % 4])
		particle.hide()
		_bursts.append({"mesh": particle, "life": 0.0, "velocity": Vector3.ZERO})
	get_viewport().size_changed.connect(_fit_camera)


## The same native rigs represent the champions selected by shared mode setup.
func configure(characters: Array[Dictionary], bpm: float) -> void:
	_player_count = characters.size()
	_beat = bpm / 60.0
	_active = true
	for dancer in _dancers:
		remove_child(dancer)
		dancer.queue_free()
	_dancers.clear()
	for player in _player_count:
		var rig := Rig.new()
		rig.name = "Champion%d" % (player + 1)
		add_child(rig)
		rig.configure(characters[player], player)
		rig.position = Vector3(-6.5 if player == 0 else 6.5, 0, -2.0)
		if _player_count == 1:
			rig.position.x = 4.0
		_dancers.append(rig)
	for player in 2:
		for lane in 4:
			var pad := _pads[player * 4 + lane]
			pad.visible = player < _player_count
			pad.position = Vector3(_lane_x(player, lane), 0.03, TARGET_Z)
		for lane in 5:
			var line := get_node("Lane_%d_%d" % [player, lane]) as MeshInstance3D
			line.visible = player < _player_count
			line.position = Vector3(_lane_x(player, 0) - 0.6 + lane * 1.2, -0.14,
				TARGET_Z - TRAVEL * 0.5)
	_fit_camera()
	clear_effects()


## Pure wardrobe updates preserve the active chart, playback position and poses.
func set_cosmetics(outfits: Array[Dictionary], shoes: Array[Dictionary]) -> void:
	for player in _dancers.size():
		_dancers[player].wear(outfits[player], shoes[player])


## Position is derived from remaining musical time, so FPS cannot change a hit.
func present(state: State, time_ms: float, scroll_speed: float) -> void:
	var used := 0
	var lookahead := 3200.0 / scroll_speed
	for player in _player_count:
		for note in state.visible_notes(player, time_ms, lookahead):
			assert(used < _arrows.size(), "Tuki Tuki arrow pool is too small for this chart.")
			var arrow := _arrows[used]
			var lane := int(note["lane"])
			arrow.material_override = _materials[lane]
			arrow.rotation.y = ROTATIONS[lane]
			arrow.position = Vector3(_lane_x(player, lane), 0.22,
				TARGET_Z - (float(note["time"]) - time_ms) / lookahead * TRAVEL)
			arrow.show()
			used += 1
	for index in range(used, _arrows.size()):
		_arrows[index].hide()
	if background_effects and not reduced_motion:
		var phase := time_ms * 0.001 * _beat * TAU
		for dancer in _dancers:
			dancer.dance(phase)


## Static targets and judgement text remain even when decorative effects are off.
func feedback(player: int, lane: int, result: String) -> void:
	if not intense_effects or reduced_motion or not background_effects:
		return
	_pad_energy[player * 4 + lane] = 0.4
	if result == "MISS":
		return
	var spawned := 0
	for burst in _bursts:
		if float(burst["life"]) > 0.0:
			continue
		var mesh: MeshInstance3D = burst["mesh"]
		var angle := spawned * TAU / 8.0
		mesh.position = Vector3(_lane_x(player, lane), 0.25, TARGET_Z)
		mesh.show()
		burst["life"] = 0.4
		burst["velocity"] = Vector3(cos(angle) * 2.0, 2.2, sin(angle) * 2.0)
		spawned += 1
		if spawned == 8:
			break


## Accessibility changes must park effects immediately, not after a timer expires.
func clear_effects() -> void:
	for index in _pad_energy.size():
		_pad_energy[index] = 0.0
		(_pads[index].material_override as StandardMaterial3D).emission_energy_multiplier = 0.1
	for burst in _bursts:
		burst["life"] = 0.0
		(burst["mesh"] as MeshInstance3D).hide()
	for dancer in _dancers:
		dancer.park()


## A finished or abandoned song cannot leave travelling notes behind the results.
func stop() -> void:
	_active = false
	for arrow in _arrows:
		arrow.hide()
	clear_effects()


func _process(delta: float) -> void:
	if not _active or reduced_motion or not intense_effects or not background_effects:
		return
	for index in _pad_energy.size():
		_pad_energy[index] = maxf(0.0, _pad_energy[index] - delta)
		(_pads[index].material_override as StandardMaterial3D).emission_energy_multiplier = \
			0.1 + _pad_energy[index] * 3.0
	for burst in _bursts:
		if float(burst["life"]) <= 0.0:
			continue
		burst["life"] = float(burst["life"]) - delta
		var mesh: MeshInstance3D = burst["mesh"]
		mesh.position += Vector3(burst["velocity"]) * delta
		mesh.visible = float(burst["life"]) > 0.0


func _lane_x(player: int, lane: int) -> float:
	var center := 0.0 if _player_count == 1 else (-2.8 if player == 0 else 2.8)
	return center + (lane - 1.5) * 1.2


func _fit_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x < 2.0 or viewport_size.y < 2.0:
		return
	var frame := Rect2(viewport_size * 0.06, viewport_size * 0.88)
	var center := Vector3(0, 0, -7.0)
	var offset := Vector3(0, 14.0, 20.0)
	for attempt in 32:
		_camera.position = center + offset
		_camera.look_at(center)
		var fits := true
		for player in _player_count:
			for lane in [0, 3]:
				for z in [TARGET_Z + 0.7, TARGET_Z - TRAVEL - 0.7]:
					var point := Vector3(_lane_x(player, lane), 0.2, z)
					if not frame.has_point(_camera.unproject_position(point)):
						fits = false
		for dancer in _dancers:
			for x in [-0.65, 0.65]:
				for y in [0.0, 2.4]:
					var point := dancer.position + Vector3(x, y, 0)
					if not frame.has_point(_camera.unproject_position(point)):
						fits = false
		if fits:
			return
		offset *= 1.1
