extends RefCounted
## Persistent site geometry, rooms and enemy wear. No global RNG or wall-clock input.
const B = preload("res://src/battle.gd")
const U = preload("res://src/undead.gd")
const Placement = preload("res://src/dungeon_placement.gd")
const Variety = preload("res://src/dungeon_variety.gd")
const Keys = preload("res://src/vault_keys.gd")
const Named = preload("res://src/named_equipment.gd")
const NamedMail = preload("res://layer_forge/named_mail.gd")
var vault_keys = Keys.new()
const VERSION = 6
var rules_version = VERSION
const NAMES = ["Blackbarrow","The Fallen Watch","King's Sepulchre"]
const TITLES = {"entry":"Stairwell","hall":"Burial hall","battle":"Guard chamber","cache":"Side vault","stairs":"Sealed descent","finale":"Warden's tomb","vault":"Guarded treasury"}
var acquisition = null
var support_acquisition = null
var intrinsic_undead_enabled := false
var forge_rewards := false
var equipment_catalog_override: Dictionary = {}
var sites: Dictionary = {}
var active = ""
var floor_index = 0
var room_index = 0
var previous = 0

func enabled() -> bool:
	return not sites.is_empty()

# Only the Named-item channel changes. The seed, room, roster and supplies
# are not rerolled, and cleared rooms remain searchable normally.
func _project_named_rewards(site: Dictionary) -> void:
	if not forge_rewards: return
	for floor: Dictionary in site.floors:
		for room: Dictionary in floor.rooms:
			if room.reward == "": continue
			var id: String = room.reward if acquisition == null else acquisition.reward(room.reward,equipment_catalog_override)
			if equipment_catalog_override.get(id,{}).get("slot") != "weapon": room.reward = ""

func _named_mail_room(site: Dictionary, region: Dictionary, seed_number: int, generation: int) -> Dictionary:
	# It must first be the original selected minor-barrow finale, not a
	# replacement draw. Of that class, one exact artifact has approved paint.
	if not forge_rewards or not NamedMail.registered_site(region,seed_number,generation,site): return {}
	var id: String = site.place.id
	if not id in Variety.IDS or not Variety.small(id) or not site.get("floors") is Array or site.floors.size() != 1: return {}
	var floor = site.floors[NamedMail.FLOOR]
	if not floor is Dictionary or floor.get("index") != NamedMail.FLOOR or floor.get("exit") != NamedMail.ROOM or floor.get("seed") != 468635108: return {}
	if not floor.get("rooms") is Array or floor.rooms.size() <= NamedMail.ROOM: return {}
	var room = floor.rooms[NamedMail.ROOM]
	if not room is Dictionary or room.get("id") != NamedMail.ROOM or room.get("kind") != "finale" or room.get("field") != "crypt_mound": return {}
	if room.get("reward") != NamedMail.TOKEN or room.get("seed") != NamedMail.PACKET.seed: return {}
	return room

func _named_mail_reservation(room: Dictionary, source: String) -> Dictionary:
	var catalog := equipment_catalog_override
	if acquisition == null or acquisition.reward(room.reward,catalog) != NamedMail.PRECURSOR or catalog.get(NamedMail.PRECURSOR,{}).get("group") != "body": return {}
	var rolled := Named.generate(NamedMail.PRECURSOR,room.seed,source,catalog)
	var item := {"definition":NamedMail.PART,"named":rolled,"condition":0}
	if not NamedMail.valid_packet(item,catalog): return {}
	item.condition = int(Named.definition(item,catalog).durability)
	var row := {"item":item,"claimed":""}
	return row if NamedMail.valid_row(row,catalog) else {}

func replay_named_mail(region: Dictionary, seed_number: int) -> Dictionary:
	var site: Dictionary = sites.get(NamedMail.SITE,{})
	var live := _named_mail_room(site,region,seed_number,rules_version)
	if live.is_empty(): return {}
	var original := Variety.make_site(self,site.seed,NamedMail.SITE,site.place,true,true)
	var raw := _named_mail_room(original,region,seed_number,rules_version)
	if raw.is_empty(): return {}
	for field in ["x","y","links","roster","loot","hazard","shortcut","risk"]:
		if live.get(field) != raw[field]: return {}
	if live.get("resolution") != raw.resolution: return {}
	return _named_mail_reservation(raw,site.place.name)

