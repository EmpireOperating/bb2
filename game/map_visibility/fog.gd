extends RefCounted
## Terrain-owned material extension, not a camera canopy or a replacement art pass.
## Public integration: configure(battle, terrain), update(), sync_shadows().
const Layout=preload("res://prototype/hex_layout.gd")
const HEADER="""
// BB2_FOG_MATERIAL: visibility texture is linear data, never source_color.
uniform sampler2D bb2_fog_mask : filter_nearest, repeat_disable;
uniform vec2 bb2_fog_size = vec2(32.0);
uniform bool bb2_fog_enabled = true;
uniform bool bb2_fog_shadow = false;
uniform bool bb2_fog_fixed = false;
uniform vec2 bb2_fog_cell = vec2(0.0);
varying vec3 bb2_fog_world;
vec2 bb2_fog_hex(vec2 p) {
 float q = sqrt(3.0)/3.0*p.x - p.y/3.0;
 float r = 2.0/3.0*p.y;
 float x = floor(q+0.5);
 float z = floor(r+0.5);
 float y = floor(-q-r+0.5);
 float dx = abs(x-q); float dz = abs(z-r); float dy = abs(y+q+r);
 if (dx > dy && dx > dz) { x = -y-z; }
 else if (dz > dy) { z = -x-y; }
 return vec2(x+(z-mod(z,2.0))/2.0,z);
}
"""
const TAIL="""
 if (bb2_fog_enabled) {
  vec2 cell = bb2_fog_fixed ? bb2_fog_cell : bb2_fog_hex(bb2_fog_world.xz);
  vec2 knowledge = vec2(0.0);
  if (all(greaterThanEqual(cell,vec2(0.0))) && all(lessThan(cell,bb2_fog_size))) {
   knowledge = texture(bb2_fog_mask,(cell+vec2(0.5))/bb2_fog_size).rg;
  }
  // This material instance is used exclusively by a shadows-only mesh.
  // Unknown terrain must not cast a shape-revealing shadow into known ground.
  if (bb2_fog_shadow && knowledge.g < 0.5) { discard; }
  if (knowledge.r < 0.5) {
   if (knowledge.g < 0.5) {
    ALBEDO = vec3(0.0); EMISSION = vec3(0.0); SPECULAR = 0.0; ROUGHNESS = 1.0;
   } else {
    float grey = dot(ALBEDO,vec3(0.299,0.587,0.114));
    ALBEDO = mix(ALBEDO,vec3(grey),0.72) * 0.23;
    SPECULAR *= 0.23;
   }
  }
  // Visible branch intentionally writes NOTHING: accepted art/light unchanged.
 }
"""
var battle
var terrain: Node3D
var image: Image
var texture: ImageTexture
var uploads := 0
var materials: Array[ShaderMaterial]=[]
var shadow_pairs: Array[Dictionary]=[]
var _shaders: Dictionary={}
var _bytes := PackedByteArray()
var _fixed: Dictionary={}

func configure(value, node: Node3D) -> void:
 battle=value;terrain=node
 image=Image.create(battle.width(),battle.height(),false,Image.FORMAT_RG8)
 texture=ImageTexture.create_from_image(image)
 update()
 for object: Dictionary in terrain.occluders:
  var bits: PackedStringArray=String(object.tile).split(",")
  for mesh in object.meshes:_fixed[mesh.get_instance_id()]=Vector2(int(bits[0]),int(bits[1]))
 var sources: Array=[]
 _collect(terrain,sources)
 for source: MeshInstance3D in sources:_bind(source)
 sync_shadows()

func _collect(node: Node, out: Array) -> void:
 if node is MeshInstance3D:out.append(node)
 for child in node.get_children():_collect(child,out)

func _append_body(code: String, signature: String, addition: String) -> String:
 var start := code.find(signature)
 if start<0:return code
 var brace := code.find("{",start)
 var depth := 1
 var end := brace+1
 while depth>0 and end<code.length():
  if code[end]=="{":depth+=1
  elif code[end]=="}":depth-=1
  end+=1
 return code.substr(0,end-1)+addition+code.substr(end-1)

func _extend(material: ShaderMaterial, source: MeshInstance3D) -> void:
 if material in materials:return
 var shader: Shader=material.shader
 var code: String=shader.code
 var params := {}
 for uniform in shader.get_shader_uniform_list():
  var value=material.get_shader_parameter(uniform.name)
  if value!=null:params[uniform.name]=value
 material.set_meta("fog_original_code",code)
 var at := code.find("void fragment()")
 material.set_meta("fog_original_fragment",code.substr(at,code.rfind("}")-at))
 if not _shaders.has(code):
  var extended := Shader.new()
  var modified := _append_body(code,"void vertex()","\n bb2_fog_world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;\n")
  modified=_append_body(modified,"void fragment()",TAIL)
  # Keep shader_type/render_mode declarations first, then global declarations.
  var declaration := modified.find("void ")
  extended.code=modified.substr(0,declaration)+HEADER+modified.substr(declaration)
  _shaders[code]=extended
 material.shader=_shaders[code]
 for key in params:material.set_shader_parameter(key,params[key])
 material.set_shader_parameter("bb2_fog_mask",texture)
 material.set_shader_parameter("bb2_fog_size",Vector2(battle.width(),battle.height()))
 material.set_shader_parameter("bb2_fog_enabled",battle.visibility_enabled)
 if _fixed.has(source.get_instance_id()):
  material.set_shader_parameter("bb2_fog_fixed",true)
  material.set_shader_parameter("bb2_fog_cell",_fixed[source.get_instance_id()])
 materials.append(material)

func _bind(source: MeshInstance3D) -> void:
 if source.mesh==null:return
 var material=source.material_override
 if not material is ShaderMaterial:
  push_error("Fog refuses terrain without its owned ShaderMaterial: "+str(source.name));source.hide();return
 _extend(material,source)
 if source.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:return
 var shadow := MeshInstance3D.new()
 shadow.name="FogKnownShadow";shadow.mesh=source.mesh
 shadow.material_override=material.duplicate()
 shadow.material_override.set_shader_parameter("bb2_fog_shadow",true)
 shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
 source.add_child(shadow)
 shadow_pairs.append({"source":source,"shadow":shadow})
 source.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func update() -> void:
 if image==null:return
 for r in battle.height():
  for q in battle.width():
   var cell := Vector2i(q,r)
   image.set_pixel(q,r,Color(1 if battle.tile_visible(0,cell) else 0,1 if battle.tile_explored(0,cell) else 0,0))
 var bytes := image.get_data()
 if bytes==_bytes:return
 _bytes=bytes
 texture.update(image);uploads+=1
 for material in materials:material.set_shader_parameter("bb2_fog_enabled",battle.visibility_enabled)
 for object: Dictionary in terrain.occluders:
  var bits: PackedStringArray=String(object.tile).split(",")
  object.root.visible=battle.tile_explored(0,Vector2i(int(bits[0]),int(bits[1])))

func sync_shadows() -> void:
 for pair in shadow_pairs:
  pair.source.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  pair.shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
 for object: Dictionary in terrain.occluders:
  if not object.faded:continue
  for mesh in object.meshes:
   for pair in shadow_pairs:
    if pair.source==mesh:pair.shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func state_at(cell: Vector2i) -> int:
 if cell.x<0 or cell.y<0 or cell.x>=image.get_width() or cell.y>=image.get_height():return 0
 var pixel := image.get_pixelv(cell)
 return 2 if pixel.r>0.5 else 1 if pixel.g>0.5 else 0
