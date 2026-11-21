extends RefCounted
## Council-funded physical service; every party belongs to its own town.
const VERSION = 1
const REST = 480
const ROUND_TICKS = 20 # One world hour; leaves time for a nearby company to help.
const RECRUIT_COST = 18
const MODES = ["patrolling","responding","fighting","returning","recovering","unpaid","defeated"]
var regional = false
var enabled = false
var faction = ""
var parties: Dictionary = {}

func setup(c, active: bool) -> void:
	enabled = active
	if not enabled: return
	regional = c.farm.regional
	faction = c.world.towns[c.farm.TOWN].owner
	if regional:
		for f in c.farm.all(): c.world.physical_sites[c.world.towns[f.town].owner] = f.camp
	c.world.physical_faction = faction
	c.world.physical_site = c.farm.camp
	sync(c)

func home(c, id: String = "") -> Vector2:
	return c.overworld.places[home_town(c,id)]

func home_town(c, id: String = "") -> String:
	return c.world.config.factions[c.world.patrols[id].faction if not id.is_empty() else faction].town

func sync(c) -> void:
	if not enabled: return
	for g in parties.values():
		if not g.target.is_empty() and c.overworld.scouts[g.target].defeated: go_home(c,g)
	for p in c.world.patrols.values():
		if not c.world.has_physical(p.faction) or parties.has(p.id): continue
		parties[p.id] = {"position":home(c,p.id),"path":[],"mode":"patrolling","health":[1000,1000,1000,1000,1000],"target":"","waypoint":0,"rest":0,"round":0,"paid_day":c.day,"wins":0,"losses":0,"recruits":0,"alerted":false}
		c.world.log_event("%s leaves %s with five guards. Protection travels with the patrol." % [p.id.replace("patrol_","P"),c.node(home_town(c,p.id)).name])

static func power(g: Dictionary) -> float:
	var total = 0.0
	for hp in g.health: total += hp*0.105
	return total

func engaged(sid: String) -> bool:
	return enabled and parties.values().any(func(g):return g.mode == "fighting" and g.target == sid)

func cover(c, at: Vector2, threat: float) -> bool:
	if not enabled: return false
	return parties.values().any(func(g):return g.mode in ["patrolling","responding"] and g.paid_day == c.day and g.position.distance_to(at) <= 60 and power(g) >= threat*0.85)

func change(g: Dictionary, mode: String) -> void:
	if g.mode != mode: g.mode = mode; g.path.clear()

func release_target(c, g: Dictionary) -> void:
	if not g.target.is_empty() and c.bandits.bands.has(g.target):
		var b: Dictionary = c.bandits.bands[g.target]
		if b.mode == "fighting_patrol":
			b.rest = maxi(b.rest,80)
			c.bandits.change_mode(b,c.overworld.scouts[g.target],"returning")
	g.target = ""; g.round = 0; g.alerted = false

func go_home(c, g: Dictionary) -> void:
	release_target(c,g); change(g,"returning"); g.rest = REST

func daily(c) -> void:
	if not enabled: return
	sync(c)
	for id in parties:
		var council: Dictionary = c.world.factions[c.world.patrols[id].faction]
		var g: Dictionary = parties[id]
		if g.mode == "defeated" or g.paid_day == c.day: continue
		if council.treasury < c.world.config.politics.patrol_wage:
			if g.mode != "unpaid":
				go_home(c,g)
				c.world.log_event(id.replace("patrol_","P")+" cannot be paid. Guards withdraw; their route is exposed.")
			continue
		council.treasury -= c.world.config.politics.patrol_wage; council.spent += c.world.config.politics.patrol_wage
		g.paid_day = c.day
		if g.mode == "unpaid": change(g,"recovering"); g.rest = REST
		if g.position.distance_to(home(c,id)) <= 1 and g.mode == "recovering":
			var dead: int = g.health.find(0)
			if dead >= 0 and council.treasury >= RECRUIT_COST:
				council.treasury -= RECRUIT_COST; council.spent += RECRUIT_COST
				g.health[dead] = 1000; g.recruits += 1
				c.world.log_event("%s recruits one replacement in town for %d crowns." % [id.replace("patrol_","P"),RECRUIT_COST])

func goals(c, id: String) -> Array:
	var site: String = c.world.patrols[id].site
	var f = c.farm.for_town(home_town(c,id))
	var road: Vector2 = c.overworld.scheduled_position(f.town,site,0.65)
	return [f.position,road,home(c,id)] if site == f.camp else [road,home(c,id)]

