extends RefCounted
const ResourceSpoils = preload("res://bandit_spoils/rewards.gd")
var bandit_stashes: Dictionary = {}
var bandit_members: Array = []
const Dungeons = preload("res://src/dungeons.gd")
var dungeons = Dungeons.new()
const Named = preload("res://src/named_equipment.gd")
const NamedMail = preload("res://layer_forge/named_mail.gd")
var named_rewards: Dictionary = {}
const RegionalNews = preload("res://src/regional_news.gd")
var news = RegionalNews.new()
const RegionalRecovery = preload("res://src/regional_recovery.gd")
var rebuilding = RegionalRecovery.new()
const ExpandedRegion = preload("res://src/expanded_region.gd")
const CampLife = preload("res://src/camp_life.gd")
var camp_life = CampLife.new()
const CampRecon = preload("res://src/camp_recon.gd")
var recon = CampRecon.new()
const RaiderNeeds = preload("res://src/raider_needs.gd")
var raiders = RaiderNeeds.new()
const CampFounding = preload("res://src/camp_founding.gd")
var founding = CampFounding.new()
const Perks = preload("res://src/perks.gd")
const PerkProgression = preload("res://src/perk_progression.gd")
var perks_pending = false
## Persistent company state. Resolving a battle is a single, idempotent transition.
const Market = preload("res://src/market.gd")
var market_books: Dictionary = {}
var sales: Array = []
const Arsenal = preload("res://src/arsenal.gd")
const Armor = preload("res://src/armor.gd")
var purchased_gear: Array = []
const People = preload("res://src/people.gd")
var recruit_pools: Dictionary = {}
var population_kind = "generated"
var balance_pending = false
var combat_pending = false
var growth_pending = false
const LegacyPeople = preload("res://src/legacy_people_v16.gd")
const Relationships = preload("res://src/relationships.gd")
var relationships = Relationships.new()
const Progression = preload("res://src/progression.gd")
const Battle = preload("res://src/battle.gd")
const SLOTS = ["weapon", "body", "head", "shield", "carry1", "carry2", "carry3", "carry4", "ammo"]
const CampaignBalance = preload("res://src/campaign_balance.gd")
const RoadContracts = preload("res://src/road_contracts.gd")
var progression_version = 0
const CompanyRoster = preload("res://src/company_roster.gd")
var roster_version = 0
var formation: Array = []
const Recovery = preload("res://src/recovery.gd")
var opening_rules = true
var recovery: Dictionary = Recovery.fresh()
var recovery_pending = false
const Previous = preload("res://src/legacy_campaign_v5.gd")
const World = preload("res://src/world.gd")
var world = World.new()
const Overworld = preload("res://src/overworld.gd")
var overworld = Overworld.new()
var encounter: Dictionary = {}
const MapGenerator = preload("res://src/map_generator.gd")
const Exploration = preload("res://src/exploration.gd")
var exploration = Exploration.new()
const Traffic = preload("res://src/traffic.gd")
var traffic = Traffic.new()
const Bandits = preload("res://src/bandits.gd")
var bandits = Bandits.new()
const Farm = preload("res://src/farm.gd")
var farm = Farm.new()
const Guards = preload("res://src/guards.gd")
var guards = Guards.new()
var encounters = 0
var reputation: Dictionary = {"wardens":0,"guild":0,"compact":0}
const Career = preload("res://src/career.gd")
var endless = false
const Economy = preload("res://src/economy.gd")
var economy = Economy.new()
const LAST_DAY = 30
const REQUIRED_WINS = 4
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
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
var battle = Battle.new()
var soldiers: Array = []
var items: Dictionary = {}
var next_item = 1
var day = 1
var crowns = 700
var tools = 60
var medicine = 18
const STARTING_AMMUNITION = 60
const AMMO_PURCHASE_SIZE = 30
var ammunition = STARTING_AMMUNITION
var ammo_pending = false
var completed = 0
var seed_value = 7391
var phase = "camp"
var journal: Array = []
var aftermath: Dictionary = {}
var retreat = false

func starting_raider_rules() -> int:
	return 5

func generate_expanded_region(geography_seed: int) -> Dictionary:
	return ExpandedRegion.new().generate(geography_seed)

func setup(seed_number: int = 7391, map_seed: int = -1, progression: bool = false, live_trade: bool = false, living_bands: bool = false, company_roster: bool = false, rural_supply: bool = false, physical_patrols: bool = false, hinterlands: bool = false, renewing_camps: bool = false, open_campaign: bool = false, world_economy: bool = false, expanded_region: bool = false, regional_news: bool = false, regional_recovery: bool = false, fading_tracks: bool = false, camp_reconnaissance: bool = false, raider_survival: bool = false, camp_founding: bool = false) -> void:
	endless = open_campaign
	economy = create_economy(); news = RegionalNews.new()
	economy.industry.acquisition = acquisition_policy()
	roster_version = 1 if company_roster else 0; formation = CompanyRoster.empty()
	progression_version = 1 if progression else 0
	opening_rules = true; recovery = Recovery.fresh(); recovery_pending = false
	seed_value = maxi(1, seed_number)
	balance_pending = false
	combat_pending = false
	growth_pending = false
	perks_pending = false
	catalog = equipment_catalog_for_validation(false)
	battle.setup(seed_value,"ford","hold",true,true,true,true,true)
	relationships = Relationships.new()
	soldiers.clear()
	rebuilding = RegionalRecovery.new()
	items.clear(); named_rewards.clear(); dungeons = create_dungeons(catalog); camp_life = CampLife.new(); recon = CampRecon.new(); raiders = RaiderNeeds.new(); founding = CampFounding.new()
	camp_life.acquisition = acquisition_policy()
	next_item = 1
	day = 1
	region = generate_expanded_region(map_seed if map_seed > 0 else seed_number) if expanded_region else MapGenerator.new().generate(map_seed) if map_seed >= 0 else JSON.parse_string(FileAccess.get_file_as_string("res://data/region.json"))
	world = World.new()
	world.configure(region)
	world.setup()
	exploration.setup(region)
	overworld.setup(region,world)
	overworld.tracks.setup(fading_tracks and living_bands and live_trade and map_seed >= 0)
	traffic = Traffic.new(); traffic.setup(self,live_trade and map_seed >= 0)
	farm = Farm.new(); guards = Guards.new()
	bandits = Bandits.new(); bandits.setup(self,living_bands and traffic.enabled)
	farm.setup(self,rural_supply and bandits.enabled,hinterlands)
	guards.setup(self,physical_patrols and farm.enabled)
	encounter.clear()
	encounters = 0
	reputation.clear()
	for faction in world.FACTIONS: reputation[faction] = 0
	crowns = 300
	tools = 20
	medicine = 6
	ammunition = STARTING_AMMUNITION
	ammo_pending = false
	completed = 0
	phase = "camp"
	bandit_stashes.clear()
	bandit_members.clear()
	journal.clear()
	aftermath.clear()
	retreat = false
	location = "ashwick"
	food = 24
	wins = 0
	arrears = 0
	unpaid_days = 0
	ending = ""
	active.clear()
	used_jobs.clear()
	hired.clear()
	purchased_gear.clear()
	market_books.clear(); sales.clear()
	deployment.clear()
	var population = create_population()
	population_kind = "generated"
	recruit_pools = population.pools
	for p in population.founders+recruit_pools.values():
		p["armor_loadout"] = Armor.offer_loadout(p,true)
		p["legacy_armor"] = false
	for p in recruit_pools.values(): prepare_new_recruit(p,0)
	for candidate in population.founders: add_person(candidate)
	# A small reserve; no free armoury of late-game equipment.
	add_item(reserve_weapon_definition())
	ensure_market()
	if world_economy: economy.setup(self,true)
	camp_life.setup(self,renewing_camps and farm.regional and bandits.enabled)
	if regional_news and economy.enabled: news.setup(self)
	rebuilding.setup(self,regional_recovery and not world_economy)
	recon.setup(self,camp_reconnaissance)
	raiders.setup(self,raider_survival)
	founding.setup(self,camp_founding)
	note("The Ashen Company takes the road. Three companions, modest kits, and a road ahead.")

# Default-preserving extension seams. Full restore below still owns every module.
func create_population() -> Dictionary:
	return People.new().population(seed_value,world.TOWNS)
func prepare_new_recruit(_offer: Dictionary, _created_week: int) -> void:
	pass
func valid_purchase_ids(data: Dictionary,definitions: Dictionary,config: Dictionary) -> Dictionary:
	var out = {}
	for town in config.towns:
		for week in range((data.day-1)/7+1):
			for definition in definitions:
				if definitions[definition].has("price"): out["%s_%d_%s" %[town,week,definition]] = true
	return out

func create_economy():
	return Economy.new()

func acquisition_policy():
	return null
func create_dungeons(definitions: Dictionary):
	var out = Dungeons.new()
	out.acquisition = acquisition_policy()
	if out.acquisition != null: out.equipment_catalog_override = definitions.duplicate(true)
	return out
func recovered_armor_is_loose() -> bool:
	return false
func reserve_weapon_definition() -> String:
	return "knife"
func equipment_catalog_for_validation(balance: bool) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy_equipment_v14.json" if balance else "res://data/equipment.json"))
func validation_slots() -> Array:
	return SLOTS
func valid_gear_size(person: Dictionary) -> bool:
	return person.gear.size() in [7,9]
func capacity_for_items(person: Dictionary, _items: Dictionary, _catalog: Dictionary) -> int:
	return 4 if Perks.has(person,"bags_and_belts") else 2
func add_item(definition: String, condition: int = -1) -> String:
	var id = "item_%03d" % next_item
	next_item += 1
	var maximum = int(catalog[definition].durability)
	items[id] = {"id":id, "definition":definition, "condition":maximum if condition < 0 else clampi(condition, 0, maximum)}
	if Arsenal.family(definition) == "crossbow": items[id]["loaded"] = false
	return id

func alive_count() -> int:
	var count = 0
	for s in soldiers:
		if s.alive: count += 1
	return count

func over() -> bool:
	return not ending.is_empty() or alive_count() == 0 or (not endless and day > LAST_DAY)

func job_deadline(duration: int) -> int:
	return day+duration if endless else mini(LAST_DAY,day+duration)

func can_continue_campaign() -> bool:
	return not endless and phase == "camp" and alive_count() > 0 and unpaid_days < 3 and ending in ["The Ashen Company endures.","The month ends. The company falls short."]

func continue_campaign() -> bool:
	if not can_continue_campaign(): return false
	endless = true; ending = ""; overworld.paused = true
	Career.ensure_recruits(self); ensure_market()
	note("The company takes the road again. There is no final day; wages and losses still matter.")
	return true

func node(id: String = "") -> Dictionary:
	if id.is_empty() and not overworld.places.is_empty() and not overworld.at_site(location):
		return {"id":"wilderness","name":"The open Marches","kind":"wild","description":"Open country.","map":"forest" if overworld.terrain(overworld.position) == "forest" else "ridge"}
	for place in region.locations+dungeons.locations():
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
		var job = make_job("clear_%s_%d" % [site, camp.generation], "clear", site, "", "Clear "+node(site).name, "Destroy the band and free remaining cargo. Reoccupation requires supplies from another band.", (130+camp.strength*60 if opening_rules else 280+camp.strength*100), camp.strength, {"ford":"hold", "forest":"eliminate", "ridge":"defend"}[world.camp_role(site)])
		if not job.id in used_jobs: out.append(job)
	for c in world.caravans.values():
		var route = world.route_data(c.route)
		var job: Dictionary = {}
		if economy.freight.physical(c.id):
			var load: Dictionary=economy.freight.state.shipments[c.id]
			# The buyer knows its overdue order, not the culprit's present location.
			if location!=load.destination or load.phase not in ["band","secured","fencing"]:continue
			if not traffic.traces[c.id].inspected and day<=c.depart_day+int(route.days[0])+int(route.days[1]):continue
			job=make_job("recover_"+c.id,"recover",route.path[1],c.id,"Recover "+world.short_id(c.id),"Missing on the %s road: %d %s. Bring the sealed freight here for payment." % [node(load.origin).name,load.amount,load.kind],130+load.cost,1,"eliminate")
			job.generation=load.generation
		elif c.status == "seized" and location in [route.path[0], route.path[2]]:
			var site: String = route.path[1]
			job = make_job("recover_"+c.id, "recover", site, c.id, "Recover "+world.short_id(c.id), "Retrieve %s for %s. The wider raider camp remains." % [world.cargo_text(c.id), node(route.path[2]).name], (130+world.cargo_value(c.id) if opening_rules else 200+world.cargo_value(c.id)), maxi(1, int(world.camps[site].strength)-1), "eliminate")
		elif c.status == "waiting" and location == route.path[0] and (progression_version == 1 or world.camps[route.path[1]].active) and reputation[world.towns[location].owner] > -12:
			job = make_job("escort_"+c.id, "escort", route.path[1], c.id, "Escort to "+node(route.path[2]).name, "Deliver %s: %s. Defend at %s, then continue to town. Payment on arrival." % [world.short_id(c.id), world.cargo_text(c.id), node(route.path[1]).name], (230+world.cargo_value(c.id) if opening_rules else 400+world.cargo_value(c.id)), world.camps[route.path[1]].strength, "escort")
		if progression_version == 1 and not job.is_empty() and job.kind == "escort" and world.protected_road(job.target):
			job.pay = ceili(float(100+world.cargo_value(c.id))*(100.0+reputation[job.client]/2.0)/100.0)
			job.brief = "Guarded road delivery: %s to %s. Pay on arrival; road security can change en route." % [world.cargo_text(c.id),node(route.path[2]).name]
		if not job.is_empty() and not job.id in used_jobs: out.append(job)
	if economy.enabled: return economy.funded_offers(self,out)
	out.append_array(RoadContracts.offers(self))
	return out

func make_job(id: String, kind: String, target: String, shipment: String, title: String, brief: String, pay: int, threat: int, objective: String) -> Dictionary:
	var client: String = world.towns[location].owner
	if progression_version == 1 and kind == "clear": pay += {"ford":0,"forest":50,"ridge":110}[world.camp_role(target)]
	pay = ceili(float(pay)*(100.0+reputation[client]/2.0)/100.0)
	return {"client":client, "id":id, "kind":kind, "target":target, "shipment":shipment, "generation":world.camps[target].generation, "title":title, "brief":brief, "pay":pay, "threat":threat, "objective":objective, "origin":location, "deadline":job_deadline(8)}

func accept_job(id: String) -> bool:
	if phase != "camp" or over() or not active.is_empty(): return false
	for job in offers():
		if job.id != id: continue
		if economy.enabled and not economy.reserve(self,job): return false
		if job.kind == "escort" and not world.reserve_escort(job.shipment):
			economy.release(self,false)
			return false
		traffic.sync(self)
		active = job.duplicate(true)
		# Contract directions name the destination; exploration reveals its geography.
		active["participants"] = CompanyRoster.active(self)
		note("Signed %s: %d crowns, due day %d." % [active.title, active.pay, active.deadline])
		return true
	return false

func finish_job(won: bool) -> int:
	if active.is_empty(): return 0
	if won and active.kind=="recover" and economy.freight.physical(active.shipment) and economy.freight.state.shipments[active.shipment].phase!="paid_return":return 0
	change_reputation(active.client,8 if won else -6,2 if won else 0)
	var legacy_pay = economy.legacy_job == active.id
	var reward = finish_job_payment(won)
	if won:
		for id in active.participants:
			Progression.grant(soldiers[id],"contract_"+active.id,10,day,"Fulfilled "+active.title+".")
		wins += 1
		if not economy.enabled or legacy_pay:
			tools += 4 if opening_rules else 12
			medicine += 1 if opening_rules else 4
		if not opening_rules: add_item(["nasal","heavy_mail","gambeson","breastplate","brigandine","mail_coif","shoulders","fur_mantle"][completed%8])
	elif active.kind == "escort": world.release_escort(active.shipment)
	completed += 1
	used_jobs.append(active.id)
	note(finish_job_message(won,reward))
	active.clear()
	traffic.sync(self)
	return reward

# Successors may retain funded rewards as receivables without changing objective
# completion, reputation, XP, loot, or escort destination settlement.
func finish_job_message(won: bool, reward: int) -> String:
	return "%s: %s. %d crowns earned." % [active.title, "fulfilled" if won else "closed unpaid", reward]

func finish_job_payment(won: bool) -> int:
	var reward = int(active.pay) if won else 0
	if economy.enabled: economy.release(self,won)
	crowns += reward
	return reward

func abandon_job() -> bool:
	if phase != "camp" or active.is_empty() or over(): return false
	finish_job(false)
	return true

func can_deploy() -> bool:
	if CompanyRoster.active(self).is_empty(): return false
	if not encounter.is_empty(): return phase == "camp" and not over()
	if not overworld.at_site(location): return false
	if phase != "camp" or over() or active.is_empty() or location != active.target or day > active.deadline: return false
	if RoadContracts.is_road(active.kind): return true
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
	if roster_version == 1 and active_ids().is_empty(): return false
	if dungeons.active != "": return false
	# Compatibility helper for old planners/tests. The player UI uses begin_travel.
	var duration = travel_days(target)
	if phase != "camp" or over() or not encounter.is_empty() or duration == 0 or (not endless and day+duration > LAST_DAY+1): return false
	var escort = not active.is_empty() and active.kind == "escort"
	if escort and target != next_escort_stop(): return false
	if escort and world.caravans[active.shipment].index == 1: world.caravans[active.shipment].guarded = true
	for i in duration:
		# Arrival and delivery precede the final day's accounting, just as battle pay does.
		if i == duration-1:
			location = target
			overworld.position = overworld.places[target]
			overworld.path.clear(); overworld.destination = ""; overworld.paused = true; overworld.reveal()
			if escort and not active.is_empty():
				world.escort_arrive(active.shipment, target)
				if world.caravans[active.shipment].status == "delivered": finish_job(true)
		advance_day("travel")
		if over() and i < duration-1: return true
	note("Arrived at %s on day %d." % [node().name, day])
	return true

