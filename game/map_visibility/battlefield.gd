extends "res://combat_pass/battlefield.gd"
## Successor-only presentation; combat and equipment remain inherited authorities.
var _camera_active := -2
var _overview_size := 64.0
var _overview_mode := false
var _presented := {}
var fog
var marker_builds := 0
var _marker_instance: MeshInstance3D
var _marker_mesh: ImmediateMesh
var _marker_material: StandardMaterial3D
var _line_vertices := PackedVector3Array()
var _line_colors := PackedColorArray()
var _fill_vertices := PackedVector3Array()
var _fill_colors := PackedColorArray()
var _marker_stamp := 0
var _ground_stamp := 0
var _ground_targets := {}
var obstacles_hidden := false
var _hidden_obstacle_meshes: Array[MeshInstance3D] = []
var _recoil_beat: Dictionary = {}
const FallPlane = preload("res://engraved_battle/fall_plane.gd")
const UndeadFall = preload("res://painted_merge/hostile_motion/undead_fall.gd")
# One noninteractive projection per witnessed casualty, owned by this field.
var _corpses: Dictionary = {}

func _init() -> void:
 controller=load("res://map_visibility/controller.gd").new()

func _create_terrain() -> Node3D:
 return load("res://map_visibility/terrain.gd").new()

func _board_bounds() -> AABB:
 var result := AABB(Layout.world(Vector2i.ZERO)-Vector3(1,0,1),Vector3.ZERO)
 for r in battle.height():
  for q in battle.width():
   var cell := Vector2i(q,r)
   for corner in Layout.corners(cell,float(battle.tiles.get(battle.key(cell),{}).get("height",0)),1.08):
    result=result.expand(corner)
 return result

func _apply_camera() -> void:
 var bounds := _board_bounds()
 # An offset-q column zigzags; its rows are not a straight hex-neighbor axis.
 # Align the true axial (0,+1) chain with screen-down instead. Its ground
 # normal becomes screen-right. Only azimuth changes; retain pitch/distance.
 var depth := Vector2(10,22).length()
 var offset := Vector3(depth*0.5,18,depth*sqrt(3.0)*0.5)
 var distance := maxf(offset.length(),camera.size*1.5)
 camera.position=camera_focus+offset.normalized()*distance
 camera.look_at(camera_focus,Vector3.UP)
 camera.far=maxf(160,distance+bounds.size.length()*2.0+50)
 for child in get_children():
  if child is DirectionalLight3D:child.directional_shadow_max_distance=maxf(65,distance+camera.size*2)

func _opening_focus_world(cell: Vector2i, shift: Vector2i) -> Vector3:
 return tile_world(cell if shift==Vector2i.ZERO else battle.offset(battle.axial(cell)-shift))

func reset_camera() -> void:
 _overview_mode=false
 # At setup only, use the original formation's focus. Do not move the initial
 # view with the optional whole-company pad translation. Home after mounting
 # still targets the currently selected real fighter, not this reference.
 var opening_shift: Vector2i = Vector2i.ZERO if built else battle.get_meta(&"level_opening_v1_player_shift",Vector2i.ZERO)
 var id: int=controller.selected
 if id<0 or id>=battle.units.size() or battle.units[id].side!=0 or not battle.living(battle.units[id]):
  id=battle.active_id if battle.active_id>=0 and battle.units[battle.active_id].side==0 else -1
 if id>=0:
  camera_focus=_opening_focus_world(battle.pos(battle.units[id]),opening_shift)
 else:
  camera_focus=Vector3.ZERO
  var count=0
  for u in battle.units:
   if u.side==0 and battle.living(u):camera_focus+=_opening_focus_world(battle.pos(u),opening_shift);count+=1
  if count>0:camera_focus/=count
 camera.size=14.2
 _apply_camera()

func overview() -> void:
 _overview_mode=true
 var bounds := _board_bounds()
 camera_focus=bounds.get_center();camera.size=24
 _apply_camera()
 var viewport := get_viewport().get_visible_rect().size
 var safe := Rect2(Vector2(24,160),Vector2(maxf(1,viewport.x-48),maxf(1,viewport.y-470)))
 var rect := Rect2(camera.unproject_position(bounds.position),Vector2.ZERO)
 for cell in [Vector2i(0,0),Vector2i(battle.width()-1,0),Vector2i(0,battle.height()-1),Vector2i(battle.width()-1,battle.height()-1)]:
  for y in [0.0,bounds.end.y]:
   for corner in Layout.corners(cell,y/Layout.HEIGHT_STEP,1.08):rect=rect.expand(camera.unproject_position(corner))
 camera.size*=maxf(rect.size.x/safe.size.x,rect.size.y/safe.size.y)*1.02
 _apply_camera()
 # Projection-derived pixels/world works with either Camera3D aspect policy.
 var center := camera.unproject_position(bounds.get_center())
 var pixel_scale := camera.unproject_position(bounds.get_center()+camera.global_basis.x).x-center.x
 var delta := center-safe.get_center()
 camera_focus+=camera.global_basis.x*(delta.x/pixel_scale)-camera.global_basis.y*(delta.y/pixel_scale)
 _apply_camera()
 _overview_size=camera.size

func zoom_camera(amount: float) -> void:
 _overview_mode=false
 camera.size=clampf(camera.size+amount,5,maxf(_overview_size,120))

func pan_camera(delta: Vector2) -> void:
 _overview_mode=false
 camera_focus+=camera.basis.x*delta.x+Vector3(camera.basis.z.x,0,camera.basis.z.z).normalized()*delta.y
 var bounds := _board_bounds()
 camera_focus.x=clampf(camera_focus.x,bounds.position.x-1,bounds.end.x+1)
 camera_focus.z=clampf(camera_focus.z,bounds.position.z-1,bounds.end.z+1)
 _apply_camera()

var _enemy_walk_ends: Dictionary = {}
var _contact_left := 0.0
var _pending_vitals: Dictionary = {}
var _impact_beats: Array[Dictionary] = []
var _instant_strike:Dictionary={}
var _shield_gap:=false
const MAX_IMPACT_BEATS := 8
const BLOCK_BEFORE_COUNTER := 0.175
var _bolt_mesh: MeshInstance3D
var _bolt_material: ShaderMaterial
var _bolt_duration := 0.0
var _bolt_origin := Vector3.ZERO
var _bolt_goal := Vector3.ZERO
var _bolt_arc := 0.0
var _bolt_path_fixed := false

const HookArt = preload("res://engraved_people/billhook_hook.gd")
var _hook_drag:Dictionary={}

func impact_pending() -> bool:
 if not _impact_beats.is_empty() or not _hook_drag.is_empty():return true
 if battle.result.is_empty():return false
 # Keep the existing terminal delay for visible, still-animating undead falls.
 # The approved human pose settles within the existing result beat.
 # Settled bodies must never hold the battle open.
 for fall in _corpses.values():
  if not fall is FallPlane and fall.age<_fall_duration(fall) and fall.is_visible_in_tree() and battle.tile_visible(0,fall.get_meta("fall_cell")):return true
 return false

func _hold_impact_refresh() -> bool:
 if _impact_beats.is_empty():return false
 # Keep an already-presented casualty through windup only. Never keep a
 # living unit that has since left party sight, or construct a hidden actor.
 for id in actors:
  if not battle.unit_visible(0,id) and not _held_casualty(id):actors[id].hide()
 return true

func _held_casualty(id:int) -> bool:
 return _pending_vitals.has(id) and not battle.living(battle.units[id]) and battle.tile_visible(0,battle.pos(battle.units[id]))

func _display_hit_vitals(id:int) -> Dictionary:
 return _pending_vitals.get(id,battle.units[id])

func _sync_pending_vitals() -> void:
 _pending_vitals.clear()
 for beat:Dictionary in _impact_beats:
  if not beat.vitals.is_empty() and not _pending_vitals.has(beat.target):_pending_vitals[beat.target]=beat.vitals

const StockBolt = preload("res://engraved_people/stock_bolt.gd")
const Shortbow = preload("res://engraved_people/bow_motion.gd")
const BowHookSpecial = preload("res://engraved_people/bow_hook_special.gd")
const FITTED_BOW_DEFINITIONS := ["shortbow","short_bow","bow","warbow","hm_trial_v1:old24-archer_weapon","hm_trial_v1:old24-archer_heavy","hm_trial_v1:old24-reedrunner_bow"]
const RangedShield = preload("res://map_visibility/ranged_shield.gd")
const CrossbowFoley = preload("res://audio/crossbow/foley.gd")
const BowFoley = preload("res://audio/shortbow/foley.gd")
const MeleeFoley = preload("res://audio/melee/foley.gd")
const MeleeArsenal = preload("res://src/arsenal.gd")
const MeleeSpecial = preload("res://engraved_people/melee_special.gd")
const BOLT_DEPTH_BIAS := 0.035 # Offset toward the ortho camera to avoid stock-plane z-fighting.
var _bolt_takeoff := Vector3.RIGHT
var _arrow_material:ShaderMaterial
var _shield_impacts:Array[Node3D]=[]
var _bow_foley:BowFoley
var _melee_foley:MeleeFoley

func _play_bow_cue(cue:String) -> void:
 if cue.is_empty() or not is_visible_in_tree():return
 if _bow_foley==null:
  _bow_foley=BowFoley.new();_bow_foley.name="ShortbowSound";add_child(_bow_foley)
 _bow_foley.play_cue(cue)

