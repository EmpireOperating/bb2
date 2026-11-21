extends RefCounted
const TerrainRules = preload("res://src/terrain_rules.gd")
var terrain_rules_enabled = false
const DungeonThemes = preload("res://src/dungeon_themes.gd")
const DungeonTactics = preload("res://src/dungeon_tactics.gd")
const Undead = preload("res://src/undead.gd")
var boss_tactics = false
const Named = preload("res://src/named_equipment.gd")
const Perks = preload("res://src/perks.gd")
var perk_rules = false
var tactical_ai = false
var engagement_ai = false
var axe_mace_rules = false
var hammer_dagger_rules = false
var inventory_rules = false
var double_grip_rules = false
var roster_rules = false
var ambush = false
const Arsenal = preload("res://src/arsenal.gd")
const Damage = preload("res://src/combat_damage.gd")
var core_rules = false
var damage_rules = false
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
var equipment_catalog_override: Dictionary = {}
var defer_initial_round := false
var armor_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
const People = preload("res://src/people.gd")
signal combat_feedback(event: Dictionary)
signal weapon_reload_committed(actor_id: int, item_uid: String)
signal utility_committed(event: Dictionary)
## Pure battle rules. No nodes, animations, input, wall clock or global random state.
## All player and AI actions go through the same validated command methods.

const Progression = preload("res://src/progression.gd")
const W = 13
const H = 9
const MAX_AP = 9
const LEGACY_FORD = Vector2i(6, 4)
const FORD = LEGACY_FORD
const DIRECTIONS = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
var weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
var units: Array = []
var tiles: Dictionary = {}
var events: Array = []
var round_no = 1
var side = 0
var result = ""
# Voluntary side-0 escape order; morale routing alone can still rally.
var withdrawing := false
var rng_state = 1
var seed_value = 1
var held: Array = [0, 0]
var commands: Array = []
var map_id = "ford"
var objective = "hold"
const ORDERS = {"free":"Free order", "line":"Shield line", "loose":"Loose order"}
var enemy_plan: Dictionary = {}
var shared_line: Array = []
# Ephemeral authored rectangles; tile/spawn installation belongs to the session.
var _board_size = Vector2i.ZERO
var _board_goal = Vector2i.ZERO
const TacticalVisibility = preload("res://src/tactical_visibility.gd")
var visibility_enabled = false
var visibility_profile: Dictionary = {}
var _visible: Array = [{},{}]
var _explored: Array = [{},{}]
var _known: Array = [{},{}]
var _personal: Dictionary = {}
var _personal_targets: Dictionary = {}
var _public_events: Array = [[],[]]
var _movement_cache: Dictionary = {}

func configure_visibility(profile: Dictionary = {}) -> bool:
	var radius = profile.get("radius",7) # Provisional day radius; not a parity claim.
	if not radius is int or radius < 1 or radius > 32: return false
	visibility_profile = profile.duplicate(true)
	visibility_profile["radius"] = radius
	visibility_enabled = true
	boss_tactics = false # Boss intelligence is outside the ordinary-company slice.
	_visible = [{},{}]; _explored = [{},{}]; _known = [{},{}]
	_public_events = [[],[]]
	refresh_visibility()
	log_public_event(objective_text(),[0,1])
	return true

func refresh_visibility() -> void:
	if not visibility_enabled: return
	_movement_cache.clear()
	_personal = {}; _personal_targets = {}; _visible = [{},{}]
	for u in units:
		if not living(u): continue
		var radius = u.get("vision",visibility_profile.radius)
		if not radius is int: radius = visibility_profile.radius
		_personal[int(u.id)] = TacticalVisibility.observer_cells(self,u,clampi(radius,1,32))
		_visible[int(u.side)].merge(_personal[int(u.id)],true)
		_personal_targets[int(u.id)] = {}
		for target in units:
			if living(target) and _personal[int(u.id)].has(key(pos(target))): _personal_targets[int(u.id)][int(target.id)] = true
	for team in 2:
		_explored[team].merge(_visible[team],true)
		_known[team] = {}
		for u in units:
			if u.side != team and living(u) and _visible[team].has(key(pos(u))): _known[team][int(u.id)] = true
	# Planner knowledge expires with sight, before a later AI step can inspect it.
	if enemy_plan.has("focus") and not known_enemy_ids(1).has(int(enemy_plan.focus)):
		enemy_plan.focus = -1

func tile_visible(team: int, cell: Vector2i) -> bool:
	return team in [0,1] and tiles.has(key(cell)) and (not visibility_enabled or _visible[team].has(key(cell)))

func tile_explored(team: int, cell: Vector2i) -> bool:
	return team in [0,1] and tiles.has(key(cell)) and (not visibility_enabled or _explored[team].has(key(cell)))

func unit_visible(team: int, id: int) -> bool:
	if not team in [0,1] or id < 0 or id >= units.size(): return false
	return units[id].side == team or (not visibility_enabled and living(units[id])) or (visibility_enabled and _known[team].has(id))

func unit_can_see(observer_id: int, target_id: int) -> bool:
	if observer_id < 0 or target_id < 0 or observer_id >= units.size() or target_id >= units.size(): return false
	if not visibility_enabled: return living(units[observer_id]) and living(units[target_id])
	return _personal_targets.get(observer_id,{}).has(target_id)

func target_visibility_reason(actor: int, target: int) -> String:
	if hidden_target(actor,target): return "Target is not currently visible."
	if visibility_enabled and actor >= 0 and actor < units.size() and target >= 0 and target < units.size() and units[target].side != units[actor].side and not unit_can_see(actor,target): return "Target is outside this soldier's sight."
	return ""

func hidden_target(actor: int, target: int) -> bool:
	return visibility_enabled and actor >= 0 and actor < units.size() and target >= 0 and target < units.size() and units[target].side != units[actor].side and not unit_visible(units[actor].side,target)

func known_enemy_ids(team: int) -> Array:
	if not team in [0,1]: return []
	if not visibility_enabled: return units.filter(func(u): return u.side != team and living(u)).map(func(u): return int(u.id))
	return _known[team].keys()


func configure_board(board_width: int, board_height: int, goal_cell: Vector2i) -> bool:
	if board_width < 1 or board_height < 1 or board_width > 256 or board_height > 256: return false
	if goal_cell.x < 0 or goal_cell.y < 0 or goal_cell.x >= board_width or goal_cell.y >= board_height: return false
	_board_size = Vector2i(board_width,board_height)
	_board_goal = goal_cell
	return true

func setup(seed_number: int = 7391, field: String = "ford", mission: String = "hold", advanced_weapons: bool = false, individual_turns: bool = false, pooled_damage: bool = false, baseline_combat: bool = false, personal_perks: bool = false, expanded_roster: bool = false, ambushed: bool = false) -> void:
	_board_size = Vector2i.ZERO; _board_goal = Vector2i.ZERO
	visibility_enabled = false; visibility_profile = {}; _personal = {}; _personal_targets = {}; _public_events = [[],[]]; _movement_cache.clear()
	_visible = [{},{}]; _explored = [{},{}]; _known = [{},{}]
	terrain_rules_enabled = false
	boss_tactics = false
	roster_rules = expanded_roster; ambush = ambushed if expanded_roster else false
	inventory_rules = personal_perks
	perk_rules = personal_perks
	tactical_ai = personal_perks
	engagement_ai = personal_perks
	axe_mace_rules = personal_perks
	hammer_dagger_rules = personal_perks
	double_grip_rules = personal_perks
	core_rules = baseline_combat
	damage_rules = pooled_damage
	weapons = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json" if core_rules else "res://data/legacy_weapons_v15.json" if damage_rules else "res://data/legacy_weapons_v14.json"))
	if perk_rules: configure_perk_weapons()
	armor_catalog = equipment_catalog_override.duplicate(true) if not equipment_catalog_override.is_empty() else JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json" if damage_rules else "res://data/legacy_equipment_v14.json"))
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
	withdrawing = false
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
	if roster_rules:
		expand_battle()
		DungeonThemes.configure_battle(self)
	if not roster_rules and objective in ["defend", "escort"]:
		for i in 6: units[i].q += 2
	for u in units:
		if damage_rules:
			u.hp = roundi(u.hp*0.75); u.max_hp = u.hp
			u.helmet = 70; u.max_helmet = 70
		initialize_arms(u)
		if perk_rules: u["perk_state"] = Perks.state()
		if hammer_dagger_rules: u["weapon_perk_state"] = weapon_perk_state()
		if individual: initialize_stats(u)
	if individual and not defer_initial_round: start_round()
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
			elif map_id in ["crypt_barrow","crypt_gallery","crypt_throne"]:
				terrain = "stone"
				if map_id == "crypt_barrow" and q in [5,7] and r in [1,7]: terrain = "wall"
				if map_id == "crypt_gallery" and ((q == 6 and r in [2,6]) or (q == 8 and r in [1,7])): terrain = "wall"
				if map_id == "crypt_throne" and q == 6 and r in [0,1,2,6,7,8]: terrain = "wall"
			elif is_crypt():
				terrain = "wall" if q == 6 and r in [0,1,2,6,7,8] else "stone"
				if q in [5,7] and r in ([2,6] if seed_value%2 == 0 else [1,7]): terrain = "rubble"
			elif map_id == "ridge":
				if q >= 5 and q <= 8 and r >= 2 and r <= 6:
					terrain = "hill"
					height = 1
				if q == 6 and r in [3, 4, 5]: height = 2
				if q in [3, 9] and r in [0, 1, 7, 8]: terrain = "forest"
			tiles[key(Vector2i(q, r))] = {"terrain":terrain, "height":height}

func objective_name() -> String:
	if is_crypt(): return "CLEAR THE CHAMBER"
	return {"hold":"TAKE THE CROSSING", "eliminate":"BREAK THE RAIDERS", "defend":"HOLD THE RIDGE", "escort":"DEFEND THE WAGONS"}[objective]

func objective_text() -> String:
	if boss_tactics: return DungeonTactics.description(self)
	if is_crypt(): return "Destroy the undead. They do not flee. Retreat preserves casualties and armour damage on both sides."
	return {"hold":"Hold the marked ground for 3 full rounds, or break the enemy company.", "eliminate":"Kill every raider or drive them to a passable field edge. Fleeing fighters remain targets until they escape.", "defend":"Survive 8 rounds. Deny the enemy 3 rounds on the banner, or break them.", "escort":"Defend the wagon circle for 8 rounds. Deny 3 enemy capture rounds, or break them."}[objective]

func add_unit(n: String, title: String, team: int, p: Vector2i, weapon: String, shield: bool, skill: int, defense: int, hp: int, armor: int) -> void:
	units.append({"id":units.size(), "name":n, "title":title, "side":team, "q":p.x, "r":p.y, "weapon":weapon, "shield":shield, "skill":skill, "defense":defense, "hp":hp, "max_hp":hp, "armor":armor, "max_armor":armor, "padding":30, "max_padding":30, "helmet":40, "max_helmet":40, "morale":85 if team == 0 else 75, "fatigue":0, "ap":MAX_AP, "guard":false, "routed":false, "escaped":false, "kills":0, "damage_hp":0, "damage_armor":0, "damage_shield":0, "damage_received":0, "perks":[], "scars":[], "damage_taken":0, "worst_hit":0, "worst_head":false, "last_attacker":"", "order":"free", "comrades":[], "strain_penalty":0, "grief_penalty":0, "endurance":25,"mobility":3,"resolve":0,"temperament":"none", "armor_parts":[], "load":0})

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

func terrain_can_react(u: Dictionary) -> bool:
	if not fighting(u) or u.weapon in Arsenal.RANGED: return false
	for status in ["stunned","dying","sleeping","entangled","horrified"]:
		if u.get(status,false): return false
	return int(weapon_stats(u).get("min_range",1)) <= 1 and weapon_reach(u) >= 1

func terrain_controls(u: Dictionary, target: Vector2i) -> bool:
	if not terrain_can_react(u) or distance(pos(u),target) != 1: return false
	return tiles.has(key(target)) and tiles.has(key(pos(u))) and absi(int(tiles[key(target)].height)-int(tiles[key(pos(u))].height)) <= 1

func departure_stopped(u: Dictionary) -> bool:
	# A valid attempt is charged before these free strikes. A hit cancels
	# departure, not payment. Ordinary reaction damage remains authoritative.
	for foe in adjacent_enemies(u,pos(u)):
		if not living(u): return true
		var audience = [0,1].filter(func(team): return unit_visible(team,foe) and unit_visible(team,int(u.id)))
		log_event("%s attempts an opportunity attack against %s." % [units[foe].name,u.name],audience)
		if strike(foe,u.id,false,true):
			log_event("The opportunity attack stops %s's departure%s." % [u.name," — killed" if u.hp <= 0 else ""],audience)
			return true
	return not living(u)

func adjacent_enemies(u: Dictionary, from: Vector2i) -> Array:
	var out: Array = []
	for v in units:
		if terrain_rules_enabled:
			if v.side != u.side and terrain_controls(v,from): out.append(v.id)
			continue
		if fighting(v) and v.side != u.side and distance(from, pos(v)) == 1 and (not core_rules or (not v.weapon in Arsenal.RANGED and absi(tiles[key(from)].height-tiles[key(pos(v))].height) <= 1)): out.append(v.id)
	return out

func shield_neighbors(u: Dictionary, from: Vector2i) -> Array:
	var allies: Array = []
	for v in units:
		if v.id != u.id and fighting(v) and v.side == u.side and v.shield and (core_rules or v.order != "loose") and distance(pos(v),from) == 1:
			allies.append(v.id)
	return allies

func shield_support(u: Dictionary) -> int:
	if core_rules: return wall_support(u)
	if not fighting(u) or not u.shield or u.order == "loose": return 0
	return mini(2,shield_neighbors(u,pos(u)).size())*5

func line_support(u: Dictionary) -> int:
	if core_rules: return 0
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
	if not core_rules and (u.ap < 2 or u.fatigue+4 > fatigue_max(u)): return "%s needs 2 AP and 4 free fatigue." % u.name
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
		units[id].ap -= 0 if core_rules else 2
		units[id].fatigue += 0 if core_rules else 4
		units[id].order = order
		clear_weapon_sequence(units[id])
		if not core_rules: units[id].guard = false
	commands.append(["order",sorted,order])
	log_event(("%s: %s (formation marker)." if core_rules else "%s: %s (2 AP / 4 fatigue each).") % [", ".join(sorted.map(func(id): return units[id].name)),ORDERS[order]])
	return true

func movement_edge(u: Dictionary, a: Vector2i, b: Vector2i) -> Dictionary:
	var edge: Dictionary
	if terrain_rules_enabled:
		edge = TerrainRules.edge(tiles.get(key(a),{}),tiles.get(key(b),{}),distance(a,b),perk_rules and Perks.has(u,"pathfinder"))
	else:
		edge = {"ap":movement_cost(u,a,b),"fatigue":legacy_movement_fatigue(u,a,b),"reason":"" if step_cost(a,b) < 999 else "Impassable terrain."}
	if edge.reason.is_empty(): edge.fatigue = paid_movement_fatigue(u,edge.fatigue)
	return edge
func paid_movement_fatigue(u: Dictionary, fatigue: int) -> int:
	return maxi(1,fatigue-int(u.get("move_fatigue_discount",0))) if u.get("inventory_balance",false) else fatigue

func movement_cost(u: Dictionary, a: Vector2i, b: Vector2i) -> int:
	if terrain_rules_enabled: return movement_edge(u,a,b).ap
	if perk_rules and Perks.has(u,"pathfinder") and step_cost(a,b) < 999:
		return maxi(2,(4 if tiles[key(b)].terrain in ["mud","forest"] else 2)-1)
	return step_cost(a,b)+(1 if not core_rules and u.order == "line" and not u.routed else 0)

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
		if visibility_enabled and not tile_visible(u.side,target):
			preview.reason = "Destination is not currently visible."
			return preview
		var cost = movement_cost(u,pos(u),target)
		var fatigue = movement_fatigue(u,pos(u),target) if terrain_rules_enabled or u.get("inventory_balance",false) else cost*People.move_rate(u)
		var reason = ""
		if not adjacent_enemies(u,pos(u)).is_empty(): reason = "Engaged: use individual Withdraw."
		elif cost >= 999: reason = "Water or field edge blocks the advance."
		elif at(target) >= 0 and not seen.has(at(target)): reason = "Destination occupied outside this group."
		elif cost > u.ap or fatigue+u.fatigue > fatigue_max(u): reason = "Insufficient AP or free fatigue."
		preview.steps.append({"id":id,"q":target.x,"r":target.y,"cost":cost,"reason":reason})
		if terrain_rules_enabled or u.get("inventory_balance",false): preview.steps.back()["fatigue"] = fatigue
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
		u.fatigue += step.fatigue if terrain_rules_enabled or u.get("inventory_balance",false) else step.cost*People.move_rate(u)
		u.q = step.q
		u.r = step.r
		refresh_visibility()
		clear_weapon_sequence(u)
		u.guard = false
		if weapon_rules: cancel_stance(u)
	if weapon_rules:
		for id in sorted: spearwall_reactions(id,offset(axial(pos(units[id]))-DIRECTIONS[direction]))
	commands.append(["advance",sorted,direction])
	log_event("%d soldiers advance together; formation orders remain." % ids.size())
	report_broken_links(links)
	check_result()
	return true

func step_cost(a: Vector2i, b: Vector2i) -> int:
	if terrain_rules_enabled: return TerrainRules.edge(tiles.get(key(a),{}),tiles.get(key(b),{}),distance(a,b)).ap
	if not tiles.has(key(b)) or tiles[key(b)].terrain in ["water","wall"]: return 999
	var cost = 4 if tiles[key(b)].terrain in ["mud", "forest"] else 2
	return cost + maxi(0, int(tiles[key(b)].height) - int(tiles[key(a)].height))

func can_act(id: int) -> bool:
	return id >= 0 and id < units.size() and result.is_empty() and living(units[id]) and units[id].side == side and (not individual or id == active_id)

func terrain_movement_map(id: int, preview_budget: int = -1) -> Dictionary:
	if not can_act(id): return {}
	var u: Dictionary = units[id]
	var start = pos(u)
	var budget: int = u.ap if preview_budget < 0 else preview_budget
	var free_fatigue: int = fatigue_max(u)-u.fatigue
	var first = {"p":start,"cost":0,"fatigue":0,"path":[]}
	var labels = {key(start):[first]}
	var frontier: Array = [first]
	while not frontier.is_empty():
		frontier.sort_custom(func(a,b): return a.cost < b.cost if a.cost != b.cost else a.fatigue < b.fatigue)
		var label: Dictionary = frontier.pop_front()
		var p: Vector2i = label.p
		if not label in labels[key(p)]: continue
		for n in neighbors(p):
			if visibility_enabled and not tile_visible(u.side,n): continue
			if at(n) != -1: continue
			var edge = movement_edge(u,p,n)
			if not edge.reason.is_empty(): continue
			var ap: int = label.cost+edge.ap
			var fatigue: int = label.fatigue+edge.fatigue
			if ap > budget or (preview_budget < 0 and fatigue > free_fatigue): continue
			var existing: Array = labels.get(key(n),[])
			if existing.any(func(v): return v.cost <= ap and v.fatigue <= fatigue): continue
			var candidate = {"p":n,"cost":ap,"fatigue":fatigue,"path":label.path+[n]}
			labels[key(n)] = existing.filter(func(v): return not (ap <= v.cost and fatigue <= v.fatigue))
			labels[key(n)].append(candidate)
			frontier.append(candidate)
	var out = {}
	for k in labels:
		if k == key(start): continue
		var choices: Array = labels[k]
		choices.sort_custom(func(a,b): return a.cost < b.cost if a.cost != b.cost else a.fatigue < b.fatigue)
		var best: Dictionary = choices[0]
		out[k] = {"cost":best.cost,"fatigue":best.fatigue,"path":best.path}
	return out

