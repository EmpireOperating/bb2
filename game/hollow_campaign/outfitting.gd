extends "res://company_loop/camp_panel.gd"
## Mounted projection only: actual full campaign/session remains the authority.
signal back_requested
signal navigation_requested(id: String)
const CompanyPages = preload("res://company_town/company_pages.gd")
const PlayerWorkflows = preload("res://company_town/player_workflows.gd")
const Recovery = preload("res://src/recovery.gd")
var section := "equipment"
var section_buttons := {}
var formation_button: Button
var recovery_label: Label
var ammo_status_label: Label
var ammo_refill_button: Button
var _ammo_callback: Callable
var _ammo_paint := {}
var pages: Panel
var perks_view: Panel
var layered_button: Button
var memorial_button: Button
var roster_counts: Label
const Inventory = preload("res://hollow_campaign/appearance.gd")
const Presentation = preload("res://ui_polish/inventory_presentation.gd")
const UI = preload("res://ui_polish/style.gd")
const Rarity = preload("res://hollow_systems/rarity.gd")
const IronSkin = preload("res://iron_oath/skin.gd")
const InventoryCard = preload("res://iron_oath/inventory_card.gd")
const InventoryArt = preload("res://iron_oath/inventory_art.gd")
const REPAIR_MARK = preload("res://company_town/assets/resources/repair-hammers-32.png")
const Offer = preload("res://company_town/equipment_offer.gd")
const VaultItems = preload("res://vault_key_items/presentation.gd")
const KeyCard = preload("res://battle_report/loot_card.gd")
var keyring: VBoxContainer
var key_grid: VBoxContainer
var key_heading: Label
var key_buttons: Dictionary = {}
var selected_key := ""
var _owned_keys: Array = []
var inventory_grid: GridContainer
var carry_card: Panel
var carry_row: HBoxContainer
var resource_label: Label
var resource_header: Control
var inventory_tab: Button
var camp_background: TextureRect
var item_art: TextureRect
var item_detail_frame: Panel
var item_detail_heading: Label
var item_details_button: Button
var item_provenance: Label
const EngravedActors = preload("res://engraved_people/actors.gd")
var selected_level_badge: Control
const LEFT_SLOTS := ["mainhand","head","hands","cloak"]
const RIGHT_SLOTS := ["offhand","body","feet","belt","ammo"]
var details_button: Button
var details_panel: Panel
var details_close_button: Button
const WeaponSkills = preload("res://company_town/weapon_skill_preview.gd")
var weapon_skills_heading: Label
var weapon_skills_context: Label
var weapon_skill_buttons := {}
var weapon_skill_effects := {}
var _expanded_skills := {}
var _skill_item_uid := ""
var weapon_skills_column: VBoxContainer
var _retained_weapon_uid := ""
var item_summary: Label
var item_scroll: ScrollContainer
var omission_label: Label
var _detail_context := ""
var _details_owner := {}
var host
# Same workspace, explicitly bound read-only battle projection. No new authority.
var battle_read_only := false
var battle_owner: Node3D
var battle_pages: Node2D
var battle_page_focus: Control
func _browse_reason() -> String:
 if not battle_read_only:return _camp_reason()
 return _workspace_reason()
var back_button: Button
var carry_buttons := {}
var carry_column: VBoxContainer
var carry_heading: Label
var mapping_scroll: ScrollContainer
var mapping_notes: Label
var _carried: Array = []
var market_button: Button
var market_panel: Panel
var market_heading: Label
var market_scroll: ScrollContainer
var market_list: VBoxContainer
var market_buttons := {}
var market_buy_button: Button
var market_close_button: Button
var market_reason_label: Label
var _market_selection := ""
var _market_seen := {}
var _market_feedback := ""
# UI-only native drag intent; Campaign remains the physical authority.
var _drag_ticket: Dictionary = {}
var _drag_serial := 0
var _drag_hover: Control
var _repair_press: Button
var _drop_refresh_held := false
var _drop_refresh_pending := false
func _ready() -> void:
 theme = UI.theme()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 camp_background = TextureRect.new();camp_background.texture = IronSkin.texture("camp")
 camp_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 camp_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 camp_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(camp_background);camp_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var veil := ColorRect.new();veil.color = Color(0.025,0.032,0.025,.36)
 veil.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(veil);veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 title_label = _label(29,INK,self);title_label.text = "THE ASHEN COMPANY"
 title_label.add_theme_font_override("font",load("res://assets/serif.ttf"))
 title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 subtitle_label = _label(15,GOLD,self);subtitle_label.text = "FIRST MUSTER  /  COMPANY ROLL"
 checkpoint_label = _label(12,GOLD,self);checkpoint_label.text = "Between-battle checkpoints save company changes. Battles resume from the last checkpoint, not mid-fight."
 resource_label = _label(16,INK,self);resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 resource_label.hide() # Retained semantic Label for inherited observers, never duplicate prose.
 resource_header = load("res://resource_header/header.gd").new(true);add_child(resource_header)
 roster_card = _card("COMPANY");portrait_card = _card("");stash_card = _card("OWNED STASH")
 portrait_card.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 slots_card = _card("");slots_card.hide()
 stash_title = stash_card.get_node("Heading")
 roster_scroll = _scroll(roster_card);roster_list = roster_scroll.get_child(0)
 roster_counts = _label(13,MUTED,roster_card)
 memorial_button = _button("Memorial",roster_card);memorial_button.pressed.connect(_navigate.bind("memorial"))
 slots_scroll = _scroll(slots_card);slots_list = slots_scroll.get_child(0)
 stash_scroll = _scroll(stash_card);stash_list = stash_scroll.get_child(0);stash_list.hide()
 var stash_contents := VBoxContainer.new();stash_contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 stash_contents.add_theme_constant_override("separation",8);stash_scroll.add_child(stash_contents)
 keyring = VBoxContainer.new();stash_contents.add_child(keyring)
 key_heading = _label(15,GOLD,keyring)
 key_grid = VBoxContainer.new();key_grid.add_theme_constant_override("separation",8);keyring.add_child(key_grid)
 inventory_grid = GridContainer.new();inventory_grid.columns = 3
 inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 inventory_grid.add_theme_constant_override("h_separation",8);inventory_grid.add_theme_constant_override("v_separation",8)
 stash_contents.add_child(inventory_grid)
 _empty_stash = _label(14,MUTED,stash_card)
 name_label = _label(31,INK,portrait_card);name_label.add_theme_font_override("font",load("res://assets/serif.ttf"))
 identity_label = _label(15,GOLD,portrait_card)
 for label in [title_label,resource_label,name_label,identity_label]:
  label.autowrap_mode = TextServer.AUTOWRAP_OFF;label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 preview = load("res://iron_oath/inventory_figure.gd").new();preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR;preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
 portrait_card.add_child(preview)
 selected_level_badge=preload("res://ui_polish/level_up_badge.gd").new();preview.add_child(selected_level_badge)
 stats_label = _label(14,INK,portrait_card);stats_label.hide()
 omission_label = _label(12,MUTED,portrait_card)
 carry_card = _card("CARRIED ARMS");carry_heading = carry_card.get_node("Heading")
 layered_button = _button("Armor",carry_card);layered_button.custom_minimum_size.y = 32
 layered_button.tooltip_text = PlayerWorkflows.ARMOR_REASON if PlayerWorkflows.LAYERED_ARMOR_PARKED else "Layered armor"
 layered_button.add_theme_font_size_override("font_size",15);layered_button.pressed.connect(_navigate.bind("armor"))
 carry_column = VBoxContainer.new();carry_column.hide();carry_card.add_child(carry_column)
 carry_row = HBoxContainer.new();carry_row.add_theme_constant_override("separation",8);carry_card.add_child(carry_row)
 comparison_label = _label(13,GOLD,stash_card);comparison_label.hide()
 reason_label = _label(13,MUTED,stash_card)
 equip_button = _button("Equip selected",stash_card);equip_button.pressed.connect(_equip)
 item_details_button = _button("Item details",stash_card);item_details_button.pressed.connect(_toggle_item_details)
 remove_button = _button("Remove slot",portrait_card);remove_button.pressed.connect(_remove)
 deploy_button = _button("",self);deploy_button.hide();deploy_button.disabled = true
 item_detail_frame = Panel.new();item_detail_frame.add_theme_stylebox_override("panel",IronSkin.panel(8))
 # On demand, over the figure and never in the stash's layout/hit area.
 add_child(item_detail_frame);item_detail_frame.hide()
 item_detail_heading = _label(14,GOLD,item_detail_frame);item_detail_heading.text = "ITEM DETAILS"
 item_detail_heading.autowrap_mode = TextServer.AUTOWRAP_OFF;item_detail_heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 item_art = TextureRect.new();item_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 item_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;item_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 item_detail_frame.add_child(item_art);UI.Press.mount_icon(item_art)
 item_scroll = ScrollContainer.new();item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 item_scroll.focus_mode = Control.FOCUS_ALL
 item_scroll.follow_focus = true
 item_detail_frame.add_child(item_scroll)
 weapon_skills_column = VBoxContainer.new();weapon_skills_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL;item_scroll.add_child(weapon_skills_column)
 weapon_skills_heading = _label(16,GOLD,weapon_skills_column);weapon_skills_heading.text = "Weapon skills"
 weapon_skills_context = _label(13,MUTED,weapon_skills_column)
 weapon_skills_context.autowrap_mode = TextServer.AUTOWRAP_OFF
 weapon_skills_context.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 for id: String in ["basic","special"]:
  var row := _button("",weapon_skills_column);row.alignment = HORIZONTAL_ALIGNMENT_LEFT
  row.add_theme_font_size_override("font_size",14);row.custom_minimum_size.y = 38
  weapon_skill_buttons[id] = row;row.pressed.connect(_toggle_weapon_skill.bind(id))
  var effect := _label(14,INK,weapon_skills_column);effect.hide();effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  weapon_skill_effects[id] = effect
 item_summary = _label(15,INK,weapon_skills_column);item_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 weapon_skills_column.move_child(item_summary,0) # Inspect the item before its optional skill disclosures.
 item_provenance = _label(14,MUTED,weapon_skills_column);item_provenance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 back_button = _button("Return to map [Esc]",self);back_button.pressed.connect(_back)
 inventory_tab = _button("Equipment",self)
 section_buttons["equipment"] = inventory_tab
 inventory_tab.pressed.connect(open_section.bind("equipment"))
 for id in ["character","perks"]:
  var tab := _button(id.capitalize(),self);section_buttons[id] = tab
  tab.pressed.connect(open_section.bind(id))
 formation_button = _button("Formation",self);formation_button.pressed.connect(_navigate.bind("formation"))
 ammo_status_label = _label(14,GOLD,self)
 ammo_status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
 ammo_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 ammo_refill_button = _button("Refill ammo",self)
 recovery_label = _label(14,MUTED,self)
 recovery_label.autowrap_mode = TextServer.AUTOWRAP_OFF;recovery_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 pages = CompanyPages.new();pages.workspace = self;add_child(pages);pages.hide()
 perks_view = load("res://company_town/company_perks.gd").new();perks_view.workspace = self;add_child(perks_view);perks_view.hide()
 details_button = _button("Details",portrait_card);details_button.pressed.connect(_open_details)
 # One polished presenter, owned only by the existing Company Details trigger.
 details_panel = pages;mapping_scroll = pages.scroll;details_close_button = pages.close_button
 pages.close_requested.connect(_close_details)
 # Keep the literal diagnostic projection for observers without a second UI.
 mapping_notes = _label(15,UI.TEXT,self);mapping_notes.hide()
 details_panel.hide();_build_market()
 if battle_read_only:
  battle_page_focus = Control.new();battle_page_focus.focus_mode = Control.FOCUS_ALL
  battle_page_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(battle_page_focus)
  battle_pages = load("res://hollow_campaign/battle_company_pages.gd").new()
  battle_pages.name = "BattleCompanyPages";battle_pages.workspace = self;add_child(battle_pages)
  battle_pages.hide();battle_page_focus.hide()
 visibility_changed.connect(_view_changed);resized.connect(_layout)
 for surface: Control in [stash_card,stash_scroll,inventory_grid,_empty_stash,stash_title]:
  surface.set_drag_forwarding(Callable(),_inventory_can_drop.bind("",surface),_inventory_drop.bind(""))
 selected_slot = "mainhand";_ready_ui = true;_bind();refresh()
