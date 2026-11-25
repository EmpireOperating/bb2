extends RefCounted
## Raider decisions consume the same World food ledger as towns and freight.
const VERSION = 5
const Danger = preload("res://src/raider_danger.gd")
var danger = Danger.new()
var shares = preload("res://camp_shares/shares.gd").new()
var rules_version = VERSION
const FORAGE_TICKS = 120 # Six hours of uninterrupted work per carried ration.
const PACK_DAYS = 2
const CARRY_DAYS = 6
const BUFFER_DAYS = 3
const HUNGER_DAMAGE = 120
var enabled = false
var camps: Dictionary = {}
var bands: Dictionary = {}

func setup(c, active: bool) -> void:
	rules_version = c.starting_raider_rules() if c.economy.enabled else VERSION
	enabled = active and c.recon.enabled
	camps.clear(); bands.clear(); danger = Danger.new()
	if not enabled: return
	c.world.raider_supply = {"version":1,"packs":{}}
	sync(c)
	# Explicit world-generation stock, not daily production or a refill on load.
	for site in c.world.SITES:
		var amount = BUFFER_DAYS*population(c,site)
		c.world.camps[site].reserves += amount; c.world.initial_food += amount
		var id: String = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)].party
		c.world.load_raider_food(id,site,PACK_DAYS*living(c,id))
	c.overworld.raider_survival = true
	sync(c)

static func displaced(c, id: String) -> bool:
	var s: Dictionary = c.overworld.scouts[id]; var camp: Dictionary = c.world.camps[s.site]
	return not camp.active or camp.generation != s.generation

static func living(c, id: String) -> int:
	return c.bandits.bands[id].health.filter(func(hp):return hp > 0).size() if not c.overworld.scouts[id].defeated else 0

func residents(c, site: String) -> int:
	var generation: int = c.world.camps[site].generation
	var r: Dictionary = c.camp_life.records[c.camp_life.key(site,generation)]
	return c.recon.garrisons[c.recon.key(site,generation)].health.filter(func(hp):return hp > 0).size()+r.reserve+r.training.get("count",0)

func population(c, site: String) -> int:
	var r: Dictionary = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)]
	var count = residents(c,site)+living(c,r.party)
	if c.founding.enabled:
		for id in c.founding.expeditions:
			if c.overworld.scouts[id].site == site and not displaced(c,id): count += living(c,id)
	return count

func reserve_food(c, site: String) -> int:
	if rules_version == 1: return BUFFER_DAYS*population(c,site)
	var r: Dictionary = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)]
	var total = BUFFER_DAYS*residents(c,site)
	var parties: Array = [r.party]
	if c.founding.enabled:
		for id in c.founding.expeditions:
			if c.overworld.scouts[id].site == site and not displaced(c,id): parties.append(id)
	for id in parties: total += maxi(0,BUFFER_DAYS*living(c,id)-int(c.world.raider_supply.packs.get(id,{}).get("food",0)))
	return total

func can_invest(c, site: String, cost: int) -> bool:
	return not enabled or c.world.camp_food(site) >= cost+reserve_food(c,site)

func desired_stock(c, site: String) -> int:
	# Saving for actual replacements/expeditions is a reason to raid before starvation.
	var saving = 2*c.camp_life.RECRUIT_FOOD
	if c.founding.enabled:
		for target in c.world.SITES:
			if c.founding.eligible(c,target) and c.overworld.places[site].distance_to(c.overworld.places[target]) <= c.founding.MAX_DISTANCE:
				var people = c.founding.expedition_size(c,site)
				saving = maxi(saving,people*(c.camp_life.RECRUIT_FOOD+3)+mini(36,8*people))
	return reserve_food(c,site)+saving