func _shortbow_arrival_sound(beat:Dictionary) -> void:
 if not is_instance_valid(_bolt_mesh) or not _bolt_mesh.has_meta("shortbow_arrow"):return
 var cue:String=beat.get("shortbow_cue","")
 if cue.is_empty() or not battle.unit_visible(0,beat.source):return
 if not battle.unit_visible(0,beat.target) and not _held_casualty(beat.target):return
 var src:Node3D=actors.get(beat.source);var dst:Node3D=actors.get(beat.target)
 if not is_instance_valid(src) or not is_instance_valid(dst) or src.get_instance_id()!=beat.owner or dst.get_instance_id()!=beat.shield_owner or not src.visible or not dst.visible:return
 _play_bow_cue(cue)

# Match the fitted crossbow that actually launched this painted bolt.
func _crossbow_arrival_sound(beat:Dictionary) -> void:
 var definition:String=beat.get("crossbow_release_definition","")
 if definition.is_empty() or not is_instance_valid(_bolt_mesh) or not _bolt_mesh.has_meta("crossbow_bolt"):return
 var cue:="block" if beat.has("ranged_shield_condition") else "body" if beat.get("recoil",false) else "pass" if beat.get("crossbow_clean_miss",false) else ""
 if cue.is_empty() or not battle.unit_visible(0,beat.source):return
 if not battle.unit_visible(0,beat.target) and not (cue=="body" and _held_casualty(beat.target)):return
 var src:Node3D=actors.get(beat.source);var dst:Node3D=actors.get(beat.target)
 if not is_instance_valid(src) or not is_instance_valid(dst) or src.get_instance_id()!=beat.owner or dst.get_instance_id()!=beat.shield_owner or not src.is_visible_in_tree() or not dst.is_visible_in_tree():return
 var uid:String=beat.get("stock_uid","")
 if uid.is_empty():return
 var worn:Dictionary=src.layer_signature().get("weapon",{})
 var equipped:Dictionary=battle.units[beat.source].get("arms",{}).get("weapon",{})
 if not worn.get("visible",false) or worn.get("definition","")!=definition or worn.get("item","")!=uid or equipped.get("definition","")!=definition or equipped.get("id","")!=uid:return
 CrossbowFoley.play(self,cue)

func _melee_contact_sound(beat:Dictionary, blocked:bool) -> void:
 var landed_melee:bool=beat.get("recoil",false) and beat.has("melee_body_weapon")
 if not is_visible_in_tree() or (not landed_melee and not beat.get("melee_contact",false)):return
 var cue:="block" if blocked and beat.get("melee_shield_loss",false) else "body" if landed_melee else "miss" if beat.get("melee_clean_miss",false) else ""
 if cue.is_empty() or not battle.unit_visible(0,beat.source):return
 if not battle.unit_visible(0,beat.target) and not (cue=="body" and beat.get("fall",false) and battle.tile_visible(0,battle.pos(battle.units[beat.target]))):return
 var src:Node3D=actors.get(beat.source);var dst:Node3D=actors.get(beat.target)
 if not is_instance_valid(src) or not is_instance_valid(dst) or src.get_instance_id()!=beat.owner or dst.get_instance_id()!=beat.shield_owner or not src.is_visible_in_tree() or not dst.is_visible_in_tree():return
 var fighter:Dictionary=battle.units[beat.source]
 var equipped:Dictionary=fighter.get("arms",{}).get("weapon",{})
 if cue=="body":
  # A landed physical melee hit needs no specific atlas or family.
  if fighter.weapon!=beat.melee_body_weapon or equipped.get("id","")!=beat.melee_body_uid or equipped.get("definition","")!=beat.melee_body_definition:return
 else:
  # Keep the approved, narrower block and clean-miss routes unchanged.
  var worn:Dictionary=src.layer_signature().get("weapon",{})
  if not worn.get("visible",false) or worn.get("item","")!=beat.melee_uid or equipped.get("id","")!=beat.melee_uid or worn.get("definition","")!=equipped.get("definition",""):return
 if _melee_foley==null:
  _melee_foley=MeleeFoley.new();_melee_foley.name="MeleeSound";add_child(_melee_foley)
 _melee_foley.play_cue(cue)

func _ranged_plate(beat:Dictionary) -> Dictionary:
 if not beat.has("ranged_shield_condition") or not battle.unit_visible(0,beat.source) or not battle.unit_visible(0,beat.target):return {}
 var src:Node3D=actors.get(beat.source);var dst:Node3D=actors.get(beat.target)
 if not is_instance_valid(src) or not is_instance_valid(dst) or src.get_instance_id()!=beat.owner or dst.get_instance_id()!=beat.shield_owner or not src.visible or not dst.visible:return {}
 var item:Dictionary=battle.units[beat.target].get("arms",{}).get("shield",{})
 var layer:Dictionary=dst.layer_signature().get("shield",{})
 if item.get("id","")!=beat.shield_uid or int(item.get("condition",-1))!=beat.ranged_shield_condition or layer.get("item","")!=beat.shield_uid or not layer.get("visible",false):return {}
 var sprite:Sprite3D=dst.get_node_or_null("Illustration/Composite")
 if sprite==null or sprite.texture==null or not sprite.texture.has_meta("fitted_shield"):return {}
 var ink:Dictionary=sprite.texture.get_meta("fitted_shield")
 var side:float=-1.0 if sprite.flip_h else 1.0
 var middle:=sprite.texture.get_size()*0.5
 var center:Vector2=ink.center
 var xy:=sprite.offset+Vector2((center.x-middle.x)*side,middle.y-center.y)
 var basis:=camera.global_basis
 var point:=sprite.global_position+(basis.x*xy.x+basis.y*xy.y)*sprite.pixel_size
 return {"point":point,"ink":ink,"side":side,"scale":sprite.pixel_size}

func _lock_ranged_shield(beat:Dictionary) -> bool:
 var plate:=_ranged_plate(beat)
 if plate.is_empty():return false
 _bolt_goal=plate.point
 beat.ranged_shield_aim=_bolt_goal
 return true

func _show_ranged_shield(beat:Dictionary) -> void:
 if not beat.has("ranged_shield_aim") or not is_instance_valid(_bolt_mesh) or _shield_impacts.size()>=8:return
 var plate:=_ranged_plate(beat)
 if plate.is_empty() or Vector3(plate.point).distance_to(beat.ranged_shield_aim)>0.16:return
 var effect:=RangedShield.new()
 effect.victim=beat.target;effect.actor_instance=beat.shield_owner;effect.cell=battle.pos(battle.units[beat.target])
 add_child(effect)
 effect.prime(beat.ranged_shield_aim,camera,_bolt_mesh,plate.ink,plate.side,plate.scale,beat.ranged_shield_condition==0)
 _shield_impacts.append(effect)

func _advance_shield_impacts(delta:float) -> void:
 for i in range(_shield_impacts.size()-1,-1,-1):
  var effect=_shield_impacts[i]
  var dst:Node3D=actors.get(effect.victim)
  if not is_visible_in_tree() or not is_instance_valid(dst) or dst.get_instance_id()!=effect.actor_instance or not dst.visible or not battle.unit_visible(0,effect.victim) or battle.pos(battle.units[effect.victim])!=effect.cell or effect.age+delta>=effect.lifetime:
   remove_child(effect);effect.queue_free();_shield_impacts.remove_at(i)
  else:effect.advance(delta,camera)

func _melee_special_shield(beat:Dictionary,defender:Node3D) -> Vector3:
 # Use the painted plate's currently mounted socket, not the recipient's chest.
 var uid:String=beat.get("shield_uid","")
 var physical:Dictionary=battle.units[beat.target].get("arms",{}).get("shield",{})
 var drawn:Dictionary=defender.layer_signature().get("shield",{})
 if uid.is_empty() or physical.get("id","")!=uid or drawn.get("item","")!=uid or drawn.get("definition","")!=physical.get("definition","") or not drawn.get("visible",false):return Vector3.INF
 var sprite:=defender.get_node_or_null("Illustration/Composite") as Sprite3D
 if sprite==null or not sprite.is_visible_in_tree() or sprite.texture==null:return Vector3.INF
 var ink:Dictionary=sprite.texture.get_meta("fitted_shield",{})
 if not ink.has("center"):return Vector3.INF
 var xy:Vector2=ink.center-sprite.texture.get_size()*0.5
 if sprite.flip_h:xy.x=-xy.x
 xy.y=-xy.y
 xy+=sprite.offset
 var basis:=camera.global_basis
 return sprite.global_position+(basis.x*xy.x+basis.y*xy.y)*sprite.pixel_size

func _start_melee_special(beat:Dictionary,attacker:Node3D,defender:Node3D) -> bool:
 var kind:String=beat.get("melee_special_kind","")
 if kind.is_empty() or defender.get_instance_id()!=beat.shield_owner or not attacker.has_method("play_fitted_melee_special"):return false
 var plate:=Vector3.INF
 if kind=="split_shield":
  if not is_instance_valid(camera) or not battle.unit_visible(0,beat.target):return false
  plate=_melee_special_shield(beat,defender)
  if not plate.is_finite():return false
 return attacker.play_fitted_melee_special(beat.direction,kind,beat.melee_special_uid,plate)

