extends "res://visual_slice/terrain.gd"
## Authored-map presentation only. Reuse painted assets/mesh/opaque fade helpers,
## never the predecessor's coordinate-dependent map construction.
const Fields = preload("res://terrain_pass/materials/fields.gdshader")
const FieldMesh = preload("res://terrain_pass/terrain_assets/field_mesh.gd")
const StrataMesh = preload("res://terrain_pass/terrain_assets/strata_mesh.gd")
var _descriptor: Dictionary = {}
var _presentation: Dictionary = {}
var _stream_cells: Dictionary = {}
var _road_keys: Dictionary = {}
var _bridge_keys: Dictionary = {}
var _board_min := Vector2i.ZERO
var _board_max := Vector2i.ZERO
var build_error := ""
var _mask_cache: Dictionary = {}
var _floor_samples: Array[Dictionary] = []
var _road_shapes: Array[Dictionary] = []

func build(battle) -> void:
	if is_instance_valid(_generated):
		remove_child(_generated)
		_generated.free()
	_generated = Node3D.new()
	_generated.name = "AuthoredTerrain"
	add_child(_generated)
	for collection in [tile_surfaces, world_anchors, water_surfaces, bridge_roots, occluders, faded_occluders, decorations, ground_batches, cliff_edges, _stream_cells, _road_keys, _bridge_keys]:
		collection.clear()
	geometry_stats.clear()
	_mask_cache.clear()
	_floor_samples.clear()
	_road_shapes.clear()
	build_error = ""
	_descriptor = battle.get_meta("authored_map", {}).duplicate(true)
	if _descriptor.is_empty():
		build_error = "Authored map metadata is required; no coordinate fallback."
		return
	_tiles = battle.tiles
	_presentation = _descriptor.presentation
	for cell: Vector2i in _presentation.stream: _stream_cells[cell] = true
	for key: String in _presentation.road: _road_keys[key] = true
	for key: String in _presentation.bridges: _bridge_keys[key] = true
	var keys: Array = _tiles.keys()
	keys.sort()
	_board_min = _cell(keys[0])
	_board_max = _board_min
	for key: String in keys:
		var cell := _cell(key)
		_board_min = _board_min.min(cell)
		_board_max = _board_max.max(cell)
		var center := Layout.world(cell, float(_tiles[key].height))
		var anchor := Node3D.new()
		anchor.name = "Standing_%s" % key.replace(",", "_")
		anchor.position = center
		_generated.add_child(anchor)
		tile_surfaces[key] = anchor
		world_anchors[key] = center
	_prepare_masks(keys)
	_build_fields()
	_build_authored_water()
	for key: String in _presentation.bridges:
		_painted_bridge(world_anchors[key])
		var bridge: Node3D = bridge_roots.back()
		bridge.name = "StoneBridge_" + key.replace(",", "_")
		bridge.set_meta("tile",key)
		bridge.rotation.y = _road_yaw(key)
	for key: String in keys:
		var tile: Dictionary = _tiles[key]
		if not tile.get("blocked",false): continue
		match tile.get("obstacle", ""):
			"tree": _authored_tree(key)
			"wall": _authored_ruin(key)
			"boulder": _authored_boulder(key)
	_authored_landscape(keys)
	_measure_geometry()

func _build_fields() -> void:
	var tops := FieldMesh.new()
	var cliffs := Builder.new()
	for r in range(_board_min.y - 6, _board_max.y + 7):
		for q in range(_board_min.x - 6, _board_max.x + 7):
			var cell := Vector2i(q,r)
			var key := "%d,%d" % [q,r]
			var y := _surface_height(cell)
			var center := Layout.world(cell)
			center.y = y
			var ring := Layout.corners(cell)
			var offboard := not _tiles.has(key) and not _stream_cells.has(cell)
			if offboard: center.y += _backdrop_height(center)
			for i in 6:
				ring[i].y = y + (_backdrop_height(ring[i]) if offboard else 0.0)
			for i in 6:
				var a: Vector3 = ring[i]
				var b: Vector3 = ring[(i+1)%6]
				# Midpoints let a smooth road continue only across actual road edges.
				var mid := (a+b)*.5
				for pair: Array in [[a,mid],[mid,b]]:
					var inner_a: Vector3 = center.lerp(pair[0],.52)
					var inner_b: Vector3 = center.lerp(pair[1],.52)
					_masked_top(tops,key,center,inner_a,inner_b)
					_masked_top(tops,key,inner_a,pair[0],pair[1])
					_masked_top(tops,key,inner_a,pair[1],inner_b)
				var midpoint := (a+b)*.5
				var outward := Vector3(midpoint.x-center.x,0,midpoint.z-center.z).normalized()
				var neighbor := Layout.from_world(midpoint+outward*.05)
				var low := _surface_height(neighbor)
				if y > low + .001:
					cliffs.quad(a,Vector3(a.x,low,a.z),Vector3(b.x,low,b.z),b,Color("969b92"))
					cliff_edges.append({"cell":cell,"neighbor":neighbor,"a":a,"b":b,"high":y,"low":low})
	var material := ShaderMaterial.new()
	material.shader = Fields
	for kind: String in ["earth", "meadow", "paving"]: material.set_shader_parameter(kind, Paint.texture(kind))
	material.set_shader_parameter("woodland", _presentation.biome == "woodland")
	var ground := _mesh(_generated,"ContinuousFields",tops,material)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground_batches.append(ground)
	_mesh(_generated,"ExposedFaces",cliffs,Paint.painted("rock",.65))
	backdrop_bounds = ground.mesh.get_aabb()

