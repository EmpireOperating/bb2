extends Node3D
## Read-only presentation of Battle.tiles. Units/camera/lights belong to the caller.
const Layout = preload("res://prototype/hex_layout.gd")
const Palette = preload("res://prototype/materials/palette.gd")
const Builder = preload("res://prototype/terrain_assets/mesh_builder.gd")
const WATER_LEVEL := -0.42
const BED_LEVEL := -0.82

var tile_surfaces: Dictionary = {}
var water_surfaces: Array[MeshInstance3D] = []
var bridge_roots: Array[Node3D] = []
## Each entry owns its meshes/materials; only these may be faded by the camera.
var occluders: Array[Dictionary] = []
var faded_occluders: Array[Node3D] = []
var decorations: Array[Dictionary] = []
var _generated: Node3D
var _hex_meshes: Dictionary = {}
var _water_mesh: ArrayMesh

func build(battle) -> void:
	if is_instance_valid(_generated):
		remove_child(_generated)
		_generated.free()
	tile_surfaces.clear()
	water_surfaces.clear()
	bridge_roots.clear()
	occluders.clear()
	faded_occluders.clear()
	decorations.clear()
	_generated = Node3D.new()
	_generated.name = "RuinedCrossing"
	add_child(_generated)
	var keys: Array = battle.tiles.keys()
	keys.sort()
	var rubble := Builder.new()
	var grasses := Builder.new()
	var litter := Builder.new()
	for key: String in keys:
		var parts := key.split(",")
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		var tile: Dictionary = battle.tiles[key]
		var center: Vector3 = Layout.world(cell, float(tile.height))
		var is_water: bool = tile.terrain == "water"
		var is_bridge: bool = tile.terrain == "ford" and cell == Vector2i(6, 4)
		var surface := MeshInstance3D.new()
		surface.name = "Tile_%d_%d" % [cell.x, cell.y]
		surface.position = center
		if is_water:
			surface.position.y += BED_LEVEL
		var depth := surface.position.y + 1.1
		if is_bridge:
			depth = 0.13
		if not _hex_meshes.has(depth):
			_hex_meshes[depth] = _hex_prism(depth)
		surface.mesh = _hex_meshes[depth]
		surface.set_surface_override_material(0, Palette.ground(str(tile.terrain)))
		surface.set_surface_override_material(1, Palette.ground("cliff"))
		_generated.add_child(surface)
		tile_surfaces[key] = surface
		if is_water or is_bridge:
			_add_water(center)
		if is_bridge:
			_add_bridge(center)
		if tile.terrain == "wall":
			_add_wall(key, cell, center, battle.tiles)
		elif tile.terrain == "forest":
			_add_tree(key, cell, center)
		if not is_water and not is_bridge:
			_add_dressing(key, cell, center, rubble, grasses, litter)
	var dressing := Node3D.new()
	dressing.name = "LowDressing"
	_generated.add_child(dressing)
	_emit_batch(dressing, "EdgeRubble", rubble, Palette.masonry())
	_emit_batch(dressing, "AutumnGrasses", grasses, Palette.foliage(0.007))
	_emit_batch(dressing, "FallenLeaves", litter, Palette.foliage(0.0))

func _add_dressing(key: String, cell: Vector2i, center: Vector3, rubble, grasses, litter) -> void:
	for i in 3:
		var sample := _sample(cell, i * 21 + 187)
		var angle := sample * TAU
		var offset := Vector3(cos(angle), 0.007, sin(angle)) * 0.72
		if i == 0:
			var height := 0.045 + sample * 0.035
			var position_local := offset + Vector3.UP * height * 0.5
			rubble.stone(center + position_local, Vector3(0.17 + sample * 0.05, height, 0.12), angle, Color("8f8970"))
			decorations.append({"tile": key, "kind": "rubble", "offset": offset, "max_height": 0.09})
		else:
			grasses.grass_tuft(center + offset, 0.13 + sample * 0.04, angle, Color("8b8451").lightened(sample * 0.06))
			decorations.append({"tile": key, "kind": "grass", "offset": offset, "max_height": 0.18})
		var leaf_offset := Vector3(cos(angle + 0.5), 0.018, sin(angle + 0.5)) * 0.72
		litter.leaf_litter(center + leaf_offset, angle, Color("98763c").lightened(sample * 0.05))
		decorations.append({"tile": key, "kind": "leaves", "offset": leaf_offset, "max_height": 0.03})

func _emit_batch(parent: Node3D, batch_name: String, builder, material: Material) -> void:
	var mesh: ArrayMesh = builder.finish()
	if mesh.get_surface_count() == 0:
		return
	var instance := MeshInstance3D.new()
	instance.name = batch_name
	instance.mesh = mesh
	instance.material_override = material
	if batch_name != "EdgeRubble":
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

