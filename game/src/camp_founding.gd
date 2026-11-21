extends RefCounted
## Physical movement, paid construction and finite people; no population is created at settlement.
const VERSION = 1
const BUILD_TICKS = 240 # Twelve campaign hours at three minutes per tick.
const BUILD_FOOD = 6
const SEARCH_TICKS = 40
const RETRY_TICKS = 480
const MAX_DISTANCE = 480.0
var enabled = false
var plans: Dictionary = {}
var checks: Dictionary = {}
var expeditions: Dictionary = {}
var founded: Dictionary = {}

func setup(c, active: bool) -> void:
	enabled = active and c.raiders.enabled
	plans.clear(); checks.clear(); expeditions.clear(); founded.clear()
	c.world.physical_founding = enabled; c.overworld.physical_founding = enabled

func committed(id: String) -> bool:
	return enabled and plans.get(id,{}).get("phase") in ["travel","building"]

func regrouping(c, id: String) -> bool:
	return enabled and c.raiders.rules_version >= 4 and expeditions.has(id) and not c.raiders.displaced(c,id) and c.raiders.living(c,id) >= 2 and plans.get(id,{}).get("phase") == "failed"

func sync(c) -> void:
	if not enabled: return
	for id in plans.keys():
		if committed(id) and (c.overworld.scouts[id].defeated or c.world.camps[plans[id].target].active or c.world.camps[plans[id].target].generation != plans[id].generation): cancel(c,id)

func occupied_target(site: String, except_id: String = "") -> bool:
	return plans.keys().any(func(id):return id != except_id and committed(id) and plans[id].target == site)

func eligible(c, site: String, id: String = "") -> bool:
	var camp: Dictionary = c.world.camps[site]
	return not camp.active and c.day >= camp.cleared_day+int(c.world.config.politics.get("reoccupy_delay",4)) and not occupied_target(site,id)

func travel_hours(c, from: Vector2, to: Vector2, id: String = "") -> float:
	var path: Array = c.raiders.danger.route(c,id,from,to) if id != "" else c.overworld.route(from,to)
	if path.is_empty() and (from.distance_to(to) > 10 or not c.raiders.danger.zones(c,id).is_empty()): return INF
	var hours = 0.0; var previous = from
	for p in path:
		hours += previous.distance_to(p)*c.overworld.travel_cost(previous,p)/17.0; previous = p
	return hours

func provisions(c, id: String, hours: float) -> int:
	return BUILD_FOOD+(2+ceili(hours/24.0))*c.raiders.living(c,id)

func target(c, id: String, at: Vector2, available: int, people: int = -1) -> String:
	var best = ""; var score = -INF
	for site in c.world.SITES:
		if not eligible(c,site,id): continue
		var point: Vector2 = c.overworld.places[site]
		var distance = at.distance_to(point)
		if distance > MAX_DISTANCE or c.bandits.sheltered(c,point,90): continue
		# Site/road knowledge is static. V5 uses personal observations made by the
		# immediate threat checks; new recruits do not borrow a field party's memory.
		if c.raiders.rules_version < 5 and distance <= c.bandits.vision(c) and c.guards.cover(c,point,c.bandits.power(id)): continue
		var hours = travel_hours(c,at,point,id if people < 0 else "")
		if not is_finite(hours): continue
		var needed = provisions(c,id,hours) if people < 0 else BUILD_FOOD+(2+ceili(hours/24.0))*people
		if needed > available: continue
		var access = 0.0
		for road in c.world.config.routes:
			if road.path[1] == site: access += 45.0
		for farm in c.farm.all():
			access += maxf(0.0,140.0-point.distance_to(farm.position))*0.25
		var value = access-hours*8.0+(20.0 if c.overworld.terrain(point) == "forest" else 0.0)
		if value > score: best = site; score = value
	return best

func start(c, id: String, site: String) -> void:
	plans[id] = {"target":site,"generation":c.world.camps[site].generation,"phase":"travel","progress":0,"paid":0,"started":c.overworld.tracks.clock,"finished":0,"new_party":""}
	c.bandits.change_mode(c.bandits.bands[id],c.overworld.scouts[id],"founding")

func cancel(c, id: String) -> void:
	if not committed(id): return
	plans[id].phase = "failed"; plans[id].progress = 0; plans[id].finished = c.overworld.tracks.clock
	checks[id] = c.overworld.tracks.clock+RETRY_TICKS
	var s: Dictionary = c.overworld.scouts[id]; var b: Dictionary = c.bandits.bands[id]
	if b.mode in ["founding","building"]: c.bandits.change_mode(b,s,"scouting")

