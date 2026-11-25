extends RefCounted
## Spatial travel is authoritative; the economy still settles once at midnight.
## Fixed three-minute steps make time, pursuit and contacts independent of frames.
const Footprints = preload("res://src/footprints.gd")
var tracks = Footprints.new()
const ORIGIN = Vector2(40, 216)
const CELL = 16.0
var SIZE = Vector2i(58, 30)
var camp_roles: Dictionary = {}
const STEP = 0.05
# Real-time conversion only: all parties/economy/recovery retain the same STEP.
const HOURS_PER_SECOND = 0.4
const MOVE_SPEED = 24.0
const PURSUIT_PACE_MULTIPLIER = 1.20
var renewing_camps = false
var physical_founding = false
var raider_survival = false # Derived from World.raider_supply, cross-validated by Campaign.
var position = Vector2(165,385)
var path: Array = []
var destination = ""
var hour: float = 8.0
var accumulator: float = 0.0
var paused = true
var speed = 1
var scouts: Dictionary = {}
var explored: Dictionary = {}
var seen: Array = []
var pending = ""
var grace: float = 0.0
var rest_left: float = 0.0
var graph = AStarGrid2D.new()
var places: Dictionary = {}
var roads: Array = []
var route_cache: Dictionary = {}
var terrain_cells: Array = []
var road_corner_rules = true # The separate trade previews retain their original pace.

func configure(region: Dictionary) -> void:
	places.clear(); roads.clear(); route_cache.clear(); camp_roles.clear()
	SIZE = Vector2i(region.get("width",58),region.get("height",30))
	for p in region.locations:
		if p.kind == "camp": camp_roles[p.id] = p.map
	terrain_cells = region.get("terrain",[]).duplicate()
	for p in region.locations: places[p.id] = Vector2(p.x,p.y)
	if region.has("road_paths"):
		for r in region.road_paths:
			for i in range(1,r.points.size()): roads.append([Vector2(r.points[i-1][0],r.points[i-1][1]),Vector2(r.points[i][0],r.points[i][1])])
	else:
		for r in region.roads: roads.append([places[r[0]],places[r[1]]])
	graph.region = Rect2i(Vector2i.ZERO,SIZE)
	graph.cell_size = Vector2(CELL,CELL)
	graph.offset = ORIGIN+Vector2.ONE*CELL/2
	graph.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	graph.update()
	for y in SIZE.y:
		for x in SIZE.x:
			var id = Vector2i(x,y)
			var p = cell_point(id)
			graph.set_point_solid(id,terrain(p) in ["water","mountains"])
			graph.set_point_weight_scale(id,cost(p))
	# Every landmark is reachable even when its exact centre falls at a bank.
	for p in places.values(): graph.set_point_solid(cell(p),false)

func setup(region: Dictionary, world, site: String = "ashwick") -> void:
	renewing_camps = false; tracks = Footprints.new()
	configure(region)
	position = places[site]; path.clear(); destination = ""; hour = 8.0
	accumulator = 0.0; paused = true; speed = 1; scouts.clear(); explored.clear(); seen.clear(); pending = ""; grace = 0.0; rest_left = 0.0
	sync_scouts(world)
	reveal()

func cell(p: Vector2) -> Vector2i:
	return Vector2i(floori((p.x-ORIGIN.x)/CELL),floori((p.y-ORIGIN.y)/CELL))

func cell_point(p: Vector2i) -> Vector2:
	return ORIGIN+(Vector2(p)+Vector2.ONE*0.5)*CELL

func river_x(y: float) -> float:
	var river = [Vector2(390,179),Vector2(418,255),Vector2(445,335),Vector2(483,405),Vector2(454,492),Vector2(490,570),Vector2(526,637),Vector2(532,734)]
	for i in range(1,river.size()):
		if y <= river[i].y: return lerpf(river[i-1].x,river[i].x,inverse_lerp(river[i-1].y,river[i].y,y))
	return 532.0

func road_at(p: Vector2) -> bool:
	if not terrain_cells.is_empty():
		var at = cell(p)
		return Rect2i(Vector2i.ZERO,SIZE).has_point(at) and terrain_cells[at.y*SIZE.x+at.x] in [4,5]
	for r in roads:
		if Geometry2D.get_closest_point_to_segment(p,r[0],r[1]).distance_to(p) < 12: return true
	return false

