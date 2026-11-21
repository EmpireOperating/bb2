extends RefCounted
const Rarity = preload("res://hollow_campaign/rarity.gd")
## Saved, nonmagical craftsmanship. Effective stats never mutate shared catalogs.
const VERSION = 1
const WEAPON_BOUNDS = {"damage":[8,18],"penetration":[4,10],"armor_damage":[10,25],"fatigue":[1,3],"weight":[10,20]}
const ARMOR_BOUNDS = {"protection":[10,25],"weight":[10,20]}
const OWNERS = ["Aldren","Hadrik","Maren","Oswin","Roderic","Sigrid","Torsten","Wulfric"]
const TITLES = ["the Warden","the Unbowed","the Captain","the Watchkeeper","the Veteran","the Wanderer"]

static func eligible(definition: String, catalog: Dictionary) -> bool:
	var d: Dictionary = catalog.get(definition,{})
	return d.get("slot") == "weapon" or (d.has("group") and int(d.get("durability",0)) > 0 and int(d.get("weight",0)) > 0)

static func generate(definition: String, seed_number: int, source: String, catalog: Dictionary) -> Dictionary:
	if not eligible(definition,catalog) or seed_number < 1 or seed_number > 2147483646 or not valid_text(source,64): return {}
	var rng = RandomNumberGenerator.new(); rng.seed = seed_number
	var weapon = catalog[definition].slot == "weapon"
	var bonuses = {}
	if weapon:
		bonuses.damage = rng.randi_range(8,18)
		var options = ["penetration","armor_damage","fatigue","weight"]
		for i in rng.randi_range(1,2):
			var at = rng.randi_range(0,options.size()-1); var stat: String = options.pop_at(at)
			bonuses[stat] = rng.randi_range(WEAPON_BOUNDS[stat][0],WEAPON_BOUNDS[stat][1])
	else:
		bonuses.protection = rng.randi_range(10,25); bonuses.weight = rng.randi_range(10,20)
	var owner: String = OWNERS[rng.randi_range(0,OWNERS.size()-1)]
	var title: String = TITLES[rng.randi_range(0,TITLES.size()-1)]
	var name = owner+"'s "+catalog[definition].name
	return {"version":VERSION,"seed":seed_number,"source":source,"name":name,"lore":"Made for %s %s. Recovered from %s." % [owner,title,source],"bonuses":bonuses}

static func valid_text(value: Variant, maximum: int) -> bool:
	if not value is String or value.is_empty() or value.length() > maximum: return false
	for i in value.length():
		if value.unicode_at(i) < 32: return false
	return true

static func valid(item: Dictionary, catalog: Dictionary) -> bool:
	if item.has("instance_roll"): return item.get("definition") is String and catalog.has(item.definition) and Rarity.valid_item(item)
	if not item.has("named"): return true
	if not item.get("definition") is String or not eligible(item.definition,catalog) or item.get("legacy_weight",false): return false
	var n = item.named
	if not n is Dictionary or n.size() != 6 or not n.get("version") is int or n.version != VERSION: return false
	if not n.get("seed") is int or n.seed < 1 or n.seed > 2147483646: return false
	if not valid_text(n.get("name"),80) or not valid_text(n.get("source"),64) or not valid_text(n.get("lore"),240): return false
	var b = n.get("bonuses")
	if not b is Dictionary: return false
	var weapon = catalog[item.definition].slot == "weapon"
	var bounds = WEAPON_BOUNDS if weapon else ARMOR_BOUNDS
	if weapon:
		if b.size() not in [2,3] or not b.has("damage"): return false
	elif b.size() != 2 or not b.has("protection") or not b.has("weight"): return false
	for key in b:
		if not bounds.has(key) or not b[key] is int or b[key] < bounds[key][0] or b[key] > bounds[key][1]: return false
	return true

static func bonuses(item: Dictionary) -> Dictionary:
	if item.has("instance_roll"): return {}
	return item.get("named",{}).get("bonuses",{})

static func weight(item: Dictionary, ordinary: int) -> int:
	if item.has("instance_roll"):return Rarity.utility_weight(item,ordinary)
	var reduction = int(bonuses(item).get("weight",0))
	return maxi(0,ordinary-maxi(1,floori(ordinary*reduction/100.0))) if reduction > 0 else ordinary

static func definition(item: Dictionary, catalog: Dictionary) -> Dictionary:
	var d: Dictionary = catalog.get(item.get("definition",""),{})
	if item.has("instance_roll"): return Rarity.effective_definition(item,d)
	if not item.has("named"): return d
	d = d.duplicate(true)
	d.name = item.named.name
	d.durability = int(d.durability)+ceili(int(d.durability)*int(bonuses(item).get("protection",0))/100.0)
	if d.has("weight"): d.weight = weight(item,int(d.weight))
	return d

static func weapon(item: Dictionary, ordinary: Dictionary) -> Dictionary:
	if item.has("instance_roll"): return Rarity.effective_weapon(item,ordinary)
	if not item.has("named"): return ordinary
	var w = ordinary.duplicate(true); var b = bonuses(item)
	w.name = item.named.name
	w.min = int(w.min)+ceili(w.min*int(b.get("damage",0))/100.0)
	w.max = int(w.max)+ceili(w.max*int(b.get("damage",0))/100.0)
	w.pierce = minf(0.95,float(w.pierce)+int(b.get("penetration",0))/100.0)
	w.armor = float(w.armor)*(1.0+int(b.get("armor_damage",0))/100.0)
	w.fatigue = maxi(1,int(w.fatigue)-int(b.get("fatigue",0)))
	if w.has("special_fatigue"): w.special_fatigue = maxi(1,int(w.special_fatigue)-int(b.get("fatigue",0)))
	return w

static func value(item: Dictionary, ordinary: int) -> int:
	return ordinary*4 if item.has("named") else ordinary

static func summary(item: Dictionary) -> String:
	if item.has("instance_roll"): return Rarity.summary(item)
	var text: Array = []
	for key in bonuses(item):
		var amount = int(bonuses(item)[key])
		match key:
			"damage": text.append("+%d%% damage" % amount)
			"penetration": text.append("+%d pp penetration" % amount)
			"armor_damage": text.append("+%d%% armour damage" % amount)
			"fatigue": text.append("-%d action fatigue" % amount)
			"weight": text.append("-%d%% load (at least 1)" % amount)
			"protection": text.append("+%d%% component protection" % amount)
	return " · ".join(text)
