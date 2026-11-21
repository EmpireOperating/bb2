extends "res://ui_polish/world_view.gd"
## Reuse the normal Character table and personal tier-tree painters only.
## No world startup, ticking, input dispatcher, campaign command or save path.
var workspace: Control
var _paint_sid := -1
func _ready() -> void:
 font = load("res://assets/sans.ttf");serif = load("res://assets/serif.ttf")
 set_process(false)
func current() -> bool:
 return is_visible_in_tree() and is_instance_valid(workspace) and workspace.battle_read_only and not workspace._host_blocked() and workspace.section in ["character","perks"] and not workspace._person().is_empty()
func blocked() -> bool:return true # All inherited direct command helpers stay closed.
func write_save(_show_notice: bool = true) -> bool:return false
func _process(_delta: float) -> void:pass
func refresh() -> void:queue_redraw()
func present() -> void:
 campaign = workspace.session.campaign; battle = campaign.battle
 camp_selected = workspace.selected_sid;person_offer = ""
 person_view = workspace.section == "character";perks_view = workspace.section == "perks"
 if _paint_sid != camp_selected:
  _paint_sid = camp_selected;perk_choice = "";perk_filter = "All";_keyboard_id = ""
 queue_redraw()
func _draw() -> void:
 buttons.clear()
 if not current():return
 if workspace.section == "character":_draw_person()
 else:_draw_perk_tree()
 _sync_keyboard_focus()
func _allowed(id: String) -> bool:
 if workspace.section == "character":return id in ["person_close","person_perks"]
 return id == "perk_close" or id.begins_with("perk_select_") or id.begins_with("perk_group_")
func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
 super.button(id,title,rect,enabled and _allowed(id),primary)
func action(id: String) -> void:
 if not current() or _paint_sid != workspace.selected_sid or not _allowed(id) or not buttons.get(id,{}).get("enabled",false):return
 if id in ["person_close","perk_close"]:workspace.open_section("equipment")
 elif id == "person_perks":workspace.open_section("perks")
 elif id.begins_with("perk_select_"):
  var choice := id.trim_prefix("perk_select_")
  if choice in workspace._person().perk_pool:perk_choice = choice
 elif id.begins_with("perk_group_"):
  var group := id.trim_prefix("perk_group_")
  if group == "All" or group in workspace._person().perk_groups:perk_filter = group
 queue_redraw()
func _input(event: InputEvent) -> void:
 if not current() or not visible:return
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
  if not Rect2(0,0,1440,900).has_point(point):return
  for id: String in buttons:
   if buttons[id].enabled and buttons[id].rect.has_point(point):action(id);break
  workspace.battle_page_focus.grab_focus()
  get_viewport().set_input_as_handled()
 elif event is InputEventKey and workspace.battle_page_focus.has_focus():
  var code: int = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
  if code not in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:return
  if event.pressed and not event.echo:
   _sync_keyboard_focus()
   var ids := _keyboard_actions()
   if not ids.is_empty():
    if code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:_keyboard_id = str(ids[posmod(ids.find(_keyboard_id)+(-1 if code in [KEY_LEFT,KEY_UP] else 1),ids.size())])
    else:action(_keyboard_id)
   queue_redraw()
  get_viewport().set_input_as_handled()
