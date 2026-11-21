extends RefCounted
## Read-only projections of saved observations. Never save a second copy of progress.
static func known(c, id: String) -> bool:
	if not c.dungeons.sites.has(id): return false
	var site: Dictionary = c.dungeons.sites[id]
	return site.entered or site.rumour or c.overworld.discovered(Vector2(site.place.x,site.place.y))

static func keys(c, id: String) -> Array:
	var out = []; var targets = c.dungeons.Keys.targets(c.dungeons.sites)
	for key in c.dungeons.vault_keys.records:
		var row: Dictionary = c.dungeons.vault_keys.records[key]
		if targets[key].site == id and (row.held or row.noticed):
			out.append({"floor":targets[key].floor,"room":targets[key].room,"held":row.held,"opened":row.opened,"noticed":row.noticed})
	return out

static func entries(c) -> Array:
	var out = []
	for id in c.dungeons.sites:
		var visible = known(c,id)
		if not visible and keys(c,id).is_empty(): continue
		var site: Dictionary = c.dungeons.sites[id]
		var row = {"id":id,"name":site.place.name,"known":visible,"status":"Entrance unknown"}
		if visible:
			var theme = c.dungeons.Variety.Themes.site_theme(site)
			if theme != "": row["theme"] = c.dungeons.Variety.Themes.LABELS[theme]; row["theme_notes"] = c.dungeons.Variety.Themes.DESCRIPTIONS[theme]
			var floors = []; var visited = 0; var cleared = 0; var unsearched = 0; var guards = 0
			for floor in site.floors:
				if not floor.rooms.any(func(r):return r.visited): continue
				var rooms = []
				for room in floor.rooms:
					if not room.seen: continue
					var detail = {"id":room.id,"x":room.x,"y":room.y,"visited":room.visited,"title":"Unexplored chamber","state":"Unexplored","enemies":[],"links":observed_links(floor,room)}
					var key: Dictionary = c.dungeons.vault_keys.records.get(c.dungeons.reward_key(id,floor.index,room.id),{})
					if key.get("noticed",false) and not key.opened: detail.title = "Locked treasury"; detail.state = "Key carried" if key.held else "Key missing"
					if room.visited:
						visited += 1; detail.title = c.dungeons.TITLES[room.kind]
						detail.state = "Loot recovered" if room.looted else "Cleared" if room.cleared else "Guards remain"
						if room.cleared: cleared += 1
						if not room.looted and not room.loot.is_empty(): unsearched += 1; detail.state += " · unsearched"
						if room.get("hazard","") != "" and room.get("resolution","") == "": detail.state += " · "+{"trap":"trap","rubble":"rubble","secret":"searchable masonry"}[room.hazard]
						var counts = {}
						if not room.cleared:
							for n in room.roster.size():
								if not room.wear.is_empty() and room.wear[n].hp <= 0: continue
								var kind: String = room.roster[n]; counts[kind] = counts.get(kind,0)+1; guards += 1
						for kind in counts: detail.enemies.append("%d × %s" % [counts[kind],c.dungeons.U.TYPES[kind].name])
					rooms.append(detail)
				floors.append({"index":floor.index,"rooms":rooms})
			row.merge({"floors":floors,"deepest":floors[-1].index+1 if not floors.is_empty() else 0,"visited":visited,"cleared":cleared,"unsearched":unsearched,"guards":guards,"keys":keys(c,id)})
			row.status = "Final chest recovered" if site.completed else "Partly explored" if visited else "Unexplored entrance"
		out.append(row)
	return out

static func observed_links(floor: Dictionary, room: Dictionary) -> Array:
	var links: Array = room.links.duplicate()
	for r in floor.rooms:
		if r.get("hazard","") != "rubble" or not r.get("resolution","") in ["cleared_tools","cleared_time"]: continue
		if r.id == room.id and not r.shortcut in links: links.append(r.shortcut)
		elif r.shortcut == room.id and not r.id in links: links.append(r.id)
	return links.filter(func(next):return floor.rooms[next].seen)

static func route(c, from: Vector2, to: Vector2) -> Dictionary:
	# Do not return the path, length or time of unexplored terrain. A map marks
	# an entrance; it does not survey a road or grant a travel-cost oracle.
	if not c.overworld.discovered(from) or not c.overworld.discovered(to): return {}
	var path: Array = c.overworld.route(from,to)
	if path.is_empty() or not path.all(func(p):return c.overworld.discovered(p)): return {}
	var previous = from; var hours = 0.0
	for point in path:
		# Check segment midpoints too (diagonal terrain is part of the estimate).
		if not c.overworld.discovered((previous+point)*0.5): return {}
		hours += previous.distance_to(point)*c.overworld.travel_cost(previous,point)/c.overworld.MOVE_SPEED; previous = point
	return {"hours":hours}

static func towns(c) -> Array:
	return c.region.locations.filter(func(p):return p.kind == "town" and c.overworld.discovered(Vector2(p.x,p.y))).map(func(p):return {"id":p.id,"name":p.name})

static func budget(c, id: String, town: String, days: int, scouting: int) -> Dictionary:
	if not known(c,id) or not towns(c).any(func(t):return t.id == town): return {}
	var point: Vector2 = c.overworld.places[id]; var home: Vector2 = c.overworld.places[town]
	var outbound = route(c,c.overworld.position,point); var returning = route(c,point,home)
	if outbound.is_empty() or returning.is_empty(): return {}
	days = clampi(days,0,7); scouting = clampi(scouting,0,20)
	var exit_hours = 0.5+(c.dungeons.floor_index*0.5 if c.dungeons.active == id else 0.0)
	if c.dungeons.active != "" and c.dungeons.active != id: exit_hours += 0.5+c.dungeons.floor_index*0.5
	var hours: float = ceilf(outbound.hours*20)/20+ceilf(returning.hours*20)/20+days*24.0+scouting+exit_hours
	var midnights = floori((c.overworld.hour+hours+0.000001)/24.0)
	var food: int = midnights*c.alive_count()+scouting*c.dungeon_scout_cost()
	var wages: int = midnights*c.wage_cost()+c.arrears
	return {"outbound":outbound.hours,"returning":returning.hours,"hours":hours,"midnights":midnights,"food":food,"crowns":wages,"food_short":maxi(0,food-c.food),"crowns_short":maxi(0,wages-c.crowns),"days":days,"scouting":scouting,"exit_hours":exit_hours}
