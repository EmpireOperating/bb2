extends RefCounted
## Detached inspection only. Pricing stays with the actual combat implementation.
const Arsenal = preload("res://src/arsenal.gd")
const Perks = preload("res://src/perks.gd")
static func project(unit: Dictionary, item: Dictionary, battle) -> Dictionary:
 var out := {"uid":item.get("id",""),"person_id":unit.get("company_id",unit.get("id",-1)),"unit":{},"rows":[]}
 var weapon: String = item.get("definition","")
 if unit.is_empty() or not weapon in Arsenal.WEAPONS:return out
 var wearer := unit.duplicate(true)
 for slot: String in Arsenal.SLOTS:
  if wearer.arms.get(slot,{}).get("id","") == item.get("id",""):wearer.arms[slot] = {}
 wearer.arms.weapon = Arsenal.combat_item(item)
 wearer.weapon = weapon
 if weapon in Arsenal.TWO_HANDS:wearer.arms.shield = {}
 wearer.shield = not wearer.arms.shield.is_empty() and wearer.arms.shield.get("condition",0)>0
 # No target, movement or previous-attack history is promised in camp.
 wearer["perk_state"] = Perks.state()
 wearer.perk_state.throws_used = 2 # Quote repeatable cost, not first-two Opportunist discount.
 out.unit = wearer
 var w: Dictionary = battle.weapon_stats(wearer)
 var family := Arsenal.family(weapon)
 for special: bool in [false,true]:
  # The item profile and combat's one-handed restriction precede numeric conversion.
  if special and ((w.has("special_ap") and w.special_ap == null) or (w.has("special_fatigue") and w.special_fatigue == null) or (family == "sword" and weapon in Arsenal.TWO_HANDS)):continue
  var cost: Dictionary = battle.action_cost(wearer,special)
  var info: Dictionary = battle.special_info(weapon)
  var effect := str(info.text) if special else "Attack one enemy with this weapon's damage and accuracy. Armor and hit chance still apply."
  if special and family in ["sword","spear"]:effect = effect.replace("6 fatigue",str(battle.reaction_cost(wearer))+" fatigue")
  # These shared family descriptions embed old prices; effective prices live in the row.
  if special and family == "bow":effect = "+1 hex of range, +10 accuracy and +10% regular damage; armor damage is unchanged."
  if special and family == "crossbow":effect = "Ready this physical crossbow for its next shot. Loaded state follows the weapon when switched."
  if family == "throwing":effect = "-5 accuracy, +20% armour damage. Uses one weapon from the held bundle. Requires no adjacent enemy; shields are allowed." if special else effect+" Requires no adjacent enemy."
  if special and family == "axe":effect = effect.replace("Deals 24 shield condition","Deals up to %d shield condition (up to %d against Shield Expert), capped by remaining shield condition" % [battle.split_shield_damage(wearer),battle.split_shield_damage(wearer,{"perks":["shield_expert"]})])
  var minimum := int(w.get("min_range",1));var maximum: int = battle.weapon_reach(wearer,special)
  if special and family == "axe":minimum = 1
  if special and family == "polearm":minimum = 2;maximum = 2
  var reach := "%d hex%s" % [minimum,"" if minimum==1 else "es"] if minimum == maximum else "%d–%d hexes" % [minimum,maximum]
  var requirements := "A visible enemy in reach and an open attack lane; enough AP and free fatigue."
  if special and not info.target:
   reach = "Self (stance)" if family != "crossbow" else "Self (reload)"
   requirements = "No active weapon stance. Each triggered reaction costs %d additional fatigue; up to two reactions." % battle.reaction_cost(wearer)
   if family == "crossbow":requirements = "Unloaded crossbow, a matching bolt case with ammunition, and no adjacent enemy. Reload does not consume the bolt; shooting does."
  elif special and family == "axe":requirements += " Target needs an intact shield."
  elif special and family == "polearm":requirements += " An empty passable hex must exist toward the user for the pull."
  if family == "bow":requirements += " One arrow per shot; matching ammunition and no adjacent enemy."
  elif family == "crossbow" and not special:requirements += " Loaded crossbow and one bolt per shot; no adjacent enemy."
  elif family == "throwing":requirements += " Consumes one weapon from the held bundle; no adjacent enemy."
  var notes: Array[String] = []
  if battle.perk_rules:
   if family == "throwing" and Perks.has(wearer,"opportunist"):notes.append("Opportunist: only the first two throws get the AP discount; not included above.")
   if family == "bow" and not special and Perks.has(wearer,"hip_shooter"):notes.append("Hip Shooter: first-shot fatigue above; later shots in the activation add fatigue.")
   if family == "dagger" and Perks.has(wearer,"swift_stabs"):notes.append("Swift Stabs: a previous hit against the same target can reduce AP; not included above.")
   if weapon in Arsenal.TWO_HANDS and not weapon in Arsenal.RANGED and Perks.has(wearer,"vigorous_assault"):notes.append("Vigorous Assault: movement of at least two hexes can discount an attack; not included above.")
  out.rows.append({"id":"special" if special else "basic","special":special,"name":info.name if special else Arsenal.primary(weapon),"ap":cost.ap,"fatigue":cost.fatigue,"effect":effect,"range":reach,"requirements":requirements,"notes":" ".join(notes)})
 return out
