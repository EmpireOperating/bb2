extends RefCounted
const Text = preload("res://src/traffic_view.gd")

static func current(c, town: String = "ashwick") -> String:
	var ids = c.guards.parties.keys().filter(func(id):return c.guards.home_town(c,id) == town); ids.reverse()
	return "" if ids.is_empty() else ids[0]

static func visible(c, g: Dictionary) -> bool:
	return g.mode != "defeated" and g.position.distance_to(c.overworld.position) < c.overworld.sight()

static func council_caption(c, town: String = "ashwick") -> String:
	var id = current(c,town)
	if id.is_empty(): return "Town guard: %dc / 90 for formation." % c.world.factions[c.world.towns[town].owner].treasury
	var g: Dictionary = c.guards.parties[id]
	return "%s · %s · %d / 5 guards" % [id.replace("patrol_","P"),g.mode,g.health.filter(func(hp):return hp > 0).size()]

static func draw_map(app) -> void:
	var c = app.campaign
	if not c.guards.enabled: return
	app.button("guard_report","TOWN GUARD",Rect2(679,185,130,25))
	for id in c.guards.parties:
		var g: Dictionary = c.guards.parties[id]
		if not visible(c,g): continue
		var p: Vector2 = g.position; var tint = app.RED if g.mode == "fighting" else Color(c.world.config.factions[c.world.patrols[id].faction].color)
		var survivors: int = g.health.filter(func(hp):return hp > 0).size()
		if app.has_method("painted_observation"):
			preload("res://engraved_world/atlas_ink.gd").guard_mark(app,p,tint,survivors,app.marker_highlighted("guard_open_"+id) or app.world_selected=="guard:"+id)
		else:
			app.draw_circle(p,12,app.INK)
			app.draw_colored_polygon(PackedVector2Array([p+Vector2(-8,-9),p+Vector2(8,-9),p+Vector2(7,5),p+Vector2(0,12),p+Vector2(-7,5)]),tint)
			app.centered(str(survivors),p+Vector2(0,4),11,app.INK)
		app.centered(c.node(c.guards.home_town(c,id)).name.to_upper()+" GUARD",p+Vector2(0,-20),9,tint)
		app.buttons["guard_open_"+id] = {"rect":Rect2(p-Vector2(13,13),Vector2(26,26)),"enabled":true}

static func detail(app) -> void:
	var c = app.campaign; var town = selected_town(app); var id = app.world_selected.trim_prefix("guard:")
	if not c.guards.parties.has(id): id = current(c,town)
	app.label_at("TOWN GUARD · "+c.node(town).name,Vector2(1030,212),12,app.GOLD)
	if c.guards.regional:
		for i in c.world.TOWNS.size():
			var target: String = c.world.TOWNS[i]
			app.button("guard_choose_"+target,c.node(target).name.to_upper().left(13) if app.known_site(target) else "UNKNOWN",Rect2(1030+(i%3)*123,223+(i/3)*23,118,20),app.known_site(target),town == target)
	app.label_at("Road watch",Vector2(1030,287),28,app.PAPER,true)
	if id.is_empty():
		var funds: int = c.world.factions[c.world.towns[town].owner].treasury
		Text.paragraph(app,"Council: %dc. Five guards cost 90 crowns. %s" % [funds,"Funds are ready; the council dispatches at dawn." if funds >= 90 else "Another %d crowns are needed. Taxes, trade and sponsorship fund the watch." % (90-funds)],322)
	else:
		var g: Dictionary = c.guards.parties[id]; var known: bool = visible(c,g) or c.in_town() and c.location == town
		if known:
			app.label_at("%s · %s" % [id.replace("patrol_","P"),g.mode.capitalize()],Vector2(1030,322),17,app.BLUE)
			app.label_at("%d / 5 guards alive · strength %d%%" % [g.health.filter(func(hp):return hp > 0).size(),roundi(c.guards.power(g)/5.25)],Vector2(1030,348),15,app.PAPER)
			app.label_at("%d field victories · %d setbacks" % [g.wins,g.losses],Vector2(1030,374),13,app.MUTED)
			app.label_at("Council %dc · wages 6/day · replacement 18c" % c.world.factions[c.world.towns[town].owner].treasury,Vector2(1030,400),12,app.GOLD)
		else: Text.paragraph(app,"Patrol out of sight. Return to its town for a report or find it on the road.",295)
		Text.paragraph(app,"Protection stays near the guards. Wounded survivors return to town for a day of rest; dead guards need paid replacements. No wages means no patrol.",420)
		if known and c.rebuilding.enabled and g.mode == "patrolling":
			var duty: Dictionary = c.rebuilding.patrol_goal(c,id)
			if not duty.is_empty(): app.label_at(duty.reason,Vector2(1030,527),13,app.BLUE)
		if visible(c,g):
			app.button("guard_approach","APPROACH PATROL",Rect2(1030,550,364,40),not c.over())
			var fight: bool = g.mode == "fighting" and not g.target.is_empty() and c.overworld.scouts[g.target].position.distance_to(c.overworld.position) < c.overworld.sight()
			app.button("guard_help","ENGAGE THEIR ATTACKERS",Rect2(1030,600,364,40),fight and not c.over(),true)
			if fight: Text.paragraph(app,"Your company takes over the tactical fight while the guards fall back. Raider wounds and losses carry into battle.",670)
	app.button("guard_fund","SUPPORT THE GUARD · 90 CROWNS",Rect2(1030,750,364,36),c.farm.for_town(town).at_client(c) and c.crowns >= 90)
	app.button("guard_town","RETURN TO GUARD TOWN",Rect2(1030,802,364,38),not c.over())

static func action(app, id: String) -> bool:
	var c = app.campaign
	if not c.guards.enabled or not id.begins_with("guard_"): return false
	var town = selected_town(app)
	if id == "guard_report":
		town = c.location if c.in_town() and c.farm.for_town(c.location) != null else town
		app.world_selected = "guard:town:"+town
	elif id.begins_with("guard_choose_"):
		var target = id.trim_prefix("guard_choose_")
		if app.known_site(target) and c.farm.for_town(target) != null: app.world_selected = "guard:town:"+target
	elif id.begins_with("guard_open_"): app.world_selected = "guard:"+id.trim_prefix("guard_open_")
	elif id == "guard_town": c.begin_travel(c.overworld.places[town],town)
	elif id == "guard_fund": c.guards.fund(c,town)
	else:
		var key = app.world_selected.trim_prefix("guard:")
		if not c.guards.parties.has(key): key = current(c,town)
		if c.guards.parties.has(key):
			var g: Dictionary = c.guards.parties[key]
			if visible(c,g):
				if id == "guard_approach": c.begin_travel(g.position)
				elif id == "guard_help" and g.mode == "fighting" and c.overworld.scouts[g.target].position.distance_to(c.overworld.position) < c.overworld.sight():
					if c.begin_travel(c.overworld.scouts[g.target].position): c.traffic.pursuit = g.target
	app.write_save(false); return true

static func selected_town(app) -> String:
	var c = app.campaign; var key: String = app.world_selected.trim_prefix("guard:")
	if c.guards.parties.has(key): return c.guards.home_town(c,key)
	var town = key.trim_prefix("town:")
	return town if c.farm.for_town(town) != null else "ashwick"
