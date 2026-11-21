extends RefCounted
## Pure successor trial: independent immutable identity/stat streams, not donor stats.
## Item percentages 0..8/18/25 (common/rare/legendary); BB2's own base is scaled.
## These overlapping trial budgets are provisional, not campaign-balance claims.
const VERSION: int = 1
const ITEM_CEILINGS: Dictionary = {"common":8, "rare":18, "legendary":25}

static func _draw(seed_number: int, kind: String, identity: Variant, stat: String, ceiling: int) -> int:
	var bytes: PackedByteArray = JSON.stringify([VERSION, seed_number, kind, identity, stat]).sha256_buffer()
	return int(bytes.decode_u32(0)) % (ceiling + 1)

static func _tier(seed_number: int, kind: String, identity: Variant) -> String:
	# Separate 10,000-ticket stream: 80/18/2 trial probabilities, not forced cohorts.
	var ticket: int = _draw(seed_number, kind, identity, "tier", 9999)
	return "common" if ticket < 8000 else "rare" if ticket < 9800 else "legendary"

## Person deltas independently add 0..2/4/7 BB2 points per supplied base stat.
## No growth, identity or background changes; no guaranteed superiority by tier.
const PERSON_CEILINGS: Dictionary = {"common":2, "rare":4, "legendary":7}

static func roll_person(seed_number: int, person_id: int, bases: Dictionary) -> Dictionary:
	if not _valid_seed(seed_number) or not _valid_person_id(person_id) or not _valid_bases(bases): return {}
	var tier: String = _tier(seed_number, "person", person_id)
	var values: Dictionary = {}
	for stat: String in bases:
		values[stat] = int(bases[stat]) + _draw(seed_number, "person", person_id, stat, int(PERSON_CEILINGS[tier]))
	return {"version":VERSION, "seed":seed_number, "person_id":person_id, "tier":tier, "bases":bases.duplicate(true), "values":values}

static func roll_item(seed_number: int, uid: String, definition: String) -> Dictionary:
	if not _valid_seed(seed_number) or not _valid_text(uid, 160) or not _valid_text(definition, 96): return {}
	var identity: Array = [uid, definition]
	var tier: String = _tier(seed_number, "item", identity)
	var percent: Dictionary = {}
	for stat: String in ["damage", "protection"]:
		percent[stat] = _draw(seed_number, "item", identity, stat, int(ITEM_CEILINGS[tier]))
	return {"version":VERSION, "seed":seed_number, "uid":uid, "definition":definition, "tier":tier, "percent":percent}

static func _valid_seed(value: Variant) -> bool:
	return value is int and value >= 1 and value <= 2147483646

static func _valid_text(value: Variant, maximum: int) -> bool:
	if not value is String or value.is_empty() or value.length() > maximum: return false
	for at: int in value.length():
		if value.unicode_at(at) < 32: return false
	return true

static func _valid_person_id(value: Variant) -> bool:
	return value is int and value >= 0 and value <= 2147483646

static func _valid_bases(value: Variant) -> bool:
	if not value is Dictionary or value.is_empty() or value.size() > 32: return false
	for stat: Variant in value:
		if not _valid_text(stat, 64) or not value[stat] is int: return false
		# Schema safety bound only: reject, never clip a supplied base or effective stat.
		if value[stat] < -10000 or value[stat] > 10000: return false
	return true

static func valid_person(metadata: Variant) -> bool:
	if not metadata is Dictionary or metadata.size() != 6: return false
	if not metadata.get("version") is int or metadata.version != VERSION or not _valid_seed(metadata.get("seed")): return false
	if not _valid_person_id(metadata.get("person_id")) or not metadata.get("tier") is String: return false
	if not _valid_bases(metadata.get("bases")) or not metadata.get("values") is Dictionary: return false
	if metadata.values.size() != metadata.bases.size(): return false
	for stat: String in metadata.bases:
		if not metadata.values.get(stat) is int: return false
	return metadata == roll_person(metadata.seed, metadata.person_id, metadata.bases)

static func valid_item(item: Dictionary) -> bool:
	if not item.has("instance_roll"): return true
	if item.has("named"): return false
	var metadata: Variant = item.instance_roll
	if not metadata is Dictionary or metadata.size() != 6: return false
	if not metadata.get("version") is int or metadata.version != VERSION or not _valid_seed(metadata.get("seed")): return false
	if not _valid_text(item.get("definition"), 96) or not _valid_text(metadata.get("uid"), 160): return false
	var uid: Variant = item.get("id", item.get("item"))
	if not uid is String or uid != metadata.uid: return false
	if item.has("item") and item.item != uid: return false
	if metadata.get("definition") != item.definition or not metadata.get("tier") is String: return false
	if not metadata.get("percent") is Dictionary or metadata.percent.size() != 2: return false
	for stat: String in ["damage", "protection"]:
		if not metadata.percent.get(stat) is int: return false
	return metadata == roll_item(metadata.seed, uid, item.definition)

static func effective_definition(item: Dictionary, ordinary: Dictionary) -> Dictionary:
	if not item.has("instance_roll"): return ordinary
	if not valid_item(item): return {}
	var out: Dictionary = ordinary.duplicate(true)
	# Weapon bundles and ammo store rounds in durability, not protection.
	if out.has("durability") and (out.has("group") or out.get("slot") == "shield"):
		out.durability = int(out.durability) + ceili(float(out.durability) * int(item.instance_roll.percent.protection) / 100.0)
	return out

static func effective_weapon(item: Dictionary, ordinary: Dictionary) -> Dictionary:
	if not item.has("instance_roll"): return ordinary
	if not valid_item(item): return {}
	var out: Dictionary = ordinary.duplicate(true)
	var percent: int = item.instance_roll.percent.damage
	for stat: String in ["min", "max"]:
		if out.has(stat): out[stat] = int(out[stat]) + ceili(float(out[stat]) * percent / 100.0)
	return out

static func summary(item: Dictionary) -> String:
	if not item.has("instance_roll"): return ""
	if not valid_item(item): return "INVALID INSTANCE ROLL"
	var metadata: Dictionary = item.instance_roll
	return "%s · +%d%% damage / +%d%% protection (where applicable; BB2 trial)" % [metadata.tier.capitalize(), metadata.percent.damage, metadata.percent.protection]

static func tier_color(tier: String) -> Color:
	match tier:
		"named": return Color("ff7628")
		"rare": return Color("72b9ed")
		"legendary": return Color("e3be68")
		_: return Color("d2d0c6")
