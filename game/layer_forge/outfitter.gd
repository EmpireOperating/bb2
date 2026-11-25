extends RefCounted
## UI state only. Campaign owns every material, fit rule and protection value.
const UI = preload("res://ui_polish/style.gd")
const Armor = preload("res://src/armor.gd")
const NamedMail = preload("res://layer_forge/named_mail.gd")
const ItemDetails = preload("res://hollow_inventory/appearance.gd")
const RarityBadge = preload("res://iron_oath/rarity_badge.gd")
const PROFILE := "ashen-company-layer-forge"
const ORDINARY_SLOTS := ["mainhand", "offhand", "ammo"]
const POSITIONS := {
 "body": {"base": ["I", "Undercoat"], "mail": ["II", "Mail"], "outer": ["III", "Harness"], "cloth": ["IV", "Livery"], "cloak": ["V", "Mantle"], "reinforce": ["VI", "Reinforcement"], "seal": ["VII", "Maker's mark"]},
 "head": {"padding": ["I", "Liner"], "shell": ["II", "Shell"], "face": ["III", "Guard"], "decor": ["IV", "Crest"], "favor": ["V", "Favor"], "seal": ["VI", "Maker's mark"]}
}
const OUTLINE := Color("c69b60")
const SURFACE := Color("23211c")
const INSET := 12
const RAIL_TOP := 44
const ROW_HEIGHT := 32
const ROW_GAP := 2
const STASH_CARD_HEIGHT := 42
const FOOTER_HEIGHT := 144

var workspace
var summaries := {}
var group := ""
var selected_layer := ""
var whole_set := false
var panel: Panel
var heading: Label
var close_button: Button
var whole_button: Button
var rail: VBoxContainer
var rows := {}
var _rail_group := ""
var stash_heading: Label
var stash_scroll: ScrollContainer
var stash_list: VBoxContainer
var empty_stash: Label
var candidates := {}
var candidate_uid := ""
var comparison: Label
var reason: Label
var fit: Button
var remove: Button
var _feedback := ""
var _intents := {}
var _armed: Dictionary = {}
var _applying := false

static func active() -> bool:
 return ProjectSettings.get_setting("application/config/use_custom_user_dir",false) and ProjectSettings.get_setting("application/config/custom_user_dir_name", "") == PROFILE

static func is_piece(definition: String, d: Dictionary) -> bool:
 return definition.begins_with("forge:") and not d.get("assembly",false) and POSITIONS.get(d.get("group",""),{}).has(d.get("layer",""))

static func position_title(d: Dictionary) -> String:
 var key: String = d.get("group","")
 var pos: Array = POSITIONS.get(key,{}).get(d.get("layer",""),[])
 return "" if pos.is_empty() else "%s %s · %s" % [key.capitalize(),pos[0],pos[1]]

static func item_icon(definition: String, d: Dictionary) -> Dictionary:
 if not is_piece(definition,d):return {}
 var short := definition.trim_prefix("forge:")
 if not short.is_valid_identifier():return {}
 var path := "res://layer_forge/art/%s/%s_icon.png" % [d.group,short]
 if ResourceLoader.exists(path,"Texture2D"):
  var imported := load(path) as Texture2D
  if imported != null:return {"texture":imported,"path":path}
 # Private source packs can contain an original PNG without an import remap.
 if not FileAccess.file_exists(path):return {}
 var image := Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:return {}
 return {"texture":ImageTexture.create_from_image(image),"path":path}

static func owned_icon(c, uid: String) -> Dictionary:
 var item: Dictionary = c.items.get(uid,{})
 if not item.has("named"):return item_icon(item.get("definition",""),c.item_def(uid))
 if not c.forge_named_mail_owned(uid):return {}
 var path := NamedMail.ICON
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null or file.get_length() < 33 or file.get_length() > 1048576:return {}
 var bytes := file.get_buffer(file.get_length())
 # Validate the bounded raw 192×192 RGBA8 header before decoding; never
 # display the ordinary laced icon for a missing Named painting.
 if bytes.slice(0,26).hex_encode() != "89504e470d0a1a0a0000000d49484452000000c0000000c00806":return {}
 var image := Image.new()
 if image.load_png_from_buffer(bytes) != OK or image.get_size() != Vector2i(192,192):return {}
 return {"texture":ImageTexture.create_from_image(image),"path":path}

