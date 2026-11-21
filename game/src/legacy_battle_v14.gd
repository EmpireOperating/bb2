extends RefCounted
const Arsenal = preload("res://src/legacy_arsenal_v18.gd")
var weapon_rules = false
var individual = false
var active_id = -1
var turn_queue: Array = []
var delayed: Array = []
var activated: Array = []
var finished: Array = []
var waited: Array = []
var turn_scores: Dictionary = {}
const Armor = preload("res://src/armor.gd")
var armor_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy_equipment_v14.json"))
const People = preload("res://src/legacy_people_v14.gd")
signal combat_feedback(event: Dictionary)
## Pure battle rules. No nodes, animations, input, wall clock or global random state.
## All player and AI actions go through the same validated command methods.

const Progression = preload("res://src/legacy_progression_v16.gd")
const W = 13
const H = 9
const MAX_AP = 9
const FORD = Vector2i(6, 4)
const DIRECTIONS = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
var weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy_weapons_v14.json"))
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
const ORDERS = {"free":"Free order", "line":"Shield line", "loose":"Loose order"}
var enemy_plan: Dictionary = {}
var shared_line: Array = []

func setup(seed_number: int = 7391, field: String = "ford", mission: String = "hold", advanced_weapons: bool = false, individual_turns: bool = false) -> void:
	weapon_rules = advanced_weapons
	individual = individual_turns
	active_id = -1; turn_queue = []; delayed = []; activated = []; finished = []; waited = []; turn_scores = {}
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
	enemy_plan = {}
	shared_line = []
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
	for u in units:
		initialize_arms(u)
		if individual: initialize_stats(u)
	if individual: start_round()
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
	units.append({"id":units.size(), "name":n, "title":title, "side":team, "q":p.x, "r":p.y, "weapon":weapon, "shield":shield, "skill":skill, "defense":defense, "hp":hp, "max_hp":hp, "armor":armor, "max_armor":armor, "padding":30, "max_padding":30, "helmet":40, "max_helmet":40, "morale":85 if team == 0 else 75, "fatigue":0, "ap":MAX_AP, "guard":false, "routed":false, "escaped":false, "kills":0, "perks":[], "scars":[], "damage_taken":0, "worst_hit":0, "worst_head":false, "last_attacker":"", "order":"free", "comrades":[], "strain_penalty":0, "grief_penalty":0, "endurance":25,"mobility":3,"resolve":0,"temperament":"none", "armor_parts":[], "load":0})

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

func shield_neighbors(u: Dictionary, from: Vector2i) -> Array:
	var allies: Array = []
	for v in units:
		if v.id != u.id and fighting(v) and v.side == u.side and v.shield and v.order != "loose" and distance(pos(v),from) == 1:
			allies.append(v.id)
	return allies

func shield_support(u: Dictionary) -> int:
	if not fighting(u) or not u.shield or u.order == "loose": return 0
	return mini(2,shield_neighbors(u,pos(u)).size())*5

func line_support(u: Dictionary) -> int:
	if not fighting(u) or not u.shield or u.order != "line": return 0
	var linked = shield_neighbors(u,pos(u)).filter(func(id): return units[id].order == "line")
	return mini(2,linked.size())*5

func spaced(u: Dictionary, from: Vector2i) -> bool:
	for v in units:
		if v.id != u.id and fighting(v) and v.side == u.side and distance(from,pos(v)) == 1: return false
	return true

func spear_screen(u: Dictionary, v: Dictionary) -> int:
	if Arsenal.family(u.weapon) != "spear" or u.order != "line" or not fighting(u) or distance(pos(u),pos(v)) != 2: return -1
	for p in neighbors(pos(u)):
		var id = at(p)
		if id >= 0 and units[id].side == u.side and fighting(units[id]) and units[id].shield and units[id].order == "line" and distance(p,pos(v)) == 1:
			return id
	return -1

func order_cost(id: int, order: String) -> String:
	if not ORDERS.has(order): return "Unknown order."
	if not can_act(id) or not fighting(units[id]): return "Soldier cannot receive orders now."
	var u: Dictionary = units[id]
	if u.order == order: return "%s already has that order." % u.name
	if order == "line" and not u.shield and Arsenal.family(u.weapon) != "spear": return "%s needs a shield or spear for the line." % u.name
	if u.ap < 2 or u.fatigue+4 > fatigue_max(u): return "%s needs 2 AP and 4 free fatigue." % u.name
	return ""

func order_preview(ids: Array, order: String) -> String:
	if ids.is_empty(): return "Select at least one soldier."
	var seen = {}
	for id in ids:
		if not id is int or seen.has(id): return "Invalid or repeated soldier."
		seen[id] = true
		var reason = order_cost(id,order)
		if not reason.is_empty(): return reason
	return ""

func set_order(ids: Array, order: String) -> bool:
	if not order_preview(ids,order).is_empty(): return false
	var sorted = ids.duplicate()
	sorted.sort()
	for id in sorted:
		units[id].ap -= 2
		units[id].fatigue += 4
		units[id].order = order
		units[id].guard = false
	commands.append(["order",sorted,order])
	log_event("%s: %s (2 AP / 4 fatigue each)." % [", ".join(sorted.map(func(id): return units[id].name)),ORDERS[order]])
	return true

func movement_cost(u: Dictionary, a: Vector2i, b: Vector2i) -> int:
	return step_cost(a,b)+(1 if u.order == "line" and not u.routed else 0)

func advance_preview(ids: Array, direction: int) -> Dictionary:
	var preview = {"ok":false,"reason":"Select soldiers and a direction.","steps":[]}
	if ids.is_empty() or direction < 0 or direction >= 6: return preview
	var seen = {}
	for id in ids:
		if not id is int or seen.has(id) or not can_act(id) or not fighting(units[id]):
			preview.reason = "Every selected soldier must be able to act."
			return preview
		seen[id] = true
	for id in ids:
		var u: Dictionary = units[id]
		var target = offset(axial(pos(u))+DIRECTIONS[direction])
		var cost = movement_cost(u,pos(u),target)
		var reason = ""
		if not adjacent_enemies(u,pos(u)).is_empty(): reason = "Engaged: use individual Withdraw."
		elif cost >= 999: reason = "Water or field edge blocks the advance."
		elif at(target) >= 0 and not seen.has(at(target)): reason = "Destination occupied outside this group."
		elif cost > u.ap or cost*People.move_rate(u)+u.fatigue > fatigue_max(u): reason = "Insufficient AP or free fatigue."
		preview.steps.append({"id":id,"q":target.x,"r":target.y,"cost":cost,"reason":reason})
		if not reason.is_empty() and preview.reason == "Select soldiers and a direction.": preview.reason = u.name+": "+reason
	preview.ok = preview.steps.all(func(step): return step.reason.is_empty())
	if preview.ok: preview.reason = "One hex together. Each soldier pays their own terrain and order cost."
	return preview

func advance_group(ids: Array, direction: int) -> bool:
	var preview = advance_preview(ids,direction)
	if not preview.ok: return false
	var links = linked_shields()
	var sorted = ids.duplicate()
	sorted.sort()
	for step in preview.steps:
		var u: Dictionary = units[step.id]
		u.ap -= step.cost
		u.fatigue += step.cost*People.move_rate(u)
		u.q = step.q
		u.r = step.r
		u.guard = false
		if weapon_rules: cancel_stance(u)
	if weapon_rules:
		for id in sorted: brace_reactions(id,offset(axial(pos(units[id]))-DIRECTIONS[direction]))
	commands.append(["advance",sorted,direction])
	log_event("%d soldiers advance together; formation orders remain." % ids.size())
	report_broken_links(links)
	check_result()
	return true

func step_cost(a: Vector2i, b: Vector2i) -> int:
	if not tiles.has(key(b)) or tiles[key(b)].terrain == "water": return 999
	var cost = 4 if tiles[key(b)].terrain in ["mud", "forest"] else 2
	return cost + maxi(0, int(tiles[key(b)].height) - int(tiles[key(a)].height))

func can_act(id: int) -> bool:
	return id >= 0 and id < units.size() and result.is_empty() and living(units[id]) and units[id].side == side and (not individual or id == active_id)

