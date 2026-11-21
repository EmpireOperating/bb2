extends Node3D
## The view owns no combat rules: commands and queries go through BattleController/Battle.
const Layout = preload("res://prototype/hex_layout.gd")
const Controller = preload("res://prototype/battle_controller.gd")
var auto_start := true
var battle
var controller = Controller.new()
var camera: Camera3D
var terrain: Node3D
var actors := {}
var actor_tweens := {}
var markers: Node3D
var hud: Control
var camera_focus := Vector3(10.8,0,6.0)
var ai_time := 0.0
var observe_time := 0.0
var revision := 0
var hover := Vector2i(-1,-1)
var hover_text := ""
var feedback_events: Array = []
var show_grid := true
var help_open := false
var built := false
var input_events := 0
var action_buttons := {}
var roster_buttons := {}
var status_label: Label
var unit_label: Label
var target_label: Label
var notice_label: Label
var log_label: Label
var help_panel: PanelContainer
var units_overlay: Control
var last_command_count := -1
var camera_velocity := Vector2.ZERO
var observe_enabled := false

func _ready() -> void:
	if not auto_start: return
	DisplayServer.window_set_title("The Ashen Company — Ruined Crossing 2.5D")
	observe_enabled = "--observe" in OS.get_cmdline_user_args()
	var scenario = load("res://prototype/scenario.gd")
	setup(scenario.create())
	terrain = load("res://prototype/terrain.gd").new()
	add_child(terrain)
	terrain.build(battle)
	var actor_script = load("res://prototype/character.gd")
	for u in battle.units:
		var actor = actor_script.new()
		add_child(actor)
		actor.configure(u,battle.armor_catalog)
		actor.position = tile_world(battle.pos(u))
		actors[int(u.id)] = actor
	refresh()

func setup(value) -> void:
	battle = value
	controller.attach(battle)
	controller.changed.connect(refresh)
	battle.combat_feedback.connect(_feedback)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 160.0
	add_child(camera)
	camera.make_current()
	reset_camera()
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101713")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("aebcc3")
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = false
	env.fog_light_color = Color("606966")
	env.fog_density = 0.004
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe4b3")
	sun.light_energy = 0.85
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 0.8
	add_child(sun)
	markers = Node3D.new()
	add_child(markers)
	_build_hud()
	built = true
	controller.select_unit(0)

func tile_world(p: Vector2i) -> Vector3:
	return Layout.world(p,float(battle.tiles.get(battle.key(p),{}).get("height",0)))
func reset_camera() -> void:
	camera_focus = Vector3(10.8,0,6.0)
	camera.size = 20.5
	_apply_camera()
func _apply_camera() -> void:
	camera.position = camera_focus + Vector3(13,22,22)
	camera.look_at(camera_focus,Vector3.UP)
func zoom_camera(amount: float) -> void:
	camera.size = clampf(camera.size+amount,10.0,31.0)
func pan_camera(delta: Vector2) -> void:
	camera_focus += camera.basis.x * delta.x + Vector3(camera.basis.z.x,0,camera.basis.z.z).normalized()*delta.y
	camera_focus.x = clampf(camera_focus.x,-2,24)
	camera_focus.z = clampf(camera_focus.z,-3,16)
	_apply_camera()

func _process(delta: float) -> void:
	if not built: return
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): direction.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): direction.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): direction.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): direction.y += 1
	if direction != Vector2.ZERO and not help_open: pan_camera(direction.normalized()*delta*camera.size*0.45)
	if battle.auto_step_needed() and not help_open:
		ai_time += delta
		if ai_time >= 0.72:
			ai_time = 0.0
			controller.enemy_step()
	if terrain != null:
		var feet: Array = []
		for u in battle.units:
			if battle.living(u): feet.append(tile_world(battle.pos(u)))
		terrain.update_occlusion(camera,feet)
	if units_overlay != null: units_overlay.queue_redraw()
	observe_time += delta
	if observe_enabled and observe_time >= 0.25:
		observe_time = 0.0
		_write_observation()