func before_step(c, background: bool = false) -> void:
	if not enabled: return
	sync(c)
	var ow = c.overworld
	for id in parties:
		var g: Dictionary = parties[id]
		if g.mode == "defeated": continue
		if g.mode == "fighting":
			if ow.scouts[g.target].defeated: go_home(c,g)
			else: continue
		if g.mode in ["recovering","unpaid"]:
			if g.paid_day != c.day: change(g,"unpaid"); continue
			for i in 5:
				if g.health[i] > 0: g.health[i] = mini(1000,g.health[i]+3)
			g.rest = maxi(0,g.rest-1)
			if g.rest == 0 and power(g) >= 280: change(g,"patrolling")
			else: continue
		var target: Vector2 = home(c,id)
		if g.mode != "returning":
			var nearest = ""; var distance = 80.0 if ow.hour < 6 or ow.hour >= 20 else 120.0
			for s in ow.scouts.values():
				if regional and parties.keys().any(func(other):return other != id and parties[other].mode in ["responding","fighting"] and parties[other].target == s.id): continue
				if s.defeated or (not c.rebuilding.enabled and s.site != c.world.patrols[id].site) or s.position.distance_to(home(c,id)) > 360: continue
				var d: float = s.position.distance_to(g.position)
				if d < distance: nearest = s.id; distance = d
			if not nearest.is_empty():
				change(g,"responding"); g.target = nearest; target = ow.scouts[nearest].position
				g.path.clear() # Follow only the currently visible position.
			else:
				g.target = ""; change(g,"patrolling")
				var priority: Dictionary = c.rebuilding.patrol_goal(c,id)
				var points = [priority.position] if not priority.is_empty() else goals(c,id)
				if c.rebuilding.enabled and not g.path.is_empty() and g.path.back().distance_to(points[g.waypoint%points.size()]) > 8: g.path.clear()
				target = points[g.waypoint%points.size()]
				if g.position.distance_to(target) < 8:
					if c.raiders.enabled and c.raiders.rules_version >= 2 and g.waypoint > 0 and target.distance_to(home(c,id)) < 1:
						# Finishing a real patrol circuit creates a paid twelve-hour rest shift.
						go_home(c,g); g.rest = 240; g.waypoint = 0; target = home(c,id)
					else:
						g.waypoint = (g.waypoint+1)%points.size(); g.path.clear(); target = points[g.waypoint]
		if g.path.is_empty(): g.path = ow.route(g.position,target)
		g.position = ow.advance_party(g.position,g.path,ow.STEP,19.0 if g.mode == "responding" else 16.0)
		if g.mode == "returning" and g.position.distance_to(home(c,id)) <= 1 and g.path.is_empty():
			change(g,"recovering" if g.paid_day == c.day else "unpaid")
			c.world.log_event(id.replace("patrol_","P")+" reaches town. Survivors rest; replacements require council funds.")

func order_for(c, sid: String) -> Dictionary:
	if not engaged(sid): return {}
	return {"position":c.overworld.scouts[sid].position,"pace":0.0}

static func hurt(health: Array, damage: int) -> void:
	for i in health.size():
		var loss = mini(health[i],damage); health[i] -= loss; damage -= loss
		if damage <= 0: break

func after_step(c, background: bool = false) -> void:
	if not enabled: return
	for id in parties:
		var g: Dictionary = parties[id]
		if g.mode == "responding" and not g.target.is_empty() and c.overworld.pending != g.target:
			if g.position.distance_to(c.overworld.scouts[g.target].position) < 18:
				change(g,"fighting"); g.round = ROUND_TICKS
				c.bandits.abandon_freight(c,c.overworld.scouts[g.target],"Town guards reach the raiders. The attack on supplies is broken off.")
				c.bandits.change_mode(c.bandits.bands[g.target],c.overworld.scouts[g.target],"fighting_patrol")
				c.world.log_event(id.replace("patrol_","P")+" engages a roaming band. Reach the fight to help the guards.")
		if g.mode != "fighting" or c.overworld.pending == g.target: continue
		if not background and not g.alerted and g.position.distance_to(c.overworld.position) < c.overworld.sight():
			g.alerted = true; c.overworld.paused = true
		g.round -= 1
		if g.round > 0: continue
		g.round = ROUND_TICKS
		var s: Dictionary = c.overworld.scouts[g.target]; var b: Dictionary = c.bandits.bands[g.target]
		var guards_hit = maxi(140,roundi(power(g)*1.3)); var band_hit = maxi(140,roundi(c.bandits.power(s.id)*1.3))
		hurt(g.health,band_hit); hurt(b.health,guards_hit)
		if b.health.all(func(hp):return hp == 0):
			s.defeated = true; b.mode = "defeated"; g.wins += 1
			if c.traffic.pursuit == s.id:
				c.traffic.pursuit = ""; c.overworld.path.clear(); c.overworld.destination = ""; c.overworld.paused = true
			c.world.log_event(id.replace("patrol_","P")+" defeats the field band. Its main camp remains; surviving guards return to recover.")
		if g.health.all(func(hp):return hp == 0):
			g.losses += 1; release_target(c,g); change(g,"defeated"); c.world.patrols[id].status = "defeated"
			c.world.log_event(id.replace("patrol_","P")+" is destroyed. The road and farm have lost their guard.")
		elif s.defeated: go_home(c,g)
		elif g.health.filter(func(hp):return hp > 0).size() <= 2:
			g.losses += 1; b.rest = c.bandits.LOSS_REST_TICKS
			go_home(c,g)
			c.world.log_event(id.replace("patrol_","P")+" falls back with casualties. Survivors must reach town before recovering.")
	c.bandits.sync(c)

