extends "res://prototype/terrain.gd"
## Presentation only. Batched continuous terrain; no physics bodies or rule writes.
const Paint = preload("res://visual_slice/materials/palette.gd")
const Organic = preload("res://visual_slice/terrain_assets/organic_mesh.gd")
const STREAM_Y := -0.62
const STREAM_BED := -1.42
var world_anchors: Dictionary = {}
var bridge_clear_width := 1.02
var ground_batches: Array[MeshInstance3D] = []
var cliff_edges: Array[Dictionary] = []
var interior_skirt_count := 0
var geometry_stats: Dictionary = {}
var backdrop_bounds := AABB()
var _tiles: Dictionary = {}

func build(battle) -> void:
	if is_instance_valid(_generated):
		remove_child(_generated)
		_generated.free()
	_generated = Node3D.new()
	_generated.name = "PaintedCrossing"
	add_child(_generated)
	tile_surfaces.clear()
	world_anchors.clear()
	water_surfaces.clear()
	bridge_roots.clear()
	occluders.clear()
	faded_occluders.clear()
	decorations.clear()
	ground_batches.clear()
	cliff_edges.clear()
	_tiles = battle.tiles
	var tops := Builder.new()
	var cliffs := Builder.new()
	var keys: Array = _tiles.keys()
	keys.sort()
	for key: String in keys:
		var cell := _cell(key)
		var center := Layout.world(cell, float(_tiles[key].height))
		var anchor := Node3D.new()
		anchor.name = "Standing_%s" % key.replace(",", "_")
		anchor.position = center
		_generated.add_child(anchor)
		tile_surfaces[key] = anchor
		world_anchors[key] = center
	# Offboard cells are mesh geometry only: never added to battle.tiles/picking.
	for r in range(-6,15):
		for q in range(-6,19):
			var cell := Vector2i(q,r)
			var y := _surface_height(cell)
			var center := Layout.world(cell)
			center.y = y
			var ring := Layout.corners(cell)
			for i in 6:
				ring[i].y = y
				if not _tiles.has("%d,%d" % [q,r]) and q != 6:
					ring[i].y += _backdrop_height(ring[i])
			if not _tiles.has("%d,%d" % [q,r]) and q != 6:
				center.y += _backdrop_height(center)
			for i in 6:
				var a: Vector3 = ring[i]
				var b: Vector3 = ring[(i+1)%6]
				tops.triangle(center,a,b,Color.WHITE)
				var midpoint := (a+b)*.5
				var outward := Vector3(midpoint.x-center.x,0,midpoint.z-center.z).normalized()
				var neighbor := Layout.from_world(midpoint+outward*.05)
				var low := _surface_height(neighbor)
				if y > low + .001:
					cliffs.quad(a,Vector3(a.x,low,a.z),Vector3(b.x,low,b.z),b,Color("b8b7aa"))
					cliff_edges.append({"cell":cell,"neighbor":neighbor,"a":a,"b":b,"high":y,"low":low})
	var ground := _mesh(_generated,"ContinuousPaintedGround",tops,Paint.ground())
	ground_batches.append(ground)
	_mesh(_generated,"ExposedRockFaces",cliffs,Paint.painted("rock",.7))
	backdrop_bounds = ground.mesh.get_aabb()
	for key: String in keys:
		if _tiles[key].terrain == "wall": _painted_ruin(key,_cell(key),world_anchors[key])
		elif _tiles[key].terrain == "forest": _painted_tree(key,_cell(key),world_anchors[key])
	_build_stream()
	if _tiles.has("6,4") and _tiles["6,4"].terrain == "ford":
		_painted_bridge(world_anchors["6,4"])
	_landscape_dressing(keys)
	_measure_geometry()

func _backdrop_height(p: Vector3) -> float:
	var outside := maxf(maxf(-p.x-2.0,p.x-23.0),maxf(-p.z-2.0,p.z-14.0))
	var distance := maxf(outside,0.0)
	return smoothstep(0.0,5.0,distance)*(1.0+sin(p.x*.27+p.z*.23)*.65+sin(p.z*.51)*.30)