func movement_map(id: int, preview_budget: int = -1) -> Dictionary:
	if not visibility_enabled: return _movement_map_uncached(id,preview_budget)
	if not can_act(id): return {}
	var u: Dictionary = units[id]
	var stamp = str([id,u.ap,u.fatigue,u.order,u.routed,u.perks,fatigue_max(u),terrain_rules_enabled])
	if not _movement_cache.has(stamp):
		if _movement_cache.size() >= 32: _movement_cache.clear()
		# Fog has no unlimited/full-board diagnostic mode. Preserve the
		# affordable two-resource Pareto search, never collapse its labels.
		_movement_cache[stamp] = _movement_map_uncached(id,-1)
	return _movement_cache[stamp].duplicate(true)

func _movement_map_uncached(id: int, preview_budget: int = -1) -> Dictionary:
	if terrain_rules_enabled: return terrain_movement_map(id,preview_budget)
	if not can_act(id): return {}
	var u: Dictionary = units[id]
	var start = pos(u)
	var budget = int(u.ap) if perk_rules else mini(int(u.ap), (fatigue_max(u) - int(u.fatigue)) / People.move_rate(u))
	if preview_budget >= 0: budget = preview_budget
	var costs: Dictionary = {key(start):0}
	var paths: Dictionary = {key(start):[]}
	var fatigue_costs = {key(start):0}
	var frontier: Array = [start]
	if not u.routed and not adjacent_enemies(u, start).is_empty(): return {}
	while not frontier.is_empty():
		frontier.sort_custom(func(a, b): return costs[key(a)] < costs[key(b)])
		var p: Vector2i = frontier.pop_front()
		if p != start and not adjacent_enemies(u, p).is_empty(): continue
		for n in neighbors(p):
			if visibility_enabled and not tile_visible(u.side,n): continue
			if at(n) != -1: continue
			var step = movement_cost(u, p, n)
			if step >= 999: continue
			var new_cost = int(costs[key(p)]) + step
			var new_fatigue = int(fatigue_costs[key(p)])+movement_fatigue(u,p,n)
			if new_cost <= budget and (preview_budget >= 0 or new_fatigue+u.fatigue <= fatigue_max(u)) and (not costs.has(key(n)) or new_cost < int(costs[key(n)]) or (new_cost == int(costs[key(n)]) and new_fatigue < int(fatigue_costs[key(n)]))):
				costs[key(n)] = new_cost
				fatigue_costs[key(n)] = new_fatigue
				paths[key(n)] = paths[key(p)] + [n]
				if not frontier.has(n): frontier.append(n)
	var out: Dictionary = {}
	for k in paths:
		if k != key(start): out[k] = {"cost":costs[k], "fatigue":fatigue_costs[k], "path":paths[k]}
	return out

func movement_block_reason(id: int, target: Vector2i) -> String:
	if not can_act(id): return "Soldier cannot move now."
	var u: Dictionary = units[id]
	if not tiles.has(key(target)): return "Outside the battlefield."
	if visibility_enabled:
		if not tile_visible(u.side,target): return "Destination is not currently visible."
		return "" if movement_map(id).has(key(target)) else "No affordable visible route."
	if pos(u) == target: return "Already on that hex."
	if terrain_rules_enabled:
		var terrain_reason = TerrainRules.tile_reason(tiles[key(target)])
		if not terrain_reason.is_empty(): return terrain_reason
	if tiles[key(target)].terrain == "water": return "Deep water is impassable."
	if tiles[key(target)].terrain == "wall": return "Dungeon walls are impassable."
	if at(target) >= 0: return "Destination occupied by %s." % units[at(target)].name
	var foes = adjacent_enemies(u,pos(u))
	if not terrain_rules_enabled and not u.routed and not foes.is_empty(): return "Engaged by %s. Use Withdraw to move." % units[foes[0]].name
	if terrain_rules_enabled and movement_map(id).has(key(target)): return ""
	# Read-only route search separates resource shortages from blocked routes.
	var routes = movement_map(id,width()*height()*8)
	if not routes.has(key(target)): return "No open route: units, terrain or enemy control block the way."
	var cost = routes[key(target)].cost
	if cost > u.ap: return "Needs %d AP to reach that hex; %d available." % [cost,u.ap]
	var fatigue = routes[key(target)].fatigue
	if fatigue+u.fatigue > fatigue_max(u): return "Needs %d free fatigue to move; %d available." % [fatigue,maxi(0,fatigue_max(u)-u.fatigue)]
	return ""

func escape_edge(cell: Vector2i, team: int = -1) -> bool:
	if not tiles.has(key(cell)) or not (cell.x == 0 or cell.y == 0 or cell.x == width()-1 or cell.y == height()-1): return false
	var tile: Dictionary = tiles[key(cell)]
	if not TerrainRules.tile_reason(tile).is_empty(): return false
	if is_crypt(): return tile.get("escape_side",-1) in [0,1] and (team < 0 or tile.escape_side == team)
	return true

func unit_event_audience(u: Dictionary) -> Array:
	return [0,1].filter(func(team): return unit_visible(team,int(u.id)))

func escape_unit(u: Dictionary) -> bool:
	if not living(u) or not u.routed or not escape_edge(pos(u),int(u.side)): return false
	# Capture witnesses before removing the actor from sight and occupancy.
	var audience = unit_event_audience(u)
	u.escaped = true
	log_event("%s escapes the field." % u.name,audience)
	refresh_visibility()
	return true

func flee_distances(u: Dictionary) -> Dictionary:
	var distances: Dictionary = {}
	var frontier: Array = []
	# Only public occupancy may affect planning; never inspect hidden positions.
	# Keep the mover's origin traversable so lateral detours have a gradient.
	var occupied: Dictionary = {}
	for other in units:
		if other.id != u.id and living(other) and unit_visible(int(u.side),int(other.id)):
			occupied[key(pos(other))] = true
	for k in tiles:
		var bits = k.split(",")
		var cell = Vector2i(int(bits[0]),int(bits[1]))
		if not occupied.has(k) and escape_edge(cell,int(u.side)):
			distances[k] = 0; frontier.append(cell)
	var cursor = 0
	while cursor < frontier.size():
		var cell: Vector2i = frontier[cursor]; cursor += 1
		for previous in neighbors(cell):
			if occupied.has(key(previous)) or distances.has(key(previous)) or movement_cost(u,previous,cell) >= 999: continue
			distances[key(previous)] = int(distances[key(cell)])+1
			frontier.append(previous)
	return distances

func flee_step(id: int) -> void:
	if not can_act(id) or not units[id].routed: return
	var u: Dictionary = units[id]
	if escape_edge(pos(u),int(u.side)):
		# No new hex is traversed when already at the boundary, but leaving
		# enemy control still resolves the ordinary departure strike chain.
		if not departure_stopped(u): escape_unit(u)
		check_result()
		if individual and active_id == id: complete_activation()
		elif living(u): finish_unit(id)
		return
	# A reverse public-occupancy potential permits multi-turn detours around
	# occupied edges without hidden actor knowledge. AP/fatigue/sight and
	# every reaction remain the ordinary movement_map/move_unit authority.
	var distances = flee_distances(u)
	var best = pos(u)
	var edge: int = distances.get(key(best),999999)
	var paid = 999999
	for route in movement_map(id).values():
		var p: Vector2i = route.path.back()
		var gap: int = distances.get(key(p),999999)
		if gap < edge or (gap == edge and best != pos(u) and route.cost < paid):
			best = p; edge = gap; paid = route.cost
	if best != pos(u): move_unit(id,best)
	else: finish_unit(id)

# Transient presentation receipt; deliberately absent from snapshot/restore.
var last_traversed: Dictionary = {}

func move_unit_path(id: int, path: Array) -> bool:
	if not movement_path_quote(id,path).valid: return false
	return _execute_movement(id,path.back(),path)

func movement_path_quote(id: int, path: Array) -> Dictionary:
	var out = {"valid":false,"cost":0,"fatigue":0}
	if not can_act(id) or path.is_empty(): return out
	var u: Dictionary = units[id]
	var previous = pos(u)
	for cell in path:
		if not cell is Vector2i: return out
		if not tile_visible(u.side,cell) or distance(previous,cell) != 1: return out
		if at(cell) != -1: return out
		if not terrain_rules_enabled and not u.routed and not adjacent_enemies(u,previous).is_empty(): return out
		var edge = movement_edge(u,previous,cell)
		if not edge.reason.is_empty(): return out
		out.cost += edge.ap; out.fatigue += edge.fatigue
		previous = cell
	out.valid = out.cost <= u.ap and out.fatigue+u.fatigue <= fatigue_max(u)
	return out

func move_unit(id: int, target: Vector2i) -> bool:
	var reachable = movement_map(id)
	if not reachable.has(key(target)): return false
	return _execute_movement(id,target,reachable[key(target)].path,reachable[key(target)].cost)

func _execute_movement(id: int, target: Vector2i, path: Array, legacy_cost: int = -1) -> bool:
	var links = linked_shields()
	var u: Dictionary = units[id]
	if u.side == 0:
		last_traversed = {"actor":id,"origin":pos(u),"path":[],"serial":int(last_traversed.get("serial",0))+1}
	if weapon_rules or terrain_rules_enabled or visibility_enabled:
		if weapon_rules: cancel_stance(u)
		if perk_rules: clear_sequence(u)
		for step in path:
			if visibility_enabled and (not living(u) or at(step) != -1 or not tile_visible(u.side,step)): break
			var previous = pos(u)
			var cost = movement_cost(u,previous,step)
			var fatigue = movement_fatigue(u,previous,step)
			# Incoming reaction fatigue can invalidate the rest of an accepted route.
			if terrain_rules_enabled and (cost >= 999 or u.ap < cost or u.fatigue+fatigue > fatigue_max(u)): break
			u.ap -= cost; u.fatigue += fatigue
			if terrain_rules_enabled and departure_stopped(u): break
			u.q = step.x; u.r = step.y
			if u.side == 0: last_traversed.path.append(step)
			refresh_visibility()
			if not core_rules: u.guard = false
			if weapon_rules and spearwall_reactions(id,previous):
				if u.side == 0 and living(u) and pos(u) != step:
					# Keep the route endpoint consistent with the actual pushback.
					last_traversed.path.pop_back()
					if pos(u) != previous: last_traversed.path.append(pos(u))
				break
			if not living(u): break
			if escape_unit(u): break
	else:
		var cost = legacy_cost if legacy_cost >= 0 else movement_path_quote(id,path).cost
		u.ap -= cost
		u.fatigue += cost * People.move_rate(u)
		u.q = target.x
		u.r = target.y
		u.guard = false
		escape_unit(u)
	commands.append(["move", id, target.x, target.y])
	report_broken_links(links)
	check_result()
	# Reactions must finish against the departing actor before ownership changes.
	# A dead/escaped mover cannot issue End; leave terminal outcomes untouched.
	if individual and active_id == id and not living(u): advance_if_spent()
	return true

func line_hex(a: Vector2i, b: Vector2i, t: float) -> Vector2i:
	var aa = axial(a); var bb = axial(b)
	var x = lerpf(aa.x,bb.x,t)+0.00001
	var z = lerpf(aa.y,bb.y,t)+0.00002
	var y = -x-z
	var rx = roundi(x); var ry = roundi(y); var rz = roundi(z)
	if absf(rx-x) > absf(ry-y) and absf(rx-x) > absf(rz-z): rx = -ry-rz
	elif absf(ry-y) <= absf(rz-z): rz = -rx-ry
	return offset(Vector2i(rx,rz))

func line_block_reason(a: Vector2i, b: Vector2i, allied_side: int = -1, ignore_id: int = -1) -> String:
	var length = distance(a, b)
	for i in range(1, length):
		var p = line_hex(a,b,float(i)/length)
		if terrain_rules_enabled:
			if tiles.get(key(p),{}).get("vision_blocking",false): return "An explicit terrain obstacle blocks the shot."
		elif tiles.has(key(p)) and tiles[key(p)].terrain in ["forest","wall"]: return "A wall blocks the shot." if tiles[key(p)].terrain == "wall" else "Trees block the shot."
		var occupant = at(p)
		if occupant >= 0 and occupant != ignore_id:
			# The shooter can fire over their immediately adjacent friendly rank.
			# Other bodies still block; this rule is identical for both sides.
			if units[occupant].side == allied_side and distance(a,p) == 1: continue
			return "Shot blocked by %s (%s)." % [units[occupant].name,"ally farther down the lane" if units[occupant].side == allied_side else "intervening unit"]
	return ""

func line_clear(a: Vector2i, b: Vector2i, allied_side: int = -1) -> bool:
	return line_block_reason(a,b,allied_side).is_empty()

func projectile_lane_visibility_reason(u: Dictionary, v: Dictionary) -> String:
	if not visibility_enabled or not u.weapon in Arsenal.RANGED: return ""
	# Admission must qualify the WHOLE dependency before any true occupancy
	# query. An unseen empty cell and an unseen body must refuse identically.
	var a = pos(u); var b = pos(v); var length = distance(a,b)
	for i in range(1,length):
		if not tile_visible(int(u.side),line_hex(a,b,float(i)/length)):
			return "Projectile lane is not fully in current party sight."
	return ""

func terrain_attack_reason(u: Dictionary, v: Dictionary, special: bool = false) -> String:
	var lane_reason = projectile_lane_visibility_reason(u,v)
	if not lane_reason.is_empty(): return lane_reason
	var a = pos(u); var b = pos(v); var gap = distance(a,b)
	var w = weapon_stats(u)
	var ranged: bool = u.weapon in Arsenal.RANGED
	var maximum = weapon_reach(u,special)
	var reason = TerrainRules.attack_reason(tiles.get(key(a),{}),tiles.get(key(b),{}),gap,int(w.get("min_range",1)),maximum,ranged)
	if not reason.is_empty(): return reason
	if ranged:
		var foes = adjacent_enemies(u,a)
		if not foes.is_empty(): return "Engaged by %s. Disengage before shooting." % units[foes[0]].name
		return line_block_reason(a,b,int(u.side) if weapon_rules else -1,int(u.id))
	if gap > 1:
		var middle = line_hex(a,b,0.5)
		if not tiles.has(key(middle)): return "No battlefield tile at the reach midpoint."
		var level: int = tiles[key(middle)].height
		if level > tiles[key(a)].height and (level-tiles[key(a)].height > 1 or level-tiles[key(b)].height > 1): return "High ground blocks the reach midpoint."
		# Retain the prototype's open/allied thrust lane. This is not vanilla cover.
		for p in neighbors(a):
			if distance(p,b) != 1 or not TerrainRules.tile_reason(tiles[key(p)]).is_empty() or tiles[key(p)].get("vision_blocking",false): continue
			var occupant = at(p)
			if occupant == -1 or units[occupant].side == u.side: return ""
		return "No open or allied lane for the thrust."
	return ""

func in_range(u: Dictionary, v: Dictionary, special: bool = false) -> bool:
	if terrain_rules_enabled: return terrain_attack_reason(u,v,special).is_empty()
	if not projectile_lane_visibility_reason(u,v).is_empty(): return false
	var w: Dictionary = weapon_stats(u)
	var d = distance(pos(u), pos(v))
	if d < int(w.get("min_range",1)) or d > weapon_reach(u,special): return false
	if special and Arsenal.family(u.weapon) == "axe" and d != 1: return false
	if u.weapon in Arsenal.RANGED:
		return (Arsenal.family(u.weapon) == "throwing" or adjacent_enemies(u, pos(u)).is_empty()) and line_clear(pos(u), pos(v),int(u.side) if weapon_rules else -1)
	# Spears can thrust past allies, but not through enemies.
	if d == 2:
		for p in neighbors(pos(u)):
			if distance(p, pos(v)) == 1 and not tiles[key(p)].terrain in ["water","wall"]:
				var occupant = at(p)
				if occupant == -1 or units[occupant].side == u.side: return true
		return false
	return true

func reach_block_reason(u: Dictionary, v: Dictionary, special: bool = false) -> String:
	if terrain_rules_enabled: return terrain_attack_reason(u,v,special)
	var lane_reason = projectile_lane_visibility_reason(u,v)
	if not lane_reason.is_empty(): return lane_reason
	var w: Dictionary = weapon_stats(u)
	var gap = distance(pos(u),pos(v))
	var minimum = int(w.get("min_range",1))
	var maximum = weapon_reach(u,special)
	if gap < minimum: return "Too close: %s needs at least %d hexes." % [w.name,minimum]
	if gap > maximum: return "Out of reach: %d hexes away; this action reaches %d." % [gap,maximum]
	if u.weapon in Arsenal.RANGED:
		var foes = adjacent_enemies(u,pos(u))
		if not foes.is_empty() and Arsenal.family(u.weapon) != "throwing": return "Engaged by %s. Withdraw before shooting." % units[foes[0]].name
		return line_block_reason(pos(u),pos(v),int(u.side) if weapon_rules else -1)
	if not in_range(u,v,special): return "No open or allied lane for the thrust."
	return ""

func hit_breakdown(a: int, b: int, special: bool = false, reaction: bool = false) -> Dictionary:
	if core_rules: return baseline_hit_breakdown(a,b,special,reaction)
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapon_stats(u)
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
		["Elevation",TerrainRules.height_modifier(tiles[key(pos(u))],tiles[key(pos(v))]) if terrain_rules_enabled else (int(tiles[key(pos(u))].height)-int(tiles[key(pos(v))].height))*12],
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
		if modifier != 0: parts.append({"name":special_info(u.weapon).name,"value":modifier})
	if individual:
		var effective_defence = defense_skill+shield_support(v)+line_support(v)+(10 if v.shield else 0)+(((30 if "shield_drill" in v.perks else 20) if v.shield else 10) if v.guard else 0)+(5 if v.temperament == "cautious" else 0)
		if effective_defence > 50: parts.append({"name":"Defence above 50: half value","value":ceili((effective_defence-50)*0.5)})
	var total = 0
	for part in parts: total += part.value
	return {"parts":parts,"raw":total,"chance":clampi(total,5,95)}

func hit_chance(a: int, b: int, special: bool = false, reaction: bool = false) -> int:
	return hit_breakdown(a,b,special,reaction).chance

