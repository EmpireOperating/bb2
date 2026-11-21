extends "res://painted_merge/hostile_motion/hostile_attack_actor.gd"
## Inherit only the core Sprite3D basis/selection/motion API; never its living paint.
const SkeletalAppearance = preload("res://painted_merge/undead/appearance.gd")
const UndeadStride = preload("res://painted_merge/hostile_motion/undead_stride.gd")
const UndeadReaction = preload("res://painted_merge/hostile_motion/undead_reaction.gd")
const WatchRelease = preload("res://painted_merge/hostile_motion/watch_release.gd")
var _watch_ranged := false
var _watch_age := -1.0
var _watch_cuts: Array[Texture2D] = []
static var appearance = SkeletalAppearance.new()
var _hurt_elapsed := -1.0
var _hurt_poses: Array[Texture2D] = []
var _diagnostics: Dictionary = {}
var _stride: Tween
var _stride_key := ""
var _stride_frames: Array[Texture2D] = []
var _stride_origin := Vector3.ZERO
var _stride_flip := true
var _stride_find_facing := false

func refresh(unit: Dictionary, catalog: Dictionary) -> void:
 _alive=int(unit.get("hp",1))>0
 if not _alive:cancel_motion()
 if _illustration==null:
  _illustration=Node3D.new();_illustration.name="Illustration";add_child(_illustration);_create_ground_shadow()
 for child in _illustration.get_children():child.free()
 var result: Dictionary=appearance.describe(unit,catalog)
 _preview=result.texture;_signature=result.signature.duplicate(true)
 _diagnostics={"ok":result.ok,"errors":result.errors.duplicate(),"issues":result.issues.duplicate(true),"plan":result.plan.duplicate(true),"source_kind":"pinned-skeletal-registered-pngs"}
 get_node("GroundShadow").visible=result.ok
 if not result.ok:cancel_motion();return
 var frame: Dictionary=result.plan.frame
 var geometry: Dictionary=result.plan.geometry
 var canvas:=Vector2(float(frame.canvas[0]),float(frame.canvas[1]))
 var origin:=Vector2(float(frame.base_origin[0]),float(frame.base_origin[1]))
 var foot:=Vector2(float(geometry.stance_x)+origin.x,float(frame.foot_anchor[1]))
 var pixel_size:=float(geometry.body_height)/(float(geometry.foot_y)-float(geometry.base_alpha_top))
 var flipped:=int(unit.get("side",0))==1
 var display_foot:=Vector2(canvas.x-foot.x if flipped else foot.x,foot.y)
 _diagnostics.merge({"canvas":canvas,"base_origin":origin,"foot_pixel":foot,"display_foot_pixel":display_foot,"donor_foot_pixel":frame.foot_anchor.duplicate(),"pixel_size":pixel_size,"body_height":geometry.body_height,"stack":result.plan.layers.duplicate(true)})
 _signature.foundation={"definition":"","item":"","asset":result.plan.base.path,"painted":true,"visible":true,"identity":"skeletal-foundation","condition":0,"maximum":0}
 var sprite:=Sprite3D.new();sprite.name="Composite";sprite.texture=_preview
 sprite.pixel_size=pixel_size;sprite.offset=Vector2(canvas.x/2.0-display_foot.x,display_foot.y-canvas.y/2.0)
 sprite.flip_h=flipped;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS;sprite.alpha_scissor_threshold=0.12
 sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;sprite.shaded=false;sprite.double_sided=true;sprite.no_depth_test=false
 sprite.modulate=Color.WHITE;sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var material:=ShaderMaterial.new();material.shader=ColorIdentity;material.set_shader_parameter("source_texture",_preview);sprite.material_override=material
 sprite.set_meta("slot","composite");_illustration.add_child(sprite)
 _stride_key=str(result.plan.base.path)
 _bind_hostile_attack(_stride_key,unit)
 var watch_weapon:Dictionary=unit.get("arms",{}).get("weapon",{})
 var watch_uid:String=str(watch_weapon.get("id",""))
 _watch_ranged = unit.get("undead_kind","")=="watch_captain" and unit.get("weapon","")==WatchRelease.WEAPON and watch_weapon.get("definition","")==WatchRelease.WEAPON and not watch_uid.is_empty() and watch_uid==_signature.get("weapon",{}).get("item","") and not _signature.get("weapon",{}).get("visible",false)
 _paint_watch_release()
 _paint_stride()
 _paint_hurt()
 _sync_billboard_depth();_apply_motion()

