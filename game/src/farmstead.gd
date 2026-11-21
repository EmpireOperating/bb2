extends RefCounted
## One rural producer. The farm manager advances each town independently.
const VERSION = 1
var town = "ashwick"
var regional = false
var initial_store = LOAD
var identified = false
var geometry: Dictionary = {}
var report: Dictionary = {"day":0,"damaged":false}
var evidence: Dictionary = {"day":0,"generation":0,"inspected":false}
const LOAD = 24
const RAID_TICKS = 80
const REPAIR_TICKS = 960
const COMMISSION_PAY = 60
var enabled = false
var position = Vector2.ZERO
var camp = ""
var stock = 0
var damage = 0
var cooldown = 0
var incident = 0
var harvested = 0
var delivered = 0
var stolen = 0
var next_cart = 1
var carts: Dictionary = {}
var raid: Dictionary = {}
var commission: Dictionary = {}
var claimed = 0

static func layout(ow, world, town_id: String = "ashwick", assigned: String = "", occupied: Array = []) -> Dictionary:
	var town: Vector2 = ow.places[town_id]; var site = assigned; var nearest = INF
	for candidate in world.adjacent_sites(town_id):
		if not assigned.is_empty(): break
		var distance: float = town.distance_to(ow.places[candidate])
		if distance < nearest: site = candidate; nearest = distance
	var choices: Array = []
	for y in ow.SIZE.y:
		for x in ow.SIZE.x:
			var p: Vector2 = ow.cell_point(Vector2i(x,y))
			var distance = town.distance_to(p)
			if not ow.valid_point(p) or distance < 100 or distance > 210: continue
			if occupied.any(func(other):return other.distance_to(p) < 56): continue
			if ow.places.keys().any(func(k):return not str(k).begins_with("dungeon_") and ow.places[k].distance_to(p) < 40): continue
			var score = absf(distance-125)+p.distance_to(ow.places[site])*0.55+(0 if ow.terrain(p) in ["plains","road"] else 24)
			choices.append({"position":p,"score":score})
	choices.sort_custom(func(a,b):return a.score < b.score)
	for choice in choices:
		if not ow.route(town,choice.position).is_empty() and not ow.route(ow.places[site],choice.position).is_empty(): return {"position":choice.position,"camp":site}
	return {}

func setup(c, active: bool) -> void:
	enabled = active
	if not enabled: return
	var place = geometry if regional else layout(c.overworld,c.world,town)
	assert(not place.is_empty(),"Generated map must have a reachable farm")
	position = place.position; camp = place.camp
	stock = dispatch_load(c.world); initial_store = stock
	c.world.towns[town].stock -= stock # Transfer existing food; never mint starting supplies.
	var entry = {"town":town,"food":stock,"output":capacity(c.world)}
	if town == "ashwick": c.world.farm_supply = entry
	else: c.world.farm_supply.sites[town] = entry

func title(c) -> String:
	return c.node(town).name+" Croft"

func output(world) -> int:
	return 0 if damage > 0 or raid.get("phase") == "raiding" else capacity(world)

func held_food() -> int:
	var held = stock+int(raid.get("loot",0))
	for cart in carts.values():
		if cart.status == "transit": held += cart.cargo
	return held

func balanced() -> bool:
	return initial_stock()+harvested == held_food()+delivered+stolen

func owns_raid(id: String) -> bool:
	return enabled and raid.get("party") == id

func secure(c) -> bool:
	if c.rebuilding.enabled: return c.rebuilding.safe(c,self)
	if c.world.protected_road(camp): return true
	var sid: String = c.overworld.current_party(c.world,camp)
	if c.overworld.scouts[sid].defeated or c.guards.cover(c,position,c.bandits.power(sid)): return true
	return c.dungeons.active == "" and c.phase == "camp" and c.overworld.position.distance_to(position) < 60 and c.bandits.company_power(c) >= c.bandits.power(sid)*0.85

