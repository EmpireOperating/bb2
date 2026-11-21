extends Panel
## Personal progression projection. Campaign commands and the host checkpoint remain authoritative.
const IronSkin = preload("res://iron_oath/skin.gd")
const Perks = preload("res://src/perks.gd")
const Progression = preload("res://src/progression.gd")
const People = preload("res://src/people.gd")
const PersonStats = preload("res://hollow_campaign/person_stats.gd")
var workspace
var heading: Label
var growth_card: Panel
var pool_card: Panel
var detail_card: Panel
var growth_scroll: ScrollContainer
var pool_scroll: ScrollContainer
var detail_scroll: ScrollContainer
var growth_list: VBoxContainer
var perk_list: VBoxContainer
var growth_status: Label
var detail_text: Label
var learn_button: Button
var growth_confirm: Button
var perk_buttons := {}
var growth_buttons := {}
var gift_buttons := {}
var selected_perk := ""
var growth_choices: Array = []
var _sid := -1
var _context_key := ""
var _pending := {}
var feedback := ""
var confirm_panel: Panel
var confirm_scroll: ScrollContainer
var confirm_text: Label
var confirm_button: Button
var cancel_button: Button
var _prior_focus: Control
func _ready() -> void:
 add_theme_stylebox_override("panel",IronSkin.panel(14))
 heading = workspace._label(27,workspace.INK,self)
 heading.add_theme_font_override("font",load("res://assets/serif.ttf"))
 growth_card = _card("ATTRIBUTE GROWTH");pool_card = _card("PERSONAL PERK POOL");detail_card = _card("PERK DETAILS")
 growth_status = workspace._label(15,workspace.GOLD,growth_card)
 growth_scroll = workspace._scroll(growth_card);growth_list = growth_scroll.get_child(0)
 pool_scroll = workspace._scroll(pool_card);perk_list = pool_scroll.get_child(0)
 detail_scroll = ScrollContainer.new();detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 detail_card.add_child(detail_scroll);detail_text = workspace._label(17,workspace.INK,detail_scroll)
 detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 learn_button = workspace._button("Learn selected perk",detail_card);learn_button.pressed.connect(_request_perk)
 growth_confirm = workspace._button("Confirm growth",growth_card);growth_confirm.pressed.connect(_request_growth)
 confirm_panel = Panel.new();confirm_panel.add_theme_stylebox_override("panel",IronSkin.panel(22));add_child(confirm_panel)
 confirm_panel.mouse_filter = Control.MOUSE_FILTER_STOP
 confirm_scroll = ScrollContainer.new();confirm_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 confirm_panel.add_child(confirm_scroll);confirm_text = workspace._label(21,workspace.INK,confirm_scroll)
 confirm_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 confirm_button = workspace._button("Confirm choice",confirm_panel);confirm_button.pressed.connect(_confirm)
 cancel_button = workspace._button("Keep considering [Esc]",confirm_panel);cancel_button.pressed.connect(cancel)
 confirm_panel.hide();resized.connect(_layout);_layout()
func _card(title: String) -> Panel:
 var card := Panel.new();card.add_theme_stylebox_override("panel",IronSkin.panel(12));add_child(card)
 var label: Label = workspace._label(17,workspace.GOLD,card);label.name = "Heading";label.text = title
 return card
func _layout() -> void:
 if heading == null:return
 workspace._place(heading,22,14,size.x-44,72)
 var width := size.x-48
 var left := floorf(width*.31);var middle := floorf(width*.36);var right := width-left-middle
 var y := 96.0;var height := size.y-y-16
 workspace._place(growth_card,12,y,left,height)
 workspace._place(pool_card,24+left,y,middle,height)
 workspace._place(detail_card,36+left+middle,y,right,height)
 for card in [growth_card,pool_card,detail_card]:workspace._place(card.get_node("Heading"),12,12,card.size.x-24,25)
 workspace._place(growth_status,12,44,left-24,64)
 workspace._place(growth_scroll,10,116,left-20,height-180)
 workspace._place(growth_confirm,12,height-54,left-24,42)
 workspace._place(pool_scroll,10,48,middle-20,height-60)
 workspace._place(detail_scroll,14,52,right-28,height-118)
 workspace._place(learn_button,12,height-54,right-24,42)
 confirm_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 workspace._place(confirm_scroll,38,38,size.x-76,size.y-126)
 workspace._place(cancel_button,38,size.y-72,minf(280,(size.x-88)/2),44)
 workspace._place(confirm_button,size.x-278,size.y-72,240,44)
func _context() -> String:
 if workspace.session == null:return ""
 return str(workspace.session.get_instance_id())+JSON.stringify(workspace._person())
func _reason() -> String:
 if not is_visible_in_tree() or workspace.section != "perks":return "Open this companion's Perks view first."
 if workspace._host_blocked():return "Resolve the checkpoint or battle overlay first."
 if workspace.session == null:return "No company session."
 var c = workspace.session.campaign
 if c.phase != "camp" or c.over():return "Progression is available between battles."
 if workspace._person().is_empty() or not workspace._person().get("alive",false):return "Select a living companion."
 if workspace.details_panel.visible or workspace.market_panel.visible:return "Close the other panel first."
 return ""
