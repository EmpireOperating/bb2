extends RefCounted
## Availability bands concern base designs only, never physical instance rarity.
## The painted catalogue currently labels every adopted design tier 1 with
## provisional 20/25/40 prices. Preserve those values; curate availability instead.
const CAPS = {"ashwick":8,"stonecross":14,"dunmere":10}
const LUCK = {"ashwick":1,"stonecross":3,"dunmere":2}
const COMMON = ["crossbow","bolts","cudgel","pike","short_sword","short_bow","hm_trial_v1:old24-medic_weapon","hm_trial_v1:old24-medic_heavy","travel_leather","hollow_campaign:padded_hood","hm_trial_v1:headwear-02-leather-cap","light_boots","hm_trial_v1:footwear-03-wrapped-shoes","hm_trial_v1:gloves-01-linen-handwraps","hm_trial_v1:belts-01-utility-belt","travel_cloak","hollow_campaign:buckler"]
const PREMIUM = ["heavy_crossbow","hm_trial_v1:twohand_sword","hm_trial_v1:old24-archer_heavy","hm_trial_v1:old24-banded_mail","hm_trial_v1:headwear-04-kettle-helm","hm_trial_v1:gloves-04-mail-gloves","hm_trial_v1:footwear-04-reinforced-boots","hm_trial_v1:belts-03-support-belt"]
const Acquisition = preload("res://painted_merge/acquisition.gd")
const Arsenal = preload("res://src/arsenal.gd")
static func choose(seed_number: int,town: String,role: String,level: int,serial: int,day: int,catalog: Dictionary,before_crossbows: bool = false,before_maul: bool = false) -> String:
 # One opening Stonecross shelf position, not a free item or equipment rewrite.
 var maul: String = Acquisition.TIER_ONE_MAUL
 var allow_maul: bool = not before_maul and not before_crossbows and town=="stonecross" and Acquisition.active(maul,catalog)
 if allow_maul and day==1 and serial==CAPS[role]-1:return maul
 var rng := RandomNumberGenerator.new()
 rng.seed = int(JSON.stringify(["local-shelf-v1",seed_number,town,role,level,serial,day]).sha256_text().left(15).hex_to_int())
 var premium: bool = rng.randi_range(0,99) < LUCK[role]*level/2
 var middle: bool = rng.randi_range(0,99) < 20+level*10
 var pool := []; var total := 0
 # Arrow quivers are physical ammo-slot equipment, not numerical company supplies.
 var ids: Array = Acquisition.stock(Acquisition.ACTIVE+["arrows"],catalog)
 if not allow_maul or day==1:ids.erase(maul)
 if before_crossbows: ids = Acquisition.stock_before_crossbows(ids)
 # Keep the original draw intervals; changing a lexical ID must not reroll other stock.
 ids.sort_custom(func(a,b):return Acquisition.previous_design(a) < Acquisition.previous_design(b))
 for id in ids:
  var d: Dictionary = catalog[id]
  var price: int = int(d.price)
  # The first physical piece is an affordable replacement, never an upgrade promise.
  if serial == 0:
   if d.get("slot") != "weapon" or id not in COMMON: continue
  else:
   var premium_item:bool=id in PREMIUM or id==maul
   if not (premium_item if premium else id not in COMMON and not premium_item if middle else id in COMMON):continue
  var weight := 1
  if id in COMMON: weight = 4
  var family: String = Arsenal.family(id)
  if role == "ashwick" and (family in ["spear","axe","mace"] or d.get("group") == "body"): weight *= 3
  if role == "stonecross" and (family in ["sword","axe","hammer"] or d.get("group") == "head"): weight *= 3
  if role == "dunmere" and (family in ["bow","crossbow","polearm"] or d.get("slot") in ["cloak","feet"]): weight *= 3
  total += weight; pool.append({"id":id,"end":total})
 var roll: int = rng.randi_range(0,total-1)
 for row in pool:
  if roll < row.end: return row.id
 return "cudgel"

static func shape(raw: Variant) -> bool:
 if not raw is Dictionary or not raw.get("towns") is Dictionary: return false
 for s in raw.towns.values():
  if not s is Dictionary or not s.get("shelf") is Array: return false
  for unit in s.shelf:
   if not unit is Dictionary or unit.size()!=5: return false
   if not unit.get("id") is String or not unit.get("definition") is String or not unit.get("day") is int or not unit.get("level") is int or not unit.get("sold") is bool: return false
 return true