func movement_map(id: int, preview_budget: int = -1) -> Dictionary:
	if not can_act(id): return {}
	var u: Dictionary = units[id]
	var start = pos(u)
	var budget = mini(int(u.ap), (fatigue_max(u) - int(u.fatigue)) / People.move_rate(u))
	if preview_budget >= 0: budget = preview_budget
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
			var step = movement_cost(u, p, n)
			if step >= 999: continue
			var new_cost = int(costs[key(p)]) + step
			if new_cost <= budget and (not costs.has(key(n)) or new_cost < int(costs[key(n)])):
				costs[key(n)] = new_cost
				paths[key(n)] = paths[key(p)] + [n]
				if not frontier.has(n): frontier.append(n)
	var out: Dictionary = {}
	for k in paths:
		if k != key(start): out[k] = {"cost":costs[k], "path":paths[k]}
	return out

func movement_block_reason(id: int, target: Vector2i) -> String:
	if not can_act(id): return "Soldier cannot move now."
	var u: Dictionary = units[id]
	if not tiles.has(key(target)): return "Outside the battlefield."
	if pos(u) == target: return "Already on that hex."
	if tiles[key(target)].terrain == "water": return "Deep water is impassable."
	if at(target) >= 0: return "Destination occupied by %s." % units[at(target)].name
	var foes = adjacent_enemies(u,pos(u))
	if not u.routed and not foes.is_empty(): return "Engaged by %s. Use Withdraw to move." % units[foes[0]].name
	# Read-only route search separates resource shortages from blocked routes.
	var routes = movement_map(id,W*H*8)
	if not routes.has(key(target)): return "No open route: units, terrain or enemy control block the way."
	var cost = routes[key(target)].cost
	if cost > u.ap: return "Needs %d AP to reach that hex; %d available." % [cost,u.ap]
	var fatigue = cost*People.move_rate(u)
	if fatigue+u.fatigue > fatigue_max(u): return "Needs %d free fatigue to move; %d available." % [fatigue,maxi(0,fatigue_max(u)-u.fatigue)]
	return ""

func move_unit(id: int, target: Vector2i) -> bool:
	var reachable = movement_map(id)
	if not reachable.has(key(target)): return false
	var links = linked_shields()
	var u: Dictionary = units[id]
	if weapon_rules:
		cancel_stance(u)
		for step in reachable[key(target)].path:
			var previous = pos(u)
			var cost = movement_cost(u,previous,step)
			u.ap -= cost; u.fatigue += cost*People.move_rate(u)
			u.q = step.x; u.r = step.y; u.guard = false
			if brace_reactions(id,previous) or not living(u): break
	else:
		var cost = int(reachable[key(target)].cost)
		u.ap -= cost
		u.fatigue += cost * People.move_rate(u)
		u.q = target.x
		u.r = target.y
		u.guard = false
	commands.append(["move", id, target.x, target.y])
	report_broken_links(links)
	if u.routed and (u.q == 0 or u.q == W - 1 or u.r == 0 or u.r == H - 1):
		u.escaped = true
		log_event("%s escapes the field." % u.name)
	check_result()
	return true

func line_block_reason(a: Vector2i, b: Vector2i, allied_side: int = -1) -> String:
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
		if tiles.has(key(p)) and tiles[key(p)].terrain == "forest": return "Trees block the shot."
		var occupant = at(p)
		if occupant >= 0:
			# The shooter can fire over their immediately adjacent friendly rank.
			# Other bodies still block; this rule is identical for both sides.
			if units[occupant].side == allied_side and distance(a,p) == 1: continue
			return "Shot blocked by %s (%s)." % [units[occupant].name,"ally farther down the lane" if units[occupant].side == allied_side else "intervening unit"]
	return ""

func line_clear(a: Vector2i, b: Vector2i, allied_side: int = -1) -> bool:
	return line_block_reason(a,b,allied_side).is_empty()

func in_range(u: Dictionary, v: Dictionary, special: bool = false) -> bool:
	var w: Dictionary = weapons[u.weapon]
	var d = distance(pos(u), pos(v))
	if d < int(w.get("min_range",1)) or d > int(w.reach): return false
	if special and Arsenal.family(u.weapon) == "axe" and d != 1: return false
	if u.weapon in Arsenal.RANGED:
		return adjacent_enemies(u, pos(u)).is_empty() and line_clear(pos(u), pos(v),int(u.side) if weapon_rules else -1)
	# Spears can thrust past allies, but not through enemies.
	if d == 2:
		for p in neighbors(pos(u)):
			if distance(p, pos(v)) == 1 and tiles[key(p)].terrain != "water":
				var occupant = at(p)
				if occupant == -1 or units[occupant].side == u.side: return true
		return false
	return true

func reach_block_reason(u: Dictionary, v: Dictionary, special: bool = false) -> String:
	var w: Dictionary = weapons[u.weapon]
	var gap = distance(pos(u),pos(v))
	var minimum = int(w.get("min_range",1))
	var maximum = 1 if special and Arsenal.family(u.weapon) == "axe" else int(w.reach)
	if gap < minimum: return "Too close: %s needs at least %d hexes." % [w.name,minimum]
	if gap > maximum: return "Out of reach: %d hexes away; this action reaches %d." % [gap,maximum]
	if u.weapon in Arsenal.RANGED:
		var foes = adjacent_enemies(u,pos(u))
		if not foes.is_empty(): return "Engaged by %s. Withdraw before shooting." % units[foes[0]].name
		return line_block_reason(pos(u),pos(v),int(u.side) if weapon_rules else -1)
	if not in_range(u,v,special): return "No open or allied lane for the thrust."
	return ""

func hit_breakdown(a: int, b: int, special: bool = false) -> Dictionary:
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapons[u.weapon]
	if weapon_rules and special and Arsenal.family(u.weapon) == "axe":
		var value = 90+(5 if adjacent_enemies(v,pos(v)).size() >= 2 else 0)
		return {"parts":[{"name":"Shield split", "value":value}],"raw":value,"chance":value}
	var ranged: bool = u.weapon in Arsenal.RANGED
	var attack_skill: int = u.get("ranged_skill",u.skill) if individual and ranged else u.skill
	var defense_skill: int = v.get("ranged_defense",v.defense) if individual and ranged else v.defense
	if individual:
		attack_skill = floori(attack_skill*morale_multiplier(u))
		defense_skill = floori(defense_skill*morale_multiplier(v))
	var parts = [{"name":("Ranged skill + weapon" if ranged else "Melee skill + weapon") if individual else "Skill + weapon", "value":attack_skill+int(w.skill)}, {"name":"Ranged defence" if individual and ranged else "Melee defence" if individual else "Defender skill", "value":-defense_skill}]
	var bonuses = [
		["Temperament",temperament_accuracy(u)],
		["Cautious defender",-5 if v.temperament == "cautious" else 0],
		["Weapon handling",5 if "weapon_drill" in u.perks else 0],
		["Elevation",(int(tiles[key(pos(u))].height)-int(tiles[key(pos(v))].height))*12],
		["Adjacent shields",-shield_support(v)],
		["Linked shield line",-line_support(v)],
		["Shield",-10 if v.shield else 0],
		["Guard",-((30 if "shield_drill" in v.perks else 20) if v.shield else 10) if v.guard else 0],
		["Outnumbered",maxi(0,adjacent_enemies(v,pos(v)).size()-1)*8],
		["Spear screen",10 if spear_screen(u,v) >= 0 else 0],
		["Loose spacing",-12 if u.weapon in Arsenal.RANGED and v.order == "loose" and spaced(v,pos(v)) else 0],
		["Loose melee exposure",5 if not u.weapon in Arsenal.RANGED and v.order == "loose" else 0],
		["Ranged distance",-maxi(0,distance(pos(u),pos(v))-3)*7 if u.weapon in Arsenal.RANGED else 0],
		["Shaken attacker",-12 if not individual and u.morale < 35 else 0],
		["Tired attacker",-10 if not individual and u.fatigue >= 75 else 0],
		["Fleeing target",20 if v.routed else 0]]
	for pair in bonuses:
		if pair[1] != 0: parts.append({"name":pair[0],"value":pair[1]})
	if weapon_rules and special:
		var modifier = {"mace":-10,"hammer":-5,"dagger":-20,"polearm":-10,"bow":15}.get(Arsenal.family(u.weapon),0)
		if modifier != 0: parts.append({"name":Arsenal.special(u.weapon).name,"value":modifier})
	if individual:
		var effective_defence = defense_skill+shield_support(v)+line_support(v)+(10 if v.shield else 0)+(((30 if "shield_drill" in v.perks else 20) if v.shield else 10) if v.guard else 0)+(5 if v.temperament == "cautious" else 0)
		if effective_defence > 50: parts.append({"name":"Defence above 50: half value","value":ceili((effective_defence-50)*0.5)})
	var total = 0
	for part in parts: total += part.value
	return {"parts":parts,"raw":total,"chance":clampi(total,5,95)}

