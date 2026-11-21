extends RefCounted
## Presentation state only. No campaign rules or saved geography live here.
var sheet = ""
var detail = false
var town_page = "home"
var journal_page = 0
const SURFACE = Color("191c1f")
const EDGE = Color("514b40")

func blocks_map(app, p: Vector2) -> bool:
	return p.y < 64 or p.y >= 852 or (detail and Rect2(1008,116,408,746).has_point(p)) or (not app.campaign.encounter.is_empty() and Rect2(1008,116,408,746).has_point(p))

func input(app, event: InputEvent) -> bool:
	if sheet == "": return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: sheet = ""
		elif event.keycode == KEY_F5: app.action("save")
		elif event.keycode == KEY_F9: sheet = ""; app.action("load")
		app.refresh()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for id in app.buttons:
			if app.buttons[id].rect.has_point(event.position):
				if app.buttons[id].enabled: app.action(id)
				break
	return true

func action(app, id: String) -> bool:
	if id in ["iron_menu","iron_journal","iron_inventory","iron_camp"]:
		sheet = id.trim_prefix("iron_"); journal_page = 0; return true
	if id == "iron_close": sheet = ""; return true
	if id == "iron_detail_close": detail = false; return true
	if id == "iron_town_home": town_page = "home"; return true
	if id == "iron_here":
		app.world_selected = app.campaign.location; detail = true; town_page = "home"; return true
	if id == "iron_log_prev": journal_page = maxi(0,journal_page-1); return true
	if id == "iron_log_next": journal_page += 1; return true
	if id == "iron_armour": sheet = ""; app.open_armor("body"); return true
	if id == "iron_supplies": sheet = ""; app.action("resources"); return true
	if id == "iron_cargo": sheet = ""; app.action("resources"); app.salvage_mode = "cargo"; return true
	# Hub links dispatch the existing actions and keep all rules in Campaign.
	if sheet != "" and id != "save": sheet = ""
	if id.begins_with("place_") or id.begins_with("scout_") or id.begins_with("trace_") or id.begins_with("footprint_") or id.begins_with("farm_") or id.begins_with("guard_") or id in ["recovery_report","dungeon_rumour"] or id.begins_with("vault_locate_"):
		detail = true; town_page = "home"
	if id in ["contracts","recruits"]: detail = true; town_page = id
	if id in ["travel","rest","plan_rest","escort_move","world_stop"]: detail = false
	return false

