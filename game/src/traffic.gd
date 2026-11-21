extends RefCounted
## Physical freight. World owns every food unit; this module owns movement and raids.
const VERSION = 2
var rules_version = VERSION
const ATTACK_TICKS = 80 # Four world hours to break the caravan's defence.
const WAGON_SPEED = 14.0
var enabled = false
var fading_tracks = false
var wagons: Dictionary = {}
var missions: Dictionary = {} # existing scout id -> shipment id
var traces: Dictionary = {}
var alerts: Array = []
var pursuit = ""

func setup(c, active: bool) -> void:
	fading_tracks = c.overworld.tracks.enabled
	enabled = active; rules_version = VERSION; c.overworld.road_corner_rules = true; wagons.clear(); missions.clear(); traces.clear(); alerts.clear(); pursuit = ""
	c.world.spatial_trade = enabled
	if enabled: sync(c)

func sync(c) -> void:
	if not enabled: return
	if c.economy.enabled:c.economy.freight.sync(c)
	var ow = c.overworld; var w = c.world
	for id in w.caravans:
		var cargo: Dictionary = w.caravans[id]; var route: Dictionary = w.route_data(cargo.route)
		if not wagons.has(id):
			wagons[id] = {"position":ow.places[route.path[cargo.index]],"path":[],"leg":cargo.index,"status":cargo.status,"raider":"","remaining":0,"carried":false}
		var v: Dictionary = wagons[id]
		if not v.raider.is_empty():
			var s: Dictionary = ow.scouts[v.raider]
			if s.defeated or (not ow.raider_survival and (not w.camps[s.site].active or w.protected_road(s.site))): release(c,id,"Patrols or the camp's fall free the caravan.")
		if v.status != cargo.status:
			v.path.clear(); v.status = cargo.status; v.leg = cargo.index
			if cargo.status in ["transit","escort"]: c.news.depart(c,id)
			elif cargo.status == "delivered": c.news.arrive(c,id)
			elif cargo.status == "plundered": c.news.lost(id)
			if cargo.status == "transit" and cargo.recovered: v.position = ow.places[route.path[1]]
			if cargo.status in ["seized","plundered","delivered","escort"] and not v.raider.is_empty(): release(c,id,"")
		if cargo.status == "escort": v.position = ow.position
		if v.leg != cargo.index: v.leg = cargo.index; v.path.clear()

func release(c, id: String, message: String) -> void:
	var v: Dictionary = wagons[id]
	missions.erase(v.raider)
	v.raider = ""; v.remaining = 0; v.carried = false; v.path.clear()
	if not message.is_empty(): c.world.log_event(c.world.short_id(id)+": "+message)

func move_wagons(c, background: bool = false) -> void:
	if not enabled: return
	sync(c)
	var ow = c.overworld; var w = c.world
	if not pursuit.is_empty():
		var chased: Dictionary = ow.scouts[pursuit]
		if chased.defeated or chased.position.distance_to(ow.position) > ow.sight():
			pursuit = ""; ow.path.clear(); ow.paused = true; c.note("The pursuit stops: the party is defeated or out of sight.")
		else: ow.path = ow.route(ow.position,chased.position)
	for id in wagons:
		var v: Dictionary = wagons[id]; var cargo: Dictionary = w.caravans[id]
		if cargo.status != "transit" or v.remaining > 0 or v.carried: continue
		var r: Dictionary = w.route_data(cargo.route)
		var target: Vector2 = ow.places[r.path[cargo.index+1]]
		if v.path.is_empty(): v.path = ow.route(v.position,target)
		v.position = ow.advance_party(v.position,v.path,ow.STEP,WAGON_SPEED)
		if v.path.is_empty() and v.position.distance_to(target) < 1:
			cargo.index += 1; v.leg = cargo.index
			if cargo.index == 2:
				w.deliver(id); c.news.arrive(c,id); v.status = cargo.status; release(c,id,"")
			else:
				cargo.remaining = 1
				c.raiders.shares.market_stop(c,id)
	# A band hunts freight on the road it threatens. No extra enemies are spawned.
	for s in ow.scouts.values():
		if s.defeated or c.guards.engaged(s.id) or missions.has(s.id) or c.farm.engaged(s.id) or (not ow.raider_survival and w.protected_road(s.site)): continue
		var closest = ""; var distance = 250.0
		if c.bandits.enabled:
			closest = c.bandits.choose_freight(c,s,background)
			if not closest.is_empty():
				missions[s.id] = closest; wagons[closest].raider = s.id; s.path.clear(); s.replan = 0.0
			continue
		for id in wagons:
			var cargo: Dictionary = w.caravans[id]; var v: Dictionary = wagons[id]
			if cargo.status != "transit" or cargo.guarded or not v.raider.is_empty() or w.route_data(cargo.route).path[1] != s.site: continue
			var d: float = s.position.distance_to(v.position)
			if d < distance: closest = id; distance = d
		if not closest.is_empty():
			missions[s.id] = closest; wagons[closest].raider = s.id; s.path.clear(); s.replan = 0.0

