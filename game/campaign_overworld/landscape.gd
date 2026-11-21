extends Node2D
## Cached presentation only. Geography, navigation and RNG remain in world.gd.
const MATERIAL_NAMES = ["ground_meadow", "ground_earth", "ground_rock", "ground_water", "hill_01", "hill_02", "bank_01", "bank_02", "bridge_h", "bridge_v"]
const GROUND_CODE = """
shader_type canvas_item;
uniform vec2 map_size = vec2(2560.0,1600.0);
uniform sampler2D material_mask : filter_linear, repeat_disable;
uniform sampler2D meadow : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D earth : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock : source_color, filter_linear_mipmap, repeat_enable;
uniform bool painted_materials = false;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 world = UV * map_size;
 vec4 tint = texture(TEXTURE,UV);
 vec3 biome = texture(material_mask,UV).rgb;
 vec2 turned = vec2(world.x*0.813-world.y*0.582,world.x*0.582+world.y*0.813)*1.31+vec2(173.0,419.0);
 vec3 grass = mix(texture(meadow,world/256.0).rgb,texture(meadow,turned/256.0).rgb,0.46);
 vec3 soil = mix(texture(earth,world/192.0).rgb,texture(earth,turned/192.0).rgb,0.46);
 vec3 stone = mix(texture(rock,world/224.0).rgb,texture(rock,turned/224.0).rgb,0.46);
 float patch = noise(world/310.0+vec2(12.7,8.9));
 float upland = smoothstep(0.20,0.56,biome.b);
 vec3 paint = mix(grass,soil,smoothstep(0.35,0.78,patch)*0.20+upland*0.32);
 paint = mix(paint,stone,smoothstep(0.29,0.70,biome.b)*0.48);
 // Retain continuous generated light and forest coolness, not per-cell blocks.
 float light = clamp(dot(tint.rgb,vec3(0.299,0.587,0.114))/0.51,0.84,1.10);
 // Broken hypsometric cuts follow the actual blurred elevation, never a screen-space hatch.
 float level=biome.b*21.0;
 float band=1.0-smoothstep(0.035,0.11,abs(fract(level+0.5)-0.5));
 float shoulder=smoothstep(0.21,0.43,biome.b)*smoothstep(0.31,0.55,patch);
 paint=mix(paint,vec3(0.42,0.43,0.35),band*shoulder*0.45);
 paint *= light * mix(vec3(1.0),vec3(0.69,0.81,0.67),biome.g*0.63);
 COLOR = vec4(painted_materials ? paint : tint.rgb,1.0);
}
"""
var ground_sprite: Sprite2D
var material_mask: ImageTexture
func configure(tint: Texture2D, mask: Image, textures: Dictionary, map_size: Vector2) -> void:
	if ground_sprite == null:
		ground_sprite = Sprite2D.new()
		ground_sprite.name = "PaintedMaterialField"
		add_child(ground_sprite)
		var shader = Shader.new()
		shader.code = GROUND_CODE
		var material = ShaderMaterial.new()
		material.shader = shader
		ground_sprite.material = material
	ground_sprite.texture = tint
	ground_sprite.position = map_size * 0.5
	ground_sprite.scale = map_size / Vector2(tint.get_size())
	material_mask = ImageTexture.create_from_image(mask)
	ground_sprite.material.set_shader_parameter("material_mask", material_mask)
	ground_sprite.material.set_shader_parameter("map_size", map_size)
	bind_materials(textures)
func bind_materials(textures: Dictionary) -> void:
	if ground_sprite == null: return
	var complete = true
	for pair in [["meadow","ground_meadow"],["earth","ground_earth"],["rock","ground_rock"]]:
		if textures.has(pair[1]):
			ground_sprite.material.set_shader_parameter(pair[0],textures[pair[1]])
		else:
			complete = false
	ground_sprite.material.set_shader_parameter("painted_materials",complete)