func draw_world(app) -> void:
	var c = app.campaign
	app.draw_rect(Rect2(0,0,1440,900),Color("101315"))
	app.region_camera.draw(app)
	# Permanent chrome: resources, navigation and time. No logs or tutorial cards.
	app.panel(Rect2(0,0,1440,64),SURFACE,EDGE)
	app.label_at("%s crowns" % c.crowns,Vector2(30,40),21,app.GOLD,true)
	var days = float(c.food)/maxi(1,c.alive_count())
	app.label_at("Food  %.1f days" % days,Vector2(254,40),19,app.RED if days < 2 else app.PAPER,true)
	app.label_at("%d / %d companions" % [c.alive_count(),c.company_limit()],Vector2(493,40),19,app.PAPER,true)
	app.button("iron_here",c.node(c.location).name if c.in_town() else "Current location",Rect2(786,14,250,36))
	app.button("iron_menu","Menu",Rect2(1314,14,100,36))
	app.panel(Rect2(0,852,1440,48),SURFACE,EDGE)
	var names = ["Company","Inventory","Journal","Camp"]
	var ids = ["company","iron_inventory","iron_journal","iron_camp"]
	for i in 4: app.button(ids[i],names[i],Rect2(18+i*140,860,132,32))
	app.label_at("Day %d · %02d:%02d" % [c.day,int(c.overworld.hour),posmod(roundi(c.overworld.hour*60),60)],Vector2(854,883),17,app.PAPER,true)
	app.button("world_pause","Resume" if c.overworld.paused else "Pause",Rect2(1028,860,100,32),c.encounter.is_empty() and not c.over(),not c.overworld.paused)
	for i in 3:
		var speed = [1,2,4][i]
		app.button("world_speed_%d" % speed,"%dx" % speed,Rect2(1137+i*55,860,48,32),true,c.overworld.speed == speed)
	app.button("camera_home","Follow",Rect2(1310,860,104,32),true,app.region_camera.follow)
	app.button("camera_out","−",Rect2(24,78,34,32))
	app.button("camera_in","+",Rect2(62,78,34,32))
	app.label_at("N ↑",Vector2(116,100),14,app.GOLD)
	if not c.overworld.path.is_empty():
		app.panel(Rect2(194,78,340,32),SURFACE,EDGE)
		var travel_status := "Pursuing band · quick march"
		if not c.traffic.enabled or c.traffic.pursuit.is_empty():
			travel_status = "Travelling · %.1f hours remaining" % c.overworld.hours_left() if c.overworld.path.all(func(p):return c.overworld.discovered(p)) else "Travelling into unexplored country"
		app.label_fit(travel_status,Vector2(208,100),315,13,app.PAPER)
	# Always expose consequential danger; everyday information stays inside menus.
	var alert = ""
	if c.over(): detail = true; app.world_selected = c.location
	elif c.roster_version == 1 and c.active_ids().is_empty(): alert = "No field party — assign companions in Company."
	elif c.arrears > 0: alert = "Unpaid wages: %dc · day %d of 3 before desertion" % [c.arrears,c.unpaid_days]
	elif c.food < c.alive_count(): alert = "Food will run out tonight. Visit a town for supplies."
	if alert != "":
		app.panel(Rect2(24,792,940,44),SURFACE,app.RED)
		app.label_at(alert,Vector2(42,820),16,app.RED)
	elif app.notice_time > 0:
		app.panel(Rect2(24,792,940,44),SURFACE,EDGE)
		app.label_fit(app.notice,Vector2(42,820),900,15,app.GOLD)
	elif c.news.pinned != "" and c.news.directions.has(c.news.pinned):
		app.button("news_journal","Directions · "+c.node(c.news.pinned).name,Rect2(24,802,420,34))
	if not c.encounter.is_empty(): detail = true
	if detail:
		# Discard marker hit areas beneath the context panel.
		for id in app.buttons.keys():
			if app.buttons[id].rect.intersects(Rect2(1008,116,408,736)): app.buttons.erase(id)
		var place = c.node(app.world_selected) if app.known_site(app.world_selected) else {}
		if c.encounter.is_empty() and not c.over() and place.get("kind") == "town" and town_page == "home":
			draw_town(app,place)
		else:
			app._draw_world_detail()
			app.button("iron_detail_close","Close",Rect2(1310,126,106,36))
			if place.get("kind") == "town" and c.encounter.is_empty(): app.button("iron_town_home","Town",Rect2(1008,126,106,36))

func draw_town(app, place: Dictionary) -> void:
	var c = app.campaign
	app.panel(Rect2(1008,116,408,620),SURFACE,EDGE)
	app.label_at("SETTLEMENT",Vector2(1032,150),11,app.GOLD)
	app.button("iron_detail_close","Close",Rect2(1310,126,82,32))
	app.label_fit(place.name,Vector2(1032,204),355,30,app.PAPER,true)
	var lines = app.wrapped_lines(place.description,355,15,3)
	for i in lines.size(): app.label_at(lines[i],Vector2(1032,241+i*23),15,app.MUTED)
	if not c.overworld.at_site(place.id) or c.location != place.id:
		app.button("travel","Travel to "+place.name,Rect2(1032,348,360,44),not c.overworld.route(c.overworld.position,c.overworld.places[place.id]).is_empty(),true)
		app.label_at("Services are available on arrival.",Vector2(1032,429),14,app.MUTED)
		return
	var actions = [["contracts","Contracts"],["recruits","Recruit companions"],["resources" if c.economy.enabled else "salvage_open","Market"],["explore_rumour","Ask for local news"],["dungeon_rumour","Ask about old ruins"]]
	for i in actions.size(): app.button(actions[i][0],actions[i][1],Rect2(1032,324+i*61,360,44),true,i==0)
	if not c.active.is_empty():
		app.label_fit("Contract · "+c.active.title,Vector2(1032,669),355,14,app.GOLD)
		app.label_at("Due day %d" % c.active.deadline,Vector2(1032,697),13,app.MUTED)

