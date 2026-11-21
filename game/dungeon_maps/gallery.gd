extends Control
## Disposable map browser. Never constructs Campaign or reads/writes its saves.
const FIELDS := ["crypt","crypt_barrow","crypt_gallery","crypt_throne","crypt_mound","crypt_garrison","crypt_royal"]
var banner: Label
var status: Label
var chooser: Control
var field_choice: OptionButton
var seed_edit: LineEdit
var refusal: Label
var campaign_return: Button
var controls := {}
var screen: TextureRect
var viewport: SubViewport
var field
var current_field := ""
var current_seed := -1
var fingerprint := ""
var replacing := false
var observe_enabled := false
var observe_time := 0.0
var build_revision := 0
var source_binding := {}

func _ready() -> void:
 observe_enabled="--observe" in OS.get_cmdline_user_args()
 if observe_enabled:
  source_binding={"gallery_sha256":FileAccess.get_sha256("res://dungeon_maps/gallery.gd"),"scene_sha256":FileAccess.get_sha256("res://dungeon_maps/gallery.tscn"),"generator_sha256":FileAccess.get_sha256("res://dungeon_maps/generator.gd"),"deployment_sha256":FileAccess.get_sha256("res://dungeon_maps/deployment.gd"),"field_sha256":FileAccess.get_sha256("res://burial_ruins/battlefield.gd"),"engine":Engine.get_version_info().string}
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var column := VBoxContainer.new();column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(column)
 var top := PanelContainer.new();column.add_child(top)
 var rows := VBoxContainer.new();top.add_child(rows)
 banner=Label.new();banner.text="MAP PREVIEW — disposable battle, no campaign saves";rows.add_child(banner)
 var actions := HBoxContainer.new();rows.add_child(actions)
 _button(actions,"maps","Map / seed…",open_chooser)
 _button(actions,"replay","Replay",func():build_request(current_field,current_seed))
 _button(actions,"next","Next seed",func():
  if current_seed<2147483647:build_request(current_field,current_seed+1))
 status=Label.new();status.text="Choose a map and seed.";status.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(status)
 screen=TextureRect.new();screen.name="FieldDisplay";screen.size_flags_vertical=Control.SIZE_EXPAND_FILL;screen.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 screen.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;screen.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;column.add_child(screen)
 viewport=SubViewport.new();viewport.name="DisposableFieldViewport";viewport.size=Vector2i(1440,900);viewport.handle_input_locally=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
 screen.texture=viewport.get_texture()
 screen.gui_input.connect(_field_pointer)
 _build_chooser()
 build_request("crypt",7391)

func build_request(requested_field: Variant, requested_seed: Variant) -> bool:
 if replacing:return false
 if not requested_field is String or not requested_field in FIELDS or not requested_seed is int or requested_seed<0 or requested_seed>2147483647:
  status.text="Refused: choose a supported field and integer seed 0…2147483647."
  return false
 var generator_path := "res://dungeon_maps/generator.gd"
 var installer_path := "res://dungeon_maps/deployment.gd"
 if not FileAccess.file_exists(generator_path) or not FileAccess.file_exists(installer_path):
  status.text="Map generator / installer is not available. Current field retained."
  return false
 var generator = load(generator_path);var installer = load(installer_path)
 var packet: Dictionary=generator.generate(requested_field,requested_seed)
 if not generator.validate(packet,requested_field,requested_seed):
  status.text="Refused: production generator did not validate this request."
  return false
 var battle = load("res://src/battle.gd").new()
 battle.setup(requested_seed,requested_field,"eliminate",true,true,true,true,true,true)
 # These are disposable stock example actors, never an owned company. Ordinary
 # stock undead equipment/stat initializers supply the preview's opposition.
 var rng := RandomNumberGenerator.new();rng.seed=requested_seed
 var family: String=packet.descriptor.presentation.family
 var kinds: Array=load("res://src/dungeon_themes.gd").roster("barrow" if family=="mound" else family,12,"battle",rng)
 # Minor barrow rosters deliberately contain only two/three stock roles.
 # Cycle those examples to fill this disposable full24 map, not a real encounter.
 for i in 12:
  load("res://src/undead.gd").equip(battle,battle.units[12+i],kinds[i%kinds.size()],1,"preview_%d"%i)
  battle.initialize_stats(battle.units[12+i])
 battle.start_round()
 if not installer.install(battle,packet,requested_field,requested_seed):
  status.text="Refused: production installer rejected this map. Current field retained."
  return false
 replacing=true
 if is_instance_valid(field):
  field.process_mode=Node.PROCESS_MODE_DISABLED
  for tween in field.actor_tweens.values():tween.kill()
  viewport.remove_child(field);field.free();field=null
 # The field's historical member is a minimal value facade, NOT Campaign.
 var facade := {"campaign":{"phase":"battle","battle":battle},"deployed_map":packet.descriptor.duplicate(true),"selected_map_id":requested_field}
 field=load("res://burial_ruins/battlefield.gd").new();field.session=facade;viewport.add_child(field)
 # Remove only the campaign-return callback from this disposable presentation.
 # Removing the dictionary entry prevents inherited refresh from reenabling it.
 campaign_return=field.action_buttons.retreat
 field.action_buttons.erase("retreat")
 for connection in campaign_return.pressed.get_connections():campaign_return.pressed.disconnect(connection.callable)
 campaign_return.disabled=true;campaign_return.text="No campaign return";campaign_return.tooltip_text="Disposable map preview. Replay discards this battle; no campaign or settlement."
 for container in field.help_panel.get_children():
  for child in container.get_children():
   if child is Label:child.text="MAP PREVIEW — disposable battle, no campaign saves\n\nStock example actors, not an owned company. No grants or settlement.\nClick your active fighter, then an exposed reachable hex for a paid move.\nSelect an enemy; Basic [1] / Special [2], then Execute / Enter.\nEnd [F / Space], Shieldwall [B], Recover [R], Wait [Q].\nEquipment [I] is read-only and pauses the battle.\nWASD / arrows / middle drag pan; wheel zoom; Home close; O overview.\nParty fog and personal targeting are unchanged.\n\nMap / seed opens a paused chooser. Build, Replay and Next discard the\nwhole old battle and field. No campaign save is read or written."
 current_field=requested_field;current_seed=requested_seed;fingerprint=packet.fingerprint;build_revision+=1
 status.text="%s · seed %d · %s"%[current_field,current_seed,fingerprint.substr(0,12)]
 replacing=false
 controls.next.disabled=current_seed>=2147483647
 controls.replay.disabled=false
 close_chooser()
 return true

