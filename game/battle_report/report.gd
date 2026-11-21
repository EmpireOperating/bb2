extends Control
## Read-only settlement projection. Campaign/session alone own rewards and return.
signal return_requested
const UI = preload("res://ui_polish/style.gd")
const IronSkin = preload("res://iron_oath/skin.gd")
const Presentation = preload("res://ui_polish/inventory_presentation.gd")
const InventoryArt = preload("res://iron_oath/inventory_art.gd")
const Equipment = preload("res://hollow_campaign/appearance.gd")
const LootCard = preload("res://battle_report/loot_card.gd")
const GearText = preload("res://battle_report/equipment_text.gd")
const VaultItems = preload("res://vault_key_items/presentation.gd")
const HEADERS := ["COMPANION","STATUS","HP","DAMAGE\nDealt","DAMAGE\nReceived","KILLS","XP"]
var return_button: Button
var scroll: ScrollContainer
var content: VBoxContainer
var result_label: Label
var mission_label: Label
var context_label: Label
var summary: HBoxContainer
var resource_totals: Label
var resource_sources: Label
var resource_section: VBoxContainer
var payment_text := ""
var table: VBoxContainer
var consequence_label: Label
var _session
var _result: Dictionary = {}
var _rows: Array = []
var _margin: MarginContainer
var loot_grid: GridContainer
var loot_heading: Label
var loot_empty: Label
var loot_buttons: Dictionary = {}
var selected_uid := ""
var detail_label: Label
var detail_scroll: ScrollContainer
var detail_art: TextureRect
var detail_title: Label
var detail_art_status: Label
var _inspector: VBoxContainer
const EngravedActors = preload("res://engraved_people/actors.gd")
var appearance_name := ""
var _loot_rows: Array = []
var _portraits: Dictionary = {}
func _ready() -> void:
 theme = UI.theme()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 var backdrop := TextureRect.new();backdrop.texture = IronSkin.texture("camp")
 backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(backdrop);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var veil := ColorRect.new();veil.color = Color(0.025,0.032,0.028,.88);veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(veil);veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _margin = MarginContainer.new();add_child(_margin);_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var column := VBoxContainer.new();column.add_theme_constant_override("separation",12);_margin.add_child(column)
 var header := _section(column)
 header.get_parent().add_theme_stylebox_override("panel",UI.Press.box("paper",12,12))
 _label("THE ASHEN COMPANY  /  BATTLE REPORT",14,UI.Press.PAPER_NOTE,header)
 var title_row := HBoxContainer.new();title_row.add_theme_constant_override("separation",28);header.add_child(title_row)
 result_label = _label("",38,UI.Press.PAPER_INK,title_row,true);result_label.custom_minimum_size.x = 205
 var mission := VBoxContainer.new();mission.size_flags_horizontal = Control.SIZE_EXPAND_FILL;title_row.add_child(mission)
 mission_label = _label("",23,UI.Press.PAPER_INK,mission,true);mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 context_label = _label("",13,UI.Press.PAPER_NOTE,mission)
 scroll = ScrollContainer.new();scroll.name = "ReportScroll";scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus = true;column.add_child(scroll)
 content = VBoxContainer.new();content.size_flags_horizontal = Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",12);scroll.add_child(content)
 summary = HBoxContainer.new();summary.add_theme_constant_override("separation",12);content.add_child(summary)
 resource_section = _section(content)
 _label("RECOVERED RESOURCES  /  ALREADY IN COMPANY STORES",17,UI.GOLD,resource_section,true)
 resource_totals = _label("",20,UI.TEXT,resource_section,true);resource_totals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 resource_sources = _label("",13,UI.MUTED,resource_section);resource_sources.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var company := _section(content);_label("COMPANY PERFORMANCE",17,UI.GOLD,company,true)
 table = VBoxContainer.new();table.add_theme_constant_override("separation",2);company.add_child(table)
 var loot := _section(content)
 loot_heading = _label("RECOVERED LOOT",17,UI.GOLD,loot,true)
 var note := _label("Already recovered · select a card to inspect. No equipment changes or extra claim.",12,UI.MUTED,loot)
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 loot_empty = _label("No loot recovered from this battle.",15,UI.MUTED,loot)
 var loot_body := HBoxContainer.new();loot_body.add_theme_constant_override("separation",12);loot.add_child(loot_body)
 loot_grid = GridContainer.new();loot_grid.columns = 3;loot_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 loot_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN;loot_grid.add_theme_constant_override("h_separation",8);loot_grid.add_theme_constant_override("v_separation",8);loot_body.add_child(loot_grid)
 _inspector = _section(loot_body);_inspector.get_parent().custom_minimum_size.x = 310
 _inspector.get_parent().size_flags_horizontal = Control.SIZE_FILL
 var detail_top := HBoxContainer.new();_inspector.add_child(detail_top)
 detail_art = TextureRect.new();detail_art.custom_minimum_size = Vector2(64,64)
 detail_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;detail_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;detail_art.mouse_filter = Control.MOUSE_FILTER_IGNORE;detail_top.add_child(detail_art);UI.Press.mount_icon(detail_art)
 var detail_identity := VBoxContainer.new();detail_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL;detail_top.add_child(detail_identity)
 detail_title = _label("Select recovered loot",18,UI.TEXT,detail_identity,true);detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_art_status = _label("",12,UI.MUTED,detail_identity)
 detail_scroll = ScrollContainer.new();detail_scroll.custom_minimum_size.y = 220;detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;_inspector.add_child(detail_scroll)
 detail_label = _label("",13,UI.TEXT,detail_scroll);detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var consequences := _section(content);_label("LASTING CONSEQUENCES",17,UI.GOLD,consequences,true)
 consequence_label = _label("",14,UI.TEXT,consequences);consequence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var footer := _section(column)
 return_button = Button.new();return_button.name = "ReturnToWorld";return_button.text = "Return to world · keep these results"
 UI.button(return_button,true);return_button.custom_minimum_size.y = 44;return_button.add_theme_font_override("font",load("res://assets/serif.ttf"));return_button.add_theme_font_size_override("font_size",19)
 footer.add_child(return_button);return_button.pressed.connect(func():return_requested.emit())
 var save_note := _label("Review only · returning saves your company. No healing, repairs or second loot claim.",12,UI.MUTED,footer)
 save_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;save_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 resized.connect(_layout);_layout()
