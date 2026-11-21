extends RefCounted
## Versioned, deterministic geography. Generated definitions are saved in full.
## Stable role IDs bridge the existing three-town company/economy providers.
const VERSION = 2
const W = 58
const H = 30
const ORIGIN = Vector2(40,216)
const CELL = 16
const TOWNS = ["ashwick","stonecross","dunmere"]
const CAMPS = ["ford","forest","ridge"]
const TERRAIN = ["plains","forest","hills","water","road","bridge","mountains"]
const COST = [1.35,2.2,1.8,100.0,1.0,1.0,100.0]
var rng = RandomNumberGenerator.new()
var cells: Array = []
var graph = AStarGrid2D.new()
var landmarks: Array = []
var river: Array = []
var bridges: Array = []
var road_paths: Array = []
var road_edges: Array = []

static func point(c: Vector2i) -> Vector2:
	return ORIGIN+(Vector2(c)+Vector2.ONE*0.5)*CELL
static func cell(p: Vector2) -> Vector2i:
	return Vector2i(floori((p.x-ORIGIN.x)/CELL),floori((p.y-ORIGIN.y)/CELL))
static func packed(p: Vector2) -> Array:
	return [roundi(p.x),roundi(p.y)]
func inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < W and p.y < H
func value(p: Vector2i) -> int:
	return int(cells[p.y*W+p.x]) if inside(p) else 6
func walkable(p: Vector2i) -> bool:
	return inside(p) and value(p) not in [3,6]
func put(p: Vector2i, t: int) -> void:
	if inside(p): cells[p.y*W+p.x] = t
func reset_graph() -> void:
	graph.region = Rect2i(0,0,W,H); graph.cell_size = Vector2(CELL,CELL); graph.offset = ORIGIN+Vector2.ONE*CELL/2
	graph.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES; graph.update()
	for y in H:
		for x in W:
			var c = Vector2i(x,y)
			graph.set_point_solid(c,not walkable(c)); graph.set_point_weight_scale(c,COST[value(c)])