func can_attack(a: int, b: int) -> bool:
	if not target_visibility_reason(a,b).is_empty(): return false
	if weapon_rules: return weapon_action_reason(a,false,b).is_empty()
	if not can_act(a) or b < 0 or b >= units.size(): return false
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapon_stats(u)
	return not u.routed and living(v) and u.side != v.side and u.ap >= w.ap and u.fatigue + attack_fatigue(u) <= fatigue_max(u) and in_range(u, v)

func attack_block_reason(a: int, b: int) -> String:
	var sight_reason = target_visibility_reason(a,b)
	if not sight_reason.is_empty(): return sight_reason
	if weapon_rules:
		var reason = weapon_action_reason(a,false,b)
		if not reason.is_empty(): return reason
		var cost = action_cost(units[a],false,b)
		return "Legal attack · %d AP / %d fatigue" % [cost.ap,cost.fatigue]
	if not can_act(a): return "Attacker cannot act now."
	if b < 0 or b >= units.size() or not living(units[b]) or units[a].side == units[b].side: return "Choose a living enemy."
	var u: Dictionary = units[a]
	if u.routed: return "Fleeing soldiers cannot attack."
	if u.ap < weapon_stats(u).ap: return "Insufficient AP."
	if u.fatigue+attack_fatigue(u) > fatigue_max(u): return "Insufficient free fatigue."
	var reason = reach_block_reason(u,units[b])
	if not reason.is_empty(): return reason
	return "Legal attack · %d AP / %d fatigue" % [weapon_stats(u).ap,attack_fatigue(u)]

func attack(a: int, b: int) -> bool:
	if weapon_rules: return use_weapon(a,false,b)
	if not can_attack(a, b): return false
	var u: Dictionary = units[a]
	var w: Dictionary = weapon_stats(u)
	u.ap -= int(w.ap)
	u.fatigue += attack_fatigue(u)
	u.guard = false
	commands.append(["attack", a, b])
	strike(a, b)
	check_result()
	return true

func strike(a: int, b: int, special: bool = false, reaction: bool = false, paid_fatigue: int = 0, spearwall: bool = false, wall_previous: Vector2i = Vector2i(-1,-1)) -> bool:
	var u: Dictionary = units[a]
	var v: Dictionary = units[b]
	var w: Dictionary = weapon_stats(u)
	# Capture disclosure at strike time, before lethal damage changes sight.
	var log_viewers = strike_log_viewers(a,b)
	var feedback_viewers: Array = []
	for team in [0,1]:
		if unit_visible(team,b):
			feedback_viewers.append({"team":team,"safe":not visibility_enabled or log_viewers.any(func(viewer): return viewer.team == team and viewer.safe)})
	# One presentation cue per actual strike, including reactions with no command row.
	var cue := {"id":b,"kind":"attack","actor":a,"strike_viewers":feedback_viewers,"special":special}
	if spearwall:
		cue.wall_entry = pos(v)
		cue.wall_previous = wall_previous
	combat_feedback.emit(cue)
	var attack_preview = hit_breakdown(a,b,special,reaction)
	var chance: int = attack_preview.chance
	var attack_roll = roll(1,100)
	if attack_roll > chance:
		var shield_before = int(v.get("arms",{}).get("shield",{}).get("condition",0))
		if core_rules:
			v.fatigue = mini(fatigue_max(v),v.fatigue+2)
			shield_block(v,u.weapon in Arsenal.RANGED,attack_roll,clampf(attack_preview.raw,5,95))
		var shield_loss = shield_before-int(v.get("arms",{}).get("shield",{}).get("condition",0))
		u["damage_shield"] = int(u.get("damage_shield",0))+shield_loss
		if v.get("damage_received") != null: v.damage_received += shield_loss
		if perk_rules: after_perk_attack(u,v,special,reaction,false,paid_fatigue)
		log_event("%s misses %s (%d%%)%s." % [u.name, v.name, chance, " — 0 HP / 0 armour lost" if not visibility_enabled else ""])
		var miss_damage = "0 HP / 0 armour lost" + ("; %d shield condition lost%s" % [shield_loss," (broken)" if not v.shield else ""] if shield_loss > 0 else "")
		publish_strike_log(log_viewers,u,v,chance,"misses", miss_damage, special,reaction)
		combat_feedback.emit({"id":b,"kind":"miss","shield":shield_loss,"strike_viewers":feedback_viewers,"text":"MISS · %d%%" % chance})
		if weapon_rules and not reaction and not u.weapon in Arsenal.RANGED and distance(pos(u),pos(v)) == 1 and v.get("stance","") == "riposte" and v.reactions > 0 and fighting(v) and v.fatigue+reaction_cost(v) <= fatigue_max(v) and (not terrain_rules_enabled or (terrain_can_react(v) and in_range(v,u))):
			v.reactions -= 1; v.fatigue += reaction_cost(v)
			log_event(v.name+" ripostes.")
			strike(b,a,false,true)
		return false
	var links = linked_shields()
	if core_rules: v.fatigue = mini(fatigue_max(v),v.fatigue+5)
	if weapon_rules and special and Arsenal.family(u.weapon) == "axe":
		var loss = mini(split_shield_damage(u,v),int(v.arms.shield.condition))
		v.arms.shield.condition -= loss
		u["damage_shield"] = int(u.get("damage_shield",0))+loss
		if v.get("damage_received") != null: v.damage_received += loss
		sync_arms(v)
		if not v.shield and v.order == "line" and Arsenal.family(v.weapon) != "spear": v.order = "free"
		log_event("%s splits %s’s shield: -%d condition%s%s." % [u.name,v.name,loss,"; shield broken" if not v.shield else "", "; %d%% hit chance" % chance if not visibility_enabled else ""])
		publish_strike_log(log_viewers,u,v,chance,"hits", "%d shield condition lost" % loss,special,reaction)
		combat_feedback.emit({"id":b,"kind":"shield","shield":loss,"strike_viewers":feedback_viewers,"text":"-%d SHIELD" % loss})
		report_broken_links(links)
		return true
	var hit = pooled_hit(u,v,w,special,reaction,spearwall) if damage_rules else legacy_damage(u,v,w,special,0.5 if spearwall else 1.0)
	refresh_equipment_slots(v)
	var head: bool = hit.head
	var layer: String = hit.layer
	var armor_loss: int = hit.armor
	var padding_loss: int = hit.padding
	var damage: int = hit.hp
	if perk_rules and damage >= v.hp and Perks.has(v,"nine_lives") and not vital_state(v).nine_used:
		vital_state(v).nine_used = true
		damage = maxi(0,v.hp-1)
		log_event(v.name+" survives with Nine Lives: 1 HP.")
	var actual = mini(v.hp,damage)
	# Outgoing this-battle totals use resolved loss, after remaining-HP/Nine Lives caps.
	u["damage_hp"] = int(u.get("damage_hp",0))+actual
	u["damage_armor"] = int(u.get("damage_armor",0))+armor_loss+padding_loss
	# Same resolved losses as outgoing; HP-only damage_taken remains injury accounting.
	# Unknown prior accounting stays unknown rather than becoming a partial total.
	if v.get("damage_received") != null: v.damage_received += actual+armor_loss+padding_loss
	v.damage_taken += actual
	v.last_attacker = u.name
	if actual > v.worst_hit:
		v.worst_hit = actual
		v.worst_head = head
	v.hp = maxi(0, int(v.hp) - damage)
	refresh_visibility()
	if perk_rules: after_perk_attack(u,v,special,reaction,true,paid_fatigue,head)
	publish_strike_log(log_viewers,u,v,chance,"hits", "%d HP / %d armour lost%s" % [actual,armor_loss+padding_loss," (head)" if head else ""],special,reaction)
	if damage_rules:
		var total_loss = armor_loss+padding_loss
		log_event("%s hits %s%s: %d armour / %d HP lost%s." % [u.name,v.name," (head)" if head else "",total_loss,actual,"; %d%% hit chance" % chance if not visibility_enabled else ""])
		combat_feedback.emit({"id":b,"kind":"hit","hp":actual,"armor":total_loss,"layer":layer,"head":head,"strike_viewers":feedback_viewers,"text":"-%d ARMOUR / -%d HP" % [total_loss,actual]})
	else:
		log_event("%s hits %s: %d HP / %d %s / %d padding%s." % [u.name, v.name, actual, armor_loss, "helm" if head else "mail",padding_loss,"; %d%% hit chance" % chance if not visibility_enabled else ""])
		combat_feedback.emit({"id":b,"kind":"hit","hp":actual,"armor":armor_loss,"padding":padding_loss,"layer":layer,"head":head,"strike_viewers":feedback_viewers,"text":"-%d HP / -%d %s" % [actual,armor_loss,"helm" if head else "mail"]})
	if v.hp == 0:
		u.kills += 1
		if core_rules:
			death_morale(u,v)
		elif individual:
			for other in units:
				if other.side == u.side and fighting(other) and distance(pos(other),pos(v)) <= 3: morale_check(other,0,"enemy fell",true)
		log_event("%s falls. The line shudders." % v.name)
		combat_feedback.emit({"id":b,"kind":"death","text":"FALLEN"})
		for other in units:
			if not core_rules and fighting(other) and other.side == v.side and distance(pos(other), pos(v)) <= 3: morale_loss(other, 24+(8 if v.id in other.comrades else 0),"comrade fell" if v.id in other.comrades else "ally fell")
	elif core_rules:
		if actual >= 15: baseline_morale_check(v,-40.0*(1.0-float(v.hp)/v.max_hp),"flesh wound")
	elif damage >= 8:
		morale_loss(v, 10 + (8 if v.hp < v.max_hp / 3.0 else 0),"severe wound" if v.hp < v.max_hp / 3.0 else "flesh wound")
	if weapon_rules and special and fighting(v):
		if Arsenal.family(u.weapon) == "mace":
			if axe_mace_rules: apply_stagger(v,"Staggering Blow")
			else:
				v.ap = maxi(0,v.ap-2); v.stagger = 2
				log_event(v.name+" is staggered: -2 current and next-turn AP.")
				combat_feedback.emit({"id":b,"kind":"stagger","text":"STAGGER · -2 AP"})
		elif Arsenal.family(u.weapon) == "polearm" and not (perk_rules and vital_state(v).indomitable):
			var destination = hook_tile(u,v)
			if destination != pos(v):
				v.q = destination.x; v.r = destination.y; v.guard = false; cancel_stance(v)
				refresh_visibility()
				if perk_rules: reset_segment(v)
				log_event(v.name+" is dragged one hex out of position.")
	if hammer_dagger_rules and not reaction and special and Arsenal.family(u.weapon) == "hammer" and Perks.has(u,"deep_impact") and actual > 0 and fighting(v):
		apply_deep_impact(v)
	if axe_mace_rules and not reaction and Arsenal.family(u.weapon) == "mace" and Perks.has(u,"concussive_strikes") and head and actual+armor_loss+padding_loss > 0:
		apply_stagger(v,"Concussive Strikes")
	if perk_rules and not reaction and Arsenal.family(u.weapon) == "crossbow" and Perks.has(u,"power_shot") and actual >= 10 and fighting(v) and v.stagger == 0 and not vital_state(v).indomitable and roll(1,100) <= 35:
		v.ap = maxi(0,v.ap-2); v.stagger = 2
		log_event(v.name+" is staggered by Power Shot: -2 current and next-turn AP.")
	report_broken_links(links)
	return true

func pooled_hit(u: Dictionary, v: Dictionary, w: Dictionary, special: bool, reaction: bool = false, spearwall: bool = false) -> Dictionary:
	if perk_rules: return perk_damage(u,v,w,special,reaction,spearwall)
	var family = Arsenal.family(u.weapon)
	var factor: float = {"mace":0.75,"dagger":0.8,"polearm":0.65,"bow":1.15}.get(family,1.0) if special else 1.0
	if core_rules and special and family == "bow": factor = 1.1
	var scale := 0.5 if spearwall else 1.0
	var regular = roll(int(w.min),int(w.max))*factor*scale
	var armour_roll = roll(int(w.min),int(w.max))*(1.0 if core_rules and special and family == "bow" else factor)*float(w.armor)*scale
	var head = roll(1,100) <= int(w.get("head_chance",25))
	var puncture = special and family == "dagger"
	if special and family in ["hammer","dagger"]: head = false
	if special and family == "hammer": armour_roll *= 2.0
	var protection: int = v.helmet if head else v.armor+v.padding
	var hit = Damage.resolve_hit(regular,armour_roll,1.0 if puncture else float(w.pierce),protection,head)
	var wear = {"armor":hit.armor,"padding":0}
	if head:
		v.helmet -= hit.armor
		Armor.damage_parts(v,"helmet",hit.armor)
	else:
		wear = Armor.damage_body(v,hit.armor)
	if special and family == "hammer": hit.hp = roundi(hit.hp*0.5)
	return {"head":head,"layer":"helmet" if head else "body","armor":wear.armor,"padding":wear.padding,"hp":hit.hp}

func legacy_damage(u: Dictionary, v: Dictionary, w: Dictionary, special: bool, scale: float = 1.0) -> Dictionary:
	var raw = roll(int(w.min), int(w.max))
	var head = roll(1, 100) <= 20
	if weapon_rules and special and Arsenal.family(u.weapon) in ["hammer","dagger"]: head = false
	if weapon_rules and special: raw = roundi(raw*{"mace":0.75,"dagger":0.8,"polearm":0.65,"bow":1.15}.get(Arsenal.family(u.weapon),1.0))
	if head: raw = roundi(raw * 1.3)
	if scale != 1.0: raw = roundi(raw*scale)
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
	return {"head":head,"layer":layer,"armor":armor_loss,"padding":padding_loss,"hp":damage}

func morale_loss(u: Dictionary, amount: int, cause: String = "shock") -> void:
	if u.get("faction","") == "undead": return
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
		log_event("%s breaks and flees toward a field edge." % u.name,unit_event_audience(u))
		combat_feedback.emit({"id":u.id,"kind":"route","text":"ROUTING"})
		for other in units:
			if other.side == u.side and other.id != u.id and fighting(other) and distance(pos(u), pos(other)) <= 2:
				morale_loss(other, 10,"nearby panic")

func guard_reason(id: int) -> String:
	if not can_act(id) or not fighting(units[id]): return "Select an active, fighting soldier."
	var u: Dictionary = units[id]
	if core_rules and not u.shield: return "Shieldwall needs a working shield."
	if u.guard: return "Shieldwall is already active."
	if u.ap < 4: return "Needs 4 AP."
	if u.fatigue+guard_fatigue(u) > fatigue_max(u): return "Needs %d free fatigue." % guard_fatigue(u)
	return ""

func guard_unit(id: int) -> bool:
	if not guard_reason(id).is_empty(): return false
	var u: Dictionary = units[id]
	u.ap -= 4
	u.fatigue += guard_fatigue(u)
	u.guard = true
	clear_weapon_sequence(u)
	if weapon_rules and not spearwall_active(u): cancel_stance(u)
	commands.append(["guard", id])
	log_event("%s %s." % [u.name, "raises a shieldwall" if u.shield else "braces"],[u.side])
	_observe_utility(u,"guard","shield")
	return true

func recover(id: int) -> bool:
	if not recover_reason(id).is_empty(): return false
	if weapon_rules and not spearwall_active(units[id]): cancel_stance(units[id])
	clear_weapon_sequence(units[id])
	var before: int = units[id].fatigue
	units[id].fatigue = floori(units[id].fatigue*(0.35 if perk_rules and (Perks.has(units[id],"deep_breath") or Perks.has(units[id],"endurance")) else 0.5)) if core_rules else maxi(0, int(units[id].fatigue) - (50 if "endurance" in units[id].perks else 35))
	units[id].ap = 0
	commands.append(["recover", id])
	log_event("%s catches a breath." % units[id].name,[units[id].side])
	combat_feedback.emit({"id":id,"kind":"recover","text":"-%d fatigue" % [before-units[id].fatigue]})
	_observe_utility(units[id],"recover","weapon")
	return true

func withdraw(id: int, target: Vector2i) -> bool:
	if not can_act(id) or units[id].ap < 4 or units[id].fatigue+12 > fatigue_max(units[id]): return false
	var u: Dictionary = units[id]
	if visibility_enabled and not tile_visible(u.side,target): return false
	if distance(pos(u), target) != 1 or at(target) != -1 or step_cost(pos(u), target) >= 999: return false
	var foes = adjacent_enemies(u, pos(u))
	if foes.is_empty(): return false
	u.ap -= 4
	u.fatigue += 12
	u.guard = false
	if weapon_rules: cancel_stance(u)
	if perk_rules: reset_segment(u)
	commands.append(["withdraw", id, target.x, target.y])
	var stopped = false
	if terrain_rules_enabled: stopped = departure_stopped(u)
	else:
		for foe in foes:
			if living(u) and (not weapon_rules or (not units[foe].weapon in Arsenal.RANGED and in_range(units[foe],u))): strike(int(foe), id,false,true)
	var links = linked_shields()
	if living(u) and not stopped:
		var previous = pos(u)
		u.q = target.x
		u.r = target.y
		refresh_visibility()
		if weapon_rules: spearwall_reactions(id,previous)
		if perk_rules: reset_segment(u)
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
			if fighting(u) and distance(pos(u), goal()) <= 1: control[int(u.side)] = 1
		for team in 2:
			held[team] = mini(3, int(held[team]) + 1) if control[team] == 1 and control[1-team] == -1 else 0
			if not withdrawing and objective != "eliminate" and held[team] >= 3 and (objective == "hold" or team == 1):
				result = "victory" if team == 0 else "defeat"
				log_event("The crossing is secured." if team == 0 else "The enemy controls the crossing.")
		if not withdrawing and objective in ["defend", "escort"] and round_no >= 8 and result.is_empty():
			result = "victory"
			log_event("The wagons are secured. Continue the escort to town." if objective == "escort" else "The relief column arrives. The ridge holds.")
		round_no += 1
		if not physical_escape_pending() and round_no > 30 and result.is_empty():
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

func begin_withdrawal() -> bool:
	if withdrawing or not result.is_empty(): return false
	withdrawing = true
	for u in units:
		if u.side != 0 or not living(u): continue
		u.routed = true; u.morale_state = -3; u.morale = morale_number(-3)
		u.order = "free"; u.guard = false; cancel_stance(u)
	log_event("The company withdraws: reach a passable field edge. Enemies can still strike.",[0])
	return true

func check_result() -> void:
	refresh_visibility()
	if not result.is_empty(): return
	var counts = [0, 0]
	for u in units:
		if living(u): counts[int(u.side)] += 1
	if counts[0] == 0: result = "defeat"
	elif counts[1] == 0 and not withdrawing: result = "victory"

# Planning projections only. Never filter authoritative occupancy/reaction helpers.
func ai_known_units(team: int) -> Array:
	return units if not visibility_enabled else units.filter(func(u): return u.side == team or unit_visible(team,u.id))

