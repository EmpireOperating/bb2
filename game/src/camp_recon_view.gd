extends RefCounted
const Text = preload("res://src/traffic_view.gd")

static func age(c, tick: int) -> String:
	var minutes: int = (c.overworld.tracks.clock-tick)*3
	return "just observed" if minutes == 0 else "%d min ago" % minutes if minutes < 60 else "%.1f hours ago" % (minutes/60.0)

static func detail(app, site: String) -> void:
	var c = app.campaign; var recon = c.recon; var ow = c.overworld
	app.label_at("CAMP RECONNAISSANCE",Vector2(1030,212),12,app.GOLD)
	app.label_fit(c.node(site).name,Vector2(1030,250),364,27,app.PAPER,true)
	Text.paragraph(app,"Watch from nearby. Roaming bands can still spot or approach your company.",280)
	app.label_at("LAST OBSERVATION",Vector2(1030,350),12,app.GOLD)
	if not recon.reports.has(site):
		Text.paragraph(app,"Defenders unknown. Watch for 30 minutes to estimate numbers; one hour to identify types.",380)
	else:
		var r: Dictionary = recon.reports[site]
		var summary: String = "Camp cleared" if not r.occupied else "Defenders not yet counted" if r.size == -1 else recon.SIZES[r.size].capitalize()
		app.label_fit(summary,Vector2(1030,382),364,21,app.PAPER,true)
		app.label_at("Count: "+age(c,r.seen)+" · may have changed",Vector2(1030,410),12,app.MUTED)
		var types: Array = r.types.map(func(grade):return recon.TYPES[grade])
		app.label_fit("Types: "+(", ".join(types) if not types.is_empty() else "not identified"),Vector2(1030,440),364,14,app.PAPER)
		if r.types_seen > 0: app.label_at("Types observed "+age(c,r.types_seen),Vector2(1030,462),11,app.MUTED)
		if r.movement != 0:
			Text.paragraph(app,recon.MOVEMENTS[r.movement]+" ("+("1–3" if r.movement_size == 1 else "4–6")+") · "+age(c,r.movement_seen)+".",492)
	var watching: bool = recon.watch.get("site") == site
	if watching:
		app.label_at("WATCHING · "+("PAUSED" if ow.paused else "%d / 60 minutes" % mini(60,recon.watch.progress*3)),Vector2(1030,575),13,app.GOLD)
	else:
		app.label_fit(recon.reason(c,site) if recon.reason(c,site) != "" else "Close enough to keep watch.",Vector2(1030,575),364,12,app.MUTED)
	app.button("recon_stop" if watching else "recon_watch","STOP WATCHING & PAUSE" if watching else "WATCH CAMP · TIME PASSES",Rect2(1030,592,364,42),watching or recon.reason(c,site) == "",true)
	if c.location == site and ow.at_site(site):
		if c.can_deploy(): app.button("deploy","FULFIL CONTRACT · TAKE THE FIELD",Rect2(1030,648,364,42),true,true)
		elif c.world.camps[site].active: app.button("attack_camp","ASSAULT CAMP",Rect2(1030,648,364,42),true,true)
	else:
		app.button("travel","APPROACH CAMP",Rect2(1030,648,364,42),not ow.route(ow.position,ow.places[site]).is_empty())
	Text.paragraph(app,"Reports stay as you last saw them. Waiting costs time; wages and rations apply at midnight.",713)
	app._draw_job_reminder(1030,805)
