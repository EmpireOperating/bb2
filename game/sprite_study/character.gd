extends "res://prototype/character.gd"
## Equipment selection belongs ONLY to the unchanged inherited resolver.
const SpriteCompositor = preload("res://sprite_study/compositor.gd")
const ColorIdentity = preload("res://sprite_study/color_identity.gdshader")
const AUTHORED := ["foundation","body_quilt","body_mail","body_brigandine","head_nasal","head_kettle","weapon_sword","weapon_axe","weapon_spear","weapon_bow","shield_kite","shield_round"]
static var _shared_compositor = SpriteCompositor.new()
var compositor = _shared_compositor
var _stack: Array = []
var _preview: Texture2D
var _render_errors: Array = []
var _asset_errors: Dictionary = {}

func refresh(unit: Dictionary, catalog: Dictionary) -> void:
	_stack.clear()
	super.refresh(unit,catalog)
	if _signature.get("head/shell",{}).get("painted",false):
		_signature.foundation.asset = "foundation_helmet.png"
		_signature.foundation.art_family = "foundation_helmet"
		for entry in _stack:
			if entry.asset == "foundation": entry.asset = "foundation_helmet"
	# These paintings are complete outfits, not independently cut inner sleeves.
	# Retain every actual part in diagnostics while suppressing covered paint only.
	var outer_slot := "body/outer" if _signature.get("body/outer",{}).get("painted",false) else "body/mail" if _signature.get("body/mail",{}).get("painted",false) else ""
	for slot in ["body/base","body/mail"]:
		if not outer_slot.is_empty() and slot != outer_slot and _signature.has(slot):
			_signature[slot].visible = false
			_signature[slot]["suppressed_by"] = outer_slot
			_signature[slot]["visibility_reason"] = "Covered by complete authored outfit; actual equipment remains unchanged."
	_stack = _stack.filter(func(entry): return _signature[entry.slot].visible)
	_stack.sort_custom(func(a,b): return a.priority < b.priority)
	var result: Dictionary = compositor.compose(_stack)
	_preview = result.texture
	var prior_errors := _render_errors.duplicate()
	_render_errors = result.errors.duplicate()
	_asset_errors = result.asset_errors.duplicate()
	get_node("GroundShadow").visible = _preview != null
	if _preview == null:
		for slot in _signature:
			_signature[slot].visible = false
			_signature[slot]["composite_blocked"] = true
			_signature[slot]["asset_error"] = _asset_errors.get(_signature[slot].art_family,"")
		if compositor.source_kind() == "source-pngs" and _render_errors != prior_errors:
			push_error("Sprite study composite refused: "+"; ".join(_render_errors))
		return
	var sprite := Sprite3D.new()
	sprite.name = "Composite"
	sprite.texture = _preview
	sprite.pixel_size = SpriteCompositor.WORLD_PIXEL_SIZE
	sprite.offset = Vector2(SpriteCompositor.CANVAS.x/2.0-SpriteCompositor.FOOT.x,SpriteCompositor.FOOT.y-SpriteCompositor.CANVAS.y/2.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.alpha_scissor_threshold = 0.12
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.shaded = false
	sprite.double_sided = true
	sprite.no_depth_test = false
	sprite.modulate = Color.WHITE
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The frozen Compatibility world applies Filmic even to unshaded artwork.
	# Compensate only its sampled RGB, never the shared image, alpha or plane.
	# Camera facing remains owned by the inherited Illustration global basis.
	var material := ShaderMaterial.new()
	material.shader = ColorIdentity
	material.set_shader_parameter("source_texture",_preview)
	sprite.material_override = material
	sprite.set_meta("slot","composite")
	_illustration.add_child(sprite)

func _add_layer(slot: String, asset: String, family: String, definition: String, item: Dictionary, catalog_color: Color, priority: int, fallback: bool = false) -> void:
	var painted: bool = asset in AUTHORED and not fallback
	if slot == "weapon" and definition not in ["sword","axe","spear","bow"]: painted = false
	if slot == "shield" and definition not in ["shield","round_shield"]: painted = false
	var maximum := int(item.get("maximum",0))
	var condition := int(item.get("condition",maximum))
	var worn := 1.0-clampf(float(condition)/maximum,0.0,1.0) if maximum > 0 else 0.0
	var tint := Color.WHITE.lerp(catalog_color,0.30) if slot == "body/base" else Color.WHITE
	tint = tint.lerp(Color("363127"),worn*0.64)
	var reason := "" if painted else "Not authored in this bounded subset; upstream fallback omitted." if fallback else "Not authored in this bounded subset; no cosmetic substitute."
	_signature[slot] = {"definition":definition,"family":family,"item":item.get("item",item.get("id","")),
		"asset":asset+".png" if painted else "","art_family":asset if painted else "","asset_root":SpriteCompositor.ASSET_ROOT,
		"priority":priority,"condition":condition,"maximum":maximum,"broken":maximum > 0 and condition <= 0,
		"color":tint.to_html(),"catalog_color":catalog_color.to_html(),"painted":painted,"visible":painted,
		"fallback":fallback or not painted,"fallback_reason":reason,"ordinary_clothing":slot == "foundation"}
	if not painted: return
	_stack.append({"slot":slot,"asset":asset,"priority":priority,"tint":tint.to_html()})
	if slot == "weapon":
		var grip := "grip_"+family
		_stack.append({"slot":"weapon_grip","asset":grip,"priority":21,"tint":Color.WHITE.to_html()})
		_signature.weapon_grip = _signature[slot].duplicate(true)
		_signature.weapon_grip.merge({"asset":grip+".png","art_family":grip,"priority":21,"support_for":"weapon","color":Color.WHITE.to_html(),"condition":0,"maximum":0,"broken":false},true)

func render_diagnostics() -> Dictionary:
	return {"ok":_preview != null,"errors":_render_errors.duplicate(),"asset_errors":_asset_errors.duplicate(),
		"source_kind":compositor.source_kind(),"canvas":SpriteCompositor.CANVAS,"foot_pixel":SpriteCompositor.FOOT,
		"pixel_size":SpriteCompositor.WORLD_PIXEL_SIZE,"stack":_stack.duplicate(true),"composite_builds":compositor.builds}

func preview_texture() -> Texture2D:
	return _preview
