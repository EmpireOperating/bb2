extends RefCounted
## Read-only projection from the current campaign's literal equipped records.
const Rarity = preload("res://hollow_campaign/rarity.gd")
const Armor = preload("res://src/armor.gd")
const Named = preload("res://src/named_equipment.gd")
const Arsenal = preload("res://src/arsenal.gd")
const SLOT_LABELS = {"mainhand":"Main hand","offhand":"Off hand","head":"Head","body":"Body","hands":"Hands","feet":"Feet","cloak":"Cloak","belt":"Belt","ammo":"Ammo"}

static func describe(person: Dictionary, c) -> Array:
 var out: Array = []
 if c == null or not c.soldiers.any(func(current):return is_same(current,person)):return out
 for slot: String in c.VISIBLE_SLOTS:
  if slot in ["body","head"]:
   var parts: Dictionary = c.kit_parts(person.gear.get(slot,""))
   for layer: String in Armor.LAYERS[slot]:
    _append(out,parts.get(layer,""),SLOT_LABELS[slot]+" · "+Armor.LABELS[layer],c)
  else:_append(out,c.slot_uid(person,slot),SLOT_LABELS[slot],c)
 return out

static func _append(out: Array, uid: String, slot: String, c) -> void:
 if uid.is_empty():return
 if not c.items.has(uid):
  out.append(_unavailable(uid,slot,"Unavailable item"));return
 var item: Dictionary = c.items[uid]
 if item.get("id") != uid or not c.catalog.has(item.get("definition","")):
  out.append(_unavailable(uid,slot,"Unavailable item"));return
 var d: Dictionary = c.catalog[item.definition]
 if not item.has("instance_roll"):
  if item.has("named"):
   if Named.valid(item,c.catalog):out.append(_named(uid,slot,item,d,c))
   else:out.append(_unavailable(uid,slot,d.name))
  return
 if not Rarity.valid_item(item) or item.instance_roll.seed != c.seed_value:
  out.append(_unavailable(uid,slot,d.name));return
 if item.instance_roll.tier == "common":return
 var rows: Array = []
 if d.get("slot") == "weapon":
  var ordinary: Dictionary = c.battle.weapons.get(d.get("weapon",""),{})
  if ordinary.has("min") and ordinary.has("max"):
   var rolled: Dictionary = Rarity.effective_weapon(item,ordinary)
   var low: int = ordinary.min;var high: int = ordinary.max
   var common_low: int = low+ceili(low*Rarity.ITEM_CEILINGS.common/100.0)
   var common_high: int = high+ceili(high*Rarity.ITEM_CEILINGS.common/100.0)
   var excess_low: int = maxi(0,rolled.min-common_low);var excess_high: int = maxi(0,rolled.max-common_high)
   var above := excess_low > 0 or excess_high > 0
   var comparison := "Common max %d–%d · " % [common_low,common_high]
   comparison += "+%d / +%d above Common" % [excess_low,excess_high] if above else "within Common range"
   rows.append({"cells":["Damage","%d–%d → %d–%d" % [low,high,rolled.min,rolled.max],"+%d%%" % item.instance_roll.percent.damage,comparison],"above":above})
 if d.has("durability") and int(d.durability) > 0 and (d.has("group") or d.get("slot") == "shield"):
  var base: int = d.durability;var rolled: int = Rarity.effective_definition(item,d).durability
  var common: int = base+ceili(base*Rarity.ITEM_CEILINGS.common/100.0)
  var comparison := "Common max %d · " % common
  comparison += "+%d above Common" % (rolled-common) if rolled > common else "within Common range"
  rows.append({"cells":["Protection","%d → %d" % [base,rolled],"+%d%%" % item.instance_roll.percent.protection,comparison],"above":rolled > common})
 var effective: Dictionary = Rarity.effective_definition(item,d)
 var utility: Dictionary = Rarity.utility_bonuses(item)
 var common_pool: Dictionary = Rarity.utility_pool(item.definition,"common")
 for stat: String in utility:
  var base: int = int(d.get("weight",0)) if stat == "weight" else int(d.get("effects",{}).get(stat,0))
  var rolled: int = int(effective.get("weight",0)) if stat == "weight" else int(effective.get("effects",{}).get(stat,0))
  var common: int = maxi(0,base-int(common_pool[stat])) if stat == "weight" else base+int(common_pool[stat])
  var above: bool = rolled < common if stat == "weight" else rolled > common
  var excess: int = common-rolled if stat == "weight" else rolled-common
  var comparison := ("Common min %d · lower is better · " if stat == "weight" else "Common max %d · ") % common
  comparison += "%d better than Common" % excess if above else "within Common range"
  rows.append({"cells":[Rarity.UTILITY_LABELS[stat],"%d → %d" % [base,rolled],"%+d" % (rolled-base),comparison],"above":above})
 out.append({"uid":uid,"name":d.name,"slot":slot,"tier":item.instance_roll.tier,"badge":"Saved tier: "+item.instance_roll.tier.capitalize(),"rows":rows,"state":_state(item,effective),"note":"No applicable rolled stat. This does not describe the item's other support effects." if rows.is_empty() else ""})

