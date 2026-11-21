extends "res://terrain_pass/camp_panel.gd"
## Genuine camp controls only: seeds choose a future map; Deploy remains explicit.
var seed_input: LineEdit
var apply_seed: Button
var next_seed: Button

func _ready() -> void:
 super._ready()
 var column := map_close.get_parent() as VBoxContainer
 column.add_theme_constant_override("separation",6)
 for button in map_choices.values(): button.custom_minimum_size.y = 48
 var generated := _button("Generated Woodland Road · reproducible seed",column)
 generated.custom_minimum_size.y = 48
 generated.pressed.connect(_choose_generated)
 map_choices["generated_woodland_road"] = generated
 var row := HBoxContainer.new(); row.add_theme_constant_override("separation",6); column.add_child(row)
 var label := _label(14,INK,row); label.text = "Seed"; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 seed_input = LineEdit.new(); seed_input.name = "GenerationSeed"; seed_input.text = "73"
 seed_input.placeholder_text = "0..2147483647"; seed_input.custom_minimum_size = Vector2(96,42)
 seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL; seed_input.max_length = 32
 row.add_child(seed_input)
 apply_seed = _button("Apply seed",row); apply_seed.size_flags_horizontal = Control.SIZE_FILL; apply_seed.custom_minimum_size.x = 108
 next_seed = _button("Next seed",row); next_seed.size_flags_horizontal = Control.SIZE_FILL; next_seed.custom_minimum_size.x = 100
 apply_seed.pressed.connect(_apply_seed)
 seed_input.text_submitted.connect(func(_text): _apply_seed())
 next_seed.pressed.connect(_next_seed)
 column.move_child(map_close,column.get_child_count()-1)
 refresh()

func _layout() -> void:
 super._layout()
 if is_instance_valid(seed_input): _chooser_card.custom_minimum_size = Vector2(minf(540,size.x-32),0)

func refresh() -> void:
 super.refresh()
 if not is_instance_valid(seed_input): return
 if session != null:
  if session.selected_map_id == "generated_woodland_road": map_button.text = "Woodland Road · seed %d ▾" % session.generation_seed
 var admitted: bool = session != null and session.campaign.phase == "camp"
 seed_input.editable = admitted; apply_seed.disabled = not admitted; next_seed.disabled = not admitted

func _open_map_chooser() -> void:
 if is_instance_valid(seed_input) and session != null: seed_input.text = str(session.generation_seed)
 super._open_map_chooser()

func _seed_admitted() -> bool:
 return is_visible_in_tree() and map_chooser.visible and session != null and session.campaign.phase == "camp"

func _choose_generated() -> void:
 if not _seed_admitted(): return
 if session.select_generated(session.generation_seed):
  _feedback = "Generated Woodland Road · seed %d. Deploy when ready." % session.generation_seed
  _close_map_chooser()
 else:
  _feedback = session.last_error; refresh()

func _apply_seed() -> void:
 if not _seed_admitted(): return
 var text := seed_input.text
 var pattern := RegEx.new(); pattern.compile("^(0|[1-9][0-9]{0,9})$")
 var matched := pattern.search(text)
 if matched == null or matched.get_string() != text or text.to_int() > 2147483647:
  _feedback = "Seed must be a literal decimal integer from 0 to 2147483647."
  reason_label.text = _feedback
  seed_input.tooltip_text = _feedback
  return
 if session.select_generated(text.to_int()):
  seed_input.text = str(session.generation_seed)
  seed_input.tooltip_text = ""
  _feedback = "Selected seed %d. Close the chooser, then Deploy when ready." % session.generation_seed
 else: _feedback = session.last_error
 refresh()

func _next_seed() -> void:
 if not _seed_admitted(): return
 var value: int = 0 if session.generation_seed == 2147483647 else session.generation_seed+1
 if session.select_generated(value):
  seed_input.text = str(session.generation_seed)
  seed_input.tooltip_text = ""
  _feedback = "Selected seed %d. Deploy remains a separate action." % value
 else: _feedback = session.last_error
 refresh()

func _input(event: InputEvent) -> void:
 if not is_visible_in_tree() or not is_instance_valid(seed_input) or not map_chooser.visible: return
 if event is InputEventKey and event.pressed:
  if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
   _close_map_chooser(); get_viewport().set_input_as_handled()
  elif event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB:
   var choices: Array = map_choices.values()+[seed_input,apply_seed,next_seed,map_close]
   var index := 0
   for i in choices.size():
    if choices[i].has_focus(): index = i
   choices[posmod(index+(-1 if event.shift_pressed else 1),choices.size())].grab_focus()
   get_viewport().set_input_as_handled()

func _seed_target() -> Dictionary:
 var raw := _canvas_rect(seed_input)
 var clipped := raw.intersection(get_viewport_rect())
 var parent := seed_input.get_parent()
 while parent != null:
  if parent is Control and parent.clip_contents: clipped = clipped.intersection(_canvas_rect(parent))
  parent = parent.get_parent()
 var shown := seed_input.is_visible_in_tree() and clipped.has_area()
 var point := clipped.get_center() if shown else Vector2.ZERO
 return {"center":[point.x,point.y],"rect":_rect(raw),"clipped_rect":_rect(clipped),"visible":shown,"disabled":not seed_input.editable,"text":seed_input.text,"reason":seed_input.tooltip_text}

func observation() -> Dictionary:
 var out := super.observation()
 out["generation_seed"] = session.generation_seed if session != null else 73
 out["selected_generation"] = session.selected_generation() if session != null else {}
 if session != null and session.selected_map_id == "generated_woodland_road": out["map_title"] = "Woodland Road · seed %d" % session.generation_seed
 if is_instance_valid(seed_input):
  out.actions["seed_input"] = _seed_target()
  out.actions["apply_seed"] = _target(apply_seed)
  out.actions["next_seed"] = _target(next_seed)
  for id in ["seed_input","apply_seed","next_seed"]: out.buttons[id] = out.actions[id].center
 return out
