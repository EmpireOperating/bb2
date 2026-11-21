extends RefCounted
## Integration boundary: progression owns XP/levels/awards; perks only spend them.
const Progression = preload("res://src/legacy_progression_perk_v1.gd")
const Perks = preload("res://src/legacy_perks_v1.gd")

static func earned(s: Dictionary) -> int:
	return clampi(int(s.get("perk_points_earned",Progression.level(s)-1)),0,10)
static func available(s: Dictionary) -> int: return earned(s)-s.get("perks",[]).size()
static func definition(id: String) -> Dictionary:
	return Perks.catalog().get(id,Progression.PERKS.get(id,{}))
static func validate(s: Dictionary, day: int) -> bool:
	if not Perks.modern(s): return Progression.validate(s,day)
	if s.has("perk_points_earned") and (not s.perk_points_earned is int or s.perk_points_earned < 0 or s.perk_points_earned > 10): return false
	if not Perks.valid(s) or not s.get("perks") is Array or available(s) < 0: return false
	var seen = []
	for id in s.perks:
		if id in seen: return false
		seen.append(id)
	var records = s.duplicate(true)
	records.perks = []
	return Progression.validate(records,day)