func wage_cost() -> int:
	var total = 0
	for s in soldiers:
		if s.alive: total += s.wage
	return total

func advance_day(activity: String, clocked: bool = false) -> void:
	if not clocked and activity != "battle" and not recovery_pending: Recovery.step(self,480,activity == "rest")
	# Travel and rest own elapsed time; tactical battles never charge upkeep.
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
	relationships.daily(soldiers,day,fed,arrears == 0,activity == "rest")
	note("Day %d: %s; %d crowns paid, %d rations. %s" % [day, activity, paid, mouths, "Hunger costs 8 HP each." if not fed else ("%d treated." % treated if activity == "rest" else "")])
	day += 1
	var old_event = world.event_seq
	farm.sync(self)
	var previous_consumed = world.consumed
	world.tick(rebuilding.enabled)
	economy.daily(self,world.consumed-previous_consumed)
	overworld.sync_scouts(world)
	guards.daily(self)
	camp_life.daily(self)
	raiders.daily(self)
	farm.daily(self)
	rebuilding.daily(self)
	if rebuilding.enabled: world.dispatch_shipments()
	if traffic.enabled:
		if not clocked: traffic.background_day(self)
		traffic.sync(self)
	bandits.sync(self)
	for event in world.events:
		if event.id > old_event: note(event.text)
	reconcile_contract()
	if not active.is_empty() and day > active.deadline:
		note("Contract expired: %s." % active.title)
		finish_job(false)
	if alive_count() == 0: ending = "The company is gone."
	elif unpaid_days >= 3: ending = "Three unpaid days. The company disbands."
	elif not endless and day > LAST_DAY:
		ending = "The Ashen Company endures." if (wins >= REQUIRED_WINS or region_secured()) and arrears == 0 else "The month ends. The company falls short."
	if not ending.is_empty() and not active.is_empty(): finish_job(false)
	if endless:
		Career.ensure_recruits(self)
		if day == 31: note("Thirty days on the road. The company carries on.")
	ensure_market()

func recruits() -> Array:
	var out: Array = []
	if not in_town() or over(): return out
	var week = (day-1)/7
	for i in 2:
		var id = "%s_recruit_%d_%d" % [location,week,i]
		if recruit_pools.has(id) and not id in hired: out.append(recruit_pools[id].duplicate(true))
	return out

func add_person(candidate: Dictionary) -> void:
	var gear = {"weapon":add_item(candidate.weapon),"body":"","head":"","shield":add_item(candidate.loadout.shield) if candidate.loadout.shield != "" else ""}
	for i in 2: gear["carry%d" % (i+1)] = add_item(candidate.carried_loadout[i]) if candidate.carried_loadout[i] != "" else ""
	gear["carry3"] = ""; gear["carry4"] = ""
	gear["ammo"] = add_item(candidate.ammo_loadout) if candidate.ammo_loadout != "" else ""
	for group in Armor.LAYERS:
		var parts = empty_owned_parts(group)
		for layer in parts:
			var definition: String = candidate.armor_loadout[group][layer]
			if definition.is_empty(): continue
			parts[layer] = add_item(definition)
			if candidate.legacy_armor: items[parts[layer]]["legacy_weight"] = true
		gear[group] = add_assembly(group,parts)
	var s = {"id":soldiers.size(),"name":candidate.person,"title":candidate.name.to_upper(),"base_hp":candidate.hp,"base_skill":candidate.skill,"base_defense":candidate.defense,"hp":candidate.hp,"alive":true,"wound_days":0,"kills":0,"battles":0,"fallen_day":0,"gear":gear,"wage":candidate.wage,"background":candidate.name,"trait":candidate.trait}
	People.copy_identity(candidate,s)
	Progression.initialize(s,day,node().name)
	if Perks.modern(candidate):
		for key in ["perk_version","perk_groups","perk_pool","gifted_choices"]: s[key] = candidate[key].duplicate(true) if candidate[key] is Array else candidate[key]
	Relationships.initialize_soldier(s)
	soldiers.append(s)
	CompanyRoster.add(self,s.id)

func hire(id: String) -> bool:
	if phase != "camp" or over() or alive_count() >= company_limit(): return false
	for candidate in recruits():
		if candidate.id != id: continue
		if crowns < candidate.price: return false
		crowns -= candidate.price
		hired.append(id)
		add_person(candidate)
		note("%s the %s joins. %d crowns now, %d per day." % [candidate.person,candidate.name,candidate.price,candidate.wage])
		return true
	return false

func develop(soldier_id: int, choices: Variant) -> bool:
	# The whole level is a single transaction. Invalid or partial picks change nothing.
	if phase != "camp" or over() or growth_pending or soldier_id < 0 or soldier_id >= soldiers.size() or not choices is Array: return false
	var s: Dictionary = soldiers[soldier_id]
	var index = Progression.pending(s)
	if not s.alive or index < 0 or choices.size() != 3-s.training[index].size(): return false
	var seen = {}
	for attr in choices:
		if not attr is String or not attr in People.ATTRS or seen.has(attr) or attr in s.training[index]: return false
		seen[attr] = true
	var summary: Array = []
	for attr in choices:
		var gain: int = s.growth_offers[index][attr]
		var old_max = max_hp(s)
		s[People.FIELDS[attr]] += gain
		if attr == "health": s.hp += max_hp(s)-old_max # Includes Colossus once; missing HP stays unchanged.
		s.development.append(attr)
		s.training[index].append(attr)
		summary.append("%s +%d" % [People.LABELS[attr],gain])
	Progression.record(s,"growth_level_%d" % (index+2),day,"training","Level %d training: %s." % [index+2,", ".join(summary)])
	note("%s trains level %d: %s." % [s.name,index+2,", ".join(summary)])
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
	return floori((int(s.base_hp) - (12 if s.wound_days > 0 else 0))*(1.25 if Perks.has(s,"colossus") else 1.0))

func effective_skill(s: Dictionary) -> int:
	return int(s.base_skill) - (10 if s.wound_days > 0 else 0) - (4 if "clouded_eye" in s.scars else 0)

func item_def(id: String) -> Dictionary:
	return Named.definition(items[id],catalog) if items.has(id) else {}

func parent_kit(id: String) -> String:
	if id.is_empty(): return ""
	for item in items.values():
		if item.has("parts") and id in item.parts.values(): return item.id
	return ""

func owner(id: String) -> int:
	if id.is_empty(): return -1
	var parent = parent_kit(id)
	for s in soldiers:
		if id in s.gear.values() or (not parent.is_empty() and parent in s.gear.values()): return int(s.id)
	return -1

func owned_layer_keys(group: String) -> Array:
	return Armor.LAYERS.get(group,[])

func empty_owned_parts(group: String) -> Dictionary:
	var out = {}
	for layer in owned_layer_keys(group): out[layer] = ""
	return out

func owned_assembly_conflict(parts: Dictionary, group: String, definitions: Dictionary) -> String:
	return Armor.conflict(parts,group,definitions)

func add_assembly(group: String, parts: Dictionary = {}) -> String:
	var id = add_item(group+"_kit")
	items[id]["parts"] = empty_owned_parts(group) if parts.is_empty() else parts.duplicate()
	return id

func wrap_spare_armor() -> void:
	for id in items.keys():
		var d = item_def(id)
		if d.get("slot") not in ["body","head"] or d.get("assembly",false) or owner(id) >= 0 or not parent_kit(id).is_empty(): continue
		var parts = Armor.empty_parts(d.group)
		parts[d.layer] = id
		add_assembly(d.group,parts)

func stash(slot: String) -> Array:
	var out: Array = []
	for id in items:
		var d = item_def(id)
		if owner(id) == -1 and parent_kit(id).is_empty() and (d.slot in ["weapon","shield","ammo"] if slot in Arsenal.CARRIED else d.slot == slot) and (slot not in ["body","head"] or d.get("assembly",false)): out.append(id)
	return out

func components(group: String, layer: String) -> Array:
	return items.keys().filter(func(id): return item_def(id).get("group") == group and item_def(id).get("layer") == layer and owner(id) < 0 and parent_kit(id).is_empty())

func kit_parts(kit: String) -> Dictionary:
	return items.get(kit,{}).get("parts",{}).duplicate()

func kit_name(id: String) -> String:
	var parts = kit_parts(id)
	for layer in ["outer","mail","base"] if item_def(id).get("slot") == "body" else ["shell","mail","padding","decor"]:
		if not parts.get(layer,"").is_empty(): return item_def(parts[layer]).name
	return "Empty assembly"

func kit_summary(id: String) -> String:
	var group = item_def(id).get("slot","")
	var s = {"gear":{"body":"","head":""}}
	if not group in Armor.LAYERS: return ""
	s.gear[group] = id
	var stats = armor_stats(s)
	var pool = Armor.display_pool(stats,group)
	return ("Body" if group == "body" else "Helmet")+" %d/%d · %s · %d load" % [pool.current,pool.maximum,Armor.condition_state(pool.current,pool.maximum),stats.load]

func component_definitions(parts: Dictionary) -> Dictionary:
	var out = {}
	for layer in parts: out[layer] = items.get(parts[layer],{}).get("definition","")
	return out

func battle_parts(s: Dictionary, override_group: String = "", override: Dictionary = {}) -> Array:
	var out: Array = []
	for group in Armor.LAYERS:
		var parts = override if group == override_group else kit_parts(s.gear[group])
		for layer in parts:
			var id: String = parts[layer]
			if not items.has(id): continue
			var item: Dictionary = items[id]
			if dungeons.forge_rewards and item.has("named") and not forge_named_mail_owned(id): continue
			var d: Dictionary = item_def(id)
			out.append({"item":id,"definition":item.definition,"group":group,"layer":layer,"pool":"helmet" if group == "head" else ("padding" if layer == "base" else "armor"),"condition":item.condition,"maximum":int(d.durability),"weight":Armor.part_weight(item,catalog)})
			if item.has("named"): out[-1]["named"] = item.named.duplicate(true)
	return out

func forge_named_mail_owned(uid: String) -> bool:
	if not dungeons.forge_rewards or not NamedMail.owned(uid,items,named_rewards,next_item,catalog): return false
	var replay: Dictionary = dungeons.replay_named_mail(region,seed_value)
	if replay.is_empty() or named_rewards[NamedMail.KEY].item != replay.item: return false
	var site: Dictionary = dungeons.sites[NamedMail.SITE]
	var room: Dictionary = site.floors[NamedMail.FLOOR].rooms[NamedMail.ROOM]
	return site.completed == true and room.looted == true and NamedMail.cleared(site,room)

func armor_stats(s: Dictionary, group: String = "", parts: Dictionary = {}) -> Dictionary:
	return Armor.totals(battle_parts(s,group,parts))

func armor_appearance(s: Dictionary) -> Dictionary:
	var out = {}
	for group in Armor.LAYERS: out[group] = component_definitions(kit_parts(s.gear[group]))
	return out

func equip(soldier_id: int, item_id: String, destination: String = "") -> bool:
	if phase != "camp" or over() or soldier_id < 0 or soldier_id >= soldiers.size() or not items.has(item_id): return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or owner(item_id) != -1 or not parent_kit(item_id).is_empty(): return false
	var definition = item_def(item_id)
	if definition.has("group"): return fit_component(soldier_id,definition.group,definition.layer,item_id)
	var slot: String = definition.slot if destination.is_empty() else destination
	if not slot in SLOTS or (slot in Arsenal.CARRIED and not slot in Arsenal.bag_slots(s)): return false
	if slot in Arsenal.SLOTS and not Arsenal.allowed(slot,items[item_id].definition,catalog): return false
	if slot in ["body","head"] and definition.slot != slot: return false
	if slot == "shield" and item_def(s.gear.weapon).get("weapon", "") in Arsenal.TWO_HANDS: return false
	s.gear[slot] = item_id
	recovery.stored.erase(item_id)
	if slot == "weapon" and definition.weapon in Arsenal.TWO_HANDS: s.gear.shield = ""
	note("%s equips %s in %s." % [s.name, definition.name,slot])
	return true

func component_preview(soldier_id: int, group: String, layer: String, item_id: String = "", definition: String = "") -> Dictionary:
	var out = {"ok":false,"reason":"Select a living soldier and a component.","before":{},"after":{},"appearance":{}}
	if soldier_id < 0 or soldier_id >= soldiers.size() or not layer in owned_layer_keys(group): return out
	var s: Dictionary = soldiers[soldier_id]
	out.before = armor_stats(s)
	var parts = kit_parts(s.gear[group])
	if parts.is_empty(): parts = empty_owned_parts(group)
	var defs = component_definitions(parts)
	if not item_id.is_empty():
		if not items.has(item_id) or owner(item_id) >= 0 or not parent_kit(item_id).is_empty(): out.reason = "That piece is already fitted or carried by a soldier."; return out
		definition = items[item_id].definition
	if not definition.is_empty() and (not catalog.has(definition) or catalog[definition].get("group") != group or catalog[definition].get("layer") != layer): out.reason = "That piece belongs to a different slot."; return out
	parts[layer] = item_id
	defs[layer] = definition
	out.after = armor_stats(s,group,parts)
	if item_id.is_empty() and not definition.is_empty():
		var d: Dictionary = catalog[definition]
		var pool = "helmet" if group == "head" else ("padding" if layer == "base" else "armor")
		out.after[pool] += int(d.durability); out.after["max_"+pool] += int(d.durability); out.after.load += int(d.weight)
	out.appearance = armor_appearance(s)
	out.appearance[group] = defs
	out.reason = owned_assembly_conflict(defs,group,catalog)
	if phase != "camp" or over() or not s.alive: out.reason = "Equipment can be changed by living soldiers in an active camp."
	out.ok = out.reason.is_empty()
	return out

func fit_component(soldier_id: int, group: String, layer: String, item_id: String) -> bool:
	var preview = component_preview(soldier_id,group,layer,item_id)
	if not preview.ok: return false
	var s: Dictionary = soldiers[soldier_id]
	if s.gear[group].is_empty():
		if item_id.is_empty(): return false
		s.gear[group] = add_assembly(group)
	var kit: Dictionary = items[s.gear[group]]
	if kit.parts[layer] == item_id: return false
	kit.parts[layer] = item_id
	recovery.stored.erase(item_id)
	note("%s: %s %s." % [s.name,"removed" if item_id.is_empty() else "fitted",Armor.LABELS.get(layer,layer) if item_id.is_empty() else item_def(item_id).name])
	return true

func swap_kit(a: int, b: int, group: String) -> bool:
	if phase != "camp" or over() or not group in Armor.LAYERS or a == b or a < 0 or b < 0 or a >= soldiers.size() or b >= soldiers.size(): return false
	if not soldiers[a].alive or not soldiers[b].alive or (soldiers[a].gear[group].is_empty() and soldiers[b].gear[group].is_empty()): return false
	var kit: String = soldiers[a].gear[group]
	soldiers[a].gear[group] = soldiers[b].gear[group]
	soldiers[b].gear[group] = kit
	note("%s and %s exchange complete %s assemblies." % [soldiers[a].name,soldiers[b].name,group])
	return true

func unequip(soldier_id: int, slot: String) -> bool:
	if phase != "camp" or over() or not slot in SLOTS or slot == "weapon" or soldier_id < 0 or soldier_id >= soldiers.size(): return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or s.gear.get(slot,"") == "": return false
	s.gear[slot] = ""
	return true

func durability(s: Dictionary, slot: String) -> int:
	if slot in ["body","head","under"]: return armor_stats(s)[{"body":"armor","head":"helmet","under":"padding"}[slot]]
	return int(items[s.gear[slot]].condition) if items.has(s.gear[slot]) else 0

func maximum(s: Dictionary, slot: String) -> int:
	if slot in ["body","head","under"]: return armor_stats(s)[{"body":"max_armor","head":"max_helmet","under":"max_padding"}[slot]]
	return int(item_def(s.gear[slot]).get("durability", 0))

func repair_cost(soldier_id: int) -> int:
	if soldier_id < 0 or soldier_id >= soldiers.size() or not soldiers[soldier_id].alive: return 0
	var missing = 0
	for p in battle_parts(soldiers[soldier_id]): missing += p.maximum-p.condition
	for slot in ["shield"]+Arsenal.CARRIED:
		var id: String = soldiers[soldier_id].gear.get(slot,"")
		if item_def(id).get("slot") == "shield": missing += int(item_def(id).durability)-items[id].condition
	return ceili(float(missing)/12)

func repair(soldier_id: int) -> bool:
	# Compatibility action: repair is automatic, never an instant refill.
	if phase != "camp" or over() or repair_cost(soldier_id) == 0: return false
	note("Repairs happen over time using tools. "+Recovery.status(self,soldier_id))
	return true

func temple(sid: int) -> bool:
	if phase != "camp" or over() or not in_town() or sid < 0 or sid >= soldiers.size() or crowns < 40: return false
	var s: Dictionary = soldiers[sid]
	if not s.alive or s.wound_days <= 0: return false
	var p = Recovery.patient(recovery,sid)
	if p.temple: return false
	crowns -= 40; p.temple = true
	note(s.name+" receives temple care: injury recovery is twice as fast. Medicine is still required; permanent scars remain.")
	return true