func _start_impact_pose(beat:Dictionary) -> float:
 # A later beat cannot reacquire an actor that the sight mount has retired.
 var a:Node3D=actors.get(beat.source)
 var v:Node3D=actors.get(beat.target)
 if not is_instance_valid(a) or not is_instance_valid(v) or a.get_instance_id()!=beat.owner:return 0.0
 if not a.visible or not v.visible or not battle.unit_visible(0,beat.source):return 0.0
 if not battle.unit_visible(0,beat.target) and not _held_casualty(beat.target):return 0.0
 var ferry_uid:String=beat.get("ferryman_uid","")
 if not ferry_uid.is_empty() and v.get_instance_id()==beat.shield_owner and battle.tile_visible(0,beat.ferryman_origin) and a.has_method("play_bow_hook_special") and a.play_bow_hook_special(beat.direction,ferry_uid,BowHookSpecial.FERRY):
  # Route the resolved result into the existing contact-owned skid.
  beat.hook_uid=ferry_uid;beat.hook_origin=beat.ferryman_origin
  return a.attack_contact_delay()
 var hook_uid:String=beat.get("hook_uid","")
 if not hook_uid.is_empty() and a.has_method("play_fitted_hook") and a.play_fitted_hook(beat.direction,hook_uid):
  beat.hook_origin=battle.pos(battle.units[beat.target])
  return a.attack_contact_delay()
 if _start_melee_special(beat,a,v):return a.attack_contact_delay()
 var bow_uid:String=beat.get("bow_uid","")
 if not bow_uid.is_empty() and a.has_method("shortbow_can_pose") and a.shortbow_can_pose(bow_uid):
  if not (beat.get("bow_hook_aim",false) and v.get_instance_id()==beat.shield_owner and a.has_method("play_bow_hook_special") and a.play_bow_hook_special(beat.direction,bow_uid,BowHookSpecial.AIMED)):
   a.play_attack(beat.direction)
  var draw_time:float=a.attack_contact_delay()
  if draw_time>0.0:beat.drawing_arrow=true
  return draw_time
 var uid:String=beat.get("stock_uid","")
 var flight:=0.0
 if not uid.is_empty() and a.has_method("present_stock_release") and a.layer_signature().get("weapon",{}).get("item","")==uid:
  if a.has_method("finish_reload"):a.finish_reload()
  if a.has_method("finish_fitted_recoil"):a.finish_fitted_recoil()
  # Take the socket from the displayed pose before the actor's recoil starts.
  flight=_start_bolt(a,v)
  a.present_stock_release(uid)
  var definition:String=a.layer_signature().get("weapon",{}).get("definition","")
  if flight>0.0 and StockBolt.DEFINITIONS.has(definition):
   beat.crossbow_release_definition=definition
   CrossbowFoley.play(self,"release")
 a.play_attack(beat.direction)
 if flight>0.0:
  return flight
 var contact:float=a.attack_contact_delay() if a.has_method("attack_contact_delay") else 0.0
 if contact>0.0 and beat.has("melee_uid") and v.get_instance_id()==beat.shield_owner:beat.melee_contact=true
 if beat.has("wall_entry") and v.get_instance_id()==beat.shield_owner:
  if actor_tweens.has(beat.target):actor_tweens[beat.target].kill();actor_tweens.erase(beat.target)
  _enemy_walk_ends.erase(beat.target)
  beat.wall_from=v.position
  contact=contact if contact>0.0 else 0.19
  beat.wall_time=contact
 return contact

func _start_bolt(a:Node3D,v:Node3D) -> float:
 var sprite:Sprite3D=a.get_node_or_null("Illustration/Composite")
 if sprite==null or sprite.texture==null or not sprite.texture.has_meta("stock_bolt_socket"):return 0.0
 if _bolt_material==null:
  var ink:=Image.new()
  if ink.load_png_from_buffer(FileAccess.get_file_as_bytes(StockBolt.FLIGHT))!=OK:return 0.0
  ink.generate_mipmaps()
  # Use the same color/alpha transfer as the fitted illustration. An alpha-
  # scissored standard material changes both the ink color and its fine edges.
  _bolt_material=ShaderMaterial.new()
  _bolt_material.shader=preload("res://sprite_study/color_identity.gdshader")
  # At separation the two transparent draws overlap in screen space. The
  # flying ink draws after the now-empty rail; opaque world depth still wins.
  _bolt_material.render_priority=1
  _bolt_material.set_shader_parameter("source_texture",ImageTexture.create_from_image(ink))
 # Project the exact same sprite-pixel tip and tilt used by the resting ink.
 var basis:=camera.global_basis
 var side:float=-1.0 if sprite.flip_h else 1.0
 var tip:Vector2=sprite.texture.get_meta("stock_bolt_socket")
 var middle:=sprite.texture.get_size()*0.5
 var xy:=sprite.offset+Vector2((tip.x-middle.x)*side,middle.y-tip.y)
 _bolt_origin=sprite.global_position+(basis.x*xy.x+basis.y*xy.y)*sprite.pixel_size
 var angle:=deg_to_rad(StockBolt.RISE)
 _bolt_takeoff=basis.x*(side*cos(angle))+basis.y*sin(angle)
 _bolt_goal=v.global_position+basis.y*1.03
 _bolt_duration=clampf(0.19+0.031*_bolt_origin.distance_to(_bolt_goal),0.25,0.46)
 _bolt_path_fixed=false
 _bolt_mesh=MeshInstance3D.new()
 _bolt_mesh.set_meta("crossbow_bolt",true)
 _bolt_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var cut:=QuadMesh.new()
 var ink_texture:Texture2D=_bolt_material.get_shader_parameter("source_texture")
 var source_size:=ink_texture.get_size()
 var ink_scale:float=StockBolt.WIDTH*sprite.pixel_size/source_size.x
 cut.size=source_size*ink_scale
 var pivot:=StockBolt.SOURCE_PIVOT-source_size*0.5
 cut.center_offset=Vector3(-pivot.x,pivot.y,0.0)*ink_scale
 _bolt_mesh.mesh=cut
 _bolt_mesh.material_override=_bolt_material
 add_child(_bolt_mesh)
 _bolt_mesh.global_transform=Transform3D(Basis(_bolt_takeoff,basis.z.cross(_bolt_takeoff),basis.z),_bolt_origin+basis.z*BOLT_DEPTH_BIAS)
 return _bolt_duration

func _release_arrow(beat:Dictionary) -> float:
 var a:Node3D=actors.get(beat.source);var v:Node3D=actors.get(beat.target)
 if not is_instance_valid(a) or not is_instance_valid(v) or a.get_instance_id()!=beat.owner or v.get_instance_id()!=beat.shield_owner:return 0.0
 if not a.visible or not v.visible or not battle.unit_visible(0,beat.source):return 0.0
 if not battle.unit_visible(0,beat.target) and not _held_casualty(beat.target):return 0.0
 var sprite:Sprite3D=a.shortbow_handoff(beat.bow_uid,false)
 if sprite==null or sprite.texture==null or not sprite.texture.has_meta("shortbow_tip"):return 0.0
 var ink:=Shortbow.flight_texture()
 if ink==null:return 0.0
 var tip:Vector2=sprite.texture.get_meta("shortbow_tip")
 var nock:Vector2=sprite.texture.get_meta("shortbow_nock")
 var tangent:=tip-nock
 if tangent.length_squared()<1.0:return 0.0
 if _arrow_material==null:
  _arrow_material=ShaderMaterial.new()
  _arrow_material.shader=preload("res://sprite_study/color_identity.gdshader")
  _arrow_material.render_priority=1
  _arrow_material.set_shader_parameter("source_texture",ink)
 var basis:=camera.global_basis
 var side:float=-1.0 if sprite.flip_h else 1.0
 var middle:=sprite.texture.get_size()*0.5
 var xy:=sprite.offset+Vector2((tip.x-middle.x)*side,middle.y-tip.y)
 _bolt_origin=sprite.global_position+(basis.x*xy.x+basis.y*xy.y)*sprite.pixel_size
 _bolt_takeoff=(basis.x*(side*tangent.x)-basis.y*tangent.y).normalized()
 # Keep the endpoint over the defender's real tile; camera-up would also
 # shift it along the ground, enough to erase a near miss's overshoot.
 _bolt_goal=v.global_position+Vector3.UP*(1.28 if not beat.get("arrow_head",false) else 1.91)
 _lock_ranged_shield(beat)
 var gap:=_bolt_origin.distance_to(_bolt_goal)
 _bolt_duration=clampf(0.17+0.038*gap,0.28,0.52)
 if beat.get("arrow_miss",false):
  var forward:=v.global_position-a.global_position;forward.y=0.0;forward=forward.normalized()
  # A clean miss clears the silhouette in the camera too, not merely in
  # hex space behind the billboard. Let it carry beyond the target.
  _bolt_goal+=forward*1.43+Vector3.UP*0.98
 _bolt_arc=clampf(0.44+0.12*gap,0.58,1.30)
 _bolt_path_fixed=true
 var cut:=QuadMesh.new()
 var dimensions:=ink.get_size()
 var ink_scale:=tangent.length()*sprite.pixel_size/(Shortbow.TIP.x-Shortbow.NOCK.x)
 cut.size=dimensions*ink_scale
 var pivot:=Shortbow.TIP-dimensions*0.5
 cut.center_offset=Vector3(-pivot.x,pivot.y,0.0)*ink_scale
 _bolt_mesh=MeshInstance3D.new()
 _bolt_mesh.set_meta("shortbow_arrow",true)
 _bolt_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 _bolt_mesh.mesh=cut;_bolt_mesh.material_override=_arrow_material
 a.shortbow_handoff(beat.bow_uid,true)
 add_child(_bolt_mesh)
 _bolt_mesh.global_transform=Transform3D(Basis(_bolt_takeoff,basis.z.cross(_bolt_takeoff),basis.z),_bolt_origin+basis.z*BOLT_DEPTH_BIAS)
 _play_bow_cue("release")
 return _bolt_duration

