extends RefCounted
## Named, visible features derived from immutable saved roads. No world RNG,
## fog changes, destination pins or live intelligence. Old geography stays intact.
const STONES = ["Hare","Stag","Raven","Fox","Badger","Owl","Boar","Wolf","Heron","Otter","Falcon","Bear","Adder","Hound","Lynx","Ram","Swan","Hawk","Elk","Crow","Crane","Wren","Marten","Lark"]
var stamp = ""
var landmarks: Array = []
var graph = AStar2D.new()
var points: Dictionary = {}

static func compass(delta: Vector2) -> String:
	return ["east","south-east","south","south-west","west","north-west","north","north-east"][posmod(roundi(delta.angle()/(PI/4)),8)]
static func point_key(p: Vector2) -> String:
	return "%d:%d" % [roundi(p.x),roundi(p.y)]
func vertex(p: Vector2) -> int:
	var key = point_key(p)
	if not points.has(key):
		points[key] = points.size(); graph.add_point(points[key],p)
	return points[key]
func prepare(c) -> void:
	var identity = "%s:%s:%s:%s" % [c.region.get("generator",0),c.region.get("seed",0),c.overworld.SIZE.x,c.overworld.SIZE.y]
	if stamp == identity: return
	stamp = identity; landmarks.clear(); graph.clear(); points.clear()
	var paths: Array = c.region.get("road_paths",[])
	for road in paths:
		var previous = -1
		for xy in road.points:
			var id = vertex(Vector2(xy[0],xy[1]))
			if previous != -1 and previous != id: graph.connect_points(previous,id)
			previous = id
	var names = {}
	for bridge in c.region.get("bridges",[]):
		var at = Vector2(bridge.position[0],bridge.position[1])
		var towns: Array = c.world.TOWNS.duplicate()
		towns.sort_custom(func(a,b): return at.distance_squared_to(c.overworld.places[a]) < at.distance_squared_to(c.overworld.places[b]))
		if towns.is_empty(): continue
		var town: String = towns[0]
		var name = "%s %s Bridge" % [c.node(town).name,compass(at-c.overworld.places[town]).capitalize()]
		names[name] = names.get(name,0)+1
		if names[name] > 1: name += " " + str(names[name])
		landmarks.append({"id":"bridge_"+str(landmarks.size()),"name":name,"kind":"bridge","position":at})
	var stone = 0
	for road in paths:
		# Prefer the middle of a real road, away from towns, camps and bridges.
		var candidates: Array = road.points.duplicate()
		var middle: Array = road.points[road.points.size()/2] if not road.points.is_empty() else [0,0]
		var centre = Vector2(middle[0],middle[1])
		candidates.sort_custom(func(a,b): return Vector2(a[0],a[1]).distance_squared_to(centre) < Vector2(b[0],b[1]).distance_squared_to(centre))
		for xy in candidates:
			var at = Vector2(xy[0],xy[1])
			if not c.overworld.valid_point(at) or not c.overworld.road_at(at): continue
			if c.overworld.places.values().any(func(p): return at.distance_to(p) < 52): continue
			if landmarks.any(func(mark): return at.distance_to(mark.position) < 80): continue
			var name: String = STONES[stone % STONES.size()] + " Waystone"
			if stone >= STONES.size(): name += " " + str(1+stone/STONES.size())
			landmarks.append({"id":"waystone_"+str(stone),"name":name,"kind":"waystone","position":at})
			stone += 1; break

func road_route(c, origin: String, destination: String) -> PackedVector2Array:
	prepare(c)
	if not c.overworld.places.has(origin) or not c.overworld.places.has(destination): return PackedVector2Array()
	var a = point_key(c.overworld.places[origin]); var b = point_key(c.overworld.places[destination])
	if not points.has(a) or not points.has(b): return PackedVector2Array()
	return graph.get_point_path(points[a],points[b])
func route_marks(c, origin: String, destination: String) -> Array:
	var route = road_route(c,origin,destination)
	var result: Array = []
	if route.size() < 2: return result
	for mark in landmarks:
		var best = INF; var index = -1
		for i in route.size():
			var distance: float = route[i].distance_squared_to(mark.position)
			if distance < best: best = distance; index = i
		if best > 24*24 or index <= 1 or index >= route.size()-2: continue
		if mark.position.distance_to(route[0]) < 48 or mark.position.distance_to(route[-1]) < 48: continue
		var row: Dictionary = mark.duplicate(); row["index"] = index; result.append(row)
	result.sort_custom(func(a,b): return a.index < b.index)
	return result
func instructions(c, origin: String, destination: String) -> Array:
	if not c.overworld.places.has(origin) or not c.overworld.places.has(destination): return ["No directions recorded."]
	if origin == destination: return ["These directions were recorded in %s itself." % c.node(origin).name]
	var start: Vector2 = c.overworld.places[origin]
	var target: Vector2 = c.overworld.places[destination]
	var marks = route_marks(c,origin,destination)
	var result: Array = []
	# Keep long journeys readable; skipped features remain visible on the road.
	if marks.size() > 4: marks = [marks[0],marks[marks.size()/3],marks[marks.size()*2/3],marks[-1]]
	var previous = start
	for mark in marks:
		var from_text = "From %s" % c.node(origin).name if result.is_empty() else "From there"
		result.append("%s, follow the road generally %s to %s." % [from_text,compass(mark.position-previous),mark.name])
		previous = mark.position
	var from_text = "From %s" % c.node(origin).name if result.is_empty() else "Beyond %s" % marks[-1].name
	var route = road_route(c,origin,destination)
	result.append("%s, %s generally %s toward %s." % [from_text,"follow the road" if route.size() > 1 else "head",compass(target-previous),c.node(destination).name])
	return result
func summary(c, origin: String, destination: String) -> String:
	var lines = instructions(c,origin,destination)
	return lines[0]
func visible(c) -> Array:
	prepare(c)
	return landmarks.filter(func(mark): return c.overworld.discovered(mark.position))