func _perk_reason(id: String) -> String:
 var reason := _reason()
 if not reason.is_empty():return reason
 var person: Dictionary = workspace._person()
 if id.is_empty():return "Select a perk to inspect its complete effect."
 if not id in person.get("perk_pool",[]):return "Outside this recruit's personal pool."
 return Perks.learn_reason(person,id,Progression.earned_perk_points(person))
func refresh() -> void:
 if heading == null or workspace.session == null:return
 var person: Dictionary = workspace._person()
 if person.is_empty():return
 var context := _context()
 if _sid != workspace.selected_sid:
  _sid = workspace.selected_sid;selected_perk = "";feedback = ""
  pool_scroll.scroll_vertical = 0;growth_scroll.scroll_vertical = 0;detail_scroll.scroll_vertical = 0
 if context != _context_key:
  _context_key = context;growth_choices.clear()
  if not _pending.is_empty():_pending.clear();confirm_panel.hide()
 heading.text = "%s · Level %d\n%d perk points · %d levels awaiting growth" % [person.name,Progression.level(person),Progression.points(person),Progression.training_levels(person)]
 var rows: Array = []
 for id: String in person.get("perk_pool",[]):rows.append({"id":id})
 workspace._sync_buttons(perk_buttons,perk_list,rows,"id",_select_perk)
 for id: String in perk_buttons:
  var definition: Dictionary = Perks.catalog()[id]
  var reason := _perk_reason(id)
  var state := "LEARNED" if id in person.perks else "AVAILABLE" if reason.is_empty() else "LOCKED"
  var button: Button = perk_buttons[id]
  button.text = "%s\nTier %d · %s" % [definition.name,definition.tier,state]
  button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y = 78
  button.tooltip_text = definition.effect+"\n"+reason
  button.disabled = not _reason().is_empty() or confirm_panel.visible
  workspace._mark(button,id == selected_perk)
 _refresh_growth(person)
 if not selected_perk.is_empty() and Perks.catalog().has(selected_perk):
  var definition: Dictionary = Perks.catalog()[selected_perk]
  detail_text.text = "%s\nTier %d\n\n%s\n\n%s%s" % [definition.name,definition.tier,definition.effect,_perk_reason(selected_perk) if not _perk_reason(selected_perk).is_empty() else "Ready to learn · costs one earned perk point. Choices are permanent.","\n\n"+feedback if not feedback.is_empty() else ""]
 else:detail_text.text = "Every companion has a personal perk pool.\n\nInspect any perk to read its full effect and requirements. Locked and learned perks remain visible.\n\nEarning a level grants a perk point and attribute choices; browsing spends nothing."
 learn_button.disabled = not _perk_reason(selected_perk).is_empty() or confirm_panel.visible
 learn_button.tooltip_text = _perk_reason(selected_perk)
func _refresh_growth(person: Dictionary) -> void:
 var index: int = Progression.pending(person)
 var rows: Array = [];var gifts: Array = []
 if index >= 0:
  for attr: String in People.ATTRS:rows.append({"id":attr})
 workspace._sync_buttons(growth_buttons,growth_list,rows,"id",_toggle_growth)
 for attr: String in growth_buttons:
  var gain: int = person.growth_offers[index][attr]
  var button: Button = growth_buttons[attr]
  var current: int = PersonStats.permanent(person,attr)
  button.text = "%s %d → %d\n+%d · %s" % [People.LABELS[attr],current,current+gain,gain,"Selected" if attr in growth_choices else "★".repeat(person.aptitudes[attr])]
  button.tooltip_text = "Current permanent base includes saved rarity and earlier growth; equipment, wounds and derived bonuses are separate."
  button.custom_minimum_size.y = 65;button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  button.disabled = not _reason().is_empty() or attr in person.training[index] or confirm_panel.visible
  workspace._mark(button,attr in growth_choices)
 var needed: int = 3-person.training[index].size() if index >= 0 else 0
 growth_status.text = "Level %d · choose %d attributes\n%d / %d selected" % [index+2,needed,growth_choices.size(),needed] if index >= 0 else "No unspent growth.\nGain another level through service."
 growth_status.text += "\nBase includes rarity"
 growth_confirm.disabled = index < 0 or growth_choices.size() != needed or not _reason().is_empty() or confirm_panel.visible
 if Perks.has(person,"gifted") and person.gifted_choices.size() < 3:
  growth_status.text += "\nGifted: %d choices remain" % (3-person.gifted_choices.size())
  for attr: String in People.ATTRS:gifts.append({"id":attr})
 workspace._sync_buttons(gift_buttons,growth_list,gifts,"id",_request_gift)
 for attr: String in gift_buttons:
  gift_buttons[attr].text = "Gifted · %s +%d" % [People.LABELS[attr],Perks.GIFT[attr]]
  gift_buttons[attr].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  gift_buttons[attr].disabled = attr in person.gifted_choices or not _reason().is_empty() or confirm_panel.visible
