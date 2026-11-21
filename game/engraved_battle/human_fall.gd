extends Node3D
## Death is decided before this visual is born. No actor, hitbox or movement.
const CANVAS := Vector2(480,464)
const SOLE := Vector2(240,411)
const STARTS := [0.0,0.075,0.174,0.313]
const RETIRE := 0.68
var age:=0.0
var _body:Sprite3D
var _cuts:Array[Texture2D]=[]
var _cut:=-1

func start(source:Sprite3D,frames:Array[Texture2D],inscribed:float) -> bool:
 if frames.size()!=STARTS.size() or not source.material_override is ShaderMaterial:return false
 if not is_finite(inscribed) or inscribed<=0.0 or source.pixel_size<=0.0:return false
 var center:Vector2=source.texture.get_size()*0.5
 var foot:=Vector2(center.x-source.offset.x,center.y+source.offset.y)
 # A registered symmetric side pad shifts the source-space sole, not the
 # mounted sprite offset. Do not admit arbitrary wider or malformed plates.
 var side_pad:Variant=source.texture.get_meta("painted_side_pad",0)
 if not side_pad is int or side_pad<0:return false
 if side_pad>0 and center.x!=CANVAS.x*0.5+side_pad:return false
 foot.x-=float(side_pad)
 # A temporarily padded special retains the same sole but has extra rows above.
 foot.y-=float(source.texture.get_meta("painted_top_pad",0))
 if not foot.is_equal_approx(SOLE):return false
 for i in frames.size():
  var pose:=frames[i]
  if pose==null or pose.get_size()!=CANVAS:return false
  var mark:Dictionary=pose.get_meta("human_collapse",{})
  if int(mark.get("frame",-1))!=i:return false
  var ink:Rect2i=mark.get("ink",Rect2i())
  if not ink.has_area() or not Rect2i(Vector2i.ZERO,Vector2i(CANVAS)).encloses(ink) or ink.end.y>SOLE.y+2.0:return false
  var span:=maxf(absf(ink.position.x-SOLE.x),absf(ink.end.x-SOLE.x))
  # No row-to-row ground drift. Positive height is upright ink; below the
  # anchor allow only two antialias rows, included conservatively in the radius.
  if (span+maxf(0.0,ink.end.y-SOLE.y))*source.pixel_size>inscribed:return false
 _cuts=frames
 _body=Sprite3D.new();_body.name="Composite"
 _body.pixel_size=source.pixel_size;_body.offset=Vector2(CANVAS.x*0.5-SOLE.x,SOLE.y-CANVAS.y*0.5)
 _body.flip_h=source.flip_h;_body.billboard=source.billboard
 _body.alpha_cut=source.alpha_cut;_body.alpha_scissor_threshold=source.alpha_scissor_threshold
 _body.texture_filter=source.texture_filter;_body.shaded=source.shaded
 _body.double_sided=source.double_sided;_body.no_depth_test=source.no_depth_test;_body.modulate=source.modulate
 _body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 _body.material_override=source.material_override.duplicate() as ShaderMaterial
 add_child(_body);advance(0.0)
 return true

func advance(dt:float) -> void:
 if not is_finite(dt):return
 age+=maxf(0.0,dt)
 if is_inside_tree():
  # The fitted color shader samples the Sprite3D quad directly.
  var camera:=get_viewport().get_camera_3d()
  if camera!=null:_body.global_basis=camera.global_basis.orthonormalized()
 var cut:=0
 for i in range(1,STARTS.size()):
  if age>=STARTS[i]:cut=i
 if cut==_cut:return
 _cut=cut;_body.texture=_cuts[cut]
 _body.material_override.set_shader_parameter("source_texture",_body.texture)
