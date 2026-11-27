extends Node3D

## One original champion rig; wardrobe changes never touch rhythm state.

const Models = preload("res://games/tuki-tuki_agents/world/rhythm_models.gd")
const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
const Detail = preload("res://scripts/miniature_detail.gd")
const INK := Color("272634")
const CREAM := Color("fff0cf")

static var _shirt_mold: ArrayMesh
static var _unit_oval: SphereMesh
var character_id := ""
var outfit_id := ""
var shoes_id := ""
var limbs: Array[Node3D] = []
var _character_color := Color.WHITE
var _torso: MeshInstance3D
var _neck: Node3D
var _eyes: Node3D
var _seam: MeshInstance3D
var _sleeves: Array[MeshInstance3D] = []
var _shoes: Array[MeshInstance3D] = []
var _toes: Array[MeshInstance3D] = []
var _soles: Array[MeshInstance3D] = []
var _shoe_bands: Array[MeshInstance3D] = []


## The player index preserves the original two-seat skin palette.
func configure(character: Dictionary, player: int,
		outfit: Dictionary = {}, shoes: Dictionary = {}) -> void:
	for child in get_children():
		child.free()
	limbs.clear()
	_sleeves.clear()
	_shoes.clear()
	_toes.clear()
	_soles.clear()
	_shoe_bands.clear()
	character_id = str(character["id"])
	_character_color = Color(str(character["color"]))
	var skin := Color("bd8c68") if player == 0 else Color("d3a17c")
	_torso = MeshInstance3D.new()
	if _shirt_mold == null:
		_shirt_mold = _build_shirt()
	_torso.mesh = _shirt_mold
	_torso.position.y = 1.3
	_torso.name = "Shirt"
	add_child(_torso)
	_neck = Node3D.new()
	_neck.position.y = 1.72
	add_child(_neck)
	var portrait := Node3D.new()
	portrait.name = "Portrait"
	portrait.scale = Vector3(1.18, 1.12, 1.15)
	portrait.position.y = -0.205 - _neck.position.y
	_neck.add_child(portrait)
	_oval_part(portrait, Vector3.UP * 2.0, Vector3.ONE * 0.60, skin)
	_face(portrait, skin)
	for stripe in 3:
		Models.box(self, Vector3(0.5, 0.08, 0.02), Vector3(0, 1.5 - stripe * 0.1, 0.22),
			[Color("f6ce46"), Color("3263b8"), Color("e55668")][stripe])
	_seam = Models.box(self, Vector3(0.035, 0.2, 0.02),
		Vector3(0, 1.07, 0.22), Color("f5f0d9"))
	for index in 4:
		var limb := Node3D.new()
		limb.name = "Limb%d" % index
		limb.position = Vector3(-0.45 if index % 2 == 0 else 0.45,
			1.6 if index < 2 else 0.85, 0)
		if index >= 2:
			limb.position.x *= 0.5
		add_child(limb)
		var detail := Detail.new()
		var side := signf(limb.position.x)
		if index < 2:
			_sleeves.append(_oval_part(limb, Vector3(-side * 0.038, -0.07, 0),
				Vector3(0.319, 0.335, 0.305), _character_color))
			detail.oval(Vector3(side * 0.021, -0.27, 0.018), Vector3(0.16, 0.30, 0.18), skin)
			detail.oval(Vector3(side * 0.031, -0.40, 0.076), Vector3(0.18, 0.28, 0.19), skin,
				Vector3(-0.38, 0, 0))
			detail.oval(Vector3(side * 0.032, -0.52, 0.14), Vector3(0.204, 0.205, 0.22), skin)
			detail.oval(Vector3(-side * 0.036, -0.485, 0.21), Vector3(0.089, 0.129, 0.092), skin)
			detail.rod(Vector3(side * 0.03, -0.481, 0.111), Vector3(side * 0.03, -0.432, 0.09),
				0.093, CREAM)
		else:
			var navy := Color("263447")
			detail.oval(Vector3(0, -0.18, 0), Vector3(0.275, 0.56, 0.31), navy)
			detail.oval(Vector3(0, -0.44, -0.009), Vector3(0.231, 0.384, 0.248), navy)
			detail.rod(Vector3(0, -0.596, -0.006), Vector3(0, -0.541, -0.006), 0.102, CREAM)
			_shoes.append(Models.box(limb, Vector3(0.24, 0.14, 0.4),
				Vector3(0, -0.65, 0.1), Color("d8dfe8")))
			_toes.append(_oval_part(limb, Vector3(0, -0.65, 0.24),
				Vector3(0.279, 0.145, 0.255), Color("d8dfe8")))
			_soles.append(Models.box(limb, Vector3(0.25, 0.04, 0.41),
				Vector3(0, -0.7, 0.1), Color("d8dfe8")))
			_shoe_bands.append(Models.box(limb, Vector3(0.24, 0.035, 0.02),
				Vector3(0, -0.64, 0.31), Color("263447")))
		detail.attach(limb, "Dancewear")
		limbs.append(limb)
	wear(outfit, shoes)