func armorer_stock(group: String, layer: String) -> Array:
	var out: Array = []
	if not in_town() or over(): return out
	var week = (day-1)/7
	for definition in catalog:
		var d: Dictionary = catalog[definition]
		if d.get("group") != group or d.get("layer") != layer or not definition in market().get("stock",[]): continue
		var id = "%s_%d_%s" % [location,week,definition]
		if id in purchased_gear: continue
		if economy.enabled and not economy.industry.available(location,definition):continue
		out.append({"id":id,"definition":definition,"price":quoted_price(location,equipment_price(definition))})
	return out

func buy_component(id: String) -> String:
	if phase != "camp" or over() or not in_town(): return ""
	for group in Armor.LAYERS:
		for layer in Armor.LAYERS[group]:
			for offer in armorer_stock(group,layer):
				if offer.id != id: continue
				if crowns < offer.price: return ""
				crowns -= offer.price
				market_receive(offer.price)
				purchased_gear.append(id)
				if economy.enabled:economy.industry.sell_gear(location,offer.definition)
				var item = add_item(offer.definition)
				note("Bought %s for %d crowns. Placed in company stores." % [catalog[offer.definition].name,offer.price])
				return item
	return ""

func rest_cost() -> int:
	return wage_cost()+arrears

func rest_day() -> bool:
	if dungeons.active != "": return dungeon_rest()
	if phase != "camp" or over() or not encounter.is_empty(): return false
	advance_day("rest")
	return true

func supply_cost(kind: String) -> int:
	if economy.enabled: return economy.quote(self,location,kind,false).price
	return quoted_price(location, world.price(location) if kind == "food" else (36 if kind == "tools" else 30))

func buy_supply(kind: String) -> bool:
	if economy.enabled: return economy.trade(self,kind,false)
	if phase != "camp" or over() or not in_town() or not kind in ["tools", "medicine", "food", "ammo"]: return false
	var cost = supply_cost(kind)
	if crowns < cost: return false
	if kind == "food" and not world.buy_food(location): return false
	crowns -= cost
	if kind == "tools": tools += 12
	elif kind == "medicine": medicine += 6
	elif kind == "ammo":
		ammunition += AMMO_PURCHASE_SIZE
		refill_company_ammo()
	else: food += 24
	note("Bought %s for %d crowns." % [kind, cost])
	return true

func prepare_deployment() -> void:
	pass
func configure_player_unit(_person: Dictionary, _unit: Dictionary) -> void:
	pass
func configure_enemy_unit(_unit: Dictionary) -> void:
	pass
func deploy() -> bool:
	if not can_deploy(): return false
	guards.player_intervenes(self)
	traffic.pursuit = ""
	exploration.cancel(self)
	if encounter.get("kind") != "dungeon": update_threat()
	overworld.paused = true
	var job = battle_job()
	recon.prepare(self)
	prepare_deployment()
	var ambushed = not encounter.is_empty() and encounter.kind == "scout" and bandits.enabled and bandits.bands.get(encounter.id,{}).get("mode","") == "hunting"
	battle.setup(dungeons.room().seed if job.get("kind") == "dungeon" else seed_value + encounters*101, battle_site(), "eliminate" if not recon.engagement.is_empty() else job.objective, true, true, true, true, true, roster_version == 1, ambushed)
	deployment = CompanyRoster.active(self)
	if roster_version == 1 and encounter.is_empty(): active.participants = deployment.duplicate()
	while deployment.size() < battle.player_slots(): deployment.append(-1)
	for i in battle.player_slots():
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
		u.ranged_skill = effective_ranged_skill(s)
		u.ranged_defense = s.base_ranged_defense
		u.stamina = s.stamina; u.initiative = s.initiative
		for field in ["endurance","mobility","resolve","temperament"]: u[field] = s[field]
		u.armor_parts = battle_parts(s)
		u.load = armor_stats(s).load
		u.perks = s.perks.duplicate()
		u.scars = s.scars.duplicate()
		u.morale = 75 if "haunted" in s.scars else 85
		u.weapon = item_def(s.gear.weapon).get("weapon", "")
		u.arms = soldier_arms(s)
		if Arsenal.family(u.weapon) == "crossbow": u.arms.weapon.loaded = battle.ammo_count(u) > 0
		battle.sync_arms(u)
		for pair in [["armor", "body"], ["padding", "under"], ["helmet", "head"]]:
			u[pair[0]] = durability(s, pair[1])
			u["max_"+pair[0]] = maximum(s, pair[1])
	for i in deployment.size():
		if deployment[i] < 0: continue
		var s: Dictionary = soldiers[deployment[i]]
		var u: Dictionary = battle.units[i]
		u.strain_penalty = s.strain*2
		u.grief_penalty = Relationships.grief_penalty(s)
		u.morale_state = -1 if "haunted" in s.scars else 0
		u.morale = battle.morale_number(u.morale_state)
		u.comrades = relationships.comrades(s.id,soldiers).filter(func(id): return id in deployment).map(func(id): return deployment.find(id))
	var threat = int(job.threat)
	for i in range(battle.player_slots(),battle.units.size()):
		if encounter.get("kind") == "dungeon": break
		var u: Dictionary = battle.units[i]
		var count = enemy_count(battle_site(),threat,job.get("kind","clear"))
		if raiders.rules_version == 6 and job.kind == "scout" and bandits.enabled: count = bandits.bands[job.id].get("capacity",count)
		if raiders.rules_version == 6 and not recon.engagement.is_empty(): count = recon.engagement.rows.size()
		if i >= battle.player_slots()+count:
			u.hp = 0
			u.name = "Empty rank"
			continue
		u.armor = maxi(20, int(u.armor)+(threat-2)*15)
		u.max_armor = u.armor
		u.skill += (threat-2)*4
		equip_enemy(u,threat)
		u.ranged_skill = u.skill if u.weapon in Arsenal.RANGED else 40+(i*7)%15
	bandits.deploy(self)
	CompanyRoster.deploy(self)
	recon.populate(self)
	if encounter.get("kind") == "dungeon": dungeons.populate(battle)
	for i in deployment.size():
		if deployment[i] >= 0: configure_player_unit(soldiers[deployment[i]],battle.units[i])
	for i in range(battle.player_slots(),battle.units.size()): configure_enemy_unit(battle.units[i])
	battle.set_meta("bandit_spoils_cohort",ResourceSpoils.cohort(self))
	battle.events.clear()
	battle.log_event(job.title + ": " + battle.objective_text())
	battle.start_round()
	phase = "battle"
	if not recon.engagement.is_empty(): battle.check_result()
	retreat = false
	return true

func retreat_from_battle() -> bool:
	if phase != "battle" or not battle.result.is_empty(): return false
	# Confirmation orders a physical retreat, never immediate settlement.
	if not battle.begin_withdrawal(): return false
	retreat = true
	return true

func resolve_battle() -> bool:
	if phase != "battle" or battle.result.is_empty(): return false
	var won = battle.result == "victory"
	var resource_spoils = ResourceSpoils.report()
	# Capture persistent identities before recon.settle clears engagement and
	# completion clears active. Only the started-alive deployment cohort counts.
	var dead_members = ResourceSpoils.dead(battle)
	var food_before_settlement = food
	var claims_before = economy.camp_claims.keys()
	var rows: Array = []
	var newly_fallen = 0
	var new_wounds = 0
	var title: String = battle_job().title
	var reward = 0
	var named_camp_loot: Dictionary = {}
	var effect = "The threat remains."
	var xp_before = {}
	for s in soldiers: xp_before[s.id] = s.xp
	for i in deployment.size():
		if deployment[i] == -1: continue
		var s: Dictionary = soldiers[deployment[i]]
		if not s.alive: continue
		var u: Dictionary = battle.units[i]
		var start_hp = int(s.hp)
		s.hp = int(u.hp)
		s.kills += int(u.kills)
		s.battles += 1
		for p in u.armor_parts:
			if items.has(p.item): items[p.item].condition = p.condition
		for slot in u.arms:
			var item: Dictionary = u.arms.get(slot,{})
			s.gear[slot] = item.get("id","")
			if not item.is_empty() and items.has(item.id):
				items[item.id].condition = item.condition
				if Arsenal.family(item.definition) == "crossbow": items[item.id]["loaded"] = item.loaded
		var status = "Survived"
		if u.hp == 0:
			s.alive = false
			s.fallen_day = day
			newly_fallen += 1
			status = "Fallen"
			for slot in s.gear:
				if not won:
					for id in kit_parts(s.gear.get(slot,"")).values(): items.erase(id)
					items.erase(s.gear.get(slot,""))
				s.gear[slot] = ""
		elif start_hp - int(u.hp) >= 20 or u.hp <= s.base_hp/3:
			s.wound_days = maxi(int(s.wound_days), 3)
			if not recovery_pending: recovery.patients.erase(str(s.id))
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
			if won and battle.objective != "eliminate" and battle.fighting(u) and battle.distance(battle.pos(u),battle.goal()) <= 1: Progression.record(s,"banner_%d" % encounter,day,"deed","Held the marked ground when the company prevailed at "+place+".")
		rows.append({"id":s.id, "name":s.name, "status":status, "hp":s.hp, "kills":int(u.kills), "damage_hp":int(u.get("damage_hp",0)), "damage_armor":int(u.get("damage_armor",0)), "damage_shield":int(u.get("damage_shield",0)), "damage_received":u.get("damage_received")})
	relationships.settle(soldiers,deployment,battle,day,encounters+1,retreat)
	recon.settle(self,won)
	if won:
		var camp_target = recon.battle_target(self)
		if camp_target != "" and not economy.enabled: raiders.salvage_camp(self,camp_target,world.camps[camp_target].generation)
	encounters += 1
	if encounter.get("kind") == "dungeon":
		dungeons.settle(battle,won)
		effect = "Chamber cleared. Its dead and loot remain cleared permanently." if won else "The company withdraws. Enemy casualties and equipment damage remain."
	elif not encounter.is_empty():
		if encounter.kind == "scout":
			var scout: Dictionary = overworld.scouts[encounter.id]
			var sealed: Array = economy.freight.retrieve_band(self,encounter.id)
			if not sealed.is_empty():note("Retrieved sealed freight: "+", ".join(sealed)+".")
			scout.defeated = won
			if not traffic.enabled: scout.position = overworld.places[scout.site]
			scout.path.clear()
		else:
			if won and clear_world_camp(encounter.site,encounter.generation): named_camp_loot = camp_life.reward_for_clear(self,encounter.site,encounter.generation)
		if won:
			reward = encounter.pay; crowns += reward
			effect = "Scouting party defeated. The main camp remains." if encounter.kind == "scout" else "Raider camp destroyed. Its remaining cargo is freed."
			if encounter.kind == "scout" and founding.enabled:
				if founding.committed(encounter.id): effect = "Camp builders defeated. Construction has stopped."
				elif not world.camps[encounter.site].active: effect = "Scouting party defeated. Its former camp is already gone."
		else: effect = "The company fell back. The enemy remains."
		if encounter.kind == "scout" and bandits.enabled:
			var retreat_effect = bandits.settle(self,encounter.id,won)
			raiders.settle_band(self,encounter.id,won)
			if not retreat_effect.is_empty(): effect = retreat_effect
		if encounter.kind == "scout" and farm.enabled:
			var farm_effect = farm.settle(self,encounter.id,won)
			if not farm_effect.is_empty(): effect = farm_effect
		if encounter.kind == "scout" and traffic.enabled:
			var rescued = traffic.settle(self,encounter.id,won)
			if not rescued.is_empty(): effect = rescued
		overworld.pending = ""; overworld.grace = 6.0; overworld.rest_left = 0
		overworld.sync_scouts(world)
	elif won and active.kind == "escort":
		world.caravans[active.shipment].guarded = true
		effect = "%s defended. Continue to %s for delivery and payment." % [world.short_id(active.shipment), node(world.route_data(world.caravans[active.shipment].route).path[2]).name]
		world.log_event(effect)
	else:
		if won:
			if RoadContracts.is_road(active.kind):
				effect = "Contract force defeated. Bounty paid and battlefield salvage recovered. The local camp and food shipments are unchanged."
			elif active.kind in ["clear", "legacy"]:
				var generation = active.generation if camp_life.enabled else world.camps[active.target].generation
				if clear_world_camp(active.target,generation): named_camp_loot = camp_life.reward_for_clear(self,active.target,generation)
				effect = "Band destroyed. Remaining cargo freed. Reoccupation needs another funded band."
			elif active.kind == "recover":
				world.recover_shipment(active.shipment)
				effect = "%s recovered and returning to town. The raider camp remains." % world.short_id(active.shipment)
		reward = finish_job(won)
	for row in rows:
		row["xp"] = soldiers[row.id].xp-xp_before[row.id]
		row["level"] = Progression.level(soldiers[row.id])
	if won and encounter.get("kind") != "dungeon" and dungeons.rules_version >= 3 and battle.seed_value%4 == 0:
		var map_site = discover_dungeon_map(battle.seed_value)
		if map_site != "": effect += " Recovered a burial map: "+node(map_site).name+" is marked."
	var recovered_keys: Array = []
	if won and encounter.get("kind") != "dungeon":
		var found_key = recover_vault_key("battle",battle.seed_value)
		if found_key != "":
			recovered_keys.append(found_key)
			effect += " Recovered "+dungeons.Keys.label(dungeons.sites,found_key)+". Location unknown unless already mapped."
	var camp_key: String = "%s/%d" % [location,world.camps.get(location,{}).get("generation",0)]
	if won and economy.enabled and economy.camp_claims.has(camp_key) and (encounter.get("kind") == "camp" or effect.begins_with("Band destroyed")):
		var spoils: Dictionary = economy.camp_claims[camp_key]
		effect += " Took %d stored rations and %d stolen crowns." % [spoils.food,spoils.crowns]
		if not spoils.get("materials",{}).is_empty():effect+=" Trade cargo: "+economy.freight.describe(spoils.materials)+"."
	var ammo_before_loot = ammunition
	if won and not retreat:
		var cleared = ""
		for key in economy.camp_claims:
			if key not in claims_before and not bandit_stashes.has(key): cleared = key
		resource_spoils = ResourceSpoils.settle(self,dead_members,cleared,food-food_before_settlement)
	var loot = recover_enemy_equipment() if won and battle.weapon_rules else []
	if not named_camp_loot.is_empty(): loot.push_front(named_camp_loot)
	var ammo_looted = ammunition-ammo_before_loot
	var ammo_spent = refill_company_ammo() if not ammo_pending else 0
	aftermath = {"damage_metrics_version":1, "damage_received_version":1, "loot":loot, "title":title, "result":battle.result, "retreat":retreat, "pay":reward, "fallen":newly_fallen, "wounded":new_wounds, "rows":rows, "day":day, "round":battle.round_no, "effect":effect}
	if not recovered_keys.is_empty(): aftermath["vault_keys"] = recovered_keys
	if not ammo_pending:
		aftermath["ammunition"] = {"looted":ammo_looted,"spent":ammo_spent,"reserve":ammunition,"missing":company_ammo_needed()}
	aftermath["resource_spoils"] = resource_spoils
	note("%s: %s; %d fallen, %d wounded." % [title, "withdrawal" if retreat else battle.result, newly_fallen, new_wounds])
	recovery.stored = recovery.stored.filter(func(id): return items.has(id))
	CompanyRoster.prune(self)
	# Apply immediate camp/convoy consequences without moving parties or timers.
	overworld.sync_scouts(world)
	traffic.sync(self)
	farm.sync(self)
	guards.sync(self)
	bandits.sync(self)
	reconcile_contract()
	phase = "aftermath"
	# Combat pauses campaign time. Settle losses/rewards above without running
	# wages, rations, recovery or background world simulation.
	if alive_count() == 0:
		ending = "The company is gone."
		if not active.is_empty(): finish_job(false)
	return true

func return_to_camp() -> bool:
	if phase != "aftermath": return false
	phase = "camp"
	recovery_pending = false
	var leaving_dungeon = encounter.get("kind") == "dungeon" and battle.result != "victory"
	encounter.clear()
	if leaving_dungeon: dungeon_exit_state()
	overworld.paused = true
	if balance_pending: apply_combat_balance()
	adopt_combat_rules()
	adopt_growth_rules()
	adopt_perks()
	if ammo_pending:
		ammo_pending = false
		refill_company_ammo()
	return true

func apply_combat_balance() -> void:
	# Only after old fight settlement: preserve identity, training, ownership,
	# wounds and each item's remaining condition fraction. Never reroll anyone.
	if not balance_pending or phase != "camp": return
	var previous_catalog = catalog
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
	for item in items.values():
		var old_max = int(previous_catalog[item.definition].durability)
		var new_max = int(catalog[item.definition].durability)
		if old_max > 0 and old_max != new_max:
			item.condition = clampi(roundi(float(item.condition)*new_max/old_max),0,new_max)
	for s in soldiers:
		var old_max = max_hp(s)
		var trained = earned_health(s)
		s.base_hp = roundi((s.base_hp-trained)*0.75)+trained
		s.hp = clampi(roundi(float(s.hp)*max_hp(s)/old_max),1 if s.alive else 0,max_hp(s)) if s.alive else 0
	for p in recruit_pools.values(): p.hp = roundi(p.hp*0.75)
	balance_pending = false
	battle.setup(seed_value,"ford","hold",true,true,true,true,true)
	note("Combat rebalance adopted: pooled body armour, new damage and health values. Wounds, training and equipment condition fractions retained.")

