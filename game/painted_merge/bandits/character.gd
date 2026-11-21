extends "res://company_loop/character.gd"
## Highwayman source-space sprite; inherit motion/picking, never companion paint.
const HighwaymanAppearance = preload("res://crossbows/art/highwayman.gd")
static var appearance = HighwaymanAppearance.new()
var _diagnostics: Dictionary = {}
const LegacyPaint = preload("res://painted_merge/hostile_motion/highwayman_motion.gd")
var _legacy := LegacyPaint.new()
var _legacy_style := ""
var _legacy_age := 0.0
var _legacy_tween: Tween
var _legacy_idle_offset := Vector2.ZERO
var _legacy_weapon_uid := ""

func refresh(unit: Dictionary, catalog: Dictionary) -> void:
 _alive=int(unit.get("hp",1))>0
 if not _alive:cancel_motion()
 if _illustration==null:
  _illustration=Node3D.new();_illustration.name="Illustration";add_child(_illustration);_create_ground_shadow()
 for child in _illustration.get_children():child.free()
 var result: Dictionary=appearance.describe(unit,catalog)
 _preview=result.texture;_signature=result.signature.duplicate(true)
 _legacy.bind(appearance,result.plan if result.ok else {})
 if _legacy_style=="attack" and _signature.get("weapon",{}).get("item","")!=_legacy_weapon_uid:cancel_motion()
 _diagnostics={"ok":result.ok,"errors":result.errors.duplicate(),"issues":result.issues.duplicate(true),"plan":result.plan.duplicate(true),"source_kind":"pinned-highwayman-source-space"}
 get_node("GroundShadow").visible=result.ok
 if not result.ok:cancel_motion();return
 if _motion_kind=="shield" and not _signature.get("shield",{}).get("visible",false):cancel_motion()
 var frame: Dictionary=result.plan.frame
 var geometry: Dictionary=result.plan.geometry
 var canvas:=Vector2(float(frame.size[0]),float(frame.size[1]))
 var origin:=Vector2(float(frame.base_origin[0]),float(frame.base_origin[1]))
 var foot:=Vector2(float(geometry.stance_x)+origin.x,float(frame.stance_anchor[1]))
 var pixel_size:=float(geometry.body_height)/(float(geometry.foot_y)-float(geometry.base_alpha_top))
 var flipped:=int(unit.get("side",0))==1
 var display_foot:=Vector2(canvas.x-foot.x if flipped else foot.x,foot.y)
 _diagnostics.merge({"canvas":canvas,"base_origin":origin,"foot_pixel":foot,"display_foot_pixel":display_foot,"donor_foot_pixel":frame.stance_anchor.duplicate(),"pixel_size":pixel_size,"body_height":geometry.body_height,"stack":result.plan.layers.duplicate(true)})
 _signature.foundation={"definition":"","item":"","asset":result.plan.base.path,"painted":true,"visible":true,"identity":"highwayman-foundation","condition":0,"maximum":0}
 var sprite:=Sprite3D.new();sprite.name="Composite";sprite.texture=_preview
 sprite.pixel_size=pixel_size;sprite.offset=Vector2(canvas.x/2.0-display_foot.x,display_foot.y-canvas.y/2.0)
 sprite.flip_h=flipped;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS;sprite.alpha_scissor_threshold=0.12
 sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;sprite.shaded=false;sprite.double_sided=true;sprite.no_depth_test=false
 sprite.modulate=Color.WHITE;sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var material:=ShaderMaterial.new();material.shader=ColorIdentity;material.set_shader_parameter("source_texture",_preview);sprite.material_override=material
 sprite.set_meta("slot","composite");_illustration.add_child(sprite)
 _legacy_idle_offset=sprite.offset
 _sync_billboard_depth();_apply_motion();_paint_legacy_motion()

# No impact-delay API: this fixed paint shared the instant strike clock.
# The first key is blade contact; preserve the inherited feedback/sound route.
func play_attack(direction:Vector3) -> void:
 if direction.is_finite() and Vector2(direction.x,direction.z).length_squared()>0.000001 and _begin_legacy_motion("attack"):
  _legacy_weapon_uid=str(_signature.weapon.item)
  return
 super.play_attack(direction)

