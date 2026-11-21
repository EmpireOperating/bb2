extends RefCounted
const Journal = preload("res://src/expedition_journal.gd")
const DView = preload("res://src/dungeon_view.gd")

static func entries(c) -> Array:
	var out = []; var targets = c.dungeons.Keys.targets(c.dungeons.sites)
	for id in c.dungeons.vault_keys.records:
		var row: Dictionary = c.dungeons.vault_keys.records[id]
		if not row.held and not row.noticed: continue
		var at: Dictionary = targets[id]
		out.append({"id":id,"site":at.site,"floor":at.floor,"held":row.held,"opened":row.opened,"noticed":row.noticed,"source":row.source})
	return out

static func draw(app) -> void:
	var c = app.campaign; var ui: Dictionary = app.expedition_view; var rows = Journal.entries(c)
	app.buttons.clear(); app.draw_rect(Rect2(0,0,1440,900),Color("0b1110")); app.panel(Rect2(60,40,1320,820),Color("17201b"),app.GOLD)
	app.label_at("EXPEDITION JOURNAL",Vector2(88,85),28,app.PAPER,true)
	app.button("vault_close","CLOSE / ESC",Rect2(1150,61,200,38))
	app.label_at("Your discoveries, cleared routes and unfinished business.",Vector2(90,126),16,app.GOLD)
	app.label_at("Keys and rumours name dungeons. Explore to find their entrances.",Vector2(90,153),13,app.MUTED)
	app.vault_page = clampi(app.vault_page,0,maxi(0,(rows.size()-1)/5))
	if rows.is_empty():
		DView.lines(app,"No expeditions recorded. Ask for burial rumours, find maps, explore or recover a vault key.",Vector2(90,230),1120,20,3,app.PAPER); return
	if not rows.any(func(row):return row.id == ui.site): ui.site = rows[app.vault_page*5].id
	for n in mini(5,rows.size()-app.vault_page*5):
		var row: Dictionary = rows[app.vault_page*5+n]; var y = 180+n*113
		app.panel(Rect2(86,y,378,102),Color("26362c") if row.id == ui.site else Color("1b2720"),app.GOLD if row.id == ui.site else Color("465040"))
		app.button("vault_select_"+row.id,row.name,Rect2(96,y+8,358,38),true,row.id == ui.site)
		app.label_at(row.status,Vector2(102,y+70),13,app.BLUE if row.known else app.MUTED)
		if row.known and app.known_site(row.id) and c.dungeons.active == "": app.button("vault_locate_"+row.id,"VIEW",Rect2(380,y+73,74,24))
	app.button("vault_prev","PREVIOUS",Rect2(86,785,130,40),app.vault_page > 0)
	app.centered("%d / %d" % [app.vault_page+1,maxi(1,ceili(rows.size()/5.0))],Vector2(275,812),14,app.GOLD)
	app.button("vault_next","NEXT",Rect2(334,785,130,40),(app.vault_page+1)*5 < rows.size())
	var row: Dictionary = rows.filter(func(r):return r.id == ui.site)[0]
	app.label_fit(row.name,Vector2(496,205),825,25,app.PAPER)
	if not row.known:
		app.label_at("ENTRANCE UNKNOWN",Vector2(496,257),16,app.GOLD)
		DView.lines(app,"You carry a key bearing this name. Find a map or discover the entrance while exploring.",Vector2(496,302),780,18,4,app.PAPER)
		return
	var tabs = ["notes","rooms","supplies","keys"]
	for i in tabs.size(): app.button("vault_tab_"+tabs[i],tabs[i].capitalize(),Rect2(496+i*211,230,201,38),true,ui.tab == tabs[i])
	match ui.tab:
		"notes": notes(app,row)
		"rooms": rooms(app,row)
		"supplies": supplies(app,row)
		"keys": draw_keys(app,row)

