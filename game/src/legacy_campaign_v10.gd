extends RefCounted
## Persistent company state. Resolving a battle is a single, idempotent transition.
const People = preload("res://src/legacy_people_v14.gd")
var recruit_pools: Dictionary = {}
var population_kind = "generated"
const Relationships = preload("res://src/relationships.gd")
var relationships = Relationships.new()
const Progression = preload("res://src/legacy_progression_v16.gd")
const Battle = preload("res://src/legacy_battle_v10.gd")
const SLOTS = ["weapon", "body", "under", "head", "shield"]
const Previous = preload("res://src/legacy_campaign_v5.gd")
const World = preload("res://src/world.gd")
var world = World.new()
var encounters = 0
var reputation: Dictionary = {"wardens":0,"guild":0,"compact":0}
const LAST_DAY = 30
const REQUIRED_WINS = 4
const BACKGROUNDS = [
	{"name":"Militia", "trait":"Drilled shield: 24 defence", "hp":78, "skill":72, "defense":24, "wage":6, "price":170, "weapon":"spear"},
	{"name":"Poacher", "trait":"Practised shot: 78 skill", "hp":66, "skill":78, "defense":9, "wage":5, "price":145, "weapon":"bow"},
	{"name":"Woodcutter", "trait":"Stout: 92 maximum health", "hp":92, "skill":65, "defense":13, "wage":4, "price":110, "weapon":"axe"},
	{"name":"Deserter", "trait":"Veteran: mail and 76 skill", "hp":80, "skill":76, "defense":20, "wage":7, "price":210, "weapon":"sword"}
]
var region: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/region.json"))
var location = "ashwick"
var food = 90
var wins = 0
var arrears = 0
var unpaid_days = 0
var ending = ""
var active: Dictionary = {}
var used_jobs: Array = []
var hired: Array = []
var deployment: Array = []
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy_equipment_v10.json"))
var battle = Battle.new()
var soldiers: Array = []
var items: Dictionary = {}
var next_item = 1
var day = 1
var crowns = 700
var tools = 60
var medicine = 18
var completed = 0
var seed_value = 7391
var phase = "camp"
var journal: Array = []
var aftermath: Dictionary = {}
var retreat = false

func setup(seed_number: int = 7391) -> void:
	seed_value = maxi(1, seed_number)
	battle.setup(seed_value)
	relationships = Relationships.new()
	soldiers.clear()
	items.clear()
	next_item = 1
	day = 1
	world.setup()
	encounters = 0
	reputation = {"wardens":0,"guild":0,"compact":0}
	crowns = 700
	tools = 60
	medicine = 18
	completed = 0
	phase = "camp"
	journal.clear()
	aftermath.clear()
	retreat = false
	location = "ashwick"
	food = 90
	wins = 0
	arrears = 0
	unpaid_days = 0
	ending = ""
	active.clear()
	used_jobs.clear()
	hired.clear()
	deployment.clear()
	var population = People.new().population(seed_value)
	population_kind = "generated"
	recruit_pools = population.pools
	for candidate in population.founders: add_person(candidate)
	for definition in ["sword", "spear", "axe", "bow", "heavy_mail", "leather", "gambeson", "nasal", "shield"]: add_item(definition)
	note("The Ashen Company takes the road. Six names on the roll.")

func add_item(definition: String, condition: int = -1) -> String:
	var id = "item_%03d" % next_item
	next_item += 1
	var maximum = int(catalog[definition].durability)
	items[id] = {"id":id, "definition":definition, "condition":maximum if condition < 0 else clampi(condition, 0, maximum)}
	return id

func alive_count() -> int:
	var count = 0
	for s in soldiers:
		if s.alive: count += 1
	return count

func over() -> bool:
	return not ending.is_empty() or alive_count() == 0 or day > LAST_DAY

func node(id: String = "") -> Dictionary:
	for place in region.locations:
		if place.id == (location if id.is_empty() else id): return place
	return {}

func in_town() -> bool:
	return node().get("kind", "") == "town"

func contract() -> Dictionary:
	return active if not active.is_empty() else {"title":"No contract accepted", "brief":"Find work at a town's contract board.", "pay":0}

func offers() -> Array:
	var out: Array = []
	if not in_town() or over(): return out
	for site in world.SITES:
		if travel_days(site) == 0 or not world.camps[site].active: continue
		var camp: Dictionary = world.camps[site]
		var job = make_job("clear_%s_%d" % [site, camp.generation], "clear", site, "", "Clear "+node(site).name, "Destroy the band and free remaining cargo. Reoccupation requires supplies from another band.", 280+camp.strength*100, camp.strength, {"ford":"hold", "forest":"eliminate", "ridge":"defend"}[site])
		if not job.id in used_jobs: out.append(job)
	for c in world.caravans.values():
		var route = world.route_data(c.route)
		var job: Dictionary = {}
		if c.status == "seized" and location in [route.path[0], route.path[2]]:
			var site: String = route.path[1]
			job = make_job("recover_"+c.id, "recover", site, c.id, "Recover "+world.short_id(c.id), "Retrieve %d stolen food for %s. The wider raider camp remains." % [c.cargo, node(route.path[2]).name], 200+c.cargo, maxi(1, int(world.camps[site].strength)-1), "eliminate")
		elif c.status == "waiting" and location == route.path[0] and world.camps[route.path[1]].active and reputation[world.towns[location].owner] > -12:
			job = make_job("escort_"+c.id, "escort", route.path[1], c.id, "Escort to "+node(route.path[2]).name, "Deliver %s: %d food. Defend at %s, then continue to town. Payment on arrival." % [world.short_id(c.id), c.cargo, node(route.path[1]).name], 400+c.cargo, world.camps[route.path[1]].strength, "escort")
		if not job.is_empty() and not job.id in used_jobs: out.append(job)
	return out

