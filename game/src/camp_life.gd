extends RefCounted
## One resourced recruitment process per camp occupation. No campaign RNG is consumed.
const VERSION = 1
const Forge = preload("res://layer_forge/rules.gd")
const FORAGE = 6
const STORE_LIMIT = 60
const RECRUIT_FOOD = 8
const TRAIN_DAYS = 2
const CARE_FOOD = 1
const CHANCES = [15,25,35]
const POOLS = [["sword","spear","mace","bow","mail","nasal"],["arming_sword","greatsword","greataxe","warbow","heavy_crossbow","heavy_mail","brigandine","bascinet"]]
var acquisition = null
var enabled = false
var records: Dictionary = {}

static func key(site: String, generation: int) -> String:
	return "camp/%s/%d" % [site,generation]

static func roll(map_seed: int, site: String, generation: int, strength: int, catalog: Dictionary, acquisition = null, policy_version: int = 3, forge: bool = false) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = map_seed ^ 0xC01471 ^ (((["ford","forest","ridge"].find(site)+1) if site in ["ford","forest","ridge"] else int(site.hash()&0x7fffffff))*0x1F123B) ^ (generation*0x4451)
	var chance: int = CHANCES[clampi(strength,1,3)-1]; var draw = rng.randi_range(0,99)
	var reward_seed = rng.randi_range(1,2147483646)
	var source: Array = POOLS[0 if strength == 1 else 1]
	var projected: bool = policy_version in [2,3] and acquisition != null and acquisition.has_method("reward_pool")
	var pool: Array = acquisition.reward_pool(source,catalog) if projected else source.filter(func(id):return catalog.has(id) and preload("res://src/named_equipment.gd").eligible(id,catalog))
	var definition: String = pool[rng.randi_range(0,pool.size()-1)] if draw < chance else ""
	if acquisition != null:
		definition = acquisition.reward(definition,catalog)
		if policy_version < 3 and acquisition.has_method("previous_design"): definition = acquisition.previous_design(definition)
	# Keep the exact source draw. Forge has no Named wearable collection yet;
	# reserve the same Named arms, but do not reroll a legacy armor result.
	if forge and catalog.get(definition,{}).get("slot") != "weapon": definition = ""
	var out := {"chance":chance,"draw":draw,"seed":reward_seed,"definition":definition}
	if projected: out["policy"] = policy_version
	return out

func setup(c, active: bool) -> void:
	enabled = active; records.clear()
	if not enabled: return
	c.overworld.renewing_camps = true; c.bandits.rules_version = 3
	c.bandits.sync(c)

func sync(c) -> void:
	if not enabled: return
	for site in c.world.SITES:
		var camp: Dictionary = c.world.camps[site]; var k = key(site,camp.generation)
		if not records.has(k):
			var strength: int = c.world.config.camps[site].strength if camp.generation == 1 else 1
			var reward = roll(c.region.get("seed",c.seed_value),site,camp.generation,strength,c.catalog,acquisition,3,Forge.enabled())
			records[k] = {"site":site,"generation":camp.generation,"started":c.day,"last_day":c.day,"party":c.overworld.party_id(site,camp.generation),"next_party":2,"foraged":0,"trained":0,"assigned":0,"reserve":0,"recruit_spent":0,"care_spent":0,"training":{},"closed":not camp.active,"reward":reward,"resolved":false}
			if not reward.definition.is_empty(): c.reserve_named_reward(k,reward.definition,reward.seed,c.node(site).name)
	# A relocated wounded party may need the new occupation's resident count during paid care.
	c.recon.sync(c)
	for k in records:
		var r: Dictionary = records[k]; var camp: Dictionary = c.world.camps[r.site]
		r.closed = not camp.active or camp.generation != r.generation
		if r.closed: continue
		var b: Dictionary = c.bandits.bands[r.party]; var s: Dictionary = c.overworld.scouts[r.party]
		if s.defeated or c.overworld.pending == s.id or c.guards.engaged(s.id) or s.position.distance_to(c.overworld.places[r.site]) > 10: continue
		var wounded: int = b.health.filter(func(hp):return hp > 0 and hp < 1000).size()
		if wounded > 0 and b.care_day != c.day and c.raiders.can_invest(c,r.site,wounded*CARE_FOOD) and c.world.spend_food(r.site,wounded*CARE_FOOD):
			b.care_day = c.day; r.care_spent += wounded*CARE_FOOD

