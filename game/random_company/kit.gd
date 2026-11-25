extends RefCounted
## Random Company v1: the same independent seed/identity draw for a fresh
## founder or recruit. No population RNG, roster context or budget input.
const Arsenal = preload("res://src/arsenal.gd")
const Armor = preload("res://src/armor.gd")
const Acquisition = preload("res://painted_merge/acquisition.gd")
const Support = preload("res://support_equipment/policy.gd")
const ForgeKit = preload("res://layer_forge/rules.gd")
const OFFER_KIT := "random_kit_v1"
const FIRST_WEEK := "random_recruit_start_week_v1"
const FORGE_KNIVES := ["hm_trial_v1:old24-medic_weapon","hm_trial_v1:old24-wayfarer_lancet"]
const OPTIONAL := ["offhand","body","head","hands","feet","cloak","belt","carry1","carry2"]
const OPTIONAL_DEFINITIONS := {
 "offhand":["hollow_campaign:buckler","hm_trial_v1:offhands-02-round-wooden-shield"],
 "body":["hm_trial_v1:old24-scout_coat","travel_leather"],
 "head":["hollow_campaign:padded_hood","hm_trial_v1:headwear-02-leather-cap",Acquisition.SKULLCAP],
 "feet":["light_boots",Support.SHOES,"trail_boots"],
 "cloak":["travel_cloak",Support.SCOUT,"scholar_cloak"],
 # Ordinary starter belts do not unlock additional reserve slots.
 "belt":[Support.UTILITY,Support.SASH,Support.SUPPORT],
}

static func roll(seed_number: int, candidate: Dictionary, catalog: Dictionary, historic_forge: bool = false) -> Dictionary:
 var key := JSON.stringify(["random-company-v1",seed_number,candidate.person_seed,candidate.get("id","")])
 var rng := RandomNumberGenerator.new()
 rng.seed = key.sha256_buffer().decode_u32(0)
 var main_pool := Arsenal.WEAPONS.filter(func(id):return id!="heavy_crossbow" and Acquisition.active(id,catalog))
 var weapon: String = main_pool[rng.randi_range(0,main_pool.size()-1)]
 var kit := {"mainhand":weapon}
 var ammo := Arsenal.ammo_type(weapon)
 if not ammo.is_empty(): kit["ammo"] = ammo

 # Replay the original draws to keep mainhand, ammo and offhand stable and
 # allow exact seed validation of already-issued quotes.
 var forge := ForgeKit.enabled()
 var available: Array = ["offhand","carry1","carry2"] if forge else OPTIONAL.duplicate()
 if weapon in Arsenal.TWO_HANDS: available.erase("offhand")
 var count: int = mini(available.size(),optional_count(rng,available.size())) if forge else optional_count(rng,available.size())
 var chosen := []
 for i in count:
  var tickets := 0
  for slot: String in available: tickets += slot_weight(slot)
  var ticket := rng.randi_range(0,tickets-1)
  for slot: String in available:
   ticket -= slot_weight(slot)
   if ticket >= 0: continue
   chosen.append(slot)
   available.erase(slot)
   break
 if "carry2" in chosen and not "carry1" in chosen:
  chosen[chosen.find("carry2")] = "carry1"
 var spares := main_pool.filter(func(id):return id!=weapon and not id in Arsenal.RANGED)
 for slot: String in OPTIONAL:
  if not slot in chosen: continue
  var pool: Array = spares if slot in Arsenal.CARRIED else [Support.WRAPS,"archer_gloves" if weapon in Arsenal.RANGED else "sword_gloves"] if slot == "hands" else OPTIONAL_DEFINITIONS[slot]
  var definition: String = pool[rng.randi_range(0,pool.size()-1)]
  kit[slot] = definition
  if slot in Arsenal.CARRIED: spares.erase(definition)
 if forge and not historic_forge:
  kit.erase("carry1")
  kit.erase("carry2")
  if weapon in Arsenal.RANGED:
   # Independent of both the old kit draw and the campaign RNG.
   var ticket := ForgeKit.ticket(seed_number,key,"pocket-knife-v1") % 100
   if ticket < 40:
    var knife: String = FORGE_KNIVES[0 if ticket < 30 else 1]
    if Acquisition.active(knife,catalog): kit["carry1"] = knife
 return kit

static func slot_weight(slot: String) -> int:
 return 1 if slot in Arsenal.CARRIED else 6

static func optional_count(rng: RandomNumberGenerator, full: int) -> int:
 var ticket := rng.randi_range(1,100)
 if ticket <= 5: return 0
 if ticket <= 8: return full
 if ticket <= 78: return rng.randi_range(2,4)
 var intermediate := [1]+range(5,full)
 return intermediate[rng.randi_range(0,intermediate.size()-1)]

# Leave raw People/Armor fields in their original validated template schema.
# Only this detached quote (also used by add_person) describes physical gear.
static func project(source: Dictionary, catalog: Dictionary) -> Dictionary:
 var out: Dictionary = source.duplicate(true)
 var kit: Dictionary = out[OFFER_KIT]
 var body: String = kit.get("body","")
 var head: String = kit.get("head","")
 out.weapon = kit.mainhand
 out.loadout = {"weapon":kit.mainhand,"shield":kit.get("offhand",""),"body":body,"head":head,"under":""}
 out.carried_loadout = [kit.get("carry1",""),kit.get("carry2","")]
 out.ammo_loadout = kit.get("ammo","")
 out.legacy_armor = false
 out.armor_loadout = {"body":Armor.empty_parts("body"),"head":Armor.empty_parts("head")}
 if not body.is_empty(): out.armor_loadout.body[catalog[body].layer] = body
 if not head.is_empty(): out.armor_loadout.head[catalog[head].layer] = head
 out["support_loadout"] = {}
 for slot: String in Support.SLOTS: out.support_loadout[slot] = kit.get(slot,"")
 # Retained modest-kit hiring fee (before its two old armor surcharges), plus
 # the exact catalogue list value of each included item. Wages never use gear.
 out.price = 65+int(source.wage)*12+int(source.aptitudes.values().max())*6
 for definition: String in kit.values(): out.price += int(catalog[definition].price)
 return out

static func valid_offers(data: Dictionary, catalog: Dictionary, enabled: bool) -> bool:
 if not data.get("recruit_pools") is Dictionary: return false
 var first := -1
 if data.has(FIRST_WEEK):
  var marker = data[FIRST_WEEK]
  if not enabled or not marker is int or not data.get("day") is int or data.day < 1: return false
  if marker != 0 and (marker < 5 or marker > (data.day-1)/7): return false
  first = marker
 for id in data.recruit_pools:
  var offer = data.recruit_pools[id]
  if not id is String or not offer is Dictionary: return false
  var week: String = id.get_slice("_recruit_",1).get_slice("_",0)
  if not week.is_valid_int(): return false
  var expected := first >= 0 and int(week) >= first
  if offer.has(OFFER_KIT) != expected: return false
  if not expected: continue
  if not offer.get("person_seed") is int or offer.person_seed < 1 or offer.person_seed > 2147483646 or not offer.get("id") is String or offer.id != id or not offer[OFFER_KIT] is Dictionary: return false
  if offer[OFFER_KIT] != roll(data.seed,offer,catalog):
   # Existing Forge caches remain the original quotes. Admit only the exact
   # predecessor ticket result, not arbitrary old-style pocket contents.
   if not ForgeKit.enabled() or offer[OFFER_KIT] != roll(data.seed,offer,catalog,true): return false
 return true
