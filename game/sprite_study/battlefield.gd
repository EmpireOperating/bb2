extends "res://visual_slice/battlefield.gd"
## Equipment study: unchanged painted terrain, rules and camera; new actor presentation.
const InspectionPanel = preload("res://sprite_study/inspection_panel.gd")
var inspector: Control

func _ready() -> void:
	if not auto_start: return
	DisplayServer.window_set_title("The Ashen Company — Equipment Study")
	observe_enabled = "--observe" in OS.get_cmdline_user_args()
	setup(Loadouts.create(Loadouts.selected_profile))
	terrain = load("res://visual_slice/terrain.gd").new()
	add_child(terrain)
	terrain.build(battle)
	var actor_script = load("res://sprite_study/character.gd")
	for u in battle.units:
		var actor = actor_script.new()
		add_child(actor)
		actor.configure(u, battle.armor_catalog)
		actor.position = tile_world(battle.pos(u))
		actors[int(u.id)] = actor
	refresh()
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	inspector = InspectionPanel.new()
	inspector.theme = hud.theme
	canvas.add_child(inspector)
	inspector.fresh_kit_requested.connect(cycle_kit)

func _build_hud() -> void:
	super._build_hud()
	var equipment := _button("Equipment [I]", toggle_inspection)
	equipment.position = Vector2(16, 106)
	equipment.size = Vector2(190, 40)
	hud.add_child(equipment)
	action_buttons.equipment = equipment

func inspector_open() -> bool:
	return is_instance_valid(inspector) and inspector.visible

func toggle_inspection() -> void:
	if inspector_open():
		inspector.hide()
		return
	if help_open or controller.selected < 0: return
	var u: Dictionary = battle.units[controller.selected]
	if u.side != 0 or not battle.living(u): return
	if not actors.has(int(u.id)): return
	inspector.set_comparison(String(battle.units[0].name), String(Loadouts.KITS[next_kit_index()].name))
	inspector.present(u, battle.armor_catalog, actors[int(u.id)], battle)

func _input(event: InputEvent) -> void:
	if not built: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_I or (inspector_open() and event.physical_keycode == KEY_ESCAPE):
			toggle_inspection()
			get_viewport().set_input_as_handled()
			return
	if inspector_open() and event is InputEventKey:
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not inspector_open():
		super._process(delta)
		return
	# Preserve the AI accumulator as well as combat/RNG state. Observation stays live.
	observe_time += delta
	if observe_enabled and observe_time >= 0.25:
		observe_time = 0.0
		_write_observation()

func _unhandled_input(event: InputEvent) -> void:
	if inspector_open():
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func observation() -> Dictionary:
	var out := super.observation()
	out["sprite_study"] = true
	out["inspector_open"] = inspector_open()
	out["inspector"] = inspector.observation() if is_instance_valid(inspector) else {}
	out["preview_unit_id"] = out.inspector.get("preview_unit_id", -1)
	out["preview_layers"] = out.inspector.get("preview_layers", {})
	if inspector_open():
		out.buttons["inspector_close"] = out.inspector.buttons.close
		out.buttons["inspector_nextkit"] = out.inspector.buttons.nextkit
	return out