func _draw_bolt(beat:Dictionary) -> void:
 if not is_instance_valid(_bolt_mesh):return
 if not _bolt_path_fixed:
  # Outcome feedback is already available on the first draw. Lock the
  # art path once; don't track the target or change course on later frames.
  var blocked:=_lock_ranged_shield(beat)
  var miss:bool=not blocked and not beat.has("ranged_shield_condition") and beat.feedback.any(func(e):return e.kind=="miss" and e.get("shield",0)==0)
  if miss:
   var heading:=_bolt_goal-_bolt_origin;heading.y=0.0
   var forward:=heading.normalized()
   _bolt_goal+=forward*0.78+forward.cross(Vector3.UP)*0.57
  _bolt_arc=clampf(0.52+0.16*_bolt_origin.distance_to(_bolt_goal),0.80,1.55)
  _bolt_path_fixed=true
 var t:=clampf(1.0-_contact_left/_bolt_duration,0.0,1.0)
 var along:Vector3=_bolt_goal-_bolt_origin+Vector3.UP*(4.0*_bolt_arc*(1.0-2.0*t))
 var normal:=camera.global_basis.z
 var flat:=along-normal*along.dot(normal)
 var axis:=flat.normalized() if flat.length_squared()>0.000001 else camera.global_basis.x
 var takeoff:=_bolt_takeoff-normal*_bolt_takeoff.dot(normal)
 if takeoff.length_squared()>0.000001:
  # Match the rail on the launch frame, then pitch freely along the lob.
  var seated:=takeoff.normalized()
  axis=seated.rotated(normal,seated.signed_angle_to(axis,normal)*smoothstep(0.0,0.18,t))
 _bolt_mesh.global_transform=Transform3D(Basis(axis,normal.cross(axis),normal),_bolt_origin.lerp(_bolt_goal,t)+Vector3.UP*(4.0*_bolt_arc*t*(1.0-t))+normal*BOLT_DEPTH_BIAS)
 _bolt_mesh.show()

func _retire_bolt() -> void:
 if not is_instance_valid(_bolt_mesh):return
 remove_child(_bolt_mesh);_bolt_mesh.queue_free();_bolt_mesh=null

func _advance_impact(delta:float) -> void:
 if _impact_beats.is_empty():return
 _contact_left=maxf(0.0,_contact_left-delta)
 if not _shield_gap:_approach_spearwall(_impact_beats[0],_contact_left)
 if _contact_left>0.0:
  _draw_bolt(_impact_beats[0])
  return
 if _shield_gap:
  _shield_gap=false
  var followup:=_start_impact_pose(_impact_beats[0])
  if followup>0.0:
   _contact_left=maxf(0.000001,followup-delta)
   return
 var bow_beat:Dictionary=_impact_beats[0]
 if bow_beat.erase("drawing_arrow"):
  var flight:=_release_arrow(bow_beat)
  if flight>0.0:
   _contact_left=flight
   return
 _show_ranged_shield(bow_beat)
 _shortbow_arrival_sound(bow_beat)
 _crossbow_arrival_sound(bow_beat)
 _retire_bolt()
 while not _impact_beats.is_empty():
  var finished:Dictionary=_impact_beats.pop_front()
  _approach_spearwall(finished,0.0)
  _sync_pending_vitals()
  for safe:Dictionary in finished.feedback:
   if safe.get("fallen",false) or battle.unit_visible(0,int(safe.id)):_publish_impact(safe)
  # Replace the generic body nudge on the landed result's display frame.
  _show_fitted_recoil(finished)
  var blocked:=_show_fitted_block(finished)
  _melee_contact_sound(finished,blocked)
  _show_final_fall(finished)
  _begin_hook_drag(finished)
  _repel_spearwall(finished)
  if _impact_beats.is_empty():break
  # The next attack cue captured the public journal through this beat only.
  var events:Array=finished.journal
  log_label.text="\n".join(events.slice(maxi(0,events.size()-2)))
  var next:Dictionary=_impact_beats[0]
  if blocked and next.source==finished.target and next.target==finished.source and next.owner==finished.shield_owner:
   # Both actions have resolved. Hold only the next visual wind-up; the
   # queued counter still owns its unrevealed vitals and journal boundary.
   _shield_gap=true;_contact_left=BLOCK_BEFORE_COUNTER
   return
  var delay:=_start_impact_pose(_impact_beats[0])
  if delay>0.0:
   # The child actor will process this same frame after the field. Debit
   # that first animation step here so its hit lands on its contact pose.
   _contact_left=maxf(0.000001,delay-delta)
   return
 refresh()

# Only visible, mounted contacts use the attempted entry from the real strike.
# This owns no tactical coordinates: the attempted step has already resolved.
func _spearwall_subject(beat:Dictionary,include_fall:bool) -> Node3D:
 if not beat.has("wall_entry"):return null
 var a:Node3D=actors.get(beat.source);var v:Node3D=actors.get(beat.target)
 if not is_instance_valid(a) or not is_instance_valid(v) or a.get_instance_id()!=beat.owner or v.get_instance_id()!=beat.shield_owner:return null
 if not a.visible or not v.visible or not battle.unit_visible(0,beat.source) or not battle.tile_visible(0,beat.wall_entry):return null
 if not battle.unit_visible(0,beat.target) and not (include_fall and _held_casualty(beat.target)):return null
 return v

func _approach_spearwall(beat:Dictionary,remaining:float) -> void:
 if not beat.has("wall_time"):return
 var v:=_spearwall_subject(beat,true)
 if v==null:return
 var t:=clampf(1.0-remaining/float(beat.wall_time),0.0,1.0)
 v.position=beat.wall_from.lerp(tile_world(beat.wall_entry),smoothstep(0.0,1.0,t))

func _repel_spearwall(beat:Dictionary) -> void:
 if not beat.has("wall_time") or not beat.get("recoil",false) or beat.get("fall",false):return
 var v:=_spearwall_subject(beat,false)
 if v==null:return
 var id:int=beat.target
 var cell:Vector2i=battle.pos(battle.units[id])
 if cell!=beat.wall_previous:return
 _hook_drag={"id":id,"instance":beat.shield_owner,"source":beat.source,"owner":beat.owner,"wall":true,"from":v.position,"old_cell":beat.wall_entry,"cell":cell,"dest":tile_world(cell),"elapsed":0.0}

func _begin_hook_drag(beat:Dictionary) -> void:
 if not beat.has("hook_origin") or not beat.get("recoil",false) or beat.get("fall",false):return
 var id:int=beat.target
 var old_cell:Vector2i=beat.hook_origin
 var new_cell:Vector2i=battle.pos(battle.units[id])
 if battle.distance(old_cell,new_cell)!=1 or not battle.living(battle.units[id]):return
 if not battle.unit_visible(0,beat.source) or not battle.unit_visible(0,id) or not battle.tile_visible(0,old_cell):return
 var a:Node3D=actors.get(beat.source);var v:Node3D=actors.get(id)
 if not is_instance_valid(a) or not is_instance_valid(v) or a.get_instance_id()!=beat.owner or v.get_instance_id()!=beat.shield_owner:return
 if not a.visible or not v.visible or a.layer_signature().get("weapon",{}).get("item","")!=beat.get("hook_uid",""):return
 var origin:=tile_world(old_cell)
 if v.position.distance_to(origin)>0.04:return
 if actor_tweens.has(id):actor_tweens[id].kill();actor_tweens.erase(id)
 _enemy_walk_ends.erase(id)
 _hook_drag={"id":id,"instance":beat.shield_owner,"source":beat.source,"owner":beat.owner,"uid":beat.hook_uid,"from":origin,"old_cell":old_cell,"cell":new_cell,"dest":tile_world(new_cell),"elapsed":0.0}

func _advance_hook_drag(delta:float) -> void:
 if _hook_drag.is_empty() or not is_finite(delta):return
 var h:=_hook_drag
 var v:Node3D=actors.get(h.id);var a:Node3D=actors.get(h.source)
 var visible:bool=is_instance_valid(v) and v.get_instance_id()==h.instance and v.visible and battle.unit_visible(0,h.id) and battle.living(battle.units[h.id]) and battle.pos(battle.units[h.id])==h.cell
 var witnessed:bool=is_instance_valid(a) and a.get_instance_id()==h.owner and a.visible and battle.unit_visible(0,h.source) and battle.tile_visible(0,h.old_cell) and (h.get("wall",false) or a.layer_signature().get("weapon",{}).get("item","")==h.uid)
 if not visible or not witnessed:
  _hook_drag={}
  if is_instance_valid(v) and v.get_instance_id()==h.instance:v.position=tile_world(battle.pos(battle.units[h.id]))
  refresh();return
 h.elapsed+=maxf(0.0,delta)
 var t:=clampf(float(h.elapsed)/0.19 if h.get("wall",false) else (float(h.elapsed)-HookArt.DRAG_DELAY)/HookArt.DRAG_DURATION,0.0,1.0)
 if t>=1.0:
  v.position=h.dest;_hook_drag={};refresh();return
 # Quick catch, then a fast skid and a damped stop at the real destination.
 var progress:=t*t*(3.0-2.0*t)
 v.position=h.from.lerp(h.dest,progress)

