extends "res://sprite_study/battlefield.gd"
## Existing battle rules and accepted terrain, with real campaign initiative/UI boundaries.
signal retreat_requested
var session
var retreat_confirm: Control
var retreat_yes: Button
var retreat_no: Button
var _observed_active := -2
var _motion_cursor := 0

func _create_terrain() -> Node3D:
	return load("res://visual_slice/terrain.gd").new()

func _ready() -> void:
	if not auto_start: return
	if session == null or session.campaign.phase != "battle":
		push_error("Company battlefield requires a deployed campaign battle.")
		return
	observe_enabled = false # The application owns the single passive observation file.
	setup(session.campaign.battle)
	terrain = _create_terrain()
	add_child(terrain)
	terrain.build(battle)
	var Actor = load("res://company_loop/character.gd")
	for unit in battle.units:
		var actor = Actor.new()
		add_child(actor)
		actor.configure(unit,battle.armor_catalog)
		actor.position = tile_world(battle.pos(unit))
		actors[int(unit.id)] = actor
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	inspector = InspectionPanel.new()
	inspector.theme = hud.theme
	canvas.add_child(inspector)
	inspector.next_kit_button.hide()
	inspector.next_kit_button.disabled = true
	_build_retreat(canvas)
	refresh()

func _build_hud() -> void:
	super._build_hud()
	var old: Button = action_buttons.kit
	var row := old.get_parent()
	row.remove_child(old)
	old.queue_free()
	action_buttons.erase("kit")
	var withdraw := _button("Withdraw…",request_retreat)
	row.add_child(withdraw)
	row.move_child(withdraw,0)
	action_buttons.retreat = withdraw
	for container in help_panel.get_children():
		for child in container.get_children():
			if child is Label:
				child.text = "COMPANY FIELD GUIDE\n\nIndividual initiative: only the named active fighter can act.\nClick your active bro, then a highlighted hex to move.\nClick an enemy, then Attack / Enter. F / Space ends activation.\nYou may inspect another bro without giving them the turn.\nEquipment / I inspects gear; changes are only allowed in camp.\nWASD / arrows / middle drag pan; wheel / +/- zoom.\nHome close view; O overview; G grid; H / Escape closes help.\nWithdraw orders a retreat: reach a passable edge under threat.\n\nCamp autosaves. Quitting a battle resumes the last camp.\nNo prototype kit swaps or instant restarts are available."

