extends RefCounted
## Stored geography version 3: two connected districts and an unroaded frontier.
const Small = preload("res://src/map_generator.gd")
const W = 116
const H = 60
const ORIGIN = Vector2(40,216)
const CELL = 16
static var canonical: Dictionary = {}
var cells: Array = []
var places: Array = []
var roads: Array = []
var paths: Array = []
var bridges: Array = []
var river: Array = []
var config: Dictionary = {}
var rng = RandomNumberGenerator.new()
var graph = AStarGrid2D.new()

static func point(p: Vector2i) -> Vector2:
	return ORIGIN+(Vector2(p)+Vector2.ONE*0.5)*CELL
static func cell(p: Vector2) -> Vector2i:
	return Vector2i((p-ORIGIN)/CELL)
static func packed(p: Vector2) -> Array:
	return [roundi(p.x),roundi(p.y)]
func rebuild() -> void:
	graph.region = Rect2i(0,0,W,H); graph.cell_size = Vector2(CELL,CELL); graph.offset = point(Vector2i.ZERO)
	graph.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES; graph.update()
	for y in H:
		for x in W:
			var at = Vector2i(x,y); var t: int = cells[y*W+x]
			graph.set_point_solid(at,t in [3,6]); graph.set_point_weight_scale(at,Small.COST[t])
func location(id: String) -> Dictionary:
	return places.filter(func(p):return p.id == id)[0]
func position(id: String) -> Vector2:
	var p = location(id); return Vector2(p.x,p.y)
func generate(seed_number: int, river_reach: bool = false) -> Dictionary:
	# Geography has its own stored seed domain; never rewrite the campaign seed.
	if seed_number > 999999999: return generate(1+posmod(seed_number-1,999999999),river_reach)
	rng.seed = seed_number ^ 0x41527
	cells.resize(W*H); cells.fill(0); places.clear(); roads.clear(); paths.clear(); bridges.clear(); river.clear()
	config = {"towns":{},"camps":{},"factions":{},"routes":[],"politics":{}}
	# Forest and hill belts beyond settled districts; streams remain inside their districts.
	for y in H:
		for x in W:
			if y < 15 or y >= 45:
				var wave = sin(x*0.17+seed_number%31)+cos(y*0.31+seed_number%17)
				cells[y*W+x] = 1 if wave > 0.35 else 2 if wave < -0.5 else 0
	for district in 2:
		var small = Small.new().generate(seed_number if district == 0 else 1+posmod(seed_number^0x547189,999999999))
		if river_reach and district == 0: preload("res://river_district/reach.gd").new().compose(small,seed_number)
		var prefix = "" if district == 0 else "east_"; var offset = Vector2(district*58*CELL,15*CELL)
		var ids = {}; var councils = {}
		for p in small.locations: ids[p.id] = prefix+p.id
		for f in small.world_config.factions: councils[f] = prefix+f
		for y in 30:
			for x in 58: cells[(y+15)*W+x+district*58] = small.terrain[y*58+x]
		for raw in small.locations:
			var p: Dictionary = raw.duplicate(true); p.id = ids[p.id]; p.x += int(offset.x); p.y += int(offset.y)
			if district == 1: p.name = "East "+p.name
			if p.kind == "discovery":
				p.guarded_by = ids.get(p.guarded_by,""); p.rumour = packed(Vector2(p.rumour[0],p.rumour[1])+offset)
			places.append(p)
		for road in small.roads: roads.append([ids[road[0]],ids[road[1]],road[2]])
		for road in small.road_paths: paths.append({"from":ids[road.from],"to":ids[road.to],"points":road.points.map(func(p):return packed(Vector2(p[0],p[1])+offset))})
		for b in small.bridges: bridges.append({"position":packed(Vector2(b.position[0],b.position[1])+offset),"vertical":b.vertical})
		for p in small.river: river.append(packed(Vector2(p[0],p[1])+offset))
		for id in small.world_config.towns:
			var t: Dictionary = small.world_config.towns[id].duplicate(true); t.owner = councils[t.owner]; t.name = location(ids[id]).name; t["market_role"] = id
			config.towns[ids[id]] = t
		for id in small.world_config.factions:
			var f: Dictionary = small.world_config.factions[id].duplicate(true); f.town = ids[f.town]; f.rival = councils[f.rival]; f.name = config.towns[f.town].name+" Council"
			config.factions[councils[id]] = f
		for id in small.world_config.camps:
			var c: Dictionary = small.world_config.camps[id].duplicate(true); c.raid_target = ids[c.raid_target]; c.name = location(ids[id]).name; c["map"] = id; c["remote"] = false
			config.camps[ids[id]] = c
		for raw in small.world_config.routes:
			var r: Dictionary = raw.duplicate(true); r.id = prefix+r.id; r.path = r.path.map(func(id):return ids[id]); config.routes.append(r)
		config.politics = small.world_config.politics.duplicate(true)
	# Open shared district boundaries without roads; all crossings remain physical.
	for y in range(13,47):
		for x in range(56,60):
			if cells[y*W+x] == 6: cells[y*W+x] = 2
	rebuild()
	for index in 2:
		var from = ["stonecross","dunmere"][index]; var to = ["east_ashwick","east_dunmere"][index]
		var trail = graph.get_id_path(cell(position(from)),cell(position(to)))
		if trail.is_empty():
			carve_connection(cell(position(from)),cell(position(to))); rebuild(); trail = graph.get_id_path(cell(position(from)),cell(position(to)))
		var at: Vector2i = trail[trail.size()/2]
		# Pick a road waypoint separated from existing settlements and sites.
		var best = -INF
		for candidate in trail:
			var p = point(candidate); var spacing = INF
			for place in places: spacing = minf(spacing,p.distance_to(Vector2(place.x,place.y)))
			var score = spacing-absf(float(trail.find(candidate))-trail.size()*0.5)*0.5
			if score > best: best = score; at = candidate
		var id = "pass_%d" % index; add_camp(id,"Border Road Hideout" if index == 0 else "High Pass Outlaws",at,"forest",2,to,false)
		add_road(from,id); add_road(id,to); rebuild()
		config.routes.append({"id":"border_%d" % index,"path":[from,id,to],"days":[2,2],"cargo":16,"period":5})
		config.routes.append({"id":"border_return_%d" % index,"path":[to,id,from],"days":[2,2],"cargo":16,"period":5})
	# Two to four hidden camps, deliberately away from roads and settlements.
	for index in 2+posmod(seed_number,3):
		var choices: Array = []
		for y in range(3,H-3):
			if y in range(13,47): continue
			for x in range(5,W-5):
				var at = Vector2i(x,y); var p = point(at)
				if graph.is_point_solid(at) or places.any(func(place):return p.distance_to(Vector2(place.x,place.y)) < (300 if place.kind == "town" else 180)): continue
				choices.append(at)
		var chosen: Vector2i = choices[rng.randi_range(0,choices.size()-1)]
		var towns = config.towns.keys(); towns.sort_custom(func(a,b):return position(a).distance_to(point(chosen)) < position(b).distance_to(point(chosen)))
		if graph.get_id_path(cell(position(towns[0])),chosen).is_empty(): carve_connection(cell(position(towns[0])),chosen); rebuild()
		add_camp("wild_%d" % index,["Pinewatch Refuge","Broken Crown Hold","Wolf's Hollow","Black Crag Stockade"][index],chosen,"forest" if index%2 == 0 else "ridge",2 if index%2 == 0 else 3,towns[0],true)
	for id in config.camps:
		config.camps[id]["neighbours"] = config.camps.keys().filter(func(other):return other != id and position(other).distance_to(position(id)) <= 480)
	# Stable one-to-one assignment of road bands to six independent farms.
	for prefix in ["","east_"]:
		config.towns[prefix+"ashwick"]["farm_camp"] = prefix+"ford"
		config.towns[prefix+"stonecross"]["farm_camp"] = prefix+"forest"
		config.towns[prefix+"dunmere"]["farm_camp"] = prefix+"ridge"
	var result = {"generator":3,"seed":seed_number,"name":location("ashwick").name+" Borderlands","width":W,"height":H,"cell_size":CELL,"origin":[40,216],"terrain":cells.duplicate(),"locations":places.duplicate(true),"roads":roads.duplicate(true),"road_paths":paths.duplicate(true),"bridges":bridges.duplicate(true),"river":river.duplicate(true),"world_config":config.duplicate(true)}
	if river_reach: result["river_district"] = 1
	if canonical.size() >= 16: canonical.erase(canonical.keys()[0])
	canonical[Vector2i(seed_number,int(river_reach))] = result.duplicate(true)
	return result
