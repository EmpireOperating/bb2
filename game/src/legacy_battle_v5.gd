extends RefCounted
## Pure battle rules. No nodes, animations, input, wall clock or global random state.
## All player and AI actions go through the same validated command methods.

const W = 13
const H = 9
const MAX_AP = 9
const FORD = Vector2i(6, 4)
const DIRECTIONS = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
var weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy_weapons_v11.json"))
var units: Array = []
var tiles: Dictionary = {}
var events: Array = []
var round_no = 1
var side = 0
var result = ""
var rng_state = 1
var seed_value = 1
var held: Array = [0, 0]
var commands: Array = []
var map_id = "ford"
var objective = "hold"

func setup(seed_number: int = 7391, field: String = "ford", mission: String = "hold") -> void:
	map_id = field
	objective = mission
	rng_state = maxi(1, seed_number % 2147483647)
	seed_value = rng_state
	units.clear()
	tiles.clear()
	events.clear()
	commands.clear()
	round_no = 1
	side = 0
	result = ""
	held = [0, 0]
	for r in H:
		for q in W:
			var terrain = "grass"
			var height = 0
			if q == 6: terrain = "water" if r < 3 or r > 5 else "ford"
			if q in [5, 7] and r in [0, 1, 7, 8]: terrain = "mud"
			if Vector2i(q, r) in [Vector2i(3, 1), Vector2i(4, 1), Vector2i(4, 2), Vector2i(8, 6), Vector2i(9, 6), Vector2i(8, 7)]:
				terrain = "hill"
				height = 1
			if Vector2i(q, r) in [Vector2i(2, 0), Vector2i(3, 7), Vector2i(10, 0), Vector2i(10, 8)]: terrain = "forest"
			tiles[key(Vector2i(q, r))] = {"terrain":terrain, "height":height}
	configure_terrain()
	add_unit("Aldric", "THE OLD HAND", 0, Vector2i(3, 3), "sword", true, 76, 22, 82, 85)
	add_unit("Bram", "THE MILLER", 0, Vector2i(3, 5), "axe", true, 66, 13, 88, 70)
	add_unit("Oswin", "THE WATCHMAN", 0, Vector2i(2, 2), "spear", true, 70, 20, 76, 75)
	add_unit("Merek", "THE POACHER", 0, Vector2i(2, 4), "bow", false, 72, 9, 65, 55)
	add_unit("Edda", "THE EXILE", 0, Vector2i(2, 6), "axe", false, 75, 17, 80, 80)
	add_unit("Tostig", "THE FARMHAND", 0, Vector2i(3, 6), "spear", true, 65, 15, 78, 60)
	add_unit("Voss", "MARCH CAPTAIN", 1, Vector2i(9, 4), "sword", true, 74, 22, 88, 90)
	add_unit("Red Pike", "MARCH SPEARMAN", 1, Vector2i(10, 3), "spear", true, 65, 16, 74, 65)
	add_unit("Wulf", "MARCH AXEMAN", 1, Vector2i(9, 5), "axe", true, 68, 15, 80, 70)
	add_unit("Ivar", "MARCH SPEARMAN", 1, Vector2i(10, 5), "spear", true, 65, 16, 74, 65)
	add_unit("Holt", "MARCH BOWMAN", 1, Vector2i(11, 4), "bow", false, 68, 8, 64, 50)
	add_unit("Sable", "MARCH RAIDER", 1, Vector2i(9, 2), "axe", false, 70, 12, 78, 65)
	if objective in ["defend", "escort"]:
		for i in 6: units[i].q += 2
	log_event(objective_text())

func configure_terrain() -> void:
	if map_id == "ford": return
	for r in H:
		for q in W:
			var terrain = "grass"
			var height = 0
			if map_id == "forest":
				if q in [4, 8] and r in [0, 1, 2, 6, 7, 8] or q in [5, 7] and r in [1, 7]: terrain = "forest"
				if r == 4: terrain = "mud"
			elif map_id == "ridge":
				if q >= 5 and q <= 8 and r >= 2 and r <= 6:
					terrain = "hill"
					height = 1
				if q == 6 and r in [3, 4, 5]: height = 2
				if q in [3, 9] and r in [0, 1, 7, 8]: terrain = "forest"
			tiles[key(Vector2i(q, r))] = {"terrain":terrain, "height":height}