func _section(parent: Node) -> VBoxContainer:
 var panel := PanelContainer.new();panel.add_theme_stylebox_override("panel",IronSkin.panel(12));panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL;parent.add_child(panel)
 var box := VBoxContainer.new();box.add_theme_constant_override("separation",8);panel.add_child(box);return box
func _label(text_value: String, font_size: int, color: Color, parent: Node, serif: bool = false) -> Label:
 var label := Label.new();UI.label(label,font_size,color);label.text = text_value;label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if serif:label.add_theme_font_override("font",load("res://assets/serif.ttf"))
 parent.add_child(label);return label
func _clear(parent: Node) -> void:
 for child in parent.get_children():parent.remove_child(child);child.queue_free()
func present(session_value) -> void:
 _session = session_value;_result = _session.campaign.aftermath.duplicate(true);_rows.clear()
 result_label.text = "WITHDRAWAL" if _result.get("retreat",false) else str(_result.get("result","")).to_upper()
 result_label.add_theme_color_override("font_color",UI.Press.PAPER_INK if result_label.text == "VICTORY" else UI.Press.PAPER_RED)
 mission_label.text = str(_result.get("title","Company sortie"))
 context_label.text = "Day %d   ·   Round %d   ·   Settlement complete" % [_result.get("day",0),_result.get("round",0)]
 _clear(summary)
 var pending: Dictionary = _session.campaign.payment_pending
 var due: int = int(pending.get("job",{}).get("pay",0))
 payment_text = "CONTRACT PAYMENT DUE · %d crowns" % due if due > 0 else "MISSION PAYMENT RECEIVED · %d crowns" % _result.get("pay",0)
 for stat in [["CONTRACT PAYMENT DUE" if due > 0 else "MISSION PAYMENT RECEIVED",str(due if due > 0 else _result.get("pay",0)),UI.GOLD],["FALLEN",str(_result.get("fallen",0)),UI.DANGER],["WOUNDED",str(_result.get("wounded",0)),UI.TEXT]]:
  var box := _section(summary);_label(stat[0],12,UI.MUTED,box);_label(stat[1],24,stat[2],box,true)
 var resources: Dictionary = _result.get("resource_spoils",{})
 resource_totals.text = _resource_text(resources.get("total",{}))
 resource_sources.text = "Pockets: %s\nCamp personal stash: %s\nExisting camp stores: %s · Carried rations recovered: %d\nImmediate spoils, not contract payment. Food and stolen camp crowns credit the small personal-supply targets." % [_resource_text(resources.get("pockets",{})),_resource_text(resources.get("camp_stash",{})),_resource_text(resources.get("camp_stores",{})),resources.get("carried_food",0)]
 if not resources.get("materials",{}).is_empty():resource_sources.text += "\nRecovered trade cargo: "+_session.campaign.economy.freight.describe(resources.materials)
 _prepare_art()
 _clear(table);_table_line(HEADERS,true)
 for row: Dictionary in _result.get("rows",[]):
  var display := row.duplicate(true)
  display.damage_hp = maxi(0,int(row.get("damage_hp",0)));display.damage_armor = maxi(0,int(row.get("damage_armor",0)));display.damage_shield = maxi(0,int(row.get("damage_shield",0)))
  display.damage_total = display.damage_hp+display.damage_armor+display.damage_shield
  # Missing received counters are unknown, never inferred from HP-only injury data.
  display.damage_received = row.get("damage_received") if row.get("damage_received") is int and row.damage_received >= 0 else null
  _rows.append(display)
  _table_line([str(row.get("name","Unknown companion")),str(row.get("status","")),str(row.get("hp",0)),str(display.damage_total),str(display.damage_received) if display.damage_received != null else "—",str(row.get("kills",0)),"+"+str(row.get("xp",0))],false,row)
 consequence_label.text = str(_result.get("effect",""))+"\n\nWounds, casualties and equipment damage persist. Returning to the world does not heal or repair the company."
 _present_loot()
 scroll.scroll_vertical = 0