func add_camp(id: String, title: String, at: Vector2i, role: String, strength: int, town: String, remote: bool) -> void:
	var p = point(at); cells[at.y*W+at.x] = 1 if remote and role == "forest" else 2 if remote else cells[at.y*W+at.x]
	places.append({"id":id,"name":title,"kind":"camp","map":role,"objective":"eliminate","x":int(p.x),"y":int(p.y),"description":"An isolated stronghold beyond the settled roads." if remote else "A band threatens this trade corridor."})
	config.camps[id] = {"name":title,"strength":strength,"raid_target":town,"map":role,"remote":remote}
func carve_connection(a: Vector2i, b: Vector2i) -> void:
	var at = a
	while at != b:
		for dy in range(-1,2):
			for dx in range(-1,2):
				var p = at+Vector2i(dx,dy)
				if Rect2i(0,0,W,H).has_point(p) and cells[p.y*W+p.x] in [3,6]: cells[p.y*W+p.x] = 0
		if at.x != b.x: at.x += signi(b.x-at.x)
		elif at.y != b.y: at.y += signi(b.y-at.y)
func add_road(from: String, to: String) -> void:
	var trail = graph.get_id_path(cell(position(from)),cell(position(to))); var points: Array = []
	for at in trail:
		cells[at.y*W+at.x] = 5 if cells[at.y*W+at.x] == 5 else 4; points.append(packed(point(at)))
	roads.append([from,to,2]); paths.append({"from":from,"to":to,"points":points})

func validate(raw: Variant) -> bool:
	# Versioned geography is immutable. Exact regeneration validates every road,
	# ID, economy, obstacle and loot definition, without mutating the running world.
	if not raw is Dictionary or raw.get("generator") != 3 or not raw.get("seed") is int or raw.seed < 1 or raw.seed > 999999999: return false
	# Missing discriminator means exact predecessor geography, never newest.
	var reach: bool = raw.has("river_district")
	if reach and (not raw.river_district is int or raw.river_district != 1): return false
	var key := Vector2i(raw.seed,int(reach))
	if not canonical.has(key): generate(raw.seed,reach)
	return raw == canonical[key]
