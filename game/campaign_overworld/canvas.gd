extends "res://src/region_canvas.gd"
var painter
# Local presentation history: never serialized or used by fog/navigation.
var _travel_sample: Dictionary = {}
var _travel_points: Array = []
var _travel_elapsed = 0.0
var _travel_period = 0.25
var _travel_focused = true
func _travel_running() -> bool:
 return _travel_focused and host.visible and host.process_mode != Node.PROCESS_MODE_DISABLED and host.world_controls_available() and not campaign.overworld.paused and not campaign.overworld.path.is_empty() and campaign.overworld.pending.is_empty() and campaign.encounter.is_empty()
func _travel_state() -> Dictionary:
 var ow = campaign.overworld
 return {"campaign":campaign,"overworld":ow,"position":ow.position,"path":ow.path.duplicate(),"destination":ow.destination,"paused":ow.paused,"speed":ow.speed,"hour":ow.hour,"day":campaign.day,"running":_travel_running()}
func reset_travel_presentation() -> void:
 _travel_sample.clear(); _travel_points.clear(); _travel_elapsed = 0.0
func travel_begin_frame() -> Dictionary:
 var state = _travel_state()
 if state != _travel_sample: reset_travel_presentation()
 _travel_sample = state
 return state
func travel_end_frame(delta: float, before: Dictionary) -> void:
 var state = _travel_state()
 if not state.running or not before.running or state.campaign != before.campaign or state.overworld != before.overworld or state.speed != before.speed:
  reset_travel_presentation(); _travel_sample = state; return
 var prior: Array = before.path
 var remaining: Array = state.path
 var consumed = prior.size()-remaining.size()
 if consumed < 0 or prior.slice(consumed) != remaining or state.destination != before.destination:
  reset_travel_presentation(); _travel_sample = state; return
 if state.position != before.position:
  # Only a confirmed authority step may create a segment; no extrapolation.
  if state.hour == before.hour and state.day == before.day:
   reset_travel_presentation(); _travel_sample = state; return
  _travel_points = [before.position]
  _travel_points.append_array(prior.slice(0,consumed))
  _travel_points.append(state.position)
  _travel_elapsed = 0.0
  _travel_period = campaign.overworld.STEP / campaign.overworld.HOURS_PER_SECOND / float(state.speed)
 elif delta > 0.0 and is_finite(delta):
  _travel_elapsed = minf(_travel_period,_travel_elapsed+delta)
 _travel_sample = state
func rendered_party_position() -> Vector2:
 # Validate again at draw time: contact/pause/order can occur after processing.
 if _travel_state() != _travel_sample or not _travel_running():
  reset_travel_presentation()
  return campaign.overworld.position
 if _travel_points.size() < 2: return campaign.overworld.position
 var length = 0.0
 for i in range(1,_travel_points.size()): length += _travel_points[i-1].distance_to(_travel_points[i])
 var distance = length*clampf(_travel_elapsed/_travel_period,0.0,1.0)
 for i in range(1,_travel_points.size()):
  var a: Vector2 = _travel_points[i-1]
  var b: Vector2 = _travel_points[i]
  var segment = a.distance_to(b)
  if distance <= segment: return a.move_toward(b,distance)
  distance -= segment
 return campaign.overworld.position
func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
  _travel_focused = false; reset_travel_presentation()
 elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
  _travel_focused = true; reset_travel_presentation()

var landscape:
 get: return painter.landscape
var ground_texture:
 get: return painter.ground_texture
var textures:
 get: return painter.textures
func prepare() -> void:
 if painter == null:
  painter = preload("res://campaign_overworld/painter.gd").new()
  painter.canvas = self; painter.show_behind_parent = true
  add_child(painter)
 painter.prepare()
func painted_observation() -> Dictionary:
 return {"enabled":true,"recipe":"campaign_painted_overworld_v1","generation":0 if painter==null else painter.generation_serial,"cache":{} if painter==null else painter.resource_tokens(),"native_presented":false if painter==null else painter.presented_generation==painter.generation_serial,"assets_ready":false if painter==null else painter.missing_art.is_empty()}
func landmark_rect(id: String) -> Rect2:
 if painter == null: return Rect2()
 for stamp in painter.stamps:
  if stamp.place.get("id","")==id and stamp.knowledge>0: return stamp.rect
 return Rect2()
