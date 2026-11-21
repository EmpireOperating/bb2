extends RefCounted
## Personal, last-seen places, never a reference to a moving or hidden actor.
const LIFETIME = 1440 # Three days, measured by the paused campaign clock.
const LIMIT = 4
const MERGE_DISTANCE = 64.0
var memories: Dictionary = {}

func active(c) -> bool:
	return c.raiders.enabled and c.raiders.rules_version >= 5

func radius(c, memory: Dictionary) -> float:
	return maxf(0.0,96.0-32.0*floorf(float(c.overworld.tracks.clock-memory.seen)/480.0))

func expire(c) -> void:
	if not active(c): return
	for id in memories.keys():
		memories[id] = memories[id].filter(func(m):return c.overworld.tracks.clock-m.seen < LIFETIME)
		if memories[id].is_empty(): memories.erase(id)

func remember(c, id: String, point: Vector2, kind: String) -> void:
	if not active(c): return
	# Callers must have observed a stronger threat. Defend the spatial boundary here too.
	if c.overworld.scouts[id].defeated or point.distance_to(c.overworld.scouts[id].position) > c.bandits.vision(c) or not c.overworld.valid_point(point): return
	expire(c)
	var recent: Array = memories.get(id,[])
	var nearest = -1; var distance = MERGE_DISTANCE
	for i in recent.size():
		var d = Vector2(recent[i].position[0],recent[i].position[1]).distance_to(point)
		if d <= distance: nearest = i; distance = d
	if nearest >= 0: recent.remove_at(nearest)
	recent.append({"position":[point.x,point.y],"seen":c.overworld.tracks.clock,"kind":kind})
	if recent.size() > LIMIT: recent.pop_front()
	memories[id] = recent
	# The existing flee transition owns path invalidation. Recording another
	# sighting must not change ordinary flight speed or its replan cadence.

func zones(c, id: String) -> Array:
	if not active(c): return []
	var out: Array = []
	for m in memories.get(id,[]):
		var reach = radius(c,m)
		if reach > 0: out.append({"point":Vector2(m.position[0],m.position[1]),"radius":reach})
	return out

func route(c, id: String, from: Vector2, to: Vector2) -> Array:
	var ow = c.overworld; var known = zones(c,id)
	if known.is_empty(): return ow.route(from,to)
	# A band can leave a remembered area it is already in. One cell of slack
	# accommodates off-centre positions; subsequent replans expand the excluded area.
	for zone in known:
		if to.distance_to(zone.point) < zone.radius: return []
		zone["block"] = minf(zone.radius+12.0,maxf(0.0,from.distance_to(zone.point)-12.0))
	var ordinary: Array = ow.route(from,to)
	if ordinary.is_empty(): return []
	var crosses = false; var previous = from
	for point in ordinary:
		for zone in known:
			if Geometry2D.get_closest_point_to_segment(zone.point,previous,point).distance_to(zone.point) < zone.block:
				crosses = true; break
		if crosses: break
		previous = point
	if not crosses: return ordinary
	# Synchronous, temporary mask: restore every changed cell before any other
	# traveller queries this graph. Terrain, road costs and diagonal rules are retained.
	var changed: Array = []
	for zone in known:
		var centre: Vector2i = ow.cell(zone.point); var reach = ceili(zone.block/ow.CELL)+1
		for y in range(maxi(0,centre.y-reach),mini(ow.SIZE.y,centre.y+reach+1)):
			for x in range(maxi(0,centre.x-reach),mini(ow.SIZE.x,centre.x+reach+1)):
				var cell = Vector2i(x,y)
				if cell == ow.cell(from) or ow.graph.is_point_solid(cell): continue
				if ow.cell_point(cell).distance_to(zone.point) < zone.block:
					ow.graph.set_point_solid(cell,true); changed.append(cell)
	var planned: Array = ow.route(from,to)
	for cell in changed: ow.graph.set_point_solid(cell,false)
	return planned

func restore(raw: Variant, c) -> bool:
	if not raw is Dictionary or raw.size() > c.overworld.scouts.size(): return false
	for id in raw:
		if not c.overworld.scouts.has(id) or not raw[id] is Array or raw[id].is_empty() or raw[id].size() > LIMIT: return false
		var previous = -1
		for m in raw[id]:
			if not m is Dictionary or m.size() != 3 or not c.overworld.valid_xy(m.get("position")) or m.get("kind") not in ["company","patrol"]: return false
			if not m.get("seen") is int or m.seen < 0 or m.seen > c.overworld.tracks.clock or m.seen < previous: return false
			# An expired entry is legal until the next simulation sync, never active.
			previous = m.seen
	memories = raw.duplicate(true)
	for records in memories.values():
		for memory in records:
			var point = Vector2(memory.position[0],memory.position[1])
			memory.position = [point.x,point.y]
	return true
