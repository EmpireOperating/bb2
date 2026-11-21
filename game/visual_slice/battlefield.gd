extends "res://prototype/battlefield.gd"
## Presentation-only art slice. All combat commands remain in the existing engine.
const Loadouts = preload("res://visual_slice/loadouts.gd")
var kit_label: Label
var cinematic_hud := false

func _ready() -> void:
	if not auto_start: return
	DisplayServer.window_set_title("The Ashen Company — Painted Crossing")
	observe_enabled = "--observe" in OS.get_cmdline_user_args()
	setup(Loadouts.create(Loadouts.selected_profile))
	terrain = load("res://visual_slice/terrain.gd").new()
	add_child(terrain)
	terrain.build(battle)
	var actor_script = load("res://visual_slice/character.gd")
	for u in battle.units:
		var actor = actor_script.new()
		add_child(actor)
		actor.configure(u,battle.armor_catalog)
		actor.position = tile_world(battle.pos(u))
		actors[int(u.id)] = actor
	refresh()

func setup(value) -> void:
	show_grid = false
	super.setup(value)
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.background_color = Color("737666")
			child.environment.ambient_light_color = Color("c0c6cc")
			child.environment.ambient_light_energy = 0.42
			child.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			child.environment.fog_enabled = false
		elif child is DirectionalLight3D:
			child.light_color = Color("fff5e3")
			child.light_energy = 0.90
			child.rotation_degrees = Vector3(-46,-38,0)
			child.shadow_normal_bias = 0.35

func reset_camera() -> void:
	camera_focus = Vector3(11.2,0.1,5.7)
	camera.size = 14.2
	_apply_camera()
func _apply_camera() -> void:
	camera.position = camera_focus+Vector3(10,18,22)
	camera.look_at(camera_focus,Vector3.UP)
func overview() -> void:
	camera_focus = Vector3(10.8,0.0,6.0)
	camera.size = 22.0
	_apply_camera()
func next_kit_index() -> int:
	return (Loadouts.selected_profile+1)%Loadouts.KITS.size()
func cycle_kit() -> void:
	Loadouts.selected_profile = next_kit_index()
	get_tree().reload_current_scene()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_L and not help_open: cycle_kit(); return
		if event.physical_keycode == KEY_O: overview(); return
		if event.physical_keycode == KEY_F10:
			cinematic_hud = not cinematic_hud
			hud.visible = not cinematic_hud
			return
	super._unhandled_input(event)

func _hex_marker(p: Vector2i, color: Color, fill: bool) -> void:
	# Movement/attack cues remain available; reduce saturation over painted ground.
	var muted := color.lerp(Color("a4b8af"),0.20)
	if color.a < 0.5: muted.a *= 0.5
	super._hex_marker(p,muted,fill)

func _panel_style() -> StyleBoxFlat:
	var style := super._panel_style()
	style.bg_color = Color(0.055,0.045,0.034,0.94)
	style.border_color = Color("84704b")
	style.set_corner_radius_all(1)
	style.shadow_color = Color(0.02,0.016,0.01,0.4)
	style.shadow_size = 5
	return style
func _panel(anchors: int, offsets: Vector4) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(anchors)
	panel.offset_left = offsets.x; panel.offset_top = offsets.y
	panel.offset_right = offsets.z; panel.offset_bottom = offsets.w
	panel.add_theme_stylebox_override("panel",_panel_style())
	hud.add_child(panel)
	return panel
