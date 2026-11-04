extends Node3D

## Compatibility-renderer stage; pooled arrows and effects never own game rules.

const State = preload("res://games/tuki-tuki_agents/rhythm/rhythm_state.gd")
const COLORS := [Color("ff6b85"), Color("60d9c4"), Color("67baff"), Color("f6ce46")]
const ROTATIONS := [PI * 0.5, PI, 0.0, -PI * 0.5]
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
var _dancers: Array[Node3D] = []
var _limbs: Array[Array] = []
var _bursts: Array[Dictionary] = []
var _pad_energy: Array[float] = []
var _player_count := 1
var _beat := 0.0
var _active := false


func _ready() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("101326")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a6bfe5")
	environment.environment.ambient_light_energy = 0.75
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.2
	add_child(light)
	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = 50.0
	_camera.current = true
	add_child(_camera)
	_box(self, Vector3(18, 0.25, 29), Vector3(0, -0.3, -7.5), Color("19233d"))
	for index in 3:
		_box(self, Vector3(13, 0.17, 0.3), Vector3(0, 0.2 + index * 0.22, -20.5),
			[Color("e55668"), Color("3263b8"), Color("f6ce46")][index])
	var title := Label3D.new()
	title.text = "TUKI TUKI"
	title.font_size = 100
	title.pixel_size = 0.015
	title.position = Vector3(0, 3.2, -18.5)
	title.modulate = Color("f6ce46")
	add_child(title)
	for index in 12:
		var x := -8.0 if index < 6 else 8.0
		var height := 1.0 + (index % 4) * 0.55
		_box(self, Vector3(0.8, height, 0.8),
			Vector3(x, height * 0.5, -17.0 + (index % 6) * 2.4), COLORS[index % 4].darkened(0.45))
	_arrow_mesh = _make_arrow()
	for color in COLORS:
		_materials.append(_material(color, 0.32))
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
			pad.material_override = _material(COLORS[lane].darkened(0.4), 0.1)
			add_child(pad)
			_pads.append(pad)
			_pad_energy.append(0.0)
		for lane in 5:
			var line := _box(self, Vector3(0.025, 0.025, TRAVEL),
				Vector3.ZERO, Color("324966"))
			line.name = "Lane_%d_%d" % [player, lane]
	for index in 32:
		var particle := _box(self, Vector3.ONE * 0.09, Vector3.ZERO, COLORS[index % 4])
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
	_limbs.clear()
	for player in _player_count:
		var rig := _make_dancer(characters[player], player)
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
		for player in _dancers.size():
			_dancers[player].position.y = absf(sin(phase)) * 0.07
			_dancers[player].rotation.z = sin(phase * 0.5) * 0.07
			var limbs := _limbs[player]
			for index in limbs.size():
				(limbs[index] as Node3D).rotation.x = sin(phase + index * PI) * 0.28


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
		dancer.position.y = 0.0
		dancer.rotation = Vector3.ZERO
	for limbs in _limbs:
		for limb: Node3D in limbs:
			limb.rotation = Vector3.ZERO


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
		if fits:
			return
		offset *= 1.1


func _make_dancer(character: Dictionary, player: int) -> Node3D:
	var rig := Node3D.new()
	rig.name = "Champion%d" % (player + 1)
	add_child(rig)
	var skin := Color("bd8c68") if player == 0 else Color("d3a17c")
	_box(rig, Vector3(0.65, 0.85, 0.4), Vector3(0, 1.3, 0), Color(character["color"]))
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	head.mesh = sphere
	head.material_override = _material(skin)
	head.position.y = 2.0
	rig.add_child(head)
	for x in [-0.11, 0.11]:
		_box(rig, Vector3(0.065, 0.06, 0.04), Vector3(x, 2.05, 0.28), Color("101326"))
	for stripe in 3:
		_box(rig, Vector3(0.5, 0.08, 0.02), Vector3(0, 1.5 - stripe * 0.1, 0.22),
			[Color("f6ce46"), Color("3263b8"), Color("e55668")][stripe])
	var limbs: Array = []
	for index in 4:
		var limb := Node3D.new()
		limb.position = Vector3((-0.45 if index % 2 == 0 else 0.45),
			1.6 if index < 2 else 0.85, 0)
		if index >= 2:
			limb.position.x *= 0.5
		rig.add_child(limb)
		_box(limb, Vector3(0.18, 0.65, 0.22), Vector3(0, -0.3, 0),
			skin if index < 2 else Color("263447"))
		if index >= 2:
			_box(limb, Vector3(0.24, 0.14, 0.4), Vector3(0, -0.65, 0.1), Color("d8dfe8"))
		limbs.append(limb)
	_limbs.append(limbs)
	return rig


static func _material(color: Color, glow := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	material.emission_enabled = glow > 0.0
	material.emission = color
	material.emission_energy_multiplier = glow
	return material


static func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = at
	parent.add_child(instance)
	return instance


static func _make_arrow() -> ArrayMesh:
	var polygon := PackedVector2Array([
		Vector2(-0.2, 0.5), Vector2(0.2, 0.5), Vector2(0.2, 0.02),
		Vector2(0.48, 0.02), Vector2(0, -0.52),
		Vector2(-0.48, 0.02), Vector2(-0.2, 0.02),
	])
	var indices := Geometry2D.triangulate_polygon(polygon)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in 2:
		for triangle in range(0, indices.size(), 3):
			for corner in 3:
				var index := indices[triangle + (corner if side == 0 else 2 - corner)]
				var point := polygon[index]
				surface.set_normal(Vector3.UP if side == 0 else Vector3.DOWN)
				surface.add_vertex(Vector3(point.x, 0.12 if side == 0 else 0.0, point.y))
	for index in polygon.size():
		var a := polygon[index]
		var b := polygon[(index + 1) % polygon.size()]
		var normal := Vector3(b.y - a.y, 0, a.x - b.x).normalized()
		for vertex in [
			Vector3(a.x, 0, a.y), Vector3(a.x, 0.12, a.y), Vector3(b.x, 0.12, b.y),
			Vector3(a.x, 0, a.y), Vector3(b.x, 0.12, b.y), Vector3(b.x, 0, b.y),
		]:
			surface.set_normal(normal)
			surface.add_vertex(vertex)
	return surface.commit()
