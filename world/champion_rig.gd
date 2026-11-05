extends Node3D

## One original champion rig; wardrobe changes never touch rhythm state.

const Models = preload("res://games/tuki-tuki_agents/world/rhythm_models.gd")
const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")

var character_id := ""
var outfit_id := ""
var shoes_id := ""
var limbs: Array[Node3D] = []
var _character_color := Color.WHITE
var _torso: MeshInstance3D
var _seam: MeshInstance3D
var _sleeves: Array[MeshInstance3D] = []
var _shoes: Array[MeshInstance3D] = []
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
	_soles.clear()
	_shoe_bands.clear()
	character_id = str(character["id"])
	_character_color = Color(str(character["color"]))
	var skin := Color("bd8c68") if player == 0 else Color("d3a17c")
	_torso = Models.box(self, Vector3(0.65, 0.85, 0.4),
		Vector3(0, 1.3, 0), _character_color)
	_torso.name = "Shirt"
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	head.mesh = sphere
	head.material_override = Models.material(skin)
	head.position.y = 2.0
	add_child(head)
	for x in [-0.11, 0.11]:
		Models.box(self, Vector3(0.065, 0.06, 0.04),
			Vector3(x, 2.05, 0.28), Color("101326"))
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
		Models.box(limb, Vector3(0.18, 0.65, 0.22), Vector3(0, -0.3, 0),
			skin if index < 2 else Color("263447"))
		if index < 2:
			_sleeves.append(Models.box(limb, Vector3(0.2, 0.27, 0.24),
				Vector3(0, -0.1, 0), _character_color))
		else:
			_shoes.append(Models.box(limb, Vector3(0.24, 0.14, 0.4),
				Vector3(0, -0.65, 0.1), Color("d8dfe8")))
			_soles.append(Models.box(limb, Vector3(0.25, 0.04, 0.41),
				Vector3(0, -0.7, 0.1), Color("d8dfe8")))
			_shoe_bands.append(Models.box(limb, Vector3(0.24, 0.035, 0.02),
				Vector3(0, -0.64, 0.31), Color("263447")))
		limbs.append(limb)
	wear(outfit, shoes)


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
	_torso.material_override = Models.material(cloth)
	var jacket := bool(outfit.get("jacket", false))
	_seam.visible = jacket
	for sleeve in _sleeves:
		sleeve.visible = jacket
		sleeve.material_override = Models.material(cloth)
	var height := 0.14 + int(shoes["shoe_style"]) * 0.05
	for index in _shoes.size():
		(_shoes[index].mesh as BoxMesh).size.y = height
		_shoes[index].position.y = -0.72 + height * 0.5
		_shoes[index].material_override = Models.material(shoes["color"])
		_soles[index].visible = int(shoes["shoe_style"]) > 0
		_shoe_bands[index].visible = int(shoes["shoe_style"]) > 0
		_shoe_bands[index].material_override = Models.material(shoes["trim"])


## Store normalizes shop fields; rendering metadata stays in the game catalogue.
static func _catalogue_item(id: String, kind: String) -> Dictionary:
	for item in Options.STORE_ITEMS:
		if str(item["id"]) == id and str(item["kind"]) == kind:
			return item
	push_error("Tuki Tuki: unknown %s cosmetic '%s'." % [kind, id])
	return {}


## The audio-derived beat phase drives the same pose in play and demonstrations.
func dance(phase: float) -> void:
	position.y = absf(sin(phase)) * 0.07
	rotation.z = sin(phase * 0.5) * 0.07
	for index in limbs.size():
		limbs[index].rotation.x = sin(phase + index * PI) * 0.28


## Accessibility changes park every decorative transform immediately.
func park() -> void:
	position.y = 0.0
	rotation = Vector3.ZERO
	for limb in limbs:
		limb.rotation = Vector3.ZERO
