extends RefCounted
## Decisions for finite camp parties. Traffic owns cargo; Overworld owns movement.
const VERSION = 2
var rules_version = VERSION
const MODES = ["scouting","hunting","raiding","hauling","fleeing","returning","recovering","defeated","fighting_patrol","founding","building","foraging"]
const SORTIE_TICKS = 960
const REST_TICKS = 240
const LOSS_REST_TICKS = 720
var enabled = false
var bands: Dictionary = {}
var circuits: Dictionary = {} # Derived from the region; never consumes campaign RNG.

func setup(c, active: bool) -> void:
	enabled = active; rules_version = VERSION; bands.clear(); circuits.clear()
	if enabled: sync(c)

func sync(c) -> void:
	if not enabled: return
	c.overworld.sync_scouts(c.world)
	for s in c.overworld.scouts.values():
		if not bands.has(s.id):
			var threat = clampi(int(c.world.camps[s.site].strength)-1,1,3)
			var health: Array = []
			var count = c.enemy_count(s.site,threat,"scout") if rules_version >= 2 else 3+threat
			for i in 6: health.append(1000 if i < count else 0)
			bands[s.id] = {"mode":"scouting","threat":threat,"health":health,"waypoint":0,"sortie":0,"rest":0,"fear":0,"chase":0}
		if rules_version >= 2 and not bands[s.id].has("capacity"):
			bands[s.id]["capacity"] = c.enemy_count(s.site,bands[s.id].threat,"scout")
			var rating = 0
			for i in bands[s.id].capacity:
				rating += [78,92,112,138][c.CampaignBalance.grade(c.world.camp_role(s.site),bands[s.id].threat,i,"scout")] if c.progression_version == 1 else 90+12*bands[s.id].threat
			bands[s.id]["rating"] = rating / bands[s.id].capacity
		if rules_version == 3: record_members(s.id)
		if s.defeated: bands[s.id].mode = "defeated"
		elif bands[s.id].mode in ["raiding","hauling"] and not c.traffic.missions.has(s.id) and not c.farm.engaged(s.id):
			if bands[s.id].mode == "hauling": bands[s.id].rest = REST_TICKS
			change_mode(bands[s.id],s,"returning" if bands[s.id].rest > 0 else "scouting")

	if c.camp_life.enabled: c.camp_life.sync(c)
	c.recon.sync(c)
	c.raiders.sync(c)
	c.founding.sync(c)

func power(id: String) -> float:
	var b: Dictionary = bands[id]; var total = 0.0
	for hp in b.health: total += hp/1000.0*b.get("rating",90+12*b.threat)
	return total

static func company_power(c) -> float:
	var total = 0.0
	for s in c.soldiers:
		if not s.alive or s.id not in c.active_ids(): continue
		var armor: Dictionary = c.armor_stats(s)
		var protection = float(armor.get("armor",0)+armor.get("padding",0)+armor.get("helmet",0))
		total += (45+c.effective_skill(s)*0.65+s.base_defense*0.8+protection*0.08)*clampf(float(s.hp)/c.max_hp(s),0.15,1.0)
	return total

func sheltered(c, p: Vector2, radius: float = 60) -> bool:
	return c.world.TOWNS.any(func(t):return c.overworld.places[t].distance_to(p) < radius)

func vision(c) -> float:
	return 100.0 if c.overworld.hour < 6 or c.overworld.hour >= 20 else 150.0

func sees_company(c, s: Dictionary, background: bool) -> bool:
	return not background and c.overworld.grace <= 0 and not sheltered(c,c.overworld.position,45) and s.position.distance_to(c.overworld.position) <= vision(c)

func change_mode(b: Dictionary, s: Dictionary, mode: String) -> void:
	if b.mode != mode:
		b.mode = mode; s.path.clear(); s.replan = 0.0

func abandon_freight(c, s: Dictionary, reason: String) -> void:
	c.farm.abandon(c,s.id,reason)
	if not c.traffic.missions.has(s.id): return
	var id: String = c.traffic.missions[s.id]; var v: Dictionary = c.traffic.wagons[id]
	if v.carried: v.position = s.position
	# Scaring off an actual attack frees the goods once, without bounty or loot.
	if v.remaining > 0 or v.carried: c.world.caravans[id].guarded = true
	c.traffic.release(c,id,reason)