func daily(c) -> void:
	if not enabled: return
	c.bandits.sync(c)
	# Feed field members before recruits transfer from resident upkeep into their party.
	c.raiders.feed_bands(c)
	for site in c.world.SITES:
		var r: Dictionary = records[key(site,c.world.camps[site].generation)]
		if r.closed or r.last_day == c.day: continue
		r.last_day = c.day
		# Camp residents gather locally; these supplies are produced, never stolen from a town ledger.
		var gathered = mini(c.raiders.forage(c,site) if c.raiders.enabled else FORAGE,maxi(0,STORE_LIMIT-c.world.camp_food(site)))
		if c.guards.cover(c,c.overworld.places[site],200): gathered = 0
		if gathered > 0:
			c.world.camps[site].reserves += gathered; c.world.produced += gathered; r.foraged += gathered
		c.raiders.feed_camp(c,site)
		var paid: bool = c.raiders.enabled and c.raiders.rules_version == 6
		if paid: c.raiders.shares.payday(c,r)
		if not r.training.is_empty() and c.day >= r.training.due:
			r.reserve += r.training.count; r.trained += r.training.count
			c.world.log_event("%s finishes training %d recruits." % [c.node(site).name,r.training.count])
			r.training.clear()
		var s: Dictionary = c.overworld.scouts[r.party]; var b: Dictionary = c.bandits.bands[r.party]
		var capacity: int = c.enemy_count(site,clampi(int(c.world.camps[site].strength)-1,1,3),"scout") if s.defeated else b.capacity
		var at_home: bool = not s.defeated and s.position.distance_to(c.overworld.places[site]) <= 10 and c.overworld.pending != s.id and not c.guards.engaged(s.id)
		var missing: int = capacity if s.defeated else b.health.slice(0,b.capacity).filter(func(hp):return hp == 0).size()
		if s.defeated and r.reserve >= capacity:
			var id: String = c.overworld.party_id(site,r.generation,r.next_party)
			c.overworld.spawn_scout(site,r.generation,r.next_party,c.overworld.places[site]); r.next_party += 1; r.party = id
			r.reserve -= capacity; r.assigned += capacity
			c.bandits.sync(c)
			c.world.log_event("A newly recruited party leaves %s. Its earlier losses remain dead." % c.node(site).name)
		elif at_home and missing > 0 and r.reserve > 0:
			for i in b.capacity:
				if b.health[i] != 0 or r.reserve == 0: continue
				b.members[i] = "%s/m%d" % [b.get("lineage",s.id),b.next_member]; b.next_member += 1; b.health[i] = 1000
				r.reserve -= 1; r.assigned += 1; missing -= 1
			c.world.log_event("New recruits join the surviving party at %s. Fallen members remain in its record." % c.node(site).name)
		if paid and at_home and not c.traffic.missions.has(s.id) and not c.farm.engaged(s.id) and c.raiders.shares.can_expand(c,r,b):
			if r.reserve > 0 and c.raiders.shares.account(c,site).misses == 0:
				c.raiders.shares.enlist(c,r,b)
			else: missing = maxi(missing,1)
		if c.founding.enabled:
			c.founding.launch(c,site)
			missing = maxi(missing,c.founding.recruiting(c,site))
		if (s.defeated or at_home or c.founding.enabled) and r.training.is_empty() and missing > r.reserve:
			# A just-dispatched replacement needs no second recruitment order.
			if r.party != s.id: continue
			var count: int = missing-r.reserve
			if paid and not c.raiders.shares.can_hire(c,site,count): continue
			if c.raiders.can_invest(c,site,count*RECRUIT_FOOD) and c.world.spend_food(site,count*RECRUIT_FOOD):
				if paid: c.raiders.shares.commission(c,site,count)
				r.training = {"count":count,"due":c.day+TRAIN_DAYS}; r.recruit_spent += count*RECRUIT_FOOD
				c.world.log_event("%s spends %d food to train %d raiders over two days." % [c.node(site).name,count*RECRUIT_FOOD,count])