# This exact boss already exposes no equipment ink. Keep existing instant
# contact and paint an anchored release/settle on the same plate.
func play_attack(direction:Vector3) -> void:
 if _watch_ranged and _can_move() and direction.is_finite() and Vector2(direction.x,direction.z).length_squared()>0.000001:
  var frames:=WatchRelease.frames(_stride_key)
  if not frames.is_empty() and frames[0].get_size()==_preview.get_size():
   cancel_motion()
   _watch_cuts=frames;_watch_age=0.0
   _paint_watch_release();return
 super.play_attack(direction)

func _paint_watch_release() -> void:
 if _watch_age<0.0:return
 var index:=WatchRelease.index_at(_watch_age)
 if not _watch_ranged or not _can_move() or index<0:cancel_motion();return
 _set_cut(_watch_cuts[index],_cut_idle_flip)

# The field hands off only its existing visibility-admitted endpoint tween.
# A redraw or an unseen actor never starts a gait clock of its own.
func follow_enemy_walk(tween: Tween) -> void:
 if not _can_move() or _watch_age>=0.0 or _hurt_elapsed>=0.0 or _cut_elapsed>=0.0 or not _motion_kind.is_empty():return
 var frames:=UndeadStride.load_frames(_stride_key)
 if frames.is_empty() or frames[0].get_size()!=_preview.get_size():return
 _stride=tween;_stride_frames=frames
 _stride_origin=global_position;_stride_flip=_cut_idle_flip;_stride_find_facing=true
 tween.finished.connect(_finish_stride.bind(tween.get_instance_id()),CONNECT_ONE_SHOT)
 _paint_stride()

func _finish_stride(owner: int) -> void:
 if _stride!=null and _stride.get_instance_id()==owner:_clear_stride()

func _clear_stride() -> void:
 _stride=null
 if _cut_elapsed<0.0 and _motion_kind.is_empty():_set_cut(_preview,_cut_idle_flip)

func _process(delta: float) -> void:
 super._process(delta)
 if _watch_age>=0.0:
  if is_finite(delta):_watch_age+=maxf(0.0,delta)
  _paint_watch_release()
 elif _hurt_elapsed>=0.0 and is_finite(delta):
  _hurt_elapsed+=maxf(0.0,delta)
  _paint_hurt()
 else:_paint_stride()

func cancel_motion() -> void:
 super.cancel_motion()
 if _watch_age>=0.0:
  _watch_age=-1.0;_watch_cuts=[]
  _set_cut(_preview,_cut_idle_flip)
 if _stride!=null:_clear_stride()
 if _hurt_elapsed>=0.0:
  _hurt_elapsed=-1.0;_hurt_poses=[]
  _set_cut(_preview,_cut_idle_flip)

func _paint_stride() -> void:
 if _stride==null:return
 if not _stride.is_running() or not _can_move() or _cut_elapsed>=0.0 or not _motion_kind.is_empty():
  _clear_stride();return
 # Resolve lateral direction once from the painted actor's actual travel,
 # not the AI route. Retain the idle side on a near-vertical screen path.
 if _stride_find_facing:
  var travel:=global_position-_stride_origin
  if travel.length_squared()>0.0016:
   _stride_find_facing=false
   var camera:=get_viewport().get_camera_3d()
   if camera!=null:
    var lateral:=camera.global_basis.x.dot(travel.normalized())
    if absf(lateral)>0.15:_stride_flip=lateral<0.0
 _set_cut(_stride_frames[UndeadStride.frame_at(_stride.get_total_elapsed_time())],_stride_flip)

func equipment_issues() -> Array:
 return _diagnostics.get("issues",[]).duplicate(true)

func appearance_diagnostics() -> Dictionary:
 return {"treatment":"exposed_skeletal_base","painted_skull":_diagnostics.get("ok",false),"gear_recolored":false,"limitations":"Exposed original skeletal model; internal weapons and protection remain effective but are deliberately not painted. Pictured gear is not recovered; encounter equipment loot is independent."}

func render_diagnostics() -> Dictionary:
 var out:=_diagnostics.duplicate(true);out["appearance"]=appearance_diagnostics();out["motion"]=_motion_kind;out.merge(_attack_diagnostics(),true);return out

# Only the field's witnessed, identity-matched contact calls this.
func play_fitted_recoil(_direction:Vector3) -> void:
 if not _can_move():return
 var poses:=UndeadReaction.load_frames(_stride_key,false)
 if poses.is_empty() or poses[0].get_size()!=_preview.get_size():return
 cancel_motion()
 _hurt_poses=poses;_hurt_elapsed=0.0;_paint_hurt()

func _paint_hurt() -> void:
 if _hurt_elapsed<0.0:return
 var index:=UndeadReaction.hit_index(_hurt_elapsed)
 if index<0 or not _can_move():cancel_motion();return
 _set_cut(_hurt_poses[index],_cut_idle_flip)

func undead_collapse_frames() -> Array[Texture2D]:
 return UndeadReaction.load_frames(_stride_key,true)
