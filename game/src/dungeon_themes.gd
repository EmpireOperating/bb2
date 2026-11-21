extends RefCounted
## Version-five generation. Keep this algorithm frozen when adding future themes.
const FIELDS = ["crypt_mound","crypt_garrison","crypt_royal"]
const LABELS = {"barrow":"Burial mound","garrison":"Buried garrison","royal":"Royal crypt"}
const DESCRIPTIONS = {
	"barrow":"Cramped burial chambers hold lightly equipped dead and scattered valuables. Named equipment is uncommon.",
	"garrison":"Long galleries shelter shield ranks, spearmen and archers. Treasuries favour weapons; side vaults need world-found keys.",
	"royal":"Armoured retainers defend narrow approaches and optional tomb vaults. Treasuries favour armour; side vaults need world-found keys."
}
const NOUNS = {"barrow":["Barrow","Burial Mound","Grave Hill","Stone Tomb"],"garrison":["Buried Garrison","Fallen Barracks","Watch Vaults","Sunken Fort"],"royal":["Royal Crypt","Crown Tombs","Ancestral Vaults","Buried Court"]}

static func theme(id: String, seed_number: int) -> String:
	if id.begins_with("dungeon_barrow_"): return "barrow"
	if id == "dungeon_complex_0": return "garrison"
	if id == "dungeon_complex_1": return "royal"
	return "garrison" if seed_number%2 == 0 else "royal"

static func field(kind: String) -> String:
	return {"barrow":FIELDS[0],"garrison":FIELDS[1],"royal":FIELDS[2]}[kind]

static func site_theme(site: Dictionary) -> String:
	# Saved field identity is authoritative; legacy sites get no invented theme.
	var saved: String = site.floors[0].rooms[0].get("field","")
	for kind in LABELS:
		if field(kind) == saved: return kind
	return ""

static func make_floor(seed_number: int, kind: String, threat: int, index: int, last: bool) -> Dictionary:
	var rng = RandomNumberGenerator.new(); rng.seed = seed_number
	var minor = kind == "barrow"
	var count = rng.randi_range(4,6) if minor else rng.randi_range(8,12)
	var rooms = [{"id":0,"x":0,"y":1,"links":[1]},{"id":1,"x":0,"y":0,"links":[0]}]
	var cells = {"0,1":0,"0,0":1}
	# Garrisons and royal tombs have a central approach. Their side chambers
	# grow differently; the locked vault remains a leaf off the entrance.
	if not minor:
		for x in range(1,4):
			var parent = 0 if x == 1 else rooms.size()-1; var next = rooms.size()
			rooms[parent].links.append(next); cells["%d,1" % x] = next
			rooms.append({"id":next,"x":x,"y":1,"links":[parent]})
	while rooms.size() < count:
		var choices = []
		for r in rooms:
			if r.id == 1: continue
			for delta in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]:
				var p = Vector2i(r.x,r.y)+delta; var key = "%d,%d" % [p.x,p.y]
				if p.x not in range(3 if minor else 4) or p.y not in range(3) or cells.has(key): continue
				var weight = 4 if (kind == "garrison" and delta.y == 0) or (kind == "royal" and r.y == 1) else 1
				for n in weight: choices.append([r.id,p,key])
		var chosen: Array = choices[rng.randi_range(0,choices.size()-1)]; var next = rooms.size()
		rooms[chosen[0]].links.append(next); cells[chosen[2]] = next
		rooms.append({"id":next,"x":chosen[1].x,"y":chosen[1].y,"links":[chosen[0]]})
	# Gallery cross-doors allow flanking; tomb branches stay secluded.
	if kind == "garrison":
		for a in rooms:
			for b in rooms:
				if a.id == 1 or b.id == 1 or a.id >= b.id or b.id in a.links: continue
				if absi(a.x-b.x)+absi(a.y-b.y) == 1 and rng.randi_range(0,1) == 0: a.links.append(b.id); b.links.append(a.id)
	var dist = {0:0}; var queue = [0]
	while not queue.is_empty():
		var at: int = queue.pop_front()
		for next in rooms[at].links:
			if not dist.has(next): dist[next] = dist[at]+1; queue.append(next)
	var exit_room = 4 if kind == "royal" else 2
	if kind != "royal":
		for at in dist:
			if at != 1 and dist[at] > dist[exit_room]: exit_room = at
	var guard = 2 if not minor else -1
	if guard == exit_room: guard = 3
	for r in rooms:
		r["kind"] = "entry" if r.id == 0 else ("finale" if last else "stairs") if r.id == exit_room else ("cache" if minor else "vault") if r.id == 1 else "battle" if r.id == guard else "hall"
		r["seed"] = rng.randi_range(1,2147483646); r["roster"] = []
		if r.kind in ["battle","stairs","finale","vault"]:
			var size = rng.randi_range(2,3) if minor else mini(12,rng.randi_range(4,6)+(threat-2)*2+index/2+(2 if r.kind == "vault" else 0))
			# Armour replaces some bodies; keep a royal site within its threat band.
			if kind == "royal": size = maxi(3,size-1)
			r.roster = roster(kind,size,r.kind,rng)
		r["reward"] = ""
		if (r.kind == "finale" and (not minor or rng.randi_range(1,5) == 1)) or (r.kind == "vault" and rng.randi_range(1,3) == 1):
			var pool = ["sword","spear","mace","mail","nasal"] if minor else ["greatsword","greataxe","warbow","heavy_crossbow","heavy_mail"] if kind == "garrison" else ["heavy_mail","brigandine","bascinet","heavy_mail","greatsword"]
			r.reward = pool[rng.randi_range(0,pool.size()-1)]
		r["loot"] = {}
		if r.kind in ["cache","vault","finale"]:
			var cash = rng.randi_range(35,65) if r.kind == "cache" else rng.randi_range(100,180) if minor else rng.randi_range(250,400)*threat if r.kind == "vault" else rng.randi_range(450,650)*threat
			r.loot = {"crowns":cash,"food":rng.randi_range(4,8)*threat,"tools":rng.randi_range(3,6)*threat,"ammunition":rng.randi_range(5,10)*threat}
		r["field"] = field(kind); r["hazard"] = "trap" if r.kind in ["cache","vault"] and rng.randi_range(0,1) == 0 else ""
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

