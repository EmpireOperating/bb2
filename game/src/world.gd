extends RefCounted
## Daily food and faction simulation. Every patrol and raider action has an accounted cost.
const PreviousWorld = preload("res://src/legacy_world_v4.gd")
var TOWNS = ["ashwick", "stonecross", "dunmere"]
var FACTIONS = ["wardens", "guild", "compact"]
var SITES = ["ford", "forest", "ridge"]
var config: Dictionary = normalize(JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json")))
var physical_faction = "" # Derived from the optional physical-patrol component.
var physical_sites: Dictionary = {}
var physical_site = ""
var spatial_trade = false # Campaign/Traffic owns this capability; legacy worlds keep daily movement.
var farm_supply: Dictionary = {} # Optional rural stock/in-transit food; cross-validated by Farm.
var physical_founding = false
var raider_supply: Dictionary = {} # Optional carried food, included in this same world ledger.
var day = 1
var towns: Dictionary = {}
var camps: Dictionary = {}
var caravans: Dictionary = {}
var next_launch: Dictionary = {}
var next_caravan = 1
var events: Array = []
var event_seq = 0
var wagon_stock: Dictionary = {} # Material-built freight vehicles; absent in legacy economies.
var spoiled_food = 0
var produced = 0
var consumed = 0
var sold = 0
var initial_food = 0
var company_food_in = 0
var raid_wealth: Dictionary = {}
var raider_consumed = 0
var factions: Dictionary = {}
var patrols: Dictionary = {}
var next_patrol = 1

func configure(region: Dictionary) -> void:
	config = normalize(region.get("world_config",JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))))
	TOWNS = config.towns.keys(); SITES = config.camps.keys(); FACTIONS = config.factions.keys()

func camp_role(site: String) -> String:
	return config.camps.get(site,{}).get("map",site)

func fresh_camp(strength: int = 1) -> Dictionary:
	return {"active":true, "strength":strength, "generation":1, "cleared_day":0, "reserves":0, "spent":0, "stolen":0, "next_raid":day, "raids":0, "expansions":0}

func setup_politics() -> void:
	factions.clear()
	patrols.clear()
	next_patrol = 1
	for id in FACTIONS:
		factions[id] = {"treasury":config.factions[id].treasury, "taxes":0, "trade":0, "contributions":0, "spent":0, "losses":0, "priority":""}

func faction_name(id: String) -> String:
	return config.factions[id].name if config.factions.has(id) else "Unknown council"

func adjacent_sites(town: String) -> Array:
	var out: Array = []
	for route in config.routes:
		if town in [route.path[0], route.path[2]] and route.path[1] not in out: out.append(route.path[1])
	for site in SITES:
		if config.camps[site].get("remote",false) and config.camps[site].raid_target == town and site not in out: out.append(site)
	return out

func camp_food(site: String) -> int:
	return int(camps[site].reserves)+seized_food(site)

func spend_food(site: String, amount: int) -> bool:
	if not withdraw_camp_food(site,amount): return false
	camps[site].spent += amount
	raider_consumed += amount
	return true

func withdraw_camp_food(site: String, amount: int) -> bool:
	if amount < 1 or camp_food(site) < amount: return false
	var left = amount
	var unpacked = mini(left, camps[site].reserves)
	camps[site].reserves -= unpacked
	left -= unpacked
	for c in caravans.values():
		if left == 0: break
		if c.status != "seized" or shipment_at(c.id) != site or c.has("material"): continue
		var used = mini(left,c.cargo)
		c.cargo -= used
		c.spent += used
		left -= used
		if c.cargo == 0:
			c.status = "plundered"
			log_event("%s is empty. Raiders spent its food; there is no cargo left to recover." % short_id(c.id))
	return true

func ensure_raider_pack(id: String) -> void:
	if not raider_supply.packs.has(id):
		raider_supply.packs[id] = {"food":0,"loaded":0,"looted":0,"foraged":0,"eaten":0,"lost":0,"returned":0,"recovered":0}

func load_raider_food(id: String, site: String, amount: int) -> void:
	if amount <= 0 or not withdraw_camp_food(site,amount): return
	raider_supply.packs[id].food += amount; raider_supply.packs[id].loaded += amount

func return_raider_food(id: String, site: String, amount: int) -> void:
	assert(amount >= 0 and amount <= raider_supply.packs[id].food)
	raider_supply.packs[id].food -= amount; raider_supply.packs[id].returned += amount
	camps[site].reserves += amount

