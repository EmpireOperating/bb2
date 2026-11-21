extends RefCounted
## Deterministic daily supply simulation. Food is transferred, never conjured by a reward.
const TOWNS = ["ashwick", "stonecross", "dunmere"]
const SITES = ["ford", "forest", "ridge"]
var config: Dictionary = normalize(JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy_world_v4.json")))
var day = 1
var towns: Dictionary = {}
var camps: Dictionary = {}
var caravans: Dictionary = {}
var next_launch: Dictionary = {}
var next_caravan = 1
var events: Array = []
var event_seq = 0
var produced = 0
var consumed = 0
var sold = 0
var initial_food = 0

func setup(start_day: int = 1) -> void:
	day = start_day
	towns = config.towns.duplicate(true)
	camps.clear()
	caravans.clear()
	next_launch.clear()
	next_caravan = 1
	events.clear()
	event_seq = 0
	produced = 0
	consumed = 0
	sold = 0
	initial_food = 0
	for town in towns:
		initial_food += towns[town].stock
		towns[town]["delivered"] = 0
		towns[town]["shortage_days"] = 0
	for site in SITES:
		camps[site] = {"active":true, "strength":config.camps[site].strength, "generation":1, "return_day":0, "cleared_day":0}
	for route in config.routes:
		launch(route.id)
		next_launch[route.id] = day+route.period

func route_data(id: String) -> Dictionary:
	for route in config.routes:
		if route.id == id: return route
	return {}

func log_event(message: String) -> void:
	event_seq += 1
	events.append({"id":event_seq, "day":day, "text":message})
	if events.size() > 200: events.pop_front()

func price(town: String) -> int:
	if not towns.has(town): return 0
	return int(towns[town].base_price)+ceili(maxf(0.0, 120.0-float(towns[town].stock))/3.0)

func buy_food(town: String, amount: int = 24) -> bool:
	if not towns.has(town) or amount <= 0 or towns[town].stock < amount: return false
	towns[town].stock -= amount
	sold += amount
	log_event("The company buys %d food from %s." % [amount, town.capitalize()])
	return true

func launch(route_id: String) -> bool:
	var route = route_data(route_id)
	if route.is_empty(): return false
	var origin: String = route.path[0]
	if towns[origin].stock < route.cargo+24: return false
	towns[origin].stock -= route.cargo
	var id = "wagon_%03d" % next_caravan
	next_caravan += 1
	caravans[id] = {"id":id, "route":route_id, "cargo":route.cargo, "status":"waiting", "index":0, "remaining":route.days[0], "depart_day":day+1, "guarded":false, "recovered":false, "delivered_day":0, "seized_day":0}
	log_event("%s loads %d food for %s; leaves day %d." % [short_id(id), route.cargo, str(route.path[2]).capitalize(), day+1])
	return true

func short_id(id: String) -> String:
	return "W"+id.trim_prefix("wagon_")

func shipment_at(id: String) -> String:
	if not caravans.has(id): return ""
	var c = caravans[id]
	return route_data(c.route).path[c.index]

func seized_food(site: String) -> int:
	var total = 0
	for c in caravans.values():
		if c.status == "seized" and shipment_at(c.id) == site: total += c.cargo
	return total

func tick() -> void:
	day += 1
	for town in towns:
		var t: Dictionary = towns[town]
		t.stock += t.production
		produced += t.production
		var eaten = mini(t.stock, t.demand)
		t.stock -= eaten
		consumed += eaten
		if eaten < t.demand: t.shortage_days += 1
	for site in camps:
		var camp: Dictionary = camps[site]
		if not camp.active and day >= camp.return_day:
			camp.active = true
			camp.generation += 1
			camp.strength = mini(3, int(camp.strength)+1)
			camp.return_day = 0
			log_event("A new raider band occupies %s. Wagon traffic is at risk again." % site.capitalize())
	for c in caravans.values():
		if c.status == "waiting" and day >= c.depart_day: c.status = "transit"
		if c.status != "transit": continue
		c.remaining -= 1
		if c.remaining > 0: continue
		c.index += 1
		if c.index == 2:
			deliver(c.id)
			continue
		var site = shipment_at(c.id)
		if camps[site].active and not c.guarded: seize(c.id)
		else: c.remaining = route_data(c.route).days[c.index]
	for route in config.routes:
		if day >= next_launch[route.id]:
			if launch(route.id): next_launch[route.id] = day+route.period
			else: next_launch[route.id] = day+1

func seize(id: String) -> bool:
	if not caravans.has(id): return false
	var c: Dictionary = caravans[id]
	if not c.status in ["transit", "escort"] or c.index != 1: return false
	c.status = "seized"
	c.remaining = 0
	c.seized_day = day
	log_event("Raiders at %s seize %s: %d food never reaches %s." % [shipment_at(id).capitalize(), short_id(id), c.cargo, str(route_data(c.route).path[2]).capitalize()])
	return true

func deliver(id: String) -> bool:
	if not caravans.has(id): return false
	var c: Dictionary = caravans[id]
	if not c.status in ["transit", "escort"] or c.index != 2: return false
	var destination: String = route_data(c.route).path[2]
	var before = price(destination)
	towns[destination].stock += c.cargo
	towns[destination].delivered += c.cargo
	c.status = "delivered"
	c.remaining = 0
	c.delivered_day = day
	log_event("%s delivers %d food to %s. Price: %d -> %d crowns / 24." % [short_id(id), c.cargo, destination.capitalize(), before, price(destination)])
	return true

func recover_shipment(id: String) -> bool:
	if not caravans.has(id) or caravans[id].status != "seized": return false
	var c: Dictionary = caravans[id]
	c.status = "transit"
	c.recovered = true
	c.guarded = true
	c.remaining = route_data(c.route).days[1]
	log_event("%s recovered: %d food resumes its journey to %s." % [short_id(id), c.cargo, str(route_data(c.route).path[2]).capitalize()])
	return true

func clear_camp(site: String, generation: int) -> bool:
	if not camps.has(site) or not camps[site].active or camps[site].generation != generation: return false
	camps[site].active = false
	camps[site].cleared_day = day
	camps[site].return_day = day+9
	log_event("%s cleared. Wagon road secured until day %d." % [site.capitalize(), day+9])
	for c in caravans.values():
		if c.status == "seized" and shipment_at(c.id) == site: recover_shipment(c.id)
	return true

func reserve_escort(id: String) -> bool:
	if not caravans.has(id) or caravans[id].status != "waiting": return false
	caravans[id].status = "escort"
	log_event("The company takes charge of %s and its %d food." % [short_id(id), caravans[id].cargo])
	return true

func escort_next(id: String) -> String:
	if not caravans.has(id) or caravans[id].status != "escort": return ""
	var c: Dictionary = caravans[id]
	if c.index >= 2: return ""
	if c.index == 1 and camps[shipment_at(id)].active and not c.guarded: return ""
	return route_data(c.route).path[c.index+1]

func escort_arrive(id: String, target: String) -> bool:
	if escort_next(id) != target or target.is_empty(): return false
	var c: Dictionary = caravans[id]
	c.index += 1
	c.remaining = 0
	if c.index == 2: return deliver(id)
	log_event("%s reaches %s under company escort." % [short_id(id), target.capitalize()])
	return true

func release_escort(id: String) -> bool:
	if not caravans.has(id) or caravans[id].status != "escort": return false
	var c: Dictionary = caravans[id]
	if c.index == 1 and camps[shipment_at(id)].active and not c.guarded: return seize(id)
	c.status = "transit"
	c.remaining = route_data(c.route).days[c.index]
	log_event("%s continues without the company." % short_id(id))
	return true

func food_total() -> int:
	var total = 0
	for t in towns.values(): total += t.stock
	for c in caravans.values():
		if c.status != "delivered": total += c.cargo
	return total

func balanced() -> bool:
	return food_total() == initial_food+produced-consumed-sold

func snapshot() -> Dictionary:
	return {"version":1, "day":day, "towns":towns.duplicate(true), "camps":camps.duplicate(true), "caravans":caravans.duplicate(true), "next_launch":next_launch.duplicate(), "next_caravan":next_caravan, "events":events.duplicate(true), "event_seq":event_seq, "produced":produced, "consumed":consumed, "sold":sold, "initial_food":initial_food}

func restore(raw: Variant) -> bool:
	if not raw is Dictionary: return false
	var d: Dictionary = normalize(raw)
	for field in ["version", "day", "next_caravan", "event_seq", "produced", "consumed", "sold", "initial_food"]:
		if not d.get(field) is int or d[field] < 0: return false
	if d.version != 1 or d.day < 1 or d.day > 31 or d.next_caravan < 1: return false
	for field in ["towns", "camps", "caravans", "next_launch"]:
		if not d.get(field) is Dictionary: return false
	if d.towns.size() != 3 or d.camps.size() != 3 or d.next_launch.size() != config.routes.size(): return false
	var total = 0
	for town in TOWNS:
		if not d.towns.get(town) is Dictionary: return false
		var t = d.towns[town]
		for field in ["stock", "production", "demand", "base_price", "delivered", "shortage_days"]:
			if not t.get(field) is int or t[field] < 0: return false
		for field in ["production", "demand", "base_price"]:
			if t[field] != config.towns[town][field]: return false
		total += t.stock
	for site in SITES:
		if not d.camps.get(site) is Dictionary: return false
		var camp = d.camps[site]
		if not camp.get("active") is bool: return false
		for field in ["strength", "generation", "return_day", "cleared_day"]:
			if not camp.get(field) is int or camp[field] < 0: return false
		if camp.strength < 1 or camp.strength > 3 or camp.generation < 1 or camp.cleared_day > d.day: return false
		if camp.active and camp.return_day != 0 or not camp.active and camp.return_day <= d.day: return false
	for route in config.routes:
		if not d.next_launch.get(route.id) is int or d.next_launch[route.id] <= d.day: return false
	for id in d.caravans:
		var c = d.caravans[id]
		if not id is String or not c is Dictionary or c.get("id") != id: return false
		if not id.begins_with("wagon_") or not id.trim_prefix("wagon_").is_valid_int() or int(id.trim_prefix("wagon_")) < 1 or int(id.trim_prefix("wagon_")) >= d.next_caravan: return false
		if not c.get("route") is String or route_data(c.route).is_empty(): return false
		var route = route_data(c.route)
		for field in ["cargo", "index", "remaining", "depart_day", "delivered_day", "seized_day"]:
			if not c.get(field) is int or c[field] < 0: return false
		if c.cargo != route.cargo or c.index > 2 or c.remaining > 2 or c.depart_day < 1 or c.delivered_day > d.day or c.seized_day > d.day: return false
		if not c.get("guarded") is bool or not c.get("recovered") is bool: return false
		if not c.get("status") in ["waiting", "transit", "seized", "escort", "delivered"]: return false
		if c.status == "waiting" and (c.index != 0 or c.depart_day <= d.day): return false
		if c.status == "transit" and (c.index >= 2 or c.remaining < 1): return false
		if c.status == "seized" and (c.index != 1 or c.remaining != 0 or c.seized_day == 0): return false
		if c.status == "escort" and c.index >= 2: return false
		if c.status == "delivered":
			if c.index != 2 or c.remaining != 0 or c.delivered_day < 1: return false
		else:
			if c.delivered_day != 0: return false
			total += c.cargo
	if total != d.initial_food+d.produced-d.consumed-d.sold: return false
	if not d.get("events") is Array or d.events.size() > 200: return false
	var last_id = 0
	for event in d.events:
		if not event is Dictionary or not event.get("id") is int or not event.get("day") is int or not event.get("text") is String: return false
		if event.id <= last_id or event.id > d.event_seq or event.day < 1 or event.day > d.day: return false
		last_id = event.id
	for field in ["day", "towns", "camps", "caravans", "next_launch", "next_caravan", "events", "event_seq", "produced", "consumed", "sold", "initial_food"]: set(field, d[field])
	return true

func normalize(value: Variant) -> Variant:
	if value is float and is_finite(value) and value == floor(value): return int(value)
	if value is Array:
		var out: Array = []
		for entry in value: out.append(normalize(entry))
		return out
	if value is Dictionary:
		var out: Dictionary = {}
		for key in value: out[key] = normalize(value[key])
		return out
	return value