func _apply_seed() -> void:
 var text := seed_edit.text
 var canonical := not text.is_empty() and (text=="0" or not text.begins_with("0")) and text.length()<=10
 for c in text:
  if c<"0" or c>"9":canonical=false
 if not canonical or text.to_int()>2147483647:
  refusal.text="Refused: enter a canonical integer seed 0…2147483647. Current field unchanged."
  refusal.show();return
 if not build_request(field_choice.get_item_text(field_choice.selected),text.to_int()):
  refusal.text=status.text;refusal.show()

func _button(parent: Node, key: String, text: String, callback: Callable) -> Button:
 var button := Button.new();button.text=text;button.custom_minimum_size=Vector2(90,32);button.pressed.connect(callback);parent.add_child(button);controls[key]=button
 return button

func _build_chooser() -> void:
 chooser=Control.new();chooser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);chooser.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(chooser)
 var shade := ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(0.02,0.025,0.03,.94);chooser.add_child(shade)
 var center := CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);center.mouse_filter=Control.MOUSE_FILTER_IGNORE;chooser.add_child(center)
 var panel := PanelContainer.new();center.add_child(panel)
 var rows := VBoxContainer.new();rows.custom_minimum_size.x=480;panel.add_child(rows)
 var label := Label.new();label.text="Build a disposable seeded map\nAll troops are stock example actors, not an owned company.";rows.add_child(label)
 field_choice=OptionButton.new();rows.add_child(field_choice)
 for id in FIELDS: field_choice.add_item(id)
 seed_edit=LineEdit.new();seed_edit.text="7391";seed_edit.placeholder_text="Integer seed 0…2147483647";rows.add_child(seed_edit)
 refusal=Label.new();refusal.custom_minimum_size.x=480;refusal.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;refusal.modulate=Color("ffb99d");rows.add_child(refusal);refusal.hide()
 _button(rows,"build","Build / Rebuild",_apply_seed)
 seed_edit.text_submitted.connect(func(_text):_apply_seed())
 _button(rows,"cancel","Cancel",close_chooser)
 chooser.hide()

func field_draw_rect() -> Rect2:
 var bounds := screen.get_global_rect()
 var factor := minf(bounds.size.x/float(viewport.size.x),bounds.size.y/float(viewport.size.y))
 var extent := Vector2(viewport.size)*factor
 return Rect2(bounds.get_center()-extent/2,extent)

func _field_pointer(event: InputEvent) -> void:
 if chooser.visible or replacing or not is_instance_valid(field):return
 if not event is InputEventMouse:return
 var draw_rect := field_draw_rect()
 var point: Vector2=screen.get_global_transform()*event.position
 if not draw_rect.has_point(point):return
 var mapped: InputEvent=event.duplicate()
 var scale_factor := draw_rect.size.x/float(viewport.size.x)
 mapped.position=(point-draw_rect.position)/scale_factor
 mapped.global_position=mapped.position
 if mapped is InputEventMouseMotion:mapped.relative/=scale_factor;mapped.velocity/=scale_factor
 viewport.push_input(mapped,true)
 screen.accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
 if chooser.visible or replacing or not is_instance_valid(field):return
 viewport.push_input(event.duplicate(),true)
 get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
 if is_instance_valid(field) and field.inspector_open():field.inspector.comparison_label.text="Read-only disposable battle inspection. No campaign, outfitting or saves."
 if not observe_enabled:return
 observe_time+=delta
 if observe_time>=.25:observe_time=0;_write_observation()

