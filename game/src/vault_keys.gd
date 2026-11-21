extends RefCounted
## Company keyring and permanent doors. Keys contain names, never map discovery.
var opportunities = 0
var records: Dictionary = {}

static func targets(sites: Dictionary) -> Dictionary:
	var out = {}
	for site in sites.values():
		for floor in site.floors:
			for room in floor.rooms:
				if room.kind == "vault":
					var id = "%s/f%d/r%d" % [site.place.id,floor.index,room.id]
					out[id] = {"site":site.place.id,"floor":floor.index,"room":room.id}
	return out

func install(sites: Dictionary) -> void:
	opportunities = 0; records.clear()
	for id in targets(sites):
		var at: Dictionary = targets(sites)[id]
		var visited: bool = sites[at.site].floors[at.floor].rooms[at.room].visited
		records[id] = {"held":false,"opened":visited,"noticed":visited,"source":"legacy" if visited else ""}

static func label(sites: Dictionary, id: String) -> String:
	var at: Dictionary = targets(sites).get(id,{})
	return "Vault Key — %s" % sites[at.site].place.name if not at.is_empty() else ""

func locked(id: String) -> bool:
	return records.has(id) and not records[id].opened

# Presentation for a known lock whose matching key is not held. Never name or
# point to the other treasury: a key does not reveal an unvisited location.
func missing_key_reason(id: String) -> String:
	var site_prefix := id.get_slice("/",0)+"/"
	var carries_key := false
	for other: String in records:
		if not records[other].held: continue
		if other.begins_with(site_prefix): return "You carry a key for this dungeon, but it fits a different treasury."
		carries_key = true
	return "Your carried vault keys fit other dungeons." if carries_key else "You carry no vault keys."

func award(source: String, seed_number: int) -> String:
	if source not in ["battle","cache"]: return ""
	var available = records.keys().filter(func(id):return not records[id].held and not records[id].opened)
	if available.is_empty(): return ""
	# First external loot event, then every third. Finite keys never duplicate;
	# recurring world combat keeps all remaining keys obtainable.
	opportunities += 1
	if (opportunities-1)%3 != 0: return ""
	var id: String = available[posmod(seed_number,available.size())]
	records[id].held = true; records[id].source = source
	return id

func snapshot() -> Dictionary:
	return {"opportunities":opportunities,"records":records.duplicate(true)}

func restore(raw: Variant, sites: Dictionary) -> bool:
	if not raw is Dictionary or raw.size() != 2 or not raw.get("opportunities") is int or raw.opportunities < 0 or raw.opportunities > 1000000000 or not raw.get("records") is Dictionary: return false
	var expected = targets(sites); var held = 0
	if raw.records.size() != expected.size(): return false
	for id in expected:
		var row = raw.records.get(id); var at: Dictionary = expected[id]
		var site: Dictionary = sites[at.site]; var floor: Dictionary = site.floors[at.floor]; var room: Dictionary = floor.rooms[at.room]
		if not row is Dictionary or row.size() != 4: return false
		for key in ["held","opened","noticed"]:
			if not row.get(key) is bool: return false
		if row.get("source") not in ["","battle","cache","legacy"]: return false
		if row.held != (row.source in ["battle","cache"]): return false
		if row.held: held += 1
		if row.source == "legacy" and (not row.opened or not room.visited): return false
		if row.opened and (not row.noticed or (not row.held and row.source != "legacy")): return false
		if room.visited and not row.opened: return false
		if row.noticed and (not site.entered or not floor.rooms[0].visited or not room.seen): return false
	if held > ceili(raw.opportunities/3.0): return false
	opportunities = raw.opportunities; records = raw.records.duplicate(true)
	return true
