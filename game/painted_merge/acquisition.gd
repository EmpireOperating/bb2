extends RefCounted
## New acquisition choices only. Never rewrite a physical record or rarity roll.
const Armor = preload("res://src/armor.gd")
const Arsenal = preload("res://src/arsenal.gd")
const SKULLCAP = "hm_trial_v1:headwear-03-iron-skullcap"
const LEGACY_CAP = "iron_cap"
# Only generation/replay tokens cross this seam. Never pass a physical item through it.
static func previous_design(definition: String) -> String:
 return LEGACY_CAP if definition == SKULLCAP else definition
const RETIRED = ["breather_belt",LEGACY_CAP,"hm_trial_v1:old24-reedrunner_bow"]
const TIER_ONE_MAUL := "hm_trial_v1:twohand_maul"
const ACTIVE = [
 TIER_ONE_MAUL,
 "bodkin_quiver",
 "deep_quiver",
 "archer_gloves",
 "crossbow",
 "heavy_crossbow",
 "bolts",
 "cudgel",
 "hm_trial_v1:additional_fighting_axe",
 "hm_trial_v1:belts-01-utility-belt",
 "hm_trial_v1:belts-03-support-belt",
 "hm_trial_v1:belts-04-woven-sash",
 "hm_trial_v1:cloaks-02-scout-cloak",
 "hm_trial_v1:cloaks-04-waxed-cape",
 "hm_trial_v1:footwear-03-wrapped-shoes",
 "hm_trial_v1:footwear-04-reinforced-boots",
 "hm_trial_v1:gloves-01-linen-handwraps",
 "hm_trial_v1:gloves-04-mail-gloves",
 "hm_trial_v1:headwear-02-leather-cap",
 "hm_trial_v1:headwear-04-kettle-helm",
 "hm_trial_v1:offhands-02-round-wooden-shield",
 "hm_trial_v1:old24-archer_heavy",
 "hm_trial_v1:old24-archer_weapon",
 "hm_trial_v1:old24-banded_mail",
 "hm_trial_v1:old24-duelist_heavy",
 "hm_trial_v1:old24-duelist_weapon",
 "hm_trial_v1:old24-ferryman_hook",
 "hm_trial_v1:old24-gatewarden_blade",
 "hm_trial_v1:old24-medic_heavy",
 "hm_trial_v1:old24-medic_weapon",
 "hm_trial_v1:old24-polearm_heavy",
 "hm_trial_v1:old24-polearm_weapon",
 "hm_trial_v1:old24-quarry_estoc",
 "hm_trial_v1:old24-scout_coat",
 "hm_trial_v1:old24-shieldbearer_heavy",
 "hm_trial_v1:old24-ward_spear",
 "hm_trial_v1:old24-wayfarer_lancet",
 "hm_trial_v1:twohand_sword",
 "hollow_campaign:buckler",
 "hollow_campaign:padded_hood",
 SKULLCAP,
 "light_boots",
 "march_mail",
 "pike",
 "pouch_belt",
 "scholar_cloak",
 "short_bow",
 "short_sword",
 "sword_gloves",
 "trail_boots",
 "travel_cloak",
 "travel_leather"
]
const STARTER_WEAPONS = {
 "shortsword":"short_sword", "club":"cudgel", "hatchet":"hm_trial_v1:old24-medic_heavy",
 "militia_spear":"pike", "knife":"hm_trial_v1:old24-medic_weapon", "shortbow":"short_bow",
 # No authored thrown definition exists. This is a real bow with real ammunition,
 # not a throwing weapon painted as one or a change to the person's rolled stats.
 "bolas":"short_bow"
}
const WEAPONS = {
 "club": "cudgel",
 "hatchet": "hm_trial_v1:old24-medic_heavy",
 "militia_spear": "pike",
 "knife": "hm_trial_v1:old24-medic_weapon",
 "shortsword": "short_sword",
 "sword": "hm_trial_v1:old24-gatewarden_blade",
 "arming_sword": "hm_trial_v1:old24-quarry_estoc",
 "falchion": "hm_trial_v1:old24-duelist_heavy",
 "dagger": "hm_trial_v1:old24-wayfarer_lancet",
 "spear": "hm_trial_v1:old24-ward_spear",
 "heavy_spear": "hm_trial_v1:old24-polearm_weapon",
 "pike": "pike",
 "polearm": "hm_trial_v1:old24-polearm_heavy",
 "glaive": "hm_trial_v1:old24-ferryman_hook",
 "axe": "hm_trial_v1:additional_fighting_axe",
 "greataxe": "hm_trial_v1:additional_fighting_axe",
 "greatsword": "hm_trial_v1:twohand_sword",
 "mace": "hm_trial_v1:old24-shieldbearer_heavy",
 "hammer": "hm_trial_v1:old24-shieldbearer_heavy",
 "maul": "hm_trial_v1:old24-shieldbearer_heavy",
 "shortbow": "short_bow",
 "bow": "hm_trial_v1:old24-archer_weapon",
 "warbow": "hm_trial_v1:old24-archer_heavy",
 "crossbow": "crossbow",
 "heavy_crossbow": "heavy_crossbow",
 "bolas": "short_bow",
 "javelins": "short_bow",
 "throwing_axes": "short_bow"
}
const SHIELDS = {
 "buckler": "hollow_campaign:buckler",
 "shield": "hm_trial_v1:offhands-02-round-wooden-shield",
 "round_shield": "hm_trial_v1:offhands-02-round-wooden-shield"
}
const BODIES = ["hm_trial_v1:old24-scout_coat", "travel_leather", "march_mail", "hm_trial_v1:old24-banded_mail"]
const HEADS = ["hollow_campaign:padded_hood", "hm_trial_v1:headwear-02-leather-cap", SKULLCAP, "hm_trial_v1:headwear-04-kettle-helm"]
const UNDEAD = {
 "barrow_lord": {
  "weapon": "hm_trial_v1:old24-shieldbearer_heavy",
  "shield": "hm_trial_v1:offhands-02-round-wooden-shield",
  "body": "hm_trial_v1:old24-banded_mail",
  "head": "hm_trial_v1:headwear-04-kettle-helm",
  "backup": "",
  "extra": ""
 },
 "watch_captain": {
  "weapon": "hm_trial_v1:old24-archer_heavy",
  "shield": "",
  "body": "march_mail",
  "head": SKULLCAP,
  "backup": "hm_trial_v1:old24-gatewarden_blade",
  "extra": ""
 },
 "buried_king": {
  "weapon": "hm_trial_v1:twohand_sword",
  "shield": "",
  "body": "hm_trial_v1:old24-banded_mail",
  "head": "hm_trial_v1:headwear-04-kettle-helm",
  "backup": "",
  "extra": ""
 },
 "sentinel": {
  "weapon": "hm_trial_v1:old24-ward_spear",
  "shield": "",
  "body": "hm_trial_v1:old24-banded_mail",
  "head": SKULLCAP,
  "backup": "",
  "extra": ""
 },
 "thrall": {
  "weapon": "cudgel",
  "shield": "",
  "body": "travel_leather",
  "head": "",
  "backup": "",
  "extra": ""
 },
 "guard": {
  "weapon": "hm_trial_v1:old24-gatewarden_blade",
  "shield": "hm_trial_v1:offhands-02-round-wooden-shield",
  "body": "march_mail",
  "head": "hm_trial_v1:headwear-02-leather-cap",
  "backup": "",
  "extra": ""
 },
 "spearman": {
  "weapon": "hm_trial_v1:old24-ward_spear",
  "shield": "",
  "body": "travel_leather",
  "head": SKULLCAP,
  "backup": "",
  "extra": ""
 },
 "archer": {
  "weapon": "short_bow",
  "shield": "",
  "body": "hm_trial_v1:old24-scout_coat",
  "head": "",
  "backup": "hm_trial_v1:old24-medic_weapon",
  "extra": ""
 },
 "warden": {
  "weapon": "hm_trial_v1:old24-shieldbearer_heavy",
  "shield": "hm_trial_v1:offhands-02-round-wooden-shield",
  "body": "hm_trial_v1:old24-banded_mail",
  "head": "hm_trial_v1:headwear-04-kettle-helm",
  "backup": "",
  "extra": ""
 }
}
static func undead(source: Dictionary, kind: String) -> Dictionary:
 var out: Dictionary = source.duplicate(true)
 out.merge(UNDEAD[kind],true)
 return out
