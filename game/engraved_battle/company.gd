extends "res://prototype/character.gd"
## The only figure owner on a friendly field row. Battle supplies identity,
## equipment and movement; the shared compositor owns fit and frame selection.
const Identity = preload("res://sprite_study/color_identity.gdshader")
const DrawArt = preload("res://engraved_people/reload_draw.gd")
const CrossbowFoley = preload("res://audio/crossbow/foley.gd")
const ShieldArt = preload("res://engraved_people/shield_contact.gd")
const RecoilArt = preload("res://engraved_people/hit_recoil.gd")
const BODY_HEIGHT := 1.94
var _people = load("res://engraved_people/actors.gd")
var _unit:Dictionary
var _info:Dictionary
var _idle:Texture2D
var _sprite:Sprite3D
var _material:ShaderMaterial
const UtilityClock = preload("res://engraved_battle/utility_clock.gd")
var _utility:=UtilityClock.new()
var _utility_outgoing:Texture2D
var spearwall_query:Callable
var _spearwall_was_active := false
var _spearwall_held:Texture2D
const Defense = preload("res://engraved_battle/defense_state.gd")
var _last_defense:=""
var _defense_cut:Texture2D
var _utility_step_kind: String = ""
var _utility_step_flip: bool = false
var _walk:Tween
var _frame := -1
const HookArt = preload("res://engraved_people/billhook_hook.gd")
var _hook_uid := ""
const BowHookSpecial = preload("res://engraved_people/bow_hook_special.gd")
var _bow_hook_uid := ""
var _bow_hook_style := ""
var _strike_time := -1.0
var _strike_flip := false
var _melee_special: Dictionary = {}
var _melee_special_uid := ""
var _reload_time := -1.0
var _reload_uid := ""
var _block_time := -1.0
var _block_uid := ""
var _block_ranged := false
var _recoil := RecoilArt.new()


func refresh(unit:Dictionary, _catalog:Dictionary) -> void:
 _refresh_impact(unit)
 _unit=unit
 if _illustration==null:
  _illustration=Node3D.new();_illustration.name="Illustration";add_child(_illustration)
  _create_ground_shadow()
  _sprite=Sprite3D.new();_sprite.name="Composite";_sprite.set_meta("slot","composite")
  _sprite.pixel_size=BODY_HEIGHT/372.0;_sprite.offset=Vector2(0,179)
  _sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  _sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS;_sprite.alpha_scissor_threshold=.12
  _sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  _sprite.shaded=false;_sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  _material=ShaderMaterial.new();_material.shader=Identity;_sprite.material_override=_material
  _illustration.add_child(_sprite)
 if _impact_alive and int(unit.get("company_id",-1))>=0:
  _info=_people.describe(unit);_idle=_people.field(unit,-1)
 else:
  _idle=null;_info={};_walk=null
 _signature=_info.get("signature",{}).duplicate(true)
 if not _melee_special.is_empty() and not _people.MeleeSpecial.fits_item(_unit,_signature,_melee_special_uid):cancel_motion()
 if _block_time>=0 and _current_shield()!=_block_uid:_block_time=-1.0
 if _reload_time>=0 and not _same_reload_item():_clear_reload()
 _signature["foundation"]={"visible":_idle!=null,"painted":_idle!=null,"identity":"first_muster_shared_fit"}
 get_node("GroundShadow").visible=_idle!=null
 _present(_frame if _walk!=null and _walk.is_running() else -1)
 _sync_billboard_depth()

func follow_walk(tween:Tween) -> void:
 if not _melee_special.is_empty():cancel_motion()
 _utility_step_kind=""
 _utility.clear()
 # Observe this particular paid route tween. A replacement, hidden/dead row,
 # cancellation or finish cannot keep a free-running walk clock alive.
 _block_time=-1.0;_clear_reload();_recoil.clear();_walk=tween
 _present(_people.walk_frame(0.0))

func follow_utility_walk(tween:Tween,kind:String,direction:Vector3) -> void:
 cancel_motion()
 follow_walk(tween)
 _utility_step_kind=kind
 var camera:=get_viewport().get_camera_3d()
 _utility_step_flip=camera!=null and camera.global_basis.x.dot(direction)<-0.05
 _present(_utility_walk_frame(0.0))