func objective_name() -> String:
	return {"hold":"TAKE THE CROSSING", "eliminate":"BREAK THE RAIDERS", "defend":"HOLD THE RIDGE", "escort":"DEFEND THE WAGONS"}[objective]

func objective_text() -> String:
	return {"hold":"Hold the marked ground for 3 full rounds, or break the enemy company.", "eliminate":"Kill or rout every raider. There is no capture victory on this field.", "defend":"Survive 8 rounds. Deny the enemy 3 rounds on the banner, or break them.", "escort":"Defend the wagon circle for 8 rounds. Deny 3 enemy capture rounds, or break them."}[objective]

func add_unit(n: String, title: String, team: int, p: Vector2i, weapon: String, shield: bool, skill: int, defense: int, hp: int, armor: int) -> void:
	units.append({"id":units.size(), "name":n, "title":title, "side":team, "q":p.x, "r":p.y, "weapon":weapon, "shield":shield, "skill":skill, "defense":defense, "hp":hp, "max_hp":hp, "armor":armor, "max_armor":armor, "padding":30, "max_padding":30, "helmet":40, "max_helmet":40, "morale":85 if team == 0 else 75, "fatigue":0, "ap":MAX_AP, "guard":false, "routed":false, "escaped":false, "kills":0})

func roll(low: int, high: int) -> int:
	rng_state = (rng_state * 48271) % 2147483647
	return low + rng_state % (high - low + 1)

func key(p: Vector2i) -> String:
	return "%d,%d" % [p.x, p.y]

func pos(u: Dictionary) -> Vector2i:
	return Vector2i(int(u.q), int(u.r))

func axial(p: Vector2i) -> Vector2i:
	return Vector2i(p.x - (p.y - (p.y & 1)) / 2, p.y)

func offset(p: Vector2i) -> Vector2i:
	return Vector2i(p.x + (p.y - (p.y & 1)) / 2, p.y)

func distance(a: Vector2i, b: Vector2i) -> int:
	var d = axial(a) - axial(b)
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2

func neighbors(p: Vector2i) -> Array:
	var out: Array = []
	for d in DIRECTIONS:
		var n = offset(axial(p) + d)
		if tiles.has(key(n)): out.append(n)
	return out

func living(u: Dictionary) -> bool:
	return u.hp > 0 and not u.escaped

func fighting(u: Dictionary) -> bool:
	return living(u) and not u.routed

func at(p: Vector2i) -> int:
	for u in units:
		if living(u) and pos(u) == p: return int(u.id)
	return -1

func adjacent_enemies(u: Dictionary, from: Vector2i) -> Array:
	var out: Array = []
	for v in units:
		if fighting(v) and v.side != u.side and distance(from, pos(v)) == 1: out.append(v.id)
	return out

func shield_support(u: Dictionary) -> int:
	if not u.shield: return 0
	var count = 0
	for v in units:
		if v.id != u.id and fighting(v) and v.side == u.side and v.shield and distance(pos(v), pos(u)) == 1:
			count += 1
	return mini(2, count) * 5

func step_cost(a: Vector2i, b: Vector2i) -> int:
	if not tiles.has(key(b)) or tiles[key(b)].terrain == "water": return 999
	var cost = 4 if tiles[key(b)].terrain in ["mud", "forest"] else 2
	return cost + maxi(0, int(tiles[key(b)].height) - int(tiles[key(a)].height))

func can_act(id: int) -> bool:
	return id >= 0 and id < units.size() and result.is_empty() and living(units[id]) and units[id].side == side

