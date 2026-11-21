extends RefCounted
const Text = preload("res://src/traffic_view.gd")

static func selected(app):
	var c = app.campaign; var id: String = app.world_selected.trim_prefix("farm:")
	var f = c.farm.for_town(id)
	return f if f != null else c.farm

static func visible(c, f) -> bool:
	return f.position.distance_to(c.overworld.position) <= c.overworld.sight()

static func draw_map(app) -> void:
	var c = app.campaign; var ow = c.overworld
	if not c.farm.enabled: return
	for f in c.farm.all():
		var previous: Vector2 = f.position
		for p in ow.route(f.position,ow.places[f.town]):
			if ow.discovered(previous) and ow.discovered(p): app.draw_dashed_line(previous,p,app.MUTED,1.5,4,true)
			previous = p
		if ow.discovered(f.position) or f.report.day > 0:
			var p: Vector2 = f.position
			var damaged: bool = f.damage > 0 if not f.regional or visible(c,f) else f.report.damaged
			var tint = app.RED if damaged else app.GOLD
			app.draw_circle(p,15,app.INK)
			app.draw_rect(Rect2(p-Vector2(7,2),Vector2(14,11)),tint,false,2)
			app.draw_polyline(PackedVector2Array([p+Vector2(-11,-2),p+Vector2(0,-12),p+Vector2(11,-2)]),tint,2,true)
			app.centered("RAIDED FARM" if damaged else "FARM",p+Vector2(0,-23),10,tint)
			app.buttons["farm_open_"+f.town if f.regional else "farm_open"] = {"rect":Rect2(p-Vector2(18,18),Vector2(36,36)),"enabled":true}
		for cart in f.carts.values():
			if cart.status != "transit" or cart.position.distance_to(ow.position) > ow.sight(): continue
			app.draw_rect(Rect2(cart.position-Vector2(5,4),Vector2(10,8)),app.GOLD,false,2)
			app.draw_circle(cart.position+Vector2(-4,5),2,app.GOLD); app.draw_circle(cart.position+Vector2(4,5),2,app.GOLD)
			app.centered("HARVEST",cart.position+Vector2(0,-12),9,app.GOLD)
	app.button("farm_report","FARM SUPPLY",Rect2(52,185,130,25),true)

