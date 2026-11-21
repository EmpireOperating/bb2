extends RefCounted
const Named = preload("res://src/named_equipment.gd")
## Physical carried equipment and explicitly priced weapon actions.
const CARRIED = ["carry1","carry2","carry3","carry4"]
const SHIELDS = ["shield", "buckler", "round_shield", "hm_trial_v1:offhands-02-round-wooden-shield", "hollow_campaign:buckler"]
const SLOTS = ["weapon","shield","carry1","carry2","carry3","carry4","ammo"]

static func bag_slots(u: Dictionary) -> Array:
 if u.get("hollow_systems",false) and u.get("hollow_capacity",0) in [2,3,4]: return CARRIED.slice(0,int(u.hollow_capacity))
 return CARRIED.duplicate() if "bags_and_belts" in u.get("perks",[]) else ["carry1","carry2"]

static func shield(definition: String) -> bool:
 return definition in SHIELDS
const WEAPONS = ["bolas", "javelins", "throwing_axes", "sword", "spear", "axe", "bow", "mace", "hammer", "dagger", "polearm", "crossbow", "shortsword", "falchion", "greatsword", "militia_spear", "heavy_spear", "hatchet", "greataxe", "club", "maul", "knife", "glaive", "shortbow", "warbow", "heavy_crossbow", "short_sword", "cudgel", "pike", "short_bow", "hm_trial_v1:old24-shieldbearer_heavy", "hm_trial_v1:old24-archer_weapon", "hm_trial_v1:old24-archer_heavy", "hm_trial_v1:old24-polearm_weapon", "hm_trial_v1:old24-polearm_heavy", "hm_trial_v1:old24-duelist_weapon", "hm_trial_v1:old24-duelist_heavy", "hm_trial_v1:old24-medic_weapon", "hm_trial_v1:old24-medic_heavy", "hm_trial_v1:old24-ward_spear", "hm_trial_v1:old24-gatewarden_blade", "hm_trial_v1:old24-reedrunner_bow", "hm_trial_v1:old24-ferryman_hook", "hm_trial_v1:old24-quarry_estoc", "hm_trial_v1:old24-wayfarer_lancet", "hm_trial_v1:additional_fighting_axe", "hm_trial_v1:twohand_sword", "hm_trial_v1:twohand_maul"]
const TWO_HANDS = ["bow", "polearm", "crossbow", "greatsword", "greataxe", "maul", "glaive", "shortbow", "warbow", "heavy_crossbow", "pike", "short_bow", "hm_trial_v1:old24-archer_weapon", "hm_trial_v1:old24-archer_heavy", "hm_trial_v1:old24-polearm_weapon", "hm_trial_v1:old24-polearm_heavy", "hm_trial_v1:old24-ward_spear", "hm_trial_v1:old24-reedrunner_bow", "hm_trial_v1:old24-ferryman_hook", "hm_trial_v1:twohand_sword", "hm_trial_v1:twohand_maul"]
const RANGED = ["bolas", "javelins", "throwing_axes", "bow", "crossbow", "shortbow", "warbow", "heavy_crossbow", "short_bow", "hm_trial_v1:old24-archer_weapon", "hm_trial_v1:old24-archer_heavy", "hm_trial_v1:old24-reedrunner_bow"]
const PRIMARY = {"throwing":"Quick throw","sword":"Slash","spear":"Thrust","axe":"Chop","mace":"Strike","hammer":"Hammer blow","dagger":"Stab","polearm":"Reach strike","bow":"Quick shot","crossbow":"Shoot bolt"}
const SPECIAL = {
 "throwing":{"name":"Heavy throw","ap":5,"fatigue":20,"target":true,"text":"-5 accuracy, +20% armour damage. Uses one weapon from the held bundle. Can throw while engaged; shields are allowed."},
 "sword":{"name":"Riposte","ap":4,"fatigue":18,"target":false,"text":"Until your next turn: counter the first two missed adjacent melee attacks. Each counter costs 6 fatigue; moving, attacking or switching ends the stance."},
 "spear":{"name":"Spearwall","ap":4,"fatigue":30,"target":false,"text":"Until your next turn, entering enemies are struck for half damage and repelled on a hit. A breach ends it unless you have Spear Mastery. Requires open ground around you unless mastered."},
 "axe":{"name":"Split shield","ap":5,"fatigue":22,"target":true,"text":"Adjacent shield: 90% base chance, +5 if outnumbered. Deals 24 shield condition; no body damage. A broken shield gives no defence or linked support."},
 "mace":{"name":"Staggering blow","ap":5,"fatigue":22,"target":true,"text":"-10 accuracy, 75% damage. A hit removes 2 current AP and 2 AP next turn. Repeated hits do not stack the next-turn penalty."},
 "hammer":{"name":"Shatter armour","ap":6,"fatigue":26,"target":true,"text":"-5 accuracy. Body hit: double armour wear, half flesh damage. Useful for opening heavy armour; expensive and destructive to loot."},
 "dagger":{"name":"Puncture","ap":4,"fatigue":18,"target":true,"text":"-20 accuracy. Body hit: 80% weapon damage directly to health, preserving armour and padding. Best against exposed or surrounded targets."},
 "polearm":{"name":"Hook and drag","ap":5,"fatigue":22,"target":true,"text":"At two hexes: -10 accuracy, 65% damage; on a hit pull the target one hex toward you into an empty passable hex."},
 "bow":{"name":"Aimed shot","ap":6,"fatigue":18,"target":true,"text":"+1 hex of range, +15 accuracy and 15% damage. Uses one arrow; leaves less AP for movement. Cannot shoot while engaged."},
 "crossbow":{"name":"Reload","ap":4,"fatigue":10,"target":false,"text":"Ready an unloaded crossbow. Requires a bolt in your case and no adjacent enemy. Loaded state follows the physical weapon through switches."}}