func forage(c, site: String) -> int:
	var workers: int = c.recon.garrisons[c.recon.key(site,c.world.camps[site].generation)].health.filter(func(hp):return hp > 0).size()
	if rules_version == 1: return 2 if workers > 0 else 0
	var id: String = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)].party
	var party: Dictionary = c.overworld.scouts[id]
	if not party.defeated and party.position.distance_to(c.overworld.places[site]) <= 10 and c.overworld.pending != id and not c.guards.engaged(id) and not c.traffic.missions.has(id) and not c.farm.engaged(id):
		workers += living(c,id)
	return mini(c.camp_life.FORAGE,2*workers)

func patrol_escape(c, s: Dictionary) -> Dictionary:
	if not enabled or rules_version < 2: return {}
	var danger = {}; var distance = c.bandits.vision(c)
	for guard in c.guards.parties.values():
		if guard.mode not in ["patrolling","responding"] or guard.paid_day != c.day or c.guards.power(guard) <= c.bandits.power(s.id)*1.25: continue
		var d: float = s.position.distance_to(guard.position)
		if d < distance: danger = guard; distance = d
	if danger.is_empty(): return {}
	self.danger.remember(c,s.id,danger.position,"patrol")
	c.bandits.abandon_freight(c,s,"The raiders abandon their raid and flee the stronger town patrol.")
	c.bandits.bands[s.id].fear = 120
	c.bandits.change_mode(c.bandits.bands[s.id],s,"fleeing")
	return {"position":c.bandits.escape_point(c,s,danger.position),"pace":20.0}

func forage_order(c, s: Dictionary) -> Dictionary:
	var id: String = s.id; var b: Dictionary = c.bandits.bands[id]; var state: Dictionary = bands[id]
	if state.forage_day != c.day: state.forage_day = c.day; state.gathered = 0
	var mouths = living(c,id); var goal = carry_limit(c,id) if displaced(c,id) else PACK_DAYS*mouths
	var pack: Dictionary = c.world.raider_supply.packs[id]
	if mouths == 0 or pack.food >= goal or state.gathered >= mini(3,mouths+1): return {}
	var point: Vector2 = s.position
	if c.overworld.terrain(point) != "forest":
		if b.mode == "foraging" and not s.path.is_empty() and c.overworld.terrain(s.path.back()) == "forest": point = s.path.back()
		else:
			var best = INF; var choices: Array = []
			var cell: Vector2i = c.overworld.cell(s.position)
			for y in range(-5,6):
				for x in range(-5,6):
					var candidate: Vector2 = c.overworld.cell_point(cell+Vector2i(x,y))
					var distance: float = candidate.distance_to(s.position)
					if distance > c.bandits.vision(c) or not c.overworld.valid_point(candidate) or c.overworld.terrain(candidate) != "forest" or c.bandits.sheltered(c,candidate): continue
					choices.append({"point":candidate,"distance":distance})
			choices.sort_custom(func(a,b):return a.distance < b.distance)
			for candidate in choices.slice(0,8):
				if not c.overworld.route(s.position,candidate.point).is_empty(): point = candidate.point; best = candidate.distance; break
			if not is_finite(best): return {}
	c.bandits.change_mode(b,s,"foraging")
	if c.overworld.terrain(s.position) == "forest":
		s.path.clear(); s.replan = 0.0
		state.forage_ticks += 1
		if state.forage_ticks >= FORAGE_TICKS:
			state.forage_ticks = 0; state.gathered += 1
			pack.food += 1; pack.foraged += 1; c.world.produced += 1
	return {"position":point,"pace":17.0}