func sync(c) -> void:
	if not enabled: return
	if not raid.is_empty():
		var s: Dictionary = c.overworld.scouts[raid.party]
		if s.defeated or c.world.protected_road(s.site): abandon(c,s.id,"The threat is driven off; the farm's harvest is freed.")
	supply(c.world).output = output(c.world)

func launch(c, at: Vector2, amount: int, recovered: bool = false) -> void:
	var id = "harvest_%03d" % next_cart; next_cart += 1
	carts[id] = {"position":at,"path":[],"cargo":amount,"status":"transit","depart_day":c.day,"delivered_day":0,"recovered":recovered,"cycle":incident}
	c.world.log_event("%s sends %d food toward %s%s." % [title(c),amount,c.node(town).name," from recovered harvest" if recovered else ""])

func daily(c) -> void:
	if not enabled: return
	# World.tick has already booked this day's actual rural production.
	var amount: int = supply(c.world).output
	stock += amount; harvested += amount
	if (not c.raiders.enabled or c.raiders.rules_version < 3) and damage == 0 and raid.get("phase") != "raiding" and stock >= dispatch_load(c.world):
		var load_size = dispatch_load(c.world)
		stock -= load_size; launch(c,position,load_size)
	sync(c)

func dispatch_harvest(c) -> void:
	if not c.raiders.enabled or c.raiders.rules_version < 3: return
	# Harvest is stored overnight, then a real cart leaves after 08:00. An approaching
	# raid holds dispatch; last ordinary departure makes repeated calls idempotent.
	if c.overworld.hour < 8 or damage > 0 or not raid.is_empty() or stock < dispatch_load(c.world): return
	if carts.values().any(func(cart):return not cart.recovered and cart.depart_day == c.day): return
	var load_size = dispatch_load(c.world)
	stock -= load_size; launch(c,position,load_size)

func before_step(c, background: bool = false) -> void:
	if not enabled: return
	sync(c)
	if not raid.is_empty() or damage > 0 or stock < (mini(12,dispatch_load(c.world)) if regional else 12) or cooldown > 0 or secure(c): return
	var sid: String = c.overworld.current_party(c.world,camp)
	var s: Dictionary = c.overworld.scouts[sid]; var b: Dictionary = c.bandits.bands[sid]
	if c.founding.committed(sid): return
	if c.raiders.enabled and not c.raiders.wants_food(c,sid): return
	if c.farm.engaged(sid) or s.defeated or c.guards.engaged(sid) or c.traffic.missions.has(sid) or b.rest > 0 or b.fear > 0 or b.sortie >= c.bandits.SORTIE_TICKS or b.chase >= 80 or c.bandits.power(sid) < (100 if regional else 260): return
	if s.position.distance_to(position) > c.bandits.vision(c): return
	if c.bandits.sees_company(c,s,background) and c.bandits.company_power(c) > c.bandits.power(sid)*1.1: return
	raid = {"party":sid,"phase":"approach","remaining":RAID_TICKS,"loot":0}
	s.path.clear(); s.replan = 0.0

func order_for(c, id: String) -> Dictionary:
	if not owns_raid(id): return {}
	return {"position":c.overworld.places[camp] if raid.phase == "return" else position,"mode":"hauling" if raid.phase == "return" else "raiding","pace":14.0 if raid.phase == "return" else 17.0}

func abandon(c, id: String, reason: String) -> void:
	if not owns_raid(id): return
	if raid.loot > 0: launch(c,c.overworld.scouts[id].position,raid.loot,true)
	var contested: bool = raid.phase != "approach"
	raid.clear(); cooldown = maxi(cooldown,120)
	if contested: c.world.log_event(reason)
	supply(c.world).output = output(c.world)

func settle(c, id: String, won: bool) -> String:
	if not won or not owns_raid(id): return ""
	var message = "Farm raiders defeated. Recovered harvest returns to town; repairs need a safe farm."
	abandon(c,id,message)
	return message

