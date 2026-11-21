extends RefCounted
## Additional sites are generated once. No company stats or combat RNG are read.
const Themes = preload("res://src/dungeon_themes.gd")
const Placement = preload("res://src/dungeon_placement.gd")
const IDS = ["dungeon_barrow_0","dungeon_barrow_1","dungeon_barrow_2","dungeon_complex_0","dungeon_complex_1","dungeon_complex_2"]
const PREFIXES = ["Ashen","Grey","Hollow","Wren's","Broken","Thorn","Raven","Bleak","Iron","Silent","Old","Wolf's"]
const BARROWS = ["Barrow","Burial Mound","Grave Hill","Stone Tomb"]
const COMPLEXES = ["Catacombs","Buried Halls","Ossuary","Deep Vaults"]

static func small(id: String) -> bool: return id.begins_with("dungeon_barrow_")
static func tier(id: String) -> int: return 1 if small(id) else 3 if id == IDS[-1] else 2
static func site_name(seed_number: int, id: String, themed: bool = false) -> String:
	var names: Array = Themes.NOUNS[Themes.theme(id,seed_number)] if themed else BARROWS if small(id) else COMPLEXES
	return PREFIXES[seed_number%PREFIXES.size()]+" "+names[(seed_number/17)%names.size()]

static func description(id: String, seed_number: int = 0, themed: bool = false) -> String:
	if themed: return Themes.DESCRIPTIONS[Themes.theme(id,seed_number)]
	return "A small burial site. Modest valuables lie among the dead; exceptional equipment is uncommon." if small(id) else "A sprawling burial complex with branching chambers, guarded side treasuries and deeper undead garrisons."

static func generate_sites(d, c) -> Dictionary:
	var rng = RandomNumberGenerator.new(); rng.seed = c.region.get("seed",c.seed_value)+481093
	var occupied: Array = c.overworld.places.values().duplicate()
	for farm in c.farm.all(): occupied.append(farm.position)
	var towns: Array = c.region.locations.filter(func(p): return p.kind == "town")
	var names: Array = d.sites.values().map(func(s): return s.place.name)
	var additions = {}
	for index in IDS.size():
		var id: String = IDS[index]; var home: Dictionary = towns[index%towns.size()]
		var origin = Vector2(home.x,home.y); var choices = []
		for y in range(2,c.overworld.SIZE.y-2):
			for x in range(2,c.overworld.SIZE.x-2):
				var point: Vector2 = c.overworld.cell_point(Vector2i(x,y))
				if point.distance_to(origin) < 80 or point.distance_to(origin) > (230 if small(id) else 420) or not c.overworld.valid_point(point): continue
				if occupied.any(func(p):return p.distance_to(point) < 64): continue
				choices.append(point)
		if choices.is_empty(): return {}
		var start = rng.randi_range(0,choices.size()-1); var chosen = Vector2.ZERO
		for offset in choices.size():
			var point: Vector2 = choices[(start+offset)%choices.size()]
			if not c.overworld.route(origin,point).is_empty(): chosen = point; break
		if c.region.get("generator") == 3: chosen = Placement.choose(c,id,occupied)
		if chosen == Vector2.ZERO: return {}
		var site_seed = rng.randi_range(1,2147483646)
		while site_name(site_seed,id,true) in names: site_seed = rng.randi_range(1,2147483646)
		var name = site_name(site_seed,id,true); names.append(name); occupied.append(chosen)
		var place = {"id":id,"name":name,"kind":"dungeon","x":int(chosen.x),"y":int(chosen.y),"description":description(id,site_seed,true)}
		additions[id] = make_site(d,site_seed,id,place,true,true)
	return additions

static func make_site(d, seed_number: int, id: String, place: Dictionary, themed: bool = false, stairwell_supplies: bool = false) -> Dictionary:
	var rng = RandomNumberGenerator.new(); rng.seed = seed_number
	var count = 1 if small(id) else rng.randi_range(2,4)
	var floors = []
	for index in count:
		var floor_seed = rng.randi_range(1,2147483646)
		floors.append(Themes.make_floor(floor_seed,Themes.theme(id,seed_number),tier(id),index,index == count-1) if themed else make_floor(d,floor_seed,id,index,index == count-1))
		# Version six adds supplies after generation, without drawing RNG or
		# changing geometry, guards, keys, named rewards or final treasure.
		if stairwell_supplies and themed and not small(id) and index < count-1:
			floors[-1].rooms[floors[-1].exit].loot = stairwell_cache(tier(id))
	return {"seed":seed_number,"tier":tier(id),"place":place,"floors":floors,"rumour":false,"entered":false,"completed":false,"discovery":""}

static func stairwell_cache(threat: int) -> Dictionary:
	return {"crowns":60*threat,"food":6*threat,"tools":8*threat,"ammunition":8*threat}