func ai_adjacent_enemies(u: Dictionary, from: Vector2i) -> Array:
	return adjacent_enemies(u,from).filter(func(id): return not visibility_enabled or unit_visible(u.side,id))

func ai_in_range(u: Dictionary, v: Dictionary) -> bool:
	if visibility_enabled:
		if not unit_visible(u.side,v.id): return false
		var length = distance(pos(u),pos(v))
		for i in range(1,length):
			if not tile_visible(u.side,line_hex(pos(u),pos(v),float(i)/length)): return false
	return in_range(u,v)

func ai_hit_score(actor: int, target: int, special: bool = false) -> int:
	if not visibility_enabled: return hit_chance(actor,target,special)
	# Heuristic only: do NOT inspect unobserved third-party shield/perk support.
	var u: Dictionary = units[actor]; var v: Dictionary = units[target]
	return int(u.ranged_skill if u.weapon in Arsenal.RANGED else u.skill)-int(v.ranged_defense if u.weapon in Arsenal.RANGED else v.defense)-(15 if v.shield else 0)

func ai_search_score(u: Dictionary, p: Vector2i) -> float:
	# Authored goal supplies a static rendezvous, never a hidden actor position.
	var anchor = Vector2i(clampi(goal().x+(1 if u.side == 0 else -1),0,width()-1),goal().y)
	return -float(distance(p,anchor))*4.0

func physical_escape_pending() -> bool:
	return withdrawing or units.any(func(u): return living(u) and u.routed)

func auto_step_needed() -> bool:
	return result.is_empty() and (side == 1 or (individual and active_id >= 0 and units[active_id].routed))

func ai_step() -> void:
	if individual and can_act(active_id) and units[active_id].routed:
		flee_step(active_id)
		return
	if individual and advance_if_spent(): return
	if not result.is_empty(): return
	if side == 1:
		coordinated_step()
		return
	for u in units:
		if not can_act(u.id) or u.ap <= 0: continue
		var id = int(u.id)
		if u.routed:
			flee_step(id)
			return
		if tactical_ai and ai_perk_step(id): return
		if weapon_rules and ai_weapon_step(id): return
		if u.fatigue >= fatigue_max(u)*0.65 and recover(id): return
		var target = -1
		var target_score = -999.0
		for v in ai_known_units(int(u.side)):
			if can_attack(id, int(v.id)):
				var score = ai_hit_score(id, int(v.id)) + (1.0 - float(v.hp) / v.max_hp) * 40.0 + (10 if v.weapon in Arsenal.RANGED else 0)
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
	if visibility_enabled and known_enemy_ids(u.side).is_empty(): return ai_search_score(u,p)
	var nearest = width()+height()
	for v in ai_known_units(int(u.side)):
		if living(v) and v.side != u.side: nearest = mini(nearest, distance(p, pos(v)))
	var score = -float(distance(p, goal())) * 2.2 if objective != "eliminate" else -float(nearest)*2.5
	if tactical_ai and objective == "eliminate" and not u.weapon in Arsenal.RANGED: score = -absf(nearest-weapon_reach(u))*2.5
	if u.weapon in Arsenal.RANGED: score -= absf(nearest - 4) * 3.5
	else: score -= maxf(0, nearest - (weapon_reach(u) if tactical_ai else 2 if Arsenal.family(u.weapon) in ["spear","polearm"] else 1)) * 1.4
	if tactical_ai and u.hp*2 < u.max_hp and (Perks.has(u,"footwork") or Perks.has(u,"rotation")): score -= (maxi(0,ai_adjacent_enemies(u,p).size()-1) if engagement_ai else ai_adjacent_enemies(u,p).size())*26
	score += float(tiles[key(p)].height) * 0.8
	if objective != "eliminate" and distance(p, goal()) <= 1: score += 3.0
	return score

func plan_enemy_turn() -> void:
	var roles = {}
	for u in units:
		if u.side != 1: continue
		roles[str(u.id)] = "archer" if u.weapon in Arsenal.RANGED else ("support" if ai_support(u) else ("screen" if u.shield else "flank"))
	var focus = -1
	var best = -INF
	for v in ai_known_units(1):
		if not living(v) or v.side != 0: continue
		var nearest = width()+height()
		for u in units:
			if fighting(u) and u.side == 1: nearest = mini(nearest,distance(pos(u),pos(v)))
		var score = (1.0-float(v.hp)/v.max_hp)*24-nearest*3+(12 if v.weapon in Arsenal.RANGED else 0)
		score += 8 if not visibility_enabled and spaced(v,pos(v)) else 0
		score += adjacent_enemies(v,pos(v)).size()*7
		score -= 0.0 if visibility_enabled else (shield_support(v)+line_support(v))*0.4
		if objective in ["defend","escort"]:
			score -= distance(pos(v),goal())*4
			if distance(pos(v),goal()) <= 1: score += 60
		elif objective != "eliminate" and distance(pos(v),goal()) <= 1: score += 10
		if score > best: best = score; focus = v.id
	enemy_plan = {"round":round_no,"focus":focus,"roles":roles}
	if focus >= 0: log_event("Enemy pressure turns toward %s; shields screen, spears support." % units[focus].name)

func enemy_role(u: Dictionary) -> String:
	if tactical_ai: return "archer" if u.weapon in Arsenal.RANGED else "support" if ai_support(u) else "screen" if u.shield else "flank"
	return enemy_plan.get("roles",{}).get(str(u.id),"archer" if u.weapon in Arsenal.RANGED else ("support" if ai_support(u) else ("screen" if u.shield else "flank")))

func ai_support(u: Dictionary) -> bool:
	return weapon_reach(u) > 1 if tactical_ai else Arsenal.family(u.weapon) in ["spear","polearm"]

func coordinated_step() -> void:
	if enemy_plan.is_empty() or enemy_plan.round != round_no or enemy_plan.focus < 0 or not living(units[enemy_plan.focus]) or (visibility_enabled and not unit_visible(1,enemy_plan.focus)): plan_enemy_turn()
	var actors = units.filter(func(u): return can_act(u.id) and u.side == 1 and u.ap > 0)
	actors.sort_custom(func(a,b):
		var pa = enemy_priority(a)
		var pb = enemy_priority(b)
		return pa < pb if pa != pb else a.id < b.id)
	for u in actors:
		var id = int(u.id)
		var role = enemy_role(u)
		if u.routed:
			flee_step(id)
			return
		if boss_tactics and DungeonTactics.step(self,u): return
		if tactical_ai and ai_perk_step(id): return
		if weapon_rules and ai_weapon_step(id): return
		# A trapped archer must pay for an ordinary, risky withdrawal.
		if role == "archer" and not ai_adjacent_enemies(u,pos(u)).is_empty() and u.ap >= 4 and u.fatigue+12 <= fatigue_max(u):
			var best = pos(u)
			var score = -INF
			for p in neighbors(pos(u)):
				if (visibility_enabled and not tile_visible(u.side,p)) or at(p) >= 0 or step_cost(pos(u),p) >= 999 or not ai_adjacent_enemies(u,p).is_empty(): continue
				var value = coordinated_position_score(u,p)
				if value > score: score = value; best = p
			if best != pos(u): withdraw(id,best); return
		if u.fatigue >= fatigue_max(u)*0.65 and recover(id): return
		# Orders consume the same AP and fatigue as company orders.
		if not core_rules and u.order == "free" and role in ["screen","support"] and u.ap == MAX_AP and not shield_neighbors(u,pos(u)).is_empty() and (not objective in ["defend","escort"] or distance(pos(u),goal()) <= 2):
			if set_order([id],"line"): return
		var target = -1
		var target_score = -INF
		for v in ai_known_units(int(u.side)):
			if can_attack(id,v.id):
				var score = ai_hit_score(id,v.id)+(1.0-float(v.hp)/v.max_hp)*35+(18 if v.id == enemy_plan.focus else 0)
				if score > target_score: target_score = score; target = v.id
		if target >= 0: attack(id,target); return
		var best_pos = pos(u)
		var best_score = coordinated_position_score(u,best_pos)
		for route in movement_map(id).values():
			var p: Vector2i = route.path.back()
			var score = coordinated_position_score(u,p)-route.cost*0.18
			# Preserve an attack after moving when possible; no free follow-up.
			if u.ap-route.cost < weapon_stats(u).ap: score -= 2.5
			if score > best_score+0.01: best_score = score; best_pos = p
		if best_pos != pos(u): move_unit(id,best_pos); return
		if not u.guard and guard_unit(id): return
		finish_unit(id)
		return
	end_turn()

func enemy_priority(u: Dictionary) -> int:
	if u.routed: return 0
	if u.weapon in Arsenal.RANGED and not ai_adjacent_enemies(u,pos(u)).is_empty(): return 1
	return {"screen":2,"support":3,"flank":4,"archer":5}[enemy_role(u)]

func coordinated_position_score(u: Dictionary, p: Vector2i) -> float:
	if visibility_enabled and known_enemy_ids(u.side).is_empty(): return ai_search_score(u,p)
	var role = enemy_role(u)
	var nearest = width()+height()
	var enemies: Array = []
	for v in ai_known_units(int(u.side)):
		if living(v) and v.side != u.side:
			enemies.append(v)
			nearest = mini(nearest,distance(p,pos(v)))
	var focus: Dictionary = units[enemy_plan.focus] if not enemy_plan.is_empty() and enemy_plan.focus >= 0 and (not visibility_enabled or unit_visible(u.side,enemy_plan.focus)) else (enemies[0] if not enemies.is_empty() else u)
	var clone = u.duplicate()
	clone.q = p.x
	clone.r = p.y
	var assault = objective in ["defend","escort"]
	var score = -distance(p,goal())*(5.5 if assault else 1.4) if objective != "eliminate" else 0.0
	score += tiles[key(p)].height*1.2
	var threats = ai_adjacent_enemies(u,p).size()
	if tactical_ai and u.hp*2 < u.max_hp and (Perks.has(u,"footwork") or Perks.has(u,"rotation")): score -= (maxi(0,threats-1) if engagement_ai else threats)*26
	if role == "archer":
		score -= absf(nearest-4)*4.0+threats*22.0
		var shot = false
		for v in enemies:
			if ai_in_range(clone,v): shot = true; break
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
			if ai_in_range(clone,v): score += 3; break
	elif role == "flank":
		score -= maxf(0,distance(p,pos(focus))-1)*2.4
		# Exposed approaches and outnumbering are worth more than a defended wall.
		if distance(p,pos(focus)) == 1:
			score += 7+adjacent_enemies(focus,pos(focus)).size()*3
			score -= 0.0 if visibility_enabled else (shield_support(focus)+line_support(focus))*0.25
		score -= maxi(0,threats-1)*6
		for id in ai_adjacent_enemies(u,p):
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
	if objective != "eliminate" and distance(p,goal()) <= 1 and role != "archer": score += 16 if assault else 4
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

func strike_log_viewers(actor: int, target: int) -> Array:
	var viewers: Array = []
	if not visibility_enabled: return viewers
	for team in [0,1]:
		if not unit_visible(team,actor) or not unit_visible(team,target): continue
		# Disclosure depends only on observable geometry, never hidden occupants.
		# Long Reach may affect surrounding from two hexes away; its lane is
		# within that target disk. All other chance and damage dependencies are
		# local to the two participants or their adjacent cells.
		var safe = true
		for center in [pos(units[actor]),pos(units[target])]:
			if not tile_visible(team,center): safe = false
			for cell in neighbors(center):
				if not tile_visible(team,cell): safe = false
		for cell in neighbors(pos(units[target])):
			for outer in neighbors(cell):
				if not tile_visible(team,outer): safe = false
		viewers.append({"team":team,"safe":safe})
	return viewers

func publish_strike_log(viewers: Array, attacker: Dictionary, target: Dictionary, chance: int, outcome: String, damage: String, special: bool, reaction: bool) -> void:
	for viewer in viewers:
		var kind = "reaction" if reaction else (special_info(attacker.weapon).name if special else Arsenal.primary(attacker.weapon))
		var numbers = "%d%% hit chance; %s" % [chance,damage] if viewer.safe else "hit chance unavailable; damage unavailable"
		log_public_event("%s %s %s [%s] — %s." % [attacker.name,outcome,target.name,kind,numbers],[viewer.team])

func public_events(team: int) -> Array[String]:
	var out: Array[String] = []
	if not team in [0,1]: return out
	for message in (_public_events[team] if visibility_enabled else events): out.append(str(message))
	return out

func log_public_event(message: String, audience: Array) -> void:
	if not visibility_enabled: return
	for team in [0,1]:
		if not team in audience: continue
		_public_events[team].append(message)
		if _public_events[team].size() > 100: _public_events[team].pop_front()

func log_event(message: String, audience: Array = []) -> void:
	# Audience is declared at emission by a trusted call site, never inferred
	# from names or current/future sight. Unqualified legacy strings fail closed.
	events.append(message)
	if events.size() > 100: events.pop_front()
	log_public_event(message,audience)

func weapon_stats(u: Dictionary) -> Dictionary:
	if Undead.intrinsic(u): return Undead.strike_profile(u)
	if u.weapon.is_empty():
		# Presentation-only empty profile, never a physical item or usable attack.
		return {"name":"Unarmed","min":0,"max":0,"ap":0,"fatigue":0,"reach":0,"pierce":0.0,"armor":0.0,"skill":0,"hands":0,"ranged":false,"ammo":"","min_range":1,"family":"","tier":0,"description":"No weapon equipped.","head_chance":0}
	return Named.weapon(u.get("arms",{}).get("weapon",{}),weapons[u.weapon])

func has_named_equipment() -> bool:
	for u in units:
		for item in u.get("arms",{}).values():
			if item.has("named"): return true
		for part in u.get("armor_parts",[]):
			if part.has("named"): return true
	return false

func snapshot() -> Dictionary:
	var saved = {"version":(25 if roster_rules else 24) if boss_tactics else 23 if roster_rules and (has_named_equipment() or is_crypt()) else 21 if roster_rules else 22 if is_crypt() else 21 if has_named_equipment() else 20 if inventory_rules else 19 if hammer_dagger_rules else 18 if axe_mace_rules else 17 if engagement_ai else 16 if double_grip_rules else 15 if tactical_ai else 14,"perk_rules":perk_rules,"core_rules":core_rules,"damage_rules":damage_rules,"individual":individual,"active_id":active_id,"turn_queue":turn_queue.duplicate(),"delayed":delayed.duplicate(),"activated":activated.duplicate(),"finished":finished.duplicate(),"waited":waited.duplicate(),"turn_scores":turn_scores.duplicate(), "weapon_rules":weapon_rules, "shared_line":shared_line.duplicate(true), "enemy_plan":enemy_plan.duplicate(true), "map":map_id, "objective":objective, "units":units.duplicate(true), "round":round_no, "side":side, "result":result, "rng":rng_state, "seed":seed_value, "held":held.duplicate(), "events":events.duplicate(), "commands":commands.duplicate(true)}

	# Orthogonal to combat-rules versions: required counters in current payloads.
	saved["damage_metrics_version"] = 1
	saved["damage_received_version"] = 1
	saved["withdrawing"] = withdrawing
	if roster_rules: saved["ambush"] = ambush
	return saved