func after_step(c, background: bool = false) -> void:
	if not enabled: return
	var ow = c.overworld; var world = c.world
	dispatch_harvest(c)
	cooldown = maxi(0,cooldown-1)
	for id in carts:
		var cart: Dictionary = carts[id]
		if cart.status != "transit": continue
		if cart.path.is_empty(): cart.path = ow.route(cart.position,ow.places[town])
		cart.position = ow.advance_party(cart.position,cart.path,ow.STEP,14.0)
		if cart.position.distance_to(ow.places[town]) < 1 and cart.path.is_empty():
			var before: int = world.price(town)
			cart.status = "delivered"; cart.delivered_day = c.day
			supply(world).food -= cart.cargo
			world.towns[town].stock += cart.cargo; world.towns[town].delivered += cart.cargo
			delivered += cart.cargo
			if not commission.is_empty() and damage == 0 and not cart.recovered and cart.cycle == incident and cart.cycle >= commission.incident:
				commission.received = mini(LOAD,commission.received+cart.cargo)
			world.log_event("Farm delivery: %d food reaches %s. Price %d -> %d crowns / 24." % [cart.cargo,c.node(town).name,before,world.price(town)])
	if not raid.is_empty() and ow.pending != raid.party:
		var s: Dictionary = ow.scouts[raid.party]
		if raid.phase == "return":
			if s.position.distance_to(ow.places[camp]) < 12:
				world.camps[camp].reserves += raid.loot; world.camps[camp].stolen += raid.loot
				supply(world).food -= raid.loot; stolen += raid.loot
				world.log_event("Raiders haul %d stolen farm food into %s." % [raid.loot,c.node(camp).name])
				raid.clear()
		elif s.position.distance_to(position) < 18:
			if raid.phase == "approach":
				raid.phase = "raiding"
				world.log_event(title(c)+" is under attack. Reach the raiders before the harvest is lost.")
				if not background and ow.position.distance_to(position) < ow.sight(): ow.paused = true
			else:
				raid.remaining -= 1
				if raid.remaining == 0:
					raid.loot = mini(LOAD,stock); stock -= raid.loot; raid.phase = "return"
					damage = REPAIR_TICKS; incident += 1; cooldown = 720
					if regional: evidence = {"day":c.day,"generation":s.generation,"inspected":false}
					if not commission.is_empty(): commission.received = 0
					s.path.clear(); s.replan = 0.0
					world.log_event("%s is raided. Production stops; %d food is being hauled away. %s needs its supply restored." % [title(c),raid.loot,c.node(town).name])
	if c.rebuilding.enabled: c.rebuilding.repair_tick(c,self)
	elif damage > 0 and secure(c) and (not c.economy.enabled or c.economy.industry.farm_ready(town,incident)):
		damage -= 1
		if damage == 0: world.log_event(title(c)+" is repaired. Food production resumes; fresh deliveries must still reach town.")
	sync(c)

func at_client(c) -> bool:
	return c.phase == "camp" and not c.over() and c.encounter.is_empty() and c.in_town() and c.location == town

func can_accept(c) -> bool:
	return enabled and at_client(c) and damage > 0 and incident > claimed and commission.is_empty() and c.world.factions[c.world.towns[town].owner].treasury >= COMMISSION_PAY

func accept(c) -> bool:
	if not can_accept(c): return false
	var owner: String = c.world.towns[town].owner; var council: Dictionary = c.world.factions[owner]
	council.treasury -= COMMISSION_PAY; council.spent += COMMISSION_PAY
	commission = {"incident":incident,"received":0,"escrow":COMMISSION_PAY,"owner":owner}
	c.note("Farm commission: restore production and deliver another %d food to %s. %d crowns held for payment on return." % [LOAD,c.node(town).name,COMMISSION_PAY])
	return true

func ready() -> bool:
	return not commission.is_empty() and damage == 0 and commission.received >= LOAD

