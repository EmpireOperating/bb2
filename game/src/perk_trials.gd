extends RefCounted
## Authored test fixtures, not a progression system. Values come from roster examples.
const P = preload("res://src/perks.gd")
const A = preload("res://src/arsenal.gd")
const Armor = preload("res://src/armor.gd")
const DATA = preload("res://data/perk_trials.json")
const KITS = {
	"Light":["light_quilt","leather","arming_cap","mail_curtain","cap","crest"],
	"Medium":["gambeson","mail","leather","arming_cap","mail_coif","nasal"],
	"Heavy":["gambeson","heavy_mail","breastplate","shoulders","fur_mantle","arming_cap","mail_coif","bascinet","cheek_guards","crest"]}
static func builds() -> Array: return DATA.data
static func equip_battle(b, id: int, build: Dictionary) -> int:
	var u: Dictionary = b.units[id]; var stats: Array = build.stats
	u.name = build.person; u.title = build.title; u.weapon = build.weapon; u.shield = build.shield
	b.initialize_arms(u)
	u.perks = build.perks.duplicate(); u.perk_state = P.state()
	u.hp = floori(stats[0]*(1.25 if P.has(u,"colossus") else 1.0)); u.max_hp = u.hp
	u.stamina = int(stats[1]); u.resolve = int(stats[2]); u.initiative = int(stats[3]); u.skill = int(stats[4]); u.defense = int(stats[5]); u.ranged_skill = int(stats[6]); u.ranged_defense = int(stats[7])
	u.temperament = "none"; u.fatigue = 0; u.morale = 85; u.morale_state = 0; u.routed = false; u.escaped = false; u.armor_parts = []
	var cost = int(b.armor_catalog[build.weapon].price)+(int(b.armor_catalog.shield.price) if build.shield else 0)
	for i in 2:
		var definition: String = build.carry[i]
		if definition.is_empty(): continue
		u.arms["carry%d" % (i+1)] = {"id":"trial_%d_carry%d" % [id,i],"definition":definition,"condition":int(b.armor_catalog[definition].durability),"loaded":false}
		cost += int(b.armor_catalog[definition].price)
	for definition in KITS[build.armor]:
		var d: Dictionary = b.armor_catalog[definition]; cost += int(d.price)
		u.armor_parts.append({"item":"trial_%d_%s" % [id,definition],"definition":definition,"group":d.group,"layer":d.layer,"pool":"helmet" if d.group == "head" else "padding" if d.layer == "base" else "armor","condition":int(d.durability),"maximum":int(d.durability),"weight":int(d.weight)})
	for field in Armor.totals(u.armor_parts): u[field] = Armor.totals(u.armor_parts)[field]
	return cost

static func install(c) -> void:
	c.setup(7391)
	for i in 3: apply_build(c,i,i*3)
	c.note("PERK SANDBOX: Runa, Hagen and Mara have ten fixture points. Declared XP supplies level eleven; final stats are authored fixtures, not natural campaign progress.")

static func apply_build(c, soldier_id: int, build_id: int) -> void:
	apply_fixture(c,soldier_id,builds()[build_id],["Militia","Farmhand","Outrider"][build_id/3])

static func apply_fixture(c, soldier_id: int, build: Dictionary, background: String) -> void:
	var s: Dictionary = c.soldiers[soldier_id]; var stats: Array = build.stats
	s.name = build.person; s.background = background; s.title = s.background.to_upper()
	s.perks = []; s.erase("perk_version"); P.initialize(s,build.groups)
	grant_test_levels(c,s)
	s.perks = build.perks.duplicate(); s.gifted_choices = build.gifts.duplicate()
	for i in 8: s[["base_hp","stamina","resolve","initiative","base_skill","base_defense","base_ranged_skill","base_ranged_defense"][i]] = int(stats[i])
	s.wound_days = 0; s.hp = c.max_hp(s); s.temperament = "none"
	s.gear.weapon = c.add_item(build.weapon); s.gear.shield = c.add_item("shield") if build.shield else ""
	s.gear.ammo = c.add_item(A.ammo_type(build.weapon)) if not A.ammo_type(build.weapon).is_empty() else ""
	for i in 2: s.gear["carry%d" % (i+1)] = c.add_item(build.carry[i]) if not build.carry[i].is_empty() else ""
	for group in ["body","head"]:
		var parts = Armor.empty_parts(group)
		for definition in KITS[build.armor]:
			var d: Dictionary = c.catalog[definition]
			if d.group == group: parts[d.layer] = c.add_item(definition)
		s.gear[group] = c.add_assembly(group,parts)

static func grant_test_levels(c, s: Dictionary) -> void:
	var n = 0
	while s.xp < c.Progression.THRESHOLDS[10]:
		c.Progression.grant(s,"battle_perk_fixture_%d" % n,mini(45,c.Progression.THRESHOLDS[10]-s.xp),c.day,"Declared perk sandbox XP fixture.")
		n += 1
