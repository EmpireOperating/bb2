extends RefCounted
## Paid reconstruction and relief use the existing food, treasury and physical-wagon ledgers.
const VERSION = 1
const REPAIR_FOOD = 6
const REPAIR_CROWNS = 12
const HAUL_CROWNS = 8
const RELIEF_INTERVAL = 3
const SAFE_RADIUS = 120.0
const STATES = ["Raided","Repairs underway","Short of food","Recovering","Stable"]
var enabled = false
var last_day = 1
var towns: Dictionary = {}
var shipments: Dictionary = {}

func setup(c, active: bool) -> void:
	enabled = active and c.farm.regional and c.guards.enabled and c.traffic.enabled
	towns.clear(); shipments.clear(); last_day = c.day
	if not enabled: return
	for town in c.world.TOWNS: towns[town] = {"repairs":{},"last_relief":0,"report":{}}
	observe(c)

func safe(c, f) -> bool:
	if f.raid.get("phase") == "raiding": return false
	for s in c.overworld.scouts.values():
		if s.defeated or not c.world.camps[s.site].active or s.position.distance_to(f.position) > SAFE_RADIUS: continue
		var strength: float = c.bandits.power(s.id)
		if c.guards.cover(c,f.position,strength): continue
		if c.dungeons.active == "" and c.phase == "camp" and c.overworld.position.distance_to(f.position) < 60 and c.bandits.company_power(c) >= strength*0.85: continue
		return false
	return true

func repair_tick(c, f) -> void:
	if not enabled or f.damage == 0 or not safe(c,f): return
	var row: Dictionary = towns[f.town]; var key = str(f.incident)
	if not row.repairs.has(key):
		var council: Dictionary = c.world.factions[c.world.towns[f.town].owner]
		if council.treasury < REPAIR_CROWNS or c.world.towns[f.town].stock < REPAIR_FOOD: return
		council.treasury -= REPAIR_CROWNS; council.spent += REPAIR_CROWNS
		c.world.towns[f.town].stock -= REPAIR_FOOD; c.world.consumed += REPAIR_FOOD
		row.repairs[key] = {"started":c.day,"finished":0,"work":0}
		c.world.log_event("%s pays %d crowns and feeds its repair crew %d food. Work requires a safe farm." % [c.node(f.town).name,REPAIR_CROWNS,REPAIR_FOOD])
	f.damage -= 1; row.repairs[key].work += 1
	if f.damage == 0:
		row.repairs[key].finished = c.day
		c.world.log_event(f.title(c)+" is repaired. Harvest must still reach the market by cart.")

func incoming(c, town: String) -> Array:
	return c.world.caravans.keys().filter(func(id):return c.world.route_data(c.world.caravans[id].route).path[2] == town and c.world.caravans[id].status in ["waiting","transit","escort"])

func dispatch(c, town: String) -> String:
	if not enabled or not towns.has(town) or c.day < towns[town].last_relief+RELIEF_INTERVAL or not incoming(c,town).is_empty(): return ""
	var destination: Dictionary = c.world.towns[town]
	if destination.stock >= destination.demand*3: return ""
	var routes: Array = c.world.config.routes.filter(func(r):return r.path[2] == town)
	routes.sort_custom(func(a,b):return c.overworld.places[a.path[0]].distance_to(c.overworld.places[town]) < c.overworld.places[b.path[0]].distance_to(c.overworld.places[town]))
	for r in routes:
		var source: String = r.path[0]; var stock: Dictionary = c.world.towns[source]
		var council: Dictionary = c.world.factions[stock.owner]
		# Keep four days of food and two days of guard wages in the donor town.
		if stock.stock < r.cargo+maxi(24,stock.demand*4) or council.treasury < HAUL_CROWNS+2*c.world.config.politics.patrol_wage: continue
		if c.overworld.route(c.overworld.places[source],c.overworld.places[town]).is_empty(): continue
		var id = "wagon_%03d" % c.world.next_caravan
		if not c.world.launch(r.id): continue
		council.treasury -= HAUL_CROWNS; council.spent += HAUL_CROWNS
		shipments[id] = {"route":r.id,"day":c.day,"cost":HAUL_CROWNS}
		towns[town].last_relief = c.day
		c.traffic.sync(c)
		c.world.log_event("Relief %s: %s pays %d crowns to send %d surplus food to %s. The wagon can be attacked." % [c.world.short_id(id),c.node(source).name,HAUL_CROWNS,r.cargo,c.node(town).name])
		return id
	return ""

func daily(c) -> void:
	if not enabled or last_day == c.day: return
	last_day = c.day
	var ordered = c.world.TOWNS.duplicate()
	ordered.sort_custom(func(a,b):return float(c.world.towns[a].stock)/c.world.towns[a].demand < float(c.world.towns[b].stock)/c.world.towns[b].demand)
	for town in ordered: dispatch(c,town)
	observe(c)

func patrol_goal(c, id: String) -> Dictionary:
	if not enabled: return {}
	var town: String = c.guards.home_town(c,id); var f = c.farm.for_town(town)
	if f.raid.get("phase") in ["approach","raiding"]: return {"position":f.position,"reason":"Defending the farm"}
	if f.damage > 0: return {"position":f.position,"reason":"Holding the farm for repairs"}
	var cargos = incoming(c,town)
	cargos.sort_custom(func(a,b):return int(shipments.has(a)) > int(shipments.has(b)))
	for cargo in cargos:
		# Daily dispatch can precede physical wagon synchronization during instant rest.
		if not c.traffic.wagons.has(cargo): continue
		var w: Dictionary = c.world.caravans[cargo]; var v: Dictionary = c.traffic.wagons[cargo]
		if w.status == "transit" and not v.carried and v.position.distance_to(c.guards.home(c,id)) <= 360:
			return {"position":v.position,"reason":"Covering relief "+c.world.short_id(cargo) if shipments.has(cargo) else "Covering incoming supplies"}
	return {}

