extends "res://town_contracts/world_view.gd"
## Only the explicit dungeon branch bypasses the two inherited action fences.
func burial_controls_available() -> bool:
 return visible and not blocked() and world_view and iron.sheet.is_empty() and not vault_journal and not intro and not help and confirmation.is_empty() and not (lineup.opened or perks_view or person_view or armor_view or arms_view or salvage_view or loot_view or service_view or bonds_view or politics_view or trade_view or guide_view or planner_view or record_view or tactics_view or news_view or inspection_view)

func _burial_command(id: String) -> Dictionary:
 var simple := {"dungeon_leave":"leave","dungeon_search":"search","dungeon_rest":"rest","dungeon_up":"up","dungeon_down":"down","dungeon_choice_disarm":"choice_disarm","dungeon_choice_force":"choice_force","dungeon_choice_clear":"choice_clear","dungeon_choice_dig":"choice_dig","dungeon_choice_search":"choice_search"}
 if simple.has(id): return {"action":simple[id],"target":-1}
 for prefix in ["dungeon_room_","dungeon_unlock_"]:
  if not id.begins_with(prefix): continue
  var literal := id.trim_prefix(prefix)
  if not literal.is_valid_int() or int(literal) < 0 or str(int(literal)) != literal: return {}
  var target := int(literal)
  var command := "unlock_vault" if prefix == "dungeon_unlock_" else "move"
  if command == "move" and host != null and host.session.burial_action_reason("inspect_vault",target).is_empty(): command = "inspect_vault"
  return {"action":command,"target":target}
 return {}

func action(id: String) -> void:
 if id == "dungeon_enter":
  if burial_controls_available() and host != null: host._enter_burial(world_selected)
  return
 var command := _burial_command(id)
 if not command.is_empty():
  if burial_controls_available() and host != null: host._burial_action(command.action,command.target)
  return
 # Local Close and genuine rumour retain stock behavior. Unknown dungeon
 # commands still hit both predecessor fences, never a raw Campaign method.
 super.action(id)

func _burial_reason(id: String) -> String:
 if host == null: return "Burial Ruins host required."
 if id == "dungeon_enter": return host.session.burial_enter_reason(world_selected)
 if id == "deploy": return host.session.burial_attack_reason()
 var command := _burial_command(id)
 return "Unsupported burial action." if command.is_empty() else host.session.burial_action_reason(command.action,command.target)

func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
 if id == "dungeon_enter" or not _burial_command(id).is_empty() or (id == "deploy" and campaign.encounter.get("kind") == "dungeon"):
  _burial_button(id,title,rect,enabled and _burial_reason(id).is_empty(),primary)
  return
 super.button(id,title,rect,enabled,primary)

func _burial_button(id: String, title: String, rect: Rect2, enabled: bool, primary: bool) -> void:
 # Exact six-line stock draw helper, bypassing TC's contract-only deploy paint.
 buttons[id] = {"rect":rect, "enabled":enabled}
 var hot = rect.has_point(get_global_mouse_position()) and enabled
 panel(rect, Color("383632") if hot else (Color("302e29") if primary else Color("202326")), GOLD if primary and enabled else Color("4c4942"))
 var fitted = fitted_text(title,rect.size.x-14,14)
 centered(fitted.text, rect.position+Vector2(rect.size.x/2, rect.size.y/2+5), fitted.size, (GOLD if primary else PAPER) if enabled else Color("667064"))
 buttons[id]["title"] = fitted.text

func _draw_world_detail() -> void:
 super._draw_world_detail()
 if burial_controls_available() and iron.detail and campaign.encounter.is_empty() and not campaign.over() and world_selected.begins_with("wagon:") and campaign.traffic.wagons.has(world_selected.trim_prefix("wagon:")):
  preload("res://engraved_world/atlas_ink.gd").site_head(self,"freight")
 if burial_controls_available() and iron.detail and campaign.encounter.is_empty() and not campaign.over() and known_site(world_selected):
  var atlas_place:Dictionary=campaign.node(world_selected)
  var kind:String=atlas_place.get("kind","")
  if kind in ["camp","dungeon","discovery"]:
   preload("res://engraved_world/atlas_ink.gd").site_head(self,"tomb" if kind=="dungeon" else atlas_place.get("feature",kind))
 if burial_controls_available() and known_site(world_selected) and campaign.dungeons.sites.has(world_selected):
  var reason := _burial_reason("dungeon_enter")
  if not reason.is_empty(): label_fit(reason,Vector2(1030,737),350,12,RED)

var _dungeon_ui: Dictionary = {}
var _centred: Dictionary = {}