func set_session(value) -> void:
 _retained_weapon_uid = "";selected_key = ""
 _repair_press = null
 if is_instance_valid(item_detail_frame):item_detail_frame.hide()
 super.set_session(value)
 selected_slot = "mainhand"; refresh()
func set_return_label(text: String) -> void:
 if is_instance_valid(back_button):back_button.text = text
func open_section(value: String) -> void:
 if not value in ["equipment","character","perks"] or _host_blocked():return
 if is_instance_valid(details_panel) and (details_panel.visible or market_panel.visible or perks_view.confirm_panel.visible):return
 if value in ["character","perks"] and not battle_read_only:
  _navigate(value);return
 if battle_read_only and not _browse_reason().is_empty():return
 section = value
 if not _ready_ui:return
 refresh()
 section_buttons[section].grab_focus()
func _navigate(id: String) -> void:
 if PlayerWorkflows.company_route_parked(id):return
 if not id in ["character","perks","formation","history","bonds","armor","memorial","journal"]:return
 var reason := _memorial_reason() if id == "memorial" else _camp_reason()
 if not reason.is_empty():return
 navigation_requested.emit(id)
func _view_changed() -> void:
 if not is_visible_in_tree():
  _retire_details();market_panel.hide()
  item_detail_frame.hide()
  _repair_press = null
  _detail_context = ""
 elif _ready_ui:refresh()
func _details_current() -> bool:
 if _details_owner.is_empty() or _host_blocked() or session == null:return false
 return session == _details_owner.session and session.campaign == _details_owner.campaign and selected_sid == _details_owner.sid and section == "equipment" and is_same(_person(),_details_owner.person) and selected_slot == _details_owner.slot and selected_item_id == _details_owner.item and selected_key == _details_owner.key
func _retire_details() -> void:
 if is_instance_valid(details_panel):
  var viewport := get_viewport()
  var focused: Control = viewport.gui_get_focus_owner() if viewport != null else null
  if focused != null and details_panel.is_ancestor_of(focused):focused.release_focus()
  details_panel.hide()
 _details_owner.clear()
func _sync_details() -> void:
 if is_instance_valid(details_panel) and details_panel.visible and not _details_current():
  _retire_details()
  if _ready_ui:_update_actions()
func _process(_delta: float) -> void:
 _sync_details()
func _host_blocked() -> bool:
 if not is_visible_in_tree():return true
 if host == null:return battle_read_only
 if battle_read_only:
  return host.outfitting != self or host.session != session or not host._battle_company_current() or not is_instance_valid(battle_owner) or host.field != battle_owner
 if host.outfitting != self or host.error_panel.visible or host.aftermath_panel.visible or is_instance_valid(host.field):return true
 if is_instance_valid(host.world) and (host.world.help or host.world.intro or not host.world.confirmation.is_empty() or not host.world.iron.sheet.is_empty()):return true
 return false
func _back() -> void:
 if _host_blocked():return
 if is_instance_valid(perks_view) and perks_view.confirm_panel.visible:
  perks_view.cancel();return
 if is_instance_valid(market_panel) and market_panel.visible:
  _close_market();return
 if is_instance_valid(details_panel) and details_panel.visible:
  _close_details();return
 back_requested.emit()
func _deploy() -> void: pass # No demo deployment route; use actual world contact.
func _input(event: InputEvent) -> void:
 if not is_visible_in_tree() or not event is InputEventKey:return
 if event.pressed and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE) and get_viewport().gui_is_dragging():
  # Real Godot 4.4.1 API; consume cancellation before the inherited Back path.
  get_viewport().gui_cancel_drag();get_viewport().set_input_as_handled();return
 if _host_blocked():return # Parent owns checkpoint/aftermath focus and input.
 if details_panel.visible:
  if event.pressed and not event.echo:
   var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
   if code == KEY_ESCAPE:_close_details()
   elif code == KEY_TAB:
    if get_viewport().gui_get_focus_owner() == details_close_button:mapping_scroll.grab_focus()
    else:details_close_button.grab_focus()
   elif code in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and details_close_button.has_focus():_close_details()
   elif code in [KEY_UP,KEY_DOWN]:mapping_scroll.scroll_vertical += -48 if code == KEY_UP else 48
   else:Presentation.scroll_key(mapping_scroll,event)
  get_viewport().set_input_as_handled();return
 if (event.keycode == KEY_I or event.physical_keycode == KEY_I) and (battle_read_only or (not market_panel.visible and not perks_view.confirm_panel.visible and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed)):
  if event.pressed and not event.echo:_back()
  get_viewport().set_input_as_handled();return
 if not event.pressed:return
 if perks_view.confirm_panel.visible:
  if Presentation.scroll_key(perks_view.confirm_scroll,event):get_viewport().set_input_as_handled();return
  if event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB:
   if not event.echo:Presentation.cycle(perks_view.confirm_panel,event.shift_pressed)
   get_viewport().set_input_as_handled();return
 var focused := get_viewport().gui_get_focus_owner()
 var inspecting := item_detail_frame.visible and focused != null and item_detail_frame.is_ancestor_of(focused)
 var scroll: ScrollContainer = market_scroll if market_panel.visible else roster_scroll if focused != null and roster_scroll.is_ancestor_of(focused) else _section_scroll(focused) if section != "equipment" else item_scroll if inspecting else stash_scroll
 if scroll != null and Presentation.scroll_key(scroll,event):
  get_viewport().set_input_as_handled();return
 if event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB:
  if battle_read_only and section != "equipment":
   if not event.echo:
    var controls: Array[Control] = []
    for button: Button in find_children("*","Button",true,false):
     if button.is_visible_in_tree() and not button.disabled and button.focus_mode != Control.FOCUS_NONE:controls.append(button)
    controls.append(battle_page_focus)
    var at: int = controls.find(get_viewport().gui_get_focus_owner())
    controls[posmod(at+(-1 if event.shift_pressed else 1),controls.size())].grab_focus()
   get_viewport().set_input_as_handled();return
  if not event.echo:
   Presentation.cycle(market_panel if market_panel.visible else details_panel if details_panel.visible else self,event.shift_pressed)
  get_viewport().set_input_as_handled();return
 if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
  if not event.echo:
   if item_detail_frame.visible and not market_panel.visible and not perks_view.confirm_panel.visible:_toggle_item_details()
   else:_back()
  get_viewport().set_input_as_handled()