func terrain(p: Vector2) -> String:
	if not terrain_cells.is_empty():
		var at = cell(p)
		return preload("res://src/map_generator.gd").TERRAIN[terrain_cells[at.y*SIZE.x+at.x]] if Rect2i(Vector2i.ZERO,SIZE).has_point(at) else "water"
	if absf(p.x-river_x(p.y)) < 16 and absf(p.y-335) > 24 and absf(p.y-624) > 24: return "water"
	if road_at(p): return "road"
	if p.x > 678 and p.y > 362 and p.y < 613: return "forest"
	if p.x < 403 and p.y > 520: return "hills"
	return "plains"

func cost(p: Vector2) -> float:
	return {"road":1.0,"plains":1.35,"forest":2.2,"hills":1.8,"water":100.0,"bridge":1.0,"mountains":100.0}[terrain(p)]

func travel_cost(a: Vector2, b: Vector2) -> float:
	# A diagonal road joins tile centres. Its exact midpoint can round into
	# either adjoining rough tile; that corner must not slow the road segment.
	if road_corner_rules and not terrain_cells.is_empty():
		var offset = cell(b)-cell(a)
		if absi(offset.x) <= 1 and absi(offset.y) <= 1 and road_at(a) and road_at(b): return 1.0
	return cost((a+b)*0.5)

func valid_point(p: Vector2) -> bool:
	return Rect2(ORIGIN,Vector2(SIZE)*CELL).has_point(p) and not graph.is_point_solid(cell(p))

func route(a: Vector2, b: Vector2) -> Array:
	if not valid_point(a) or not valid_point(b): return []
	var points = graph.get_point_path(cell(a),cell(b))
	if points.is_empty(): return []
	var out: Array = []
	# Start from the actual position. Recentring on every AI replan traps slow
	# parties inside their current cell instead of advancing toward the target.
	for i in range(1,points.size()): out.append(points[i])
	out.append(b)
	return out

func order(target: Vector2, site: String = "") -> bool:
	var planned = route(position,target)
	if planned.is_empty() or not pending.is_empty(): return false
	path = planned; destination = site; paused = false
	return true

func at_site(site: String) -> bool:
	return places.has(site) and position.distance_to(places[site]) < 14.0

func hours_left() -> float:
	var result = 0.0
	var from = position
	for p in path:
		result += from.distance_to(p)*travel_cost(from,p)/travel_pace()
		from = p
	return result

func travel_pace(pursuing: bool = false) -> float:
	return MOVE_SPEED*(tracks.SCOUT_PACE if tracks.enabled and tracks.scouting else 1.0)*(PURSUIT_PACE_MULTIPLIER if pursuing else 1.0)

func reveal() -> void:
	var radius = sight()
	var home = cell(position)
	for y in range(maxi(0,home.y-11),mini(SIZE.y,home.y+12)):
		for x in range(maxi(0,home.x-11),mini(SIZE.x,home.x+12)):
			if position.distance_to(cell_point(Vector2i(x,y))) < radius: explored[str(y*SIZE.x+x)] = true

func discovered(p: Vector2) -> bool:
	var c = cell(p)
	return explored.has(str(c.y*SIZE.x+c.x))

func sight() -> float:
	return 115.0 if hour < 6 or hour >= 20 else 175.0

func sync_scouts(world) -> void:
	raider_survival = not world.raider_supply.is_empty()
	physical_founding = world.physical_founding
	for site in world.SITES:
		var c: Dictionary = world.camps[site]
		var id = party_id(site,c.generation)
		if c.active and not scouts.has(id):
			# Initial party for this occupation. Paid replacements use distinct IDs.
			var start = places[site]+{"ford":Vector2(-64,-32),"forest":Vector2(64,32),"ridge":Vector2(-48,32)}.get(camp_roles.get(site,site),Vector2.ZERO)
			if not valid_point(start): start = places[site]
			spawn_scout(site,c.generation,1,start)
	for s in scouts.values():
		if not raider_survival and (world.camps[s.site].generation != s.generation or not world.camps[s.site].active): s.defeated = true