static func named_tier(c, uid: String) -> String:
 var item: Dictionary = c.items.get(uid,{})
 if not item.has("named"):return ""
 return ItemDetails.item_tier(item,c.catalog) if c.forge_named_mail_owned(uid) else "invalid"

static func named_details(c, uid: String) -> String:
 return ItemDetails.item_details(c.items[uid],c.catalog) if named_tier(c,uid) == "named" else "Invalid Named claim; no artwork."

static func set_row(c, uid: String, region: String) -> Dictionary:
 var parts: Dictionary = c.kit_parts(uid)
 var gear := {"body":"","head":""};gear[region] = uid
 var totals: Dictionary = c.armor_stats({"gear":gear})
 var pool := Armor.display_pool(totals,region)
 var lines := PackedStringArray()
 for layer: String in parts:
  var child: String = parts[layer]
  if child.is_empty():continue
  var design: Dictionary = c.item_def(child)
  var condition := "%d/%d" % [c.items[child].condition,design.durability] if int(design.durability) > 0 else "Cosmetic"
  lines.append("%s · %s · %s" % [design.name,condition,child])
 var detail := "%d %s · %d/%d protection" % [lines.size(),"piece" if lines.size()==1 else "pieces",pool.current,pool.maximum]
 return {"item_id":uid,"definition":c.items[uid].definition,"name":"%s set · %s" % [region.capitalize(),c.kit_name(uid)],
  "condition":pool.current,"maximum":pool.maximum,"set_group":region,"set_detail":detail,"set_count":lines.size(),
  "set_tooltip":"%s · %d fatigue burden\nSet %s\n%s" % [detail,totals.load,uid,"\n".join(lines)],"icon_uid":c.slot_uid({"gear":gear},region)}

static func set_icon(c, row: Dictionary) -> Dictionary:
 var leaf: String = row.icon_uid
 return owned_icon(c,leaf)

func _init(owner) -> void:
 workspace = owner
 for key: String in POSITIONS:
  var summary: Button = workspace._button(key.capitalize(),workspace.portrait_card)
  summary.name = "ForgeSummary"+key.capitalize()
  summary.custom_minimum_size.y = 76
  summary.add_theme_font_size_override("font_size",15)
  summary.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  summary.pressed.connect(_toggle.bind(key))
  summaries[key] = summary
 panel = Panel.new()
 panel.name = "LayerForgeReview"
 panel.mouse_filter = Control.MOUSE_FILTER_STOP
 var outline := UI.panel(SURFACE,OUTLINE,0)
 outline.set_border_width_all(2)
 panel.add_theme_stylebox_override("panel",outline)
 workspace.stash_card.add_child(panel)
 panel.hide()
 heading = _caption("",17,UI.GOLD,panel)
 close_button = _button("All stash [Esc]",panel,14)
 close_button.name = "ForgeAllStash"
 close_button.pressed.connect(close)
 whole_button = _button("Whole set",panel,14)
 whole_button.name = "ForgeWholeSet"
 whole_button.pressed.connect(_toggle_set)
 rail = VBoxContainer.new()
 rail.name = "ForgeRomanRail"
 rail.add_theme_constant_override("separation",ROW_GAP)
 panel.add_child(rail)
 stash_heading = _caption("",13,UI.GOLD,panel)
 stash_scroll = workspace._scroll(panel)
 stash_scroll.name = "ForgeCompatibleStash"
 stash_list = stash_scroll.get_child(0)
 stash_list.add_theme_constant_override("separation",3)
 empty_stash = _caption("No loose pieces for this position.",14,UI.MUTED,panel)
 comparison = _caption("",14,UI.TEXT,panel)
 comparison.add_theme_constant_override("line_spacing",1)
 reason = _caption("",13,UI.MUTED,panel)
 reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 reason.max_lines_visible = 2
 fit = _button("Fit",panel,15)
 fit.name = "ForgeFitOrReplace"
 remove = _button("Remove",panel,15)
 remove.name = "ForgeRemove"
 for action: Button in [fit,remove]:
  action.button_down.connect(_arm.bind(action))
  action.pressed.connect(_apply.bind(action))

