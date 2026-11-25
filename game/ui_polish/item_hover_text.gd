extends RefCounted
## Presentation of one already-admitted physical record. Never computes a loadout.
const Equipment = preload("res://hollow_campaign/appearance.gd")
const Named = preload("res://src/named_equipment.gd")
const Arsenal = preload("res://src/arsenal.gd")
const Crossbows = preload("res://crossbows/ui.gd")
const WeaponSkills = preload("res://company_town/weapon_skill_preview.gd")

static func item(record: Dictionary, catalog: Dictionary, unit: Dictionary, battle, ammo: Dictionary, origin: String) -> Dictionary:
 var uid: String = record.id
 var definition := str(record.get("definition",""))
 var tier := Equipment.item_tier(record,catalog)
 var out := {"uid":uid,"key":"","title":"Invalid equipment metadata","tier":tier,"class":"","stats":"Effective stats unavailable.","skills":"","record":"UID %s · %s\n%s" % [uid,definition,origin]}
 if tier == "invalid":return out
 var base: Dictionary = catalog[definition]
 var effective := Named.definition(record,catalog)
 var slot: String = base.slot
 out.title = str(effective.get("name",definition))
 out["class"] = "Named craftsmanship" if tier == "named" else "Unrated" if tier.is_empty() else tier.capitalize()
 if base.has("tier") and base.has("quality"):out["class"] += " · Tier %d %s" % [base.tier,base.quality]
 var lines := PackedStringArray()
 var weapon: Dictionary = {}
 var base_weapon: Dictionary = {}
 if slot == "weapon":
  var weapon_id = base.get("weapon",definition)
  base_weapon = Equipment._weapons.get(weapon_id,{})
  if not base_weapon.is_empty():weapon = Named.weapon(record,base_weapon)
  if not weapon.is_empty():
   lines.append("Damage %d–%d%s" % [weapon.min,weapon.max,"  (base %d–%d)" % [base_weapon.min,base_weapon.max] if weapon.min != base_weapon.min or weapon.max != base_weapon.max else ""])
   lines.append("Armor damage %s%%\nArmor penetration %s%%" % [_percent(weapon.armor),_percent(weapon.pierce)])
   lines.append("Accuracy %+d  ·  %d %s  ·  Range %d–%d" % [weapon.get("skill",0),weapon.get("hands",1),"hands" if weapon.get("hands",1) == 2 else "hand",weapon.get("min_range",1),weapon.get("reach",1)])
 var load_value := Named.weight(record,int(Arsenal.LOAD[definition])) if Arsenal.LOAD.has(definition) else int(effective.get("weight",0))
 var maximum := int(record.get("maximum",effective.get("durability",0)))
 var condition := int(record.get("condition",maximum))
 var broken := maximum > 0 and condition <= 0
 var rounds := Equipment.is_round_supply(base)
 var protective := base.has("group") and slot != "shield" and int(base.get("durability",0)) > 0
 var load_row := "Load %d" % load_value
 if maximum > 0:
  var state := " · EMPTY" if broken and rounds else " · BROKEN" if broken else ""
  var resource := "Rounds" if rounds else "Protection" if protective else "Condition"
  var baseline := " (base %d)" % base.durability if protective and maximum != int(base.durability) else ""
  load_row = "%s %d/%d%s%s  ·  %s" % [resource,condition,maximum,state,baseline,load_row]
 lines.append(load_row)
 if protective and slot in ["hands","feet","cloak","belt"]:lines.append("Pooled body protection only")
 if slot == "shield":
  var melee := int(effective.get("melee_defense",0))
  var ranged := int(effective.get("ranged_defense",0))
  lines.append("Melee defense %+d  ·  Ranged defense %+d" % [0 if broken else melee,0 if broken else ranged])
  if broken:lines.append("When intact: melee %+d  ·  ranged %+d" % [melee,ranged])
 for field: String in Equipment.EFFECT_LABELS:
  var value := int(effective.get("effects",{}).get(field,0))
  if value != 0:lines.append("%s %+d%s" % [Equipment.EFFECT_LABELS[field],value," (inactive while broken)" if broken and value > 0 else ""])
 if slot == "belt":lines.append("Pocket capacity +%d" % int(effective.get("capacity",0)))
 if slot == "ammo" and base.has("description"):lines.append(str(base.description))
 var readiness := Crossbows.readiness(record,ammo,catalog,true)
 if not readiness.is_empty():lines.append(readiness.replace("\n"," · "))
 out.stats = "\n".join(lines)
 if not weapon.is_empty():out.skills = _skills(record,unit,battle,weapon)
 if base.has("price"):out.record += " · Catalog value %d" % int(base.price)
 if tier == "named":out.record += "\n"+Named.summary(record)+"\nSource: "+str(record.named.source)
 return out