func _prepare_art() -> void:
 _portraits.clear()
 appearance_name = "engraved-company"
 for row: Dictionary in _result.get("rows",[]):
  var id := int(row.get("id",-1))
  var unit: Dictionary = _session.preview_unit(id)
  _portraits[id] = EngravedActors.portrait(unit)
func _resource_text(amounts: Dictionary) -> String:
 return "+%d crowns · +%d rations · +%d tools · +%d medicine" % [amounts.get("crowns",0),amounts.get("food",0),amounts.get("tools",0),amounts.get("medicine",0)]
func _present_loot() -> void:
 var previous := selected_uid
 _clear(loot_grid);loot_buttons.clear();_loot_rows.clear()
 var c = _session.campaign
 for row: Dictionary in _result.get("loot",[]):
  var uid := str(row.get("item",""))
  var item: Dictionary = c.items.get(uid,{})
  var d: Dictionary = c.item_def(uid)
  var icon := InventoryArt.item_icon(item,c.catalog,null,"")
  var card = LootCard.new();card.name = "Recovered_"+uid;card.mode = "slot";card.custom_minimum_size = Vector2(150,110)
  loot_grid.add_child(card)
  var tier := Equipment.item_tier(item,c.catalog)
  var maximum := int(item.get("maximum",d.get("durability",0)))
  var condition := int(item.get("condition",0))
  var item_name := GearText.title(item,c.catalog)
  var identity := GearText.identity(item,c.catalog)
  card.present(item_name,identity,icon.get("texture"),uid,tier,condition,maximum)
  var round_supply := Equipment.is_round_supply(d)
  var condition_text := "%s %d/%d" % ["Rounds" if round_supply else "Condition",condition,maximum] if maximum > 0 else "No durability"
  if maximum > 0 and condition <= 0:condition_text += " · EMPTY" if round_supply else " · BROKEN"
  card.annotate(tier,condition_text);card.set_meta("icon_source",icon)
  card.tooltip_text = identity
  card.pressed.connect(_select_loot.bind(uid));loot_buttons[uid] = card
  _loot_rows.append({"uid":uid,"name":item_name,"source":row.get("source",""),"tier":tier,"condition":condition,"maximum":maximum,"art_status":"No artwork" if icon.is_empty() else "Exact inventory artwork","art_key":icon.get("art_key","")})
 # Only explicit settlement receipts enter recovered loot, never old prose or
 # the complete historical keyring. Key IDs remain separate from equipment UIDs.
 for id in _result.get("vault_keys",[]):
  if not id is String:continue
  var entry := VaultItems.row(c,id)
  if entry.is_empty():continue
  var token: String = "vault_key:"+id
  var card = LootCard.new();card.name = "RecoveredVaultKey";card.mode = "slot";card.custom_minimum_size = Vector2(150,110)
  loot_grid.add_child(card)
  card.present(entry.name,entry.destination,VaultItems.artwork(),"")
  card.annotate("", "");card.rarity_label.text = "Company key item"
  card.tooltip_text = entry.destination+"\n"+entry.status+" · read-only"
  card.set_meta("vault_key",entry)
  card.pressed.connect(_select_loot.bind(token));loot_buttons[token] = card
  entry["uid"] = token;entry["art_status"] = "No artwork" if card.art.texture == null else "Key artwork"
  _loot_rows.append(entry)
 loot_heading.text = "RECOVERED LOOT  /  %d ITEMS" % _loot_rows.size()
 loot_empty.visible = _loot_rows.is_empty();_inspector.get_parent().visible = not _loot_rows.is_empty()
 selected_uid = ""
 if loot_buttons.has(previous):_select_loot(previous)
 elif not _loot_rows.is_empty():_select_loot(str(_loot_rows[0].uid))
 else:detail_label.text = "";detail_art.texture = null;detail_title.text = "No recovered loot"
 _layout()
