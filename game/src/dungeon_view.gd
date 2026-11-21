extends RefCounted
## Presentation only; every command is checked by Campaign.
const LEAF = preload("res://engraved_world/plates/survey_leaf.png")
const ELEVATION = preload("res://engraved_world/plates/section_01.png")
static func lines(app, text: String, at: Vector2, width: float, size: int = 15, maximum: int = 5, color: Color = Color("a4ad9c")) -> void:
	var rows = app.wrapped_lines(text,width,size,maximum)
	for i in rows.size(): app.label_at(rows[i],at+Vector2(0,i*(size+7)),size,color)

static func draw_sites(app) -> void:
	var c = app.campaign
	for id in c.dungeons.sites:
		var site: Dictionary = c.dungeons.sites[id]; var p = Vector2(site.place.x,site.place.y)
		var visible = c.overworld.discovered(p)
		# Rumours and recovered maps carry narrative knowledge, not fog penetration.
		if not visible: continue
		var color: Color = app.BLUE if site.completed else app.GOLD if site.rumour and not visible else app.PAPER
		app.draw_circle(p,17,Color("111817")); app.draw_arc(p,19,0,TAU,30,color,1.5,true)
		if visible:
			app.draw_rect(Rect2(p+Vector2(-10,-4),Vector2(20,14)),Color("73796b"))
			app.draw_arc(p+Vector2(0,-4),10,PI,TAU,20,Color("73796b"),5,true)
			app.draw_rect(Rect2(p+Vector2(-4,-4),Vector2(8,15)),Color("0a0d0b"))
		else: app.centered("?",p+Vector2(0,6),22,color,true)
		var width: float = app.font.get_string_size(site.place.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		if not app.has_method("draw_labels"): app.draw_rect(Rect2(p+Vector2(-width/2-5,22),Vector2(width+10,33)),Color("101915"))
		app.centered(site.place.name,p+Vector2(0,35),12,color)
		app.centered("CLEARED" if site.completed else ("RECOVERED MAP" if site.get("discovery","") == "map" else "RUMOURED TOMB") if not visible else "UNDEAD · TIER %d" % site.tier,p+Vector2(0,49),9,color)
		app.buttons["place_"+id] = {"rect":Rect2(p-Vector2(23,20),Vector2(46,40)),"enabled":true}

static func entrance(app, id: String) -> void:
	var c = app.campaign; var site: Dictionary = c.dungeons.sites[id]
	var theme = c.dungeons.Variety.Themes.site_theme(site)
	app.label_at((c.dungeons.Variety.Themes.LABELS[theme].to_upper() if theme != "" else ("SMALL BARROW" if c.dungeons.Variety.small(id) else "BURIAL COMPLEX"))+" · UNDEAD",Vector2(1030,213),12,app.GOLD)
	lines(app,site.place.name,Vector2(1030,254),350,26,2,app.PAPER)
	app.label_at("%d FLOORS · THREAT %d" % [site.floors.size(),site.tier],Vector2(1030,323),16,app.RED)
	lines(app,site.place.description,Vector2(1030,365),350,15,4)
	lines(app,"Carry supplies for several fights. Scouting costs %d food; wages and daily rations still apply." % c.dungeon_scout_cost(),Vector2(1030,470),350,15,5)
	var explored = 0; var total = 0
	for floor in site.floors:
		for room in floor.rooms:
			total += 1
			if room.visited: explored += 1
	app.label_at("%d / %d rooms explored%s" % [explored,total," · TREASURE TAKEN" if site.completed else ""],Vector2(1030,615),14,app.BLUE)
	lines(app,("Progress persists. Named equipment is uncommon in small barrows." if c.dungeons.Variety.small(id) else "Progress persists. A named item awaits in the final chest; guarded side treasuries offer additional loot.") if not site.completed else "The final chest is empty. Any unsearched side vaults remain.",Vector2(1030,652),350,14,3)
	if c.location == id and c.overworld.at_site(id):
		var reason = c.dungeon_enter_reason(id)
		app.button("dungeon_enter","ENTER THE DUNGEON",Rect2(1030,766,364,49),reason == "",true)
		if reason != "": lines(app,reason,Vector2(1030,737),350,12,2,app.RED)
	else:
		app.button("travel","TRAVEL TO THE ENTRANCE",Rect2(1030,766,364,49),not c.over(),true)

static func draw(app) -> void:
	var c = app.campaign; var d = c.dungeons; var site: Dictionary = d.sites[d.active]
	var floor: Dictionary = site.floors[d.floor_index]; var room: Dictionary = d.room()
	app.draw_rect(Rect2(0,0,1440,900),Color("0b1110"))
	app.panel(Rect2(25,27,1390,128),Color("17201b"),Color("696041"))
	app.label_at("THE ASHEN COMPANY · UNDERGROUND",Vector2(48,53),12,app.GOLD)
	app.label_at(site.place.name,Vector2(48,92),30,app.PAPER,true)
	app.label_at("FLOOR %d / %d  ·  DAY %d, %02d:%02d" % [d.floor_index+1,site.floors.size(),c.day,int(c.overworld.hour),roundi(c.overworld.hour*60)%60],Vector2(500,90),18,app.GOLD)
	app.label_at("%dc   ·   %d FOOD   ·   %d TOOLS   ·   %d MEDICINE   ·   %d AMMO" % [c.crowns,c.food,c.tools,c.medicine,c.ammunition],Vector2(48,132),15,app.BLUE)
	app.button("save","F5 SAVE",Rect2(1110,42,120,40))
	app.button("load","F9 LOAD",Rect2(1240,42,145,40),FileAccess.file_exists(app.SAVE_PATH))
	app.button("company","COMPANY & EQUIPMENT",Rect2(1085,99,300,38))
	app.button("vault_journal","EXPEDITIONS",Rect2(855,102,200,32))
	app.panel(Rect2(25,177,940,561),Color("141c19"),Color("464e3e"))
	app.draw_texture_rect(LEAF,Rect2(25,177,940,561),false)
	var theme = d.Variety.Themes.site_theme(site)
	app.label_at((d.Variety.Themes.LABELS[theme].to_upper()+" · " if theme != "" else "")+"CHAMBERS · CLICK A CONNECTING DOORWAY",Vector2(45,205),12,Color("4f5345"))
	for a in floor.rooms:
		if not a.seen: continue
		for next in d.links(a.id):
			var b: Dictionary = floor.rooms[next]
			if next <= a.id or not b.seen: continue
			app.draw_line(centre(a),centre(b),Color("69533b") if next not in a.links else Color("4c5143"),6,true)
			app.draw_line(centre(a),centre(b),Color("c19a56") if next not in a.links else Color("e9dbb9"),3,true)
	for r in floor.rooms:
		if not r.seen: continue
		var p = centre(r); var selected = r.id == d.room_index
		var hostile: bool = r.visited and not r.cleared
		var color: Color = app.GOLD if selected else app.RED if hostile else app.BLUE if r.visited else app.MUTED
		var rect = Rect2(p-Vector2(77,40),Vector2(154,80))
		app.panel(rect,Color("353628") if selected else Color("1d2923") if r.visited else Color("111916"),color)
		var key = d.reward_key(d.active,d.floor_index,r.id)
		var locked: bool = d.vault_keys.locked(key)
		var title: String = "Locked treasury" if locked else room_title(r) if r.visited else "Unexplored"
		# Surveyed chamber jambs: leave unseen rooms, target bounds and label anchors alone.
		for side in [-1,1]:
			var corner=p+Vector2(side*71,-34)
			app.draw_polyline(PackedVector2Array([corner+Vector2(-side*11,0),corner,corner+Vector2(0,11)]),color,1,true)
		app.centered(title,p+Vector2(0,-3),15,color,true)
		var status = "LOOTED" if r.looted else "UNDEAD" if hostile else "CLEARED" if r.visited else "?"
		if r.visited and r.kind == "stairs" and r.cleared and not r.loot.is_empty() and not r.looted: status = "SUPPLIES"
		if r.visited and r.get("resolution","") == "": status = {"trap":"TRAPPED","rubble":"BLOCKED","secret":"SEARCHABLE"}.get(r.get("hazard",""),status)
		if locked: status = "KEY CARRIED" if d.vault_keys.records[key].held else "KEY REQUIRED"
		app.centered(status,p+Vector2(0,23),11,color)
		if r.id in d.links(d.room_index): app.buttons["dungeon_room_%d" % r.id] = {"rect":rect,"enabled":(locked and c.phase == "camp" and c.encounter.is_empty()) or c.dungeon_move_reason(r.id) == ""}
		if selected:
			app.draw_line(p+Vector2(-53,-62),p+Vector2(-53,-24),app.GOLD,3)
			app.draw_colored_polygon(PackedVector2Array([p+Vector2(-53,-62),p+Vector2(-20,-55),p+Vector2(-53,-43)]),Color("a14835"))
			app.draw_line(p+Vector2(-46,-57),p+Vector2(-31,-51),app.GOLD,2)
	app.panel(Rect2(985,177,430,561),Color("18221c"),Color("626348"))
	app.label_at(room_title(room),Vector2(1008,216),26,app.PAPER,true)
	if not c.encounter.is_empty():
		var count = room.roster.size() if room.wear.is_empty() else room.wear.filter(func(w):return w.hp > 0).size()
		app.label_at("%d UNDEAD REMAIN · FEARLESS" % count,Vector2(1008,260),15,app.RED)
		var types = {}
		for i in room.roster.size():
			if not room.wear.is_empty() and room.wear[i].hp == 0: continue
			var name: String = d.U.TYPES[room.roster[i]].name
			types[name] = types.get(name,0)+1
		var y = 304
		for name in types: app.label_at("%d × %s" % [types[name],name],Vector2(1008,y),17,app.PAPER); y += 29
		var tactics = preload("res://src/dungeon_tactics.gd").DESCRIPTIONS.get(room.roster[0],"Fight on the tactical map, or withdraw to the entrance.")
		lines(app,tactics+" Enemy losses persist after retreat.",Vector2(1008,493),380,15,5)
		app.button("deploy","ENGAGE THE UNDEAD",Rect2(1008,650,383,49),c.can_deploy(),true)
	else:
		var text = "The way is clear. Follow a connected doorway to explore. Unknown rooms conceal their contents."
		if room.kind == "stairs":
			text = "The guard is defeated. The stairs lead deeper. Cleared floors will remain cleared."
			if not room.loot.is_empty(): text = "Supplies collected by your company. The stairs lead deeper." if room.looted else "The guard is defeated. A supply cache waits beside the stairs. Take it now or return later."
		elif room.kind == "entry": text = "A stairwell connects this floor to the entrance." if d.floor_index == 0 else "A stairwell connects to the previous floor."
		elif room.kind in ["cache","finale","vault"]: text = "Supplies collected by your company." if room.looted else "A sealed chest remains here. Open it to take the supplies and valuables."
		var obstacle: bool = room.get("hazard","") != "" and room.get("resolution","") == ""
		if obstacle:
			text = {"trap":"A mechanical trap guards the vault. Spend tools to disarm it, or force it: a one-in-three risk of injury to the first fighter in your formation. You can leave it alone.","rubble":"A collapsed passage leads straight to this floor's final chamber. Spend tools or extra time and food to open a permanent shortcut. The ordinary route remains open.","secret":"Scratches behind loose masonry suggest a hidden cache. Spend time and food to search, or continue exploring."}[room.hazard]
		elif room.get("hazard","") == "rubble": text = "The passage is open. Gold connections mark the permanent shortcut."
		elif room.get("hazard","") == "secret": text = "Hidden supplies collected by your company." if room.looted else "A hidden supply cache is ready to collect."
		lines(app,text,Vector2(1008,263),380,16,6)
		if room.looted and not room.loot.is_empty():
			app.label_at("%d crowns · %d food" % [room.loot.crowns,room.loot.food],Vector2(1008,350),16,app.BLUE)
			app.label_at("%d tools · %d ammunition" % [room.loot.tools,room.loot.ammunition],Vector2(1008,375),16,app.BLUE)
		if obstacle: choices(app,room)
		if room.looted and room.reward != "":
			var reward: Dictionary = c.named_rewards[d.reward_key(d.active,d.floor_index,d.room_index)].item
			lines(app,"RECOVERED: "+reward.named.name,Vector2(1008,405),380,18,3,app.GOLD)
			lines(app,c.Named.summary(reward),Vector2(1008,490),380,14,3,app.BLUE)
		if not room.loot.is_empty() and not room.looted and d.can_search(room):
			var supplies: bool = room.kind == "stairs"
			if supplies: lines(app,"%dc · %d food · %d tools · %d ammunition" % [room.loot.crowns,room.loot.food,room.loot.tools,room.loot.ammunition],Vector2(1008,440),380,16,3,app.BLUE)
			app.button("dungeon_search","TAKE SUPPLIES" if supplies else "OPEN THE CHEST",Rect2(1008,525 if supplies else 585,383,46),not c.over(),true)
		if room.kind == "stairs": app.button("dungeon_down","DESCEND TO FLOOR %d" % (d.floor_index+2),Rect2(1008,585,383,46),not c.over(),true)
		if room.kind == "entry" and not obstacle and room.loot.is_empty():
			# Exterior architectural study, not a depiction of concealed adjoining rooms.
			app.draw_rect(Rect2(1013,370,371,163),Color("d4c7a5"))
			app.draw_texture_rect(ELEVATION,Rect2(1023,376,351,136),false)
			app.draw_string(app.font,Vector2(1030,526),"FIELD STUDY   /   BURIAL ARCHITECTURE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("585a4b"))
		if room.kind == "entry" and d.floor_index > 0: app.button("dungeon_up","RETURN TO UPPER FLOOR",Rect2(1008,585,383,46),not c.over())
		app.button("dungeon_rest","REST 4 HOURS",Rect2(1008,650,383,46),not c.over())
	app.panel(Rect2(25,756,940,112),Color("141c19"))
	app.label_at("SCOUTING: %d FOOD + 1 HOUR   ·   CLEARED ROOM: 15 MINUTES" % c.dungeon_scout_cost(),Vector2(45,784),12,app.GOLD)
	app.label_at("Rest advances time. Wages and rations are paid at midnight; repairs and healing use normal supplies.",Vector2(45,811),12,app.MUTED)
	var recent: String = c.journal[-1] if not c.journal.is_empty() else ""
	lines(app,recent,Vector2(45,841),895,12,1,app.PAPER)
	app.button("dungeon_leave","WITHDRAW TO ENTRANCE",Rect2(985,764,430,49),true)
	lines(app,"Your cleared rooms, opened chests and enemy losses remain saved.",Vector2(1000,842),400,13,2,app.BLUE)
	if c.over(): lines(app,c.ending,Vector2(50,716),880,14,1,app.RED)
	if app.dungeon_door >= 0: locked_door(app,app.dungeon_door)

static func centre(room: Dictionary) -> Vector2:
	return Vector2(145+room.x*223,295+room.y*160)

static func room_title(room: Dictionary) -> String:
	if room.kind == "cache": return "Trapped cache" if room.get("hazard","") == "trap" else "Supply cache"
	return {"trap":"Trapped vault","rubble":"Collapsed passage","secret":"Sealed alcove"}.get(room.get("hazard",""),preload("res://src/dungeons.gd").TITLES[room.kind])

static func choices(app, room: Dictionary) -> void:
	var c = app.campaign
	var actions = {"trap":["disarm","force"],"rubble":["clear","dig"],"secret":["search"]}[room.hazard]
	var y = 425
	for action in actions:
		var cost: Dictionary = c.dungeon_choice_cost(action)
		var label: String = {"disarm":"DISARM","force":"FORCE OPEN","clear":"CLEAR PASSAGE","dig":"DIG THROUGH","search":"SEARCH ALCOVE"}[action]
		label += " · %d TOOLS" % cost.tools if cost.tools else " · %d FOOD" % cost.food if cost.food else " · INJURY RISK"
		label += " · 15 MIN" if cost.hours < 1 else " · %d H" % cost.hours
		var reason: String = c.dungeon_choice_reason(action)
		app.button("dungeon_choice_"+action,label,Rect2(1008,y,383,42),reason == "")
		if reason != "": app.label_at(reason,Vector2(1010,y+57),11,app.RED)
		y += 72
	if room.hazard == "trap": lines(app,"Trap hit: %d HP, never fatal. A two-day wound also lowers maximum HP and skill." % (8+4*c.dungeons.sites[c.dungeons.active].tier),Vector2(1008,590),380,13,2,app.MUTED)

static func locked_door(app, target: int) -> void:
	var c = app.campaign; var d = c.dungeons; var id = c.vault_id(target)
	if not d.vault_keys.locked(id) or not target in d.links(d.room_index): return
	var rect = Rect2(985,177,430,561)
	for button_id in app.buttons.keys():
		if rect.intersects(app.buttons[button_id].rect): app.buttons.erase(button_id)
	app.panel(rect,Color("18221c"),app.GOLD)
	app.label_at("LOCKED TREASURY",Vector2(1008,217),23,app.PAPER,true)
	lines(app,"Each treasury takes a specific key found outside the dungeon. Dungeon tier doesn't determine which key fits.",Vector2(1008,265),380,17,4)
	lines(app,d.Keys.label(d.sites,id),Vector2(1008,390),380,19,3,app.GOLD)
	var held: bool = d.vault_keys.records[id].held
	var status: String = d.vault_keys.missing_key_reason(id)+" See Expeditions or return later." if not held else "Matching key carried. Unlocking is permanent; guards and traps may wait inside."
	if held and c.food < c.dungeon_scout_cost(): status = "Matching key carried. Bring more scouting food to enter."
	elif held and c.active_ids().is_empty(): status = "Matching key carried. Assign companions to the formation to enter."
	lines(app,status,Vector2(1008,488),380,16,4,app.BLUE if held else app.MUTED)
	app.button("dungeon_close","BACK TO CURRENT ROOM",Rect2(1008,585,383,40))
	if held:
		app.button("dungeon_unlock_%d" % target,"UNLOCK & ENTER",Rect2(1008,650,383,46),not c.over() and c.food >= c.dungeon_scout_cost() and not c.active_ids().is_empty(),true)
	else: app.button("vault_journal","EXPEDITIONS",Rect2(1008,650,383,46))
