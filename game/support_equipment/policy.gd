extends RefCounted
## Provisional conservative acquisition-v1, NOT a campaign-balance claim.
## Each slot has an independent identity hash. No People/combat/global RNG draws.
const SLOTS = ["hands","feet","cloak","belt"]
const CHANCE = {"hands":18,"feet":22,"cloak":18,"belt":22}
const WRAPS = "hm_trial_v1:gloves-01-linen-handwraps"
const MAIL = "hm_trial_v1:gloves-04-mail-gloves"
const SHOES = "hm_trial_v1:footwear-03-wrapped-shoes"
const BOOTS = "hm_trial_v1:footwear-04-reinforced-boots"
const SCOUT = "hm_trial_v1:cloaks-02-scout-cloak"
const CAPE = "hm_trial_v1:cloaks-04-waxed-cape"
const UTILITY = "hm_trial_v1:belts-01-utility-belt"
const SUPPORT = "hm_trial_v1:belts-03-support-belt"
const SASH = "hm_trial_v1:belts-04-woven-sash"
static func selection(seed_number: int, identity: Variant, ranged: bool, grade: int, catalog: Dictionary) -> Dictionary:
 var out := {}
 var g := clampi(grade,0,3)
 var pools := {
  "hands":[WRAPS,WRAPS,"archer_gloves" if ranged else "sword_gloves"],
  "feet":["light_boots",SHOES,"trail_boots"],
  "cloak":["travel_cloak","travel_cloak",SCOUT if ranged else "scholar_cloak"],
  "belt":[UTILITY,UTILITY,SASH]}
 if g >= 2:
  pools.hands.append_array([MAIL,MAIL] if not ranged else [MAIL])
  pools.feet.append_array([BOOTS,BOOTS] if not ranged else [BOOTS])
  pools.cloak.append(CAPE); pools.belt.append_array([SUPPORT,"pouch_belt"])
 for slot in SLOTS:
  var bytes: PackedByteArray = JSON.stringify(["support-acquisition-v1",seed_number,identity,slot]).sha256_buffer()
  out[slot] = ""
  if int(bytes.decode_u32(0)) % 100 >= int(CHANCE[slot])+g*4: continue
  var definition: String = pools[slot][int(bytes.decode_u32(4)) % pools[slot].size()]
  assert(catalog.has(definition) and catalog[definition].slot == slot)
  out[slot] = definition
 return out
static func recruit(seed_number: int, candidate: Dictionary, catalog: Dictionary) -> Dictionary:
 var grade := 1 if candidate.name in ["Militia","Deserter","Caravan guard"] else 0
 return selection(seed_number,["recruit",candidate.id,candidate.person_seed],candidate.weapon in preload("res://src/arsenal.gd").RANGED,grade,catalog)
static func append_enemy(unit: Dictionary, catalog: Dictionary, seed_number: int, identity: Variant, grade: int, condition_percent: int, token: String) -> void:
 # Real worn parts, not a drop table. Configure may run again after damage.
 if unit.get("support_acquisition_v1",false): return
 unit["support_acquisition_v1"] = true # Empty selections are final too.
 if unit.armor_parts.any(func(p):return p.layer in SLOTS): return
 var selected := selection(seed_number,identity,unit.weapon in preload("res://src/arsenal.gd").RANGED,grade,catalog)
 for slot in SLOTS:
  var definition: String = selected[slot]
  if definition.is_empty(): continue
  var d: Dictionary = catalog[definition]
  unit.armor_parts.append({"item":token+"_"+slot,"definition":definition,"group":"body","layer":slot,"pool":"armor","condition":int(d.durability)*condition_percent/100,"maximum":int(d.durability),"weight":int(d.weight),"hollow_slot":slot})
 var totals: Dictionary = preload("res://src/armor.gd").totals(unit.armor_parts)
 for key in totals: unit[key] = totals[key]
static func crypt(b, unit: Dictionary, room_seed: int, kind: String, tier: int, token: String) -> void:
 # This is called by the room factory AND exact validator, before first capture.
 unit.erase("support_acquisition_v1") # U.equip just created a new physical kit.
 append_enemy(unit,b.armor_catalog,room_seed,["crypt",token,kind],tier-1,int(preload("res://src/undead.gd").TYPES[kind].condition),token+"_support_v1")
 for part in unit.armor_parts:
  part["hollow_slot"] = part.layer if part.layer in SLOTS else part.group