# Future human kits only; immutable People templates and already-owned records
# retain their exact definitions. Pools are ordered and grade-bounded, not rarity rolls.
const HUMAN_WEAPONS = [
 ["club","hatchet","militia_spear","knife","shortsword","hm_trial_v1:old24-duelist_weapon"],
 ["shortsword","militia_spear","hatchet","club","hm_trial_v1:old24-duelist_weapon","heavy_spear","glaive","dagger"],
 ["sword","spear","axe","mace","falchion","heavy_spear","glaive","arming_sword","hm_trial_v1:old24-duelist_weapon"],
 ["sword","hammer","polearm","axe","greatsword","heavy_spear","glaive","arming_sword","falchion"]
]
static func human_weapon(grade: int, n: int, original: String, finite_bow: bool) -> String:
 if finite_bow:
  return ["shortbow","bow"][posmod(n/3,2)] if grade < 2 else ["bow","warbow"][posmod(n/3,2)]
 if original in ["shortbow","bow","crossbow","heavy_crossbow"]: return original
 var pool: Array = HUMAN_WEAPONS[grade]
 return pool[n%pool.size()]
static func human_ammo(definitions: Dictionary, grade: int, n: int) -> void:
 if Arsenal.family(definitions.weapon) == "bow" and grade >= 1:
  definitions.ammo = ["arrows","bodkin_quiver","deep_quiver"][posmod(n/5,3)]
static func arms(source: Dictionary) -> Dictionary:
 var out: Dictionary = source.duplicate(true)
 for slot in out:
  out[slot] = SHIELDS.get(out[slot],WEAPONS.get(out[slot],out[slot]))
 out.ammo = Arsenal.ammo_type(out.weapon)
 if out.weapon in Arsenal.TWO_HANDS: out.shield = ""
 return out
