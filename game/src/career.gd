extends RefCounted
## Continuing campaign recruits use a separate, reproducible weekly seed.
## Current offers are persisted authority, never replaced during inspection/load.
## A new generation policy must be explicit; unsupported saves are refused.
const People = preload("res://src/people.gd")
const Armor = preload("res://src/armor.gd")
const Arsenal = preload("res://src/arsenal.gd")
const Perks = preload("res://src/perks.gd")
const TOWNS = ["ashwick","stonecross","dunmere"]

static func ensure_recruits(c) -> void:
	if not c.endless: return
	for week in range(5,(c.day-1)/7+1):
		for town_index in c.world.TOWNS.size():
			var town: String = c.world.TOWNS[town_index]
			if c.recruit_pools.has("%s_recruit_%d_0" % [town,week]) and c.recruit_pools.has("%s_recruit_%d_1" % [town,week]): continue
			var generator = People.new()
			generator.state = 1+posmod(c.seed_value+week*104729+(town_index+1)*15485863,2147483646)
			for index in 2:
				var name: String = People.NAMES[generator.roll(0,People.NAMES.size()-1)]
				var p = generator.generate(name,false)
				p["id"] = "%s_recruit_%d_%d" % [town,week,index]
				if c.recruit_pools.has(p.id): continue
				People.modest_gear(p)
				p["armor_loadout"] = Armor.offer_loadout(p,true)
				p["legacy_armor"] = false
				c.prepare_new_recruit(p,week)
				c.recruit_pools[p.id] = p

static func valid_recruits(d: Dictionary, people_rules, catalog: Dictionary, endless: bool, towns: Array = TOWNS) -> bool:
	if not d.get("generation_policy") is int or d.generation_policy != People.GENERATION_POLICY: return false
	if not d.get("day") is int or d.day < 1: return false
	if d.get("population_kind") not in ["generated","legacy"] or not d.get("recruit_pools") is Dictionary: return false
	var weeks = maxi(5,(d.day-1)/7+1) if endless else 5
	if d.recruit_pools.size() != towns.size()*weeks*2: return false
	var names = {}
	for town in towns:
		for week in weeks:
			for index in 2:
				var id = "%s_recruit_%d_%d" % [town,week,index]
				var p = d.recruit_pools.get(id)
				var rules = People if week >= 5 else people_rules
				if not rules.validate_offer(p) or not Perks.valid(p) or p.id != id or not Armor.valid_loadout(p.get("armor_loadout"),catalog) or not p.get("legacy_armor") is bool: return false
				if not p.get("carried_loadout") is Array or p.carried_loadout.size() != 2: return false
				for definition in p.carried_loadout:
					if not definition is String or (definition != "" and not Arsenal.allowed("carry1",definition,catalog)): return false
				if not p.get("ammo_loadout") is String or p.ammo_loadout not in ["","arrows","bolts"]: return false
				if week < 5 and d.population_kind == "generated":
					if names.has(p.person): return false
					names[p.person] = true
	return true