func earned_health(s: Dictionary) -> int:
	# Pre-0.14 health stars granted twice their current bonus. The service
	# record preserves each actual award, including mixed old/new training.
	var total = 0
	for i in s.development.size():
		if s.development[i] != "health": continue
		var gain = People.growth(s,"health")
		for entry in s.history:
			if entry.id != "development_%d" % (i+1) or not entry.text.begins_with("Developed Health: +"): continue
			var recorded = entry.text.trim_prefix("Developed Health: +").get_slice(" ",0).to_int()
			if recorded in [4+s.aptitudes.health,4+s.aptitudes.health*2]: gain = recorded
			break
		total += gain
	return total

func note(message: String) -> void:
	journal.append(message)
	if journal.size() > 60: journal.pop_front()

func snapshot() -> Dictionary:
	var saved = {"version":23,"opening_rules":opening_rules,"recovery":recovery.duplicate(true),"recovery_pending":recovery_pending,"ammunition":ammunition,"ammo_pending":ammo_pending,"overworld":overworld.snapshot(),"encounter":encounter.duplicate(true),"perks_pending":perks_pending,"growth_pending":growth_pending,"combat_pending":combat_pending,"balance_pending":balance_pending, "market_books":market_books.duplicate(true),"sales":sales.duplicate(true), "purchased_gear":purchased_gear.duplicate(), "population_kind":population_kind, "recruit_pools":recruit_pools.duplicate(true), "relationships":relationships.snapshot(), "reputation":reputation.duplicate(), "world":world.snapshot(), "encounters":encounters, "location":location, "food":food, "wins":wins, "arrears":arrears, "unpaid_days":unpaid_days, "ending":ending, "active":active.duplicate(true), "used_jobs":used_jobs.duplicate(), "hired":hired.duplicate(), "deployment":deployment.duplicate(), "seed":seed_value, "day":day, "crowns":crowns, "tools":tools, "medicine":medicine, "completed":completed, "phase":phase, "next_item":next_item, "soldiers":soldiers.duplicate(true), "items":items.duplicate(true), "journal":journal.duplicate(), "aftermath":aftermath.duplicate(true), "retreat":retreat, "battle":battle.snapshot() if phase in ["battle", "aftermath"] else null}
	if region.has("generator"):
		saved.version = 24; saved["region"] = region.duplicate(true); saved["exploration"] = exploration.snapshot()
	if progression_version == 1: saved.version = 25; saved["progression_version"] = 1
	if traffic.enabled: saved.version = 26; saved["traffic"] = traffic.snapshot()
	if bandits.enabled: saved["bandits"] = bandits.snapshot()
	if roster_version == 1:
		saved.version = 27; saved["roster_version"] = 1; saved["formation"] = formation.duplicate()
	if not named_rewards.is_empty() or items.values().any(func(item): return item.has("named")) or (phase in ["battle","aftermath"] and battle.has_method("has_named_equipment") and battle.has_named_equipment()):
		saved["campaign_rules"] = saved.version; saved.version = 29
		saved["named_rewards"] = named_rewards.duplicate(true)
	if dungeons.enabled():
		saved["dungeon_base_version"] = saved.version; saved.version = 30
		saved["dungeons"] = dungeons.snapshot()
	if farm.enabled:
		saved["world_base_version"] = saved.version; saved.version = 31; saved["farm"] = farm.snapshot()
		if guards.enabled: saved["guards"] = guards.snapshot()
	if camp_life.enabled: saved["camp_life"] = camp_life.snapshot()
	if recon.enabled: saved["camp_recon"] = recon.snapshot()
	if raiders.enabled: saved["raider_needs"] = raiders.snapshot()
	if founding.enabled: saved["camp_founding"] = founding.snapshot()
	if endless:
		saved["career_base_version"] = saved.version; saved.version = 32
	if economy.enabled:
		saved["economy_base_version"] = saved.version; saved.version = 33; saved["economy"] = economy.snapshot()
	if news.enabled:
		saved["news_base_version"] = saved.version; saved.version = 34; saved["regional_news"] = news.snapshot()
	if rebuilding.enabled:
		saved["recovery_base_version"] = saved.version; saved.version = 35; saved["regional_recovery"] = rebuilding.snapshot()
	# Independent of the full-campaign feature envelope. Missing/other policies
	# are unsupported, never silently reconstructed with this generator.
	saved["generation_policy"] = People.GENERATION_POLICY
	saved["bandit_spoils"] = {"version":1,"camps":bandit_stashes.duplicate(true),"members":bandit_members.duplicate()}
	return saved