func _painted_tree(key: String, cell: Vector2i, center: Vector3) -> void:
	var tree := Node3D.new()
	tree.name = "BranchedOak_%s" % key.replace(",","_")
	tree.position = center
	_generated.add_child(tree)
	var wood := Organic.new()
	var leaves := Organic.new()
	var foot := Vector3(.57,0,-.27)
	var fork := foot+Vector3(-.09,1.05,.02)
	var leader := foot+Vector3(-.23,2.40,.02)
	wood.branch(foot,fork,.095,.07,Color("635440"))
	wood.branch(fork,leader,.07,.016,Color("6f5a40"))
	for i in 5:
		var angle := float(i)*TAU/5.0
		wood.branch(foot+Vector3(cos(angle)*.10,.015,sin(angle)*.10),foot+Vector3.UP*.26,.021,.042,Color("584a38"))
	for i in 10:
		var angle := float(i)*2.39996+_sample(cell,141)
		var length := .52+_sample(cell,i+244)*.36
		var tip := foot+Vector3(cos(angle)*length,1.78+float(i%4)*.24,sin(angle)*length*.85)
		var start := fork+Vector3.UP*float(i%4)*.17
		wood.branch(start,tip,.041,.010,Color("746045"))
		for twig in 3:
			var twig_angle := angle+float(twig-1)*.65
			var end := tip+Vector3(cos(twig_angle)*.25,.18+float(twig%2)*.12,sin(twig_angle)*.23)
			wood.branch(tip-Vector3.UP*.05,end,.012,.003,Color("846b48"))
		for j in 24:
			var phase := _sample(cell,i*487+j*31+93)*TAU
			var spread := sqrt(_sample(cell,i*157+j*41+187))*.42
			var point := tip+Vector3(cos(phase)*spread,(_sample(cell,i*41+j*63+79)-.5)*.61,sin(phase)*spread*.85)
			var tint: Color=[Color("c09243"),Color("b47c35"),Color("9f883e"),Color("cb9e4c")][(i+j)%4]
			leaves.leaf_card(point,Basis.from_euler(Vector3(phase*.72,phase,float(j%3)*.5)),.72+_sample(cell,j+i*83)*.55,tint)
	var trunk := _mesh(tree,"TrunkBranches",wood,Paint.painted("earth",1.9))
	var leaf_material := Paint.painted("meadow",1.1,.009)
	leaf_material.set_shader_parameter("painted_mix",.38)
	var canopy := _mesh(tree,"LeafCards",leaves,leaf_material)
	_register_occluder("tree",key,tree,[trunk,canopy])