static func roster(kind: String, count: int, room_kind: String, rng: RandomNumberGenerator) -> Array:
	if kind == "barrow":
		var out = ["thrall","thrall"]
		if count == 3: out.append("guard" if room_kind == "finale" and rng.randi_range(0,1) == 0 else "spearman")
		return out
	var out = []; var elite = room_kind in ["vault","finale"]
	if elite: out.append("warden")
	if kind == "garrison":
		var archers = maxi(1,count/3); var spears = maxi(1,(count-archers)/2)
		while out.size() < count-archers-spears: out.append("guard")
		for i in spears: out.append("spearman")
		for i in archers: out.append("archer")
	else:
		while out.size() < count: out.append("sentinel" if out.size()%3 == 0 else "guard")
	return out

static func configure_battle(b) -> void:
	if b.map_id not in FIELDS: return
	for r in b.height():
		for q in b.width():
			var wall = false
			match b.map_id:
				"crypt_mound": wall = r in [0,1,9,10] or (q == 7 and r in [2,3,7,8])
				"crypt_garrison": wall = q in range(5,11) and r in [3,7]
				"crypt_royal": wall = (q == 9 and r in [0,1,2,3,7,8,9,10]) or (q == 6 and r in [3,7])
			b.tiles[b.key(Vector2i(q,r))] = {"terrain":"wall" if wall else "stone","height":0}

static func position_enemies(b, current: Dictionary) -> void:
	var ranks = {}; var rows = [5,4,6,3,7,2,8,1,9]
	for i in current.roster.size():
		var role: String = current.roster[i]; var q = 11
		if current.field == "crypt_mound": q = 10
		elif role == "archer": q = 14
		elif role == "spearman" or role == "warden": q = 12
		var at: int = ranks.get(q,0); ranks[q] = at+1
		var u: Dictionary = b.units[b.player_slots()+i]
		# Overflow goes forward: the warden owns the centre of column twelve.
		u.q = q-at/rows.size(); u.r = [2,8,1,9][at%4] if role == "archer" else rows[at%rows.size()]