func state(c, town: String) -> String:
	var f = c.farm.for_town(town)
	if f.damage > 0 or f.raid.get("phase") == "raiding": return "Repairs underway" if towns[town].repairs.has(str(f.incident)) and safe(c,f) else "Raided"
	if c.world.towns[town].stock < c.world.towns[town].demand*3: return "Short of food"
	if f.incident > 0 and f.carts.values().filter(func(cart):return cart.cycle == f.incident and cart.status == "delivered" and not cart.recovered).size() < 2: return "Recovering"
	return "Stable"

func observe(c) -> void:
	if enabled and c.in_town(): hear(c,c.location)

func hear(c, town: String) -> bool:
	if not enabled or not c.in_town() or c.location != town: return false
	var f = c.farm.for_town(town); var repair: Dictionary = towns[town].repairs.get(str(f.incident),{})
	var aid: Array = []
	for id in shipments.keys().slice(-24):
		var w: Dictionary = c.world.caravans[id]; var r: Dictionary = c.world.route_data(w.route)
		if town not in [r.path[0],r.path[2]]: continue
		aid.append({"id":id,"status":w.status,"food":w.cargo,"from":r.path[0],"to":r.path[2]})
	towns[town].report = {"day":c.day,"hour":c.overworld.hour,"state":state(c,town),"stock":c.world.towns[town].stock,"price":c.world.price(town),"damage":f.damage,"paid":not repair.is_empty(),"safe":safe(c,f),"output":f.output(c.world),"delivered":f.delivered,"aid":aid.slice(-3)}
	return true

func snapshot() -> Dictionary:
	return {"version":VERSION,"last_day":last_day,"towns":towns.duplicate(true),"shipments":shipments.duplicate(true)}

func restore(raw: Variant, w, farms, traffic) -> bool:
	if not raw is Dictionary or raw.get("version") != VERSION or raw.get("last_day") != w.day or not farms.regional or not traffic.enabled: return false
	if not raw.get("towns") is Dictionary or raw.towns.size() != w.TOWNS.size() or not raw.get("shipments") is Dictionary: return false
	var charges = {}; var food = 0; var last = {}
	for faction in w.FACTIONS: charges[faction] = 0
	for town in w.TOWNS: last[town] = 0
	for id in raw.shipments:
		var s = raw.shipments[id]
		if not s is Dictionary or s.size() != 3 or not w.caravans.has(id) or s.get("route") != w.caravans[id].route or s.get("cost") != HAUL_CROWNS or not s.get("day") is int: return false
		if s.day < RELIEF_INTERVAL or s.day > w.day or w.caravans[id].depart_day != s.day+1: return false
		var r: Dictionary = w.route_data(s.route)
		charges[w.towns[r.path[0]].owner] += HAUL_CROWNS; last[r.path[2]] = maxi(last[r.path[2]],s.day)
	for town in w.TOWNS:
		var t = raw.towns.get(town); var f = farms.for_town(town)
		if not t is Dictionary or t.size() != 3 or not t.get("repairs") is Dictionary or t.get("last_relief") != last[town] or not t.get("report") is Dictionary: return false
		for key in t.repairs:
			if not key is String or not key.is_valid_int() or str(int(key)) != key or int(key) < 1 or int(key) > f.incident: return false
			var r = t.repairs[key]
			if not r is Dictionary or r.size() != 3: return false
			for field in ["started","finished","work"]:
				if not r.get(field) is int or r[field] < 0: return false
			if r.started < 1 or r.started > w.day or r.finished > w.day or r.work < 1 or r.work > f.REPAIR_TICKS: return false
			if (r.work == f.REPAIR_TICKS) != (r.finished >= r.started): return false
			if int(key) == f.incident and f.damage != f.REPAIR_TICKS-r.work: return false
			if int(key) < f.incident and r.work != f.REPAIR_TICKS: return false
			charges[w.towns[town].owner] += REPAIR_CROWNS; food += REPAIR_FOOD
		if f.damage > 0 and not t.repairs.has(str(f.incident)) and f.damage != f.REPAIR_TICKS: return false
		var r: Dictionary = t.report
		if not r.is_empty():
			if r.size() != 11 or not r.get("day") is int or r.day < 1 or r.day > w.day or r.get("state") not in STATES: return false
			if not (r.get("hour") is int or r.get("hour") is float) or not is_finite(r.hour) or r.hour < 0 or r.hour >= 24: return false
			for field in ["stock","price","damage","output","delivered"]:
				if not r.get(field) is int or r[field] < 0: return false
			if r.damage > f.REPAIR_TICKS or r.output > f.capacity(w) or not r.get("paid") is bool or not r.get("safe") is bool or not r.get("aid") is Array or r.aid.size() > 3: return false
			for a in r.aid:
				if not a is Dictionary or a.size() != 5 or not raw.shipments.has(a.get("id")): return false
				var route = w.route_data(raw.shipments[a.id].route)
				if a.get("from") != route.path[0] or a.get("to") != route.path[2] or town not in route.path or a.get("status") not in ["waiting","transit","seized","escort","delivered","plundered"] or not a.get("food") is int or a.food < 0 or a.food > route.cargo: return false
	if food > w.consumed: return false
	for faction in charges:
		if charges[faction] > w.factions[faction].spent: return false
	enabled = true; last_day = raw.last_day; towns = raw.towns.duplicate(true); shipments = raw.shipments.duplicate(true)
	for town in towns:
		if not towns[town].report.is_empty(): towns[town].report.hour = snappedf(float(towns[town].report.hour),0.05)
	return true
