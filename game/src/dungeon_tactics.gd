extends RefCounted
## Deterministic decisions from visible state. No extra attacks, rolls or buffs.
const A = preload("res://src/arsenal.gd")
const BOSSES = ["barrow_lord","watch_captain","buried_king"]
const DESCRIPTIONS = {
	"barrow_lord":"The guards close shields around their lord. Split the line to remove their shieldwall support.",
	"watch_captain":"Spears cover the captain's firing lanes. He shifts before reloading; engage him to force his sword.",
	"buried_king":"Sentinels hold the centre. The king targets fighters pinned by his guards; spread out and turn their flank."
}

static func leader(b, living_only: bool = true) -> Dictionary:
	for u in b.units:
		if u.side == 1 and u.get("undead_kind","") in BOSSES and (not living_only or b.fighting(u)): return u
	return {}

static func description(b) -> String:
	var boss := leader(b,false)
	if boss.get("weapon") == "":
		return "The undead do not flee. They close in to strike without weapons or armour."
	return DESCRIPTIONS.get(boss.get("undead_kind",""),"")

static func nearest(b, u: Dictionary, p: Vector2i) -> int:
	var value = 99
	for v in b.units:
		if b.fighting(v) and v.side != u.side: value = mini(value,b.distance(p,b.pos(v)))
	return value

static func handled(b, u: Dictionary, boss: Dictionary) -> bool:
	return not boss.is_empty() and u.side == 1 and u.has("undead_kind") and (u.id == boss.id or u.shield)

static func allies_pinning(b, u: Dictionary, target: Dictionary) -> int:
	var count = 0
	for ally in b.units:
		if ally.id != u.id and ally.side == u.side and b.fighting(ally) and not ally.weapon in A.RANGED and b.distance(b.pos(ally),b.pos(target)) == 1: count += 1
	return count

static func target_score(b, u: Dictionary, v: Dictionary) -> float:
	var score: float = b.hit_chance(u.id,v.id)+(1.0-float(v.hp)/v.max_hp)*25
	if u.get("undead_kind","") == "buried_king":
		# Existing surround rules supply accuracy; this is target preference only.
		score += allies_pinning(b,u,v)*18
	return score

static func position_score(b, u: Dictionary, p: Vector2i, boss: Dictionary) -> float:
	var near = nearest(b,u,p)
	var threats: int = b.adjacent_enemies(u,p).size()
	var kind: String = boss.undead_kind
	if u.id == boss.id and kind == "watch_captain" and u.weapon in A.RANGED:
		var clone = u.duplicate(); clone.q = p.x; clone.r = p.y
		var shots = 0; var best_hit = 0
		for v in b.units:
			if not b.fighting(v) or v.side == u.side or not b.in_range(clone,v): continue
			shots += 1
			# Range/cover decide the lane; no RNG or unseen campaign state.
			best_hit = maxi(best_hit,10-b.distance(p,b.pos(v)))
		var score = -absf(near-4)*5-threats*35+mini(shots,3)*5+best_hit
		for ally in b.units:
			if ally.id != u.id and ally.side == u.side and b.fighting(ally) and ally.shield and b.distance(p,b.pos(ally)) <= 2 and nearest(b,ally,b.pos(ally)) < near:
				score += 6; break
		return score
	if u.id == boss.id and kind == "buried_king":
		var score = -maxi(0,near-1)*3.0-maxi(0,threats-2)*6.0
		for v in b.units:
			if b.fighting(v) and v.side != u.side and b.distance(p,b.pos(v)) == 1: score += 4+allies_pinning(b,u,v)*7
		return score
	if kind == "barrow_lord":
		var score = -maxi(0,near-1)*2.5+mini(2,b.shield_neighbors(u,p).size())*4.0-maxi(0,threats-2)*4.0
		if u.id != boss.id: score -= maxi(0,b.distance(p,b.pos(boss))-1)*7.0
		return score
	if kind == "watch_captain":
		var score = -absf(b.distance(p,b.pos(boss))-2)*4.0-maxi(0,near-1)*2.0
		if near < nearest(b,boss,b.pos(boss)): score += 5
		# Do not stand directly in a clear firing lane to a visible target.
		for v in b.units:
			if b.fighting(v) and v.side != u.side and b.distance(b.pos(boss),p)+b.distance(p,b.pos(v)) == b.distance(b.pos(boss),b.pos(v)): score -= 3
		return score
	# Royal shields contest the central approach, but can engage flankers nearby.
	var anchor: Vector2i = b.goal()+Vector2i(2,0)
	return -maxi(0,near-1)*2.5-b.distance(p,anchor)*2.0-maxi(0,b.distance(p,b.pos(boss))-2)*3.0+mini(2,b.shield_neighbors(u,p).size())*2.0