static func _named(uid: String, slot: String, item: Dictionary, d: Dictionary, c) -> Dictionary:
 var rows: Array = []
 var bonuses: Dictionary = Named.bonuses(item)
 var effective: Dictionary = Named.definition(item,c.catalog)
 if d.get("slot") == "weapon":
  var ordinary: Dictionary = c.battle.weapons.get(d.get("weapon",""),{})
  var rolled: Dictionary = Named.weapon(item,ordinary)
  var low: int = ordinary.min;var high: int = ordinary.max
  var common_low: int = low+ceili(low*Rarity.ITEM_CEILINGS.common/100.0)
  var common_high: int = high+ceili(high*Rarity.ITEM_CEILINGS.common/100.0)
  var excess_low: int = maxi(0,rolled.min-common_low);var excess_high: int = maxi(0,rolled.max-common_high)
  var above := excess_low > 0 or excess_high > 0
  var comparison := "Common max %d–%d · " % [common_low,common_high]
  comparison += "+%d / +%d above Common" % [excess_low,excess_high] if above else "within Common range"
  rows.append({"cells":["Damage","%d–%d → %d–%d" % [low,high,rolled.min,rolled.max],"+%d%%" % bonuses.damage,comparison],"above":above})
  if bonuses.has("penetration"):
   rows.append({"cells":["Penetration","%.1f%% → %.1f%%" % [ordinary.pierce*100,rolled.pierce*100],"+%d pp" % bonuses.penetration,"Common %.1f%%" % (ordinary.pierce*100)],"above":rolled.pierce > ordinary.pierce})
  if bonuses.has("armor_damage"):
   rows.append({"cells":["Armor damage","%.1f%% → %.1f%%" % [ordinary.armor*100,rolled.armor*100],"+%d%%" % bonuses.armor_damage,"Common %.1f%%" % (ordinary.armor*100)],"above":rolled.armor > ordinary.armor})
  if bonuses.has("fatigue"):
   rows.append(_lower("Action fatigue",ordinary.fatigue,rolled.fatigue,"-%d" % bonuses.fatigue))
   if ordinary.has("special_fatigue"):rows.append(_lower("Special fatigue",ordinary.special_fatigue,rolled.special_fatigue,"-%d" % bonuses.fatigue))
 elif bonuses.has("protection"):
  var common: int = int(d.durability)+ceili(int(d.durability)*Rarity.ITEM_CEILINGS.common/100.0)
  var comparison := "Common max %d · " % common
  comparison += "+%d above Common" % (effective.durability-common) if effective.durability > common else "within Common range"
  rows.append({"cells":["Protection","%d → %d" % [d.durability,effective.durability],"+%d%%" % bonuses.protection,comparison],"above":effective.durability > common})
 if bonuses.has("weight"):
  var base_load: int = Arsenal.LOAD.get(item.definition,0) if d.get("slot") == "weapon" else d.get("weight",0)
  rows.append(_lower("Load",base_load,Named.weight(item,base_load),"-%d%%" % bonuses.weight))
 return {"uid":uid,"name":item.named.name,"slot":slot,"tier":"","badge":"Named craftsmanship","rows":rows,"state":_state(item,effective),"note":"Saved craftsmanship bonuses; not an instance rarity tier."}

static func _lower(stat: String, original: int, rolled: int, saved: String) -> Dictionary:
 return {"cells":[stat,"%d → %d" % [original,rolled],saved,"Common %d · lower is better" % original],"above":rolled < original}

static func _unavailable(uid: String, slot: String, item_name: String) -> Dictionary:
 return {"uid":uid,"name":item_name,"slot":slot,"tier":"","badge":"Roll details unavailable","unavailable":true,"rows":[],"state":"","note":"The saved item record is missing or invalid. No tier or bonuses can be reconstructed."}

static func _state(item: Dictionary, definition: Dictionary) -> String:
 var maximum: int = definition.get("durability",0)
 if maximum <= 0:return "No condition pool · roll quality is independent of condition."
 if not item.get("condition") is int:return "Condition unavailable · roll quality is independent of condition."
 var current: int = item.condition
 var rounds: bool = definition.get("slot") == "ammo" or definition.get("weapon") in ["bolas","javelins","throwing_axes"]
 var text := "%s: %d / %d" % ["Rounds" if rounds else "Condition",current,maximum]
 if current <= 0:text += " · Exhausted" if rounds else " · Broken"
 elif current < maximum:text += " · Depleted" if rounds else " · Damaged"
 return text+" · separate from roll quality."

