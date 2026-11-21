extends RefCounted
## Read-only projection of the actual, already-rolled merchant item.
## Browsing never mints gear, consumes RNG or reconstructs a missing roll.
const Arsenal = preload("res://src/arsenal.gd")
const Rarity = preload("res://hollow_campaign/rarity.gd")
const BASE_NOTE := "Fixed stock · rarity and rolls shown before purchase · fitting is separate"
const EFFECT_LABELS := {"skill":"Melee skill","ranged_skill":"Ranged skill","defense":"Melee defense","ranged_defense":"Ranged defense","stamina":"Stamina","initiative":"Initiative","recovery":"Recovery"}

static func _number(row: Dictionary, key: String) -> bool:
 var value: Variant = row.get(key)
 return (value is int or value is float) and is_finite(float(value))

static func stock_item(offer: Dictionary) -> Dictionary:
 var item: Variant=offer.get("item")
 if not item is Dictionary or not item.has("instance_roll") or item.get("definition")!=offer.get("definition") or not Rarity.valid_item(item):return {}
 return item

static func lines(offer: Dictionary, catalog: Dictionary, weapons: Dictionary) -> PackedStringArray:
 var item:=stock_item(offer)
 if item.is_empty():return PackedStringArray(["Roll details unavailable."])
 var d: Dictionary = Rarity.effective_definition(item,catalog.get(offer.get("definition",""),{}))
 if d.is_empty():return PackedStringArray(["Roll details unavailable."])
 var primary := PackedStringArray()
 var secondary := PackedStringArray()
 var slot := str(d.get("slot",""))
 if slot == "weapon":
  var w: Dictionary = Rarity.effective_weapon(item,weapons.get(d.get("weapon",""),{}))
  if _number(w,"min") and _number(w,"max"): primary.append("Damage %d–%d (+%d%%)" % [w.min,w.max,item.instance_roll.percent.damage])
  if _number(w,"armor"): primary.append("Armor dmg %d%%" % roundi(float(w.armor)*100))
  if _number(w,"pierce"): primary.append("Penetration %d%%" % roundi(float(w.pierce)*100))
  if _number(w,"skill"): secondary.append("Accuracy %+d" % w.skill)
  if _number(w,"min_range") and _number(w,"reach"): secondary.append("Reach %d–%d" % [w.min_range,w.reach])
  elif _number(w,"reach"): secondary.append("Reach %d" % w.reach)
  if _number(w,"hands"): secondary.append("Hands %d" % w.hands)
  if _number(w,"ap") and _number(w,"fatigue"): secondary.append("Basic %d AP / %d fatigue" % [w.ap,w.fatigue])
  if w.get("ammo") is String and not w.ammo.is_empty(): secondary.append("Uses "+w.ammo)
  # Thrown weapon durability holds bundle count, not protection or weapon wear.
  if _number(d,"durability") and d.durability > 0: primary.append("Bundle %d" % d.durability)
 elif slot == "shield":
  # Battle.shield_defence's retained intact, pre-perk defaults for legacy shields.
  var melee: int = int(d.melee_defense) if _number(d,"melee_defense") else 20
  var ranged: int = int(d.ranged_defense) if _number(d,"ranged_defense") else 15
  primary.append("Melee defense %+d · Ranged defense %+d (intact)" % [melee,ranged])
  if _number(d,"durability") and d.durability > 0: secondary.append("Durability %d" % d.durability)
 elif slot == "ammo":
  if d.get("ammo") is String: primary.append(d.ammo.capitalize())
  if _number(d,"durability") and d.durability > 0: primary.append("Rounds %d" % d.durability)
 elif _number(d,"durability"):
  primary.append("Protection %d (+%d%%)" % [d.durability,item.instance_roll.percent.protection] if d.durability > 0 else "No armor protection")
 var definition := str(offer.get("definition",""))
 var load_text := ""
 if Arsenal.LOAD.has(definition): load_text = "Load %d" % Arsenal.LOAD[definition]
 elif _number(d,"weight"): load_text = "Load %d" % d.weight
 if not load_text.is_empty():
  if slot == "shield": secondary.append(load_text)
  else: primary.append(load_text)
 var effects: Dictionary = d.get("effects",{}) if d.get("effects") is Dictionary else {}
 for field: String in EFFECT_LABELS:
  if _number(effects,field) and effects[field] != 0: secondary.append("%s %+d" % [EFFECT_LABELS[field],effects[field]])
 if _number(effects,"move_fatigue_discount") and effects.move_fatigue_discount != 0: secondary.append("Move fatigue %+d/edge" % -effects.move_fatigue_discount)
 if _number(effects,"carried_load_discount") and effects.carried_load_discount != 0: secondary.append("Reserve load %+d/slot" % -effects.carried_load_discount)
 if slot == "belt" and _number(d,"capacity") and d.capacity > 0: secondary.append("Reserve capacity +%d" % d.capacity)
 if slot == "belt" and _number(d,"switch_ap") and d.switch_ap == 2: secondary.append("Weapon switching 2 AP · Quick Hands free first")
 var out := PackedStringArray()
 if not primary.is_empty(): out.append(" · ".join(primary))
 if not secondary.is_empty(): out.append(" · ".join(secondary))
 for line: String in Rarity.utility_lines(item,catalog.get(offer.get("definition",""),{})):out.append("Utility roll · "+line)
 return out if not out.is_empty() else PackedStringArray(["Properties unavailable."])