func _select_loot(uid: String) -> void:
 if not loot_buttons.has(uid):return
 selected_uid = uid
 for key: String in loot_buttons:loot_buttons[key].set_selected(key == uid)
 var c = _session.campaign
 var item: Dictionary = c.items.get(uid,{})
 var card = loot_buttons[uid]
 if card.has_meta("vault_key"):
  detail_title.text = card.heading.text;detail_art.texture = card.art.texture
  detail_art_status.visible = true
  detail_art_status.text = "No artwork" if card.art.texture == null else "Key artwork · company keyring"
  detail_label.text = VaultItems.details(card.get_meta("vault_key"));detail_scroll.scroll_vertical = 0
  return
 detail_title.text = card.heading.text;detail_art.texture = card.art.texture
 detail_art_status.text = "No artwork" if card.art.texture == null else ""
 detail_art_status.visible = card.art.texture == null
 detail_label.text = GearText.details(item,c.catalog)
 detail_scroll.scroll_vertical = 0
func _table_line(values: Array, heading: bool, row: Dictionary = {}) -> void:
 var panel := PanelContainer.new();panel.add_theme_stylebox_override("panel",UI.panel(UI.BG if heading else Color("1b211e"),UI.LINE,6));table.add_child(panel)
 var line := HBoxContainer.new();line.add_theme_constant_override("separation",8);panel.add_child(line)
 var widths := [170,96,44,95,95,44,46]
 for index in values.size():
  var cell := HBoxContainer.new();cell.custom_minimum_size.x = widths[index]
  cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL if index == 0 else Control.SIZE_FILL;line.add_child(cell)
  if index == 0 and not heading and _portraits.get(int(row.get("id",-1))) != null:
   var portrait := TextureRect.new();portrait.texture = _portraits[int(row.id)]
   portrait.custom_minimum_size = Vector2(38,38);portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE;cell.add_child(portrait)
   var badge = preload("res://ui_polish/level_up_badge.gd").new();portrait.add_child(badge)
   badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);badge.position = Vector2(16,0);badge.size = Vector2(22,22)
   var sid := int(row.get("id",-1))
   var person: Dictionary = _session.campaign.soldiers[sid] if sid >= 0 and sid < _session.campaign.soldiers.size() else {}
   badge.present(person)
  var label := _label(str(values[index]),12 if heading else 15,UI.GOLD if heading else UI.TEXT,cell,index == 0 and not heading)
  label.custom_minimum_size.y = 34 if heading else 31
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  if index >= 2:label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  if index == 1 and not heading:label.add_theme_color_override("font_color",UI.HEALTH if row.get("status") == "Survived" else UI.DANGER)
func _layout() -> void:
 if _margin == null:return
 var side := maxi(16,int((size.x-1320)/2))
 for edge in ["left","right"]:_margin.add_theme_constant_override("margin_"+edge,side)
 for edge in ["top","bottom"]:_margin.add_theme_constant_override("margin_"+edge,16)
 result_label.add_theme_font_size_override("font_size",30 if size.x < 1100 else 38)
 mission_label.add_theme_font_size_override("font_size",19 if size.x < 1100 else 23)
 if loot_grid != null:loot_grid.columns = 2 if size.x < 1100 else 3
 if _inspector != null:_inspector.get_parent().custom_minimum_size.x = 290 if size.x < 1100 else 330
