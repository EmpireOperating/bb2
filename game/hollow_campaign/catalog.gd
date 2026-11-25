extends RefCounted
## Additive current catalog. Conflicting adopted IDs never redefine stock gear.
const COLLISIONS = {"padded_hood":"hollow_campaign:padded_hood","buckler":"hollow_campaign:buckler"}
const ForgeCatalog = preload("res://layer_forge/rules.gd")
const LAB_PROFILE := "ashen-company-armor-lab"
const LAB_BODY_LAYERS := ["base","mail","outer"]
const LAB_BASE := "linen"
const LAB_MAIL := "march_mail"
# Banded Mail keeps its name/design; its external iron bands make it an outer.
const LAB_BANDED_OUTER := "hm_trial_v1:old24-banded_mail"
const LAB_GARMENTS := ["travel_leather","hm_trial_v1:old24-scout_coat"]
const LAB_RETIRED_OUTER := ["leather","jerkin"]
const LAB_DRAPES := ["blue_tabard","red_surcoat","sash","forest_cloak","red_cape","fur_mantle"]
static func armor_lab_profile() -> bool:
 return ProjectSettings.get_setting("application/config/use_custom_user_dir",false) and ProjectSettings.get_setting("application/config/custom_user_dir_name","") == LAB_PROFILE

static func equipment() -> Dictionary:
 var out: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
 var adopted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://hollow_campaign/authored_equipment.json"))
 for id in adopted:
  var key: String = COLLISIONS.get(id,id)
  assert(not out.has(key),"Authored catalog collision: "+key)
  out[key] = adopted[id].duplicate(true)
  out[key]["campaign_adopted"] = true
 if ForgeCatalog.enabled():
  out.merge(ForgeCatalog.designs())
 # Called by live Campaign, merchant validation and the immutable corpse replay.
 # Use the same lab projection at all three boundaries; keep the archived data.
 if armor_lab_profile():
  out[LAB_MAIL].layer = "mail"
  for id in LAB_GARMENTS: out[id].layer = "base"
  for id in LAB_DRAPES:
   # Leave the group/layer used by immutable People offer templates intact.
   # Physical acquisition and equipping use the standalone cosmetic slot.
   out[id].slot = "cloak"
  for row: Dictionary in out.values():
   if row.get("slot") not in ["hands","feet","cloak","belt"]: continue
   row["lab_outfit"] = true
   row["durability"] = 0
   row["weight"] = 0
   row["effects"] = {}
   row.erase("switch_ap")
   row["role"] = "Pockets capacity only" if int(row.get("capacity",0)) > 0 else "Decoration only"
 return out
# Catalogue/wardrobe projection. equipment() remains the complete lookup for owned
# and reserved records; historical IDs must keep their own stats, rolls and art.
static func physical_ids() -> Array:
 if ForgeCatalog.enabled():
  var catalog := equipment()
  return catalog.keys().filter(func(id):return ForgeCatalog.tradeable(id,catalog))
 var ids := retained_physical_ids()
 ids.erase(preload("res://painted_merge/acquisition.gd").LEGACY_CAP)
 return ids
static func retained_physical_ids() -> Array:
 var out := []
 var catalog := equipment()
 for id in catalog:
  if catalog[id].get("campaign_adopted",false):out.append(id)
 return out
