extends "res://hollow_systems/appearance.gd"
## A detached projection of current owned definitions, never a cosmetic loadout.
const People = preload("res://src/people.gd")
const Rarity = preload("res://hollow_campaign/rarity.gd")
const EFFECT_LABELS := {"skill":"Melee skill","ranged_skill":"Ranged skill","defense":"Melee defense","ranged_defense":"Ranged defense","stamina":"Stamina capacity","initiative":"Initiative","recovery":"Normal recovery","move_fatigue_discount":"Movement fatigue discount per paid edge","carried_load_discount":"Occupied reserve load discount after halving"}

static func item_tier(item: Dictionary, catalog: Dictionary) -> String:
	if item.is_empty(): return ""
	if not item.get("definition") is String or not catalog.has(item.definition) or not Named.valid(item,catalog): return "invalid"
	if item.has("named"): return "named"
	return str(item.get("instance_roll",{}).get("tier",""))

static func is_round_supply(definition: Dictionary) -> bool:
	return definition.get("slot","") == "ammo" or (definition.get("slot","") == "weapon" and int(definition.get("durability",0)) > 0)

static func item_details(item: Dictionary, catalog: Dictionary) -> String:
	if item.is_empty(): return "Empty"
	var uid := str(item.get("id",item.get("item",item.get("item_id",""))))
	if uid.is_empty(): return "Empty"
	var definition := str(item.get("definition",""))
	var ordinary: Dictionary = catalog.get(definition,{})
	if item_tier(item,catalog) == "invalid": return "Invalid equipment metadata\nUID "+uid+" · "+definition+"\nInvalid definition/roll; effective stats unavailable."
	var effective: Dictionary = Named.definition(item,catalog)
	var roll: Dictionary = item.get("instance_roll",{})
	var rarity := item_tier(item,catalog).capitalize()
	var progression := "Tier %d %s" % [int(ordinary.tier),str(ordinary.quality)] if ordinary.has("tier") and ordinary.has("quality") else "Ammunition supply" if ordinary.get("slot","") == "ammo" else "Progression tier unavailable"
	var role := str(ordinary.get("role","Ammunition supply (remaining rounds)" if ordinary.get("slot","") == "ammo" else "Not authored"))
	var lines := PackedStringArray([str(effective.get("name",definition)),progression+" · Rarity: "+(rarity+" (immutable)" if not rarity.is_empty() else "Unrated"),"Role: "+role,"UID "+uid+" · "+definition])
	if effective.is_empty():
		lines.append("Invalid definition/roll; effective stats unavailable.")
		return "\n".join(lines)
	if item.has("named"):
		lines.append("Named craftsmanship; independent of Common/Rare/Legendary tiers.")
		lines.append("Named bonuses: "+Named.summary(item))
		lines.append("Source: "+str(item.named.source))
		lines.append(str(item.named.lore))
	elif not item.has("instance_roll"):
		lines.append("No immutable rarity roll recorded; base stats shown.")
	var maximum := int(item.get("maximum",effective.get("durability",0)))
	if maximum > 0:
		var ammo := is_round_supply(ordinary)
		lines.append(("Rounds" if ammo else "Condition")+" %d/%d%s" % [item.get("condition",maximum),maximum," · EMPTY" if ammo and int(item.get("condition",maximum)) <= 0 else " · BROKEN" if not ammo and int(item.get("condition",maximum)) <= 0 else ""])
	if int(ordinary.get("durability",0)) > 0 and ordinary.has("group") and ordinary.get("slot","") != "shield":
		lines.append("Protection %d → %d · %s" % [ordinary.durability,effective.get("durability",0),"Named bonus +%d%%" % Named.bonuses(item).get("protection",0) if item.has("named") else "immutable roll +%d%%" % roll.percent.protection if item.has("instance_roll") else "base definition (unrolled)"])
		if ordinary.get("slot","") in ["hands","feet","cloak","belt"]: lines.append("Pooled body protection only; no extra head mitigation.")
	if ordinary.get("slot","") == "shield":
		var broken := maximum > 0 and int(item.get("condition",maximum)) <= 0
		var melee := int(ordinary.get("melee_defense",0))
		var ranged := int(ordinary.get("ranged_defense",0))
		lines.append("Shield bonuses while equipped; before fighter/perk modifiers%s" % (" · BROKEN · inactive" if broken else ""))
		lines.append("Melee defense %+d · Ranged defense %+d" % [0 if broken else melee,0 if broken else ranged])
		if broken: lines.append("Intact shield: Melee defense %+d · Ranged defense %+d" % [melee,ranged])
	if ordinary.get("slot","") == "weapon":
		var base: Dictionary = _weapons.get(ordinary.get("weapon",definition),{})
		var weapon: Dictionary = Named.weapon(item,base)
		if not weapon.is_empty():
			lines.append("Damage %d–%d → %d–%d · %s" % [base.min,base.max,weapon.min,weapon.max,"Named bonus +%d%%" % Named.bonuses(item).get("damage",0) if item.has("named") else "immutable roll +%d%%" % roll.percent.damage if item.has("instance_roll") else "base definition (unrolled)"])
			lines.append("Armor multiplier %.2f → %.2f · Penetration %d%% → %d%%" % [base.armor,weapon.armor,roundi(float(base.pierce)*100),roundi(float(weapon.pierce)*100)])
			lines.append("Accuracy %+d · %d hand(s) · Range %d–%d" % [weapon.get("skill",0),weapon.get("hands",1),weapon.get("min_range",1),weapon.get("reach",1)])
			lines.append("Basic base cost %d AP / %d fatigue; current fighter/perks may modify costs (see effective stats)." % [weapon.ap,weapon.fatigue])
			if weapon.get("special_ap") != null and weapon.get("special_fatigue") != null: lines.append("Special base cost %d AP / %d fatigue" % [weapon.special_ap,weapon.special_fatigue])
	var load_value := int(effective.get("weight",0))
	if ArmLoad.LOAD.has(definition): load_value = Named.weight(item,int(ArmLoad.LOAD[definition]))
	lines.append("Load %d" % load_value)
	for field: String in EFFECT_LABELS:
		var value := int(effective.get("effects",{}).get(field,0))
		if value != 0: lines.append("%s %+d%s" % [EFFECT_LABELS[field],value," (disabled while broken)" if maximum > 0 and int(item.get("condition",maximum)) <= 0 and value > 0 else ""])
	if ordinary.get("slot","") == "belt": lines.append("Reserve capacity +%d; base 2, Bags and Belts 4. Only actual capacity belts add a reserve; existing paid single-item switches." % int(effective.get("capacity",0)))
	for line: String in Rarity.utility_lines(item,ordinary):lines.append("Utility roll · "+line)
	if int(ordinary.get("durability",0)) == 0 and ordinary.get("slot","") in ["hands","feet","cloak","belt"]: lines.append("Utility is active at zero condition. Whole-point utility rolls derive independently from immutable item identity; fixed functions stay unchanged.")
	elif ordinary.get("slot","") in ["hands","feet","cloak","belt"]: lines.append("Rarity improves protection only on this protective alternative; authored penalties stay unchanged.")
	if SHARED_PAINT.has(definition): lines.append(SHARED_PAINT[definition])
	if ordinary.get("slot","") == "ammo" and ordinary.has("description"): lines.append(str(ordinary.description))
	if ordinary.has("price"): lines.append("Price %d · provisional economy value, not campaign-qualified." % int(ordinary.price))
	return "\n".join(lines)