func movement_map(id: int) -> Dictionary:
	if not can_act(id): return {}
	var u: Dictionary = units[id]
	var start = pos(u)
	var budget = mini(int(u.ap), (100 - int(u.fatigue)) / 3)
	var costs: Dictionary = {key(start):0}
	var paths: Dictionary = {key(start):[]}
	var frontier: Array = [start]
	if not u.routed and not adjacent_enemies(u, start).is_empty(): return {}
	while not frontier.is_empty():
		frontier.sort_custom(func(a, b): return costs[key(a)] < costs[key(b)])
		var p: Vector2i = frontier.pop_front()
		if p != start and not adjacent_enemies(u, p).is_empty(): continue
		for n in neighbors(p):
			if at(n) != -1: continue
			var new_cost = int(costs[key(p)]) + step_cost(p, n)
			if new_cost <= budget and (not costs.has(key(n)) or new_cost < int(costs[key(n)])):
				costs[key(n)] = new_cost
				paths[key(n)] = paths[key(p)] + [n]
				if not frontier.has(n): frontier.append(n)
	var out: Dictionary = {}
	for k in paths:
		if k != key(start): out[k] = {"cost":costs[k], "path":paths[k]}
	return out

func move_unit(id: int, target: Vector2i) -> bool:
	var reachable = movement_map(id)
	if not reachable.has(key(target)): return false
	var u: Dictionary = units[id]
	var cost = int(reachable[key(target)].cost)
	u.ap -= cost
	u.fatigue += cost * 3
	u.q = target.x
	u.r = target.y
	u.guard = false
	commands.append(["move", id, target.x, target.y])
	if u.routed and (target.x == 0 or target.x == W - 1 or target.y == 0 or target.y == H - 1):
		u.escaped = true
		log_event("%s escapes the field." % u.name)
	check_result()
	return true

func line_clear(a: Vector2i, b: Vector2i) -> bool:
	var aa = axial(a)
	var bb = axial(b)
	var length = distance(a, b)
	for i in range(1, length):
		var t = float(i) / length
		var x = lerpf(aa.x, bb.x, t) + 0.00001
		var z = lerpf(aa.y, bb.y, t) + 0.00002
		var y = -x-z
		var rx = roundi(x)
		var ry = roundi(y)
		var rz = roundi(z)
		if absf(rx-x) > absf(ry-y) and absf(rx-x) > absf(rz-z): rx = -ry-rz
		elif absf(ry-y) <= absf(rz-z): rz = -rx-ry
		var p = offset(Vector2i(rx, rz))
		if at(p) != -1 or (tiles.has(key(p)) and tiles[key(p)].terrain == "forest"): return false
	return true

func in_range(u: Dictionary, v: Dictionary) -> bool:
	var w: Dictionary = weapons[u.weapon]
	var d = distance(pos(u), pos(v))
	if d < 1 or d > int(w.reach): return false
	if u.weapon == "bow":
		return adjacent_enemies(u, pos(u)).is_empty() and line_clear(pos(u), pos(v))
	# Spears can thrust past allies, but not through enemies.
	if d == 2:
		for p in neighbors(pos(u)):
			if distance(p, pos(v)) == 1 and tiles[key(p)].terrain != "water":
				var occupant = at(p)
				if occupant == -1 or units[occupant].side == u.side: return true
		return false
	return true

func hit_chance(a: int, b: int) -> int:
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapons[u.weapon]
	var value = int(u.skill) + int(w.skill) - int(v.defense)
	value += (int(tiles[key(pos(u))].height) - int(tiles[key(pos(v))].height)) * 12
	value -= shield_support(v)
	if v.shield: value -= 10
	if v.guard: value -= 20 if v.shield else 10
	value += maxi(0, adjacent_enemies(v, pos(v)).size() - 1) * 8
	if u.weapon == "bow": value -= maxi(0, distance(pos(u), pos(v)) - 3) * 7
	if u.morale < 35: value -= 12
	if u.fatigue >= 75: value -= 10
	if v.routed: value += 20
	return clampi(value, 5, 95)

