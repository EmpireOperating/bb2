extends RefCounted
## Additive current catalog. Conflicting adopted IDs never redefine stock gear.
const COLLISIONS = {"padded_hood":"hollow_campaign:padded_hood","buckler":"hollow_campaign:buckler"}
static func equipment() -> Dictionary:
 var out: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
 var adopted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://hollow_campaign/authored_equipment.json"))
 for id in adopted:
  var key: String = COLLISIONS.get(id,id)
  assert(not out.has(key),"Authored catalog collision: "+key)
  out[key] = adopted[id].duplicate(true)
  out[key]["campaign_adopted"] = true
 return out
# Catalogue/wardrobe projection. equipment() remains the complete lookup for owned
# and reserved records; historical IDs must keep their own stats, rolls and art.
static func physical_ids() -> Array:
 var ids := retained_physical_ids()
 ids.erase(preload("res://painted_merge/acquisition.gd").LEGACY_CAP)
 return ids
static func retained_physical_ids() -> Array:
 var out := []
 var catalog := equipment()
 for id in catalog:
  if catalog[id].get("campaign_adopted",false):out.append(id)
 return out