func refresh() -> void:
 if not built or _hold_impact_refresh():return
 _advance_corpses(0.0)
 if terrain!=null and terrain.has_method("refresh_terrain_work"):terrain.refresh_terrain_work(battle)
 if terrain!=null and battle.visibility_enabled:
  if fog==null:
   fog=load("res://map_visibility/fog.gd").new();fog.configure(battle,terrain)
  else:fog.update()
 controller.sanitize_target()
 if battle.active_id!=_camera_active:
  _camera_active=battle.active_id
  if _camera_active>=0 and battle.units[_camera_active].side==0:
   # Activation owns selection/targeting, never the user's view. Initial
   # framing is established by setup(); Home and Overview remain explicit.
   controller.selected=_camera_active;controller.reset_action()
 revision+=1
 for u in battle.units:
  var id: int=u.id
  if not actors.has(id):
   _enemy_walk_ends.erase(id)
   continue
  var actor: Node3D=actors[id]
  var shown: bool=battle.living(u) and battle.unit_visible(0,id)
  actor.visible=shown
  var destination := tile_world(battle.pos(u))
  var bind_enemy_walk: bool=u.side!=0 and actor.has_method("follow_enemy_walk")
  var next_walk: Tween
  if not shown or not _presented.get(id,false):
   if actor_tweens.has(id):actor_tweens[id].kill();actor_tweens.erase(id)
   _enemy_walk_ends.erase(id)
   actor.position=destination
  elif actor.position.distance_to(destination)>0.01 and not (_hook_drag.get("id",-1)==id and _hook_drag.get("instance",0)==actor.get_instance_id() and _hook_drag.get("cell")==battle.pos(u)):
   # A redraw is not another move. Bind hostile art to the existing public
   # endpoint tween; never consume the Battle's private enemy path or serial.
   var held: bool=bind_enemy_walk and _enemy_walk_ends.get(id)==destination and actor_tweens.has(id) and actor_tweens[id].is_running()
   if not held:
    if actor_tweens.has(id):actor_tweens[id].kill();actor_tweens.erase(id)
    var tween := create_tween()
    tween.tween_property(actor,"position",destination,0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    actor_tweens[id]=tween
    if bind_enemy_walk:
     _enemy_walk_ends[id]=destination
     next_walk=tween
  if shown:actor.refresh(u,battle.armor_catalog);actor.set_selected(id==controller.selected)
  if next_walk!=null:actor.follow_enemy_walk(next_walk)
  _presented[id]=shown
 _rebuild_board_markers()
 for child in get_children():
  if child is Label3D and child.has_meta("public_actor_id") and not child.get_meta("public_last_hit",false) and not battle.unit_visible(0,int(child.get_meta("public_actor_id"))):child.hide();child.queue_free()
 if fog!=null:fog.sync_shadows()
 _update_hud()

func _set_obstacles_hidden(value:bool) -> void:
 if not built or terrain==null or obstacles_hidden==value:return
 obstacles_hidden=value
 if obstacles_hidden:
  # Fog owns each prop root. Hide only its render meshes (and their shadow
  # children), so fog updates can still change the root independently.
  for object:Dictionary in terrain.occluders:
   for mesh:MeshInstance3D in object.meshes:
    if mesh.visible:
     _hidden_obstacle_meshes.append(mesh);mesh.hide()
 else:
  for mesh in _hidden_obstacle_meshes:
   if is_instance_valid(mesh):mesh.show()
  _hidden_obstacle_meshes.clear()
 _rebuild_board_markers()

func _rebuild_board_markers() -> void:
 _line_vertices.clear();_line_colors.clear();_fill_vertices.clear();_fill_colors.clear()
 var reachable: Dictionary=battle.movement_map(controller.selected) if controller.selected>=0 else {}
 var obstacles:Dictionary={}
 if obstacles_hidden and terrain!=null:
  for object:Dictionary in terrain.occluders:obstacles[object.tile]=true
 for k: String in battle.tiles:
  var bits := k.split(",")
  var cell := Vector2i(int(bits[0]),int(bits[1]))
  if not battle.tile_visible(0,cell):continue
  if obstacles.has(k):
   # Keep the blocked footprint legible even with the optional grid off.
   _append_hex_marker(cell,float(battle.tiles[k].height),Color(0.94,0.20,0.16,0.94),0.44,0.93)
   continue
  var color := Color(0.85,0.79,0.60,0.12)
  var fill := false
  if reachable.has(k):color=Color(0.28,0.69,0.86,0.58);fill=true
  var occupant: int=battle.at(cell)
  # Gold belongs to the scheduler's current living companion, never inspection
  # or enemy activity (even when that enemy is public). Tile sight is gated above.
  if occupant>=0 and occupant==battle.active_id and battle.side==0 and battle.result.is_empty() and battle.units[occupant].side==0 and battle.living(battle.units[occupant]) and battle.unit_visible(0,occupant):
   _active_turn_marker(cell);continue
  if occupant>=0 and battle.unit_visible(0,occupant):
   if controller.selected>=0 and battle.can_attack(controller.selected,occupant):color=Color(0.90,0.31,0.23,0.75);fill=true
   if occupant==controller.selected:color=Color(0.55,0.91,1.0,1.0);fill=true
   if occupant==controller.target:color=Color(1.0,0.45,0.25,1.0);fill=true
  if show_grid or fill:_hex_marker(cell,color,fill)
 if controller.action in ["footwork","rotation"] and battle.tile_visible(0,controller.target_hex):_hex_marker(controller.target_hex,Color(0.95,0.72,0.2,0.5),false)
 _finish_markers()

func _hex_marker(cell: Vector2i,color: Color,fill: bool) -> void:
 if not battle.tile_visible(0,cell):return
 var tile: Dictionary=battle.tiles[battle.key(cell)]
 if not TerrainRules.tile_reason(tile).is_empty():color=Color(0.69,0.39,0.28,0.23)
 color=color.lerp(Color("a4b8af"),0.20)
 if not fill and tile.get("blocked",false)==false and color.a<0.4:color=Color(0.22,0.26,0.19,0.52)
 elif color.a<0.5:color.a*=0.5
 _append_hex_marker(cell,float(tile.height),color,color.a*0.17 if fill else 0.0)

func _append_hex_marker(cell:Vector2i,height:float,color:Color,fill_opacity:float,radius:float=1.0) -> void:
 var corners := Layout.corners(cell,height,radius) # Default: native Voronoi edge shared with the ground ray.
 for i in 6:
  _line_vertices.append(corners[i]+Vector3.UP*0.035);_line_colors.append(color)
  _line_vertices.append(corners[(i+1)%6]+Vector3.UP*0.035);_line_colors.append(color)
  if fill_opacity>0.0:
   for vertex in [tile_world(cell),corners[i],corners[(i+1)%6]]:
    _fill_vertices.append(vertex+Vector3.UP*0.028);_fill_colors.append(Color(color,fill_opacity))

func _active_turn_marker(cell: Vector2i) -> void:
 # Ground-space triangles, not driver-dependent GL line widths. The dark
 # outer keyline survives pale stone; the amber band survives deep shadow.
 # Keep the existing one-node, shared-material, depth-tested cue batch.
 var height := float(battle.tiles[battle.key(cell)].height)
 var center := tile_world(cell)+Vector3.UP*0.05
 var inner := Layout.corners(cell,height,0.76)
 var band := Layout.corners(cell,height,0.92)
 var outer := Layout.corners(cell,height,0.98)
 for i in 6:
  var next := (i+1)%6
  for vertex in [center,inner[i]+Vector3.UP*0.05,inner[next]+Vector3.UP*0.05]:
   _fill_vertices.append(vertex);_fill_colors.append(Color(0.98,0.64,0.10,0.43))
  for ring in [[inner,band,Color(1.0,0.74,0.15,0.98)],[band,outer,Color(0.075,0.045,0.018,0.96)]]:
   for vertex in [ring[0][i],ring[1][i],ring[1][next],ring[0][i],ring[1][next],ring[0][next]]:
    _fill_vertices.append(vertex+Vector3.UP*0.05);_fill_colors.append(ring[2])

func _finish_markers() -> void:
 var stamp := hash([_line_vertices,_line_colors,_fill_vertices,_fill_colors])
 if is_instance_valid(_marker_instance) and stamp==_marker_stamp:return
 if not is_instance_valid(_marker_instance):
  _marker_mesh=ImmediateMesh.new();_marker_material=StandardMaterial3D.new()
  _marker_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  _marker_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  _marker_material.vertex_color_use_as_albedo=true;_marker_material.cull_mode=BaseMaterial3D.CULL_DISABLED
  _marker_material.no_depth_test=false
  _marker_instance=MeshInstance3D.new();_marker_instance.name="BatchedPublicCues";_marker_instance.mesh=_marker_mesh
  _marker_instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;markers.add_child(_marker_instance)
 _marker_mesh.clear_surfaces()
 for data in [[_line_vertices,_line_colors,Mesh.PRIMITIVE_LINES],[_fill_vertices,_fill_colors,Mesh.PRIMITIVE_TRIANGLES]]:
  if data[0].is_empty():continue
  _marker_mesh.surface_begin(data[2],_marker_material)
  for i in data[0].size():_marker_mesh.surface_set_color(data[1][i]);_marker_mesh.surface_add_vertex(data[0][i])
  _marker_mesh.surface_end()
 _marker_stamp=stamp;marker_builds+=1

func presented_unit_ids() -> Array:
 var ids: Array=[]
 for u in battle.units:
  if battle.living(u) and battle.unit_visible(0,int(u.id)):ids.append(int(u.id))
 return ids

func presented_feet() -> Array:
 var feet: Array=[]
 for id in presented_unit_ids():
  feet.append(actors[id].global_position if actors.has(id) else to_global(tile_world(battle.pos(battle.units[id]))))
 return feet

func _process(delta: float) -> void:
 if not built:return
 _advance_corpses(delta)
 _advance_shield_impacts(delta)
 _advance_hook_drag(delta)
 _advance_impact(delta)
 var paused: bool=inspector_open() or (is_instance_valid(retreat_confirm) and retreat_confirm.visible)
 if not paused:
  var direction := Vector2.ZERO
  if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):direction.x-=1
  if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):direction.x+=1
  if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):direction.y-=1
  if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):direction.y+=1
  if direction!=Vector2.ZERO and not help_open:pan_camera(direction.normalized()*delta*camera.size*0.45)
  if battle.auto_step_needed() and not help_open and not impact_pending():
   ai_time+=delta
   if ai_time>=0.72:ai_time=0;controller.enemy_step()
 if terrain!=null:terrain.update_occlusion(camera,presented_feet())
 if fog!=null:fog.sync_shadows()
 if units_overlay!=null:units_overlay.queue_redraw()
 observe_time+=delta
 if observe_enabled and observe_time>=0.25:observe_time=0;_write_observation()