func restore(data: Variant) -> bool:
	if not data is Dictionary: return false
	data = normalize_json_numbers(data)
	if data.has("withdrawing") and not data.withdrawing is bool: return false
	if data.has("damage_metrics_version"):
		if not data.damage_metrics_version is int or data.damage_metrics_version != 1: return false
	if data.has("damage_received_version"):
		if not data.damage_received_version is int or data.damage_received_version != 1: return false
	for field in ["version", "units", "round", "side", "result", "rng", "seed", "held", "events", "commands"]:
		if not data.has(field): return false
	for field in ["version", "round", "side", "rng", "seed"]:
		if not data[field] is int: return false
	var expanded = data.get("version") in [23,25] or (data.get("version") == 21 and data.has("ambush"))
	if not data.version in range(1,26) or not data.units is Array or data.units.size() != (24 if expanded else 12): return false
	var slots = 12 if expanded else 6
	var total = slots*2
	if expanded and not data.get("ambush") is bool: return false
	if not expanded and data.has("ambush"): return false
	if not data.side in [0, 1] or data.round < 1: return false
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
	if not map_name in ["ford", "forest", "ridge", "crypt", "crypt_barrow", "crypt_gallery", "crypt_throne"]+DungeonThemes.FIELDS or not mission in ["hold", "eliminate", "defend", "escort"]: return false
	if map_name in DungeonThemes.FIELDS and (not expanded or mission != "eliminate"): return false
	if data.version in [24,25] and (not map_name in ["crypt_barrow","crypt_gallery","crypt_throne"]+DungeonThemes.FIELDS or mission != "eliminate"): return false
	if (map_name.begins_with("crypt") and data.version not in [22,23,24,25]) or (data.version == 22 and not map_name.begins_with("crypt")): return false
	var terrain_check = get_script().new()
	terrain_check.setup(int(data.seed), map_name, mission,false,false,false,false,false,expanded)
	var plan = data.get("enemy_plan",{}) if data.version >= 4 else {}
	if not plan is Dictionary: return false
	if data.version >= 4 and not data.has("enemy_plan"): return false
	if not plan.is_empty():
		if not plan.get("round") is int or plan.round < 1 or plan.round > data.round: return false
		if not plan.get("focus") is int or plan.focus < -1 or plan.focus >= slots: return false
		if not plan.get("roles") is Dictionary or plan.roles.size() != slots: return false
		for id in range(slots,total):
			if plan.roles.get(str(id),"") not in ["screen","support","flank","archer"]: return false
	var shared = data.get("shared_line") if data.version >= 5 else []
	if not shared is Array or shared.size() > slots*(slots-1): return false
	var links = {}
	for pair in shared:
		if not pair is Array or pair.size() != 2 or not pair[0] is int or not pair[1] is int: return false
		if pair[0] < 0 or pair[1] >= total or pair[0] >= pair[1] or pair[0]/slots != pair[1]/slots or links.has(str(pair)): return false
		links[str(pair)] = true
	var modern = data.get("weapon_rules",false) if data.version >= 8 else false
	if not modern is bool: return false
	var new_turns = data.get("individual",false) if data.version >= 10 else false
	if not new_turns is bool or (new_turns and not modern): return false
	if data.version >= 10 and not valid_turn_state(data): return false
	var pooled = data.get("damage_rules",false) if data.version >= 11 else false
	if data.version >= 11 and not data.has("damage_rules"): return false
	if not pooled is bool or (pooled and (not modern or not new_turns)): return false
	var check_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json" if pooled else "res://data/legacy_equipment_v14.json"))
	var baseline = data.get("core_rules",false) if data.version >= 12 else false
	if data.version >= 12 and not data.has("core_rules"): return false
	if not baseline is bool or (baseline and not pooled): return false
	var check_weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json" if baseline else "res://data/legacy_weapons_v15.json" if pooled else "res://data/legacy_weapons_v14.json"))
	var personal = data.get("perk_rules",false) if data.version >= 13 else false
	if not personal is bool or (personal and not baseline) or (data.version >= 13 and not data.has("perk_rules")): return false
	if data.version >= 15 and not personal: return false
	var equipment_ids = {}
	var occupied: Dictionary = {}
	for i in data.units.size():
		var u = data.units[i]
		if not u is Dictionary: return false
		if u.has("faction"):
			if data.version not in [22,23,24,25] or not map_name.begins_with("crypt") or u.faction != "undead" or i < slots or not preload("res://src/undead.gd").TYPES.has(u.get("undead_kind","")) or u.get("morale_state") != 0 or u.get("routed") != false or u.get("escaped") != false: return false
		elif u.has("undead_kind"): return false
		if personal and data.version == 13 and u.get("perk_state") is Dictionary:
			for k in ["bow_shots","throws_used","head_ready"]:
				if not u.perk_state.has(k): u.perk_state[k] = Perks.state()[k]
		if personal and not Perks.valid_state(u.get("perk_state"),total,terrain_check.width(),terrain_check.height()): return false
		if data.version >= 19 and not valid_weapon_perk_state(u.get("weapon_perk_state"),total): return false
		if not u.get("weapon") is String or not check_weapons.has(u.weapon) or not u.get("shield") is bool: return false
		if data.version < 8: initialize_arms(u)
		if not Arsenal.valid_arms(u.get("arms"),check_catalog): return false
		if not Perks.has(u,"bags_and_belts") and ["carry3","carry4"].any(func(slot): return not u.arms.get(slot,{}).is_empty()): return false
		for item in u.arms.values():
			if item.is_empty(): continue
			if item.has("named") and data.version < 21: return false
			if equipment_ids.has(item.id): return false
			equipment_ids[item.id] = true
		if u.get("weapon") != u.arms.weapon.definition or u.get("shield") != (not u.arms.shield.is_empty() and u.arms.shield.condition > 0): return false
		if not u.get("stance") in ["","riposte","brace"] or not u.get("reactions") is int or u.reactions < 0 or u.reactions > 2 or not u.get("stagger") is int or not u.stagger in [0,2]: return false
		if (u.stance == "riposte" and Arsenal.family(u.weapon) != "sword") or (u.stance == "brace" and Arsenal.family(u.weapon) != "spear"): return false
		if u.stance.is_empty() and u.reactions != 0: return false
		if data.version < 7: u["armor_parts"] = []; u["load"] = 0
		if not Armor.valid_battle_parts(u.get("armor_parts"),check_catalog) or not u.get("load") is int or u.load < 0 or u.load > 100: return false
		for part in u.armor_parts:
			if part.has("named") and data.version < 21: return false
			if equipment_ids.has(part.item): return false
			equipment_ids[part.item] = true
		if not u.armor_parts.is_empty():
			var stats = Armor.totals(u.armor_parts)
			for field in stats:
				if u.get(field) != stats[field]: return false
		if data.version < 6:
			for pair in [["endurance",25],["mobility",3],["resolve",0],["temperament","none"]]: u[pair[0]] = pair[1]
		for spec in ([["endurance",15,48],["mobility",2,4],["resolve",10,204],["stamina",60,254],["initiative",50,245],["ranged_skill",0,204],["ranged_defense",0,154],["morale_state",-3,1]] if new_turns else [["endurance",15,48],["mobility",2,4],["resolve",-5,12]]):
			if not u.get(spec[0]) is int or u[spec[0]] < spec[1] or u[spec[0]] > spec[2]: return false
		if new_turns and (u.get("stat_rules") != true or u.routed != (u.morale_state == -3) or u.morale != morale_number(u.morale_state)): return false
		if baseline and (not u.get("fleeing_rounds") is int or u.fleeing_rounds < 0 or u.fleeing_rounds > maxi(31,data.round)): return false
		if not u.get("temperament") is String or not People.TEMPERAMENTS.has(u.temperament): return false
		if data.version < 5:
			u["comrades"] = []
			u["strain_penalty"] = 0
			u["grief_penalty"] = 0
		if not u.get("comrades") is Array or u.comrades.size() >= slots: return false
		var friends = {}
		for id in u.comrades:
			if not id is int or id < 0 or id >= total or id == i or id/slots != i/slots or friends.has(id): return false
			friends[id] = true
		if not u.get("strain_penalty") is int or not u.get("grief_penalty") is int: return false
		if u.strain_penalty < 0 or u.strain_penalty > 12 or u.strain_penalty%2 != 0 or u.grief_penalty < 0 or u.grief_penalty > 8 or u.grief_penalty%4 != 0: return false
		if i >= slots and (not u.comrades.is_empty() or u.strain_penalty != 0 or u.grief_penalty != 0): return false
		if data.version < 4: u["order"] = "free"
		if not u.get("order") is String or not ORDERS.has(u.order): return false
		if data.version < 3:
			u["perks"] = []
			u["scars"] = []
			u["damage_taken"] = 0
			u["worst_hit"] = 0
			u["worst_head"] = false
			u["last_attacker"] = ""
		for pair in [["perks",all_perk_definitions() if personal else Progression.PERKS],["scars",Progression.SCARS]]:
			if not u.get(pair[0]) is Array: return false
			var unique = {}
			for id in u[pair[0]]:
				if not id is String or not pair[1].has(id) or unique.has(id): return false
				unique[id] = true
		if u.perks.size() > (10 if personal else Progression.PERKS.size()) or u.scars.size() > 2 or not u.get("worst_head") is bool or not u.get("last_attacker") is String: return false
		for field in ["damage_taken","worst_hit"]:
			if not u.get(field) is int or u[field] < 0: return false
		for field in ["damage_hp","damage_armor","damage_shield"]:
			# Missing pre-extension totals start neutrally; never infer from prose.
			if not u.has(field) and not data.has("damage_metrics_version"): u[field] = 0
			if not u.get(field) is int or u[field] < 0: return false
		if not u.has("damage_received"):
			if data.has("damage_received_version"): return false
			u["damage_received"] = null # Explicitly unrecorded, not a known zero.
		if u.damage_received != null and (not u.damage_received is int or u.damage_received < 0): return false
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
		if u.id != i or not check_weapons.has(u.weapon) or u.side != (0 if i < slots else 1): return false
		if u.q < 0 or u.q >= terrain_check.width() or u.r < 0 or u.r >= terrain_check.height() or u.hp < 0 or u.ap < 0 or u.ap > MAX_AP or u.fatigue < 0 or u.fatigue > (254 if new_turns else 100): return false
		if u.max_hp <= 0 or u.hp > u.max_hp or u.armor < 0 or u.padding < 0 or u.helmet < 0 or u.morale < 0 or u.morale > 100: return false
		if u.hp > 0 and not u.escaped:
			if terrain_check.tiles[key(pos(u))].terrain in ["water","wall"]: return false
			if occupied.has(key(pos(u))): return false
			occupied[key(pos(u))] = true
	for u in data.units:
		for id in u.comrades:
			if not u.id in data.units[id].comrades: return false
	# Presence of the validated boolean marks the physical-retreat extension.
	# Its rounds can outlive the last pending runner (death, escape or rally).
	# Payloads predating that extension retain the original round ceiling.
	if data.round > 31 and not data.has("withdrawing"): return false
	if data.get("withdrawing",false):
		if data.result not in ["","defeat"]: return false
		if data.units.any(func(u): return u.side == 0 and u.hp > 0 and not u.escaped and not u.routed): return false
	if data.version in [24,25] and data.units.filter(func(u):return u.side == 1 and u.get("undead_kind","") in DungeonTactics.BOSSES).size() != 1: return false
	setup(int(data.seed), map_name, mission, modern, new_turns, pooled, baseline, personal,expanded,data.get("ambush",false))
	boss_tactics = data.version in [24,25]
	individual = new_turns
	tactical_ai = data.version >= 15
	engagement_ai = data.version >= 17
	axe_mace_rules = data.version >= 18
	hammer_dagger_rules = data.version >= 19
	inventory_rules = data.version >= 20
	double_grip_rules = data.version >= 16
	if data.version >= 10:
		active_id = data.active_id
		turn_queue = data.turn_queue.duplicate(); delayed = data.delayed.duplicate(); activated = data.activated.duplicate(); finished = data.finished.duplicate(); waited = data.waited.duplicate(); turn_scores = data.turn_scores.duplicate()
	units = data.units.duplicate(true)
	round_no = int(data.round)
	side = int(data.side)
	result = str(data.result)
	withdrawing = data.get("withdrawing",false)
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
	if perk_rules: return perk_action_cost(u,false).fatigue
	return maxi(1,int(weapon_stats(u).fatigue)+(0 if u.get("stat_rules",false) else Armor.tier(u.get("load",0)))+(4 if u.temperament == "aggressive" else 0)-(4 if "weapon_drill" in u.perks else 0))

func guard_fatigue(u: Dictionary) -> int:
	if perk_rules: return Perks.fatigue_cost(u,20+(5 if u.temperament == "restless" else 0),false)
	if core_rules: return 20+(5 if u.temperament == "restless" else 0)
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
	u.weapon = u.arms.weapon.get("definition","")
	u.shield = not u.arms.shield.is_empty() and u.arms.shield.condition > 0
	refresh_equipment_slots(u)
	if u.side == 1 and not enemy_plan.is_empty(): enemy_plan.roles[str(u.id)] = "archer" if u.weapon in Arsenal.RANGED else "support" if Arsenal.family(u.weapon) in ["spear","polearm"] else "screen" if u.shield else "flank"

func refresh_equipment_slots(u: Dictionary) -> void:
	# Effects reuse the stage-captured final bases; never reinstall after wear/switch.
	if u.get("inventory_balance",false): preload("res://hollow_campaign/equipment_effects.gd").refresh(u,armor_catalog)
	# Detached presentation only. Rebuild from the live physical battle authority.
	if not u.get("hollow_systems",false): return
	var slots: Dictionary = {}
	var priorities := {}
	for part in u.get("armor_parts",[]):
		var slot: String = part.get("hollow_slot",part.group)
		if slot in ["body","head"]:
			var priority: int = {"outer":6,"mail":5,"base":4,"shell":6,"padding":4}.get(part.layer,0)
			if priorities.get(slot,-1) >= priority: continue
			priorities[slot] = priority
		slots[slot] = {"id":part.item,"definition":part.definition,"condition":part.condition,"maximum":part.maximum}
		for key in ["named","instance_roll"]:
			if part.has(key): slots[slot][key] = part[key].duplicate(true)
	for slot in ["weapon","shield","ammo"]:
		var item: Dictionary = u.arms.get(slot,{})
		if item.is_empty(): continue
		var projected := {"id":item.id,"definition":item.definition,"condition":item.condition,"maximum":int(Named.definition(item,armor_catalog).durability)}
		for key in ["named","instance_roll"]:
			if item.has(key): projected[key] = item[key].duplicate(true)
		slots[{"weapon":"mainhand","shield":"offhand"}.get(slot,slot)] = projected
	u["equipment_slots"] = slots

func cancel_stance(u: Dictionary) -> void:
	u.stance = ""; u.reactions = 0

func ammo_count(u: Dictionary) -> int:
	if Arsenal.family(u.weapon) == "throwing": return int(u.arms.weapon.condition)
	return int(u.arms.ammo.get("condition",0)) if not Arsenal.ammo_type(u.weapon).is_empty() and Arsenal.ammo_kind(u.arms.ammo.get("definition",""),armor_catalog) == Arsenal.ammo_type(u.weapon) else 0

func action_quote(id: int, action: String, target: int = -1, hex: Vector2i = Vector2i(-1,-1), slot: String = "") -> Dictionary:
	# Detached values only; never sample RNG, restore a snapshot or mutate wear.
	var q = {"action":action,"name":action.capitalize(),"legal":false,"reason":"Select a fighting soldier on their turn.","ap":0,"fatigue":0,"target_kind":"none","hit":{},"damage":{},"ammo":0}
	if id < 0 or id >= units.size(): return q
	var u: Dictionary = units[id]
	if action in ["basic","special"] and not target_visibility_reason(id,target).is_empty():
		q.reason = target_visibility_reason(id,target)
		return q
	if action not in ["basic","special"]:
		match action:
			"guard":
				q.name = "Shieldwall" if u.shield else "Guard"
				q.ap = 4; q.fatigue = guard_fatigue(u); q.reason = guard_reason(id)
			"recover":
				q.ap = int(u.ap); q.reason = recover_reason(id)
			"wait": q.reason = "" if can_wait(id) else "Cannot wait again or no other activation remains."
			"end": q.reason = "" if can_act(id) else "Only the active soldier can finish."
			"switch":
				q.name = "Switch carried item"
				q.ap = switch_ap(u,slot); q.fatigue = switch_fatigue(); q.reason = switch_reason(id,slot)
			"rotation","footwork","indomitable":
				var cost = active_perk_cost(u,action)
				q.ap = cost.ap; q.fatigue = cost.fatigue
				q.target_kind = "ally" if action == "rotation" else "hex" if action == "footwork" else "none"
				q.reason = perk_action_reason(id,action,hex)
			_: q.reason = "Unknown combat action."
		q.legal = q.reason.is_empty()
		return q
	var special = action == "special"
	q.name = special_info(u.weapon).name if special else primary_attack_name(u)
	q.target_kind = "enemy" if not special or special_info(u.weapon).target else "none"
	if target < -1 or target >= units.size():
		q.reason = "Choose a living enemy."
		return q
	var cost = action_cost(u,special,target)
	q.ap = cost.ap; q.fatigue = cost.fatigue
	q.ammo = ammo_count(u) if u.weapon in Arsenal.RANGED else 0
	q.reason = weapon_action_reason(id,special,target)
	q.legal = q.reason.is_empty()
	if q.legal and q.target_kind == "enemy":
		if combat_preview_neighborhood_visible(id,target):
			q.hit = hit_breakdown(id,target,special)
			q.damage = damage_preview(id,target,special)
		else:
			q["preview_reason"] = "Exact forecast unavailable: nearby ground is out of sight."
	return q

func combat_preview_neighborhood_visible(actor: int, target: int) -> bool:
	if not visibility_enabled: return true
	# Shield/support/spacing/surround/Target Practice/ribs read adjacent cells.
	# Long Reach reads known same-side allies at distance two; their possible
	# thrust-lane occupants are adjacent to the target too. Own actors are public.
	# Inspect geometry ONLY: searching for an actual unseen supporter is an oracle.
	var team: int = units[actor].side
	for center in [pos(units[actor]),pos(units[target])]:
		if not tile_visible(team,center): return false
		for cell in neighbors(center):
			if not tile_visible(team,cell): return false
	return true

func perform_action(id: int, action: String, target: int = -1, hex: Vector2i = Vector2i(-1,-1), slot: String = "") -> bool:
	# Revalidate at commit; a previously displayed quote grants no authority.
	if not action_quote(id,action,target,hex,slot).legal: return false
	match action:
		"basic","special": return use_weapon(id,action == "special",target)
		"guard": return guard_unit(id)
		"recover": return recover(id)
		"wait": return wait_unit(id)
		"switch": return switch_carried(id,slot)
		"rotation","footwork","indomitable": return use_perk(id,action,hex)
		"end": end_turn(); return true
	return false

func primary_attack_name(u: Dictionary) -> String:
	return str(weapon_stats(u).name) if Undead.intrinsic(u) else Arsenal.primary(u.weapon)

func action_cost(u: Dictionary, special: bool, target: int = -1) -> Dictionary:
	if u.weapon.is_empty() and (special or not Undead.intrinsic(u)): return {"ap":0,"fatigue":0}
	if special and Arsenal.family(u.weapon) == "spear":
		var wall = Arsenal.special(u.weapon)
		var specialist = perk_rules and Perks.has(u,"spearwaller")
		return {"ap":int(wall.ap)-(1 if specialist else 0),"fatigue":Perks.fatigue_cost(u,wall.fatigue,true,false,0.75 if specialist else 1.0) if perk_rules else wall.fatigue}
	if perk_rules: return perk_action_cost(u,special,target)
	if not special: return {"ap":int(weapon_stats(u).ap),"fatigue":attack_fatigue(u)}
	var w: Dictionary = weapon_stats(u); var base: Dictionary = weapons.get(Arsenal.family(u.weapon),w)
	return {"ap":int(w.get("special_ap",maxi(w.ap,special_info(u.weapon).ap))),"fatigue":maxi(1,int(w.get("special_fatigue",special_info(u.weapon).fatigue+w.fatigue-base.fatigue))+(0 if u.get("stat_rules",false) else Armor.tier(u.load))+(4 if u.temperament == "aggressive" else 0)-(4 if "weapon_drill" in u.perks else 0))}

func hook_tile(u: Dictionary, v: Dictionary) -> Vector2i:
	for p in neighbors(pos(v)):
		if distance(p,pos(u)) == 1 and at(p) < 0 and step_cost(pos(v),p) < 999: return p
	return pos(v)

func weapon_action_reason(id: int, special: bool, target: int = -1) -> String:
	var sight_reason = target_visibility_reason(id,target)
	if not sight_reason.is_empty(): return sight_reason
	if not weapon_rules: return "Weapon actions become available in the next deployment."
	if not can_act(id) or not fighting(units[id]): return "Select a fighting soldier on their turn."
	if target < -1 or target >= units.size(): return "Choose a living enemy."
	var u: Dictionary = units[id]
	if u.weapon.is_empty() and (special or not Undead.intrinsic(u)): return "Equip a weapon to use this action."
	var cost = action_cost(u,special,target)
	if u.ap < cost.ap: return "Needs %d AP." % cost.ap
	if u.fatigue+cost.fatigue > fatigue_max(u): return "Needs %d free fatigue." % cost.fatigue
	if perk_rules and special and Arsenal.family(u.weapon) == "sword" and u.weapon in Arsenal.TWO_HANDS: return "Riposte requires a one-handed sword."
	if special and Arsenal.family(u.weapon) == "polearm" and target >= 0 and distance(pos(u),pos(units[target])) != 2: return "Hook and drag requires two hexes."
	if special and not special_info(u.weapon).target:
		if Arsenal.family(u.weapon) == "spear":
			if spearwall_active(u): return "Spearwall is already active."
			if not terrain_can_react(u): return "This soldier cannot set a Spearwall."
			if not spearwall_mastered(u) and not adjacent_enemies(u,pos(u)).is_empty(): return "Cannot set Spearwall while engaged without Spear Mastery."
			return ""
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
	var cost = action_cost(u,special,target)
	u.ap -= cost.ap; u.fatigue += cost.fatigue
	if not core_rules or perk_rules: u.guard = false
	if not spearwall_active(u): cancel_stance(u)
	commands.append(["weapon",id,"special" if special else "basic",target])
	var reloaded_uid := ""
	if special and not special_info(u.weapon).target:
		clear_weapon_sequence(u)
		if Arsenal.family(u.weapon) == "crossbow":
			u.arms.weapon.loaded = true
			reloaded_uid = u.arms.weapon.id
		elif Arsenal.family(u.weapon) == "spear":
			u.stance = "brace" # Internal save/art key. The effect itself has no charge counter.
		else: u.stance = "riposte"; u.reactions = 2
		log_event("%s: %s · %d AP / %d fatigue." % [u.name,special_info(u.weapon).name,cost.ap,cost.fatigue])
	else:
		if u.weapon in Arsenal.RANGED:
			if Arsenal.family(u.weapon) == "throwing": u.arms.weapon.condition -= 1
			else: u.arms.ammo.condition -= 1
			if Arsenal.family(u.weapon) == "crossbow": u.arms.weapon.loaded = false
			refresh_equipment_slots(u)
		log_event("%s: %s." % [u.name,special_info(u.weapon).name if special else primary_attack_name(u)])
		strike(id,target,special,false,cost.fatigue)
	check_result()
	# A nested riposte may kill the attacker; finish only after its chain returns.
	if individual and active_id == id and not living(u): advance_if_spent()
	# A passive effect for the already-paid action, not a second command.
	if not reloaded_uid.is_empty(): weapon_reload_committed.emit(id,reloaded_uid)
	elif special and not special_info(u.weapon).target and u.stance in ["riposte","brace"]: _observe_utility(u,u.stance,"weapon")
	return true

