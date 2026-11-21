extends "res://company_loop/camp_panel.gd"
## Compact camp-owned modal. Reuse every accepted equipment/portrait operation.
const Maps = preload("res://terrain_pass/maps.gd")
var map_button: Button
var map_chooser: Control
var map_choices := {}
var map_close: Button
var _chooser_card: PanelContainer

func _ready() -> void:
 super._ready()
 map_button = _button("Battlefield…",self)
 map_button.pressed.connect(_open_map_chooser)
 map_chooser = Control.new()
 map_chooser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 map_chooser.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(map_chooser)
 var shade := ColorRect.new()
 shade.color = Color(0.01,0.015,0.02,0.88)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 map_chooser.add_child(shade)
 var centered := CenterContainer.new()
 centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 map_chooser.add_child(centered)
 _chooser_card = PanelContainer.new()
 _chooser_card.add_theme_stylebox_override("panel",_style(Color("1b2329"),GOLD))
 centered.add_child(_chooser_card)
 var margin := MarginContainer.new()
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
 _chooser_card.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",10)
 margin.add_child(column)
 _label(20,INK,column).text = "NEXT BATTLEFIELD"
 var note := _label(13,MUTED,column)
 note.text = "Choose terrain for the next sortie, then deploy from camp. Your company, equipment and wounds stay unchanged."
 note.custom_minimum_size.y = 38
 for id in Maps.ids():
  var button := _button("",column)
  button.custom_minimum_size.y = 60
  button.text = "Ruined Crossing · bridge and ruined keep" if id == "ruined_crossing" else "Woodland Road · wooded flanks and high ground"
  button.pressed.connect(_choose_map.bind(id))
  map_choices[id] = button
 map_close = _button("Back to outfitting [Esc]",column)
 map_close.pressed.connect(_close_map_chooser)
 map_chooser.hide()
 refresh()

func _layout() -> void:
 super._layout()
 if not is_instance_valid(map_button): return
 var margin := 16.0 if size.x >= 900 else 10.0
 _place(map_button,size.x-margin-208,8,208,42)
 title_label.size.x = maxf(0,map_button.position.x-margin-10)
 title_label.add_theme_font_size_override("font_size",20 if size.x < 800 else 26)
 _place(subtitle_label,margin,52,size.x-margin*2,18)
 _chooser_card.custom_minimum_size = Vector2(minf(540,size.x-32),326)

func refresh() -> void:
 super.refresh()
 if not is_instance_valid(map_button): return
 var id: String = session.selected_map_id if session != null else ""
 map_button.text = Maps.create(id).get("title","Choose battlefield")+" ▾"
 map_button.disabled = not _camp_reason().is_empty()
 for key in map_choices: _mark(map_choices[key],key == id)
 if session != null and not session.last_error.is_empty(): reason_label.text = session.last_error
 _layout()

func _camp_reason() -> String:
 if is_instance_valid(map_chooser) and map_chooser.visible: return "Close the battlefield chooser to continue outfitting."
 return super._camp_reason()

func _open_map_chooser() -> void:
 if not _camp_reason().is_empty(): return
 map_chooser.show()
 refresh()
 map_choices.ruined_crossing.grab_focus()

func _close_map_chooser() -> void:
 map_chooser.hide()
 refresh()
 map_button.grab_focus()

func _choose_map(id: String) -> void:
 if not map_chooser.visible or session == null: return
 if not session.select_map(id):
  _feedback = session.last_error
  return
 _feedback = "Next sortie: %s. Deploy when the company is ready." % Maps.create(id).title
 _close_map_chooser()

func _input(event: InputEvent) -> void:
 if not is_visible_in_tree() or not is_instance_valid(map_chooser) or not map_chooser.visible: return
 if event is InputEventKey and event.pressed:
  if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
   _close_map_chooser()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB:
   var choices: Array = map_choices.values()+[map_close]
   var index := 0
   for i in choices.size():
    if choices[i].has_focus(): index = i
   choices[posmod(index+(-1 if event.shift_pressed else 1),choices.size())].grab_focus()
   get_viewport().set_input_as_handled()

func observation() -> Dictionary:
 var out := super.observation()
 out["map_chooser_open"] = is_instance_valid(map_chooser) and map_chooser.visible
 out["selected_map_id"] = session.selected_map_id if session != null else ""
 out["deployed_map_id"] = session.deployed_map.get("id","") if session != null else ""
 out["map_title"] = Maps.create(out.selected_map_id).get("title","")
 out["map_choices"] = {}
 if is_instance_valid(map_button):
  out.actions["map_chooser"] = _target(map_button)
  out.buttons["map_chooser"] = out.actions.map_chooser.center
  for id in map_choices: out.map_choices[id] = _target(map_choices[id])
  out["map_close"] = _target(map_close)
 return out