func can_attack(a: int, b: int) -> bool:
	if not can_act(a) or b < 0 or b >= units.size(): return false
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapons[u.weapon]
	return not u.routed and living(v) and u.side != v.side and u.ap >= w.ap and u.fatigue + w.fatigue <= 100 and in_range(u, v)

func attack(a: int, b: int) -> bool:
	if not can_attack(a, b): return false
	var u: Dictionary = units[a]
	var w: Dictionary = weapons[u.weapon]
	u.ap -= int(w.ap)
	u.fatigue += int(w.fatigue)
	u.guard = false
	commands.append(["attack", a, b])
	strike(a, b)
	check_result()
	return true

func strike(a: int, b: int) -> void:
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapons[u.weapon]
	var chance = hit_chance(a, b)
	if roll(1, 100) > chance:
		log_event("%s misses %s (%d%%)." % [u.name, v.name, chance])
		return
	var raw = roll(int(w.min), int(w.max))
	var head = roll(1, 100) <= 20
	if head: raw = roundi(raw * 1.3)
	var layer = "helmet" if head else "armor"
	var armor_loss = mini(int(v[layer]), roundi(raw * float(w.armor)))
	var absorbed = mini(roundi(raw * (1.0 - float(w.pierce))), roundi(float(armor_loss) / float(w.armor) * 0.72))
	v[layer] -= armor_loss
	var damage = raw - absorbed
	if not head:
		var padding_loss = mini(int(v.padding), roundi(damage * 0.5))
		v.padding -= padding_loss
		damage -= padding_loss
	v.hp = maxi(0, int(v.hp) - damage)
	log_event("%s hits %s: %d flesh / %d %s." % [u.name, v.name, damage, armor_loss, "helm" if head else "mail"])
	if v.hp == 0:
		u.kills += 1
		log_event("%s falls. The line shudders." % v.name)
		for other in units:
			if fighting(other) and other.side == v.side and distance(pos(other), pos(v)) <= 3: morale_loss(other, 24)
	elif damage >= 8:
		morale_loss(v, 10 + (8 if v.hp < v.max_hp / 3.0 else 0))

func morale_loss(u: Dictionary, amount: int) -> void:
	if not fighting(u): return
	u.morale = maxi(0, int(u.morale) - amount)
	if u.morale <= 15:
		u.routed = true
		u.guard = false
		log_event("%s breaks and flees!" % u.name)
		for other in units:
			if other.side == u.side and other.id != u.id and fighting(other) and distance(pos(u), pos(other)) <= 2:
				morale_loss(other, 10)

func guard_unit(id: int) -> bool:
	if not can_act(id): return false
	var u: Dictionary = units[id]
	if u.routed or u.ap < 4 or u.fatigue > 85 or u.guard: return false
	u.ap -= 4
	u.fatigue += 15
	u.guard = true
	commands.append(["guard", id])
	log_event("%s %s." % [u.name, "raises a shieldwall" if u.shield else "braces"])
	return true

func recover(id: int) -> bool:
	if not can_act(id) or units[id].ap < 4 or units[id].routed: return false
	units[id].fatigue = maxi(0, int(units[id].fatigue) - 35)
	units[id].ap = 0
	commands.append(["recover", id])
	log_event("%s catches a breath." % units[id].name)
	return true

func withdraw(id: int, target: Vector2i) -> bool:
	if not can_act(id) or units[id].ap < 4 or units[id].fatigue > 88: return false
	var u: Dictionary = units[id]
	if distance(pos(u), target) != 1 or at(target) != -1 or step_cost(pos(u), target) >= 999: return false
	var foes = adjacent_enemies(u, pos(u))
	if foes.is_empty(): return false
	u.ap -= 4
	u.fatigue += 12
	u.guard = false
	commands.append(["withdraw", id, target.x, target.y])
	for foe in foes:
		if living(u): strike(int(foe), id)
	if living(u):
		u.q = target.x
		u.r = target.y
	check_result()
	return true

