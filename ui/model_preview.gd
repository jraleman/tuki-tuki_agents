extends Control

## Shared-feature adapters draw the same original geometry as the rhythm stage.

const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")
const Models = preload("res://games/tuki-tuki_agents/world/rhythm_models.gd")
const Rig = preload("res://games/tuki-tuki_agents/world/champion_rig.gd")

@export_enum("champion", "store", "gallery") var purpose := "champion"
var configured_id := ""
var _data: Dictionary = {}
var _viewport: SubViewport
var _world: Node3D
var _subject: Node3D
var _camera: Camera3D
var _rig: Rig
var _bounds := AABB()
var _base_pitch := 0.12
var _yaw := 0.0
var _pitch := 0.0
var _zoom := 1.0
var _auto_spin := false
var _running := true
var _elapsed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.gui_disable_input = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_viewport)
	var texture := TextureRect.new()
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.texture = _viewport.get_texture()
	add_child(texture)
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world = Node3D.new()
	_viewport.add_child(_world)
	Models.light_world(_world, true)
	_camera = Camera3D.new()
	_camera.current = true
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = 35.0
	_camera.far = 1000.0
	_world.add_child(_camera)
	resized.connect(_resize)
	Settings.changed.connect(_on_setting_changed)
	Store.equipped_changed.connect(_on_equipped_changed)
	if not _data.is_empty():
		configure(_data)
	_resize()
	_update_motion()


## Supports the framework's item/character wrappers as well as exhibit dictionaries.
func configure(data: Dictionary) -> void:
	_data = data.duplicate(true)
	if not is_node_ready():
		return
	if _subject != null:
		_world.remove_child(_subject)
		_subject.queue_free()
	_subject = Node3D.new()
	_subject.name = "ActualGameModel"
	_world.add_child(_subject)
	_rig = null
	var entry: Dictionary = data.get("item", data.get("character", data))
	configured_id = str(entry.get("id", ""))
	_base_pitch = 0.12
	if purpose == "gallery" and str(entry.get("kind", "")) == "venue":
		Models.build_venue(_subject)
		_base_pitch = 0.55
	elif purpose == "gallery" and str(entry.get("kind", "")) == "arrows":
		var mesh := Models.arrow_mesh()
		for lane in 4:
			var arrow := MeshInstance3D.new()
			arrow.mesh = mesh
			arrow.rotation.y = Models.LANE_ROTATIONS[lane]
			arrow.position.x = (lane - 1.5) * 1.2
			arrow.material_override = Models.material(Models.LANE_COLORS[lane])
			_subject.add_child(arrow)
		Models.box(_subject, Vector3(5.8, 0.1, 1.8),
			Vector3(0, -0.12, 0), Color("19233d"))
		_base_pitch = 0.65
	else:
		var character := Data.CHARACTERS[0].duplicate(true) if purpose == "store" \
			else Data.character(configured_id)
		if character.is_empty():
			return
		_rig = Rig.new()
		_subject.add_child(_rig)
		_rig.configure(character, int(_data.get("player_index", 0)))
		_wear_equipped()
	_measure_bounds()
	if purpose == "store" and str(entry.get("kind", "")) == "shoes":
		_bounds = AABB(Vector3(-0.4, 0.1, -0.15), Vector3(0.8, 0.5, 0.7))
		_base_pitch = 0.3
	_resize()
	_update_motion()


## The gallery owns gesture state and auto-spin; these are framing offsets.
func set_view(yaw: float, pitch: float, zoom: float) -> void:
	_yaw = yaw
	_pitch = pitch
	_zoom = zoom
	_frame_camera()


func set_auto_spin(enabled: bool) -> void:
	_auto_spin = enabled and not Settings.reduced_motion_enabled()


## Shop refreshes cannot accidentally restart a reduced-motion preview.
func set_preview_running(enabled: bool) -> void:
	_running = enabled
	_update_motion()


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _rig == null:
		return
	_elapsed += delta
	_rig.dance(_elapsed * 1.6)
	_request_render()


func _on_setting_changed(key: String, _value: Variant) -> void:
	if key.begins_with("accessibility/"):
		if Settings.reduced_motion_enabled():
			_auto_spin = false
		_update_motion()


func _on_equipped_changed(id: String, _slot: String, _item: String) -> void:
	if id == Options.GAME_ID and _rig != null:
		_wear_equipped()
		_request_render()


func _wear_equipped() -> void:
	var player := int(_data.get("player_index", 0))
	var outfit := Store.equipped_item(Options.GAME_ID, Options.OUTFIT_SLOTS[player])
	var shoes := Store.equipped_item(Options.GAME_ID, Options.SHOE_SLOTS[player])
	if purpose == "store":
		var entry: Dictionary = _data.get("item", _data)
		if str(entry["kind"]) == "outfit":
			outfit = entry
		else:
			shoes = entry
	_rig.wear(outfit, shoes)


func _update_motion() -> void:
	var animate := _running and purpose != "gallery" and _rig != null \
		and not Settings.reduced_motion_enabled()
	set_process(animate)
	if not animate and _rig != null:
		_rig.park()
		_request_render()


func _resize() -> void:
	if _viewport == null:
		return
	var factor := minf(1.0, 1024.0 / maxf(1.0, maxf(size.x, size.y)))
	_viewport.size = Vector2i(maxi(32, roundi(size.x * factor)),
		maxi(32, roundi(size.y * factor)))
	_frame_camera()


func _measure_bounds() -> void:
	var first := true
	for node in _subject.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if not mesh.is_visible_in_tree():
			continue
		var local := mesh.get_aabb()
		for corner in 8:
			var point := _subject.to_local(mesh.to_global(local.get_endpoint(corner)))
			if first:
				_bounds = AABB(point, Vector3.ZERO)
				first = false
			else:
				_bounds = _bounds.expand(point)


func _frame_camera() -> void:
	if _camera == null or _subject == null:
		return
	var aspect := float(_viewport.size.x) / _viewport.size.y
	var center := _bounds.get_center()
	if purpose == "champion":
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.size = maxf(_bounds.size.y * 1.08, _bounds.size.x / aspect * 1.12)
		center.y = _bounds.position.y + _camera.size * 0.5 - 0.03
		_camera.position = center + Vector3(0, 0, 10)
	else:
		_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		var half_angle := deg_to_rad(_camera.fov) * 0.5
		half_angle = minf(half_angle, atan(tan(half_angle) * aspect))
		var distance := maxf(0.1, _bounds.size.length() * 0.5) \
			/ sin(half_angle) * 1.06 / _zoom
		var pitch := clampf(_base_pitch + _pitch, -0.8, 1.3)
		_camera.position = center + Vector3(
			sin(_yaw) * cos(pitch), sin(pitch), cos(_yaw) * cos(pitch)) * distance
	_camera.look_at(center)
	_request_render()


func _request_render() -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
