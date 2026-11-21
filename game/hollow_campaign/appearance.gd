extends "res://hollow_inventory/appearance.gd"
const WeaponFits = preload("res://painted_merge/weapon_fits/extension.gd")
var _weapon_fits = WeaponFits.new()
const CrossbowFits = preload("res://crossbows/art/binding.gd")
var _crossbow_fits = CrossbowFits.new()
const FaceIdentity = preload("res://companion_variety/face_identity.gd")
const FaceProducer = preload("res://companion_variety/foundation_producer.gd")
var _face_producer = FaceProducer.new()

func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
 var reason:=CrossbowFits.validate(unit,catalog)
 if not reason.is_empty():return {"ok":false,"texture":null,"error":reason,"signature":{},"issues":[]}
 var result: Dictionary = super.describe(unit,catalog)
 if not result.get("ok",false):
  result.texture = null
  for entry: Dictionary in result.get("signature",{}).values():entry.visible=false;entry.painted=false
 return result

func _present(detached: Dictionary, signature: Dictionary) -> Dictionary:
 if detached.has("face_id"):return _face_producer.present_face(self,detached,signature)
 if CrossbowFits.wants(signature):return _crossbow_fits.present_crossbow(self,detached,signature)
 if WeaponFits.needed(detached):return _weapon_fits.present_current(self,detached,signature)
 return super._present(detached,signature)

## No cosmetic authority or inferred family proxies. Unmapped actual gear is
## omitted by the pinned compositor with exact definition/UID diagnostics.
const CompanionModelRarity = preload("res://hollow_campaign/rarity.gd")
const COMPANION_MODEL_VERSION := "bb2-companion-model-bag-v1"

# Cosmetic only: immutable company IDs own positions, not names, gear or stats.
# Recomputed locally; never consumes a campaign, battle, person or global stream.
static func _companion_model(unit: Dictionary, fallback: String) -> String:
 return "duelist" if unit.get("side",-1) == 0 else fallback

static func _model_bag(campaign_seed: int, bag_index: int) -> Array:
 var rng := RandomNumberGenerator.new()
 rng.seed = JSON.stringify([COMPANION_MODEL_VERSION,campaign_seed,bag_index]).sha256_buffer().decode_u32(0)
 var bag := APPEARANCES.duplicate()
 for index in range(bag.size()-1,0,-1):
  var other := rng.randi_range(0,index)
  var held: String = bag[index];bag[index] = bag[other];bag[other] = held
 return bag

func payload(unit: Dictionary, catalog: Dictionary) -> Dictionary:
 var out := super.payload(unit,catalog)
 out.detached.appearance = _companion_model(unit,out.detached.appearance)
 out.detached.merge(FaceIdentity.selection(unit,out.detached.appearance))
 out.issues=out.issues.filter(func(issue):return issue.get("definition","") not in CrossbowFits.Assets.IDS)
 # Nine canonical cards do not erase inherited inner/reinforcement parts.
 # Preserve every actual physical owner; no invented support or duplicate paint.
 for part: Dictionary in unit.get("armor_parts",[]):
  var uid := str(part.get("id",part.get("item","")))
  if uid.is_empty() or out.signature.values().any(func(entry):return entry.get("item","") == uid):continue
  var slot := str(part.get("group","armor"))+"/"+str(part.get("layer","part"))
  var definition := str(part.get("definition",""))
  var entry := _record(slot,definition,part,catalog,"")
  out.signature[slot] = entry
  _omit(entry,out.issues,"Retained physical assembly layer; no separate fitted paint. Canonical outfit is a presentation selection only; inner protection and wear remain authoritative.")
 return out
