extends "res://burial_ruins/main.gd"
const GameUI = preload("res://ui_polish/style.gd")
const PlayerWorkflows = preload("res://company_town/player_workflows.gd")
var _overlay_prior_focus: Control
var battle_report: Control
## One world/session authority; Company is a mounted between-battle projection.
var outfitting: Control
var _parked_company: Control
var _memorial: Control
var _company_return_context: Dictionary = {}
var _battle_company_field: Node3D
var _battle_company_mode: int
var _battle_company_focus: Control
var _battle_company_context: Dictionary = {}
func _battle_company_open() -> bool:
 return not _battle_company_context.is_empty()
func _battle_company_current() -> bool:
 if not _battle_company_open() or not is_instance_valid(_battle_company_field) or not is_instance_valid(outfitting):return false
 if not _battle_company_field.is_inside_tree() or not outfitting.is_inside_tree() or not outfitting.visible or outfitting.is_queued_for_deletion():return false
 return field == _battle_company_field and session == _battle_company_context.session and session.campaign == _battle_company_context.campaign and session.campaign.phase == "battle" and field.session == session and field.battle == _battle_company_context.battle and field.battle.result.is_empty() and not error_panel.visible and not aftermath_panel.visible
func _battle_company_back(owner_id: int) -> void:
 if is_instance_valid(outfitting) and outfitting.get_instance_id() == owner_id and _battle_company_open():_close_battle_company()
func _open_battle_company() -> void:
 if session == null or session.campaign.phase != "battle" or not is_instance_valid(field) or is_instance_valid(outfitting) or is_instance_valid(_parked_company) or error_panel.visible or aftermath_panel.visible:return
 if field._reserve_modal() or not field.battle.result.is_empty():return
 _battle_company_field=field;_battle_company_mode=field.process_mode
 _battle_company_context={"session":session,"campaign":session.campaign,"battle":field.battle}
 _battle_company_focus=get_viewport().gui_get_focus_owner()
 field.process_mode=Node.PROCESS_MODE_DISABLED
 outfitting=load("res://hollow_campaign/outfitting.gd").new()
 outfitting.host=self;outfitting.battle_read_only=true;outfitting.battle_owner=field
 _canvas.add_child(outfitting)
 outfitting.set_session(session)
 var id:int=field.controller.selected
 if id>=0 and id<field.battle.units.size() and field.battle.units[id].side==0:
  outfitting.selected_sid=field.battle.units[id].get("company_id",world.camp_selected)
 outfitting.refresh();outfitting.set_return_label("Return to battle [Esc / I]")
 outfitting.back_requested.connect(_battle_company_back.bind(outfitting.get_instance_id()))
 outfitting.navigation_requested.connect(_company_navigation)
 outfitting.back_button.grab_focus()
func _close_battle_company() -> void:
 if is_instance_valid(outfitting):
  outfitting.hide();outfitting.queue_free();outfitting=null
 if is_instance_valid(_battle_company_field):_battle_company_field.process_mode=_battle_company_mode
 _battle_company_field=null;_battle_company_context.clear()
 if is_instance_valid(_battle_company_focus) and _battle_company_focus.is_inside_tree() and _battle_company_focus.is_visible_in_tree() and _battle_company_focus.can_process():_battle_company_focus.grab_focus()
 _battle_company_focus=null
const COMPANY_ROUTES := {"character":"person_open","perks":"personal_perks","formation":"lineup_open","history":"service","bonds":"bonds","armor":"iron_armour","journal":"iron_journal"}
func _create_session():
 checkpoint_path = "user://hollow-campaign-camp.json"
 return load("res://hollow_campaign/session.gd").new()
func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Painted Company")
func _open_company() -> void:
 if not session.changed.is_connected(_session_changed): session.changed.connect(_session_changed)
 if not is_instance_valid(world):
  world = load("res://ui_polish/world_view.gd").new()
  world.host = self; world.campaign = session.campaign; add_child(world)
 world.set_active(not is_instance_valid(outfitting))
func _open_outfitting() -> void:
 if session != null and session.campaign.phase == "battle":
  _open_battle_company();return
 if is_instance_valid(outfitting) or is_instance_valid(_parked_company) or not is_instance_valid(world) or not world.inventory_available(): return
 world.set_active(false)
 outfitting = load("res://hollow_campaign/outfitting.gd").new()
 _canvas.add_child(outfitting)
 _canvas.move_child(outfitting,0) # Checkpoint/aftermath overlays retain top ownership.
 outfitting.host = self
 outfitting.set_session(session)
 outfitting.selected_sid = world.camp_selected
 outfitting.refresh()
 outfitting.back_requested.connect(_close_outfitting)
 if outfitting.has_signal("navigation_requested"):outfitting.connect("navigation_requested",_company_navigation)
 if outfitting.has_method("set_return_label"):
  outfitting.set_return_label("Return to town" if world.has_method("company_returns_to_town") and world.company_returns_to_town() else "Return to map")
