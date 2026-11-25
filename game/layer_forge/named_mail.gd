extends RefCounted
## One approved physical counterpart, not a replacement draw or a Named pool.
const Named = preload("res://src/named_equipment.gd")
const TOKEN := "mail"
const PRECURSOR := "march_mail"
const PART := "forge:b2_laced"
const SITE := "dungeon_barrow_2"
const FLOOR := 0
const ROOM := 2
const KEY := "dungeon_barrow_2/f0/r2"
const SEED := 7391
const MAXIMUM := 62
const WEIGHT := 9
const FRONT := "res://layer_forge/art/body/b2_laced_wulfric_marchers_mail.png"
const ICON := "res://layer_forge/art/body/b2_laced_wulfric_marchers_mail_icon.png"
const DESIGN := {"name":"Lace-edged Hauberk","slot":"body","group":"body","layer":"mail","durability":51,"weight":10,"price":42}
const PACKET := {
 "version":1,"seed":1057367312,"source":"Raven Stone Tomb",
 "name":"Wulfric's Marcher's mail","lore":"Made for Wulfric the Warden. Recovered from Raven Stone Tomb.",
 "bonuses":{"protection":21,"weight":15},
}

# A matching class in a future world does not inherit this paint/claim.
# Key/name/roll alone are not identity: compare the registered generation tuple.
static func registered_site(region: Dictionary, seed_number: int, version: int, site: Dictionary) -> bool:
 if version != 6 or seed_number != SEED or region.get("generator") != 3 or region.get("seed") != SEED: return false
 if site.get("seed") != 718871586 or site.get("tier") != 1 or not site.get("place") is Dictionary: return false
 var p: Dictionary = site.place
 return p.get("id") == SITE and p.get("kind") == "dungeon" and p.get("x") == 1104 and p.get("y") == 416 and p.get("name") == PACKET.source

static func valid_packet(item: Dictionary, catalog: Dictionary) -> bool:
 if not item.get("definition") is String or item.definition != PART or not item.has("named") or item.has("instance_roll") or item.has("legacy_weight"): return false
 var design: Dictionary = catalog.get(PART,{})
 if design.size() != DESIGN.size(): return false
 for field in DESIGN:
  # The unchanged JSON catalogue supplies its numbers as floats at runtime.
  if design.get(field) != DESIGN[field]: return false
 return Named.valid(item,catalog) and item.named == PACKET

static func valid_row(row: Variant, catalog: Dictionary) -> bool:
 if not row is Dictionary or row.size() != 2 or not row.get("claimed") is String or not row.get("item") is Dictionary: return false
 var item: Dictionary = row.item
 return item.size() == 3 and item.get("condition") is int and item.condition == MAXIMUM and valid_packet(item,catalog)

static func uid_valid(uid: Variant, next_uid: int) -> bool:
 if not uid is String or not uid.begins_with("item_"): return false
 var suffix: String = uid.trim_prefix("item_")
 if not suffix.is_valid_int(): return false
 var serial := int(suffix)
 return serial > 0 and serial < next_uid and uid == "item_%03d" % serial

static func valid_leaf(item: Variant, uid: String, catalog: Dictionary) -> bool:
 if not item is Dictionary or item.size() != 4 or not item.get("id") is String or item.id != uid: return false
 if not item.get("condition") is int or item.condition < 0 or item.condition > MAXIMUM: return false
 return valid_packet(item,catalog)

static func valid_claim(row: Variant, inventory: Dictionary, next_uid: int, catalog: Dictionary) -> bool:
 if not valid_row(row,catalog): return false
 var uid: String = row.claimed
 if uid.is_empty(): return true
 if not uid_valid(uid,next_uid): return false
 # Sale or loss removes the leaf, not the historical claim.
 return not inventory.has(uid) or valid_leaf(inventory[uid],uid,catalog)

static func owned(uid: String, inventory: Dictionary, rewards: Variant, next_uid: Variant, catalog: Dictionary) -> bool:
 if not rewards is Dictionary or not next_uid is int or not uid_valid(uid,next_uid): return false
 var row = rewards.get(KEY)
 return valid_row(row,catalog) and row.claimed == uid and valid_leaf(inventory.get(uid),uid,catalog)

static func cleared(site: Dictionary, room: Dictionary) -> bool:
 if not site.get("entered") is bool or not site.entered or not room.get("seen") is bool or not room.seen: return false
 if not room.get("visited") is bool or not room.visited or not room.get("cleared") is bool or not room.cleared: return false
 if not room.get("wear") is Array or room.wear.size() != 2: return false
 for guardian in room.wear:
  if not guardian is Dictionary or not guardian.get("hp") is int or guardian.hp != 0: return false
 return true

static func valid_projection(part: Dictionary, catalog: Dictionary, claimed_mail: String) -> bool:
 # The expected UID comes from the already joined company, not the part being
 # examined. Standalone restore/enemy wear have no such authority.
 if claimed_mail.is_empty() or not part.get("item") is String or part.item != claimed_mail: return false
 if not valid_packet(part,catalog) or part.size() != (10 if part.has("hollow_slot") else 9): return false
 if part.get("hollow_slot","body") != "body" or part.get("group") != "body" or part.get("layer") != "mail" or part.get("pool") != "armor": return false
 if not part.get("maximum") is int or part.maximum != MAXIMUM or not part.get("weight") is int or part.weight != WEIGHT: return false
 return part.get("condition") is int and part.condition >= 0 and part.condition <= MAXIMUM