func switch_reason(id: int, slot: String) -> String:
	if not weapon_rules or not can_act(id) or not fighting(units[id]) or not slot in Arsenal.bag_slots(units[id]): return "Select a carried item on this soldier's turn."
	var u: Dictionary = units[id]
	var item: Dictionary = u.arms[slot]
	if item.is_empty(): return "Carried slot is empty."
	if u.ap < switch_ap(u,slot) or u.fatigue+switch_fatigue() > fatigue_max(u): return "Switching costs %d AP and %d fatigue." % [switch_ap(u,slot),switch_fatigue()]
	if Arsenal.shield(item.definition) and u.weapon in Arsenal.TWO_HANDS: return "Switch to a one-handed weapon before raising the carried shield."
	if item.definition in Arsenal.TWO_HANDS and not u.arms.shield.is_empty():
		if empty_bag(u,slot).is_empty(): return "Free another carried slot to stow your shield."
	return ""

func switch_carried(id: int, slot: String) -> bool:
	if not switch_reason(id,slot).is_empty(): return false
	var u: Dictionary = units[id]
	var links = linked_shields()
	var item: Dictionary = u.arms[slot]
	var paid_ap = switch_ap(u,slot)
	if perk_rules and paid_ap == 0: vital_state(u).quick_used = true
	var destination = "shield" if Arsenal.shield(item.definition) else "ammo" if not Arsenal.ammo_kind(item.definition,armor_catalog).is_empty() else "weapon"
	if item.definition in Arsenal.TWO_HANDS and not u.arms.shield.is_empty():
		u.arms[empty_bag(u,slot)] = u.arms.shield
		u.arms.shield = {}
	u.arms[slot] = u.arms[destination]
	u.arms[destination] = item
	u.ap -= paid_ap; u.fatigue += switch_fatigue(); u.guard = false; cancel_stance(u); sync_arms(u)
	if perk_rules: reset_segment(u)
	if u.order == "line" and not u.shield and Arsenal.family(u.weapon) != "spear": u.order = "free"
	commands.append(["switch",id,slot])
	log_event("%s switches to %s: %d AP / %d fatigue." % [u.name,Named.definition(item,armor_catalog).name,paid_ap,switch_fatigue()],[u.side])
	report_broken_links(links)
	_observe_utility(u,"switch",destination,str(u.arms[slot].get("id","")))
	return true

func spearwall_mastered(u: Dictionary) -> bool:
	return perk_rules and Perks.has(u,"spear_mastery")

func spearwall_active(u: Dictionary) -> bool:
	return weapon_rules and u.get("stance","") == "brace" and Arsenal.family(u.weapon) == "spear" and terrain_can_react(u)

func spearwall_threatens(wall: Dictionary, mover: Dictionary, previous: Vector2i, entry: Vector2i) -> bool:
	if not spearwall_active(wall) or wall.side == mover.side or not living(mover) or mover.get("immune_to_zone_of_control",false): return false
	if not terrain_controls(wall,entry) or terrain_controls(wall,previous): return false
	return true

func spearwall_reactions(id: int, previous: Vector2i) -> bool:
	var mover: Dictionary = units[id]
	var entry := pos(mover)
	for wall in units:
		if not spearwall_threatens(wall,mover,previous,entry): continue
		# The arriving mover is already on the board. Its own ZoC does not
		# count as an earlier breach. Apart from that mover, a normal wall
		# cannot make another entry attack when tied up by an existing foe.
		if not spearwall_mastered(wall) and adjacent_enemies(wall,pos(wall)).any(func(foe): return foe != id):
			cancel_stance(wall)
			continue
		var viewers = [0,1].filter(func(team): return unit_visible(team,wall.id) and unit_visible(team,id))
		var hit := strike(wall.id,id,false,true,0,true,previous)
		if not living(mover): return true
		# A normal approach was denied, not a free-choice knockback. A
		# simultaneous formation move may already have filled that old tile.
		if hit and at(previous) == -1:
			mover.q = previous.x; mover.r = previous.y
			if perk_rules: reset_segment(mover)
			refresh_visibility()
			log_event("%s is pushed back by Spearwall." % mover.name,viewers)
			return true
		if not spearwall_mastered(wall):
			cancel_stance(wall)
			log_event("%s's Spearwall is breached." % wall.name,viewers)
	return false

func ai_can_close_and_attack(u: Dictionary) -> bool:
	# Only legal, paid routes. Planning does not consume RNG or alter unit state.
	var cost = action_cost(u,false)
	if u.ap < cost.ap or u.fatigue+cost.fatigue > fatigue_max(u): return false
	for v in ai_known_units(int(u.side)):
		if fighting(v) and v.side != u.side and ai_in_range(u,v): return true
	for route in movement_map(u.id).values():
		if route.cost+cost.ap > u.ap or route.fatigue+cost.fatigue+u.fatigue > fatigue_max(u): continue
		var candidate = u.duplicate(); var p: Vector2i = route.path.back()
		candidate.q = p.x; candidate.r = p.y
		for v in ai_known_units(int(u.side)):
			if fighting(v) and v.side != u.side and ai_in_range(candidate,v): return true
	return false

func ai_weapon_step(id: int) -> bool:
	var u: Dictionary = units[id]
	if not fighting(u): return false
	if not u.stance.is_empty(): finish_unit(id); return true
	var trapped = not ai_adjacent_enemies(u,pos(u)).is_empty()
	if (u.weapon in Arsenal.RANGED and (ammo_count(u) <= 0 or (trapped and Arsenal.family(u.weapon) != "throwing"))) or (Arsenal.family(u.weapon) == "polearm" and trapped):
		for slot in Arsenal.bag_slots(u):
			var definition: String = u.arms[slot].get("definition","")
			if definition in Arsenal.WEAPONS and not definition in Arsenal.RANGED and Arsenal.family(definition) != "polearm" and switch_carried(id,slot): return true
	if u.fatigue >= fatigue_max(u)*0.65: return false
	if Arsenal.family(u.weapon) == "crossbow" and not u.arms.weapon.loaded and use_weapon(id,true): return true
	for v in ai_known_units(int(u.side)):
		if not weapon_action_reason(id,true,v.id).is_empty() or not special_info(u.weapon).target: continue
		var protection: int = v.armor+(v.padding if damage_rules else 0)
		var shatter_worth = shatter_useful(u,v) if damage_rules else protection > 65
		var worth = (Arsenal.family(u.weapon) == "axe" and v.shield and v.arms.shield.condition <= (split_shield_damage(u,v) if axe_mace_rules else 24)) or (Arsenal.family(u.weapon) == "mace" and v.stagger == 0 and v.hp > 25 and (not axe_mace_rules or not vital_state(v).indomitable)) or (Arsenal.family(u.weapon) == "hammer" and (shatter_worth or (hammer_dagger_rules and Perks.has(u,"deep_impact") and not impact_active(v) and protection > 0 and v.hp > 25 and ai_hit_score(id,v.id,true) >= 40))) or (Arsenal.family(u.weapon) == "dagger" and protection > 30 and ai_hit_score(id,v.id,true) >= 45) or (Arsenal.family(u.weapon) == "bow" and (ai_hit_score(id,v.id) < 65 or (tactical_ai and Perks.has(u,"patient_hunter") and id in waited))) or (Arsenal.family(u.weapon) == "throwing" and protection > 50) or (Arsenal.family(u.weapon) == "polearm" and v.order == "line")
		if worth and use_weapon(id,true,v.id): return true
	if Arsenal.family(u.weapon) == "spear" and not trapped and u.stance.is_empty():
		var defend = objective != "eliminate" and distance(pos(u),goal()) <= 1
		var brace_worth = not engagement_ai or defend or not ai_can_close_and_attack(u)
		if brace_worth and ai_known_units(int(u.side)).any(func(v): return fighting(v) and v.side != u.side and distance(pos(u),pos(v)) == 3) and use_weapon(id,true): return true
	var counter_worth = not tactical_ai or (not (Perks.has(u,"double_strike") and vital_state(u).double) and (Perks.has(u,"en_garde") or ai_adjacent_enemies(u,pos(u)).size() >= 2))
	if Arsenal.family(u.weapon) == "sword" and counter_worth and trapped and u.ap >= 4 and u.ap < 8 and u.stance.is_empty() and use_weapon(id,true): return true
	return false

func ai_perk_step(id: int) -> bool:
	# Visible state only. All choices pay through the same commands as the player.
	var u: Dictionary = units[id]
	if not perk_rules or not can_act(id) or not fighting(u): return false
	var pressure = ai_adjacent_enemies(u,pos(u)).size()
	var fragile = u.hp*2 < u.max_hp
	var ranged = u.weapon in Arsenal.RANGED and Arsenal.family(u.weapon) != "throwing"
	if Perks.has(u,"rotation"):
		var best = Vector2i(-1,-1); var score = 0.0
		for p in neighbors(pos(u)):
			if not perk_action_reason(id,"rotation",p).is_empty(): continue
			var ally: Dictionary = units[at(p)]
			var ally_pressure = ai_adjacent_enemies(ally,p).size()
			var ally_ranged = ally.weapon in Arsenal.RANGED and Arsenal.family(ally.weapon) != "throwing"
			var value = 0.0
			if pressure > ally_pressure and (fragile or ranged) and not ally_ranged and ally.hp*4 >= ally.max_hp*3:
				value = (pressure-ally_pressure)*20.0+(1.0-float(u.hp)/u.max_hp)*20
			if ally_pressure > pressure and (ally.hp*2 < ally.max_hp or ally_ranged) and not ranged and u.hp*4 >= u.max_hp*3:
				value = (ally_pressure-pressure)*20.0+(1.0-float(ally.hp)/ally.max_hp)*20
			if value > score: score = value; best = p
		if score > 0 and use_perk(id,"rotation",best): return true
	if pressure > 0 and Perks.has(u,"footwork") and (ranged or pressure >= 2 or (fragile and not engagement_ai)):
		var best = Vector2i(-1,-1); var score = -INF
		for p in neighbors(pos(u)):
			if not perk_action_reason(id,"footwork",p).is_empty(): continue
			var after = ai_adjacent_enemies(u,p).size()
			if after >= pressure: continue
			var value = -after*50.0+ai_position_score(u,p)
			if value > score: score = value; best = p
		if best.x >= 0 and use_perk(id,"footwork",best): return true
	if pressure > 0 and (pressure >= 2 or fragile) and Perks.has(u,"indomitable"):
		var incoming = ai_adjacent_enemies(u,pos(u)).any(func(enemy_id): return not enemy_id in finished)
		if incoming and use_perk(id,"indomitable"): return true
	if pressure == 0 and Arsenal.family(u.weapon) == "bow" and Perks.has(u,"patient_hunter") and can_wait(id):
		for v in ai_known_units(int(u.side)):
			if distance(pos(u),pos(v)) >= 3 and weapon_action_reason(id,true,v.id).is_empty() and v.hp > weapon_stats(u).min:
				return wait_unit(id)
	return false

func shatter_useful(u: Dictionary, v: Dictionary) -> bool:
	# No RNG consumed by planning. Pay for Shatter only when it removes a
	# substantial amount beyond a normal blow; avoid sacrificing HP damage
	# against armour the ordinary attack can already destroy.
	var w: Dictionary = weapon_stats(u)
	var regular = (float(w.min)+float(w.max))*0.5
	var armor_factor = float(w.armor)*hammer_armor_factor(u)
	var normal = Damage.resolve_hit(regular,regular*armor_factor,float(w.pierce),v.armor+v.padding)
	var shatter = Damage.resolve_hit(regular,regular*armor_factor*2.0,float(w.pierce),v.armor+v.padding)
	return shatter.armor-normal.armor >= maxf(25.0,normal.armor*0.5)


func initialize_stats(u: Dictionary) -> void:
	u["stat_rules"] = true
	u["stamina"] = 105+(u.id%3)*5
	u["initiative"] = 95+(u.id*13+seed_value)%25
	u["ranged_skill"] = u.skill if u.weapon in Arsenal.RANGED else 40+(u.id*7)%15
	u["ranged_defense"] = 3+(u.id*3)%10
	u["resolve"] = 45+(5 if u.id == player_slots() else 0)
	u["morale_state"] = 0
	if core_rules: u["fleeing_rounds"] = 0
	u.morale = 85

func fatigue_max(u: Dictionary) -> int:
	return People.fatigue_max(u)

func initiative_value(u: Dictionary) -> int:
	if perk_rules:
		return int(u.get("initiative",100))-Perks.armor_load(u,true)-Arsenal.load(u.get("arms",{}),Perks.has(u,"bags_and_belts"),int(u.get("carried_load_discount",0)) if u.get("inventory_balance",false) else 0)-(ceili(u.fatigue*0.5) if Perks.has(u,"relentless") else int(u.fatigue))-(5 if u.get("temperament","") == "stoic" else 0)
	if core_rules: return int(u.get("initiative",100))-People.equipment_load(u)-int(u.get("fatigue",0))-(5 if u.get("temperament","") == "stoic" else 0)
	return People.initiative_value(u)

func tie_priority(id: int) -> int:
	var value = posmod(seed_value*48271+(id+1)*69621+round_no*104729,2147483647)
	return posmod(value*48271,2147483647)

func start_round() -> void:
	var previous_waited = waited.duplicate()
	activated = []; finished = []; waited = []; delayed = []; turn_queue = []; turn_scores = {}; active_id = -1
	for u in units:
		u.ap = 0
		if living(u):
			turn_queue.append(u.id)
			var score = initiative_value(u)-(1000 if core_rules and u.routed else 0)
			if core_rules and u.id in previous_waited and not (perk_rules and Perks.has(u,"relentless")): score = floori(score*0.75 if score >= 0 else score/0.75)
			turn_scores[str(u.id)] = score
	turn_queue.sort_custom(func(a,b): return turn_scores[str(a)] > turn_scores[str(b)] if turn_scores[str(a)] != turn_scores[str(b)] else tie_priority(a) < tie_priority(b))
	activate_next()

func complete_round() -> void:
	record_shared_line()
	var control = [0,0]
	for u in units:
		if fighting(u) and distance(pos(u),goal()) <= 1: control[u.side] = 1
	for team in 2:
		held[team] = mini(3,held[team]+1) if control[team] == 1 and control[1-team] == 0 else 0
		if not withdrawing and objective != "eliminate" and held[team] >= 3 and (objective == "hold" or team == 1): result = "victory" if team == 0 else "defeat"
	if not withdrawing and objective in ["defend","escort"] and round_no >= 8 and result.is_empty(): result = "victory"
	if not result.is_empty(): return
	round_no += 1
	if not physical_escape_pending() and round_no > 30: result = "draw"; return
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
			if perk_rules:
				var state = vital_state(u)
				state.activation += 1; state.quick_used = false; state.vigor_used = false; state.reach = 0; state.indomitable = false; state.bow_shots = 0
				reset_segment(u)
			u.ap = MAX_AP-u.stagger; u.stagger = 0
			u.fatigue = maxi(0,mini(fatigue_max(u)-15,u.fatigue-People.recovery(u))) if core_rules else maxi(0,u.fatigue-People.recovery(u))
			if core_rules and u.routed and not (withdrawing and u.side == 0): rally_check(u)
			u.guard = false; cancel_stance(u)
		log_event("%s acts%s · initiative %d." % [u.name," after waiting" if id in waited else "",turn_scores[str(id)]],[u.side])
		return
	active_id = -1
	complete_round()

func complete_activation() -> void:
	if active_id >= 0:
		if perk_rules: end_perk_activation(units[active_id])
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
	if perk_rules: reset_segment(units[id])
	commands.append(["wait",id]); waited.append(id); delayed.append(id)
	log_event(units[id].name+" waits; remaining AP and fatigue are preserved.",[units[id].side])
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
	if u.get("faction","") == "undead": return
	if core_rules:
		baseline_morale_check(u,-severity,cause,positive)
		return
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
		log_event("%s breaks and flees toward a field edge." % u.name,unit_event_audience(u))
		for other in units:
			if other.id != u.id and other.side == u.side and fighting(other) and distance(pos(u),pos(other)) <= 2: morale_check(other,10,"nearby panic")

func valid_turn_state(d: Dictionary) -> bool:
	for u in d.units:
		if not u is Dictionary: return false
	if not d.get("individual") is bool or not d.get("active_id") is int or not d.get("turn_scores") is Dictionary: return false
	for field in ["turn_queue","delayed","activated","finished","waited"]:
		if not d.get(field) is Array or d[field].size() > d.units.size(): return false
		var seen = {}
		for id in d[field]:
			if not id is int or id < 0 or id >= d.units.size() or seen.has(id): return false
			seen[id] = true
	if not d.individual:
		return d.active_id == -1 and d.turn_queue.is_empty() and d.delayed.is_empty() and d.activated.is_empty() and d.finished.is_empty() and d.waited.is_empty() and d.turn_scores.is_empty()
	if d.active_id < -1 or d.active_id >= d.units.size() or (d.result.is_empty() and d.active_id < 0): return false
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
	for id in range(d.units.size()):
		if not d.units[id] is Dictionary: return false
		if not d.units[id].get("hp") is int or not d.units[id].get("escaped") is bool: return false
		if d.units[id].hp > 0 and not d.units[id].escaped and not unique.has(id): return false
		if (id in d.turn_queue or id in d.finished) and d.units[id].get("ap") != 0: return false
		if unique.has(id) and not d.turn_scores.get(str(id)) is int: return false
	for value in d.turn_scores.values():
		if not value is int or value < (-2000 if d.get("core_rules",false) else 0) or value > 245: return false
	return true

