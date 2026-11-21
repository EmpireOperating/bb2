extends RefCounted
const GROUND = preload("res://visual_slice/materials/ground.gdshader")
const PAINTED = preload("res://visual_slice/materials/painted.gdshader")
static var textures: Dictionary = {}
static func texture(kind: String) -> Texture2D:
	if textures.has(kind): return textures[kind]
	var path := "res://visual_slice/assets/terrain/%s.png" % kind
	var result: Texture2D
	if FileAccess.file_exists(path + ".import"):
		result = load(path)
	else:
		var image := Image.new()
		var status := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		assert(status == OK, "Missing actual painted terrain texture " + path)
		image.generate_mipmaps()
		result = ImageTexture.create_from_image(image)
	textures[kind] = result
	return result
static func ground() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GROUND
	for kind: String in ["earth", "meadow", "paving"]:
		material.set_shader_parameter(kind, texture(kind))
	return material
static func painted(kind: String = "rock", frequency: float = .8, wind: float = 0.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = PAINTED
	material.set_shader_parameter("paint", texture(kind))
	material.set_shader_parameter("scale", frequency)
	material.set_shader_parameter("wind_strength", wind)
	material.set_shader_parameter("opacity", 1.0)
	return material
