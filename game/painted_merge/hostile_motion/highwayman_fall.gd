extends "res://engraved_battle/human_fall.gd"
## Terminal presentation shares the inherited human effect owner's cap, clock
## and refog/retirement gates. No actor, physics body, occupancy or picker.
const Motion = preload("res://painted_merge/hostile_motion/highwayman_motion.gd")
var _shadow:Sprite3D

static func from_legacy(dst:Node3D,source:Sprite3D,textures:Array[Texture2D],id:int,cell:Vector2i,anchor:Vector3,radius:float):
 if textures.is_empty():return null
 var fall=load("res://painted_merge/hostile_motion/highwayman_fall.gd").new()
 if not fall.start(source,textures,radius):fall.free();return null
 fall.position=anchor
 fall.set_meta("legacy_fall_actor",id);fall.set_meta("fall_cell",cell)
 var original:=dst.get_node_or_null("GroundShadow") as Sprite3D
 if original!=null:fall.copy_shadow(original)
 return fall

func start(source:Sprite3D,frames:Array[Texture2D],inscribed:float) -> bool:
 if frames.size()!=STARTS.size() or not source.material_override is ShaderMaterial:return false
 if not is_finite(inscribed) or inscribed<=0.0 or source.pixel_size<=0.0:return false
 var center:=source.texture.get_size()*0.5
 var foot:=Vector2(center.x-source.offset.x,center.y+source.offset.y)
 if source.flip_h:foot.x=source.texture.get_width()-foot.x
 if not foot.is_equal_approx(Motion.SOLE):return false
 for i in frames.size():
  var tex:=frames[i]
  if tex==null or tex.get_size()!=Vector2(Motion.CANVAS):return false
  var mark:Dictionary=tex.get_meta("legacy_pose",{})
  var ink:Rect2i=mark.get("ink",Rect2i())
  if mark.get("style","")!="fall" or mark.get("frame",-1)!=i or not ink.has_area() or not Rect2i(Vector2i.ZERO,Motion.CANVAS).encloses(ink) or ink.end.y>Motion.SOLE.y+2:return false
  var span:=maxf(absf(ink.position.x-Motion.SOLE.x),absf(ink.end.x-Motion.SOLE.x))
  if (span+maxf(0.0,ink.end.y-Motion.SOLE.y))*source.pixel_size>inscribed:return false
 _cuts=frames
 _body=Sprite3D.new();_body.name="Composite"
 _body.pixel_size=source.pixel_size
 var displayed:=Motion.SOLE.x if not source.flip_h else Motion.CANVAS.x-Motion.SOLE.x
 _body.offset=Vector2(Motion.CANVAS.x*0.5-displayed,Motion.SOLE.y-Motion.CANVAS.y*0.5)
 _body.flip_h=source.flip_h;_body.billboard=source.billboard
 _body.alpha_cut=source.alpha_cut;_body.alpha_scissor_threshold=source.alpha_scissor_threshold
 _body.texture_filter=source.texture_filter;_body.shaded=source.shaded
 _body.double_sided=source.double_sided;_body.no_depth_test=source.no_depth_test;_body.modulate=source.modulate
 _body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 _body.material_override=source.material_override.duplicate() as ShaderMaterial
 add_child(_body);advance(0.0)
 return true

func copy_shadow(original:Sprite3D) -> void:
 _shadow=original.duplicate(0) as Sprite3D
 _shadow.modulate.a=0.40;_shadow.scale*=0.82
 add_child(_shadow)

func advance(dt:float) -> void:
 super.advance(dt)
 if _shadow!=null:
  _shadow.modulate.a=0.40+0.16*smoothstep(0.10,0.32,age)
