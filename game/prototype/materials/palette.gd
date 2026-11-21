extends RefCounted
## One small mipmapped pigment atlas, generated from a private seeded noise source.
const GROUND = preload("res://prototype/materials/ground.gdshader")
static var _pigment: ImageTexture
static var _ground: Dictionary = {}

static func pigment() -> ImageTexture:
	if _pigment != null:
		return _pigment
	var noise := FastNoiseLite.new()
	noise.seed = 827391
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.038
	noise.fractal_octaves = 3
	var image := Image.create(128, 128, false, Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var broad := clampf(0.5 + _tile_noise(noise, x, y, Vector2.ONE, Vector2.ZERO) * 0.8, 0.0, 1.0)
			var grain := clampf(0.5 + _tile_noise(noise, x, y, Vector2(4.7, 4.7), Vector2(231, 0)) * 0.65, 0.0, 1.0)
			var brush := clampf(0.5 + _tile_noise(noise, x, y, Vector2(1.9, 6.0), Vector2(0, 851)) * 0.8, 0.0, 1.0)
			image.set_pixel(x, y, Color(broad, grain, brush))
	image.generate_mipmaps()
	_pigment = ImageTexture.create_from_image(image)
	return _pigment

static func _tile_noise(noise: FastNoiseLite, x: float, y: float, scale: Vector2, offset: Vector2) -> float:
	var point := Vector2(x, y) * scale + offset
	var period := Vector2(127, 127) * scale
	var a := noise.get_noise_2d(point.x, point.y)
	var b := noise.get_noise_2d(point.x - period.x, point.y)
	var c := noise.get_noise_2d(point.x, point.y - period.y)
	var d := noise.get_noise_2d(point.x - period.x, point.y - period.y)
	return lerpf(lerpf(a, b, x / 127.0), lerpf(c, d, x / 127.0), y / 127.0)

static func ground(kind: String) -> ShaderMaterial:
	if _ground.has(kind):
		return _ground[kind]
	var colors: Array = {
		"grass": ["8d855c", "545d3d"],
		"hill": ["a09b7d", "626747"],
		"mud": ["80735c", "514a36"],
		"stone": ["a39d88", "666654"],
		"rubble": ["a39d88", "666654"],
		"wall": ["99957b", "65684c"],
		"forest": ["8d7851", "4a5436"],
		"ford": ["aaa18a", "70705c"],
		"water": ["566158", "343f38"],
		"cliff": ["938573", "5b5345"],
	}.get(kind, ["8d855c", "545d3d"])
	var material := ShaderMaterial.new()
	material.shader = GROUND
	material.set_shader_parameter("pigment", pigment())
	material.set_shader_parameter("earth_light", Color(colors[0]))
	material.set_shader_parameter("earth_dark", Color(colors[1]))
	material.set_shader_parameter("cliff", kind == "cliff")
	material.set_shader_parameter("paved", kind in ["stone", "ford"])
	_ground[kind] = material
	return material

static func water() -> ShaderMaterial:
	if _ground.has("stream"):
		return _ground["stream"]
	var material := ShaderMaterial.new()
	material.shader = preload("res://prototype/materials/water.gdshader")
	material.set_shader_parameter("pigment", pigment())
	_ground["stream"] = material
	return material

static func masonry() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://prototype/materials/masonry.gdshader")
	material.set_shader_parameter("pigment", pigment())
	material.set_shader_parameter("opacity", 1.0)
	return material

static func foliage(wind_strength: float = 0.022) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://prototype/materials/foliage.gdshader")
	material.set_shader_parameter("pigment", pigment())
	material.set_shader_parameter("opacity", 1.0)
	material.set_shader_parameter("wind_strength", wind_strength)
	return material