static func make_floor(d, seed_number: int, id: String, index: int, last: bool) -> Dictionary:
	var rng = RandomNumberGenerator.new(); rng.seed = seed_number
	var minor = small(id); var threat = tier(id)
	var count = rng.randi_range(4,6) if minor else rng.randi_range(8,12)
	# Reserve the upper-left leaf as an optional vault. The rest of the tree
	# grows from the entry and remains traversable without entering that vault.
	var rooms = [{"id":0,"x":0,"y":1,"links":[1]},{"id":1,"x":0,"y":0,"links":[0]}]
	var cells = {"0,1":0,"0,0":1}
	while rooms.size() < count:
		var choices = []
		for r in rooms:
			if r.id == 1: continue
			for delta in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]:
				var p = Vector2i(r.x,r.y)+delta; var key = "%d,%d" % [p.x,p.y]
				if p.x in range(4) and p.y in range(3) and not cells.has(key): choices.append([r.id,p,key])
		var chosen: Array = choices[rng.randi_range(0,choices.size()-1)]; var next = rooms.size()
		rooms[chosen[0]].links.append(next); cells[chosen[2]] = next
		rooms.append({"id":next,"x":chosen[1].x,"y":chosen[1].y,"links":[chosen[0]]})
	# Extra doors make loops; the side vault stays an optional leaf.
	for a in rooms:
		for b in rooms:
			if a.id == 1 or b.id == 1 or a.id >= b.id or b.id in a.links: continue
			if absi(a.x-b.x)+absi(a.y-b.y) == 1 and rng.randi_range(0,3) == 0: a.links.append(b.id); b.links.append(a.id)
	var dist = {0:0}; var queue = [0]
	while not queue.is_empty():
		var at: int = queue.pop_front()
		for next in rooms[at].links:
			if not dist.has(next): dist[next] = dist[at]+1; queue.append(next)
	var exit_room = 2
	for at in dist:
		if at != 1 and dist[at] > dist[exit_room]: exit_room = at
	var options: Array = rooms.map(func(r):return r.id).filter(func(at):return at not in [0,1,exit_room])
	var guard_room: int = options[rng.randi_range(0,options.size()-1)] if not minor else -1
	var field: String = ["crypt_barrow","crypt_gallery","crypt_throne"][rng.randi_range(0,2)]
	for r in rooms:
		r["kind"] = "entry" if r.id == 0 else ("finale" if last else "stairs") if r.id == exit_room else ("cache" if minor else "vault") if r.id == 1 else "battle" if r.id == guard_room else "hall"
		r["seed"] = rng.randi_range(1,2147483646); r["roster"] = []
		if r.kind in ["battle","stairs","finale","vault"]:
			var size = rng.randi_range(2,3) if minor else mini(12,rng.randi_range(4,6)+(threat-2)*2+index/2+(2 if r.kind == "vault" else 0))
			var pool = ["thrall","guard","spearman"] if minor else ["guard","spearman","archer"] if threat == 2 else ["sentinel","guard","spearman","archer"]
			for n in size: r.roster.append("warden" if not minor and n == 0 and r.kind in ["vault","finale"] else pool[rng.randi_range(0,pool.size()-1)])
		r["reward"] = ""
		if (r.kind == "finale" and (not minor or rng.randi_range(1,5) == 1)) or (r.kind == "vault" and rng.randi_range(1,3) == 1):
			var rewards = ["sword","spear","mace","mail","nasal"] if minor else ["heavy_mail","brigandine","greatsword","greataxe","warbow","heavy_crossbow","bascinet"]
			r.reward = rewards[rng.randi_range(0,rewards.size()-1)]
		r["loot"] = {}
		if r.kind in ["cache","vault","finale"]:
			var cash = rng.randi_range(35,65) if r.kind == "cache" else rng.randi_range(100,180) if minor else rng.randi_range(250,400)*threat if r.kind == "vault" else rng.randi_range(450,650)*threat
			r.loot = {"crowns":cash,"food":rng.randi_range(4,8)*threat,"tools":rng.randi_range(3,6)*threat,"ammunition":rng.randi_range(5,10)*threat}
		r["field"] = field; r["hazard"] = "trap" if r.kind in ["cache","vault"] and rng.randi_range(0,1) == 0 else ""
		r["risk"] = rng.randi_range(0,2) == 0; r["shortcut"] = -1; r["resolution"] = ""
		r["seen"] = r.id == 0 or r.id in rooms[0].links; r["visited"] = false; r["cleared"] = r.roster.is_empty(); r["looted"] = false; r["wear"] = []
	var halls: Array = rooms.filter(func(r):return r.kind == "hall")
	if not halls.is_empty():
		var r: Dictionary = halls[rng.randi_range(0,halls.size()-1)]
		r.hazard = "secret"; r.loot = {"crowns":20*threat,"food":6*threat,"tools":4*threat,"ammunition":8*threat}
	if not minor:
		var passages: Array = halls.filter(func(r):return r.hazard == "" and not exit_room in r.links)
		if not passages.is_empty(): passages[0].hazard = "rubble"; passages[0].shortcut = exit_room
	return {"index":index,"seed":seed_number,"exit":exit_room,"rooms":rooms}