func choose_freight(c, s: Dictionary, background: bool) -> String:
	if c.raiders.enabled: return c.raiders.choose_freight(c,s,background)
	var b: Dictionary = bands[s.id]
	if s.defeated or b.rest > 0 or b.fear > 0 or b.sortie >= SORTIE_TICKS or b.chase >= 80 or power(s.id) < (100 if rules_version >= 2 else 260) or c.world.protected_road(s.site): return ""
	var visible = sees_company(c,s,background)
	if visible and company_power(c) > power(s.id)*1.1: return ""
	var best = ""; var score = -1.0
	for id in c.traffic.wagons:
		var v: Dictionary = c.traffic.wagons[id]; var cargo: Dictionary = c.world.caravans[id]
		if c.guards.cover(c,v.position,power(s.id)): continue
		if cargo.status != "transit" or cargo.guarded or not v.raider.is_empty() or c.world.route_data(cargo.route).path[1] != s.site: continue
		var distance: float = s.position.distance_to(v.position)
		if distance > vision(c) or sheltered(c,v.position): continue
		if visible and v.position.distance_to(c.overworld.position) < 100: continue
		var value: float = c.world.cargo_value(id)/(30.0+distance)
		if value > score: best = id; score = value
	return best

func circuit(c, s: Dictionary) -> Array:
	if circuits.has(s.id): return circuits[s.id]
	var ow = c.overworld; var home: Vector2 = ow.places[s.site]; var points: Array = []
	for road in c.world.config.routes:
		if road.path[1] != s.site: continue
		for town in [road.path[0],road.path[2]]:
			var p: Vector2 = ow.scheduled_position(s.site,town,0.65)
			if not sheltered(c,p) and home.distance_to(p) <= 320: points.append(p)
	# A deterministic broad circuit mixes road approaches with nearby wilderness.
	var phase = float(c.world.SITES.find(s.site))*1.7+s.generation*0.6
	for i in 8:
		var p: Vector2 = home+Vector2.from_angle(phase+i*TAU/8)*(170 if i%2 == 0 else 230)
		if ow.valid_point(p) and not sheltered(c,p) and not ow.route(home,p).is_empty(): points.append(p)
	if points.is_empty(): points.append(home)
	circuits[s.id] = points
	return points

func escape_point(c, s: Dictionary, danger: Vector2) -> Vector2:
	var ow = c.overworld
	if s.replan > ow.STEP and not s.path.is_empty(): return s.path.back()
	var best: Vector2 = s.position; var score = -INF
	var away: Vector2 = (s.position-danger).normalized()
	if away == Vector2.ZERO: away = Vector2.RIGHT
	for i in 12:
		var p: Vector2 = s.position+away.rotated(i*TAU/12)*96
		if not ow.valid_point(p) or sheltered(c,p): continue
		var route: Array = ow.route(s.position,p)
		if route.is_empty(): continue
		var clearance: float = p.distance_to(danger)
		# Avoid a path that initially runs into the company to reach a distant refuge.
		for q in route.slice(0,4): clearance = minf(clearance,q.distance_to(danger)+32)
		var value: float = clearance-p.distance_to(ow.places[s.site])*0.08
		if value > score: best = p; score = value
	return best