func finish_unit(id: int) -> void:
	if can_act(id):
		units[id].ap = 0
		commands.append(["finish", id])

func end_turn() -> void:
	if not result.is_empty(): return
	commands.append(["end", side])
	if side == 1:
		var control = [-1, -1]
		for u in units:
			if fighting(u) and distance(pos(u), FORD) <= 1: control[int(u.side)] = 1
		for team in 2:
			held[team] = mini(3, int(held[team]) + 1) if control[team] == 1 and control[1-team] == -1 else 0
			if objective != "eliminate" and held[team] >= 3 and (objective == "hold" or team == 1):
				result = "victory" if team == 0 else "defeat"
				log_event("The crossing is secured." if team == 0 else "The enemy controls the crossing.")
		if objective in ["defend", "escort"] and round_no >= 8 and result.is_empty():
			result = "victory"
			log_event("The wagons are secured. Continue the escort to town." if objective == "escort" else "The relief column arrives. The ridge holds.")
		round_no += 1
		if round_no > 30 and result.is_empty():
			result = "draw"
			log_event("Night falls. Both companies withdraw.")
	side = 1 - side
	for u in units:
		if living(u) and u.side == side:
			u.ap = MAX_AP
			u.fatigue = maxi(0, int(u.fatigue) - 25)
			u.guard = false
	check_result()

func check_result() -> void:
	if not result.is_empty(): return
	var counts = [0, 0]
	for u in units:
		if fighting(u): counts[int(u.side)] += 1
	if counts[0] == 0: result = "defeat"
	elif counts[1] == 0: result = "victory"

func ai_step() -> void:
	if not result.is_empty(): return
	for u in units:
		if not living(u) or u.side != side or u.ap <= 0: continue
		var id = int(u.id)
		if u.routed:
			var routes = movement_map(id)
			var best = pos(u)
			var edge = 999
			for v in routes.values():
				var p: Vector2i = v.path.back()
				var e = mini(mini(p.x, W-1-p.x), mini(p.y, H-1-p.y))
				if e < edge:
					edge = e
					best = p
			if best != pos(u): move_unit(id, best)
			else: finish_unit(id)
			return
		if u.fatigue >= 65 and u.ap >= 4:
			recover(id)
			return
		var target = -1
		var target_score = -999.0
		for v in units:
			if can_attack(id, int(v.id)):
				var score = hit_chance(id, int(v.id)) + (1.0 - float(v.hp) / v.max_hp) * 40.0 + (10 if v.weapon == "bow" else 0)
				if score > target_score:
					target_score = score
					target = int(v.id)
		if target != -1:
			attack(id, target)
			return
		var moves = movement_map(id)
		var best_pos = pos(u)
		var best_score = ai_position_score(u, best_pos)
		for v in moves.values():
			var p: Vector2i = v.path.back()
			var score = ai_position_score(u, p) - float(v.cost) * 0.08
			if score > best_score + 0.01:
				best_score = score
				best_pos = p
		if best_pos != pos(u):
			move_unit(id, best_pos)
			return
		if not u.guard and guard_unit(id): return
		finish_unit(id)
		return
	end_turn()

func ai_position_score(u: Dictionary, p: Vector2i) -> float:
	var nearest = 99
	for v in units:
		if fighting(v) and v.side != u.side: nearest = mini(nearest, distance(p, pos(v)))
	var score = -float(distance(p, FORD)) * 2.2 if objective != "eliminate" else -float(nearest)*2.5
	if u.weapon == "bow": score -= absf(nearest - 4) * 3.5
	else: score -= maxf(0, nearest - (2 if u.weapon == "spear" else 1)) * 1.4
	score += float(tiles[key(p)].height) * 0.8
	if objective != "eliminate" and distance(p, FORD) <= 1: score += 3.0
	return score

func log_event(message: String) -> void:
	events.append(message)
	if events.size() > 100: events.pop_front()

