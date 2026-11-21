extends "res://prototype/character.gd"
## Painted art adapter. Equipment selection remains inherited and authoritative.
const PAINT_ROOT := "res://visual_slice/assets/characters/"
const PAINT_PIXEL_SIZE := 0.00129
const PAINT_FOOT := Vector2(512,1460)
const PAINT_CANVAS := Vector2(1024,1536)
static var _paint_textures: Dictionary = {}
var _helmet_equipped := false

func refresh(unit: Dictionary, catalog: Dictionary) -> void:
	_helmet_equipped = false
	for part in unit.get("armor_parts",[]):
		if part is Dictionary and part.get("group","") == "head" and part.get("layer","") == "shell" and not str(part.get("definition","")).is_empty():
			_helmet_equipped = true
	super.refresh(unit,catalog)

# A source-family alias is explicitly diagnosed; omitted unsupported art never
# masquerades as another weapon or silently resurrects a legacy SVG sprite.
const PAINT_FAMILIES := {
	"foundation":"foundation", "body_quilt":"body_quilt",
	"body_mail":"body_mail", "body_mail_short":"body_mail", "body_mail_long":"body_mail",
	"body_brigandine":"body_brigandine", "body_leather":"body_brigandine",
	"body_plate":"body_brigandine", "body_patched":"body_brigandine", "body_scale":"body_mail",
	"body_shoulders":"body_shoulders", "body_collar":"body_collar",
	"head_nasal":"head_nasal", "head_kettle":"head_kettle", "head_cap":"head_cap", "head_bascinet":"head_nasal",
	"weapon_sword":"weapon_sword", "weapon_axe":"weapon_axe", "weapon_dagger":"weapon_dagger",
	"shield_round":"shield_round", "shield_kite":"shield_kite", "shield_buckler":"shield_buckler"
}

func _add_layer(slot: String, asset: String, family: String, definition: String, item: Dictionary, catalog_color: Color, priority: int, fallback: bool = false) -> void:
	var paint: String = PAINT_FAMILIES.get(asset,"")
	if slot == "foundation" and _helmet_equipped: paint = "foundation_helmet"
	var reason := ""
	if paint.is_empty():
		reason = "Not authored in bounded painted slice; identity retained, no substitute cosmetic gear."
	elif paint != asset and slot != "foundation":
		reason = "Painted broad-family proxy: " + paint + "; not an exact " + family + " design."
	elif family in ["cap","buckler","dagger"]:
		reason = "Derived source-family cut/scale; not separately generated design."
	elif fallback:
		reason = "Unknown catalog family uses upstream fallback selection."
	var maximum := int(item.get("maximum",0))
	var condition := int(item.get("condition",maximum))
	var worn := 1.0-clampf(float(condition)/maximum,0.0,1.0) if maximum > 0 else 0.0
	# Generated metal/skin retains its painted lighting. Full catalog multiplication
	# would darken it twice. Cloth takes a restrained true-definition tint.
	var tint := Color.WHITE
	if slot == "body/base": tint = Color.WHITE.lerp(catalog_color,0.30)
	tint = tint.lerp(Color("363127"),worn*0.64)
	_signature[slot] = {"definition":definition,"family":family,"asset":paint+".png" if not paint.is_empty() else "",
		"item":item.get("item",item.get("id","")),"color":tint.to_html(),"catalog_color":catalog_color.to_html(),
		"condition":condition,"maximum":maximum,"broken":maximum > 0 and condition <= 0,"priority":priority,
		"fallback":fallback or not reason.is_empty(),"fallback_reason":reason,"painted":not paint.is_empty(),"visible":not paint.is_empty(),
		"art_family":paint,"asset_root":PAINT_ROOT,"ordinary_clothing":slot == "foundation"}
	if paint.is_empty(): return
	_paint_sprite(slot,paint,definition,tint,priority)
	if slot == "weapon":
		# Original accepted glove, restricted to the actual weapon's support.
		# Source hands and faces from edited masters are never pasted into the actor.
		_paint_sprite("weapon_grip","grip_"+family,definition,Color.WHITE,21)

func _paint_sprite(slot: String, paint: String, definition: String, tint: Color, priority: int) -> void:
	var sprite := Sprite3D.new()
	sprite.name = slot.replace("/","_")
	sprite.texture = _paint_texture(paint)
	sprite.pixel_size = PAINT_PIXEL_SIZE
	sprite.offset = Vector2(PAINT_CANVAS.x/2-PAINT_FOOT.x,PAINT_FOOT.y-PAINT_CANVAS.y/2)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.alpha_scissor_threshold = 0.12
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.shaded = false
	sprite.double_sided = true
	sprite.no_depth_test = false
	sprite.render_priority = priority
	sprite.position.z = float(priority)*0.001
	sprite.modulate = tint
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.set_meta("slot",slot)
	sprite.set_meta("definition",definition)
	sprite.set_meta("paint_asset",paint)
	_illustration.add_child(sprite)

static func _paint_texture(asset: String) -> Texture2D:
	if not _paint_textures.has(asset):
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(PAINT_ROOT+asset+".png")) != OK:
			push_error("Painted character asset missing: " + asset)
			return null
		image.generate_mipmaps()
		_paint_textures[asset] = ImageTexture.create_from_image(image)
	return _paint_textures[asset]
