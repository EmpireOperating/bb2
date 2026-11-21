extends RefCounted
## Fearless enemies retain normal fatigue. Legacy rooms keep their captured kits.
const A = preload("res://src/arsenal.gd")
const Armor = preload("res://src/armor.gd")
const TYPES = {
	"barrow_lord":{"name":"Lord of Blackbarrow","hp":95,"skill":67,"defense":14,"initiative":65,"weapon":"mace","shield":"shield","body":"heavy_mail","head":"nasal","condition":90},
	"watch_captain":{"name":"The Watch Captain","hp":85,"skill":73,"defense":12,"initiative":80,"weapon":"heavy_crossbow","shield":"","body":"brigandine","head":"nasal","condition":90,"backup":"sword"},
	"buried_king":{"name":"The Buried King","hp":110,"skill":76,"defense":18,"initiative":70,"weapon":"greatsword","shield":"","body":"heavy_mail","head":"bascinet","condition":95,"extra":"breastplate"},
	"sentinel":{"name":"Royal Sentinel","hp":68,"skill":64,"defense":12,"initiative":65,"weapon":"spear","shield":"shield","body":"heavy_mail","head":"nasal","condition":85},
	"thrall":{"name":"Barrow Thrall","hp":65,"skill":49,"defense":2,"initiative":55,"weapon":"club","shield":"","body":"leather","head":"","condition":65},
	"guard":{"name":"Tomb Guard","hp":58,"skill":58,"defense":8,"initiative":70,"weapon":"sword","shield":"round_shield","body":"mail","head":"cap","condition":70},
	"spearman":{"name":"Bone Spearman","hp":52,"skill":55,"defense":5,"initiative":68,"weapon":"spear","shield":"round_shield","body":"leather","head":"nasal","condition":70},
	"archer":{"name":"Crypt Archer","hp":45,"skill":53,"defense":3,"initiative":65,"weapon":"shortbow","shield":"","body":"jerkin","head":"","condition":80},
	"warden":{"name":"Sepulchral Warden","hp":95,"skill":67,"defense":14,"initiative":65,"weapon":"hammer","shield":"shield","body":"heavy_mail","head":"nasal","condition":90}}

# Min/max, AP/fatigue, penetration/armour multipliers, accuracy. These are
# fixed intrinsic values from each archetype's shipped basic melee profile
# (the old melee fallback for ranged archetypes), not catalogue references.
const STRIKES := {
	"barrow_lord":[26,36,4,15,0.30,1.15,-5],
	"watch_captain":[27,33,4,14,0.20,0.90,5],
	"buried_king":[42,54,6,20,0.20,0.90,5],
	"sentinel":[24,32,4,12,0.25,0.70,15],
	"thrall":[24,32,4,10,0.25,0.95,0],
	"guard":[27,33,4,14,0.20,0.90,5],
	"spearman":[24,32,4,12,0.25,0.70,15],
	"archer":[12,22,3,7,0.20,0.40,5],
	"warden":[26,36,4,15,0.30,1.15,-5],
}

static func intrinsic(u: Dictionary) -> bool:
	return u.get("side") == 1 and u.get("faction") == "undead" and u.get("weapon") == "" and STRIKES.has(u.get("undead_kind",""))

static func strike_profile(u: Dictionary) -> Dictionary:
	var row: Array = STRIKES[u.undead_kind]
	return {"name":"Claw strike","min":row[0],"max":row[1],"ap":row[2],"fatigue":row[3],"reach":1,"min_range":1,"pierce":row[4],"armor":row[5],"skill":row[6],"head_chance":25,"family":"","ranged":false,"hands":0,"ammo":"","tier":0,"description":"Innate undead attack; no weapon equipped."}

static func spawn_intrinsic(b, u: Dictionary, kind: String, tier: int) -> void:
	set_stats(u,TYPES[kind],kind,tier,35)
	b.cancel_stance(u)
	apply_wear(b,u,{"hp":u.hp,"arms":A.empty_arms(),"parts":[]})

