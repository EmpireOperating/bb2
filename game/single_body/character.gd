extends "res://company_loop/character.gd"
## Engraved enemy body with the real fitted kit and shared motion.
const EngravedAppearance = preload("res://single_body/appearance.gd")
const WalkPeople = preload("res://engraved_people/actors.gd")
const DrawArt = preload("res://engraved_people/reload_draw.gd")
const CrossbowFoley = preload("res://audio/crossbow/foley.gd")
const ShieldArt = preload("res://engraved_people/shield_contact.gd")
const RecoilArt = preload("res://engraved_people/hit_recoil.gd")
const HOSTILE_DRAW_SECONDS := 0.66
static var appearance = EngravedAppearance.new()
var _diagnostics: Dictionary = {}
var _enemy_walk: Tween
var _enemy_sprite: Sprite3D
var _walk_recipe: Dictionary = {}
var spearwall_query:Callable
var _spearwall_on:=false
var _spearwall_cut:Texture2D
const Defense = preload("res://engraved_battle/defense_state.gd")
const DefenseClock = preload("res://engraved_battle/utility_clock.gd")
var _defense_entry:=DefenseClock.new()
var _last_defense:=""
var _defense_cut:Texture2D

func _spearwall_active() -> bool:
 return _can_move() and not _walk_recipe.is_empty() and spearwall_query.is_valid() and spearwall_query.call(_unit)

func has_spearwall_pose() -> bool:
 return _spearwall_cut!=null
const HookArt = preload("res://engraved_people/billhook_hook.gd")
var _hook_uid := ""
const BowHookSpecial = preload("res://engraved_people/bow_hook_special.gd")
var _bow_hook_uid := ""
var _bow_hook_style := ""
var _strike_time := -1.0
var _strike_flip := true
var _melee_special: Dictionary = {}
var _melee_special_uid := ""
var _natural_flip := true
var _unit:Dictionary={}
var _reload_uid := ""
var _reload_time := -1.0
var _block_time := -1.0
var _block_uid := ""
var _block_ranged := false
var _recoil := RecoilArt.new()


func refresh(unit: Dictionary, catalog: Dictionary) -> void:
 _unit=unit
 _alive=int(unit.get("hp",1))>0
 if not _alive:cancel_motion()
 if _illustration==null:
  _illustration=Node3D.new();_illustration.name="Illustration";add_child(_illustration);_create_ground_shadow()
 for child in _illustration.get_children():child.free()
 var result: Dictionary=appearance.describe(unit,catalog)
 _preview=result.texture;_signature=result.signature.duplicate(true)
 _walk_recipe=result.get("walk_recipe",{})
 if not _melee_special.is_empty() and (_walk_recipe.is_empty() or not WalkPeople.MeleeSpecial.fits_item(_unit,_signature,_melee_special_uid)):
  # Refresh is rebuilding the Composite; don't try to repaint the retired node.
  _melee_special={};_melee_special_uid="";_strike_time=-1.0
 if _block_time>=0 and _current_shield()!=_block_uid:_block_time=-1.0
 if _reload_time>=0 and not _same_reload_item(_reload_uid):_clear_reload()
 _enemy_sprite=null
 _diagnostics={"ok":result.ok,"errors":result.errors.duplicate(),"issues":result.issues.duplicate(true),"plan":result.plan.duplicate(true),"source_kind":result.get("source_kind","")}
 get_node("GroundShadow").visible=result.ok
 if not result.ok:_enemy_walk=null;cancel_motion();return
 if _motion_kind=="shield" and not _signature.get("shield",{}).get("visible",false):cancel_motion()
 var frame: Dictionary=result.plan.frame
 var geometry: Dictionary=result.plan.geometry
 var canvas:=Vector2(float(frame.size[0]),float(frame.size[1]))
 var origin:=Vector2(float(frame.base_origin[0]),float(frame.base_origin[1]))
 var foot:=Vector2(float(geometry.stance_x)+origin.x,float(frame.stance_anchor[1]))
 var pixel_size:=float(geometry.body_height)/(float(geometry.foot_y)-float(geometry.base_alpha_top))
 var flipped:=int(unit.get("side",0))==1
 _natural_flip=flipped
 var display_foot:=Vector2(canvas.x-foot.x if flipped else foot.x,foot.y)
 _diagnostics.merge({"canvas":canvas,"base_origin":origin,"foot_pixel":foot,"display_foot_pixel":display_foot,"donor_foot_pixel":frame.stance_anchor.duplicate(),"pixel_size":pixel_size,"body_height":geometry.body_height,"stack":result.plan.layers.duplicate(true)})
 _signature.foundation={"definition":"","item":"","asset":result.plan.base.path,"painted":true,"visible":true,"identity":"rolled_physical_kit","condition":0,"maximum":0}
 var sprite:=Sprite3D.new();sprite.name="Composite";sprite.texture=_preview
 sprite.pixel_size=pixel_size;sprite.offset=Vector2(canvas.x/2.0-display_foot.x,display_foot.y-canvas.y/2.0)
 sprite.flip_h=flipped;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS;sprite.alpha_scissor_threshold=0.12
 sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;sprite.shaded=false;sprite.double_sided=true;sprite.no_depth_test=false
 sprite.modulate=Color.WHITE;sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var material:=ShaderMaterial.new();material.shader=ColorIdentity;material.set_shader_parameter("source_texture",_preview);sprite.material_override=material
 sprite.set_meta("slot","composite");_illustration.add_child(sprite)
 _enemy_sprite=sprite
 _present_enemy_walk()
 _sync_billboard_depth();_apply_motion()

