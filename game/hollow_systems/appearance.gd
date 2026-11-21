extends "res://hollow_experiment/appearance.gd"
## Only detached current equipment_slots enter the immutable donor resolver.
## No armor-owned support, inferred UID, inventory, or appearance-dependent rules.
const SLOTS := ["mainhand","offhand","head","body","hands","feet","cloak","belt","ammo"]
const Named = preload("res://src/named_equipment.gd")
const ArmLoad = preload("res://src/arsenal.gd")
static var _weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))

static func item_details(item: Dictionary, catalog: Dictionary) -> String:
	if item.is_empty(): return "Empty"
	var uid := str(item.get("id",item.get("item",item.get("item_id",""))))
	if uid.is_empty(): return "Empty"
	var definition := str(item.get("definition",""))
	var ordinary: Dictionary = catalog.get(definition,{})
	var effective: Dictionary = Named.definition(item,catalog)
	var roll: Dictionary = item.get("instance_roll",{})
	var tier := str(roll.get("tier",""))
	var lines := PackedStringArray([str(effective.get("name",ordinary.get("name",definition)))+" · "+(tier.capitalize() if not tier.is_empty() else "Unrated"),"UID "+uid+" · "+definition])
	if effective.is_empty():
		lines.append("Invalid definition/roll metadata; effective stats unavailable.")
		return "\n".join(lines)
	var maximum := int(item.get("maximum",effective.get("durability",0)))
	if maximum > 0:
		var supply: bool = ordinary.get("slot","") == "ammo"
		lines.append(("Rounds" if supply else "Condition")+" %d/%d%s" % [item.get("condition",maximum),maximum," · EMPTY" if supply and int(item.get("condition",maximum)) <= 0 else " · BROKEN" if not supply and int(item.get("condition",maximum)) <= 0 else ""])
	if int(ordinary.get("durability",0)) > 0 and ordinary.get("slot","") != "ammo":
		lines.append("Protection %d → %d · roll +%d%%" % [ordinary.durability,effective.get("durability",0),roll.get("percent",{}).get("protection",0)])
	if ordinary.get("slot","") == "weapon":
		var base: Dictionary = _weapons.get(ordinary.get("weapon",definition),{})
		var weapon: Dictionary = Named.weapon(item,base)
		if not weapon.is_empty(): lines.append("Damage %d–%d → %d–%d · roll +%d%%" % [base.min,base.max,weapon.min,weapon.max,roll.get("percent",{}).get("damage",0)])
	var load_value := int(effective.get("weight",0))
	if ArmLoad.LOAD.has(definition): load_value = Named.weight(item,int(ArmLoad.LOAD[definition]))
	lines.append("Load %d" % load_value)
	if effective.has("capacity"): lines.append("Carried-arm capacity +%d; existing paid single-item switches only." % effective.capacity)
	if ordinary.has("budget_note"): lines.append(str(ordinary.budget_note))
	return "\n".join(lines)

static func person_details(unit: Dictionary) -> String:
	var roll: Dictionary = unit.get("companion_roll",{})
	if roll.is_empty(): return "Companion rarity unavailable; no roll invented."
	var lines := PackedStringArray(["COMPANION · "+str(roll.get("tier","")).capitalize()])
	var bases: Dictionary = roll.get("bases",{})
	var values: Dictionary = roll.get("values",{})
	var keys: Array = bases.keys(); keys.sort()
	for key: String in keys:
		if not values.has(key): continue
		lines.append("%s %d → %d (%+d)" % [key.replace("_"," ").capitalize(),bases[key],values[key],int(values[key])-int(bases[key])])
	lines.append("Immutable trial rolls; rarity is potential, not guaranteed superiority. No growth-star conversion.")
	return "\n".join(lines)

func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
	if not admission.get("ok",false): return admission.duplicate(true)
	var family: String = APPEARANCES[posmod(int(unit.get("visual_id",0)),6)]
	var detached := {"person_id":"bb2:"+str(unit.get("visual_id",0)),"appearance":family,"slots":{}}
	var signature := {}
	var issues: Array = []
	var equipment: Dictionary = unit.get("equipment_slots",{})
	var weapon: String = equipment.get("mainhand",{}).get("definition","")
	for slot: String in SLOTS:
		var physical: Dictionary = equipment.get(slot,{})
		if physical.is_empty(): continue
		var definition := str(physical.get("definition",""))
		var ordinary: Dictionary = catalog.get(definition,{})
		var mapped: String = ordinary.get("donor_definition","")
		if mapped.is_empty():
			if slot == "mainhand": mapped = WEAPONS.get(definition,"")
			elif slot == "offhand": mapped = SHIELDS.get(definition,"")
			elif slot == "body": mapped = BODY.get(definition,"")
			elif slot == "head": mapped = HEAD.get(definition,"")
		if slot == "mainhand" and definition == "axe" and family == "medic": mapped = "hm_trial_v1:additional_fighting_axe"
		var entry := _record(slot,definition,physical,catalog,mapped)
		signature[slot] = entry
		if slot == "ammo":
			entry.broken = false
			entry.visible = false; entry.painted = false
			entry.visibility_reason = "Actual ammunition %d/%d rounds; quiver/ammo paint omitted, supply remains mechanical." % [entry.condition,entry.maximum]
			issues.append({"slot":slot,"uid":entry.item,"definition":definition,"reason":entry.visibility_reason})
			continue
		if slot == "offhand" and (entry.broken or weapon in ["spear","bow"]):
			entry.visible = false; entry.painted = false
			entry.visibility_reason = "Broken shield has no paint." if entry.broken else "Complete donor two-hand pose excludes actual offhand shield paint; BB2 mechanics unchanged."
			issues.append({"slot":slot,"uid":entry.item,"definition":definition,"reason":entry.visibility_reason})
			continue
		if not _admit(entry,issues): continue
		detached.slots[slot] = {"uid":entry.item,"definition_id":mapped}
		if slot == "mainhand": detached.slots[slot]["physical_hand"] = null if definition in ["spear","bow"] else "right"
		elif slot == "offhand": detached.slots[slot]["physical_hand"] = "left"
	var result: Dictionary = _present(detached,signature)
	result["detached"] = detached.duplicate(true)
	result["signature"] = signature
	result["issues"] = issues
	result["notes"] = []
	for entry: Dictionary in signature.values():
		if entry.proxy: result.notes.append(entry.fallback_reason)
		if not entry.visibility_reason.is_empty(): result.notes.append(entry.visibility_reason)
	if result.get("ok",false):
		for issue: Dictionary in result.plan.issues:
			var slot := str(issue.get("slot",""))
			if signature.has(slot):
				signature[slot].visible = false
				signature[slot].painted = false
				signature[slot].visibility_reason = issue.reason
				issue = issue.duplicate(true)
				issue["definition"] = signature[slot].definition
			result.issues.append(issue)
	return result

func _record(slot: String, definition: String, source: Dictionary, catalog: Dictionary, mapped: String) -> Dictionary:
	var entry := super._record(slot,definition,source,catalog,mapped)
	entry["instance_roll"] = source.get("instance_roll",{}).duplicate(true)
	entry["rarity"] = str(entry.instance_roll.get("tier",""))
	return entry