# Baseline combat formulas. Authored traits/perks are explicit property additions;
# their values are not advertised as the commercial game's trait catalogue.
func special_info(weapon: String) -> Dictionary:
	var info = Arsenal.special(weapon).duplicate()
	if not core_rules: return info
	match Arsenal.family(weapon):
		"bow":
			info.ap = 7; info.fatigue = 20
			info.text = "+1 hex of range, +10 accuracy, -2 per hex beyond the first, +10% regular damage (armour roll unchanged). Costs 7 AP / 20 fatigue and one arrow. Cannot shoot while engaged."
		"crossbow":
			info.ap = 4; info.fatigue = 20
			info.text = "Reload: 4 AP / 20 fatigue. Requires a bolt and an unloaded crossbow. Cannot reload while engaged."
		"axe":
			info.text = "An adjacent shield is hit automatically. Deals 24 shield condition; no body damage. A broken shield grants no defence."
	return info

func shield_defence(u: Dictionary, ranged: bool) -> int:
	if not u.get("shield",false): return 0
	var shield_item: Dictionary = armor_catalog.get(u.get("arms",{}).get("shield",{}).get("definition","shield"),{})
	return floori(int(shield_item.get("ranged_defense" if ranged else "melee_defense",15 if ranged else 20))*(1.25 if ("shield_drill" in u.get("perks",[]) or (perk_rules and Perks.has(u,"shield_expert"))) else 1.0))

func wall_support(u: Dictionary) -> int:
	if not fighting(u) or not u.shield or not u.guard: return 0
	var count = 0
	for v in units:
		if v.id != u.id and v.side == u.side and fighting(v) and v.shield and v.guard and distance(pos(u),pos(v)) == 1 and absi(tiles[key(pos(u))].height-tiles[key(pos(v))].height) <= 1: count += 1
	return mini(4,count)*5

func surround_count(u: Dictionary) -> int:
	# Surrounding is separate from zone of control: the reference counts a
	# living melee opponent even while fleeing, but not ranged weapon holders.
	var count = 0
	for v in units:
		if living(v) and v.side != u.side and not v.weapon in Arsenal.RANGED and distance(pos(u),pos(v)) == 1 and absi(tiles[key(pos(u))].height-tiles[key(pos(v))].height) <= 1: count += 1
	return maxi(0,count-1)

func baseline_hit_breakdown(a: int, b: int, special: bool = false, reaction: bool = false) -> Dictionary:
	var u: Dictionary = units[a]; var v: Dictionary = units[b]
	var w: Dictionary = weapon_stats(u); var family = Arsenal.family(u.weapon)
	if special and family == "axe": return {"parts":[{"name":"Split shield: automatic hit","value":100}],"raw":100,"chance":100}
	var ranged: bool = u.weapon in Arsenal.RANGED
	var skill: int = u.ranged_skill if ranged else u.skill
	if perk_rules:
		if Perks.has(u,"hybridization"): skill += floori((u.skill if ranged else u.ranged_skill)*0.1)
		skill = floori(skill*(1.0-0.1*vital_state(u).overwhelm))
	var defence: int = v.ranged_defense if ranged else v.defense
	var action_bonus = int(w.skill)
	if special: action_bonus += int({"mace":-10,"hammer":-5,"dagger":-20,"polearm":-10,"bow":10,"throwing":-5}.get(family,0))
	var trait_bonus = temperament_accuracy(u)+(5 if "weapon_drill" in u.perks else 0)
	var shield = shield_defence(v,ranged)
	var wall = shield if v.guard else 0
	var support = wall_support(v)
	var cautious = 5 if v.temperament == "cautious" else 0
	var perk_def = perk_defence(v,ranged,u) if perk_rules else 0
	var before_defence = defence+shield+wall+support+cautious+perk_def
	var after_defence = floori(before_defence*morale_multiplier(v))
	var parts = [{"name":"Ranged skill" if ranged else "Melee skill","value":skill}]
	var rows = [
		["Weapon / action accuracy",action_bonus],
		["Traits / weapon handling",trait_bonus],
		["Attacker morale",(skill+action_bonus+trait_bonus)*(morale_multiplier(u)-1.0)],
		["Ranged defence" if ranged else "Melee defence",-defence],
		["Shield",-shield], ["Active Shieldwall",-wall], ["Adjacent active walls",-support],
		["Perk defence",-perk_def], ["Cautious defender",-cautious], ["Defender morale / rounding",before_defence-after_defence],
		["Defence above 50: half value",maxf(0,(after_defence-50)*0.5)],
		["Melee surrounding",0 if ranged else perk_surround(u,v) if perk_rules else surround_count(v)*5]]
	if perk_rules: rows.append(["Perk accuracy",perk_accuracy(u,v,reaction)])
	if perk_rules and int(w.reach) == 2 and family in ["polearm","spear"] and distance(pos(u),pos(v)) == 1:
		var mastery := "spear_mastery" if family == "spear" else "polearm_mastery"
		if not Perks.has(u,mastery): rows.append(["Adjacent pike" if family == "spear" else "Adjacent polearm",-15])
	var height: int = tiles[key(pos(u))].height-tiles[key(pos(v))].height
	rows.append(["Elevation",10 if height > 0 else height*10])
	if ranged:
		var per_tile = -3 if family == "crossbow" else -2 if family == "throwing" or special else -4
		rows.append(["Ranged distance",maxi(0,distance(pos(u),pos(v))-1)*per_tile])
	for row in rows:
		if not is_zero_approx(float(row[1])): parts.append({"name":row[0],"value":row[1]})
	var raw = 0.0
	for part in parts: raw += part.value
	# A 1..100 integer roll <= a fractional threshold has this exact probability.
	return {"parts":parts,"raw":raw,"chance":floori(clampf(raw+0.0000001,5,95))}

func shield_block(v: Dictionary, ranged: bool, attack_roll: int, chance: float) -> void:
	# BB's shield-impact interval is twice the shield bonus, doubled again by wall.
	var shield_bonus = shield_defence(v,ranged)
	if not v.shield or attack_roll > chance+shield_bonus*2*(2 if v.guard else 1): return
	v.arms.shield.condition = maxi(0,v.arms.shield.condition-1)
	sync_arms(v)
	if not v.shield:
		v.guard = false
		if v.order == "line" and Arsenal.family(v.weapon) != "spear": v.order = "free"
	log_event("%s blocks: -1 shield condition%s." % [v.name,"; shield broken" if not v.shield else ""])
	combat_feedback.emit({"id":v.id,"kind":"shield","text":"BLOCK · -1 SHIELD"})

func recover_reason(id: int) -> String:
	if not can_act(id) or units[id].routed: return "Select an active, fighting soldier."
	if core_rules and not perk_rules and not "endurance" in units[id].perks: return "Recover requires the Second wind perk."
	if units[id].ap < (9 if core_rules else 4): return "Recover needs %d AP and ends this activation." % (9 if core_rules else 4)
	return ""

func resolve_chance(u: Dictionary, difficulty: float, positive: bool = false, physical: bool = false) -> int:
	var bravery = floori(u.resolve*(1.25 if perk_rules and Perks.has(u,"fortified_mind") else 1.0))+comrade_support(u)-u.strain_penalty-u.grief_penalty+(10 if u.temperament == "stoic" else 0)+(15 if "steadfast" in u.perks else 0)
	if perk_rules and physical and not positive and Perks.has(u,"bulwark"): bravery += mini(15,floori((u.helmet+u.armor+u.padding)/25.0))
	bravery = floori(bravery*(1.0+minf(0,u.morale_state)*0.1))
	var friends = 0; var opponents = 0
	for v in units:
		if v.id == u.id or not fighting(v) or distance(pos(u),pos(v)) != 1: continue
		if v.side == u.side: friends += 1
		else: opponents += 1
	# Only negative checks receive allied adjacency. Unlike hit rolls, resolve
	# has a 95 ceiling but no guaranteed 5% success floor.
	return maxi(0,floori(minf(95,bravery+difficulty-opponents*3+(0 if positive else friends*3))))

func baseline_morale_check(u: Dictionary, difficulty: float, cause: String, positive: bool = false) -> void:
	if u.get("faction","") == "undead": return
	if not fighting(u) or (positive and u.morale_state == 1): return
	var chance = resolve_chance(u,difficulty,positive,cause in ["flesh wound","ally fell","comrade fell","nearby enemies"])
	var passed = roll(1,100) <= chance
	if passed != positive:
		if not positive: log_event("%s holds nerve (%d%% · %s)." % [u.name,chance,cause])
		return
	u.morale_state = clampi(u.morale_state+(1 if positive else -1),-3,1)
	u.morale = morale_number(u.morale_state); u.fleeing_rounds = 0
	log_event("%s: %s · %s (%d%% resolve check)." % [u.name,morale_name(u),cause,chance])
	combat_feedback.emit({"id":u.id,"kind":"morale","text":morale_name(u)})
	if u.morale_state != -3: return
	u.routed = true; u.order = "free"; u.guard = false; cancel_stance(u)
	log_event("%s breaks and flees toward a field edge." % u.name,unit_event_audience(u))
	for other in units:
		if other.id != u.id and other.side == u.side and fighting(other):
			baseline_morale_check(other,30-200*0.035+pow(distance(pos(u),pos(other)),3),"ally fleeing")

func death_morale(killer: Dictionary, victim: Dictionary) -> void:
	# Prototype humanoid encounter value 200; separate from company XP awards.
	# Distances and check equations follow the reference baseline.
	for other in units:
		if not fighting(other): continue
		var gap = distance(pos(other),pos(victim))
		if other.side == victim.side:
			baseline_morale_check(other,20-200*0.035+pow(gap,2.4),"ally fell")
		else:
			baseline_morale_check(other,-30+200*0.04-pow(gap,3)+(15 if other.id == killer.id else 0),"enemy fell",true)

func rally_check(u: Dictionary) -> void:
	if adjacent_enemies(u,pos(u)).is_empty() and roll(1,100) <= resolve_chance(u,u.fleeing_rounds*2,true):
		u.routed = false; u.morale_state = -1; u.morale = morale_number(-1); u.fleeing_rounds = 0
		log_event(u.name+" rallies to wavering.")
		combat_feedback.emit({"id":u.id,"kind":"morale","text":"RALLIED · WAVERING"})
	else: u.fleeing_rounds += 1

# Personal-perk rules. Every transient value is in perk_state and saved/replayed.
func all_perk_definitions() -> Dictionary:
	var out = Progression.PERKS.duplicate(true)
	out.merge(Perks.catalog())
	return out

func configure_perk_weapons() -> void:
	for id in weapons:
		var family = Arsenal.family(id)
		if family in ["sword","spear"] and not id in Arsenal.TWO_HANDS:
			weapons[id].ap = 4; weapons[id].reach = 1
		if family == "polearm":
			weapons[id].ap = 6; weapons[id].min_range = 1; weapons[id].reach = 2

func vital_state(u: Dictionary) -> Dictionary:
	# New battles initialize this before activation; fallback supports test fixtures.
	return u.get("perk_state",Perks.state())

func paid_action(u: Dictionary, special: bool) -> bool:
	return not special or (special_info(u.weapon).target and Arsenal.family(u.weapon) != "axe")

func one_handed(u: Dictionary) -> bool:
	return not u.weapon in Arsenal.TWO_HANDS and not u.weapon in Arsenal.RANGED

func offhand_free(u: Dictionary) -> bool:
	# Broken shields remain physical repairable items but no longer occupy a usable hand.
	return u.arms.shield.is_empty() or u.arms.shield.get("condition",0) <= 0

func double_grip_factor(u: Dictionary, special: bool = false) -> float:
	if not double_grip_rules or u.weapon.is_empty() or not one_handed(u) or not offhand_free(u): return 1.0
	# Puncture bypasses armour; Split Shield deals fixed shield condition, not weapon damage.
	if special and Arsenal.family(u.weapon) in ["dagger","axe"]: return 1.0
	return 1.25

func reaction_cost(u: Dictionary) -> int:
	return Perks.fatigue_cost(u,6,true,true) if perk_rules else 6

func vigor_ready(u: Dictionary) -> bool:
	var s = vital_state(u)
	return Perks.has(u,"vigorous_assault") and not s.vigor_used and u.weapon in Arsenal.TWO_HANDS and not u.weapon in Arsenal.RANGED and s.origin_q >= 0 and distance(Vector2i(s.origin_q,s.origin_r),pos(u)) >= 2

func perk_action_cost(u: Dictionary, special: bool, target: int = -1) -> Dictionary:
	var w: Dictionary = weapon_stats(u); var family = Arsenal.family(u.weapon)
	var base: Dictionary = weapons.get(family,w)
	var ap = int(w.get("special_ap",maxi(w.ap,special_info(u.weapon).ap))) if special else int(w.ap)
	var fatigue = int(w.get("special_fatigue",special_info(u.weapon).fatigue+w.fatigue-base.fatigue)) if special else int(w.fatigue)
	fatigue += (4 if u.temperament == "aggressive" else 0)-(4 if "weapon_drill" in u.perks else 0)
	var factor = 1.0
	if family == "bow" and not special and Perks.has(u,"hip_shooter"):
		ap = 3; fatigue += 7*vital_state(u).bow_shots
	if family == "crossbow" and special and Perks.has(u,"crossbow_mastery"): ap = 3
	if family == "throwing" and Perks.has(u,"opportunist") and vital_state(u).throws_used < 2: ap = maxi(3,ap-1)
	if not special and family == "polearm" and Perks.has(u,"polearm_mastery"): ap = 5
	if special and family == "sword" and one_handed(u) and Perks.has(u,"en_garde"): ap = 2; factor *= 2.0/3.0
	if swift_ready(u,target): ap = maxi(2,ap-2)
	if paid_action(u,special) and vigor_ready(u): ap = maxi(4,ap-1); factor *= 0.9
	# Preserve one paid reach strike in a full activation, after AP discounts.
	if paid_action(u,special) and not u.weapon in Arsenal.RANGED and int(w.reach) == 2: ap = maxi(ap,(MAX_AP >> 1)+1)
	return {"ap":ap,"fatigue":Perks.fatigue_cost(u,maxi(1,fatigue),true,false,factor)}

func movement_fatigue(u: Dictionary, a: Vector2i, b: Vector2i) -> int:
	if terrain_rules_enabled: return movement_edge(u,a,b).fatigue
	return paid_movement_fatigue(u,legacy_movement_fatigue(u,a,b))
func legacy_movement_fatigue(u: Dictionary, a: Vector2i, b: Vector2i) -> int:
	if terrain_rules_enabled: return movement_edge(u,a,b).fatigue
	if not perk_rules or not Perks.has(u,"pathfinder"): return movement_cost(u,a,b)*People.move_rate(u)
	var terrain = (4 if tiles[key(b)].terrain in ["mud","forest"] else 2)*People.move_rate(u)
	var uphill = maxi(0,int(tiles[key(b)].height)-int(tiles[key(a)].height))*People.move_rate(u)
	return ceili(terrain*0.5)+uphill

func clear_sequence(u: Dictionary) -> void:
	var s = vital_state(u); s.feint = -1; s.double = false
	clear_weapon_sequence(u)

func reset_segment(u: Dictionary) -> void:
	clear_sequence(u)
	var s = vital_state(u); s.origin_q = u.q; s.origin_r = u.r

func end_perk_activation(u: Dictionary) -> void:
	clear_sequence(u)
	var s = vital_state(u); s.overwhelm = 0
	if hammer_dagger_rules and s.activation >= weapon_state(u).impact_end: weapon_state(u).impact_end = 0
	if s.activation >= s.frenzy_end: s.frenzy_end = 0
	if s.activation >= s.opening_end: s.opening = -1; s.opening_end = 0

func switch_fatigue() -> int:
	return 0 if inventory_rules else 4

func empty_bag(u: Dictionary, except_slot: String) -> String:
	for slot in Arsenal.bag_slots(u):
		if slot != except_slot and u.arms.get(slot,{}).is_empty(): return slot
	return ""

func switch_ap(u: Dictionary, slot: String) -> int:
	var cost = 4 if inventory_rules else 2
	if inventory_rules:
		# Read actual worn belt parts, never stash/carried gear or UI projections.
		# Zero-durability utility is intact at zero condition; durable broken gear is not.
		for part in u.get("armor_parts",[]):
			var definition: Dictionary = armor_catalog.get(part.get("definition",""),{})
			if part.get("layer","") != "belt" or definition.get("slot","") != "belt": continue
			if int(part.get("maximum",definition.get("durability",0))) > 0 and int(part.get("condition",0)) <= 0: continue
			if definition.get("switch_ap",4) == 2: cost = 2
	if not perk_rules or vital_state(u).quick_used: return cost
	var item: Dictionary = u.arms.get(slot,{})
	if Arsenal.shield(item.get("definition","")) or (item.get("definition","") in Arsenal.TWO_HANDS and not u.arms.shield.is_empty()): return cost
	if Perks.has(u,"quick_hands"): return 0
	if Perks.has(u,"hybridization") and (Arsenal.family(u.weapon) == "throwing" or Arsenal.family(item.get("definition","")) == "throwing"): return 0
	return cost

func perk_defence(u: Dictionary, ranged: bool, attacker: Dictionary) -> int:
	var value = 0
	if Perks.has(u,"dodge"): value += floori(0.15*maxi(0,initiative_value(u)))
	if Perks.has(u,"balance"): value += floori(6*Perks.medium(u)+0.000001)
	if ranged and Perks.has(u,"anticipation"): value += mini(15,3*distance(pos(u),pos(attacker)))
	if not ranged:
		value += vital_state(u).reach
		if u.shield and Perks.has(u,"phalanx"): value += mini(2,shield_neighbors(u,pos(u)).size())*3
	return value

func perk_surround(u: Dictionary, v: Dictionary) -> int:
	if Perks.has(v,"underdog"): return 0
	var virtual = 0
	for ally in units:
		if ally.id == u.id or ally.side != u.side or not fighting(ally) or not Perks.has(ally,"long_reach") or Arsenal.family(ally.weapon) != "polearm": continue
		if distance(pos(ally),pos(v)) == 2 and in_range(ally,v) and absi(tiles[key(pos(ally))].height-tiles[key(pos(v))].height) <= 1:
			virtual = 1; break
	return (surround_count(v)+virtual)*(10 if Perks.has(u,"backstabber") else 5)

func perk_accuracy(u: Dictionary, v: Dictionary, reaction: bool) -> int:
	var s = vital_state(u)
	var impact = -10 if impact_active(u) else 0
	if reaction: return impact+(10 if Perks.has(u,"en_garde") and u.stance == "riposte" and one_handed(u) else 0)
	var practice = 0
	if Arsenal.family(u.weapon) == "bow" and Perks.has(u,"target_practice"):
		var supported = units.any(func(ally): return ally.id != v.id and ally.side == v.side and fighting(ally) and distance(pos(ally),pos(v)) == 1)
		if v.weapon in Arsenal.RANGED or (not v.shield and not supported): practice = 10
	return impact+practice+(s.adaptation if Perks.has(u,"fast_adaptation") else 0)+(10 if Perks.has(u,"feint") and Arsenal.family(u.weapon) == "sword" and s.feint == v.id else 0)+(10 if Perks.has(u,"exploit_opening") and s.opening == v.id and not u.weapon in Arsenal.RANGED else 0)