func _draw() -> void:
 # Hover belongs to the current camera/modal/pointer frame, not the last motion event.
 var pointer: Vector2=host.get_global_mouse_position()
 hovered_marker=hover_marker_at(pointer) if host.world_controls_available() and host.world_view and not host.iron.blocks_map(host,pointer) else ""
 buttons.clear(); map_labels.clear()
 if campaign.region.get("generator") != 3: return
 prepare()
 painter.position = camera.RECT.size/2-camera.center*camera.zoom
 painter.scale = Vector2.ONE*camera.zoom
 painter.queue_redraw()
 draw_set_transform(painter.position,0,painter.scale)
 # Painter owns the knowledge-qualified art and inward-only fog pass.
 preload("res://campaign_overworld/annotations.gd").draw_map(self)
 preload("res://src/footprint_view.gd").draw_map(self)
 preload("res://src/traffic_view.gd").draw_map(self)
 preload("res://campaign_overworld/annotations.gd").draw_farms(self)
 preload("res://src/guard_view.gd").draw_map(self)
 draw_parties()
 preload("res://campaign_overworld/annotations.gd").draw_sites(self)
 preload("res://src/regional_news_view.gd").draw_landmarks(self)
 draw_labels()
 preload("res://engraved_world/atlas_ink.gd").compass(self)

func party_paint_rect() -> Rect2:
 if painter==null or not textures.has("wagon_01"): return Rect2()
 var painting: Texture2D=textures.wagon_01
 var dimensions=Vector2(49,49*painting.get_height()/float(painting.get_width()))
 return Rect2(rendered_party_position()-Vector2(dimensions.x*0.5,dimensions.y),dimensions)
var hovered_marker: String=""
func marker_highlighted(key: String) -> bool:
 if key.begins_with("convoy_") and host.iron.detail and world_selected=="wagon:"+key.trim_prefix("convoy_"):return true
 return hovered_marker==key or (key.begins_with("place_") and world_selected==key.trim_prefix("place_"))
func hover_marker_at(screen: Vector2) -> String:
 var key: String=camera.marker_at(host,screen)
 return key if not key.is_empty() and host.buttons[key].enabled else ""
func centered(text: String,at: Vector2,size: int,color: Color,fancy: bool=false) -> void:
 # Secondary names appear on actual selection/hover; town names stay visible.
 if text in ["Caravan","Patrol","FARM"]:return
 var priority=0
 for place in campaign.region.locations:
  if text!=place.name:continue
  if place.kind!="town" and not marker_highlighted("place_"+place.id):return
  fancy=true;priority=10 if place.kind=="town" else 5
 for landmark in campaign.news.navigation.visible(campaign):
  if text==landmark.name:fancy=true;size=maxi(size,12);priority=2
 for id in campaign.dungeons.sites:
  if text!=campaign.dungeons.sites[id].place.name:continue
  if not marker_highlighted("place_"+id):return
  fancy=true;priority=5
 super.centered(text,at,size,color,fancy)
 if not map_labels.is_empty():map_labels.back()["priority"]=priority

func draw_parties() -> void:
 var ow = campaign.overworld
 for party in ow.friendly_parties(campaign.world,campaign.traffic):
  var p: Vector2 = party.position
  if p.distance_to(ow.position) > ow.sight(): continue
  var tint = GOLD if party.kind == "wagon" else BLUE
  if campaign.traffic.enabled and party.kind == "wagon" and campaign.traffic.wagons[party.id].carried: tint = RED
  if party.kind == "wagon":
   preload("res://engraved_world/atlas_ink.gd").caravan_mark(self,p,tint,marker_highlighted("convoy_"+party.id))
  else:
   draw_polyline(PackedVector2Array([p+Vector2(0,-7),p+Vector2(5,0),p+Vector2(0,7),p+Vector2(-5,0),p+Vector2(0,-7)]),tint,1.3,true)
  centered(("RELIEF " if campaign.rebuilding.enabled and campaign.rebuilding.shipments.has(party.id) else "")+("Caravan" if party.kind == "wagon" else "Patrol"),p+Vector2(0,-15),10,tint)
  if party.kind == "wagon": buttons["convoy_"+party.id] = {"rect":Rect2(p-Vector2.ONE*11,Vector2.ONE*22),"enabled":true}
 for scout in ow.scouts.values():
  if scout.defeated or scout.position.distance_to(ow.position) > ow.sight(): continue
  var p: Vector2 = scout.position
  preload("res://campaign_overworld/annotations.gd").draw_marker(self,"scout",p,RED,marker_highlighted("scout_"+scout.id))
  var scouts_name = campaign.enemy_label(scout.site,campaign.world.camps[scout.site].strength,"scout").to_upper()
  var caption = "PURSUING" if scout.mode == "pursuit" else "RAIDER SCOUTS"
  if campaign.traffic.enabled and campaign.traffic.missions.has(scout.id):
   caption = "HAULING LOOT" if campaign.traffic.wagons[campaign.traffic.missions[scout.id]].carried else "RAIDING PARTY"
  if campaign.bandits.enabled: caption = campaign.bandits.caption(scout.id)
  if not campaign.guards.engaged(scout.id): centered(caption.replace("RETURNING HOME","RETURNING").replace("HUNTING YOU","HUNTING") if campaign.bandits.enabled else scouts_name+" · "+str(campaign.enemy_count(scout.site,maxi(1,int(campaign.world.camps[scout.site].strength)-1),"scout")),p+Vector2(0,-18),10,RED)
  buttons["scout_"+scout.id] = {"rect":Rect2(p-Vector2.ONE*12,Vector2.ONE*24),"enabled":true}
 draw_player_party(rendered_party_position())