func sync(c) -> void:
	if not enabled: return
	danger.expire(c)
	for r in c.camp_life.records.values():
		var key: String = c.camp_life.key(r.site,r.generation)
		if not r.has("deserted"): r["deserted"] = 0; r["cancelled"] = 0
		if rules_version == 6:
			if not r.closed: shares.account(c,r.site)
			elif shares.accounts.has(key):
				var a: Dictionary = shares.accounts[key]
				a.lost += a.cash; a.cash = 0
		if not camps.has(key): camps[key] = {"last_day":c.day,"hunger":0,"eaten":0,"mouths":0}
	for id in c.overworld.scouts:
		if not bands.has(id):
			bands[id] = {"last_day":c.day,"hunger":0,"lost_home":0}
			if rules_version >= 2: bands[id].merge({"forage_ticks":0,"forage_day":c.day,"gathered":0})
		if rules_version >= 2 and c.bandits.bands[id].mode != "foraging": bands[id].forage_ticks = 0
		c.world.ensure_raider_pack(id)
		var s: Dictionary = c.overworld.scouts[id]
		if s.defeated:
			c.world.use_raider_pack(id,c.world.raider_supply.packs[id].food,"lost")
			continue
		if displaced(c,id):
			if bands[id].lost_home == 0:
				bands[id].lost_home = c.day; s.path.clear(); s.replan = 0.0
				c.world.log_event("A surviving band from %s is displaced. Its supplies and wounds remain." % c.node(s.site).name)
			continue
		if s.position.distance_to(c.overworld.places[s.site]) > 10 or c.overworld.pending == id or c.guards.engaged(id): continue
		if s.get("expedition",false): continue
		var pack: Dictionary = c.world.raider_supply.packs[id]
		var target = PACK_DAYS*living(c,id)
		if pack.food > target: c.world.return_raider_food(id,s.site,pack.food-target)
		var available = maxi(0,c.world.camp_food(s.site)-PACK_DAYS*residents(c,s.site))
		c.world.load_raider_food(id,s.site,mini(available,maxi(0,target-pack.food)))

func feed_camp(c, site: String) -> void:
	if not enabled: return
	var r: Dictionary = camps[c.camp_life.key(site,c.world.camps[site].generation)]
	if r.last_day == c.day: return
	r.last_day = c.day; r.mouths = residents(c,site)
	var eaten = mini(r.mouths,c.world.camp_food(site))
	if eaten > 0: c.world.spend_food(site,eaten)
	r.eaten += eaten; r.hunger = r.hunger+1 if eaten < r.mouths else 0
	if r.hunger >= 3:
		var g: Dictionary = c.recon.garrisons[c.recon.key(site,c.world.camps[site].generation)]
		for i in g.health.size(): g.health[i] = maxi(0,g.health[i]-HUNGER_DAMAGE)
		var recruits: Dictionary = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)]
		if recruits.reserve > 0:
			recruits.reserve -= 1; recruits.deserted += 1
		elif not recruits.training.is_empty():
			recruits.training.count -= 1; recruits.cancelled += 1
			if recruits.training.count == 0: recruits.training.clear()

func feed_bands(c) -> void:
	if not enabled: return
	for id in bands:
		var r: Dictionary = bands[id]; var s: Dictionary = c.overworld.scouts[id]
		if r.last_day == c.day: continue
		r.last_day = c.day
		if s.defeated: continue
		var mouths = living(c,id); var pack: Dictionary = c.world.raider_supply.packs[id]
		# Quiet woodland foraging sustains at most two people, with no stock for growth.
		if rules_version == 1 and bands[id].hunger > 0 and c.bandits.bands[id].mode == "recovering" and c.overworld.terrain(s.position) == "forest" and not c.guards.cover(c,s.position,c.bandits.power(id)):
			var gathered = mini(mini(2,mouths),maxi(0,mouths-pack.food))
			pack.food += gathered; pack.foraged += gathered; c.world.produced += gathered
		var eaten = mini(mouths,pack.food)
		c.world.use_raider_pack(id,eaten,"eaten")
		r.hunger = r.hunger+1 if eaten < mouths else 0
		if r.hunger >= 3:
			var b: Dictionary = c.bandits.bands[id]
			for i in b.capacity: b.health[i] = maxi(0,b.health[i]-HUNGER_DAMAGE)
			c.bandits.record_members(id)
			if b.health.all(func(hp):return hp == 0):
				s.defeated = true; c.bandits.change_mode(b,s,"defeated")
				c.bandits.abandon_freight(c,s,"The starving band collapses; the freight is freed.")