func _utility_walk_frame(time:float) -> int:
 # One short, low stride for disengage; two transfer beats when turning places.
 if _utility_step_kind=="footwork":return [0,1,2,4,5,8,9][clampi(floori(time*27.0),0,6)]
 return [0,1,3,5,6,8,9][clampi(floori(time*20.0),0,6)]

func utility_outgoing(event:Dictionary) -> Texture2D:
 if event.kind!="switch" or event.slot not in ["weapon","shield"] or _idle==null:return null
 if str(_signature.get(event.slot,{}).get("item",""))!=event.outgoing:return null
 return _people.utility_pose(_info.recipe,"switch",0)

func play_utility(event:Dictionary,outgoing:Texture2D) -> void:
 if not _impact_alive or not is_visible_in_tree() or not UtilityClock.LENGTH.has(event.kind):return
 # The existing clock validates the receipt against the live arm UID. Only
 # a real, admitted entry can show frame 0; no event is needed to hold frame 1.
 if event.kind=="brace" and (event.slot!="weapon" or event.uid.is_empty() or not _spearwall_active()):return
 _utility.begin(event)
 _utility_outgoing=outgoing
 if not _utility.matches(_unit):_utility.clear();return
 _present(_frame)

func _spearwall_active() -> bool:
 return _impact_alive and is_visible_in_tree() and spearwall_query.is_valid() and spearwall_query.call(_unit)

func has_spearwall_pose() -> bool:
 return _spearwall_held!=null

func _process(delta:float) -> void:
 super._process(delta)
 var utility_tick:=_utility.sample(_unit,_impact_alive and is_visible_in_tree(),delta)
 if (utility_tick and _walk==null) or _spearwall_was_active!=_spearwall_active() or _last_defense!=Defense.kind(_unit):
  _present(_frame if _walk!=null and _walk.is_running() else -1)
 if _recoil.elapsed>=0.0 and is_finite(delta):
  _recoil.advance(delta,_impact_alive and is_visible_in_tree())
  _present(-1)
 if _block_time>=0 and is_finite(delta):
  _block_time+=maxf(delta,0.0)
  if ShieldArt.frame(_block_time)<0 or _current_shield()!=_block_uid:_block_time=-1.0
  _present(_frame if _walk!=null and _walk.is_running() else -1)
 if _reload_time>=0 and is_finite(delta):
  var prior_draw:=DrawArt.frame(_reload_time)
  _reload_time+=maxf(delta,0.0)
  if _reload_time>=DrawArt.DURATION or not _same_reload_item():finish_reload()
  else:
   _present(-1)
   # Sleeve offsets first move rearward on fitted pose 5. Don't cue reach or seat.
   var draw:=DrawArt.frame(_reload_time)
   if prior_draw<5 and draw>=5 and draw<DrawArt.SEAT_FRAME and _people.StockBolt.DEFINITIONS.has(_signature.get("weapon",{}).get("definition","")) and _sprite.texture.has_meta("reload_hand"):
    CrossbowFoley.play(self,"pull")
   return
 if _strike_time>=0 and is_finite(delta):
  if not _melee_special.is_empty() and (not is_visible_in_tree() or not _impact_alive or not _people.MeleeSpecial.fits_item(_unit,_signature,_melee_special_uid)):
   cancel_motion();return
  if not _bow_hook_uid.is_empty() and not _bow_hook_live():
   _strike_time=-1.0;_bow_hook_uid="";_bow_hook_style=""
   _present(-1);return
  _strike_time+=maxf(delta,0.0)
  if not is_visible_in_tree() or not _impact_alive or (not _hook_uid.is_empty() and _signature.get("weapon",{}).get("item","")!=_hook_uid) or _people.strike_frame(_strike_time,_hook_recipe())<0:
   _strike_time=-1.0;_hook_uid=""
   _melee_special={};_melee_special_uid=""
   _bow_hook_uid="";_bow_hook_style=""
  _present(_frame if _walk!=null and _walk.is_running() else -1)
  if _strike_time>=0:return
 if _walk==null:return
 if not _walk.is_running() or not is_visible_in_tree() or not _impact_alive:
  _walk=null;_utility_step_kind="";_present(-1);return
 var time:float=_walk.get_total_elapsed_time()
 var next:int=_people.walk_frame(time) if _utility_step_kind.is_empty() else _utility_walk_frame(time)
 if next!=_frame:_present(next)