func claim(c) -> bool:
	if not at_client(c) or not ready(): return false
	c.crowns += commission.escrow; claimed = incident
	commission.clear()
	c.note("Farm supply restored: %d crowns paid. Fresh food has reached town." % COMMISSION_PAY)
	return true

func cancel(c) -> bool:
	if not enabled or commission.is_empty() or c.phase != "camp" or not c.encounter.is_empty(): return false
	var council: Dictionary = c.world.factions[commission.owner]
	council.treasury += commission.escrow; council.spent -= commission.escrow
	commission.clear(); c.note("Farm commission cancelled unpaid. Reserved crowns return to the council.")
	return true

func snapshot() -> Dictionary:
	var result = {"version":VERSION,"position":[position.x,position.y],"camp":camp,"stock":stock,"damage":damage,"cooldown":cooldown,"incident":incident,"harvested":harvested,"delivered":delivered,"stolen":stolen,"next_cart":next_cart,"claimed":claimed,"raid":raid.duplicate(true),"commission":commission.duplicate(true),"carts":carts.duplicate(true)}
	for cart in result.carts.values():
		cart.position = [cart.position.x,cart.position.y]; cart.path = cart.path.map(func(p):return [p.x,p.y])
	if regional:
		result["identified"] = identified
		result["town"] = town; result["report"] = report.duplicate(); result["evidence"] = evidence.duplicate()
	return result

func restore(d: Variant, ow, world) -> bool:
	if not d is Dictionary or d.get("version") != VERSION or not ow.valid_xy(d.get("position")) or not d.get("carts") is Dictionary or not d.get("raid") is Dictionary or not d.get("commission") is Dictionary: return false
	var place = geometry if regional else layout(ow,world,town)
	initial_store = dispatch_load(world)
	if place.is_empty() or Vector2(d.position[0],d.position[1]) != place.position or d.get("camp") != place.camp: return false
	for key in ["stock","damage","cooldown","incident","harvested","delivered","stolen","next_cart","claimed"]:
		if not d.get(key) is int or d[key] < 0: return false
	if d.damage > REPAIR_TICKS or d.cooldown > 720 or d.claimed > d.incident or d.next_cart != d.carts.size()+1: return false
	var held: int = d.stock; var received = 0
	for id in d.carts:
		var cart = d.carts[id]
		if not id is String or not id.begins_with("harvest_") or not id.trim_prefix("harvest_").is_valid_int() or int(id.trim_prefix("harvest_")) < 1 or int(id.trim_prefix("harvest_")) >= d.next_cart: return false
		if not cart is Dictionary or not ow.valid_xy(cart.get("position")) or cart.get("status") not in ["transit","delivered"] or not cart.get("path") is Array or cart.path.size() > 1800 or not cart.get("recovered") is bool: return false
		for point in cart.path:
			if not ow.valid_xy(point): return false
		if not ow.valid_route(cart.position,cart.path): return false
		for key in ["cargo","depart_day","delivered_day","cycle"]:
			if not cart.get(key) is int or cart[key] < 0: return false
		if cart.cargo < 1 or cart.cargo > LOAD or cart.depart_day < 1 or cart.depart_day > world.day or cart.delivered_day > world.day: return false
		if cart.cycle > d.incident: return false
		if cart.status == "delivered":
			if cart.delivered_day < cart.depart_day or not cart.path.is_empty() or Vector2(cart.position[0],cart.position[1]) != ow.places[town]: return false
			received += cart.cargo
		else:
			if cart.delivered_day != 0: return false
			held += cart.cargo
	if not d.raid.is_empty():
		var r: Dictionary = d.raid
		if not r.get("party") is String or not ow.scouts.has(r.party) or ow.scouts[r.party].defeated or ow.scouts[r.party].site != d.camp: return false
		if r.get("phase") not in ["approach","raiding","return"] or not r.get("remaining") is int or not r.get("loot") is int: return false
		if r.remaining < 0 or r.remaining > RAID_TICKS or r.loot < 0 or r.loot > LOAD: return false
		if r.phase == "return":
			if r.remaining != 0 or d.incident == 0: return false
		elif r.loot != 0 or r.remaining == 0 or d.damage != 0: return false
		held += r.loot
	if d.delivered != received or initial_stock()+d.harvested != held+d.delivered+d.stolen: return false
	if supply(world).get("town") != town or supply(world).get("food") != held: return false
	if supply(world).get("output") != (0 if d.damage > 0 or d.raid.get("phase") == "raiding" else capacity(world)): return false
	if not d.commission.is_empty():
		var job: Dictionary = d.commission
		for key in ["incident","received","escrow"]:
			if not job.get(key) is int: return false
		if job.incident < 1 or job.incident > d.incident or job.incident <= d.claimed or job.received < 0 or job.received > LOAD or job.received > d.delivered or job.escrow != COMMISSION_PAY or job.get("owner") != world.towns[town].owner: return false
		if world.factions[job.owner].spent < job.escrow: return false
	if regional:
		if not d.get("identified") is bool or d.get("town") != town or not d.get("report") is Dictionary or not d.get("evidence") is Dictionary: return false
		var r = d.report; var e = d.evidence
		if r.size() != 2 or not r.get("day") is int or r.day < 0 or r.day > world.day or not r.get("damaged") is bool: return false
		if r.day == 0 and r.damaged: return false
		if e.size() != 3 or not e.get("day") is int or not e.get("generation") is int or not e.get("inspected") is bool: return false
		if e.day < 0 or e.day > world.day or e.generation < 0 or e.generation > world.camps[place.camp].generation: return false
		if (e.day == 0) != (e.generation == 0) or (d.incident == 0) != (e.day == 0) or e.inspected and e.day == 0: return false
		if e.inspected and not d.identified or d.identified and e.day == 0: return false
		identified = d.identified; report = r.duplicate(); evidence = e.duplicate()
	elif d.has("identified") or d.has("town") or d.has("report") or d.has("evidence"): return false
	enabled = true; position = place.position; camp = place.camp
	for key in ["stock","damage","cooldown","incident","harvested","delivered","stolen","next_cart","claimed"]: set(key,d[key])
	raid = d.raid.duplicate(true); commission = d.commission.duplicate(true); carts = d.carts.duplicate(true)
	for cart in carts.values(): cart.position = Vector2(cart.position[0],cart.position[1]); cart.path = ow.unpack_path(cart.path)
	return true