func follow_enemy_walk(tween:Tween) -> void:
 if not _melee_special.is_empty():cancel_motion()
 _block_time=-1.0
 _recoil.clear()
 _clear_reload()
 _enemy_walk=tween
 _present_enemy_walk()

func _process(delta:float) -> void:
 super._process(delta)
 var defense_tick:=_defense_entry.sample(_unit,_can_move(),delta)
 if _recoil.elapsed>=0.0 and is_finite(delta):
  _recoil.advance(delta,_can_move())
  _present_enemy_walk()
 elif _block_time>=0 and is_finite(delta):
  _block_time+=maxf(delta,0.0)
  if ShieldArt.frame(_block_time)<0 or _current_shield()!=_block_uid:_block_time=-1.0
  _present_enemy_walk()
 elif _reload_time>=0 and is_finite(delta):
  var prior_draw:=_reload_frame()
  _reload_time+=maxf(0.0,delta)
  if _reload_time>=HOSTILE_DRAW_SECONDS or not _same_reload_item(_reload_uid):
   _clear_reload();_present_enemy_walk()
  else:
   _present_enemy_walk()
   # Match the company cue: first rearward draw, never reach or seating.
   var draw:=_reload_frame()
   if prior_draw<5 and draw>=5 and draw<DrawArt.SEAT_FRAME and is_instance_valid(_enemy_sprite) and _enemy_sprite.texture!=null and _enemy_sprite.texture.has_meta("reload_hand"):
    CrossbowFoley.play(self,"pull")
 elif _strike_time>=0 and is_finite(delta):
  if not _melee_special.is_empty() and (not _can_move() or not WalkPeople.MeleeSpecial.fits_item(_unit,_signature,_melee_special_uid)):
   cancel_motion();return
  if not _bow_hook_uid.is_empty() and not _bow_hook_live():
   _strike_time=-1.0;_bow_hook_uid="";_bow_hook_style=""
   _present_enemy_walk();return
  _strike_time+=maxf(delta,0.0)
  if not _can_move() or (not _hook_uid.is_empty() and _signature.get("weapon",{}).get("item","")!=_hook_uid) or WalkPeople.strike_frame(_strike_time,_hook_recipe())<0:
   _strike_time=-1.0;_hook_uid=""
   _melee_special={};_melee_special_uid=""
   _bow_hook_uid="";_bow_hook_style=""
  _present_enemy_walk()
 elif _enemy_walk!=null or _spearwall_on!=_spearwall_active() or defense_tick or _last_defense!=Defense.kind(_unit):_present_enemy_walk()

func _present_enemy_walk() -> void:
 if not is_instance_valid(_enemy_sprite):return
 if _enemy_walk!=null and (not _alive or not is_visible_in_tree() or not _enemy_walk.is_running()):_enemy_walk=null
 _spearwall_on=_spearwall_active()
 _spearwall_cut=WalkPeople.utility_pose(_walk_recipe,"brace",1) if _spearwall_on else null
 _last_defense=Defense.kind(_unit)
 var defense_kind:=Defense.paint_kind(_last_defense,_spearwall_cut!=null)
 var defense_step:=0 if _defense_entry.kind==_last_defense and _defense_entry.progress()<0.32 else 1
 _defense_cut=WalkPeople.utility_pose(_walk_recipe,defense_kind,defense_step) if not defense_kind.is_empty() and _can_move() else null
 var tex:Texture2D=_preview
 var frame:=WalkPeople.strike_frame(_strike_time,_hook_recipe()) if _strike_time>=0 else -1
 if _block_time>=0:
  tex=WalkPeople._render(_walk_recipe,-1,false,-1,-1,ShieldArt.frame(_block_time),_block_ranged)
 elif _reload_time>=0:
  # Finish before the next existing AI beat; do not hold enemy decisions.
  tex=WalkPeople._render(_walk_recipe,-1,false,-1,_reload_frame())
 elif frame>=0 and not _walk_recipe.is_empty():
  tex=WalkPeople._render(_hook_recipe(),-1,false,frame)
 elif _enemy_walk!=null and not _walk_recipe.is_empty():
  tex=WalkPeople._render(_walk_recipe,WalkPeople.walk_frame(_enemy_walk.get_total_elapsed_time()),false)
 elif _defense_cut!=null:
  tex=_defense_cut
 elif _spearwall_cut!=null:
  tex=_spearwall_cut
 var flip:=_strike_flip if frame>=0 and tex!=null and tex!=_preview else _natural_flip
 if _enemy_sprite.flip_h!=flip and _enemy_sprite.has_meta("pick_alpha"):_enemy_sprite.remove_meta("pick_alpha")
 _enemy_sprite.flip_h=flip
 if tex==null:tex=_preview
 tex=_recoil.stamp(tex)
 if tex==_enemy_sprite.texture:return
 var old_pad:float=float(_enemy_sprite.texture.get_meta("painted_top_pad",0)) if _enemy_sprite.texture!=null else 0.0
 var top_pad:float=float(tex.get_meta("painted_top_pad",0)) if tex!=null else 0.0
 if top_pad!=old_pad:_enemy_sprite.offset.y+=(top_pad-old_pad)*0.5
 _enemy_sprite.texture=tex
 _enemy_sprite.material_override.set_shader_parameter("source_texture",tex)
 if _enemy_sprite.has_meta("pick_alpha"):_enemy_sprite.remove_meta("pick_alpha")