func _close_outfitting() -> void:
 if _battle_company_open():
  _close_battle_company();return
 if error_panel.visible or aftermath_panel.visible:return
 if not is_instance_valid(outfitting): return
 world.camp_selected = outfitting.selected_sid
 outfitting.queue_free(); outfitting = null
 if is_instance_valid(world):
  world.rebind(session.campaign)
  world.set_active(session.campaign.phase == "camp" and not error_panel.visible)
func _company_navigation(id: String) -> void:
 if PlayerWorkflows.company_route_parked(id):return # Refuse before parking or writing return context.
 if (not COMPANY_ROUTES.has(id) and id != "memorial") or not is_instance_valid(outfitting) or not is_instance_valid(world):return
 if error_panel.visible or aftermath_panel.visible or session.campaign.phase != "camp":return
 if outfitting.details_panel.visible or outfitting.market_panel.visible or outfitting.perks_view.confirm_panel.visible:return
 _company_return_context = {"world_view":world.world_view,"sheet":world.iron.sheet}
 world.camp_selected = outfitting.selected_sid
 _parked_company = outfitting; outfitting = null
 _parked_company.hide();_parked_company.process_mode = Node.PROCESS_MODE_DISABLED
 if id == "memorial":
  _memorial = load("res://company_town/memorial_view.gd").new()
  _memorial.host = self
  _canvas.add_child(_memorial);_canvas.move_child(_memorial,1)
  _memorial.show_company(session.campaign)
  _memorial.close_requested.connect(_close_memorial)
  return
 world.world_view = false;world.iron.sheet = ""
 world.set_active(true)
 world.action(COMPANY_ROUTES[id])
 # An inherited refusal must not strand the hidden workspace.
 _resume_company_if_ready()
func _company_subview_open() -> bool:
 if is_instance_valid(_memorial):return true
 return not world.iron.sheet.is_empty() or world.lineup.opened or not world.confirmation.is_empty() or world.help or world.intro or world.news_view or world.perks_view or world.salvage_view or world.guide_view or world.vault_journal or world.planner_view or world.arms_view or world.armor_view or world.person_view or world.bonds_view or world.service_view or world.politics_view or world.trade_view or world.record_view or world.tactics_view or world.inspection_view or world.dungeon_door >= 0
func _resume_company_if_ready() -> void:
 if not is_instance_valid(_parked_company) or not is_instance_valid(world):return
 if error_panel.visible or aftermath_panel.visible or session.campaign.phase != "camp" or _company_subview_open():return
 outfitting = _parked_company;_parked_company = null
 outfitting.selected_sid = world.camp_selected
 world.world_view = _company_return_context.get("world_view",true)
 world.iron.sheet = _company_return_context.get("sheet","")
 _company_return_context.clear()
 world.set_active(false)
 outfitting.process_mode = Node.PROCESS_MODE_INHERIT
 outfitting.show();outfitting.refresh()
func _close_memorial() -> void:
 if error_panel.visible or aftermath_panel.visible or not is_instance_valid(_memorial):return
 _memorial.queue_free();_memorial = null
 _resume_company_if_ready()
func _process(delta: float) -> void:
 if _battle_company_open():
  if not _battle_company_current():_close_battle_company()
  return
 _resume_company_if_ready()
 super._process(delta)
func _retreat() -> void:
 if _battle_company_open():return
 super._retreat()
func _session_changed() -> void:
 super._session_changed()
 if is_instance_valid(outfitting) and is_instance_valid(world): world.set_active(false)
var _battle_loading: CanvasLayer
var _loading_world_mode: int = Node.PROCESS_MODE_INHERIT
var _held_inputs: Dictionary = {}
func _loading_input_id(event: InputEvent) -> String:
 if event is InputEventMouseButton:return "m:" + str(event.button_index)
 if event is InputEventKey:
  if event.physical_keycode != KEY_NONE:return "p:" + str(event.physical_keycode)
  if event.keycode != KEY_NONE:return "k:" + str(event.keycode)
 return ""