func _landscape_dressing(keys: Array) -> void:
	var rocks := Organic.new()
	var grasses := Organic.new()
	var litter := Organic.new()
	var moss := Organic.new()
	var foam := Organic.new()
	for key: String in keys:
		if _tiles[key].terrain in ["water","ford"]: continue
		var cell := _cell(key)
		var center: Vector3 = world_anchors[key]
		# Uneven clusters, not identical per-hex rings. Nothing tall in a clear lane.
		var count := 6+int(_sample(cell,711)*7)
		for i in count:
			var angle := _sample(cell,i*37+123)*TAU
			var radius := .66+_sample(cell,i*71+19)*.13
			var offset := Vector3(cos(angle)*radius,.009,sin(angle)*radius)
			var shade := _sample(cell,i*45+919)
			var height := .09+shade*.12
			grasses.grass_tuft(center+offset,height,angle,Color("aa955c").darkened(shade*.17))
			decorations.append({"tile":key,"kind":"grass","offset":offset,"max_height":.22})
			if i%3 == 0:
				rocks.boulder(center+offset+Vector3.UP*.018,Vector3(.11+shade*.10,.045+shade*.035,.10),angle,Color("aaa793"))
				litter.leaf_litter(center+offset,angle,Color("b28843"))
			if i%4 == 0:
				moss.leaf_card(center+offset+Vector3.UP*.02,Basis(Vector3.UP,angle),.65,Color("76804b"))
	# Irregular rock strata interrupt the height-step and zigzag bank silhouettes.
	for edge: Dictionary in cliff_edges:
		var a: Vector3 = edge.a
		var b: Vector3 = edge.b
		var along := (b-a).normalized()
		var toward := (Layout.world(edge.neighbor)-Layout.world(edge.cell)).normalized()
		var cell: Vector2i = edge.cell
		var layers := clampi(int(ceil((edge.high-maxf(edge.low,STREAM_Y-.09))/.26)),1,3)
		for layer in layers:
			for i in 2:
				var sample := _sample(cell,layer*73+i*47+511)
				var point := a.lerp(b,.24+float(i)*.52)-toward*(.07+sample*.05)
				point.y = edge.high-.14-float(layer)*.245
				rocks.boulder(point,Vector3(.50+sample*.21,.28,.44+sample*.12),sample*TAU,Color("b4b3a2").darkened(sample*.17))
		if edge.low < -1.0:
			for i in 3:
				var phase := _sample(cell,i*137+588)
				var p := a.lerp(b,.12+float(i)*.29)+toward*(.15+phase*.12)
				p.y=STREAM_Y+.016
				var u := along*(.10+phase*.10)
				var v := toward*.018
				foam.quad(p-u-v,p-u+v,p+u+v,p+u-v,Color.WHITE)
	# Low, purely nonplayable scrub carries the environment beyond board limits.
	for r in range(-4,13):
		for q in range(-4,17):
			var cell := Vector2i(q,r)
			if _tiles.has("%d,%d" % [q,r]) or q == 6 or _sample(cell,872) < .45: continue
			var center := Layout.world(cell)
			center.y = _backdrop_height(center)
			for i in 5:
				var angle := _sample(cell,i*127+689)*TAU
				var p := center+Vector3(cos(angle)*.6,.01,sin(angle)*.6)
				grasses.grass_tuft(p,.17+_sample(cell,i+77)*.22,angle,Color("97844f"))
				if i == 0: rocks.boulder(p+Vector3.UP*.06,Vector3(.29,.16,.25),angle,Color("a5a28c"))
				if i < 2:
					for j in 3:
						var t := angle+float(j)*2.4
						var leaf := p+Vector3(cos(t)*.13,.08+float(j%3)*.075,sin(t)*.13)
						moss.leaf_card(leaf,Basis.from_euler(Vector3(t,angle,t*.3)),.9,Color("878951"))
	_mesh(_generated,"LayeredOutcrops",rocks,Paint.painted("rock",1.15))
	var grass_material := Paint.painted("meadow",1.8,.012)
	grass_material.set_shader_parameter("painted_mix",.40)
	_mesh(_generated,"AutumnGrasses",grasses,grass_material).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh(_generated,"FallenLeaves",litter,grass_material).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh(_generated,"MossAndLowScrub",moss,Paint.painted("meadow",1.7,.002)).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var foam_material := ShaderMaterial.new()
	foam_material.shader=preload("res://visual_slice/materials/foam.gdshader")
	_mesh(_generated,"BankFoam",foam,foam_material).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _measure_geometry() -> void:
	geometry_stats={"triangles":0,"instances":0,"surfaces":0}
	var queue: Array[Node]=[_generated]
	while not queue.is_empty():
		var node: Node=queue.pop_back()
		for child: Node in node.get_children(): queue.append(child)
		if node is MeshInstance3D:
			geometry_stats.instances+=1
			for s in node.mesh.get_surface_count():
				geometry_stats.surfaces+=1
				var arrays: Array=node.mesh.surface_get_arrays(s)
				var indices=arrays[Mesh.ARRAY_INDEX]
				geometry_stats.triangles+=(indices.size() if indices != null and not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size())/3