func _masked_top(builder, key: String, a: Vector3, b: Vector3, c: Vector3) -> void:
	builder.masked_triangle(a,b,c,_field_mask(key,a),_field_mask(key,b),_field_mask(key,c))

func _prepare_masks(keys: Array) -> void:
	for key: String in keys:
		var cell := _cell(key)
		var center := Layout.world(cell)
		var origin := Vector2(center.x,center.z)
		var tag: String = _tiles[key].terrain
		_floor_samples.append({"p":origin,"mask":Vector3(1 if tag == "forest" else 0,1 if tag in ["mud","water","deep_water","shallow_water"] else 0,1 if tag in ["rocks","rubble","stone"] else 0)})
		if not _road_keys.has(key): continue
		var shape := {"p":origin,"exits":[],"closed":[]}
		var corners := Layout.corners(cell)
		for i in 6:
			var midpoint := (corners[i]+corners[(i+1)%6])*.5
			var outward := (midpoint-center).normalized()
			var neighbor := Layout.from_world(midpoint+outward*.05)
			if _road_keys.has("%d,%d" % [neighbor.x,neighbor.y]):
				var end := Layout.world(neighbor)
				shape.exits.append(Vector2(end.x,end.z))
			else: shape.closed.append(Vector2(outward.x,outward.z))
		_road_shapes.append(shape)

func _field_mask(_key: String, point: Vector3) -> Color:
	# Shared spatial mask, not independently colored hexes. Quantization only
	# unifies mask evaluation at shared floating-point boundaries; geometry stays exact.
	var p := Vector2(point.x,point.z).snapped(Vector2.ONE*.00001)
	if _mask_cache.has(p): return _mask_cache[p]
	var floor_mask := Vector3.ZERO
	var total := 0.0
	for sample: Dictionary in _floor_samples:
		var distance: float = p.distance_to(sample.p)
		if distance >= 1.75: continue
		var weight := pow(1.75-distance,2.0)
		floor_mask += sample.mask*weight
		total += weight
	if total > 0.0: floor_mask /= total
	var road := 0.0
	for shape: Dictionary in _road_shapes:
		var offset: Vector2 = p-shape.p
		if offset.length() > 1.001: continue
		var distance := offset.length()
		for end: Vector2 in shape.exits:
			distance = minf(distance,p.distance_to(Geometry2D.get_closest_point_to_segment(p,shape.p,end)))
		var mask := 1.0-smoothstep(.35,.72,distance)
		for normal: Vector2 in shape.closed:
			mask *= smoothstep(0.0,.25,sqrt(3.0)*.5-offset.dot(normal))
		road = maxf(road,mask)
	var result := Color(road,floor_mask.x,floor_mask.y,floor_mask.z)
	_mask_cache[p] = result
	return result

func _road_yaw(key: String) -> float:
	var center := Layout.world(_cell(key))
	for other: String in _presentation.road:
		var delta := Layout.world(_cell(other))-center
		if delta.length() > .1 and delta.length() < 1.74: return -atan2(delta.z,delta.x)
	return 0.0

func _build_authored_water() -> void:
	if _presentation.stream.is_empty(): return
	var flow := Builder.new()
	for cell: Vector2i in _presentation.stream:
		var key := "%d,%d" % [cell.x,cell.y]
		var shallow: bool = _tiles.has(key) and _tiles[key].terrain == "shallow_water"
		var center := Layout.world(cell)
		center.y = float(_tiles[key].height)*Layout.HEIGHT_STEP+.012 if shallow else STREAM_Y
		var ring := Layout.corners(cell,0,.68 if shallow else 1.0)
		for i in 6: ring[i].y = center.y
		for i in 6: flow.triangle(center,ring[i],ring[(i+1)%6],Color.WHITE)
	var material := ShaderMaterial.new()
	material.shader = preload("res://visual_slice/materials/water.gdshader")
	material.set_shader_parameter("paint",Paint.texture("rock"))
	var water := _mesh(_generated,"AuthoredStream",flow,material)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_surfaces.append(water)