func _draw_unit_labels() -> void:
 var shown:=presented_unit_ids()
 for id in _pending_vitals:
  if id not in shown and _held_casualty(id):shown.append(id)
 for id in shown:
  for row in _unit_vital_rows(id):
   units_overlay.draw_rect(row.track.grow(0.5),Color("13120f"))
   units_overlay.draw_rect(row.track,Color("48433b"))
   if row.fill.has_area():units_overlay.draw_rect(row.fill,row.tint)

func _unit_vital_rows(id: int) -> Array[Dictionary]:
 var actor:Node3D=actors.get(id)
 if not is_instance_valid(actor) or not actor.is_visible_in_tree():return []
 if not battle.unit_visible(0,id) and not _held_casualty(id):return []
 var u:Dictionary=_display_hit_vitals(id)
 var origin:=unit_label_point(actor.global_position).round()+Vector2(-21,-7)
 var rows:Array[Dictionary]=[]
 # Always head, pooled body (including padding), then health. The same palette
 # and empty tracks apply to both sides; allegiance is carried by the field.
 for vital in [[u.helmet,u.max_helmet,Color("b5d4e5")],
   [u.armor+u.padding,u.max_armor+u.max_padding,Color("d7b97b")],
   [u.hp,u.max_hp,Color("df6458")]]:
  var track:=Rect2(origin+Vector2(0,rows.size()*5),Vector2(42,4))
  var fill:=track
  fill.size.x*=clampf(float(vital[0])/float(vital[1]),0.0,1.0) if vital[1]>0 else 0.0
  rows.append({"track":track,"fill":fill,"tint":vital[2]})
 return rows

func pick_unit(screen: Vector2) -> int:
 var id: int=super.pick_unit(screen)
 return id if battle.unit_visible(0,id) else -1

func _update_hud() -> void:
 # Do not call the inherited raw-log/active-enemy-name/true-target HUD chain.
 controller.sanitize_target()
 if not battle.result.is_empty():status_label.text="BATTLE %s · Round %d"%[battle.result.to_upper(),battle.round_no]
 elif battle.side==1:status_label.text="Round %d · ENEMY ACTING"%battle.round_no
 else:
  var name: String=battle.units[battle.active_id].name if battle.active_id>=0 else "—"
  status_label.text="Round %d · YOUR ACTIVE BRO: %s"%[battle.round_no,name]
 if kit_label:kit_label.text="%s · PARTY SIGHT · BB2 policy"%session.deployed_map.get("title","")
 for id in roster_buttons:
  roster_buttons[id].modulate=Color("a2e7ed") if id==controller.selected else Color.WHITE
  roster_buttons[id].disabled=not battle.living(battle.units[id])
 notice_label.text=controller.notice
 var events: Array=battle.public_events(0)
 log_label.text="\n".join(events.slice(maxi(0,events.size()-2)))
 action_buttons.end.text="End activation [F]"
 action_buttons.end.disabled=battle.side!=0 or not battle.result.is_empty()
 if action_buttons.has("retreat"):action_buttons.retreat.disabled=not battle.result.is_empty()
 var id: int=controller.selected
 if id<0 or id>=battle.units.size() or battle.units[id].side!=0:return
 var u: Dictionary=battle.units[id]
 var active: bool=battle.can_act(id) and battle.side==0 and battle.fighting(u)
 unit_label.text="%s · %s\nHP %d/%d · AP %d · Initiative %d\nArmor %d · Head %d\nFatigue %d/%d · Morale %s\n%s"%[u.name,String(u.weapon).capitalize(),u.hp,u.max_hp,u.ap,battle.initiative_value(u),u.armor+u.padding,u.helmet,u.fatigue,battle.fatigue_max(u),preload("res://morale_flags/readout.gd").current_name(battle,id),"Shieldwall" if u.guard else u.get("stance","")]
 carry_choice.clear()
 var selected_index=0
 for slot in battle.Arsenal.bag_slots(u):
  var item: Dictionary=u.arms.get(slot,{})
  var index=carry_choice.item_count
  carry_choice.add_item("%s: %s"%[slot,String(item.get("definition","empty")).capitalize()]);carry_choice.set_item_metadata(index,slot)
  if slot==controller.carry_slot:selected_index=index
 if carry_choice.item_count>0:carry_choice.select(selected_index);controller.carry_slot=carry_choice.get_item_metadata(selected_index)
 for action in ["guard","recover","wait","switch","indomitable"]:
  var q: Dictionary=battle.action_quote(id,action,-1,Vector2i(-1,-1),controller.carry_slot)
  action_buttons[action].text="%s · %d AP"%[q.name,q.ap] if q.ap>0 else q.name
  action_buttons[action].disabled=not active or not q.legal
  action_buttons[action].tooltip_text=q.reason if not q.legal else "%d AP / %d fatigue"%[q.ap,q.fatigue]
 for action in ["basic","special","footwork","rotation"]:
  action_buttons[action].disabled=not active or (action in ["footwork","rotation"] and not action in u.perks)
  action_buttons[action].modulate=Color("eac783") if controller.action==action else Color.WHITE
  action_buttons[action].tooltip_text="Select a target, then Execute." if not action_buttons[action].disabled else "Not available to this active brother."
 action_buttons.basic.text=battle.Arsenal.primary(u.weapon)+" [1]"
 action_buttons.special.text=battle.special_info(u.weapon).name+" [2]"
 _last_quote=controller.quote()
 action_buttons.attack.text="Execute %s"%_last_quote.name
 action_buttons.attack.disabled=not active or not _last_quote.legal
 target_label.text=_quote_text(_last_quote)
 action_buttons.attack.tooltip_text=target_label.text+"\nParty sight is not personal attack sight. Forecasts require known influencing ground."

func _quote_text(q: Dictionary) -> String:
 var text: String=super._quote_text(q)
 var reason: String=q.get("preview_reason","")
 return text+("\n"+reason if not reason.is_empty() else "")

func _update_hover() -> void:
 if not battle.tiles.has(battle.key(hover)):hover_text=""
 elif not battle.tile_explored(0,hover):hover_text="Unexplored terrain."
 elif not battle.tile_visible(0,hover):
  var tile: Dictionary=battle.tiles[battle.key(hover)]
  hover_text="Remembered %s · elevation %d"%[String(tile.terrain).capitalize(),tile.height]
 else:
  super._update_hover()
  return
 if notice_label:notice_label.text=hover_text

