extends Control
## Read-only equipment projection. Never equips, repairs, transfers, or rolls RNG.
const Named = preload("res://src/named_equipment.gd")
signal fresh_kit_requested
var close_button: Button
var next_kit_button: Button
var comparison_label: Label
var sheet: Panel
var portrait: Panel
var preview: TextureRect
var name_label: Label
var identity_label: Label
var stats_label: Label
var slot_labels := {}
var carried_label: Label
var art_note: Label
var details: ScrollContainer
var hint: Label
var preview_unit_id := -1
var preview_layers := {}
var slots := {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.019, 0.024, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	sheet = Panel.new()
	sheet.add_theme_stylebox_override("panel", style(Color("13191e"), Color("6c6250")))
	add_child(sheet)
	name_label = label(28, Color("e5d8b9"))
	sheet.add_child(name_label)
	identity_label = label(13, Color("adb7b9"))
	identity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sheet.add_child(identity_label)
	portrait = Panel.new()
	portrait.add_theme_stylebox_override("panel", style(Color("20252a"), Color("333c42")))
	sheet.add_child(portrait)
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(preview)
	details = ScrollContainer.new()
	details.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	details.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sheet.add_child(details)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	details.add_child(column)
	stats_label = label(17, Color("d8e0db"))
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stats_label)
	for slot in ["body", "head", "weapon", "shield"]:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", style(Color("1b2329"), Color("354047")))
		column.add_child(card)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 4)
		card.add_child(content)
		var title := label(12, Color("b5a579"))
		title.text = slot.to_upper()
		content.add_child(title)
		var value := label(16, Color("e0e1d9"))
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value.add_theme_constant_override("line_spacing", 3)
		content.add_child(value)
		slot_labels[slot] = value
	carried_label = label(14, Color("bac5c5"))
	carried_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(carried_label)
	art_note = label(13, Color("a6acae"))
	art_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(art_note)
	hint = label(13, Color("abb5b8"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "Read-only inspection · Battle paused."
	comparison_label = hint
	sheet.add_child(hint)
	close_button = make_button("Return to battle [Esc / I]")
	close_button.pressed.connect(hide)
	sheet.add_child(close_button)
	next_kit_button = make_button("Next kit · New battle")
	next_kit_button.pressed.connect(fresh_kit_requested.emit)
	sheet.add_child(next_kit_button)
	resized.connect(_layout)
	_layout()
	hide()

func style(background: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 9
	box.content_margin_bottom = 9
	return box

func label(font_size: int, color: Color) -> Label:
	var value := Label.new()
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size", font_size)
	value.add_theme_color_override("font_color", color)
	return value

func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("e4d8bb"))
	button.add_theme_stylebox_override("normal", style(Color("273137"), Color("766c51")))
	button.add_theme_stylebox_override("hover", style(Color("39464b"), Color("b5a579")))
	button.add_theme_stylebox_override("pressed", style(Color("182125"), Color("b5a579")))
	return button

func _layout() -> void:
	if not is_instance_valid(sheet): return
	var extent := Vector2(minf(1040, size.x-24), minf(820, size.y-24))
	sheet.position = (size-extent)/2.0
	sheet.size = extent
	name_label.position = Vector2(24, 17)
	name_label.size = Vector2(extent.x-48, 36)
	identity_label.position = Vector2(24, 55)
	identity_label.size = Vector2(extent.x-48, 34)
	var preview_width := floorf((extent.x-72)*0.43)
	portrait.position = Vector2(24, 94)
	portrait.size = Vector2(preview_width, extent.y-218)
	preview.position = Vector2(8, 8)
	preview.size = portrait.size-Vector2(16, 16)
	details.position = Vector2(preview_width+44, 94)
	details.size = Vector2(extent.x-preview_width-68, extent.y-218)
	hint.position = Vector2(24, extent.y-108)
	hint.size = Vector2(extent.x-48, 44)
	close_button.position = Vector2(24, extent.y-55)
	close_button.size = Vector2(228, 38)
	next_kit_button.position = Vector2(extent.x-252, extent.y-55)
	next_kit_button.size = Vector2(228, 38)

func set_comparison(hero_name: String, next_kit_name: String) -> void:
	comparison_label.text = "Compare %s: %s\nStarts a fresh battle; this fight is discarded. No mid-combat equipment changes." % [hero_name, next_kit_name]

func present(unit: Dictionary, catalog: Dictionary, actor, battle) -> void:
	preview_unit_id = int(unit.id)
	preview_layers = actor.layer_signature().duplicate(true)
	# Keep the resource itself. No second compositor, PNG or costume state.
	preview.texture = actor.preview_texture()
	name_label.text = String(unit.name)
	identity_label.text = "YOUR COMPANY  /  %s  /  READ-ONLY · BATTLE PAUSED" % String(unit.get("title", "MERCENARY"))
	stats_label.text = "HP %d/%d    AP %d/%d\nBody %d/%d    Head %d/%d\nFatigue %d/%d" % [unit.hp, unit.max_hp, unit.ap, battle.MAX_AP,
		unit.armor+unit.padding, unit.max_armor+unit.max_padding, unit.helmet, unit.max_helmet, unit.fatigue, battle.fatigue_max(unit)]
	slots = {"body":[], "head":[], "weapon":[], "shield":[]}
	for part: Dictionary in unit.get("armor_parts", []):
		var group: String = "head" if part.get("group", "") == "head" else "body"
		slots[group].append(item_record(part, catalog))
	for slot in ["weapon", "shield"]:
		var item: Dictionary = unit.get("arms", {}).get(slot, {})
		if not item.is_empty(): slots[slot].append(item_record(item, catalog))
	for slot in slots:
		var lines := PackedStringArray()
		for record: Dictionary in slots[slot]: lines.append(item_text(record))
		slot_labels[slot].text = "None" if lines.is_empty() else "\n".join(lines)
	var carried := PackedStringArray()
	for slot in ["carry1", "carry2", "carry3", "carry4", "ammo"]:
		var item: Dictionary = unit.get("arms", {}).get(slot, {})
		if not item.is_empty(): carried.append(item_text(item_record(item, catalog)))
	carried_label.text = "CARRIED / AMMUNITION\n"+"\n".join(carried)
	carried_label.visible = not carried.is_empty()
	var missing_art := false
	for entry: Dictionary in preview_layers.values():
		if not entry.get("painted", true) and not String(entry.get("definition", "")).is_empty(): missing_art = true
	art_note.text = "Some equipped items have no painted layer. Their names, condition and combat stats are still real." if missing_art else "Condition is current / maximum. This preview includes the field's actual wear and equipment layers."
	details.scroll_vertical = 0
	show()
	_layout()

func item_record(item: Dictionary, catalog: Dictionary) -> Dictionary:
	var definition := Named.definition(item, catalog)
	return {"definition":item.get("definition", ""), "id":item.get("item", item.get("id", "")),
		"name":definition.get("name", item.get("definition", "Unknown item")),
		"condition":int(item.get("condition", 0)), "maximum":int(item.get("maximum", definition.get("durability", 0)))}

func item_text(item: Dictionary) -> String:
	if item.maximum <= 0: return item.name
	return "%s · %d/%d%s" % [item.name, item.condition, item.maximum, " · BROKEN" if item.condition <= 0 else ""]

func rect_array(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func observation() -> Dictionary:
	var point := close_button.get_global_rect().get_center()
	var next := next_kit_button.get_global_rect().get_center()
	return {"preview_unit_id":preview_unit_id if visible else -1, "unit_name":name_label.text if visible else "",
		"preview_texture_id":preview.texture.get_instance_id() if visible and preview.texture != null else 0,
		"preview_layers":preview_layers.duplicate(true) if visible else {}, "slots":slots.duplicate(true) if visible else {},
		"buttons":{"close":[point.x, point.y], "nextkit":[next.x, next.y]} if visible else {},
		"panel_rect":rect_array(sheet.get_global_rect()), "preview_rect":rect_array(preview.get_global_rect())}