func _section_scroll(focused: Control) -> ScrollContainer:
 if section == "character":return pages.scroll
 for scroll: ScrollContainer in [perks_view.growth_scroll,perks_view.pool_scroll,perks_view.detail_scroll]:
  if focused != null and scroll.is_ancestor_of(focused):return scroll
 return perks_view.detail_scroll
func _person() -> Dictionary:
 if session != null:
  for person: Dictionary in session.campaign.soldiers:
   if person.id == selected_sid:return person
 return {}
func _item_row(uid: String) -> Dictionary:
 var item: Dictionary = session.campaign.items.get(uid,{})
 var definition: Dictionary = session.campaign.item_def(uid)
 return {"item_id":uid,"definition":item.get("definition",""),"name":definition.get("name","Empty"),"condition":item.get("condition",0),"maximum":definition.get("durability",0)}
func _available_rows() -> Array:
 # A stash is all owned, loose, unassigned equippable items, not a hidden slot filter.
 var out: Array = []
 for uid: String in session.campaign.items:
  if session.campaign.owner(uid) >= 0 or not session.campaign.parent_kit(uid).is_empty():continue
  var definition: String = session.campaign.items[uid].definition
  if not session.campaign.VISIBLE_SLOTS.any(func(slot):return session.campaign.slot_allowed(definition,slot)):continue
  out.append(_item_row(uid))
 return out
func _select_item(id: String) -> void:
 if not _browse_reason().is_empty() or not _items.any(func(row):return row.item_id == id):return
 _retained_weapon_uid = ""
 var definition: String = session.campaign.items[id].definition
 if not session.campaign.slot_allowed(definition,selected_slot):
  for slot: String in session.campaign.VISIBLE_SLOTS:
   if session.campaign.slot_allowed(definition,slot):selected_slot = slot;break
 selected_key = "";selected_item_id = id;_feedback = "";refresh()
func _carry_rows() -> Array:
 var out: Array = []
 var person := _person()
 if person.is_empty():return out
 for i in session.campaign.carry_capacity(person):
  var key := "carry%d" % (i+1)
  var row := _item_row(session.campaign.slot_uid(person,key))
  row.merge({"key":key,"label":"Reserve %d" % (i+1)},true);out.append(row)
 return out
func refresh() -> void:
 if _drop_refresh_held:
  _drop_refresh_pending = true
  return
 if not _ready_ui: return
 checkpoint_label.text = "BATTLE · READ-ONLY · Company records before battle. Live damage / AP / fatigue / reserve swaps remain in the combat HUD." if battle_read_only else ("SAVED" if host != null and host.saved_ok else "UNSAVED") + " · Save / F5 in the world menu checkpoints your company. No automatic saves."
 _sync_details()
 _revision += 1
 var people: Array = []
 if session != null:
  for person: Dictionary in session.campaign.soldiers:
   if person.get("alive", false): people.append(person)
 if not people.any(func(person): return person.id == selected_sid):
  selected_sid = int(people[0].id) if not people.is_empty() else -1
  selected_item_id = ""
 _unit = session.preview_unit(selected_sid) if selected_sid >= 0 else {}
 _slots = session.slot_rows(selected_sid) if selected_sid >= 0 else []
 _carried = _carry_rows()
 if not (_slots+_carried).any(func(row):return row.key == selected_slot):
  selected_slot = "mainhand"; selected_item_id = ""
 _items = _available_rows() if selected_sid >= 0 else []
 if not _items.any(func(item): return item.item_id == selected_item_id): selected_item_id = ""
 _sync_cards(roster_buttons, roster_list, people, "id", _select_bro,"roster")
 for person: Dictionary in people:
  var row: Button = roster_buttons[person.id]
  row.text = "%s\nHP %d/%d" % [person.name, person.hp, session.campaign.max_hp(person)]
  row.tooltip_text = "%s · %s · HP %d/%d" % [person.name, person.get("title", ""), person.hp, session.campaign.max_hp(person)]
  _mark(row, person.id == selected_sid)
 _sync_cards(slot_buttons, portrait_card, _slots, "key", _select_slot,"slot")
 for slot: Dictionary in _slots:
  var row: Button = slot_buttons[slot.key]
  row.text = "%s\n%s" % [slot.label.to_upper(), _item_text(slot)]
  row.tooltip_text = row.text.replace("\n", " · ")
  _mark(row, slot.key == selected_slot)
 _sync_cards(item_buttons, inventory_grid, _items, "item_id", _select_item,"stash")
 for item: Dictionary in _items:
  var row: Button = item_buttons[item.item_id]
  row.text = _item_text(item)
  row.tooltip_text = row.text.replace("\n", " · ")
  _mark(row, item.item_id == selected_item_id)
 _refresh_keyring()
 _empty_stash.visible = _items.is_empty() and _owned_keys.is_empty()
 _empty_stash.text = "No suitable unassigned items.\nEquipment already worn by a brother is not in the stash."
 var stash_count := _items.size()+_owned_keys.size()
 stash_title.text = "OWNED STASH  /  %d %s" % [stash_count,"ITEM" if stash_count==1 else "ITEMS"]
 name_label.text = _unit.get("name", "No brother selected")
 name_label.tooltip_text = name_label.text
 identity_label.text = "HP %d/%d  ·  %s" % [_unit.hp, _unit.max_hp, _unit.get("title", "MERCENARY")] if not _unit.is_empty() else ""
 identity_label.tooltip_text = identity_label.text
 stats_label.text = "Body %d/%d  ·  Head %d/%d\nMelee %d  ·  Ranged %d\nDefense %d  ·  Load %d" % [_unit.armor + _unit.padding, _unit.max_armor + _unit.max_padding, _unit.helmet, _unit.max_helmet, _unit.skill, _unit.ranged_skill, _unit.defense, _unit.load] if not _unit.is_empty() else ""
 _sync_cards(carry_buttons,carry_row,_carried,"key",_select_slot,"carry")
 for row: Dictionary in _carried:
  carry_buttons[row.key].text = row.label.to_upper()+"\n"+_item_text(row)
  _mark(carry_buttons[row.key],row.key == selected_slot)
 if is_instance_valid(carry_heading): carry_heading.text = "CARRIED ARMS · %d" % _carried.size()
 if not _unit.is_empty():
  var tier := str(_unit.get("companion_roll",{}).get("tier",""))
  identity_label.text += " · "+(tier.capitalize() if not tier.is_empty() else "Unrated")
  identity_label.add_theme_color_override("font_color",Rarity.tier_color(tier))
 stats_label.text = Presentation.stats(_unit,session.campaign.battle) if session != null else ""
 var context := "%s/%s/%s/%s" % [session.get_instance_id() if session != null else 0,selected_sid,selected_slot,selected_item_id]
 if context != _detail_context:
  _detail_context = context
  _retire_details()
  item_scroll.scroll_vertical = 0
 _update_portrait()
 selected_level_badge.present(_person())
 _paint_inventory(people)
 _refresh_workspace()
 _update_actions()
 _layout()

