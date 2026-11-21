extends Node3D
## Original temporary layered illustration. Gameplay equipment is the only source
## of equipment visuals; appearance and aggregate protection are never consulted.
const ASSET_ROOT := "res://prototype/character_assets/"
const Arsenal = preload("res://src/arsenal.gd")
const WEAPON_FAMILIES := ["sword", "axe", "spear", "bow", "mace", "hammer", "dagger", "polearm", "crossbow", "bolas"]
const PIXEL_SIZE := 0.0048
const FOOT_PIXEL := Vector2(192, 486)
const CANVAS_SIZE := Vector2(384, 512)
const ARMOR_FAMILIES := {
	"body/base":["quilt"], "body/mail":["mail", "mail_short", "mail_long"],
	"body/outer":["leather", "plate", "brigandine", "scale", "patched"],
	"body/reinforce":["shoulders", "collar"], "body/cloth":["tabard", "surcoat", "sash"],
	"body/cloak":["cloak", "cape", "fur"], "head/padding":["liner", "hood"],
	"head/mail":["coif", "curtain"], "head/shell":["cap", "nasal", "kettle", "bascinet"],
	"head/face":["cheeks", "visor"], "head/decor":["wrap", "plume", "crest"]
}
const ARMOR_PRIORITY := {"body/cloak":-10, "body/base":1, "body/mail":2, "body/outer":3, "body/cloth":4, "body/reinforce":5, "head/padding":8, "head/mail":9, "head/shell":12, "head/face":13, "head/decor":14}
static var _textures: Dictionary = {}
var _illustration: Node3D
var _signature: Dictionary = {}
var _selected := false
var _impact_motion
var _impact_alive := true
var _impact_identity := -1

func _refresh_impact(unit: Dictionary) -> void:
	var identity := int(unit.get("visual_id",0))
	_impact_alive=int(unit.get("hp",1))>0
	if not _impact_alive or identity!=_impact_identity:cancel_motion()
	_impact_identity=identity

func play_hit(kind: String = "hit") -> void:
	cancel_motion()
	if not _impact_alive or kind not in ["hit","shield","block","stagger"]:return
	if kind in ["shield","block"] and not _signature.get("shield",{}).get("visible",false):return
	var camera := get_viewport().get_camera_3d()
	var right := camera.global_basis.x.normalized() if camera!=null else Vector3.RIGHT
	if _impact_motion==null:_impact_motion=load("res://combat_ux/impact_motion.gd").new(self)
	_impact_motion.play(right*(-0.045),0.05,0.18)

func play_attack(direction: Vector3) -> void:
	cancel_motion()
	if not _impact_alive or not direction.is_finite():return
	var planar := Vector3(direction.x,0,direction.z)
	if planar.length_squared()<0.000001:return
	if _impact_motion==null:_impact_motion=load("res://combat_ux/impact_motion.gd").new(self)
	_impact_motion.play(planar.normalized()*0.10,0.065,0.22)

func cancel_motion() -> void:
	if _impact_motion!=null:_impact_motion.cancel()

func _exit_tree() -> void:
	cancel_motion()

func configure(unit: Dictionary, catalog: Dictionary) -> void:
	refresh(unit, catalog)

func refresh(unit: Dictionary, catalog: Dictionary) -> void:
	if _illustration == null:
		_illustration = Node3D.new()
		_illustration.name = "Illustration"
		add_child(_illustration)
		_create_ground_shadow()
	for child in _illustration.get_children():
		child.free()
	_signature.clear()
	_add_layer("foundation", "foundation", "bare", "", {}, Color.WHITE, 0)
	for part in unit.get("armor_parts", []):
		if not part is Dictionary:
			continue
		var definition := str(part.get("definition", ""))
		var d: Dictionary = catalog.get(definition, {})
		var slot := str(part.get("group", "")) + "/" + str(part.get("layer", ""))
		if not ARMOR_FAMILIES.has(slot) or definition.is_empty() or _signature.has(slot):
			continue
		var families: Array = ARMOR_FAMILIES[slot]
		var family := str(d.get("shape", families[0]))
		var fallback: bool = not d.has("shape") or family not in families
		if family not in families:
			family = families[0]
		var priority: int = 6 if family == "fur" else ARMOR_PRIORITY[slot]
		_add_layer(slot, str(part.group) + "_" + family, family, definition, part, Color(str(d.get("color", "aab1a5"))), priority, fallback)
	_refresh_arms(unit, catalog)
	_sync_billboard_depth()

func _process(_delta: float) -> void:
	_sync_billboard_depth()
	if _impact_motion!=null:_impact_motion.advance(_delta)