## unit_positions are WORLD-SPACE feet positions, not tile coordinates or heads.
## OBB ray tests use Camera3D projection, including orthographic ray origins.
func update_occlusion(camera: Camera3D, unit_positions: Array) -> void:
	faded_occluders.clear()
	var camera_valid := is_instance_valid(camera) and camera.is_inside_tree()
	for object: Dictionary in occluders:
		var faded := false
		if camera_valid:
			for foot in unit_positions:
				if foot is Vector3 and _hides_unit(camera, object, foot):
					faded = true
					break
		if faded:
			faded_occluders.append(object.root)
		if faded != object.faded:
			object.faded = faded
			for material: ShaderMaterial in object.materials:
				material.set_shader_parameter("opacity", 0.23 if faded else 1.0)
			for mesh: MeshInstance3D in object.meshes:
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if faded else GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _hides_unit(camera: Camera3D, object: Dictionary, foot: Vector3) -> bool:
	var inverse: Transform3D = object.root.global_transform.affine_inverse()
	var bounds: AABB = object.bounds.grow(0.06)
	var viewport := camera.get_viewport().get_visible_rect()
	# Conservative body samples include knees, torso and helmet; no physics/sim edits.
	for height: float in [0.45, 0.95, 1.40]:
		var target := foot + Vector3.UP * height
		if camera.is_position_behind(target):
			continue
		var pixel := camera.unproject_position(target)
		if not viewport.has_point(pixel):
			continue
		var origin := camera.project_ray_origin(pixel)
		if bounds.intersects_segment(inverse * origin, inverse * target) != null:
			return true
	return false

static func _sample(cell: Vector2i, salt: int) -> float:
	var value := ((cell.x * 73856093) ^ (cell.y * 19349663) ^ (salt * 83492791)) & 0x7fffffff
	value = (value ^ (value >> 13)) * 1274126177
	return float(value & 0xffff) / 65535.0

func _add_wall(key: String, cell: Vector2i, center: Vector3, tiles: Dictionary) -> void:
	var ruin := Node3D.new()
	ruin.name = "RuinedWall_%d_%d" % [cell.x, cell.y]
	ruin.position = center
	# Follow actual adjacent wall cells; never infer blockers from scenic coordinates.
	var nearby: Array = tiles.keys()
	nearby.sort()
	for other: String in nearby:
		if other == key or tiles[other].terrain != "wall":
			continue
		var parts := other.split(",")
		var delta: Vector3 = Layout.world(Vector2i(int(parts[0]), int(parts[1]))) - Layout.world(cell)
		if delta.length() < 1.74:
			ruin.rotation.y = -atan2(delta.z, delta.x)
			break
	_generated.add_child(ruin)
	var stones := Builder.new()
	for column in 4:
		var courses := 5 + int(_sample(cell, column + 19) * 4.0)
		for row in courses:
			var shade := _sample(cell, column * 23 + row * 7)
			var position_local := Vector3(-0.51 + column * 0.34 + (0.035 if row % 2 == 0 else -0.035), row * 0.235 + 0.113, 0.0)
			position_local.z += (shade - 0.5) * 0.05
			stones.stone(position_local, Vector3(0.321, 0.218, 0.44 + shade * 0.06), (shade - 0.5) * 0.05, Color("8e8d7b").lightened(shade * 0.13))
	# Fallen capstones remain inside the blocked tile, not on neighbouring lanes.
	for i in 3:
		stones.stone(Vector3(-0.45 + i * 0.43, 0.075, 0.48), Vector3(0.24, 0.15, 0.17), _sample(cell, i + 63) * 0.8, Color("898874"))
	var masonry := MeshInstance3D.new()
	masonry.name = "Masonry"
	masonry.mesh = stones.finish()
	masonry.material_override = Palette.masonry()
	ruin.add_child(masonry)
	_register_occluder("wall", key, ruin, [masonry])