func _oval_part(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	if _unit_oval == null:
		_unit_oval = SphereMesh.new()
		_unit_oval.radial_segments = 20
		_unit_oval.rings = 9
	var part := MeshInstance3D.new()
	part.mesh = _unit_oval
	part.scale = size
	part.position = at
	part.material_override = Detail.ink(color)
	parent.add_child(part)
	return part


## A flat chest takes the three printed stripes; the shoulders taper into the neck.
static func _build_shirt() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var outline: Array[Vector2] = [
		Vector2(-0.82, 1), Vector2(0.82, 1), Vector2(1, 0.66), Vector2(1, -0.66),
		Vector2(0.82, -1), Vector2(-0.82, -1), Vector2(-1, -0.66), Vector2(-1, 0.66),
	]
	var previous := PackedVector3Array()
	for level: Vector3 in [Vector3(0.28, -0.425, 0.165), Vector3(0.30, -0.37, 0.207),
			Vector3(0.356, 0.27, 0.207), Vector3(0.32, 0.355, 0.18), Vector3(0.18, 0.425, 0.13)]:
		var ring := PackedVector3Array()
		for corner in outline:
			ring.append(Vector3(corner.x * level.x, level.y, corner.y * level.z))
		for i in ring.size():
			var j := (i + 1) % ring.size()
			if previous.is_empty():
				for point: Vector3 in [Vector3.UP * level.y, ring[i], ring[j]]:
					surface.add_vertex(point)
			else:
				for point: Vector3 in [previous[i], ring[i], ring[j], previous[i], ring[j], previous[j]]:
					surface.add_vertex(point)
		previous = ring
	for i in previous.size():
		for point: Vector3 in [Vector3.UP * previous[i].y, previous[(i + 1) % previous.size()], previous[i]]:
			surface.add_vertex(point)
	surface.generate_normals()
	surface.index()
	return surface.commit()


func _face(portrait: Node3D, skin: Color) -> void:
	var detail := Detail.new()
	var hair := Color("48323a")
	detail.oval(Vector3(0, 2.206, -0.028), Vector3(0.60, 0.25, 0.58), hair)
	detail.oval(Vector3(0, 1.99, 0.288), Vector3(0.11, 0.095, 0.11), skin)
	detail.grin(Vector3(0.008, 1.907, 0.294), Vector3.RIGHT * 0.127,
		Vector3.UP * 0.082, Vector3.BACK * 0.028, 0.14)
	_eyes = Node3D.new()
	_eyes.name = "EyeLine"
	_eyes.position = Vector3(0, 2.046, 0.266)
	portrait.add_child(_eyes)
	var eyes := Detail.new()
	for side: float in [-1.0, 1.0]:
		detail.oval(Vector3(side * 0.283, 1.997, -0.004), Vector3(0.11, 0.145, 0.105), skin)
		detail.oval(Vector3(side * 0.314, 2.002, 0.019), Vector3(0.042, 0.083, 0.052),
			skin.darkened(0.19))
		detail.oval(Vector3(side * 0.183, 1.976, 0.226), Vector3(0.104, 0.043, 0.045),
			skin.lerp(Color("c67364"), 0.47), Vector3(0, side * 0.56, side * 0.1))
		var eye := Vector3.RIGHT * side * 0.115
		eyes.oval(eye, Vector3(0.150, 0.139, 0.078), CREAM, Vector3(0, side * 0.31, 0))
		eyes.oval(eye + Vector3(0.008, -0.001, 0.030), Vector3(0.100, 0.112, 0.037),
			Color("845849"))
		eyes.oval(eye + Vector3(0.009, 0.003, 0.044), Vector3(0.063, 0.085, 0.025), INK)
		eyes.oval(eye + Vector3(-0.005, 0.024, 0.053), Vector3.ONE * 0.028, Color.WHITE)
		eyes.tube([eye + Vector3(-side * 0.064, 0.013, 0.026),
			eye + Vector3(-side * 0.031, 0.061, 0.024), eye + Vector3(side * 0.025, 0.067, 0.006),
			eye + Vector3(side * 0.086, 0.041, -0.012)], [0.003, 0.009, 0.011, 0.002], hair)
		detail.oval(Vector3(side * 0.12, 2.133, 0.245), Vector3(0.153, 0.038, 0.056), hair,
			Vector3(0, 0, side * (0.08 if side < 0.0 else 0.22)))
	eyes.attach(_eyes, "LidsAndGaze")
	detail.sweep(Vector3(-0.095, 2.262, 0.09), Vector3(0.183, 2.119, 0.262),
		Vector3(-0.13, -0.11, 0.04), Vector3(0, 0.045, 0.085), hair)
	detail.sweep(Vector3(-0.207, 2.233, 0.107), Vector3(-0.187, 2.103, 0.222),
		Vector3(0.108, 0.012, 0), Vector3(-0.019, 0.025, 0.062), hair.lightened(0.08))
	match character_id:
		"maria_caracas":
			for side: float in [-1.0, 1.0]:
				detail.oval(Vector3(side * 0.30, 1.943, 0.033),
					Vector3(0.049, 0.055, 0.037), Color("ffc75b"))
			detail.oval(Vector3(0, 2.08, -0.29), Vector3(0.27, 0.24, 0.20), _character_color)
			detail.oval(Vector3(0.099, 2.035, -0.342), Vector3(0.32, 0.30, 0.24), hair,
				Vector3(0, 0, 0.45))
			detail.sweep(Vector3(0.073, 2.12, -0.329), Vector3(0.43, 1.815, -0.344),
				Vector3(0.115, 0.179, 0), Vector3(0, 0.013, 0.135), hair)
		"lucia_valencia":
			for side: float in [-1.0, 1.0]:
				detail.oval(Vector3(side * 0.229, 2.235, -0.113), Vector3.ONE * 0.255, hair)
		"rodriguez_barquisimeto":
			detail.oval(Vector3(0.015, 2.247, 0.163), Vector3(0.55, 0.06, 0.41), _character_color)
			detail.oval(Vector3(0, 2.259, -0.01), Vector3(0.59, 0.19, 0.55), _character_color)
		_:
			detail.oval(Vector3(0.065, 2.228, 0.17), Vector3(0.39, 0.18, 0.23), hair,
				Vector3(0, 0, 0.21))
	detail.attach(portrait, "FaceAndHair")
	var waist := Detail.new()
	waist.oval(Vector3(0, 1.731, 0), Vector3(0.25, 0.21, 0.25), skin)
	waist.oval(Vector3(0, 0.872, 0), Vector3(0.64, 0.25, 0.40), INK)
	waist.attach(self, "NeckAndWaist")


## Materials and shoe geometry are private to this rig, including in live previews.
func wear(outfit: Dictionary, shoes: Dictionary) -> void:
	outfit = _catalogue_item(str(outfit.get("id", Options.DEFAULT_OUTFIT["id"])), "outfit")
	shoes = _catalogue_item(str(shoes.get("id", Options.DEFAULT_SHOES["id"])), "shoes")
	if outfit.is_empty() or shoes.is_empty():
		return
	outfit_id = str(outfit["id"])
	shoes_id = str(shoes["id"])
	var cloth: Color = _character_color if bool(outfit.get("champion_color", false)) \
		else outfit["color"]
	var shirt := Models.material(cloth)
	shirt.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	shirt.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	shirt.roughness = 0.15
	_torso.material_override = shirt
	var jacket := bool(outfit.get("jacket", false))
	_seam.visible = jacket
	for sleeve in _sleeves:
		sleeve.material_override = Detail.ink(cloth)
		sleeve.scale.y = 0.46 if jacket else 0.335
		sleeve.position.y = -0.12 if jacket else -0.07
	var height := 0.14 + int(shoes["shoe_style"]) * 0.05
	for index in _shoes.size():
		(_shoes[index].mesh as BoxMesh).size.y = height
		_shoes[index].position.y = -0.72 + height * 0.5
		_shoes[index].material_override = Detail.ink(shoes["color"])
		_toes[index].material_override = _shoes[index].material_override
		_soles[index].visible = int(shoes["shoe_style"]) > 0
		_shoe_bands[index].visible = int(shoes["shoe_style"]) > 0
		_shoe_bands[index].material_override = Detail.ink(shoes["trim"])


## Store normalizes shop fields; rendering metadata stays in the game catalogue.
static func _catalogue_item(id: String, kind: String) -> Dictionary:
	for item in Options.STORE_ITEMS:
		if str(item["id"]) == id and str(item["kind"]) == kind:
			return item
	push_error("Tuki Tuki: unknown %s cosmetic '%s'." % [kind, id])
	return {}


## The audio-derived beat phase drives the same pose in play and demonstrations.
func dance(phase: float) -> void:
	var beat := sin(phase)
	var sway := sin(phase * 0.5)
	position.y = absf(sin(phase)) * 0.07
	rotation.z = sway * 0.07
	_neck.rotation = Vector3(-0.07 - beat * 0.10, sway * 0.22, -sway * 0.14)
	_eyes.scale.y = 1.0 - 0.28 * maxf(beat, 0.0)
	for index in limbs.size():
		var side := -1.0 if index % 2 == 0 else 1.0
		if index < 2:
			limbs[index].rotation = Vector3(-0.46 + side * beat * 0.62, side * 0.22,
				side * (0.41 + 0.29 * side * sway))
		else:
			limbs[index].rotation.x = -side * beat * 0.32


## Accessibility changes park every decorative transform immediately.
func park() -> void:
	position.y = 0.0
	rotation = Vector3.ZERO
	_neck.rotation = Vector3.ZERO
	_eyes.scale.y = 1.0
	for limb in limbs:
		limb.rotation = Vector3.ZERO
