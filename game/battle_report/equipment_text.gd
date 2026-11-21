extends RefCounted
## Player-facing recovered gear only; technical audit formatters remain untouched.
const Equipment = preload("res://hollow_campaign/appearance.gd")
const Named = preload("res://src/named_equipment.gd")
const Arsenal = preload("res://src/arsenal.gd")
static var weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
static func title(item: Dictionary, catalog: Dictionary) -> String:
 if item.is_empty() or Equipment.item_tier(item,catalog) == "invalid":return "Unavailable equipment"
 return str(Named.definition(item,catalog).get("name","Unknown equipment")).trim_suffix(" option")
static func condition(item: Dictionary, d: Dictionary) -> String:
 var maximum := int(item.get("maximum",d.get("durability",0)))
 if maximum <= 0:return "No durability"
 var supply := Equipment.is_round_supply(d)
 var current := int(item.get("condition",maximum))
 return "%s %d/%d%s" % ["Rounds" if supply else "Condition",current,maximum,(" · EMPTY" if supply else " · BROKEN") if current <= 0 else ""]
static func identity(item: Dictionary, catalog: Dictionary) -> String:
 if item.is_empty() or Equipment.item_tier(item,catalog) == "invalid":return "Equipment details unavailable"
 return title(item,catalog)+" · "+Equipment.item_tier(item,catalog).capitalize()+" · "+condition(item,Named.definition(item,catalog))
static func details(item: Dictionary, catalog: Dictionary) -> String:
 if item.is_empty() or Equipment.item_tier(item,catalog) == "invalid":return "Equipment details unavailable."
 var d: Dictionary = Named.definition(item,catalog)
 var ordinary: Dictionary = catalog[item.definition]
 var lines := PackedStringArray([Equipment.item_tier(item,catalog).capitalize(),condition(item,d)])
 var maximum := int(item.get("maximum",d.get("durability",0)))
 var broken := maximum > 0 and int(item.get("condition",maximum)) <= 0
 if int(d.get("durability",0)) > 0 and d.has("group") and d.get("slot","") != "shield":
  lines.append("Protection %d" % int(d.durability))
 if d.get("slot","") == "shield":
  lines.append("Shield defense while equipped%s" % (" · inactive while broken" if broken else ""))
  lines.append("Melee defense %+d · Ranged defense %+d" % [0 if broken else int(d.get("melee_defense",20)),0 if broken else int(d.get("ranged_defense",15))])
 if d.get("slot","") == "weapon":
  var w: Dictionary = Named.weapon(item,weapons.get(ordinary.get("weapon",item.definition),{}))
  if not w.is_empty():
   lines.append("Damage %d–%d" % [w.min,w.max])
   lines.append("Armour damage %d%% · Penetration %d%%" % [roundi(w.armor*100),roundi(w.pierce*100)])
   lines.append("Accuracy %+d · %d-handed · Range %d–%d" % [w.get("skill",0),w.get("hands",1),w.get("min_range",1),w.get("reach",1)])
   lines.append("Attack cost: %d AP · %d fatigue" % [w.ap,w.fatigue])
   if w.has("special_ap") and w.has("special_fatigue"):lines.append("Special cost: %d AP · %d fatigue" % [w.special_ap,w.special_fatigue])
   lines.append("Weapon costs before companion and perk modifiers.")
 var load_value := int(d.get("weight",0))
 if Arsenal.LOAD.has(item.definition):load_value = Named.weight(item,int(Arsenal.LOAD[item.definition]))
 lines.append("Equipment load %d" % load_value)
 for field: String in Equipment.EFFECT_LABELS:
  var value := int(d.get("effects",{}).get(field,0))
  if value != 0:lines.append("%s %+d%s" % [Equipment.EFFECT_LABELS[field],value," (inactive while broken)" if broken and value > 0 else ""])
 if d.get("slot","") == "belt":lines.append("Carried reserve capacity +%d" % int(d.get("capacity",0)))
 if maximum <= 0 and d.get("slot","") in ["hands","feet","cloak","belt"]:lines.append("Utility bonuses stay active without durability.")
 return "\n".join(lines)