static func notes(app, row: Dictionary) -> void:
	app.label_at(row.status.to_upper(),Vector2(496,311),17,app.GOLD)
	if row.deepest == 0:
		DView.lines(app,"The entrance is known. No rooms have been explored yet.",Vector2(496,360),770,19,3,app.PAPER)
	else:
		app.label_at("Deepest explored: floor %d" % row.deepest,Vector2(496,357),21,app.PAPER)
		app.label_at("%d rooms visited · %d cleared" % [row.visited,row.cleared],Vector2(496,401),18,app.PAPER)
		app.label_at("Observed guards remaining: %d · Unsearched rooms: %d" % [row.guards,row.unsearched],Vector2(496,442),18,app.PAPER)
	var locked = row.keys.filter(func(k):return k.noticed and not k.opened).size()
	app.label_at("%d locked vaults found · %d keys carried" % [locked,row.keys.filter(func(k):return k.held).size()],Vector2(496,503),17,app.GOLD)
	DView.lines(app,"Room notes contain only what you have seen. Clearing the final chamber does not empty side vaults.",Vector2(496,565),780,16,3)
	DView.lines(app,"Cleared rooms, unlocked doors and enemy losses persist when you retreat and return.",Vector2(496,661),780,16,3)
	if row.has("theme"):
		app.label_at(row.theme.to_upper(),Vector2(496,735),15,app.GOLD)
		DView.lines(app,row.theme_notes,Vector2(496,767),780,14,3)

static func rooms(app, row: Dictionary) -> void:
	var ui: Dictionary = app.expedition_view
	if row.floors.is_empty(): DView.lines(app,"Enter the dungeon to begin your room notes.",Vector2(496,320),780,19,3,app.PAPER); return
	ui.floor = clampi(ui.floor,0,row.floors.size()-1)
	var floor: Dictionary = row.floors[ui.floor]
	app.button("vault_floor_prev","◀",Rect2(496,287,50,32),ui.floor > 0)
	app.label_at("FLOOR %d" % [floor.index+1],Vector2(568,310),17,app.GOLD)
	app.button("vault_floor_next","▶",Rect2(728,287,50,32),ui.floor+1 < row.floors.size())
	if not floor.rooms.any(func(r):return r.id == ui.room): ui.room = floor.rooms[0].id
	for r in floor.rooms:
		var pos = Vector2(531+r.x*90,368+r.y*90)
		for next in r.links:
			if next <= r.id: continue
			var other = floor.rooms.filter(func(v):return v.id == next)[0]
			app.draw_line(pos,Vector2(531+other.x*90,368+other.y*90),Color("566552"),3)
	for r in floor.rooms:
		var pos = Vector2(531+r.x*90,368+r.y*90)
		app.button("vault_room_%d" % r.id,str(r.id+1),Rect2(pos-Vector2(26,22),Vector2(52,44)),true,r.id == ui.room)
		app.centered("?" if not r.visited else "CLEAR" if r.enemies.is_empty() else "GUARDS",pos+Vector2(0,40),10,app.MUTED if not r.visited else app.BLUE if r.enemies.is_empty() else app.RED)
	var room: Dictionary = floor.rooms.filter(func(r):return r.id == ui.room)[0]
	app.label_at("CHAMBER %d" % [room.id+1],Vector2(905,311),16,app.GOLD)
	DView.lines(app,room.title,Vector2(905,353),420,22,2,app.PAPER)
	DView.lines(app,room.state,Vector2(905,427),420,16,3,app.GOLD)
	var y = 514
	for enemy in room.enemies:
		app.label_at(enemy,Vector2(905,y),15,app.PAPER); y += 27
	if room.enemies.is_empty(): DView.lines(app,"No guards remain here." if room.visited else "Contents unknown.",Vector2(905,y),420,15,2)
	DView.lines(app,"Numbers identify chambers in these notes. Lines show observed connections; unopened rooms conceal their contents.",Vector2(496,701),800,15,3)

static func draw_keys(app, row: Dictionary) -> void:
	var ui: Dictionary = app.expedition_view; var rows: Array = row.keys
	ui.keys_page = clampi(ui.keys_page,0,maxi(0,(rows.size()-1)/4))
	if rows.is_empty(): DView.lines(app,"No keys or locked vaults recorded for this dungeon.",Vector2(496,320),780,19,3,app.PAPER); return
	for i in mini(4,rows.size()-ui.keys_page*4):
		var key: Dictionary = rows[ui.keys_page*4+i]; var y = 293+i*104
		app.panel(Rect2(496,y,838,92),Color("1d2923"),Color("465040"))
		app.label_at("KEY CARRIED" if key.held else "KEY MISSING" if not key.opened else "PREVIOUSLY OPEN",Vector2(512,y+30),17,app.PAPER)
		app.label_at("DOOR UNLOCKED" if key.opened else "LOCKED VAULT FOUND" if key.noticed else "VAULT NOT YET VISITED",Vector2(512,y+64),14,app.GOLD)
	app.button("vault_keys_prev","PREVIOUS KEYS",Rect2(496,746,180,36),ui.keys_page > 0)
	app.button("vault_keys_next","NEXT KEYS",Rect2(1154,746,180,36),(ui.keys_page+1)*4 < rows.size())