func _reserve_named_mail(c, key: String, room: Dictionary, source: String) -> bool:
	if key != NamedMail.KEY or not Named.valid_text(key,96) or c.combat_pending: return false
	var row := _named_mail_reservation(room,source)
	if row.is_empty() or not NamedMail.valid_row(row,c.catalog): return false
	if c.named_rewards.has(key):
		return NamedMail.valid_row(c.named_rewards[key],c.catalog) and c.named_rewards[key] == row
	if c.named_rewards.size() >= 1000: return false
	c.named_rewards[key] = row
	return true

func expand(c) -> bool:
	if rules_version != 2 or c.roster_version != 1 or c.phase != "camp" or not c.encounter.is_empty() or active != "": return false
	var additions = Variety.generate_sites(self,c)
	if additions.size() != Variety.IDS.size(): return false
	# Reserve every reward before committing the additions. Existing identities
	# and progress are not regenerated, including the three original landmarks.
	var keys = []
	for site in additions.values():
		var mail := _named_mail_room(site,c.region,c.seed_value,VERSION).duplicate()
		_project_named_rewards(site)
		for floor in site.floors:
			for r in floor.rooms:
				var is_mail: bool = not mail.is_empty() and floor.index == NamedMail.FLOOR and r.id == NamedMail.ROOM
				if r.reward == "" and not is_mail: continue
				var key = reward_key(site.place.id,floor.index,r.id)
				var existed: bool = c.named_rewards.has(key)
				var reserved: bool = _reserve_named_mail(c,key,mail,site.place.name) if is_mail else not c.reserve_named_reward(key,r.reward,r.seed,site.place.name).is_empty()
				if not reserved:
					for added in keys: c.named_rewards.erase(added)
					return false
				if is_mail: r.reward = NamedMail.TOKEN
				if not existed: keys.append(key)
	sites.merge(additions); rules_version = 3
	c.overworld.configure(spatial_region(c.region))
	enable_keys(c)
	rules_version = VERSION
	return true

func enable_keys(c) -> bool:
	if rules_version != 3 or c.phase != "camp" or active != "" or not c.encounter.is_empty(): return false
	vault_keys.install(sites); rules_version = 4
	return true

func discover(id: String, source: String) -> bool:
	if source not in ["rumour","map"] or not sites.has(id) or sites[id].rumour or sites[id].completed: return false
	sites[id].rumour = true
	if sites[id].has("discovery"): sites[id].discovery = source
	return true

func locations() -> Array:
	return sites.values().map(func(s): return s.place.duplicate(true))

func spatial_region(region: Dictionary) -> Dictionary:
	var out = region.duplicate(true); out.locations.append_array(locations()); return out

func generate(c) -> bool:
	if enabled(): return false
	rules_version = 2 if c.roster_version == 1 else 1
	var rng = RandomNumberGenerator.new(); rng.seed = c.region.get("seed",c.seed_value)+908172
	var occupied: Array = c.overworld.places.values()
	for farm in c.farm.all(): occupied.append(farm.position)
	for index in 3:
		var town: Vector2 = c.overworld.places[["ashwick","stonecross","dunmere"][index]]
		var choices = []
		for y in range(2,c.overworld.SIZE.y-2):
			for x in range(2,c.overworld.SIZE.x-2):
				var p = c.overworld.cell_point(Vector2i(x,y)); var distance = p.distance_to(town)
				if distance < 85 or distance > 210 or not c.overworld.valid_point(p): continue
				if occupied.any(func(other): return p.distance_to(other) < 70): continue
				choices.append(p)
		# Deterministically choose a reachable candidate; disconnected land is rejected.
		var at = rng.randi_range(0,maxi(0,choices.size()-1)); var position = Vector2.ZERO
		for offset in choices.size():
			var p: Vector2 = choices[(at+offset)%choices.size()]
			if not c.overworld.route(town,p).is_empty(): position = p; break
		if c.region.get("generator") == 3: position = Placement.choose(c,"dungeon_%d" % index,occupied)
		if position == Vector2.ZERO: sites.clear(); return false
		occupied.append(position)
		var id = "dungeon_%d" % index; var seed_number = rng.randi_range(1,2147483646)
		var place = {"id":id,"name":NAMES[index],"kind":"dungeon","x":int(position.x),"y":int(position.y),"description":"An old burial complex held by the unquiet dead."}
		sites[id] = make_site(seed_number,index+1,place)
	for site in sites.values():
		_project_named_rewards(site)
		for floor in site.floors:
			for room in floor.rooms:
				if room.reward != "": c.reserve_named_reward(reward_key(site.place.id,floor.index,room.id),room.reward,room.seed,site.place.name)
	c.overworld.configure(spatial_region(c.region))
	if rules_version >= 2: expand(c)
	return true

