extends RefCounted
## Read-only presentation queries. Campaign/preview and Battle remain authority.
const People = preload("res://src/people.gd")
const Armor = preload("res://src/armor.gd")
const Arsenal = preload("res://src/arsenal.gd")
const Perks = preload("res://src/perks.gd")
const Effects = preload("res://hollow_campaign/equipment_effects.gd")

static func permanent(person: Dictionary, attr: String, offer: bool = false) -> int:
 # Current stored bases already contain training and Gifted. The immutable
 # creation roll contributes its saved delta, never its historical full value.
 var roll: Dictionary = person.get("companion_roll",{})
 var delta := int(roll.get("values",{}).get(attr,0))-int(roll.get("bases",{}).get(attr,0))
 return int(person[People.OFFER_FIELDS[attr] if offer else People.FIELDS[attr]])+delta

static func offer_preview(person: Dictionary, catalog: Dictionary) -> Dictionary:
 # Definition-only projection: no physical UIDs/rolls exist until a paid hire.
 # Rarity v1 changes damage/protection, not these attributes or basekit weight.
 var unit: Dictionary = person.duplicate(true)
 for attr: String in People.ATTRS: unit[attr] = permanent(person,attr,true)
 unit["max_hp"] = floori(unit.health*(1.25 if Perks.has(person,"colossus") else 1.0))
 unit["fatigue"] = 0;unit["arms"] = Arsenal.empty_arms();unit["armor_parts"] = []
 var definitions := {"weapon":person.weapon,"shield":person.loadout.shield,"carry1":person.carried_loadout[0],"carry2":person.carried_loadout[1],"ammo":person.ammo_loadout}
 for slot: String in definitions:
  var definition: String = definitions[slot]
  if not definition.is_empty(): unit.arms[slot] = {"definition":definition,"condition":int(catalog[definition].durability),"loaded":false}
 unit["shield"] = not unit.arms.shield.is_empty() and unit.arms.shield.condition > 0
 for group: String in person.armor_loadout:
  for layer: String in person.armor_loadout[group]:
   var definition: String = person.armor_loadout[group][layer]
   if definition.is_empty(): continue
   var d: Dictionary = catalog[definition]
   unit.armor_parts.append({"definition":definition,"group":group,"layer":layer,"pool":"helmet" if group == "head" else ("padding" if layer == "base" else "armor"),"condition":int(d.durability),"maximum":int(d.durability),"weight":Armor.part_weight({"definition":definition,"legacy_weight":person.legacy_armor},catalog),"hollow_slot":group})
 # Optional producer contract; absent metadata keeps the existing starter kit.
 for slot: String in ["hands","feet","cloak","belt"]:
  var definition: String = person.get("support_loadout",{}).get(slot,"")
  if definition.is_empty(): continue
  var d: Dictionary = catalog[definition]
  unit.armor_parts.append({"definition":definition,"group":"body","layer":slot,"pool":"armor","condition":int(d.durability),"maximum":int(d.durability),"weight":Armor.part_weight({"definition":definition},catalog),"hollow_slot":slot})
 unit.merge(Armor.totals(unit.armor_parts),true)
 Effects.install(unit,catalog)
 return unit
