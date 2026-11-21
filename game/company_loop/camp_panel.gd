extends Control
## Outfitting is a projection of Session. This panel never owns campaign state.
signal deploy_requested

const INK := Color("e5d8b9")
const MUTED := Color("aab8b9")
const GOLD := Color("b5a579")
const Character = preload("res://company_loop/character.gd")
const Arsenal = preload("res://src/arsenal.gd")
const CHECKPOINT_NOTICE := "Camp autosaves. Battles are not saved; quitting resumes your last camp."
var session
var selected_sid := -1
var selected_slot := "weapon"
var selected_item_id := ""
var preview_layers := {}
var preview_actor
var preview: TextureRect
var roster_buttons := {}
var slot_buttons := {}
var item_buttons := {}
var equip_button: Button
var remove_button: Button
var deploy_button: Button
var title_label: Label
var subtitle_label: Label
var checkpoint_label: Label
var name_label: Label
var identity_label: Label
var stats_label: Label
var comparison_label: Label
var reason_label: Label
var roster_card: Panel
var portrait_card: Panel
var slots_card: Panel
var stash_card: Panel
var roster_scroll: ScrollContainer
var slots_scroll: ScrollContainer
var stash_scroll: ScrollContainer
var roster_list: VBoxContainer
var slots_list: VBoxContainer
var stash_list: VBoxContainer
var stash_title: Label
var _ready_ui := false
var _unit := {}
var _slots: Array = []
var _items: Array = []
var _feedback := ""
var _empty_stash: Label
var _rendered_unit := {}
var _revision := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.color = Color("11171c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	title_label = _label(26, INK, self)
	title_label.text = "THE ASHEN COMPANY"
	subtitle_label = _label(13, MUTED, self)
	subtitle_label.text = "CAMP  /  OUTFITTING  ·  Choose a brother, a slot, then an owned item."
	checkpoint_label = _label(12, MUTED, self)
	checkpoint_label.text = CHECKPOINT_NOTICE
	roster_card = _card("COMPANY")
	portrait_card = _card("")
	slots_card = _card("EQUIPPED  /  SELECT A SLOT")
	stash_card = _card("OWNED STASH")
	stash_title = stash_card.get_node("Heading")
	roster_scroll = _scroll(roster_card)
	roster_list = roster_scroll.get_child(0)
	slots_scroll = _scroll(slots_card)
	slots_list = slots_scroll.get_child(0)
	stash_scroll = _scroll(stash_card)
	stash_list = stash_scroll.get_child(0)
	_empty_stash = _label(14, MUTED, stash_list)
	name_label = _label(23, INK, portrait_card)
	identity_label = _label(13, GOLD, portrait_card)
	for label in [name_label, identity_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.max_lines_visible = 1
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_card.add_child(preview)
	stats_label = _label(14, INK, portrait_card)
	comparison_label = _label(14, INK, self)
	reason_label = _label(13, MUTED, self)
	equip_button = _button("Equip selected", self)
	remove_button = _button("Remove slot", self)
	deploy_button = _button("Deploy company  →", self)
	equip_button.pressed.connect(_equip)
	remove_button.pressed.connect(_remove)
	deploy_button.pressed.connect(_deploy)
	resized.connect(_layout)
	_ready_ui = true
	_bind()
	refresh()

func _style(background: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 7
	box.content_margin_bottom = 7
	return box

func _label(font_size: int, color: Color, parent: Node) -> Label:
	var value := Label.new()
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size", font_size)
	value.add_theme_color_override("font_color", color)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(value)
	return value

func _button(text: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("7d898c"))
	button.add_theme_stylebox_override("normal", _style(Color("253138"), Color("4a5657")))
	button.add_theme_stylebox_override("hover", _style(Color("37454b"), GOLD))
	button.add_theme_stylebox_override("pressed", _style(Color("19282c"), GOLD))
	button.add_theme_stylebox_override("disabled", _style(Color("1a2227"), Color("303a3e")))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), Color("e5c875")))
	parent.add_child(button)
	return button