func _caption(text: String, point: int, tint: Color, parent: Control) -> Label:
 var label := Label.new()
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_size_override("font_size",point)
 label.add_theme_color_override("font_color",tint)
 label.text = text
 parent.add_child(label)
 return label

func _button(text: String, parent: Control, point: int) -> Button:
 var button := Button.new()
 button.text = text
 button.clip_text = true
 button.focus_mode = Control.FOCUS_ALL
 button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 button.add_theme_font_size_override("font_size",point)
 parent.add_child(button)
 return button

func _row_style(button: Button, selected: bool, primary := false) -> void:
 var normal := UI.panel(Color("343426") if selected else Color("292b24"),OUTLINE if selected else Color("555344"),0)
 normal.content_margin_left = 9
 normal.content_margin_right = 9
 var badge: Control = button.get_node_or_null("ForgeNamedBadge")
 if badge != null and badge.visible:normal.content_margin_right = 34
 if primary:normal.content_margin_bottom = 14 # Row title above the physical piece label.
 var hover := normal.duplicate() as StyleBoxFlat
 hover.bg_color = Color("414137")
 var disabled := normal.duplicate() as StyleBoxFlat
 disabled.bg_color = Color("262721")
 disabled.border_color = Color("44443b")
 button.add_theme_stylebox_override("normal",normal)
 button.add_theme_stylebox_override("hover",hover)
 button.add_theme_stylebox_override("pressed",hover)
 button.add_theme_stylebox_override("disabled",disabled)

func _named_badge(button: Button, tier: String) -> void:
 var badge = button.get_node_or_null("ForgeNamedBadge")
 if badge == null and not tier.is_empty():
  badge = RarityBadge.new()
  badge.name = "ForgeNamedBadge"
  button.add_child(badge)
  badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
  badge.offset_left = -29
  badge.offset_right = -5
  badge.offset_top = 3
  badge.offset_bottom = 27
 if badge != null:badge.present(tier)

func _toggle(key: String) -> void:
 if group == key:close()
 else:open(key)

func open(key: String, layer: String = "", uid: String = "", review_set := false) -> void:
 if not POSITIONS.has(key) or not _can_browse():return
 group = key
 selected_layer = layer if POSITIONS[key].has(layer) else str(POSITIONS[key].keys()[0])
 whole_set = review_set
 clear_candidate()
 candidate_uid = uid
 workspace.item_hover.retire()
 workspace.refresh()
 var focus: Button = candidates.get(candidate_uid,whole_button if whole_set else rows.get(selected_layer))
 if focus != null:
  focus.grab_focus()
  if stash_scroll.is_ancestor_of(focus):_reveal.call_deferred(candidate_uid,focus)

func _reveal(uid: String, focus: Button) -> void:
 if candidate_uid == uid and is_instance_valid(focus) and focus.is_visible_in_tree() and focus.has_focus():
  stash_scroll.ensure_control_visible(focus)

func reset() -> void:
 group = ""
 selected_layer = ""
 whole_set = false
 clear_candidate()

func clear_candidate() -> void:
 candidate_uid = ""
 _feedback = ""
 _intents.clear()
 _armed = {}
 stash_scroll.scroll_vertical = 0

func close() -> void:
 if group.is_empty() or not workspace._workspace_reason().is_empty():return
 var summary: Button = summaries[group]
 reset()
 workspace.refresh()
 summary.grab_focus()

func _can_browse() -> bool:
 return workspace.section == "equipment" and workspace._browse_reason().is_empty() and not workspace._person().is_empty()

func _rebuild_rail() -> void:
 if _rail_group == group:return
 _rail_group = group
 for control in rail.get_children():
  rail.remove_child(control)
  control.queue_free()
 rows.clear()
 for layer: String in POSITIONS[group]:
  var pos: Array = POSITIONS[group][layer]
  var row := _button("%s  ·  %s" % pos,rail,12)
  row.name = "ForgeLayer_"+layer
  row.alignment = HORIZONTAL_ALIGNMENT_LEFT
  row.custom_minimum_size.y = ROW_HEIGHT
  var piece := _caption("",13,UI.TEXT,row)
  piece.name = "Piece"
  piece.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  var wear := _caption("",13,UI.MUTED,row)
  wear.name = "Wear"
  wear.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  wear.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  row.pressed.connect(_select_layer.bind(layer))
  rows[layer] = row