func order(c, s: Dictionary, background: bool) -> Dictionary:
	var b: Dictionary = bands[s.id]; var ow = c.overworld
	var guard_order: Dictionary = c.guards.order_for(c,s.id)
	if not guard_order.is_empty(): return guard_order
	var home: Vector2 = ow.places[s.site]
	var visible = sees_company(c,s,background)
	var strong = visible and company_power(c) > power(s.id)*(1.1 if b.mode == "fleeing" else 1.25)
	b.fear = maxi(0,b.fear-1)
	if strong:
		c.raiders.danger.remember(c,s.id,c.overworld.position,"company")
		abandon_freight(c,s,"The raiders abandon the freight and flee the stronger company.")
		b.fear = 120; change_mode(b,s,"fleeing")
		return {"position":escape_point(c,s,ow.position),"pace":20.0}
	var patrol_order: Dictionary = c.raiders.patrol_escape(c,s)
	if not patrol_order.is_empty(): return patrol_order
	var founding_order: Dictionary = c.founding.order(c,s,background)
	if not founding_order.is_empty(): return founding_order
	var survival_order: Dictionary = c.raiders.order(c,s,background)
	if not survival_order.is_empty(): return survival_order
	var camp_order: Dictionary = c.camp_life.order_for(c,s)
	if not camp_order.is_empty():
		if b.mode == "recovering" and b.care_day == c.day:
			for i in b.capacity:
				if b.health[i] > 0: b.health[i] = mini(1000,b.health[i]+2)
		return camp_order
	if b.rest > 0 or b.fear > 0 or b.sortie >= SORTIE_TICKS or b.chase >= 80 or c.world.protected_road(s.site):
		abandon_freight(c,s,"The raiders break off and return to camp.")
		if s.position.distance_to(home) <= 10:
			if b.rest == 0 and b.mode != "recovering": b.rest = REST_TICKS
			change_mode(b,s,"recovering")
			b.rest = maxi(0,b.rest-1)
			for i in 6:
				if b.health[i] > 0 and (rules_version != 3 or b.care_day == c.day): b.health[i] = mini(1000,b.health[i]+2)
			if b.rest == 0: b.sortie = 0; b.chase = 0
		else: change_mode(b,s,"returning")
		return {"position":home,"pace":17.0}
	b.sortie = mini(SORTIE_TICKS,b.sortie+1)
	var farm_order: Dictionary = c.farm.order_for(c,s.id)
	if not farm_order.is_empty():
		change_mode(b,s,farm_order.mode)
		return farm_order
	var mission: Dictionary = c.traffic.order_for(s,ow)
	if not mission.is_empty():
		var v: Dictionary = c.traffic.wagons[c.traffic.missions[s.id]]
		change_mode(b,s,"hauling" if v.carried else "raiding")
		return {"position":mission.position,"pace":14.0 if v.carried else 17.0}
	var hunt = (not c.raiders.enabled or c.raiders.urgency(c,s.id) == 0) and visible and company_power(c) <= power(s.id)*(1.1 if b.mode == "hunting" else 0.85) and ow.position.distance_to(home) <= 360
	if hunt:
		b.chase += 1; change_mode(b,s,"hunting")
		return {"position":ow.position,"pace":19.0}
	if b.mode == "hunting":
		b.rest = 80; change_mode(b,s,"returning")
		return {"position":home,"pace":17.0}
	change_mode(b,s,"scouting")
	var points = circuit(c,s)
	if s.position.distance_to(points[b.waypoint%points.size()]) < 10:
		b.waypoint = (b.waypoint+1)%points.size(); s.path.clear()
	return {"position":points[b.waypoint%points.size()],"pace":17.0}

func deploy(c) -> void:
	if not enabled or c.encounter.get("kind") != "scout": return
	var b: Dictionary = bands[c.encounter.id]
	for i in 6:
		var u: Dictionary = c.battle.units[c.battle.player_slots()+i]
		if b.has("lineage") and i < b.capacity:
			c.CampaignBalance.equip(c,u,b.threat,i,"scout",c.world.camp_role(c.overworld.scouts[b.lineage].site))
			u.ranged_skill = u.skill if u.weapon in c.Arsenal.RANGED else 40+(u.id*7)%15
		u.hp = maxi(1,ceili(u.max_hp*b.health[i]/1000.0)) if b.health[i] > 0 else 0
		if u.hp == 0: u.name = "Empty rank" # Excludes previously dead members from loot recovery.

func settle(c, id: String, won: bool) -> String:
	if not enabled: return ""
	var b: Dictionary = bands[id]; var s: Dictionary = c.overworld.scouts[id]
	var before: Array = b.health.duplicate()
	for i in 6:
		var u: Dictionary = c.battle.units[c.battle.player_slots()+i]
		b.health[i] = mini(before[i],floori(1000.0*u.hp/u.max_hp))
	if won or b.health.all(func(hp):return hp == 0):
		s.defeated = true; b.mode = "defeated"; return ""
	if b.health != before:
		b.rest = LOSS_REST_TICKS; b.fear = 0
		change_mode(b,s,"returning")
		abandon_freight(c,s,"Bloodied raiders abandon the freight and retreat home.")
		return "The surviving raiders retreat to camp to recover. Their casualties remain lost."
	return ""

func caption(id: String) -> String:
	var b: Dictionary = bands[id]
	return "%s · %d" % [{"scouting":"SCOUTING","hunting":"HUNTING YOU","raiding":"RAIDING","hauling":"HAULING LOOT","fleeing":"FLEEING","returning":"RETURNING HOME","recovering":"RECOVERING","defeated":"DEFEATED","fighting_patrol":"FIGHTING GUARDS","founding":"MOVING CAMP","building":"BUILDING CAMP","foraging":"FORAGING"}[b.mode],b.health.filter(func(hp):return hp > 0).size()]

func snapshot() -> Dictionary:
	return {"version":rules_version,"bands":bands.duplicate(true)}