func advance_party(p: Vector2, waypoints: Array, hours: float, pace: float) -> Vector2:
	var left = hours
	while not waypoints.is_empty() and left > 0:
		var to: Vector2 = waypoints[0]
		var distance = p.distance_to(to)
		var terrain_cost = travel_cost(p,to)
		var travel = distance*terrain_cost/pace
		if travel <= left:
			p = to; waypoints.pop_front(); left -= travel
		else:
			p = p.move_toward(to,left*pace/terrain_cost); left = 0
	return p

func step(world, town_safe: bool, traffic = null, background: bool = false, campaign = null) -> Dictionary:
	var out = {"arrived":"","spotted":"","contact":""}
	sync_scouts(world)
	tracks.advance(self,not background)
	if background and campaign != null: campaign.recon.watch.clear()
	if not background: grace = maxf(0.0,snappedf(grace-STEP,STEP))
	var moving = not path.is_empty()
	if not background and traffic != null and campaign != null and not traffic.follow_wagon.is_empty():
		var dock: String = traffic.advance_follow(campaign)
		if not dock.is_empty():
			out.arrived = dock; destination = ""; paused = true
	elif not background:
		# Traffic has already refreshed the order and revoked lost contacts.
		# Only the company moves farther; the tick and terrain costs stay fixed.
		var pursuing: bool = traffic != null and traffic.enabled and not traffic.pursuit.is_empty()
		position = advance_party(position,path,STEP,travel_pace(pursuing))
	if not background and moving and path.is_empty():
		out.arrived = destination if not destination.is_empty() else "wilderness"
		destination = ""; paused = true
	if not background: reveal()
	for s in scouts.values():
		if s.defeated: continue
		var previous_position: Vector2 = s.position
		var distance = position.distance_to(s.position)
		var safe = false
		for town in world.TOWNS:
			if position.distance_to(places[town]) < 45: safe = true
		if campaign != null and campaign.bandits.enabled:
			var decision: Dictionary = campaign.bandits.order(campaign,s,background)
			s.mode = "pursuit" if campaign.bandits.bands[s.id].mode == "hunting" else "patrol"
			s.replan = snappedf(s.replan-STEP,STEP)
			if s.replan <= 0 or s.path.is_empty():
				s.replan = 0.5
				if campaign.bandits.bands[s.id].mode in ["fleeing","fighting_patrol"]: s.path = route(s.position,decision.position)
				elif campaign.founding.committed(s.id) or campaign.founding.regrouping(campaign,s.id): s.path = campaign.raiders.danger.route(campaign,s.id,s.position,decision.position)
				else: s.path = route(s.position,decision.position)
			s.position = advance_party(s.position,s.path,STEP,decision.pace)
		else:
			var mission: Dictionary = traffic.order_for(s,self) if traffic != null else {}
			var chase = not background and not mission.get("committed",false) and distance < 100 and not safe and grace <= 0
			s.mode = "pursuit" if chase else "patrol"
			s.replan = snappedf(s.replan-STEP,STEP)
			if s.replan <= 0 or s.path.is_empty():
				s.replan = 0.5
				var target = position
				if not chase and not mission.is_empty(): target = mission.position
				elif not chase:
					var offsets = [Vector2(-64,-32),Vector2(64,-32),Vector2(64,48),Vector2(-64,48)]
					target = places[s.site]+offsets[s.leg%4]
					if s.position.distance_to(target) < 10: s.leg += 1
					if not valid_point(target): target = places[s.site]
				s.path = route(s.position,target)
			s.position = advance_party(s.position,s.path,STEP,17.0)
		if tracks.enabled and campaign != null and campaign.bandits.enabled:
			tracks.record(self,s.id,previous_position,s.position,campaign.bandits.bands[s.id].health.filter(func(hp):return hp > 0).size())
		if not background and position.distance_to(s.position) < sight() and not s.id in seen:
			seen.append(s.id); out.spotted = s.id; paused = true
		if not background and position.distance_to(s.position) < 13 and not safe and grace <= 0:
			pending = s.id; out.contact = s.id; paused = true; path.clear(); destination = ""
			break
	if campaign != null: campaign.founding.tick(campaign)
	return out

func scheduled_position(from: String, to: String, fraction: float) -> Vector2:
	var key = from+":"+to
	if not route_cache.has(key): route_cache[key] = route(places[from],places[to])
	var points: Array = route_cache[key]
	var total = 0.0
	var p: Vector2 = places[from]
	for q in points: total += p.distance_to(q)*travel_cost(p,q); p = q
	return advance_party(places[from],points.duplicate(),total*clampf(fraction,0,1),1.0)