func _painted_ruin(key: String, cell: Vector2i, center: Vector3) -> void:
	var ruin := Node3D.new()
	ruin.name = "Keep_%s" % key.replace(",","_")
	ruin.position = center
	_generated.add_child(ruin)
	var stones := Builder.new()
	var meshes: Array = []
	var keep := key in ["8,2","9,2"]
	if keep:
		# Broken curtain tower. All tall vertices remain in these real wall hexes.
		for row in 4:
			for column in 5:
				var variation := _sample(cell,row*31+column)
				stones.stone(Vector3(-.646+column*.323,.12+row*.245,(variation-.5)*.025),Vector3(.310,.232,.79),0,Color("c2c0ac").darkened(variation*.12))
		for side: float in [-1.0,1.0]:
			for row in 6:
				var variation := _sample(cell,row*19+int(side)+11)
				stones.stone(Vector3(side*.595,1.10+row*.24,0),Vector3(.43,.225,.77),0,Color("bcbca9").darkened(variation*.10))
		for column in 5:
			var courses := (4 if key == "8,2" else 2)+int(_sample(cell,column+103)*2)
			for row in courses:
				var variance := _sample(cell,column*71+row+311)
				stones.stone(Vector3(-.646+column*.323,2.61+row*.233,(variance-.5)*.035),Vector3(.307,.217,.76-variance*.10),0,Color("c6c3b1").darkened(variance*.14))
		var arch := Builder.new()
		for i in 11:
			if i == 0 and key == "8,2": continue
			var a := PI*float(i)/11.0+.018
			var b := PI*float(i+1)/11.0-.018
			arch.extrude_quad(PackedVector2Array([
				Vector2(cos(a)*.57,1.95+sin(a)*.55),Vector2(cos(b)*.57,1.95+sin(b)*.55),
				Vector2(cos(b)*.345,1.95+sin(b)*.35),Vector2(cos(a)*.345,1.95+sin(a)*.35)]),-.41,.41,Color("c9c4b1"))
		meshes.append(_mesh(ruin,"WindowArch",arch,Paint.painted("rock",1.05)))
		var detail := Builder.new()
		if key == "9,2":
			# Recessed weathered timber door on the lower wall, not a new lane.
			for i in 6:
				detail.stone(Vector3(-.25+float(i)*.10,.45,.424),Vector3(.093,.86-float(i%2)*.035,.055),0,Color("635039"))
			for y: float in [.23,.68]: detail.stone(Vector3(0,y,.466),Vector3(.60,.06,.04),0,Color("3b3e36"))
			detail.branch(Vector3(.13,.40,.49),Vector3(.13,.49,.49),.025,.025,Color("272c27"))
			meshes.append(_mesh(ruin,"TimberDoor",detail,Paint.painted("earth",1.8)))
		else:
			# Torn cloth is dimensional geometry; shader moves it slightly in wind.
			var x := -.59
			for i in 5:
				var y := 1.92-float(i)*.23
				var z := .445+sin(float(i)*1.7)*.025
				detail.quad(Vector3(x-.13,y,z),Vector3(x-.13,y-.24,z+.02),Vector3(x+.13,y-.24,z+.02),Vector3(x+.13,y,z),Color("753b2b"))
			for i in 3:
				var left := x-.13+float(i)*.086
				detail.triangle(Vector3(left,.78,.46),Vector3(left+.04,.57+float(i%2)*.12,.48),Vector3(left+.082,.78,.46),Color("713727"))
			detail.quad(Vector3(x-.022,1.78,.481),Vector3(x-.022,1.13,.481),Vector3(x+.022,1.13,.481),Vector3(x+.022,1.78,.481),Color("c2ae75"))
			meshes.append(_mesh(ruin,"TornBanner",detail,Paint.painted("earth",1.0,.003)))
	else:
		for column in 5:
			var courses := 3+int(_sample(cell,column+51)*4)
			for row in courses:
				var variation := _sample(cell,column*31+row)
				stones.stone(Vector3(-.59+column*.295,.118+row*.235,(variation-.5)*.05),Vector3(.28,.22,.47),0,Color("b6b5a2").darkened(variation*.13))
		for i in 4:
			stones.stone(Vector3(-.48+i*.30,.09,.43),Vector3(.23,.18,.19),_sample(cell,i+981)*.8,Color("a3a390"))
	meshes.push_front(_mesh(ruin,"Masonry",stones,Paint.painted("rock",1.0)))
	_register_occluder("wall",key,ruin,meshes)