func _present(frame:int) -> void:
 _frame=frame
 var tex:Texture2D=_people.field(_unit,frame) if frame>=0 and _idle!=null else _idle
 _utility.sample(_unit,_impact_alive and is_visible_in_tree())
 _spearwall_was_active=_spearwall_active()
 if not _spearwall_was_active and _utility.kind=="brace":_utility.clear()
 _spearwall_held=_people.utility_pose(_info.recipe,"brace",1) if _spearwall_was_active and _idle!=null else null
 _last_defense=Defense.kind(_unit)
 var defense_kind:=Defense.paint_kind(_last_defense,_spearwall_held!=null)
 var defense_step:=0 if _utility.kind==_last_defense and _utility.progress()<0.32 else 1
 _defense_cut=_people.utility_pose(_info.recipe,defense_kind,defense_step) if not defense_kind.is_empty() and _idle!=null and is_visible_in_tree() else null
 if _utility.kind.is_empty():_utility_outgoing=null
 if frame<0 and _idle!=null and _block_time<0 and _strike_time<0 and _reload_time<0 and _recoil.elapsed<0.0:
  var progress:=_utility.progress()
  if _utility.kind not in ["guard","indomitable"] and not _utility.kind.is_empty():
   var cut:=1 if _utility.kind!="brace" and progress>=0.32 and (_utility.kind in UtilityClock.HOLD or progress<0.79) else 0
   var gesture:Texture2D=_utility_outgoing if progress<0.32 and _utility_outgoing!=null else _people.utility_pose(_info.recipe,_utility.kind,cut)
   if gesture!=null:tex=gesture
  if _defense_cut!=null and (tex==_idle or _spearwall_was_active):tex=_defense_cut
  if tex==_idle and _spearwall_held!=null:tex=_spearwall_held
 var swing: int=_people.strike_frame(_strike_time,_hook_recipe()) if _strike_time>=0 else -1
 if swing>=0 and _idle!=null:
  var pose:Texture2D=_people._render(_hook_recipe(),-1,false,swing)
  if pose!=null:tex=pose
 if _reload_time>=0 and _idle!=null:
  var reload_pose:Texture2D=_people._render(_info.recipe,-1,false,-1,DrawArt.frame(_reload_time))
  if reload_pose!=null:tex=reload_pose
 if _block_time>=0 and _idle!=null:
  var brace:Texture2D=_people._render(_info.recipe,-1,false,-1,-1,ShieldArt.frame(_block_time),_block_ranged)
  if brace!=null:tex=brace
 var flip:bool=(_strike_flip and tex!=_idle) if swing>=0 else (frame>=0 and not _utility_step_kind.is_empty() and _utility_step_flip)
 tex=_recoil.stamp(tex)
 if _sprite.flip_h!=flip and _sprite.has_meta("pick_alpha"):_sprite.remove_meta("pick_alpha")
 _sprite.flip_h=flip
 if tex==_sprite.texture:return
 var old_pad:float=float(_sprite.texture.get_meta("painted_top_pad",0)) if _sprite.texture!=null else 0.0
 var top_pad:float=float(tex.get_meta("painted_top_pad",0)) if tex!=null else 0.0
 if top_pad!=old_pad:_sprite.offset.y+=(top_pad-old_pad)*0.5
 _sprite.texture=tex;_sprite.visible=tex!=null
 _material.set_shader_parameter("source_texture",tex)
 if _sprite.has_meta("pick_alpha"):_sprite.remove_meta("pick_alpha")

func play_attack(direction:Vector3) -> void:
 if not _impact_alive or not is_visible_in_tree() or not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001 or not _people.can_strike(_info.get("recipe",{})):
  super.play_attack(direction);return
 cancel_motion()
 var camera:=get_viewport().get_camera_3d()
 _strike_flip=camera!=null and camera.global_basis.x.dot(Vector3(direction.x,0,direction.z))<-0.05
 _strike_time=0.0;_present(-1)

