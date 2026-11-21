extends "res://sprite_study/compositor.gd"
## Presentation-only full outfits; inherited resolver and compositing math stay intact.
const IDENTITY_ROOT := "res://company_loop/assets/characters/"
const IDENTITIES := ["original", "copper", "silver"]
const IDENTITY_ASSETS := ["foundation_copper", "foundation_copper_helmet", "foundation_silver", "foundation_silver_helmet"]
const OUTFIT_ROOT := "res://company_loop/outfits/characters/"
const OUTFIT_ASSETS := {"body_quilt":"outfit_quilt", "body_mail":"outfit_mail", "body_brigandine":"outfit_brigandine"}
const KEEP_MASK := "foundation_keep_mask"
const GLOVE_ROOT := "res://company_loop/gloves/characters/"
const GLOVE_ASSETS := {"outfit_quilt":"glove_pair_quilt", "outfit_mail":"glove_pair_mail", "outfit_brigandine":"glove_pair_brigandine"}
const HAND_KEEP_MASK := "hand_keep_mask"

static func identity_index(visual_id: int) -> int:
	return posmod(visual_id, IDENTITIES.size())

static func foundation_asset(index: int, helmet: bool) -> String:
	if index == 0: return "foundation_helmet" if helmet else "foundation"
	return "foundation_"+IDENTITIES[index]+("_helmet" if helmet else "")

static func outfit_slot(stack: Array) -> String:
	# Input is the inherited resolver's already filtered visible stack, never raw gear.
	for slot in ["body/outer","body/mail","body/base"]:
		for entry in stack:
			if entry.slot == slot and entry.asset in OUTFIT_ASSETS.values(): return slot
	return ""

static func contextual_stack(stack: Array) -> Array:
	# Idempotent: both compose() and observer diagnostics use this exact plan.
	var selected := stack.filter(func(e): return e.slot != "glove_pair").duplicate(true)
	var slot := outfit_slot(selected)
	var owner := {}
	for entry in selected:
		if entry.slot == slot: owner = entry
		if entry.slot == "foundation":
			entry["keep_mask"] = KEEP_MASK if not slot.is_empty() else ""
			entry["hand_keep_mask"] = HAND_KEEP_MASK if not slot.is_empty() else ""
	if not owner.is_empty():
		var glove: String = GLOVE_ASSETS[owner.asset]
		selected.append({"slot":"glove_pair","asset":glove,"priority":19,"tint":owner.tint,"owner_slot":slot})
		for entry in selected:
			if entry.slot != "weapon_grip": continue
			# Preserve the original inherited foreground as alpha only. Its skin RGB
			# must never reappear above the glove, nor may the pair cover the weapon.
			entry["clip_mask"] = entry.get("clip_mask",entry.asset)
			entry.asset = glove
			entry.tint = owner.tint
			entry["owner_slot"] = slot
	selected.sort_custom(func(a,b): return a.priority < b.priority)
	return selected

func compose(stack: Array) -> Dictionary:
	var selected := contextual_stack(stack)
	var key := JSON.stringify(selected)
	if _cache.has(key):
		_cache_order.erase(key)
		_cache_order.append(key)
		return _cache[key].duplicate(true)
	var asset_errors := {}
	var masks: Array[Image] = []
	if not outfit_slot(selected).is_empty():
		for name in [KEEP_MASK,HAND_KEEP_MASK]:
			var mask := _image(name)
			var error := _validate_keep_mask(mask)
			if not error.is_empty(): asset_errors[name] = error
			else: masks.append(mask)
	for entry in selected:
		var error := _validate_image(_image(str(entry.asset)))
		if not error.is_empty(): asset_errors[str(entry.asset)] = error
		if entry.has("clip_mask"):
			var clip_error := _validate_image(_image(str(entry.clip_mask)))
			if not clip_error.is_empty(): asset_errors[str(entry.clip_mask)] = clip_error
	if not asset_errors.is_empty():
		var errors: Array = []
		for asset in asset_errors: errors.append(asset+": "+str(asset_errors[asset]))
		return {"texture":null,"errors":errors,"asset_errors":asset_errors}
	var output: Image
	for entry in selected:
		var image := _image(str(entry.asset))
		var tint := Color(str(entry.get("tint","ffffffff")))
		var masked: bool = entry.slot == "foundation" and not masks.is_empty()
		if masked or entry.has("clip_mask") or tint != Color.WHITE:
			var bytes := image.get_data()
			var mask_data: Array = []
			if masked:
				for mask in masks: mask_data.append(mask.get_data())
			if entry.has("clip_mask"): mask_data.append(_image(str(entry.clip_mask)).get_data())
			var rect := image.get_used_rect()
			for y in range(rect.position.y,rect.end.y):
				for x in range(rect.position.x,rect.end.x):
					var offset := (y*CANVAS.x+x)*4
					if bytes[offset+3] == 0: continue
					for mask_bytes in mask_data:
						bytes[offset+3] = roundi(bytes[offset+3]*mask_bytes[offset+3]/255.0)
					if tint != Color.WHITE:
						bytes[offset] = roundi(bytes[offset]*tint.r)
						bytes[offset+1] = roundi(bytes[offset+1]*tint.g)
						bytes[offset+2] = roundi(bytes[offset+2]*tint.b)
			image = Image.create_from_data(CANVAS.x,CANVAS.y,false,Image.FORMAT_RGBA8,bytes)
		if output == null: output = image.duplicate()
		else: output.blend_rect(image,Rect2i(Vector2i.ZERO,CANVAS),Vector2i.ZERO)
	output.generate_mipmaps()
	var result := {"texture":ImageTexture.create_from_image(output),"errors":[],"asset_errors":{}}
	_cache[key] = result
	_cache_order.append(key)
	while _cache_order.size() > CACHE_LIMIT: _cache.erase(_cache_order.pop_front())
	builds += 1
	return result.duplicate(true)

func _validate_keep_mask(image: Image) -> String:
	# Auxiliary alpha data, NOT an ordinary painted source: opaque corners and
	# RGB of any value are valid. Require meaningful keep AND suppression data.
	if image == null: return "Missing or undecodable required keep mask PNG"
	if image.get_size() != CANVAS: return "Required keep mask canvas is 1024x1536"
	if image.get_format() != Image.FORMAT_RGBA8 or image.has_mipmaps(): return "Expected RGBA8 keep mask without mipmaps"
	var bytes := image.get_data()
	var keeps := false
	var suppresses := false
	for i in range(3,bytes.size(),4):
		keeps = keeps or bytes[i] > 0
		suppresses = suppresses or bytes[i] < 255
		if keeps and suppresses: return ""
	return "Keep mask must contain retained and suppressed alpha"

func _image(asset: String) -> Image:
	if _fixture_mode: return super._image(asset)
	var source_root := IDENTITY_ROOT if asset in IDENTITY_ASSETS else GLOVE_ROOT if asset in GLOVE_ASSETS.values() or asset == HAND_KEEP_MASK else OUTFIT_ROOT if asset in OUTFIT_ASSETS.values() or asset == KEEP_MASK else ASSET_ROOT
	if not _images.has(asset):
		var path := source_root+asset+".png"
		if not FileAccess.file_exists(path): return null
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK: return null
		image.convert(Image.FORMAT_RGBA8)
		_images[asset] = image
	return _images[asset]
