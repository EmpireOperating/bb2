extends Node
## Owns phases and isolated camp checkpoints; gameplay/ownership remain in Campaign.
var session
var checkpoint_path := "user://company-camp.json"
var camp_panel: Control
var field: Node3D
var aftermath_panel: Control
var return_button: Button
var error_panel: Control
var error_label: Label
var saved_ok := false
var save_error := ""
var _loading_failed := false
var _saving := false
var _result_time := 0.0
var _observe_time := 0.0
var observe_enabled := false
var _canvas: CanvasLayer
var _aftermath_text: RichTextLabel

func _create_session():
	return load("res://company_loop/session.gd").new()

func _create_camp_panel() -> Control:
	return load("res://company_loop/camp_panel.gd").new()

func _create_battlefield() -> Node3D:
	return load("res://company_loop/battlefield.gd").new()

func _ready() -> void:
	DisplayServer.window_set_title("The Ashen Company — Company Outfitting")
	observe_enabled = "--observe" in OS.get_cmdline_user_args()
	_canvas = CanvasLayer.new()
	_canvas.layer = 30
	add_child(_canvas)
	_build_overlays()
	session = _create_session()
	if _show_launch_title(): return
	if FileAccess.file_exists(checkpoint_path):
		if not session.load_camp(checkpoint_path):
			_loading_failed = true
			_show_error("The camp checkpoint could not be validated. It has NOT been overwritten.\n\n" + session.last_error)
			return
		saved_ok = true
	else:
		session.setup()
	_open_company()

func _show_launch_title() -> bool:
	return false

func _open_company() -> void:
	if not session.changed.is_connected(_session_changed): session.changed.connect(_session_changed)
	camp_panel = _create_camp_panel()
	_canvas.add_child(camp_panel)
	_canvas.move_child(camp_panel,0)
	camp_panel.set_session(session)
	camp_panel.deploy_requested.connect(_deploy)

func _session_changed() -> void:
	saved_ok = false

func _save_checkpoint() -> bool:
	if _saving or _loading_failed: return false
	if session == null or session.campaign == null or session.campaign.phase != "camp": return false
	_saving = true
	saved_ok = session.save_camp(checkpoint_path)
	save_error = "" if saved_ok else String(session.last_error)
	_saving = false
	if not saved_ok: _show_error("Camp changes are not safely saved yet. Deployment is blocked.\n\n" + save_error)
	return saved_ok

func _retry_checkpoint() -> void:
	if _loading_failed:
		if not session.load_camp(checkpoint_path):
			_show_error("The camp checkpoint still cannot be validated. It remains untouched.\n\n" + session.last_error)
			return
		_loading_failed = false
		saved_ok = true
		error_panel.hide()
		_open_company()
	elif not save_error.is_empty() and _save_checkpoint(): error_panel.hide()

func _deploy() -> void:
	if session == null or session.campaign == null or session.campaign.phase != "camp" or error_panel.visible: return
	if not session.start_battle():
		camp_panel.refresh()
		return
	camp_panel.hide()
	field = _create_battlefield()
	field.session = session
	field.retreat_requested.connect(_retreat)
	add_child(field)
	_result_time = 0.0

func _retreat() -> void:
	if session.campaign.phase != "battle": return
	if session.retreat_battle(): _show_aftermath()

func _settle() -> void:
	if session.campaign.phase != "battle": return
	if session.resolve_battle(): _show_aftermath()

func _show_aftermath() -> void:
	if session.campaign.phase != "aftermath": return
	if is_instance_valid(field):
		field.process_mode = Node.PROCESS_MODE_DISABLED
		field.hide()
		for node in field.get_children():
			if node is CanvasLayer: node.hide()
	var result: Dictionary = session.campaign.aftermath
	var lines: Array[String] = []
	lines.append("WITHDRAWAL" if result.get("retreat",false) else String(result.get("result","")).to_upper())
	lines.append("%s · Round %d" % [result.get("title","Company sortie"),result.get("round",0)])
	lines.append("\n%d fallen · %d wounded · %d crowns paid" % [result.get("fallen",0),result.get("wounded",0),result.get("pay",0)])
	for row in result.get("rows",[]):
		lines.append("%s — %s · %d HP · %d kills · +%d XP" % [row.name,row.status,row.hp,row.kills,row.get("xp",0)])
	lines.append("\nRecovered items: %d" % result.get("loot",[]).size())
	lines.append(String(result.get("effect","")))
	lines.append("\nWounds, casualties and equipment damage persist. Returning to camp does not heal or repair the company.")
	_aftermath_text.text = "\n".join(lines)
	aftermath_panel.show()