func _empty_dungeon_ui() -> Dictionary:
 return {"version":1,"surface":"","site":"","title":"","floor":-1,"floor_count":0,"current_room":-1,"nodes":[],"links":[],"current":{},"supplies":{},"costs":[],"pending_room":null,"controls":{},"left":false}

func centered(s: String, p: Vector2, size: int = 16, color: Color = PAPER, display: bool = false) -> void:
 super.centered(s,p,size,color,display)
 _centred[Vector2i(p)] = s

func _draw() -> void:
 _dungeon_ui = _empty_dungeon_ui()
 _centred.clear()
 super._draw()
 if not burial_controls_available(): return
 var d = campaign.dungeons
 var active: bool = d.active != ""
 var entrance: bool = not active and iron.detail and known_site(world_selected) and d.sites.has(world_selected) and (buttons.has("dungeon_enter") or buttons.has("travel"))
 if not active and not entrance: return
 var site: String = d.active if active else world_selected
 var displayed: Dictionary = d.sites[site]
 _dungeon_ui.site = site
 _dungeon_ui.title = displayed.place.name
 _dungeon_ui.floor_count = displayed.floors.size()
 _dungeon_ui.surface = ("locked_door" if dungeon_door >= 0 else "rooms") if active else "entrance"
 _dungeon_ui.left = not active
 _dungeon_ui.supplies = {"crowns":campaign.crowns,"food":campaign.food,"tools":campaign.tools,"medicine":campaign.medicine,"ammunition":campaign.ammunition}
 if active:
  _dungeon_ui.floor = d.floor_index
  _dungeon_ui.current_room = d.room_index
  var rooms: Array = displayed.floors[d.floor_index].rooms
  var seen := {}
  for room: Dictionary in rooms:
   var p: Vector2 = DungeonView.centre(room)
   # Export a node only if its actual title and status were drawn this frame.
   if not _centred.has(Vector2i(p+Vector2(0,-3))) or not _centred.has(Vector2i(p+Vector2(0,23))): continue
   var rect := Rect2(p-Vector2(77,40),Vector2(154,80))
   var title: String = _centred[Vector2i(p+Vector2(0,-3))]
   var status: String = _centred[Vector2i(p+Vector2(0,23))]
   seen[room.id] = true
   _dungeon_ui.nodes.append({"id":room.id,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"center":[p.x,p.y],"visited":room.visited,"current":room.id==d.room_index,"title":title,"status":status})
   var control := "dungeon_room_%d" % room.id
   if buttons.has(control): buttons[control]["title"] = title+" · "+status
  for room: Dictionary in rooms:
   if not seen.has(room.id): continue
   for next in d.links(room.id):
    if next > room.id and seen.has(next): _dungeon_ui.links.append({"from":room.id,"to":next,"shortcut":next not in room.links})
  var lines: Array[String] = []
  var types: Array[String] = []
  for p in _painted_labels:
   if p.x == 1008 and p.y >= 216 and p.y <= 620:
    lines.append(_painted_labels[p])
    if p.y >= 304 and p.y < 490: types.append(_painted_labels[p])
   if p.x == 45 and p.y in [784,811]: _dungeon_ui.costs.append(_painted_labels[p])
  _dungeon_ui.current = {"title":_painted_labels.get(Vector2i(1008,216),_painted_labels.get(Vector2i(1008,217),"")),"lines":lines}
  if buttons.has("deploy"):
   _dungeon_ui.pending_room = {"site":site,"floor":d.floor_index,"room":d.room_index,"title":_dungeon_ui.current.title,"count_label":_painted_labels.get(Vector2i(1008,260),""),"type_labels":types}
 else:
  for p in _painted_labels:
   if p.x == 1030 and p.y >= 470 and p.y < 615: _dungeon_ui.costs.append(_painted_labels[p])
 for id in buttons:
  if id.begins_with("dungeon_") or id in ["deploy","save","load","company","vault_journal","travel"]: _dungeon_ui.controls[id] = _public_control(id)

func observation() -> Dictionary:
 var out := super.observation()
 out["dungeon_ui"] = _dungeon_ui.duplicate(true) if burial_controls_available() else _empty_dungeon_ui()
 if not burial_controls_available():
  for id in out.buttons.keys():
   if id.begins_with("dungeon_") or (id == "deploy" and campaign.encounter.get("kind") == "dungeon"): out.buttons.erase(id)
 if campaign.encounter.get("kind") == "dungeon":
  # The inherited encounter id is a private reward key, not public identity.
  out.pending_contact = {} if out.dungeon_ui.pending_room == null else out.dungeon_ui.pending_room.duplicate(true)
 return out
