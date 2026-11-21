extends "res://sprite_study/character.gd"
## Same production resolver/shader/composite; identity is never gear.
const CompanyCompositor = preload("res://company_loop/compositor.gd")
static var _company_compositor = CompanyCompositor.new()
var _visual_id := 0
var _identity := 0
var _helmet_context := false
var _alive := true
var _motion_kind := ""
var _motion_elapsed := 0.0
var _motion_duration := 0.0
var _motion_peak := 0.0
var _motion_world := Vector3.ZERO

func _init() -> void:
	compositor = _company_compositor

func refresh(unit: Dictionary, catalog: Dictionary) -> void:
	# The domain owns visual_id: never infer it from a battle index or gear.
	var next_id := int(unit.get("visual_id",0))
	_alive = int(unit.get("hp",1)) > 0
	if next_id != _visual_id or not _alive: cancel_motion()
	_visual_id = next_id
	_identity = CompanyCompositor.identity_index(_visual_id)
	_helmet_context = false
	super.refresh(unit,catalog)
	_stack = CompanyCompositor.contextual_stack(_stack)
	var owner_slot := CompanyCompositor.outfit_slot(_stack)
	var outfit_owner := {}
	if not owner_slot.is_empty():
		var entry: Dictionary = _signature[owner_slot]
		outfit_owner = {"slot":owner_slot,"item":entry.item,"definition":entry.definition,"asset":entry.asset}
	for slot in ["body/base","body/mail","body/outer"]:
		if _signature.has(slot) and _signature[slot].art_family in CompanyCompositor.OUTFIT_ASSETS.values():
			_signature[slot]["owns_lower_body"] = slot == owner_slot
			_signature[slot]["owns_gloves"] = slot == owner_slot
	if not owner_slot.is_empty():
		var owner: Dictionary = _signature[owner_slot]
		var glove: String = CompanyCompositor.GLOVE_ASSETS[owner.art_family]
		_signature.glove_pair = owner.duplicate(true)
		_signature.glove_pair.merge({"asset":glove+".png","art_family":glove,"asset_root":CompanyCompositor.GLOVE_ROOT,"priority":19,"support_for":owner_slot,"outfit_owner":outfit_owner.duplicate(true)},true)
		_signature.glove_pair.erase("owns_lower_body")
		_signature.glove_pair.erase("owns_gloves")
		_signature.glove_pair["asset_error"] = _asset_errors.get(glove,"")
		for entry in _stack:
			if entry.slot != "weapon_grip": continue
			# Keep the physical weapon identity/condition; glove wear belongs to
			# the explicit outfit owner rather than an invented protective item.
			_signature.weapon_grip.merge({"asset":glove+".png","art_family":glove,"asset_root":CompanyCompositor.GLOVE_ROOT,"color":owner.color,
				"clip_mask":entry.clip_mask+".png","clip_mask_root":SpriteCompositor.ASSET_ROOT,"clip_mask_error":_asset_errors.get(entry.clip_mask,""),
				"outfit_owner":outfit_owner.duplicate(true),"wear_condition":owner.condition,"wear_maximum":owner.maximum,"asset_error":_asset_errors.get(glove,"")},true)
	_signature.foundation["hand_keep_mask"] = CompanyCompositor.HAND_KEEP_MASK+".png" if not owner_slot.is_empty() else ""
	_signature.foundation["hand_keep_mask_root"] = CompanyCompositor.GLOVE_ROOT if not owner_slot.is_empty() else ""
	_signature.foundation["hand_keep_mask_error"] = _asset_errors.get(CompanyCompositor.HAND_KEEP_MASK,"")
	_signature.foundation["outfit_owner"] = outfit_owner
	_signature.foundation["keep_mask"] = CompanyCompositor.KEEP_MASK+".png" if not owner_slot.is_empty() else ""
	_signature.foundation["keep_mask_root"] = CompanyCompositor.OUTFIT_ROOT if not owner_slot.is_empty() else ""
	_signature.foundation["keep_mask_error"] = _asset_errors.get(CompanyCompositor.KEEP_MASK,"")
	var foundation := CompanyCompositor.foundation_asset(_identity,_helmet_context)
	_signature.foundation.asset = foundation+".png"
	_signature.foundation.art_family = foundation
	_signature.foundation.asset_root = CompanyCompositor.IDENTITY_ROOT if _identity != 0 else SpriteCompositor.ASSET_ROOT
	_signature.foundation["visual_id"] = _visual_id
	_signature.foundation["identity"] = CompanyCompositor.IDENTITIES[_identity]
	_signature.foundation["helmet_context"] = _helmet_context
	if _preview == null:
		_signature.foundation["asset_error"] = _asset_errors.get(foundation,"")
	if _preview == null or (_motion_kind == "shield" and not _signature.get("shield",{}).get("visible",false)):
		cancel_motion()
	else:
		_apply_motion()