func supply(world) -> Dictionary:
	return world.farm_supply if town == "ashwick" else world.farm_supply.get("sites",{}).get(town,{})

func capacity(world) -> int:
	return maxi(4,int(world.towns[town].production)) if regional else int(world.towns[town].production)

func dispatch_load(world) -> int:
	return mini(LOAD,capacity(world)) if regional else LOAD

func initial_stock() -> int:
	return initial_store

func hear_report(c) -> bool:
	if not regional or not at_client(c): return false
	report = {"day":c.day,"damaged":damage > 0}
	c.note("%s report: %s. %d food in town; market %dc / 24. %s" % [c.node(town).name,"farm raided" if damage > 0 else "farm working",c.world.towns[town].stock,c.world.price(town),"Visit the farm and inspect the raid tracks." if evidence.day > 0 else "Farm and connecting path marked; surrounding country remains unexplored."])
	return true

func inspect(c) -> bool:
	if not regional or evidence.day == 0 or evidence.inspected or c.phase != "camp" or c.over() or not c.encounter.is_empty() or c.overworld.position.distance_to(position) > 20: return false
	evidence.inspected = true; identified = true
	c.note("The farm was raided. Search the nearby ground for fresh prints; old tracks do not identify a camp." if c.overworld.tracks.enabled else "Tracks from the day %d raid lead to %s. They record that attack, not the camp's current strength." % [evidence.day,c.node(camp).name])
	return true