const FAMILIES = {"bolas": "throwing", "javelins": "throwing", "throwing_axes": "throwing", "sword": "sword", "spear": "spear", "axe": "axe", "bow": "bow", "mace": "mace", "hammer": "hammer", "dagger": "dagger", "polearm": "polearm", "crossbow": "crossbow", "shortsword": "sword", "falchion": "sword", "greatsword": "sword", "militia_spear": "spear", "heavy_spear": "spear", "hatchet": "axe", "greataxe": "axe", "club": "mace", "maul": "hammer", "knife": "dagger", "glaive": "polearm", "shortbow": "bow", "warbow": "bow", "heavy_crossbow": "crossbow", "short_sword": "sword", "cudgel": "mace", "pike": "spear", "short_bow": "bow", "hm_trial_v1:old24-shieldbearer_heavy": "mace", "hm_trial_v1:old24-archer_weapon": "bow", "hm_trial_v1:old24-archer_heavy": "bow", "hm_trial_v1:old24-polearm_weapon": "spear", "hm_trial_v1:old24-polearm_heavy": "polearm", "hm_trial_v1:old24-duelist_weapon": "sword", "hm_trial_v1:old24-duelist_heavy": "sword", "hm_trial_v1:old24-medic_weapon": "dagger", "hm_trial_v1:old24-medic_heavy": "axe", "hm_trial_v1:old24-ward_spear": "spear", "hm_trial_v1:old24-gatewarden_blade": "sword", "hm_trial_v1:old24-reedrunner_bow": "bow", "hm_trial_v1:old24-ferryman_hook": "polearm", "hm_trial_v1:old24-quarry_estoc": "sword", "hm_trial_v1:old24-wayfarer_lancet": "dagger", "hm_trial_v1:additional_fighting_axe": "axe", "hm_trial_v1:twohand_sword": "sword", "hm_trial_v1:twohand_maul": "hammer"}

static func family(weapon: String) -> String:
 return FAMILIES.get(weapon,weapon)

static func special(weapon: String) -> Dictionary:
 if family(weapon) == "spear" and weapon in TWO_HANDS:
  var wall = SPECIAL.spear.duplicate()
  wall.ap = 6; wall.fatigue = 35
  return wall
 return {"name":"No weapon","ap":0,"fatigue":0,"target":false,"text":"Equip a weapon to attack."} if weapon.is_empty() else SPECIAL[family(weapon)]

static func primary(weapon: String) -> String:
 return "Unarmed" if weapon.is_empty() else PRIMARY[family(weapon)]

