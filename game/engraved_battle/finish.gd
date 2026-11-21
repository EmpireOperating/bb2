extends RefCounted
## No overlay mesh, extra pass, sampler substitution or independent fog boundary.
## Keep each terrain material's original uniforms (including opacity and wind).
const FIELD = preload("res://terrain_pass/materials/fields.gdshader")
const PROP = preload("res://visual_slice/materials/painted.gdshader")
const HEATH = preload("res://engraved_battle/heath.gdshader")
const CUT = preload("res://engraved_battle/cut.gdshader")
static func coat(material:Material) -> Material:
 if not material is ShaderMaterial:return material
 var mat:=material as ShaderMaterial
 var target:Shader=HEATH if mat.shader==FIELD else CUT if mat.shader==PROP else null
 if target==null:return material
 var uniforms:={}
 for uniform in mat.shader.get_shader_uniform_list():
  var value=mat.get_shader_parameter(uniform.name)
  if value!=null:uniforms[uniform.name]=value
 mat.shader=target
 for key in uniforms:mat.set_shader_parameter(key,uniforms[key])
 return mat