func make_job(id: String, kind: String, target: String, shipment: String, title: String, brief: String, pay: int, threat: int, objective: String) -> Dictionary:
	var client: String = world.towns[location].owner
	pay = ceili(float(pay)*(100.0+reputation[client]/2.0)/100.0)
	return {"client":client, "id":id, "kind":kind, "target":target, "shipment":shipment, "generation":world.camps[target].generation, "title":title, "brief":brief, "pay":pay, "threat":threat, "objective":objective, "origin":location, "deadline":mini(LAST_DAY, day+8)}

func accept_job(id: String) -> bool:
	if phase != "camp" or over() or not active.is_empty(): return false
	for job in offers():
		if job.id != id: continue
		if job.kind == "escort" and not world.reserve_escort(job.shipment): return false
		active = job.duplicate(true)
		active["participants"] = soldiers.filter(func(s): return s.alive).map(func(s): return s.id)
		note("Signed %s: %d crowns, due day %d." % [active.title, active.pay, active.deadline])
		return true
	return false

func finish_job(won: bool) -> int:
	if active.is_empty(): return 0
	change_reputation(active.client,8 if won else -6,2 if won else 0)
	var reward = int(active.pay) if won else 0
	crowns += reward
	if won:
		for id in active.participants:
			Progression.grant(soldiers[id],"contract_"+active.id,10,day,"Fulfilled "+active.title+".")
		wins += 1
		tools += 12
		medicine += 4
		add_item(["nasal", "heavy_mail", "gambeson"][completed%3])
	elif active.kind == "escort": world.release_escort(active.shipment)
	completed += 1
	used_jobs.append(active.id)
	note("%s: %s. %d crowns earned." % [active.title, "fulfilled" if won else "closed unpaid", reward])
	active.clear()
	return reward

func abandon_job() -> bool:
	if phase != "camp" or active.is_empty() or over(): return false
	finish_job(false)
	return true

func can_deploy() -> bool:
	if phase != "camp" or over() or active.is_empty() or location != active.target or day > active.deadline: return false
	match active.kind:
		"escort": return world.caravans[active.shipment].status == "escort" and not world.caravans[active.shipment].guarded and world.camps[location].active and not world.protected_road(location)
		"clear": return world.camps[location].active and world.camps[location].generation == active.generation
		"recover": return world.caravans[active.shipment].status == "seized"
		"legacy": return true
	return false

func next_escort_stop() -> String:
	return world.escort_next(active.shipment) if not active.is_empty() and active.kind == "escort" else ""

func travel_days(target: String) -> int:
	for road in region.roads:
		if road[0] == location and road[1] == target or road[1] == location and road[0] == target: return int(road[2])
	return 0

func travel(target: String) -> bool:
	var duration = travel_days(target)
	if phase != "camp" or over() or duration == 0 or day+duration > LAST_DAY+1: return false
	var escort = not active.is_empty() and active.kind == "escort"
	if escort and target != next_escort_stop(): return false
	for i in duration:
		# Arrival and delivery precede the final day's accounting, just as battle pay does.
		if i == duration-1:
			location = target
			if escort and not active.is_empty():
				world.escort_arrive(active.shipment, target)
				if world.caravans[active.shipment].status == "delivered": finish_job(true)
		advance_day("travel")
		if over() and i < duration-1: return true
	note("Arrived at %s on day %d." % [node().name, mini(day, LAST_DAY)])
	return true

func wage_cost() -> int:
	var total = 0
	for s in soldiers:
		if s.alive: total += s.wage
	return total

func advance_day(activity: String) -> void:
	# Every day has one owner: travel, rest, or resolved battle. No double upkeep.
	var mouths = alive_count()
	var due = wage_cost()+arrears
	var paid = mini(crowns, due)
	crowns -= paid
	arrears = due-paid
	unpaid_days = unpaid_days+1 if arrears > 0 else 0
	var fed = food >= mouths
	food = maxi(0, food-mouths)
	var treated = 0
	for s in soldiers:
		if not s.alive: continue
		if not fed:
			s.hp = maxi(1, int(s.hp)-8)
		elif activity == "rest":
			if (s.wound_days > 0 or s.hp < max_hp(s)) and medicine > 0:
				medicine -= 1
				treated += 1
				var was_wounded: bool = s.wound_days > 0
				s.wound_days = maxi(0, int(s.wound_days)-1)
				if was_wounded and s.wound_days == 0: Progression.record(s,"healed_%d" % day,day,"healed","Deep wound healed after treatment. Permanent scars remain.")
				s.hp = mini(max_hp(s), int(s.hp)+18)
			else: s.hp = mini(max_hp(s), int(s.hp)+6)
		elif activity == "travel": s.hp = mini(max_hp(s), int(s.hp)+2)
	relationships.daily(soldiers,day,fed,arrears == 0,activity == "rest")
	note("Day %d: %s; %d crowns paid, %d rations. %s" % [day, activity, paid, mouths, "Hunger costs 8 HP each." if not fed else ("%d treated." % treated if activity == "rest" else "")])
	day += 1
	var old_event = world.event_seq
	world.tick()
	for event in world.events:
		if event.id > old_event: note(event.text)
	reconcile_contract()
	if not active.is_empty() and day > active.deadline:
		note("Contract expired: %s." % active.title)
		finish_job(false)
	if alive_count() == 0: ending = "The company is gone."
	elif unpaid_days >= 3: ending = "Three unpaid days. The company disbands."
	elif day > LAST_DAY:
		ending = "The Ashen Company endures." if (wins >= REQUIRED_WINS or region_secured()) and arrears == 0 else "The month ends. The company falls short."
	if not ending.is_empty() and not active.is_empty(): finish_job(false)

