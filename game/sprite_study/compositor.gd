extends RefCounted
## CPU source-over once per selected stack. No viewport or per-frame paint work.
const CANVAS := Vector2i(1024,1536)
const FOOT := Vector2(512,1490)
const WORLD_PIXEL_SIZE := 0.00134
const ASSET_ROOT := "res://sprite_study/assets/characters/"
var _test_images: Dictionary = {}
var _fixture_mode := false
const CACHE_LIMIT := 16
var _cache: Dictionary = {}
var _cache_order: Array[String] = []
var _images: Dictionary = {}
var builds := 0

func install_test_images(images: Dictionary) -> void:
	# Explicit harness-only dependency injection; runtime never enables this.
	_fixture_mode = true
	_test_images = images.duplicate(true)
	_cache.clear()
	_cache_order.clear()
	_images.clear()

func compose(stack: Array) -> Dictionary:
	var key := JSON.stringify(stack)
	if _cache.has(key):
		_cache_order.erase(key)
		_cache_order.append(key)
		return _cache[key].duplicate(true)
	var asset_errors: Dictionary = {}
	for entry in stack:
		var image := _image(str(entry.asset))
		var error := _validate_image(image)
		if not error.is_empty(): asset_errors[str(entry.asset)] = error
	if not asset_errors.is_empty():
		var errors: Array = []
		for asset in asset_errors: errors.append(asset+": "+str(asset_errors[asset]))
		return {"texture":null,"errors":errors,"asset_errors":asset_errors}
	var output := Image.create(CANVAS.x,CANVAS.y,false,Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	var first := true
	for entry in stack:
		var image := _image(str(entry.asset))
		var tint := Color(str(entry.get("tint","ffffffff")))
		if tint != Color.WHITE:
			var bytes := image.get_data()
			var rect := image.get_used_rect()
			for y in range(rect.position.y,rect.end.y):
				for x in range(rect.position.x,rect.end.x):
					var offset := (y*CANVAS.x+x)*4
					if bytes[offset+3] == 0: continue
					bytes[offset] = roundi(bytes[offset]*tint.r)
					bytes[offset+1] = roundi(bytes[offset+1]*tint.g)
					bytes[offset+2] = roundi(bytes[offset+2]*tint.b)
			image = Image.create_from_data(CANVAS.x,CANVAS.y,false,Image.FORMAT_RGBA8,bytes)
		if first:
			output = image.duplicate()
			first = false
		else:
			output.blend_rect(image,Rect2i(Vector2i.ZERO,CANVAS),Vector2i.ZERO)
	output.generate_mipmaps()
	var result := {"texture":ImageTexture.create_from_image(output),"errors":[],"asset_errors":{}}
	_cache[key] = result
	_cache_order.append(key)
	while _cache_order.size() > CACHE_LIMIT:
		_cache.erase(_cache_order.pop_front())
	builds += 1
	return result.duplicate(true)

func source_kind() -> String:
	return "synthetic-test-fixtures" if _fixture_mode else "source-pngs"

func _validate_image(image: Image) -> String:
	if image == null: return "Missing or undecodable required PNG"
	if image.get_size() != CANVAS: return "Required canvas is 1024x1536"
	if image.get_format() != Image.FORMAT_RGBA8 or image.has_mipmaps(): return "Expected straight RGBA8 source without mipmaps"
	if not image.get_used_rect().has_area(): return "Required source has no visible pixels"
	if image.detect_alpha() == Image.ALPHA_NONE: return "Required source has no transparent background"
	for p in [Vector2i.ZERO,Vector2i(CANVAS.x-1,0),Vector2i(0,CANVAS.y-1),CANVAS-Vector2i.ONE]:
		if image.get_pixelv(p).a > 0.0: return "Required source has an opaque canvas corner"
	return ""

func _image(asset: String) -> Image:
	if not _images.has(asset):
		if _fixture_mode:
			if not _test_images.has(asset): return null
			_images[asset] = _test_images[asset]
		else:
			var path := ASSET_ROOT+asset+".png"
			if not FileAccess.file_exists(path): return null
			var image := Image.new()
			if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK: return null
			image.convert(Image.FORMAT_RGBA8)
			_images[asset] = image
	return _images[asset]
