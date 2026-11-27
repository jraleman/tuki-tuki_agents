extends RefCounted

## A real champion in a fixed dance pose, surrounded by the actual chart arrows.
const Helpers = preload("res://tools/cover_art_helpers.gd")
const Rig = preload("res://games/tuki-tuki_agents/world/champion_rig.gd")
const Models = preload("res://games/tuki-tuki_agents/world/rhythm_models.gd")
const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")


## Bright dance-floor printing, with an oversized lower word instead of a tiny arrow icon.
static func design() -> Dictionary:
	return {
		"paper": Color("302353"), "ink": Color("fff0d0"), "accent": Color("ee6969"),
		"motif": "rhythm", "camera": Vector3(12, 8, -5),
		"photo": Rect2(20, 195, 984, 610),
		"lettering": [
			{"text": "TUKI", "at": Vector2(55, 184), "size": 218, "color": Color("f5cf48")},
			{"text": "TUKI", "at": Vector2(335, 969), "width": 640, "size": 225},
			{"text": "FIND YOUR", "at": Vector2(53, 875), "width": 285, "size": 36, "font": "mono"},
			{"text": "RHYTHM.", "at": Vector2(53, 930), "width": 285, "size": 43, "font": "mono"},
		],
	}


## The exact rig and chart meshes stay game-owned; scoring is never instantiated.
static func build(parent: Node) -> Node:
	var root := Helpers.group(parent)
	var champion := Rig.new()
	root.add_child(champion)
	champion.configure(Data.CHARACTERS[0], 0)
	champion.dance(1.1)
	for lane in 4:
		var arrow := Helpers.mesh(root, Models.arrow_mesh(),
			Models.material(Models.LANE_COLORS[lane]))
		arrow.position = [Vector3(-1.25, 0.3, 0.1), Vector3(-1.0, 2.2, 0),
			Vector3(1.2, 1.6, 0.1), Vector3(0.8, 0, 0.7)][lane]
		arrow.basis = Basis(Vector3.RIGHT, PI * 0.5) \
			* Basis(Vector3.UP, Models.LANE_ROTATIONS[lane])
		arrow.scale = Vector3.ONE * 0.75
	return root
