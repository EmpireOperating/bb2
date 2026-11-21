extends RefCounted
## Deliberate ten-point fixtures: same personal pool and stats within each trio.
const T = preload("res://src/perk_trials.gd")
const DATA = preload("res://data/ranged_trials.json")
static func builds() -> Array: return DATA.data
static func install(c) -> void:
	c.setup(7391)
	for i in 3: apply_build(c,i,i*3)
	c.note("RANGED SANDBOX: Lysa, Oren and Tova have ten fixture points. Career XP and attribute growth use the supplied progression system.")
static func apply_build(c, soldier_id: int, build_id: int) -> void:
	var build: Dictionary = builds()[build_id]
	T.apply_fixture(c,soldier_id,build,build.background)