func order(c, s: Dictionary, background: bool) -> Dictionary:
	if not enabled: return {}
	var id: String = s.id; var b: Dictionary = c.bandits.bands[id]
	if s.defeated or c.overworld.pending == id or c.guards.engaged(id): return {}
	if regrouping(c,id):
		return retry_expedition(c,s)
	if not committed(id) and c.raiders.displaced(c,id) and c.overworld.tracks.clock >= checks.get(id,0):
		checks[id] = c.overworld.tracks.clock+SEARCH_TICKS
		if c.raiders.living(c,id) >= 2 and c.raiders.bands[id].hunger == 0 and not c.traffic.missions.has(id) and not c.farm.engaged(id):
			var site = target(c,id,s.position,c.world.raider_supply.packs[id].food)
			if site != "": start(c,id,site)
	if not committed(id): return {}
	var plan: Dictionary = plans[id]; var point: Vector2 = c.overworld.places[plan.target]
	if not eligible(c,plan.target,id) or c.world.camps[plan.target].generation != plan.generation or c.raiders.living(c,id) < 2 or c.raiders.bands[id].hunger > 0:
		cancel(c,id); return {}
	if c.raiders.rules_version < 5 and s.position.distance_to(point) <= c.bandits.vision(c) and c.guards.cover(c,point,c.bandits.power(id)):
		cancel(c,id); return {}
	if plan.phase == "travel" and not c.raiders.danger.zones(c,id).is_empty() and (s.replan <= 0 or s.path.is_empty()):
		var hours = travel_hours(c,s.position,point,id)
		if not is_finite(hours) or provisions(c,id,hours) > c.world.raider_supply.packs[id].food:
			cancel(c,id); return {}
	if s.position.distance_to(point) <= 10:
		if plan.phase == "travel":
			if c.world.raider_supply.packs[id].food < BUILD_FOOD+2*c.raiders.living(c,id): cancel(c,id); return {}
			c.world.use_raider_pack(id,BUILD_FOOD,"eaten"); plan.paid = BUILD_FOOD; plan.phase = "building"
		c.bandits.change_mode(b,s,"building")
		return {"position":point,"pace":17.0}
	c.bandits.change_mode(b,s,"founding")
	return {"position":point,"pace":17.0}

func retry_expedition(c, s: Dictionary) -> Dictionary:
	var id: String = s.id; var home: Vector2 = c.overworld.places[s.site]
	var b: Dictionary = c.bandits.bands[id]
	c.bandits.abandon_freight(c,s,"The surviving expedition abandons the raid to regroup at its camp.")
	# Reuse the paid survivors. Threat checks still run before founding orders.
	if s.position.distance_to(home) > 10:
		c.bandits.change_mode(b,s,"returning")
		return {"position":home,"pace":17.0}
	# Failed founders can eat at home, but never draw from the residents' protected food.
	var pack: Dictionary = c.world.raider_supply.packs[id]
	var available: int = maxi(0,c.world.camp_food(s.site)-c.raiders.PACK_DAYS*c.raiders.residents(c,s.site))
	c.world.load_raider_food(id,s.site,mini(available,maxi(0,c.raiders.PACK_DAYS*c.raiders.living(c,id)-pack.food)))
	c.bandits.change_mode(b,s,"recovering")
	if c.overworld.tracks.clock < checks.get(id,0) or c.raiders.living(c,id) < 2 or c.raiders.bands[id].hunger > 0: return {"position":home,"pace":17.0}
	checks[id] = c.overworld.tracks.clock+SEARCH_TICKS
	var destination = target(c,id,home,c.raiders.carry_limit(c,id))
	if destination == "": return {"position":home,"pace":17.0}
	var needed = provisions(c,id,travel_hours(c,home,c.overworld.places[destination],id))
	# The existing party's carried provisions already count toward its survival buffer.
	var others = c.raiders.reserve_food(c,s.site)-maxi(0,c.raiders.BUFFER_DAYS*c.raiders.living(c,id)-pack.food)
	var load_size: int = maxi(0,needed-pack.food)
	if c.world.camp_food(s.site) < others+load_size: return {"position":home,"pace":17.0}
	c.world.load_raider_food(id,s.site,load_size)
	start(c,id,destination)
	c.world.log_event("The surviving expedition from %s sets out again with fresh provisions." % c.node(s.site).name)
	return {"position":c.overworld.places[destination],"pace":17.0}

func tick(c) -> void:
	if not enabled: return
	for id in plans.keys():
		if not committed(id): continue
		var p: Dictionary = plans[id]; var s: Dictionary = c.overworld.scouts[id]; var b: Dictionary = c.bandits.bands[id]
		if s.defeated or b.mode in ["fleeing","fighting_patrol"] or not eligible(c,p.target,id) or c.raiders.living(c,id) < 2:
			cancel(c,id); continue
		if c.overworld.pending == id: continue
		if p.phase != "building": continue
		if s.position.distance_to(c.overworld.places[p.target]) > 10 or b.mode != "building" or c.raiders.bands[id].hunger > 0:
			cancel(c,id); continue
		p.progress += 1
		if p.progress >= BUILD_TICKS: settle(c,id)