func _feedback(event: Dictionary) -> void:
 var id: int=int(event.get("id",-1))
 if event.get("kind","")=="attack":
  _instant_strike={}
  _recoil_beat={}
  var actor_id: int=int(event.get("actor",-1))
  var beat:Dictionary={"source":actor_id,"target":id,"owner":0,"direction":Vector3.ZERO,"vitals":{},"feedback":[],"journal":[]}
  if battle.unit_visible(0,actor_id) and battle.unit_visible(0,id) and actors.has(actor_id) and actors.has(id):
   var attacker: Node3D=actors[actor_id]
   if attacker.visible and actors[id].visible and attacker.has_method("play_attack"):
    beat.owner=attacker.get_instance_id()
    var defender:Node3D=actors[id]
    beat.shield_owner=defender.get_instance_id()
    if event.has("wall_entry") and battle.tile_visible(0,event.wall_previous) and battle.tile_visible(0,event.wall_entry):
     beat.wall_entry=event.wall_entry
     beat.wall_previous=event.wall_previous
    var shield:Dictionary=defender.layer_signature().get("shield",{})
    if shield.get("visible",false):beat.shield_uid=String(shield.get("item",""))
    beat.direction=actors[id].global_position-attacker.global_position
    var firing:Dictionary=battle.units[actor_id]
    var weapon:Dictionary=attacker.layer_signature().get("weapon",{})
    var equipped:Dictionary=firing.get("arms",{}).get("weapon",{})
    var uid:String=equipped.get("id","")
    if battle.weapon_rules and event.get("special",false)==true and MeleeSpecial.fits_item(firing,{"weapon":weapon},uid):
     var kind:String=MeleeSpecial.FAMILY.get(MeleeArsenal.family(firing.weapon),"")
     if not kind.is_empty():beat.melee_special_kind=kind;beat.melee_special_uid=uid
    if StockBolt.DEFINITIONS.has(firing.weapon) and not equipped.get("loaded",true) and weapon.get("visible",false) and weapon.get("definition","")==equipped.get("definition","none") and weapon.get("item","")==uid:
     beat.stock_uid=uid
    var bow_def:String=equipped.get("definition","")
    if event.get("special",false)==true and bow_def==BowHookSpecial.FERRY_DEF and BowHookSpecial.matches(BowHookSpecial.FERRY,weapon,equipped,uid):
     var origin:Vector2i=battle.pos(battle.units[id])
     if battle.distance(battle.pos(firing),origin)==2 and battle.tile_visible(0,origin):
      beat.ferryman_uid=uid;beat.ferryman_origin=origin
    if event.get("special",false)==true and bow_def==HookArt.DEF and weapon.get("definition","")==bow_def and weapon.get("visible",false) and weapon.get("item","")==uid and not uid.is_empty():beat.hook_uid=uid
    if bow_def in FITTED_BOW_DEFINITIONS and weapon.get("visible",false) and weapon.get("item","")==uid and (bow_def==Shortbow.DEFINITION or (attacker.has_method("shortbow_can_pose") and attacker.shortbow_can_pose(uid))):
     beat.bow_uid=uid
     if event.get("special",false)==true:beat.bow_hook_aim=true
    if not str(firing.weapon).is_empty() and not bool(battle.weapon_stats(firing).get("ranged",false)):
     beat.melee_body_weapon=firing.weapon
     beat.melee_body_uid=uid
     beat.melee_body_definition=equipped.get("definition","")
    if not uid.is_empty() and MeleeArsenal.family(firing.weapon) in ["sword","spear"] and weapon.get("visible",false) and weapon.get("item","")==uid and weapon.get("definition","")==equipped.get("definition",""):
     beat.melee_uid=uid
    # Copy only the fields read by the on-board vitals painter.
    var u:Dictionary=battle.units[id]
    beat.vitals={"hp":u.hp,"max_hp":u.max_hp,"helmet":u.helmet,"max_helmet":u.max_helmet,"armor":u.armor,"max_armor":u.max_armor,"padding":u.padding,"max_padding":u.max_padding,"side":u.side,"name":u.name}
  if not _impact_beats.is_empty():
   if _impact_beats.size()<MAX_IMPACT_BEATS:
    _impact_beats.back().journal=battle.public_events(0).duplicate()
    _impact_beats.append(beat)
    if beat.owner!=0:_recoil_beat=beat
    _sync_pending_vitals()
  elif beat.owner!=0:
   _contact_left=_start_impact_pose(beat)
   if _contact_left>0.0:
    _impact_beats.append(beat)
    _sync_pending_vitals()
   else:_instant_strike=beat
   _recoil_beat=beat
  return
 var viewers: Array=event.get("strike_viewers",[])
 var kind: String=event.get("kind","")
 var outcome:bool=event.has("strike_viewers") and kind in ["miss","hit","shield"]
 var received:Dictionary={}
 if outcome:
  received=_recoil_beat
  _recoil_beat={}
 var witnessed: bool=viewers.any(func(viewer):return viewer.team==0)
 if not witnessed and (event.has("strike_viewers") or not battle.unit_visible(0,id)):return
 var disclosed: bool=witnessed and viewers.any(func(viewer):return viewer.team==0 and viewer.safe)
 if witnessed and kind=="miss" and received.get("target",-1)==id:
  var lost:int=int(event.get("shield",0))
  if lost==0 and received.has("stock_uid"):received.crossbow_clean_miss=true
  if received.has("melee_uid"):
   received.melee_clean_miss=lost==0
   received.melee_shield_loss=lost>0
  if received.has("bow_uid"):
   received.arrow_miss=lost==0
   if lost==0:received.shortbow_cue="pass"
  if lost>0 and (received.has("bow_uid") or received.has("stock_uid")):
   var shield:Dictionary=battle.units[id].get("arms",{}).get("shield",{})
   var uid:String=received.get("shield_uid","")
   if not uid.is_empty() and uid==shield.get("id",""):
    # The preceding legacy BLOCK popup is not an outcome receipt. Bind
    # precisely the consumed strike and keep numeric HUD disclosure separate.
    received.ranged_shield_condition=int(shield.get("condition",0))
    received.shield_condition=received.ranged_shield_condition
    if received.has("bow_uid"):received.shortbow_cue="break" if received.ranged_shield_condition==0 else "block"
 if witnessed and kind=="hit" and not received.is_empty() and received.target==id:
  # Art admission is independent of whether damage numbers may be shown.
  received.recoil=true
  if received.has("bow_uid"):received.shortbow_cue="body"
  if disclosed and received.has("bow_uid"):received.arrow_head=bool(event.get("head",false))
  received.fall=int(battle.units[id].hp)<=0
 var safe := {"id":id,"kind":kind,"text":{"hit":"HIT","miss":"MISS","shield":"SHIELD HIT","stagger":"STAGGER","stun":"STUNNED","death":"FALLEN","morale":"MORALE","route":"ROUTING"}.get(kind,"")}
 if kind=="hit" and disclosed:
  safe["hp"]=int(event.hp);safe["armor"]=int(event.armor)+int(event.get("padding",0));safe["layer"]=String(event.layer)
  safe.text="-%d ARMOUR / -%d HP%s"%[safe.armor,safe.hp," · HEAD" if event.get("head",false) else ""]
 if kind=="shield" and disclosed:
  safe["shield"]=int(event.shield);safe.text="-%d SHIELD"%safe.shield
 if kind=="miss" and disclosed and int(event.get("shield",0))>0:
  safe["shield"]=int(event.shield);safe.text="MISS · -%d SHIELD"%safe.shield
 if kind=="miss" and received.has("ranged_shield_condition"):
  # The legacy bare shield notice precedes this same strike's resolved miss.
  # Draw one shield result instead of stacking two labels at the same point.
  received.feedback=received.feedback.filter(func(row):return row.id!=id or row.kind!="shield" or row.has("shield"))
  safe.text="SHIELD BROKEN" if received.ranged_shield_condition==0 else "BLOCK"
  if disclosed:safe.text+=" · -%d SHIELD"%safe.shield
 if witnessed and kind=="hit" and not battle.living(battle.units[id]):safe["fallen"]=true
 if safe.text.is_empty():return
 # A bare legacy popup is still published, but cannot start fitted art.
 var strike:Dictionary=_impact_beats.back() if not _impact_beats.is_empty() else _instant_strike
 if disclosed and int(safe.get("shield",0))>0 and not strike.is_empty() and strike.target==id and not strike.has("bow_uid") and not strike.has("stock_uid"):
  var item:Dictionary=battle.units[id].get("arms",{}).get("shield",{})
  if strike.get("shield_uid","")==item.get("id",""):
   strike.shield_condition=int(item.get("condition",0))
 if not _impact_beats.is_empty():
  _impact_beats.back().feedback.append(safe)
  return
 _publish_impact(safe)
 if outcome:
  _instant_strike={}
  _show_fitted_recoil(received)
  _melee_contact_sound(received,false)
  _show_final_fall(received)
  _show_fitted_block(strike)

func _show_final_fall(beat:Dictionary) -> void:
 if not beat.get("fall",false) or not is_instance_valid(camera):return
 var id:int=beat.target
 if _corpses.has(id):return
 var unit:Dictionary=battle.units[id]
 var cell:Vector2i=battle.pos(unit)
 if battle.living(unit) or not battle.tile_visible(0,cell) or not battle.unit_visible(0,beat.source):return
 var src:Node3D=actors.get(beat.source);var dst:Node3D=actors.get(id)
 if not is_instance_valid(src) or not is_instance_valid(dst) or src.get_instance_id()!=beat.owner or dst.get_instance_id()!=beat.shield_owner:return
 if not src.is_visible_in_tree() or not dst.is_visible_in_tree():return
 var sprite:=dst.get_node_or_null("Illustration/Composite") as Sprite3D
 if sprite==null or not sprite.visible or sprite.texture==null or not sprite.material_override is ShaderMaterial:return
 var installed:ShaderMaterial=sprite.material_override
 if installed.get_shader_parameter("source_texture")!=sprite.texture:return
 if unit.get("faction","")=="undead" or not str(unit.get("undead_kind","")).is_empty():
  _show_undead_fall(dst,sprite,id,cell)
  return
 # The approved in-hex collapse consumes the mounted composite directly,
 # preserving its actual Layer Forge layers and mirror at witnessed contact.
 var fall:=FallPlane.new()
 fall.set_meta("fall_actor",id);fall.set_meta("fall_cell",cell)
 var ring:=PackedVector3Array()
 for corner:Vector3 in Layout.corners(cell,float(battle.tiles[battle.key(cell)].height),0.91):ring.append(to_global(corner))
 add_child(fall);fall.start(sprite,camera,beat.direction,to_global(tile_world(cell)),ring)
 _corpses[id]=fall
 dst.hide()

func _show_undead_fall(dst:Node3D,sprite:Sprite3D,id:int,cell:Vector2i) -> void:
 if not dst.has_method("undead_collapse_frames"):return
 var center:=tile_world(cell)
 var ring:PackedVector3Array=Layout.corners(cell,float(battle.tiles[battle.key(cell)].height),0.91)
 var radius:=INF
 for i in ring.size():
  var mid:Vector3=(ring[i]+ring[(i+1)%ring.size()])*0.5-center
  radius=minf(radius,Vector2(mid.x,mid.z).length())
 var fall:=UndeadFall.new()
 if not fall.start(sprite,dst.undead_collapse_frames(),radius):fall.free();return
 fall.position=center;fall.set_meta("undead_fall_actor",id);fall.set_meta("fall_cell",cell)
 add_child(fall);_corpses[id]=fall;dst.hide()