func friendly_parties(world, traffic = null) -> Array:
	var out: Array = []
	for c in world.caravans.values():
		if c.status not in ["transit","waiting","escort"]: continue
		var r = world.route_data(c.route)
		var p: Vector2 = places[r.path[c.index]]
		if traffic != null and traffic.enabled: p = traffic.wagons[c.id].position
		elif c.status == "escort": p = position+Vector2(-12,12)
		elif c.index < 2:
			var duration = float(r.days[c.index])
			p = scheduled_position(r.path[c.index],r.path[c.index+1],(duration-c.remaining+hour/24.0)/duration)
		out.append({"id":c.id,"kind":"wagon","position":p,"name":world.short_id(c.id)})
	for p in world.patrols.values():
		if world.has_physical(p.faction): continue
		if p.status not in ["marching","stationed"]: continue
		var pos: Vector2 = places[p.site]+Vector2(20,0)
		if p.status == "marching":
			var duration = float(world.day-p.started+p.remaining)
			pos = scheduled_position(world.config.factions[p.faction].town,p.site,(duration-p.remaining+hour/24.0)/duration)
		out.append({"id":p.id,"kind":"patrol","position":pos,"name":p.faction.capitalize()})
	return out

static func pack_point(p: Vector2) -> Array:
	return [p.x,p.y]

func snapshot() -> Dictionary:
	var parties = scouts.duplicate(true)
	for s in parties.values():
		s.position = pack_point(s.position); s.path = s.path.map(pack_point)
	var out = {"version":2 if renewing_camps else 1,"position":pack_point(position),"path":path.map(pack_point),"destination":destination,"hour":hour,"accumulator":snappedf(accumulator,0.000000001),"paused":paused,"speed":speed,"scouts":parties,"explored":explored.duplicate(),"seen":seen.duplicate(),"pending":pending,"grace":grace,"rest_left":rest_left}

	if tracks.enabled:
		out["tracks_base_version"] = out.version; out.version = 3; out["tracks"] = tracks.snapshot()
	return out

func valid_xy(p: Variant) -> bool:
	return p is Array and p.size() == 2 and (p[0] is int or p[0] is float) and (p[1] is int or p[1] is float) and is_finite(float(p[0])) and is_finite(float(p[1])) and valid_point(Vector2(p[0],p[1]))

func unpack_path(raw: Array) -> Array:
	return raw.map(func(p): return Vector2(p[0],p[1]))