# Scalar fields are copied literally; `load` is the engine's raw armor load,
# not total carried/equipped burden. Derived consumers are named separately.
const OBSERVED_SCALARS := ["id","company_id","visual_id","side","hp","max_hp","ap","resolve","skill","ranged_skill","defense","ranged_defense","stamina","initiative","fatigue","load","armor","max_armor","padding","max_padding","helmet","max_helmet","recovery_bonus","move_fatigue_discount","carried_load_discount","hollow_capacity"]
const INVENTORY_STAT_SCALARS := ["skill","ranged_skill","defense","ranged_defense","stamina","initiative","fatigue","load","recovery_bonus","move_fatigue_discount","carried_load_discount"]

static func inventory_stats(unit: Dictionary, battle = null) -> Dictionary:
	if unit.is_empty(): return {}
	var out := {}
	for key: String in INVENTORY_STAT_SCALARS:
		if unit.has(key): out[key] = unit[key]
	out["equipment_load"] = People.equipment_load(unit)
	out["fatigue_max"] = People.fatigue_max(unit)
	out["recovery"] = People.recovery(unit)
	out["effective_initiative"] = int(battle.initiative_value(unit)) if battle != null else People.initiative_value(unit)
	return out

static func unit_observation(unit: Dictionary, battle = null) -> Dictionary:
	if unit.is_empty(): return {}
	var out := {}
	for key: String in OBSERVED_SCALARS:
		if unit.has(key): out[key] = unit[key]
	out["inventory_balance"] = unit.get("inventory_balance",false)
	for key: String in ["equipment_slots","inventory_equipment_base","inventory_effects","arms","companion_roll"]:
		out[key] = unit.get(key,{}).duplicate(true)
	out["armor_parts"] = unit.get("armor_parts",[]).duplicate(true)
	out["inventory_stats"] = inventory_stats(unit,battle)
	out["effective_stats_text"] = effective_stats(unit,battle)
	return out