static func key(entry: Dictionary) -> Dictionary:
 return {"uid":"","key":entry.key_id,"title":entry.name,"tier":"","class":"Company key item · Read-only","stats":entry.status+"\nOpens the matching treasury. Stays in the keyring after use.","skills":"","record":"Cannot be equipped, sold or dragged."}

static func _percent(multiplier: float) -> String:
 return String.num(multiplier*100.0,2).trim_suffix(".0")

static func _skills(record: Dictionary, unit: Dictionary, battle, weapon: Dictionary) -> String:
 var rows: Array = WeaponSkills.project(unit,record,battle).rows if battle != null else []
 if rows.is_empty():
  var costs := "Basic %d AP / %d fatigue (base)" % [weapon.ap,weapon.fatigue]
  if weapon.get("special_ap") != null and weapon.get("special_fatigue") != null:costs += "\nSpecial %d AP / %d fatigue (base)" % [weapon.special_ap,weapon.special_fatigue]
  return costs
 var skills := PackedStringArray()
 var family := Arsenal.family(record.definition)
 for row: Dictionary in rows:
  skills.append("%s · %d AP / %d fatigue · %s" % [row.name,row.ap,row.fatigue,row.range])
  # The common hit/cost caveats are identical for each skill. Keep the actual
  # distinct effects and restrictions, not the boilerplate targeting sentences.
  var effect: String = row.effect.trim_prefix("Attack one enemy with this weapon's damage and accuracy. Armor and hit chance still apply.").strip_edges()
  var needs: String = row.requirements.trim_prefix("A visible enemy in reach and an open attack lane; enough AP and free fatigue.").strip_edges()
  if effect == "Requires no adjacent enemy." and needs.contains("no adjacent enemy"):effect = ""
  if needs == "An empty passable hex must exist toward the user for the pull." and effect.contains("into an empty passable hex"):needs = ""
  if effect.contains("Uses one weapon from the held bundle."):needs = needs.trim_prefix("Consumes one weapon from the held bundle; no adjacent enemy.").strip_edges()
  if family == "sword" and row.special and effect.contains("Each counter costs") and needs.begins_with("No active weapon stance."):needs = "No active weapon stance."
  if family == "crossbow":
   effect = ""
   needs = "Unloaded, matching bolts, no adjacent enemy.\nReload uses no bolt; readiness follows the weapon." if row.special else "Loaded, 1 bolt per shot, no adjacent enemy."
  if not effect.is_empty():skills.append(effect)
  if not needs.is_empty():skills.append(needs)
  if not row.notes.is_empty():skills.append(row.notes)
  var base_ap = weapon.get("special_ap",row.ap) if row.special else weapon.ap
  var base_fatigue = weapon.get("special_fatigue",row.fatigue) if row.special else weapon.fatigue
  if row.ap != base_ap or row.fatigue != base_fatigue:skills.append("Base cost %d AP / %d fatigue" % [base_ap,base_fatigue])
 return "\n".join(skills)