func draw_player_party(p: Vector2) -> void:
 if textures.has("wagon_01"):
  draw_texture_rect(textures.wagon_01,party_paint_rect(),false)
 else:
  draw_circle(p,8,PAPER)
 for i in 4:
  draw_arc(p+Vector2(0,3),24,i*PI*0.5+0.08,i*PI*0.5+0.9,10,Color(0.84,0.78,0.53,0.72),1.3,true)
 var mast=p+Vector2(-15,-44)
 draw_line(p+Vector2(-15,-8),mast,Color("b8ad88"),1.5,true)
 draw_colored_polygon(PackedVector2Array([mast,mast+Vector2(17,3),mast+Vector2(14,14),mast+Vector2(0,11)]),Color("4c6a64"))

func atlas_label_layout() -> Array:
 # Screen-sized lettering, with the existing known-marker collision policy.
 var layout: Array=[]
 var occupied: Array=[]
 for control in buttons.values():
  occupied.append(Rect2(camera.world_to_screen(control.rect.position)-camera.RECT.position,control.rect.size*camera.zoom).grow(3))
 var rows: Array=map_labels.duplicate()
 rows.sort_custom(func(a,b):return int(a.get("priority",0))>int(b.get("priority",0)))
 for source in rows:
  var row: Dictionary=source.duplicate()
  var f: Font=serif if row.fancy else font
  var anchor: Vector2=camera.world_to_screen(row.at)-camera.RECT.position
  var width: float=f.get_string_size(row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.size).x+12
  var height: float=f.get_height(row.size)+4
  var offsets: Array=[Vector2.ZERO]
  for i in range(1,8):
   for dx in [0,-100,100]:
    offsets.append(Vector2(dx,i*23));offsets.append(Vector2(dx,-i*23))
  for offset in offsets:
   var rect=Rect2(anchor+offset-Vector2(width/2,f.get_ascent(row.size)+2),Vector2(width,height))
   if not Rect2(Vector2(8,8),camera.RECT.size-Vector2(16,16)).encloses(rect):continue
   if layout.any(func(other):return other.rect.grow(3).intersects(rect)) or occupied.any(func(other):return other.intersects(rect)):continue
   row["rect"]=rect;row["font"]=f;row["anchor"]=anchor
   row["baseline"]=rect.position+Vector2(6,f.get_ascent(row.size)+2)
   layout.append(row);break
 return layout

func draw_labels() -> void:
 draw_set_transform(Vector2.ZERO)
 label_rects.clear();drawn_labels.clear()
 for row in atlas_label_layout():
  label_rects.append(row.rect);drawn_labels.append(row.text)
  if row.rect.get_center().distance_to(row.anchor)>28:
   draw_line(row.anchor,row.rect.get_center(),Color(0.55,0.53,0.44,0.35),1,true)
  # A soft ink halo keeps the painting visible instead of mounting a black plaque.
  var place_name:bool=row.get("priority",0)>=5
  var halo=Color("e7d9b7") if place_name else Color(0.12,0.15,0.12,0.87)
  draw_string_outline(row.font,row.baseline,row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.size,3,halo)
  draw_string(row.font,row.baseline,row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.size,Color("38392e") if place_name else row.tint)