func generate(seed_number: int) -> Dictionary:
	# Local RNG only: map generation never consumes soldier/combat randomness.
	rng.seed = maxi(1,seed_number)^0x35A791
	cells.clear(); cells.resize(W*H); cells.fill(0)
	landmarks.clear(); river.clear(); bridges.clear(); road_paths.clear(); road_edges.clear()
	for terrain_type in [1,2,6]:
		for i in (8 if terrain_type != 6 else 3):
			var centre = Vector2(rng.randf_range(2,W-3),rng.randf_range(1,H-2))
			var radius = Vector2(rng.randf_range(3,9),rng.randf_range(2,5))
			if terrain_type == 6:
				centre.y = rng.randf_range(0,3) if i%2 == 0 else rng.randf_range(H-4,H-1)
				radius *= 0.75
			for y in H:
				for x in W:
					var d = (Vector2(x,y)-centre)/radius
					if d.length_squared() < rng.randf_range(0.75,1.2): put(Vector2i(x,y),terrain_type)
	var vertical = rng.randi_range(0,1) == 0
	var length = H if vertical else W
	var across = W if vertical else H
	var middle = across*0.5+rng.randf_range(-across*0.13,across*0.13)
	var bend = rng.randf_range(1.8,4.0)
	var phase = rng.randf_range(0,TAU)
	var rows: Array = []
	for i in length:
		var n = clampi(roundi(middle+sin(float(i)/length*TAU+phase)*bend),4,across-5)
		rows.append(n)
		for j in range(n-1,n+2): put(Vector2i(j,i) if vertical else Vector2i(i,j),3)
		river.append(packed(point(Vector2i(n,i) if vertical else Vector2i(i,n))))
	for fraction in [0.27,0.73]:
		var at = clampi(roundi(length*fraction)+rng.randi_range(-2,2),3,length-4)
		var n: int = rows[at]
		for a in range(at-1,at+2):
			for b in range(n-4,n+5):
				var c = Vector2i(b,a) if vertical else Vector2i(a,b)
				if value(c) == 6: put(c,2)
		for b in range(n-2,n+3):
			var c = Vector2i(b,at) if vertical else Vector2i(at,b)
			put(c,5 if value(c) == 3 else 4)
		bridges.append({"position":packed(point(Vector2i(n,at) if vertical else Vector2i(at,n))),"vertical":not vertical})
	reset_graph()
	var town_points: Array = []
	var names = town_names()
	for i in 3:
		var chosen = select_town(town_points,i)
		town_points.append(chosen)
		var role: String = ["Farming town","Market town","Mining town"][i]
		landmarks.append({"id":TOWNS[i],"name":names[i],"kind":"town","x":int(point(chosen).x),"y":int(point(chosen).y),"role":role,"description":role+". Provisions, work and recruits are available within its walls."})
		# Habitable clearings; no isolated settlement is created on an obstacle.
		for y in range(chosen.y-1,chosen.y+2):
			for x in range(chosen.x-1,chosen.x+2):
				if value(Vector2i(x,y)) not in [3,5]: put(Vector2i(x,y),0 if i != 2 else 2)
	reset_graph()
	var links = [[0,1],[2,1],[0,2]]
	for i in 3:
		var link: Array = links[i]
		var a: Vector2i = town_points[link[0]]
		var b: Vector2i = town_points[link[1]]
		var trail = graph.get_id_path(a,b)
		var camp = select_camp(trail,town_points,i)
		var title = ["Crossing Outlaws","Woodland Hideout","Deserter Encampment"][i]
		landmarks.append({"id":CAMPS[i],"name":title,"kind":"camp","x":int(point(camp).x),"y":int(point(camp).y),"map":CAMPS[i],"objective":["hold","eliminate","defend"][i],"description":"A band threatens the nearby trade road. Destroy it to restore safe passage."})
		add_road(TOWNS[link[0]],CAMPS[i],a,camp)
		add_road(CAMPS[i],TOWNS[link[1]],camp,b)
		reset_graph()
	for i in 3:
		var chosen = select_discovery(town_points[0],i)
		var p = point(chosen)
		var kinds = ["watchtower","ruin","cave"]
		var site_names = ["Old Signal Tower","Forgotten Wayside","Smuggler's Hollow"]
		var descriptions = ["The broken stair still leads above the trees. Surveying it may reveal the surrounding country.","An abandoned roadside refuge. Someone left stores beneath the fallen roof.","A rocky hollow used by the nearby deserters. Their camp controls access to the cache."]
		var reward = {"crowns":rng.randi_range(20,50),"food":rng.randi_range(6,14),"tools":rng.randi_range(3,7),"ammunition":rng.randi_range(5,12)}
		var rumour = p+Vector2(rng.randi_range(-36,36),rng.randi_range(-32,32))
		# A rumour is an approximate, reachable search area, not a click into water.
		if not walkable(cell(rumour)): rumour = p+Vector2(5,5)
		landmarks.append({"id":"discovery_%d" % i,"name":site_names[i],"kind":"discovery","feature":kinds[i],"x":int(p.x),"y":int(p.y),"description":descriptions[i],"guarded_by":"ridge" if i == 2 else "","search_hours":2+i,"loot":reward,"rumour":[roundi(rumour.x),roundi(rumour.y)]})
	var out = {"generator":VERSION,"seed":maxi(1,seed_number),"name":names[0]+" March","width":W,"height":H,"cell_size":CELL,"origin":[40,216],"terrain":cells.duplicate(),"river":river.duplicate(true),"bridges":bridges.duplicate(true),"locations":landmarks.duplicate(true),"roads":road_edges.duplicate(true),"road_paths":road_paths.duplicate(true)}
	out["world_config"] = economy(out)
	return out

func town_names() -> Array:
	var first = ["Alder","Briar","Grey","Oak","Raven","Moss","Ash","Red","Hollow","Stone","West","North"]
	var last = ["ford","wick","mere","bridge","haven","cross","stead","fall"]
	var out: Array = []
	while out.size() < 3:
		var n: String = first[rng.randi_range(0,first.size()-1)]+last[rng.randi_range(0,last.size()-1)]
		if not n in out: out.append(n)
	return out

func select_town(others: Array, index: int) -> Vector2i:
	var best = Vector2i(8,10)
	var score = -INF
	# Broad sample plus deterministic scan fallback; candidates must share land access.
	for y in range(6,24):
		for x in range(6,52):
			var c = Vector2i(x,y)
			if not walkable(c) or value(c) in [4,5]: continue
			if not others.is_empty() and graph.get_id_path(others[0],c).is_empty(): continue
			var spacing = 40.0
			for p in others: spacing = minf(spacing,Vector2(c).distance_to(Vector2(p)))
			var river_distance = 99.0
			for p in river: river_distance = minf(river_distance,point(c).distance_to(Vector2(p[0],p[1]))/CELL)
			if river_distance < 3: continue
			var merit = rng.randf_range(0,8)+(spacing*1.4 if not others.is_empty() else 0)-absf(river_distance-8)*0.25
			if value(c) == (2 if index == 2 else 0): merit += 3
			if merit > score: score = merit; best = c
	return best