func _exit_tree() -> void:
 if is_instance_valid(_battle_loading):
  if is_instance_valid(world):world.process_mode = _loading_world_mode
  _battle_loading.queue_free()
  _battle_loading = null
func _deploy() -> void:
 if is_instance_valid(outfitting) or is_instance_valid(_parked_company):return
 if session == null or session.campaign == null or session.campaign.phase != "camp" or error_panel.visible or not is_instance_valid(world) or is_instance_valid(field) or is_instance_valid(_battle_loading):return
 if session.campaign.encounter.get("kind") == "dungeon" and not _burial_available():return
 _begin_battle_loading(false)
func _deploy_camp() -> void:
 if is_instance_valid(outfitting) or is_instance_valid(_parked_company):return
 if session == null or session.campaign == null or session.campaign.phase != "camp" or error_panel.visible or not is_instance_valid(world) or is_instance_valid(field) or is_instance_valid(_battle_loading):return
 _begin_battle_loading(true)
func _begin_battle_loading(camp_route: bool) -> void:
 _battle_loading = load("res://hollow_campaign/battle_loading.gd").new()
 _battle_loading.name = "BattleLoading"
 add_child(_battle_loading)
 # Preserve visibility for the inherited dungeon admission gate, but suspend world input.
 _loading_world_mode = world.process_mode
 world.process_mode = Node.PROCESS_MODE_DISABLED
 var owner := _battle_loading
 await get_tree().process_frame
 if not is_inside_tree() or _battle_loading != owner:return
 await get_tree().process_frame
 if not is_inside_tree() or _battle_loading != owner:return
 # No events can interleave with the synchronous inherited authority path.
 if is_instance_valid(world):world.process_mode = _loading_world_mode
 if camp_route:super._deploy_camp()
 else:super._deploy()
 # Retain the surface through the next input pump: native events can queue
 # while the synchronous checkpoint and field construction block the thread.
 await get_tree().process_frame
 if not is_inside_tree() or _battle_loading != owner:return
 # A release/repeat from an earlier gesture must not activate the new field.
 if not _held_inputs.is_empty():
  var fence = load("res://hollow_campaign/loading_release_fence.gd").new()
  fence.host = self;fence.holds = _held_inputs.duplicate()
  add_child(fence) # Last sibling receives input before field and GUI descendants.
 # The mounted field was fenced while loading owned input.
 if is_instance_valid(field):field.process_mode = Node.PROCESS_MODE_INHERIT
 if is_instance_valid(_battle_loading):
  remove_child(_battle_loading)
  _battle_loading.queue_free()
 _battle_loading = null
func _accept_contract(id: String) -> void:
 if is_instance_valid(outfitting) or is_instance_valid(_parked_company):return
 super._accept_contract(id)
func _new_company(seed: int) -> void:
 if is_instance_valid(outfitting) or is_instance_valid(_parked_company):return
 super._new_company(seed)
func _load_checkpoint() -> void:
 if is_instance_valid(outfitting) or is_instance_valid(_parked_company):return
 super._load_checkpoint()
func _create_battlefield() -> Node3D:
 var result: Node3D = load("res://hollow_campaign/battlefield.gd").new()
 result.ready.connect(preload("res://engraved_ui/combat_docket.gd").mount.bind(result),CONNECT_ONE_SHOT)
 if is_instance_valid(_battle_loading):result.process_mode = Node.PROCESS_MODE_DISABLED
 return result
func observation() -> Dictionary:
 var out := super.observation()
 out["hollow_campaign"] = true
 out["checkpoint_origin"] = "ashen-company-painted-merge"
 out["checkpoint_path"] = checkpoint_path
 if is_instance_valid(outfitting): out["outfitting"] = outfitting.observation()
 if is_instance_valid(_parked_company):out["company_parked"] = {"selected_sid":_parked_company.selected_sid,"section":_parked_company.section}
 if is_instance_valid(_memorial):out["memorial"] = _memorial.observation()
 return out

func _overlay_margins(margin: MarginContainer) -> void:
 var viewport_size:=get_viewport().get_visible_rect().size
 var horizontal:=maxi(24,int((viewport_size.x-1000)/2))
 var vertical:=maxi(24,int((viewport_size.y-760)/2))
 for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,horizontal)
 for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,vertical)