func hit_chance(a: int, b: int, special: bool = false) -> int:
	return hit_breakdown(a,b,special).chance

func can_attack(a: int, b: int) -> bool:
	if weapon_rules: return weapon_action_reason(a,false,b).is_empty()
	if not can_act(a) or b < 0 or b >= units.size(): return false
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapons[u.weapon]
	return not u.routed and living(v) and u.side != v.side and u.ap >= w.ap and u.fatigue + attack_fatigue(u) <= fatigue_max(u) and in_range(u, v)

func attack_block_reason(a: int, b: int) -> String:
	if weapon_rules:
		var reason = weapon_action_reason(a,false,b)
		return reason if not reason.is_empty() else "Legal attack · %d AP / %d fatigue" % [weapons[units[a].weapon].ap,attack_fatigue(units[a])]
	if not can_act(a): return "Attacker cannot act now."
	if b < 0 or b >= units.size() or not living(units[b]) or units[a].side == units[b].side: return "Choose a living enemy."
	var u: Dictionary = units[a]
	if u.routed: return "Fleeing soldiers cannot attack."
	if u.ap < weapons[u.weapon].ap: return "Insufficient AP."
	if u.fatigue+attack_fatigue(u) > fatigue_max(u): return "Insufficient free fatigue."
	var reason = reach_block_reason(u,units[b])
	if not reason.is_empty(): return reason
	return "Legal attack · %d AP / %d fatigue" % [weapons[u.weapon].ap,attack_fatigue(u)]

func attack(a: int, b: int) -> bool:
	if weapon_rules: return use_weapon(a,false,b)
	if not can_attack(a, b): return false
	var u: Dictionary = units[a]
	var w: Dictionary = weapons[u.weapon]
	u.ap -= int(w.ap)
	u.fatigue += attack_fatigue(u)
	u.guard = false
	commands.append(["attack", a, b])
	strike(a, b)
	check_result()
	return true

func strike(a: int, b: int, special: bool = false, reaction: bool = false) -> bool:
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapons[u.weapon]
	var chance = hit_chance(a, b, special)
	if roll(1, 100) > chance:
		log_event("%s misses %s (%d%%)." % [u.name, v.name, chance])
		combat_feedback.emit({"id":b,"kind":"miss","text":"MISS · %d%%" % chance})
		if weapon_rules and not reaction and not u.weapon in Arsenal.RANGED and distance(pos(u),pos(v)) == 1 and v.get("stance","") == "riposte" and v.reactions > 0 and fighting(v) and v.fatigue+6 <= fatigue_max(v):
			v.reactions -= 1; v.fatigue += 6
			log_event(v.name+" ripostes.")
			strike(b,a,false,true)
		return false
	var links = linked_shields()
	if weapon_rules and special and Arsenal.family(u.weapon) == "axe":
		var loss = mini(24,int(v.arms.shield.condition))
		v.arms.shield.condition -= loss
		sync_arms(v)
		if not v.shield and v.order == "line" and Arsenal.family(v.weapon) != "spear": v.order = "free"
		log_event("%s splits %s’s shield: -%d condition%s." % [u.name,v.name,loss,"; shield broken" if not v.shield else ""])
		combat_feedback.emit({"id":b,"kind":"shield","text":"-%d SHIELD" % loss})
		report_broken_links(links)
		return true
	var raw = roll(int(w.min), int(w.max))
	var head = roll(1, 100) <= 20
	if weapon_rules and special and Arsenal.family(u.weapon) in ["hammer","dagger"]: head = false
	if weapon_rules and special: raw = roundi(raw*{"mace":0.75,"dagger":0.8,"polearm":0.65,"bow":1.15}.get(Arsenal.family(u.weapon),1.0))
	if head: raw = roundi(raw * 1.3)
	var layer = "helmet" if head else "armor"
	var armor_factor = float(w.armor)*(2.0 if weapon_rules and special and Arsenal.family(u.weapon) == "hammer" else 1.0)
	var puncture = weapon_rules and special and Arsenal.family(u.weapon) == "dagger"
	var armor_loss = 0 if puncture else mini(int(v[layer]), roundi(raw * armor_factor))
	var absorbed = mini(roundi(raw * (1.0 - float(w.pierce))), roundi(float(armor_loss) / armor_factor * 0.72))
	v[layer] -= armor_loss
	Armor.damage_parts(v,layer,armor_loss)
	var damage = raw - absorbed
	var padding_loss = 0
	if not head and not puncture:
		padding_loss = mini(int(v.padding), roundi(damage * 0.5))
		v.padding -= padding_loss
		Armor.damage_parts(v,"padding",padding_loss)
		damage -= padding_loss
	if weapon_rules and special and Arsenal.family(u.weapon) == "hammer": damage = maxi(1,roundi(damage*0.5))
	var actual = mini(v.hp,damage)
	v.damage_taken += actual
	v.last_attacker = u.name
	if actual > v.worst_hit:
		v.worst_hit = actual
		v.worst_head = head
	v.hp = maxi(0, int(v.hp) - damage)
	log_event("%s hits %s: %d HP / %d %s / %d padding." % [u.name, v.name, actual, armor_loss, "helm" if head else "mail",padding_loss])
	combat_feedback.emit({"id":b,"kind":"hit","hp":actual,"armor":armor_loss,"padding":padding_loss,"layer":layer,"text":"-%d HP / -%d %s" % [actual,armor_loss,"helm" if head else "mail"]})
	if v.hp == 0:
		u.kills += 1
		if individual:
			for other in units:
				if other.side == u.side and fighting(other) and distance(pos(other),pos(v)) <= 3: morale_check(other,0,"enemy fell",true)
		log_event("%s falls. The line shudders." % v.name)
		combat_feedback.emit({"id":b,"kind":"death","text":"FALLEN"})
		for other in units:
			if fighting(other) and other.side == v.side and distance(pos(other), pos(v)) <= 3: morale_loss(other, 24+(8 if v.id in other.comrades else 0),"comrade fell" if v.id in other.comrades else "ally fell")
	elif damage >= 8:
		morale_loss(v, 10 + (8 if v.hp < v.max_hp / 3.0 else 0),"severe wound" if v.hp < v.max_hp / 3.0 else "flesh wound")
	if weapon_rules and special and fighting(v):
		if Arsenal.family(u.weapon) == "mace":
			v.ap = maxi(0,v.ap-2); v.stagger = 2
			log_event(v.name+" is staggered: -2 current and next-turn AP.")
			combat_feedback.emit({"id":b,"kind":"stagger","text":"STAGGER · -2 AP"})
		elif Arsenal.family(u.weapon) == "polearm":
			var destination = hook_tile(u,v)
			if destination != pos(v):
				v.q = destination.x; v.r = destination.y; v.guard = false; cancel_stance(v)
				log_event(v.name+" is dragged one hex out of position.")
	report_broken_links(links)
	return true