func use_raider_pack(id: String, amount: int, kind: String) -> void:
	assert(kind in ["eaten","lost","recovered"] and amount >= 0 and amount <= raider_supply.packs[id].food)
	raider_supply.packs[id].food -= amount; raider_supply.packs[id][kind] += amount
	if kind == "recovered": sold += amount
	else: raider_consumed += amount

func loot_raider_food(id: String, shipment: String, amount: int) -> void:
	var cargo: Dictionary = caravans[shipment]
	assert(amount > 0 and amount <= cargo.cargo)
	cargo.cargo -= amount; cargo.spent += amount
	raider_supply.packs[id].food += amount; raider_supply.packs[id].looted += amount
	if cargo.cargo == 0:
		cargo.status = "plundered"; cargo.index = 1; cargo.remaining = 0; cargo.seized_day = day

func patrol_power(site: String) -> int:
	var power = 0
	for p in patrols.values():
		if not has_physical(p.faction) and p.site == site and p.status == "stationed": power += p.strength
	return power

func patrol_names(site: String) -> String:
	var names: Array = []
	for p in patrols.values():
		if not has_physical(p.faction) and p.site == site and p.status == "stationed": names.append(faction_name(p.faction))
	return ", ".join(names)

func protected_road(site: String) -> bool:
	return not camps[site].active or patrol_power(site) >= camps[site].strength

func road_status(site: String) -> String:
	if not camps[site].active: return "CLEAR · patrol %d" % patrol_power(site)
	return "GUARDED · raiders %d / patrol %d" % [camps[site].strength,patrol_power(site)] if protected_road(site) else "RAIDERS · %d men" % (camps[site].strength+3)

func tax_towns() -> void:
	for town in TOWNS:
		var t: Dictionary = towns[town]
		var f: Dictionary = factions[t.owner]
		var tax = int(config.factions[t.owner].tax)
		if t.stock < t.demand: tax = 0
		elif t.stock < t.demand*3: tax /= 2
		if t.pressure > 0: tax /= 2
		f.treasury += tax
		f.taxes += tax
		var threatened = false
		for site in adjacent_sites(town):
			if camps[site].active and camps[site].strength == 3 and not protected_road(site): threatened = true
		if not threatened: t.pressure = maxi(0,t.pressure-1)

func fund_patrol(faction: String, site: String, amount: int) -> bool:
	if not factions.has(faction) or not site in adjacent_sites(config.factions[faction].town) or amount != config.politics.patrol_cost: return false
	factions[faction].treasury += amount
	factions[faction].contributions += amount
	factions[faction].priority = site
	log_event("The company gives %d crowns to %s for the next patrol to %s." % [amount,faction_name(faction),place_name(site)])
	return true

func dispatch_patrols() -> void:
	# One patrol per council. Departures are bought; no free respawn or free upkeep.
	for faction in FACTIONS:
		var f: Dictionary = factions[faction]
		if f.treasury < config.politics.patrol_cost: continue
		var deployed = false
		for p in patrols.values():
			if p.faction == faction and p.status in ["marching","stationed"]: deployed = true
		if deployed: continue
		var site: String = f.priority
		if site.is_empty() and has_physical(faction): site = physical_sites.get(faction,physical_site)
		if site.is_empty():
			var best = -999
			for candidate in adjacent_sites(config.factions[faction].town):
				var score = (50+camps[candidate].strength*10 if camps[candidate].active else 5)-patrol_power(candidate)*25
				# Councils prioritize roads carrying their food, then unprotected threats.
				if config.camps[candidate].raid_target == config.factions[faction].town: score += 10
				if score > best:
					best = score
					site = candidate
		f.priority = ""
		f.treasury -= config.politics.patrol_cost
		f.spent += config.politics.patrol_cost
		var id = "patrol_%03d" % next_patrol
		next_patrol += 1
		var duration = 1
		for route in config.routes:
			if route.path[1] == site: duration = route.days[0] if config.factions[faction].town == route.path[0] else route.days[1]
		patrols[id] = {"id":id,"faction":faction,"site":site,"strength":config.politics.patrol_strength,"status":"marching","remaining":duration,"days_left":config.politics.patrol_days,"started":day}
		log_event("%s spends %d crowns: %s marches to %s (%dd)." % [faction_name(faction),config.politics.patrol_cost,id.replace("patrol_","P"),place_name(site),duration])

