extends RefCounted
## Authored starting gear, never a cosmetic override or mid-fight equipment cheat.
const Scenario = preload("res://prototype/scenario.gd")
const Armor = preload("res://src/armor.gd")
const KITS := [
	{"name":"MAIL RETAINER", "weapon":"sword", "shield":"shield", "perks":["shield_expert"], "parts":["linen","mail","arming_cap","nasal"]},
	{"name":"BRIGANDINE AXEMAN", "weapon":"axe", "shield":"round_shield", "perks":["axe_mastery"], "parts":["red_gambeson","brigandine","kettle"]},
	{"name":"LIGHT TRAVELLER", "weapon":"sword", "shield":"", "perks":["sword_mastery"], "parts":["linen"]}
]
static var selected_profile := 0
static func create(index: int = 0):
	var battle = Scenario.create()
	var hero: Dictionary = battle.units[0]
	var kit: Dictionary = KITS[clampi(index,0,KITS.size()-1)]
	hero.weapon = kit.weapon
	hero.shield = not kit.shield.is_empty()
	hero.perks = kit.perks.duplicate()
	battle.initialize_arms(hero)
	if hero.shield:
		hero.arms.shield.definition = kit.shield
		hero.arms.shield.condition = int(battle.armor_catalog[kit.shield].durability)
	battle.sync_arms(hero)
	hero.armor_parts = []
	for definition: String in kit.parts:
		var d: Dictionary = battle.armor_catalog[definition]
		hero.armor_parts.append({"item":"slice_0_"+definition,"definition":definition,
			"group":d.group,"layer":d.layer,"pool":"helmet" if d.group == "head" else "padding" if d.layer == "base" else "armor",
			"condition":int(d.durability),"maximum":int(d.durability),
			"weight":Armor.part_weight({"definition":definition},battle.armor_catalog)})
	var totals: Dictionary = Armor.totals(hero.armor_parts)
	for key in totals: hero[key] = totals[key]
	battle.initialize_stats(hero)
	return battle