func morale_loss(u: Dictionary, amount: int, cause: String = "shock") -> void:
	if individual:
		morale_check(u,amount,cause)
		return
	if not fighting(u): return
	amount = maxi(1,amount-comrade_support(u)-u.resolve-(3 if u.temperament == "stoic" else 0))
	if "steadfast" in u.perks: amount = ceili(amount*0.6)
	var before: int = u.morale
	u.morale = maxi(0, int(u.morale) - amount)
	log_event("%s: -%d morale (%s); %d remains." % [u.name,before-u.morale,cause,u.morale])
	combat_feedback.emit({"id":u.id,"kind":"morale","amount":before-u.morale,"text":"-%d morale · %s" % [before-u.morale,cause]})
	if u.morale <= 15:
		u.routed = true
		u.order = "free"
		u.guard = false
		log_event("%s breaks and flees!" % u.name)
		combat_feedback.emit({"id":u.id,"kind":"route","text":"ROUTING"})
		for other in units:
			if other.side == u.side and other.id != u.id and fighting(other) and distance(pos(u), pos(other)) <= 2:
				morale_loss(other, 10,"nearby panic")

func guard_unit(id: int) -> bool:
	if not can_act(id): return false
	var u: Dictionary = units[id]
	if u.routed or u.ap < 4 or u.fatigue+guard_fatigue(u) > fatigue_max(u) or u.guard: return false
	u.ap -= 4
	u.fatigue += guard_fatigue(u)
	u.guard = true
	if weapon_rules: cancel_stance(u)
	commands.append(["guard", id])
	log_event("%s %s." % [u.name, "raises a shieldwall" if u.shield else "braces"])
	return true

func recover(id: int) -> bool:
	if not can_act(id) or units[id].ap < 4 or units[id].routed: return false
	if weapon_rules: cancel_stance(units[id])
	var before: int = units[id].fatigue
	units[id].fatigue = maxi(0, int(units[id].fatigue) - (50 if "endurance" in units[id].perks else 35))
	units[id].ap = 0
	commands.append(["recover", id])
	log_event("%s catches a breath." % units[id].name)
	combat_feedback.emit({"id":id,"kind":"recover","text":"-%d fatigue" % [before-units[id].fatigue]})
	return true

func withdraw(id: int, target: Vector2i) -> bool:
	if not can_act(id) or units[id].ap < 4 or units[id].fatigue+12 > fatigue_max(units[id]): return false
	var u: Dictionary = units[id]
	if distance(pos(u), target) != 1 or at(target) != -1 or step_cost(pos(u), target) >= 999: return false
	var foes = adjacent_enemies(u, pos(u))
	if foes.is_empty(): return false
	u.ap -= 4
	u.fatigue += 12
	u.guard = false
	if weapon_rules: cancel_stance(u)
	commands.append(["withdraw", id, target.x, target.y])
	for foe in foes:
		if living(u) and (not weapon_rules or (not units[foe].weapon in Arsenal.RANGED and in_range(units[foe],u))): strike(int(foe), id,false,true)
	var links = linked_shields()
	if living(u):
		var previous = pos(u)
		u.q = target.x
		u.r = target.y
		if weapon_rules: brace_reactions(id,previous)
	report_broken_links(links)
	check_result()
	return true

func finish_unit(id: int) -> void:
	if individual:
		if can_act(id):
			commands.append(["finish",id])
			complete_activation()
		return
	if can_act(id):
		units[id].ap = 0
		commands.append(["finish", id])

func end_turn() -> void:
	if individual:
		finish_unit(active_id)
		return
	if not result.is_empty(): return
	commands.append(["end", side])
	if side == 1:
		record_shared_line()
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
			u.ap = MAX_AP-(u.get("stagger",0) if weapon_rules else 0)
			if weapon_rules: u.stagger = 0; cancel_stance(u)
			u.fatigue = maxi(0, int(u.fatigue) - People.recovery(u))
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
	if individual and advance_if_spent(): return
	if not result.is_empty(): return
	if side == 1:
		coordinated_step()
		return
	for u in units:
		if not can_act(u.id) or u.ap <= 0: continue
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
		if weapon_rules and ai_weapon_step(id): return
		if u.fatigue >= fatigue_max(u)*0.65 and u.ap >= 4:
			recover(id)
			return
		var target = -1
		var target_score = -999.0
		for v in units:
			if can_attack(id, int(v.id)):
				var score = hit_chance(id, int(v.id)) + (1.0 - float(v.hp) / v.max_hp) * 40.0 + (10 if v.weapon in Arsenal.RANGED else 0)
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
	if u.weapon in Arsenal.RANGED: score -= absf(nearest - 4) * 3.5
	else: score -= maxf(0, nearest - (2 if Arsenal.family(u.weapon) in ["spear","polearm"] else 1)) * 1.4
	score += float(tiles[key(p)].height) * 0.8
	if objective != "eliminate" and distance(p, FORD) <= 1: score += 3.0
	return score

func plan_enemy_turn() -> void:
	var roles = {}
	for u in units:
		if u.side != 1: continue
		roles[str(u.id)] = "archer" if u.weapon in Arsenal.RANGED else ("support" if Arsenal.family(u.weapon) in ["spear","polearm"] else ("screen" if u.shield else "flank"))
	var focus = -1
	var best = -INF
	for v in units:
		if not fighting(v) or v.side != 0: continue
		var nearest = 99
		for u in units:
			if fighting(u) and u.side == 1: nearest = mini(nearest,distance(pos(u),pos(v)))
		var score = (1.0-float(v.hp)/v.max_hp)*24-nearest*3+(12 if v.weapon in Arsenal.RANGED else 0)
		score += 8 if spaced(v,pos(v)) else 0
		score += adjacent_enemies(v,pos(v)).size()*7
		score -= (shield_support(v)+line_support(v))*0.4
		if objective in ["defend","escort"]:
			score -= distance(pos(v),FORD)*4
			if distance(pos(v),FORD) <= 1: score += 60
		elif objective != "eliminate" and distance(pos(v),FORD) <= 1: score += 10
		if score > best: best = score; focus = v.id
	enemy_plan = {"round":round_no,"focus":focus,"roles":roles}
	if focus >= 0: log_event("Enemy pressure turns toward %s; shields screen, spears support." % units[focus].name)

func enemy_role(u: Dictionary) -> String:
	return enemy_plan.get("roles",{}).get(str(u.id),"archer" if u.weapon in Arsenal.RANGED else ("support" if Arsenal.family(u.weapon) in ["spear","polearm"] else ("screen" if u.shield else "flank")))

func coordinated_step() -> void:
	if enemy_plan.is_empty() or enemy_plan.round != round_no or enemy_plan.focus < 0 or not fighting(units[enemy_plan.focus]): plan_enemy_turn()
	var actors = units.filter(func(u): return can_act(u.id) and u.side == 1 and u.ap > 0)
	actors.sort_custom(func(a,b):
		var pa = enemy_priority(a)
		var pb = enemy_priority(b)
		return pa < pb if pa != pb else a.id < b.id)
	for u in actors:
		var id = int(u.id)
		var role = enemy_role(u)
		if u.routed:
			var best = pos(u)
			var edge = 999
			for route in movement_map(id).values():
				var p: Vector2i = route.path.back()
				var d = mini(mini(p.x,W-1-p.x),mini(p.y,H-1-p.y))
				if d < edge: best = p; edge = d
			if best != pos(u): move_unit(id,best)
			else: finish_unit(id)
			return
		if weapon_rules and ai_weapon_step(id): return
		# A trapped archer must pay for an ordinary, risky withdrawal.
		if role == "archer" and not adjacent_enemies(u,pos(u)).is_empty() and u.ap >= 4 and u.fatigue+12 <= fatigue_max(u):
			var best = pos(u)
			var score = -INF
			for p in neighbors(pos(u)):
				if at(p) >= 0 or step_cost(pos(u),p) >= 999 or not adjacent_enemies(u,p).is_empty(): continue
				var value = coordinated_position_score(u,p)
				if value > score: score = value; best = p
			if best != pos(u): withdraw(id,best); return
		if u.fatigue >= fatigue_max(u)*0.65 and u.ap >= 4: recover(id); return
		# Orders consume the same AP and fatigue as company orders.
		if u.order == "free" and role in ["screen","support"] and u.ap == MAX_AP and not shield_neighbors(u,pos(u)).is_empty() and (not objective in ["defend","escort"] or distance(pos(u),FORD) <= 2):
			if set_order([id],"line"): return
		var target = -1
		var target_score = -INF
		for v in units:
			if can_attack(id,v.id):
				var score = hit_chance(id,v.id)+(1.0-float(v.hp)/v.max_hp)*35+(18 if v.id == enemy_plan.focus else 0)
				if score > target_score: target_score = score; target = v.id
		if target >= 0: attack(id,target); return
		var best_pos = pos(u)
		var best_score = coordinated_position_score(u,best_pos)
		for route in movement_map(id).values():
			var p: Vector2i = route.path.back()
			var score = coordinated_position_score(u,p)-route.cost*0.18
			# Preserve an attack after moving when possible; no free follow-up.
			if u.ap-route.cost < weapons[u.weapon].ap: score -= 2.5
			if score > best_score+0.01: best_score = score; best_pos = p
		if best_pos != pos(u): move_unit(id,best_pos); return
		if not u.guard and guard_unit(id): return
		finish_unit(id)
		return
	end_turn()

