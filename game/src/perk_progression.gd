extends RefCounted
## Progression is the sole owner of XP, levels and cumulative point awards.
const Progression = preload("res://src/progression.gd")
const Perks = preload("res://src/perks.gd")
static func earned(s: Dictionary) -> int: return Progression.earned_perk_points(s)
static func available(s: Dictionary) -> int: return Progression.points(s)
static func definition(id: String) -> Dictionary:
	return Perks.catalog().get(id,Progression.PERKS.get(id,{}))
static func validate(s: Dictionary, day: int) -> bool: return Progression.validate(s,day)