func select_camp(trail: Array[Vector2i], towns: Array, index: int) -> Vector2i:
	var best: Vector2i = trail[mini(10,trail.size()-1)] if index == 0 else trail[trail.size()/2]
	var score = -INF
	# The first job lives on the homeward stretch, before the far-bank threats.
	# Definitions remain stored in saves; version-one worlds keep their geography.
	var candidates = trail.slice(5,mini(15,trail.size()-1)) if index == 0 else trail
	for at in candidates:
		for dy in range(-3,4):
			for dx in range(-3,4):
				var c = at+Vector2i(dx,dy)
				if not walkable(c) or c.x < 5 or c.x > 52 or c.y < 6 or c.y > 24: continue
				if graph.get_id_path(at,c).is_empty(): continue
				var spacing = INF
				for p in towns: spacing = minf(spacing,point(c).distance_to(point(p)))
				for p in landmarks.filter(func(n): return n.kind == "camp"): spacing = minf(spacing,point(c).distance_to(Vector2(p.x,p.y)))
				var anchor = trail[mini(10,trail.size()-1)] if index == 0 else trail[trail.size()/2]
				var merit = minf(spacing,160)*2-point(c).distance_to(point(anchor))*0.25+rng.randf_range(0,12)
				if index == 0: merit -= maxf(0,point(c).distance_to(point(towns[0]))-225)*4
				if value(c) == (1 if index == 1 else 2 if index == 2 else 5): merit += 12
				if merit > score:
					if index == 0:
						# Nearby across a river can still mean a long detour. Bound
						# the actual road, not only the straight-line separation.
						var home_path = graph.get_id_path(towns[0],c)
						var road_length = 0.0
						for j in range(1,home_path.size()): road_length += point(home_path[j-1]).distance_to(point(home_path[j]))
						if home_path.is_empty() or road_length > 12.0*24.0: continue
					score = merit; best = c
	return best

func select_discovery(start: Vector2i, index: int) -> Vector2i:
	var best = start
	var score = -INF
	for y in range(5,26):
		for x in range(5,53):
			var c = Vector2i(x,y)
			if not walkable(c) or value(c) in [4,5] or graph.get_id_path(start,c).is_empty(): continue
			var spacing = INF
			for p in landmarks: spacing = minf(spacing,point(c).distance_to(Vector2(p.x,p.y)))
			var merit = minf(spacing,135)+rng.randf_range(0,30)
			if index == 0: merit -= absf(point(c).distance_to(point(start))-210)*0.4
			if index == 2 and value(c) == 2: merit += 22
			if merit > score: score = merit; best = c
	return best

func add_road(from: String, to: String, a: Vector2i, b: Vector2i) -> void:
	var ids = graph.get_id_path(a,b)
	var points: Array = []
	var distance = 0.0
	var previous = point(a)
	for c in ids:
		var p = point(c); points.append(packed(p)); distance += previous.distance_to(p); previous = p
		put(c,5 if value(c) == 5 else 4)
	var days = clampi(ceili(distance/(24.0*24.0)),1,2)
	road_edges.append([from,to,days]); road_paths.append({"from":from,"to":to,"points":points})