func enemy_priority(u: Dictionary) -> int:
	if u.routed: return 0
	if u.weapon in Arsenal.RANGED and not adjacent_enemies(u,pos(u)).is_empty(): return 1
	return {"screen":2,"support":3,"flank":4,"archer":5}[enemy_role(u)]

func coordinated_position_score(u: Dictionary, p: Vector2i) -> float:
	var role = enemy_role(u)
	var nearest = 99
	var enemies: Array = []
	for v in units:
		if fighting(v) and v.side != u.side:
			enemies.append(v)
			nearest = mini(nearest,distance(p,pos(v)))
	var focus: Dictionary = units[enemy_plan.focus] if not enemy_plan.is_empty() and enemy_plan.focus >= 0 else (enemies[0] if not enemies.is_empty() else u)
	var clone = u.duplicate()
	clone.q = p.x
	clone.r = p.y
	var assault = objective in ["defend","escort"]
	var score = -distance(p,FORD)*(5.5 if assault else 1.4) if objective != "eliminate" else 0.0
	score += tiles[key(p)].height*1.2
	var threats = adjacent_enemies(u,p).size()
	if role == "archer":
		score -= absf(nearest-4)*4.0+threats*22.0
		var shot = false
		for v in enemies:
			if in_range(clone,v): shot = true; break
		if shot: score += 7
		# Stay behind a friendly screen without intentionally blocking the shot.
		for ally in units:
			if ally.id != u.id and fighting(ally) and ally.side == u.side and ally.shield and distance(p,pos(ally)) <= 2 and distance(pos(ally),pos(focus)) < distance(p,pos(focus)):
				score += 4
				break
	elif role == "support":
		score -= absf(nearest-2)*3.0+threats*7.0
		if spear_screen(clone,focus) >= 0: score += 9
		for v in enemies:
			if in_range(clone,v): score += 3; break
	elif role == "flank":
		score -= maxf(0,distance(p,pos(focus))-1)*2.4
		# Exposed approaches and outnumbering are worth more than a defended wall.
		if distance(p,pos(focus)) == 1:
			score += 7+adjacent_enemies(focus,pos(focus)).size()*3
			score -= (shield_support(focus)+line_support(focus))*0.25
		score -= maxi(0,threats-1)*6
		for id in adjacent_enemies(u,p):
			if id != focus.id: score -= 8 if units[id].shield else 4
	else:
		score -= maxf(0,nearest-1)*2.0
		score += mini(2,shield_neighbors(u,p).size())*2.5
		# Cover the nearest approach to an allied archer when it is threatened.
		for ally in units:
			if fighting(ally) and ally.side == u.side and Arsenal.family(ally.weapon) == "bow" and distance(pos(ally),pos(focus)) <= 5:
				if distance(p,pos(ally)) <= 2 and distance(p,pos(focus)) < distance(pos(ally),pos(focus)): score += 4
				break
		score -= maxi(0,threats-2)*3
	if objective != "eliminate" and distance(p,FORD) <= 1 and role != "archer": score += 16 if assault else 4
	return score

func linked_shields() -> Array:
	return units.filter(func(u): return u.shield and line_support(u) > 0).map(func(u): return u.id)

func report_broken_links(before: Array) -> void:
	for id in before:
		var u: Dictionary = units[id]
		if fighting(u) and line_support(u) == 0:
			log_event("%s: shield-line link broken; ordered support lost." % u.name)
			combat_feedback.emit({"id":id,"kind":"gap","text":"LINE BROKEN"})

func comrade_support(u: Dictionary) -> int:
	if not fighting(u): return 0
	var count = 0
	for id in u.comrades:
		if fighting(units[id]) and distance(pos(u),pos(units[id])) <= 2: count += 1
	return mini(4,count*2)

func record_shared_line() -> void:
	for i in units.size():
		var a: Dictionary = units[i]
		if not fighting(a) or a.order != "line": continue
		for j in range(i+1,units.size()):
			var b: Dictionary = units[j]
			if not fighting(b) or a.side != b.side or b.order != "line" or distance(pos(a),pos(b)) != 1 or not (a.shield or b.shield): continue
			if [i,j] in shared_line: continue
			var threatened = units.any(func(foe): return fighting(foe) and foe.side != a.side and mini(distance(pos(foe),pos(a)),distance(pos(foe),pos(b))) <= 3)
			if threatened: shared_line.append([i,j])

func log_event(message: String) -> void:
	events.append(message)
	if events.size() > 100: events.pop_front()

func snapshot() -> Dictionary:
	return {"version":10,"individual":individual,"active_id":active_id,"turn_queue":turn_queue.duplicate(),"delayed":delayed.duplicate(),"activated":activated.duplicate(),"finished":finished.duplicate(),"waited":waited.duplicate(),"turn_scores":turn_scores.duplicate(), "weapon_rules":weapon_rules, "shared_line":shared_line.duplicate(true), "enemy_plan":enemy_plan.duplicate(true), "map":map_id, "objective":objective, "units":units.duplicate(true), "round":round_no, "side":side, "result":result, "rng":rng_state, "seed":seed_value, "held":held.duplicate(), "events":events.duplicate(), "commands":commands.duplicate(true)}