func after_perk_attack(u: Dictionary, v: Dictionary, special: bool, reaction: bool, hit: bool, paid_fatigue: int, head: bool = false) -> void:
	if reaction or not paid_action(u,special): return
	var s = vital_state(u); var target = vital_state(v)
	if hammer_dagger_rules:
		weapon_state(u).swift_target = v.id if hit and fighting(v) and Arsenal.family(u.weapon) == "dagger" and Perks.has(u,"swift_stabs") else -1
	if Arsenal.family(u.weapon) == "bow": s.bow_shots = mini(3,s.bow_shots+1)
	if Arsenal.family(u.weapon) == "throwing": s.throws_used = mini(2,s.throws_used+1)
	if head_eligible(u,special) and Perks.has(u,"head_hunter"):
		s.head_ready = false if s.head_ready else hit and head
	if Perks.has(u,"fast_adaptation"): s.adaptation = 0 if hit else mini(24,s.adaptation+8)
	if Perks.has(u,"feint") and Arsenal.family(u.weapon) == "sword":
		s.feint = -1 if hit else v.id
		if not hit: u.fatigue = maxi(0,u.fatigue-floori(paid_fatigue*0.25))
	if not u.weapon in Arsenal.RANGED and s.opening == v.id: s.opening = -1; s.opening_end = 0
	if not hit and not special and not u.weapon in Arsenal.RANGED and distance(pos(u),pos(v)) == 1 and Perks.has(v,"exploit_opening"):
		target.opening = u.id; target.opening_end = target.activation+1
	if one_handed(u) and Perks.has(u,"double_strike"): s.double = hit
	if vigor_ready(u): s.vigor_used = true
	if hit and u.weapon in Arsenal.TWO_HANDS and not u.weapon in Arsenal.RANGED and Perks.has(u,"reach_advantage"): s.reach = mini(10,s.reach+5)
	if hit and v.hp == 0 and Perks.has(u,"killing_frenzy"): s.frenzy_end = s.activation+1
	if Perks.has(u,"overwhelm") and not v.id in activated: target.overwhelm = mini(2,target.overwhelm+1)

func shot_quiver(u: Dictionary, reaction: bool = false) -> String:
	# Derive afresh from the actual equipped physical bundle, never cached on a
	# fighter/weapon. Commit has already consumed the final arrow before strike;
	# zero remaining here is valid for that shot, not authority to fire another.
	if reaction or Arsenal.family(u.weapon) != "bow": return ""
	var arms: Dictionary = u.get("arms",{})
	if arms.get("weapon",{}).get("definition","") != u.weapon: return ""
	var item: Dictionary = arms.get("ammo",{})
	var definition: String = item.get("definition","")
	if definition not in ["arrows","bodkin_quiver","deep_quiver"] or item.get("id","").is_empty(): return ""
	if Arsenal.ammo_kind(definition,armor_catalog) != "arrows" or not Named.valid(item,armor_catalog): return ""
	return definition

func perk_penetration(u: Dictionary, w: Dictionary, reaction: bool = false) -> float:
	var penetration = float(w.pierce)
	if shot_quiver(u,reaction) == "bodkin_quiver": penetration += 0.15
	if Arsenal.family(u.weapon) == "spear" and Perks.has(u,"through_the_gaps"): penetration += 0.15
	if one_handed(u) and (offhand_free(u) if double_grip_rules else u.arms.shield.is_empty()) and Perks.has(u,"duelist"): penetration += 0.25
	if not reaction and u.weapon in Arsenal.RANGED and Perks.has(u,"bullseye"): penetration += 0.15
	return clampf(penetration,0,1)

func damage_context(u: Dictionary, v: Dictionary, w: Dictionary, special: bool, reaction: bool, spearwall: bool = false) -> Dictionary:
	var family = Arsenal.family(u.weapon); var s = vital_state(u)
	var factor: float = {"mace":0.75,"dagger":0.8,"polearm":0.65,"bow":1.1}.get(family,1.0) if special else 1.0
	var bonus = 0.0
	if s.frenzy_end > 0: bonus += 0.2
	if spearwall and Perks.has(u,"spearwaller"): bonus += 0.2
	if not reaction:
		if s.opening == v.id and not u.weapon in Arsenal.RANGED and Perks.has(u,"exploit_opening"): bonus += 0.2
		if one_handed(u) and s.double and Perks.has(u,"double_strike"): bonus += 0.15
		if family == "bow" and special and u.id in waited and Perks.has(u,"patient_hunter"): bonus += 0.2
		if family == "throwing" and Perks.has(u,"throwing_mastery"):
			var gap = distance(pos(u),pos(v)); bonus += 0.2 if gap <= 2 else 0.1 if gap == 3 else 0.0
	var head_chance = int(w.get("head_chance",25))+(15 if not reaction and family == "polearm" and distance(pos(u),pos(v)) == 2 and Perks.has(u,"leverage") else 0)
	if not reaction and family == "crossbow" and Perks.has(u,"iron_sights"): head_chance += 20
	if advantage_ready(u,v,reaction): head_chance += 10
	var forced_head = not reaction and head_eligible(u,special) and Perks.has(u,"head_hunter") and s.head_ready
	var quiver_factor := 0.90 if shot_quiver(u,reaction) == "deep_quiver" else 1.0
	var wall_factor := 0.5 if spearwall else 1.0
	return {"min":int(w.min),"max":int(w.max),"factor":factor*quiver_factor*wall_factor,"bonus":bonus,"grip":double_grip_factor(u,special),"weakened":0.8 if impact_active(u) else 1.0,
		"armor_special":(1.0 if special and family == "bow" else factor)*quiver_factor*wall_factor,"weapon_armor":float(w.armor),"hammer_factor":hammer_armor_factor(u),
		"head_chance":head_chance,"forced_head":forced_head,"body_only":special and family in ["hammer","dagger"],
		"king":not forced_head and family == "spear" and Perks.has(u,"king_of_all_weapons"),"helmet":v.helmet,"body":v.armor+v.padding,
		"bypass":special and family == "dagger","shatter":special and family == "hammer","heavy_throw":special and family == "throwing",
		"penetration":perk_penetration(u,w,reaction),"armor_factor":Perks.armor_factor(v),"hp_factor":Perks.hp_factor(v),
		"steel_brow":Perks.has(v,"steel_brow"),"advantage":advantage_ready(u,v,reaction),"ribs_factor":1.0 if reaction else 1.0+ribs_bonus(u,v)}

func perk_damage(u: Dictionary, v: Dictionary, w: Dictionary, special: bool, reaction: bool, spearwall: bool = false) -> Dictionary:
	var c = damage_context(u,v,w,special,reaction,spearwall)
	# Preserve every original draw, including an overridden head roll and king's
	# draw when both pools happen to be equal. Preview never calls this method.
	var regular_roll = roll(c.min,c.max)
	var armor_roll = roll(c.min,c.max)
	var head_roll = roll(1,100)
	var king_roll = roll(1,100) if c.king else 100
	var head = Damage.current_head(c,head_roll,king_roll)
	var hit = Damage.resolve_current(c,regular_roll,armor_roll,head)
	var wear = {"armor":hit.armor,"padding":0}
	if head: v.helmet -= hit.armor; Armor.damage_parts(v,"helmet",hit.armor)
	else: wear = Armor.damage_body(v,hit.armor)
	return {"head":head,"layer":"helmet" if head else "body","armor":wear.armor,"padding":wear.padding,"hp":hit.hp}

func damage_preview(id: int, target: int, special: bool = false, reaction: bool = false) -> Dictionary:
	if not perk_rules or id < 0 or target < 0 or id >= units.size() or target >= units.size(): return {}
	var u: Dictionary = units[id]; var v: Dictionary = units[target]
	if special and not special_info(u.weapon).target: return {}
	if special and Arsenal.family(u.weapon) == "axe":
		return {"kind":"shield","shield":mini(split_shield_damage(u,v),int(v.arms.shield.get("condition",0)))}
	var c = damage_context(u,v,weapon_stats(u),special,reaction)
	var heads: Array = []
	for head_roll in [1,100]:
		for king_roll in [1,100]:
			var head = Damage.current_head(c,head_roll,king_roll)
			if not head in heads: heads.append(head)
	var out = {"kind":"hit","hp_min":2147483647,"hp_max":0,"armor_min":2147483647,"armor_max":0}
	var cap = int(v.hp)
	if Perks.has(v,"nine_lives") and not vital_state(v).nine_used: cap = maxi(0,cap-1)
	# Enumerate independent damage rolls, not a mean or paired-roll approximation.
	for regular_roll in range(c.min,c.max+1):
		for armor_roll in range(c.min,c.max+1):
			for head in heads:
				var hit = Damage.resolve_current(c,regular_roll,armor_roll,head)
				var hp = mini(cap,hit.hp)
				out.hp_min = mini(out.hp_min,hp); out.hp_max = maxi(out.hp_max,hp)
				out.armor_min = mini(out.armor_min,hit.armor); out.armor_max = maxi(out.armor_max,hit.armor)
	return out

func active_perk_cost(u: Dictionary, action: String) -> Dictionary:
	return {"ap":5 if action == "indomitable" else 3,"fatigue":Perks.fatigue_cost(u,20 if action == "footwork" else 25,false)}

func perk_action_reason(id: int, action: String, target: Vector2i = Vector2i(-1,-1)) -> String:
	if not perk_rules or not can_act(id) or not fighting(units[id]) or not Perks.has(units[id],action): return "This perk is not available to the active soldier."
	if not action in ["rotation","footwork","indomitable"]: return "Unknown active perk."
	var u: Dictionary = units[id]
	var cost = active_perk_cost(u,action)
	if u.ap < cost.ap or u.fatigue+cost.fatigue > fatigue_max(u): return "Insufficient AP or free fatigue."
	if action == "indomitable": return "Already active." if vital_state(u).indomitable else ""
	if visibility_enabled and not tile_visible(u.side,target): return "Destination is not currently visible."
	if not tiles.has(key(target)): return "Choose an adjacent passable hex."
	if distance(pos(u),target) != 1 or step_cost(pos(u),target) >= 999 or absi(tiles[key(pos(u))].height-tiles[key(target)].height) > 1: return "Choose an adjacent passable hex."
	var other = at(target)
	if action == "footwork": return "Choose an empty hex." if other >= 0 else ""
	if other < 0 or units[other].side != u.side or not fighting(units[other]): return "Choose a standing adjacent ally."
	return ""

func use_perk(id: int, action: String, target: Vector2i = Vector2i(-1,-1)) -> bool:
	if not perk_action_reason(id,action,target).is_empty(): return false
	var u: Dictionary = units[id]
	var cost = active_perk_cost(u,action)
	u.ap -= cost.ap
	u.fatigue += cost.fatigue
	clear_weapon_sequence(u)
	var swap_id := -1
	if action == "indomitable": vital_state(u).indomitable = true
	else:
		if action == "rotation":
			swap_id = at(target)
			var ally: Dictionary = units[swap_id]
			ally.q = u.q; ally.r = u.r; ally.guard = false; cancel_stance(ally); reset_segment(ally)
		u.q = target.x; u.r = target.y; u.guard = false; cancel_stance(u); reset_segment(u)
	refresh_visibility()
	commands.append(["perk",id,action,target.x,target.y])
	log_event(u.name+": "+Perks.catalog()[action].name+".")
	if action in ["footwork","rotation","indomitable"]: _observe_utility(u,action,"weapon")
	if swap_id>=0: _observe_utility(units[swap_id],action,"weapon")
	return true

func _observe_utility(u:Dictionary,kind:String,slot:String,outgoing:String="") -> void:
	# Do not retain this receipt in Battle or snapshots. Recipients qualify sight.
	utility_committed.emit({"id":u.id,"kind":kind,"cell":pos(u),"slot":slot,"uid":str(u.get("arms",{}).get(slot,{}).get("id","")),"outgoing":outgoing})

func weapon_reach(u: Dictionary, special: bool = false) -> int:
	var family := Arsenal.family(u.weapon)
	if special and family == "axe": return 1
	var maximum := int(weapon_stats(u).reach)
	if family == "bow":
		if perk_rules and Perks.has(u,"bow_mastery"): maximum += 1
		if special and weapon_rules: maximum += 1 # Aimed Shot only.
	return maximum

func head_eligible(u: Dictionary, special: bool) -> bool:
	return paid_action(u,special) and not (special and Arsenal.family(u.weapon) in ["hammer","dagger"])

# Axe/mace 0.24 helpers share exact values between actions, AI and previews.
func split_shield_damage(u: Dictionary, v: Dictionary = {}) -> int:
	var damage = 24
	if axe_mace_rules and perk_rules and Arsenal.family(u.weapon) == "axe" and Perks.has(u,"smashing_shields"): damage = 36
	return damage/2 if perk_rules and Perks.has(v,"shield_expert") else damage

func advantage_ready(u: Dictionary, v: Dictionary, reaction: bool = false) -> bool:
	return axe_mace_rules and perk_rules and not reaction and Arsenal.family(u.weapon) == "mace" and Perks.has(u,"push_the_advantage") and v.get("stagger",0) > 0

func apply_stagger(v: Dictionary, source: String) -> bool:
	if not fighting(v) or v.stagger > 0 or vital_state(v).indomitable: return false
	v.ap = maxi(0,v.ap-2); v.stagger = 2
	log_event("%s staggers %s: -2 current and next-turn AP." % [source,v.name])
	combat_feedback.emit({"id":v.id,"kind":"stagger","text":"STAGGER · -2 AP"})
	return true

func axe_mace_notes(u: Dictionary, target: Dictionary = {}) -> String:
	if not axe_mace_rules or not perk_rules: return ""
	if Arsenal.family(u.weapon) == "axe" and Perks.has(u,"smashing_shields"):
		return "Split Shield: %d condition; %d against Shield Expert." % [split_shield_damage(u),split_shield_damage(u,{"perks":["shield_expert"]})]
	if Arsenal.family(u.weapon) == "mace":
		var notes = []
		if Perks.has(u,"concussive_strikes"): notes.append("Damaging paid head hits stagger; no stacking or stun.")
		if Perks.has(u,"push_the_advantage"):
			notes.append("Already staggered: +10 pp head chance, +10% head HP damage." if target.is_empty() else "Advantage ACTIVE: +10 pp head chance, +10% head HP damage." if advantage_ready(u,target) else "Advantage inactive: target is not staggered.")
		return " ".join(notes)
	return ""

# Hammer/dagger state exists only in new encounters, preserving old snapshots exactly.
static func weapon_perk_state() -> Dictionary:
	return {"swift_target":-1,"impact_end":0}

static func valid_weapon_perk_state(s: Variant, count: int = 12) -> bool:
	return s is Dictionary and s.size() == 2 and s.get("swift_target") is int and s.swift_target >= -1 and s.swift_target < count and s.get("impact_end") is int and s.impact_end >= 0 and s.impact_end <= 32

func weapon_state(u: Dictionary) -> Dictionary:
	return u.get("weapon_perk_state",weapon_perk_state())

func clear_weapon_sequence(u: Dictionary) -> void:
	if hammer_dagger_rules: weapon_state(u).swift_target = -1

func swift_ready(u: Dictionary, target: int) -> bool:
	return hammer_dagger_rules and perk_rules and target >= 0 and target < units.size() and fighting(units[target]) and units[target].side != u.side and Arsenal.family(u.weapon) == "dagger" and Perks.has(u,"swift_stabs") and weapon_state(u).swift_target == target

func ribs_bonus(u: Dictionary, v: Dictionary) -> float:
	if not hammer_dagger_rules or not perk_rules or Arsenal.family(u.weapon) != "dagger" or not Perks.has(u,"between_the_ribs") or Perks.has(v,"underdog"): return 0.0
	return 0.1*mini(3,surround_count(v))

func hammer_armor_factor(u: Dictionary) -> float:
	return 1.3 if hammer_dagger_rules and perk_rules and Arsenal.family(u.weapon) == "hammer" and Perks.has(u,"smackdown") else 1.0

func impact_active(u: Dictionary) -> bool:
	return hammer_dagger_rules and perk_rules and weapon_state(u).impact_end > 0

func apply_deep_impact(v: Dictionary) -> void:
	weapon_state(v).impact_end = vital_state(v).activation+1
	log_event(v.name+" is weakened by Deep Impact: -10 attack accuracy, -20% damage.")
	combat_feedback.emit({"id":v.id,"kind":"impact","text":"WEAKENED · -10 HIT / -20% DAMAGE"})

func weapon_perk_notes(u: Dictionary, target: Dictionary = {}) -> String:
	var notes: Array = []
	var old = axe_mace_notes(u,target)
	if not old.is_empty(): notes.append(old)
	if not hammer_dagger_rules or not perk_rules: return old
	if impact_active(u): notes.append("WEAKENED: -10 attack accuracy, -20% damage.")
	if Arsenal.family(u.weapon) == "hammer":
		if Perks.has(u,"smackdown"): notes.append("Smackdown: +30% armour damage.")
		if Perks.has(u,"deep_impact"): notes.append("Shatter HP hits weaken the target through its next activation.")
	if Arsenal.family(u.weapon) == "dagger":
		if Perks.has(u,"between_the_ribs"): notes.append("Surrounding: up to +30% HP damage." if target.is_empty() else "Surrounding: +%d%% HP damage." % roundi(ribs_bonus(u,target)*100))
		if Perks.has(u,"swift_stabs"): notes.append("Swift Stabs: hit to chain against the same target." if target.is_empty() or not swift_ready(u,target.id) else "Swift Stabs ACTIVE: -2 AP, minimum 2.")
	if not target.is_empty() and impact_active(target): notes.append("Target WEAKENED: -10 hit / -20% damage.")
	return " ".join(notes)

func player_slots() -> int: return 12 if roster_rules else 6
func enemy_slots() -> int: return 12 if roster_rules else 6
func width() -> int: return _board_size.x if _board_size != Vector2i.ZERO else 17 if roster_rules else W
func height() -> int: return _board_size.y if _board_size != Vector2i.ZERO else 11 if roster_rules else H
func goal() -> Vector2i: return _board_goal if _board_size != Vector2i.ZERO else Vector2i(8,5) if roster_rules else LEGACY_FORD

func expand_battle() -> void:
	var old_tiles = tiles.duplicate(true)
	tiles.clear()
	for r in height():
		for q in width():
			var original = Vector2i(q-2,r-1)
			tiles[key(Vector2i(q,r))] = old_tiles.get(key(original),{"terrain":"water" if map_id=="ford" and q==8 else "stone" if map_id in ["crypt_barrow","crypt_gallery","crypt_throne"] else "grass","height":0}).duplicate()
	var originals = units.duplicate(true)
	units.clear()
	for team in 2:
		for i in 12:
			var u: Dictionary = originals[team*6+i%6].duplicate(true)
			u.id = units.size()
			if i>=6: u.name += " II"
			u.q = (4 if team==0 else 12)+(1 if team==1 else -1)*(i/6)
			u.r = 2+i%6
			units.append(u)

func is_crypt() -> bool:
	return map_id in ["crypt","crypt_barrow","crypt_gallery","crypt_throne"]+DungeonThemes.FIELDS