func make_site(seed_number: int, tier: int, place: Dictionary, generation: int = rules_version) -> Dictionary:
	var rng = RandomNumberGenerator.new(); rng.seed = seed_number
	var floors = []
	for index in (2 if tier == 1 else 3): floors.append(make_floor(rng.randi_range(1,2147483646),tier,index,index == (1 if tier == 1 else 2),generation))
	return {"seed":seed_number,"tier":tier,"place":place,"floors":floors,"rumour":false,"entered":false,"completed":false}

func make_floor_v1(seed_number: int, tier: int, index: int, last: bool) -> Dictionary:
	var rng = RandomNumberGenerator.new(); rng.seed = seed_number
	var rooms = [{"id":0,"x":0,"y":1,"links":[]}]; var cells = {"0,1":0}
	while rooms.size() < 7+index%2:
		var options = []
		for room in rooms:
			for delta in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]:
				var p = Vector2i(room.x,room.y)+delta; var key = "%d,%d" % [p.x,p.y]
				if p.x in range(4) and p.y in range(3) and not cells.has(key): options.append([room.id,p,key])
		var chosen = options[rng.randi_range(0,options.size()-1)]; var id = rooms.size()
		rooms[chosen[0]].links.append(id); cells[chosen[2]] = id
		rooms.append({"id":id,"x":chosen[1].x,"y":chosen[1].y,"links":[chosen[0]]})
	# A few loops allow optional side rooms without creating disconnected chambers.
	for a in rooms:
		for b in rooms:
			if a.id >= b.id or b.id in a.links: continue
			if absi(a.x-b.x)+absi(a.y-b.y) == 1 and rng.randi_range(0,3) == 0: a.links.append(b.id); b.links.append(a.id)
	var dist = {0:0}; var queue = [0]
	while not queue.is_empty():
		var id = queue.pop_front()
		for next in rooms[id].links:
			if not dist.has(next): dist[next] = dist[id]+1; queue.append(next)
	var exit_room = 1
	for id in dist:
		if dist[id] > dist[exit_room]: exit_room = id
	var options = rooms.map(func(r): return r.id).filter(func(id): return id != 0 and id != exit_room)
	var cache = options.pop_at(rng.randi_range(0,options.size()-1))
	var patrol = options[rng.randi_range(0,options.size()-1)]
	for room in rooms:
		room["kind"] = "entry" if room.id == 0 else ("finale" if last else "stairs") if room.id == exit_room else "cache" if room.id == cache else "battle" if room.id == patrol else "hall"
		room["seed"] = rng.randi_range(1,2147483646); room["roster"] = []
		if room.kind in ["battle","stairs","finale"]:
			var count = mini(6,2+tier+(1 if room.kind != "battle" else 0)+(1 if index > 0 else 0))
			for i in count:
				room.roster.append("warden" if room.kind == "finale" and i == 0 else ["thrall","guard","spearman","archer"][rng.randi_range(0,2 if tier == 1 else 3)])
		room["reward"] = ""
		if room.kind == "finale" or (room.kind == "cache" and rng.randi_range(1,5) == 1):
			var pool = ["sword","spear","mail","nasal","bow","mace"] if tier == 1 else ["heavy_mail","brigandine","greatsword","greataxe","warbow","heavy_crossbow","bascinet"]
			room.reward = pool[rng.randi_range(0,pool.size()-1)]
		room["loot"] = {"crowns":250*tier if room.kind == "finale" else rng.randi_range(30,70)*tier,"food":rng.randi_range(4,8),"tools":rng.randi_range(3,7),"ammunition":rng.randi_range(5,12)} if room.kind in ["cache","finale"] else {}
		room["seen"] = room.id == 0 or room.id in rooms[0].links
		room["visited"] = false
		room["cleared"] = room.roster.is_empty()
		room["looted"] = false
		room["wear"] = []
	return {"index":index,"seed":seed_number,"exit":exit_room,"rooms":rooms}

