extends RefCounted
## Presentation only. Navigation and discovery permissions live in the models.
static func draw_map(app) -> void:
	var c = app.campaign; var ow = c.overworld; var r: Dictionary = c.region
	var visible = Rect2i(0,0,ow.SIZE.x,ow.SIZE.y)
	if app.has_method("visible_cells"): visible = app.visible_cells()
	var colours = [Color("3c4930"),Color("293e2c"),Color("4c4938"),Color("294d54"),Color("3c4930"),Color("294d54"),Color("454a43")]
	app.draw_rect(Rect2(40,216,928,480),Color("080e0b"))
	for y in range(visible.position.y,visible.end.y):
		for x in range(visible.position.x,visible.end.x):
			var p = ow.cell_point(Vector2i(x,y))
			if not ow.discovered(p): continue
			var t: int = r.terrain[y*ow.SIZE.x+x]
			var hash_value = posmod(x*761+y*283+int(r.seed)*17,127)
			app.draw_rect(Rect2(p-Vector2.ONE*8,Vector2.ONE*16),colours[t].lightened((hash_value%7)*0.008))
			if t == 1:
				for j in 2:
					var tree = p+Vector2(-4+j*8,(hash_value%5)-2)
					app.draw_line(tree+Vector2(0,2),tree+Vector2(0,7),Color("766447"),1)
					app.draw_colored_polygon(PackedVector2Array([tree+Vector2(0,-8-j*2),tree+Vector2(-5,3),tree+Vector2(5,3)]),Color("162d23").lightened(j*0.035))
			elif t == 2 and hash_value%2 == 0:
				app.draw_polyline(PackedVector2Array([p+Vector2(-7,4),p+Vector2(-1,-3),p+Vector2(7,4)]),Color("747255"),1.3,true)
			elif t == 6:
				app.draw_colored_polygon(PackedVector2Array([p+Vector2(-8,6),p+Vector2(0,-9),p+Vector2(8,6)]),Color("7a7e6d"))
				app.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-9),p+Vector2(8,6),p+Vector2(1,6)]),Color("555e55"))
			elif t == 3 and hash_value%4 == 0:
				app.draw_line(p-Vector2(5,0),p+Vector2(4,1),Color("528087"),1,true)
	for path in r.road_paths:
		for i in range(1,path.points.size()):
			var a = Vector2(path.points[i-1][0],path.points[i-1][1]); var b = Vector2(path.points[i][0],path.points[i][1])
			if ow.discovered(a) and ow.discovered(b):
				app.draw_line(a,b,Color("252d22"),7,true); app.draw_line(a,b,Color("9d8b61"),3,true)
	for bridge in r.bridges:
		var p = Vector2(bridge.position[0],bridge.position[1])
		if not ow.discovered(p): continue
		var d = Vector2(0,1) if bridge.vertical else Vector2(1,0)
		app.draw_line(p-d*25,p+d*25,Color("b1a179"),9,true)
		for i in range(-3,4): app.draw_line(p+d*i*7-d.orthogonal()*5,p+d*i*7+d.orthogonal()*5,Color("685a41"),1,true)
	for y in range(visible.position.y,visible.end.y):
		for x in range(visible.position.x,visible.end.x):
			var p = ow.cell_point(Vector2i(x,y))
			if not ow.discovered(p): app.draw_rect(Rect2(p-Vector2.ONE*8,Vector2.ONE*16),Color("080e0b"))
	for id in c.exploration.sites:
		var state: Dictionary = c.exploration.sites[id]; var p: Dictionary = c.node(id)
		if not state.rumour or state.searched or ow.discovered(Vector2(p.x,p.y)): continue
		var centre = Vector2(p.rumour[0],p.rumour[1])
		app.draw_arc(centre,62,0,TAU,40,Color(0.84,0.71,0.43,0.65),1.5,true)
		app.centered("RUMOURED SITE",centre+Vector2(0,5),10,app.GOLD)
	# Draw only explored sections; a planned route must not reveal unseen roads.
	var from = ow.position
	for to in ow.path:
		if ow.discovered(from) and ow.discovered(to): app.draw_line(from,to,app.GOLD,2,true)
		from = to
	if not ow.path.is_empty() and ow.discovered(ow.path.back()): app.draw_arc(ow.path.back(),8,0,TAU,20,app.GOLD,2,true)
	for place in r.locations:
		var p = Vector2(place.x,place.y)
		var known = ow.discovered(p) or c.traffic.camp_known(place.id)
		if not known: continue
		var selected = app.world_selected == place.id
		if selected: app.draw_arc(p,23,0,TAU,32,app.GOLD,1.5,true)
		var tint = app.PAPER if place.kind == "town" else app.RED if place.kind == "camp" and c.world.camps[place.id].active else app.MUTED
		app.draw_circle(p,18,Color("12211b")); app.draw_arc(p,18,0,TAU,32,tint,1.5,true)
		if place.kind == "town":
			app.draw_rect(Rect2(p-Vector2(10,4),Vector2(20,14)),Color("c0b28b"))
			for dx in [-10,-2,6]: app.draw_rect(Rect2(p+Vector2(dx,-12),Vector2(4,10)),Color("c0b28b"))
		elif place.kind == "camp":
			app.draw_colored_polygon(PackedVector2Array([p+Vector2(-11,9),p+Vector2(0,-10),p+Vector2(11,9)]),tint)
			app.draw_colored_polygon(PackedVector2Array([p+Vector2(-3,9),p,p+Vector2(3,9)]),Color("12211b"))
		elif place.feature == "watchtower":
			app.draw_rect(Rect2(p-Vector2(5,10),Vector2(10,20)),Color("a2a18a")); app.draw_line(p+Vector2(-8,-10),p+Vector2(8,-10),app.GOLD,3)
		elif place.feature == "cave":
			app.draw_colored_polygon(PackedVector2Array([p+Vector2(-12,9),p+Vector2(-3,-10),p+Vector2(4,-7),p+Vector2(12,9)]),Color("8b8e7b")); app.draw_circle(p+Vector2(0,5),5,Color("080e0b"))
		else:
			for dx in [-9,-2,7]: app.draw_rect(Rect2(p+Vector2(dx,-8+absi(dx)/2),Vector2(4,15-absi(dx)/2)),Color("99997d"))
		var width: float = app.font.get_string_size(place.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		if not app.has_method("draw_labels"): app.draw_rect(Rect2(p+Vector2(-width/2-5,22),Vector2(width+10,20)),Color(0.045,0.085,0.065,0.94))
		app.centered(place.name,p+Vector2(0,37),13,app.PAPER)
		var status: String = place.role if place.kind == "town" else c.camp_label(place.id) if place.kind == "camp" else "SEARCHED" if c.exploration.sites[place.id].searched else "SCOUTED" if c.exploration.sites[place.id].scouted else "UNEXPLORED"
		app.centered(status,p+Vector2(0,50),9,tint)
		app.buttons["place_"+place.id] = {"rect":Rect2(p-Vector2(23,20),Vector2(46,40)),"enabled":true}
		if c.active.get("target") == place.id:
			app.draw_line(p+Vector2(20,-9),p+Vector2(20,-34),app.GOLD,2)
			app.draw_colored_polygon(PackedVector2Array([p+Vector2(20,-34),p+Vector2(36,-29),p+Vector2(20,-24)]),app.GOLD)

static func draw_discovery(app, id: String) -> void:
	var c = app.campaign; var p: Dictionary = c.node(id); var state: Dictionary = c.exploration.sites[id]
	app.label_at("DISCOVERY · "+p.feature.to_upper(),Vector2(1030,213),11,app.GOLD)
	app.label_at(p.name,Vector2(1030,253),26,app.PAPER,true)
	var lines = app.wrapped_lines(p.description,354,14,4)
	for i in lines.size(): app.label_at(lines[i],Vector2(1030,290+i*22),14,app.MUTED)
	if not c.overworld.at_site(id) or c.location != id:
		app.label_at("Reach the site to investigate.",Vector2(1030,412),15,app.BLUE)
		app.button("travel","SET COURSE",Rect2(1030,455,364,45),not c.over(),true)
		app._draw_job_reminder(1030,710)
		return
	if state.searched:
		app.label_at("SEARCHED",Vector2(1030,412),17,app.BLUE)
		app.label_at("The stores are gone. This history is saved.",Vector2(1030,449),13,app.MUTED)
	elif not c.exploration.task.is_empty():
		var task: Dictionary = c.exploration.task
		app.label_at(task.kind.to_upper()+" IN PROGRESS",Vector2(1030,412),16,app.BLUE)
		app.label_at("%.1f hours remaining" % (task.remaining*0.05),Vector2(1030,450),20,app.PAPER,true)
		app.label_at("Time and nearby parties keep moving.",Vector2(1030,484),12,app.MUTED)
		app.button("explore_cancel","BREAK OFF",Rect2(1030,528,364,40))
	else:
		var scout_reason: String = c.exploration.reason(c,id,"scout")
		var search_reason: String = c.exploration.reason(c,id,"search")
		app.button("explore_scout","SCOUT · 1 HOUR" if not state.scouted else "SCOUTED",Rect2(1030,400,364,42),scout_reason.is_empty(),true)
		app.button("explore_search","SEARCH · %d HOURS" % p.search_hours,Rect2(1030,456,364,42),search_reason.is_empty(),true)
		lines = app.wrapped_lines(search_reason if not search_reason.is_empty() else "Searching costs time. Scouts can interrupt you. Supplies are collected only on completion.",354,13,4)
		for i in lines.size(): app.label_at(lines[i],Vector2(1030,535+i*22),13,app.MUTED)
		if state.scouted and not p.guarded_by.is_empty() and c.world.camps[p.guarded_by].active:
			app.button("place_"+p.guarded_by,"INSPECT CONTROLLING CAMP",Rect2(1030,640,364,36))
	app.button("world_stop","STOP / CHOOSE ANOTHER ROUTE",Rect2(1030,777,364,42))