func _scenic_material(kind: String, mix_value: float = .45) -> ShaderMaterial:
	var material := Paint.painted(kind,.8)
	material.set_shader_parameter("painted_mix",mix_value)
	return material

func _obstacle_root(key: String, label: String) -> Node3D:
	var object := Node3D.new()
	object.name = label + "_" + key.replace(",", "_")
	object.position = world_anchors[key]
	_generated.add_child(object)
	return object

func _authored_tree(key: String) -> void:
	var cell := _cell(key)
	var tree := _obstacle_root(key,"WoodlandOak")
	var wood := Organic.new()
	var leaves := Organic.new()
	var height := 2.65+_sample(cell,231)*.42
	var fork := Vector3(-.04,1.24,.025)
	wood.branch(Vector3.ZERO,fork,.13,.085,Color("666759"))
	wood.branch(fork,Vector3(.06,height-.12,-.02),.085,.016,Color("777667"))
	for i in 5:
		var angle := float(i)*TAU/5.0
		wood.branch(Vector3(cos(angle)*.25,.018,sin(angle)*.25),Vector3.UP*.38,.035,.08,Color("5f6253"))
	for i in 7:
		var angle := float(i)*2.39996+_sample(cell,19)
		var tip := Vector3(cos(angle)*.29,height-.58+float(i%3)*.20,sin(angle)*.29)
		wood.branch(fork+Vector3.UP*float(i%3)*.23,tip,.052,.012,Color("747666"))
		var tint: Color = [Color("64794f"),Color("596e4b"),Color("768955"),Color("526b53")][i%4]
		if _presentation.biome == "crossing": tint = tint.lerp(Color("8c8a56"),.24)
		leaves.leaf_cluster(tip,Vector3(.32,.40,.32),angle,tint.darkened(.08))
		for j in 14:
			var phase := _sample(cell,i*411+j*29+77)*TAU
			var spread := sqrt(_sample(cell,i*79+j*13+21))*.28
			var point := tip+Vector3(cos(phase)*spread,(_sample(cell,i*41+j*73)-.5)*.55,sin(phase)*spread)
			leaves.leaf_card(point,Basis.from_euler(Vector3(phase*.7,angle,phase*.3)),.85+_sample(cell,j+78)*.24,tint.lightened(float(j%3)*.035))
	var trunk := _mesh(tree,"TrunkBranches",wood,_scenic_material("earth",.35))
	var canopy := _mesh(tree,"LeafCards",leaves,_scenic_material("meadow",.20))
	_register_occluder("tree",key,tree,[trunk,canopy])

func _authored_ruin(key: String) -> void:
	var cell := _cell(key)
	var ruin := _obstacle_root(key,"RuinedCurtain")
	var foundation := Builder.new()
	var stones := Builder.new()
	var directions: Array[Vector3] = []
	for other: String in _tiles:
		if other == key or _tiles[other].get("obstacle", "") != "wall": continue
		var delta := Layout.world(_cell(other))-Layout.world(cell)
		if delta.length() < 1.74: directions.append(delta.normalized())
	if directions.is_empty(): directions = [Vector3.RIGHT,Vector3.BACK]
	# Foundation and each curtain arm are clipped by construction to this hex.
	# Adjacent cells produce matching half-arms; bend cells become broken corners.
	foundation.stone(Vector3(0,.09,0),Vector3(1.35,.18,1.02),0,Color("929888"))
	var is_keep: bool = key in _presentation.keep
	var courses := 9 if is_keep else 5
	for row in courses:
		stones.stone(Vector3(0,.29+float(row)*.245,0),Vector3(.39,.23,.39),0,Color("b0b1a0").darkened(_sample(cell,row+41)*.08))
	for d in directions:
		var yaw := -atan2(d.z,d.x)
		for column in 3:
			var count := courses-int(_sample(cell,column+int(d.x*11)+85)*3)
			for row in count:
				var shade := _sample(cell,row*51+column*17+91)
				var p: Vector3 = d*(.19+float(column)*.24)+Vector3.UP*(.29+float(row)*.245)
				stones.stone(p,Vector3(.232,.23,.36),yaw,Color("b2b3a4").darkened(shade*.13))
	for i in 4:
		var angle := _sample(cell,i+791)*TAU
		stones.stone(Vector3(cos(angle)*.55,.095,sin(angle)*.55),Vector3(.21,.19,.17),angle,Color("969c8d"))
	var base := _mesh(ruin,"Foundation",foundation,_scenic_material("rock",.55))
	var masonry := _mesh(ruin,"BrokenCorners",stones,_scenic_material("rock",.55))
	_register_occluder("wall",key,ruin,[base,masonry])