func restore(d: Variant, region: Dictionary, world) -> bool:
	raider_survival = not world.raider_supply.is_empty()
	physical_founding = world.physical_founding
	configure(region)
	if not d is Dictionary or d.get("version") not in [1,2,3] or not valid_xy(d.get("position")): return false
	var tracks_save: bool = d.version == 3
	var base_version = d.get("tracks_base_version") if tracks_save else d.version
	if tracks_save and (base_version not in [1,2] or not d.get("tracks") is Dictionary): return false
	if not tracks_save and (d.has("tracks_base_version") or d.has("tracks")): return false
	if not d.get("path") is Array or d.path.size() > 1800: return false
	for p in d.path:
		if not valid_xy(p): return false
	if not valid_route(d.position,d.path): return false
	if not d.get("destination") is String or (d.destination != "" and not places.has(d.destination)): return false
	for key in ["hour","accumulator","grace","rest_left"]:
		if not (d.get(key) is int or d.get(key) is float) or not is_finite(float(d[key])): return false
	if d.hour < 0 or d.hour >= 24 or d.accumulator < 0 or d.accumulator >= STEP+0.00001 or d.grace < 0 or d.grace > 24 or d.rest_left < 0 or d.rest_left > 24: return false
	if not d.get("paused") is bool or d.get("speed") not in [1,2,4] or not d.get("scouts") is Dictionary: return false
	if not d.get("explored") is Dictionary or d.explored.size() > SIZE.x*SIZE.y or not d.get("seen") is Array or not d.get("pending") is String: return false
	for k in d.explored:
		if not k is String or not k.is_valid_int() or int(k) < 0 or int(k) >= SIZE.x*SIZE.y or d.explored[k] != true: return false
	for id in d.scouts:
		var s = d.scouts[id]
		if not s is Dictionary or s.get("id") != id or s.get("site") not in world.SITES: return false
		if not s.get("generation") is int or s.generation < 1: return false
		var sortie = s.get("sortie",1)
		if not sortie is int or sortie < 1 or sortie > (world.day*2+1 if physical_founding else world.day+1) or (sortie > 1 and base_version != 2) or id != party_id(s.site,s.generation,sortie): return false
		if s.has("expedition") and (not physical_founding or s.expedition != true): return false
		if s.generation > world.camps[s.site].generation or not valid_xy(s.get("position")) or not s.get("path") is Array or s.path.size() > 1800: return false
		for p in s.path:
			if not valid_xy(p): return false
		if not valid_route(s.position,s.path): return false
		if not s.get("leg") is int or s.leg < 0 or not s.get("defeated") is bool or s.get("mode") not in ["patrol","pursuit"]: return false
		if not (s.get("replan") is int or s.get("replan") is float) or not is_finite(float(s.replan)) or s.replan < 0 or s.replan > 0.5: return false
	for id in d.seen:
		if not id is String or not d.scouts.has(id): return false
	if d.pending != "" and (not d.scouts.has(d.pending) or d.scouts[d.pending].defeated or not d.paused or not d.path.is_empty()): return false
	renewing_camps = base_version == 2
	position = Vector2(d.position[0],d.position[1]); path = unpack_path(d.path); destination = d.destination
	hour = snappedf(float(d.hour),STEP); accumulator = snappedf(float(d.accumulator),0.000000001); paused = d.paused; speed = d.speed
	scouts = d.scouts.duplicate(true)
	for s in scouts.values(): s.position = Vector2(s.position[0],s.position[1]); s.path = unpack_path(s.path); s.replan = snappedf(float(s.replan),STEP)
	explored = d.explored.duplicate(); seen = d.seen.duplicate(); pending = d.pending; grace = snappedf(float(d.grace),STEP); rest_left = snappedf(float(d.rest_left),STEP)
	tracks = Footprints.new()
	if tracks_save and not tracks.restore(d.tracks,self,world): return false
	return true

func mark_site(site: String) -> void:
	if not terrain_cells.is_empty(): return # A contract marks the site, not hidden geography.
	var at = cell(places[site])
	for y in range(maxi(0,at.y-2),mini(SIZE.y,at.y+3)):
		for x in range(maxi(0,at.x-2),mini(SIZE.x,at.x+3)): explored[str(y*SIZE.x+x)] = true

func valid_route(origin: Array, points: Array) -> bool:
	var previous = Vector2(origin[0],origin[1])
	for p in points:
		var to = Vector2(p[0],p[1])
		var delta = cell(to)-cell(previous)
		if absi(delta.x) > 1 or absi(delta.y) > 1: return false
		if delta.x != 0 and delta.y != 0:
			if graph.is_point_solid(cell(previous)+Vector2i(delta.x,0)) or graph.is_point_solid(cell(previous)+Vector2i(0,delta.y)): return false
		previous = to
	return true

func reveal_radius(centre: Vector2, radius: float) -> void:
	for y in SIZE.y:
		for x in SIZE.x:
			if centre.distance_to(cell_point(Vector2i(x,y))) <= radius: explored[str(y*SIZE.x+x)] = true

static func party_id(site: String, generation: int, sortie: int = 1) -> String:
	return "%s_%d" % [site,generation]+("_r%d" % sortie if sortie > 1 else "")

func spawn_scout(site: String, generation: int, sortie: int, start: Vector2) -> void:
	var id = party_id(site,generation,sortie)
	assert(not scouts.has(id))
	scouts[id] = {"id":id,"site":site,"generation":generation,"position":start,"path":[],"leg":0,"replan":0.0,"defeated":false,"mode":"patrol"}
	if sortie > 1: scouts[id]["sortie"] = sortie

func current_party(world, site: String) -> String:
	var found = party_id(site,world.camps[site].generation); var latest = 1
	for s in scouts.values():
		if not s.get("expedition",false) and s.site == site and s.generation == world.camps[site].generation and s.get("sortie",1) > latest:
			found = s.id; latest = s.sortie
	return found