func restore(raw: Variant) -> bool:
	# Validate using temporary objects. Never partially mutate a live company.
	if not raw is Dictionary: return false
	var d: Dictionary = battle.normalize_json_numbers(raw)
	if not d.get("generation_policy") is int or d.generation_policy != People.GENERATION_POLICY: return false
	if not ResourceSpoils.valid(d): return false
	var recovery_save = d.has("regional_recovery")
	if recovery_save:
		if d.get("version") not in [33,35] or d.get("recovery_base_version") not in [31,32,33,34] or not d.regional_recovery is Dictionary: return false
		d.version = d.recovery_base_version
	elif d.has("recovery_base_version"): return false
	var news_save = d.get("version") == 34
	if news_save:
		if d.get("news_base_version") != 33 or not d.get("regional_news") is Dictionary: return false
		d.version = 33
	elif d.has("regional_news") or d.has("news_base_version"): return false
	var economy_save = d.get("version") == 33
	if economy_save:
		if d.get("economy_base_version") != 32 or not d.get("economy") is Dictionary: return false
		d.version = 32
	elif d.has("economy") or d.has("economy_base_version"): return false
	var endless_save = d.get("version") == 32
	if endless_save:
		if not d.get("career_base_version") is int or d.career_base_version not in [23,24,25,26,27,29,30,31]: return false
		d.version = d.career_base_version
	elif d.has("career_base_version"): return false
	var rural_save = d.get("version") == 31
	var guard_save = rural_save and d.has("guards")
	if rural_save:
		if not d.get("world_base_version") is int or d.world_base_version not in [23,24,25,26,27,29,30] or not d.get("farm") is Dictionary: return false
		d.version = d.world_base_version
	elif d.get("version") in [26,27] and d.has("farm") and not d.has("opening_rules"):
		rural_save = true; guard_save = d.version == 27
		if guard_save != d.has("guards") or not d.has("traffic") or not d.has("bandits"): return false
		d.version = 25
	elif d.has("farm") or d.has("guards") or d.has("world_base_version"): return false
	var dungeon_save = d.get("version") in [28,30]
	if dungeon_save:
		if not d.get("dungeon_base_version") is int or not d.dungeon_base_version in [23,24,25,26,27,29] or not d.get("dungeons") is Dictionary: return false
		d.version = d.dungeon_base_version
	elif d.has("dungeon_base_version") or d.has("dungeons"): return false
	var named_preview = d.get("version") == 26 and d.has("campaign_rules") and d.has("named_rewards")
	var named_save = d.get("version") == 29 or (d.get("version") == 27 and d.has("campaign_rules") and not d.has("roster_version")) or named_preview
	if named_save:
		if not d.get("campaign_rules") is int or not d.campaign_rules in ([23,24,25] if named_preview else [23,24,25,26,27]) or not d.get("named_rewards") is Dictionary: return false
		d.version = d.campaign_rules
	elif d.has("campaign_rules") or d.has("named_rewards"): return false
	if d.get("version") in range(2,20):
		var previous = preload("res://src/legacy_campaign_v20.gd").new()
		if not previous.restore(d): return false
		d = previous.snapshot(); d.version = 20
	# The isolated map/trade/band previews reused main schemas 23–25.
	# Distinguish their exact capabilities before migration; reject mixed payloads.
	var roster = d.get("version") == 27
	if roster:
		if not d.get("roster_version") is int or d.roster_version != 1 or not d.has("formation"): return false
	elif d.has("roster_version") or d.has("formation"): return false
	var preview_trade = d.get("version") in [24,25] and d.has("traffic")
	var preview_map = d.get("version") == 23 and d.has("region")
	if (preview_map or preview_trade) and (d.has("opening_rules") or d.has("recovery") or d.has("progression_version")): return false
	if preview_trade and (d.has("bandits") != (d.version == 25)): return false
	var live_trade = preview_trade or d.get("version") == 26 or (roster and d.has("traffic"))
	var living_bands = live_trade and d.has("bandits")
	if not live_trade and (d.has("traffic") or d.has("bandits")): return false
	if d.get("version") == 26 and (not d.has("traffic") or not d.has("region")): return false
	if d.get("version") == 25 and not preview_trade and (not d.get("progression_version") is int or d.progression_version != 1 or not d.get("opening_rules",false)): return false
	if d.has("progression_version") and (d.get("version") not in [25,26,27] or not d.progression_version is int or d.progression_version != 1 or not d.get("opening_rules",false)): return false
	var generated_map = d.get("version") in [24,26] or (d.get("version") in [25,27] and d.has("region"))
	if d.get("version") in [20,21,22] or preview_map or preview_trade:
		d["opening_rules"] = false; d["recovery"] = Recovery.fresh(); d["recovery_pending"] = d.get("phase") != "camp"
	if not d.get("opening_rules") is bool or not d.get("recovery_pending") is bool: return false
	if d.recovery_pending and d.get("phase") == "camp": return false
	if d.get("version") in [20,21]:
		d["ammunition"] = STARTING_AMMUNITION
		d["ammo_pending"] = d.get("phase", "") != "camp"
	if not d.get("ammo_pending") is bool or (d.ammo_pending and d.get("phase") == "camp"): return false
	if not d.get("ammunition") is int or d.ammunition < 0: return false
	if not d.get("growth_pending") is bool or not d.get("perks_pending") is bool: return false
	var candidate_region: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/region.json"))
	if generated_map or preview_map:
		if not d.get("region") is Dictionary: return false
		if not (ExpandedRegion.new().validate(d.get("region")) if d.get("region",{}).get("generator") == 3 else MapGenerator.new().validate(d.get("region"))): return false
		candidate_region = d.region.duplicate(true)
	var check_config: Dictionary = candidate_region.get("world_config",world.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))))
	var people_rules = LegacyPeople if d.growth_pending else People
	if not d.get("balance_pending") is bool or not d.get("combat_pending") is bool: return false
	if d.balance_pending and not d.combat_pending: return false
	if (d.growth_pending or d.combat_pending) and not d.perks_pending: return false
	var check_catalog: Dictionary = equipment_catalog_for_validation(d.balance_pending)
	if not Career.valid_recruits(d,people_rules,check_catalog,endless_save,check_config.towns.keys()): return false
	for field in ["version", "seed", "day", "crowns", "tools", "medicine", "completed", "next_item", "food", "wins", "arrears", "unpaid_days", "encounters"]:
		if not d.has(field) or not d[field] is int: return false
	if d.version not in [20,21,22,23,24,25,26,27] or d.encounters < 0 or (not endless_save and d.encounters > 1000) or d.food < 0 or d.wins < 0 or d.wins > d.completed or d.arrears < 0 or d.unpaid_days < 0 or d.unpaid_days > 3 or d.seed < 1 or d.day < 1 or (not endless_save and d.day > LAST_DAY+1) or d.crowns < 0 or d.tools < 0 or d.medicine < 0 or d.completed < 0 or (not endless_save and d.completed > 200) or d.next_item < 1: return false
	if not d.get("reputation") is Dictionary or d.reputation.size() != check_config.factions.size(): return false
	for faction in check_config.factions:
		if not d.reputation.get(faction) is int or d.reputation[faction] < -30 or d.reputation[faction] > 60: return false
	if not d.get("phase", "") in ["camp", "battle", "aftermath"]: return false
	if not d.get("soldiers") is Array or (d.soldiers.size() < (3 if d.opening_rules else 6) or (not endless_save and d.soldiers.size() > 186)) or not d.get("items") is Dictionary: return false
	if not Recovery.valid(d.recovery,d.soldiers,d.items): return false
	if not d.get("journal") is Array or not d.get("aftermath") is Dictionary or not d.get("retreat") is bool: return false
	# The last report also survives Return to Camp; validate its extension in every phase.
	if d.aftermath.has("damage_metrics_version"):
		if not d.aftermath.damage_metrics_version is int or d.aftermath.damage_metrics_version != 1 or not d.aftermath.get("rows") is Array: return false
	if d.aftermath.has("damage_received_version"):
		if not d.aftermath.damage_received_version is int or d.aftermath.damage_received_version != 1 or not d.aftermath.get("rows") is Array: return false
	if d.aftermath.get("rows") is Array:
		for row in d.aftermath.rows:
			if not row is Dictionary: return false
			for field in ["damage_hp","damage_armor","damage_shield"]:
				if not row.has(field) and not d.aftermath.has("damage_metrics_version"): continue
				if not row.get(field) is int or row[field] < 0: return false
			if not row.has("damage_received") and d.aftermath.has("damage_received_version"): return false
			# null/absence means unrecorded. Never substitute HP-only injury totals.
			if row.get("damage_received") != null and (not row.damage_received is int or row.damage_received < 0): return false
	for message in d.journal:
		if not message is String: return false
	for id in d.items:
		var item = d.items[id]
		if not id is String or not item is Dictionary or item.get("id") != id: return false
		if not check_catalog.has(item.get("definition", "")) or not item.get("condition") is int: return false
		if (item.has("named") and (not named_save or d.combat_pending)) or not Named.valid(item,check_catalog): return false
		if item.condition < 0 or item.condition > Named.definition(item,check_catalog).durability: return false
		if item.has("loaded") and (not item.loaded is bool or Arsenal.family(item.definition) != "crossbow"): return false
		if not id.begins_with("item_") or not id.trim_prefix("item_").is_valid_int() or int(id.trim_prefix("item_")) >= d.next_item: return false
	if not valid_named_rewards(d.get("named_rewards",{}),d.items,d.next_item,check_catalog): return false
	var children: Dictionary = {}
	for item in d.items.values():
		var definition: Dictionary = check_catalog[item.definition]
		if item.has("legacy_weight") and not item.legacy_weight is bool: return false
		if definition.get("assembly",false):
			var group: String = definition.slot
			if not item.get("parts") is Dictionary or item.parts.size() != owned_layer_keys(group).size(): return false
			var defs = {}
			for layer in owned_layer_keys(group):
				var id = item.parts.get(layer)
				if not id is String: return false
				defs[layer] = ""
				if id.is_empty(): continue
				if not d.items.has(id) or children.has(id): return false
				var component: Dictionary = check_catalog[d.items[id].definition]
				if component.get("group") != group or component.get("layer") != layer: return false
				children[id] = item.id
				defs[layer] = d.items[id].definition
			if not owned_assembly_conflict(defs,group,check_catalog).is_empty(): return false
		elif item.has("parts"): return false
	if not d.get("purchased_gear") is Array or (not endless_save and d.purchased_gear.size() > 900): return false
	var purchases = {}
	var valid_purchases = valid_purchase_ids(d,check_catalog,check_config)
	for id in d.purchased_gear:
		if not id is String or purchases.has(id) or not valid_purchases.has(id): return false
		purchases[id] = true
	var assigned: Dictionary = {}
	var living_count = 0
	for i in d.soldiers.size():
		var s = d.soldiers[i]
		if not s is Dictionary or s.get("id", -1) != i or not s.get("alive") is bool or not s.get("gear") is Dictionary: return false
		for field in ["name", "title", "background", "trait"]:
			if not s.get(field) is String: return false
		for field in ["id", "base_hp", "base_skill", "base_defense", "hp", "wound_days", "kills", "battles", "fallen_day", "wage"]:
			if not s.get(field) is int or s[field] < 0: return false
		if not people_rules.validate(s) or not PerkProgression.validate(s,d.day): return false
		if d.growth_pending and (s.has("growth_version") or s.development.size() > Progression.level(s)-1): return false
		if s.alive: living_count += 1
		if s.wage < 1 or s.wage > 20: return false
		if s.base_hp <= 12 or s.hp > max_hp(s) or s.wound_days > 3 or s.alive != (s.hp > 0): return false
		if not valid_gear_size(s): return false
		for slot in validation_slots():
			if not s.gear.get(slot,"" if slot in ["carry3","carry4"] else null) is String: return false
			var id: String = s.gear.get(slot,"")
			if id == "":
				continue
			if slot in Arsenal.CARRIED and Arsenal.CARRIED.find(slot) >= capacity_for_items(s,d.items,check_catalog): return false
			if not s.alive or not d.items.has(id) or assigned.has(id) or children.has(id) or not (Arsenal.allowed(slot,d.items[id].definition,check_catalog) if slot in Arsenal.SLOTS else check_catalog[d.items[id].definition].slot == slot): return false
			if slot in ["body","head"] and not check_catalog[d.items[id].definition].get("assembly",false): return false
			assigned[id] = true
		if s.alive and not s.gear.weapon.is_empty() and d.items[s.gear.weapon].definition in Arsenal.TWO_HANDS and s.gear.shield != "": return false
	if living_count > (20 if roster else 6): return false
	if roster and not CompanyRoster.valid(d.formation,d.soldiers): return false
	if not d.get("location") is String: return false
	if not d.get("ending") is String or not d.get("active") is Dictionary: return false
	if d.version == 20: d["encounter"] = {}
	if not d.get("encounter") is Dictionary: return false
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
	candidate_world.configure(candidate_region)
	if not candidate_world.restore(d.get("world")) or candidate_world.day != d.day: return false
	var candidate_dungeons = create_dungeons(check_catalog)
	var spatial_region = candidate_region
	if dungeon_save:
		var geography = Overworld.new(); geography.setup(candidate_region,candidate_world)
		if not candidate_dungeons.restore(d.dungeons,candidate_region,geography,d.get("named_rewards",{}),d.seed): return false
		if candidate_dungeons.rules_version >= 2 and not roster: return false
		spatial_region = candidate_dungeons.spatial_region(candidate_region)
	if place_in(spatial_region,d.location).is_empty(): return false
	var candidate_overworld = Overworld.new()
	if d.version == 20: candidate_overworld.setup(candidate_region,candidate_world,d.location)
	elif not candidate_overworld.restore(d.get("overworld"),spatial_region,candidate_world): return false
	var candidate_exploration = Exploration.new()
	if generated_map or preview_map:
		if not candidate_exploration.restore(d.get("exploration"),candidate_region,candidate_overworld,d.location,d.phase): return false
	else: candidate_exploration.setup(candidate_region)
	var candidate_traffic = Traffic.new()
	if live_trade:
		if not candidate_traffic.restore(d.get("traffic"),candidate_overworld,candidate_world): return false
	var candidate_farm = Farm.new()
	if rural_save:
		if not live_trade or not living_bands: return false
		if not candidate_farm.restore(d.get("farm"),candidate_overworld,candidate_world): return false
	elif not candidate_world.farm_supply.is_empty(): return false
	var candidate_guards = Guards.new()
	if guard_save and not candidate_guards.restore(d.get("guards"),candidate_overworld,candidate_world,candidate_farm,recovery_save): return false
	var candidate_bandits = Bandits.new()
	if living_bands:
		if not candidate_bandits.restore(d.get("bandits"),candidate_overworld,candidate_traffic,d.get("progression_version",0),d.opening_rules,candidate_farm,candidate_guards,d.get("raider_needs",{}) is Dictionary and d.get("raider_needs",{}).get("version") == 6): return false
		if d.encounter.get("kind") == "scout" and d.encounter.get("threat") != candidate_bandits.bands.get(d.encounter.get("id"),{}).get("threat"): return false
	var candidate_rebuilding = RegionalRecovery.new()
	if recovery_save and (not guard_save or not candidate_rebuilding.restore(d.regional_recovery,candidate_world,candidate_farm,candidate_traffic)): return false
	var candidate_camp_life = CampLife.new()
	candidate_camp_life.acquisition = acquisition_policy()
	if d.has("camp_life"):
		if not rural_save or not candidate_farm.regional or not living_bands: return false
		if not candidate_camp_life.restore(d.camp_life,d,candidate_overworld,candidate_world,candidate_bandits,check_catalog,candidate_region): return false
	elif candidate_overworld.renewing_camps or candidate_bandits.rules_version == 3: return false
	if d.aftermath.has("vault_keys"):
		# A settlement receipt is not a second inventory or an award command.
		# Current awards produce at most one literal, held, battle-sourced key.
		var keys = d.aftermath.vault_keys
		if not keys is Array or keys.size() > 1: return false
		if not keys.is_empty():
			if d.aftermath.get("result") != "victory" or not d.aftermath.get("retreat") is bool or d.aftermath.retreat: return false
			if d.phase == "aftermath" and d.encounter.get("kind") == "dungeon": return false
			for id in keys:
				if not id is String or not candidate_dungeons.vault_keys.records.has(id): return false
				var key: Dictionary = candidate_dungeons.vault_keys.records[id]
				if not key.held or key.source != "battle": return false
	var candidate_recon = CampRecon.new()
	var recon_context = {"world":candidate_world,"overworld":candidate_overworld,"camp_life":candidate_camp_life,"bandits":candidate_bandits,"guards":candidate_guards,"dungeons":candidate_dungeons,"progression_version":d.get("progression_version",0),"phase":d.phase,"encounter":d.encounter,"active":d.active}
	if d.has("camp_recon") and not candidate_recon.restore(d.camp_recon,recon_context): return false
	var candidate_raiders = RaiderNeeds.new()
	recon_context["recon"] = candidate_recon
	if d.has("raider_needs"):
		if not candidate_raiders.restore(d.raider_needs,recon_context): return false
	elif not candidate_world.raider_supply.is_empty(): return false
	var candidate_founding = CampFounding.new()
	recon_context["raiders"] = candidate_raiders
	if d.has("camp_founding"):
		if not candidate_founding.restore(d.camp_founding,recon_context): return false
	elif candidate_world.physical_founding: return false
	if d.encounter.get("kind") == "dungeon":
		if not valid_dungeon_context(d,candidate_dungeons,candidate_overworld): return false
	elif not valid_encounter(d.encounter,candidate_overworld,candidate_world,d.phase,economy_save): return false
	if candidate_dungeons.active != "":
		if d.location != candidate_dungeons.active or not candidate_overworld.at_site(d.location) or not candidate_overworld.paused or not candidate_overworld.path.is_empty() or candidate_overworld.rest_left != 0 or not candidate_overworld.pending.is_empty() or not candidate_exploration.task.is_empty() or candidate_traffic.pursuit != "" or d.active.get("kind") == "escort": return false
		if d.encounter.get("kind","") not in ["","dungeon"]: return false
		if d.phase in ["battle","aftermath"] and d.encounter.get("kind") != "dungeon": return false
		if d.encounter.is_empty() and not candidate_dungeons.room().cleared: return false
	if not candidate_overworld.pending.is_empty() and d.encounter.is_empty(): return false
	if not d.active.is_empty():
		for field in ["id", "title", "brief", "origin", "target", "objective", "kind", "shipment", "client"]:
			if not d.active.get(field) is String: return false
		for field in ["pay", "threat", "deadline", "generation"]:
			if not d.active.get(field) is int: return false
		if not d.active.origin in candidate_world.TOWNS or not d.active.target in candidate_world.SITES: return false
		if d.active.client != candidate_world.towns[d.active.origin].owner: return false
		if not d.active.get("participants") is Array or d.active.participants.size() > (12 if roster else 6): return false
		var participants = {}
		for id in d.active.participants:
			if not id is int or id < 0 or id >= d.soldiers.size() or participants.has(id): return false
			participants[id] = true
		if not d.active.objective in ["hold", "eliminate", "defend", "escort"] or d.active.pay < 0 or d.active.threat < 1 or d.active.threat > 3: return false
		if d.active.deadline < d.day or d.active.deadline > (d.day+8 if endless_save else LAST_DAY) or d.active.id in d.used_jobs: return false
		if not d.active.kind in ["clear", "recover", "escort", "legacy"]+RoadContracts.KINDS or d.active.generation < 1: return false
		if RoadContracts.is_road(d.active.kind) and not RoadContracts.valid(d.active,d,candidate_region,roster,endless_save): return false
		if d.active.kind in ["recover", "escort"]:
			if not candidate_world.caravans.has(d.active.shipment): return false
			var convoy: Dictionary = candidate_world.caravans[d.active.shipment]
			if candidate_world.route_data(convoy.route).path[1] != d.active.target: return false
			if d.active.kind == "recover" and convoy.status != "seized":
				var load=d.get("economy",{}).get("freight",{}).get("shipments",{}).get(convoy.id,{})
				if not load is Dictionary or not load.has("seizer") or load.get("phase") not in ["band","secured","company","fencing"]:return false
				if d.active.id!="recover_"+convoy.id or d.active.origin!=load.get("destination") or d.active.generation!=load.get("generation") or d.economy.escrow.get("id")!=d.active.id:return false
			if d.active.kind == "escort" and (convoy.status != "escort" or candidate_world.shipment_at(convoy.id) != d.location): return false
		elif d.active.shipment != "": return false
	for convoy in candidate_world.caravans.values():
		if convoy.status == "escort" and (d.active.is_empty() or d.active.kind != "escort" or d.active.shipment != convoy.id): return false
	if d.phase == "battle" and (not d.ending.is_empty() or (d.encounter.is_empty() and (d.active.is_empty() or d.location != d.active.target or not candidate_overworld.at_site(d.location)))): return false
	if d.phase == "aftermath" and d.encounter.is_empty() and not d.active.is_empty() and (d.active.kind != "escort" or not candidate_world.caravans[d.active.shipment].guarded): return false
	if not endless_save and d.day > LAST_DAY and d.ending.is_empty(): return false
	var deploy_ids = {}
	if d.phase in ["battle", "aftermath"] and d.deployment.size() != (12 if roster else 6): return false
	for id in d.deployment:
		if not id is int or id < -1 or id >= d.soldiers.size(): return false
		if id >= 0:
			if deploy_ids.has(id): return false
			deploy_ids[id] = true
	if d.phase == "camp" and not candidate_recon.engagement.is_empty(): return false
	var candidate = Battle.new()
	candidate.setup(d.seed)
	if d.phase in ["battle", "aftermath"]:
		if not candidate.restore(d.get("battle")): return false
		recon_context["battle"] = candidate
		if candidate_recon.enabled and not candidate_recon.valid_engagement(recon_context): return false
		if candidate.roster_rules != roster: return false
		if roster and d.phase == "battle":
			if d.deployment.filter(func(id): return id>=0) != d.formation.filter(func(id): return id>=0): return false
			for i in d.deployment.size():
				if d.deployment[i]<0 and (candidate.units[i].hp>0 or candidate.units[i].name!="Empty rank"): return false
		if candidate.has_named_equipment() and not named_save: return false
		if candidate.is_crypt() != (d.encounter.get("kind") == "dungeon"): return false
		if d.encounter.get("kind") == "dungeon" and not valid_dungeon_enemies(candidate,candidate_dungeons,d.phase): return false
		if candidate.damage_rules == d.balance_pending or candidate.core_rules == d.combat_pending or (not d.perks_pending and not candidate.perk_rules): return false
		if d.phase == "battle":
			for i in d.deployment.size():
				if d.deployment[i] < 0: continue
				var s: Dictionary = d.soldiers[d.deployment[i]]
				var expected = {}
				var expected_load = 0
				for group in Armor.LAYERS:
					for id in d.items.get(s.gear[group],{}).get("parts",{}).values():
						if id.is_empty(): continue
						expected[id] = d.items[id]
						expected_load += Armor.part_weight(d.items[id],check_catalog)
				if candidate.units[i].armor_parts.size() != expected.size() or candidate.units[i].load != expected_load: return false
				for part in candidate.units[i].armor_parts:
					if not expected.has(part.item) or part.definition != expected[part.item].definition or part.condition > expected[part.item].condition or part.weight != Armor.part_weight(expected[part.item],check_catalog) or part.get("named",{}) != expected[part.item].get("named",{}): return false
				var totals = Armor.totals(candidate.units[i].armor_parts)
				for pool in ["armor","padding","helmet"]:
					if candidate.units[i][pool] != totals[pool] or candidate.units[i]["max_"+pool] != totals["max_"+pool]: return false
				var expected_arms = {}
				for slot in Arsenal.SLOTS:
					if not s.gear.get(slot,"").is_empty(): expected_arms[s.gear[slot]] = d.items[s.gear[slot]]
				var actual_arms = candidate.units[i].arms.values().filter(func(item): return not item.is_empty())
				if actual_arms.size() != expected_arms.size(): return false
				for item in actual_arms:
					if not expected_arms.has(item.id) or expected_arms[item.id].definition != item.definition or item.condition > expected_arms[item.id].condition or item.get("named",{}) != expected_arms[item.id].get("named",{}): return false
				for field in ["endurance","mobility","temperament"]:
					if candidate.units[i][field] != s[field]: return false
				if candidate.individual:
					for field in ["resolve","stamina","initiative"]:
						if candidate.units[i][field] != s[field]: return false
					if candidate.units[i].skill != effective_skill(s) or candidate.units[i].ranged_skill != effective_ranged_skill(s) or candidate.units[i].defense != s.base_defense or candidate.units[i].ranged_defense != s.base_ranged_defense: return false
				elif candidate.units[i].resolve != s.get("legacy_resolve",s.resolve): return false
				if candidate.units[i].perks != s.perks or candidate.units[i].scars != s.scars: return false
				var comrades = candidate_relationships.comrades(s.id,d.soldiers).filter(func(id): return id in d.deployment).map(func(id): return d.deployment.find(id))
				if candidate.units[i].comrades != comrades or candidate.units[i].strain_penalty != s.strain*2 or candidate.units[i].grief_penalty != Relationships.grief_penalty(s): return false
		if d.phase == "battle" and (not candidate.result.is_empty() or (not endless_save and d.day > LAST_DAY)): return false
		if d.phase == "aftermath":
			if not d.ammo_pending:
				if not d.aftermath.get("ammunition") is Dictionary: return false
				for field in ["looted","spent","reserve","missing"]:
					if not d.aftermath.ammunition.get(field) is int or d.aftermath.ammunition[field] < 0: return false
				if d.aftermath.ammunition.reserve != d.ammunition: return false
			if not d.aftermath.get("loot") is Array: return false
			for row in d.aftermath.loot:
				if not row is Dictionary or not row.get("source") is String or not row.get("item") is String or not row.get("name") is String or not d.items.has(row.item): return false
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
	var market_state = d.duplicate()
	market_state["endless"] = endless_save
	if not candidate_overworld.at_site(d.location): market_state.location = "wilderness"
	if not Market.valid(d.get("market_books"),d.get("sales"),market_state,check_catalog,candidate_world.config,acquisition_policy()): return false
	var candidate_economy = create_economy()
	candidate_economy.industry.acquisition = acquisition_policy()
	if economy_save and not candidate_economy.restore(d.economy,d,candidate_world,check_catalog): return false
	if candidate_raiders.rules_version == 6:
		if not economy_save or not candidate_raiders.shares.restore(d.raider_needs.get("shares"),candidate_world,candidate_economy,candidate_camp_life,candidate_traffic): return false
	elif candidate_economy.towns.values().any(func(t):return t.has("haul_paid")): return false
	if not economy_save and (candidate_world.company_food_in > 0 or not candidate_world.raid_wealth.is_empty() or not candidate_world.wagon_stock.is_empty()): return false
	var candidate_news = RegionalNews.new()
	if news_save and not candidate_news.restore(d.regional_news,candidate_world,(d.day-1)*1440+roundi(candidate_overworld.hour*60)): return false
	news = candidate_news
	economy = candidate_economy
	bandit_stashes = d.bandit_spoils.camps.duplicate(true)
	bandit_members = d.bandit_spoils.members.duplicate()
	endless = endless_save
	roster_version = 1 if roster else 0; formation = d.formation if roster else CompanyRoster.empty()
	dungeons = candidate_dungeons
	named_rewards = d.get("named_rewards",{}).duplicate(true)
	progression_version = d.get("progression_version",0)
	opening_rules = d.opening_rules; recovery = d.recovery; recovery_pending = d.recovery_pending
	market_books = d.market_books; sales = d.sales
	purchased_gear = d.purchased_gear
	recruit_pools = d.recruit_pools
	population_kind = d.population_kind
	relationships = candidate_relationships
	region = candidate_region
	exploration = candidate_exploration
	traffic = candidate_traffic
	rebuilding = candidate_rebuilding
	camp_life = candidate_camp_life
	recon = candidate_recon
	raiders = candidate_raiders
	founding = candidate_founding
	bandits = candidate_bandits
	farm = candidate_farm
	guards = candidate_guards
	world = candidate_world
	overworld = candidate_overworld
	encounter = d.encounter
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
	ammunition = d.ammunition
	ammo_pending = d.ammo_pending
	completed = d.completed
	phase = d.phase
	next_item = d.next_item
	soldiers = d.soldiers
	items = d.items
	journal = d.journal
	aftermath = d.aftermath
	retreat = d.retreat
	battle = candidate
	catalog = check_catalog
	balance_pending = d.balance_pending
	combat_pending = d.combat_pending
	growth_pending = d.growth_pending
	perks_pending = d.perks_pending
	if phase == "camp":
		if balance_pending: apply_combat_balance()
		else: battle.setup(seed_value,"ford","hold",true,true,true,true,true)
		adopt_combat_rules()
		adopt_growth_rules()
		adopt_perks()
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
		var migrated_battle = preload("res://src/legacy_battle_v10.gd").new()
		if not migrated_battle.restore(upgraded.battle): return false
		upgraded.battle = migrated_battle.snapshot()
	upgraded.journal.append("Soldier service records begin. Earlier battles and kills grant service XP; no scars or detailed deeds are invented.")
	return restore(upgraded)

func learn_perk(soldier_id: int, perk: String) -> bool:
	if phase != "camp" or over() or soldier_id < 0 or soldier_id >= soldiers.size(): return false
	var s: Dictionary = soldiers[soldier_id]
	var definition = PerkProgression.definition(perk)
	if definition.is_empty() or not s.alive: return false
	if Perks.modern(s):
		if not Perks.learn_reason(s,perk,PerkProgression.earned(s)).is_empty(): return false
	elif not Progression.PERKS.has(perk) or Progression.points(s) < 1 or perk in s.perks: return false
	var before = max_hp(s)
	s.perks.append(perk)
	s.hp += max_hp(s)-before
	Progression.record(s,"training_"+perk,day,"training","Learned %s." % definition.name)
	note("%s learns %s." % [s.name,definition.name])
	return true

func choose_gift(soldier_id: int, attr: String) -> bool:
	if phase != "camp" or over() or soldier_id < 0 or soldier_id >= soldiers.size() or not attr in People.ATTRS: return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or not Perks.has(s,"gifted") or s.gifted_choices.size() >= 3 or attr in s.gifted_choices: return false
	var before = max_hp(s)
	s[People.FIELDS[attr]] += Perks.GIFT[attr]
	s.gifted_choices.append(attr)
	s.hp += max_hp(s)-before
	Progression.record(s,"gifted_"+attr,day,"training","Gifted: +%d %s." % [Perks.GIFT[attr],People.LABELS[attr]])
	return true