func _return_to_camp() -> void:
	if session.campaign.phase != "aftermath": return
	if not session.return_to_camp(): return
	if is_instance_valid(field):
		field.queue_free()
		field = null
	aftermath_panel.hide()
	camp_panel.refresh()
	camp_panel.show()
	_result_time = 0.0


func _process(delta: float) -> void:
	if session != null and session.campaign != null and session.campaign.phase == "battle":
		var outcome_waits: bool = is_instance_valid(field) and field.battle == session.campaign.battle and field.has_method("impact_pending") and field.impact_pending()
		if not session.campaign.battle.result.is_empty() and not outcome_waits:
			_result_time += delta
			if _result_time >= 0.6: _settle()
	if observe_enabled:
		_observe_time += delta
		if _observe_time >= 0.25:
			_observe_time = 0.0
			_write_observation()

func _panel(title: String) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.add_child(overlay)
	var background := ColorRect.new()
	background.color = Color("171b20")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	overlay.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	margin.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_color_override("font_color",Color("dec69b"))
	heading.add_theme_font_size_override("font_size",26)
	column.add_child(heading)
	return {"root":overlay,"column":column}

func _build_overlays() -> void:
	var result := _panel("THE COMPANY RETURNS")
	aftermath_panel = result.root
	_aftermath_text = RichTextLabel.new()
	_aftermath_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_aftermath_text.add_theme_font_size_override("normal_font_size",19)
	_aftermath_text.bbcode_enabled = false
	result.column.add_child(_aftermath_text)
	return_button = Button.new()
	return_button.text = "Return to camp · keep these results"
	return_button.custom_minimum_size.y = 44
	return_button.pressed.connect(_return_to_camp)
	result.column.add_child(return_button)
	aftermath_panel.hide()
	var error := _panel("CHECKPOINT NEEDS ATTENTION")
	error_panel = error.root
	error_label = Label.new()
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	error_label.add_theme_font_size_override("font_size",19)
	error.column.add_child(error_label)
	var retry := Button.new()
	retry.text = "Retry checkpoint"
	retry.custom_minimum_size.y = 44
	retry.pressed.connect(_retry_checkpoint)
	error.column.add_child(retry)
	var close := Button.new()
	close.text = "Quit without overwriting the checkpoint"
	close.pressed.connect(func(): get_tree().quit())
	error.column.add_child(close)
	error_panel.hide()

func _show_error(message: String) -> void:
	error_label.text = message
	error_panel.show()

func observation() -> Dictionary:
	var out := {"company_loop":true,"phase":"blocked","saved_ok":saved_ok,"save_error":save_error,"checkpoint_path":ProjectSettings.globalize_path(checkpoint_path),"checkpoint_blocked":error_panel.visible,"buttons":{}}
	var rect := get_viewport().get_visible_rect()
	out["viewport"] = [rect.size.x,rect.size.y]
	var transform: Transform2D = get_viewport().get_final_transform()
	out["screen_transform"] = [transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y]
	if session == null or session.campaign == null or _loading_failed: return out
	out.phase = session.campaign.phase
	out["encounters"] = session.campaign.encounters
	out["company"] = []
	for soldier in session.campaign.soldiers:
		out.company.append({"id":soldier.id,"name":soldier.name,"alive":soldier.alive,"hp":soldier.hp,"gear":session.gear_slots(soldier.id),"visual_id":soldier.id})
	out["inventory"] = session.campaign.items.duplicate(true)
	if is_instance_valid(camp_panel): out["camp"] = camp_panel.observation()
	if out.phase == "battle" and is_instance_valid(field):
		out.merge(field.observation(),true)
		out["phase"] = "battle"
	if out.phase == "aftermath":
		out["aftermath"] = session.campaign.aftermath.duplicate(true)
		var center := return_button.get_global_rect().get_center()
		out.buttons["return_to_camp"] = [center.x,center.y]
	return out

func _write_observation() -> void:
	var text := JSON.stringify(observation())
	var file := FileAccess.open("user://company-observation.json.tmp",FileAccess.WRITE)
	if file == null: return
	file.store_string(text)
	file.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path("user://company-observation.json.tmp"),ProjectSettings.globalize_path("user://company-observation.json"))