func daily(c) -> void:
	if not enabled: return
	sync(c)
	feed_bands(c)
	var budgets = {}; var growth_allowed = {}
	for site in c.world.SITES:
		if not c.world.camps[site].active: continue
		budgets[site] = reserve_food(c,site)
		if rules_version == 6:
			var a: Dictionary = shares.account(c,site)
			growth_allowed[site] = a.cash >= population(c,site)+1 and a.misses == 0 and not c.world.protected_road(site) and not c.guards.cover(c,c.overworld.places[site],200)
			budgets[site] += BUFFER_DAYS # Tomorrow’s additional resident also needs to eat.
		if population(c,site) == 0: c.world.clear_camp(site,c.world.camps[site].generation,"hunger and abandonment")
	# Existing paid growth/reoccupation, after mouths are fed; no abstract town-stock raid.
	c.world.raider_actions(budgets,growth_allowed)
	c.overworld.sync_scouts(c.world); c.bandits.sync(c)

func urgency(c, id: String) -> int:
	if not enabled or not bands.has(id): return 0
	if bands[id].hunger > 0: return 2
	var mouths = living(c,id)
	if c.world.raider_supply.packs[id].food < PACK_DAYS*mouths: return 1
	if not displaced(c,id) and c.world.camp_food(c.overworld.scouts[id].site) < BUFFER_DAYS*population(c,c.overworld.scouts[id].site): return 1
	return 0

func carry_limit(c, id: String) -> int:
	return mini(36,(8 if rules_version >= 2 else CARRY_DAYS)*living(c,id))

func wants_food(c, id: String) -> bool:
	if not enabled: return true
	if c.world.raider_supply.packs[id].food >= carry_limit(c,id): return false
	return displaced(c,id) or urgency(c,id) > 0 or (rules_version >= 2 and c.world.camp_food(c.overworld.scouts[id].site) < desired_stock(c,c.overworld.scouts[id].site))

func choose_freight(c, s: Dictionary, background: bool) -> String:
	var id: String = s.id; var b: Dictionary = c.bandits.bands[id]
	if c.founding.committed(id) or c.founding.regrouping(c,id): return ""
	if s.defeated or b.fear > 0: return ""
	var needs_food = wants_food(c,id)
	var urgent = urgency(c,id)
	if b.rest > 0 and urgent < 2: return ""
	if c.bandits.power(id) < (60 if urgent == 2 else 100): return ""
	var visible: bool = c.bandits.sees_company(c,s,background)
	if visible and c.bandits.company_power(c) > c.bandits.power(id)*(1.20 if urgent == 2 else 1.0): return ""
	var best = ""; var score = -1.0; var material = ""; var material_score = -1.0
	for wid in c.traffic.wagons:
		var v: Dictionary = c.traffic.wagons[wid]; var cargo: Dictionary = c.world.caravans[wid]
		if cargo.has("material"):
			if displaced(c,id): continue
			if rules_version < 3 and needs_food: continue
			if rules_version >= 3 and (urgent == 2 or c.world.raider_supply.packs[id].food < PACK_DAYS*living(c,id)): continue
			# Material wagons retain their existing road/camp ownership and hauling rules.
			if c.world.route_data(cargo.route).path[1] != s.site or c.world.protected_road(s.site): continue
		elif not needs_food: continue
		if cargo.status != "transit" or cargo.guarded or v.raider != "": continue
		var distance: float = s.position.distance_to(v.position)
		if distance > c.bandits.vision(c) or c.bandits.sheltered(c,v.position): continue
		# Only visible traffic is considered. No access to distant town stock or target coordinates.
		if c.guards.cover(c,v.position,c.bandits.power(id)*(1.35 if urgent == 2 else 1.0)): continue
		# An escort is not a protection flag. Keep every other stock risk gate.
		if visible and v.position.distance_to(c.overworld.position) < 100 and c.traffic.follow_wagon != wid: continue
		var take = cargo.material.amount if cargo.has("material") else mini(cargo.cargo,carry_limit(c,id)-c.world.raider_supply.packs[id].food)
		var value = float(take)/(20.0+distance*(2.0 if urgent == 2 else 1.0))
		if rules_version >= 3 and cargo.has("material"):
			if value > material_score: material = wid; material_score = value
		elif value > score: best = wid; score = value
	return material if best == "" and rules_version >= 3 else best