static func move_best(b, u: Dictionary, boss: Dictionary, reserve_ap: int = 0) -> bool:
	var best: Vector2i = b.pos(u)
	var score = position_score(b,u,best,boss)
	# Use actual reachable routes, including fatigue and engagement restrictions.
	for route in b.movement_map(u.id).values():
		if u.ap-route.cost < reserve_ap: continue
		var p: Vector2i = route.path.back()
		var candidate = position_score(b,u,p,boss)-route.cost*0.2
		if candidate > score+0.01: best = p; score = candidate
	return best != b.pos(u) and b.move_unit(u.id,best)

static func step(b, u: Dictionary) -> bool:
	var boss = leader(b)
	if not handled(b,u,boss): return false
	var id: int = u.id
	if not u.stance.is_empty(): b.finish_unit(id); return true
	if u.fatigue >= b.fatigue_max(u)*0.65 and b.recover(id): return true
	var engaged: bool = not b.adjacent_enemies(u,b.pos(u)).is_empty()
	if u.id == boss.id and boss.undead_kind == "watch_captain":
		if u.weapon in A.RANGED:
			if engaged or b.ammo_count(u) <= 0:
				for slot in A.bag_slots(u):
					if u.arms[slot].get("definition","") == "sword" and b.switch_carried(id,slot): return true
			elif not u.arms.weapon.loaded:
				# One legal shift before reloading, retaining its normal AP cost.
				var state: Dictionary = b.vital_state(u)
				if b.pos(u) == Vector2i(state.origin_q,state.origin_r) and move_best(b,u,boss,b.action_cost(u,true).ap): return true
				if b.use_weapon(id,true): return true
		elif not engaged:
			for slot in A.bag_slots(u):
				if u.arms[slot].get("definition","") == "heavy_crossbow" and int(u.arms.ammo.get("condition",0)) > 0 and b.switch_carried(id,slot): return true
	# Hold an established wall after striking, instead of spending the last AP
	# on another attack and immediately dropping it. A flank can isolate shields.
	if u.shield and u.ap < 8 and not u.guard and nearest(b,u,b.pos(u)) <= 2 and not b.shield_neighbors(u,b.pos(u)).is_empty() and b.guard_unit(id): return true
	if u.guard: b.finish_unit(id); return true
	if boss.undead_kind == "watch_captain" and u.id != boss.id and A.family(u.weapon) == "spear" and not engaged and nearest(b,u,b.pos(u)) in [2,3] and b.distance(b.pos(u),b.pos(boss)) <= 3 and b.use_weapon(id,true): return true
	if b.ai_weapon_step(id): return true
	var target = -1; var score = -INF
	for v in b.units:
		if b.can_attack(id,v.id):
			var candidate = target_score(b,u,v)
			if candidate > score: target = v.id; score = candidate
	if target >= 0: return b.attack(id,target)
	if move_best(b,u,boss): return true
	if not u.guard and b.guard_unit(id): return true
	b.finish_unit(id)
	return true
