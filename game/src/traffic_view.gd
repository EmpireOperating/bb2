extends RefCounted
## Map presentation and commands. All loot, capture and rescue authority is in Traffic.
static func draw_map(app) -> void:
	var c = app.campaign; var ow = c.overworld
	if not c.traffic.enabled: return
	for id in c.traffic.traces:
		var t: Dictionary = c.traffic.traces[id]; var p: Vector2 = t.position
		if t.discovered:
			if app.has_method("painted_observation"):
				preload("res://engraved_world/atlas_ink.gd").wreck_mark(app,p,p.distance_to(ow.position)>ow.sight(),app.marker_highlighted("trace_"+id) or app.world_selected=="trace:"+id)
			else:
				app.draw_line(p+Vector2(-10,-6),p+Vector2(10,6),app.MUTED,4,true)
				app.draw_line(p+Vector2(-10,6),p+Vector2(10,-6),app.GOLD,2,true)
			app.centered("WAGON WRECK",p+Vector2(0,27),10,app.GOLD)
			app.buttons["trace_"+id] = {"rect":Rect2(p-Vector2(18,14),Vector2(36,30)),"enabled":true}
			if t.inspected and not ow.tracks.enabled:
				for i in range(1,t.points.size()):
					if ow.discovered(t.points[i-1]) and ow.discovered(t.points[i]): app.draw_dashed_line(t.points[i-1],t.points[i],app.MUTED,1,4,true)
		elif t.rumour:
			app.draw_arc(p,45,0,TAU,32,app.GOLD,1,true)
			app.centered("MISSING CARAVAN",p+Vector2(0,5),10,app.GOLD)
	for id in c.traffic.wagons:
		var v: Dictionary = c.traffic.wagons[id]
		if v.remaining > 0 and v.position.distance_to(ow.position) <= ow.sight():
			app.draw_arc(v.position,23,0,TAU,32,app.RED,2,true)
			app.centered("UNDER ATTACK · %.1fh" % (v.remaining*0.05),v.position+Vector2(0,37),10,app.RED)