static func supplies(app, row: Dictionary) -> void:
	var c = app.campaign; var ui: Dictionary = app.expedition_view; var towns = Journal.towns(c)
	if towns.is_empty(): DView.lines(app,"Discover a town before planning a return journey.",Vector2(496,320),780,19,3); return
	if not towns.any(func(t):return t.id == ui.town): ui.town = towns[0].id
	var town: Dictionary = towns.filter(func(t):return t.id == ui.town)[0]
	app.label_at("FROM COMPANY → DUNGEON → RETURN TOWN",Vector2(496,304),13,app.GOLD)
	app.button("vault_town_prev","◀",Rect2(496,320,45,34))
	app.label_fit(town.name,Vector2(555,345),708,18,app.PAPER)
	app.button("vault_town_next","▶",Rect2(1289,320,45,34))
	app.label_at("Exploration / recovery: %d extra days" % ui.days,Vector2(496,393),16,app.PAPER)
	app.button("vault_days_less","−",Rect2(1177,369,70,34),ui.days > 0); app.button("vault_days_more","+",Rect2(1264,369,70,34),ui.days < 7)
	app.label_at("Scouting allowance: %d new rooms" % ui.scouting,Vector2(496,439),16,app.PAPER)
	app.button("vault_scout_less","−",Rect2(1177,415,70,34),ui.scouting > 0); app.button("vault_scout_more","+",Rect2(1264,415,70,34),ui.scouting < 20)
	var quote = Journal.budget(c,row.id,ui.town,ui.days,ui.scouting)
	if quote.is_empty():
		DView.lines(app,"Travel estimate unavailable: the route crosses unexplored terrain. A marked entrance does not reveal the journey.",Vector2(496,500),800,18,4,app.GOLD)
	else:
		app.label_at("Travel: %.1fh out + %.1fh back · total plan %.1fh" % [quote.outbound,quote.returning,quote.hours],Vector2(496,493),18,app.PAPER)
		app.label_at("%d midnights · %d rations · %d crowns incl. arrears" % [quote.midnights,quote.food,quote.crowns],Vector2(496,534),18,app.GOLD)
		app.label_at("Carrying: %d rations · %d crowns" % [c.food,c.crowns],Vector2(496,575),16,app.PAPER)
		app.label_at("Shortfall: %d rations · %d crowns" % [quote.food_short,quote.crowns_short],Vector2(496,613),16,app.RED if quote.food_short+quote.crowns_short > 0 else app.BLUE)
	DView.lines(app,"Scouting adds one hour and %d rations per new room. A basic exit is included. Extra days cover deeper exploration and recovery. Battles pause world time." % c.dungeon_scout_cost(),Vector2(496,666),810,14,3)
	DView.lines(app,"Tools, medicine, ammunition, purchases and unexpected delays are additional. This estimate neither reserves supplies nor guarantees a safe return.",Vector2(496,747),810,14,3)

static func action(app, id: String) -> void:
	var ui: Dictionary = app.expedition_view
	if id.begins_with("vault_select_"):
		ui.site = id.trim_prefix("vault_select_"); ui.floor = 0; ui.room = 0; ui.keys_page = 0
	elif id.begins_with("vault_tab_"):
		var tab = id.trim_prefix("vault_tab_"); if tab in ["notes","rooms","supplies","keys"]: ui.tab = tab
	elif id == "vault_floor_prev": ui.floor -= 1; ui.room = 0
	elif id == "vault_floor_next": ui.floor += 1; ui.room = 0
	elif id.begins_with("vault_room_"): ui.room = int(id.trim_prefix("vault_room_"))
	elif id == "vault_keys_prev": ui.keys_page -= 1
	elif id == "vault_keys_next": ui.keys_page += 1
	elif id == "vault_days_less": ui.days = maxi(0,ui.days-1)
	elif id == "vault_days_more": ui.days = mini(7,ui.days+1)
	elif id == "vault_scout_less": ui.scouting = maxi(0,ui.scouting-1)
	elif id == "vault_scout_more": ui.scouting = mini(20,ui.scouting+1)
	elif id in ["vault_town_prev","vault_town_next"]:
		var towns = Journal.towns(app.campaign).map(func(t):return t.id)
		if not towns.is_empty(): ui.town = towns[posmod(towns.find(ui.town)+(1 if id == "vault_town_next" else -1),towns.size())]
