extends "res://company_loop/main.gd"
## Phase composition only. World and accepted field share the one session authority.
var world: Node2D
func _create_session():
	return load("res://bandit_camps/session.gd").new()
func _create_battlefield() -> Node3D:
	return load("res://world_loop/battlefield.gd").new()
func _ready() -> void:
	checkpoint_path = "user://bandit-camps-camp.json"
	super._ready()
	DisplayServer.window_set_title("The Ashen Company — Bandit Camps")
	return_button.text = "Return to world · keep these results"
func _open_company() -> void:
	if not session.changed.is_connected(_session_changed): session.changed.connect(_session_changed)
	if not is_instance_valid(world):
		world = load("res://bandit_camps/world_view.gd").new()
		world.host = self
		world.campaign = session.campaign
		add_child(world)
	world.set_active(true)
	_save_checkpoint()
func _session_changed() -> void:
	if is_instance_valid(world):
		world.rebind(session.campaign)
		world.set_active(session.campaign.phase == "camp" and not error_panel.visible)
	if session.campaign.phase == "camp": _save_checkpoint()
func observation() -> Dictionary:
	var rect := get_viewport().get_visible_rect()
	var tx: Transform2D = get_viewport().get_final_transform()
	var out := {"world_loop":true,"bandit_camps":true,"phase":"blocked","saved_ok":saved_ok,"save_error":save_error,"checkpoint_blocked":error_panel.visible,"viewport":[rect.size.x,rect.size.y],"screen_transform":[tx.x.x,tx.x.y,tx.y.x,tx.y.y,tx.origin.x,tx.origin.y],"buttons":{}}
	if error_panel.visible:
		out["overlay_controls"] = {}
		for node in error_panel.find_children("*","Button",true,false):
			var id: String = "retry_checkpoint" if node.text == "Retry checkpoint" else "quit_without_save"
			var r: Rect2 = node.get_global_rect()
			out.buttons[id] = [r.get_center().x,r.get_center().y]
			out.overlay_controls[id] = {"title":node.text,"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"enabled":not node.disabled,"visible":node.is_visible_in_tree()}
	if session == null or session.campaign == null or _loading_failed: return out
	var c = session.campaign
	out.phase = c.phase
	out["company"] = []
	for soldier in c.soldiers:
		out.company.append({"id":soldier.id,"name":soldier.name,"alive":soldier.alive,"hp":soldier.hp,"gear":soldier.gear.duplicate(true)})
	out["inventory"] = c.items.duplicate(true)
	if is_instance_valid(world): out["world"] = world.observation()
	out["generation"] = session.deployed_generation if c.phase in ["battle","aftermath"] else session.selected_generation()
	if c.phase == "battle" and is_instance_valid(field):
		out.merge(field.observation(),true)
		out.phase = "battle"
		out["field_controls"] = {}
		if field.retreat_confirm.visible:
			out.field_controls["confirm_retreat"] = _control_observation(field.retreat_yes)
			out.field_controls["cancel_retreat"] = _control_observation(field.retreat_no)
	if c.phase == "aftermath":
		out["aftermath"] = c.aftermath.duplicate(true)
		var center := return_button.get_global_rect().get_center()
		out.buttons["return_to_camp"] = [center.x,center.y]
		out["aftermath_controls"] = {"return_to_camp":_control_observation(return_button)}
	return out

func _replace_world() -> void:
	if is_instance_valid(world):
		world.set_active(false)
		remove_child(world)
		world.queue_free()
	world = null
	_open_company()

func _load_checkpoint() -> void:
	if error_panel.visible: return
	if not session.load_camp(checkpoint_path):
		_loading_failed = true
		saved_ok = false
		_show_error("The camp checkpoint could not be validated. It has NOT been overwritten.\n\n" + session.last_error)
		return
	saved_ok = true
	_replace_world()

func _new_company(seed: int) -> void:
	if error_panel.visible or session.campaign.phase != "camp": return
	session.setup(seed)
	_replace_world()

func _show_error(message: String) -> void:
	super._show_error(message)
	if is_instance_valid(world): world.set_active(false)

func _retry_checkpoint() -> void:
	var replacing: bool = _loading_failed
	super._retry_checkpoint()
	if not error_panel.visible:
		if replacing: _replace_world()
		elif is_instance_valid(world): world.set_active(true)

func _deploy() -> void:
	if session == null or session.campaign.phase != "camp" or error_panel.visible: return
	if not _save_checkpoint(): return
	if not session.start_battle():
		world.tell(session.last_error)
		world.refresh()
		return
	_mount_field()

func _deploy_camp() -> void:
	if session == null or session.campaign == null or session.campaign.phase != "camp" or error_panel.visible or not is_instance_valid(world): return
	if not _save_checkpoint(): return
	if not session.start_camp_battle(world.world_selected):
		world.tell(session.last_error)
		world.refresh()
		return
	_mount_field()

func _mount_field() -> void:
	if session == null or session.campaign == null or session.campaign.phase != "battle" or error_panel.visible or is_instance_valid(field): return
	# Both admitted routes publish once, then use the same unchanged field lifecycle.
	world.set_active(false)
	field = _create_battlefield()
	field.session = session
	field.retreat_requested.connect(_retreat)
	add_child(field)
	_result_time = 0.0

func _return_to_camp() -> void:
	if session.campaign.phase != "aftermath": return
	if not session.return_to_camp(): return
	if is_instance_valid(field):
		field.queue_free()
		field = null
	aftermath_panel.hide()
	_result_time = 0.0
	_replace_world()

func _control_observation(node: Control) -> Dictionary:
	var r: Rect2 = node.get_global_rect()
	return {"title":node.text,"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"center":[r.get_center().x,r.get_center().y],"enabled":not node.disabled,"visible":node.is_visible_in_tree()}