static func detail(app) -> void:
	var c = app.campaign; var f = selected(app)
	app.label_at("RURAL SUPPLY · "+c.node(f.town).name,Vector2(1030,212),12,app.GOLD)
	if c.farm.regional:
		for i in c.world.TOWNS.size():
			var town: String = c.world.TOWNS[i]
			app.button("farm_choose_"+town,c.node(town).name.to_upper().left(13) if app.known_site(town) else "UNKNOWN",Rect2(1030+(i%3)*123,223+(i/3)*23,118,20),app.known_site(town),town == f.town)
	app.label_at(f.title(c),Vector2(1030,292),24,app.PAPER,true)
	var current: bool = not f.regional or visible(c,f) or f.at_client(c)
	var status = "Working fields. Harvest reaches the market only when its cart arrives."
	if c.raiders.enabled and c.raiders.rules_version >= 3: status = "Harvest waits here overnight. Carts leave after 08:00 and deliver food to the town."
	if not current:
		status = "No local report. Visit the town or find its farm." if f.report.day == 0 else "Last town report: day %d, farm %s. Visit again for current conditions." % [f.report.day,"raided" if f.report.damaged else "working"]
	elif f.raid.get("phase") == "raiding": status = "UNDER ATTACK · %.1fh before the farm falls. Reach the raiders to intervene." % (f.raid.remaining*0.05)
	elif f.damage > 0 and c.economy.enabled and not c.economy.industry.farm_ready(f.town,f.incident): status = "Repairs await 4 lumber, 1 iron, 2 tools and council funds. Sell materials at the town market; safe work begins once supplied."
	elif f.damage > 0: status = "Production stopped. %.1fh of safe repairs remain. Defeat the raiders, clear their camp, or guard the farm." % (f.damage*0.05)
	Text.paragraph(app,status,329)
	if current:
		app.label_at("Output %d/day · farm stores %d · delivered %d" % [f.output(c.world),f.stock,f.delivered],Vector2(1030,410),13,app.GOLD)
		app.label_at("Town: %d food · market %dc / 24" % [c.world.towns[f.town].stock,c.world.price(f.town)],Vector2(1030,432),13,app.MUTED)
	app.button("farm_travel","TRAVEL TO FARM",Rect2(1030,451,364,34),not c.over(),true)
	app.button("farm_guard","GUARD & REST · 24 HOURS",Rect2(1030,493,364,34),not c.over() and c.overworld.position.distance_to(f.position) <= 18)
	if c.overworld.tracks.enabled:
		app.label_at("Fresh footprints fade within four hours.",Vector2(1030,550),12,app.MUTED)
		app.button("tracks_scout","SCOUT THE NEARBY GROUND",Rect2(1030,566,364,34),not c.over(),c.overworld.tracks.scouting)
	elif not f.regional or f.evidence.inspected:
		app.label_at("Tracks from day %d; the camp may have changed." % f.evidence.day if f.regional else "Raiders threaten this supply route.",Vector2(1030,550),12,app.MUTED)
		app.button("farm_camp","FOLLOW TRACKS TO CAMP" if f.regional else "TRAVEL TO THREATENING CAMP",Rect2(1030,566,364,34),not c.over())
	elif current and f.evidence.day > 0:
		app.label_at("Raid tracks remain. Inspect them at the farm.",Vector2(1030,550),12,app.GOLD)
		app.button("farm_inspect","INSPECT RAID TRACKS",Rect2(1030,566,364,34),not c.over() and c.overworld.position.distance_to(f.position) <= 20)
	else: app.label_at("Explore the farm for evidence of recent attacks.",Vector2(1030,559),12,app.MUTED)
	if f.commission.is_empty():
		var offered: bool = current and f.damage > 0 and f.incident > f.claimed
		Text.paragraph(app,"Recovery work: restore production and deliver 24 fresh food. Collect 60 crowns from this town." if offered else "Check in town for recovery work. Safe farms keep food reaching the market.",635)
		if offered: app.button("farm_accept","ACCEPT · 60 CROWNS",Rect2(1030,701,364,38),f.can_accept(c),true)
	else:
		Text.paragraph(app,"COMMISSION · %d / 24 fresh food delivered after repairs. Return to %s for payment." % [f.commission.received,c.node(f.town).name],635)
		app.button("farm_claim","COLLECT 60 CROWNS",Rect2(1030,701,364,38),f.ready() and f.at_client(c),true)
		app.button("farm_cancel","CANCEL COMMISSION",Rect2(1030,748,364,30))
	app.button("farm_town","RETURN TO "+c.node(f.town).name.to_upper(),Rect2(1030,802,364,38),not c.over())

static func action(app, id: String) -> bool:
	var c = app.campaign
	if not c.farm.enabled or not id.begins_with("farm_"): return false
	var f = selected(app)
	if id in ["farm_open","farm_report"]:
		f = c.farm.for_town(c.location) if c.in_town() else f
		if f == null: f = c.farm
		app.world_selected = "farm:"+f.town
		if id == "farm_report": f.hear_report(c)
	elif id.begins_with("farm_open_") or id.begins_with("farm_choose_"):
		var town = id.trim_prefix("farm_open_").trim_prefix("farm_choose_")
		var chosen = c.farm.for_town(town)
		if chosen != null and (app.known_site(town) or c.overworld.discovered(chosen.position)):
			app.world_selected = "farm:"+town; chosen.hear_report(c)
	elif id == "farm_travel": c.begin_travel(f.position)
	elif id == "farm_camp" and not c.overworld.tracks.enabled and (not f.regional or f.evidence.inspected): c.begin_travel(c.overworld.places[f.camp],f.camp)
	elif id == "farm_inspect": f.inspect(c)
	elif id == "farm_guard" and c.overworld.position.distance_to(f.position) <= 18: c.begin_rest()
	elif id == "farm_accept": f.accept(c)
	elif id == "farm_claim": f.claim(c)
	elif id == "farm_cancel": f.cancel(c)
	elif id == "farm_town": c.begin_travel(c.overworld.places[f.town],f.town)
	app.write_save(false)
	return true