func _build_retreat(canvas: CanvasLayer) -> void:
	retreat_confirm = Control.new()
	retreat_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	retreat_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(retreat_confirm)
	var shade := ColorRect.new()
	shade.color = Color(0.01,0.015,0.02,0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	retreat_confirm.add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -290; panel.offset_right = 290; panel.offset_top = -110; panel.offset_bottom = 110
	panel.add_theme_stylebox_override("panel",_panel_style())
	retreat_confirm.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",18)
	panel.add_child(column)
	var label := _label(20)
	label.text = "WITHDRAW FROM THE FIELD?\n\nReach your passable field edge to escape.\nEnemies can make opportunity attacks. Deaths, wounds\nand equipment damage persist. No instant escape."
	column.add_child(label)
	var buttons := HBoxContainer.new(); column.add_child(buttons)
	retreat_no = _button("Keep fighting",cancel_retreat); buttons.add_child(retreat_no)
	retreat_yes = _button("Begin physical withdrawal",confirm_retreat); buttons.add_child(retreat_yes)
	retreat_confirm.hide()

func request_retreat() -> void:
	if not built or not battle.result.is_empty() or not is_instance_valid(retreat_confirm): return
	if inspector_open(): inspector.hide()
	retreat_confirm.show()
func cancel_retreat() -> void:
	if is_instance_valid(retreat_confirm): retreat_confirm.hide()
func confirm_retreat() -> void:
	if not is_instance_valid(retreat_confirm) or not retreat_confirm.visible or not battle.result.is_empty(): return
	retreat_confirm.hide()
	retreat_requested.emit()
func cycle_kit() -> void: pass # Frozen demo hotkey must never reset campaign ownership.
func toggle_inspection() -> void:
	if is_instance_valid(retreat_confirm) and retreat_confirm.visible: return
	super.toggle_inspection()
	if inspector_open():
		inspector.next_kit_button.hide()
		inspector.next_kit_button.disabled = true
		inspector.comparison_label.text = "Read-only field inspection. Battle paused.\nChange equipment after returning to camp."

func _input(event: InputEvent) -> void:
	if is_instance_valid(retreat_confirm) and retreat_confirm.visible:
		if event is InputEventKey:
			if event.pressed and event.physical_keycode == KEY_ESCAPE: cancel_retreat()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.physical_keycode in [KEY_L,KEY_N]:
		get_viewport().set_input_as_handled()
		return
	super._input(event)
func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(retreat_confirm) and retreat_confirm.visible:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.physical_keycode in [KEY_L,KEY_N]: return
	super._unhandled_input(event)
func _process(delta: float) -> void:
	if is_instance_valid(retreat_confirm) and retreat_confirm.visible: return
	super._process(delta)

func refresh() -> void:
	if not built: return
	if battle.individual and battle.active_id != _observed_active:
		_observed_active = battle.active_id
		if battle.active_id >= 0 and battle.units[battle.active_id].side == 0:
			controller.selected = battle.active_id
			controller.target = -1
			controller.notice = "%s may act." % battle.units[battle.active_id].name
	super.refresh()
	while _motion_cursor < battle.commands.size():
		var command: Array = battle.commands[_motion_cursor]
		_motion_cursor += 1
		var target_id := -1
		if command.size() >= 3 and command[0] == "attack": target_id = int(command[2])
		elif command.size() >= 4 and command[0] == "weapon": target_id = int(command[3])
		if target_id >= 0 and actors.has(int(command[1])) and actors.has(target_id):
			var attacker = actors[int(command[1])]
			var defender = actors[target_id]
			if attacker.has_method("play_attack"): attacker.play_attack(defender.global_position-attacker.global_position)

func _update_hud() -> void:
	super._update_hud()
	if not battle.result.is_empty():
		status_label.text = "BATTLE %s · Round %d" % [battle.result.to_upper(),battle.round_no]
	else:
		var active_name: String = battle.units[battle.active_id].name if battle.active_id >= 0 else "—"
		status_label.text = "Round %d · %s: %s" % [battle.round_no,"YOUR ACTIVE BRO" if battle.side == 0 else "ENEMY ACTING",active_name]
	if kit_label: kit_label.text = "COMPANY SORTIE · Gear and losses are real"
	if action_buttons.has("end"): action_buttons.end.text = "End activation [F]"
	if action_buttons.has("retreat"): action_buttons.retreat.disabled = not battle.result.is_empty()
	if controller.selected >= 0 and battle.individual and controller.selected != battle.active_id and battle.result.is_empty():
		notice_label.text = "Inspecting %s. Only the active fighter can act." % battle.units[controller.selected].name

func _feedback(event: Dictionary) -> void:
	super._feedback(event)
	var id := int(event.get("id",-1))
	var kind := String(event.get("kind",""))
	if actors.has(id) and kind in ["hit","shield","stagger"] and actors[id].has_method("play_hit"):
		actors[id].play_hit(kind)

func observation() -> Dictionary:
	var out := super.observation()
	out.erase("kit_index"); out.erase("kit_name")
	out["individual"] = battle.individual
	out["active_id"] = battle.active_id
	out["initiative"] = battle.turn_order() if battle.has_method("turn_order") else battle.turn_queue.duplicate()
	out["retreat_confirm_open"] = is_instance_valid(retreat_confirm) and retreat_confirm.visible
	if out.retreat_confirm_open:
		var yes := retreat_yes.get_global_rect().get_center()
		var no := retreat_no.get_global_rect().get_center()
		out.buttons["confirm_retreat"] = [yes.x,yes.y]
		out.buttons["cancel_retreat"] = [no.x,no.y]
	out.buttons.erase("kit");out.buttons.erase("inspector_nextkit")
	return out