func adopt_perks() -> void:
	if phase != "camp" or not perks_pending: return
	for p in recruit_pools.values():
		Perks.initialize(p)
	for s in soldiers:
		if not s.alive or Perks.modern(s): continue
		Perks.initialize(s,[],item_def(s.gear.weapon).get("weapon",""))
		s.perks = []
		Progression.record(s,"personal_tree",day,"training","Personal perk pool saved. Earlier placeholder picks refunded; earned points and stats retained.")
	perks_pending = false
	battle.setup(seed_value,"ford","hold",true,true,true,true,true)
	note("Personal perk pools adopted, including ranged routes; previous placeholder picks refunded. Existing personal trees and growth retained.")

func region_secured() -> bool:
	if raiders.enabled and overworld.scouts.values().any(func(s):return not s.defeated): return false
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
	if active.is_empty() or active.kind == "legacy" or RoadContracts.is_road(active.kind): return
	if active.kind=="recover" and economy.freight.physical(active.shipment):return
	active.threat = maxi(1,world.camps[active.target].strength-(1 if active.kind == "recover" else 0))
	if active.kind == "recover":
		active.brief = "Recover %s in %s for its buyer. The signed payment is reserved; recovered freight resumes its journey." % [world.cargo_text(active.shipment),world.short_id(active.shipment)]

func reconcile_contract() -> void:
	if active.is_empty(): return
	var obsolete = (active.kind == "clear" and (not world.camps[active.target].active or world.camps[active.target].generation != active.generation)) or (active.kind == "recover" and world.caravans[active.shipment].status != "seized" and not economy.freight.open_recovery(active.shipment))
	if obsolete:
		note("%s withdrawn: the target was resolved or its cargo exhausted. No payment or reputation penalty." % active.title)
		used_jobs.append(active.id)
		economy.release(self,false)
		active.clear()
	else: update_threat()

func camp_decision_reason(kind: String, id: int, other: int = -1) -> String:
	if not encounter.is_empty(): return "Resolve contact before making camp."
	if kind != "meal" and not in_town(): return "Find shelter in a town for a full day of support or mediation."
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

func upgrade_armor(data: Dictionary) -> Dictionary:
	var old = preload("res://src/legacy_campaign_v10.gd").new()
	if not old.restore(data): return {}
	var d = old.snapshot()
	var temp = get_script().new()
	temp.items = d.items
	temp.next_item = d.next_item
	temp.soldiers = d.soldiers
	for item in temp.items.values():
		if temp.catalog[item.definition].has("group"): item["legacy_weight"] = true
	for s in temp.soldiers:
		if s.alive:
			var body = Armor.empty_parts("body")
			var head = Armor.empty_parts("head")
			body.base = s.gear.under
			if not s.gear.body.is_empty(): body[temp.item_def(s.gear.body).layer] = s.gear.body
			head.shell = s.gear.head
			s.gear.body = temp.add_assembly("body",body)
			s.gear.head = temp.add_assembly("head",head)
		s.gear.erase("under")
	temp.wrap_spare_armor()
	for p in d.recruit_pools.values():
		p["armor_loadout"] = Armor.offer_loadout(p,false)
		p["legacy_armor"] = true
	d.items = temp.items
	d.next_item = temp.next_item
	d.soldiers = temp.soldiers
	d["purchased_gear"] = []
	d.version = 10
	if d.phase in ["battle","aftermath"]:
		d.battle.version = 7
		for u in d.battle.units:
			u["armor_parts"] = []; u["load"] = 0
			if u.id >= d.deployment.size() or d.deployment[u.id] < 0: continue
			u.armor_parts = temp.battle_parts(d.soldiers[d.deployment[u.id]])
			for pool in ["armor","padding","helmet"]:
				var total = Armor.totals(u.armor_parts)[pool]
				Armor.damage_parts(u,pool,maxi(0,total-u[pool]))
	return d

func soldier_arms(s: Dictionary) -> Dictionary:
	var out = Arsenal.empty_arms()
	for slot in Arsenal.SLOTS:
		if items.has(s.gear.get(slot,"")): out[slot] = Arsenal.combat_item(items[s.gear[slot]])
	return out

func valid_offer_arms(p: Dictionary) -> bool:
	if not p.get("carried_loadout") is Array or p.carried_loadout.size() != 2 or not p.get("ammo_loadout") is String: return false
	for id in p.carried_loadout:
		if not id is String or (not id.is_empty() and not Arsenal.allowed("carry1",id,catalog)): return false
	return p.ammo_loadout in ["","arrows","bolts"]

func weapons_stock() -> Array:
	var out: Array = []
	if not in_town() or over(): return out
	for definition in market().get("stock",[]):
		if not definition in Arsenal.WEAPONS+Arsenal.SHIELDS+["arrows","bolts"]: continue
		var id = "%s_%d_%s" % [location,(day-1)/7,definition]
		if economy.enabled and not economy.industry.available(location,definition):continue
		if not id in purchased_gear: out.append({"id":id,"definition":definition,"price":quoted_price(location,equipment_price(definition))})
	return out

func buy_weapon(id: String) -> String:
	if phase != "camp" or over(): return ""
	for offer in weapons_stock():
		if offer.id != id or crowns < offer.price: continue
		crowns -= offer.price; purchased_gear.append(id)
		if economy.enabled:economy.industry.sell_gear(location,offer.definition)
		market_receive(offer.price)
		var item = add_item(offer.definition)
		note("Bought %s for %d crowns; placed in stores." % [catalog[offer.definition].name,offer.price])
		return item
	return ""

func refill_items(sid: int) -> Array:
	var out: Array = []
	if sid < 0 or sid >= soldiers.size(): return out
	for slot in ["ammo","weapon"]+Arsenal.CARRIED:
		var id: String = soldiers[sid].gear.get(slot,"")
		if not items.has(id): continue
		if item_def(id).slot == "ammo" or Arsenal.family(items[id].definition) == "throwing": out.append(id)
	return out

func ammo_refill_cost(sid: int) -> int:
	# Company ammunition units, never crowns or repair tools.
	var cost = 0
	for id in refill_items(sid):
		cost += (int(item_def(id).durability)-int(items[id].condition))*Arsenal.ammo_supply_cost(items[id].definition)
	return cost

func company_ammo_needed() -> int:
	var cost = 0
	for s in soldiers:
		if s.alive: cost += ammo_refill_cost(s.id)
	return cost

func can_refill_ammo(sid: int) -> bool:
	if phase != "camp" or over() or sid < 0 or sid >= soldiers.size() or not soldiers[sid].alive: return false
	for id in refill_items(sid):
		if items[id].condition < item_def(id).durability and ammunition >= Arsenal.ammo_supply_cost(items[id].definition): return true
	return false

func replenish_ammo(ids: Array) -> int:
	# One round per item per pass shares scarce supplies across the roster.
	# Whole rounds only: a remainder of 1–2 cannot manufacture a throwing weapon.
	var before = ammunition
	var progressed = true
	while progressed:
		progressed = false
		for id in ids:
			var cost = Arsenal.ammo_supply_cost(items[id].definition)
			if cost <= 0 or ammunition < cost or items[id].condition >= item_def(id).durability: continue
			items[id].condition += 1
			ammunition -= cost
			progressed = true
	return before-ammunition

func refill_company_ammo() -> int:
	var ids: Array = []
	for s in soldiers:
		if s.alive: ids.append_array(refill_items(s.id))
	var spent = replenish_ammo(ids)
	if spent > 0: note("Replenished carried ammunition: %d company ammo used; %d in reserve." % [spent,ammunition])
	var missing = company_ammo_needed()
	if missing > 0: note("Ammunition shortfall: %d more company ammo needed to fill carried packs and bundles." % missing)
	return spent

func refill_ammo(sid: int) -> bool:
	if not can_refill_ammo(sid): return false
	var spent = replenish_ammo(refill_items(sid))
	note("Refilled %s's ammunition: %d company ammo used; %d still needed." % [soldiers[sid].name,spent,ammo_refill_cost(sid)])
	return spent > 0

func work_hint() -> String:
	if economy.enabled: return economy.work_hint(self)
	if not in_town(): return "Town boards offer work and replacement recruits. Recover while travelling; keep a wage reserve."
	for job in offers():
		if job.kind == "escort" and world.protected_road(job.target): return "Guarded-road delivery available. Earn while recovering on the road; security can change."
	var loading = day+1000 if endless else LAST_DAY+1
	for route in world.config.routes:
		if route.path[0] == location and world.protected_road(route.path[1]): loading = mini(loading,maxi(day,int(world.next_launch[route.id])))
	if loading < day+1000 and (endless or loading <= LAST_DAY): return "Next guarded-road loading: day %d, food permitting. Recruits refresh weekly." % loading
	return "Check other town boards for work. Road bounties refresh weekly from day 8."

func equipment_price(definition: String) -> int:
	return CampaignBalance.PRICES.get(definition,int(catalog[definition].get("price",0))) if progression_version == 1 else int(catalog[definition].get("price",0))

func enemy_label(site: String, threat: int, kind: String = "clear") -> String:
	if RoadContracts.is_road(kind): return RoadContracts.JOBS[kind].label
	site = world.camp_role(site)
	return CampaignBalance.label(site,threat,kind) if progression_version == 1 else "Thugs" if opening_rules and site == "ford" else "Raiders"

func job_danger(job: Dictionary) -> String:
	if recon.enabled and job.kind in ["clear","legacy"]: return recon.label(self,job.target)
	if RoadContracts.is_road(job.kind): return RoadContracts.JOBS[job.kind].label
	if job.kind == "escort" and world.protected_road(job.target): return "Guarded road · delivery"
	return "%s · %d enemies" % [enemy_label(job.target,job.threat,job.kind),enemy_count(job.target,job.threat,job.kind)]

func enemy_count(site: String, threat: int, kind: String = "clear") -> int:
	if RoadContracts.is_road(kind): return RoadContracts.JOBS[kind].grades.size()
	site = world.camp_role(site)
	if progression_version == 1: return CampaignBalance.count(site,threat,kind)
	if opening_rules and site == "ford": return 2 if kind == "scout" else mini(4,2+threat)
	return mini(6,3+threat)

func equip_enemy(u: Dictionary, threat: int) -> void:
	if progression_version == 1:
		CampaignBalance.equip(self,u,threat); return
	var logical_id = u.id-battle.player_slots()+6
	var n = posmod(seed_value+encounters*17+logical_id*29,2147483646)
	var occupations = {"ford":[["mace","sword"],["spear"],["axe","mace"],["spear","sword"],["crossbow"],["hammer","dagger"]],"forest":[["axe","sword"],["polearm"],["axe"],["spear","mace"],["bow"],["axe","dagger"]],"ridge":[["sword","hammer"],["spear","polearm"],["mace","axe"],["sword","spear"],["crossbow","bow"],["hammer","axe"]]}
	var families: Array = occupations[battle_site()][(logical_id-6)%6]
	var family: String = families[n%families.size()]
	var reserves: int = world.camps[encounter.site if not encounter.is_empty() else location].reserves
	var wealth = clampi(threat+(1 if reserves >= 36 else 0)+(1 if logical_id == 6 else 0),1,3)
	# The authored Mason's Hammer is not an enemy draw; every previous interval stays literal.
	var pool = Arsenal.WEAPONS.filter(func(id): return id != Arsenal.MASON_HAMMER and Arsenal.family(id) == family and battle.weapons[id].tier <= wealth)
	if pool.is_empty():
		# Some families have no tier-one item; use their cheapest available tier.
		var available = Arsenal.WEAPONS.filter(func(id): return id != Arsenal.MASON_HAMMER and Arsenal.family(id) == family)
		var minimum = 99
		for id in available: minimum = mini(minimum,battle.weapons[id].tier)
		pool = available.filter(func(id): return battle.weapons[id].tier == minimum)
	var best_tier = 0
	for id in pool: best_tier = maxi(best_tier,battle.weapons[id].tier)
	pool = pool.filter(func(id): return battle.weapons[id].tier == best_tier)
	var weapon: String = pool[(n/11)%pool.size()]
	var thug = opening_rules and battle_site() == "ford"
	if thug:
		weapon = ["club","hatchet","militia_spear","knife"][n%4]
		u.skill = 43+threat*2+n%7; u.defense = 0; u.ranged_defense = 0
		u.hp = 43+n%10; u.max_hp = u.hp; u.resolve = 30; u.stamina = 95; u.initiative = 95
		wealth = 1
	u.title = {"ford":"Toll raider","forest":"Woodland raider","ridge":"Deserter"}[battle_site()]+(" captain" if logical_id == 6 else "")+" · "+Market.LABELS[wealth]
	if thug: u.title = "Bandit thug"
	var arms = Arsenal.empty_arms()
	var definitions = {"weapon":weapon,"shield":"shield" if not weapon in Arsenal.TWO_HANDS and logical_id != 11 else "","carry1":("dagger" if wealth >= 2 else "knife") if weapon in Arsenal.TWO_HANDS else "","carry2":"","ammo":Arsenal.ammo_type(weapon)}
	if thug: definitions.shield = "buckler" if n%3 == 0 else ""; definitions.carry1 = ""
	if acquisition_policy() != null: definitions = acquisition_policy().arms(definitions)
	for slot in definitions:
		var definition: String = definitions[slot]
		if definition.is_empty(): continue
		arms[slot] = {"id":"enemy_%d_%d_%s" % [encounters,u.id,slot],"definition":definition,"condition":int(catalog[definition].durability),"loaded":Arsenal.family(definition) == "crossbow"}
	u.arms = arms; battle.sync_arms(u)
	var outfit = {"body":Armor.empty_parts("body"),"head":Armor.empty_parts("head")}
	outfit.body.base = "light_quilt" if n%2 == 0 else "linen"
	if logical_id == 6:
		outfit.body.outer = "brigandine" if wealth >= 3 else "leather"
		outfit.body.mail = "short_mail" if wealth >= 3 else ""
		outfit.head.shell = "bascinet" if wealth >= 3 else "nasal"
		outfit.head.padding = "arming_cap"
	elif u.id == 10:
		outfit.body.outer = "leather"; outfit.head.shell = "cap"
	else:
		outfit.body["mail" if n%2 == 0 else "outer"] = "short_mail" if n%2 == 0 else "leather"
		outfit.head.shell = "cap" if n%3 != 0 else "nasal"
		if wealth >= 3: outfit.body.mail = "mail"; outfit.body.outer = "scale_vest"; outfit.head.shell = "nasal"
	if thug:
		outfit = {"body":Armor.empty_parts("body"),"head":Armor.empty_parts("head")}
		outfit.body.base = "tunic" if n%2 == 0 else "light_quilt"
		outfit.body.outer = "jerkin" if n%4 == 0 else ""
		outfit.head.padding = "felt_cap" if n%3 == 0 else ""
	outfit.body.cloth = ["","sash","red_surcoat"][n%3]
	if acquisition_policy() != null: outfit = acquisition_policy().outfit(outfit,0 if thug else wealth,catalog)
	u.armor_parts = []
	for group in outfit:
		for layer in outfit[group]:
			var definition: String = outfit[group][layer]
			if definition.is_empty(): continue
			var d: Dictionary = catalog[definition]
			u.armor_parts.append({"item":"enemy_%d_%d_%s_%s" % [encounters,u.id,group,layer],"definition":definition,"group":group,"layer":layer,"pool":"helmet" if group == "head" else "padding" if layer == "base" else "armor","condition":int(d.durability)*(100 if wealth == 3 else 85+n%16 if wealth == 2 else 65+n%26)/100,"maximum":int(d.durability),"weight":int(d.weight)})
	var stats = Armor.totals(u.armor_parts)
	for key in stats: u[key] = stats[key]

func recover_enemy_equipment() -> Array:
	var loot: Array = []
	for u in battle.units:
		if u.side != 1 or u.hp > 0 or u.name == "Empty rank": continue
		for group in Armor.LAYERS:
			var parts = Armor.empty_parts(group)
			for part in u.armor_parts:
				if part.group != group: continue
				var recovered = recover_item(part,part.condition)
				if recovered_armor_is_loose(): loot.append({"source":u.name,"item":recovered,"name":item_name(recovered)})
				else: parts[part.layer] = recovered
			if parts.values().all(func(id): return id.is_empty()): continue
			var kit = add_assembly(group,parts)
			loot.append({"source":u.name,"item":kit,"name":kit_name(kit)})
		for slot in Arsenal.SLOTS:
			var item: Dictionary = u.arms.get(slot,{})
			if item.is_empty(): continue
			var recovered_rounds = item.condition*Arsenal.ammo_supply_cost(item.definition) if not ammo_pending else 0
			ammunition += recovered_rounds
			var id = recover_item(item,0 if recovered_rounds > 0 else item.condition)
			if Arsenal.family(item.definition) == "crossbow": items[id].loaded = item.loaded
			loot.append({"source":u.name,"item":id,"name":item_name(id)})
	if not loot.is_empty(): note("Recovered %d items / assemblies from fallen enemies. Routed enemies kept their gear." % loot.size())
	return loot

func upgrade_weapons(data: Dictionary) -> Dictionary:
	var previous = preload("res://src/legacy_campaign_v11.gd").new()
	if not previous.restore(data): return {}
	var d = previous.snapshot()
	var temp = get_script().new()
	temp.items = d.items; temp.soldiers = d.soldiers; temp.next_item = d.next_item
	for item in d.items.values():
		if item.definition == "shield": item.condition = 40
	for s in d.soldiers:
		s.gear["carry1"] = ""; s.gear["carry2"] = ""; s.gear["ammo"] = ""
		if s.alive:
			var ammo = Arsenal.ammo_type(temp.item_def(s.gear.weapon).get("weapon",""))
			if not ammo.is_empty(): s.gear.ammo = temp.add_item(ammo)
	for offer in d.recruit_pools.values():
		offer["carried_loadout"] = ["",""]
		offer["ammo_loadout"] = Arsenal.ammo_type(offer.weapon)
	d.items = temp.items; d.next_item = temp.next_item; d.version = 11
	if d.phase in ["battle","aftermath"]:
		d.battle.version = 8; d.battle["weapon_rules"] = false
		for u in d.battle.units:
			temp.battle.initialize_arms(u)
			if u.id < 6 and d.deployment[u.id] >= 0 and d.soldiers[d.deployment[u.id]].alive: u.arms = temp.soldier_arms(d.soldiers[d.deployment[u.id]])
			temp.battle.sync_arms(u)
	if d.phase == "aftermath": d.aftermath["loot"] = []
	return d