func snapshot() -> Dictionary:
	return {"version":2, "map":map_id, "objective":objective, "units":units.duplicate(true), "round":round_no, "side":side, "result":result, "rng":rng_state, "seed":seed_value, "held":held.duplicate(), "events":events.duplicate(), "commands":commands.duplicate(true)}

func restore(data: Variant) -> bool:
	if not data is Dictionary: return false
	data = normalize_json_numbers(data)
	for field in ["version", "units", "round", "side", "result", "rng", "seed", "held", "events", "commands"]:
		if not data.has(field): return false
	for field in ["version", "round", "side", "rng", "seed"]:
		if not data[field] is int: return false
	if not data.version in [1, 2] or not data.units is Array or data.units.size() != 12: return false
	if not data.side in [0, 1] or data.round < 1 or data.round > 31: return false
	if data.rng <= 0 or data.rng >= 2147483647 or data.seed <= 0: return false
	if not data.result in ["", "victory", "defeat", "draw"]: return false
	if not data.held is Array or data.held.size() != 2: return false
	for value in data.held:
		if not value is int or value < 0 or value > 3: return false
	if not data.events is Array or not data.commands is Array: return false
	for value in data.events:
		if not value is String: return false
	var map_name = data.get("map", "ford")
	var mission = data.get("objective", "hold")
	if not map_name in ["ford", "forest", "ridge"] or not mission in ["hold", "eliminate", "defend", "escort"]: return false
	var terrain_check = get_script().new()
	terrain_check.setup(int(data.seed), map_name, mission)
	var occupied: Dictionary = {}
	for i in data.units.size():
		var u = data.units[i]
		if not u is Dictionary: return false
		for field in ["id", "name", "title", "side", "q", "r", "weapon", "shield", "skill", "defense", "hp", "max_hp", "armor", "max_armor", "padding", "max_padding", "helmet", "max_helmet", "morale", "fatigue", "ap", "guard", "routed", "escaped", "kills"]:
			if not u.has(field): return false
		for field in ["id", "side", "q", "r", "skill", "defense", "hp", "max_hp", "armor", "max_armor", "padding", "max_padding", "helmet", "max_helmet", "morale", "fatigue", "ap", "kills"]:
			if not u[field] is int: return false
		for field in ["shield", "guard", "routed", "escaped"]:
			if not u[field] is bool: return false
		for field in ["name", "title", "weapon"]:
			if not u[field] is String: return false
		if u.id != i or not weapons.has(u.weapon) or u.side != (0 if i < 6 else 1): return false
		if u.q < 0 or u.q >= W or u.r < 0 or u.r >= H or u.hp < 0 or u.ap < 0 or u.ap > MAX_AP or u.fatigue < 0 or u.fatigue > 100: return false
		if u.max_hp <= 0 or u.hp > u.max_hp or u.armor < 0 or u.padding < 0 or u.helmet < 0 or u.morale < 0 or u.morale > 100: return false
		if u.hp > 0 and not u.escaped:
			if terrain_check.tiles[key(pos(u))].terrain == "water": return false
			if occupied.has(key(pos(u))): return false
			occupied[key(pos(u))] = true
	setup(int(data.seed), map_name, mission)
	units = data.units.duplicate(true)
	round_no = int(data.round)
	side = int(data.side)
	result = str(data.result)
	rng_state = int(data.rng)
	held = data.held.duplicate()
	events = data.events.duplicate()
	commands = data.commands.duplicate(true)
	return true

func normalize_json_numbers(value: Variant) -> Variant:
	# Godot JSON parses every number as float. Array membership is type-sensitive.
	# Battle state contains integers only; normalize exact integers before validation.
	if value is float and is_finite(value) and value == floor(value): return int(value)
	if value is Array:
		var out: Array = []
		for entry in value: out.append(normalize_json_numbers(entry))
		return out
	if value is Dictionary:
		var out: Dictionary = {}
		for k in value: out[k] = normalize_json_numbers(value[k])
		return out
	return value