func order(c, s: Dictionary, background: bool) -> Dictionary:
	if not enabled: return {}
	var id: String = s.id; var b: Dictionary = c.bandits.bands[id]
	var homeless = displaced(c,id); var urgent = urgency(c,id)
	# Existing physical freight/farm missions remain the movement authority.
	if c.traffic.missions.has(id) or c.farm.engaged(id):
		if urgent == 2: b.rest = 0; b.sortie = 0; b.chase = 0
		if homeless:
			var farm_order: Dictionary = c.farm.order_for(c,id)
			if not farm_order.is_empty():
				c.bandits.change_mode(b,s,farm_order.mode)
				return farm_order
			var mission: Dictionary = c.traffic.order_for(s,c.overworld)
			if not mission.is_empty():
				c.bandits.change_mode(b,s,"raiding")
				return {"position":mission.position,"pace":17.0}
		return {}
	if not homeless:
		if c.world.raider_supply.packs[id].food < PACK_DAYS*living(c,id) and c.world.camp_food(s.site) > PACK_DAYS*residents(c,s.site):
			c.bandits.change_mode(b,s,"returning")
			return {"position":c.overworld.places[s.site],"pace":17.0}
		if c.world.raider_supply.packs[id].food > PACK_DAYS*living(c,id):
			c.bandits.change_mode(b,s,"returning")
			return {"position":c.overworld.places[s.site],"pace":14.0}
		if rules_version >= 2:
			var food_order = forage_order(c,s)
			if not food_order.is_empty(): return food_order
		if rules_version == 6 and urgent < 2 and b.fear == 0:
			var fence: Dictionary = shares.fence_order(c,s)
			if not fence.is_empty(): return fence
		if rules_version == 1 and urgent == 2 and not can_invest(c,s.site,living(c,id)):
			b.rest = 0; b.sortie = 0; b.chase = 0
			if c.overworld.terrain(s.position) == "forest" and not c.guards.cover(c,s.position,c.bandits.power(id)):
				c.bandits.change_mode(b,s,"recovering")
				return {"position":s.position,"pace":17.0}
		return {}
	# Displaced survivors retain their old route knowledge. No new base or members spawn.
	b.rest = 0; b.sortie = 0; b.chase = 0
	if not background and c.bandits.sees_company(c,s,false) and c.bandits.company_power(c) < c.bandits.power(id)*0.75:
		c.bandits.change_mode(b,s,"hunting")
		return {"position":c.overworld.position,"pace":19.0}
	var points: Array = c.bandits.circuit(c,s)
	if rules_version >= 2:
		var food_order = forage_order(c,s)
		if not food_order.is_empty(): return food_order
	if rules_version == 1 and urgent == 2 and c.overworld.terrain(s.position) == "forest" and not c.guards.cover(c,s.position,c.bandits.power(id)):
		c.bandits.change_mode(b,s,"recovering")
		return {"position":s.position,"pace":17.0}
	if s.position.distance_to(points[b.waypoint%points.size()]) < 10: b.waypoint = (b.waypoint+1)%points.size(); s.path.clear()
	c.bandits.change_mode(b,s,"scouting")
	return {"position":points[b.waypoint%points.size()],"pace":17.0}

func capture(c, id: String, shipment: String) -> int:
	if c.world.caravans[shipment].has("material"): return 0
	var amount = mini(c.world.caravans[shipment].cargo,carry_limit(c,id)-c.world.raider_supply.packs[id].food)
	if amount <= 0: return 0
	c.world.loot_raider_food(id,shipment,amount)
	c.world.caravans[shipment].guarded = true
	c.world.log_event("Raiding band takes %d food from %s and carries it away." % [amount,c.world.short_id(shipment)])
	return amount

