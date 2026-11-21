extends "res://world_loop/world_view.gd"
## Owned copy of the small camp adapter over the common world base: no ancestor accept/paint bypass.
var _contract_ui := {"version":1,"surface":"","rows":[],"active":{},"controls":{}}
var _painted_labels := {}
var contract_policy_painted := false
var _journal_ui := {"version":1,"surface":"","page":0,"entries":[],"controls":{}}

func _draw() -> void:
	_contract_ui = {"version":1,"surface":"","rows":[],"active":{},"controls":{}}
	_journal_ui = {"version":1,"surface":"","page":0,"entries":[],"controls":{}}
	_painted_labels.clear()
	contract_policy_painted = false
	super._draw()
	_finish_contract_surface()
	if visible and not blocked() and iron.sheet == "journal" and buttons.has("iron_log_next"):
		_journal_ui.surface = "journal"
		_journal_ui.page = iron.journal_page
		for i in 6:
			var lines: Array[String] = []
			for j in 2:
				var p := Vector2i(260,365+i*48+j*19)
				if _painted_labels.has(p): lines.append(_painted_labels[p])
			if not lines.is_empty(): _journal_ui.entries.append("\n".join(lines))
		for id in ["iron_log_prev","iron_log_next","iron_close"]: _journal_ui.controls[id] = _public_control(id)

func _finish_contract_surface() -> void:
	if not visible or not world_controls_available(): return
	if _painted_labels.get(Vector2i(1030,335)) == "ACCEPTED CONTRACT":
		var brief: Array = []
		for y in [393,412]:
			if _painted_labels.has(Vector2i(1030,y)): brief.append(_painted_labels[Vector2i(1030,y)])
		_contract_ui.surface = "active"
		_contract_ui.active = {"title":_painted_labels[Vector2i(1030,365)],"brief_lines":brief,"pay":campaign.active.pay,"deadline":campaign.active.deadline,"danger":_painted_labels[Vector2i(1030,461)]}
	elif _painted_labels.has(Vector2i(1032,669)) and _painted_labels[Vector2i(1032,669)].begins_with("Contract · "):
		_contract_ui.surface = "town_reminder"
		_contract_ui.active = {"title":_painted_labels[Vector2i(1032,669)].trim_prefix("Contract · "),"deadline":campaign.active.deadline}
	if not _contract_ui.surface.is_empty():
		for id in ["deploy","abandon","iron_detail_close"]:
			if buttons.has(id): _contract_ui.controls[id] = _public_control(id)

func known_news(message: String) -> bool:
	# Personal standing with a known council is already public in Councils. The
	# stock place-name filter otherwise hides our own paid consequence merely
	# because its static rival council names an undiscovered town. Keep every
	# other world-news filter unchanged; never admit remote activity this way.
	for id in campaign.world.FACTIONS:
		if known_site(campaign.world.config.factions[id].town) and message.begins_with(campaign.world.faction_name(id)+": reputation "): return true
	return super.known_news(message)

func _draw_job_reminder(x: float, y: float) -> void:
	super._draw_job_reminder(x,y)
	if campaign.active.is_empty(): return
	_contract_ui.surface = "reminder"
	_contract_ui.active = {"title":_painted_labels[Vector2i(x,y)].trim_prefix("CONTRACT: "),"target_name":campaign.node(campaign.active.target).name,"deadline":campaign.active.deadline}

func label_at(s: String, p: Vector2, size: int = 16, color: Color = PAPER, display: bool = false) -> void:
	super.label_at(s,p,size,color,display)
	_painted_labels[Vector2i(p)] = s