func market_key() -> String:
	return "%s_%d" % [location,(day-1)/7]

func ensure_market() -> void:
	rebuilding.observe(self)
	if in_town() and not market_books.has(market_key()): market_books[market_key()] = Market.create(self,location)

func market() -> Dictionary:
	return market_books.get(market_key(),{}) if in_town() else {}

func market_receive(amount: int) -> void:
	var book = market()
	if not book.is_empty():
		book.cash += amount; book.income += amount
		if economy.enabled: economy.receive(location,amount)

func sale_items() -> Array:
	var out: Array = []
	for id in items:
		if owner(id) < 0 and parent_kit(id).is_empty(): out.append(id)
	out.sort()
	return out

func stored_repair_cost(id: String) -> int:
	if not items.has(id): return 0
	var ids = kit_parts(id).values().filter(func(value): return value != "") if item_def(id).get("assembly",false) else [id]
	var missing = 0
	for part in ids:
		if item_def(part).slot != "ammo" and Arsenal.family(items[part].definition) != "throwing": missing += int(item_def(part).durability)-int(items[part].condition)
	return ceili(float(missing)/12)

func repair_stored(id: String) -> bool:
	if phase != "camp" or over() or not id in sale_items() or stored_repair_cost(id) <= 0: return false
	if id in recovery.stored:
		recovery.stored.erase(id); note("Stopped repairing "+item_name(id))
	else:
		recovery.stored.append(id); note("Queued "+item_name(id)+" for repair over time using tools.")
	return true

func item_name(id: String) -> String:
	return kit_name(id) if item_def(id).get("assembly",false) else item_def(id).get("name","Missing item")

func sale_quote(id: String) -> Dictionary:
	var out = {"price":0,"repair":stored_repair_cost(id),"replacement":0,"reason":"Choose an unequipped item.","parts":0}
	if not items.has(id): return out
	var definition: Dictionary = item_def(id)
	var ids = kit_parts(id).values().filter(func(value): return value != "") if definition.get("assembly",false) else [id]
	out.parts = ids.size()
	var value = 0.0
	for part in ids:
		var d = item_def(part); var base = float(Named.value(items[part],equipment_price(items[part].definition))); var fraction = 1.0
		if d.durability > 0:
			fraction = float(items[part].condition)/d.durability
			if d.slot != "ammo" and Arsenal.family(items[part].definition) != "throwing": fraction = 0.15+0.85*fraction
		value += base*fraction
		out.replacement += quoted_price(location,int(base))
	if not in_town() or market().is_empty(): out.reason = "Equipment buyers are in towns."; return out
	var rate = clampi(14+market().tier*4+int(reputation[world.towns[location].owner])/10,16,30)
	# Free disposal applies only to broken, condition-tracked durable roots.
	var broken = not definition.get("assembly",false) and definition.durability > 0 and items[id].condition == 0 and definition.slot != "ammo" and Arsenal.family(items[id].definition) != "throwing"
	out.price = 0 if broken else floori(value*rate/100.0)
	if phase != "camp" or over(): out.reason = "Trading requires an active company in camp."
	elif owner(id) >= 0: out.reason = "Return equipped gear to stores before selling."
	elif not parent_kit(id).is_empty(): out.reason = "Remove this component from its assembly before selling."
	elif out.price < 0 or (out.price == 0 and not broken): out.reason = "The merchant offers nothing for this item."
	elif market().cash < out.price: out.reason = "Merchant cannot afford this item; local trade replenishes funds over time."
	else: out.reason = ""
	return out

func sell_item(id: String, expected_price: int = -1) -> bool:
	var quote = sale_quote(id)
	if not quote.reason.is_empty() or (expected_price >= 0 and quote.price != expected_price): return false
	var name = item_name(id)
	for part in kit_parts(id).values():
		if not part.is_empty(): items.erase(part)
	items.erase(id)
	recovery.stored.erase(id)
	crowns += quote.price; market().cash -= quote.price; market().spent += quote.price
	if economy.enabled: economy.pay(location,quote.price)
	sales.append({"item":id,"market":market_key(),"name":name,"price":quote.price,"day":day})
	note("Sold %s for %d crowns. %d crowns remain in the merchant's purse." % [name,quote.price,market().cash])
	return true

func upgrade_market(data: Dictionary) -> Dictionary:
	var previous = preload("res://src/legacy_campaign_v12.gd").new()
	if not previous.restore(data): return {}
	var d = previous.snapshot()
	d.version = 12; d["market_books"] = {}; d["sales"] = []
	if previous.in_town():
		var key = "%s_%d" % [previous.location,(previous.day-1)/7]
		d.market_books[key] = Market.create(previous,previous.location)
	if d.battle != null: d.battle.version = 9
	return d

func effective_ranged_skill(s: Dictionary) -> int:
	return s.base_ranged_skill-(10 if s.wound_days > 0 else 0)-(4 if "clouded_eye" in s.scars else 0)

func preview_unit(s: Dictionary, stats: Dictionary = {}) -> Dictionary:
	var u = s.duplicate(true)
	u["load"] = armor_stats(s).load if stats.is_empty() else stats.load
	u["arms"] = soldier_arms(s)
	u["weapon"] = u.arms.weapon.get("definition","")
	u["shield"] = not u.arms.shield.is_empty() and u.arms.shield.condition > 0
	u["fatigue"] = 0
	return u

func adopt_combat_rules() -> void:
	if phase != "camp" or not combat_pending: return
	combat_pending = false
	battle.setup(seed_value,"ford","hold",true,true,true,true,true)
	note("Combat baseline adopted: skill versus defence, active Shieldwall, melee surrounding, ranged distance and fatigue. Company and equipment retained.")

func adopt_growth_rules() -> void:
	if phase != "camp" or not growth_pending: return
	for s in soldiers: People.initialize_growth(s,true)
	for p in recruit_pools.values(): People.initialize_growth(p,true)
	growth_pending = false
	note("Talent growth adopted: saved rolls to level 11; three stats per level. Earlier stats and picks retained; finish the two remaining picks for each earlier trained level.")


func battle_site() -> String:
	if encounter.get("kind") == "dungeon": return dungeons.room().get("field","crypt")
	return world.camp_role(encounter.site if not encounter.is_empty() else location)

func battle_job() -> Dictionary:
	return encounter if not encounter.is_empty() else contract()

func begin_travel(target: Vector2, site: String = "") -> bool:
	if roster_version == 1 and active_ids().is_empty(): return false
	if dungeons.active != "": return false
	if phase != "camp" or over() or not encounter.is_empty(): return false
	if not site.is_empty() and (not overworld.places.has(site) or target != overworld.places[site]): return false
	# Escort wagons follow the company off road; stopping at the ambush is mandatory.
	if active.get("kind") == "escort":
		var next = next_escort_stop()
		if next.is_empty(): return false
		if not site.is_empty() and site != next: return false
	if not overworld.order(target,site): return false
	recon.watch.clear()
	# A legal departure commits the convoy to its final leg. A camp that
	# reoccupies behind it cannot strand the wagon at the previous waypoint.
	if active.get("kind") == "escort" and world.caravans[active.shipment].index == 1:
		world.caravans[active.shipment].guarded = true
	traffic.pursuit = ""
	exploration.cancel(self)
	overworld.rest_left = 0
	return true

func begin_rest() -> bool:
	if roster_version == 1 and active_ids().is_empty(): return false
	if dungeons.active != "": return dungeon_rest()
	if phase != "camp" or over() or not encounter.is_empty(): return false
	traffic.pursuit = ""
	exploration.cancel(self)
	recon.watch.clear()
	overworld.path.clear(); overworld.destination = ""; overworld.rest_left = 24.0; overworld.paused = false
	return true

func tick_overworld(seconds: float) -> bool:
	if roster_version == 1 and active_ids().is_empty():
		overworld.paused = true; return false
	if dungeons.active != "": return false
	if phase != "camp" or over() or overworld.paused or not encounter.is_empty() or seconds <= 0 or not is_finite(seconds): return false
	overworld.accumulator += seconds*Overworld.HOURS_PER_SECOND*overworld.speed
	var changed = false
	while overworld.accumulator+0.0000001 >= Overworld.STEP:
		overworld.accumulator = maxf(0.0,overworld.accumulator-Overworld.STEP)
		var resting = overworld.rest_left > 0
		var freight_event = world.event_seq
		bandits.sync(self)
		guards.before_step(self)
		farm.before_step(self)
		traffic.move_wagons(self)
		if world.event_seq > freight_event:
			for event in world.events:
				if event.id > freight_event: note(event.text)
			changed = true
		freight_event = world.event_seq
		var events = overworld.step(world,in_town(),traffic,false,self)
		guards.after_step(self)
		farm.after_step(self)
		if world.event_seq > freight_event:
			for event in world.events:
				if event.id > freight_event: note(event.text)
			changed = true
		if not recovery_pending: Recovery.step(self,1,resting)
		overworld.hour = snappedf(overworld.hour+Overworld.STEP,Overworld.STEP)
		if overworld.hour >= 24.0-0.0000001:
			overworld.hour = maxf(0.0,overworld.hour-24.0)
			advance_day("rest" if resting else "travel",true)
			changed = true
		if resting:
			overworld.rest_left = maxf(0.0,snappedf(overworld.rest_left-Overworld.STEP,Overworld.STEP))
			if overworld.rest_left < 0.000001:
				overworld.rest_left = 0; overworld.paused = true; note("The company breaks camp."); changed = true
		if not events.arrived.is_empty():
			if events.arrived != "wilderness":
				location = events.arrived
				if active.get("kind") == "escort" and world.escort_next(active.shipment) == location:
					world.escort_arrive(active.shipment,location)
					if world.caravans[active.shipment].status == "delivered": finish_job(true)
				ensure_market()
			note("Arrived at %s. Time paused." % node().name); changed = true
		if not events.spotted.is_empty():
			note("Scouts spotted near %s. Time paused; choose a route or resume." % node(overworld.scouts[events.spotted].site).name); changed = true
		if not events.contact.is_empty() and (over() or overworld.scouts[events.contact].defeated): overworld.pending = ""
		if not events.contact.is_empty() and not over() and not overworld.scouts[events.contact].defeated:
			var scout: Dictionary = overworld.scouts[events.contact]
			encounter = make_encounter("scout",scout.site,scout.id)
			note("The company meets a roaming bandit party."); changed = true
		freight_event = world.event_seq
		traffic.sync(self)
		if traffic.resolve_contacts(self): changed = true
		bandits.sync(self)
		if world.event_seq > freight_event:
			for event in world.events:
				if event.id > freight_event: note(event.text)
			changed = true
		if traffic.enabled: reconcile_contract()
		rebuilding.observe(self)
		recon.step(self)
		if exploration.tick(self): changed = true
		if over(): overworld.paused = true
		if overworld.paused:
			# Never bank elapsed wall time across an arrival, sighting or modal pause.
			overworld.accumulator = 0.0
			break
	return changed

func make_encounter(kind: String, site: String, id: String) -> Dictionary:
	var threat = maxi(1,int(world.camps[site].strength)-(1 if kind == "scout" else 0))
	if kind == "scout" and bandits.enabled: threat = bandits.bands[id].threat
	return {"kind":kind,"id":id,"site":site,"generation":overworld.scouts[id].generation if kind == "scout" else world.camps[site].generation,"threat":threat,"title":(("Bandit thugs" if opening_rules and world.camp_role(site) == "ford" else "Raider scouts") if kind == "scout" else "Assault on "+node(site).name),"objective":"eliminate","pay":0 if economy.enabled else 60+20*threat if kind == "scout" else 120+40*threat}

func attack_camp() -> bool:
	if roster_version == 1 and active_ids().is_empty(): return false
	if phase != "camp" or over() or not encounter.is_empty() or not overworld.at_site(location) or not world.camps.has(location) or not world.camps[location].active: return false
	if can_deploy(): return deploy()
	encounter = make_encounter("camp",location,location)
	return deploy()

func valid_encounter(e: Dictionary, spatial, economy, saved_phase: String, world_economy: bool = false) -> bool:
	if e.is_empty(): return true
	if e.get("kind") not in ["scout","camp"] or e.get("site") not in economy.SITES or e.get("objective") != "eliminate": return false
	for f in ["id","title"]:
		if not e.get(f) is String: return false
	for f in ["generation","threat","pay"]:
		if not e.get(f) is int: return false
	if e.generation < 1 or e.generation > economy.camps[e.site].generation or e.threat < 1 or e.threat > 3: return false
	if e.pay != (0 if world_economy else 60+20*e.threat if e.kind == "scout" else 120+40*e.threat): return false
	if e.kind == "scout":
		if not spatial.scouts.has(e.id) or spatial.scouts[e.id].site != e.site or spatial.scouts[e.id].generation != e.generation: return false
		if saved_phase in ["camp","battle"] and spatial.pending != e.id: return false
	else:
		if e.id != e.site or not spatial.at_site(e.site): return false
	if saved_phase == "aftermath" and spatial.pending != "": return false
	return spatial.paused

func camp_label(site: String) -> String:
	if recon.enabled: return recon.label(self,site)
	if progression_version == 1:
		if not world.camps[site].active: return "CLEARED"
		return "%s · %d" % [enemy_label(site,world.camps[site].strength).to_upper(),enemy_count(site,world.camps[site].strength)]
	if not opening_rules or world.camp_role(site) != "ford": return world.road_status(site)
	if not world.camps[site].active: return "CLEARED"
	return "BANDIT THUGS · %d men" % enemy_count(site,world.camps[site].strength)

func contract_direction() -> String:
	if active.is_empty(): return ""
	if active.kind=="recover" and economy.freight.physical(active.shipment):return active.brief
	var delta: Vector2 = overworld.places[active.target]-overworld.position
	var bearing = ("north" if delta.y < -30 else "south" if delta.y > 30 else "")+("east" if delta.x > 30 else "west" if delta.x < -30 else "")
	return "Contract site: "+("nearby" if bearing.is_empty() else bearing)+" of the company."

static func place_in(definition: Dictionary, id: String) -> Dictionary:
	for p in definition.locations:
		if p.id == id: return p
	return {}

func encounter_enemy_count() -> int:
	if encounter.is_empty(): return 0
	if encounter.kind == "dungeon": return dungeons.room().roster.size() if dungeons.room().wear.is_empty() else dungeons.room().wear.filter(func(w):return w.hp > 0).size()
	if recon.enabled and encounter.kind == "camp": return recon.roster(self,encounter.site).filter(func(row):return row.health > 0).size()
	if bandits.enabled and encounter.kind == "scout":
		return bandits.bands[encounter.id].health.filter(func(hp):return hp > 0).size()
	return enemy_count(encounter.site,encounter.threat,encounter.kind)

func company_limit() -> int: return 20 if roster_version == 1 else 6
func active_ids() -> Array: return CompanyRoster.active(self)
func reserve_ids() -> Array: return CompanyRoster.reserves(self)
# Dungeon integration: reserve once when a site is generated, claim only after its
# guardian/chest condition succeeds. These functions do not invent a dungeon UI.
func reserve_named_reward(key: String, definition: String, reward_seed: int, source: String) -> Dictionary:
	if named_rewards.has(key): return named_rewards[key].item.duplicate(true)
	if not Named.valid_text(key,96) or named_rewards.size() >= 1000 or combat_pending: return {}
	if acquisition_policy() != null: definition = acquisition_policy().reward(definition,catalog)
	var rolled = Named.generate(definition,reward_seed,source,catalog)
	if rolled.is_empty(): return {}
	var item = {"definition":definition,"named":rolled,"condition":0}
	item.condition = int(Named.definition(item,catalog).durability)
	named_rewards[key] = {"item":item,"claimed":""}
	return item.duplicate(true)

func claim_named_reward(key: String) -> String:
	if key.begins_with("camp/") or phase != "camp" or over() or not named_rewards.has(key) or named_rewards[key].claimed != "": return ""
	var reward: Dictionary = named_rewards[key].item
	var id = recover_item(reward,reward.condition)
	named_rewards[key].claimed = id
	note("Recovered named equipment: %s. %s" % [item_name(id),reward.named.lore])
	return id

func recover_item(item: Dictionary, condition: int) -> String:
	var id = add_item(item.definition)
	if item.has("named"):
		items[id].erase("instance_roll")
		items[id]["named"] = item.named.duplicate(true)
	items[id].condition = clampi(condition,0,int(item_def(id).durability))
	return id

func valid_named_rewards(rewards: Variant, inventory: Dictionary, next_id: int, definitions: Dictionary) -> bool:
	if not rewards is Dictionary: return false
	var claimed = {}
	for key in rewards:
		if not Named.valid_text(key,96): return false
		var reward = rewards[key]
		if not reward is Dictionary or reward.size() != 2 or not reward.get("item") is Dictionary or not reward.get("claimed") is String: return false
		var item: Dictionary = reward.item
		if item.size() != 3 or not item.has("named") or not Named.valid(item,definitions) or not item.get("condition") is int or item.condition != Named.definition(item,definitions).durability: return false
		var id: String = reward.claimed
		if id.is_empty(): continue
		if not id.begins_with("item_") or not id.trim_prefix("item_").is_valid_int() or int(id.trim_prefix("item_")) < 1 or int(id.trim_prefix("item_")) >= next_id or claimed.has(id): return false
		claimed[id] = true
		if inventory.has(id) and (inventory[id].definition != item.definition or inventory[id].get("named",{}) != item.named): return false
	return true