func move_patrols() -> void:
	for p in patrols.values():
		if has_physical(p.faction): continue
		if not p.status in ["marching","stationed"]: continue
		var f: Dictionary = factions[p.faction]
		if f.treasury < config.politics.patrol_wage:
			p.status = "withdrawn"
			log_event("%s withdraws from %s: its council cannot pay wages." % [p.id.replace("patrol_","P"),place_name(p.site)])
			continue
		f.treasury -= config.politics.patrol_wage
		f.spent += config.politics.patrol_wage
		if p.status == "marching":
			p.remaining -= 1
			if p.remaining == 0:
				p.status = "stationed"
				log_event("%s reaches %s. Patrol strength %d." % [p.id.replace("patrol_","P"),place_name(p.site),p.strength])
		else:
			p.days_left -= 1
			if p.days_left == 0:
				p.status = "returned"
				log_event("%s finishes its watch at %s." % [p.id.replace("patrol_","P"),place_name(p.site)])
	for site in SITES:
		if not camps[site].active: continue
		var power = patrol_power(site)
		if power > camps[site].strength:
			clear_camp(site,camps[site].generation,patrol_names(site))
		elif power > 0 and power < camps[site].strength:
			for p in patrols.values():
				if not has_physical(p.faction) and p.site == site and p.status == "stationed":
					p.status = "defeated"
					log_event("Raiders overwhelm %s at %s. The road is exposed." % [p.id.replace("patrol_","P"),place_name(site)])

func raider_actions(budgets: Dictionary = {}, growth_allowed: Dictionary = {}) -> void:
	if not raider_supply.is_empty() and budgets.is_empty(): return
	# Iterate the initial active set: a newly founded band cannot act the same day.
	var acting = SITES.filter(func(site): return camps[site].active)
	for site in acting:
		var c: Dictionary = camps[site]
		var buffer: int = budgets.get(site,0)
		if raider_supply.is_empty() and camp_food(site) > 0: spend_food(site,1)
		if growth_allowed.get(site,true) and c.strength < 3 and camp_food(site) >= config.politics.recruit_food+buffer and spend_food(site,config.politics.recruit_food):
			c.strength += 1
			log_event("The band at %s spends %d stolen food recruiting. Threat rises to %d." % [place_name(site),config.politics.recruit_food,c.strength])
		if c.strength != 3 or physical_founding: continue
		for target in SITES:
			if (config.camps[site].has("neighbours") and target not in config.camps[site].neighbours) or target == site or camps[target].active or patrol_power(target) > 0: continue
			if camps[target].cleared_day > 0 and day < camps[target].cleared_day+int(config.politics.get("reoccupy_delay",0)): continue
			if camp_food(site) >= config.politics.expand_food+buffer and spend_food(site,config.politics.expand_food):
				camps[target].active = true
				camps[target].strength = 1
				camps[target].generation += 1
				camps[target].next_raid = day
				c.expansions += 1
				log_event("Raiders from %s spend %d food to establish a new band at %s." % [place_name(site),config.politics.expand_food,place_name(target)])
				break
		if not raider_supply.is_empty(): continue # Food must be taken by an actual field raid.
		if protected_road(site) or day < c.next_raid or camp_food(site) < config.politics.raid_cost: continue
		var town: String = config.camps[site].raid_target
		var t: Dictionary = towns[town]
		# Empty towns cannot feed further expansion; raids must have actual loot.
		if t.stock == 0: continue
		spend_food(site,config.politics.raid_cost)
		var loot = mini(config.politics.raid_loot,t.stock)
		t.stock -= loot
		t.raided += loot
		t.pressure = mini(5,t.pressure+2)
		c.reserves += loot
		c.stolen += loot
		c.raids += 1
		c.next_raid = day+config.politics.raid_interval
		var f: Dictionary = factions[t.owner]
		var lost = mini(24,f.treasury)
		f.treasury -= lost
		f.losses += lost
		if not raid_wealth.is_empty(): raid_wealth.camps[site].held += lost
		log_event("The %s warband raids %s: %d food stolen, %d treasury crowns lost; taxes halved under pressure." % [place_name(site),place_name(town),loot,lost])

func treasuries_balanced() -> bool:
	for id in FACTIONS:
		var f: Dictionary = factions[id]
		if f.treasury != config.factions[id].treasury+f.taxes+f.trade+f.contributions-f.spent-f.losses: return false
	return true