static func economy(region: Dictionary) -> Dictionary:
	var config: Dictionary = normalize(JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json")))
	for p in region.locations:
		if p.kind == "town":
			config.towns[p.id]["name"] = p.name
			var owner: String = config.towns[p.id].owner
			config.factions[owner].name = p.name+{"wardens":" Wardens","guild":" Guild","compact":" Compact"}[owner]
		elif p.kind == "camp": config.camps[p.id]["name"] = p.name
	for route in config.routes:
		for i in 2:
			for road in region.roads:
				if (road[0] == route.path[i] and road[1] == route.path[i+1]) or (road[1] == route.path[i] and road[0] == route.path[i+1]): route.days[i] = road[2]
	config.politics["reoccupy_delay"] = 4
	return config

func validate(d: Variant) -> bool:
	if not d is Dictionary or d.get("generator") not in [1,VERSION] or not d.get("seed") is int or d.seed < 1 or not d.get("name") is String: return false
	if d.get("width") != W or d.get("height") != H or d.get("cell_size") != CELL or d.get("origin") != [40,216]: return false
	if not d.get("terrain") is Array or d.terrain.size() != W*H: return false
	for t in d.terrain:
		if not t is int or t < 0 or t >= TERRAIN.size(): return false
	cells = d.terrain.duplicate(); reset_graph()
	if not d.get("locations") is Array or d.locations.size() != 9: return false
	var ids = {}; var town_count = 0; var camp_count = 0; var discovery_count = 0
	for p in d.locations:
		if not p is Dictionary or not p.get("id") is String or ids.has(p.id) or not p.get("name") is String or not p.get("description") is String: return false
		if not p.get("x") is int or not p.get("y") is int or not walkable(cell(Vector2(p.x,p.y))): return false
		if p.get("kind") not in ["town","camp","discovery"]: return false
		if p.kind == "town":
			if p.id not in TOWNS or not p.get("role") is String: return false
			town_count += 1
		elif p.kind == "camp":
			if p.id not in CAMPS or p.get("map") not in CAMPS or p.get("objective") not in ["hold","eliminate","defend"]: return false
			camp_count += 1
		elif p.kind == "discovery":
			if p.id not in ["discovery_0","discovery_1","discovery_2"] or p.get("feature") not in ["watchtower","ruin","cave"] or p.get("guarded_by") not in ["","ford","forest","ridge"]: return false
			if not p.get("search_hours") is int or p.search_hours < 1 or p.search_hours > 6 or not p.get("loot") is Dictionary: return false
			for key in ["crowns","food","tools","ammunition"]:
				if not p.loot.get(key) is int or p.loot[key] < 0 or p.loot[key] > 100: return false
			if not xy(p.get("rumour")) or Vector2(p.rumour[0],p.rumour[1]).distance_to(Vector2(p.x,p.y)) > 64: return false
			discovery_count += 1
		else: return false
		for old in ids.values():
			if Vector2(p.x,p.y).distance_to(Vector2(old.x,old.y)) < 48: return false
		ids[p.id] = p
	if town_count != 3 or camp_count != 3 or discovery_count != 3: return false
	for p in ids.values():
		if graph.get_id_path(cell(Vector2(ids.ashwick.x,ids.ashwick.y)),cell(Vector2(p.x,p.y))).is_empty(): return false
	if not d.get("roads") is Array or d.roads.size() != 6 or not d.get("road_paths") is Array or d.road_paths.size() != 6: return false
	var edges = {}
	for i in 6:
		var r = d.roads[i]; var path = d.road_paths[i]
		if not r is Array or r.size() != 3 or not ids.has(r[0]) or not ids.has(r[1]) or r[2] not in [1,2]: return false
		if not path is Dictionary or path.get("from") != r[0] or path.get("to") != r[1] or not path.get("points") is Array or path.points.is_empty() or path.points.size() > W*H: return false
		var start: Dictionary = ids[r[0]]; var end: Dictionary = ids[r[1]]
		if path.points[0] != [start.x,start.y] or path.points.back() != [end.x,end.y]: return false
		var previous = cell(Vector2(start.x,start.y))
		for p in path.points:
			if not xy(p): return false
			var at = cell(Vector2(p[0],p[1])); var delta = at-previous
			if not walkable(at) or value(at) not in [4,5] or absi(delta.x) > 1 or absi(delta.y) > 1: return false
			if delta.x != 0 and delta.y != 0 and (not walkable(previous+Vector2i(delta.x,0)) or not walkable(previous+Vector2i(0,delta.y))): return false
			previous = at
		var key = str(r[0])+":"+str(r[1])
		if edges.has(key): return false
		edges[key] = true
	if not d.get("river") is Array or d.river.size() not in [W,H] or not d.get("bridges") is Array or d.bridges.size() != 2: return false
	for p in d.river:
		if not xy(p): return false
	for b in d.bridges:
		if not b is Dictionary or not xy(b.get("position")) or not b.get("vertical") is bool: return false
	if not d.get("world_config") is Dictionary or JSON.stringify(d.world_config) != JSON.stringify(economy(d)): return false
	# Required economic chains must be present; graph connectivity alone is insufficient.
	for r in d.world_config.routes:
		for i in 2:
			if not edges.has(str(r.path[i])+":"+str(r.path[i+1])) and not edges.has(str(r.path[i+1])+":"+str(r.path[i])): return false
	return true

static func xy(p: Variant) -> bool:
	return p is Array and p.size() == 2 and p[0] is int and p[1] is int and p[0] >= 40 and p[0] < 968 and p[1] >= 216 and p[1] < 696

static func normalize(v: Variant) -> Variant:
	if v is float and is_finite(v) and v == floor(v): return int(v)
	if v is Array: return v.map(normalize)
	if v is Dictionary:
		var out = {}
		for k in v: out[k] = normalize(v[k])
		return out
	return v
