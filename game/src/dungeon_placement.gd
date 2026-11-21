extends RefCounted
## Only new entrances in geography v3. Saved sites are never moved on load.
## Travel bands use the same paths, terrain costs and pace as the company.
static func band(id: String) -> Vector2:
	if id.begins_with("dungeon_barrow_"): return Vector2(5,14)
	if id in ["dungeon_2","dungeon_complex_2"]: return Vector2(28,48)
	return Vector2(14,28)

static func hours(ow, origin: Vector2, target: Vector2) -> float:
	var path: Array = ow.route(origin,target)
	if path.is_empty(): return INF
	var total = 0.0; var previous = origin
	for point in path:
		total += previous.distance_to(point)*ow.travel_cost(previous,point)/ow.MOVE_SPEED
		previous = point
	return total

static func nearest(c, point: Vector2) -> Dictionary:
	var result = {"town":"","hours":INF}
	for town in c.region.locations:
		if town.kind != "town": continue
		var travel = hours(c.overworld,Vector2(town.x,town.y),point)
		if travel < result.hours: result = {"town":town.id,"hours":travel}
	return result

static func choose(c, id: String, occupied: Array) -> Vector2:
	var seed_number: int = c.region.seed
	var rng = RandomNumberGenerator.new(); rng.seed = seed_number ^ hash(id) ^ 0x41593
	var bounds = band(id); var minor = id.begins_with("dungeon_barrow_")
	# Both districts get early and middle expeditions; the two hardest sites
	# occupy opposite halves. The third barrow alternates sides by world seed.
	var east = id in ["dungeon_1","dungeon_complex_1","dungeon_barrow_1"] or (id == "dungeon_barrow_2" and seed_number%2 == 1) or (id == "dungeon_2" and seed_number%2 == 1) or (id == "dungeon_complex_2" and seed_number%2 == 0)
	var towns: Array = c.region.locations.filter(func(p):return p.kind == "town")
	var choices = []
	for y in range(2,c.overworld.SIZE.y-2):
		for x in range(2,c.overworld.SIZE.x-2):
			if (x >= c.overworld.SIZE.x/2) != east: continue
			var point: Vector2 = c.overworld.cell_point(Vector2i(x,y))
			if not c.overworld.valid_point(point) or c.overworld.road_at(point): continue
			if occupied.any(func(p):return p.distance_to(point) < 80): continue
			var distance = INF
			for town in towns: distance = minf(distance,point.distance_to(Vector2(town.x,town.y)))
			if distance < (80 if minor else 320 if bounds.x == 28 else 200): continue
			if minor and distance > 200: continue
			# Ensure one short expedition belongs to the starting settlement.
			if id == "dungeon_barrow_0" and point.distance_to(c.overworld.places.ashwick) > 200: continue
			choices.append(point)
	while not choices.is_empty():
		var point: Vector2 = choices.pop_at(rng.randi_range(0,choices.size()-1))
		var travel: Dictionary = nearest(c,point)
		if travel.hours < bounds.x or travel.hours > bounds.y: continue
		if id == "dungeon_barrow_0" and hours(c.overworld,c.overworld.places.ashwick,point) > bounds.y: continue
		return point
	return Vector2.ZERO