func draw_sheet(app) -> void:
	app.buttons.clear()
	app.draw_rect(Rect2(0,0,1440,900),Color(0.035,0.04,0.045,0.92))
	app.panel(Rect2(220,108,1000,684),SURFACE,EDGE)
	app.label_at(sheet.capitalize(),Vector2(260,173),36,app.PAPER,true)
	app.button("iron_close","Close · Esc",Rect2(1028,138,152,40))
	app.draw_line(Vector2(260,199),Vector2(1180,199),EDGE)
	var c = app.campaign
	if sheet == "menu":
		var rows = [["save","Save company · F5"],["load","Load company · F9"],["help","Controls & rules"],["guide","Field guide"],["new_top","Start a new company"]]
		for i in rows.size(): app.button(rows[i][0],rows[i][1],Rect2(260,235+i*82,430,52),rows[i][0] != "load" or FileAccess.file_exists(app.SAVE_PATH))
		app.label_at("THE ASHEN COMPANY",Vector2(770,275),16,app.GOLD)
		app.label_at("Iron UI · 0.46",Vector2(770,313),16,app.MUTED)
		app.label_at("World seed %d" % c.seed_value,Vector2(770,347),14,app.MUTED)
		app.label_at("Map: drag or WASD to pan",Vector2(770,429),15,app.PAPER)
		app.label_at("Scroll to zoom · Home to follow",Vector2(770,465),15,app.PAPER)
		app.label_at("Space pauses · right-click stops",Vector2(770,501),15,app.PAPER)
	elif sheet == "inventory":
		app.label_at("Company stores",Vector2(260,249),23,app.PAPER,true)
		var supplies = [["Food",c.food],["Tools",c.tools],["Medicine",c.medicine],["Ammunition",c.ammunition]]
		for i in supplies.size():
			app.label_at(supplies[i][0],Vector2(260,301+i*58),18,app.MUTED)
			app.label_at(str(supplies[i][1]),Vector2(550,301+i*58),20,app.PAPER)
		app.button("loadout","Weapons & equipment",Rect2(736,254,444,54))
		app.button("iron_armour","Layered armour",Rect2(736,332,444,54))
		app.button("iron_supplies","Supplies",Rect2(736,410,444,54),c.economy.enabled)
		app.button("iron_cargo","Trade goods",Rect2(736,488,444,54),c.economy.enabled)
		app.button("salvage_open","Stored equipment & salvage",Rect2(736,566,444,54))
		app.label_at("Trading requires a town. Equipping uses your company stores.",Vector2(260,728),15,app.MUTED)
	elif sheet == "camp":
		app.label_at("Daily upkeep",Vector2(260,249),23,app.PAPER,true)
		app.label_at("%d crowns · %d rations" % [c.wage_cost(),c.alive_count()],Vector2(260,296),21,app.GOLD)
		app.label_at("%d companions alive" % c.alive_count(),Vector2(260,342),17,app.MUTED)
		app.button("planner","Recovery plan",Rect2(736,254,444,54))
		app.button("rest","Rest one day · %dc + %d food" % [c.rest_cost(),c.alive_count()],Rect2(736,332,444,54),not c.over())
		app.button("bonds","Companions & bonds",Rect2(736,410,444,54))
		app.button("lineup_open","Formation & reserves",Rect2(736,488,444,54))
		app.button("tracks_scout","Stop scouting" if c.overworld.tracks.scouting else "Scout tracks · 70% travel pace",Rect2(736,566,444,54),c.overworld.tracks.enabled and not c.over(),c.overworld.tracks.scouting)
		app.button("world_stop","Stop travel / activity",Rect2(736,644,444,54))
	elif sheet == "journal":
		app.button("news_journal","Reports & directions",Rect2(260,230,280,44))
		app.button("vault_journal","Expeditions",Rect2(580,230,280,44))
		app.button("trade","Trade & roads",Rect2(900,230,280,44))
		app.label_at("Company chronicle",Vector2(260,325),23,app.PAPER,true)
		var known = c.journal.filter(app.known_news)
		var pages = maxi(1,ceili(known.size()/6.0)); journal_page = clampi(journal_page,0,pages-1)
		var end = maxi(0,known.size()-journal_page*6)
		var recent = known.slice(maxi(0,end-6),end)
		for i in recent.size():
			var lines = app.wrapped_lines(str(recent[i]),900,15,2)
			for j in lines.size(): app.label_at(lines[j],Vector2(260,365+i*48+j*19),15,app.PAPER if i == recent.size()-1 else app.MUTED)
		app.button("iron_log_prev","Newer",Rect2(260,666,100,32),journal_page>0)
		app.button("iron_log_next","Older",Rect2(375,666,100,32),journal_page+1<pages)
		var reports = [["politics","Councils"],["farm_report","Farms"],["guard_report","Town guard"]]
		for i in reports.size(): app.button(reports[i][0],reports[i][1],Rect2(640+i*180,718,170,36))