func _refresh_workspace() -> void:
 if not is_instance_valid(pages):return
 var equipment := section == "equipment"
 portrait_card.visible = equipment;stash_card.visible = equipment;carry_card.visible = equipment
 perks_view.visible = section == "perks" and not battle_read_only
 if is_instance_valid(battle_pages):
  battle_pages.visible = not equipment;battle_page_focus.visible = not equipment
  if not equipment:battle_pages.present()
 for id: String in section_buttons:_mark(section_buttons[id],id == section)
 market_button.hide()
 if session != null:
  var c = session.campaign
  var points: int = maxi(0,c.Progression.points(_person())) if not _person().is_empty() else 0
  section_buttons.perks.text = "Perks"+(" · +%d" % points if points > 0 else "")
  section_buttons.perks.tooltip_text = "%d unspent perk points" % points if points > 0 else "Personal perk tree"
  roster_card.get_node("Heading").text = "COMPANY · %d" % c.alive_count()
  roster_counts.text = "%d field · %d reserve" % [c.active_ids().size(),c.reserve_ids().size()]
  roster_card.get_node("Heading").tooltip_text = "%d in the field · %d in reserve" % [c.active_ids().size(),c.reserve_ids().size()]
  resource_label.text = "%d crowns · %d / day\nFood %d · Tools %d · Medicine %d" % [c.crowns,c.wage_cost(),c.food,c.tools,c.medicine]
  resource_header.present(c)
  recovery_label.text = "Recovery as world time advances  ·  "+Recovery.status(c,selected_sid) if selected_sid >= 0 else "No living companions"
  recovery_label.tooltip_text = recovery_label.text
 if battle_read_only:
  recovery_label.text = "BATTLE · READ-ONLY · Company records BEFORE battle; current damage / AP / fatigue / held arms are in the combat HUD."
  recovery_label.tooltip_text = recovery_label.text
 if section == "perks" and not battle_read_only:perks_view.refresh()

func _update_portrait() -> void:
 if _unit.is_empty():
  _retained_weapon_uid = ""
  if is_instance_valid(item_summary):item_summary.text = "No current fighter.";item_summary.tooltip_text = ""
  item_provenance.hide()
  if is_instance_valid(mapping_notes):mapping_notes.text = ""
  _refresh_weapon_skills()
  preview.present(null)
  preview_layers.clear()
  _rendered_unit.clear()
  if is_instance_valid(preview_actor):
   preview_actor.queue_free()
   preview_actor = null
  return
 if not is_instance_valid(preview_actor):
  preview_actor = preload("res://engraved_people/preview.gd").new()
  preview_actor.name = "CampPreviewActor"
  preview_actor.position = Vector3(0, -1000, 0)
  preview_actor.visible = false
  preview_actor.process_mode = Node.PROCESS_MODE_DISABLED
  add_child(preview_actor)
 # Resolve the actual selected soldier, never the highlighted stash item.
 preview_actor.configure(_unit, session.campaign.catalog)
 preview_actor.set_process(false)
 _rendered_unit = _unit.duplicate(true)
 # Keep the exact resource owned by the field-capable actor, not a copy.
 preview.present(preview_actor.preview_texture())
 preview_layers = preview_actor.layer_signature().duplicate(true)

 if not is_instance_valid(mapping_notes): return
 var uid := _inspected_item_uid()
 var item: Dictionary = session.campaign.items.get(uid,{})
 var record := Inventory.item_details(item,session.campaign.catalog)
 mapping_notes.text = Inventory.effective_stats(_unit,session.campaign.battle)+"\n\n"+Inventory.person_details(_unit)+"\n\n"+selected_slot.to_upper()+"\n"+record+"\n\n"+Inventory.diagnostics_text(preview_actor.render_diagnostics() if is_instance_valid(preview_actor) else {})
 if is_instance_valid(item_summary):
  var owner_id: int = session.campaign.owner(uid)
  var origin := "Owned stash" if owner_id < 0 else "Assigned to "+str(session.campaign.soldiers[owner_id].name)
  item_summary.text = Presentation.summary(item,session.campaign.catalog)
  item_provenance.text = "\nFULL ITEM RECORD\n"+record+"\n"+origin
  item_provenance.visible = not item.is_empty()
  mapping_notes.text += "\n\n"+origin
  var ammo_uid: String = session.campaign.slot_uid(_person(),"ammo")
  var ammo: Dictionary = session.campaign.items.get(ammo_uid,{})
  var crossbow_ui = load("res://crossbows/ui.gd")
  var readiness: String = crossbow_ui.inspection(item,ammo,_unit,session.campaign.battle,session.campaign.catalog,true)
  if not readiness.is_empty():
   item_summary.text = crossbow_ui.summary(item,ammo,_unit,session.campaign.battle,session.campaign.catalog,true)
   mapping_notes.text += "\n\n"+readiness+"\nCAMP physical record, not battle readiness. Inspection never loads or refills equipment."
  item_summary.tooltip_text = item_summary.text
  omission_label.text = Presentation.omission(preview_actor.render_diagnostics())
  _refresh_weapon_skills()

func weapon_skill_preview() -> Dictionary:
 if session == null:return {"rows":[]}
 var uid := _inspected_item_uid()
 return WeaponSkills.project(_unit,session.campaign.items.get(uid,{}),session.campaign.battle)
func weapon_skill_expanded(id: String) -> bool:
 return bool(_expanded_skills.get(id,false))
func _toggle_weapon_skill(id: String) -> void:
 if not _browse_reason().is_empty() or not weapon_skill_buttons.has(id):return
 _expanded_skills[id] = not weapon_skill_expanded(id)
 _refresh_weapon_skills()
func _refresh_weapon_skills() -> void:
 if not is_instance_valid(weapon_skills_heading):return
 var data := weapon_skill_preview()
 if str(data.get("uid","")) != _skill_item_uid:
  _skill_item_uid = str(data.get("uid",""));_expanded_skills.clear();item_scroll.scroll_vertical = 0
 weapon_skills_heading.visible = not data.rows.is_empty()
 weapon_skills_context.visible = weapon_skills_heading.visible
 var owner_id: int = session.campaign.owner(_inspected_item_uid()) if session != null else -1
 var origin := "Owned stash" if owner_id < 0 else "Assigned to "+str(session.campaign.soldiers[owner_id].name)
 weapon_skills_context.text = "If equipped by %s\n%s · perks included · conditions apply" % [_unit.get("name",""),origin]
 weapon_skills_context.tooltip_text = weapon_skills_context.text+"\nNo target or movement discounts are assumed. Expand a skill for details."
 var supported: Array = data.rows.map(func(row):return row.id)
 for id: String in weapon_skill_buttons:weapon_skill_buttons[id].visible = id in supported
 for effect: Label in weapon_skill_effects.values():effect.hide()
 for row: Dictionary in data.rows:
  var button: Button = weapon_skill_buttons[row.id];button.show()
  button.text = "%s %s\n%d AP · %d fatigue%s" % ["▾" if weapon_skill_expanded(row.id) else "▸",row.name,row.ap,row.fatigue," †" if not row.notes.is_empty() else ""]
  var effect: Label = weapon_skill_effects[row.id]
  effect.text = row.effect+"\nRange: "+row.range+"\nRequires: "+row.requirements+("\n"+row.notes if not row.notes.is_empty() else "")
  effect.visible = weapon_skill_expanded(row.id)
  button.tooltip_text = effect.text
func _inspected_item_uid() -> String:
 if not selected_key.is_empty():return ""
 if session != null and session.campaign.items.has(_retained_weapon_uid):return _retained_weapon_uid
 return selected_item_id if not selected_item_id.is_empty() else str(_selected_row().get("item_id",""))
func _selected_row() -> Dictionary:
 for row: Dictionary in _slots+_carried:
  if row.key == selected_slot:return row
 return {}
func _workspace_reason() -> String:
 if _host_blocked():return "Close the checkpoint or battle overlay before outfitting."
 if is_instance_valid(perks_view) and perks_view.confirm_panel.visible:return "Finish or cancel the progression choice first."
 if is_instance_valid(details_panel) and details_panel.visible:return "Close Details before fitting."
 if is_instance_valid(market_panel) and market_panel.visible:return "Close town stock before fitting."
 return ""
func _camp_reason() -> String:
 if battle_read_only:return "Battle Company is read-only. Change equipment, reserves and training after battle."
 var reason := _workspace_reason()
 return reason if not reason.is_empty() else super._camp_reason()
func _memorial_reason() -> String:
 var reason := _workspace_reason()
 if not reason.is_empty():return reason
 if session == null:return "No company session is attached."
 if host == null or not is_instance_valid(host.world) or host.session != session:return "Memorial requires the mounted Company."
 if session.campaign.phase != "camp":return "Return after the battle before opening Memorial."
 if not session.campaign.encounter.is_empty():return "Resolve the current contact before opening Memorial."
 # Remembered companions remain readable after the last living companion falls.
 return ""
func _equip() -> void:
 if not _equip_reason().is_empty():return
 super._equip()
func _remove_reason() -> String:
 if not selected_key.is_empty():return "Company key item · read-only. Not equipment."
 if section != "equipment":return "Open Equipment before changing items."
 var reason := _camp_reason()
 return reason if not reason.is_empty() else session.campaign.equipment_change_reason(_person(),selected_slot,"")