func _unhandled_input(event: InputEvent) -> void:
	if not built: return
	input_events += 1
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F, KEY_SPACE: if not help_open: controller.end_player_turn()
			KEY_ENTER: if not help_open: controller.attack_target()
			KEY_HOME: reset_camera()
			KEY_MINUS: zoom_camera(1.4)
			KEY_EQUAL, KEY_PLUS: zoom_camera(-1.4)
			KEY_H, KEY_ESCAPE: _toggle_help()
			KEY_TAB: _cycle_unit()
			KEY_G: show_grid = not show_grid; refresh()
			KEY_N: if not help_open: get_tree().reload_current_scene()
	if help_open: return
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			pan_camera(Vector2(-event.relative.x,-event.relative.y)*camera.size/get_viewport().get_visible_rect().size.y)
		else:
			hover = pick_hex(event.position)
			_update_hover()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom_camera(-1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom_camera(1.1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var id := pick_unit(event.position)
			if id >= 0:
				if battle.units[id].side == 0: controller.select_unit(id)
				elif controller.target == id: controller.attack_target()
				else: controller.select_target(id)
			else:
				var p := pick_hex(event.position)
				if battle.tiles.has(battle.key(p)): controller.move_to(p)

func pick_unit(screen: Vector2) -> int:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var found := -1
	var best := INF
	for u in battle.units:
		if not battle.living(u) or not actors.has(int(u.id)): continue
		var actor: Node3D = actors[int(u.id)]
		var illustration := actor.get_node_or_null("Illustration")
		if not actor.is_visible_in_tree() or illustration == null: continue
		# Intersect the rendered camera-facing layers, not the simulation's tile
		# or a world-up box. Layer transforms include the current movement tween.
		for sprite: Sprite3D in illustration.get_children():
			if not sprite.is_visible_in_tree() or sprite.texture == null: continue
			var normal := sprite.global_basis.z.normalized()
			var denominator := direction.dot(normal)
			if absf(denominator) < 0.00001: continue
			var distance := (sprite.global_position-origin).dot(normal)/denominator
			if distance < 0.0 or distance >= best: continue
			var local := sprite.to_local(origin+direction*distance)
			var bounds := sprite.get_aabb()
			var pixel := Vector2i(floori((local.x-bounds.position.x)/sprite.pixel_size),
				floori((bounds.end.y-local.y)/sprite.pixel_size))
			if pixel.x < 0 or pixel.y < 0 or pixel.x >= sprite.texture.get_width() or pixel.y >= sprite.texture.get_height(): continue
			if sprite.flip_h: pixel.x = sprite.texture.get_width()-1-pixel.x
			# Cache only on this layer's lifetime; refresh replaces the node/texture.
			# Transparent margins must not steal a visible actor behind this one.
			if not sprite.has_meta("pick_alpha"): sprite.set_meta("pick_alpha",sprite.texture.get_image())
			var image: Image = sprite.get_meta("pick_alpha")
			if image.get_pixelv(pixel).a*sprite.modulate.a <= sprite.alpha_scissor_threshold: continue
			found = int(u.id)
			best = distance
	return found
func pick_hex(screen: Vector2) -> Vector2i:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var found := Vector2i(-1,-1)
	var nearest := INF
	for k in battle.tiles:
		var bits: PackedStringArray = k.split(",")
		var p := Vector2i(int(bits[0]),int(bits[1]))
		var y := tile_world(p).y
		var t := (y-origin.y)/direction.y
		if t <= 0 or t >= nearest: continue
		var point := origin+direction*t
		if Layout.from_world(point) == p:
			found = p
			nearest = t
	return found
func _update_hover() -> void:
	if not battle.tiles.has(battle.key(hover)): hover_text = ""; return
	var tile: Dictionary = battle.tiles[battle.key(hover)]
	hover_text = "%s · elevation %d · hex %d,%d" % [String(tile.terrain).capitalize(),tile.height,hover.x,hover.y]
	if tile.terrain in ["wall","water"]: hover_text += " · BLOCKED"
	elif controller.selected >= 0:
		var moves: Dictionary = battle.movement_map(controller.selected)
		if moves.has(battle.key(hover)): hover_text += " · %d AP" % moves[battle.key(hover)].cost
	if notice_label: notice_label.text = hover_text
func _cycle_unit() -> void:
	for step in battle.units.size():
		var id: int = (controller.selected+step+1)%battle.units.size()
		if battle.units[id].side == 0 and battle.fighting(battle.units[id]): controller.select_unit(id); return

func refresh() -> void:
	if not built: return
	revision += 1
	for u in battle.units:
		if not actors.has(int(u.id)): continue
		var actor: Node3D = actors[int(u.id)]
		actor.visible = battle.living(u)
		actor.refresh(u,battle.armor_catalog)
		actor.set_selected(int(u.id) == controller.selected)
		var destination := tile_world(battle.pos(u))
		if actor.position.distance_to(destination) > 0.01:
			if actor_tweens.has(u.id): actor_tweens[u.id].kill()
			var tween := create_tween()
			tween.tween_property(actor,"position",destination,0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			actor_tweens[u.id] = tween
	for node in markers.get_children(): markers.remove_child(node); node.queue_free()
	var reachable: Dictionary = battle.movement_map(controller.selected) if controller.selected >= 0 else {}
	for k in battle.tiles:
		var parts: PackedStringArray = k.split(",")
		var p := Vector2i(int(parts[0]),int(parts[1]))
		var color := Color(0.85,0.79,0.60,0.12)
		var fill := false
		if reachable.has(k): color = Color(0.28,0.69,0.86,0.58); fill = true
		if battle.tiles[k].terrain in ["wall","water"]: color = Color(0.69,0.39,0.28,0.23)
		var occupant: int = battle.at(p)
		if occupant >= 0 and controller.selected >= 0 and battle.can_attack(controller.selected,occupant): color = Color(0.90,0.31,0.23,0.75); fill = true
		if occupant >= 0 and occupant == controller.selected: color = Color(0.55,0.91,1.0,1.0); fill = true
		if occupant >= 0 and occupant == controller.target: color = Color(1.0,0.45,0.25,1.0); fill = true
		if show_grid or fill: _hex_marker(p,color,fill)
	_update_hud()
func _hex_marker(p: Vector2i, color: Color, fill: bool) -> void:
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	var corners := Layout.corners(p,float(battle.tiles[battle.key(p)].height),0.94)
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,material)
	for i in 6:
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(corners[i]+Vector3.UP*0.035)
		mesh.surface_add_vertex(corners[(i+1)%6]+Vector3.UP*0.035)
	mesh.surface_end()
	if fill:
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,material)
		for i in 6:
			mesh.surface_set_color(Color(color,color.a*0.17))
			mesh.surface_add_vertex(tile_world(p)+Vector3.UP*0.028)
			mesh.surface_add_vertex(corners[i]+Vector3.UP*0.028)
			mesh.surface_add_vertex(corners[(i+1)%6]+Vector3.UP*0.028)
		mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	markers.add_child(instance)
func _feedback(event: Dictionary) -> void:
	feedback_events.append(event.duplicate(true))
	var id: int = event.get("id",-1)
	if id < 0 or id >= battle.units.size(): return
	var text := Label3D.new()
	text.text = event.get("text","")
	text.font_size = 56
	text.pixel_size = 0.008
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = true
	text.modulate = Color("ffdc9d") if event.get("kind","") == "miss" else Color("ff8f70")
	text.outline_size = 10
	add_child(text)
	text.position = tile_world(battle.pos(battle.units[id]))+Vector3.UP*2.15
	var tween := create_tween().set_parallel(true)
	tween.tween_property(text,"position:y",text.position.y+1.1,1.4)
	tween.tween_property(text,"modulate:a",0.0,1.4)
	tween.chain().tween_callback(text.queue_free)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045,0.054,0.055,0.95)
	style.border_color = Color("75684c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style
func _label(size: int, color: Color = Color("e0d6bd")) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
func _button(title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(100,38)
	button.add_theme_stylebox_override("normal",_panel_style())
	var highlight := _panel_style()
	highlight.bg_color = Color("39433f")
	highlight.border_color = Color("d5bb77")
	button.add_theme_stylebox_override("hover",highlight)
	button.add_theme_stylebox_override("pressed",highlight)
	button.add_theme_font_size_override("font_size",15)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button
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
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14; top.offset_top = 12; top.offset_right = -14
	top.add_theme_stylebox_override("panel",_panel_style())
	hud.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	top.add_child(row)
	var title := _label(21,Color("e1c78d"))
	title.text = "THE ASHEN COMPANY"
	row.add_child(title)
	status_label = _label(17)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status_label)
	row.add_child(_button("Help  [H]",_toggle_help))
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 14; bottom.offset_right = -14; bottom.offset_top = -170; bottom.offset_bottom = -12
	bottom.add_theme_stylebox_override("panel",_panel_style())
	hud.add_child(bottom)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",20)
	bottom.add_child(columns)
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = 270
	columns.add_child(details)
	unit_label = _label(16)
	details.add_child(unit_label)
	target_label = _label(14,Color("e5aa92"))
	details.add_child(target_label)
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(center)
	var roster := HBoxContainer.new()
	center.add_child(roster)
	for u in battle.units:
		if u.side != 0: continue
		var button := _button(String(u.name),func(): controller.select_unit(u.id))
		button.custom_minimum_size = Vector2(66,30)
		button.add_theme_font_size_override("font_size",13)
		roster.add_child(button)
		roster_buttons[int(u.id)] = button
	var actions := HBoxContainer.new()
	center.add_child(actions)
	action_buttons.attack = _button("Attack  [Enter]",func(): controller.attack_target())
	actions.add_child(action_buttons.attack)
	action_buttons.end = _button("End turn  [F]",func(): controller.end_player_turn())
	actions.add_child(action_buttons.end)
	actions.add_child(_button("New battle",func(): get_tree().reload_current_scene()))
	notice_label = _label(14,Color("bfcbb7"))
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(notice_label)
	log_label = _label(13,Color("ada994"))
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(log_label)
	help_panel = PanelContainer.new()
	help_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	help_panel.position = Vector2(-320,-215)
	help_panel.size = Vector2(640,430)
	help_panel.add_theme_stylebox_override("panel",_panel_style())
	help_panel.visible = false
	hud.add_child(help_panel)
	var help := VBoxContainer.new()
	help_panel.add_child(help)
	var help_text := _label(17)
	help_text.text = "RUINED CROSSING · 2.5D RENDERING PROOF\n\nClick a mercenary or their name to select.\nBlue hexes: reachable with current AP and fatigue.\nClick an enemy to inspect; click again or Enter to attack.\nF / Space: end your side's turn; raiders use existing AI.\nWASD / arrows or middle-drag: pan. Wheel / +/-: zoom.\nHome: reset camera. Tab: next mercenary. G: grid.\n\nGold terrain height is real: climbing costs extra AP.\nStone ruins and deep water block movement.\nTrees and walls block shots using existing hex LOS.\nHeight-dependent LOS and partial cover are NOT simulated.\n\nThis battle never reads or writes your campaign saves.\nTemporary layered art is driven by actual equipment."
	help.add_child(help_text)
	help.add_child(_button("Return to battle",_toggle_help))
	units_overlay = Control.new()
	units_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	units_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	units_overlay.draw.connect(_draw_unit_labels)
	hud.add_child(units_overlay)
	hud.move_child(units_overlay,0)
func _toggle_help() -> void:
	help_open = not help_open
	help_panel.visible = help_open
func _update_hud() -> void:
	status_label.text = "Ruined Crossing   ·   Round %d   ·   %s" % [battle.round_no,"YOUR TURN" if battle.side == 0 else "RAIDERS"]
	if not battle.result.is_empty(): status_label.text = "BATTLE %s · Round %d" % [battle.result.to_upper(),battle.round_no]
	if controller.selected >= 0:
		var u: Dictionary = battle.units[controller.selected]
		unit_label.text = "%s · %s\nHP %d/%d   AP %d/%d\nBody %d   Head %d   Fatigue %d\n%s · %s" % [u.name,String(u.weapon).capitalize(),u.hp,u.max_hp,u.ap,battle.MAX_AP,u.armor+u.padding,u.helmet,u.fatigue,"Shield" if u.shield else "No shield","ELEV %d" % battle.tiles[battle.key(battle.pos(u))].height]
	if controller.target >= 0:
		var v: Dictionary = battle.units[controller.target]
		target_label.text = "%s · HP %d · armor %d\n%s" % [v.name,v.hp,v.armor+v.padding,"Hit chance %d%%" % battle.hit_chance(controller.selected,controller.target) if battle.can_attack(controller.selected,controller.target) else "Not a legal target yet"]
	else: target_label.text = "Objective: defeat or rout the raiders."
	action_buttons.attack.disabled = controller.target < 0 or controller.selected < 0 or not battle.can_attack(controller.selected,controller.target)
	action_buttons.end.disabled = battle.side != 0 or not battle.result.is_empty()
	for id in roster_buttons:
		roster_buttons[id].modulate = Color("a2e7ed") if id == controller.selected else Color.WHITE
		roster_buttons[id].disabled = not battle.living(battle.units[id])
	notice_label.text = controller.notice
	var lines: Array = []
	for i in range(maxi(0,battle.events.size()-2),battle.events.size()): lines.append(str(battle.events[i]))
	log_label.text = "\n".join(lines)
func unit_label_point(foot: Vector3) -> Vector2:
	return camera.unproject_position(foot+camera.global_basis.y*2.3)
func _draw_unit_labels() -> void:
	var font := ThemeDB.fallback_font
	for u in battle.units:
		if not battle.living(u): continue
		var world: Vector3 = actors[int(u.id)].position if actors.has(int(u.id)) else tile_world(battle.pos(u))
		var point := unit_label_point(world)
		var rect := Rect2(point+Vector2(-28,-5),Vector2(56,9))
		units_overlay.draw_rect(rect,Color(0.04,0.04,0.04,0.9))
		units_overlay.draw_rect(Rect2(rect.position+Vector2.ONE,Vector2(54*float(u.hp)/u.max_hp,4)),Color("659eaf") if u.side == 0 else Color("b74938"))
		var armor: float = float(u.armor+u.padding)/maxf(1.0,float(u.max_armor+u.max_padding))
		units_overlay.draw_rect(Rect2(rect.position+Vector2(1,6),Vector2(54*armor,2)),Color("c0bba6"))
		if int(u.id) in [controller.selected,controller.target]: units_overlay.draw_string(font,point+Vector2(-28,-9),u.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f3e5c6"))
func observation() -> Dictionary:
	var out := {"revision":revision,"input_events":input_events,"side":battle.side,"round":battle.round_no,"result":battle.result,"selected":controller.selected,"target":controller.target,"commands":battle.commands.duplicate(true),"feedback":feedback_events.duplicate(true),"camera_size":camera.size,"camera_position":[camera.position.x,camera.position.y,camera.position.z],"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"units":[],"hexes":{},"buttons":{},"hover":hover_text}
	out["can_attack"] = controller.selected >= 0 and controller.target >= 0 and battle.can_attack(controller.selected,controller.target)
	out["animating"] = actor_tweens.values().any(func(t): return t.is_running())
	var transform: Transform2D = get_viewport().get_final_transform()
	out["screen_transform"] = [transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y]
	for u in battle.units:
		var foot: Vector3 = actors[int(u.id)].global_position if actors.has(int(u.id)) else to_global(tile_world(battle.pos(u)))
		var p := camera.unproject_position(foot+camera.global_basis.y*1.0)
		var head := camera.unproject_position(foot+camera.global_basis.y*1.8)
		out.units.append({"id":u.id,"side":u.side,"name":u.name,"q":u.q,"r":u.r,"hp":u.hp,"ap":u.ap,"armor":u.armor,"helmet":u.helmet,"living":battle.living(u),"screen":[p.x,p.y],"head_screen":[head.x,head.y],"layers":actors[int(u.id)].layer_signature() if actors.has(int(u.id)) else {}})
	for k in battle.tiles:
		var bits: PackedStringArray = k.split(",")
		var p := camera.unproject_position(tile_world(Vector2i(int(bits[0]),int(bits[1]))))
		out.hexes[k] = [p.x,p.y]
	for key in action_buttons:
		var p: Vector2 = action_buttons[key].get_global_rect().get_center()
		out.buttons[key] = [p.x,p.y]
	return out
func _write_observation() -> void:
	var f := FileAccess.open("user://prototype-observation.json",FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(observation()))