func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud)
	var theme := Theme.new()
	var font := FontFile.new()
	if font.load_dynamic_font("res://assets/sans.ttf") == OK: theme.default_font = font
	hud.theme = theme
	var top := _panel(Control.PRESET_TOP_LEFT,Vector4(16,14,495,93))
	var title_box := VBoxContainer.new(); top.add_child(title_box)
	var title := _label(24,Color("e1c58e")); title.text = "THE ASHEN COMPANY"; title_box.add_child(title)
	status_label = _label(17,Color("c2baa6")); title_box.add_child(status_label)
	var kit_panel := _panel(Control.PRESET_TOP_RIGHT,Vector4(-542,14,-16,108))
	var kit_box := VBoxContainer.new(); kit_panel.add_child(kit_box)
	kit_label = _label(18,Color("dcc28e")); kit_box.add_child(kit_label)
	var kit_row := HBoxContainer.new(); kit_row.add_theme_constant_override("separation",8); kit_box.add_child(kit_row)
	action_buttons.kit = _button("Next kit · new battle [L]",cycle_kit); kit_row.add_child(action_buttons.kit)
	action_buttons.overview = _button("Overview [O]",overview); kit_row.add_child(action_buttons.overview)
	kit_row.add_child(_button("Help [H]",_toggle_help))
	var info := _panel(Control.PRESET_BOTTOM_LEFT,Vector4(16,-173,408,-16))
	var details := VBoxContainer.new(); details.add_theme_constant_override("separation",6); info.add_child(details)
	unit_label = _label(17); details.add_child(unit_label)
	target_label = _label(16,Color("dab59f")); target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; details.add_child(target_label)
	var actions_panel := _panel(Control.PRESET_BOTTOM_RIGHT,Vector4(-716,-173,-16,-16))
	var columns := VBoxContainer.new(); columns.add_theme_constant_override("separation",6); actions_panel.add_child(columns)
	var roster := HBoxContainer.new(); roster.add_theme_constant_override("separation",6); columns.add_child(roster)
	for u in battle.units:
		if u.side != 0: continue
		var button := _button(String(u.name),func(): controller.select_unit(u.id))
		button.custom_minimum_size = Vector2(92,30)
		button.add_theme_font_size_override("font_size",16)
		roster.add_child(button); roster_buttons[int(u.id)] = button
	var actions := HBoxContainer.new(); actions.add_theme_constant_override("separation",8); columns.add_child(actions)
	action_buttons.attack = _button("Attack [Enter]",func(): controller.attack_target()); actions.add_child(action_buttons.attack)
	action_buttons.end = _button("End turn [F]",func(): controller.end_player_turn()); actions.add_child(action_buttons.end)
	actions.add_child(_button("Close view [Home]",reset_camera))
	notice_label = _label(15,Color("b5bc9d")); notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; columns.add_child(notice_label)
	log_label = _label(14,Color("b5a993")); log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; columns.add_child(log_label)
	help_panel = _panel(Control.PRESET_CENTER,Vector4(-345,-228,345,228))
	help_panel.hide()
	var help := VBoxContainer.new(); help_panel.add_child(help)
	var copy := _label(18)
	copy.text = "PAINTED CROSSING · PLAYABLE ART SLICE\n\nClick a mercenary, then a blue hex to move.\nClick an enemy to inspect, then Enter / Attack.\nF / Space ends your side and lets the raiders act.\nWASD / arrows / middle drag pan; wheel / +/- zoom.\nHome restores the close composition; O shows the board.\nG toggles the full hex grid; Tab cycles mercenaries.\nL / Next kit restarts with different REAL hero equipment.\nF10 hides/shows HUD for screenshots; H closes this help.\n\nPainted art is temporary; movement and combat are real.\nNo campaign save is read or written.\nHeight affects climb cost/hit odds, not height-aware LOS."
	help.add_child(copy); help.add_child(_button("Return to battlefield",_toggle_help))
	units_overlay = Control.new()
	units_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	units_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	units_overlay.draw.connect(_draw_unit_labels)
	hud.add_child(units_overlay); hud.move_child(units_overlay,0)
func _update_hud() -> void:
	super._update_hud()
	status_label.text = "PAINTED CROSSING  ·  Round %d  ·  %s" % [battle.round_no,"YOUR TURN" if battle.side == 0 else "RAIDERS"]
	if not battle.result.is_empty(): status_label.text = "BATTLE %s · Round %d" % [battle.result.to_upper(),battle.round_no]
	if kit_label: kit_label.text = "ALDRIC'S EQUIPMENT  ·  "+Loadouts.KITS[Loadouts.selected_profile].name
func _feedback(event: Dictionary) -> void:
	feedback_events.append(event.duplicate(true))
	var id: int = event.get("id",-1)
	if id < 0 or id >= battle.units.size(): return
	var popup := Label3D.new()
	popup.text = event.get("text","")
	popup.font_size = 42; popup.pixel_size = 0.007
	popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	popup.no_depth_test = true
	popup.modulate = Color("f2daab") if event.get("kind","") == "miss" else Color("e9a189")
	popup.outline_size = 8
	add_child(popup)
	popup.position = tile_world(battle.pos(battle.units[id]))+camera.global_basis.y*(2.15+0.22*(feedback_events.size()%3))
	var tween := create_tween().set_parallel(true)
	tween.tween_property(popup,"position",popup.position+camera.global_basis.y*0.65,1.1)
	tween.tween_property(popup,"modulate:a",0.0,1.1)
	tween.chain().tween_callback(popup.queue_free)
func observation() -> Dictionary:
	var out := super.observation()
	out["visual_slice"] = true
	out["kit_index"] = Loadouts.selected_profile
	out["kit_name"] = Loadouts.KITS[Loadouts.selected_profile].name
	out["hud_visible"] = hud.visible
	out["default_camera_size"] = 14.2
	return out