func _sync_billboard_depth() -> void:
	if not is_inside_tree() or _illustration == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		# A real camera-space depth stack is essential: Godot 4.4 ignores
		# render_priority for opaque-prepass sprites. All canvas origins still
		# share the same foot; the tiny z offsets change depth, not screen x/y.
		_illustration.global_basis = camera.global_basis.orthonormalized().scaled(global_basis.get_scale())

func _create_ground_shadow() -> void:
	var shadow := Sprite3D.new()
	shadow.name = "GroundShadow"
	shadow.texture = _texture("ground_shadow")
	shadow.pixel_size = PIXEL_SIZE
	shadow.rotation.x = -PI / 2.0
	shadow.position.y = 0.018
	shadow.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	shadow.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	shadow.shaded = false
	shadow.no_depth_test = false
	shadow.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

func _refresh_arms(unit: Dictionary, catalog: Dictionary) -> void:
	var arms: Dictionary = unit.get("arms", {})
	var weapon: Dictionary = arms.get("weapon", {})
	# Battle.sync_arms normally keeps these equal. Explicit combat state wins
	# if the caller is between updates, including an explicitly empty weapon.
	var weapon_id := str(unit.get("weapon", weapon.get("definition", "")))
	if not weapon_id.is_empty():
		var d: Dictionary = catalog.get(weapon_id, {})
		var family := Arsenal.family(str(d.get("weapon", weapon_id)))
		if family == "throwing":
			family = "spear" if weapon_id == "javelins" else "axe" if weapon_id == "throwing_axes" else "bolas"
		var fallback: bool = family not in WEAPON_FAMILIES
		if fallback:
			family = "sword"
		# Never attribute the stale physical item's identity to a different weapon.
		var source: Dictionary = weapon if weapon.get("definition", "") == weapon_id else {}
		_add_layer("weapon", "weapon_" + family, family, weapon_id, source, Color(str(d.get("color", "ffffff"))), 20, fallback)
	var shield: Dictionary = arms.get("shield", {})
	if not bool(unit.get("shield", not shield.is_empty())) or shield.is_empty() or int(shield.get("condition", 0)) <= 0:
		return
	var shield_id := str(shield.get("definition", ""))
	if shield_id.is_empty():
		return
	var d: Dictionary = catalog.get(shield_id, {})
	var family: String = {"round_shield":"round", "buckler":"buckler"}.get(shield_id, "kite")
	var shape := str(d.get("shape", family))
	if shape in ["round", "kite", "buckler"]:
		family = shape
	var source: Dictionary = shield.duplicate(true)
	source["maximum"] = int(d.get("durability", 0))
	_add_layer("shield", "shield_" + family, family, shield_id, source, Color(str(d.get("color", "ffffff"))), 22, d.is_empty())

func set_selected(value: bool) -> void:
	_selected = value

func layer_signature() -> Dictionary:
	return _signature.duplicate(true)

func _add_layer(slot: String, asset: String, family: String, definition: String, item: Dictionary, color: Color, priority: int, fallback: bool = false) -> void:
	var sprite := Sprite3D.new()
	sprite.name = slot.replace("/", "_")
	sprite.texture = _texture(asset)
	sprite.pixel_size = PIXEL_SIZE
	# Pixel coordinates on each canvas share a boot-ground origin.
	sprite.offset = Vector2(0, FOOT_PIXEL.y - CANVAS_SIZE.y / 2.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.alpha_scissor_threshold = 0.12
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.shaded = false
	sprite.double_sided = true
	sprite.no_depth_test = false
	sprite.render_priority = priority
	sprite.position.z = float(priority) * 0.001
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var maximum := int(item.get("maximum", 0))
	var condition := int(item.get("condition", maximum))
	var worn := 1.0 - clampf(float(condition) / maximum, 0.0, 1.0) if maximum > 0 else 0.0
	color = color.lerp(Color("363127"), worn * 0.64)
	sprite.modulate = color
	sprite.set_meta("slot", slot)
	sprite.set_meta("definition", definition)
	_illustration.add_child(sprite)
	_signature[slot] = {"definition":definition,"family":family,"asset":asset + ".png","item":item.get("item", item.get("id", "")),"color":color.to_html(),"condition":condition,"maximum":maximum,"broken":maximum > 0 and condition <= 0,"priority":priority,"fallback":fallback}

static func _texture(asset: String) -> Texture2D:
	if not _textures.has(asset):
		var path := ASSET_ROOT + asset + ".png"
		var image: Image
		var metadata := ConfigFile.new()
		if metadata.load(path+".import") == OK:
			var remap: String = metadata.get_value("remap","path","")
			if not remap.is_empty() and FileAccess.file_exists(remap):
				var imported: Texture2D = load(path)
				if imported != null: image = imported.get_image()
		if image == null:
			image = Image.new()
			if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
				push_error("Character asset missing: " + asset)
				return null
		image.generate_mipmaps()
		_textures[asset] = ImageTexture.create_from_image(image)
	return _textures[asset]