static func ammo_type(weapon: String) -> String:
 return "arrows" if family(weapon) == "bow" else "bolts" if family(weapon) == "crossbow" else ""

static func ammo_kind(definition: String, catalog: Dictionary) -> String:
 # Definition identity is not ammunition kind: all arrow bundles feed bows.
 var d: Dictionary = catalog.get(definition,{})
 return str(d.get("ammo","")) if d.get("slot","") == "ammo" else ""

static func ammo_supply_cost(definition: String) -> int:
 return 3 if family(definition) == "throwing" else 1 if definition in ["arrows","bodkin_quiver","deep_quiver","bolts"] else 0

static func empty_arms() -> Dictionary:
 var out = {}
 for slot in SLOTS: out[slot] = {}
 return out

static func allowed(slot: String, definition: String, catalog: Dictionary) -> bool:
 if not catalog.has(definition): return false
 var kind = catalog[definition].slot
 return kind in ["weapon","shield","ammo"] if slot in CARRIED else kind == slot

static func combat_item(item: Dictionary) -> Dictionary:
 var out = {"id":item.id,"definition":item.definition,"condition":item.condition,"loaded":item.get("loaded",false)}
 if item.has("named"): out["named"] = item.named.duplicate(true)
 if item.has("instance_roll"): out["instance_roll"] = item.instance_roll.duplicate(true)
 return out

static func valid_arms(value: Variant, catalog: Dictionary) -> bool:
 if not value is Dictionary or value.size() not in [5,7]: return false
 if value.keys().any(func(slot): return not slot in SLOTS): return false
 if ["weapon","shield","carry1","carry2","ammo"].any(func(slot): return not value.has(slot)): return false
 var ids = {}
 for slot in SLOTS:
  var item = value.get(slot,{})
  if not item is Dictionary: return false
  if item.is_empty():
   continue
  if not item.get("id") is String or item.id.is_empty() or ids.has(item.id) or not item.get("definition") is String or not allowed(slot,item.definition,catalog): return false
  ids[item.id] = true
  if not Named.valid(item,catalog): return false
  if not item.get("condition") is int or item.condition < 0 or item.condition > Named.definition(item,catalog).durability or not item.get("loaded") is bool: return false
  if item.loaded and family(item.definition) != "crossbow": return false
 if value.weapon.get("definition","") in TWO_HANDS and not value.shield.is_empty(): return false
 return true

static func weapon_offer(p: Dictionary, varied: bool, ranged_expansion: bool = false) -> void:
 # Identity-derived variety does not consume population or combat RNG.
 if varied:
  var n = int(p.person_seed)
  if family(p.weapon) == "bow" and n%3 == 0: p.weapon = "crossbow"
  elif p.weapon == "axe" and n%3 != 0: p.weapon = "mace" if n%3 == 1 else "hammer"
  elif p.weapon == "spear" and p.loadout.shield == "" and n%2 == 0: p.weapon = "polearm"
  var choices = {"sword":["shortsword","sword","falchion"],"spear":["militia_spear","spear","heavy_spear"],"axe":["hatchet","axe"],"mace":["club","mace"],"dagger":["knife","dagger"],"bow":["shortbow","bow"]}.get(p.weapon,[p.weapon])
  p.weapon = choices[(n/7)%choices.size()]
  if ranged_expansion and p.weapon in RANGED and n%5 == 0: p.weapon = "javelins" if n%2 == 0 else "throwing_axes"
  p.loadout.weapon = p.weapon
  if p.weapon in TWO_HANDS: p.loadout.shield = ""
 p["carried_loadout"] = ["dagger" if p.weapon in RANGED or p.weapon == "polearm" else "",""]
 p["ammo_loadout"] = ammo_type(p.weapon)

