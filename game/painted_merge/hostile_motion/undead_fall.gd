extends Node3D
## Short visual aftermath only: never an actor, picker target or occupant.
const Paint = preload("res://painted_merge/hostile_motion/undead_reaction.gd")
const RETIRE := 0.68
var age:=0.0
var _body:Sprite3D
var _poses:Array[Texture2D]=[]
var _frame:=-1

func start(source:Sprite3D,frames:Array[Texture2D],radius:float) -> bool:
 if frames.size()!=4 or not source.material_override is ShaderMaterial:return false
 # A billboard's every horizontal screen segment is within this inscribed
 # circle, regardless of azimuth or mirror. Keep authored proportions at 1×.
 var foot_x:=source.texture.get_width()*0.5-source.offset.x
 for pose in frames:
  var ink:Rect2i=pose.get_meta("undead_reaction").ink
  if maxf(absf(foot_x-ink.position.x),absf(ink.end.x-foot_x))*source.pixel_size>radius:return false
 _poses=frames
 _body=Sprite3D.new();_body.name="Composite"
 _body.pixel_size=source.pixel_size;_body.offset=source.offset;_body.flip_h=source.flip_h
 _body.billboard=source.billboard;_body.alpha_cut=source.alpha_cut
 _body.alpha_scissor_threshold=source.alpha_scissor_threshold;_body.texture_filter=source.texture_filter
 _body.shaded=source.shaded;_body.double_sided=source.double_sided;_body.no_depth_test=source.no_depth_test
 _body.modulate=source.modulate;_body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 _body.material_override=source.material_override.duplicate() as ShaderMaterial
 _body.basis=source.global_basis.orthonormalized()
 add_child(_body);advance(0.0)
 return true

func advance(dt:float) -> void:
 age+=maxf(0.0,dt)
 if is_inside_tree():
  var camera:=get_viewport().get_camera_3d()
  if camera!=null:_body.global_basis=camera.global_basis.orthonormalized()
 var frame:=Paint.fall_index(age)
 if frame==_frame:return
 _frame=frame
 _body.texture=_poses[frame]
 _body.material_override.set_shader_parameter("source_texture",_body.texture)