func restore(data: Variant) -> bool:
	if not data is Dictionary: return false
	data = normalize_json_numbers(data)
	for field in ["version", "units", "round", "side", "result", "rng", "seed", "held", "events", "commands"]:
		if not data.has(field): return false
	for field in ["version", "round", "side", "rng", "seed"]:
		if not data[field] is int: return false
	if not data.version in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] or not data.units is Array or data.units.size() != 12: return false
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
	var plan = data.get("enemy_plan",{}) if data.version >= 4 else {}
	if not plan is Dictionary: return false
	if data.version >= 4 and not data.has("enemy_plan"): return false
	if not plan.is_empty():
		if not plan.get("round") is int or plan.round < 1 or plan.round > data.round: return false
		if not plan.get("focus") is int or plan.focus < -1 or plan.focus > 5: return false
		if not plan.get("roles") is Dictionary or plan.roles.size() != 6: return false
		for id in range(6,12):
			if plan.roles.get(str(id),"") not in ["screen","support","flank","archer"]: return false
	var shared = data.get("shared_line") if data.version >= 5 else []
	if not shared is Array or shared.size() > 30: return false
	var links = {}
	for pair in shared:
		if not pair is Array or pair.size() != 2 or not pair[0] is int or not pair[1] is int: return false
		if pair[0] < 0 or pair[1] >= 12 or pair[0] >= pair[1] or pair[0]/6 != pair[1]/6 or links.has(str(pair)): return false
		links[str(pair)] = true
	var modern = data.get("weapon_rules",false) if data.version >= 8 else false
	if not modern is bool: return false
	var new_turns = data.get("individual",false) if data.version >= 10 else false
	if not new_turns is bool or (new_turns and not modern): return false
	if data.version >= 10 and not valid_turn_state(data): return false
	var equipment_ids = {}
	var occupied: Dictionary = {}
	for i in data.units.size():
		var u = data.units[i]
		if not u is Dictionary: return false
		if not u.get("weapon") is String or not weapons.has(u.weapon) or not u.get("shield") is bool: return false
		if data.version < 8: initialize_arms(u)
		if not Arsenal.valid_arms(u.get("arms"),armor_catalog): return false
		for item in u.arms.values():
			if item.is_empty(): continue
			if equipment_ids.has(item.id): return false
			equipment_ids[item.id] = true
		if u.get("weapon") != u.arms.weapon.definition or u.get("shield") != (not u.arms.shield.is_empty() and u.arms.shield.condition > 0): return false
		if not u.get("stance") in ["","riposte","brace"] or not u.get("reactions") is int or u.reactions < 0 or u.reactions > 2 or not u.get("stagger") is int or not u.stagger in [0,2]: return false
		if (u.stance == "riposte" and Arsenal.family(u.weapon) != "sword") or (u.stance == "brace" and Arsenal.family(u.weapon) != "spear"): return false
		if u.stance.is_empty() and u.reactions != 0: return false
		if data.version < 7: u["armor_parts"] = []; u["load"] = 0
		if not Armor.valid_battle_parts(u.get("armor_parts"),armor_catalog) or not u.get("load") is int or u.load < 0 or u.load > 100: return false
		for part in u.armor_parts:
			if equipment_ids.has(part.item): return false
			equipment_ids[part.item] = true
		if not u.armor_parts.is_empty():
			var stats = Armor.totals(u.armor_parts)
			for field in stats:
				if u.get(field) != stats[field]: return false
		if data.version < 6:
			for pair in [["endurance",25],["mobility",3],["resolve",0],["temperament","none"]]: u[pair[0]] = pair[1]
		for spec in ([["endurance",15,48],["mobility",2,4],["resolve",10,150],["stamina",60,200],["initiative",50,180],["ranged_skill",0,150],["ranged_defense",0,100],["morale_state",-3,1]] if new_turns else [["endurance",15,48],["mobility",2,4],["resolve",-5,12]]):
			if not u.get(spec[0]) is int or u[spec[0]] < spec[1] or u[spec[0]] > spec[2]: return false
		if new_turns and (u.get("stat_rules") != true or u.routed != (u.morale_state == -3) or u.morale != morale_number(u.morale_state)): return false
		if not u.get("temperament") is String or not People.TEMPERAMENTS.has(u.temperament): return false
		if data.version < 5:
			u["comrades"] = []
			u["strain_penalty"] = 0
			u["grief_penalty"] = 0
		if not u.get("comrades") is Array or u.comrades.size() > 5: return false
		var friends = {}
		for id in u.comrades:
			if not id is int or id < 0 or id >= 12 or id == i or id/6 != i/6 or friends.has(id): return false
			friends[id] = true
		if not u.get("strain_penalty") is int or not u.get("grief_penalty") is int: return false
		if u.strain_penalty < 0 or u.strain_penalty > 12 or u.strain_penalty%2 != 0 or u.grief_penalty < 0 or u.grief_penalty > 8 or u.grief_penalty%4 != 0: return false
		if i >= 6 and (not u.comrades.is_empty() or u.strain_penalty != 0 or u.grief_penalty != 0): return false
		if data.version < 4: u["order"] = "free"
		if not u.get("order") is String or not ORDERS.has(u.order): return false
		if data.version < 3:
			u["perks"] = []
			u["scars"] = []
			u["damage_taken"] = 0
			u["worst_hit"] = 0
			u["worst_head"] = false
			u["last_attacker"] = ""
		for pair in [["perks",Progression.PERKS],["scars",Progression.SCARS]]:
			if not u.get(pair[0]) is Array: return false
			var unique = {}
			for id in u[pair[0]]:
				if not id is String or not pair[1].has(id) or unique.has(id): return false
				unique[id] = true
		if u.perks.size() > 3 or u.scars.size() > 2 or not u.get("worst_head") is bool or not u.get("last_attacker") is String: return false
		for field in ["damage_taken","worst_hit"]:
			if not u.get(field) is int or u[field] < 0: return false
		for field in ["id", "name", "title", "side", "q", "r", "weapon", "shield", "skill", "defense", "hp", "max_hp", "armor", "max_armor", "padding", "max_padding", "helmet", "max_helmet", "morale", "fatigue", "ap", "guard", "routed", "escaped", "kills"]:
			if not u.has(field): return false
		for field in ["id", "side", "q", "r", "skill", "defense", "hp", "max_hp", "armor", "max_armor", "padding", "max_padding", "helmet", "max_helmet", "morale", "fatigue", "ap", "kills"]:
			if not u[field] is int: return false
		for field in ["shield", "guard", "routed", "escaped"]:
			if not u[field] is bool: return false
		for field in ["name", "title", "weapon"]:
			if not u[field] is String: return false
		if u.order == "line" and not u.shield and Arsenal.family(u.weapon) != "spear": return false
		if u.routed and u.order != "free": return false
		if u.id != i or not weapons.has(u.weapon) or u.side != (0 if i < 6 else 1): return false
		if u.q < 0 or u.q >= W or u.r < 0 or u.r >= H or u.hp < 0 or u.ap < 0 or u.ap > MAX_AP or u.fatigue < 0 or u.fatigue > (200 if new_turns else 100): return false
		if u.max_hp <= 0 or u.hp > u.max_hp or u.armor < 0 or u.padding < 0 or u.helmet < 0 or u.morale < 0 or u.morale > 100: return false
		if u.hp > 0 and not u.escaped:
			if terrain_check.tiles[key(pos(u))].terrain == "water": return false
			if occupied.has(key(pos(u))): return false
			occupied[key(pos(u))] = true
	for u in data.units:
		for id in u.comrades:
			if not u.id in data.units[id].comrades: return false
	setup(int(data.seed), map_name, mission, modern)
	individual = new_turns
	if data.version >= 10:
		active_id = data.active_id
		turn_queue = data.turn_queue.duplicate(); delayed = data.delayed.duplicate(); activated = data.activated.duplicate(); finished = data.finished.duplicate(); waited = data.waited.duplicate(); turn_scores = data.turn_scores.duplicate()
	units = data.units.duplicate(true)
	round_no = int(data.round)
	side = int(data.side)
	result = str(data.result)
	rng_state = int(data.rng)
	held = data.held.duplicate()
	events = data.events.duplicate()
	commands = data.commands.duplicate(true)
	enemy_plan = plan.duplicate(true)
	shared_line = shared.duplicate(true)
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

func attack_fatigue(u: Dictionary) -> int:
	return maxi(1,int(weapons[u.weapon].fatigue)+(0 if u.get("stat_rules",false) else Armor.tier(u.get("load",0)))+(4 if u.temperament == "aggressive" else 0)-(4 if "weapon_drill" in u.perks else 0))

func guard_fatigue(u: Dictionary) -> int:
	return (0 if u.get("stat_rules",false) else Armor.tier(u.get("load",0)))+(10 if u.shield and "shield_drill" in u.perks else 15)+(5 if u.temperament == "restless" else 0)

func temperament_accuracy(u: Dictionary) -> int:
	match u.temperament:
		"aggressive": return 5
		"cautious": return -4
		"loner": return 8 if spaced(u,pos(u)) else -4
		"gregarious": return -4 if spaced(u,pos(u)) else 6
	return 0

func initialize_arms(u: Dictionary) -> void:
	var arms = Arsenal.empty_arms()
	for slot in ["weapon","shield","ammo"]:
		var definition: String = u.weapon if slot == "weapon" else ("shield" if slot == "shield" and u.shield else Arsenal.ammo_type(u.weapon) if slot == "ammo" else "")
		if definition.is_empty(): continue
		arms[slot] = {"id":"unit_%d_%s" % [u.id,slot],"definition":definition,"condition":int(armor_catalog[definition].durability),"loaded":Arsenal.family(definition) == "crossbow"}
	u["arms"] = arms
	u["stance"] = ""; u["reactions"] = 0; u["stagger"] = 0

func sync_arms(u: Dictionary) -> void:
	u.weapon = u.arms.weapon.definition
	u.shield = not u.arms.shield.is_empty() and u.arms.shield.condition > 0
	if u.side == 1 and not enemy_plan.is_empty(): enemy_plan.roles[str(u.id)] = "archer" if u.weapon in Arsenal.RANGED else "support" if Arsenal.family(u.weapon) in ["spear","polearm"] else "screen" if u.shield else "flank"

