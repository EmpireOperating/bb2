extends "res://prototype/character.gd"
## Only the BB2 world/basis/shadow/selection seam is inherited. No old body resolver.
const Appearance = preload("res://hollow_experiment/appearance.gd")
const ColorIdentity = preload("res://sprite_study/color_identity.gdshader")
# Source-coordinate stance centers: midpoint of both low-foot silhouettes, not
# the donor's one-lowest-toe X. Y remains the exact donor ground contact row.
# Second component is measured immutable base alpha top, never weapon bounds.
const STANCE_TOP := {"archer":Vector2(115,10),"duelist":Vector2(162,18),"medic":Vector2(125,12),"occultist":Vector2(112,12),"polearm":Vector2(133,30),"shieldbearer":Vector2(139,11)}
const BODY_HEIGHT := 1.94
static var _shared_appearance = Appearance.new()
var appearance = _shared_appearance
var _preview: Texture2D
var _diagnostics: Dictionary = {}

func refresh(unit: Dictionary, catalog: Dictionary) -> void:
	_refresh_impact(unit)
	if _illustration == null:
		_illustration = Node3D.new()
		_illustration.name = "Illustration"
		add_child(_illustration)
		_create_ground_shadow()
	for child in _illustration.get_children(): child.free()
	_preview = null
	_signature.clear()
	var result: Dictionary = appearance.describe(unit,catalog)
	_signature = result.get("signature",{}).duplicate(true)
	_diagnostics = {"ok":result.get("ok",false),"source_kind":"pinned-hollow-march-source-pngs","errors":[],"issues":result.get("issues",[]).duplicate(true),
		"notes":result.get("notes",[]).duplicate(true),"outfit_owner":result.get("outfit_owner",{}).duplicate(true),"visual_id":int(unit.get("visual_id",0)),"stack":[],"asset_errors":{}}
	get_node("GroundShadow").visible = result.get("ok",false)
	if not result.get("ok",false):
		_diagnostics.errors.append(result.get("error","Composition refused"))
		var source_path: String = result.get("source_path","")
		if not source_path.is_empty(): _diagnostics.asset_errors[source_path] = result.get("error","Composition refused")
		_diagnostics.notes.append("Required Hollow March art refused: "+source_path+" · "+str(result.get("error","Composition refused")))
		for entry in _signature.values(): entry.visible = false; entry["composite_blocked"] = true
		return
	_preview = result.texture
	var plan: Dictionary = result.plan
	var frame: Dictionary = plan.frame
	var family: String = plan.appearance
	var origin := Vector2(float(frame.base_origin[0]),float(frame.base_origin[1]))
	var canvas := Vector2(float(frame.canvas[0]),float(frame.canvas[1]))
	var stance: Vector2 = STANCE_TOP[family]
	var foot := Vector2(stance.x+origin.x,float(frame.foot_anchor[1]))
	var pixel_size := BODY_HEIGHT/(foot.y-origin.y-stance.y)
	_diagnostics.merge({"appearance":family,"identity":family,"canvas":canvas,"base_origin":origin,"foot_pixel":foot,"donor_foot_pixel":frame.foot_anchor.duplicate(),
		"pixel_size":pixel_size,"body_height":BODY_HEIGHT,"stack":plan.layers.duplicate(true),"plan":plan.duplicate(true)},true)
	_signature.foundation = {"definition":"","item":"","asset":plan.base.path,"art_family":family,"painted":true,"visible":true,"ordinary_clothing":true,"visual_id":int(unit.get("visual_id",0)),"identity":family}
	var sprite := Sprite3D.new()
	sprite.name = "Composite"
	sprite.texture = _preview
	sprite.pixel_size = pixel_size
	sprite.offset = Vector2(canvas.x/2.0-foot.x,foot.y-canvas.y/2.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.alpha_scissor_threshold = 0.12
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.shaded = false
	sprite.double_sided = true
	sprite.no_depth_test = false
	sprite.modulate = Color.WHITE
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = ColorIdentity
	material.set_shader_parameter("source_texture",_preview)
	sprite.material_override = material
	sprite.set_meta("slot","composite")
	_illustration.add_child(sprite)
	_sync_billboard_depth()

func preview_texture() -> Texture2D:
	return _preview

func render_diagnostics() -> Dictionary:
	return _diagnostics.duplicate(true)
