extends RefCounted
## Persistent site history and timed actions. Geography and loot definitions are
## immutable; searching marks the site spent before transferring any supplies.
var sites: Dictionary = {}
var task: Dictionary = {}

func setup(region: Dictionary) -> void:
	sites.clear(); task.clear()
	for p in region.locations:
		if p.kind == "discovery": sites[p.id] = {"scouted":false,"searched":false,"rumour":false}

func hear_rumour(c) -> String:
	if not c.in_town() or c.phase != "camp" or c.over() or not c.encounter.is_empty(): return ""
	var nearest = ""; var distance = INF
	for id in sites:
		if sites[id].rumour or sites[id].searched: continue
		var p: Vector2 = c.overworld.places[id]
		var d = c.overworld.position.distance_to(p)
		if d < distance: nearest = id; distance = d
	if not nearest.is_empty():
		sites[nearest].rumour = true
		c.note("A rumour points to %s. A search area has been marked; the country around it is still unknown." % c.node(nearest).name)
	return nearest

func reason(c, id: String, kind: String) -> String:
	if not sites.has(id) or kind not in ["scout","search"]: return "Choose a known discovery."
	if c.phase != "camp" or c.over() or not c.encounter.is_empty(): return "Resolve the current encounter first."
	if not c.overworld.at_site(id) or c.location != id: return "Reach the location first."
	if not task.is_empty(): return "An exploration action is already underway."
	if sites[id].searched: return "This site has already been searched."
	if kind == "scout" and sites[id].scouted: return "This site has already been scouted."
	var guard: String = c.node(id).guarded_by
	if kind == "search" and not guard.is_empty() and c.world.camps[guard].active: return "Clear %s before searching this cache." % c.node(guard).name
	return ""

func begin(c, id: String, kind: String) -> bool:
	if not reason(c,id,kind).is_empty(): return false
	task = {"site":id,"kind":kind,"remaining":20 if kind == "scout" else c.node(id).search_hours*20}
	c.overworld.path.clear(); c.overworld.destination = ""; c.overworld.rest_left = 0; c.overworld.paused = false
	return true

func tick(c) -> bool:
	if task.is_empty(): return false
	if c.over() or not c.encounter.is_empty() or not c.overworld.at_site(task.site):
		cancel(c); return true
	task.remaining -= 1
	if task.remaining > 0: return false
	var id: String = task.site; var kind: String = task.kind
	task.clear()
	if kind == "scout":
		sites[id].scouted = true
		var p: Dictionary = c.node(id)
		if p.feature == "watchtower": c.overworld.reveal_radius(c.overworld.position,260)
		if not p.guarded_by.is_empty():
			# Scout information identifies the controlling camp, without surveying its roads.
			c.note("Scouted %s. The cache is controlled by %s." % [p.name,c.node(p.guarded_by).name])
		else: c.note("Scouted %s. Stores may remain; searching will take %d hours." % [p.name,p.search_hours])
	else:
		var p: Dictionary = c.node(id)
		var guard: String = p.guarded_by
		if not guard.is_empty() and c.world.camps[guard].active:
			c.note("Raiders have returned. The search is abandoned before reaching the cache.")
		else:
			sites[id].searched = true; sites[id].scouted = true
			var loot: Dictionary = p.loot
			c.crowns += loot.crowns; c.food += loot.food; c.tools += loot.tools; c.ammunition += loot.ammunition
			c.note("Searched %s: %dc, %d rations, %d tools, %d ammunition. These stores are gone for good." % [p.name,loot.crowns,loot.food,loot.tools,loot.ammunition])
			c.recover_vault_key("cache",id.hash())
	c.overworld.paused = true
	return true

func cancel(c) -> void:
	if task.is_empty(): return
	c.note("Work at %s was interrupted. Nothing was taken." % c.node(task.site).name)
	task.clear()

func snapshot() -> Dictionary:
	return {"sites":sites.duplicate(true),"task":task.duplicate(true)}

func restore(d: Variant, region: Dictionary, spatial, saved_location: String, phase: String) -> bool:
	setup(region)
	if not d is Dictionary or not d.get("sites") is Dictionary or d.sites.size() != sites.size() or not d.get("task") is Dictionary: return false
	for id in sites:
		if not d.sites.get(id) is Dictionary or d.sites[id].size() != 3: return false
		for key in ["scouted","searched","rumour"]:
			if not d.sites[id].get(key) is bool: return false
		if d.sites[id].searched and not d.sites[id].scouted: return false
	if not d.task.is_empty():
		if d.task.size() != 3 or not sites.has(d.task.get("site")) or d.task.get("kind") not in ["scout","search"] or not d.task.get("remaining") is int: return false
		var p: Dictionary = region.locations.filter(func(n):return n.id == d.task.site)[0]
		var maximum: int = 20 if d.task.kind == "scout" else p.search_hours*20
		if d.task.remaining < 1 or d.task.remaining > maximum or d.sites[d.task.site].searched: return false
		if d.task.kind == "scout" and d.sites[d.task.site].scouted: return false
		if saved_location != d.task.site or not spatial.at_site(d.task.site) or not spatial.path.is_empty() or spatial.rest_left > 0 or not spatial.pending.is_empty() or phase != "camp": return false
	sites = d.sites.duplicate(true); task = d.task.duplicate(true)
	return true
