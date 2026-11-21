extends RefCounted
## Isolated, in-memory battle fixture. Combat stays in the existing Battle.
const Battle = preload("res://src/battle.gd")
const Armor = preload("res://src/armor.gd")
const Arsenal = preload("res://src/arsenal.gd")

static func create(seed_value: int = 7391):
	var battle = Battle.new()
	# advanced weapons, SIDE turns, pooled damage, core combat, personal perks.
	battle.setup(seed_value, "ford", "eliminate", true, false, true, true, true)
	configure_equipment(battle)
	# setup normally initializes these only for initiative turns. Core hit/morale
	# methods also need them in side mode; use the engine's own initializer.
	for unit in battle.units:
		battle.initialize_stats(unit)
	configure_map(battle)
	var positions = [Vector2i(5,4), Vector2i(4,5), Vector2i(3,2),
		Vector2i(3,1), Vector2i(3,6), Vector2i(4,7),
		Vector2i(7,4), Vector2i(8,3), Vector2i(8,5),
		Vector2i(9,6), Vector2i(10,3), Vector2i(10,6)]
	for unit in battle.units:
		unit.q = positions[unit.id].x
		unit.r = positions[unit.id].y
	return battle

static func configure_equipment(battle) -> void:
	# These are catalog definitions, not cosmetic equipment labels. The chosen
	# perks are passive: activation-timed perk lifetimes require individual turns.
	var kits = [
		["sword", "shield", "shield_expert", ["linen","mail","blue_tabard","arming_cap","nasal"]],
		["axe", "round_shield", "axe_mastery", ["red_gambeson","brigandine","kettle"]],
		["spear", "buckler", "spear_mastery", ["light_quilt","short_mail","cap","blue_wrap"]],
		["bow", "", "bow_mastery", ["green_jack","leather","forest_cloak","felt_cap"]],
		["greatsword", "", "sword_mastery", ["red_gambeson","long_mail","bascinet","visor"]],
		["mace", "buckler", "mace_mastery", ["gambeson","scale_vest","sash","cap","cheek_guards"]],
		["sword", "round_shield", "steel_brow", ["red_gambeson","mail","red_surcoat","arming_cap","nasal"]],
		["heavy_spear", "shield", "shield_expert", ["gambeson","short_mail","kettle","mail_curtain"]],
		["hatchet", "buckler", "axe_mastery", ["linen","leather","red_cape","simple_helm"]],
		["hammer", "", "hammer_mastery", ["green_jack","heavy_mail","collar","bascinet"]],
		["shortbow", "", "bow_mastery", ["light_quilt","leather","padded_hood"]],
		["polearm", "", "polearm_mastery", ["linen","mail","shoulders","cap","mail_coif"]],
	]
	for unit in battle.units:
		var kit: Array = kits[unit.id]
		unit.weapon = kit[0]
		unit.shield = kit[1] != ""
		unit.perks = [kit[2]]
		battle.initialize_arms(unit)
		if unit.shield:
			unit.arms.shield.definition = kit[1]
			unit.arms.shield.condition = int(battle.armor_catalog[kit[1]].durability)
		battle.sync_arms(unit)
		unit.armor_parts = []
		for definition in kit[3]:
			var d: Dictionary = battle.armor_catalog[definition]
			unit.armor_parts.append({
				"item":"prototype_%d_%s" % [unit.id,definition],
				"definition":definition, "group":d.group, "layer":d.layer,
				"pool":"helmet" if d.group == "head" else "padding" if d.layer == "base" else "armor",
				"condition":int(d.durability), "maximum":int(d.durability),
				"weight":Armor.part_weight({"definition":definition},battle.armor_catalog),
			})
		var totals = Armor.totals(unit.armor_parts)
		for field in totals: unit[field] = totals[field]
	battle.units[9].title = "MARCH HAMMERMAN"
	battle.units[11].title = "MARCH BILLMAN"

static func configure_map(battle) -> void:
	# q/r are the engine's odd-row offset coordinates, NOT axial coordinates.
	for r in 9:
		for q in 13:
			var p = Vector2i(q,r)
			var terrain = "stone" if r == 4 and q >= 2 and q <= 10 else "grass"
			var elevation = 0
			if (q >= 2 and q <= 4 and r >= 1 and r <= 2) or (q >= 8 and q <= 10 and r >= 1 and r <= 3):
				terrain = "hill"
				elevation = 1
			if p == Vector2i(9,1): elevation = 2
			if q in [5,7] and r in [0,1,7,8]: terrain = "mud"
			if q == 6: terrain = "ford" if r == 4 else "water"
			battle.tiles[battle.key(p)] = {"terrain":terrain,"height":elevation}
	for p in [Vector2i(0,0),Vector2i(1,7),Vector2i(12,1),Vector2i(12,8)]:
		battle.tiles[battle.key(p)].terrain = "forest"
	# The two northern ruin caps prevent direct h0->h2 entry to the peak.
	# They are real wall blockers, not an invented maximum-climb rule.
	for p in [Vector2i(4,2),Vector2i(4,3),Vector2i(8,2),Vector2i(9,2),
		Vector2i(9,5),Vector2i(10,5),Vector2i(9,0),Vector2i(10,0)]:
		battle.tiles[battle.key(p)].terrain = "wall"