func _equip_reason() -> String:
 if not selected_key.is_empty():return "Company key item · read-only. Cannot equip or sell."
 if section != "equipment":return "Open Equipment before changing items."
 var reason := _camp_reason()
 if not reason.is_empty():return reason
 if selected_item_id.is_empty():return "Choose a slot and an owned stash item."
 return session.campaign.equipment_change_reason(_person(),selected_slot,selected_item_id)
func _ammo_context() -> Dictionary:
 if not _camp_reason().is_empty() or section != "equipment" or session == null:return {}
 var c = session.campaign
 if selected_sid < 0 or selected_sid >= c.soldiers.size() or not c.soldiers[selected_sid].alive or not c.encounter.is_empty():return {}
 var records := {}
 for uid: String in c.refill_items(selected_sid):records[uid] = c.items[uid].duplicate(true)
 return {"session":session,"campaign":c,"sid":selected_sid,"person":c.soldiers[selected_sid],"records":records,"reserve":c.ammunition}
func _refresh_ammo() -> void:
 if not is_instance_valid(ammo_refill_button):return
 if _ammo_callback.is_valid() and ammo_refill_button.pressed.is_connected(_ammo_callback):ammo_refill_button.pressed.disconnect(_ammo_callback)
 var token := _ammo_context()
 _ammo_paint = token
 var needed: int = session.campaign.ammo_refill_cost(selected_sid) if session != null else 0
 var reserve: int = session.campaign.ammunition if session != null else 0
 var can_refill: bool = not token.is_empty() and session.campaign.can_refill_ammo(selected_sid)
 var state := "Carried packs full" if needed <= 0 else "Need %d to fill selected packs" % needed
 if needed > 0 and not can_refill:state += " · Not enough ammunition; buy at town Provisions & trade"
 elif needed > reserve:state += " · Partial refill available"
 ammo_status_label.text = "Ammunition %d · %s" % [reserve,state]
 ammo_status_label.tooltip_text = ammo_status_label.text+"\nArrows/bolts: 1 supply per round; throwing weapons: 3. Stored packs must be equipped first."
 ammo_refill_button.disabled = not can_refill
 ammo_refill_button.text = "Refill ammo" if needed > 0 else "Ammo full"
 ammo_refill_button.tooltip_text = "Fill this companion's equipped and carried packs from company reserve. No crowns or tools.\n"+ammo_status_label.tooltip_text
 _ammo_callback = _refill_ammo.bind(token)
 ammo_refill_button.pressed.connect(_ammo_callback)
func _refill_ammo(token: Dictionary) -> void:
 var current := _ammo_context()
 if token.is_empty() or not is_same(token,_ammo_paint) or current.is_empty() or current != token or not is_same(current.person,token.person) or ammo_refill_button.disabled:return
 # Consume the painted intent before synchronous changed/autosave callbacks.
 _ammo_paint = {}
 ammo_refill_button.disabled = true
 if _ammo_callback.is_valid() and ammo_refill_button.pressed.is_connected(_ammo_callback):ammo_refill_button.pressed.disconnect(_ammo_callback)
 if not session.campaign.refill_ammo(selected_sid):return
 _feedback = "Carried ammunition refilled from company reserve."
 session.changed.emit()
 refresh()
func _update_actions() -> void:
 _refresh_ammo()
 _sync_item_details_button()
 var reason := _equip_reason()
 equip_button.disabled = not reason.is_empty();equip_button.tooltip_text = reason
 reason = _remove_reason();remove_button.disabled = not reason.is_empty();remove_button.tooltip_text = reason
 reason_label.text = _feedback if not _feedback.is_empty() else _equip_reason()
 comparison_label.text = _comparison()
 for button: Button in slot_buttons.values()+carry_buttons.values()+roster_buttons.values(): button.disabled = not _browse_reason().is_empty()
 deploy_button.hide();deploy_button.disabled = true
 if is_instance_valid(formation_button):
  formation_button.disabled = not _camp_reason().is_empty()
  memorial_button.disabled = not _memorial_reason().is_empty()
  layered_button.disabled = PlayerWorkflows.LAYERED_ARMOR_PARKED or not _camp_reason().is_empty()
  for button: Button in section_buttons.values():button.disabled = _host_blocked() or details_panel.visible or market_panel.visible or perks_view.confirm_panel.visible
 if is_instance_valid(market_button):
  market_button.disabled = not _market_reason().is_empty() or market_panel.visible
  market_button.tooltip_text = _market_reason()
  back_button.disabled = market_panel.visible
  for button: Button in item_buttons.values():button.disabled = not _browse_reason().is_empty()
  _refresh_market()
func _label(font_size: int, color: Color, parent: Node) -> Label:
 var value := super._label(font_size,color,parent)
 value.add_theme_color_override("font_color",UI.TEXT if color == INK else UI.MUTED if color == MUTED else UI.GOLD)
 return value
func _button(text: String, parent: Node) -> Button:
 var value := super._button(text,parent)
 var primary := text == "Equip selected" or text.begins_with("Buy selected")
 value.add_theme_stylebox_override("normal",IronSkin.button(primary))
 value.add_theme_stylebox_override("hover",IronSkin.button(primary,true))
 value.add_theme_stylebox_override("pressed",IronSkin.button(true,true))
 value.add_theme_stylebox_override("disabled",IronSkin.button(primary,false,true))
 value.add_theme_stylebox_override("focus",UI.Press.focus())
 value.add_theme_font_override("font",load("res://assets/serif.ttf"))
 value.add_theme_font_size_override("font_size",17)
 value.autowrap_mode = TextServer.AUTOWRAP_OFF
 return value
func _card(heading: String) -> Panel:
 var card := Panel.new();card.add_theme_stylebox_override("panel",IronSkin.panel(12));add_child(card)
 var label := _label(19,GOLD,card);label.name = "Heading";label.text = heading
 label.add_theme_font_override("font",load("res://assets/serif.ttf"))
 label.autowrap_mode = TextServer.AUTOWRAP_OFF
 return card
func _style(background: Color, border: Color) -> StyleBoxFlat:
 return UI.panel(UI.SURFACE,UI.LINE,8)
func _mark(button: Button, selected: bool) -> void:
 if button.has_method("set_selected"):button.set_selected(selected)
 else:button.add_theme_stylebox_override("normal",IronSkin.button(false,selected))
func _sync_cards(buttons: Dictionary, parent: Control, rows: Array, key: String, handler: Callable, mode: String) -> void:
 var ids: Array = rows.map(func(row):return row[key])
 for id in buttons.keys():
  if id in ids:continue
  var old: Button = buttons[id]
  old.get_parent().remove_child(old);old.queue_free();buttons.erase(id)
 for row: Dictionary in rows:
  var id = row[key]
  if buttons.has(id):continue
  var button = load("res://company_town/company_roster_card.gd").new() if mode == "roster" else InventoryCard.new()
  button.mode = mode;parent.add_child(button)
  button.pressed.connect(handler.bind(id));buttons[id] = button
  if mode == "stash":
   button.gui_input.connect(_stash_repair_input.bind(button,id))
   var mark := TextureRect.new();mark.name = "RepairQueued"
   mark.texture = REPAIR_MARK;mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
   mark.position = Vector2(9,7);mark.size = Vector2(24,24)
   button.add_child(mark);UI.Press.mount_icon(mark,true);mark.hide()
  if mode != "roster":
   var target: String = "" if mode == "stash" else str(id)
   button.set_drag_forwarding(_inventory_drag.bind(button,target),_inventory_can_drop.bind(target,button),_inventory_drop.bind(target))
func _stash_repair_input(event: InputEvent, card: Button, uid: String) -> void:
 if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:return
 if event.pressed:
  # Capture the modifier at press time, before BaseButton arms selection.
  _repair_press = card if event.shift_pressed else null
  if _repair_press == card:card.accept_event()
  return
 if _repair_press != card:return
 _repair_press = null
 card.accept_event()
 if not Rect2(Vector2.ZERO,card.size).has_point(event.position):return
 if section != "equipment" or not _camp_reason().is_empty() or card.disabled or not card.is_visible_in_tree() or item_buttons.get(uid) != card or card.item_uid != uid:return
 var c = session.campaign
 if not c.repair_stored(uid):return
 _feedback = "Queued for repair over time." if uid in c.recovery.stored else "Repair cancelled."
 session.changed.emit()