func _fall_duration(fall:Node3D) -> float:
 if fall is FallPlane:return FallPlane.RETIRE
 return UndeadFall.RETIRE

func _advance_corpses(delta:float) -> void:
 for fall in _corpses.values():
  # Fog only masks the already-witnessed body. It is not removed/recreated,
  # and if the fall finishes unseen we still restore its settled pose.
  fall.visible=battle.tile_visible(0,fall.get_meta("fall_cell"))
  var remaining:=_fall_duration(fall)-float(fall.age)
  var step:=minf(delta,remaining)
  if step<=0.0:continue
  if fall is FallPlane:fall.advance(step,camera)
  else:fall.advance(step)

func _show_fitted_recoil(beat:Dictionary) -> void:
 if not beat.get("recoil",false):return
 if not battle.living(battle.units[beat.target]) or not battle.unit_visible(0,beat.target) or not battle.unit_visible(0,beat.source):return
 var src:Node3D=actors.get(beat.source);var dst:Node3D=actors.get(beat.target)
 if not is_instance_valid(src) or not is_instance_valid(dst) or src.get_instance_id()!=beat.owner or dst.get_instance_id()!=beat.shield_owner:return
 if src.visible and dst.visible and dst.has_method("play_fitted_recoil"):dst.play_fitted_recoil(beat.direction)

func _show_fitted_block(beat:Dictionary) -> bool:
 if not beat.has("shield_condition") or String(beat.get("shield_uid","")).is_empty():return false
 if not battle.unit_visible(0,beat.source) or not battle.unit_visible(0,beat.target):return false
 var src:Node3D=actors.get(beat.source);var dst:Node3D=actors.get(beat.target)
 if not is_instance_valid(src) or not is_instance_valid(dst) or src.get_instance_id()!=beat.owner or dst.get_instance_id()!=beat.shield_owner:return false
 if not dst.has_method("play_shield_contact"):return false
 if beat.has("ranged_shield_aim"):return dst.play_shield_contact(beat.shield_uid,beat.shield_condition,true)
 return dst.play_shield_contact(beat.shield_uid,beat.shield_condition)

func _publish_impact(safe:Dictionary) -> void:
 var id:int=safe.id
 var prior := get_children()
 super._feedback(safe)
 for child in get_children():
  if child is Label3D and not child in prior:
   child.set_meta("public_actor_id",id);child.set_meta("public_last_hit",safe.get("fallen",false))
 if feedback_events.size()>128:feedback_events.pop_front()

func _movement_click_targets(options: Dictionary) -> Dictionary:
 # Passive geometry only. A tile's centre can be covered by a neighbouring
 # actor, so offer a currently exposed point rather than bypassing picking.
 var poses: Array=[]
 for id in presented_unit_ids():
  if actors.has(id):poses.append([id,actors[id].global_transform])
 var stamp := hash([camera.global_transform,camera.size,get_viewport().get_visible_rect().size,poses,options.keys()])
 if stamp==_ground_stamp:return _ground_targets.duplicate(true)
 _ground_stamp=stamp;_ground_targets.clear()
 for key: String in options:
  var bits := key.split(",");var cell := Vector2i(int(bits[0]),int(bits[1]))
  var points: Array=[tile_world(cell)]
  for corner in Layout.corners(cell,float(battle.tiles[key].height),0.7):points.append(corner)
  for point: Vector3 in points:
   var screen := camera.unproject_position(to_global(point))
   if get_viewport().get_visible_rect().has_point(screen) and pick_unit(screen)<0 and pick_hex(screen)==cell:
    _ground_targets[key]=[screen.x,screen.y];break
 return _ground_targets.duplicate(true)

func observation() -> Dictionary:
 # Construct the public projection directly: inherited intermediate observers
 # enumerate true units, logs, terrain and reasons before returning.
 controller.sanitize_target()
 var size := get_viewport().get_visible_rect().size
 var transform := get_viewport().get_final_transform()
 var active: int=battle.active_id if battle.unit_visible(0,battle.active_id) else -1
 var quote: Dictionary=controller.quote()
 var out := {"map_visibility":true,"combat_pass":true,"individual":battle.individual,"revision":revision,"input_events":input_events,"side":battle.side,"round":battle.round_no,"result":battle.result,"selected":controller.selected,"target":controller.target,"active_id":active,"initiative":battle.upcoming().filter(func(id):return battle.unit_visible(0,id)),"commands":[],"feedback":feedback_events.filter(func(event):return event.get("fallen",false) or battle.unit_visible(0,int(event.id))).duplicate(true),"camera_size":camera.size,"camera_position":[camera.position.x,camera.position.y,camera.position.z],"camera_focus":[camera_focus.x,camera_focus.y,camera_focus.z],"viewport":[size.x,size.y],"screen_transform":[transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y],"board_size":[battle.width(),battle.height()],"units":[],"hexes":{},"buttons":{},"action_controls":{},"hover":hover_text,"action":controller.action,"action_quote":quote,"can_attack":quote.legal and controller.target>=0,"animating":actor_tweens.values().any(func(t):return t.is_running()),"hud_visible":hud.visible,"tile_profiles":{},"movement_options":{},"attack_reasons":{},"fog":{"visible_tiles":[],"explored_tiles":[]},"events":battle.public_events(0),"selected_map_id":session.selected_map_id,"deployed_map_id":session.deployed_map.get("id",""),"map_title":session.deployed_map.get("title",""),"terrain_rules_enabled":battle.terrain_rules_enabled,"terrain_profile":"BB2 explicit terrain-only hard-blocker day radius 7; immediate refog; shared party view / personal attacks; not exact vanilla LOS"}
 for u in battle.units:
  if not battle.unit_visible(0,int(u.id)):continue
  var foot: Vector3=actors[int(u.id)].global_position if actors.has(int(u.id)) else to_global(tile_world(battle.pos(u)))
  var p := camera.unproject_position(foot+camera.global_basis.y)
  var head := camera.unproject_position(foot+camera.global_basis.y*1.8)
  var state: Dictionary=u.get("perk_state",{})
  out.units.append({"id":u.id,"side":u.side,"name":u.name,"q":u.q,"r":u.r,"hp":u.hp,"ap":u.ap,"armor":u.armor,"helmet":u.helmet,"living":battle.living(u),"fatigue":u.fatigue,"fatigue_max":battle.fatigue_max(u),"company_id":u.get("company_id",-1),"activation_origin":[state.get("origin_q",-1),state.get("origin_r",-1)],"screen":[p.x,p.y],"head_screen":[head.x,head.y],"layers":actors[int(u.id)].layer_signature() if actors.has(int(u.id)) else {}})
 for key: String in battle.tiles:
  var bits := key.split(",");var cell := Vector2i(int(bits[0]),int(bits[1]))
  if battle.tile_visible(0,cell):out.fog.visible_tiles.append(key)
  if not battle.tile_explored(0,cell):continue
  out.fog.explored_tiles.append(key)
  var p := camera.unproject_position(tile_world(cell));out.hexes[key]=[p.x,p.y]
  var tile: Dictionary=battle.tiles[key].duplicate(true)
  tile.obstacle=tile.get("obstacle","");tile.blocked=tile.get("blocked",false);tile.vision_blocking=tile.get("vision_blocking",false);tile.cover=tile.get("cover",false)
  var base: Array=TerrainRules.COSTS.get(tile.terrain,[999,999])
  tile.profile={"ap":base[0],"fatigue":base[1],"reason":TerrainRules.tile_reason(tile)}
  out.tile_profiles[key]=tile
 out.fog.visible_tiles.sort();out.fog.explored_tiles.sort()
 if controller.selected>=0:
  var options: Dictionary=battle.movement_map(controller.selected)
  for key in options:
   var move: Dictionary=options[key]
   if not move.path.all(func(cell):return battle.tile_visible(0,cell)):continue
   out.movement_options[key]={"ap":move.cost,"fatigue":move.fatigue,"path":move.path.map(func(cell):return [cell.x,cell.y])}
  for id in battle.known_enemy_ids(0):out.attack_reasons[str(id)]="" if battle.can_attack(controller.selected,id) else "No legal attack from this position."
 out["ground_targets"]=_movement_click_targets(out.movement_options)
 for key in action_buttons:
  var button: Button=action_buttons[key];var rect := button.get_global_rect();var center := rect.get_center()
  out.buttons[key]=[center.x,center.y]
  out.action_controls[key]={"text":button.text,"disabled":button.disabled,"visible":button.is_visible_in_tree(),"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}
 out["inspector_open"]=inspector_open();out["inspector"]=inspector.observation() if is_instance_valid(inspector) else {}
 out["preview_unit_id"]=out.inspector.get("preview_unit_id",-1);out["preview_layers"]=out.inspector.get("preview_layers",{})
 if inspector_open():out.buttons.inspector_close=out.inspector.buttons.close
 out["retreat_confirm_open"]=is_instance_valid(retreat_confirm) and retreat_confirm.visible
 if out.retreat_confirm_open:
  var yes := retreat_yes.get_global_rect().get_center();var no := retreat_no.get_global_rect().get_center()
  out.buttons.confirm_retreat=[yes.x,yes.y];out.buttons.cancel_retreat=[no.x,no.y]
 return out