func recruits() -> Array:
	var out: Array = []
	if not in_town() or over(): return out
	var week = (day-1)/7
	for i in 2:
		var id = "%s_recruit_%d_%d" % [location,week,i]
		if recruit_pools.has(id) and not id in hired: out.append(recruit_pools[id].duplicate(true))
	return out

func add_person(candidate: Dictionary) -> void:
	var gear: Dictionary = {}
	for slot in SLOTS:
		gear[slot] = add_item(candidate.loadout[slot]) if not candidate.loadout[slot].is_empty() else ""
	var s = {"id":soldiers.size(),"name":candidate.person,"title":candidate.name.to_upper(),"base_hp":candidate.hp,"base_skill":candidate.skill,"base_defense":candidate.defense,"hp":candidate.hp,"alive":true,"wound_days":0,"kills":0,"battles":0,"fallen_day":0,"gear":gear,"wage":candidate.wage,"background":candidate.name,"trait":candidate.trait}
	People.copy_identity(candidate,s)
	Progression.initialize(s,day,node().name)
	Relationships.initialize_soldier(s)
	soldiers.append(s)

func hire(id: String) -> bool:
	if phase != "camp" or over() or alive_count() >= 6: return false
	for candidate in recruits():
		if candidate.id != id: continue
		if crowns < candidate.price: return false
		crowns -= candidate.price
		hired.append(id)
		add_person(candidate)
		note("%s the %s joins. %d crowns now, %d per day." % [candidate.person,candidate.name,candidate.price,candidate.wage])
		return true
	return false

func develop(soldier_id: int, attr: String) -> bool:
	if phase != "camp" or over() or soldier_id < 0 or soldier_id >= soldiers.size() or not attr in People.ATTRS: return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or Progression.level(s)-1 <= s.development.size(): return false
	var gain = People.growth(s,attr)
	s[People.FIELDS[attr]] += gain
	s.development.append(attr)
	Progression.record(s,"development_%d" % s.development.size(),day,"training","Developed %s: +%d (aptitude %d/3)." % [People.LABELS[attr],gain,s.aptitudes[attr]])
	note("%s develops %s: +%d." % [s.name,People.LABELS[attr],gain])
	return true

func legacy_pools(seed_number: int) -> Dictionary:
	var previous = preload("res://src/legacy_campaign_v9.gd").new()
	previous.setup(seed_number)
	var out: Dictionary = {}
	for town in ["ashwick","stonecross","dunmere"]:
		previous.location = town
		for week in 5:
			previous.day = week*7+1
			for p in previous.recruits():
				People.neutral(p)
				p["loadout"] = {"weapon":p.weapon,"body":"mail" if p.name == "Deserter" else "leather","under":"linen","head":"cap","shield":"shield" if p.weapon != "bow" else ""}
				out[p.id] = p
	return out

func roll_ids() -> Array:
	var out: Array = []
	for s in soldiers:
		if s.alive: out.append(s.id)
	for s in soldiers:
		if not s.alive: out.append(s.id)
	return out

func max_hp(s: Dictionary) -> int:
	return int(s.base_hp) - (12 if s.wound_days > 0 else 0)

func effective_skill(s: Dictionary) -> int:
	return int(s.base_skill) - (10 if s.wound_days > 0 else 0) - (4 if "clouded_eye" in s.scars else 0)

func item_def(id: String) -> Dictionary:
	return catalog[items[id].definition] if items.has(id) else {}

func owner(id: String) -> int:
	for s in soldiers:
		for slot in SLOTS:
			if id != "" and s.gear[slot] == id: return int(s.id)
	return -1

func stash(slot: String) -> Array:
	var out: Array = []
	for id in items:
		if owner(id) == -1 and item_def(id).slot == slot: out.append(id)
	return out

func equip(soldier_id: int, item_id: String) -> bool:
	if phase != "camp" or over() or soldier_id < 0 or soldier_id >= soldiers.size() or not items.has(item_id): return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or owner(item_id) != -1: return false
	var definition = item_def(item_id)
	var slot: String = definition.slot
	if slot == "shield" and item_def(s.gear.weapon).get("weapon", "") == "bow": return false
	s.gear[slot] = item_id
	if slot == "weapon" and definition.weapon == "bow": s.gear.shield = ""
	note("%s equips %s." % [s.name, definition.name])
	return true

func unequip(soldier_id: int, slot: String) -> bool:
	if phase != "camp" or over() or not slot in SLOTS or slot == "weapon" or soldier_id < 0 or soldier_id >= soldiers.size(): return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or s.gear[slot] == "": return false
	s.gear[slot] = ""
	return true