func cancel_stance(u: Dictionary) -> void:
	u.stance = ""; u.reactions = 0

func ammo_count(u: Dictionary) -> int:
	return int(u.arms.ammo.get("condition",0)) if u.arms.ammo.get("definition","") == Arsenal.ammo_type(u.weapon) else 0

func action_cost(u: Dictionary, special: bool) -> Dictionary:
	if not special: return {"ap":int(weapons[u.weapon].ap),"fatigue":attack_fatigue(u)}
	var w: Dictionary = weapons[u.weapon]; var base: Dictionary = weapons[Arsenal.family(u.weapon)]
	return {"ap":int(w.get("special_ap",maxi(w.ap,Arsenal.special(u.weapon).ap))),"fatigue":maxi(1,int(w.get("special_fatigue",Arsenal.special(u.weapon).fatigue+w.fatigue-base.fatigue))+(0 if u.get("stat_rules",false) else Armor.tier(u.load))+(4 if u.temperament == "aggressive" else 0)-(4 if "weapon_drill" in u.perks else 0))}

func hook_tile(u: Dictionary, v: Dictionary) -> Vector2i:
	for p in neighbors(pos(v)):
		if distance(p,pos(u)) == 1 and at(p) < 0 and step_cost(pos(v),p) < 999: return p
	return pos(v)

func weapon_action_reason(id: int, special: bool, target: int = -1) -> String:
	if not weapon_rules: return "Weapon actions become available in the next deployment."
	if not can_act(id) or not fighting(units[id]): return "Select a fighting soldier on their turn."
	var u: Dictionary = units[id]
	var cost = action_cost(u,special)
	if u.ap < cost.ap: return "Needs %d AP." % cost.ap
	if u.fatigue+cost.fatigue > fatigue_max(u): return "Needs %d free fatigue." % cost.fatigue
	if special and not Arsenal.special(u.weapon).target:
		if Arsenal.family(u.weapon) == "crossbow":
			if u.arms.weapon.loaded: return "Crossbow is already loaded."
			if ammo_count(u) <= 0: return "Needs a bolt case with ammunition."
			if not adjacent_enemies(u,pos(u)).is_empty(): return "Cannot reload while engaged."
		elif not u.stance.is_empty(): return "This stance is already active."
		return ""
	if target < 0 or target >= units.size() or not living(units[target]) or units[target].side == u.side: return "Choose a living enemy."
	var v: Dictionary = units[target]
	var reach_reason = reach_block_reason(u,v,special)
	if not reach_reason.is_empty(): return reach_reason
	if u.weapon in Arsenal.RANGED:
		if ammo_count(u) <= 0: return "No matching ammunition."
		if Arsenal.family(u.weapon) == "crossbow" and not u.arms.weapon.loaded: return "Crossbow needs reloading."
	if special and Arsenal.family(u.weapon) == "axe" and not v.shield: return "Target has no working shield."
	if special and Arsenal.family(u.weapon) == "polearm" and hook_tile(u,v) == pos(v): return "No empty passable hex to pull the target into."
	return ""

func use_weapon(id: int, special: bool, target: int = -1) -> bool:
	if not weapon_action_reason(id,special,target).is_empty(): return false
	var u: Dictionary = units[id]
	var cost = action_cost(u,special)
	u.ap -= cost.ap; u.fatigue += cost.fatigue; u.guard = false
	cancel_stance(u)
	commands.append(["weapon",id,"special" if special else "basic",target])
	if special and not Arsenal.special(u.weapon).target:
		if Arsenal.family(u.weapon) == "crossbow": u.arms.weapon.loaded = true
		else: u.stance = "riposte" if Arsenal.family(u.weapon) == "sword" else "brace"; u.reactions = 2
		log_event("%s: %s · %d AP / %d fatigue." % [u.name,Arsenal.special(u.weapon).name,cost.ap,cost.fatigue])
	else:
		if u.weapon in Arsenal.RANGED:
			u.arms.ammo.condition -= 1
			if Arsenal.family(u.weapon) == "crossbow": u.arms.weapon.loaded = false
		log_event("%s: %s." % [u.name,Arsenal.special(u.weapon).name if special else Arsenal.primary(u.weapon)])
		strike(id,target,special)
	check_result()
	return true

func switch_reason(id: int, slot: String) -> String:
	if not weapon_rules or not can_act(id) or not fighting(units[id]) or not slot in ["carry1","carry2"]: return "Select a carried item on this soldier's turn."
	var u: Dictionary = units[id]
	var item: Dictionary = u.arms[slot]
	if item.is_empty(): return "Carried slot is empty."
	if u.ap < 2 or u.fatigue+4 > fatigue_max(u): return "Switching costs 2 AP and 4 fatigue."
	if item.definition == "shield" and u.weapon in Arsenal.TWO_HANDS: return "Switch to a one-handed weapon before raising the carried shield."
	if item.definition in Arsenal.TWO_HANDS and not u.arms.shield.is_empty():
		var other = "carry2" if slot == "carry1" else "carry1"
		if not u.arms[other].is_empty(): return "Free the other carried slot to stow your shield."
	return ""

func switch_carried(id: int, slot: String) -> bool:
	if not switch_reason(id,slot).is_empty(): return false
	var u: Dictionary = units[id]
	var links = linked_shields()
	var item: Dictionary = u.arms[slot]
	var destination = "shield" if item.definition == "shield" else "weapon"
	if item.definition in Arsenal.TWO_HANDS and not u.arms.shield.is_empty():
		u.arms["carry2" if slot == "carry1" else "carry1"] = u.arms.shield
		u.arms.shield = {}
	u.arms[slot] = u.arms[destination]
	u.arms[destination] = item
	u.ap -= 2; u.fatigue += 4; u.guard = false; cancel_stance(u); sync_arms(u)
	if u.order == "line" and not u.shield and Arsenal.family(u.weapon) != "spear": u.order = "free"
	commands.append(["switch",id,slot])
	log_event("%s switches to %s: 2 AP / 4 fatigue." % [u.name,armor_catalog[item.definition].name])
	report_broken_links(links)
	return true

func brace_reactions(id: int, previous: Vector2i) -> bool:
	var mover: Dictionary = units[id]
	var stopped = false
	for u in units:
		if not living(mover): break
		if not fighting(u) or u.side == mover.side or u.get("stance","") != "brace" or u.reactions <= 0 or u.fatigue+6 > fatigue_max(u): continue
		if distance(previous,pos(u)) <= 1 or distance(pos(mover),pos(u)) != 1: continue
		u.reactions -= 1; u.fatigue += 6
		log_event(u.name+" meets the approach with a braced spear.")
		if strike(u.id,id,false,true): stopped = true
	return stopped

func ai_weapon_step(id: int) -> bool:
	var u: Dictionary = units[id]
	if not fighting(u): return false
	if not u.stance.is_empty(): finish_unit(id); return true
	var trapped = not adjacent_enemies(u,pos(u)).is_empty()
	if (u.weapon in Arsenal.RANGED and (ammo_count(u) <= 0 or trapped)) or (Arsenal.family(u.weapon) == "polearm" and trapped):
		for slot in ["carry1","carry2"]:
			var definition: String = u.arms[slot].get("definition","")
			if definition in Arsenal.WEAPONS and not definition in Arsenal.RANGED and Arsenal.family(definition) != "polearm" and switch_carried(id,slot): return true
	if u.fatigue >= fatigue_max(u)*0.65: return false
	if Arsenal.family(u.weapon) == "crossbow" and not u.arms.weapon.loaded and use_weapon(id,true): return true
	for v in units:
		if not weapon_action_reason(id,true,v.id).is_empty() or not Arsenal.special(u.weapon).target: continue
		var worth = (Arsenal.family(u.weapon) == "axe" and v.shield and v.arms.shield.condition <= 24) or (Arsenal.family(u.weapon) == "mace" and v.stagger == 0 and v.hp > 25) or (Arsenal.family(u.weapon) == "hammer" and v.armor > 65) or (Arsenal.family(u.weapon) == "dagger" and v.armor > 30 and hit_chance(id,v.id,true) >= 45) or (u.weapon in Arsenal.RANGED and hit_chance(id,v.id) < 65) or (Arsenal.family(u.weapon) == "polearm" and v.order == "line")
		if worth and use_weapon(id,true,v.id): return true
	if Arsenal.family(u.weapon) == "spear" and not trapped and u.stance.is_empty():
		if units.any(func(v): return fighting(v) and v.side != u.side and distance(pos(u),pos(v)) == 3) and use_weapon(id,true): return true
	if Arsenal.family(u.weapon) == "sword" and trapped and u.ap >= 4 and u.ap < 8 and u.stance.is_empty() and use_weapon(id,true): return true
	return false