func validate_politics(d: Dictionary) -> bool:
	if d.factions.size() != config.factions.size() or d.next_patrol < 1: return false
	for id in FACTIONS:
		if not d.factions.get(id) is Dictionary: return false
		var f: Dictionary = d.factions[id]
		for field in ["treasury","taxes","trade","contributions","spent","losses"]:
			if not f.get(field) is int or f[field] < 0: return false
		if not f.get("priority") is String or (f.priority != "" and not f.priority in adjacent_sites(config.factions[id].town)): return false
		if f.treasury != config.factions[id].treasury+f.taxes+f.trade+f.contributions-f.spent-f.losses: return false
	var deployed = {}
	for id in d.patrols:
		var p = d.patrols[id]
		if not id is String or not p is Dictionary or p.get("id") != id: return false
		if not id.begins_with("patrol_") or not id.trim_prefix("patrol_").is_valid_int() or int(id.trim_prefix("patrol_")) < 1 or int(id.trim_prefix("patrol_")) >= d.next_patrol: return false
		if not config.factions.has(p.get("faction","")): return false
		if not p.get("site") in adjacent_sites(config.factions[p.faction].town): return false
		if not p.get("status") in ["marching","stationed","withdrawn","defeated","returned"]: return false
		for field in ["strength","remaining","days_left","started"]:
			if not p.get(field) is int or p[field] < 0: return false
		if p.strength != config.politics.patrol_strength or p.remaining > 2 or p.days_left > config.politics.patrol_days or p.started < 1 or p.started > d.day: return false
		if p.status == "marching" and (p.remaining == 0 or p.days_left == 0): return false
		if p.status == "stationed" and (p.remaining != 0 or p.days_left == 0): return false
		if p.status in ["marching","stationed"]:
			if deployed.has(p.faction): return false
			deployed[p.faction] = true
	return true

func migrate_v1(d: Dictionary) -> bool:
	var previous = PreviousWorld.new()
	if not previous.restore(d): return false
	var candidate = get_script().new()
	candidate.setup(d.day)
	var upgraded: Dictionary = d.duplicate(true)
	upgraded.version = 2
	upgraded["factions"] = candidate.factions.duplicate(true)
	upgraded["patrols"] = {}
	upgraded["next_patrol"] = 1
	upgraded["raider_consumed"] = 0
	for town in TOWNS:
		upgraded.towns[town]["owner"] = config.towns[town].owner
		upgraded.towns[town]["pressure"] = 0
		upgraded.towns[town]["raided"] = 0
	for site in SITES:
		var old: Dictionary = upgraded.camps[site]
		var camp = fresh_camp(old.strength)
		for field in ["active","strength","generation","cleared_day"]: camp[field] = old[field]
		camp.next_raid = d.day
		upgraded.camps[site] = camp
	for c in upgraded.caravans.values():
		c["spent"] = 0
		c["protection"] = ""
	return restore(upgraded)

func setup(start_day: int = 1) -> void:
	day = start_day
	physical_faction = ""
	physical_site = ""; physical_sites.clear()
	farm_supply.clear(); raider_supply.clear(); physical_founding = false
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
	initial_food = 0; company_food_in = 0; raid_wealth.clear(); wagon_stock.clear(); spoiled_food = 0
	raider_consumed = 0
	setup_politics()
	for town in towns:
		initial_food += towns[town].stock
		towns[town]["delivered"] = 0
		towns[town]["shortage_days"] = 0
		towns[town]["pressure"] = 0
		towns[town]["raided"] = 0
	for site in SITES:
		camps[site] = fresh_camp(config.camps[site].strength)
	for route in config.routes:
		launch(route.id)
		next_launch[route.id] = day+route.period

func route_data(id: String) -> Dictionary:
	if id.begins_with("material:"):
		var parts=id.split(":")
		if parts.size()!=3 or parts[2] not in ["out","back"]:return {}
		for base in config.routes:
			if base.id!=parts[1]:continue
			var route: Dictionary=base.duplicate(true);route.id=id;route.cargo=0
			if parts[2]=="back":route.path.reverse();route.days.reverse()
			return route
		return {}
	for route in config.routes:
		if route.id == id: return route
	return {}