static func reward_key(site: String, floor_id: int, room_id: int) -> String:
	return "%s/f%d/r%d" % [site,floor_id,room_id]

func room() -> Dictionary:
	return sites[active].floors[floor_index].rooms[room_index] if sites.has(active) else {}

func reveal() -> void:
	var current = room(); current.visited = true; current.seen = true
	for id in links(room_index): sites[active].floors[floor_index].rooms[id].seen = true

func token(site: String, floor_id: int, room_id: int, index: int) -> String:
	return "%s_%d_%d_%d" % [site,floor_id,room_id,index]

func populate(b) -> void:
	var current = room(); var site: Dictionary = sites[active]
	# Enroll only a genuinely unpopulated room, never captured current wear.
	if current.wear.is_empty() and not current.roster.is_empty():
		if intrinsic_undead_enabled: current["intrinsic_undead"] = 1
		else:
			if support_acquisition != null: current["support_cohort"] = 1
			if acquisition != null and acquisition.has_method("previous_design"): current["headwear_policy"] = 1
	for i in b.enemy_slots():
		var u: Dictionary = b.units[i+b.player_slots()]
		if i >= current.roster.size(): u.hp = 0; u.name = "Empty rank"; continue
		equip_room_enemy(b,u,current.roster[i],site.tier,token(active,floor_index,room_index,i),current)
		if not current.wear.is_empty(): U.apply_wear(b,u,current.wear[i])
	if rules_version >= 2: position_enemies(b,current)
	b.boss_tactics = rules_version >= 2 and current.roster.any(func(kind): return kind in b.DungeonTactics.BOSSES)
	if current.wear.is_empty():
		for i in current.roster.size(): current.wear.append(U.wear(b.units[i+b.player_slots()]))

func equip_room_enemy(b, u: Dictionary, kind: String, tier: int, source: String, current: Dictionary) -> void:
	if current.has("intrinsic_undead"):
		U.spawn_intrinsic(b,u,kind,tier)
		return
	U.equip(b,u,kind,tier,source,acquisition,not current.has("headwear_policy"))
	if current.get("support_cohort") == 1 and support_acquisition != null:
		support_acquisition.crypt(b,u,current.seed,kind,tier,source)

func valid_room_wear(saved: Variant, original: Dictionary, catalog: Dictionary, cohort: bool) -> bool:
	if not U.valid_wear(saved,original,catalog): return false
	if cohort:
		# Current cohort parts reconstruct exactly, except for decreasing condition.
		for part in saved.parts:
			var expected: Dictionary = original.parts.filter(func(p): return p.item == part.item)[0].duplicate(true)
			expected.condition = part.condition
			if part != expected: return false
	return true

func settle(b, won: bool) -> void:
	var current = room(); current.wear.clear()
	for i in current.roster.size(): current.wear.append(U.wear(b.units[i+b.player_slots()]))
	if won: current.cleared = true

func snapshot() -> Dictionary:
	var saved = {"version":rules_version,"sites":sites.duplicate(true),"active":active,"floor":floor_index,"room":room_index,"previous":previous}
	if rules_version >= 4: saved["vault_keys"] = vault_keys.snapshot()
	return saved