func _inventory_drag(_position: Vector2, card: Button, source: String) -> Variant:
 if not selected_key.is_empty() or card == _repair_press:return null
 if section != "equipment" or not _camp_reason().is_empty() or card.disabled:return null
 var uid: String = card.item_uid
 var c = session.campaign
 if uid.is_empty() or not c.items.has(uid):return null
 if source.is_empty():
  if c.owner(uid) >= 0 or not c.parent_kit(uid).is_empty():return null
 elif c.slot_uid(_person(),source) != uid or c.owner(uid) != selected_sid:return null
 _drag_serial += 1
 _drag_ticket = {"kind":"bb2-equipment","workspace":get_instance_id(),"session":session.get_instance_id(),"campaign":c.get_instance_id(),"revision":_revision,"sid":selected_sid,"source":source,"uid":uid,"serial":_drag_serial}
 var ghost := InventoryCard.new();ghost.name = "InventoryDragPreview";ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ghost.size = Vector2(250,78)
 ghost.present("MOVING · "+card.heading.text,"Drop to fit / stash · Esc cancels",card.art.texture,uid,Inventory.item_tier(c.items[uid],c.catalog))
 ghost.modulate.a = .92;card.set_drag_preview(ghost)
 reason_label.text = "Dragging "+card.heading.text+" · drop on a slot or stash · Esc cancels"
 return _drag_ticket.duplicate(true)
func _inventory_drop_reason(data: Variant, target: String) -> String:
 if not selected_key.is_empty():return "Company key item · read-only."
 if section != "equipment":return "Open Equipment before changing items."
 var reason := _camp_reason()
 if not reason.is_empty():return reason
 if not data is Dictionary or _drag_ticket.is_empty() or data.size() != _drag_ticket.size():return "This drag is stale or foreign."
 for key in _drag_ticket:
  if not data.has(key) or typeof(data[key]) != typeof(_drag_ticket[key]) or data[key] != _drag_ticket[key]:return "This drag is stale or foreign."
 if data.workspace != get_instance_id() or data.session != session.get_instance_id() or data.campaign != session.campaign.get_instance_id() or data.revision != _revision or data.sid != selected_sid:return "The selected companion or equipment has changed."
 return session.campaign.equipment_move_reason(selected_sid,data.uid,data.source,target)
func _inventory_can_drop(_position: Vector2, data: Variant, target: String, surface: Control) -> bool:
 var reason := _inventory_drop_reason(data,target)
 _clear_drag_hint();_drag_hover = surface
 surface.self_modulate = Color(1.18,1.12,1.02) if reason.is_empty() else Color(.95,.66,.55)
 reason_label.text = ("Drop → "+("owned stash" if target.is_empty() else target.capitalize())) if reason.is_empty() else reason
 return reason.is_empty()
func _inventory_drop(_position: Vector2, data: Variant, target: String) -> void:
 if not _inventory_drop_reason(data,target).is_empty():return
 var uid: String = data.uid;var source: String = data.source
 _drag_ticket.clear();_clear_drag_hint()
 # Hold only this projection; synchronous host listeners still publish dirty state.
 _drop_refresh_held = true
 var accepted: bool = session.move_equipment(selected_sid,uid,source,target)
 _drop_refresh_held = false
 if accepted:
  _retained_weapon_uid = ""
  selected_item_id = uid if target.is_empty() else ""
  if not target.is_empty():selected_slot = target
  _feedback = "Moved to "+("owned stash." if target.is_empty() else target.capitalize()+".")
 if accepted or _drop_refresh_pending:
  _drop_refresh_pending = false
  refresh()
func _clear_drag_hint() -> void:
 if is_instance_valid(_drag_hover):_drag_hover.self_modulate = Color.WHITE
 _drag_hover = null
func _notification(what: int) -> void:
 if what == NOTIFICATION_DRAG_END:
  _drag_ticket.clear();_clear_drag_hint()
  if _ready_ui and is_inside_tree():_update_actions()
func _paint_inventory(people: Array) -> void:
 if session == null:return
 for person: Dictionary in people:
  var unit: Dictionary = session.preview_unit(person.id)
  var portrait := EngravedActors.portrait(unit)
  var row = roster_buttons[person.id]
  row.present(person.name,"HP %d / %d" % [person.hp,session.campaign.max_hp(person)],portrait,"",str(unit.get("companion_roll",{}).get("tier","")),person.hp,session.campaign.max_hp(person))
  row.set_assignment("%s · Lv %d" % ["FIELD" if person.id in session.campaign.active_ids() else "RESERVE",session.campaign.Progression.level(person)])
  row.present_vitals(unit)
  row.present_progression(person)
  row.present_injuries(person)
  row.tooltip_text = "%s · %s\n%s" % [person.name,row.assignment.text,row.vitals.tooltip_text]
 for row: Dictionary in _slots+_carried+_items:
  var is_slot: bool = row.has("key")
  var card = slot_buttons.get(row.get("key",""),carry_buttons.get(row.get("key",""))) if is_slot else item_buttons[row.item_id]
  var item: Dictionary = session.campaign.items.get(row.item_id,{})
  var icon := InventoryArt.item_icon(item,session.campaign.catalog,null,"")
  card.set_meta("icon_source",icon)
  var detail := _item_text(row)
  if not is_slot:detail=detail.trim_prefix(str(row.name)+" · ") # The stash heading already names the item.
  card.present(row.label if is_slot else row.name,detail,icon.get("texture"),row.item_id,Inventory.item_tier(item,session.campaign.catalog),row.condition,row.maximum)
  card.art.modulate = Color.WHITE # Wear is the meter, never a tint of the physical painting.
  if not is_slot:
   var repairable: bool = session.campaign.stored_repair_cost(row.item_id) > 0
   var queued: bool = repairable and row.item_id in session.campaign.recovery.stored
   card.get_node("RepairQueued").visible = queued
   if queued:card.tooltip_text += "\nQueued for repair"
   if repairable and not battle_read_only:card.tooltip_text += "\nShift-click to "+("cancel repair" if queued else "queue repair")
  if not item.is_empty() and icon.is_empty():card.tooltip_text += " · No exact item paint; actual item retained."
 var inspected: Dictionary = session.campaign.items.get(_inspected_item_uid(),{})
 item_art.texture = InventoryArt.item_icon(inspected,session.campaign.catalog,null,"").get("texture")
 item_art.modulate = Color.WHITE
 if not _unit.is_empty():
  var stats := Inventory.inventory_stats(_unit,session.campaign.battle)
  identity_label.text = "HP %d / %d    ·    Fatigue %d / %d    ·    %s" % [_unit.hp,_unit.max_hp,stats.fatigue,stats.fatigue_max,_unit.get("title","")]
 _paint_key_details()
func _select_slot(key: String) -> void:
 if not _browse_reason().is_empty() or not (slot_buttons.has(key) or carry_buttons.has(key)):return
 _retained_weapon_uid = ""
 selected_key = ""
 selected_slot = key;selected_item_id = "";_feedback = ""
 stash_scroll.scroll_vertical = 0;refresh()
func _select_bro(id: int) -> void:
 if not _browse_reason().is_empty() or not roster_buttons.has(id):return
 var uid := _inspected_item_uid()
 _retained_weapon_uid = uid if session.campaign.items.get(uid,{}).get("definition","") in Arsenal.WEAPONS else ""
 selected_key = ""
 selected_sid = id;_feedback = "";refresh()
func _refresh_keyring() -> void:
 _owned_keys = VaultItems.owned(session.campaign) if session != null else []
 if not _owned_keys.any(func(entry):return entry.key_id == selected_key):selected_key = ""
 for card in key_buttons.values():
  card.get_parent().remove_child(card);card.queue_free()
 key_buttons.clear();keyring.visible = not _owned_keys.is_empty()
 key_heading.text = "COMPANY KEYRING · %d" % _owned_keys.size()
 for entry: Dictionary in _owned_keys:
  var card = KeyCard.new();card.mode = "slot";card.custom_minimum_size = Vector2(0,110)
  key_grid.add_child(card)
  card.present(entry.name,entry.destination,VaultItems.artwork(),"")
  card.annotate("", "Vault opened" if entry.opened else "Held")
  card.rarity_label.text = "Company key item"
  card.set_selected(entry.key_id == selected_key)
  card.tooltip_text = entry.destination+"\n"+entry.status+" · read-only"
  card.pressed.connect(_select_key.bind(entry.key_id));key_buttons[entry.key_id] = card
func _select_key(id: String) -> void:
 if not _browse_reason().is_empty() or not key_buttons.has(id):return
 _retained_weapon_uid = ""
 selected_key = id;selected_item_id = "";_feedback = ""
 item_scroll.scroll_vertical = 0
 # These cards are intentionally outside item_buttons and drag forwarding.
 for key: String in key_buttons:key_buttons[key].set_selected(key == id)
 _drag_ticket.clear();_clear_drag_hint();_refresh_weapon_skills();_paint_key_details();_update_actions();_layout()
func _paint_key_details() -> void:
 if selected_key.is_empty():return
 var entry := VaultItems.row(session.campaign,selected_key)
 if entry.is_empty():return
 item_detail_heading.text = "VAULT KEY · READ-ONLY"
 item_detail_heading.tooltip_text = entry.name+" · Company key item · read-only"
 item_art.texture = VaultItems.artwork();item_art.modulate = Color.WHITE
 item_summary.text = entry.name+"\n"+VaultItems.details(entry)+("\n\nNo artwork" if item_art.texture == null else "")
 item_summary.tooltip_text = item_summary.text
 item_provenance.hide() # Use only the existing spoiler-safe key projection.
 mapping_notes.text = item_summary.text