func launch_material(route_id: String,kind: String,amount: int) -> String:
	var route=route_data(route_id)
	if route.is_empty() or not route_id.begins_with("material:") or wagon_stock.is_empty() or wagon_stock[route.path[0]]<1 or amount<1 or amount>4:return ""
	if kind not in ["furs","cloth","silk","salt","lumber","iron","grain","hides"]:return ""
	var id="wagon_%03d"%next_caravan;next_caravan+=1;wagon_stock[route.path[0]]-=1
	caravans[id]={"id":id,"route":route_id,"cargo":0,"spent":0,"material":{"kind":kind,"amount":amount},"protection":"","status":"waiting","index":0,"remaining":route.days[0],"depart_day":day+1,"guarded":false,"recovered":false,"delivered_day":0,"seized_day":0}
	return id

func cargo_text(id: String) -> String:
	var wagon: Dictionary=caravans[id]
	if wagon.has("material"):return "%d %s"%[0 if wagon.status=="plundered" else wagon.material.amount,wagon.material.kind]
	return "%d food"%wagon.cargo

func cargo_value(id: String) -> int:
	var wagon: Dictionary=caravans[id]
	return wagon.material.amount*12 if wagon.has("material") else wagon.cargo

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
	log_event("The company buys %d food from %s." % [amount, place_name(town)])
	return true

func launch(route_id: String) -> bool:
	var route = route_data(route_id)
	if route.is_empty(): return false
	var origin: String = route.path[0]
	if not raid_wealth.is_empty():
		var destination: String = route.path[2]; var incoming = 0
		for wagon in caravans.values():
			if route_data(wagon.route).path[2] == destination and wagon.status in ["waiting","transit","escort"]: incoming += wagon.cargo
		if towns[destination].stock+incoming >= towns[destination].demand*8: return false
	if towns[origin].stock < route.cargo+24: return false
	if not wagon_stock.is_empty():
		if wagon_stock[origin] <= 0: return false
		wagon_stock[origin] -= 1
	towns[origin].stock -= route.cargo
	var id = "wagon_%03d" % next_caravan
	next_caravan += 1
	caravans[id] = {"id":id, "route":route_id, "cargo":route.cargo, "spent":0, "protection":"", "status":"waiting", "index":0, "remaining":route.days[0], "depart_day":day+1, "guarded":false, "recovered":false, "delivered_day":0, "seized_day":0}
	log_event("%s loads %d food for %s; leaves day %d." % [short_id(id), route.cargo, place_name(route.path[2]), day+1])
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

func tick(defer_shipments: bool = false) -> void:
	day += 1
	for town in towns:
		var t: Dictionary = towns[town]
		var supply = rural(town)
		if not supply.is_empty():
			supply.food += supply.output
			produced += supply.output
		else:
			t.stock += t.production
			produced += t.production
		var eaten = mini(t.stock, t.demand)
		t.stock -= eaten
		consumed += eaten
		if eaten < t.demand: t.shortage_days += 1
	tax_towns()
	move_patrols()
	raider_actions()
	dispatch_patrols()
	for c in caravans.values():
		if c.status == "waiting" and day >= c.depart_day: c.status = "transit"
		if c.status != "transit" or spatial_trade: continue
		c.remaining -= 1
		if c.remaining > 0: continue
		c.index += 1
		if c.index == 2:
			deliver(c.id)
			continue
		var site = shipment_at(c.id)
		if camps[site].active and not c.guarded and not protected_road(site): seize(c.id)
		else:
			if not c.guarded and patrol_power(site) > 0:
				c.protection = patrol_names(site)
				log_event("%s passes %s under %s patrol protection." % [short_id(c.id), place_name(site), c.protection])
			c.remaining = route_data(c.route).days[c.index]
	if not defer_shipments: dispatch_shipments()

func dispatch_shipments() -> void:
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
	camps[shipment_at(id)].stolen += c.cargo
	log_event("Raiders at %s seize %s: %s never reaches %s." % [place_name(shipment_at(id)), short_id(id), cargo_text(id), place_name(route_data(c.route).path[2])])
	return true

func deliver(id: String) -> bool:
	if not caravans.has(id): return false
	var c: Dictionary = caravans[id]
	if not c.status in ["transit", "escort"] or c.index != 2: return false
	var destination: String = route_data(c.route).path[2]
	var before = price(destination)
	towns[destination].stock += c.cargo
	towns[destination].delivered += c.cargo
	var owner: String = towns[destination].owner
	var toll = int(c.cargo/2)
	factions[owner].treasury += toll
	factions[owner].trade += toll
	c.status = "delivered"
	c.remaining = 0
	c.delivered_day = day
	if c.has("material"):log_event("%s arrives at %s with %s."%[short_id(id),place_name(destination),cargo_text(id)])
	else:log_event("%s delivers %d food to %s. Price: %d -> %d crowns / 24." % [short_id(id), c.cargo, place_name(destination), before, price(destination)])
	return true