func durability(s: Dictionary, slot: String) -> int:
	return int(items[s.gear[slot]].condition) if items.has(s.gear[slot]) else 0

func maximum(s: Dictionary, slot: String) -> int:
	return int(item_def(s.gear[slot]).get("durability", 0))

func repair_cost(soldier_id: int) -> int:
	if soldier_id < 0 or soldier_id >= soldiers.size() or not soldiers[soldier_id].alive: return 0
	var missing = 0
	var s: Dictionary = soldiers[soldier_id]
	for slot in ["body", "under", "head"]: missing += maximum(s, slot) - durability(s, slot)
	return ceili(float(missing)/12)

func repair(soldier_id: int) -> bool:
	if phase != "camp" or over(): return false
	var cost = repair_cost(soldier_id)
	if cost == 0 or tools < cost: return false
	var s: Dictionary = soldiers[soldier_id]
	for slot in ["body", "under", "head"]:
		if items.has(s.gear[slot]): items[s.gear[slot]].condition = maximum(s, slot)
	tools -= cost
	note("%s's armour repaired: %d tools." % [s.name, cost])
	return true

func rest_cost() -> int:
	return wage_cost()+arrears

func rest_day() -> bool:
	if phase != "camp" or over(): return false
	advance_day("rest")
	return true

func supply_cost(kind: String) -> int:
	return quoted_price(location, world.price(location) if kind == "food" else (36 if kind == "tools" else 30))

func buy_supply(kind: String) -> bool:
	if phase != "camp" or over() or not in_town() or not kind in ["tools", "medicine", "food"]: return false
	var cost = supply_cost(kind)
	if crowns < cost: return false
	if kind == "food" and not world.buy_food(location): return false
	crowns -= cost
	if kind == "tools": tools += 12
	elif kind == "medicine": medicine += 6
	else: food += 24
	note("Bought %s for %d crowns." % [kind, cost])
	return true

func deploy() -> bool:
	if not can_deploy(): return false
	update_threat()
	battle.setup(seed_value + encounters*101, node().map, active.objective)
	deployment.clear()
	for s in soldiers:
		if s.alive: deployment.append(s.id)
	while deployment.size() < 6: deployment.append(-1)
	for i in 6:
		if deployment[i] == -1:
			battle.units[i].hp = 0
			battle.units[i].name = "Empty rank"
			continue
		var s: Dictionary = soldiers[deployment[i]]
		var u: Dictionary = battle.units[i]
		u.name = s.name
		u.title = s.title
		u.hp = int(s.hp) if s.alive else 0
		u.max_hp = max_hp(s)
		u.skill = effective_skill(s)
		u.defense = s.base_defense
		for field in ["endurance","mobility","resolve","temperament"]: u[field] = s[field]
		u.perks = s.perks.duplicate()
		u.scars = s.scars.duplicate()
		u.morale = 75 if "haunted" in s.scars else 85
		u.weapon = item_def(s.gear.weapon).get("weapon", "sword")
		u.shield = s.gear.shield != ""
		for pair in [["armor", "body"], ["padding", "under"], ["helmet", "head"]]:
			u[pair[0]] = durability(s, pair[1])
			u["max_"+pair[0]] = maximum(s, pair[1])
	for i in deployment.size():
		if deployment[i] < 0: continue
		var s: Dictionary = soldiers[deployment[i]]
		var u: Dictionary = battle.units[i]
		u.strain_penalty = s.strain*2
		u.grief_penalty = Relationships.grief_penalty(s)
		u.morale = Relationships.starting_morale(s)
		u.comrades = relationships.comrades(s.id,soldiers).filter(func(id): return id in deployment).map(func(id): return deployment.find(id))
	var threat = int(active.threat)
	for i in range(6, 12):
		var u: Dictionary = battle.units[i]
		if i >= 9+threat:
			u.hp = 0
			u.name = "Empty rank"
			continue
		u.armor = maxi(20, int(u.armor)+(threat-2)*15)
		u.max_armor = u.armor
		u.skill += (threat-2)*4
	battle.events.clear()
	battle.log_event(contract().title + ": " + battle.objective_text())
	phase = "battle"
	retreat = false
	return true

func retreat_from_battle() -> bool:
	if phase != "battle" or not battle.result.is_empty(): return false
	# Clear, voluntary loss: casualties and equipment damage already suffered persist.
	# A retreat spends this contract and receives no pay; it never rerolls the same job.
	retreat = true
	battle.result = "defeat"
	battle.log_event("The company abandons the field and retreats.")
	return resolve_battle()