func restore(raw: Variant, region: Dictionary, spatial, rewards: Dictionary, campaign_seed: int = -1) -> bool:
	if not raw is Dictionary or raw.size() != (7 if raw.get("version",0) in [4,5,6] else 6) or raw.get("version") not in [1,2,3,4,5,VERSION] or not raw.get("sites") is Dictionary or raw.sites.size() != (9 if raw.version >= 3 else 3): return false
	if not raw.get("active") is String or (raw.active != "" and not raw.sites.has(raw.active)): return false
	for key in ["floor","room","previous"]:
		if not raw.get(key) is int or raw[key] < 0: return false
	var occupied = spatial.places.values()
	var ids = ["dungeon_0","dungeon_1","dungeon_2"]+(Variety.IDS if raw.version >= 3 else [])
	var joined_mail := false
	for index in ids.size():
		var id: String = ids[index]; var extra: bool = id in Variety.IDS; var s = raw.sites.get(id)
		if not s is Dictionary or s.size() != (8 if extra else 7) or not s.get("seed") is int or s.seed < 1 or s.seed > 2147483646 or s.get("tier") != (Variety.tier(id) if extra else index+1): return false
		if not s.get("place") is Dictionary: return false
		var p: Dictionary = s.place
		if p.size() != 6 or p.get("id") != id or p.get("kind") != "dungeon" or p.get("name") != (Variety.site_name(s.seed,id,raw.version >= 5) if extra else NAMES[index]) or not p.get("description") is String: return false
		if not p.get("x") is int or not p.get("y") is int: return false
		var point = Vector2(p.x,p.y)
		if not spatial.valid_point(point) or occupied.any(func(other): return point.distance_to(other) < 40) or spatial.route(spatial.places.ashwick,point).is_empty(): return false
		occupied.append(point)
		for key in ["rumour","entered","completed"]:
			if not s.get(key) is bool: return false
		if extra and (s.get("discovery") not in ["","rumour","map"] or s.rumour != (s.discovery != "") or p.description != Variety.description(id,s.seed,raw.version >= 5)): return false
		var expected = Variety.make_site(self,s.seed,id,p,raw.version >= 5,raw.version >= 6) if extra else make_site(s.seed,s.tier,p,mini(raw.version,2))
		var mail := _named_mail_room(expected,region,campaign_seed,raw.version).duplicate()
		_project_named_rewards(expected)
		if not s.get("floors") is Array or s.floors.size() != expected.floors.size(): return false
		for f in s.floors.size():
			var floor = s.floors[f]; var original: Dictionary = expected.floors[f]
			if not floor is Dictionary or floor.size() != 4 or floor.get("index") != f or floor.get("seed") != original.seed or floor.get("exit") != original.exit or not floor.get("rooms") is Array or floor.rooms.size() != original.rooms.size(): return false
			for r in floor.rooms.size():
				var current = floor.rooms[r]; var base: Dictionary = original.rooms[r]
				if not current is Dictionary: return false
				var is_mail := false
				if not mail.is_empty() and f == NamedMail.FLOOR and r == NamedMail.ROOM:
					var mail_key := reward_key(id,f,r)
					if mail_key != NamedMail.KEY: return false
					var token = current.get("reward")
					if not token is String: return false
					if token == NamedMail.TOKEN:
						var exact := _named_mail_reservation(mail,p.name)
						var row = rewards.get(mail_key)
						if exact.is_empty() or not NamedMail.valid_row(row,equipment_catalog_override) or row.item != exact.item or current.get("looted") != (row.claimed != ""): return false
						base.reward = mail.reward
						is_mail = true
						joined_mail = true
					elif token != "" or rewards.has(mail_key): return false
				var cohort: bool = current.has("support_cohort")
				if cohort and (support_acquisition == null or not current.support_cohort is int or current.support_cohort != 1): return false
				var cap_policy: bool = current.has("headwear_policy")
				if cap_policy and (acquisition == null or not acquisition.has_method("previous_design") or not current.headwear_policy is int or current.headwear_policy != 1): return false
				var intrinsic: bool = current.has("intrinsic_undead")
				if intrinsic and (not intrinsic_undead_enabled or cohort or cap_policy or not current.intrinsic_undead is int or current.intrinsic_undead != 1): return false
				if current.size() != base.size()+int(cohort)+int(cap_policy)+int(intrinsic): return false
				for key in ["id","x","y","links","kind","seed","roster","reward","loot"]+(["field","hazard","risk","shortcut"] if raw.version >= 2 else []):
					if current.get(key) != base[key]: return false
				for key in ["seen","visited","cleared","looted"]:
					if not current.get(key) is bool: return false
				if raw.version >= 2 and not valid_resolution(current): return false
				if current.visited and (not current.seen or not s.entered): return false
				if current.visited and f > 0 and not s.floors[f-1].rooms[s.floors[f-1].exit].cleared: return false
				if current.roster.is_empty() and not current.cleared: return false
				if current.looted and (not current.visited or not current.cleared or current.loot.is_empty()): return false
				if not current.get("wear") is Array or (not current.wear.is_empty() and current.wear.size() != current.roster.size()): return false
				if (cohort or cap_policy or intrinsic) and (current.roster.is_empty() or current.wear.is_empty()): return false
				if not current.wear.is_empty():
					if not current.visited: return false
					var b = B.new()
					b.equipment_catalog_override = equipment_catalog_override.duplicate(true)
					b.setup(current.seed,current.get("field","crypt"),"eliminate",true,true,true,true,true,raw.version >= 2)
					for i in current.roster.size():
						equip_room_enemy(b,b.units[b.player_slots()+i],current.roster[i],s.tier,token(id,f,r,i),current)
						if not valid_room_wear(current.wear[i],U.wear(b.units[b.player_slots()+i]),b.armor_catalog,cohort): return false
					if current.cleared != current.wear.all(func(w): return w.hp == 0): return false
				elif not current.roster.is_empty() and current.cleared: return false
				if current.reward != "" and not is_mail:
					var key = reward_key(id,f,r); var reward = rewards.get(key)
					var expected_definition: String = current.reward if acquisition == null else acquisition.reward(current.reward,equipment_catalog_override)
					var retained_definition: String = acquisition.reward_before_crossbows(current.reward,equipment_catalog_override) if not forge_rewards and acquisition != null and acquisition.has_method("reward_before_crossbows") else expected_definition
					if not reward is Dictionary or reward.get("item",{}).get("definition") not in [expected_definition,retained_definition] or reward.item.get("named",{}).get("seed") != current.seed or reward.item.named.source != p.name: return false
					if current.looted != (reward.get("claimed","") != ""): return false
		var finale: Dictionary = s.floors[-1].rooms[s.floors[-1].exit]
		if s.completed != finale.looted or (s.completed and not s.entered): return false
	if forge_rewards:
		for key in rewards:
			var row = rewards[key]
			if row is Dictionary and row.get("item") is Dictionary and row.item.get("definition") == NamedMail.PART and (not joined_mail or key != NamedMail.KEY): return false
	if raw.active != "":
		var site: Dictionary = raw.sites[raw.active]
		if not site.entered or raw.floor >= site.floors.size() or raw.room >= site.floors[raw.floor].rooms.size() or raw.previous >= site.floors[raw.floor].rooms.size(): return false
		if not site.floors[raw.floor].rooms[raw.room].visited or not site.floors[raw.floor].rooms[raw.previous].visited: return false
		for f in raw.floor:
			if not site.floors[f].rooms[site.floors[f].exit].cleared: return false
	elif raw.floor != 0 or raw.room != 0 or raw.previous != 0: return false
	var keys = Keys.new()
	if raw.version >= 4 and not keys.restore(raw.get("vault_keys"),raw.sites): return false
	vault_keys = keys
	rules_version = raw.version
	sites = raw.sites.duplicate(true); active = raw.active; floor_index = raw.floor; room_index = raw.room; previous = raw.previous
	return true

