extends "res://src/main.gd"
## Existing Iron world/town/company UI; Campaign is injected by the phase host.
var host
func _ready() -> void:
	region_camera.setup(self)
	font = load("res://assets/sans.ttf")
	serif = load("res://assets/serif.ttf")
	battle = campaign.battle
	seed_number = campaign.seed_value
	world_selected = campaign.location
	refresh()

func blocked() -> bool:
	return campaign == null or campaign.phase != "camp" or (host != null and host.error_panel.visible)

func world_controls_available() -> bool:
	return not blocked() and super.world_controls_available()

func _process(delta: float) -> void:
	if blocked(): return
	# Continuous travel/time mutates authority even on ticks without an event.
	if world_controls_available() and not campaign.overworld.paused and delta > 0.0:
		host.saved_ok = false
	var travel_before: Dictionary = region_camera.canvas.travel_begin_frame() if region_camera.canvas.has_method("travel_begin_frame") else {}
	super._process(delta)
	if not travel_before.is_empty(): region_camera.canvas.travel_end_frame(delta,travel_before)

func _input(event: InputEvent) -> void:
	if blocked(): return
	super._input(event)

func _draw() -> void:
	if campaign == null or campaign.phase != "camp":
		buttons.clear()
		return
	super._draw()

func write_save(show_notice: bool = true) -> bool:
	if host == null or blocked(): return false
	if not show_notice:
		host.saved_ok = false
		return true # Legacy routine-change notification, not a checkpoint request.
	var ok: bool = host._save_checkpoint()
	save_failed = not ok
	if show_notice and ok: tell("Company saved to Woodland Campaign checkpoint.")
	return ok

func action(id: String) -> void:
	if blocked(): return
	if id in ["world_pause","world_stop"] or id.begins_with("world_speed_"):
		var ow = campaign.overworld
		var before = [ow.paused,ow.speed,ow.path.duplicate(),ow.destination,ow.rest_left]
		super.action(id)
		if before != [ow.paused,ow.speed,ow.path,ow.destination,ow.rest_left]:host.saved_ok = false
		return
	if id == "save": write_save(); return
	if id == "load":
		if host != null: host._load_checkpoint()
		return
	if id == "deploy":
		if host != null: host._deploy()
		return
	if id == "confirm" and confirmation == "new":
		if host != null and int(seed_text) > 0: host._new_company(int(seed_text))
		return
	if id == "attack_camp" or id == "continue_campaign" or id.begins_with("accept_") or (id.begins_with("dungeon_") and id not in ["dungeon_rumour","dungeon_close"]):
		tell("Only ordinary roaming scout contacts can take the field in this Woodland Campaign slice. Camps, contracts and dungeons are unavailable.")
		refresh()
		return
	super.action(id)

func weapon_ui_action(id: String) -> void:
	# Direct inherited helper calls must obey the same gate as routed input.
	if blocked(): return
	super.weapon_ui_action(id)

func rebind(value) -> void:
	# Never attach raw legacy combat listeners; the field owns visible feedback.
	if battle != null and battle.combat_feedback.is_connected(on_combat_feedback): battle.combat_feedback.disconnect(on_combat_feedback)
	if region_camera.canvas.has_method("reset_travel_presentation"): region_camera.canvas.reset_travel_presentation()
	campaign = value
	battle = campaign.battle
	seed_number = campaign.seed_value
	camp_selected = clampi(camp_selected,0,maxi(0,campaign.soldiers.size()-1))
	feedback_popups.clear()
	buttons.clear()
	if is_inside_tree(): refresh()

func set_active(active: bool) -> void:
	if region_camera.canvas.has_method("reset_travel_presentation"): region_camera.canvas.reset_travel_presentation()
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	set_process_input(active)
	set_process_unhandled_input(active)
	if not active: buttons.clear()

func observation() -> Dictionary:
	var controls := {}
	var markers := []
	if visible and not blocked():
		for id in buttons:
			var row: Dictionary = buttons[id]
			var r: Rect2 = row.rect
			controls[id] = {"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"center":[r.get_center().x,r.get_center().y],"enabled":row.enabled,"title":row.get("title",id)}
			if id.begins_with("place_") or id.begins_with("scout_") or id.begins_with("convoy_"):
				markers.append({"id":id,"center":controls[id].center})
	var ow = campaign.overworld
	var pending := {}
	for key in ["kind","id","site","generation","title","threat","pay","objective"]:
		if campaign.encounter.has(key): pending[key] = campaign.encounter[key]
	return {"visible":visible,"map_first":world_view,"selected":world_selected,"sheet":iron.sheet,"town_page":iron.town_page,"town_tab":town_tab,"context_open":iron.detail,"buttons":controls,"known_markers":markers,"position":[ow.position.x,ow.position.y],"location":campaign.location,"in_town":campaign.in_town(),"day":campaign.day,"hour":ow.hour,"paused":ow.paused,"speed":ow.speed,"travelling":not ow.path.is_empty(),"pending_contact":pending,"resources":{"crowns":campaign.crowns,"food":campaign.food,"tools":campaign.tools,"medicine":campaign.medicine,"ammunition":campaign.ammunition},"notice":notice if notice_time > 0 else "","camera":{"center":[region_camera.center.x,region_camera.center.y],"zoom":region_camera.zoom,"follow":region_camera.follow,"rect":[0,64,1440,788]}}

func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
	if id == "load" and host != null: enabled = FileAccess.file_exists(host.checkpoint_path)
	super.button(id,title,rect,enabled,primary)
	buttons[id]["title"] = title
