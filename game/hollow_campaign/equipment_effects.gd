extends RefCounted
## Runtime projections only: physical items, rarity rolls and companion bases stay authoritative.
const Perks = preload("res://src/perks.gd")
const Named = preload("res://src/named_equipment.gd")
const EFFECTS = ["skill","ranged_skill","defense","ranged_defense","stamina","initiative","recovery","move_fatigue_discount","carried_load_discount"]

static func profile(parts: Array, catalog: Dictionary) -> Dictionary:
 var out: Dictionary = {}
 for field in EFFECTS: out[field] = 0
 for part in parts:
  # The immutable instance roll may still contain legacy utility bonuses.
  if catalog.get(part.definition,{}).get("lab_outfit",false): continue
  var definition: Dictionary = Named.definition(part,catalog)
  var broken = int(part.get("maximum",definition.get("durability",0))) > 0 and int(part.get("condition",0)) <= 0
  for field in EFFECTS:
   var value = definition.get("effects",{}).get(field,0)
   # Godot JSON numbers are floats. Convert only finite, integral int64 values.
   if value is float:
    if not is_finite(value) or value != floor(value) or value < -9223372036854775808.0 or value >= 9223372036854775808.0: continue
    value = int(value)
   if value is int and (value < 0 or not broken): out[field] += value
 return out

const BASE_FIELDS = ["skill","ranged_skill","defense","ranged_defense","stamina","initiative"]

static func capacity(person: Dictionary, items: Dictionary, catalog: Dictionary) -> int:
 if Perks.has(person,"bags_and_belts"): return 4
 var belt: Dictionary = items.get(person.get("gear",{}).get("belt",""),{})
 var definition: Dictionary = catalog.get(belt.get("definition",""),{})
 if int(definition.get("durability",0)) > 0 and int(belt.get("condition",0)) <= 0: return 2
 return 2+int(definition.get("capacity",0))

static func install(unit: Dictionary, catalog: Dictionary) -> void:
 # Called only after companion-derived fields are final. Never recapture adjusted stats.
 if not unit.has("inventory_equipment_base"):
  var bases: Dictionary = {}
  for field in BASE_FIELDS: bases[field] = int(unit.get(field,0))
  unit["inventory_equipment_base"] = bases
 unit["inventory_balance"] = true
 refresh(unit,catalog)

static func refresh(unit: Dictionary, catalog: Dictionary) -> void:
 if not unit.get("inventory_balance",false) or not unit.has("inventory_equipment_base"): return
 var applied = profile(unit.get("armor_parts",[]),catalog)
 unit["inventory_effects"] = applied
 for field in BASE_FIELDS: unit[field] = int(unit.inventory_equipment_base[field])+applied[field]
 unit["recovery_bonus"] = applied.recovery
 unit["move_fatigue_discount"] = applied.move_fatigue_discount
 unit["carried_load_discount"] = applied.carried_load_discount