static func effective_stats(unit: Dictionary, battle = null) -> String:
	if unit.is_empty(): return "No current fighter."
	var stats := inventory_stats(unit,battle)
	var lines := PackedStringArray(["WHOLE EFFECTIVE STATS","HP %d/%d · AP %d · Resolve %d" % [unit.get("hp",0),unit.get("max_hp",0),unit.get("ap",0),unit.get("resolve",0)],"Body %d/%d · Head %d/%d" % [int(unit.get("armor",0))+int(unit.get("padding",0)),int(unit.get("max_armor",0))+int(unit.get("max_padding",0)),unit.get("helmet",0),unit.get("max_helmet",0)],"Melee %d · Ranged %d" % [stats.get("skill",0),stats.get("ranged_skill",0)],"Defense: base + support (pre-shield)","Melee defense %d · Ranged defense %d" % [stats.get("defense",0),stats.get("ranged_defense",0)],"Shield, stance, perk and target modifiers are separate; not total defense.","Stamina %d · Fatigue %d/%d" % [stats.get("stamina",0),stats.get("fatigue",0),stats.fatigue_max],"Initiative %d · Equipment load %d" % [stats.effective_initiative,stats.equipment_load],"Normal recovery %d · Wait does not grant recovery" % stats.recovery])
	var effects: Dictionary = unit.get("inventory_effects",{})
	for field: String in EFFECT_LABELS:
		if int(effects.get(field,0)) != 0: lines.append("Equipped %s %+d" % [EFFECT_LABELS[field],effects[field]])
	if battle != null and battle.weapons.has(unit.get("weapon","")):
		var cost: Dictionary = battle.action_cost(unit,false)
		lines.append("Current basic cost %d AP / %d fatigue (no target selected)" % [cost.ap,cost.fatigue])
		var ammo: Dictionary = unit.get("arms",{}).get("ammo",{})
		var bundle: Dictionary = battle.armor_catalog.get(ammo.get("definition",""),{})
		if bundle.get("slot","") == "ammo" and bundle.has("description"):
			lines.append("Equipped %s · Rounds %d/%d" % [bundle.name,ammo.get("condition",0),bundle.durability])
			lines.append(str(bundle.description))
		if battle.weapon_stats(unit).get("special_enabled",true):
			cost = battle.action_cost(unit,true)
			lines.append("Current special cost %d AP / %d fatigue (target can modify admission/cost)" % [cost.ap,cost.fatigue])
	return "\n".join(lines)

const SHARED_PAINT := {
	"short_bow":"Short bow / Reedrunner Bow share the same exact fitted paint; their real profiles differ.",
	"hm_trial_v1:old24-reedrunner_bow":"Short bow / Reedrunner Bow share the same exact fitted paint; their real profiles differ.",
	"iron_cap":"Legacy Iron cap; retains its original protection and load.",
	"breather_belt":"Breather belt / Support belt share the same exact fitted paint; utility is not protection.",
	"hm_trial_v1:belts-03-support-belt":"Breather belt / Support belt share the same exact fitted paint; utility is not protection."
}

