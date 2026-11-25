extends "res://src/farmstead.gd"
## Aggregates independent farmsteads; the inherited first farm preserves old saves/API.
const TOWN = "ashwick"
const Farmstead = preload("res://src/farmstead.gd")
var others: Dictionary = {}
var fading_tracks = false

static func layouts(ow, w) -> Dictionary:
	if w.TOWNS.size() > 3:
		# Overworld places preserve the generated locations array, unlike JSON object keys.
		# Its town order is the original placement priority; do not sort these farms.
		var town_order: Array = ow.places.keys().filter(func(id):return id in w.TOWNS)
		if town_order.size() != w.TOWNS.size(): return {}
		var expanded = {}; var used: Array = []
		for id in town_order:
			var place = Farmstead.layout(ow,w,id,w.config.towns[id].farm_camp,used)
			if place.is_empty(): return {}
			expanded[id] = place; used.append(place.position)
		return expanded
	var first = Farmstead.layout(ow,w)
	if first.is_empty(): return {}
	var out = {"ashwick":first}; var used = [first.position]
	# The three trade roads form a triangle. Match one adjacent camp to each town.
	var assigned = {"ashwick":first.camp,"stonecross":"forest" if first.camp == "ford" else "ford","dunmere":"ridge" if first.camp == "ford" else "forest"}
	for id in ["stonecross","dunmere"]:
		var place = Farmstead.layout(ow,w,id,assigned[id],used)
		if place.is_empty(): return {}
		out[id] = place; used.append(place.position)
	return out

func all() -> Array:
	return [self]+others.values() if enabled else []

func for_town(id: String):
	return self if enabled and id == town else others.get(id)

func setup(c, active: bool, all_towns: bool = false) -> void:
	fading_tracks = c.overworld.tracks.enabled
	regional = active and all_towns; others.clear()
	var places = layouts(c.overworld,c.world) if regional else {}
	if regional: geometry = places[town]
	super.setup(c,active)
	if not regional: return
	c.world.farm_supply["sites"] = {}
	for id in places.keys().filter(func(key):return key != town):
		var f = Farmstead.new(); f.town = id; f.regional = true; f.geometry = places[id]
		f.setup(c,true); others[id] = f

func balanced() -> bool:
	return super.balanced() and others.values().all(func(f):return f.balanced())

func engaged(id: String) -> bool:
	return all().any(func(f):return f.owns_raid(id))

func raid_for(id: String) -> Dictionary:
	for f in all():
		if f.owns_raid(id): return f.raid
	return {}

func sync(c) -> void:
	super.sync(c)
	for f in others.values(): f.sync(c)

func daily(c) -> void:
	super.daily(c)
	for f in others.values(): f.daily(c)

func before_step(c, background: bool = false) -> void:
	super.before_step(c,background)
	for f in others.values(): f.before_step(c,background)

func after_step(c, background: bool = false) -> void:
	super.after_step(c,background)
	for f in others.values(): f.after_step(c,background)

func order_for(c, id: String) -> Dictionary:
	if owns_raid(id): return super.order_for(c,id)
	for f in others.values():
		if f.owns_raid(id): return f.order_for(c,id)
	return {}

func abandon(c, id: String, reason: String) -> void:
	if owns_raid(id): super.abandon(c,id,reason)
	for f in others.values(): f.abandon(c,id,reason)

func settle(c, id: String, won: bool) -> String:
	if owns_raid(id): return super.settle(c,id,won)
	for f in others.values():
		if f.owns_raid(id): return f.settle(c,id,won)
	return ""

func camp_known(id: String) -> bool:
	return not fading_tracks and regional and all().any(func(f):return f.camp == id and f.identified)

func snapshot() -> Dictionary:
	if not regional: return super.snapshot()
	var farms = {town:super.snapshot()}
	for id in others: farms[id] = others[id].snapshot()
	return {"version":2,"farms":farms}

func restore(d: Variant, ow, world) -> bool:
	fading_tracks = ow.tracks.enabled
	if not d is Dictionary: return false
	regional = d.get("version") == 2; others.clear()
	if not regional:
		if world.farm_supply.has("sites"): return false
		return super.restore(d,ow,world)
	if not d.get("farms") is Dictionary or d.farms.size() != world.TOWNS.size() or not world.farm_supply.has("sites"): return false
	var places = layouts(ow,world)
	if places.size() != world.TOWNS.size(): return false
	geometry = places[town]
	if not super.restore(d.farms.get(town),ow,world): return false
	for id in places.keys().filter(func(key):return key != town):
		var f = Farmstead.new(); f.town = id; f.regional = true; f.geometry = places[id]
		if not f.restore(d.farms.get(id),ow,world): return false
		others[id] = f
	var taken = {}
	for f in all():
		if not f.raid.is_empty():
			if taken.has(f.raid.party): return false
			taken[f.raid.party] = true
	return true