func expedition_size(c, site: String) -> int:
	return c.enemy_count(site,clampi(c.world.camps[site].strength-1,1,3),"scout")

func expedition_plan(c, site: String) -> Dictionary:
	var r: Dictionary = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)]
	var count = expedition_size(c,site)
	var capacity = mini(36,8*count) if c.raiders.rules_version >= 2 else BUILD_FOOD+3*count
	var destination = target(c,r.party,c.overworld.places[site],capacity,count if c.raiders.rules_version >= 2 else -1)
	if destination == "": return {}
	var hours = travel_hours(c,c.overworld.places[site],c.overworld.places[destination])
	var supply = BUILD_FOOD+(2+ceili(hours/24.0))*count if c.raiders.rules_version >= 2 else capacity
	return {"target":destination,"supply":supply}

func recruiting(c, site: String) -> int:
	if not enabled or not c.world.camps[site].active: return 0
	var r: Dictionary = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)]
	var s: Dictionary = c.overworld.scouts[r.party]
	if s.defeated or c.raiders.living(c,s.id) < c.bandits.bands[s.id].capacity: return 0
	if expeditions.keys().any(func(id):return expeditions[id].site == site and not c.overworld.scouts[id].defeated and (c.raiders.rules_version < 4 or (not c.raiders.displaced(c,id) and c.raiders.living(c,id) >= 2))): return 0
	var count = expedition_size(c,site); var plan = expedition_plan(c,site)
	if plan.is_empty(): return 0
	if c.world.camp_food(site) < recruit_food_required(c,site,count,plan.supply): return 0
	return count

func recruit_food_required(c, site: String, count: int, supply: int) -> int:
	var r: Dictionary = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)]
	var missing = maxi(0,count-r.reserve-r.training.get("count",0))
	var buffer: int = c.raiders.reserve_food(c,site)
	# Trained founders leave the resident pool. Their route supplies cover their upkeep;
	# retaining another home buffer for those same people can strand a funded expedition.
	if c.raiders.rules_version >= 4: buffer -= c.raiders.BUFFER_DAYS*mini(count,r.reserve)
	return buffer+missing*c.camp_life.RECRUIT_FOOD+supply+3*missing

func launch(c, site: String) -> bool:
	var count = recruiting(c,site)
	if count == 0: return false
	var r: Dictionary = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)]
	if r.reserve < count: return false
	var plan = expedition_plan(c,site)
	if plan.is_empty(): return false
	var supply: int = plan.supply
	var destination: String = plan.target
	var id: String = c.overworld.party_id(site,r.generation,r.next_party)
	c.overworld.spawn_scout(site,r.generation,r.next_party,c.overworld.places[site]); c.overworld.scouts[id]["expedition"] = true
	r.next_party += 1; r.reserve -= count; r.assigned += count
	expeditions[id] = {"site":site,"generation":r.generation,"count":count,"day":c.day}
	c.bandits.sync(c)
	c.world.load_raider_food(id,site,supply-c.world.raider_supply.packs[id].food)
	start(c,id,destination)
	c.world.log_event("A provisioned party leaves %s to establish another camp." % c.node(site).name)
	return true

func settle(c, id: String) -> void:
	var p: Dictionary = plans[id]; var site: String = p.target; var camp: Dictionary = c.world.camps[site]
	var source: Dictionary = c.bandits.bands[id]; var old: Dictionary = c.overworld.scouts[id]
	if not eligible(c,site,id) or camp.generation != p.generation or c.raiders.living(c,id) < 2: cancel(c,id); return
	camp.active = true; camp.strength = 1; camp.generation += 1; camp.next_raid = c.day
	var new_id: String = c.overworld.party_id(site,camp.generation)
	c.overworld.spawn_scout(site,camp.generation,1,c.overworld.places[site])
	var band: Dictionary = source.duplicate(true)
	band["lineage"] = source.get("lineage",id); band["inherited"] = source.next_member-source.get("base_capacity",source.capacity)-1
	band.mode = "recovering"; band.rest = 40; band.sortie = 0; band.chase = 0; band.fear = 0; band.care_day = 0
	c.bandits.bands[new_id] = band
	# The old record is retired, not killed. Every member ID and wound is carried into the new occupation.
	old.defeated = true; c.bandits.change_mode(source,old,"defeated")
	c.world.return_raider_food(id,site,c.world.raider_supply.packs[id].food)
	p.phase = "settled"; p.finished = c.overworld.tracks.clock; p.new_party = new_id
	founded[new_id] = {"source":id,"site":site,"generation":camp.generation,"day":c.day}
	c.bandits.sync(c)
	if c.raiders.danger.memories.has(id): c.raiders.danger.memories[new_id] = c.raiders.danger.memories[id].duplicate(true)
	c.world.log_event("A travelling band finishes rebuilding %s. Its existing members now occupy the camp." % c.node(site).name)

