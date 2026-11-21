extends RefCounted
## Reports are heard in town and remain dated when read from elsewhere.
const Text = preload("res://src/traffic_view.gd")
static func detail(app) -> void:
	var c = app.campaign; var town: String = app.world_selected.trim_prefix("recovery:")
	if not c.rebuilding.towns.has(town): return
	app.label_at("REGIONAL RECOVERY",Vector2(1030,212),12,app.GOLD)
	for i in c.world.TOWNS.size():
		var target: String = c.world.TOWNS[i]
		app.button("recovery_choose_"+target,c.node(target).name.to_upper().left(13) if app.known_site(target) else "UNKNOWN",Rect2(1030+(i%3)*123,223+(i/3)*23,118,20),app.known_site(target),town == target)
	app.label_at(c.node(town).name,Vector2(1030,293),28,app.PAPER,true)
	var r: Dictionary = c.rebuilding.towns[town].report
	if r.is_empty():
		Text.paragraph(app,"No report collected. Visit this town to hear about its farms, food stocks and relief shipments.",334)
	else:
		app.label_at("Heard day %d, %02d:%02d%s" % [r.day,int(r.hour),roundi(fmod(r.hour,1.0)*60)," · local" if c.in_town() and c.location == town else " · last visit"],Vector2(1030,322),12,app.MUTED)
		app.label_at(r.state,Vector2(1030,356),24,app.RED if r.state in ["Raided","Short of food"] else app.BLUE,true)
		app.label_at("%d food in market · %dc / 24 food" % [r.stock,r.price],Vector2(1030,389),15,app.PAPER)
		app.label_at("Farm: %d food/day · %d delivered total" % [r.output,r.delivered],Vector2(1030,416),13,app.MUTED)
		var work = "Farm working. Fresh harvest still travels by cart."
		if r.damage > 0:
			work = "%.1f safe work hours remain. " % (r.damage*0.05)
			work += "Crew paid: 12 crowns and 6 food." if r.paid else "Council needs 12 crowns and 6 town food."
			if not r.safe: work += " Nearby raiders are stopping repairs."
		Text.paragraph(app,work,450)
		app.label_at("RELIEF SHIPMENTS · REPORTED",Vector2(1030,552),12,app.GOLD)
		if r.aid.is_empty(): Text.paragraph(app,"None reported. A surplus town can send relief when food is low and no supplies are already on their way.",581)
		for i in r.aid.size():
			var a: Dictionary = r.aid[i]
			app.label_at("%s · %d food · %s" % [c.world.short_id(a.id),a.food,a.status.capitalize()],Vector2(1030,582+i*39),14,app.PAPER)
			app.label_at(c.node(a.from).name+" → "+c.node(a.to).name,Vector2(1030,599+i*39),11,app.MUTED)
	app.button("recovery_farm","FARM & RAID REPORT",Rect2(1030,719,364,35))
	app.button("recovery_guard","TOWN GUARD",Rect2(1030,762,364,35))
	app.button("recovery_travel","VISIT TOWN",Rect2(1030,805,364,35),not c.over())

static func action(app, id: String) -> bool:
	var c = app.campaign
	if not c.rebuilding.enabled or not id.begins_with("recovery_"): return false
	var town: String = app.world_selected.trim_prefix("recovery:")
	if not c.rebuilding.towns.has(town): town = c.location if c.in_town() else "ashwick"
	if id == "recovery_report":
		town = c.location if c.in_town() else town
		c.rebuilding.hear(c,town); app.world_selected = "recovery:"+town
	elif id.begins_with("recovery_choose_"):
		var target = id.trim_prefix("recovery_choose_")
		if c.rebuilding.towns.has(target) and app.known_site(target):
			c.rebuilding.hear(c,target); app.world_selected = "recovery:"+target
	elif id == "recovery_farm": app.world_selected = "farm:"+town
	elif id == "recovery_guard": app.world_selected = "guard:town:"+town
	elif id == "recovery_travel": c.begin_travel(c.overworld.places[town],town)
	app.write_save(false); return true