func play_attack(direction:Vector3) -> void:
 if not _can_move() or not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001 or not WalkPeople.can_strike(_walk_recipe):
  super.play_attack(direction);return
 cancel_motion()
 var camera:=get_viewport().get_camera_3d()
 _strike_flip=_natural_flip if camera==null else camera.global_basis.x.dot(Vector3(direction.x,0,direction.z))<=0.05
 _strike_time=0.0;_present_enemy_walk()

func _hook_recipe() -> Dictionary:
 var recipe:Dictionary=_walk_recipe
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
 if not (_can_move()) or uid.is_empty() or item.get("item","")!=uid or item.get("definition","")!=HookArt.DEF or not item.get("visible",false):return false
 if not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001:return false
 var fitted:Dictionary=_walk_recipe.duplicate()
 fitted.billhook_hook=true
 if not WalkPeople.can_strike(fitted):return false
 play_attack(direction)
 if _strike_time<0.0:return false
 _hook_uid=uid
 _present_enemy_walk()
 return true

func attack_contact_delay() -> float:
 return WalkPeople.strike_contact(_hook_recipe()) if _strike_time>=0.0 else 0.0

func play_fitted_melee_special(direction:Vector3,kind:String,uid:String,plate:Vector3) -> bool:
 if not _can_move() or not WalkPeople.MeleeSpecial.fits_item(_unit,_signature,uid):return false
 if not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001 or not WalkPeople.can_strike(_walk_recipe):return false
 var camera:=get_viewport().get_camera_3d()
 var flip:=_natural_flip if camera==null else camera.global_basis.x.dot(Vector3(direction.x,0,direction.z))<=0.05
 var move:=WalkPeople.MeleeSpecial.select(_walk_recipe,kind,_enemy_sprite,camera,flip,plate)
 if move.is_empty():return false
 cancel_motion()
 _melee_special=move;_melee_special_uid=uid
 _strike_flip=flip;_strike_time=0.0;_present_enemy_walk()
 return true

func _bow_hook_live() -> bool:
 return BowHookSpecial.matches(_bow_hook_style,_signature.get("weapon",{}),_unit.get("arms",{}).get("weapon",{}),_bow_hook_uid)

func play_bow_hook_special(direction:Vector3,uid:String,style:String) -> bool:
 if not (_can_move()) or not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001:return false
 if not BowHookSpecial.matches(style,_signature.get("weapon",{}),_unit.get("arms",{}).get("weapon",{}),uid):return false
 var fitted:Dictionary=_walk_recipe.duplicate();fitted.bow_hook_pose=style
 if not WalkPeople.can_strike(fitted):return false
 play_attack(direction) # Same facing and cancellation as the inherited strike.
 if _strike_time<0.0:return false
 _bow_hook_uid=uid;_bow_hook_style=style
 _present_enemy_walk()
 return true

func shortbow_can_pose(uid:String) -> bool:
 var item:Dictionary=_signature.get("weapon",{})
 return _can_move() and not uid.is_empty() and item.get("item","")==uid and item.get("visible",false) and WalkPeople.is_fitted_bow(_walk_recipe)

func shortbow_handoff(uid:String,release:bool) -> Sprite3D:
 if not _bow_hook_uid.is_empty() and not _bow_hook_live():return null
 if not shortbow_can_pose(uid) or _strike_time<0.0:return null
 _strike_time=WalkPeople.bow_handoff_time(_walk_recipe,release)
 _present_enemy_walk()
 return _enemy_sprite