static func set_stats(u: Dictionary, d: Dictionary, kind: String, tier: int, ranged_skill: int) -> void:
	u["faction"] = "undead"; u["undead_kind"] = kind
	u.name = d.name; u.title = "UNDEAD · FEARLESS"
	u.hp = int(d.hp)+(tier-1)*8; u.max_hp = u.hp
	u.skill = int(d.skill)+(tier-1)*3; u.ranged_skill = ranged_skill
	u.defense = int(d.defense)+(tier-1)*2; u.ranged_defense = u.defense
	u.stamina = 120; u.initiative = int(d.initiative); u.resolve = 50
	u.morale_state = 0; u.morale = 85; u.routed = false; u.escaped = false; u.fleeing_rounds = 0
	u.perks = []; u.scars = []; u.temperament = "none"; u.comrades = []

static func equip(b, u: Dictionary, kind: String, tier: int, token: String, acquisition = null, before_cap: bool = false) -> void:
	var d: Dictionary = TYPES[kind] if acquisition == null else acquisition.undead(TYPES[kind],kind)
	if before_cap and acquisition != null and acquisition.has_method("previous_design"): d.head = acquisition.previous_design(d.head)
	var catalog: Dictionary = b.armor_catalog
	set_stats(u,d,kind,tier,int(d.skill)+(tier-1)*3 if d.weapon in A.RANGED else 35)
	u.weapon = d.weapon
	u.arms = A.empty_arms()
	var definitions = {"weapon":d.weapon,"shield":d.shield,"ammo":A.ammo_type(d.weapon),"carry1":d.get("backup","knife" if kind == "archer" else "")}
	for slot in definitions:
		var definition: String = definitions[slot]
		if definition == "": continue
		u.arms[slot] = {"id":token+"_"+slot,"definition":definition,"condition":int(catalog[definition].durability),"loaded":false}
	u.armor_parts = []
	for definition in [d.body,d.head,d.get("extra","")]:
		if definition == "": continue
		var part: Dictionary = catalog[definition]
		u.armor_parts.append({"item":token+"_"+part.group+("_extra" if definition == d.get("extra","") else ""),"definition":definition,"group":part.group,"layer":part.layer,"pool":"helmet" if part.group == "head" else "armor","condition":int(part.durability)*int(d.condition)/100,"maximum":int(part.durability),"weight":int(part.weight)})
	if A.family(d.weapon) == "crossbow": u.arms.weapon.loaded = true
	apply_wear(b,u,{"hp":u.hp,"arms":u.arms,"parts":u.armor_parts})

static func wear(u: Dictionary) -> Dictionary:
	return {"hp":int(u.hp),"arms":u.arms.duplicate(true),"parts":u.armor_parts.duplicate(true)}

static func apply_wear(b, u: Dictionary, saved: Dictionary) -> void:
	u.hp = saved.hp; u.arms = saved.arms.duplicate(true); u.armor_parts = saved.parts.duplicate(true)
	b.sync_arms(u)
	var totals = Armor.totals(u.armor_parts)
	for key in totals: u[key] = totals[key]

static func valid_wear(saved: Variant, original: Dictionary, catalog: Dictionary) -> bool:
	if not saved is Dictionary or saved.size() != 3 or not saved.get("hp") is int or saved.hp < 0 or saved.hp > original.hp: return false
	if not A.valid_arms(saved.get("arms"),catalog) or not Armor.valid_battle_parts(saved.get("parts"),catalog): return false
	var allowed = {}
	for item in original.arms.values():
		if not item.is_empty(): allowed[item.id] = item
	var actual = saved.arms.values().filter(func(item): return not item.is_empty())
	if actual.size() != allowed.size() or saved.parts.size() != original.parts.size(): return false
	for item in actual:
		if not allowed.has(item.id) or item.definition != allowed[item.id].definition or item.condition > allowed[item.id].condition or item.has("named"): return false
	for part in saved.parts:
		var matches = original.parts.filter(func(p): return p.item == part.item)
		if matches.is_empty(): return false
		var expected: Dictionary = matches[0]
		for key in ["definition","group","layer","pool","maximum","weight"]:
			if part[key] != expected[key]: return false
		if part.condition > expected.condition or part.has("named"): return false
	return true