static func detail(app, selected: String) -> void:
	var c = app.campaign; var ow = c.overworld; var id = selected.get_slice(":",1)
	if selected.begins_with("trace:"):
		if not c.traffic.traces.has(id): return
		var t: Dictionary = c.traffic.traces[id]
		app.label_at("EVIDENCE · DAY %d" % t.day,Vector2(1030,214),12,app.GOLD)
		app.label_at("Wreck of "+c.world.short_id(id),Vector2(1030,254),28,app.PAPER,true)
		var clue := "Broken wheel rims and drag marks remain where the caravan was overrun. The cargo was hauled away."
		if t.inspected and ow.position.distance_to(t.position)<=20 and c.economy.freight.has_method("visible_wrecks"):
			for row:Dictionary in c.economy.freight.visible_wrecks(c):
				if row.id==id:clue=row.clue;break
		paragraph(app,clue,305)
		if not t.inspected:
			app.button("traffic_trace_travel","REACH THE WRECK",Rect2(1030,440,364,43),not c.over(),true)
			app.button("traffic_inspect","READ THE TRACKS",Rect2(1030,499,364,43),ow.position.distance_to(t.position) <= 20 and not c.over(),true)
		elif ow.tracks.enabled:
			paragraph(app,"The wreck records where the attack happened. Only fresh footprints nearby can tell you which way the group moved; they fade within four hours.",420)
			app.button("tracks_scout","SCOUT THE NEARBY GROUND",Rect2(1030,550,364,45),not c.over(),ow.tracks.scouting)
		else:
			paragraph(app,"The tracks point toward "+c.node(t.site).name+". Older tracks remain after a road is cleared; this record does not guarantee a living band.",420)
			app.button("traffic_follow","FOLLOW TRACKS TO CAMP",Rect2(1030,550,364,45),not c.over(),true)
			if not c.world.camps[t.site].active: app.label_at("The band has been destroyed.",Vector2(1030,630),14,app.BLUE)
		app.button("world_stop","STOP & PAUSE",Rect2(1030,640,364,40))
		app._draw_job_reminder(1030,720)
		return
	if not c.traffic.wagons.has(id): return
	var v: Dictionary = c.traffic.wagons[id]; var cargo: Dictionary = c.world.caravans[id]; var r: Dictionary = c.world.route_data(cargo.route)
	var visible: bool = v.position.distance_to(ow.position) <= ow.sight() and cargo.status in ["waiting","transit","escort"]
	app.label_at(("RELIEF · " if c.rebuilding.enabled and c.rebuilding.shipments.has(id) else "CARAVAN · ")+c.world.short_id(id),Vector2(1030,214),12,app.GOLD)
	app.label_at(c.world.cargo_text(id)+" aboard",Vector2(1030,254),28,app.PAPER,true)
	paragraph(app,c.node(r.path[0]).name+" → "+c.node(r.path[2]).name,300)
	if not visible:
		paragraph(app,"The caravan is out of sight. Its last selection does not reveal its current position. Check the trade report for recorded outcomes.",370)
	elif v.remaining > 0:
		paragraph(app,"RAID IN PROGRESS · %.1f hours before the guards give way. Reach the raiding party to take the field; victory releases the caravan." % (v.remaining*0.05),370)
		app.button("traffic_intercept","INTERVENE",Rect2(1030,505,364,45),not c.over(),true)
	elif v.carried:
		paragraph(app,"The raiders have the cargo and are returning to camp. Intercept them before the goods reach their stores.",370)
		app.button("traffic_intercept","PURSUE RAIDERS",Rect2(1030,505,364,45),not c.over(),true)
	elif c.has_method("can_follow_freight") and c.active.get("kind")=="freight_escort" and c.active.get("shipment")==id:
		paragraph(app,"Your signed caravan. Wait for departure or follow it to the receiving town. The road is not secured.",370)
		app.button("traffic_escort","FOLLOW ESCORT",Rect2(1030,505,364,45),c.can_follow_freight(id),true)
	else:
		paragraph(app,"Waiting to depart." if cargo.status == "waiting" else "Moving along the trade road. Travel alongside it to watch for raiders. A company escort contract is still taken at its origin town.",370)
		app.button("traffic_approach","APPROACH CARAVAN",Rect2(1030,505,364,45),not c.over(),true)
	app.button("world_stop","STOP & PAUSE",Rect2(1030,565,364,40))
	app.button("trade","TRADE & ROAD REPORT",Rect2(1030,620,364,40))
	app._draw_job_reminder(1030,720)

static func paragraph(app, text: String, y: int) -> void:
	var lines = app.wrapped_lines(text,354,14,5)
	for i in lines.size(): app.label_at(lines[i],Vector2(1030,y+i*23),14,app.MUTED)

static func action(app, id: String) -> bool:
	var c = app.campaign; var ow = c.overworld
	if not c.traffic.enabled: return false
	if id.begins_with("trace_"):
		var key = id.trim_prefix("trace_")
		if c.traffic.traces.has(key) and c.traffic.traces[key].discovered: app.world_selected = "trace:"+key
		return true
	if id.begins_with("convoy_") and not app.trade_view:
		app.world_selected = "wagon:"+id.trim_prefix("convoy_"); return true
	if not id.begins_with("traffic_"): return false
	var key: String = app.world_selected.get_slice(":",1)
	if id == "traffic_escort":
		if selected_wagon(app,key) and c.has_method("begin_freight_follow"):c.begin_freight_follow(key)
	elif id == "traffic_inspect": c.traffic.inspect_trace(c,key)
	elif id == "traffic_trace_travel" and c.traffic.traces.has(key): c.begin_travel(c.traffic.traces[key].position)
	elif id == "traffic_follow" and not ow.tracks.enabled and c.traffic.traces.has(key) and c.traffic.traces[key].inspected:
		var target: String = c.traffic.traces[key].site
		c.begin_travel(ow.places[target],target)
	elif id in ["traffic_intercept","traffic_approach"] and c.traffic.wagons.has(key):
		var v: Dictionary = c.traffic.wagons[key]
		if v.position.distance_to(ow.position) <= ow.sight():
			if c.begin_travel(ow.scouts[v.raider].position if id == "traffic_intercept" and not v.raider.is_empty() else v.position):
				if id == "traffic_intercept": c.traffic.pursuit = v.raider
	app.write_save(false)
	return true

static func selected_wagon(app,id: String) -> bool:
	return app.world_selected == "wagon:"+id and app.world_controls_available()