func recover_shipment(id: String) -> bool:
	if not caravans.has(id) or caravans[id].status != "seized": return false
	var c: Dictionary = caravans[id]
	c.status = "transit"
	c.recovered = true
	c.guarded = true
	c.remaining = route_data(c.route).days[1]
	log_event("%s recovered: %s resumes its journey to %s." % [short_id(id), cargo_text(id), place_name(route_data(c.route).path[2])])
	return true

func clear_camp(site: String, generation: int, liberator: String = "the company") -> bool:
	if not camps.has(site) or not camps[site].active or camps[site].generation != generation: return false
	if not raid_wealth.is_empty():
		raid_wealth.camps[site].lost += raid_wealth.camps[site].held; raid_wealth.camps[site].held = 0
	camps[site].active = false
	camps[site].cleared_day = day
	# Unpacked stores are destroyed; identifiable wagons are freed below.
	raider_consumed += camps[site].reserves
	camps[site].spent += camps[site].reserves
	camps[site].reserves = 0
	log_event("%s cleared by %s. Only another funded band can occupy it again." % [place_name(site), liberator])
	for c in caravans.values():
		if c.status == "seized" and shipment_at(c.id) == site: recover_shipment(c.id)
	return true

func reserve_escort(id: String) -> bool:
	if not caravans.has(id) or caravans[id].status != "waiting": return false
	caravans[id].status = "escort"
	log_event("The company takes charge of %s and its %s." % [short_id(id), cargo_text(id)])
	return true

func escort_next(id: String) -> String:
	if not caravans.has(id) or caravans[id].status != "escort": return ""
	var c: Dictionary = caravans[id]
	if c.index >= 2: return ""
	if c.index == 1 and camps[shipment_at(id)].active and not c.guarded and not protected_road(shipment_at(id)): return ""
	return route_data(c.route).path[c.index+1]

func escort_arrive(id: String, target: String) -> bool:
	if escort_next(id) != target or target.is_empty(): return false
	var c: Dictionary = caravans[id]
	c.index += 1
	c.remaining = 0
	if c.index == 2: return deliver(id)
	log_event("%s reaches %s under company escort." % [short_id(id), place_name(target)])
	return true

func release_escort(id: String) -> bool:
	if not caravans.has(id) or caravans[id].status != "escort": return false
	var c: Dictionary = caravans[id]
	if c.index == 1 and camps[shipment_at(id)].active and not c.guarded and not protected_road(shipment_at(id)): return seize(id)
	c.status = "transit"
	c.remaining = route_data(c.route).days[c.index]
	log_event("%s continues without the company." % short_id(id))
	return true

func food_total() -> int:
	var total = 0
	for pack in raider_supply.get("packs",{}).values(): total += pack.food
	for town in TOWNS: total += int(rural(town).get("food",0))
	for t in towns.values(): total += t.stock
	for c in caravans.values():
		if c.status != "delivered": total += c.cargo
	for camp in camps.values(): total += camp.reserves
	return total

func balanced() -> bool:
	return food_total() == initial_food+produced+company_food_in-consumed-sold-raider_consumed-spoiled_food and treasuries_balanced()

func snapshot() -> Dictionary:
	var out = {"version":3 if TOWNS.size() > 3 else 2, "factions":factions.duplicate(true), "patrols":patrols.duplicate(true), "next_patrol":next_patrol, "raider_consumed":raider_consumed, "day":day, "towns":towns.duplicate(true), "camps":camps.duplicate(true), "caravans":caravans.duplicate(true), "next_launch":next_launch.duplicate(), "next_caravan":next_caravan, "events":events.duplicate(true), "event_seq":event_seq, "produced":produced, "consumed":consumed, "sold":sold, "initial_food":initial_food}

	if not wagon_stock.is_empty():out["wagon_stock"]=wagon_stock.duplicate();out["spoiled_food"]=spoiled_food
	if not farm_supply.is_empty(): out["farm_supply"] = farm_supply.duplicate(true)
	if not raid_wealth.is_empty():
		out["raid_wealth"] = raid_wealth.duplicate(true); out["company_food_in"] = company_food_in
	if not raider_supply.is_empty(): out["raider_supply"] = raider_supply.duplicate(true)
	if physical_founding: out["physical_founding"] = true
	return out

