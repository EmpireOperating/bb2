extends RefCounted
const Text = preload("res://src/traffic_view.gd")
static func draw_map(app) -> void:
	var c = app.campaign; var tracks = c.overworld.tracks
	if not tracks.enabled: return
	for id in tracks.marks:
		var m: Dictionary = tracks.marks[id]
		if not tracks.visible(c,m): continue
		var forward = Vector2.from_angle(m.heading*PI/4); var across = forward.orthogonal()
		var tint: Color = app.GOLD; tint.a = tracks.opacity(m)
		var shade = Color("15140f"); shade.a = tint.a
		# Boot soles and heels, with denser impressions for larger groups.
		for pair in 2+m.group:
			for side in [-1,1]:
				var p: Vector2 = m.position+forward*((pair-(1+m.group)*0.5)*5+side*1.5)+across*side*3.2
				var sole = PackedVector2Array()
				for i in 8: sole.append(p+forward*(1.7+cos(i*TAU/8)*2.1)+across*sin(i*TAU/8)*1.25)
				var edge = sole.duplicate(); edge.append(sole[0])
				app.draw_polyline(edge,shade,2.0,true); app.draw_colored_polygon(sole,tint)
				app.draw_circle(p-forward*1.6,1.6,shade); app.draw_circle(p-forward*1.6,0.9,tint)
		if app.world_selected == "footprints:"+id: app.draw_arc(m.position,14,0,TAU,24,tint,1,true)
		app.buttons["footprint_"+id] = {"rect":Rect2(m.position-Vector2(13,13),Vector2(26,26)),"enabled":true}

static func detail(app) -> void:
	var c = app.campaign; var tracks = c.overworld.tracks; var id: String = app.world_selected.trim_prefix("footprints:")
	app.label_at("SIGNS ON THE GROUND",Vector2(1030,212),12,app.GOLD)
	app.label_at("Footprints",Vector2(1030,254),28,app.PAPER,true)
	if not tracks.marks.has(id):
		Text.paragraph(app,"The prints have faded away. Search the nearby ground for a fresher trail.",310)
	elif not tracks.visible(c,tracks.marks[id]):
		Text.paragraph(app,"These prints are no longer readable from here. Move closer or scout the nearby ground.",310)
	else:
		var m: Dictionary = tracks.marks[id]
		app.label_at(tracks.freshness(m),Vector2(1030,303),18,app.BLUE)
		Text.paragraph(app,tracks.size_hint(m),342)
		Text.paragraph(app,"The prints head "+tracks.DIRECTIONS[m.heading]+". That records where the group stepped, not where they are now.",400)
		Text.paragraph(app,"Follow the impressions across the ground. A turn or an old gap may lose the trail. All prints vanish within four hours.",493)
	app.button("tracks_scout","SCOUTING ON · 70% PACE" if tracks.scouting else "SCOUT · 70% TRAVEL PACE",Rect2(1030,639,364,42),not c.over(),tracks.scouting)
	Text.paragraph(app,"Scouting takes 15 minutes to widen your search. It never preserves prints or marks a camp.",718)
	app.button("world_stop","STOP & PAUSE",Rect2(1030,804,364,36))

static func action(app, id: String) -> bool:
	var c = app.campaign; var tracks = c.overworld.tracks
	if not tracks.enabled: return false
	if id == "tracks_scout": tracks.toggle(c); app.write_save(false); return true
	if not id.begins_with("footprint_"): return false
	var key = id.trim_prefix("footprint_")
	if tracks.marks.has(key) and tracks.visible(c,tracks.marks[key]): app.world_selected = "footprints:"+key
	return true