func order_for(s: Dictionary, ow) -> Dictionary:
	if not enabled or not missions.has(s.id): return {}
	var v: Dictionary = wagons[missions[s.id]]
	return {"position":ow.places[s.site] if v.carried else v.position,"committed":v.carried or v.remaining > 0}

func resolve_contacts(c, background: bool = false) -> bool:
	if not enabled: return false
	var changed = false; var ow = c.overworld; var w = c.world
	if not ow.pending.is_empty(): pursuit = ""
	for scout_id in missions.keys():
		var id: String = missions[scout_id]; var v: Dictionary = wagons[id]; var s: Dictionary = ow.scouts[scout_id]
		if ow.pending == scout_id: continue # Tactical contact freezes the contested cargo.
		if v.carried:
			v.position = s.position
			var trail: Array = traces[id].points
			if s.position.distance_to(trail.back()) >= 12: trail.append(s.position)
			if s.position.distance_to(ow.places[s.site]) < 12:
				v.position = ow.places[s.site]; trail.append(v.position)
				w.caravans[id].index = 1; w.seize(id); v.status = "seized"; v.leg = 1
				release(c,id,""); changed = true
		elif s.position.distance_to(v.position) < 18 and not w.TOWNS.any(func(t):return ow.places[t].distance_to(v.position) < 45):
			if v.remaining == 0: v.remaining = ATTACK_TICKS; v.path.clear(); changed = true
			else:
				v.remaining -= 1
				if v.remaining == 0:
					if c.economy.enabled and w.caravans[id].has("material") and c.economy.freight.capture_material(c,id,scout_id):
						traces[id] = {"position":v.position,"site":s.site,"generation":s.generation,"day":c.day,"rumour":false,"discovered":false,"inspected":false,"points":[v.position],"seizer":scout_id}
						release(c,id,""); sync(c); changed = true; continue
					if c.raiders.enabled and not w.caravans[id].has("material"):
						c.raiders.capture(c,scout_id,id)
						traces[id] = {"position":v.position,"site":s.site,"generation":s.generation,"day":c.day,"rumour":false,"discovered":false,"inspected":false,"points":[v.position]}
						release(c,id,""); sync(c); changed = true; continue
					v.carried = true
					traces[id] = {"position":v.position,"site":s.site,"generation":s.generation,"day":c.day,"rumour":false,"discovered":false,"inspected":false,"points":[v.position]}
					s.path.clear(); s.replan = 0.0
					w.log_event("%s is overrun. Raiders are hauling its %s back to camp." % [w.short_id(id),w.cargo_text(id)]); changed = true
		# If a party abandons its attack to pursue the player, the defence timer stops.
		if not background and v.remaining > 0 and v.position.distance_to(ow.position) < ow.sight() and id not in alerts:
			alerts.append(id); ow.paused = true; c.note("%s is under attack! Reach the raiders to defend its cargo." % w.short_id(id)); changed = true
	if not background:
		for id in traces:
			var trace: Dictionary = traces[id]
			if not trace.discovered and ow.position.distance_to(trace.position) < ow.sight():
				trace.discovered = true; c.note("A wrecked wagon and wheel tracks lie nearby."); changed = true
	return changed

func settle(c, scout_id: String, won: bool) -> String:
	if not enabled or not won or not missions.has(scout_id): return ""
	var id: String = missions[scout_id]
	var contested: bool = wagons[id].remaining > 0 or wagons[id].carried
	release(c,id,"")
	if contested:
		c.world.caravans[id].guarded = true
		var text = "%s rescued: %s resumes its journey. The cargo belongs to the town." % [c.world.short_id(id),c.world.cargo_text(id)]
		c.world.log_event(text); return text
	return "Raiding party defeated before it reached the caravan."

func rumour(c) -> String:
	if not enabled or not c.in_town() or c.over() or not c.encounter.is_empty(): return ""
	var ids = traces.keys(); ids.reverse()
	for id in ids:
		if traces[id].has("seizer") or traces[id].rumour or traces[id].inspected: continue
		traces[id].rumour = true
		c.note("Traders report %s missing. Its last reported area is marked; look for tracks." % c.world.short_id(id))
		return id
	return ""

func inspect_trace(c, id: String) -> bool:
	if not enabled or not traces.has(id) or c.phase != "camp" or c.over() or not c.encounter.is_empty(): return false
	var t: Dictionary = traces[id]
	if c.overworld.position.distance_to(t.position) > 20: return false
	t.discovered = true; t.inspected = true
	c.note("The wreck is empty. Search the nearby ground for fresh footprints; older prints may already be gone." if fading_tracks or t.has("seizer") else "The wreck is empty. Tracks lead toward %s. Follow them to find the raiders." % c.node(t.site).name)
	return true

