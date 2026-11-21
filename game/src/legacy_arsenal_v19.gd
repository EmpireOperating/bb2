extends RefCounted
## Physical carried equipment and explicitly priced weapon actions.
const SLOTS = ["weapon","shield","carry1","carry2","ammo"]
const WEAPONS = ["javelins", "throwing_axes", "sword", "spear", "axe", "bow", "mace", "hammer", "dagger", "polearm", "crossbow", "shortsword", "falchion", "greatsword", "militia_spear", "heavy_spear", "hatchet", "greataxe", "club", "maul", "knife", "glaive", "shortbow", "warbow", "heavy_crossbow"]
const TWO_HANDS = ["bow", "polearm", "crossbow", "greatsword", "greataxe", "maul", "glaive", "shortbow", "warbow", "heavy_crossbow"]
const RANGED = ["javelins", "throwing_axes", "bow", "crossbow", "shortbow", "warbow", "heavy_crossbow"]
const PRIMARY = {"throwing":"Quick throw","sword":"Slash","spear":"Thrust","axe":"Chop","mace":"Strike","hammer":"Hammer blow","dagger":"Stab","polearm":"Reach strike","bow":"Quick shot","crossbow":"Shoot bolt"}
const SPECIAL = {
 "throwing":{"name":"Heavy throw","ap":5,"fatigue":20,"target":true,"text":"-5 accuracy, +20% armour damage. Uses one weapon from the held bundle. Can throw while engaged; shields are allowed."},
 "sword":{"name":"Riposte","ap":4,"fatigue":18,"target":false,"text":"Until your next turn: counter the first two missed adjacent melee attacks. Each counter costs 6 fatigue; moving, attacking or switching ends the stance."},
 "spear":{"name":"Spear brace","ap":4,"fatigue":16,"target":false,"text":"Until your next turn: strike the first two enemies entering an adjacent hex. A hit stops their remaining movement. Each reaction costs 6 fatigue."},
 "axe":{"name":"Split shield","ap":5,"fatigue":22,"target":true,"text":"Adjacent shield: 90% base chance, +5 if outnumbered. Deals 24 shield condition; no body damage. A broken shield gives no defence or linked support."},
 "mace":{"name":"Staggering blow","ap":5,"fatigue":22,"target":true,"text":"-10 accuracy, 75% damage. A hit removes 2 current AP and 2 AP next turn. Repeated hits do not stack the next-turn penalty."},
 "hammer":{"name":"Shatter armour","ap":6,"fatigue":26,"target":true,"text":"-5 accuracy. Body hit: double armour wear, half flesh damage. Useful for opening heavy armour; expensive and destructive to loot."},
 "dagger":{"name":"Puncture","ap":4,"fatigue":18,"target":true,"text":"-20 accuracy. Body hit: 80% weapon damage directly to health, preserving armour and padding. Best against exposed or surrounded targets."},
 "polearm":{"name":"Hook and drag","ap":5,"fatigue":22,"target":true,"text":"At two hexes: -10 accuracy, 65% damage; on a hit pull the target one hex toward you into an empty passable hex."},
 "bow":{"name":"Aimed shot","ap":6,"fatigue":18,"target":true,"text":"+15 accuracy and 15% damage. Uses one arrow; leaves less AP for movement. Cannot shoot while engaged."},
 "crossbow":{"name":"Reload","ap":4,"fatigue":10,"target":false,"text":"Ready an unloaded crossbow. Requires a bolt in your case and no adjacent enemy. Loaded state follows the physical weapon through switches."}}

const FAMILIES = {"javelins":"throwing","throwing_axes":"throwing","sword": "sword", "spear": "spear", "axe": "axe", "bow": "bow", "mace": "mace", "hammer": "hammer", "dagger": "dagger", "polearm": "polearm", "crossbow": "crossbow", "shortsword": "sword", "falchion": "sword", "greatsword": "sword", "militia_spear": "spear", "heavy_spear": "spear", "hatchet": "axe", "greataxe": "axe", "club": "mace", "maul": "hammer", "knife": "dagger", "glaive": "polearm", "shortbow": "bow", "warbow": "bow", "heavy_crossbow": "crossbow"}

static func family(weapon: String) -> String:
 return FAMILIES.get(weapon,weapon)

static func special(weapon: String) -> Dictionary:
 return SPECIAL[family(weapon)]

static func primary(weapon: String) -> String:
 return PRIMARY[family(weapon)]

static func ammo_type(weapon: String) -> String:
 return "arrows" if family(weapon) == "bow" else "bolts" if family(weapon) == "crossbow" else ""

static func empty_arms() -> Dictionary:
 var out = {}
 for slot in SLOTS: out[slot] = {}
 return out

static func allowed(slot: String, definition: String, catalog: Dictionary) -> bool:
 if not catalog.has(definition): return false
 var kind = catalog[definition].slot
 return kind in ["weapon","shield"] if slot in ["carry1","carry2"] else kind == slot

static func combat_item(item: Dictionary) -> Dictionary:
 return {"id":item.id,"definition":item.definition,"condition":item.condition,"loaded":item.get("loaded",false)}

static func valid_arms(value: Variant, catalog: Dictionary) -> bool:
 if not value is Dictionary or value.size() != SLOTS.size(): return false
 var ids = {}
 for slot in SLOTS:
  var item = value.get(slot)
  if not item is Dictionary: return false
  if item.is_empty():
   if slot == "weapon": return false
   continue
  if not item.get("id") is String or item.id.is_empty() or ids.has(item.id) or not item.get("definition") is String or not allowed(slot,item.definition,catalog): return false
  ids[item.id] = true
  if not item.get("condition") is int or item.condition < 0 or item.condition > catalog[item.definition].durability or not item.get("loaded") is bool: return false
  if item.loaded and family(item.definition) != "crossbow": return false
 if value.weapon.definition in TWO_HANDS and not value.shield.is_empty(): return false
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
const LOAD = {"javelins":6,"throwing_axes":8,"sword":8,"shortsword":6,"falchion":9,"greatsword":16,"spear":8,"militia_spear":6,"heavy_spear":10,"axe":10,"hatchet":6,"greataxe":18,"mace":10,"club":7,"maul":18,"hammer":10,"dagger":3,"knife":2,"polearm":12,"glaive":15,"bow":8,"shortbow":6,"warbow":12,"crossbow":10,"heavy_crossbow":14,"shield":12,"arrows":2,"bolts":2}

static func load(arms: Dictionary) -> int:
 var total = 0
 for slot in SLOTS:
  var item: Dictionary = arms.get(slot,{})
  var weight: int = LOAD.get(item.get("definition",""),0)
  total += ceili(weight/2.0) if slot in ["carry1","carry2"] else weight
 return total