func resolve_battle() -> bool:
	if phase != "battle" or battle.result.is_empty(): return false
	var won = battle.result == "victory"
	var rows: Array = []
	var newly_fallen = 0
	var new_wounds = 0
	var title: String = contract().title
	var reward = 0
	var effect = "The threat remains."
	var xp_before = {}
	for s in soldiers: xp_before[s.id] = s.xp
	for i in 6:
		if deployment[i] == -1: continue
		var s: Dictionary = soldiers[deployment[i]]
		if not s.alive: continue
		var u: Dictionary = battle.units[i]
		var start_hp = int(s.hp)
		s.hp = int(u.hp)
		s.kills += int(u.kills)
		s.battles += 1
		for pair in [["armor", "body"], ["padding", "under"], ["helmet", "head"]]:
			if items.has(s.gear[pair[1]]): items[s.gear[pair[1]]].condition = int(u[pair[0]])
		var status = "Survived"
		if u.hp == 0:
			s.alive = false
			s.fallen_day = day
			newly_fallen += 1
			status = "Fallen"
			for slot in SLOTS:
				if not won: items.erase(s.gear[slot])
				s.gear[slot] = ""
		elif start_hp - int(u.hp) >= 20 or u.hp <= s.base_hp/3:
			s.wound_days = maxi(int(s.wound_days), 3)
			s.hp = mini(int(s.hp), max_hp(s))
			new_wounds += 1
			status = "Deep wound"
		elif u.routed or u.escaped: status = "Returned shaken"
		var encounter = encounters+1
		var place: String = node().name
		Progression.record(s,"battle_%d" % encounter,day,"battle","%s at %s: %s; %d kills; ended with %d HP." % [title,place,"retreated" if retreat else battle.result,u.kills,s.hp])
		if not s.alive:
			Progression.record(s,"death",day,"death","Fell at %s%s. %d battles and %d kills in company service." % [place," to "+u.last_attacker if not u.last_attacker.is_empty() else "",s.battles,s.kills])
		else:
			if not retreat: Progression.grant(s,"battle_%d" % encounter,20+(10 if won else 0)+mini(3,int(u.kills))*5,day,"Survived "+title+".")
			Progression.scar(s,u,day,encounter,place)
			if u.kills > 0 and s.kills == u.kills: Progression.record(s,"first_kill",day,"deed","First kill in company service at "+place+".")
			if u.kills >= 2: Progression.record(s,"deed_%d" % encounter,day,"deed","Broke their line: %d enemies slain at %s." % [u.kills,place])
			if won and battle.objective != "eliminate" and battle.fighting(u) and battle.distance(battle.pos(u),battle.FORD) <= 1: Progression.record(s,"banner_%d" % encounter,day,"deed","Held the marked ground when the company prevailed at "+place+".")
		rows.append({"id":s.id, "name":s.name, "status":status, "hp":s.hp, "kills":int(u.kills)})
	relationships.settle(soldiers,deployment,battle,day,encounters+1,retreat)
	encounters += 1
	if won and active.kind == "escort":
		world.caravans[active.shipment].guarded = true
		effect = "%s defended. Continue to %s for delivery and payment." % [world.short_id(active.shipment), node(world.route_data(world.caravans[active.shipment].route).path[2]).name]
		world.log_event(effect)
	else:
		if won:
			if active.kind in ["clear", "legacy"]:
				world.clear_camp(active.target, world.camps[active.target].generation)
				effect = "Band destroyed. Remaining cargo freed. Reoccupation needs another funded band."
			elif active.kind == "recover":
				world.recover_shipment(active.shipment)
				effect = "%s recovered and returning to town. The raider camp remains." % world.short_id(active.shipment)
		reward = finish_job(won)
	for row in rows:
		row["xp"] = soldiers[row.id].xp-xp_before[row.id]
		row["level"] = Progression.level(soldiers[row.id])
	aftermath = {"title":title, "result":battle.result, "retreat":retreat, "pay":reward, "fallen":newly_fallen, "wounded":new_wounds, "rows":rows, "day":day, "round":battle.round_no, "effect":effect}
	note("%s: %s; %d fallen, %d wounded." % [title, "withdrawal" if retreat else battle.result, newly_fallen, new_wounds])
	phase = "aftermath"
	advance_day("battle")
	return true

func return_to_camp() -> bool:
	if phase != "aftermath": return false
	phase = "camp"
	return true

func note(message: String) -> void:
	journal.append(message)
	if journal.size() > 60: journal.pop_front()

func snapshot() -> Dictionary:
	return {"version":9, "population_kind":population_kind, "recruit_pools":recruit_pools.duplicate(true), "relationships":relationships.snapshot(), "reputation":reputation.duplicate(), "world":world.snapshot(), "encounters":encounters, "location":location, "food":food, "wins":wins, "arrears":arrears, "unpaid_days":unpaid_days, "ending":ending, "active":active.duplicate(true), "used_jobs":used_jobs.duplicate(), "hired":hired.duplicate(), "deployment":deployment.duplicate(), "seed":seed_value, "day":day, "crowns":crowns, "tools":tools, "medicine":medicine, "completed":completed, "phase":phase, "next_item":next_item, "soldiers":soldiers.duplicate(true), "items":items.duplicate(true), "journal":journal.duplicate(), "aftermath":aftermath.duplicate(true), "retreat":retreat, "battle":battle.snapshot() if phase in ["battle", "aftermath"] else null}