func handle_key(event: InputEventKey) -> bool:
 # The parent remains the single modal input owner. Alt targets the nested
 # exact-stat inspector; ordinary paging scrolls the complete report.
 return Presentation.scroll_key(detail_scroll if event.alt_pressed and not selected_uid.is_empty() else scroll,event)
func _target(control: Control) -> Dictionary:
 var raw := Rect2(control.get_global_transform_with_canvas()*Vector2.ZERO,control.size)
 var clipped := raw.intersection(get_viewport_rect())
 var parent := control.get_parent()
 while parent != null:
  if parent is Control and parent.clip_contents:clipped = clipped.intersection(Rect2(parent.get_global_transform_with_canvas()*Vector2.ZERO,parent.size))
  parent = parent.get_parent()
 return {"rect":[raw.position.x,raw.position.y,raw.size.x,raw.size.y],"clipped_rect":[clipped.position.x,clipped.position.y,clipped.size.x,clipped.size.y],"visible":control.is_visible_in_tree() and clipped.has_area()}
func observation() -> Dictionary:
 var loot: Array = []
 for row: Dictionary in _loot_rows:
  var out := row.duplicate(true);out.button = _target(loot_buttons[row.uid]);loot.append(out)
 return {"result":result_label.text,"mission":mission_label.text,"rows":_rows.duplicate(true),"headers":HEADERS,"pay":_result.get("pay",0),"payment":payment_text,"resource_spoils":_result.get("resource_spoils",{}).duplicate(true),"resources_text":resource_totals.text,"resource_sources":resource_sources.text,"resources":_target(resource_section.get_parent()),"fallen":_result.get("fallen",0),"wounded":_result.get("wounded",0),"consequences":consequence_label.text,"loot":loot,"selected_uid":selected_uid,"detail_text":detail_label.text,"return":_target(return_button),"scroll":_target(scroll),"scroll_vertical":scroll.scroll_vertical,"scroll_max":scroll.get_v_scroll_bar().max_value,"inspector":_target(_inspector.get_parent()),"table":_target(table)}
