extends "res://sprite_study/inspection_panel.gd"
## Read-only current equipment. The field remains the owner of pause/admission.
const Equipment = preload("res://hollow_campaign/appearance.gd")
const Rarity = preload("res://hollow_systems/rarity.gd")
const Presentation = preload("res://ui_polish/inventory_presentation.gd")
const UI = preload("res://ui_polish/style.gd")
const Arsenal = preload("res://src/arsenal.gd")
var summary_labels := {}
var details_button: Button
var details_panel: Panel
var details_close_button: Button
var provenance: ScrollContainer
var person_notes: Label
var carried_notes: Label
var omission_label: Label
var _previous_focus: Control
func _ready() -> void:
 theme = UI.theme()
 super._ready()
 var column := stats_label.get_parent()
 # Retain full legacy slot-label text in the closed provenance surface.
 for value: Label in slot_labels.values():
  var card := value.get_parent().get_parent()
  column.remove_child(card);card.free()
 slot_labels.clear()
 art_note.reparent(sheet)
 details_panel = Panel.new();details_panel.mouse_filter = Control.MOUSE_FILTER_STOP
 details_panel.add_theme_stylebox_override("panel",UI.panel(UI.BG))
 sheet.add_child(details_panel)
 provenance = ScrollContainer.new()
 provenance.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
 provenance.follow_focus = true
 details_panel.add_child(provenance)
 var notes := VBoxContainer.new();notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 provenance.add_child(notes)
 person_notes = label(15,UI.TEXT);person_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;notes.add_child(person_notes)
 var grid := GridContainer.new();grid.columns = 2;grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10)
 column.add_child(grid);column.move_child(grid,1)
 for slot: String in Equipment.SLOTS:
  var card := PanelContainer.new();card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  card.add_theme_stylebox_override("panel",UI.panel(UI.SURFACE,UI.LINE,10));grid.add_child(card)
  var content := VBoxContainer.new();card.add_child(content)
  var title := label(14,UI.MUTED);title.text = slot.to_upper();content.add_child(title)
  var value := label(15,UI.TEXT);value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  content.add_child(value);summary_labels[slot] = value
  var full := label(15,UI.TEXT);full.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  notes.add_child(full);slot_labels[slot] = full
 carried_notes = label(15,UI.TEXT);carried_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;notes.add_child(carried_notes)
 art_note.reparent(notes)
 details_close_button = make_button("Close Details [Esc]");details_panel.add_child(details_close_button)
 details_close_button.pressed.connect(_close_details)
 details_button = make_button("Details");sheet.add_child(details_button);details_button.pressed.connect(_open_details)
 omission_label = label(14,UI.MUTED);omission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;sheet.add_child(omission_label)
 details_panel.hide()
 next_kit_button.hide();next_kit_button.disabled = true
 visibility_changed.connect(_visibility_changed)
 _layout()
func style(background: Color, border: Color) -> StyleBoxFlat:
 return UI.panel(UI.SURFACE,UI.LINE,10)
func label(font_size: int, color: Color) -> Label:
 var value := super.label(font_size,color)
 UI.label(value,maxi(14,font_size),color)
 return value
func make_button(text: String) -> Button:
 var button := super.make_button(text);UI.button(button)
 return button