func _item_text(row: Dictionary) -> String:
 var uid := str(row.get("item_id",""))
 if uid.is_empty() or session == null:return "Empty"
 return Presentation.identity(session.campaign.items.get(uid,{}),session.campaign.catalog)
func _sync_item_details_button() -> void:
 var available := section == "equipment" and (not selected_key.is_empty() or not _inspected_item_uid().is_empty())
 if not available:item_detail_frame.hide()
 item_details_button.disabled = not available or not _browse_reason().is_empty()
 item_details_button.text = "Close item" if item_detail_frame.visible else "Item details"
 item_details_button.tooltip_text = "Close item details [Esc]" if item_detail_frame.visible else "Inspect the selected item: stats, weapon skills and full item record" if available else "Select an item to inspect"
func _toggle_item_details() -> void:
 if item_details_button.disabled or not item_details_button.is_visible_in_tree() or not _browse_reason().is_empty():return
 item_detail_frame.visible = not item_detail_frame.visible
 if item_detail_frame.visible:
  item_scroll.scroll_vertical = 0
  item_scroll.grab_focus()
 else:item_details_button.grab_focus()
 _sync_item_details_button()
func _open_details() -> void:
 if section != "equipment" or not _browse_reason().is_empty() or _person().is_empty():return
 _details_owner = {"session":session,"campaign":session.campaign,"sid":selected_sid,"person":_person(),"slot":selected_slot,"item":selected_item_id,"key":selected_key}
 pages.present(_person(),session.campaign,_unit)
 details_panel.show();mapping_scroll.scroll_vertical = 0
 _update_actions();details_close_button.grab_focus()
func _close_details() -> void:
 if _host_blocked() or not details_panel.visible:return
 if not _details_current():_retire_details();_update_actions();return
 _retire_details();_update_actions();details_button.grab_focus()
func _layout() -> void:
 if not _ready_ui:return
 var margin := 12.0
 var gap := 12.0
 var top := 104.0
 var height := size.y-top-62
 var roster_width := clampf(size.x*.18,188,300)
 var stash_width := clampf(size.x*.285,310,480)
 var middle_x := margin+roster_width+gap
 var middle_width := size.x-margin*2-roster_width-stash_width-gap*2
 var carry_height := 122.0
 var header_width := maxf(stash_width,minf(size.x*.47,530))
 var header_x := size.x-header_width-22
 var title_x := roster_width+30
 _place(title_label,title_x,6,minf(middle_width,header_x-title_x-14),38)
 title_label.add_theme_font_size_override("font_size",24 if size.x < 1300 else 31)
 _place(subtitle_label,22,14,roster_width,24)
 _place(resource_label,size.x-stash_width-22,12,stash_width,40)
 resource_label.add_theme_font_size_override("font_size",12 if size.x < 1400 else 14)
 _place(resource_header,header_x,6,header_width,38)
 _place(back_button,margin,54,roster_width,38)
 var tab_width := minf(164,(size.x-middle_x-180)/3)
 for index in section_buttons.size():_place(section_buttons.values()[index],middle_x+index*(tab_width+8),54,tab_width,38)
 _place(formation_button,size.x-154,54,142,38)
 _place(perks_view,middle_x,top,size.x-middle_x-margin,height)
 if is_instance_valid(battle_pages):
  var fit: float = minf((size.x-middle_x-margin)/1440.0,height/900.0)
  battle_pages.scale = Vector2.ONE*fit
  battle_pages.position = Vector2(middle_x,top)+(Vector2(size.x-middle_x-margin,height)-Vector2(1440,900)*fit)*0.5
  battle_page_focus.position = battle_pages.position;battle_page_focus.size = Vector2(1440,900)*fit
 _place(recovery_label,20,size.y-54,size.x-250,24)
 _place(ammo_status_label,20,size.y-27,size.x-250,22)
 _place(ammo_refill_button,size.x-222,size.y-48,202,32)
 checkpoint_label.hide() # Compact footer; retain the autosave policy on Back.
 back_button.tooltip_text = checkpoint_label.text
 _place(roster_card,margin,top,roster_width,height)
 _place(portrait_card,middle_x,top,middle_width,height-carry_height-gap)
 _place(carry_card,middle_x,top+height-carry_height,middle_width,carry_height)
 _place(stash_card,size.x-margin-stash_width,top,stash_width,height)
 for card in [roster_card,stash_card,carry_card]:_place(card.get_node("Heading"),14,10,card.size.x-28,26)
 stash_title.add_theme_font_size_override("font_size",16 if size.x < 1400 else 19)
 _place(roster_counts,14,38,roster_width-28,22)
 _place(roster_scroll,9,68,roster_width-18,height-124)
 _place(memorial_button,10,height-48,roster_width-20,38)
 for row: Button in roster_buttons.values():row.custom_minimum_size = Vector2(0,112 if size.x >= 1400 else 96)
 _place(market_button,roster_card.position.x+10,roster_card.position.y+height-52,roster_width-20,40)
 market_button.text = "Town stock";market_button.tooltip_text = _market_reason()
 _place(name_label,10,0,middle_width-126,38)
 _place(identity_label,10,40,middle_width-20,24)
 _place(details_button,middle_width-112,2,102,36)
 var flank := floorf(middle_width*.29)
 var figure_x := flank+8
 var figure_width := middle_width-flank*2-16
 var figure_height := portrait_card.size.y-74
 _place(preview,figure_x,70,figure_width,figure_height)
 if selected_level_badge != null:
  selected_level_badge.position=Vector2(maxf(0,figure_width-24),0);selected_level_badge.size=Vector2(24,24)
 var card_height := minf(90,(portrait_card.size.y-132)/5)
 var slot_top := 86.0
 for index in LEFT_SLOTS.size():
  if slot_buttons.has(LEFT_SLOTS[index]):_place(slot_buttons[LEFT_SLOTS[index]],0,slot_top+index*(card_height+10),flank,card_height)
 for index in RIGHT_SLOTS.size():
  if slot_buttons.has(RIGHT_SLOTS[index]):_place(slot_buttons[RIGHT_SLOTS[index]],middle_width-flank,slot_top+index*(card_height+8),flank,card_height)
 _place(remove_button,0,portrait_card.size.y-42,flank,36)
 _place(omission_label,flank+10,portrait_card.size.y-18,figure_width,18)
 omission_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS;omission_label.autowrap_mode = TextServer.AUTOWRAP_OFF
 _place(carry_heading,14,10,middle_width-170,26)
 _place(layered_button,middle_width-146,8,132,32)
 _place(carry_row,12,48,middle_width-24,carry_height-56)
 for card: Button in carry_buttons.values():card.custom_minimum_size = Vector2(0,carry_height-50)
 _place(stash_scroll,12,48,stash_width-24,height-148)
 for card: Button in item_buttons.values():card.custom_minimum_size = Vector2(0,116 if size.x < 1400 else 140)
 _place(_empty_stash,22,64,stash_width-44,100)
 var detail_width := minf(434,middle_width)
 _place(item_detail_frame,middle_x+middle_width-detail_width,top,detail_width,height)
 item_detail_heading.text = "ITEM DETAILS"
 item_detail_heading.tooltip_text = ""
 _place(item_detail_heading,12,7,detail_width-69,30)
 _place(item_art,detail_width-48,5,40,40)
 _place(item_scroll,12,49,detail_width-24,height-61)
 if not selected_key.is_empty():_paint_key_details()
 _place(reason_label,18,height-91,stash_width-36,32)
 reason_label.max_lines_visible = 2
 var inspect_width := minf(154,(stash_width-36)*.46)
 _place(equip_button,18,height-53,stash_width-inspect_width-44,42)
 _place(item_details_button,stash_width-inspect_width-18,height-53,inspect_width,42)
 if is_instance_valid(market_panel):
  market_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  var side := maxf(16,(size.x-920)/2)
  _place(market_heading,side,24,size.x-side*2,64)
  _place(market_scroll,side,98,size.x-side*2,maxf(80,size.y-256))
  _place(market_reason_label,side,size.y-150,size.x-side*2,80)
  _place(market_buy_button,side,size.y-60,300,44)
  _place(market_close_button,size.x-side-244,size.y-60,244,44)
 if is_instance_valid(details_panel):
  details_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _build_market() -> void:
 market_button = _button("Town stock · Buy equipment",self)
 market_button.pressed.connect(_open_market)
 market_panel = Panel.new();market_panel.mouse_filter = Control.MOUSE_FILTER_STOP
 market_panel.add_theme_stylebox_override("panel",IronSkin.panel(16))
 add_child(market_panel)
 market_heading = _label(20,INK,market_panel)
 market_scroll = _scroll(market_panel);market_list = market_scroll.get_child(0)
 market_reason_label = _label(14,INK,market_panel)
 market_buy_button = _button("Buy selected → owned stash",market_panel)
 market_buy_button.pressed.connect(_buy_market)
 market_close_button = _button("Back to Inventory [Esc]",market_panel)
 market_close_button.pressed.connect(_close_market)
 market_panel.hide()