# Fatigue capacity/initiative penalties. Carried arms weigh half, rounded up.
const LOAD = {"bolas": 6, "javelins": 6, "throwing_axes": 8, "sword": 8, "shortsword": 6, "falchion": 9, "greatsword": 16, "spear": 8, "militia_spear": 6, "heavy_spear": 10, "axe": 10, "hatchet": 6, "greataxe": 18, "mace": 10, "club": 7, "maul": 18, "hammer": 10, "dagger": 3, "knife": 2, "polearm": 12, "glaive": 15, "bow": 8, "shortbow": 6, "warbow": 12, "crossbow": 10, "heavy_crossbow": 14, "shield": 12, "buckler": 5, "round_shield": 8, "arrows": 2, "bodkin_quiver": 2, "deep_quiver": 2, "bolts": 2, "short_sword": 6, "cudgel": 6, "pike": 10, "short_bow": 5, "hm_trial_v1:old24-shieldbearer_heavy": 9, "hm_trial_v1:old24-archer_weapon": 8, "hm_trial_v1:old24-archer_heavy": 10, "hm_trial_v1:old24-polearm_weapon": 11, "hm_trial_v1:old24-polearm_heavy": 12, "hm_trial_v1:old24-duelist_weapon": 5, "hm_trial_v1:old24-duelist_heavy": 8, "hm_trial_v1:old24-medic_weapon": 2, "hm_trial_v1:old24-medic_heavy": 6, "hm_trial_v1:old24-ward_spear": 9, "hm_trial_v1:old24-gatewarden_blade": 9, "hm_trial_v1:old24-reedrunner_bow": 6, "hm_trial_v1:old24-ferryman_hook": 14, "hm_trial_v1:old24-quarry_estoc": 5, "hm_trial_v1:old24-wayfarer_lancet": 3, "hm_trial_v1:additional_fighting_axe": 9, "hm_trial_v1:twohand_sword": 12, "hm_trial_v1:offhands-02-round-wooden-shield": 8, "hollow_campaign:buckler": 5, "hm_trial_v1:twohand_maul": 18}

static func load(arms: Dictionary, bags: bool = false, carried_discount: int = 0) -> int:
 var total = 0
 for slot in SLOTS:
  var item: Dictionary = arms.get(slot,{})
  var weight: int = Named.weight(item,LOAD.get(item.get("definition",""),0))
  if slot in CARRIED:
   total += (0 if not item.get("definition","") in TWO_HANDS else ceili(weight/2.0)) if bags else maxi(0,ceili(weight/2.0)-(maxi(0,carried_discount) if not item.is_empty() else 0))
  else: total += weight
 return total

static func background_offer(p: Dictionary, weights: Dictionary) -> void:
 # Equipment RNG is independent of identity/stat/talent/tree rolls.
 var rng = RandomNumberGenerator.new(); rng.seed = int(p.person_seed)+200880301
 var supported = p.perk_groups.filter(func(g): return g in ["Spear","Sword","Polearm","Bow","Crossbow","Throwing"])
 var total = 0; var scores = {}
 for group in supported:
  var ranged = group in ["Bow","Crossbow","Throwing"]
  var suited = (int(p.base_ranged_skill)+10 >= int(p.skill)) == ranged
  scores[group] = int(weights.get(group,1))*(2 if suited else 1); total += scores[group]
 var roll = rng.randi_range(1,total); var selected: String = supported[0]
 for group in supported:
  roll -= int(scores[group])
  if roll <= 0: selected = group; break
 var options: Array = {"Spear":["militia_spear","spear","heavy_spear"],"Sword":["shortsword","sword","falchion"],"Polearm":["polearm"],"Bow":["shortbow","bow"],"Crossbow":["crossbow"],"Throwing":["javelins","throwing_axes"]}[selected]
 p.weapon = options[rng.randi_range(0,options.size()-1)]; p.loadout.weapon = p.weapon
 p.loadout.shield = "" if p.weapon in TWO_HANDS else "shield" if rng.randi_range(0,3) != 0 else ""
 p["carried_loadout"] = ["sword" if "Sword" in supported else "spear" if "Spear" in supported else "dagger",""] if p.weapon in RANGED or p.weapon == "polearm" else ["",""]
 p["ammo_loadout"] = ammo_type(p.weapon)

static func frontline_offer(p: Dictionary) -> void:
 # Every weapon remains usable; company safety gear never rewrites potential.
 p.weapon = "sword" if "Sword" in p.perk_groups else "spear"
 p.loadout.weapon = p.weapon; p.loadout.shield = "shield"
 p.carried_loadout = ["",""]; p.ammo_loadout = ""