func present(unit: Dictionary, catalog: Dictionary, actor, battle) -> void:
 if not visible:_previous_focus = get_viewport().gui_get_focus_owner()
 preview_unit_id = int(unit.id)
 preview_layers = actor.layer_signature().duplicate(true)
 preview.texture = actor.preview_texture() # exact resource; no second compositor
 name_label.text = str(unit.name)
 var tier := str(unit.get("companion_roll",{}).get("tier",""))
 identity_label.text = "%s · READ-ONLY · BATTLE PAUSED" % (tier.capitalize() if not tier.is_empty() else "Unrated")
 identity_label.add_theme_color_override("font_color",Rarity.tier_color(tier))
 stats_label.text = "HP %d/%d · AP %d\n" % [unit.get("hp",0),unit.get("max_hp",0),unit.get("ap",0)]+Presentation.stats(unit,battle)
 person_notes.text = Equipment.effective_stats(unit,battle)+"\n\n"+Equipment.person_details(unit)
 slots = unit.get("equipment_slots",{}).duplicate(true)
 for slot: String in Equipment.SLOTS:
  var item: Dictionary = slots.get(slot,{})
  slot_labels[slot].text = slot.to_upper()+"\n"+Equipment.item_details(item,catalog)
  summary_labels[slot].text = Presentation.summary(item,catalog)
  summary_labels[slot].add_theme_color_override("font_color",Rarity.tier_color(str(item.get("instance_roll",{}).get("tier",""))))
 var carried := PackedStringArray()
 var full_carried := PackedStringArray()
 var reserves: Array = Arsenal.bag_slots(unit)
 for slot: String in reserves:
  var item: Dictionary = unit.get("arms",{}).get(slot,{})
  carried.append("Pocket %s · " % slot.trim_prefix("carry")+Presentation.identity(item,catalog))
  full_carried.append("POCKET %s\n" % slot.trim_prefix("carry")+Equipment.item_details(item,catalog))
 carried_label.text = "POCKETS · %d\n" % reserves.size()+"\n".join(carried)
 carried_label.visible = true
 carried_notes.text = "POCKETS\n"+"\n\n".join(full_carried)
 art_note.text = Equipment.diagnostics_text(actor.render_diagnostics())
 omission_label.text = Presentation.omission(actor.render_diagnostics())
 details_panel.hide();details.scroll_vertical = 0;provenance.scroll_vertical = 0
 show();_layout();close_button.grab_focus()
func _open_details() -> void:
 details_panel.show();provenance.scroll_vertical = 0;details_close_button.grab_focus()
func _close_details() -> void:
 details_panel.hide();details_button.grab_focus()
func _visibility_changed() -> void:
 if visible:return
 details_panel.hide()
 if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():_previous_focus.grab_focus()
func _input(event: InputEvent) -> void:
 if not is_visible_in_tree() or not event is InputEventKey:return
 if Presentation.scroll_key(provenance if details_panel.visible else details,event):
  get_viewport().set_input_as_handled();return
 var code: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
 if code == KEY_TAB:
  if event.pressed and not event.echo:Presentation.cycle(details_panel if details_panel.visible else sheet,event.shift_pressed)
 elif code == KEY_ESCAPE or code == KEY_I:
  if event.pressed and not event.echo:
   if code == KEY_ESCAPE and details_panel.visible:_close_details()
   else:hide()
 elif code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_SPACE:
  if event.pressed and not event.echo:
   var focus := get_viewport().gui_get_focus_owner()
   if focus is Button and (details_panel.is_ancestor_of(focus) if details_panel.visible else sheet.is_ancestor_of(focus)) and not focus.disabled:focus.pressed.emit()
 else:return
 get_viewport().set_input_as_handled()
func _layout() -> void:
 super._layout()
 if not is_instance_valid(details_button):return
 var extent := sheet.size
 # Full body at the left; concise current values + nine real cards at right.
 var width := floorf((extent.x-72)*0.38)
 portrait.size.x = width
 preview.size = portrait.size-Vector2(16,16)
 details.position.x = width+44;details.size.x = extent.x-width-68
 stats_label.add_theme_font_size_override("font_size",15)
 hint.text = "Read-only · Battle paused. Change equipment after returning to camp."
 # The inherited company presenter supplies two guidance lines after present().
 # Reserve both lines above the separate art note and fixed footer actions.
 hint.position.y = extent.y-120
 hint.size.y = 36
 omission_label.position = Vector2(24,extent.y-80);omission_label.size = Vector2(extent.x-48,20)
 details_button.position = Vector2(extent.x-144,extent.y-55);details_button.size = Vector2(120,38)
 details_panel.position = Vector2(12,12);details_panel.size = extent-Vector2(24,24)
 provenance.position = Vector2(16,16);provenance.size = details_panel.size-Vector2(32,86)
 details_close_button.position = Vector2(details_panel.size.x-256,details_panel.size.y-54);details_close_button.size = Vector2(240,40)
func observation() -> Dictionary:
 var out := super.observation()
 out.buttons.erase("nextkit")
 out["details_open"] = details_panel.visible
 out["cards"] = {}
 for slot in slot_labels:out.cards[slot] = slot_labels[slot].text
 out["summary_cards"] = {}
 for slot in summary_labels:out.summary_cards[slot] = summary_labels[slot].text
 out["details_text"] = person_notes.text+"\n\n"+"\n\n".join(out.cards.values())+"\n\n"+carried_notes.text+"\n\n"+art_note.text
 return out