func restore(raw: Variant) -> bool:
	# Validate using temporary objects. Never partially mutate a live company.
	if not raw is Dictionary: return false
	var d: Dictionary = battle.normalize_json_numbers(raw)
	if d.get("version") in [2, 3, 4, 5]: return migrate_previous(d)
	if d.get("version") in [6,7]:
		d.version = 8
		d["relationships"] = Relationships.new().snapshot()
		if d.get("soldiers") is Array:
			for s in d.soldiers:
				if s is Dictionary: Relationships.initialize_soldier(s)
	if d.get("version") == 8:
		if not d.get("seed") is int or not d.get("soldiers") is Array: return false
		d.version = 9
		if not d.has("recruit_pools"):
			d["recruit_pools"] = legacy_pools(d.seed)
			d["population_kind"] = "legacy"
		for s in d.soldiers:
			if s is Dictionary and not s.has("aptitudes"): People.neutral(s)
	if not d.get("population_kind") in ["generated","legacy"] or not d.get("recruit_pools") is Dictionary or d.recruit_pools.size() != 30: return false
	var names = {}
	for town in ["ashwick","stonecross","dunmere"]:
		for week in 5:
			for index in 2:
				var id = "%s_recruit_%d_%d" % [town,week,index]
				var p = d.recruit_pools.get(id)
				if not People.validate_offer(p) or p.id != id: return false
				if d.population_kind == "generated" and names.has(p.person): return false
				names[p.person] = true
	for field in ["version", "seed", "day", "crowns", "tools", "medicine", "completed", "next_item", "food", "wins", "arrears", "unpaid_days", "encounters"]:
		if not d.has(field) or not d[field] is int: return false
	if d.version != 9 or d.encounters < 0 or d.encounters > 1000 or d.food < 0 or d.wins < 0 or d.wins > d.completed or d.arrears < 0 or d.unpaid_days < 0 or d.unpaid_days > 3 or d.seed < 1 or d.day < 1 or d.day > LAST_DAY+1 or d.crowns < 0 or d.tools < 0 or d.medicine < 0 or d.completed < 0 or d.completed > 200 or d.next_item < 1: return false
	if not d.get("reputation") is Dictionary or d.reputation.size() != world.config.factions.size(): return false
	for faction in world.config.factions:
		if not d.reputation.get(faction) is int or d.reputation[faction] < -30 or d.reputation[faction] > 60: return false
	if not d.get("phase", "") in ["camp", "battle", "aftermath"]: return false
	if not d.get("soldiers") is Array or (d.soldiers.size() < 6 or d.soldiers.size() > 186) or not d.get("items") is Dictionary: return false
	if not d.get("journal") is Array or not d.get("aftermath") is Dictionary or not d.get("retreat") is bool: return false
	for message in d.journal:
		if not message is String: return false
	for id in d.items:
		var item = d.items[id]
		if not id is String or not item is Dictionary or item.get("id") != id: return false
		if not catalog.has(item.get("definition", "")) or not item.get("condition") is int: return false
		if item.condition < 0 or item.condition > catalog[item.definition].durability: return false
		if not id.begins_with("item_") or not id.trim_prefix("item_").is_valid_int() or int(id.trim_prefix("item_")) >= d.next_item: return false
	var assigned: Dictionary = {}
	var living_count = 0
	for i in d.soldiers.size():
		var s = d.soldiers[i]
		if not s is Dictionary or s.get("id", -1) != i or not s.get("alive") is bool or not s.get("gear") is Dictionary: return false
		for field in ["name", "title", "background", "trait"]:
			if not s.get(field) is String: return false
		for field in ["id", "base_hp", "base_skill", "base_defense", "hp", "wound_days", "kills", "battles", "fallen_day", "wage"]:
			if not s.get(field) is int or s[field] < 0: return false
		if not Progression.validate(s,d.day) or not People.validate(s) or s.development.size() > Progression.level(s)-1: return false
		if s.alive: living_count += 1
		if s.wage < 1 or s.wage > 20: return false
		if s.base_hp <= 12 or s.hp > max_hp(s) or s.wound_days > 3 or s.alive != (s.hp > 0): return false
		for slot in SLOTS:
			if not s.gear.get(slot) is String: return false
			var id: String = s.gear[slot]
			if id == "":
				if s.alive and slot == "weapon": return false
				continue
			if not s.alive or not d.items.has(id) or assigned.has(id) or catalog[d.items[id].definition].slot != slot: return false
			assigned[id] = true
		if s.alive and d.items[s.gear.weapon].definition == "bow" and s.gear.shield != "": return false
	if living_count > 6: return false
	if not d.get("location") is String or node(d.location).is_empty(): return false
	if not d.get("ending") is String or not d.get("active") is Dictionary: return false
	for field in ["used_jobs", "hired", "deployment"]:
		if not d.get(field) is Array: return false
	for field in ["used_jobs", "hired"]:
		var unique = {}
		for entry in d[field]:
			if not entry is String or unique.has(entry): return false
			unique[entry] = true
	var candidate_relationships = Relationships.new()
	if not candidate_relationships.restore(d.get("relationships"),d.soldiers,d.day,d.encounters): return false
	var candidate_world = World.new()
	if not candidate_world.restore(d.get("world")) or candidate_world.day != d.day: return false
	if not d.active.is_empty():
		for field in ["id", "title", "brief", "origin", "target", "objective", "kind", "shipment", "client"]:
			if not d.active.get(field) is String: return false
		for field in ["pay", "threat", "deadline", "generation"]:
			if not d.active.get(field) is int: return false
		if not d.active.origin in ["ashwick", "stonecross", "dunmere"] or not d.active.target in ["ford", "forest", "ridge"]: return false
		if d.active.client != candidate_world.towns[d.active.origin].owner: return false
		if not d.active.get("participants") is Array or d.active.participants.size() > 6: return false
		var participants = {}
		for id in d.active.participants:
			if not id is int or id < 0 or id >= d.soldiers.size() or participants.has(id): return false
			participants[id] = true
		if not d.active.objective in ["hold", "eliminate", "defend", "escort"] or d.active.pay < 0 or d.active.threat < 1 or d.active.threat > 3: return false
		if d.active.deadline < d.day or d.active.deadline > LAST_DAY or d.active.id in d.used_jobs: return false
		if not d.active.kind in ["clear", "recover", "escort", "legacy"] or d.active.generation < 1: return false
		if d.active.kind in ["recover", "escort"]:
			if not candidate_world.caravans.has(d.active.shipment): return false
			var convoy: Dictionary = candidate_world.caravans[d.active.shipment]
			if candidate_world.route_data(convoy.route).path[1] != d.active.target: return false
			if d.active.kind == "recover" and convoy.status != "seized": return false
			if d.active.kind == "escort" and (convoy.status != "escort" or candidate_world.shipment_at(convoy.id) != d.location): return false
		elif d.active.shipment != "": return false
	for convoy in candidate_world.caravans.values():
		if convoy.status == "escort" and (d.active.is_empty() or d.active.kind != "escort" or d.active.shipment != convoy.id): return false
	if d.phase == "battle" and (d.active.is_empty() or not d.ending.is_empty() or d.location != d.active.target): return false
	if d.phase == "aftermath" and not d.active.is_empty() and (d.active.kind != "escort" or not candidate_world.caravans[d.active.shipment].guarded): return false
	if d.day > LAST_DAY and d.ending.is_empty(): return false
	var deploy_ids = {}
	if d.phase in ["battle", "aftermath"] and d.deployment.size() != 6: return false
	for id in d.deployment:
		if not id is int or id < -1 or id >= d.soldiers.size(): return false
		if id >= 0:
			if deploy_ids.has(id): return false
			deploy_ids[id] = true
	var candidate = Battle.new()
	candidate.setup(d.seed)
	if d.phase in ["battle", "aftermath"]:
		if not candidate.restore(d.get("battle")): return false
		if d.phase == "battle":
			for i in d.deployment.size():
				if d.deployment[i] < 0: continue
				var s: Dictionary = d.soldiers[d.deployment[i]]
				for field in ["endurance","mobility","resolve","temperament"]:
					if candidate.units[i][field] != s[field]: return false
				if candidate.units[i].perks != s.perks or candidate.units[i].scars != s.scars: return false
				var comrades = candidate_relationships.comrades(s.id,d.soldiers).filter(func(id): return id in d.deployment).map(func(id): return d.deployment.find(id))
				if candidate.units[i].comrades != comrades or candidate.units[i].strain_penalty != s.strain*2 or candidate.units[i].grief_penalty != Relationships.grief_penalty(s): return false
		if d.phase == "battle" and (not candidate.result.is_empty() or d.day > LAST_DAY): return false
		if d.phase == "aftermath":
			if candidate.result.is_empty() or d.encounters == 0: return false
			for field in ["title", "result", "retreat", "pay", "fallen", "wounded", "rows", "day", "round"]:
				if not d.aftermath.has(field): return false
			if not d.aftermath.title is String or d.aftermath.result != candidate.result: return false
			if not d.aftermath.day is int or not d.aftermath.round is int: return false
			if not d.aftermath.rows is Array: return false
			for row in d.aftermath.rows:
				if not row is Dictionary: return false
				for field in ["id", "hp", "kills"]:
					if not row.get(field) is int: return false
				for field in ["name", "status"]:
					if not row.get(field) is String: return false
				if row.id < 0 or row.id >= d.soldiers.size() or row.hp < 0 or row.kills < 0: return false
			if not d.aftermath.pay is int or not d.aftermath.fallen is int or not d.aftermath.wounded is int or not d.aftermath.retreat is bool: return false
	recruit_pools = d.recruit_pools
	population_kind = d.population_kind
	relationships = candidate_relationships
	world = candidate_world
	reputation = d.reputation
	encounters = d.encounters
	location = d.location
	food = d.food
	wins = d.wins
	arrears = d.arrears
	unpaid_days = d.unpaid_days
	ending = d.ending
	active = d.active
	used_jobs = d.used_jobs
	hired = d.hired
	deployment = d.deployment
	seed_value = d.seed
	day = d.day
	crowns = d.crowns
	tools = d.tools
	medicine = d.medicine
	completed = d.completed
	phase = d.phase
	next_item = d.next_item
	soldiers = d.soldiers
	items = d.items
	journal = d.journal
	aftermath = d.aftermath
	retreat = d.retreat
	battle = candidate
	return true