func order_for(c, s: Dictionary) -> Dictionary:
	if not enabled: return {}
	var r: Dictionary = records[key(s.site,s.generation)]
	if r.closed or r.training.is_empty() or c.overworld.scouts[r.party].defeated: return {}
	var b: Dictionary = c.bandits.bands[s.id]
	if b.health.slice(0,b.capacity).all(func(hp):return hp > 0): return {}
	c.bandits.change_mode(b,s,"recovering" if s.position.distance_to(c.overworld.places[s.site]) <= 10 else "returning")
	return {"position":c.overworld.places[s.site],"pace":17.0}

func reward_for_clear(c, site: String, generation: int) -> Dictionary:
	if not enabled or c.phase != "battle" or c.battle.result != "victory": return {}
	var k = key(site,generation)
	if not records.has(k) or c.world.camps[site].active or c.world.camps[site].generation != generation: return {}
	var job: Dictionary = c.battle_job()
	if job.get("kind") not in ["camp","clear","legacy"] or job.get("site",job.get("target")) != site: return {}
	var r: Dictionary = records[k]
	if r.resolved: return {}
	r.resolved = true
	if r.reward.definition.is_empty(): return {}
	var reward: Dictionary = c.named_rewards[k]
	if reward.claimed != "": return {}
	var id: String = c.recover_item(reward.item,reward.item.condition); reward.claimed = id
	c.note("Recovered named equipment from %s: %s." % [c.node(site).name,c.item_name(id)])
	return {"source":c.node(site).name,"item":id,"name":c.item_name(id)}

func description(c, site: String) -> String:
	var r: Dictionary = records[key(site,c.world.camps[site].generation)]
	if r.closed: return "Destroyed. No recruitment or foraging. Reoccupation needs another funded band, no earlier than day %d." % (c.world.camps[site].cleared_day+int(c.world.config.politics.get("reoccupy_delay",0)))
	if c.overworld.position.distance_to(c.overworld.places[site]) > c.overworld.sight(): return "The camp can gather supplies and rebuild its raiding parties while it stands. Its current activity is out of sight."
	if not r.training.is_empty(): return "%d food stored. Training %d raiders; due day %d. Named equipment may be found after victory." % [c.world.camp_food(site),r.training.count,r.training.due]
	return "%d food stored. %s Named equipment may be found after victory." % [c.world.camp_food(site),"Rebuilding after field losses." if c.overworld.scouts[r.party].defeated else "A roaming party serves this camp."]

static func current_saved_party(ow, site: String, generation: int) -> String:
	var found = ow.party_id(site,generation); var serial = 1
	for s in ow.scouts.values():
		if s.site == site and s.generation == generation and not s.get("expedition",false) and s.get("sortie",1) > serial: found = s.id; serial = s.sortie
	return found

func snapshot() -> Dictionary:
	return {"version":VERSION,"records":records.duplicate(true)}