func _add_tree(key: String, cell: Vector2i, center: Vector3) -> void:
	var tree := Node3D.new()
	tree.name = "AutumnOak_%d_%d" % [cell.x, cell.y]
	tree.position = center
	_generated.add_child(tree)
	var wood := Builder.new()
	var leaves := Builder.new()
	var foot := Vector3(0.52, 0.0, -0.30)
	var fork := foot + Vector3(-0.035, 1.12, 0.035)
	var crown_center := foot + Vector3(-0.13, 1.90, 0.04)
	wood.branch(foot, fork, 0.105, 0.068, Color("4b4030"))
	wood.branch(fork, crown_center + Vector3(0.0, 0.28, 0.0), 0.068, 0.022, Color("5b4b36"))
	# Root buttresses stay at the tile edge, clear of the unit's standing center.
	for i in 4:
		var angle := float(i) * TAU / 4.0
		var tip := foot + Vector3(cos(angle) * 0.11, 0.02, sin(angle) * 0.11)
		wood.branch(tip, foot + Vector3.UP * 0.26, 0.025, 0.044, Color("514631"))
	for i in 7:
		var angle := float(i) * 2.39996 + _sample(cell, 72) * 0.8
		var reach := 0.32 if i % 2 == 0 else 0.47
		var tip := crown_center + Vector3(cos(angle) * reach, float(i % 3) * 0.22 - 0.12, sin(angle) * reach)
		wood.branch(fork + Vector3.UP * (float(i % 3) * 0.17), tip, 0.036, 0.009, Color("665339"))
		var tint: Color = [Color("a57c35"), Color("a06329"), Color("8d843d"), Color("b08b42")][(i + cell.x + cell.y) % 4]
		leaves.leaf_cluster(tip, Vector3(0.35, 0.40, 0.31), _sample(cell, i + 101) * TAU, tint)
	var trunk := MeshInstance3D.new()
	trunk.name = "TrunkBranches"
	trunk.mesh = wood.finish()
	trunk.material_override = Palette.masonry()
	tree.add_child(trunk)
	var canopy := MeshInstance3D.new()
	canopy.name = "AutumnCanopy"
	canopy.mesh = leaves.finish()
	canopy.material_override = Palette.foliage()
	tree.add_child(canopy)
	_register_occluder("tree", key, tree, [trunk, canopy])

func _register_occluder(kind: String, tile: String, object_root: Node3D, meshes: Array) -> void:
	var bounds: AABB = meshes[0].transform * meshes[0].mesh.get_aabb()
	var materials: Array[ShaderMaterial] = []
	for mesh: MeshInstance3D in meshes:
		bounds = bounds.merge(mesh.transform * mesh.mesh.get_aabb())
		materials.append(mesh.material_override)
	occluders.append({"kind": kind, "tile": tile, "root": object_root, "meshes": meshes, "materials": materials, "bounds": bounds, "faded": false})

func _add_water(center: Vector3) -> void:
	if _water_mesh == null:
		_water_mesh = ArrayMesh.new()
		_water_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _hex_prism(0.1).surface_get_arrays(0))
	var water := MeshInstance3D.new()
	water.name = "Stream_%d" % water_surfaces.size()
	water.position = center + Vector3.UP * WATER_LEVEL
	water.mesh = _water_mesh
	water.material_override = Palette.water()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_generated.add_child(water)
	water_surfaces.append(water)

func _add_bridge(center: Vector3) -> void:
	var bridge := Node3D.new()
	bridge.name = "StoneBridge_6_4"
	bridge.position = center
	_generated.add_child(bridge)
	bridge_roots.append(bridge)
	var stones := Builder.new()
	# Individual voussoirs leave dark joints around a real open elliptical arch.
	for i in 11:
		var a := PI * float(i) / 11.0 + 0.012
		var b := PI * float(i + 1) / 11.0 - 0.012
		var points := PackedVector2Array([
			Vector2(cos(a) * 0.88, -0.76 + sin(a) * 0.67),
			Vector2(cos(b) * 0.88, -0.76 + sin(b) * 0.67),
			Vector2(cos(b) * 0.65, -0.76 + sin(b) * 0.48),
			Vector2(cos(a) * 0.65, -0.76 + sin(a) * 0.48),
		])
		stones.extrude_quad(points, -0.61, 0.61, Color("999486").lightened(float(i % 3) * 0.035))
	# Low coping at the outer edges preserves the standing and movement lane.
	for sign_z: float in [-1.0, 1.0]:
		for i in 5:
			stones.stone(Vector3(-0.68 + i * 0.34, 0.085, sign_z * 0.59), Vector3(0.32, 0.17, 0.16), 0.0, Color("a49e88"))
		# Spandrel blocks beside the crown, all below the deck.
		for sign_x: float in [-1.0, 1.0]:
			stones.stone(Vector3(sign_x * 0.73, -0.30, sign_z * 0.52), Vector3(0.25, 0.34, 0.20), 0.0, Color("8b8a77"))
	var masonry := MeshInstance3D.new()
	masonry.name = "ArchMasonry"
	masonry.mesh = stones.finish()
	masonry.material_override = Palette.masonry()
	bridge.add_child(masonry)

func _hex_prism(depth: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := Layout.corners(Vector2i.ZERO)
	for i in 6:
		for point: Vector3 in [Vector3.ZERO, corners[i], corners[(i + 1) % 6]]:
			tool.set_normal(Vector3.UP)
			tool.set_uv(Vector2(point.x, point.z))
			tool.add_vertex(point)
	var mesh := tool.commit()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 6]
		var c := b - Vector3.UP * depth
		var d := a - Vector3.UP * depth
		var normal := Vector3(a.x + b.x, 0, a.z + b.z).normalized()
		for point: Vector3 in [a, d, b, b, d, c]:
			tool.set_normal(normal)
			tool.set_uv(Vector2(point.x + point.z, point.y))
			tool.add_vertex(point)
	tool.commit(mesh)
	return mesh