func _rect(rect: Rect2) -> Array:
 return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
func _transform(transform: Transform2D) -> Array:
 return [transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y]
func _control_geometry(control: Control) -> Dictionary:
 var rect := control.get_global_rect()
 var clipped := rect.intersection(get_viewport().get_visible_rect())
 var parent := control.get_parent()
 while parent!=null:
  if parent is Control and parent.clip_contents:clipped=clipped.intersection(parent.get_global_rect())
  parent=parent.get_parent()
 var shown := control.is_visible_in_tree()
 if not shown:clipped=Rect2()
 return {"rect":_rect(rect),"clipped_rect":_rect(clipped),"visible":shown,"disabled":control.disabled if control is BaseButton else not control.is_editable() if control is LineEdit else false,"text":control.text if control is Button or control is LineEdit or control is Label else ""}

func observation() -> Dictionary:
 var draw_rect := field_draw_rect()
 var scale_factor := draw_rect.size.x/float(viewport.size.x)
 var mapping := Transform2D(Vector2(scale_factor,0),Vector2(0,scale_factor),draw_rect.position)
 var window := get_window()
 var out := {"schema":"dungeon_map_gallery_observation_v1","label":banner.text,"ready":not replacing and is_instance_valid(field) and field.built and draw_rect.has_area(),"build_revision":build_revision,"source":source_binding.duplicate(true),"current":{"recipe":"seeded_crypt_v1","field":current_field,"seed":current_seed,"fingerprint":fingerprint},"window":{"physical_size":[window.size.x,window.size.y],"logical_rect":_rect(get_viewport().get_visible_rect()),"screen_transform":_transform(get_viewport().get_final_transform())},"chooser_open":chooser.visible,"refusal":refusal.text if refusal.visible else "","status":status.text,"controls":{},"field_view":{"viewport":[viewport.size.x,viewport.size.y],"draw_rect":_rect(draw_rect),"clipped_draw_rect":_rect(draw_rect.intersection(screen.get_global_rect()).intersection(get_viewport().get_visible_rect())),"field_to_window":_transform(mapping),"field_to_physical":_transform(get_viewport().get_final_transform()*mapping)},"field":field.observation() if is_instance_valid(field) and field.built else {}}
 for name in controls:out.controls[name]=_control_geometry(controls[name])
 out.controls["field_choice"]=_control_geometry(field_choice);out.controls.field_choice["selected"]=field_choice.get_item_text(field_choice.selected)
 out.controls["seed"]=_control_geometry(seed_edit)
 return out

func _write_observation() -> void:
 if not observe_enabled:return
 # Godot 4.4's JSON serializer can leave control codes in inherited item UIDs.
 # Escape raw C0 bytes in compact JSON without changing any decoded identifier.
 var raw := JSON.stringify(observation(),"",true,true)
 var strict := ""
 for c in raw:
  var code := c.unicode_at(0)
  strict+=("\\u%04x"%code) if code<32 else c
 var temporary := "user://dungeon-map-gallery-observation.json.tmp"
 var file := FileAccess.open(temporary,FileAccess.WRITE)
 if file==null:return
 file.store_string(strict);file.close()
 DirAccess.rename_absolute(temporary,"user://dungeon-map-gallery-observation.json")

func _input(event: InputEvent) -> void:
 if not chooser.visible or not event is InputEventKey or not event.pressed:return
 if event.physical_keycode==KEY_ESCAPE:
  close_chooser();get_viewport().set_input_as_handled()
 elif event.physical_keycode==KEY_TAB:
  var ring := [field_choice,seed_edit,controls.build,controls.cancel]
  var index := ring.find(get_viewport().gui_get_focus_owner())
  ring[posmod(index+(-1 if event.shift_pressed else 1),ring.size())].grab_focus()
  get_viewport().set_input_as_handled()

func open_chooser() -> void:
 if current_seed>=0:seed_edit.text=str(current_seed);field_choice.select(FIELDS.find(current_field))
 refusal.hide();chooser.show()
 if is_instance_valid(field):field.process_mode=Node.PROCESS_MODE_DISABLED
 seed_edit.grab_focus()
func close_chooser() -> void:
 chooser.hide();seed_edit.release_focus()
 if is_instance_valid(field):field.process_mode=Node.PROCESS_MODE_INHERIT
 controls.maps.grab_focus()