func payload(unit: Dictionary, catalog: Dictionary) -> Dictionary:
	var family: String = APPEARANCES[posmod(int(unit.get("visual_id",0)),6)]
	var detached := {"person_id":"bb2:"+str(unit.get("visual_id",0)),"appearance":family,"slots":{}}
	var signature := {}
	var issues: Array = []
	var equipment: Dictionary = unit.get("equipment_slots",{})
	var main_definition := str(equipment.get("mainhand",{}).get("definition",""))
	var main_donor := str(catalog.get(main_definition,{}).get("donor_definition",""))
	# The frozen resolver metadata, not an old BB2 family/name, owns fitted hands.
	var main_hands := int(resolver._model.get("definitions",{}).get(main_donor,{}).get("hands",0))
	for slot: String in SLOTS:
		var physical: Dictionary = equipment.get(slot,{})
		if physical.is_empty(): continue
		var definition := str(physical.get("definition",""))
		var mapped := str(catalog.get(definition,{}).get("donor_definition",""))
		var entry := _record(slot,definition,physical,catalog,mapped)
		signature[slot] = entry
		if slot == "ammo":
			entry.broken = false
			_omit(entry,issues,"Actual ammunition %d/%d rounds; quiver/ammo paint omitted, supply remains mechanical." % [entry.condition,entry.maximum])
			continue
		if slot == "offhand" and (entry.broken or main_hands == 2):
			_omit(entry,issues,"Broken shield has no paint." if entry.broken else "Exact donor two-hand pose excludes offhand paint; actual mechanics remain authoritative.")
			continue
		if not _admit(entry,issues): continue
		detached.slots[slot] = {"uid":entry.item,"definition_id":mapped}
		if slot in ["mainhand","offhand"]:
			var hands := int(resolver._model.get("definitions",{}).get(mapped,{}).get("hands",0))
			detached.slots[slot]["physical_hand"] = ("right" if slot == "mainhand" else "left") if hands == 1 else null
	return {"detached":detached,"signature":signature,"issues":issues}

func _omit(entry: Dictionary, issues: Array, reason: String) -> void:
	entry.visible = false
	entry.painted = false
	entry.visibility_reason = reason
	issues.append({"slot":entry.slot,"uid":entry.item,"definition":entry.definition,"reason":reason})

func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
	if not admission.get("ok",false): return admission.duplicate(true)
	var projected := payload(unit,catalog)
	var result: Dictionary = _present(projected.detached,projected.signature)
	result["detached"] = projected.detached
	result["signature"] = projected.signature
	result["issues"] = projected.issues
	result["notes"] = []
	if result.get("ok",false):
		for issue: Dictionary in result.plan.issues:
			var slot := str(issue.get("slot",""))
			if not result.signature.has(slot): continue
			var entry: Dictionary = result.signature[slot]
			var reason := str(issue.reason)
			if entry.definition in ["hm_trial_v1:additional_fighting_axe","hm_trial_v1:twohand_sword"]:
				reason = "Missing exact fitted art for %s on %s: %s. Medic-only source route; mechanics allowed on every companion, no class lock or proxy paint." % [catalog.get(entry.definition,{}).get("name",entry.definition),result.detached.appearance,reason]
			_omit(entry,result.issues,reason)
	for entry: Dictionary in result.signature.values():
		if SHARED_PAINT.has(entry.definition): result.notes.append(SHARED_PAINT[entry.definition])
		if not entry.visibility_reason.is_empty(): result.notes.append(entry.visibility_reason)
	return result

func _record(slot: String, definition: String, source: Dictionary, catalog: Dictionary, mapped: String) -> Dictionary:
	var entry := super._record(slot,definition,source,catalog,mapped)
	# Literal successor definitions are exact mappings, not predecessor family proxies.
	entry.proxy = false
	entry.fallback = mapped.is_empty()
	entry.fallback_reason = ""
	return entry
