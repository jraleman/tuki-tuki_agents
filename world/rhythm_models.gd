extends RefCounted

## Original geometry shared by play, the opening, setup, shop and museum.

const LANE_COLORS := [Color("ff6b85"), Color("60d9c4"), Color("67baff"), Color("f6ce46")]
const LANE_ROTATIONS := [PI * 0.5, PI, 0.0, -PI * 0.5]


## An isolated world needs its own Compatibility lighting, not the host's camera.
static func light_world(parent: Node3D, transparent := false) -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR \
		if transparent else Environment.BG_COLOR
	environment.environment.background_color = Color("101326")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a6bfe5")
	environment.environment.ambient_light_energy = 0.75
	parent.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.2
	parent.add_child(light)


## The museum displays the actual venue rather than a separately authored copy.
static func build_venue(parent: Node3D) -> void:
	box(parent, Vector3(18, 0.25, 29), Vector3(0, -0.3, -7.5), Color("19233d"))
	for index in 3:
		box(parent, Vector3(13, 0.17, 0.3), Vector3(0, 0.2 + index * 0.22, -20.5),
			[Color("e55668"), Color("3263b8"), Color("f6ce46")][index])
	var title := Label3D.new()
	title.text = "TUKI TUKI"
	title.font_size = 100
	title.pixel_size = 0.015
	title.position = Vector3(0, 3.2, -18.5)
	title.modulate = Color("f6ce46")
	parent.add_child(title)
	for index in 12:
		var x := -8.0 if index < 6 else 8.0
		var height := 1.0 + (index % 4) * 0.55
		box(parent, Vector3(0.8, height, 0.8),
			Vector3(x, height * 0.5, -17.0 + (index % 6) * 2.4),
			LANE_COLORS[index % 4].darkened(0.45))


## Separate material instances keep live cosmetics local to their player.
static func material(color: Color, glow := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.65
	result.emission_enabled = glow > 0.0
	result.emission = color
	result.emission_energy_multiplier = glow
	return result


static func box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = at
	parent.add_child(instance)
	return instance


## Both faces and the extrusion have normals; arrows are not flat UI billboards.
static func arrow_mesh() -> ArrayMesh:
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