func _card(heading: String) -> Panel:
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", _style(Color("1b2329"), Color("39444a")))
	add_child(card)
	var label := _label(12, GOLD, card)
	label.name = "Heading"
	label.text = heading
	return card

func _scroll(parent: Node) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	parent.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	scroll.add_child(column)
	return scroll

func _place(control: Control, x: float, y: float, width: float, height: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(maxf(0, width), maxf(0, height))

func _layout() -> void:
	if not _ready_ui: return
	var margin := 16.0 if size.x >= 900 else 10.0
	var gap := 12.0 if size.x >= 900 else 8.0
	var width := size.x - margin * 2
	var top := 92.0
	var foot := size.y - 112.0
	var height := foot - top - 12.0
	_place(title_label, margin, 12, width, 32)
	_place(subtitle_label, margin, 46, width, 25)
	_place(checkpoint_label, margin, 70, width, 18)
	var roster_width := 180.0 if size.x >= 1200 else 146.0
	var portrait_width := floorf(width * 0.29)
	if size.x < 800:
		roster_width = 112.0
		portrait_width = floorf(width * 0.33)
	_place(roster_card, margin, top, roster_width, height)
	_place(portrait_card, margin + roster_width + gap, top, portrait_width, height)
	var right_x := portrait_card.position.x + portrait_width + gap
	var right_width := size.x - margin - right_x
	if size.x >= 1200:
		var slot_width := floorf(right_width * 0.46)
		_place(slots_card, right_x, top, slot_width, height)
		_place(stash_card, right_x + slot_width + gap, top, right_width - slot_width - gap, height)
	else:
		var slot_height := floorf(height * 0.51)
		_place(slots_card, right_x, top, right_width, slot_height)
		_place(stash_card, right_x, top + slot_height + gap, right_width, height - slot_height - gap)
	for card in [roster_card, slots_card, stash_card]:
		_place(card.get_node("Heading"), 10, 8, card.size.x - 20, 20)
	for pair in [[roster_scroll, roster_card], [slots_scroll, slots_card], [stash_scroll, stash_card]]:
		_place(pair[0], 8, 32, pair[1].size.x - 16, pair[1].size.y - 40)
	var compact := size.x < 800
	name_label.add_theme_font_size_override("font_size", 17 if compact else 23)
	stats_label.add_theme_font_size_override("font_size", 12 if compact else 14)
	_place(name_label, 12, 8, portrait_width - 24, 34)
	_place(identity_label, 12, 44, portrait_width - 24, 20)
	var stats_height := 65.0 if compact else 91.0
	_place(preview, 8, 68, portrait_width - 16, portrait_card.size.y - 76 - stats_height)
	_place(stats_label, 12, portrait_card.size.y - stats_height, portrait_width - 24, stats_height - 5)
	_place(comparison_label, margin, foot, width, 29)
	_place(reason_label, margin, foot + 29, width, 30)
	_place(equip_button, margin, size.y - 52, 144, 40)
	_place(remove_button, margin + 154, size.y - 52, 132, 40)
	_place(deploy_button, size.x - margin - 206, size.y - 52, 206, 40)

func set_session(value) -> void:
	if session == value:
		_bind()
		refresh()
		return
	_unbind()
	session = value
	selected_sid = -1
	selected_slot = "weapon"
	selected_item_id = ""
	_feedback = ""
	_bind()
	refresh()

func _bind() -> void:
	if session != null and is_inside_tree() and not session.changed.is_connected(refresh):
		session.changed.connect(refresh)

func _unbind() -> void:
	if session != null and session.changed.is_connected(refresh): session.changed.disconnect(refresh)

func _enter_tree() -> void:
	if _ready_ui:
		_bind()
		refresh.call_deferred()

func _exit_tree() -> void:
	_unbind()

func refresh() -> void:
	if not _ready_ui: return
	_revision += 1
	var people: Array = []
	if session != null:
		for person: Dictionary in session.campaign.soldiers:
			if person.get("alive", false): people.append(person)
	if not people.any(func(person): return person.id == selected_sid):
		selected_sid = int(people[0].id) if not people.is_empty() else -1
		selected_item_id = ""
	_unit = session.preview_unit(selected_sid) if selected_sid >= 0 else {}
	_slots = session.gear_slots(selected_sid) if selected_sid >= 0 else []
	_items = session.available_items(selected_sid, selected_slot) if selected_sid >= 0 else []
	if not _items.any(func(item): return item.item_id == selected_item_id): selected_item_id = ""
	_sync_buttons(roster_buttons, roster_list, people, "id", _select_bro)
	for person: Dictionary in people:
		var row: Button = roster_buttons[person.id]
		row.text = "%s\nHP %d/%d" % [person.name, person.hp, session.campaign.max_hp(person)]
		row.tooltip_text = "%s · %s · HP %d/%d" % [person.name, person.get("title", ""), person.hp, session.campaign.max_hp(person)]
		_mark(row, person.id == selected_sid)
	_sync_buttons(slot_buttons, slots_list, _slots, "key", _select_slot)
	for slot: Dictionary in _slots:
		var row: Button = slot_buttons[slot.key]
		row.text = "%s\n%s" % [slot.label.to_upper(), _item_text(slot)]
		row.tooltip_text = row.text.replace("\n", " · ")
		_mark(row, slot.key == selected_slot)
	_sync_buttons(item_buttons, stash_list, _items, "item_id", _select_item)
	for item: Dictionary in _items:
		var row: Button = item_buttons[item.item_id]
		row.text = _item_text(item) + "\nOwned · " + item.item_id
		row.tooltip_text = row.text.replace("\n", " · ")
		_mark(row, item.item_id == selected_item_id)
	_empty_stash.visible = _items.is_empty()
	_empty_stash.text = "No suitable unassigned items.\nEquipment already worn by a brother is not in the stash."
	stash_title.text = "OWNED STASH  /  %d AVAILABLE" % _items.size()
	name_label.text = _unit.get("name", "No brother selected")
	name_label.tooltip_text = name_label.text
	identity_label.text = "HP %d/%d  ·  %s" % [_unit.hp, _unit.max_hp, _unit.get("title", "MERCENARY")] if not _unit.is_empty() else ""
	identity_label.tooltip_text = identity_label.text
	stats_label.text = "Body %d/%d  ·  Head %d/%d\nMelee %d  ·  Ranged %d\nDefense %d  ·  Load %d" % [_unit.armor + _unit.padding, _unit.max_armor + _unit.max_padding, _unit.helmet, _unit.max_helmet, _unit.skill, _unit.ranged_skill, _unit.defense, _unit.load] if not _unit.is_empty() else ""
	_update_portrait()
	_update_actions()
	_layout()

func _update_portrait() -> void:
	if _unit.is_empty():
		preview.texture = null
		preview_layers.clear()
		_rendered_unit.clear()
		if is_instance_valid(preview_actor):
			preview_actor.queue_free()
			preview_actor = null
		return
	if not is_instance_valid(preview_actor):
		preview_actor = Character.new()
		preview_actor.name = "CampPreviewActor"
		preview_actor.position = Vector3(0, -1000, 0)
		preview_actor.visible = false
		preview_actor.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(preview_actor)
	if _rendered_unit != _unit:
		preview_actor.configure(_unit, session.campaign.catalog)
		preview_actor.set_process(false)
		_rendered_unit = _unit.duplicate(true)
	# Keep the exact resource owned by the field-capable actor, not a copy.
	preview.texture = preview_actor.preview_texture()
	preview_layers = preview_actor.layer_signature().duplicate(true)

func _sync_buttons(buttons: Dictionary, column: VBoxContainer, rows: Array, key: String, handler: Callable) -> void:
	var ids: Array = rows.map(func(row): return row[key])
	for id in buttons.keys():
		if id in ids: continue
		var old: Button = buttons[id]
		var focused := old.has_focus()
		column.remove_child(old)
		old.queue_free()
		buttons.erase(id)
		if focused: equip_button.grab_focus()
	for row: Dictionary in rows:
		var id = row[key]
		if buttons.has(id): continue
		var button := _button("", column)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 60
		button.pressed.connect(handler.bind(id))
		buttons[id] = button

func _mark(button: Button, selected: bool) -> void:
	button.add_theme_stylebox_override("normal", _style(Color("354249") if selected else Color("222e34"), GOLD if selected else Color("3c484d")))

func _item_text(item: Dictionary) -> String:
	if String(item.get("item_id", "")).is_empty(): return "Empty"
	if int(item.maximum) <= 0: return String(item.name)
	return "%s · %d/%d%s" % [item.name, item.condition, item.maximum, " BROKEN" if item.condition <= 0 else ""]

func _camp_reason() -> String:
	if session == null: return "No company session is attached."
	if session.campaign.phase != "camp": return "Outfitting is only available in camp. Return after the battle."
	if session.campaign.over(): return "This company cannot change equipment after its campaign ends."
	if selected_sid < 0: return "No living brother is available."
	return ""

func _selected_row() -> Dictionary:
	for row: Dictionary in _slots:
		if row.key == selected_slot: return row
	return {}

func _remove_reason() -> String:
	var reason := _camp_reason()
	if not reason.is_empty(): return reason
	var row := _selected_row()
	if row.is_empty() or String(row.item_id).is_empty(): return "This slot is already empty."
	if selected_slot == "weapon": return "A brother must keep a weapon. Select another owned weapon to replace it."
	if "/" in selected_slot:
		var pair := selected_slot.split("/")
		var result: Dictionary = session.campaign.component_preview(selected_sid, pair[0], pair[1])
		if not result.ok: return result.reason
	return ""

func _update_actions() -> void:
	var camp_reason := _camp_reason()
	var equip_reason := camp_reason
	if equip_reason.is_empty() and selected_item_id.is_empty():
		equip_reason = _availability_reason() if _items.is_empty() else "Choose a slot, then an owned stash item to equip."
	if _items.is_empty() and camp_reason.is_empty(): _empty_stash.text = _availability_reason()
	equip_button.disabled = not equip_reason.is_empty()
	equip_button.tooltip_text = equip_reason if equip_button.disabled else "Equip this owned item; the replaced item returns to the stash."
	var remove_reason := _remove_reason()
	remove_button.disabled = not remove_reason.is_empty()
	remove_button.tooltip_text = remove_reason if remove_button.disabled else "Return this exact item, with its current condition, to the owned stash."
	deploy_button.disabled = not camp_reason.is_empty()
	deploy_button.tooltip_text = camp_reason if deploy_button.disabled else "Deploy the actual company. No equipment changes during battle."
	for button: Button in slot_buttons.values(): button.disabled = not camp_reason.is_empty()
	for button: Button in roster_buttons.values(): button.disabled = not camp_reason.is_empty()
	reason_label.text = camp_reason if not camp_reason.is_empty() else _feedback if not _feedback.is_empty() else equip_reason if not equip_reason.is_empty() else "Ready to equip. Current gear remains unchanged until you confirm."
	comparison_label.text = _comparison()
	comparison_label.tooltip_text = comparison_label.text

func _availability_reason() -> String:
	if selected_slot == "shield" and _unit.get("weapon", "") in Arsenal.TWO_HANDS:
		return "This two-handed weapon cannot use a shield. Replace the weapon first."
	return "No compatible unassigned item is in your stash for this slot. Choose another slot."

func _comparison() -> String:
	if selected_item_id.is_empty():
		var row := _selected_row()
		return "%s: %s  ·  %s" % [row.label, _item_text(row), _remove_reason()] if not row.is_empty() else "Your company. Your equipment. No free replacements or automatic repairs."
	var item: Dictionary = _items.filter(func(row): return row.item_id == selected_item_id)[0]
	if "/" in selected_slot:
		var pair := selected_slot.split("/")
		var change: Dictionary = session.campaign.component_preview(selected_sid, pair[0], pair[1], selected_item_id)
		return "%s  ·  Body %d → %d  ·  Head %d → %d  ·  Load %d → %d" % [item.name, change.before.armor + change.before.padding, change.after.armor + change.after.padding, change.before.helmet, change.after.helmet, change.before.load, change.after.load]
	return "%s  →  %s" % [_item_text(_selected_row()), _item_text(item)]

func _select_bro(sid: int) -> void:
	if not _camp_reason().is_empty(): return
	selected_sid = sid
	selected_item_id = ""
	_feedback = ""
	refresh()

func _select_slot(slot: String) -> void:
	if not _camp_reason().is_empty(): return
	selected_slot = slot
	selected_item_id = ""
	_feedback = ""
	stash_scroll.scroll_vertical = 0
	refresh()

func _select_item(id: String) -> void:
	if not _camp_reason().is_empty(): return
	selected_item_id = id
	_feedback = ""
	refresh()

func _equip() -> void:
	if not _camp_reason().is_empty() or selected_item_id.is_empty(): return
	var id := selected_item_id
	var accepted: bool = session.equip(selected_sid, id, selected_slot)
	_feedback = "Equipped. The replaced item is back in your stash." if accepted else session.last_error
	selected_item_id = ""
	refresh()

func _remove() -> void:
	if not _remove_reason().is_empty(): return
	var accepted: bool = session.unequip(selected_sid, selected_slot)
	_feedback = "Removed to the owned stash. Condition is preserved." if accepted else session.last_error
	selected_item_id = ""
	refresh()

func _deploy() -> void:
	if not _camp_reason().is_empty(): return
	deploy_requested.emit()

func observation() -> Dictionary:
	var targets := {"roster": {}, "slots": {}, "items": {}}
	var centers := {"roster": {}, "slots": {}, "items": {}}
	for group: String in targets:
		var source: Dictionary = {"roster": roster_buttons, "slots": slot_buttons, "items": item_buttons}[group]
		for id in source:
			targets[group][str(id)] = _target(source[id])
			centers[group][str(id)] = targets[group][str(id)].center
	var actions := {"equip": _target(equip_button), "remove": _target(remove_button), "deploy": _target(deploy_button)} if _ready_ui else {}
	for action: String in actions: centers[action] = actions[action].center
	return {"selected_sid": selected_sid, "selected_slot": selected_slot, "selected_item_id": selected_item_id,
		"selected_preview": _unit.duplicate(true), "unit_name": _unit.get("name", ""),
		"phase": session.campaign.phase if session != null else "", "revision": _revision,
		"preview_layers": preview_layers.duplicate(true),
		"preview_texture_id": preview.texture.get_instance_id() if _ready_ui and preview.texture != null else 0,
		"preview_diagnostics": preview_actor.render_diagnostics() if is_instance_valid(preview_actor) else {},
		"slots": _slots.duplicate(true), "items": _items.duplicate(true),
		"checkpoint_notice": checkpoint_label.text if _ready_ui else "",
		"comparison": comparison_label.text if _ready_ui else "",
		"reason": reason_label.text if _ready_ui else "Panel not mounted.",
		"actions": actions, "targets": targets, "buttons": centers,
		"viewport_rect": _rect(get_viewport_rect()), "window_size": [get_window().size.x, get_window().size.y],
		"scrolls": {"roster": _rect(_canvas_rect(roster_scroll)), "slots": _rect(_canvas_rect(slots_scroll)), "items": _rect(_canvas_rect(stash_scroll))} if _ready_ui else {},
		"panel_rect": _rect(_canvas_rect(self)), "preview_rect": _rect(_canvas_rect(preview)) if _ready_ui else []}

func _rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]

func _canvas_rect(control: Control) -> Rect2:
	return control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)

func _target(button: Button) -> Dictionary:
	var raw := _canvas_rect(button)
	var clipped := raw.intersection(get_viewport_rect())
	var parent := button.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents:
			clipped = clipped.intersection(_canvas_rect(parent))
		parent = parent.get_parent()
	var shown := button.is_visible_in_tree() and clipped.has_area()
	var point := clipped.get_center() if shown else Vector2.ZERO
	return {"center": [point.x, point.y], "rect": _rect(raw), "clipped_rect": _rect(clipped),
		"visible": shown, "disabled": button.disabled, "text": button.text, "reason": button.tooltip_text}