# Version one generation above is frozen for existing campaigns.
func make_floor(seed_number: int, tier: int, index: int, last: bool, generation: int = rules_version) -> Dictionary:
	var floor = make_floor_v1(seed_number,tier,index,last)
	if generation == 1: return floor
	var rng = RandomNumberGenerator.new(); rng.seed = seed_number+17389
	var field: String = ["crypt_barrow","crypt_gallery","crypt_throne"][tier-1]
	for r in floor.rooms:
		r["field"] = field; r["hazard"] = ""; r["risk"] = rng.randi_range(0,2) == 0; r["shortcut"] = -1; r["resolution"] = ""
		if r.kind in ["battle","stairs","finale"]: r.roster = encounter_roster(tier,index,r.kind,r.seed)
		if r.kind == "cache":
			r.hazard = "trap"
			r.loot = {"crowns":rng.randi_range(60,120)*tier,"food":8+2*tier,"tools":4+2*tier,"ammunition":10+4*tier}
		if r.kind == "finale":
			r.loot = {"crowns":[600,1400,2800][tier-1],"food":[12,20,30][tier-1],"tools":[10,18,28][tier-1],"ammunition":[18,30,45][tier-1]}
	var halls = floor.rooms.filter(func(r):return r.kind == "hall")
	var shortcuts = halls.filter(func(r):return not floor.exit in r.links)
	if not shortcuts.is_empty():
		var r: Dictionary = shortcuts[0]; r.hazard = "rubble"; r.shortcut = floor.exit
	var secrets = halls.filter(func(r):return r.hazard == "")
	if not secrets.is_empty():
		var r: Dictionary = secrets[rng.randi_range(0,secrets.size()-1)]
		r.hazard = "secret"; r.loot = {"crowns":30*tier,"food":8+4*tier,"tools":6+2*tier,"ammunition":12+6*tier}
	return floor