func settle_band(c, id: String, won: bool) -> void:
	if not enabled or not won: return
	var amount: int = c.world.raider_supply.packs[id].food
	if amount == 0: return
	c.world.use_raider_pack(id,amount,"recovered"); c.food += amount
	c.note("Recovered %d carried rations from the defeated band." % amount)

func salvage_camp(c, site: String, generation: int) -> void:
	if not enabled or not c.world.camps[site].active or c.world.camps[site].generation != generation: return
	var amount: int = c.world.camps[site].reserves
	c.world.camps[site].reserves = 0; c.world.sold += amount; c.food += amount
	if amount > 0: c.note("Recovered %d stored rations. Captured wagons still belong to their towns." % amount)

func description(c, id: String) -> String:
	var state = "Hungry and taking greater risks." if bands[id].hunger > 0 else "Looking for food." if urgency(c,id) > 0 else "Carrying supplies."
	return ("Displaced survivors. " if displaced(c,id) else "Camp raiders. ")+state+(" Wary of recently seen danger." if not danger.zones(c,id).is_empty() else "")

func snapshot() -> Dictionary:
	var out = {"version":rules_version,"camps":camps.duplicate(true),"bands":bands.duplicate(true)}
	if rules_version == 6: out["shares"] = shares.snapshot()
	if rules_version >= 5: out["danger"] = danger.memories.duplicate(true)
	return out

func restore(raw: Variant, c) -> bool:
	if not raw is Dictionary or raw.get("version") not in [1,2,3,4,VERSION,6] or raw.size() != (5 if raw.get("version") == 6 else 4 if raw.get("version") == 5 else 3) or not raw.get("camps") is Dictionary or not raw.get("bands") is Dictionary: return false
	if not c.recon.enabled or c.world.raider_supply.is_empty() or raw.camps.size() != c.camp_life.records.size() or raw.bands.size() != c.overworld.scouts.size(): return false
	if c.world.raider_supply.packs.size() != raw.bands.size(): return false
	for key in c.camp_life.records:
		var r = raw.camps.get(key)
		if not r is Dictionary or r.size() != 4: return false
		for field in ["last_day","hunger","eaten","mouths"]:
			if not r.get(field) is int or r[field] < 0: return false
		if r.last_day < 1 or r.last_day > c.world.day or r.hunger >= c.world.day or r.mouths > 16: return false
	for id in c.overworld.scouts:
		var r = raw.bands.get(id); var s: Dictionary = c.overworld.scouts[id]
		if not r is Dictionary or r.size() != (6 if raw.version >= 2 else 3) or not c.world.raider_supply.packs.has(id): return false
		if raw.version >= 2:
			for field in ["forage_ticks","forage_day","gathered"]:
				if not r.get(field) is int: return false
			if r.forage_ticks < 0 or r.forage_ticks >= FORAGE_TICKS or r.forage_day < 1 or r.forage_day > c.world.day or r.gathered < 0 or r.gathered > 3: return false
			if c.bandits.bands[id].mode != "foraging" and r.forage_ticks != 0: return false
		elif c.bandits.bands[id].mode == "foraging": return false
		for field in ["last_day","hunger","lost_home"]:
			if not r.get(field) is int or r[field] < 0 or r[field] > c.world.day: return false
		if r.last_day < 1 or r.hunger >= c.world.day: return false
		if not s.defeated and displaced(c,id) != (r.lost_home > 0): return false
		if s.defeated and c.world.raider_supply.packs[id].food != 0: return false
	var candidate = Danger.new()
	if raw.version >= 5 and not candidate.restore(raw.get("danger"),c): return false
	danger = candidate
	enabled = true; rules_version = raw.version; camps = raw.camps.duplicate(true); bands = raw.bands.duplicate(true)
	return true
