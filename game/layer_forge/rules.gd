extends RefCounted
## Forge admission and design selection. Neither loadout sketches nor the
## catalogue hold ownership; the Campaign allocates/validates physical UIDs.
const PROFILE := "ashen-company-layer-forge"
const SCHEMA := 1
const ASSEMBLY := {"body":"body_kit", "head":"head_kit"}
const LAYERS := {
 "body":["base","mail","outer","cloth","cloak","reinforce","seal"],
 "head":["padding","shell","face","decor","favor","seal"],
}
const ARMS := ["weapon","shield","ammo"]
const GEAR := ["weapon","shield","ammo","body","head","carry1","carry2","carry3","carry4"]
const VISIBLE := ["mainhand","offhand","head","body","ammo"]
const SUPPORT := ["belt","hands","feet","cloak"]
# Authored upper armor circulates via Local Markets' paid replacement shelves
# only. Market roles are stable across generated town names and districts.
const RESTOCK_ONLY := {
 "ashwick":["forge:b4_cinderwatch","forge:b5_stormfelt","forge:h5_wayfarer_tie"],
 "stonecross":["forge:b6_riveted_wings","forge:b7_black_kiln"],
 "dunmere":["forge:h4_brass_comb","forge:h6_hammermark"],
}
# Admission-only Wave 2 designs; do not extend the original rotation.
const QUILTED_TABARD := "forge:b4_quilted_tabard"
const LEATHER_BACKED_MANTLE := "forge:b5_leather_backed_mantle"
const PADDED_TEMPLE_WRAP := "forge:h5_padded_temple_wrap"
# Physical corpse recovery only; not an ordinary pick/merchant draw.
const RIVETED_MANTLE := "forge:b5_riveted_mantle"
const NamedMail = preload("res://layer_forge/named_mail.gd")

static func enabled() -> bool:
 return ProjectSettings.get_setting("application/config/use_custom_user_dir",false) == true and ProjectSettings.get_setting("application/config/custom_user_dir_name","") == PROFILE

static func designs() -> Dictionary:
 return JSON.parse_string(FileAccess.get_file_as_string("res://layer_forge/catalog.json"))

static func is_layer(id: String, catalog: Dictionary) -> bool:
 return id.begins_with("forge:") and catalog.has(id)

static func tradeable(id: String, catalog: Dictionary) -> bool:
 return is_layer(id,catalog) or catalog.get(id,{}).get("slot","") in ARMS

static func empty_parts(group: String) -> Dictionary:
 var parts := {}
 for layer: String in LAYERS[group]: parts[layer] = ""
 return parts

static func has_pieces(parts: Dictionary) -> bool:
 return parts.values().any(func(piece): return not piece.is_empty())

static func conflict(parts: Dictionary, group: String) -> String:
 if group == "body":
  if parts.get("base","").is_empty() and has_pieces(parts):
   return "Remove the upper body layers first; they need Body I."
  return ""
 if parts.get("shell","").is_empty() and not parts.get("face","").is_empty():
  return "Remove the guard before removing the shell; Head III requires Head II."
 if parts.get("padding","").is_empty():
  for layer in ["shell","decor","favor","seal"]:
   if not parts.get(layer,"").is_empty(): return "Remove the layers that require the liner before removing it; they need Head I."
 return ""

static func layer_designs(catalog: Dictionary, group: String, layer: String) -> Array:
 # Sort explicitly so new generation never depends on JSON insertion order.
 var out := []
 for id: String in catalog:
  if not is_layer(id,catalog): continue
  var design: Dictionary = catalog[id]
  if design.group == group and design.layer == layer: out.append(id)
 out.sort()
 return out

static func pick(catalog: Dictionary, group: String, layer: String, ticket: int) -> String:
 var ids := layer_designs(catalog,group,layer)
 # The ordinal intervals are also used to reconstruct already-issued human
 # kits (and saved wear), the opening company and historical shelf draws.
 for line: Array in RESTOCK_ONLY.values():
  for id: String in line: ids.erase(id)
 ids.erase(QUILTED_TABARD)
 ids.erase(LEATHER_BACKED_MANTLE)
 ids.erase(PADDED_TEMPLE_WRAP)
 ids.erase(RIVETED_MANTLE)
 return ids[posmod(ticket,ids.size())]

static func ticket(seed: int, source: Variant, position: String) -> int:
 return JSON.stringify([PROFILE,seed,source,position]).sha256_text().left(8).hex_to_int()

static func companion(catalog: Dictionary, seed: int, candidate: Dictionary, founder_index: int) -> Dictionary:
 var body := empty_parts("body")
 var head := empty_parts("head")
 var choice: int = seed + founder_index if founder_index >= 0 else ticket(seed,candidate.person_seed,"recruit")
 body.base = pick(catalog,"body","base",choice)
 if founder_index == 0:
  # First founder carries a separate layer over each foundation. The home
  # shelf offers a different foundation, not a replacement whole kit.
  body.mail = pick(catalog,"body","mail",choice)
  head.shell = pick(catalog,"head","shell",choice)
 if founder_index == 0 or choice % 3 != 2:
  head.padding = pick(catalog,"head","padding",choice)
 return {"body":body,"head":head}

static func opening_stock(catalog: Dictionary, seed: int, town: String, serial: int) -> String:
 if town != "ashwick": return ""
 if serial == 1: return pick(catalog,"body","base",seed+1)
 if serial == 2: return pick(catalog,"head","padding",seed+1)
 return ""

static func valid_inventory(d: Dictionary, catalog: Dictionary) -> bool:
 # Runs after the inherited shape/Rarity fence and before the existing full
 # restore (including UID, assignment, condition and ledger validation).
 var attached := {}
 for person: Dictionary in d.soldiers:
  if person.gear.size() != GEAR.size(): return false
  for slot: String in GEAR:
   if not person.gear.get(slot) is String: return false
  if not person.alive: continue
  for group: String in LAYERS:
   var uid: String = person.gear[group]
   if attached.has(uid): return false
   attached[uid] = group
 for uid: Variant in d.items:
  var item: Dictionary = d.items[uid]
  if not uid is String or not item.get("id") is String or item.id != uid or not item.get("condition") is int or item.has("legacy_weight"): return false
  if not catalog.has(item.definition): return false
  if item.definition in ASSEMBLY.values():
   # Same kit record in either custody: a living gear reference wears it;
   # otherwise the root and its children are in company stores.
   var group: String = catalog[item.definition].slot
   if attached.get(uid,group) != group or item.size() != 4 or item.condition != 0: return false
   if not item.get("parts") is Dictionary or item.parts.size() != LAYERS[group].size(): return false
   for layer: String in LAYERS[group]:
    var child = item.parts.get(layer)
    if not child is String: return false
    if child.is_empty(): continue
    if not d.items.has(child): return false
    var design: Dictionary = catalog.get(d.items[child].definition,{})
    if design.get("group") != group or design.get("layer") != layer: return false
   if not conflict(item.parts,group).is_empty(): return false
  elif not tradeable(item.definition,catalog): return false
  elif is_layer(item.definition,catalog):
   if item.has("named"):
    if not NamedMail.owned(uid,d.items,d.get("named_rewards"),d.get("next_item"),catalog): return false
   elif item.size() != 4 or not item.has("instance_roll"): return false
 return true
