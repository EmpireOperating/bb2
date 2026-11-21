extends "res://world_loop/world_view.gd"
## Only the successor camp entrance differs; every inherited phase/helper fence stays.
func action(id: String) -> void:
	if blocked(): return
	if id == "attack_camp":
		if host != null: host._deploy_camp()
		else: tell("Camp assault requires the Bandit Camps host."); refresh()
		return
	if id == "continue_campaign" or id.begins_with("accept_") or (id.begins_with("dungeon_") and id not in ["dungeon_rumour","dungeon_close"]):
		tell("Only roaming scout contacts and physically reached camps can take the field. Contracts and dungeons are unavailable.")
		refresh()
		return
	super.action(id)

func write_save(show_notice: bool = true) -> bool:
	var ok: bool = super.write_save(false)
	if show_notice and ok: tell("Company saved to Bandit Camps checkpoint.")
	return ok

func _selected_is_camp() -> bool:
	return campaign != null and known_site(world_selected) and campaign.node(world_selected).get("kind") == "camp" and campaign.recon.enabled

func _camp_reason() -> String:
	# Physical arrival is public; do not ask current remote camp admission first.
	if campaign.location != world_selected or not campaign.overworld.at_site(world_selected): return "Approach the camp before assaulting it."
	return "Camp assault requires the Bandit Camps host." if host == null else host.session.camp_attack_reason(world_selected)

func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
	if id == "attack_camp": enabled = enabled and _camp_reason().is_empty()
	if id == "deploy" and campaign.encounter.get("kind") != "scout": enabled = false
	if id == "iron_detail_close" and _selected_is_camp() and campaign.encounter.is_empty(): title = "Leave camp"
	super.button(id,title,rect,enabled,primary)

func _draw_world_detail() -> void:
	super._draw_world_detail()
	if _selected_is_camp() and campaign.encounter.is_empty() and campaign.location == world_selected and campaign.overworld.at_site(world_selected):
		var reason := _camp_reason()
		if not reason.is_empty(): label_fit(reason,Vector2(1030,704),364,11,MUTED)

func observation() -> Dictionary:
	var out: Dictionary = super.observation()
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