func migrate_previous(data: Dictionary) -> bool:
	var previous = Previous.new()
	if not previous.restore(data): return false
	var upgraded = previous.snapshot()
	upgraded.version = 7
	for s in upgraded.soldiers: Progression.initialize(s,upgraded.day,node(upgraded.location).name,true)
	if not upgraded.active.is_empty():
		upgraded.active["participants"] = upgraded.soldiers.filter(func(s): return s.alive).map(func(s): return s.id)
	# Upgrade the tactical payload with neutral perks; old battles keep their exact stats.
	if upgraded.battle != null:
		var migrated_battle = Battle.new()
		if not migrated_battle.restore(upgraded.battle): return false
		upgraded.battle = migrated_battle.snapshot()
	upgraded.journal.append("Soldier service records begin. Earlier battles and kills grant service XP; no scars or detailed deeds are invented.")
	return restore(upgraded)

func learn_perk(soldier_id: int, perk: String) -> bool:
	if phase != "camp" or over() or soldier_id < 0 or soldier_id >= soldiers.size() or not Progression.PERKS.has(perk): return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or Progression.points(s) < 1 or perk in s.perks: return false
	s.perks.append(perk)
	Progression.record(s,"training_"+perk,day,"training","Learned %s. %s" % [Progression.PERKS[perk].name,Progression.PERKS[perk].effect])
	note("%s learns %s." % [s.name,Progression.PERKS[perk].name])
	return true