func description(c, id: String) -> String:
	if committed(id): return "Establishing a camp here. They can still be intercepted." if plans[id].phase == "building" else "A provisioned party is looking for a place to establish camp."
	return ""

func snapshot() -> Dictionary:
	return {"version":VERSION,"plans":plans.duplicate(true),"checks":checks.duplicate(),"expeditions":expeditions.duplicate(true),"founded":founded.duplicate(true)}

func restore(raw: Variant, c) -> bool:
	if not raw is Dictionary or raw.size() != 5 or raw.get("version") != VERSION or not c.raiders.enabled or not c.world.physical_founding: return false
	for field in ["plans","checks","expeditions","founded"]:
		if not raw.get(field) is Dictionary: return false
	var clock: int = c.overworld.tracks.clock; var targets = {}
	for id in raw.checks:
		if not c.overworld.scouts.has(id) or not raw.checks[id] is int or raw.checks[id] < 0 or raw.checks[id] > clock+RETRY_TICKS: return false
	for id in raw.plans:
		var p = raw.plans[id]
		if not c.overworld.scouts.has(id) or not p is Dictionary or p.size() != 8 or p.get("target") not in c.world.SITES or p.get("phase") not in ["travel","building","failed","settled"]: return false
		for field in ["generation","progress","paid","started","finished"]:
			if not p.get(field) is int or p[field] < 0: return false
		if p.generation < 1 or p.generation > c.world.camps[p.target].generation or p.progress > BUILD_TICKS or p.paid not in [0,BUILD_FOOD] or p.started > clock or p.finished > clock or not p.get("new_party") is String: return false
		if p.phase in ["travel","building"]:
			if c.overworld.scouts[id].defeated or targets.has(p.target) or c.world.camps[p.target].active or c.world.camps[p.target].generation != p.generation or p.finished != 0 or p.new_party != "": return false
			targets[p.target] = id
			if p.phase == "travel" and (p.progress != 0 or p.paid != 0): return false
			if p.phase == "building" and (p.paid != BUILD_FOOD or p.progress >= BUILD_TICKS): return false
		elif p.phase == "settled":
			if not raw.founded.has(p.new_party) or raw.founded[p.new_party].source != id or p.progress != BUILD_TICKS or p.paid != BUILD_FOOD or p.finished < p.started: return false
		elif p.progress != 0 or p.new_party != "" or p.finished < p.started: return false
	for id in raw.expeditions:
		var e = raw.expeditions[id]
		if not c.overworld.scouts.has(id) or not e is Dictionary or e.size() != 4: return false
		var s: Dictionary = c.overworld.scouts[id]
		if not s.get("expedition",false) or e.get("site") != s.site or e.get("generation") != s.generation or e.get("count") != c.bandits.bands[id].capacity or not e.get("day") is int or e.day < 1 or e.day > c.world.day: return false
	for id in raw.founded:
		var f = raw.founded[id]
		if not c.overworld.scouts.has(id) or not f is Dictionary or f.size() != 4 or not c.overworld.scouts.has(f.get("source","")): return false
		var s: Dictionary = c.overworld.scouts[id]; var previous: Dictionary = c.bandits.bands[f.source]; var b: Dictionary = c.bandits.bands[id]
		if f.get("site") != s.site or f.get("generation") != s.generation or s.generation < 2 or not f.get("day") is int or f.day < 1 or f.day > c.world.day or not c.overworld.scouts[f.source].defeated: return false
		if not raw.plans.has(f.source) or raw.plans[f.source].new_party != id: return false
		if b.get("lineage") != previous.get("lineage",f.source) or b.get("inherited") != previous.next_member-previous.get("base_capacity",previous.capacity)-1 or b.capacity != previous.capacity or b.rating != previous.rating or b.threat != previous.threat: return false
		for member in previous.fallen:
			if member not in b.fallen: return false
	for id in c.overworld.scouts:
		var s: Dictionary = c.overworld.scouts[id]; var b: Dictionary = c.bandits.bands[id]
		if s.get("expedition",false) != raw.expeditions.has(id) or b.has("lineage") != raw.founded.has(id): return false
		if b.mode in ["founding","building"] and (not raw.plans.has(id) or raw.plans[id].phase not in ["travel","building"]): return false
	for site in c.world.SITES:
		for generation in range(2,c.world.camps[site].generation+1):
			if not raw.founded.has(c.overworld.party_id(site,generation)): return false
	enabled = true; plans = raw.plans.duplicate(true); checks = raw.checks.duplicate(); expeditions = raw.expeditions.duplicate(true); founded = raw.founded.duplicate(true)
	return true