func _authored_boulder(key: String) -> void:
	var rock := _obstacle_root(key,"StandingOutcrop")
	var stones := Organic.new()
	var cell := _cell(key)
	stones.boulder(Vector3(0,.61,0),Vector3(1.45,1.32,1.34),_sample(cell,621),Color("a3aaa0"))
	stones.boulder(Vector3(-.34,.23,.24),Vector3(.64,.53,.56),.8,Color("939b90"))
	var mesh := _mesh(rock,"RockMass",stones,_scenic_material("rock",.5))
	_register_occluder("boulder",key,rock,[mesh])

func _authored_landscape(keys: Array) -> void:
	var strata := StrataMesh.new()
	var gravel := Organic.new()
	var grass := Organic.new()
	var litter := Organic.new()
	for edge: Dictionary in cliff_edges:
		# A wide eroded face, not piles of tiny rocks or submerged detail.
		var a: Vector3 = edge.a
		var b: Vector3 = edge.b
		var outward := (Layout.world(edge.neighbor)-Layout.world(edge.cell)).normalized()
		var angle := atan2((b-a).z,(b-a).x)
		var low := maxf(edge.low,STREAM_Y-.05)
		var depth := minf(edge.high-low,1.3)
		if depth <= .06: continue
		var layers := 2 if depth > .45 else 1
		for layer in layers:
			var phase := _sample(edge.cell,layer+711)
			var p := a.lerp(b,.43+phase*.12)-outward*.12
			p.y = edge.high-.13-float(layer)*depth*.52
			strata.ledge(p,Vector3(1.75+phase*.25,.25+depth*.20,.50),-angle,phase,Color("a3aa9a").darkened(phase*.10))
	for key: String in keys:
		var tile: Dictionary = _tiles[key]
		if tile.get("blocked",false) or tile.terrain in ["water","deep_water"] or _bridge_keys.has(key): continue
		var cell := _cell(key)
		var center: Vector3 = world_anchors[key]
		var is_gravel: bool = tile.terrain in ["mud","rubble","rocks","shallow_water"]
		var count := 5 if is_gravel else (2 if tile.terrain == "forest" else (1 if _sample(cell,713) > .52 else 0))
		for i in count:
			var sample := _sample(cell,i*101+51)
			var angle := _sample(cell,i*19+761)*TAU
			var offset := Vector3(cos(angle)*.68,.008,sin(angle)*.68)
			if is_gravel:
				gravel.boulder(center+offset+Vector3.UP*.045,Vector3(.24+sample*.17,.09+sample*.035,.20+sample*.11),angle,Color("929a8c"))
				decorations.append({"tile":key,"kind":"gravel","offset":offset,"max_height":.12})
			elif tile.terrain == "forest":
				litter.leaf_litter(center+offset,angle,Color("777652"))
				decorations.append({"tile":key,"kind":"litter","offset":offset,"max_height":.03})
			elif not _road_keys.has(key):
				grass.grass_tuft(center+offset,.12+sample*.05,angle,Color("7b8b5d"))
				decorations.append({"tile":key,"kind":"grass","offset":offset,"max_height":.18})
	_mesh(_generated,"LayeredOutcrops",strata,_scenic_material("rock",.55))
	_mesh(_generated,"BankAndRuinGravel",gravel,_scenic_material("rock",.5))
	_mesh(_generated,"SparseGrasses",grass,_scenic_material("meadow",.25)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh(_generated,"ForestLitter",litter,_scenic_material("earth",.25)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _surface_height(cell: Vector2i) -> float:
	var key := "%d,%d" % [cell.x,cell.y]
	if _bridge_keys.has(key): return STREAM_BED
	if _tiles.has(key):
		if _tiles[key].terrain in ["water", "deep_water"]: return STREAM_BED
		return float(_tiles[key].height)*Layout.HEIGHT_STEP
	return STREAM_BED if _stream_cells.has(cell) else 0.0

func _backdrop_height(p: Vector3) -> float:
	var lo := Layout.world(_board_min)
	var hi := Layout.world(_board_max)
	var outside := maxf(maxf(lo.x-p.x-1.1,p.x-hi.x-1.1),maxf(lo.z-p.z-1.1,p.z-hi.z-1.1))
	return smoothstep(0.0,5.0,maxf(outside,0.0)) * (1.0 + sin(p.x*.19+p.z*.11)*.8 + sin(p.z*.29)*.35)