func enable_dungeons() -> bool:
	if dungeons.enabled() or phase != "camp" or over() or not encounter.is_empty() or combat_pending: return false
	return dungeons.generate(self)

func dungeon_rumour() -> String:
	if not in_town() or phase != "camp" or over() or not encounter.is_empty(): return ""
	if not dungeons.enabled() and not enable_dungeons(): return ""
	if dungeons.rules_version == 2: dungeons.expand(self)
	if dungeons.rules_version == 3: dungeons.enable_keys(self)
	var choices = dungeons.sites.keys().filter(func(id): return not dungeons.sites[id].rumour and not dungeons.sites[id].entered and not dungeons.sites[id].completed and not overworld.discovered(overworld.places[id]))
	if choices.is_empty(): return ""
	choices.sort_custom(func(a,b): return overworld.position.distance_to(overworld.places[a]) < overworld.position.distance_to(overworld.places[b]))
	var id: String = choices[0]; dungeons.discover(id,"rumour")
	note("A traveller speaks of "+node(id).name+". "+node(id).description)
	return id

func discover_dungeon_map(source_seed: int) -> String:
	# The winning battle/chest supplies a stable roll. No new RNG is consumed;
	# settlement and chest state prevent duplicate claims after Save/Load.
	if not dungeons.enabled() or dungeons.rules_version < 3: return ""
	var choices = dungeons.Variety.IDS.filter(func(id):return not dungeons.sites[id].rumour and not dungeons.sites[id].entered and not dungeons.sites[id].completed and not overworld.discovered(overworld.places[id]))
	if choices.is_empty(): return ""
	var id: String = choices[posmod(source_seed,choices.size())]
	dungeons.discover(id,"map")
	note("Recovered a burial map mentioning "+node(id).name+". Find the entrance through exploration.")
	return id

func recover_vault_key(source: String, source_seed: int) -> String:
	if dungeons.rules_version < 4 or dungeons.active != "": return ""
	var id = dungeons.vault_keys.award(source,source_seed)
	if id != "": note("Recovered "+dungeons.Keys.label(dungeons.sites,id)+". The key names its dungeon but gives no directions. Maps and exploration can locate it.")
	return id

func vault_id(target: int) -> String:
	return Dungeons.reward_key(dungeons.active,dungeons.floor_index,target)

func inspect_vault(target: int) -> bool:
	if dungeons.active == "" or phase != "camp" or not encounter.is_empty() or not target in dungeons.links(dungeons.room_index): return false
	var key = vault_id(target)
	if not dungeons.vault_keys.locked(key): return false
	if not dungeons.vault_keys.records[key].noticed:
		dungeons.vault_keys.records[key].noticed = true
		note("Locked treasury recorded: "+dungeons.Keys.label(dungeons.sites,key)+". Its key is somewhere in the world.")
	return true

func unlock_vault(target: int) -> bool:
	if not inspect_vault(target): return false
	var key = vault_id(target); var row: Dictionary = dungeons.vault_keys.records[key]
	if over() or active_ids().is_empty() or not row.held or food < dungeon_scout_cost(): return false
	row.opened = true
	note("Unlocked treasury at "+node(dungeons.active).name+". The door will stay open.")
	return dungeon_move(target)

func dungeon_enter_reason(id: String) -> String:
	if active_ids().is_empty(): return "Assign companions to the formation first."
	if not dungeons.sites.has(id): return "Choose a burial complex."
	if phase != "camp" or over() or not encounter.is_empty() or dungeons.active != "": return "Resolve the current expedition or encounter first."
	if active.get("kind") == "escort": return "Finish or abandon the escort before entering a dungeon."
	if location != id or not overworld.at_site(id): return "Reach the entrance first."
	return ""

func enter_dungeon(id: String) -> bool:
	if dungeon_enter_reason(id) != "": return false
	exploration.cancel(self)
	overworld.path.clear(); overworld.destination = ""; overworld.rest_left = 0; overworld.accumulator = 0.0; overworld.paused = true
	traffic.pursuit = ""
	dungeons.active = id; dungeons.floor_index = 0; dungeons.room_index = 0; dungeons.previous = 0
	dungeons.sites[id].entered = true; dungeons.reveal()
	note("Entered "+node(id).name+". Cleared rooms and enemy losses persist if the company leaves.")
	return true

func dungeon_scout_cost() -> int:
	return ceili(alive_count()/3.0)

func dungeon_move_reason(target: int) -> String:
	if active_ids().is_empty(): return "Assign companions to the formation first."
	if dungeons.active == "" or phase != "camp" or over(): return "No active expedition."
	if not encounter.is_empty(): return "Fight or retreat from the occupied chamber."
	if not target in dungeons.links(dungeons.room_index): return "Choose a connecting doorway."
	var next: Dictionary = dungeons.sites[dungeons.active].floors[dungeons.floor_index].rooms[target]
	if dungeons.vault_keys.locked(vault_id(target)): return "This treasury needs its matching world-found key."
	if not next.visited and food < dungeon_scout_cost(): return "Not enough food to scout another room. You can still leave."
	return ""

func dungeon_move(target: int) -> bool:
	if dungeon_move_reason(target) != "": return false
	var next: Dictionary = dungeons.sites[dungeons.active].floors[dungeons.floor_index].rooms[target]
	var fresh = not next.visited
	if fresh: food -= dungeon_scout_cost()
	dungeons.previous = dungeons.room_index; dungeons.room_index = target; dungeons.reveal()
	dungeon_hours(1.0 if fresh else 0.25,false)
	if not next.cleared:
		encounter = {"kind":"dungeon","id":Dungeons.reward_key(dungeons.active,dungeons.floor_index,target),"site":dungeons.active,"floor":dungeons.floor_index,"room":target,"generation":1,"threat":dungeons.sites[dungeons.active].tier,"title":node().name+" · "+Dungeons.TITLES[next.kind],"objective":"eliminate","pay":0}
	return true

func dungeon_stairs(down: bool) -> bool:
	if dungeons.active == "" or phase != "camp" or over() or not encounter.is_empty(): return false
	var site: Dictionary = dungeons.sites[dungeons.active]; var current = dungeons.room()
	if down:
		if current.kind != "stairs" or not current.cleared or dungeons.floor_index+1 >= site.floors.size(): return false
		dungeons.floor_index += 1; dungeons.room_index = 0
	else:
		if current.kind != "entry" or dungeons.floor_index == 0: return false
		dungeons.floor_index -= 1; dungeons.room_index = site.floors[dungeons.floor_index].exit
	dungeons.previous = dungeons.room_index; dungeons.reveal(); dungeon_hours(0.25,false)
	return true

func dungeon_search() -> bool:
	if dungeons.active == "" or phase != "camp" or over() or not encounter.is_empty(): return false
	var current = dungeons.room()
	if not current.cleared or current.looted or current.loot.is_empty() or not Dungeons.can_search(current): return false
	var item = ""
	var reward_key := Dungeons.reward_key(dungeons.active,dungeons.floor_index,dungeons.room_index)
	var site: Dictionary = dungeons.sites[dungeons.active]
	var is_mail: bool = dungeons.forge_rewards and (current.reward == NamedMail.TOKEN or (reward_key == NamedMail.KEY and NamedMail.registered_site(region,seed_value,dungeons.rules_version,site) and named_rewards.has(reward_key)))
	if is_mail or current.reward != "":
		if is_mail:
			if reward_key != NamedMail.KEY or combat_pending or location != dungeons.active or not overworld.at_site(location) or site.completed != false or not NamedMail.cleared(site,current): return false
			var exact: Dictionary = dungeons.replay_named_mail(region,seed_value)
			var row = named_rewards.get(reward_key)
			if exact.is_empty() or not NamedMail.valid_row(row,catalog) or row.claimed != "" or row.item != exact.item: return false
			item = "item_%03d" % next_item
			if not NamedMail.uid_valid(item,next_item+1) or items.has(item): return false
			# All predicates precede the first write. Only Search allocates this
			# physical leaf; no temporary ordinary roll and no assembled armor.
			var leaf: Dictionary = exact.item.duplicate(true)
			leaf["id"] = item
			items[item] = leaf
			next_item += 1
			row.claimed = item
		else:
			item = claim_named_reward(reward_key)
			if item == "": return false
	current.looted = true
	for key in current.loot:
		match key:
			"crowns": crowns += current.loot[key]
			"food": food += current.loot[key]
			"tools": tools += current.loot[key]
			"ammunition": ammunition += current.loot[key]
	if current.kind == "finale": dungeons.sites[dungeons.active].completed = true
	var map_site = discover_dungeon_map(current.seed) if dungeons.rules_version >= 3 and current.kind != "stairs" and (current.kind == "vault" or current.seed%2 == 0) else ""
	var action = "Recovered stairwell supplies" if current.kind == "stairs" else "Opened "+Dungeons.TITLES[current.kind]
	note("%s: %dc, %d rations, %d tools, %d ammunition%s." % [action,current.loot.crowns,current.loot.food,current.loot.tools,current.loot.ammunition,"; "+item_name(item) if item != "" else ""])
	if map_site != "": note("A burial map in the chest marks "+node(map_site).name+". "+node(map_site).description)
	dungeon_hours(0.25,false)
	return true

func dungeon_rest() -> bool:
	if dungeons.active == "" or phase != "camp" or over() or not encounter.is_empty() or not dungeons.room().cleared: return false
	dungeon_hours(4.0,true)
	note("Rested four hours in a cleared chamber. Daily rations and wages apply at midnight; recovery uses tools and medicine.")
	return true

func dungeon_hours(hours: float, resting: bool) -> void:
	# Discrete expedition actions advance world accounting, without scouts contacting
	# a company underground. Outside travel remains paused; no wall-time is banked.
	recon.watch.clear()
	var ticks = roundi(hours*20)
	for i in ticks:
		if over(): break
		if traffic.enabled:
			bandits.sync(self); guards.before_step(self,true); farm.before_step(self,true); traffic.move_wagons(self,true)
			overworld.step(world,in_town(),traffic,true,self)
			guards.after_step(self,true); farm.after_step(self,true); traffic.resolve_contacts(self,true); bandits.sync(self)
		Recovery.step(self,1,resting)
		overworld.hour = snappedf(overworld.hour+0.05,0.05)
		if overworld.hour >= 24.0:
			overworld.hour -= 24.0; advance_day("dungeon rest" if resting else "dungeon exploration",true)
	if traffic.enabled: traffic.sync(self); reconcile_contract()
	overworld.accumulator = 0.0; overworld.paused = true

func leave_dungeon() -> bool:
	if dungeons.active == "" or phase != "camp": return false
	if not encounter.is_empty() and encounter.get("kind") != "dungeon": return false
	var hours = 0.5+dungeons.floor_index*0.5
	encounter.clear(); dungeon_hours(hours,false); dungeon_exit_state()
	note("Returned to the dungeon entrance. Cleared rooms, opened chests and enemy losses are saved.")
	return true

func dungeon_exit_state() -> void:
	dungeons.active = ""; dungeons.floor_index = 0; dungeons.room_index = 0; dungeons.previous = 0
	overworld.paused = true; overworld.grace = maxf(overworld.grace,2.0)

func valid_dungeon_context(d: Dictionary, state, spatial) -> bool:
	var e: Dictionary = d.encounter
	if state.active == "" or e.size() != 10 or e.get("site") != state.active or e.get("floor") != state.floor_index or e.get("room") != state.room_index: return false
	var current: Dictionary = state.room()
	if e.get("id") != Dungeons.reward_key(state.active,state.floor_index,state.room_index) or e.get("kind") != "dungeon" or e.get("objective") != "eliminate" or e.get("pay") != 0 or e.get("generation") != 1 or e.get("threat") != state.sites[state.active].tier: return false
	if e.get("title") != state.sites[state.active].place.name+" · "+Dungeons.TITLES[current.kind] or current.roster.is_empty() or not current.visited or not spatial.paused: return false
	if d.phase in ["camp","battle"] and current.cleared: return false
	return true

func valid_dungeon_enemies(b, state, saved_phase: String) -> bool:
	var current: Dictionary = state.room()
	if b.seed_value != current.seed or b.objective != "eliminate" or current.wear.size() != current.roster.size(): return false
	if saved_phase == "aftermath" and current.cleared != (b.result == "victory"): return false
	if b.map_id != current.get("field","crypt") or current.roster.size() > b.enemy_slots(): return false
	var originals = dungeon_battle_template(current.seed,b.roster_rules,b.map_id)
	for i in b.enemy_slots():
		var u: Dictionary = b.units[b.player_slots()+i]
		if i >= current.roster.size():
			if u.hp != 0 or u.name != "Empty rank" or u.has("faction"): return false
			continue
		Dungeons.U.equip(originals,originals.units[originals.player_slots()+i],current.roster[i],state.sites[state.active].tier,state.token(state.active,state.floor_index,state.room_index,i))
		var original: Dictionary = originals.units[originals.player_slots()+i]
		for key in ["faction","undead_kind","name","title","max_hp","skill","ranged_skill","defense","ranged_defense","stamina","initiative","resolve","perks"]:
			if u.get(key) != original[key]: return false
		var prior: Dictionary = current.wear[i] if not current.wear.is_empty() else Dungeons.U.wear(original)
		if not Dungeons.U.valid_wear(Dungeons.U.wear(u),prior,b.armor_catalog): return false
		if saved_phase == "aftermath" and Dungeons.U.wear(u) != prior: return false
	return true

func dungeon_battle_template(seed_number: int, expanded: bool = false, field: String = "crypt"):
	var b = Battle.new(); b.setup(seed_number,field,"eliminate",true,true,true,true,true,expanded); return b

func dungeon_choice_reason(choice: String) -> String:
	if dungeons.active == "" or phase != "camp" or over() or not encounter.is_empty() or active_ids().is_empty(): return "Resolve the current encounter first."
	var r = dungeons.room()
	if r.get("resolution","") != "" or not r.cleared: return "This room's obstacle is already resolved."
	var actions = {"trap":["disarm","force"],"rubble":["clear","dig"],"secret":["search"]}
	if not choice in actions.get(r.get("hazard",""),[]): return "That choice is unavailable here."
	var cost = dungeon_choice_cost(choice)
	if tools < cost.tools: return "Need %d tools." % cost.tools
	if food < cost.food: return "Need %d food." % cost.food
	return ""

func dungeon_choice_cost(choice: String) -> Dictionary:
	var tier: int = dungeons.sites[dungeons.active].tier if dungeons.active != "" else 1
	return {"disarm":{"tools":2*tier,"food":0,"hours":1.0},"force":{"tools":0,"food":0,"hours":0.25},"clear":{"tools":4*tier,"food":0,"hours":1.0},"dig":{"tools":0,"food":ceili(alive_count()/2.0),"hours":4.0},"search":{"tools":0,"food":dungeon_scout_cost(),"hours":2.0}}.get(choice,{"tools":0,"food":0,"hours":0.0})

func dungeon_choice(choice: String) -> bool:
	if dungeon_choice_reason(choice) != "": return false
	var r = dungeons.room(); var cost = dungeon_choice_cost(choice)
	tools -= cost.tools; food -= cost.food
	r.resolution = {"disarm":"disarmed","force":"forced","clear":"cleared_tools","dig":"cleared_time","search":"searched"}[choice]
	var message = {"disarm":"The vault trap is disarmed; its chest is safe.","force":"The vault was forced open without injury.","clear":"Tools clear the blocked passage. The shortcut stays open.","dig":"The company digs out the passage. The shortcut stays open.","search":"A concealed supply cache is uncovered."}[choice]
	if choice == "force" and r.risk:
		var s: Dictionary = soldiers[active_ids()[0]]; var harm: int = 8+4*dungeons.sites[dungeons.active].tier; var prior_hp: int = s.hp
		s.hp = maxi(1,s.hp-harm); s.wound_days = maxi(s.wound_days,2); s.hp = mini(s.hp,max_hp(s)); recovery.patients.erase(str(s.id))
		message = "%s triggers the trap: %d HP damage and a two-day injury. The chest is accessible." % [s.name,prior_hp-s.hp]
		Progression.record(s,"dungeon_trap_"+Dungeons.reward_key(dungeons.active,dungeons.floor_index,dungeons.room_index),day,"hardship",message)
	dungeons.reveal(); dungeon_hours(cost.hours,false); note(message)
	return true

func enable_economy() -> bool:
	if economy.enabled or not endless or phase != "camp" or not encounter.is_empty(): return false
	economy.setup(self,false)
	note("Council-funded work and resource trading adopted. Existing signed payment is honoured; future work follows actual camps and shipments.")
	return true

func clear_world_camp(site: String, generation: int) -> bool:
	if not world.camps[site].active or world.camps[site].generation != generation: return false
	if economy.enabled: economy.claim_camp(self,site)
	if raiders.enabled and raiders.rules_version == 6: raiders.shares.claim(self,site)
	return world.clear_camp(site,generation)

func food_quote_at(town: String) -> int:
	return economy.quote(self,town,"food",false).price if economy.enabled else quoted_price(town,world.price(town))

func hear_regional_news() -> int:
	if not economy.enabled or not in_town() or phase != "camp" or over() or not encounter.is_empty(): return -1
	if not news.enabled: news.setup(self)
	return news.hear(self)