func restore(d: Variant, ow, traffic, progression: int = 0, opening: bool = false, farm = null, guards = null, shares: bool = false) -> bool:
	if not d is Dictionary or d.get("version") not in [1,2,3] or not d.get("bands") is Dictionary or d.bands.size() != ow.scouts.size(): return false
	for id in ow.scouts:
		var b = d.bands.get(id)
		if not b is Dictionary or b.get("mode") not in MODES: return false
		if (b.mode == "defeated") != ow.scouts[id].defeated: return false
		for field in ["threat","waypoint","sortie","rest","fear","chase"]:
			if not b.get(field) is int: return false
		if b.threat < 1 or b.threat > 3 or b.waypoint < 0 or b.waypoint > 31 or b.sortie < 0 or b.sortie > SORTIE_TICKS or b.rest < 0 or b.rest > LOSS_REST_TICKS or b.fear < 0 or b.fear > 120 or b.chase < 0 or b.chase > 80: return false
		if not b.get("health") is Array or b.health.size() != 6: return false
		var capacity = 3+b.threat
		if d.version >= 2:
			if b.has("lineage") and (not ow.physical_founding or not b.lineage is String or not ow.scouts.has(b.lineage) or not b.get("inherited") is int or b.inherited < 0): return false
			if b.has("inherited") != b.has("lineage"): return false
			if b.mode in ["founding","building"] and not ow.physical_founding: return false
			if b.mode == "foraging" and not ow.raider_survival: return false
			var origin: String = ow.scouts[b.get("lineage",id)].site
			var site: String = ow.camp_roles.get(origin,origin)
			capacity = preload("res://src/campaign_balance.gd").count(site,b.threat,"scout") if progression == 1 else 2 if opening and site == "ford" else 3+b.threat
			if not b.get("capacity") is int or not b.get("rating") is int: return false
			if b.has("base_capacity"):
				if not shares or not b.base_capacity is int or b.base_capacity != capacity or b.capacity <= capacity or b.capacity > 6-preload("res://src/camp_recon.gd").resident_count(site,3): return false
			elif b.capacity != capacity: return false
			if b.has("departed") and not shares: return false
			var rating = 0
			for i in capacity: rating += [78,92,112,138][preload("res://src/campaign_balance.gd").grade(site,b.threat,i,"scout")] if progression == 1 else 90+12*b.threat
			if b.rating != rating/capacity: return false
			capacity = b.capacity
		elif b.has("capacity") or b.has("rating"): return false
		for i in 6:
			var hp = b.health[i]
			if not hp is int or hp < 0 or hp > 1000 or (i >= capacity and hp != 0): return false
		if d.version == 3:
			if not valid_members(id,b): return false
		elif b.has("members") or b.has("fallen") or b.has("next_member") or b.has("care_day"): return false
		if not ow.scouts[id].defeated and b.health.all(func(hp):return hp == 0): return false
		if (b.mode == "fighting_patrol") != (guards != null and guards.engaged(id)): return false
		var farming: bool = farm != null and farm.engaged(id)
		if farming and traffic.missions.has(id): return false
		if b.mode in ["raiding","hauling"] and not traffic.missions.has(id) and not farming: return false
		if b.mode == "hauling":
			if farming:
				if farm.raid_for(id).phase != "return": return false
			elif not traffic.wagons[traffic.missions[id]].carried: return false
	enabled = true; rules_version = d.version; bands = d.bands.duplicate(true); circuits.clear()
	return true

func record_members(id: String) -> void:
	var b: Dictionary = bands[id]
	if not b.has("members"):
		b["members"] = []; b["fallen"] = []; b["next_member"] = b.capacity+1; b["care_day"] = 0
		for i in 6: b.members.append("%s/m%d" % [id,i+1] if i < b.capacity else "")
	for i in b.capacity:
		if b.health[i] == 0 and b.members[i] not in b.fallen and b.members[i] not in b.get("departed",[]): b.fallen.append(b.members[i])

static func valid_members(id: String, b: Dictionary) -> bool:
	if not b.get("members") is Array or b.members.size() != 6 or not b.get("fallen") is Array or not b.get("next_member") is int or not b.get("care_day") is int: return false
	if b.next_member < b.capacity+1 or b.care_day < 0: return false
	var all_members = {}; var dead = {}
	if not b.get("departed",[]) is Array: return false
	for member in b.fallen+b.get("departed",[]):
		if not member is String or dead.has(member): return false
		dead[member] = true; all_members[member] = true
	for i in 6:
		var member = b.members[i]
		if i >= b.capacity:
			if member != "": return false
			continue
		if not member is String or member == "" or b.members.count(member) != 1 or (b.health[i] == 0) != dead.has(member): return false
		all_members[member] = true
	if all_members.size() != b.next_member-1: return false
	for serial in range(1,b.next_member):
		if not all_members.has("%s/m%d" % [b.get("lineage",id),serial]): return false
	return true
