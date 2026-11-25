extends "res://burial_ruins/battlefield.gd"
## Preserve current map/fog/controller and crypt/undead policy. Only living
## company presentation and guarded paid reserve controls are composed here.
const Inventory = preload("res://hollow_campaign/appearance.gd")
const SkeletalMount = preload("res://painted_merge/undead/mount.gd")
const EngravedBanditMount = preload("res://painted_merge/bandits/mount.gd")
var _skeletal_mount_ready := false
var reserve_panel: PanelContainer
var reserve_column: VBoxContainer
var reserve_switch_buttons := {}
var combat_dock: PanelContainer
var combat_top: PanelContainer
var combat_hover: Label
var hit_chance_hover: Label
const UnitCard = preload("res://field_hud/unit_card.gd")
const AbilityHelp = preload("res://field_hud/ability_help.gd")
var combat_unit_hover: PanelContainer
var _combat_hover_pointer := Vector2(-1,-1)
var _terrain_ray_stamp: Array = []
var _terrain_quote_stamp: Array = []
var _work_dock_base := ""
var _work_dock_base_tooltip := ""
var _work_dock_active := false
const WORK_NOTICE_PAID := "Swing completed."
const WORK_NOTICE_FAILED := "Swing did not resolve."
var _terrain_swing: Dictionary = {}
const HoverMovement = preload("res://src/tactical_movement_plan.gd")
var combat_target_name: Label
var combat_actions: GridContainer
var combat_roster: HBoxContainer
const CombatStyle = preload("res://ui_polish/style.gd")
var combat_style = CombatStyle
var _retained_hud_theme: Theme
var combat_help_scrim: Control
var combat_help_close: Button
var combat_help_copy: Label
var combat_help_heading: Label
const CombatJournal = preload("res://combat_log/journal.gd")
var combat_journal: VBoxContainer
var _combat_guide_text := ""
var _combat_focus_return: Control
const CombatPortrait = preload("res://iron_oath/combat_portrait.gd")
var combat_initiative: HBoxContainer
var combat_initiative_scroll: ScrollContainer
var combat_initiative_buttons := {}
var combat_active_portrait: Control
var combat_active_identity: Label
const CombatSkin = preload("res://iron_oath/skin.gd")
const CombatIcons = preload("res://iron_oath/combat_icons.gd")
const WeaponSkillIcons = preload("res://iron_oath/weapon_skill_icons.gd")
var combat_surface: Control
var combat_selected_identity: Label
var combat_active_stats: Label
var combat_vitals: Control
var combat_perks: PanelContainer
var _combat_perk_actor := -2
func setup(value) -> void:
 super.setup(value)
 show_grid=true # Start with the selectable cells visible; the existing G toggle still owns it.

var _utility_pending:Dictionary={}
var _utility_step_ends:Dictionary={}

func _remember_utility(event:Dictionary) -> void:
 if not _skeletal_mount_ready:return
 var id:int=event.id
 var a:Node3D=actors.get(id)
 if not is_instance_valid(a) or not a.is_visible_in_tree() or not battle.unit_visible(0,id):return
 if event.kind in ["footwork","rotation"]:
  if not a.has_method("follow_utility_walk"):return
 elif not a.has_method("play_utility"):
  return
 var outgoing:Texture2D=a.utility_outgoing(event) if event.kind=="switch" and a.has_method("utility_outgoing") else null
 _utility_pending[id]={"event":event.duplicate(),"sprite_owner":a.get_instance_id(),"outgoing":outgoing}

func _utility_step_held(held:Dictionary) -> void:
 for id in _utility_step_ends.keys():
  var a:Node3D=actors.get(id)
  var step:Dictionary=_utility_step_ends[id]
  if not is_instance_valid(a) or not battle.unit_visible(0,id) or not battle.living(battle.units[id]) or step.owner!=a.get_instance_id() or not actor_tweens.has(id) or actor_tweens[id]!=step.tween or not step.tween.is_running():
   _utility_step_ends.erase(id);continue
  if battle.pos(battle.units[id])!=step.cell:
   step.tween.kill();actor_tweens.erase(id);_utility_step_ends.erase(id);continue
  held[id]=a.position
  a.position=tile_world(step.cell)