static func encounter_roster(tier: int, floor_id: int, kind: String, seed_number: int) -> Array:
	if kind == "finale":
		return [
			["barrow_lord","guard","spearman","guard","spearman","thrall"],
			["watch_captain","guard","guard","guard","spearman","spearman","spearman","archer","archer"],
			["buried_king","sentinel","sentinel","sentinel","guard","guard","guard","spearman","spearman","archer","archer","archer"]][tier-1].duplicate()
	var count: int = ([3,6,9] if kind == "battle" else [4,7,10])[tier-1]+(1 if floor_id > 0 else 0)
	var pools = [["thrall","spearman","guard"],["guard","spearman","archer"],["sentinel","guard","spearman","archer"]]
	var out = []
	for i in count: out.append(pools[tier-1][(i+seed_number)%pools[tier-1].size()])
	return out

func links(id: int) -> Array:
	var floor: Dictionary = sites[active].floors[floor_index]
	var out: Array = floor.rooms[id].links.duplicate()
	if rules_version >= 2:
		for r in floor.rooms:
			if r.hazard != "rubble" or not r.resolution in ["cleared_tools","cleared_time"]: continue
			if r.id == id and not r.shortcut in out: out.append(r.shortcut)
			elif r.shortcut == id and not r.id in out: out.append(r.id)
	return out

static func can_search(r: Dictionary) -> bool:
	return r.get("hazard","") not in ["trap","secret"] or r.get("resolution","") != ""

static func valid_resolution(r: Dictionary) -> bool:
	if not r.get("resolution") is String: return false
	var allowed = {"trap":["","disarmed","forced"],"rubble":["","cleared_tools","cleared_time"],"secret":["","searched"],"":[""]}
	if not r.resolution in allowed[r.hazard] or (r.resolution != "" and not r.visited): return false
	if r.looted and not can_search(r): return false
	return true

static func position_enemies(b, current: Dictionary) -> void:
	if current.get("field","") in Variety.Themes.FIELDS:
		Variety.Themes.position_enemies(b,current); return
	var melee = 0; var ranged = 0
	var rows = [5,4,6,3,7,2,8,1,9]
	for i in current.roster.size():
		var u: Dictionary = b.units[b.player_slots()+i]
		var shooter = U.TYPES[current.roster[i]].weapon in U.A.RANGED
		var row = rows[(ranged if shooter else melee)%rows.size()]
		u.q = 13+ranged/rows.size() if shooter else 12-melee/rows.size(); u.r = row
		if shooter: ranged += 1
		else: melee += 1
