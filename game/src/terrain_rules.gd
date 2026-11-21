extends RefCounted
## Pure, research-bound ordinary terrain costs. See terrain_pass/RULES.md.
const COSTS = {
	"grass":[2,4], "hill":[2,4], "road":[2,2], "stone":[2,2], "ford":[2,2],
	"forest":[3,6], "mud":[3,6], "rough":[3,6], "rubble":[4,8], "rocks":[4,8],
	"swamp":[4,14], "sand":[2,6], "shallow_water":[4,12]
}

static func tile_reason(tile: Dictionary) -> String:
	if tile.is_empty(): return "Outside the battlefield."
	if tile.get("blocked",false) or tile.get("terrain","") in ["water","deep_water","wall"]:
		return "Impassable terrain or obstacle."
	if not COSTS.has(tile.get("terrain","")): return "Unknown terrain: movement refused."
	return ""

static func edge(origin: Dictionary, destination: Dictionary, gap: int, pathfinder: bool = false) -> Dictionary:
	var reason = tile_reason(destination)
	if reason.is_empty(): reason = tile_reason(origin)
	if reason.is_empty() and gap != 1: reason = "Choose an adjacent battlefield hex."
	var delta = absi(int(destination.get("height",0))-int(origin.get("height",0)))
	if reason.is_empty() and delta > 1: reason = "Cannot traverse more than one height level."
	if not reason.is_empty(): return {"ap":999,"fatigue":999,"reason":reason}
	var cost: Array = COSTS[destination.terrain]
	var ap: int = maxi(2,cost[0]-1) if pathfinder else cost[0]
	var fatigue: int = cost[1]/2 if pathfinder else cost[1]
	if delta != 0:
		ap += 0 if pathfinder else 1
		fatigue += 4
	return {"ap":ap,"fatigue":fatigue,"reason":""}

static func height_modifier(attacker: Dictionary, target: Dictionary) -> int:
	var delta = int(attacker.get("height",0))-int(target.get("height",0))
	return 10 if delta > 0 else delta*10

static func attack_reason(origin: Dictionary, target: Dictionary, gap: int, minimum: int, maximum: int, ranged: bool) -> String:
	if origin.is_empty() or target.is_empty(): return "Outside the battlefield."
	var delta = int(origin.height)-int(target.height)
	if absi(delta) > (4 if ranged else 1): return "Target exceeds the action's height limit."
	if ranged: maximum += mini(9,maxi(0,delta))
	if gap < minimum: return "Too close: this action needs at least %d hexes." % minimum
	if gap > maximum: return "Out of reach: %d hexes away; this action reaches %d." % [gap,maximum]
	return ""