static func outfit(source: Dictionary, grade: int, catalog: Dictionary) -> Dictionary:
 var out := {"body":Armor.empty_parts("body"),"head":Armor.empty_parts("head")}
 out.body[catalog[BODIES[grade]].layer] = BODIES[grade]
 if grade > 0 or source.head.values().any(func(id):return not id.is_empty()):
  out.head[catalog[HEADS[grade]].layer] = HEADS[grade]
 return out
const REWARD_ARMOR = {
 "mail": "march_mail",
 "short_mail": "march_mail",
 "long_mail": "hm_trial_v1:old24-banded_mail",
 "heavy_mail": "hm_trial_v1:old24-banded_mail",
 "brigandine": "hm_trial_v1:old24-banded_mail",
 "breastplate": "hm_trial_v1:old24-banded_mail",
 "nasal": SKULLCAP,
 "bascinet": "hm_trial_v1:headwear-04-kettle-helm",
 "cap": "hm_trial_v1:headwear-02-leather-cap",
 "kettle": "hm_trial_v1:headwear-04-kettle-helm"
}
# Resolve source aliases before catalogue admission. The source token remains
# the selection entry, preserving deterministic pool order and physical identity.
static func reward_pool(source: Array, catalog: Dictionary) -> Array:
 return source.filter(func(id):return preload("res://src/named_equipment.gd").eligible(reward(id,catalog),catalog))
static func reward(source: String, catalog: Dictionary) -> String:
 if source == LEGACY_CAP: return SKULLCAP
 if source.is_empty() or active(source,catalog): return source
 return WEAPONS.get(source,REWARD_ARMOR.get(source,""))
# Exact predecessor reward alias, used only to validate already-reserved records.
# New generation always calls reward(), never this admission projection.
static func reward_before_crossbows(source: String, catalog: Dictionary) -> String:
 return {"crossbow":"hm_trial_v1:old24-archer_weapon","heavy_crossbow":"hm_trial_v1:old24-archer_heavy"}.get(source,previous_design(reward(source,catalog)))
static func recorded_design(definition: String, catalog: Dictionary) -> bool:
 return active(definition,catalog) or (definition == LEGACY_CAP and catalog.has(definition))
static func active(definition: String, catalog: Dictionary) -> bool:
 return catalog.has(definition) and (definition == "arrows" or definition in ACTIVE)
# Exact predecessor market-book projection, admission only. Existing books never
# gain stock merely because a newly authorized design becomes available.
static func stock_before_cap(expected: Array) -> Array:
 var old := expected.map(previous_design)
 old.sort()
 return old
static func stock_before_crossbows(expected: Array) -> Array:
 return stock_before_cap(expected).filter(func(id):return id not in ["crossbow","heavy_crossbow","bolts"])
static func stock(source: Array, catalog: Dictionary) -> Array:
 var out := []
 for definition in source:
  if active(definition,catalog) and definition not in out: out.append(definition)
 return out
static func candidate(source: Dictionary, catalog: Dictionary) -> Dictionary:
 var out: Dictionary = source.duplicate(true)
 out.weapon = STARTER_WEAPONS.get(source.weapon,source.weapon)
 out.loadout.weapon = out.weapon
 for i in out.carried_loadout.size():
  out.carried_loadout[i] = STARTER_WEAPONS.get(out.carried_loadout[i],out.carried_loadout[i])
 out.ammo_loadout = Arsenal.ammo_type(out.weapon)
 out.loadout.shield = "" if out.weapon in Arsenal.TWO_HANDS else {"buckler":"hollow_campaign:buckler","shield":"hm_trial_v1:offhands-02-round-wooden-shield","round_shield":"hm_trial_v1:offhands-02-round-wooden-shield"}.get(source.loadout.shield,source.loadout.shield)
 var physical := {"body":Armor.empty_parts("body"),"head":Armor.empty_parts("head")}
 for group in ["body","head"]:
  var chosen := ""
  for layer in (["outer","mail","base"] if group == "body" else ["shell","mail","padding"]):
   var definition: String = source.armor_loadout[group][layer]
   if definition.is_empty(): continue
   chosen = definition
   break
  if chosen.is_empty(): continue
  if chosen == LEGACY_CAP: chosen = SKULLCAP
  if not catalog[chosen].get("campaign_adopted",false):
   chosen = ("travel_leather" if chosen in ["jerkin","leather"] else "hm_trial_v1:old24-scout_coat") if group == "body" else ("hollow_campaign:padded_hood" if chosen in ["felt_cap","arming_cap","padded_hood"] else SKULLCAP)
  physical[group][catalog[chosen].layer] = chosen
 out.armor_loadout = physical
 # This detached offer presents the new physical outfit; source templates retain
 # their native format for identity/progression validation and future generation.
 out.loadout.body = physical.body.outer
 out.loadout.under = ""
 out.loadout.head = physical.head.shell
 out.legacy_armor = false
 return out
