extends RefCounted
## Explanation only. Never install modifiers or write a person/preview.
const People = preload("res://src/people.gd")
const Perks = preload("res://src/perks.gd")
const Arsenal = preload("res://src/arsenal.gd")
const Stats = preload("res://hollow_campaign/person_stats.gd")
const Effects = preload("res://hollow_campaign/equipment_effects.gd")

static func add(rows: Array, source: String, amount: int, rule: String = "", include_zero: bool = false) -> void:
 if amount != 0 or include_zero:rows.append({"source":source,"amount":amount,"rule":rule})

static func item_name(world, item: Dictionary) -> String:
 var uid: String = str(item.get("item",""))
 if world.campaign.items.has(uid):return world.campaign.item_name(uid)
 return str(world.campaign.catalog.get(item.get("definition",""),{}).get("name",item.get("definition","Equipment")))

static func loads(world, u: Dictionary, initiative: bool, rows: Array) -> void:
 for part: Dictionary in u.get("armor_parts",[]):add(rows,item_name(world,part)+" · worn load",-int(part.weight))
 var raw := int(u.get("load",0))
 var normal := Perks.armor_load(u)
 if Perks.has(u,"brawny"):add(rows,"Brawny",raw-normal,"Armor load ×0.7, rounded up",true)
 if initiative and world.battle.perk_rules and Perks.has(u,"perfect_fit"):
  add(rows,"Perfect Fit",normal-Perks.armor_load(u,true),"Initiative armor load ×(1 − 0.2 × medium fit), rounded up",true)
 var arms: Dictionary = u.get("arms",{})
 for slot: String in Arsenal.SLOTS:
  var item: Dictionary = arms.get(slot,{})
  if item.is_empty():continue
  var single := {slot:item}
  var weight := Arsenal.load(single)
  var bags := Arsenal.load(single,Perks.has(u,"bags_and_belts"))
  add(rows,item_name(world,item)+(" · carried load" if slot in Arsenal.CARRIED else " · load"),-weight,"Carried weight is halved, rounded up" if slot in Arsenal.CARRIED else "")
  if Perks.has(u,"bags_and_belts") and slot in Arsenal.CARRIED:
   add(rows,"Bags and Belts · "+item_name(world,item),weight-bags,"Carried two-handed arms retain half load; other carried arms have no load",true)
  var discount := int(u.get("carried_load_discount",0)) if u.get("inventory_balance",false) else 0
  var discounted := Arsenal.load(single,Perks.has(u,"bags_and_belts"),discount)
  if bags != discounted:
   var names: Array[String] = []
   for part: Dictionary in u.get("armor_parts",[]):
    if Effects.profile([part],world.campaign.catalog).carried_load_discount != 0:names.append(item_name(world,part))
   add(rows,", ".join(names)+" · carried-load relief on "+item_name(world,item),bags-discounted,"Per carried slot, capped at its load")