func _select_perk(id: String) -> void:
 if not _reason().is_empty() or confirm_panel.visible or not perk_buttons.has(id):return
 selected_perk = id;feedback = "";detail_scroll.scroll_vertical = 0;refresh()
func _toggle_growth(attr: String) -> void:
 if not _reason().is_empty() or confirm_panel.visible or not growth_buttons.has(attr) or growth_buttons[attr].disabled:return
 var person: Dictionary = workspace._person();var index: int = Progression.pending(person)
 if attr in growth_choices:growth_choices.erase(attr)
 elif growth_choices.size() < 3-person.training[index].size():growth_choices.append(attr)
 refresh()
func _request_perk() -> void:
 if not _perk_reason(selected_perk).is_empty() or confirm_panel.visible:return
 _request("perk",selected_perk,"Learn %s?\n\n%s\n\nCost: one earned perk point. This choice is permanent." % [Perks.catalog()[selected_perk].name,Perks.catalog()[selected_perk].effect])
func _request_growth() -> void:
 if growth_confirm.disabled or not _reason().is_empty() or confirm_panel.visible:return
 var person: Dictionary = workspace._person();var index: int = Progression.pending(person)
 var summary: Array[String] = []
 for attr: String in growth_choices:summary.append("%s +%d" % [People.LABELS[attr],person.growth_offers[index][attr]])
 _request("growth",growth_choices.duplicate(),"Train level %d?\n\n%s\n\nApplies this level's stored attribute rolls together. These choices are permanent." % [index+2,"\n".join(summary)])
func _request_gift(attr: String) -> void:
 if not _reason().is_empty() or confirm_panel.visible or not gift_buttons.has(attr) or gift_buttons[attr].disabled:return
 _request("gift",attr,"Gifted · %s +%d?\n\nUses one of the three existing Gifted choices. This choice is permanent." % [People.LABELS[attr],Perks.GIFT[attr]])
func _request(kind: String, value: Variant, text: String) -> void:
 _pending = {"kind":kind,"value":value,"sid":workspace.selected_sid,"context":_context()}
 _prior_focus = get_viewport().gui_get_focus_owner();confirm_text.text = workspace._person().name+"\n\n"+text
 confirm_scroll.scroll_vertical = 0;confirm_panel.show();workspace._update_actions();refresh();cancel_button.grab_focus()
func cancel() -> void:
 if workspace._host_blocked():return
 _pending.clear();confirm_panel.hide();workspace._update_actions();refresh()
 if is_instance_valid(_prior_focus) and _prior_focus.is_visible_in_tree() and not _prior_focus.disabled:_prior_focus.grab_focus()
 else:workspace.section_buttons.perks.grab_focus()
func _confirm() -> void:
 if not confirm_panel.visible or _pending.is_empty() or not _reason().is_empty():return
 var pending := _pending.duplicate(true)
 # Consume before the canonical mutation emits refresh/save. Repeated delivery is inert.
 _pending.clear();confirm_panel.hide()
 if pending.sid != workspace.selected_sid or pending.context != _context():
  feedback = "Companion state changed. Review the current choices before confirming.";workspace.refresh();workspace.section_buttons.perks.grab_focus();return
 var c = workspace.session.campaign
 var accepted := false
 match pending.kind:
  "perk":accepted = c.learn_perk(pending.sid,pending.value)
  "growth":accepted = c.develop(pending.sid,pending.value)
  "gift":accepted = c.choose_gift(pending.sid,pending.value)
 feedback = "Choice applied." if accepted else "The campaign refused this choice; nothing was spent."
 if accepted:workspace.session.changed.emit()
 workspace.refresh()
 if workspace._host_blocked():return # Host save-error focus wins.
 workspace.section_buttons.perks.grab_focus()
func observation() -> Dictionary:
 var out := {"selection":selected_perk,"description":detail_text.text,"growth_status":growth_status.text,"choices":growth_choices.duplicate(),"perks":{},"growth":{},"gifted":{},"learn":workspace._target(learn_button),"train":workspace._target(growth_confirm),"confirmation":{"open":confirm_panel.visible,"text":confirm_text.text,"confirm":workspace._target(confirm_button),"cancel":workspace._target(cancel_button)},"scrolls":{"pool":workspace._rect(workspace._canvas_rect(pool_scroll)),"growth":workspace._rect(workspace._canvas_rect(growth_scroll)),"details":workspace._rect(workspace._canvas_rect(detail_scroll))}}
 for id: String in perk_buttons:out.perks[id] = workspace._target(perk_buttons[id])
 for id: String in growth_buttons:out.growth[id] = workspace._target(growth_buttons[id])
 for id: String in gift_buttons:out.gifted[id] = workspace._target(gift_buttons[id])
 return out