func _select_layer(layer: String) -> void:
 if not _can_browse() or not panel.is_visible_in_tree() or not rows.has(layer):return
 whole_set = false
 selected_layer = layer
 clear_candidate()
 workspace.refresh()

func _toggle_set() -> void:
 if not _can_browse() or not panel.is_visible_in_tree():return
 whole_set = not whole_set
 clear_candidate()
 workspace.refresh()

func _parts(c, person: Dictionary) -> Dictionary:
 return c.kit_parts(person.get("gear",{}).get(group,""))

func _fitted(c, person: Dictionary) -> String:
 if not whole_set:return _parts(c,person).get(selected_layer,"")
 var uid: String = person.get("gear",{}).get(group,"")
 return uid if c.forge_set_group(uid) == group else ""

func _wear(row: Dictionary) -> String:
 if row.item_id.is_empty():return "—"
 if int(row.maximum) <= 0:return "Cosmetic"
 return "%d/%d" % [row.condition,row.maximum]

func _compatible(c, uid: String) -> bool:
 if not c.items.has(uid) or c.owner(uid) >= 0 or not c.parent_kit(uid).is_empty():return false
 if whole_set:return c.forge_set_group(uid) == group
 var d: Dictionary = c.item_def(uid)
 return is_piece(c.items[uid].definition,d) and d.get("group") == group and d.get("layer") == selected_layer

func _compatible_uids(c) -> Array:
 if whole_set:return c.forge_sets(group)
 var uids: Array = []
 for uid: String in c.components(group,selected_layer):
  if uid not in uids and _compatible(c,uid):uids.append(uid)
 return uids

func _select_candidate(uid: String) -> void:
 if not _can_browse() or not panel.is_visible_in_tree() or not candidates.has(uid):return
 if not _compatible(workspace.session.campaign,uid):
  _feedback = "That item is no longer available in the stash."
 else:
  candidate_uid = "" if uid == candidate_uid else uid
  _feedback = ""
 workspace.refresh()

func _sync_stash(c, uids: Array) -> void:
 for uid: String in candidates.keys():
  if uid in uids:continue
  var old: Button = candidates[uid]
  stash_list.remove_child(old)
  old.queue_free()
  candidates.erase(uid)
 for index in uids.size():
  var uid: String = uids[index]
  var button: Button = candidates.get(uid)
  if button == null:
   button = _button("",stash_list,14)
   button.alignment = HORIZONTAL_ALIGNMENT_LEFT
   button.add_theme_constant_override("line_spacing",0)
   button.expand_icon = true
   button.add_theme_constant_override("icon_max_width",30)
   button.custom_minimum_size.y = STASH_CARD_HEIGHT
   button.pressed.connect(_select_candidate.bind(uid))
   candidates[uid] = button
  if button.get_index() != index:stash_list.move_child(button,index)
  var item: Dictionary = workspace._item_row(uid)
  var detail: String = item.set_detail if whole_set else "Condition "+_wear(item) if int(item.maximum) > 0 else "Cosmetic"
  # A visible literal UID distinguishes equally worn, same-definition copies.
  button.text = "%s\n%s  ·  %s" % [item.name,detail,uid]
  button.tooltip_text = "%s\n%s · %s\nSelect again to clear comparison." % [item.name,detail,uid]
  var icon := set_icon(c,item) if whole_set else owned_icon(c,uid)
  button.icon = icon.get("texture")
  var tier := "" if whole_set else named_tier(c,uid)
  _named_badge(button,tier)
  if whole_set:button.tooltip_text = item.name+"\n"+item.set_tooltip
  elif not tier.is_empty():button.tooltip_text += "\n"+named_details(c,uid)
  if not whole_set and icon.is_empty():button.tooltip_text += "\nNo standalone art."
  button.disabled = not _can_browse()
  _row_style(button,candidate_uid == uid)
 stash_heading.text = ("STASHED SETS  ·  %d" if whole_set else "COMPATIBLE STASH  ·  %d") % uids.size()
 empty_stash.text = "No intact sets for this region." if whole_set else "No loose pieces for this position."
 empty_stash.visible = uids.is_empty()

func _quote(c, uid: String) -> Dictionary:
 if whole_set:return c.forge_set_preview(workspace.selected_sid,group,uid)
 return c.component_preview(workspace.selected_sid,group,selected_layer,uid)