static func describe(world, person: Dictionary, attr: String, offer: bool = false) -> Dictionary:
 if person.is_empty() or attr not in People.ATTRS:return {}
 var u: Dictionary = world.person_preview(person,offer)
 var base := Stats.permanent(person,attr,offer)
 var rows: Array = []
 var wound := not offer and int(person.get("wound_days",0)) > 0
 var scars: Array = [] if offer else person.get("scars",[])
 if wound and attr in ["skill","ranged_skill","health"]:add(rows,"Deep wound",-12 if attr == "health" else -10,"Temporary injury; before percentage perks")
 if "clouded_eye" in scars and attr in ["skill","ranged_skill"]:add(rows,"Clouded eye",-4,"Permanent scar")
 if attr in Effects.BASE_FIELDS:
  for part: Dictionary in u.get("armor_parts",[]):add(rows,item_name(world,part),int(Effects.profile([part],world.campaign.catalog)[attr]),"Equipment effect; positive effects require an intact item")
 match attr:
  "health":
   if Perks.has(person,"colossus"):
    var health := base-(12 if wound else 0)
    add(rows,"Colossus",floori(health*1.25)-health,"Maximum health ×1.25, rounded down",true)
  "skill", "ranged_skill":
   if u.temperament in ["aggressive","cautious"]:add(rows,People.TEMPERAMENTS[u.temperament].name,5 if u.temperament == "aggressive" else -4)
   if "weapon_drill" in person.get("perks",[]):add(rows,"Weapon handling",5)
   if (attr == "ranged_skill") == (u.weapon in Arsenal.RANGED):add(rows,item_name(world,u.get("arms",{}).get("weapon",{"definition":u.weapon}))+" · accuracy",int(world.battle.weapon_stats(u).skill))
   if Perks.has(person,"hybridization"):
    var opposite := "skill" if attr == "ranged_skill" else "ranged_skill"
    var value := int(u.get(opposite,Stats.permanent(person,opposite,offer)-(10 if wound else 0)-(4 if "clouded_eye" in scars else 0)))
    add(rows,"Hybridization",floori(value*0.1),"10% of preview "+People.LABELS[opposite]+" (%d), rounded down" % value,true)
  "defense", "ranged_defense":
   if Perks.has(person,"dodge"):add(rows,"Dodge",floori(0.15*maxi(0,world.battle.initiative_value(u))),"15% of nonnegative equipped initiative, rounded down",true)
   if Perks.has(person,"balance"):add(rows,"Balance",floori(6*Perks.medium(u)),"6 × medium fit, rounded down",true)
   if u.get("shield",false):
    var item: Dictionary = u.get("arms",{}).get("shield",{})
    var shield: Dictionary = world.battle.armor_catalog.get(item.get("definition","shield"),{})
    var value := int(shield.get("ranged_defense" if attr == "ranged_defense" else "melee_defense",15 if attr == "ranged_defense" else 20)) if world.battle.core_rules else 10
    add(rows,item_name(world,item)+" · shield defence",value)
    var final: int = world.battle.shield_defence(u,attr == "ranged_defense") if world.battle.core_rules else 10
    if final != value:
     add(rows,"Shield drill" if "shield_drill" in u.get("perks",[]) else "Shield Expert",final-value,"Shield defence ×1.25, rounded down")
   if u.temperament == "cautious":add(rows,"Cautious",5)
  "resolve":
   if Perks.has(person,"fortified_mind"):add(rows,"Fortified Mind",floori(base*1.25)-base,"Resolve ×1.25, rounded down",true)
   if u.temperament == "stoic":add(rows,"Stoic",10)
   if "steadfast" in person.get("perks",[]):add(rows,"Steadfast",15)
  "stamina", "initiative":
   loads(world,u,attr == "initiative",rows)
   if attr == "initiative":
    var fatigue := int(u.get("fatigue",0))
    add(rows,"Current fatigue",-fatigue)
    if world.battle.perk_rules and Perks.has(u,"relentless"):add(rows,"Relentless",fatigue-ceili(fatigue*0.5),"Fatigue initiative penalty ×0.5, rounded up",true)
    if u.temperament == "stoic":add(rows,"Stoic",-5)
   var value := base
   for row: Dictionary in rows:value += int(row.amount)
   if attr == "stamina":
    if u.get("stat_rules",false):add(rows,"Minimum available stamina",maxi(15,value)-value,"Floor of 15")
    else:add(rows,"Earlier stamina rules",100-value,"Fixed available stamina of 100")
   elif not world.battle.perk_rules and not world.battle.core_rules:add(rows,"Minimum initiative",maxi(0,value)-value,"Floor of 0")
 var total: int = world.equipped_attribute(person,u,attr,offer)
 var sum_value := base
 var lines: Array[String] = [People.LABELS[attr].to_upper(),"Permanent base: %d" % base,"Current growth + saved rarity; already includes training and Gifted."]
 if rows.is_empty():lines.append("No applied modifiers (+0).")
 for row: Dictionary in rows:
  sum_value += int(row.amount)
  lines.append("%s: %+d%s" % [row.source,row.amount," · "+row.rule if not row.rule.is_empty() else ""])
 lines.append("Equipped total: %d" % total)
 lines.append("Company preview only. Target, range, morale and adjacency modifiers are not included.")
 return {"base":base,"rows":rows,"total":total,"sum":sum_value,"text":"\n".join(lines)}