func region_secured() -> bool:
	for camp in world.camps.values():
		if camp.active: return false
	return true

func attitude(faction: String) -> String:
	var rep = reputation[faction]
	return "Trusted" if rep >= 12 else ("Respected" if rep > 0 else ("Distrusted" if rep <= -12 else "Unproven"))

func quoted_price(town: String, base: int) -> int:
	if not world.towns.has(town): return base
	return maxi(1,roundi(float(base)*(100-clampi(reputation[world.towns[town].owner],-20,20))/100.0))

func change_reputation(faction: String, amount: int, rivalry: int = 0) -> void:
	reputation[faction] = clampi(reputation[faction]+amount,-30,60)
	var rival: String = world.config.factions[faction].rival
	if rivalry > 0: reputation[rival] = clampi(reputation[rival]-rivalry,-30,60)
	note("%s: reputation %+d (%d).%s" % [world.faction_name(faction),amount,reputation[faction], " Rival %s: -%d." % [world.faction_name(rival),rivalry] if rivalry > 0 else ""])

func sponsor_patrol(site: String) -> bool:
	var price: int = world.config.politics.patrol_cost
	if phase != "camp" or over() or not in_town() or crowns < price: return false
	var owner: String = world.towns[location].owner
	# One outstanding order: repeated clicks cannot silently overwrite a paid direction.
	if not world.factions[owner].priority.is_empty(): return false
	if not world.fund_patrol(owner,site,price): return false
	crowns -= price
	change_reputation(owner,4,1)
	note("Funded the next %s patrol to %s for %d crowns. It will depart when the council has no active patrol." % [world.faction_name(owner),node(site).name,price])
	return true

func update_threat() -> void:
	if active.is_empty() or active.kind == "legacy": return
	active.threat = maxi(1,world.camps[active.target].strength-(1 if active.kind == "recover" else 0))
	if active.kind == "recover":
		active.brief = "Recover the remaining %d food in %s. Raiders spend cargo daily. Quoted pay is honored if any food is recovered." % [world.caravans[active.shipment].cargo,world.short_id(active.shipment)]

func reconcile_contract() -> void:
	if active.is_empty(): return
	var obsolete = (active.kind == "clear" and (not world.camps[active.target].active or world.camps[active.target].generation != active.generation)) or (active.kind == "recover" and world.caravans[active.shipment].status != "seized")
	if obsolete:
		note("%s withdrawn: the target was resolved or its cargo exhausted. No payment or reputation penalty." % active.title)
		used_jobs.append(active.id)
		active.clear()
	else: update_threat()

func camp_decision_reason(kind: String, id: int, other: int = -1) -> String:
	if phase != "camp" or over() or id < 0 or id >= soldiers.size() or not soldiers[id].alive: return "Choose a living soldier in an active camp."
	var s: Dictionary = soldiers[id]
	if kind == "meal":
		if s.strain == 0: return "No strain to ease."
		if food < 6: return "Needs 6 extra rations."
		if s.history.any(func(e): return e.id == "meal_%d" % day): return "Already shared an extra meal today."
		return ""
	if not kind in ["support","mediate"]: return "Unknown camp decision."
	if crowns < wage_cost()+arrears or food < alive_count(): return "A day together requires the full wages, arrears and company rations."
	if kind == "support" and s.grief.is_empty(): return "No active grief to support."
	if kind == "mediate":
		if other < 0 or other >= soldiers.size() or not soldiers[other].alive or other == id: return "Select a living partner."
		if relationships.trust(id,other) >= 0: return "No strained relationship to mediate."
	return ""

func camp_decision(kind: String, id: int, other: int = -1) -> bool:
	if not camp_decision_reason(kind,id,other).is_empty(): return false
	var s: Dictionary = soldiers[id]
	if kind == "meal":
		food -= 6
		s.strain = maxi(0,s.strain-2)
		Progression.record(s,"meal_%d" % day,day,"camp","Shared 6 extra company rations; strain reduced by up to 2. No time passed.")
		note("Extra meal for %s: 6 rations; strain now %d." % [s.name,s.strain])
	elif kind == "support":
		var loss: Dictionary = s.grief.pop_front()
		Progression.record(s,"grief_eased_%d" % loss.person,day,"grief","A day of company support eased grief for %s. The bond remains in their record." % soldiers[loss.person].name)
		note("The company makes time for %s to remember %s." % [s.name,soldiers[loss.person].name])
		advance_day("rest")
	else:
		relationships.change(soldiers,id,other,mini(2,-relationships.trust(id,other)),"mediation_%d" % day,day,"A day of mediation eased the dispute; trust can return to neutral, not become comrades by payment.")
		note("A day to mediate between %s and %s." % [s.name,soldiers[other].name])
		advance_day("rest")
	return true