func _admission(c, uid: String, fitted: String, quote: Dictionary) -> String:
 var camp_reason: String = workspace._camp_reason()
 if not camp_reason.is_empty():return camp_reason
 if not _can_browse() or workspace.host == null or workspace.host.session != workspace.session or not workspace.can_process() or workspace.is_queued_for_deletion():
  return "Open the current Company Equipment screen."
 if not workspace.session.has_method("fit_forge_set" if whole_set else "fit_forge_layer"):return "Fitting is unavailable."
 if not quote.get("ok",false):
  var why: String = quote.get("reason","")
  return "This layer change is not available." if why.is_empty() else why
 if uid.is_empty():
  return "This position is empty." if fitted.is_empty() else ""
 return "That item is no longer available in the stash." if not _compatible(c,uid) else ""

func _compare(quote: Dictionary, load_now: int) -> String:
 var diff := Armor.comparison(quote.before,quote.after,group)
 var load_change: int = int(quote.after.load)-int(quote.before.load)
 return "Protection  %d/%d → %d/%d\nChange %+d current · %+d max\nFatigue burden  %d → %d  (%+d)" % [diff.before.current,diff.before.maximum,diff.after.current,diff.after.maximum,diff.now_change,diff.max_change,load_now,load_now+load_change,load_change]

func _has_delta(quote: Dictionary) -> bool:
 return quote.get("ok",false) and not quote.get("before",{}).is_empty() and not quote.get("after",{}).is_empty()

func _paint_action(button: Button, c, person: Dictionary, uid: String, fitted: String, quote: Dictionary, blocked: String, tip: String) -> void:
 button.disabled = not blocked.is_empty()
 button.tooltip_text = blocked if button.disabled else tip
 if button.disabled:return
 _intents[button] = {"control":button,"session":workspace.session,"campaign":c,"person":person,"sid":workspace.selected_sid,"group":group,"layer":selected_layer,"whole_set":whole_set,"uid":uid,"fitted":fitted,"record":c.items.get(uid,{}).duplicate(true),"revision":workspace._revision,"quote":quote.duplicate(true)}

func _paint_actions(c, person: Dictionary, fitted: String, pool: Dictionary, load_now: int) -> void:
 _intents.clear()
 var fit_quote := _quote(c,candidate_uid) if not candidate_uid.is_empty() else {}
 var remove_quote := _quote(c,"")
 var choose := "Choose an intact set to compare." if whole_set else "Choose a loose piece to compare."
 var fit_reason := choose if candidate_uid.is_empty() else _admission(c,candidate_uid,fitted,fit_quote)
 var remove_reason := _admission(c,"",fitted,remove_quote)
 fit.text = ("Fit " if fitted.is_empty() else "Replace ")+("set" if whole_set else "piece")
 remove.text = "Remove set" if whole_set else "Remove"
 var quote := remove_quote if candidate_uid.is_empty() else fit_quote
 comparison.text = "Protection  %d/%d\nFatigue burden  %d" % [pool.current,pool.maximum,load_now]
 if _has_delta(quote):comparison.text = _compare(quote,load_now)
 comparison.tooltip_text = "Current/max protection · Change in current/max\n"+comparison.text
 var remove_tip := ("Stash the whole set intact." if whole_set else "Return the worn piece to the stash.")
 if _has_delta(remove_quote):remove_tip += "\n\n"+_compare(remove_quote,load_now)
 _paint_action(fit,c,person,candidate_uid,fitted,fit_quote,fit_reason,comparison.tooltip_text)
 _paint_action(remove,c,person,"",fitted,remove_quote,remove_reason,remove_tip)
 var status := "Nothing changes until you confirm."
 if candidate_uid.is_empty():
  status = choose
  if not fitted.is_empty():
   status = remove_reason if not remove_reason.is_empty() else "Removal shown. "+choose
 elif not fit_reason.is_empty():status = fit_reason
 elif whole_set and not fitted.is_empty():status = "Replacing returns the current set to the stash intact."
 reason.text = _feedback if not _feedback.is_empty() else workspace._camp_reason() if workspace.battle_read_only else status
 reason.tooltip_text = reason.text

func _arm(button: Button) -> void:
 _armed = _intents.get(button,{})