func restore(raw: Variant, cdata: Dictionary, ow, w, bands, catalog: Dictionary, region: Dictionary) -> bool:
	if not raw is Dictionary or raw.get("version") != VERSION or not raw.get("records") is Dictionary: return false
	if not ow.renewing_camps or bands.rules_version != 3: return false
	var expected = 0; var forage_total = 0
	for site in w.SITES:
		if w.camps[site].generation > w.day+1: return false
		expected += w.camps[site].generation
		var site_spent = 0
		for generation in range(1,w.camps[site].generation+1):
			var k = key(site,generation); var r = raw.records.get(k)
			if not r is Dictionary or r.get("site") != site or r.get("generation") != generation or not r.get("training") is Dictionary or not r.get("closed") is bool or not r.get("resolved") is bool: return false
			for field in ["started","last_day","next_party","foraged","trained","assigned","reserve","recruit_spent","care_spent"]:
				if not r.get(field) is int or r[field] < 0: return false
			if r.started < 1 or r.last_day < r.started or r.last_day > w.day or r.next_party < 2 or r.next_party > (2*w.day+2 if w.physical_founding else w.day+2) or r.reserve > 6: return false
			if r.closed != (generation != w.camps[site].generation or not w.camps[site].active): return false
			if not r.get("party") is String or r.party != current_saved_party(ow,site,generation) or not ow.scouts.has(r.party): return false
			var assigned = 0
			for sortie in range(1,r.next_party):
				var id: String = ow.party_id(site,generation,sortie)
				if not ow.scouts.has(id) or not bands.bands.has(id): return false
				if id != r.party and not ow.scouts[id].get("expedition",false) and not ow.scouts[id].defeated: return false
				var b: Dictionary = bands.bands[id]
				if b.care_day > w.day: return false
				var base: int = b.get("base_capacity",b.capacity)
				assigned += b.next_member-base-1-b.get("inherited",0)+(base if sortie > 1 else 0)
			var deserted = r.get("deserted",0); var cancelled = r.get("cancelled",0)
			if not deserted is int or not cancelled is int or deserted < 0 or cancelled < 0: return false
			if not w.raider_supply.is_empty():
				if not r.has("deserted") or not r.has("cancelled"): return false
			elif r.has("deserted") or r.has("cancelled"): return false
			if assigned != r.assigned or r.trained != r.assigned+r.reserve+deserted or r.foraged > FORAGE*(r.last_day-r.started): return false
			var pending = 0
			if not r.training.is_empty():
				if r.training.size() != 2 or not r.training.get("count") is int or not r.training.get("due") is int: return false
				if r.training.count < 1 or r.training.count > 6 or r.training.due > r.last_day+TRAIN_DAYS or (not r.closed and r.training.due <= r.last_day): return false
				pending = r.training.count
			if r.recruit_spent != (r.trained+pending+cancelled)*RECRUIT_FOOD: return false
			site_spent += r.recruit_spent+r.care_spent; forage_total += r.foraged
			# Absent marker is the exact predecessor algorithm, never a reroll.
			# New occupations opt in explicitly; unknown markers fail closed.
			if not r.get("reward") is Dictionary: return false
			var policy_version = r.reward.get("policy",1)
			if not policy_version is int or policy_version not in [1,2,3]: return false
			var reward = roll(region.get("seed",cdata.seed),site,generation,w.config.camps[site].strength if generation == 1 else 1,catalog,acquisition,policy_version,Forge.enabled())
			if r.get("reward") != reward:
				if Forge.enabled() or policy_version != 1 or acquisition == null or not acquisition.has_method("reward_before_crossbows"): return false
				var retained: Dictionary = reward.duplicate(true)
				retained.definition = acquisition.reward_before_crossbows(reward.definition,catalog)
				if r.get("reward") != retained: return false
				reward = retained
			if r.resolved and not r.closed: return false
			var stored = cdata.get("named_rewards",{}).get(k)
			if reward.definition.is_empty():
				if stored != null: return false
			else:
				if not stored is Dictionary or stored.item.definition != reward.definition: return false
				var source: String = w.config.camps[site].get("name",site.capitalize())
				if stored.item.named != preload("res://src/named_equipment.gd").generate(reward.definition,reward.seed,source,catalog): return false
				if (stored.claimed != "") != r.resolved: return false
		if site_spent > w.camps[site].spent: return false
	if expected != raw.records.size() or forage_total > w.produced: return false
	for s in ow.scouts.values():
		var r: Dictionary = raw.records[key(s.site,s.generation)]
		if s.get("sortie",1) >= r.next_party: return false
	enabled = true; records = raw.records.duplicate(true)
	return true
