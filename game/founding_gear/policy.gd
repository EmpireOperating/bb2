extends RefCounted
## Fresh owned companions only. These are design tickets, not item rarity rolls.
## A draw knows one founder and one slot; it never sees a party value or a prior draw.
const Arsenal = preload("res://src/arsenal.gd")
const Armor = preload("res://src/armor.gd")
const Support = preload("res://support_equipment/policy.gd")
const WEAPON = {
 "two_handed":{"pike":65,"hm_trial_v1:old24-polearm_weapon":25,"hm_trial_v1:old24-polearm_heavy":10},
 "shield":{"short_sword":55,"cudgel":35,"hm_trial_v1:old24-duelist_weapon":10},
 "ranged":{"short_bow":60,"hm_trial_v1:old24-archer_weapon":15,"crossbow":25},
}
const SHIELD = {"hollow_campaign:buckler":75,"hm_trial_v1:offhands-02-round-wooden-shield":25}
const BODY = {"hm_trial_v1:old24-scout_coat":70,"travel_leather":30}
const HEAD = {"hollow_campaign:padded_hood":60,"hm_trial_v1:headwear-02-leather-cap":32,"hm_trial_v1:headwear-03-iron-skullcap":8}

static func pick(seed_number: int, person: Dictionary, slot: String, weights: Dictionary) -> String:
 var ticket: int = JSON.stringify(["founder-kit-v1",seed_number,person.person_seed,person.companion_role,slot]).sha256_buffer().decode_u32(0) % 100
 for definition: String in weights:
  ticket -= int(weights[definition])
  if ticket < 0: return definition
 assert(false,"Founder design weights must total 100")
 return ""

static func outfit(seed_number: int, offer: Dictionary, catalog: Dictionary) -> void:
 # The caller owns this detached acquisition offer. The native identity/growth
 # template, perk tree, and saved physical records never pass through this roll.
 var role: String = offer.companion_role
 offer.weapon = pick(seed_number,offer,"weapon",WEAPON[role])
 offer.loadout.weapon = offer.weapon
 offer.loadout.shield = pick(seed_number,offer,"shield",SHIELD) if role == "shield" else ""
 offer.ammo_loadout = Arsenal.ammo_type(offer.weapon)
 # Ranged founders retain their existing fitted reserve field knife.
 for group: String in ["body","head"]:
  var id := pick(seed_number,offer,group,BODY if group == "body" else HEAD)
  var parts := Armor.empty_parts(group)
  parts[catalog[id].layer] = id
  offer.armor_loadout[group] = parts
  offer.loadout[group] = id

static func accessories(seed_number: int, person: Dictionary, catalog: Dictionary) -> Dictionary:
 # Use the existing modest (grade 0) independent per-slot support draws, with
 # a founder namespace rather than a recruit ID. Empty is an ordinary outcome.
 return Support.selection(seed_number,["founder-kit-v1",person.person_seed,person.companion_role],person.companion_role == "ranged",0,catalog)