func _build_stream() -> void:
	var flow := Builder.new()
	for r in range(-6,15):
		var cell := Vector2i(6,r)
		var key := "6,%d" % r
		if _tiles.has(key) and not _tiles[key].terrain in ["water","ford"]: continue
		var center := Layout.world(cell)
		center.y = STREAM_Y
		var ring := Layout.corners(cell)
		for i in 6: ring[i].y = STREAM_Y
		for i in 6: flow.triangle(center,ring[i],ring[(i+1)%6],Color.WHITE)
	var material := ShaderMaterial.new()
	material.shader = preload("res://visual_slice/materials/water.gdshader")
	material.set_shader_parameter("paint",Paint.texture("rock"))
	var mesh := _mesh(_generated,"ContinuousFlowingStream",flow,material)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_surfaces.append(mesh)

func _painted_bridge(center: Vector3) -> void:
	var bridge := Node3D.new()
	bridge.name = "StoneBridge_6_4"
	bridge.position = center
	_generated.add_child(bridge)
	bridge_roots.append(bridge)
	var stones := Builder.new()
	# The arch is a ring, never a filled disk: real water/air is visible beneath.
	for i in 15:
		var a := PI*float(i)/15.0+.010
		var b := PI*float(i+1)/15.0-.010
		stones.extrude_quad(PackedVector2Array([
			Vector2(cos(a)*1.06,-1.20+sin(a)*1.07),
			Vector2(cos(b)*1.06,-1.20+sin(b)*1.07),
			Vector2(cos(b)*.78,-1.20+sin(b)*.96),
			Vector2(cos(a)*.78,-1.20+sin(a)*.96)]),-.64,.64,Color("b8b6a5").lightened(float(i%3)*.025))
	# Abutments sit under their banks, below the playable surface.
	for side: float in [-1.0,1.0]:
		for zside: float in [-1.0,1.0]:
			for row in 3:
				stones.stone(Vector3(side*.93,-.80+float(row)*.25,zside*.52),Vector3(.26,.23,.25),side*.03,Color("a7a79a"))
		for i in 6:
			var x := -.85+float(i)*.34
			stones.stone(Vector3(x,.06,side*.62),Vector3(.326,.12,.20),float(i%2)*.018,Color("bebaa7"))
		for i in 4:
			# Small dry-stone spandrels, clear of the central opening.
			var x := -.78+float(i)*.52
			if absf(x) > .5:
				stones.stone(Vector3(x,-.14,side*.54),Vector3(.27,.20,.18),0,Color("b3b1a0"))
	_mesh(bridge,"ArchMasonry",stones,Paint.painted("rock",1.1))
	var pavers := Builder.new()
	for row in 5:
		for column in 7:
			var shade := _sample(Vector2i(column,row),904)
			pavers.stone(Vector3(-.90+float(column)*.30,-.024,-.44+float(row)*.22),Vector3(.292,.048,.212),0,Color("c2bcaa").darkened(shade*.10))
	_mesh(bridge,"FloorPavers",pavers,Paint.painted("paving",1.0))

func _cell(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]),int(parts[1]))

func _surface_height(cell: Vector2i) -> float:
	var key := "%d,%d" % [cell.x,cell.y]
	if _tiles.has(key):
		if _tiles[key].terrain in ["water","ford"]: return STREAM_BED
		return float(_tiles[key].height)*Layout.HEIGHT_STEP
	return STREAM_BED if cell.x == 6 else 0.0

func _mesh(parent: Node3D, label: String, builder, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = builder.finish()
	instance.material_override = material
	parent.add_child(instance)
	return instance