func _panel(title: String) -> Dictionary:
 var overlay:=Control.new()
 overlay.theme=GameUI.theme()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter=Control.MOUSE_FILTER_STOP
 _canvas.add_child(overlay)
 var shade:=ColorRect.new();shade.color=GameUI.BG
 shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(shade)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(margin);_overlay_margins(margin)
 overlay.resized.connect(_overlay_margins.bind(margin))
 var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",GameUI.panel(GameUI.SURFACE,GameUI.LINE,24));margin.add_child(card)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",16);card.add_child(column)
 var heading:=Label.new();GameUI.label(heading,26)
 heading.text="Battle report" if title=="THE COMPANY RETURNS" else "Your progress needs attention"
 column.add_child(heading)
 return {"root":overlay,"column":column}

func _build_overlays() -> void:
 aftermath_panel=Control.new();aftermath_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 aftermath_panel.mouse_filter=Control.MOUSE_FILTER_STOP;_canvas.add_child(aftermath_panel)
 battle_report=load("res://battle_report/report.gd").new();battle_report.name="BattleReport"
 aftermath_panel.add_child(battle_report)
 battle_report.return_requested.connect(_return_to_camp)
 return_button=battle_report.return_button
 # Existing integrations may inspect this full inherited summary; never show two reports.
 _aftermath_text=RichTextLabel.new();_aftermath_text.bbcode_enabled=false
 aftermath_panel.add_child(_aftermath_text);_aftermath_text.hide();aftermath_panel.hide()
 var error:=_panel("CHECKPOINT NEEDS ATTENTION");error_panel=error.root
 var explanation:=Label.new();GameUI.label(explanation,16,GameUI.DANGER)
 explanation.text="Changes are not safely saved. Your previous checkpoint has not been overwritten."
 explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;error.column.add_child(explanation)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;error.column.add_child(scroll)
 error_label=Label.new();GameUI.label(error_label,16)
 error_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 error_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(error_label)
 var retry:=Button.new();retry.text="Retry checkpoint";GameUI.button(retry,true)
 retry.custom_minimum_size.y=44;retry.pressed.connect(_retry_checkpoint);error.column.add_child(retry)
 var close:=Button.new();close.text="Quit without overwriting the checkpoint";GameUI.button(close)
 close.custom_minimum_size.y=44;close.pressed.connect(func():get_tree().quit());error.column.add_child(close)
 error_panel.hide()

func _overlay_scope() -> Control:
 if is_instance_valid(error_panel) and error_panel.visible:return error_panel
 if is_instance_valid(aftermath_panel) and aftermath_panel.visible:return aftermath_panel
 return null

func _overlay_buttons(scope: Control) -> Array:
 return scope.find_children("*","Button",true,false).filter(func(button):return button.is_visible_in_tree() and not button.disabled)

func _focus_overlay() -> void:
 var scope:=_overlay_scope()
 if scope==null:return
 if scope==aftermath_panel:
  return_button.grab_focus();return
 var buttons:=_overlay_buttons(scope)
 if not buttons.is_empty():buttons[0].grab_focus()

func _show_error(message: String) -> void:
 if not error_panel.visible:_overlay_prior_focus=get_viewport().gui_get_focus_owner()
 super._show_error(message)
 call_deferred("_focus_overlay")

func _show_aftermath() -> void:
 super._show_aftermath()
 if aftermath_panel.visible:
  battle_report.present(session)
  call_deferred("_focus_overlay")

func _retry_checkpoint() -> void:
 super._retry_checkpoint()
 if not error_panel.visible and is_instance_valid(_overlay_prior_focus) and _overlay_prior_focus.is_visible_in_tree():_overlay_prior_focus.grab_focus()

func _input(event: InputEvent) -> void:
 var input_id := _loading_input_id(event)
 if not input_id.is_empty():
  if event.pressed:_held_inputs[input_id] = true
  else:_held_inputs.erase(input_id)
 if is_instance_valid(_battle_loading):
  get_viewport().set_input_as_handled()
  return
 var scope:=_overlay_scope()
 if scope==null or not event is InputEventKey:return
 if scope==aftermath_panel and battle_report.handle_key(event):
  get_viewport().set_input_as_handled();return
 var code: Key=event.physical_keycode if event.physical_keycode!=KEY_NONE else event.keycode
 if code==KEY_TAB and event.pressed and not event.echo:
  var buttons:=_overlay_buttons(scope)
  if not buttons.is_empty():
   var at:=buttons.find(get_viewport().gui_get_focus_owner())
   buttons[posmod(at+(-1 if event.shift_pressed else 1),buttons.size())].grab_focus()
  get_viewport().set_input_as_handled()
 elif code not in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:get_viewport().set_input_as_handled()

func _unhandled_key_input(_event: InputEvent) -> void:
 if _overlay_scope()!=null:get_viewport().set_input_as_handled()