func _market_reason() -> String:
 var reason := super._camp_reason()
 if not reason.is_empty():return reason
 if host == null or host.outfitting != self:return "Town stock requires the mounted Company inventory."
 if host.error_panel.visible or host.aftermath_panel.visible or is_instance_valid(host.field):return "Resolve the checkpoint or battle overlay first."
 if is_instance_valid(host.world) and (host.world.help or host.world.intro or not host.world.confirmation.is_empty() or not host.world.iron.sheet.is_empty()):return "Close the other modal first."
 if not session.campaign.in_town():return "Town stock is only available while physically in town."
 if not session.campaign.encounter.is_empty() or not session.campaign.dungeons.active.is_empty():return "Resolve the current contact first."
 return ""
func _market_offers() -> Array:
 if session == null or not _market_reason().is_empty():return []
 var c = session.campaign
 var out: Array = []
 for offer: Dictionary in c.weapons_stock():
  var row := offer.duplicate(true);row["kind"] = offer.get("kind","weapon");out.append(row)
 for group in ["body","head"]:
  for layer in (["base","mail","outer"] if group == "body" else ["shell"]):
   for offer: Dictionary in c.armorer_stock(group,layer):
    var row := offer.duplicate(true);row["kind"] = offer.get("kind","component");out.append(row)
 return out
func _open_market() -> void:
 if details_panel.visible or not _market_reason().is_empty():return
 if is_instance_valid(details_panel):details_panel.hide()
 _market_feedback = "";market_panel.show();refresh()
 market_close_button.grab_focus()
func _close_market() -> void:
 if _host_blocked():return
 market_panel.hide();refresh();inventory_tab.grab_focus()
func _select_market(id: String) -> void:
 if not market_panel.visible or not _market_reason().is_empty():return
 _market_selection = id;_market_feedback = "";_refresh_market()
func _market_buy_reason() -> String:
 var reason := _market_reason()
 if not reason.is_empty():return reason
 if not market_panel.visible:return "Open town stock first."
 if _market_selection.is_empty():return "Choose an offer. Purchases go to your stash; equip separately."
 for offer: Dictionary in _market_offers():
  if offer.id == _market_selection:
   if Offer.stock_item(offer).is_empty():return "Roll details unavailable. No purchase possible."
   return "Not enough crowns: need %d; have %d." % [offer.price,session.campaign.crowns] if session.campaign.crowns < offer.price else ""
 return "Sold out or no longer offered here. No purchase made."
func _refresh_market() -> void:
 if not is_instance_valid(market_panel) or not market_panel.visible:return
 var offers := _market_offers()
 for offer: Dictionary in offers:_market_seen[offer.id] = offer.duplicate(true)
 var rows: Array = _market_seen.values()
 _sync_buttons(market_buttons,market_list,rows,"id",_select_market)
 for offer: Dictionary in rows:
  var button: Button = market_buttons[offer.id]
  var available: bool = offers.any(func(row):return row.id == offer.id)
  var d: Dictionary = session.campaign.catalog.get(offer.definition,{})
  var item := Offer.stock_item(offer)
  available = available and not item.is_empty()
  var tier: String = Inventory.item_tier(item,session.campaign.catalog)
  var properties := Offer.lines(offer,session.campaign.catalog,session.campaign.battle.weapons)
  button.text = "%s · %s · %s · %d crowns%s\n%s" % [d.get("name",offer.definition),tier.capitalize() if not tier.is_empty() else "Roll unavailable",str(d.get("slot",d.get("group","equipment"))).capitalize(),offer.price,"" if available else " · Sold out / unavailable","\n".join(properties)]
  button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  button.custom_minimum_size.y = 108
  button.tooltip_text = button.text+"\n"+preload("res://company_town/equipment_offer.gd").BASE_NOTE+"\nOffer "+offer.id
  var icon := InventoryArt.item_icon(item,session.campaign.catalog,null,"")
  button.set_meta("icon_source",icon)
  button.icon = icon.get("texture")
  button.expand_icon = true;button.add_theme_constant_override("icon_max_width",64)
  if icon.is_empty():
   button.text += "\nNo standalone art"
   button.tooltip_text += " · No standalone art; actual offer retained."
  button.disabled = not _market_reason().is_empty() or item.is_empty()
  _mark(button,offer.id == _market_selection)
 market_heading.text = "TOWN STOCK · %s · %d crowns\n%s" % [session.campaign.node().get("name","Town"),session.campaign.crowns,preload("res://company_town/equipment_offer.gd").BASE_NOTE]
 var reason := _market_buy_reason()
 market_buy_button.disabled = not reason.is_empty();market_buy_button.tooltip_text = reason
 market_reason_label.text = _market_feedback if not _market_feedback.is_empty() else reason if not reason.is_empty() else "Ready to buy the selected exact offer. No automatic fitting."
 if not _market_reason().is_empty():market_reason_label.text = _market_reason()+"\n"+_market_feedback
func _buy_market() -> void:
 var reason := _market_buy_reason()
 if not reason.is_empty():_market_feedback = reason;_refresh_market();return
 for offer: Dictionary in _market_offers():
  if offer.id != _market_selection:continue
  var uid: String = session.campaign.buy_weapon(offer.id) if offer.kind == "weapon" else session.campaign.buy_component(offer.id)
  if uid.is_empty():_market_feedback = "Purchase refused; no item received."
  else:
   _market_feedback = "Bought for %d crowns → owned stash · %s. Equip separately." % [offer.price,uid]
   session.changed.emit() # Publish gameplay; checkpoint only on explicit Save.
   if not host.saved_ok:_market_feedback += " UNSAVED · use Save to checkpoint."
  refresh();return
func observation() -> Dictionary:
 var out := super.observation()
 out.actions.erase("deploy");out.buttons.erase("deploy")
 out.actions["back"] = _target(back_button)
 out["carried_slots"] = _carried.duplicate(true)
 out["vault_keys"] = []
 for entry: Dictionary in _owned_keys:
  var row := entry.duplicate(true);row["button"] = _target(key_buttons[entry.key_id])
  row["art_status"] = "No artwork" if key_buttons[entry.key_id].art.texture == null else "Key artwork"
  out.vault_keys.append(row)
 out["selected_key"] = selected_key
 out.scrolls["slots"] = _rect(_canvas_rect(portrait_card))
 out.scrolls["carried"] = _rect(_canvas_rect(carry_row))
 out["inventory_layout"] = {"direction":"B / Iron & Oath","stash_columns":inventory_grid.columns,"roster":_rect(_canvas_rect(roster_card)),"figure_stage":_rect(_canvas_rect(portrait_card)),"carried":_rect(_canvas_rect(carry_card)),"stash":_rect(_canvas_rect(stash_card)),"resources":resource_label.text}
 out.targets["carried"] = {}
 for slot: String in carry_buttons:out.targets.carried[slot] = _target(carry_buttons[slot])
 out["details_text"] = pages.character_text
 out["mapping_text"] = mapping_notes.text
 out["details_open"] = details_panel.visible
 out["item_summary"] = item_summary.text
 out.actions["item_details"] = _target(item_details_button)
 out["item_details_open"] = item_detail_frame.visible
 out.actions["details"] = _target(details_button)
 out.actions["town_stock"] = _target(market_button)
 out["market"] = {"open":market_panel.visible,"selection":_market_selection,"reason":market_reason_label.text,"buy":_target(market_buy_button),"close":_target(market_close_button),"offers":_market_seen.values().duplicate(true),"targets":{}}
 for id in market_buttons:out.market.targets[id] = _target(market_buttons[id])
 out["company"] = {"section":section,"sections":{},"formation":_target(formation_button),"recovery":recovery_label.text,"character_text":pages.character_text,"page_rect":_rect(_canvas_rect(pages)),"page_scroll":_rect(_canvas_rect(pages.scroll)),"field_ids":session.campaign.active_ids(),"reserve_ids":session.campaign.reserve_ids()}
 out.company["perks"] = perks_view.observation()
 out.company["navigation"] = {"formation":_target(formation_button),"armor":_target(layered_button),"memorial":_target(memorial_button)}
 for id: String in pages.navigation_buttons:out.company.navigation[id] = _target(pages.navigation_buttons[id])
 for id: String in section_buttons:out.company.sections[id] = _target(section_buttons[id])
 out.merge(Inventory.unit_observation(_unit,session.campaign.battle),true)
 return out