func initialize_stats(u: Dictionary) -> void:
	u["stat_rules"] = true
	u["stamina"] = 105+(u.id%3)*5
	u["initiative"] = 95+(u.id*13+seed_value)%25
	u["ranged_skill"] = u.skill if u.weapon in Arsenal.RANGED else 40+(u.id*7)%15
	u["ranged_defense"] = 3+(u.id*3)%10
	u["resolve"] = 45+(5 if u.id == 6 else 0)
	u["morale_state"] = 0
	u.morale = 85

func fatigue_max(u: Dictionary) -> int:
	return People.fatigue_max(u)

func initiative_value(u: Dictionary) -> int:
	return People.initiative_value(u)

func tie_priority(id: int) -> int:
	var value = posmod(seed_value*48271+(id+1)*69621+round_no*104729,2147483647)
	return posmod(value*48271,2147483647)

func start_round() -> void:
	activated = []; finished = []; waited = []; delayed = []; turn_queue = []; turn_scores = {}; active_id = -1
	for u in units:
		u.ap = 0
		if living(u):
			turn_queue.append(u.id)
			turn_scores[str(u.id)] = initiative_value(u)
	turn_queue.sort_custom(func(a,b): return turn_scores[str(a)] > turn_scores[str(b)] if turn_scores[str(a)] != turn_scores[str(b)] else tie_priority(a) < tie_priority(b))
	activate_next()

func complete_round() -> void:
	record_shared_line()
	var control = [0,0]
	for u in units:
		if fighting(u) and distance(pos(u),FORD) <= 1: control[u.side] = 1
	for team in 2:
		held[team] = mini(3,held[team]+1) if control[team] == 1 and control[1-team] == 0 else 0
		if objective != "eliminate" and held[team] >= 3 and (objective == "hold" or team == 1): result = "victory" if team == 0 else "defeat"
	if objective in ["defend","escort"] and round_no >= 8 and result.is_empty(): result = "victory"
	if not result.is_empty(): return
	round_no += 1
	if round_no > 30: result = "draw"; return
	start_round()

func activate_next() -> void:
	check_result()
	if not result.is_empty(): return
	while not turn_queue.is_empty() or not delayed.is_empty():
		var id: int = turn_queue.pop_front() if not turn_queue.is_empty() else delayed.pop_front()
		if not living(units[id]):
			units[id].ap = 0
			if not id in finished: finished.append(id)
			continue
		active_id = id; side = units[id].side
		var u: Dictionary = units[id]
		if not id in activated:
			activated.append(id)
			u.ap = MAX_AP-u.stagger; u.stagger = 0
			u.fatigue = maxi(0,u.fatigue-People.recovery(u))
			u.guard = false; cancel_stance(u)
		log_event("%s acts%s · initiative %d." % [u.name," after waiting" if id in waited else "",turn_scores[str(id)]])
		return
	active_id = -1
	complete_round()

func complete_activation() -> void:
	if active_id >= 0:
		units[active_id].ap = 0
		if not active_id in finished: finished.append(active_id)
	active_id = -1
	activate_next()

func advance_if_spent() -> bool:
	if not individual or not result.is_empty(): return false
	if active_id < 0 or not living(units[active_id]) or units[active_id].ap <= 0:
		complete_activation()
		return true
	return false

func can_wait(id: int) -> bool:
	return individual and can_act(id) and fighting(units[id]) and units[id].ap > 0 and not id in waited and (not turn_queue.is_empty() or not delayed.is_empty())

func wait_unit(id: int) -> bool:
	if not can_wait(id): return false
	commands.append(["wait",id]); waited.append(id); delayed.append(id)
	log_event(units[id].name+" waits; remaining AP and fatigue are preserved.")
	active_id = -1; activate_next()
	return true

func upcoming() -> Array:
	var out: Array = [active_id] if active_id >= 0 and living(units[active_id]) else []
	for id in turn_queue+delayed:
		if living(units[id]): out.append(id)
	return out

static func morale_number(state: int) -> int:
	return {-3:15,-2:35,-1:60,0:85,1:100}.get(state,85)

func morale_multiplier(u: Dictionary) -> float:
	return 1.0+u.get("morale_state",0)*0.1

func morale_name(u: Dictionary) -> String:
	return {-3:"FLEEING",-2:"BREAKING",-1:"WAVERING",0:"STEADY",1:"CONFIDENT"}.get(u.get("morale_state",0),"STEADY")

func morale_check(u: Dictionary, severity: int, cause: String, positive: bool = false) -> void:
	if not fighting(u): return
	var chance = clampi(u.resolve+20-severity+comrade_support(u)+u.morale_state*10-u.strain_penalty-u.grief_penalty+(10 if u.temperament == "stoic" else 0)+(15 if "steadfast" in u.perks else 0),5,95)
	var success = roll(1,100) <= chance
	if positive and not success: return
	if not positive and success:
		log_event("%s holds nerve (%d%% · %s)." % [u.name,chance,cause]); return
	var state: int = clampi(u.morale_state+(1 if positive else -1),-3,1)
	if state == u.morale_state: return
	u.morale_state = state; u.morale = morale_number(state)
	log_event("%s: %s · %s (%d%% resolve check)." % [u.name,morale_name(u),cause,chance])
	combat_feedback.emit({"id":u.id,"kind":"morale","text":morale_name(u)})
	if state == -3:
		u.routed = true; u.order = "free"; u.guard = false; cancel_stance(u)
		for other in units:
			if other.id != u.id and other.side == u.side and fighting(other) and distance(pos(u),pos(other)) <= 2: morale_check(other,10,"nearby panic")

func valid_turn_state(d: Dictionary) -> bool:
	for u in d.units:
		if not u is Dictionary: return false
	if not d.get("individual") is bool or not d.get("active_id") is int or not d.get("turn_scores") is Dictionary: return false
	for field in ["turn_queue","delayed","activated","finished","waited"]:
		if not d.get(field) is Array or d[field].size() > 12: return false
		var seen = {}
		for id in d[field]:
			if not id is int or id < 0 or id >= 12 or seen.has(id): return false
			seen[id] = true
	if not d.individual:
		return d.active_id == -1 and d.turn_queue.is_empty() and d.delayed.is_empty() and d.activated.is_empty() and d.finished.is_empty() and d.waited.is_empty() and d.turn_scores.is_empty()
	if d.active_id < -1 or d.active_id >= 12 or (d.result.is_empty() and d.active_id < 0): return false
	var all_ids: Array = d.turn_queue+d.delayed+d.finished+([d.active_id] if d.active_id >= 0 else [])
	var unique = {}
	for id in all_ids:
		if unique.has(id): return false
		unique[id] = true
	for id in d.delayed:
		if not id in d.waited or not id in d.activated: return false
	for id in d.waited:
		if not id in d.activated: return false
	for id in d.turn_queue:
		if id in d.activated: return false
	if d.active_id >= 0 and (not d.active_id in d.activated or d.units[d.active_id].get("side") != d.side): return false
	for id in range(12):
		if not d.units[id] is Dictionary: return false
		if not d.units[id].get("hp") is int or not d.units[id].get("escaped") is bool: return false
		if d.units[id].hp > 0 and not d.units[id].escaped and not unique.has(id): return false
		if (id in d.turn_queue or id in d.finished) and d.units[id].get("ap") != 0: return false
		if unique.has(id) and not d.turn_scores.get(str(id)) is int: return false
	for value in d.turn_scores.values():
		if not value is int or value < 0 or value > 180: return false
	return true