func _pop_utility() -> void:
 var rows:=_utility_pending
 _utility_pending={}
 for id in rows:
  var row:Dictionary=rows[id]
  var event:Dictionary=row.event
  var a:Node3D=actors.get(id)
  if not is_instance_valid(a) or not a.is_visible_in_tree() or not battle.living(battle.units[id]) or not battle.unit_visible(0,id) or a.get_instance_id()!=row.sprite_owner:continue
  if event.kind in ["footwork","rotation"]:
   if battle.pos(battle.units[id])!=event.cell:continue
   var destination:Vector3=tile_world(event.cell)
   var start:Vector3=a.position
   if start.is_equal_approx(destination):continue
   if actor_tweens.has(id):actor_tweens[id].kill()
   var swap:bool=event.kind=="rotation"
   var drift:=Vector3.ZERO
   if swap:
    var vector:=destination-start
    drift=Vector3(-vector.z,0,vector.x)*0.15
   var tween:=create_tween().bind_node(a)
   tween.tween_method(func(t:float):a.position=start.lerp(destination,t)+drift*sin(t*PI),0.0,1.0,0.36 if swap else 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
   actor_tweens[id]=tween
   _utility_step_ends[id]={"cell":event.cell,"owner":a.get_instance_id(),"tween":tween}
   a.follow_utility_walk(tween,event.kind,destination-start)
  else:a.play_utility(event,row.outgoing)

func _play_fitted_reload(id:int,uid:String) -> void:
 # Never retain a cue for someone outside current party sight.
 if not _skeletal_mount_ready or not battle.unit_visible(0,id):return
 var actor:Node3D=actors.get(id)
 if is_instance_valid(actor) and actor.is_visible_in_tree() and actor.has_method("play_reload"):
  actor.play_reload(uid)

func _create_terrain() -> Node3D:
 var desc:Dictionary=battle.get_meta("authored_map",{})
 if desc.get("presentation",{}).get("biome","")=="crypt":return preload("res://engraved_battle/crypt.gd").new()
 return preload("res://engraved_battle/heath.gd").new()

func _init() -> void:
 controller=load("res://enemy_inspection/controller.gd").new()

func _ready() -> void:
 super._ready()
 if not built:return
 controller.admission=func():return is_inside_tree() and built and not _reserve_modal()
 controller.intent_retired.connect(func():armed_action="")
 battle.weapon_reload_committed.connect(_play_fitted_reload)
 battle.utility_committed.connect(_remember_utility)
 for unit in battle.units:
  if unit.side != 0:continue
  var id := int(unit.id)
  if not actors.has(id):continue
  var old: Node3D = actors[id]
  var pose := old.transform;var shown := old.visible
  if actor_tweens.has(id):actor_tweens[id].kill();actor_tweens.erase(id)
  actors.erase(id);remove_child(old);old.free()
  var actor = load("res://engraved_battle/company.gd").new()
  actor.spearwall_query=battle.spearwall_active
  add_child(actor);actor.configure(unit,battle.armor_catalog)
  actor.transform = pose;actor.visible = shown;actor.set_selected(id == controller.selected)
  actors[id] = actor
 var canvas := inspector.get_parent()
 canvas.remove_child(inspector);inspector.free()
 inspector = load("res://enemy_inspection/view.gd").new()
 inspector.theme = hud.theme;canvas.add_child(inspector)
 inspector.visibility_changed.connect(_inspection_visibility_changed)
 _skeletal_mount_ready = true
 # Initial framing only: look slightly ahead to the known crossing. Home, pan,
 # zoom, later activations and visibility remain owned by their usual controls.
 var field:Dictionary=battle.get_meta("authored_map",{})
 if field.get("presentation",{}).has("reach") and battle.tile_visible(0,field.goal):
  var view_center:Vector3=tile_world(field.goal)
  var nearest:=INF
  for water:Vector2i in field.presentation.stream:
   if battle.tiles[battle.key(water)].terrain!="shallow_water" or not battle.tile_visible(0,water):continue
   var point:=tile_world(water);var cost:=camera_focus.distance_squared_to(point)
   if cost<nearest:nearest=cost;view_center=tile_world(field.goal).lerp(point,.45)
  camera_focus=camera_focus.lerp(view_center,.56)
  _apply_camera()
 refresh()
 # Passive morale render span (no combat, HUD, or actor picking ownership).
 add_child(preload("res://morale_flags/hip_flags.gd").new())
var _movement_walk_stamp:=0
func refresh() -> void:
 # Hold the mounted HUD, portraits, and fitted target wear until contact.
 if _hold_impact_refresh():return
 # Protect an in-flight exact-route tween from the inherited endpoint refresh.
 var held_pose:Dictionary={}
 if built and not battle.last_traversed.is_empty():
  var receipt:Dictionary=battle.last_traversed;var id:int=receipt.actor
  var endpoint:Vector2i=receipt.origin if receipt.path.is_empty() else receipt.path.back()
  if _movement_walk_stamp==hash([battle.get_instance_id(),receipt]):
   if battle.pos(battle.units[id])!=endpoint:
    # Footwork/Rotation can displace the actor without a new walk receipt.
    if actor_tweens.has(id):actor_tweens[id].kill();actor_tweens.erase(id)
   elif actors.has(id) and actor_tweens.has(id) and actor_tweens[id].is_running():
    held_pose[id]=actors[id].position;actors[id].position=tile_world(endpoint)
 _validate_inspection()
 _sync_inspection_intent()
 # map_visibility owns refresh without calling combat_pass.refresh.
 _sync_action_activation()
 if built and _skeletal_mount_ready:
  SkeletalMount.refresh_visible(self)
  EngravedBanditMount.refresh_visible(self)
 _utility_step_held(held_pose)
 super.refresh()
 for id in held_pose:actors[id].position=held_pose[id]
 _refresh_movement_walk()
 _pop_utility()
 # Refresh only the retained figure after actors validate their current sources.
 if inspector_open():
  var actor = actors.get(inspector.preview_unit_id)
  inspector.preview.present(actor.preview_texture() if is_instance_valid(actor) and actor.visible else null)
 _refresh_combat_log()

func _spearwall_status(id:int) -> String:
 var actor:Node3D=actors.get(id)
 if not is_instance_valid(actor) or not actor.is_visible_in_tree() or not battle.unit_visible(0,id):return ""
 if actor.has_method("has_spearwall_pose") and actor.has_spearwall_pose():return ""
 return "Spearwall" if battle.spearwall_active(battle.units[id]) else ""

func _defensive_status(id:int) -> String:
 var actor:Node3D=actors.get(id)
 if not is_instance_valid(actor) or not actor.is_visible_in_tree() or not battle.unit_visible(0,id):return ""
 var u:Dictionary=battle.units[id]
 if not battle.fighting(u):return ""
 var plate:Dictionary=u.get("arms",{}).get("shield",{})
 var labels:=PackedStringArray()
 if u.get("guard",false) and int(plate.get("condition",0))>0 and not (actor.has_method("has_defense_pose") and actor.has_defense_pose("guard")):labels.append("Shieldwall")
 if battle.vital_state(u).get("indomitable",false) and not (actor.has_method("has_defense_pose") and actor.has_defense_pose("indomitable")):labels.append("Indomitable")
 return " · ".join(labels)

func _draw_unit_labels() -> void:
 super._draw_unit_labels()
 var font:=ThemeDB.fallback_font
 for id:int in presented_unit_ids():
  var status:=_spearwall_status(id)
  var defense:=_defensive_status(id)
  if not defense.is_empty():status=defense if status.is_empty() else status+" · "+defense
  if status.is_empty():continue
  # No separate marker or picking surface. Anchor the fallback to the same
  # sight-admitted actor and projected position as the public vitals bar.
  var at:=unit_label_point(actors[id].global_position)+Vector2(32,-8)
  var width:=font.get_string_size(status,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
  units_overlay.draw_rect(Rect2(at,Vector2(width+10,17)),Color(0.06,0.05,0.04,0.92))
  units_overlay.draw_string(font,at+Vector2(5,1+font.get_ascent(13)),status,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("eed4a0"))

func _refresh_movement_walk() -> void:
 if not built or battle.last_traversed.is_empty():return
 var receipt:Dictionary=battle.last_traversed
 var stamp:=hash([battle.get_instance_id(),receipt])
 if stamp==_movement_walk_stamp:return
 _movement_walk_stamp=stamp
 var id:int=receipt.actor
 var endpoint:Vector2i=receipt.origin if receipt.path.is_empty() else receipt.path.back()
 if battle.pos(battle.units[id])!=endpoint:return
 if not actors.has(id) or battle.units[id].side!=0 or not actors[id].visible or receipt.path.is_empty():return
 if actor_tweens.has(id):actor_tweens[id].kill()
 var tween:=create_tween()
 for cell:Vector2i in receipt.path:
  tween.tween_property(actors[id],"position",tile_world(cell),0.42/receipt.path.size()).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
 actor_tweens[id]=tween
 if actors[id].has_method("follow_walk"):actors[id].follow_walk(tween)
func _build_hud() -> void:
 super._build_hud()
 # Replace (not supplement) inherited direct controller callbacks: the
 # centered Help panel does not cover these controls at large viewports.
 for action: String in ["attack","end"]:
  var button: Button = action_buttons[action]
  for connection: Dictionary in button.pressed.get_connections():
   button.pressed.disconnect(connection.callable)
 action_buttons.attack.pressed.connect(_attack_from_hud)
 action_buttons.end.pressed.connect(_end_from_hud)
 var toggle := _button("Pockets…",_toggle_reserves)
 toggle.position = Vector2(214,106)
 toggle.size = Vector2(170,40)
 hud.add_child(toggle)
 action_buttons.reserves = toggle
 reserve_panel = PanelContainer.new()
 reserve_panel.position = Vector2(16,154)
 reserve_panel.custom_minimum_size.x = 360
 reserve_panel.add_theme_stylebox_override("panel",_panel_style())
 hud.add_child(reserve_panel)
 reserve_column = VBoxContainer.new()
 reserve_column.add_theme_constant_override("separation",6)
 reserve_panel.add_child(reserve_column)
 reserve_panel.hide()
 _compact_combat_hud()
 hit_chance_hover=_label(17);hit_chance_hover.name="HitChanceHover"
 hit_chance_hover.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hit_chance_hover.autowrap_mode=TextServer.AUTOWRAP_OFF
 hit_chance_hover.add_theme_stylebox_override("normal",CombatSkin.panel(6))
 hit_chance_hover.z_index=100;hud.add_child(hit_chance_hover);hit_chance_hover.hide()
 combat_unit_hover=UnitCard.new();hud.add_child(combat_unit_hover)
 get_viewport().mouse_exited.connect(func():
  _combat_hover_pointer=Vector2(-1,-1);_refresh_pointer_hover())

func _update_hit_hover(point: Vector2) -> void:
 if not is_instance_valid(hit_chance_hover):return
 hit_chance_hover.hide();hit_chance_hover.text=""
 if not built or not is_visible_in_tree() or _reserve_modal() or not get_viewport().get_visible_rect().has_point(point):return
 if get_viewport().gui_get_hovered_control()!=null:return
 var attacker:int=battle.active_id
 if battle.side!=0 or not battle.can_act(attacker):return
 var target:int=pick_unit(point)
 if target<0 or battle.units[target].side==0 or not battle.unit_visible(0,target):return
 var action:="basic"
 # Inspection can retain a legacy controller quote. Only this activation's
 # explicitly armed enemy-targeted action changes the passive forecast.
 if controller.selected==attacker and controller.action==armed_action and _armed_actor==attacker and _armed_round==battle.round_no and _armed_selected==attacker:
  if armed_action=="shield_bash":action=armed_action
  elif armed_action=="special" and battle.special_info(battle.units[attacker].weapon).target:action="special"
 var quote:Dictionary=battle.action_quote(attacker,action,target)
 if action=="shield_bash":
  hit_chance_hover.text="Bash · %d%% to hit"%quote.hit.chance if not quote.hit.is_empty() else str(quote.get("preview_reason",quote.reason))
  _place_hover(hit_chance_hover,point)
  return
 if not quote.legal or quote.hit.is_empty():return
 hit_chance_hover.text="%d%% to hit"%quote.hit.chance
 _place_hover(hit_chance_hover,point)

func _place_hover(label:Label,point:Vector2) -> void:
 label.size=label.get_combined_minimum_size()
 var limit:=get_viewport().get_visible_rect().end-label.size-Vector2(8,8)
 label.position=(point+Vector2(18,18)).clamp(Vector2(8,8),limit.max(Vector2(8,8)))
 label.show()

func _refresh_pointer_hover() -> void:
 _update_hit_hover(_combat_hover_pointer)
 _update_unit_hover(_combat_hover_pointer)
 _update_terrain_hover()

func _update_unit_hover(point:Vector2) -> void:
 if not is_instance_valid(combat_unit_hover):return
 var view:=get_viewport()
 if not is_visible_in_tree() or _reserve_modal() or not view.get_visible_rect().has_point(point) or view.gui_get_hovered_control()!=null or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
  combat_unit_hover.clear_card();return
 var id:=pick_unit(point)
 if id<0:
  # The bars may be inspected without making their rectangle a click target.
  for candidate:int in presented_unit_ids():
   var strips:=_unit_vital_rows(candidate)
   if not strips.is_empty() and strips[0].track.merge(strips[-1].track).has_point(point):id=candidate;break
 if id<0 or not battle.unit_visible(0,id) or not battle.living(battle.units[id]):
  combat_unit_hover.clear_card();return
 var u:Dictionary=battle.units[id]
 var soldier:Dictionary={}
 var campaign=session.campaign
 if u.side==0 and campaign.battle==battle:
  var company_id:int=u.get("company_id",campaign.deployment[id] if id<campaign.deployment.size() else -1)
  if company_id>=0 and company_id<campaign.soldiers.size():soldier=campaign.soldiers[company_id]
 combat_unit_hover.present(battle,u,soldier)
 _layout_unit_hover(id,point)

func _unit_hover_footprint(id:int) -> Rect2:
 var foot:Vector3=actors[id].global_position
 var feet:=camera.unproject_position(foot)
 var top:=unit_label_point(foot)
 var half_width:=maxf(22.0,(feet.y-top.y)*0.28)
 return Rect2(Vector2(top.x-half_width,top.y-9),Vector2(half_width*2,feet.y-top.y+13))

func _layout_unit_hover(id:int,point:Vector2) -> void:
 # The map gap is bounded by the live initiative row and command dock.
 var view:=get_viewport().get_visible_rect().grow(-8)
 var top:=maxf(combat_initiative_scroll.get_global_rect().end.y,combat_top.get_global_rect().end.y)+4
 var bottom:=combat_dock.get_global_rect().position.y-4
 var size:Vector2=combat_unit_hover.size
 var subject:=_unit_hover_footprint(id).grow(8)
 var avoid:=subject.merge(Rect2(point-Vector2(6,6),Vector2(12,12)))
 if hit_chance_hover.visible:avoid=avoid.merge(hit_chance_hover.get_global_rect().grow(4))
 var x:=clampf(point.x-size.x/2,view.position.x,maxf(view.position.x,view.end.x-size.x))
 var y:=clampf(point.y-34,top,maxf(top,bottom-size.y))
 var area:=Rect2(Vector2(view.position.x,top),Vector2(view.size.x,maxf(0,bottom-top)))
 var candidates:=[Vector2(avoid.end.x,y),Vector2(avoid.position.x-size.x,y),Vector2(x,avoid.position.y-size.y),Vector2(x,avoid.end.y)]
 var best:=INF
 for position:Vector2 in candidates:
  var rect:=Rect2(position,size)
  if not area.encloses(rect):continue
  var score:=rect.get_center().distance_to(point)
  for other:int in presented_unit_ids():
   if other!=id and actors.has(other):score+=rect.intersection(_unit_hover_footprint(other)).get_area()
  if score<best:best=score;combat_unit_hover.position=position
 combat_unit_hover.visible=best<INF

func _update_terrain_hover(already_picked:bool=false) -> void:
 if not is_instance_valid(combat_hover):return
 var viewport:=get_viewport()
 var point:=_combat_hover_pointer
 var view:=viewport.get_visible_rect()
 if not built or not is_visible_in_tree() or _reserve_modal() or not view.has_point(point) or viewport.gui_get_hovered_control()!=null or hit_chance_hover.visible or (is_instance_valid(combat_unit_hover) and combat_unit_hover.visible) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
  _paint_special_skill()
  _show_work_dock("")
  combat_hover.hide();combat_hover.text="";return
 # Motion usually arrives with the inherited hit result. Reproject on a
 # stationary pointer when the camera moves, and re-quote after field refresh.
 var ray_stamp:=[point,view,camera.global_transform,camera.size,revision]
 if not already_picked and ray_stamp!=_terrain_ray_stamp:hover=pick_hex(point)
 _terrain_ray_stamp=ray_stamp
 var quote_stamp:=[hover,revision]
 if quote_stamp!=_terrain_quote_stamp:
  _terrain_quote_stamp=quote_stamp
  hover_text=_terrain_hover_copy(hover)
 # A work quote is live, like the hit hover. Do not cache it in hover_text
 # (the inherited public observation) or leave work details after losing sight.
 var work:=_visible_terrain_work(hover) if controller.action not in ["footwork","rotation"] else {}
 if not work.is_empty() and pick_unit(point)>=0:work={}
 var text:=hover_text
 var dock:=""
 var work_kind:=""
 if not work.is_empty():
  var quote:Dictionary=battle.action_quote(controller.selected,"terrain_work",-1,hover) if work.hp>0 else {}
  text=_terrain_work_copy(work,quote)
  if armed_action=="special":
   dock=_terrain_work_copy(work,quote,true)
   if quote.get("legal",false):work_kind=work.kind
 _paint_special_skill(work_kind)
 _show_work_dock(dock)
 if combat_hover.text!=text:combat_hover.text=text
 if text.is_empty():combat_hover.hide()
 else:_place_hover(combat_hover,point)

func _visible_terrain_work(cell: Vector2i) -> Dictionary:
 if not battle.tile_visible(0,cell) or not battle.has_method("terrain_work_at"):return {}
 return battle.terrain_work_at(cell)

func _show_work_dock(text: String) -> void:
 if not is_instance_valid(target_label):return
 if text.is_empty() and not _work_dock_active:return
 _work_dock_active=not text.is_empty()
 var shown:=text if _work_dock_active else _work_dock_base
 var tooltip:=text if _work_dock_active else _work_dock_base_tooltip
 if target_label.text!=shown:target_label.text=shown
 if target_label.tooltip_text!=tooltip:target_label.tooltip_text=tooltip
 # A stock unit-action notice can outlive its quote (e.g. after AP changes).
 # The ground quote already gives the exact refusal; keep only paid-work
 # feedback here. The controller's untouched notice returns off this hex.
 var notice:String=controller.notice
 if _work_dock_active and notice not in [WORK_NOTICE_PAID,WORK_NOTICE_FAILED]:notice=""
 if notice_label.text!=notice:
  notice_label.text=notice
  notice_label.tooltip_text=notice

func _terrain_work_copy(work: Dictionary, quote: Dictionary, compact: bool=false) -> String:
 var title:="%s · %s"%[work.verb,work.name]
 var hp:="%d/%d HP"%[work.hp,work.max_hp]
 if work.hp==0:
  var cleared:="Cleared · Click hex to plan movement" if armed_action=="special" else "Cleared"
  return title+"\n"+cleared # Debris is no longer a work target.
 var damage:Dictionary=quote.get("terrain_damage",{})
 if not damage.is_empty():hp+=" · %d–%d damage"%[damage.min,damage.max]
 var cost:="%d AP / %d fatigue"%[quote.ap,quote.fatigue]
 var detail:String=quote.reason
 if quote.legal:
  detail="Click hex to swing" if armed_action=="special" else "Choose weapon special [2], then click hex"
  if not damage.is_empty() and work.hp<=damage.max:
   detail=("Guaranteed to clear" if work.hp<=damage.min else "May clear")+" · "+detail
  if not compact:detail="Always hits · "+detail
 if compact:return title+"\n"+cost+" · "+("Click hex to swing" if quote.legal else quote.reason)
 return title+"\n"+hp+"\n"+cost+" per swing\n"+detail

func _terrain_hover_copy(cell:Vector2i) -> String:
 var key:String=battle.key(cell)
 var tile:Dictionary=battle.tiles.get(key,{})
 if tile.is_empty():return ""
 if not battle.tile_explored(0,cell):return "Unexplored terrain."
 var sight:bool=battle.tile_visible(0,cell)
 if not sight and terrain!=null and terrain.has_method("remembered_work_tile"):
  tile=terrain.remembered_work_tile(key,tile)
 var terrain_text:="%s · elevation %d"%[String(tile.terrain).capitalize(),tile.height]
 if not sight:return "Remembered "+terrain_text
 if not TerrainRules.tile_reason(tile).is_empty():return terrain_text+" · Blocked"
 var id:int=controller.selected
 if id>=0 and id<battle.units.size() and battle.pos(battle.units[id])==cell:return terrain_text+" · Current hex"
 if battle.at(cell)>=0:return terrain_text+" · Occupied"
 if battle.side!=0 or not battle.can_act(id) or controller.action in ["footwork","rotation"]:return terrain_text
 var preview:Dictionary=controller.movement_preview()
 var move:Dictionary
 if preview.valid:
  # Match the three ordinary click meanings, without changing the plan:
  # confirm its destination, truncate its path, or append a waypoint.
  var index:int=preview.path.find({"q":cell.x,"r":cell.y})
  if index==preview.path.size()-1:move=preview
  elif index>=0:
   var prefix:Array=preview.path.slice(0,index+1).map(func(row):return Vector2i(row.q,row.r))
   move=HoverMovement.quote_path(battle,id,prefix,[])
  else:
   var points:Array=preview.waypoints.map(func(row):return Vector2i(row.q,row.r))
   points.append(cell)
   move=HoverMovement.plan(battle,id,points)
 else:move=HoverMovement.plan(battle,id,[cell])
 if move.is_empty():return terrain_text+" · No affordable visible route"
 return "%s · %s: %d AP / %d fatigue"%[terrain_text,"Route" if preview.valid else "Move",move.cost,move.fatigue]

func _button(title: String, callback: Callable) -> Button:
 var button := super._button(title,callback)
 button.focus_mode = Control.FOCUS_ALL
 button.custom_minimum_size = Vector2(72,34)
 if ResourceLoader.exists("res://ui_polish/style.gd"):
  load("res://ui_polish/style.gd").button(button)
 return button

func _combat_panel() -> PanelContainer:
 var panel := PanelContainer.new()
 panel.add_theme_stylebox_override("panel",combat_style.panel())
 hud.add_child(panel)
 return panel

func _compact_combat_hud() -> void:
 combat_style = CombatStyle
 _retained_hud_theme = hud.theme
 hud.theme = combat_style.theme()
 for child in hud.get_children():
  if child is Control and child != units_overlay and child != help_panel:child.hide()
 # The original controls/callbacks are moved, never duplicated. The full
 # selected stats remain in Details while the card always identifies ACTIVE.
 unit_label.reparent(hud);unit_label.hide()
 combat_top=_combat_panel();combat_top.name="CombatUtilities"
 combat_top.add_theme_stylebox_override("panel",CombatSkin.panel(8))
 # Keep camera shortcuts/API, but retire the redundant visible utility.
 action_buttons.overview.hide();action_buttons.overview.focus_mode=Control.FOCUS_NONE
 action_buttons.overview.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var utilities:=VBoxContainer.new();utilities.add_theme_constant_override("separation",6);combat_top.add_child(utilities)
 var information:=HBoxContainer.new();information.add_theme_constant_override("separation",6);utilities.add_child(information)
 status_label.reparent(information);status_label.show();combat_style.label(status_label,16)
 status_label.clip_text=false;status_label.autowrap_mode=TextServer.AUTOWRAP_OFF
 status_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var help_button:=_button("Help [H]",_toggle_help);information.add_child(help_button);action_buttons.help=help_button
 var public_log:=_button("Log",_open_combat_page.bind("log"));information.add_child(public_log);action_buttons.log=public_log
 var details:=_button("Details",_open_combat_page.bind("details"));information.add_child(details);action_buttons.details=details
 var commands:=HBoxContainer.new();commands.alignment=BoxContainer.ALIGNMENT_END
 commands.add_theme_constant_override("separation",6);utilities.add_child(commands)
 var obstacles:=_button("Hide obstacles",_toggle_battle_obstacles)
 obstacles.tooltip_text="Toggle obstacle art. Red hexes are still blocked."
 commands.add_child(obstacles);action_buttons.obstacles=obstacles
 for key in ["equipment","retreat"]:
  var button:Button=action_buttons[key];button.reparent(commands);button.show()
  button.text={"equipment":"Company [I]","retreat":"Withdraw…"}[key]
 for key in ["help","log","details","obstacles","equipment","retreat"]:
  var button:Button=action_buttons[key];_iron_button(button)
  # Containers must see the complete themed text minimum, not clipped text.
  button.custom_minimum_size=Vector2.ZERO;button.clip_text=false
  button.add_theme_font_size_override("font_size",15)
 combat_top.minimum_size_changed.connect(_layout_combat_dock)
 var brand:=_label(22);brand.name="CombatBrand";brand.text="IRON & OATH"
 brand.add_theme_font_override("font",load("res://assets/serif.ttf"));brand.position=Vector2(18,16);brand.size=Vector2(196,30);hud.add_child(brand)
 kit_label.reparent(hud);kit_label.show();kit_label.position=Vector2(18,49);kit_label.size=Vector2(196,34)
 kit_label.clip_text=true;combat_style.label(kit_label,14)
 combat_dock=_combat_panel();combat_dock.name="CombatDock"
 combat_dock.add_theme_stylebox_override("panel",CombatSkin.panel(0))
 combat_surface=Control.new();combat_surface.name="CombatOverlaySurface";combat_dock.add_child(combat_surface)
 combat_selected_identity=_label(16);combat_selected_identity.name="CombatInspectedIdentity";combat_surface.add_child(combat_selected_identity)
 combat_selected_identity.clip_text=true
 combat_target_name=_label(15);combat_target_name.hide();hud.add_child(combat_target_name)
 target_label.reparent(combat_surface);target_label.show();combat_style.label(target_label,15)
 target_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;target_label.max_lines_visible=2;target_label.clip_text=true
 combat_actions=GridContainer.new();combat_actions.name="CombatActionRail";combat_actions.columns=6
 combat_actions.add_theme_constant_override("h_separation",6);combat_surface.add_child(combat_actions)
 for key in ["basic","special","guard","recover","wait","reserves"]:
  var button:Button=action_buttons[key];button.reparent(combat_actions);button.show();_iron_button(button)
  button.custom_minimum_size=Vector2(0,102);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.icon=CombatIcons.texture(key);button.expand_icon=true;button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP
  button.add_theme_constant_override("icon_max_width",76);button.clip_text=true;button.add_theme_font_size_override("font_size",16)
 combat_perks=_combat_panel();combat_perks.name="CombatPerkActions"
 combat_perks.add_theme_stylebox_override("panel",CombatSkin.panel())
 var perk_row:=VBoxContainer.new();combat_perks.add_child(perk_row)
 var more:=_button("Perks ▾",_toggle_combat_perks);combat_surface.add_child(more);action_buttons.more=more
 more.custom_minimum_size=Vector2.ZERO;more.add_theme_font_size_override("font_size",15)
 combat_perks.hide()
 for key in ["footwork","rotation","indomitable"]:
  var button:Button=action_buttons[key];button.reparent(perk_row);button.show();_iron_button(button)
 var rally:=_button("Rally the Troops",_press_rally)
 rally.name="RallyTheTroops";_iron_button(rally);perk_row.add_child(rally);rally.hide()
 action_buttons["rally_the_troops"]=rally
 for key in ["attack","end"]:
  var button:Button=action_buttons[key];button.reparent(combat_surface);button.show();_iron_button(button,key=="end")
  button.clip_text=true;button.custom_minimum_size=Vector2.ZERO
 # Use the free space above Execute so the six stock action tiles don't shrink.
 var bash:=_button("Bash",_choose.bind("shield_bash"))
 bash.name="ShieldBash";_iron_button(bash);combat_surface.add_child(bash)
 bash.custom_minimum_size=Vector2.ZERO;bash.add_theme_font_size_override("font_size",14)
 for state in ["normal","hover","pressed","disabled"]:
  bash.add_theme_stylebox_override(state,_bash_style(state in ["hover","pressed"],state=="disabled"))
 action_buttons.shield_bash=bash
 action_buttons.end.add_theme_font_override("font",load("res://assets/serif.ttf"))
 action_buttons.end.add_theme_font_size_override("font_size",24)
 notice_label.reparent(combat_surface);notice_label.show();combat_style.label(notice_label,15)
 notice_label.autowrap_mode=TextServer.AUTOWRAP_OFF;notice_label.clip_text=true
 combat_hover=_label(14);combat_hover.name="CombatTerrainHover";hud.add_child(combat_hover)
 combat_hover.mouse_filter=Control.MOUSE_FILTER_IGNORE;combat_hover.z_index=100
 combat_hover.add_theme_stylebox_override("normal",CombatSkin.panel(6));combat_hover.hide()
 # Old anonymous boxes and roster focus surfaces cannot intercept the field.
 for button:Button in roster_buttons.values():button.hide();button.focus_mode=Control.FOCUS_NONE
 carry_choice.hide();carry_choice.focus_mode=Control.FOCUS_NONE;carry_choice.mouse_filter=Control.MOUSE_FILTER_IGNORE
 action_buttons.switch.hide();action_buttons.switch.focus_mode=Control.FOCUS_NONE;action_buttons.switch.mouse_filter=Control.MOUSE_FILTER_IGNORE
 reserve_panel.reparent(hud);reserve_panel.hide();reserve_panel.add_theme_stylebox_override("panel",CombatSkin.panel())
 _build_combat_identity()
 _build_combat_guide()
 hud.resized.connect(_layout_combat_dock)
 _layout_combat_dock()

func _iron_button(button:Button, primary:bool=false) -> void:
 combat_style.button(button)
 for state in ["normal","hover","pressed","disabled"]:
  button.add_theme_stylebox_override(state,CombatSkin.button(primary,state in ["hover","pressed"],state=="disabled"))

func _bash_style(selected:bool,disabled:bool=false) -> StyleBoxTexture:
 # The normal vertical theme padding raises the real minimum past the gap.
 var style:=CombatSkin.button(false,selected,disabled)
 style.content_margin_top=3;style.content_margin_bottom=3
 return style

func _toggle_battle_obstacles() -> void:
 if _reserve_modal():return
 _set_obstacles_hidden(not obstacles_hidden)
 action_buttons.obstacles.text="Show obstacles" if obstacles_hidden else "Hide obstacles"

func _build_combat_identity() -> void:
 combat_initiative_scroll=ScrollContainer.new();combat_initiative_scroll.name="CombatInitiativeScroll"
 hud.add_child(combat_initiative_scroll)
 combat_initiative_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 combat_initiative_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 combat_initiative=HBoxContainer.new();combat_initiative.name="CombatInitiative"
 combat_initiative.add_theme_constant_override("separation",6);combat_initiative_scroll.add_child(combat_initiative)
 combat_active_identity=_label(20);combat_active_identity.name="CombatActiveIdentity";combat_surface.add_child(combat_active_identity)
 combat_active_identity.add_theme_font_override("font",load("res://assets/serif.ttf"));combat_active_identity.clip_text=true
 combat_active_portrait=CombatPortrait.new();combat_active_portrait.name="CombatActivePortrait";combat_surface.add_child(combat_active_portrait)
 combat_vitals=preload("res://iron_oath/vitals.gd").new();combat_vitals.name="CombatVitals";combat_surface.add_child(combat_vitals)
 combat_active_stats=_label(14);combat_active_stats.name="CombatActiveStats";combat_surface.add_child(combat_active_stats)
 combat_active_stats.add_theme_constant_override("line_spacing",1)
 combat_active_stats.clip_text=true

func _toggle_combat_perks() -> void:
 if _reserve_modal():return
 _retire_movement()
 reserve_panel.hide();combat_perks.visible=not combat_perks.visible
 if combat_perks.visible:
  for key in ["footwork","rotation","indomitable","rally_the_troops"]:
   var button:Button=action_buttons[key]
   if button.visible and not button.disabled:button.grab_focus();break
 else:action_buttons.more.grab_focus()

func _press_rally() -> void:
 var button: Button=action_buttons["rally_the_troops"]
 if _reserve_modal() or not button.is_visible_in_tree() or button.disabled:return
 _execute("rally_the_troops")
 if action_buttons.more.is_visible_in_tree():action_buttons.more.grab_focus()

func _refresh_rally_control(id: int) -> void:
 var button: Button=action_buttons["rally_the_troops"]
 var learned: bool=id>=0 and id<battle.units.size() and battle.units[id].side==0 and battle.living(battle.units[id]) and "rally_the_troops" in battle.units[id].perks
 var changed:=button.visible!=learned
 button.visible=learned
 var q: Dictionary=battle.action_quote(id,"rally_the_troops")
 button.disabled=not q.legal
 button.text="%s · %d AP"%[q.name,q.ap]
 button.tooltip_text="%d AP / %d fatigue\n%s"%[q.ap,q.fatigue,q.reason if not q.legal else "Rally allies within 4 hexes. Each rolls Resolve; Fleeing can recover to Wavering. Cannot raise morale above Steady."]
 if changed:_layout_combat_dock()

func _choose(action:String) -> void:
 if not _commands_available():return
 if action=="shield_bash":
  if not battle.action_quote(controller.selected,action).get("ready",false):return
  controller.target=-1
 if controller.is_reload_action(action):
  _execute(action)
  return
 armed_action=action;_armed_actor=battle.active_id;_armed_round=battle.round_no;_armed_selected=controller.selected
 super._choose(action)
 if is_instance_valid(combat_perks):
  combat_perks.hide()
  if action in ["footwork","rotation"]:action_buttons.attack.grab_focus()

func _execute(action:String) -> void:
 super._execute(action)
 if is_instance_valid(combat_perks):combat_perks.hide()

func _inspect_initiative(id: int) -> void:
 if _reserve_modal() or not battle.unit_visible(0,id):return
 if battle.units[id].side==0:controller.select_unit(id)
 else:controller.select_target(id)

func _refresh_combat_identity() -> void:
 if not is_instance_valid(combat_initiative):return
 var ids:Array=battle.upcoming().filter(func(id):return battle.unit_visible(0,id))
 for id in combat_initiative_buttons.keys():
  if id not in ids:
   var old:Button=combat_initiative_buttons[id];combat_initiative.remove_child(old);old.queue_free();combat_initiative_buttons.erase(id)
 for index in ids.size():
  var id:int=ids[index];var u:Dictionary=battle.units[id]
  if not combat_initiative_buttons.has(id):
   var button:=_button("",_inspect_initiative.bind(id));button.custom_minimum_size=Vector2(72,78)
   button.set_meta("fighter_id",id);combat_initiative.add_child(button);combat_initiative_buttons[id]=button
   var portrait:=CombatPortrait.new();portrait.name="FighterPortrait";button.add_child(portrait)
   portrait.position=Vector2(5,3);portrait.size=Vector2(62,55)
   var caption:=_label(12);caption.name="Identity";caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   caption.position=Vector2(0,59);caption.size=Vector2(72,18);caption.clip_text=true;button.add_child(caption)
  var button:Button=combat_initiative_buttons[id];combat_initiative.move_child(button,index)
  var is_active:bool=id==battle.active_id
  var is_inspected:bool=id==controller.selected and not is_active
  button.tooltip_text=("ACTIVE · " if is_active else "Inspecting · " if is_inspected else "Inspect · ")+str(u.name)
  button.get_node("Identity").text="ACTIVE" if is_active else "INSPECT" if is_inspected else str(u.name)
  button.get_node("FighterPortrait").present(actors.get(id),id,is_active,is_inspected,u.side!=0)
 var active:int=battle.active_id
 var selected:int=controller.selected
 if selected>=0 and selected<battle.units.size() and battle.units[selected].side==0 and battle.living(battle.units[selected]) and battle.unit_visible(0,selected):
  active=selected
 if active>=0 and battle.unit_visible(0,active):
  var is_active:bool=active==battle.active_id
  combat_active_identity.text=("ACTIVE · " if is_active else "INSPECTING · ")+str(battle.units[active].name)
  combat_active_portrait.present(actors.get(active),active,is_active,not is_active,battle.units[active].side!=0)
  var u:Dictionary=battle.units[active]
  combat_vitals.show();combat_vitals.present(u)
  combat_active_stats.text="AP  %d / %d\nFatigue  %d / %d\nHead %d · Body %d\nInitiative %d\nMorale %s" % [u.ap,battle.MAX_AP,u.fatigue,battle.fatigue_max(u),u.helmet,u.armor+u.padding,battle.initiative_value(u),preload("res://morale_flags/readout.gd").current_name(battle,active)]
  combat_active_stats.tooltip_text=combat_vitals.tooltip_text
 else:
  combat_active_identity.text="ENEMY TURN" if battle.side!=0 else "NO ACTIVE FIGHTER"
  combat_active_portrait.present(null,-1,false,false,false)
  combat_vitals.clear();combat_vitals.hide();combat_active_stats.tooltip_text=""
  combat_active_stats.text="Identity concealed\nby party sight."

 _fit_combat_identity()

func _fit_combat_identity() -> void:
 if not is_instance_valid(combat_active_identity) or combat_active_identity.size.x<=0:return
 var font:=combat_active_identity.get_theme_font("font")
 var px:=20
 while px>13 and font.get_string_size(combat_active_identity.text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>combat_active_identity.size.x-2:px-=1
 if combat_active_identity.get_theme_font_size("font_size")!=px:combat_active_identity.add_theme_font_size_override("font_size",px)

func _layout_combat_dock() -> void:
 if not is_instance_valid(combat_surface) or not is_instance_valid(combat_active_portrait):return
 var view:=get_viewport().get_visible_rect().size
 combat_top.size=Vector2(334,84).max(combat_top.get_combined_minimum_size())
 combat_top.position=Vector2(view.x-combat_top.size.x-12,10)
 combat_initiative_scroll.position=Vector2(224,10);combat_initiative_scroll.size=Vector2(maxf(100,combat_top.position.x-236),94)
 var height:=214.0
 combat_dock.position=Vector2(12,view.y-height-12);combat_dock.size=Vector2(view.x-24,height)
 var card_width:=330.0 if view.x>=1120 else 290.0
 var end_width:=174.0 if view.x>=1120 else 150.0
 var rail_x:=card_width+12
 var end_x:=combat_dock.size.x-end_width-12
 var rail_width:=end_x-rail_x-12
 combat_active_portrait.position=Vector2(10,12);combat_active_portrait.size=Vector2(110 if view.x>=1120 else 88,176)
 var text_x:=combat_active_portrait.size.x+22
 combat_active_identity.position=Vector2(text_x,12);combat_active_identity.size=Vector2(card_width-text_x,26)
 _fit_combat_identity()
 combat_vitals.position=Vector2(text_x,42);combat_vitals.size=Vector2(card_width-text_x,56)
 combat_active_stats.position=Vector2(text_x,104);combat_active_stats.size=Vector2(card_width-text_x,96)
 combat_selected_identity.position=Vector2(rail_x,12);combat_selected_identity.size=Vector2(rail_width-84,24)
 action_buttons.more.position=Vector2(rail_x+rail_width-80,10);action_buttons.more.size=Vector2(80,28)
 target_label.position=Vector2(rail_x,39);target_label.size=Vector2(rail_width,43)
 combat_actions.position=Vector2(rail_x,86);combat_actions.size=Vector2(rail_width,102)
 action_buttons.shield_bash.position=Vector2(end_x,2);action_buttons.shield_bash.size=Vector2(end_width,26)
 action_buttons.attack.position=Vector2(end_x,30);action_buttons.attack.size=Vector2(end_width,46)
 action_buttons.end.position=Vector2(end_x,86);action_buttons.end.size=Vector2(end_width,102)
 notice_label.position=Vector2(rail_x,190);notice_label.size=Vector2(combat_dock.size.x-rail_x-12,22)
 reserve_panel.position=Vector2(rail_x+12,combat_dock.position.y-212);reserve_panel.size=Vector2(minf(500,view.x-rail_x-24),202)
 var perk_height:=172.0 if action_buttons["rally_the_troops"].visible else 140.0
 combat_perks.position=Vector2(end_x-220,combat_dock.position.y-perk_height-10);combat_perks.size=Vector2(220,perk_height)
 if is_instance_valid(help_panel):
  help_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
  var half:=Vector2(minf(380,(view.x-40)/2),minf(280,(view.y-40)/2))
  help_panel.offset_left=-half.x;help_panel.offset_right=half.x;help_panel.offset_top=-half.y;help_panel.offset_bottom=half.y

func _build_combat_guide() -> void:
 combat_help_scrim=Control.new();combat_help_scrim.name="CombatGuideScrim"
 combat_help_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 combat_help_scrim.mouse_filter=Control.MOUSE_FILTER_STOP;hud.add_child(combat_help_scrim)
 var shade:=ColorRect.new();shade.color=Color(0.02,0.03,0.025,0.8)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;combat_help_scrim.add_child(shade)
 help_panel.reparent(combat_help_scrim)
 help_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 help_panel.offset_left=-330;help_panel.offset_right=330;help_panel.offset_top=-260;help_panel.offset_bottom=260
 help_panel.add_theme_stylebox_override("panel",combat_style.panel())
 for child in help_panel.get_children():help_panel.remove_child(child);child.queue_free()
 var column:=VBoxContainer.new();help_panel.add_child(column)
 combat_help_heading=_label(22);combat_help_heading.text="How to fight";column.add_child(combat_help_heading)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;column.add_child(scroll)
 combat_help_copy=_label(16);combat_help_copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 combat_help_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(combat_help_copy)
 combat_help_copy.text="YOUR ACTIVATION\nOnly the named active fighter may act. Selecting another fighter is inspection, not a change of turn. Click ground for footprints and exact AP / fatigue. Click the same destination again to move. Plain clicks on other tiles append waypoints; an earlier planned tile truncates. Your origin, right-click or Escape clears the route. The complete route must fit this activation. Amber steps warn of known control / reactions, not guaranteed safety.\n\nCHOOSE AND ATTACK\nChoose Basic [1] or Special [2], then click a legal enemy once to attack immediately. Choosing a skill never attacks an old target. Execute [Enter] remains optional for attacks and commits nonattack actions. Costs, legality and forecasts come from Battle. Damage is on hit, before morale and reactions; a hit is not guaranteed.\n\nTURN CONTROLS\nShieldwall / Guard [B], Recover [R], Wait [Space / Q], End [F]. Recover ends the activation; Wait defers it without recovery. Learned Footwork / Rotation: choose the action, select a hex / ally, then Execute. Escape cancels targeting. Indomitable acts directly.\n\nPOCKETS\nOpen Pockets and choose an owned item. Switching pays the displayed AP / fatigue cost. Fill pockets on the Equipment page in camp.\n\nSIGHT AND FORECASTS\nShared party sight is not personal attack sight. Unknown influencing ground withholds the forecast rather than reporting zero damage. Lost contacts cannot be targeted.\n\nCAMERA AND EQUIPMENT\nWASD / arrows / middle drag pan; wheel or +/- zoom. Home restores close view; O shows the board; G toggles the grid. Equipment [I] is read-only and pauses battle. Tab / Shift-Tab navigates controls. Escape closes the top overlay.\n\nSAVING AND WITHDRAWAL\nSave / F5 in camp creates a manual checkpoint. Nothing auto-saves; battle and aftermath are not saved. Quitting resumes your last manual checkpoint. Withdraw is a confirmed loss: wounds, casualties and equipment wear remain. Return does not heal or repair. A save failure blocks progress until retry succeeds."
 _combat_guide_text=combat_help_copy.text
 combat_journal=CombatJournal.new();column.add_child(combat_journal);combat_journal.hide()
 combat_help_close=_button("Return to battle [Esc]",_toggle_help);column.add_child(combat_help_close)
 combat_help_scrim.hide()

func _toggle_help() -> void:
 if not is_instance_valid(combat_help_scrim):super._toggle_help();return
 if inspector_open() or (is_instance_valid(retreat_confirm) and retreat_confirm.visible):return
 if help_open:
  help_open=false;help_panel.hide();combat_help_scrim.hide();_restore_combat_focus(action_buttons.help)
 else:
  _retire_movement()
  combat_help_heading.text="How to fight";combat_help_copy.text=_combat_guide_text
  combat_help_heading.remove_theme_color_override("font_color")
  combat_help_heading.remove_theme_font_override("font")
  combat_journal.hide();combat_help_copy.get_parent().show()
  combat_help_copy.get_parent().scroll_vertical=0
  reserve_panel.hide();combat_perks.hide();_combat_focus_return=get_viewport().gui_get_focus_owner()
  help_open=true;combat_help_scrim.show();help_panel.show();combat_help_close.grab_focus()

func _open_combat_page(page: String) -> void:
 if _reserve_modal():return
 controller.sanitize_target()
 var text := ""
 if page=="log":
  text="\n".join(battle.public_events(0))
 elif page=="details":
  text=str(session.deployed_map.get("title",""))+"\n\n"+unit_label.text+"\n\n"+_quote_text(controller.quote())
  # Read only actor notes whose identity is already admitted to party sight.
  for id in [controller.selected,controller.target]:
   if id<0 or not battle.unit_visible(0,id) or not actors.has(id):continue
   var actor=actors[id]
   if actor.has_method("appearance_diagnostics"):
    var notes: Dictionary=actor.appearance_diagnostics()
    var limitations: String=notes.get("limitations","")
    if not limitations.is_empty():text+="\n\n"+limitations
   for issue: Dictionary in actor.equipment_issues():
    text+="\n%s: %s [UID %s; condition %d%s] — %s" % ["Omitted" if issue.kind=="omitted" else "Visual proxy",issue.definition,str(issue.item),issue.condition,"/%d" % issue.maximum if issue.maximum>0 else " (no durability)",issue.reason]
 else:return
 _toggle_help()
 combat_help_heading.text="Combat log" if page=="log" else "Encounter details"
 if page=="log":
  combat_help_heading.add_theme_color_override("font_color",CombatStyle.GOLD)
  combat_help_heading.add_theme_font_override("font",load("res://assets/serif.ttf"))
 combat_help_copy.text=text
 combat_journal.visible=page=="log"
 combat_help_copy.get_parent().visible=page!="log"
 if page=="log":combat_journal.present(battle.public_events(0),true)

func _refresh_combat_log() -> void:
 # Event-driven presentation refresh only; never poll battle/hidden events.
 if not help_open or not is_instance_valid(combat_help_heading) or combat_help_heading.text!="Combat log":return
 var text:="\n".join(battle.public_events(0))
 if text==combat_help_copy.text:return
 combat_help_copy.text=text
 combat_journal.present(battle.public_events(0))

func _restore_combat_focus(fallback: Control) -> void:
 var target:Control=_combat_focus_return if is_instance_valid(_combat_focus_return) and _combat_focus_return.is_visible_in_tree() else fallback
 if is_instance_valid(target):target.grab_focus()
 _combat_focus_return=null

func _combat_focusables(node: Node) -> Array[Control]:
 var values:Array[Control]=[]
 for child in node.get_children():
  if child is Control and child.is_visible_in_tree() and child.focus_mode==Control.FOCUS_ALL and (not child is BaseButton or not child.disabled):values.append(child)
  values.append_array(_combat_focusables(child))
 return values

func _combat_modal_root() -> Control:
 if is_instance_valid(retreat_confirm) and retreat_confirm.visible:return retreat_confirm
 if inspector_open():return inspector
 if help_open:return help_panel
 return null

func _input(event: InputEvent) -> void:
 if impact_pending() and (event is InputEventKey or event is InputEventMouseButton):
  get_viewport().set_input_as_handled();return
 if _company_modal():
  get_viewport().set_input_as_handled();return
 if not built:return
 if event is InputEventMouseMotion:
  _combat_hover_pointer=event.position;_update_hit_hover(_combat_hover_pointer)
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed and not _reserve_modal():
  armed_action="";controller.reset_action();controller.target=-1;refresh()
  get_viewport().set_input_as_handled();return
 var modal:=_combat_modal_root()
 if event is InputEventKey and is_instance_valid(modal):
  if event.pressed and not event.echo:
   if event.physical_keycode==KEY_ESCAPE or (help_open and event.physical_keycode==KEY_H):
    if modal==retreat_confirm:cancel_retreat()
    elif modal==inspector:
     if inspector.details_panel.visible:inspector._close_details()
     else:toggle_inspection()
    else:_toggle_help()
    get_viewport().set_input_as_handled();return
   if event.physical_keycode==KEY_TAB:
    var controls:=_combat_focusables(modal)
    if not controls.is_empty():
     var index:=controls.find(get_viewport().gui_get_focus_owner())
     controls[posmod(index+(-1 if event.shift_pressed else 1),controls.size())].grab_focus()
    get_viewport().set_input_as_handled();return
  # Let the native focused button own one Enter/Space gesture, never the
  # underlying field shortcut. All other gameplay keys are modal-inert.
  var focus:=get_viewport().gui_get_focus_owner()
  if event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and is_instance_valid(focus) and modal.is_ancestor_of(focus) and not event.echo:return
  get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE:
  armed_action="";controller.reset_action();controller.target=-1;refresh()
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE and combat_perks.visible:
  combat_perks.hide();action_buttons.more.grab_focus();get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE and reserve_panel.visible:
  reserve_panel.hide();action_buttons.reserves.grab_focus();get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.physical_keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER]:
  var focus:=get_viewport().gui_get_focus_owner()
  if focus is Button and focus.is_visible_in_tree():
   # Enter keeps keyboard/accessibility activation. Space belongs to Wait.
   # Consume both edges so native ui_accept cannot activate a second time.
   if event.pressed and not event.echo and not focus.disabled and not (event.ctrl_pressed or event.alt_pressed or event.shift_pressed or event.meta_pressed):focus.pressed.emit()
   get_viewport().set_input_as_handled();return
 super._input(event)

# Presentation intent is distinct from the legacy default Basic quote.
var armed_action := ""
var inspected_id := -1
var _armed_actor := -2
var _armed_round := -1
var _armed_selected := -2
var _inspection_owner := -2
var _inspection_round := -1
var _inspection_selected := -2
var _inspection_stamp := 0
var _inspection_actor: Node
func _sync_inspection_intent() -> void:
 if not built:return
 if battle.active_id!=_armed_actor or battle.round_no!=_armed_round or controller.selected!=_armed_selected or controller.action!=armed_action:
  armed_action=""
func _inspection_visibility_changed() -> void:
 if inspector_open():return
 inspected_id=-1;_inspection_actor=null
 _restore_combat_focus(action_buttons.equipment)
func _validate_inspection() -> void:
 if inspected_id<0 or not inspector_open():return
 var valid:bool=built and inspected_id<battle.units.size() and battle.active_id==_inspection_owner and battle.round_no==_inspection_round and controller.selected==_inspection_selected
 if valid:
  var unit:Dictionary=battle.units[inspected_id]
  valid=battle.living(unit) and battle.unit_visible(0,inspected_id) and hash(unit)==_inspection_stamp and actors.get(inspected_id)==_inspection_actor and is_instance_valid(_inspection_actor) and _inspection_actor.visible
 if not valid:inspector.hide()
func _process(delta:float) -> void:
 if built and controller.sync_movement():refresh()
 var was_inspection:bool=inspector_open()
 _validate_inspection();_sync_inspection_intent()
 if was_inspection and not inspector_open():
  _refresh_pointer_hover();return
 super._process(delta)
 # Re-quote stationary pointers too: activation, AP/ammo, sight, actor tween,
 # camera and overlays can all change without another mouse-motion event.
 _refresh_pointer_hover()

func _inspect_enemy(id: int) -> void:
 if _reserve_modal() or id<0 or id>=battle.units.size():return
 var unit:Dictionary=battle.units[id]
 if unit.side==0 or not battle.living(unit) or not battle.unit_visible(0,id):return
 if not actors.has(id) or not is_instance_valid(actors[id]) or not actors[id].visible:return
 reserve_panel.hide();combat_perks.hide();_combat_focus_return=get_viewport().gui_get_focus_owner()
 inspected_id=id;_inspection_owner=battle.active_id;_inspection_round=battle.round_no;_inspection_selected=controller.selected
 _inspection_stamp=hash(unit);_inspection_actor=actors[id]
 inspector.present(unit,battle.armor_catalog,actors[id],battle)

func _unhandled_input(event: InputEvent) -> void:
 if _company_modal():
  get_viewport().set_input_as_handled();return
 if _combat_modal_root()!=null:return
 _sync_inspection_intent()
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and _commands_available():
  var id:int=pick_unit(event.position)
  if id>=0 and battle.units[id].side!=0 and armed_action.is_empty():
   controller.cancel_movement();_inspect_enemy(id);get_viewport().set_input_as_handled();return
  if id>=0 and battle.units[id].side!=0 and armed_action=="shield_bash":
   if controller.select_target(id):_execute("shield_bash")
   get_viewport().set_input_as_handled();return
  if id<0 and controller.action not in ["footwork","rotation"]:
   var cell:=pick_hex(event.position)
   if controller.action=="shield_bash":controller.reset_action();controller.target=-1
   if not _try_terrain_work(cell):
    armed_action=""
    controller.movement_click(cell)
   get_viewport().set_input_as_handled();return
 super._unhandled_input(event)

func _try_terrain_work(cell: Vector2i) -> bool:
 if armed_action!="special" or not controller.available():return false
 var work:=_visible_terrain_work(cell)
 if work.is_empty() or work.hp<=0:return false
 var id:int=controller.selected
 var quote:Dictionary=battle.action_quote(id,"terrain_work",-1,cell)
 controller.cancel_movement()
 controller.target=-1 # Execute must not hit a previously selected unit after aiming at ground.
 if not quote.legal:
  controller.notice="Cannot swing · see the hex hover."
  controller.changed.emit()
  return true
 var actor:Node3D=actors.get(id)
 if not is_instance_valid(actor) or not actor.is_visible_in_tree():return true
 actor.play_attack(to_global(tile_world(cell))-actor.global_position)
 var delay:float=actor.attack_contact_delay() if actor.has_method("attack_contact_delay") else 0.0
 _terrain_swing={"battle":battle,"actor":actor.get_instance_id(),"id":id,"round":battle.round_no,
  "origin":battle.pos(battle.units[id]),"weapon":battle.units[id].arms.weapon.duplicate(),"cell":cell}
 controller.notice="Winding up…"
 controller.changed.emit()
 # Owned by this mounted field. A retired field cannot finish the payment.
 var swing:=create_tween()
 swing.tween_interval(delay if delay>0.0 else 0.19)
 swing.tween_callback(_finish_terrain_swing)
 return true

func impact_pending() -> bool:
 return not _terrain_swing.is_empty() or super.impact_pending()

func _finish_terrain_swing() -> void:
 var swing:=_terrain_swing
 _terrain_swing={}
 var id:int=swing.id
 var actor:Node3D=actors.get(id)
 var current:bool=is_visible_in_tree() and swing.battle==battle and battle.active_id==id and battle.round_no==swing.round and controller.selected==id and not _reserve_modal()
 current=current and is_instance_valid(actor) and actor.get_instance_id()==swing.actor and actor.is_visible_in_tree()
 if current:
  current=battle.pos(battle.units[id])==swing.origin and battle.units[id].arms.weapon==swing.weapon
 var paid:bool=current and battle.perform_action(id,"terrain_work",-1,swing.cell)
 controller.notice=WORK_NOTICE_PAID if paid else WORK_NOTICE_FAILED
 controller.changed.emit() # Existing field refresh updates HUD, fog and movement cues.

func toggle_inspection() -> void:
 if inspector_open():
  inspector.hide();return # Enemy inspection keeps its own existing close route.
 var owner=get_parent()
 if owner != null and owner.has_method("_open_battle_company"):
  owner._open_battle_company();return
 if help_open:return
 var was_open:=inspector_open()
 if not was_open:
  _retire_movement()
  reserve_panel.hide();combat_perks.hide();_combat_focus_return=get_viewport().gui_get_focus_owner()
 super.toggle_inspection()
 if inspector_open():
  var controls:=_combat_focusables(inspector)
  if not controls.is_empty():controls[0].grab_focus()
 elif was_open:_restore_combat_focus(action_buttons.equipment)

func request_retreat() -> void:
 if impact_pending() or _company_modal() or help_open or inspector_open():return
 _retire_movement()
 reserve_panel.hide();combat_perks.hide();_combat_focus_return=get_viewport().gui_get_focus_owner()
 super.request_retreat()
 if is_instance_valid(retreat_confirm) and retreat_confirm.visible:retreat_no.grab_focus()

func confirm_retreat() -> void:
 if _company_modal():return
 super.confirm_retreat()

func cancel_retreat() -> void:
 super.cancel_retreat()
 _restore_combat_focus(action_buttons.retreat)

func _update_hover() -> void:
 _update_terrain_hover(true)

func _feedback(event:Dictionary) -> void:
 if event.get("kind","")!="shield_bash":
  super._feedback(event);return
 if 0 in event.audience and battle.unit_visible(0,int(event.id)):
  _publish_impact({"id":event.id,"kind":"shield_bash","text":"KNOCKED BACK" if event.hit else "BASH MISSED"})

func _attack_from_hud() -> void:
 if _reserve_modal(): return
 controller.attack_target()

func _end_from_hud() -> void:
 if _reserve_modal(): return
 controller.end_player_turn()

func _retire_movement() -> void:
 controller.cancel_movement()
 if built:refresh()

func _company_modal() -> bool:
 var owner=get_parent()
 return owner != null and owner.has_method("_battle_company_open") and owner._battle_company_open()
func _commands_available() -> bool:
 return not _company_modal() and super._commands_available()
func _reserve_modal() -> bool:
 return impact_pending() or _company_modal() or help_open or inspector_open() or (is_instance_valid(retreat_confirm) and retreat_confirm.visible)

func _reserve_reason(slot: String) -> String:
 if _reserve_modal(): return "Close the open overlay before switching pocket equipment."
 var id: int = controller.selected
 if id < 0 or id >= battle.units.size() or battle.units[id].side != 0: return "Select your active fighter."
 return battle.switch_reason(id,slot)

func _toggle_reserves() -> void:
 if _reserve_modal(): return
 _retire_movement()
 combat_perks.hide()
 _refresh_reserves()
 reserve_panel.visible = not reserve_panel.visible
 if reserve_panel.visible:
  for button: Button in reserve_switch_buttons.values():
   if not button.disabled:button.grab_focus();break
 else:action_buttons.reserves.grab_focus()

func _refresh_reserves() -> void:
 if not is_instance_valid(reserve_panel): return
 var id: int = controller.selected
 var slots: Array = []
 if id >= 0 and id < battle.units.size() and battle.units[id].side == 0:
  slots = load("res://src/arsenal.gd").bag_slots(battle.units[id])
 for slot in reserve_switch_buttons.keys():
  if slot not in slots:
   var old: Button = reserve_switch_buttons[slot]
   reserve_column.remove_child(old)
   old.queue_free()
   reserve_switch_buttons.erase(slot)
 var any_item := false
 for slot: String in slots:
  if not reserve_switch_buttons.has(slot):
   var button := _button("",_switch_reserve.bind(slot))
   button.add_theme_font_size_override("font_size",13)
   reserve_column.add_child(button)
   reserve_switch_buttons[slot] = button
  var button: Button = reserve_switch_buttons[slot]
  var unit: Dictionary = battle.units[id]
  var item: Dictionary = unit.arms.get(slot,{})
  var definition: Dictionary = load("res://src/named_equipment.gd").definition(item,battle.armor_catalog)
  var reason := _reserve_reason(slot)
  button.text = "Pocket %s · %s" % [slot.trim_prefix("carry"),definition.get("name","Empty")]
  if not item.is_empty():
   any_item = true
   button.text += " · %d AP / %d fatigue" % [battle.switch_ap(unit,slot),battle.switch_fatigue()]
  button.tooltip_text = Inventory.item_details(item,battle.armor_catalog)+( "\n"+reason if not reason.is_empty() else "")
  button.disabled = not reason.is_empty()
 action_buttons.reserves.disabled = not any_item or _reserve_modal() or not battle.result.is_empty()
 action_buttons.reserves.tooltip_text = "Switch the selected fighter’s owned pocket equipment during their activation. The displayed AP/fatigue cost applies. Fill pockets in camp."
 if _reserve_modal() or battle.result != "": reserve_panel.hide()

func _switch_reserve(slot: String) -> void:
 if not _reserve_reason(slot).is_empty(): return
 controller.cancel_movement()
 var accepted: bool = battle.switch_carried(controller.selected,slot)
 if accepted:
  controller.notice = "Pocket equipment switched; AP and fatigue paid."
  reserve_panel.hide()
 refresh()

var _presented_round := 0
var _round_cue_timer: Timer

func _refresh_round_status() -> void:
 var previous := _presented_round
 _presented_round=battle.round_no
 var showing := _round_cue_timer!=null and not _round_cue_timer.is_stopped()
 # The first refresh seeds the ordinary label. Only a real, nonterminal
 # round advance can start the cue, irrespective of who activates next.
 if not battle.result.is_empty() or _presented_round<previous:
  if showing:
   _round_cue_timer.stop()
   _clear_round_cue()
  else:status_label.text="Round %d"%_presented_round
  return
 if previous>0 and _presented_round>previous:
  if _round_cue_timer==null:
   _round_cue_timer=Timer.new()
   _round_cue_timer.one_shot=true
   add_child(_round_cue_timer)
   _round_cue_timer.timeout.connect(_clear_round_cue)
  _round_cue_timer.start(1.35)
  status_label.add_theme_stylebox_override("normal",CombatStyle.panel(Color("5b4328"),CombatStyle.GOLD,3))
  showing=true
 status_label.text=("NEW ROUND %d" if showing else "Round %d")%_presented_round

func _clear_round_cue() -> void:
 status_label.remove_theme_stylebox_override("normal")
 status_label.text="Round %d"%_presented_round

func _update_hud() -> void:
 # This public formatter intentionally stops the raw superchain at
 # map_visibility. Never invoke the older Company/Combat HUD directly.
 super._update_hud()
 _refresh_reserves()
 if not is_instance_valid(combat_dock):return
 status_label.tooltip_text=status_label.text
 _refresh_round_status()
 kit_label.text=str(session.deployed_map.get("title","Encounter")).split(" — Seed")[0]
 for unit_id in roster_buttons:roster_buttons[unit_id].hide()
 var id:int=controller.selected
 if id>=0 and id<battle.units.size() and battle.units[id].side==0:
  unit_label.text=("Active · " if id==battle.active_id and battle.side==0 else "Inspecting · ")+unit_label.text
  for action in ["footwork","rotation","indomitable"]:action_buttons[action].visible=action in battle.units[id].perks
 else:
  unit_label.text="Select a fighter."
  for action in ["footwork","rotation","indomitable"]:action_buttons[action].hide()
 # Reformat only the already-public quote, excluding inherited art/debug prose.
 target_label.text=_quote_text(_last_quote) if not _last_quote.is_empty() else "Select an action."
 var bash:Button=action_buttons.shield_bash
 var bash_quote:Dictionary=battle.action_quote(id,"shield_bash")
 bash.text="Bash · %d AP"%bash_quote.ap
 bash.disabled=battle.side!=0 or not bash_quote.ready
 bash.tooltip_text="Knock Back · %d AP / %d fatigue\n%s"%[bash_quote.ap,bash_quote.fatigue,
  bash_quote.reason if bash.disabled else "Click an adjacent enemy. On hit, pushes them one hex away and breaks their stance. No HP or armour damage."]
 bash.add_theme_stylebox_override("normal",_bash_style(armed_action=="shield_bash"))
 combat_target_name.text="Target · select an enemy"
 if controller.target>=0 and battle.unit_visible(0,controller.target):
  combat_target_name.text="Target · "+str(battle.units[controller.target].name)
 combat_target_name.clip_text=true
 action_buttons.attack.text="Execute [Enter]"
 action_buttons.end.text="END TURN"
 action_buttons.end.tooltip_text="End the current activation [F]."
 action_buttons.reserves.text="Pockets…"
 combat_selected_identity.text=("Active · " if id==battle.active_id else "Inspecting · ")+str(battle.units[id].name) if id>=0 and battle.unit_visible(0,id) else "Select a known fighter"
 if controller.target>=0 and battle.unit_visible(0,controller.target):combat_selected_identity.text+="  →  "+str(battle.units[controller.target].name)
 combat_selected_identity.tooltip_text=unit_label.text
 var movement:Dictionary=controller.movement_preview()
 if movement.valid:
  target_label.text="MOVE · %d AP / %d fatigue\n%s"%[movement.cost,movement.fatigue,movement.danger_text if movement.known_danger else "Click endpoint again to confirm · other tiles add waypoints"]
 if controller.action!="shield_bash" and controller.target>=0 and battle.unit_visible(0,controller.target):
  var target: Dictionary = battle.units[controller.target]
  if target.side != 0 and battle.living(target):
   var shield: Dictionary = target.get("arms",{}).get("shield",{})
   var status: String = " · SHIELD BROKEN" if not shield.is_empty() and int(shield.condition)<=0 else ""
   target_label.text = str(target.title)+status+" · "+preload("res://morale_flags/readout.gd").current_name(battle,int(target.id))+"\n"+target_label.text
   target_label.tooltip_text = "Fixed appearance; combat equipment is authoritative. Pictured gear is not recovered."
 target_label.tooltip_text=target_label.text
 notice_label.tooltip_text=notice_label.text
 _refresh_rally_control(id)
 var any_perk:=false
 for key in ["footwork","rotation","indomitable","rally_the_troops"]:any_perk=any_perk or action_buttons[key].visible
 action_buttons.more.visible=any_perk
 if _combat_perk_actor!=id or not any_perk or _reserve_modal():combat_perks.hide()
 _combat_perk_actor=id
 for key in ["basic","special","guard","recover","wait"]:
  var button:Button=action_buttons[key]
  if " · " in button.text:button.text=button.text.split(" · ")[0]
  if key=="guard":button.text="Shieldwall"
  button.modulate=Color.WHITE
  button.add_theme_stylebox_override("normal",CombatSkin.button(false,armed_action==key,false))
 _refresh_combat_identity()
 load("res://crossbows/ui.gd").present_combat(self,id)
 var tip_font:=hud.get_theme_font("font","TooltipLabel")
 var tip_size:=hud.get_theme_font_size("font_size","TooltipLabel")
 for key:String in AbilityHelp.ACTIONS:
  action_buttons[key].tooltip_text=AbilityHelp.wrap(AbilityHelp.copy(self,key),tip_font,tip_size)
 # Basic stays class-owned. Special may show the current admitted ground action.
 var icon:=WeaponSkillIcons.texture("basic",_skill_weapon())
 if action_buttons.basic.icon!=icon:action_buttons.basic.icon=icon
 _paint_special_skill()
 _work_dock_base=target_label.text
 _work_dock_base_tooltip=target_label.tooltip_text
 _work_dock_active=false

func _skill_weapon() -> String:
 var id:int=controller.selected
 return battle.units[id].weapon if id>=0 and id<battle.units.size() and battle.units[id].side==0 else ""

func _paint_special_skill(work_kind:String="") -> void:
 var button:Button=action_buttons.get("special")
 if not is_instance_valid(button):return
 var icon:=WeaponSkillIcons.terrain_texture(work_kind)
 if icon==null:
  var weapon:=_skill_weapon()
  # The current perk-rules Battle permanently refuses Riposte for these swords.
  # Keep the inherited slot, copy and input semantics; do not illustrate a skill they lack.
  if not (battle.perk_rules and weapon in battle.Arsenal.TWO_HANDS and battle.Arsenal.family(weapon)=="sword"):
   icon=WeaponSkillIcons.texture("special",weapon)
 if button.icon!=icon:button.icon=icon

func _finish_markers() -> void:
 var preview:Dictionary=controller.movement_preview()
 if preview.valid:
  var previous:=Vector2i(preview.origin.q,preview.origin.r)
  for index in preview.path.size():
   var row:Dictionary=preview.path[index];var cell:=Vector2i(row.q,row.r)
   var forward:Vector3=(tile_world(cell)-tile_world(previous));forward.y=0;forward=forward.normalized()
   var across:=Vector3(-forward.z,0,forward.x)
   var color:=Color(0.98,0.95,0.83,0.95)
   if index in preview.risk_steps:color=Color(0.95,0.61,0.24,0.92)
   if {"q":cell.x,"r":cell.y} in preview.waypoints:color=Color(1.0,0.76,0.25,0.98)
   for foot in [-1,1]:
    var center:Vector3=tile_world(cell)+Vector3.UP*0.065+across*0.17*foot+forward*0.07*foot
    # Separate heel and broad rounded toe: paired actual ground-space soles.
    for shape in [[Vector2(-0.065,-0.24),Vector2(0.065,-0.24),Vector2(0.065,-0.10),Vector2(-0.065,-0.10)],[Vector2(-0.075,-0.055),Vector2(0.075,-0.055),Vector2(0.09,0.16),Vector2(0.045,0.25),Vector2(-0.045,0.25),Vector2(-0.09,0.16)]]:
     for i in range(1,shape.size()-1):
      for point:Vector2 in [shape[0],shape[i],shape[i+1]]:
       _fill_vertices.append(center+across*point.x+forward*point.y);_fill_colors.append(color)
   previous=cell
 super._finish_markers()

func observation() -> Dictionary:
 _validate_inspection();_sync_inspection_intent()
 var out := super.observation()
 # The inherited profiles describe static terrain. Only these mutable cells
 # need last-witnessed tile data when explored but not currently visible.
 if terrain!=null and terrain.has_method("work_tile_keys"):
  for key:String in terrain.work_tile_keys():
   if not out.tile_profiles.has(key) or key in out.fog.visible_tiles:continue
   var tile:Dictionary=terrain.remembered_work_tile(key,{}).duplicate()
   tile.obstacle=tile.get("obstacle","");tile.blocked=tile.get("blocked",false);tile.vision_blocking=tile.get("vision_blocking",false);tile.cover=tile.get("cover",false)
   var base:Array=TerrainRules.COSTS.get(tile.terrain,[999,999])
   tile.profile={"ap":base[0],"fatigue":base[1],"reason":TerrainRules.tile_reason(tile)}
   out.tile_profiles[key]=tile
 # Extend only rows already admitted by the retained sight projection.
 for row: Dictionary in out.units:
  var unit: Dictionary = battle.units[int(row.id)]
  row.merge(Inventory.unit_observation(unit,battle),true)
  var actor = actors.get(int(row.id))
  row["preview_texture_id"] = actor.preview_texture().get_instance_id() if is_instance_valid(actor) and actor.preview_texture() != null else 0
 out["movement_preview"]=controller.movement_preview()
 out["last_traversed"]={}
 var receipt:Dictionary=battle.last_traversed
 if not receipt.is_empty() and battle.units[receipt.actor].side==0:
  out.last_traversed={"actor":receipt.actor,"origin":{"q":receipt.origin.x,"r":receipt.origin.y},"path":controller.MovementPlan.cells(receipt.path),"serial":receipt.serial}
 out["armed_action"]=armed_action;out["inspected_id"]=inspected_id if inspector_open() else -1
 out["reserve_panel_open"] = is_instance_valid(reserve_panel) and reserve_panel.visible
 out["reserve_switches"] = {}
 if out.reserve_panel_open:
  for slot: String in reserve_switch_buttons:
   var button: Button = reserve_switch_buttons[slot]
   var r := button.get_global_rect()
   out.buttons["reserve_"+slot] = [r.get_center().x,r.get_center().y]
   out.reserve_switches[slot] = {"disabled":button.disabled,"text":button.text,"tooltip":button.tooltip_text,"rect":[r.position.x,r.position.y,r.size.x,r.size.y]}
 if inspector_open():
  out["inventory_inspection"] = {"stats":inspector.stats_label.text,"cards":{},"diagnostics":inspector.art_note.text,"carried":inspector.carried_label.text}
  for slot: String in inspector.slot_labels:out.inventory_inspection.cards[slot] = inspector.slot_labels[slot].text
 return out