func camp_known(id: String) -> bool:
	return not fading_tracks and traces.values().any(func(t):return t.inspected and not t.has("seizer") and t.site == id)

func background_day(c) -> void:
	# Legacy instant rest/travel actions charge one day. Freight must
	# advance that same day, without moving the company or opening hidden battles.
	if not enabled: return
	for i in 480:
		c.bandits.sync(c); c.guards.before_step(c,true); c.farm.before_step(c,true); move_wagons(c,true)
		c.overworld.step(c.world,c.in_town(),self,true,c); c.guards.after_step(c,true); c.farm.after_step(c,true)
		resolve_contacts(c,true); c.bandits.sync(c)
	sync(c)

func snapshot() -> Dictionary:
	var out = {"version":rules_version,"wagons":wagons.duplicate(true),"missions":missions.duplicate(),"traces":traces.duplicate(true),"alerts":alerts.duplicate(),"pursuit":pursuit}
	for v in out.wagons.values(): v.position = [v.position.x,v.position.y]; v.path = v.path.map(func(p):return [p.x,p.y])
	for t in out.traces.values(): t.position = [t.position.x,t.position.y]; t.points = t.points.map(func(p):return [p.x,p.y])
	return out

func restore(d: Variant, ow, w) -> bool:
	fading_tracks = ow.tracks.enabled
	if not d is Dictionary or d.get("version") not in [1,VERSION]: return false
	for key in ["wagons","missions","traces"]:
		if not d.get(key) is Dictionary: return false
	if d.wagons.size() != w.caravans.size() or d.traces.size() > d.wagons.size() or not d.get("alerts") is Array: return false
	if not d.get("pursuit") is String or (not d.pursuit.is_empty() and (not ow.scouts.has(d.pursuit) or ow.scouts[d.pursuit].defeated or not ow.pending.is_empty())): return false
	var taken = {}
	for sid in d.missions:
		var id = d.missions[sid]
		if not ow.scouts.has(sid) or ow.scouts[sid].defeated or not d.wagons.has(id) or taken.has(id): return false
		taken[id] = sid
	for id in w.caravans:
		var v = d.wagons.get(id); var cargo: Dictionary = w.caravans[id]
		if not v is Dictionary or not ow.valid_xy(v.get("position")) or not v.get("path") is Array: return false
		if v.path.size() > 1800: return false
		for p in v.path:
			if not ow.valid_xy(p): return false
		if not ow.valid_route(v.position,v.path) or v.get("leg") != cargo.index or v.get("status") != cargo.status: return false
		if not v.get("raider") is String or not v.get("remaining") is int or v.remaining < 0 or v.remaining > ATTACK_TICKS or not v.get("carried") is bool: return false
		if v.raider != taken.get(id,""): return false
		if v.raider.is_empty() and (v.remaining > 0 or v.carried): return false
		if not v.raider.is_empty():
			var s: Dictionary = ow.scouts[v.raider]
			if cargo.status != "transit" or cargo.guarded or ((not ow.raider_survival or cargo.has("material")) and (w.route_data(cargo.route).path[1] != s.site or w.protected_road(s.site))): return false
		if v.carried and (v.remaining != 0 or not d.traces.has(id) or not v.path.is_empty()): return false
		if v.remaining > 0 and not v.path.is_empty(): return false
	for id in d.traces:
		var t = d.traces[id]
		if not w.caravans.has(id) or not t is Dictionary or not ow.valid_xy(t.get("position")) or t.get("site") not in w.SITES: return false
		if not t.get("generation") is int or t.generation < 1 or t.generation > w.camps[t.site].generation or not t.get("day") is int or t.day < 1 or t.day > w.day: return false
		for key in ["rumour","discovered","inspected"]:
			if not t.get(key) is bool: return false
		if t.has("seizer"):
			if not t.seizer is String or not ow.scouts.has(t.seizer) or not w.caravans[id].has("material"):return false
			var captor: Dictionary=ow.scouts[t.seizer]
			if captor.site!=t.site or captor.generation!=t.generation:return false
		if t.inspected and not t.discovered: return false
		if not t.get("points") is Array or t.points.is_empty() or t.points.size() > 1800: return false
		for p in t.points:
			if not ow.valid_xy(p): return false
		if t.points[0] != t.position: return false
	var seen = {}
	for id in d.alerts:
		if not id is String or not w.caravans.has(id) or seen.has(id): return false
		seen[id] = true
	enabled = true; rules_version = d.version; ow.road_corner_rules = rules_version >= 2; wagons = d.wagons.duplicate(true); missions = d.missions.duplicate(); traces = d.traces.duplicate(true); alerts = d.alerts.duplicate(); pursuit = d.pursuit
	for v in wagons.values(): v.position = Vector2(v.position[0],v.position[1]); v.path = ow.unpack_path(v.path)
	for t in traces.values(): t.position = Vector2(t.position[0],t.position[1]); t.points = ow.unpack_path(t.points)
	w.spatial_trade = true
	return true