func _public_control(id: String) -> Dictionary:
	if not buttons.has(id): return {}
	var row: Dictionary = buttons[id]
	var r: Rect2 = row.rect
	return {"title":row.title,"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"center":[r.get_center().x,r.get_center().y],"enabled":row.enabled,"visible":true}

func _record_board_row(id: String, rect: Rect2) -> void:
	# Called only after this exact accept control and preceding card labels were painted.
	# offers() is a draw-time identity lookup, never an observation-time/all-offers export.
	for job in campaign.offers():
		if id != "accept_"+job.id: continue
		_contract_ui.surface = "board"
		_contract_ui.rows.append({"id":job.id,"kind":job.kind,"target":job.target,"title":_painted_labels.get(Vector2i(1030,int(rect.position.y)-62),""),"target_name":campaign.node(job.target).name,"pay":job.pay,"deadline":job.deadline,"danger":_painted_labels.get(Vector2i(1030,int(rect.position.y)-13),""),"accept_id":id,"control":_public_control(id)})
		break

func action(id: String) -> void:
	if blocked(): return
	if id == "attack_camp":
		if host != null: host._deploy_camp()
		else: tell("Camp assault requires the Town Contracts host."); refresh()
		return
	if id.begins_with("accept_"):
		if host != null: host._accept_contract(id.trim_prefix("accept_"))
		else: tell("Contract signing requires the Town Contracts host."); refresh()
		return
	if id == "continue_campaign" or (id.begins_with("dungeon_") and id not in ["dungeon_rumour","dungeon_close"]):
		tell("Only roaming scout contacts and physically reached camps can take the field. Only funded clear contracts are supported; other jobs and dungeons are unavailable.")
		refresh()
		return
	super.action(id)

func write_save(show_notice: bool = true) -> bool:
	var ok: bool = super.write_save(show_notice)
	if show_notice and ok: tell("Company saved to Town Contracts checkpoint.")
	return ok

func _selected_is_camp() -> bool:
	return campaign != null and known_site(world_selected) and campaign.node(world_selected).get("kind") == "camp" and campaign.recon.enabled

func _camp_reason() -> String:
	# Physical arrival is public; do not ask current remote camp admission first.
	if campaign.location != world_selected or not campaign.overworld.at_site(world_selected): return "Approach the camp before assaulting it."
	return "Camp assault requires the Town Contracts host." if host == null else host.session.camp_attack_preview_reason(world_selected)

func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
	if id == "attack_camp": enabled = enabled and _camp_reason().is_empty()
	if id.begins_with("accept_"):
		enabled = enabled and host != null and host.session.contract_accept_preview_reason(id.trim_prefix("accept_")).is_empty()
	if id == "deploy" and campaign.encounter.get("kind") != "scout":
		enabled = enabled and host != null and host.session.contract_attack_preview_reason().is_empty()
	if id == "iron_detail_close" and _selected_is_camp() and campaign.encounter.is_empty(): title = "Leave camp"
	super.button(id,title,rect,enabled,primary)
	if id.begins_with("accept_"): _record_board_row(id,rect)
	if id in ["jobs_prev","jobs_next"]: _contract_ui.controls[id] = _public_control(id)

func _draw_world_detail() -> void:
	super._draw_world_detail()
	if _contract_ui.surface == "board":
		label_fit("Only funded camp-clearing contracts are available.",Vector2(1030,705),364,11,MUTED)
		contract_policy_painted = true
	if _selected_is_camp() and campaign.encounter.is_empty() and campaign.location == world_selected and campaign.overworld.at_site(world_selected):
		var matching: bool = not campaign.active.is_empty() and campaign.active.get("target") == world_selected
		var reason: String = host.session.contract_attack_preview_reason() if matching and host != null else _camp_reason()
		if not reason.is_empty(): label_fit(reason,Vector2(1030,704),364,11,MUTED)

func observation() -> Dictionary:
	var out: Dictionary = super.observation()
	out["contract_ui"] = _contract_ui.duplicate(true) if visible and world_controls_available() else {"version":1,"surface":"","rows":[],"active":{},"controls":{}}
	out["journal_ui"] = _journal_ui.duplicate(true) if visible and not blocked() and iron.sheet == "journal" else {"version":1,"surface":"","page":0,"entries":[],"controls":{}}
	if not _selected_is_camp(): return out
	var site: String = world_selected
	var recon = campaign.recon
	var display := {"site":site,"name":campaign.node(site).name,"at_site":campaign.location == site and campaign.overworld.at_site(site),"watching":recon.watch.get("site") == site,"summary":"Defenders unknown. Watch for 30 minutes to estimate numbers; one hour to identify types.","count_label":"","types_label":"","types_observed_label":"","movement_label":"","assault_reason":_camp_reason(),"controls":{}}
	# These are exactly the dated report strings used by the retained ReconView.
	# Never query roster/garrison/home-party/current remote activity here.
	if recon.reports.has(site):
		var r: Dictionary = recon.reports[site]
		display.summary = "Camp cleared" if not r.occupied else "Defenders not yet counted" if r.size == -1 else recon.SIZES[r.size].capitalize()
		display.count_label = "Count: "+ReconView.age(campaign,r.seen)+" · may have changed"
		var types: Array = r.types.map(func(grade):return recon.TYPES[grade])
		display.types_label = "Types: "+(", ".join(types) if not types.is_empty() else "not identified")
		if r.types_seen > 0: display.types_observed_label = "Types observed "+ReconView.age(campaign,r.types_seen)
		if r.movement != 0: display.movement_label = recon.MOVEMENTS[r.movement]+" ("+("1–3" if r.movement_size == 1 else "4–6")+") · "+ReconView.age(campaign,r.movement_seen)+"."
		display["observed_generation"] = r.generation
	for id in ["attack_camp","deploy","travel","iron_detail_close","recon_watch","recon_stop"]:
		if out.buttons.has(id):
			display.controls[id] = out.buttons[id].duplicate(true)
			display.controls[id]["visible"] = visible and not blocked()
	out["selected_camp"] = display
	return out