func player_intervenes(c) -> void:
	if not enabled or c.encounter.get("kind") != "scout": return
	for g in parties.values():
		if g.mode == "fighting" and g.target == c.encounter.id:
			go_home(c,g)
			c.note("Your company takes over the fight. The surviving guards withdraw to recover; the raiders keep their wounds.")

func fund(c, town: String = "ashwick") -> bool:
	var f = c.farm.for_town(town)
	if not enabled or f == null or not f.at_client(c) or c.crowns < 90: return false
	var council: Dictionary = c.world.factions[c.world.towns[town].owner]
	c.crowns -= 90
	council.treasury += 90; council.contributions += 90
	c.note("90 crowns donated to the town guard: wages and replacements still require time. No immediate recruits or protection.")
	return true

func snapshot() -> Dictionary:
	var out = {"version":2 if regional else VERSION,"faction":faction,"parties":parties.duplicate(true)}
	for g in out.parties.values(): g.position = [g.position.x,g.position.y]; g.path = g.path.map(func(p):return [p.x,p.y])
	return out

func restore(d: Variant, ow, w, farm, adaptive: bool = false) -> bool:
	if not d is Dictionary or d.get("version") not in [1,2] or d.get("faction") != w.towns.ashwick.owner or not d.get("parties") is Dictionary: return false
	if (d.version == 2) != farm.regional: return false
	var records: Array = w.patrols.values().filter(func(p):return d.version == 2 or p.faction == d.faction)
	if records.size() != d.parties.size(): return false
	var taken = {}
	for p in records:
		var g = d.parties.get(p.id)
		if not g is Dictionary or g.get("mode") not in MODES or not ow.valid_xy(g.get("position")) or not g.get("path") is Array or g.path.size() > 1800 or not g.get("health") is Array or g.health.size() != 5: return false
		for point in g.path:
			if not ow.valid_xy(point): return false
		if not ow.valid_route(g.position,g.path): return false
		for hp in g.health:
			if not hp is int or hp < 0 or hp > 1000: return false
		for field in ["waypoint","rest","round","paid_day","wins","losses","recruits"]:
			if not g.get(field) is int or g[field] < 0: return false
		if g.waypoint > 2 or g.rest > REST or g.round > ROUND_TICKS or g.paid_day < p.started or g.paid_day > w.day or not g.get("alerted") is bool or not g.get("target") is String: return false
		if (g.mode == "defeated") != (p.status == "defeated") or (g.mode == "defeated") != g.health.all(func(hp):return hp == 0): return false
		if g.mode != "defeated" and p.status != "marching": return false
		if g.mode in ["recovering","unpaid"] and (Vector2(g.position[0],g.position[1]) != ow.places[w.config.factions[p.faction].town] or not g.path.is_empty()): return false
		if g.mode in ["responding","fighting"]:
			if not ow.scouts.has(g.target) or ow.scouts[g.target].defeated or (not adaptive and ow.scouts[g.target].site != p.site) or taken.has(g.target): return false
			taken[g.target] = true
		elif not g.target.is_empty(): return false
		if g.mode == "fighting":
			if g.round < 1 or not g.path.is_empty() or Vector2(g.position[0],g.position[1]).distance_to(ow.scouts[g.target].position) >= 20: return false
		elif g.round != 0: return false
	regional = d.version == 2
	if regional:
		for f in farm.all(): w.physical_sites[w.towns[f.town].owner] = f.camp
	enabled = true; faction = d.faction; parties = d.parties.duplicate(true); w.physical_faction = faction
	w.physical_site = farm.camp
	for g in parties.values(): g.position = Vector2(g.position[0],g.position[1]); g.path = ow.unpack_path(g.path)
	return true