func _add_layer(slot: String, asset: String, family: String, definition: String, item: Dictionary, catalog_color: Color, priority: int, fallback: bool = false) -> void:
	super._add_layer(slot,asset,family,definition,item,catalog_color,priority,fallback)
	if slot.begins_with("body/") and _signature[slot].painted and CompanyCompositor.OUTFIT_ASSETS.has(asset):
		var outfit: String = CompanyCompositor.OUTFIT_ASSETS[asset]
		_stack.back().asset = outfit
		_signature[slot].asset = outfit+".png"
		_signature[slot].art_family = outfit
		_signature[slot].asset_root = CompanyCompositor.OUTFIT_ROOT
	if slot == "foundation":
		_stack.back().asset = CompanyCompositor.foundation_asset(_identity,false)
	elif slot == "head/shell" and _signature[slot].painted:
		_helmet_context = true
		_stack[0].asset = CompanyCompositor.foundation_asset(_identity,true)

func play_attack(direction: Vector3) -> void:
	cancel_motion()
	if not _can_move() or not direction.is_finite(): return
	var planar := Vector3(direction.x,0,direction.z)
	if planar.length_squared() < 0.000001: return
	_motion_kind = "attack"
	_motion_duration = 0.22
	_motion_peak = 0.065
	_motion_world = planar.normalized()*0.10

func play_hit(kind: String = "hit") -> void:
	cancel_motion()
	if kind == "stagger": kind = "hit"
	if not _can_move() or kind not in ["hit","shield","block"]: return
	if kind != "hit" and not _signature.get("shield",{}).get("visible",false): return
	_motion_kind = "hit" if kind == "hit" else "shield"
	_motion_duration = 0.18 if kind == "hit" else 0.20
	_motion_peak = 0.05 if kind == "hit" else 0.055
	var camera := get_viewport().get_camera_3d()
	var right := camera.global_basis.x.normalized() if camera != null else Vector3.RIGHT
	_motion_world = right*(-0.045 if kind == "hit" else -0.025)

func cancel_motion() -> void:
	_motion_kind = ""
	_motion_elapsed = 0.0
	_motion_duration = 0.0
	_motion_world = Vector3.ZERO
	if _illustration != null:
		_illustration.position = Vector3.ZERO
		for child in _illustration.get_children():
			if child is Sprite3D: child.scale = Vector3.ONE

func _can_move() -> bool:
	return _alive and is_inside_tree() and is_visible_in_tree() and _preview != null

func _process(delta: float) -> void:
	super._process(delta)
	if _motion_kind.is_empty(): return
	if not _can_move():
		cancel_motion()
		return
	if not is_finite(delta): return
	_motion_elapsed += maxf(delta,0.0)
	if _motion_elapsed >= _motion_duration:
		cancel_motion()
	else:
		_apply_motion()

func _apply_motion() -> void:
	if _illustration == null or _motion_kind.is_empty(): return
	var weight := smoothstep(0.0,_motion_peak,_motion_elapsed) if _motion_elapsed < _motion_peak else 1.0-smoothstep(_motion_peak,_motion_duration,_motion_elapsed)
	# Only Illustration moves; parent movement tweens and simulation anchors stay
	# authoritative. The unchanged picker reads the very same child transforms.
	_illustration.position = global_basis.inverse()*(_motion_world*weight)
	var sprite := _illustration.get_node_or_null("Composite")
	if sprite != null:
		# A tiny whole-guard pulse, not a separated shield animation or repaint.
		sprite.scale = Vector3(1.0+0.014*weight,1.0+0.008*weight,1) if _motion_kind == "shield" else Vector3.ONE

func _exit_tree() -> void:
	cancel_motion()

func render_diagnostics() -> Dictionary:
	var result := super.render_diagnostics()
	result["outfit_owner"] = _signature.get("foundation",{}).get("outfit_owner",{}).duplicate(true)
	result["cache_key"] = JSON.stringify(_stack)
	result["visual_id"] = _visual_id
	result["identity"] = CompanyCompositor.IDENTITIES[_identity]
	result["motion"] = _motion_kind
	result["motion_elapsed"] = _motion_elapsed
	return result
