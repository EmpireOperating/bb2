extends RefCounted
## Cosmetic projection only. Never saved; no global/campaign/battle RNG calls.
const Rarity = preload("res://hollow_campaign/rarity.gd")
const VERSION := "bb2-companion-face-bag-v1"
const IDS := ["male-angular","male-broad","female-long","female-broad"]
const MANIFEST := "res://companion_variety/faces/manifest.json"
const MANIFEST_SHA := "627d1a49560b0fea014fdf261ac720285adcbc8a1ce47d4db1a7ac1e95d03675"
static func selection(unit: Dictionary, model: String) -> Dictionary:
 # Only reviewed/imported models opt in. Hostile/missing metadata stays original.
 var identity: Variant = unit.get("company_id")
 var roll: Variant = unit.get("companion_roll")
 if model not in ["shieldbearer","duelist","polearm","archer","medic","occultist"] or unit.get("side",-1) != 0 or not identity is int or identity < 0 or identity > 2147483646 or not Rarity.valid_person(roll):return {}
 # The reviewed six-model bag gives each model exactly one member per bag.
 # Single party body: every companion is a new duelist occurrence.
 var occurrence: int = identity if model == "duelist" else identity / 6
 var cycle: int = occurrence / 4
 var bag := _bag(roll.seed,model,cycle)
 if cycle > 0 and bag[0] == _bag(roll.seed,model,cycle-1)[-1]:
  var held: String = bag[0];bag[0] = bag[1];bag[1] = held
 var face: String = bag[occurrence % 4]
 return {"face_id":face,"face_presentation":"male" if face.begins_with("male-") else "female","face_version":VERSION}
static func _bag(seed_number: int, model: String, cycle: int) -> Array:
 var bag := IDS.duplicate()
 bag.sort_custom(func(a,b):return JSON.stringify([VERSION,seed_number,model,cycle,a]).sha256_text() < JSON.stringify([VERSION,seed_number,model,cycle,b]).sha256_text())
 return bag
static func foundation(detached: Dictionary, base: Dictionary) -> Dictionary:
 if FileAccess.get_sha256(MANIFEST) != MANIFEST_SHA:return {"ok":false,"error":"FACE_MANIFEST_HASH_MISMATCH"}
 var manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
 if not manifest is Dictionary or manifest.get("schema") != "bb2-reviewed-face-foundations-v1":return {"ok":false,"error":"FACE_MANIFEST_SCHEMA"}
 var model: Dictionary = manifest.appearances.get(detached.appearance,{})
 if model.get("base_sha256") != base.sha256:return {"ok":false,"error":"FACE_BASE_MISMATCH"}
 var face: Dictionary = model.get("variants",{}).get(detached.get("face_id",""),{}).duplicate(true)
 if face.is_empty():return {"ok":false,"error":"FACE_NOT_ADMITTED"}
 face["size"] = model.size
 face["version"] = VERSION
 face["base_sha256"] = base.sha256
 return {"ok":true,"foundation":face}
static func image(face: Dictionary) -> Dictionary:
 var path: String = face.path
 if FileAccess.get_sha256(path) != face.sha256:return {"ok":false,"error":"FACE_SOURCE_HASH_MISMATCH","source_path":path}
 var raw := Image.new()
 if raw.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or raw.get_format() != Image.FORMAT_RGBA8 or raw.get_size() != Vector2i(face.size[0],face.size[1]):return {"ok":false,"error":"FACE_SOURCE_INVALID","source_path":path}
 return {"ok":true,"image":raw}