func _current_shield() -> String:
 return ShieldArt.item(_unit,_signature,_walk_recipe) if _can_move() else ""

func play_fitted_recoil(direction:Vector3) -> void:
 if not _can_move() or _walk_recipe.is_empty() or not is_instance_valid(_enemy_sprite) or (_enemy_walk!=null and _enemy_walk.is_running()):return
 cancel_motion()
 _recoil.begin(direction,get_viewport().get_camera_3d(),_natural_flip)
 _present_enemy_walk()

func finish_fitted_recoil() -> void:
 if _recoil.elapsed<0.0:return
 _recoil.clear();_present_enemy_walk()

func play_shield_contact(uid:String,condition:int,ranged:bool=false) -> bool:
 var item:Dictionary=_unit.get("arms",{}).get("shield",{})
 var layer:Dictionary=_signature.get("shield",{})
 if not _can_move() or uid.is_empty() or item.get("id","")!=uid or layer.get("item","")!=uid or int(item.get("condition",-1))!=condition or _walk_recipe.get("shield","").is_empty():return false
 # Refresh only the struck shield and retain its wear through the counter.
 var maximum:int=int(layer.get("maximum",0))
 _walk_recipe.shield_wear="wear/shield" if condition>0 and maximum>0 and condition*2<=maximum else ""
 if condition==0:_walk_recipe.shield=""
 _preview=WalkPeople._render(_walk_recipe,-1,false)
 if condition==0:_present_enemy_walk();return false
 if _current_shield()!=uid or not ShieldArt.ready():return false
 cancel_motion();_block_uid=uid;_block_ranged=ranged;_block_time=0.0;_present_enemy_walk()
 return true

func _reload_frame() -> int:
 return DrawArt.frame(_reload_time*DrawArt.DURATION/HOSTILE_DRAW_SECONDS)

func _same_reload_item(uid:String) -> bool:
 var equipped:Dictionary=_unit.get("arms",{}).get("weapon",{})
 var layer:Dictionary=_signature.get("weapon",{})
 return _can_move() and not uid.is_empty() and layer.get("visible",false) and layer.get("item","")==uid and equipped.get("id","")==uid and equipped.get("loaded",false) and WalkPeople.StockBolt.fitted(_walk_recipe)

func play_reload(uid:String) -> void:
 if not _same_reload_item(uid) or not DrawArt.ready():return
 cancel_motion()
 _enemy_walk=null;_reload_uid=uid;_reload_time=0.0
 _present_enemy_walk()

func _clear_reload() -> void:
 CrossbowFoley.retire_pull(self)
 _reload_uid="";_reload_time=-1.0

func finish_reload() -> void:
 if _reload_time<0:return
 _clear_reload();_present_enemy_walk()

func present_stock_release(uid:String) -> void:
 if not is_instance_valid(_enemy_sprite) or _walk_recipe.is_empty() or _signature.get("weapon",{}).get("item","")!=uid:return
 _walk_recipe.erase("seated_bolt")
 _preview=WalkPeople._render(_walk_recipe,-1,false)
 _present_enemy_walk()

func cancel_motion() -> void:
 _melee_special={};_melee_special_uid=""
 _bow_hook_uid="";_bow_hook_style=""
 _hook_uid=""
 super.cancel_motion()
 finish_reload()
 if _strike_time<0 and _block_time<0 and _recoil.elapsed<0.0:return
 _recoil.clear()
 _block_time=-1.0
 _strike_time=-1.0
 _present_enemy_walk()

func equipment_issues() -> Array:
 return _diagnostics.get("issues",[]).duplicate(true)

func appearance_diagnostics() -> Dictionary:
 if not _diagnostics.get("ok",false):
  return {"treatment":"unavailable_enemy_plate","painted_highwayman":false,"gear_recolored":false,"limitations":"No verified painting for this enemy. Combat equipment is authoritative."}

 return {"treatment":"rolled_physical_kit","painted_highwayman":false,"gear_recolored":false,"limitations":"Visible gear comes from this fighter’s kit. Reserve items are stowed; damaged equipment is not guaranteed salvage."}

func render_diagnostics() -> Dictionary:
 var out:=_diagnostics.duplicate(true);out["appearance"]=appearance_diagnostics();out["motion"]=_motion_kind;return out

func fitted_collapse_recipe() -> Dictionary:
 return _walk_recipe.duplicate(true)

func play_utility(event:Dictionary,_outgoing:Texture2D) -> void:
 if event.kind not in ["guard","indomitable"] or not _can_move():return
 _defense_entry.begin(event)
 if not _defense_entry.matches(_unit):_defense_entry.clear();return
 _present_enemy_walk()

func has_defense_pose(kind:String) -> bool:
 return _defense_cut!=null and _last_defense==kind