func _hook_recipe() -> Dictionary:
 var recipe:Dictionary=_info.get("recipe",{})
 if not _melee_special.is_empty():
  var gear:=recipe.duplicate();gear.melee_special=_melee_special
  return gear
 if _bow_hook_live():
  var special:=recipe.duplicate();special.bow_hook_pose=_bow_hook_style
  return special
 if _hook_uid.is_empty():return recipe
 var fitted:=recipe.duplicate()
 fitted.billhook_hook=true
 return fitted

func play_fitted_hook(direction:Vector3,uid:String) -> bool:
 var item:Dictionary=_signature.get("weapon",{})
 if not (_impact_alive and is_visible_in_tree()) or uid.is_empty() or item.get("item","")!=uid or item.get("definition","")!=HookArt.DEF or not item.get("visible",false):return false
 if not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001:return false
 var fitted:Dictionary=_info.get("recipe",{}).duplicate()
 fitted.billhook_hook=true
 if not _people.can_strike(fitted):return false
 play_attack(direction)
 if _strike_time<0.0:return false
 _hook_uid=uid
 _present(-1)
 return true

func attack_contact_delay() -> float:
 return _people.strike_contact(_hook_recipe()) if _strike_time>=0.0 else 0.0

func play_fitted_melee_special(direction:Vector3,kind:String,uid:String,plate:Vector3) -> bool:
 if _idle==null or not _impact_alive or not is_visible_in_tree() or not _people.MeleeSpecial.fits_item(_unit,_signature,uid):return false
 if not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001 or not _people.can_strike(_info.recipe):return false
 var camera:=get_viewport().get_camera_3d()
 var flip:=camera!=null and camera.global_basis.x.dot(Vector3(direction.x,0,direction.z))<-0.05
 var move:Dictionary=_people.MeleeSpecial.select(_info.recipe,kind,_sprite,camera,flip,plate)
 if move.is_empty():return false
 cancel_motion()
 _melee_special=move;_melee_special_uid=uid
 _strike_flip=flip;_strike_time=0.0;_present(-1)
 return true

func _bow_hook_live() -> bool:
 return BowHookSpecial.matches(_bow_hook_style,_signature.get("weapon",{}),_unit.get("arms",{}).get("weapon",{}),_bow_hook_uid)

func play_bow_hook_special(direction:Vector3,uid:String,style:String) -> bool:
 if not (_impact_alive and is_visible_in_tree()) or not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001:return false
 if not BowHookSpecial.matches(style,_signature.get("weapon",{}),_unit.get("arms",{}).get("weapon",{}),uid):return false
 var fitted:Dictionary=_info.get("recipe",{}).duplicate();fitted.bow_hook_pose=style
 if not _people.can_strike(fitted):return false
 play_attack(direction) # Same facing and cancellation as the inherited strike.
 if _strike_time<0.0:return false
 _bow_hook_uid=uid;_bow_hook_style=style
 _present(-1)
 return true

func shortbow_can_pose(uid:String) -> bool:
 var recipe:Dictionary=_info.get("recipe",{})
 var item:Dictionary=_signature.get("weapon",{})
 return _impact_alive and is_visible_in_tree() and not uid.is_empty() and item.get("item","")==uid and item.get("visible",false) and _people.is_fitted_bow(recipe)

func shortbow_handoff(uid:String,release:bool) -> Sprite3D:
 if not _bow_hook_uid.is_empty() and not _bow_hook_live():return null
 if not shortbow_can_pose(uid) or _strike_time<0.0:return null
 _strike_time=_people.bow_handoff_time(_info.get("recipe",{}),release)
 _present(-1)
 return _sprite

func _current_shield() -> String:
 return ShieldArt.item(_unit,_signature,_info.get("recipe",{})) if _impact_alive and is_visible_in_tree() else ""

func play_fitted_recoil(direction:Vector3) -> void:
 if _idle==null or not _impact_alive or not is_visible_in_tree() or (_walk!=null and _walk.is_running()):return
 cancel_motion()
 _recoil.begin(direction,get_viewport().get_camera_3d(),_sprite.flip_h)
 _present(-1)