func _apply(button: Button) -> void:
 var intent := _armed
 _armed = {}
 if _applying or intent.is_empty() or intent.control != button or button.disabled or not button.is_visible_in_tree() or not _can_browse():return
 var session = workspace.session
 var c = session.campaign
 var person: Dictionary = workspace._person()
 if intent.session != session or intent.campaign != c or intent.sid != workspace.selected_sid or not is_same(intent.person,person) or intent.group != group or intent.layer != selected_layer or intent.whole_set != whole_set or (button == fit and intent.uid != candidate_uid):return
 var quote := _quote(c,intent.uid)
 if intent.revision != workspace._revision or _fitted(c,person) != intent.fitted or c.items.get(intent.uid,{}) != intent.record or quote != intent.quote:
  _feedback = "Equipment changed. Review the updated comparison first."
  workspace.refresh()
  return
 if not _admission(c,intent.uid,intent.fitted,quote).is_empty():
  workspace.refresh()
  return
 _applying = true # Session.changed may repaint synchronously.
 _intents.clear()
 var accepted: bool = session.fit_forge_set(intent.sid,intent.group,intent.uid) if intent.whole_set else session.fit_forge_layer(intent.sid,intent.group,intent.layer,intent.uid)
 _applying = false
 if not is_instance_valid(workspace) or group != intent.group or selected_layer != intent.layer or whole_set != intent.whole_set or workspace.selected_sid != intent.sid:return
 if accepted:
  candidate_uid = ""
  if whole_set:
   _feedback = "Set stashed intact." if intent.uid.is_empty() else "Set fitted." if intent.fitted.is_empty() else "Set fitted. Previous set stashed intact."
  else:
   _feedback = "Removed to the stash." if intent.uid.is_empty() else "Piece fitted." if intent.fitted.is_empty() else "Replaced. Previous piece returned to stash."
 else:
  _feedback = session.last_error if not session.last_error.is_empty() else "Equipment change refused."
 workspace.refresh()
 if accepted and panel.is_visible_in_tree():
  if whole_set:whole_button.grab_focus()
  elif rows.has(selected_layer):rows[selected_layer].grab_focus()

func paint() -> void:
 var person: Dictionary = workspace._person()
 if person.is_empty():reset()
 var showing: bool = not group.is_empty() and workspace.section == "equipment"
 panel.visible = showing
 workspace.stash_scroll.visible = not showing
 workspace.stash_title.visible = not showing
 workspace.equip_button.visible = not showing
 workspace.remove_button.visible = not showing
 if showing:workspace._empty_stash.hide()
 var c = workspace.session.campaign if not person.is_empty() else null
 var totals: Dictionary = c.armor_stats(person) if c != null else {}
 var group_load := 0
 for key: String in summaries:
  var summary: Button = summaries[key]
  summary.disabled = not _can_browse()
  summary.text = key.capitalize()+"  ▸\nNo companion"
  summary.tooltip_text = ""
  if c != null:
   var pool := Armor.display_pool(totals,key)
   var other := "head" if key == "body" else "body"
   var isolated: Dictionary = c.armor_stats(person,other,{})
   if key == group:group_load = int(isolated.load)
   summary.text = "%s  %s\n%d/%d protection\n%d fatigue burden" % [key.capitalize(),"▾" if showing and group == key else "▸",pool.current,pool.maximum,isolated.load]
   summary.tooltip_text = "%s layers · %d/%d current/max protection · %d fatigue burden" % [key.capitalize(),pool.current,pool.maximum,isolated.load]
  _row_style(summary,showing and group == key)
 if not showing:return
 _rebuild_rail()
 heading.text = group.to_upper()+(" / SETS" if whole_set else " / LAYERS")
 whole_button.text = "Layers" if whole_set else "Whole set"
 whole_button.tooltip_text = "Review individual layers." if whole_set else "Remove or fit every layer in this region together."
 whole_button.disabled = not _can_browse()
 _row_style(whole_button,whole_set)
 var parts := _parts(c,person)
 for layer: String in rows:
  var row: Button = rows[layer]
  var item: Dictionary = workspace._item_row(parts.get(layer,""))
  row.get_node("Piece").text = item.name
  row.get_node("Wear").text = _wear(item)
  row.set_meta("fitted_uid",item.item_id)
  row.tooltip_text = row.text+"\n"+item.name+("\n"+_wear(item)+" · Item "+item.item_id if not item.item_id.is_empty() else "")
  var tier := named_tier(c,item.item_id)
  _named_badge(row,tier)
  row.get_node("Piece").modulate = Color("ff7628") if tier == "named" else Color.WHITE
  row.icon = null
  if not tier.is_empty():
   var icon := owned_icon(c,item.item_id)
   row.icon = icon.get("texture")
   row.expand_icon = true
   row.add_theme_constant_override("icon_max_width",24)
   row.tooltip_text += "\n"+named_details(c,item.item_id)
   if icon.is_empty():row.tooltip_text += "\nNo standalone art."
  row.disabled = not _can_browse()
  _row_style(row,not whole_set and layer == selected_layer,true)
 var uids := _compatible_uids(c)
 if candidate_uid not in uids:candidate_uid = ""
 _sync_stash(c,uids)
 _paint_actions(c,person,_fitted(c,person),Armor.display_pool(totals,group),group_load)