func restore(raw: Variant) -> bool:
	if not raw is Dictionary: return false
	var d: Dictionary = normalize(raw)
	if d.get("version") == 1: return TOWNS.size() == 3 and migrate_v1(d)
	for field in ["version", "day", "next_caravan", "event_seq", "produced", "consumed", "sold", "initial_food", "raider_consumed", "next_patrol"]:
		if not d.get(field) is int or d[field] < 0: return false
	if d.version != (3 if TOWNS.size() > 3 else 2) or d.day < 1 or d.next_caravan < 1: return false
	for field in ["towns", "camps", "caravans", "next_launch", "factions", "patrols"]:
		if not d.get(field) is Dictionary: return false
	if d.towns.size() != TOWNS.size() or d.camps.size() != SITES.size() or d.next_launch.size() != config.routes.size(): return false
	var rural = d.get("farm_supply",{})
	if not rural is Dictionary: return false
	var total = 0
	if not rural.is_empty():
		if rural.get("town") != "ashwick": return false
		var supplies = {"ashwick":rural}
		if rural.has("sites"):
			if not rural.sites is Dictionary or rural.sites.size() != TOWNS.size()-1: return false
			for town in TOWNS.filter(func(id):return id != "ashwick"):
				if not rural.sites.get(town) is Dictionary: return false
				supplies[town] = rural.sites[town]
		for town in supplies:
			var supply = supplies[town]
			if supply.get("town") != town or not supply.get("food") is int or supply.food < 0: return false
			var capacity = maxi(4,int(config.towns[town].production)) if rural.has("sites") else int(config.towns[town].production)
			if not supply.get("output") is int or supply.output not in [0,capacity]: return false
			total += supply.food
	var spent_total = 0
	if d.has("physical_founding") and (d.physical_founding != true or not d.has("raider_supply")): return false
	var carried = d.get("raider_supply",{})
	if not carried is Dictionary: return false
	if not carried.is_empty():
		if carried.size() != 2 or carried.get("version") != 1 or not carried.get("packs") is Dictionary: return false
		for id in carried.packs:
			var pack = carried.packs[id]
			if not id is String or not pack is Dictionary or pack.size() != 8: return false
			for field in ["food","loaded","looted","foraged","eaten","lost","returned","recovered"]:
				if not pack.get(field) is int or pack[field] < 0: return false
			if pack.food > 36 or pack.food != pack.loaded+pack.looted+pack.foraged-pack.eaten-pack.lost-pack.returned-pack.recovered: return false
			total += pack.food; spent_total += pack.eaten+pack.lost
	for town in TOWNS:
		if not d.towns.get(town) is Dictionary: return false
		var t = d.towns[town]
		for field in ["stock", "production", "demand", "base_price", "delivered", "shortage_days", "pressure", "raided"]:
			if not t.get(field) is int or t[field] < 0: return false
		for field in ["production", "demand", "base_price"]:
			if t[field] != config.towns[town][field]: return false
		if t.get("owner") != config.towns[town].owner or t.pressure > 5: return false
		total += t.stock
	for site in SITES:
		if not d.camps.get(site) is Dictionary: return false
		var camp = d.camps[site]
		if not camp.get("active") is bool: return false
		for field in ["strength", "generation", "cleared_day", "reserves", "spent", "stolen", "next_raid", "raids", "expansions"]:
			if not camp.get(field) is int or camp[field] < 0: return false
		if camp.strength < 1 or camp.strength > 3 or camp.generation < 1 or camp.cleared_day > d.day: return false
		if not camp.active and camp.reserves != 0: return false
		total += camp.reserves
		spent_total += camp.spent
	if spent_total != d.raider_consumed: return false
	for route in config.routes:
		if not d.next_launch.get(route.id) is int or d.next_launch[route.id] <= d.day: return false
	for id in d.caravans:
		var c = d.caravans[id]
		if not id is String or not c is Dictionary or c.get("id") != id: return false
		if not id.begins_with("wagon_") or not id.trim_prefix("wagon_").is_valid_int() or int(id.trim_prefix("wagon_")) < 1 or int(id.trim_prefix("wagon_")) >= d.next_caravan: return false
		if not c.get("route") is String or route_data(c.route).is_empty(): return false
		var route = route_data(c.route)
		for field in ["cargo", "spent", "index", "remaining", "depart_day", "delivered_day", "seized_day"]:
			if not c.get(field) is int or c[field] < 0: return false
		if c.cargo+c.spent != route.cargo or c.index > 2 or c.remaining > 2 or c.depart_day < 1 or c.delivered_day > d.day or c.seized_day > d.day: return false
		if not c.get("guarded") is bool or not c.get("recovered") is bool or not c.get("protection") is String: return false
		if not c.get("status") in ["waiting", "transit", "seized", "escort", "delivered", "plundered"]: return false
		if c.status == "waiting" and (c.index != 0 or c.depart_day <= d.day): return false
		if c.status == "transit" and (c.index >= 2 or c.remaining < 1): return false
		if c.status == "seized" and (c.index != 1 or c.remaining != 0 or c.seized_day == 0): return false
		if c.status == "escort" and c.index >= 2: return false
		if c.status == "plundered" and (c.cargo != 0 or c.index != 1 or c.seized_day == 0 or c.remaining != 0): return false
		if c.has("material"):
			if not d.get("wagon_stock") is Dictionary or d.wagon_stock.is_empty() or not d.get("raid_wealth") is Dictionary or d.raid_wealth.is_empty():return false
			if not c.route.begins_with("material:") or not c.material is Dictionary or c.material.size()!=2 or c.cargo!=0 or c.spent!=0:return false
			if c.material.get("kind") not in ["furs","cloth","silk","salt","lumber","iron","grain","hides"] or not c.material.get("amount") is int or c.material.amount<1 or c.material.amount>4:return false
		elif c.route.begins_with("material:") or c.status != "plundered" and c.cargo <= 0: return false
		if c.status == "delivered":
			if c.index != 2 or c.remaining != 0 or c.delivered_day < 1: return false
		else:
			if c.delivered_day != 0: return false
			total += c.cargo
	var incoming = d.get("company_food_in",0)
	if not incoming is int or incoming < 0: return false
	var spoiled=d.get("spoiled_food",0);var fleet=d.get("wagon_stock",{})
	if not spoiled is int or spoiled<0 or not fleet is Dictionary:return false
	if not fleet.is_empty():
		if fleet.size()!=TOWNS.size() or d.get("raid_wealth",{}).is_empty():return false
		for town in TOWNS:
			if not fleet.get(town) is int or fleet[town]<0:return false
	elif spoiled>0:return false
	if total != d.initial_food+d.produced+incoming-d.consumed-d.sold-d.raider_consumed-spoiled: return false
	var wealth = d.get("raid_wealth",{})
	if not wealth is Dictionary: return false
	if not wealth.is_empty():
		if not wealth.get("baseline") is int or wealth.baseline < 0 or not wealth.get("camps") is Dictionary or wealth.camps.size() != SITES.size(): return false
		var accounted = wealth.baseline; var losses = 0
		for faction in d.factions.values():
			if not faction is Dictionary or not faction.get("losses") is int: return false
			losses += faction.losses
		for site in SITES:
			if not wealth.camps.get(site) is Dictionary: return false
			for field in ["held","taken","lost"]:
				if not wealth.camps[site].get(field) is int or wealth.camps[site][field] < 0: return false
				accounted += wealth.camps[site][field]
			if not d.camps[site].active and wealth.camps[site].held != 0: return false
		if accounted != losses: return false
	elif incoming > 0: return false
	if not validate_politics(d): return false
	if not d.get("events") is Array or d.events.size() > 200: return false
	var last_id = 0
	for event in d.events:
		if not event is Dictionary or not event.get("id") is int or not event.get("day") is int or not event.get("text") is String: return false
		if event.id <= last_id or event.id > d.event_seq or event.day < 1 or event.day > d.day: return false
		last_id = event.id
	company_food_in = incoming; raid_wealth = wealth.duplicate(true); wagon_stock=fleet.duplicate();spoiled_food=spoiled
	farm_supply = rural.duplicate(true)
	raider_supply = carried.duplicate(true)
	physical_founding = d.get("physical_founding",false)
	for field in ["day", "towns", "camps", "caravans", "next_launch", "next_caravan", "events", "event_seq", "produced", "consumed", "sold", "initial_food", "raider_consumed", "factions", "patrols", "next_patrol"]: set(field, d[field])
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

func place_name(id: String) -> String:
	return str(config.towns.get(id,config.camps.get(id,{})).get("name",id.capitalize()))

func has_physical(faction: String) -> bool:
	return faction == physical_faction or physical_sites.has(faction)

func rural(town: String) -> Dictionary:
	if farm_supply.get("town") == town: return farm_supply
	return farm_supply.get("sites",{}).get(town,{})