func finish_fitted_recoil() -> void:
 if _recoil.elapsed<0.0:return
 _recoil.clear();_present(-1)

func play_shield_contact(uid:String,condition:int,ranged:bool=false) -> bool:
 var item:Dictionary=_unit.get("arms",{}).get("shield",{})
 var layer:Dictionary=_signature.get("shield",{})
 if _idle==null or not _impact_alive or not is_visible_in_tree() or uid.is_empty() or item.get("id","")!=uid or layer.get("item","")!=uid or int(item.get("condition",-1))!=condition or _info.recipe.get("shield","").is_empty():return false
 var maximum:int=int(layer.get("maximum",0))
 _info.recipe.shield_wear="wear/shield" if condition>0 and maximum>0 and condition*2<=maximum else ""
 if condition==0:_info.recipe.shield=""
 _idle=_people._render(_info.recipe,-1,false)
 if condition==0:_present(-1);return false
 if _current_shield()!=uid or not ShieldArt.ready():return false
 cancel_motion();_block_uid=uid;_block_ranged=ranged;_block_time=0.0;_present(-1)
 return true

func _same_reload_item() -> bool:
 var equipped:Dictionary=_unit.get("arms",{}).get("weapon",{})
 return _impact_alive and is_visible_in_tree() and not _reload_uid.is_empty() and equipped.get("id","")==_reload_uid and equipped.get("loaded",false) and _signature.get("weapon",{}).get("item","")==_reload_uid and _people.StockBolt.fitted(_info.get("recipe",{}))

func play_reload(uid:String) -> void:
 if _idle==null or not DrawArt.ready():return
 _reload_uid=uid
 if not _same_reload_item():_clear_reload();return
 cancel_motion()
 _walk=null;_reload_uid=uid;_reload_time=0.0
 _present(-1)

func _clear_reload() -> void:
 CrossbowFoley.retire_pull(self)
 _reload_time=-1.0;_reload_uid=""

func finish_reload() -> void:
 if _reload_time<0:return
 _clear_reload()
 if is_instance_valid(_sprite):_present(-1)

func present_stock_release(uid:String) -> void:
 if _idle==null or _signature.get("weapon",{}).get("item","")!=uid:return
 _info.recipe.erase("seated_bolt")
 _idle=_people._render(_info.recipe,-1,false)
 _present(_frame)

func cancel_motion() -> void:
 _melee_special={};_melee_special_uid=""
 _bow_hook_uid="";_bow_hook_style=""
 _hook_uid=""
 if not _utility.kind in UtilityClock.HOLD:_utility.clear()
 super.cancel_motion()
 finish_reload()
 if _strike_time<0 and _block_time<0 and _recoil.elapsed<0.0:return
 _recoil.clear()
 _block_time=-1.0
 _strike_time=-1.0
 if is_instance_valid(_sprite):_present(-1)

func preview_texture() -> Texture2D:return _idle
func render_diagnostics() -> Dictionary:
 return {"ok":_idle!=null,"source_kind":"first_muster_shared_fit","issues":_info.get("issues",[]).duplicate(true),"recipe":_info.get("recipe",{}).duplicate(true),"notes":_info.get("notes",[]).duplicate(),"frame":_frame}
func appearance_diagnostics() -> Dictionary:
 return {"treatment":"first_muster_shared_fit","limitations":"Unpainted equipment stays on the native item sheet; it is never replaced mechanically."}
func equipment_issues() -> Array:
 var out:=[]
 for issue:Dictionary in _info.get("issues",[]):
  var record:Dictionary=_signature.get(issue.slot,{})
  out.append({"kind":"omitted","slot":issue.slot,"reason":issue.reason,"definition":issue.definition,"item":issue.uid,"condition":record.get("condition",0),"maximum":record.get("maximum",0)})
 return out

func fitted_collapse_recipe() -> Dictionary:
 return _info.get("recipe",{}).duplicate(true)

func has_defense_pose(kind:String) -> bool:
 return _defense_cut!=null and _last_defense==kind