func layout(width: float, height: float, middle_width: float, flank: float, slot_top: float, card_height: float) -> void:
 workspace._place(summaries.head,0,slot_top+card_height+10,flank,76)
 workspace._place(summaries.body,middle_width-flank,slot_top+card_height+8,flank,76)
 if not panel.visible:return
 workspace._place(panel,0,0,width,height)
 workspace._place(heading,INSET,7,width-154,28)
 workspace._place(close_button,width-140,7,128,30)
 var rail_height := rows.size()*ROW_HEIGHT+maxi(0,rows.size()-1)*ROW_GAP
 workspace._place(rail,INSET,RAIL_TOP,width-2*INSET,rail_height)
 for row: Button in rows.values():
  var badge: Control = row.get_node_or_null("ForgeNamedBadge")
  var crest_space := 26 if badge != null and badge.visible else 0
  var icon_space := 28 if row.icon != null else 0
  workspace._place(row.get_node("Piece"),9+icon_space,14,width-2*INSET-105-crest_space-icon_space,17)
  workspace._place(row.get_node("Wear"),width-2*INSET-85-crest_space,0,76,ROW_HEIGHT)
 var rail_end := RAIL_TOP+rail_height
 var stash_top := rail_end+32
 workspace._place(stash_heading,INSET,rail_end+9,width-2*INSET-104,20)
 workspace._place(whole_button,width-INSET-96,rail_end+3,96,26)
 workspace._place(stash_scroll,INSET,stash_top,width-2*INSET,height-stash_top-FOOTER_HEIGHT)
 workspace._place(empty_stash,INSET+3,stash_top+8,width-2*INSET-6,24)
 workspace._place(comparison,INSET,height-FOOTER_HEIGHT+6,width-2*INSET,55)
 workspace._place(reason,INSET,height-80,width-2*INSET,36)
 var action_width := (width-2*INSET-8)/2.0
 workspace._place(fit,INSET,height-41,action_width,34)
 workspace._place(remove,INSET+action_width+8,height-41,action_width,34)

func observation() -> Dictionary:
 var summary_targets := {}
 for key: String in summaries:summary_targets[key] = workspace._target(summaries[key])
 var row_targets := {}
 var stash_targets := {}
 if panel.is_visible_in_tree():
  for layer: String in rows:
   var row: Button = rows[layer]
   var target: Dictionary = workspace._target(row)
   target.merge({"uid":row.get_meta("fitted_uid",""),"piece":row.get_node("Piece").text,"wear":row.get_node("Wear").text})
   row_targets[layer] = target
  for uid: String in candidates:stash_targets[uid] = workspace._target(candidates[uid])
 return {"group":group,"layer":selected_layer,"candidate_uid":candidate_uid,"summaries":summary_targets,"rows":row_targets,"stash":stash_targets,
  "whole_set":whole_set,"whole_set_toggle":workspace._target(whole_button),
  "compare":comparison.text,"reason":reason.text,"fit":workspace._target(fit),"remove":workspace._target(remove),"close":workspace._target(close_button),
  "review_rect":workspace._rect(workspace._canvas_rect(panel)),"stash_rect":workspace._rect(workspace._canvas_rect(stash_scroll)),"stash_scroll":stash_scroll.scroll_vertical}