func play_fitted_recoil(_direction:Vector3) -> void:
 # Called only for a landed, sight-qualified contact by the field.
 _begin_legacy_motion("hit")

func follow_enemy_walk(tween:Tween) -> void:
 if not _legacy_style.is_empty() and _legacy_style!="walk":return
 if _begin_legacy_motion("walk",tween):
  tween.finished.connect(_stop_legacy_tween.bind(tween.get_instance_id()),CONNECT_ONE_SHOT)

func _stop_legacy_tween(owner:int) -> void:
 if _legacy_tween!=null and owner==_legacy_tween.get_instance_id():cancel_motion()

func _begin_legacy_motion(style:String,tween:Tween=null) -> bool:
 if not _can_move() or not _legacy.admits(style):return false
 var first:=_legacy.pose(style,0)
 if first==null:return false
 cancel_motion()
 _legacy_style=style;_legacy_age=0.0;_legacy_tween=tween
 LegacyPaint.set_texture(_legacy_sprite(),first,_preview.get_size(),_legacy_idle_offset)
 return true

func _legacy_sprite() -> Sprite3D:
 return _illustration.get_node_or_null("Composite") as Sprite3D if _illustration!=null else null

func _paint_legacy_motion() -> void:
 if _legacy_style.is_empty():return
 if not _can_move() or not _legacy.admits(_legacy_style) or (_legacy_style=="walk" and (_legacy_tween==null or not _legacy_tween.is_running())):cancel_motion();return
 var age:=_legacy_tween.get_total_elapsed_time() if _legacy_style=="walk" else _legacy_age
 var index:=LegacyPaint.frame_at(_legacy_style,age)
 if index<0:
  if _legacy_style=="walk":LegacyPaint.set_texture(_legacy_sprite(),_preview,_preview.get_size(),_legacy_idle_offset)
  else:cancel_motion()
  return
 var pose:=_legacy.pose(_legacy_style,index)
 if pose==null:cancel_motion();return
 LegacyPaint.set_texture(_legacy_sprite(),pose,_preview.get_size(),_legacy_idle_offset)

func _process(delta:float) -> void:
 super._process(delta)
 if not _legacy_style.is_empty() and is_finite(delta):
  _legacy_age+=maxf(0.0,delta)
  _paint_legacy_motion()

func cancel_motion() -> void:
 super.cancel_motion()
 if _legacy_style.is_empty():return
 _legacy_style="";_legacy_tween=null;_legacy_age=0.0;_legacy_weapon_uid=""
 if _preview!=null:LegacyPaint.set_texture(_legacy_sprite(),_preview,_preview.get_size(),_legacy_idle_offset)

func legacy_collapse_frames(casualty:Dictionary,catalog:Dictionary) -> Array[Texture2D]:
 # Wind-up holds the old sprite for disclosure. At witnessed contact use the
 # actually resolved physical armor/shield values, without refreshing the actor.
 if not _legacy.admits("fall"):return []
 var result:Dictionary=appearance.describe(casualty,catalog)
 if not result.ok:return []
 var paint:=LegacyPaint.new()
 paint.bind(appearance,result.plan)
 return paint.fall_frames()

func equipment_issues() -> Array:
 return _diagnostics.get("issues",[]).duplicate(true)

func appearance_diagnostics() -> Dictionary:
 return {"treatment":"source_bound_highwayman_equipment","painted_highwayman":_diagnostics.get("ok",false),"gear_recolored":false,"limitations":"One painted Highwayman foundation; literal owned grade0/1 equipment, static carries. Accepted three-pixel hem residual and enlarged fringe/wrist/cap/cuff limits remain. No bow fit or firing pose; no native visual approval."}

func render_diagnostics() -> Dictionary:
 var out:=_diagnostics.duplicate(true);out["appearance"]=appearance_diagnostics();out["motion"]=_motion_kind;return out
