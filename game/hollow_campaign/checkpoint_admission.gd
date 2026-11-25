extends RefCounted
## Extension type admission only. Never replace current full Campaign.restore.
const Rarity = preload("res://hollow_campaign/rarity.gd")
# Derived battle/preview authority is rebuilt, never checkpoint input. Reject
# forged capacity/effect projections instead of silently retaining or dropping them.
const RUNTIME_ONLY = ["capacity","hollow_capacity","hollow_systems","equipment_slots","inventory_effects","inventory_equipment_base","forge_named_mail_uid"]
static func no_runtime_authority(record: Dictionary) -> bool:
 for key in RUNTIME_ONLY:
  if record.has(key): return false
 return true
static func valid(d: Variant) -> bool:
 if not d is Dictionary or not d.get("hollow_campaign") is int or d.hollow_campaign != 1: return false
 if not no_runtime_authority(d): return false
 if not d.get("version") is int or d.version != 34 or not d.get("phase") is String or d.phase != "camp" or d.get("battle") != null: return false
 if not d.get("soldiers") is Array or not d.get("items") is Dictionary or not d.get("seed") is int: return false
 for person in d.soldiers:
  if not person is Dictionary or not person.get("person_seed") is int or not Rarity.valid_person(person.get("companion_roll")): return false
  if not no_runtime_authority(person) or not person.get("alive") is bool or not person.get("gear") is Dictionary: return false
  if person.alive:
   for group in ["body","head"]:
    var uid = person.gear.get(group)
    if not uid is String or uid.is_empty() or not d.items.get(uid) is Dictionary: return false
    var owner: Dictionary = d.items[uid]
    if not owner.get("definition") is String or owner.definition != group+"_kit" or not owner.get("parts") is Dictionary: return false
 for item in d.items.values():
  if not item is Dictionary or not no_runtime_authority(item) or not item.get("definition") is String: return false
  if item.definition in ["body_kit","head_kit"] and item.has("instance_roll"): return false
  if not Rarity.valid_item(item): return false
 return true
