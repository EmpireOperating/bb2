extends RefCounted
## Saved personal pools and shared arithmetic. No combat/population RNG consumption.
const Arsenal = preload("res://src/legacy_arsenal_v18.gd")
const DATA = preload("res://data/legacy_perks_v18.json")
const CORE = ["colossus","pathfinder","fast_adaptation","fortified_mind","steel_brow","quick_hands"]
const GROUPS = {
	"Spear":["through_the_gaps","spear_mastery","spearwaller","king_of_all_weapons"],
	"Sword":["feint","sword_mastery","en_garde"],
	"Polearm":["leverage","polearm_mastery","long_reach"],
	"Light":["dodge","relentless","nimble"],
	"Medium":["balance","perfect_fit","poise"],
	"Heavy":["brawny","bulwark","battle_forged"],
	"Shield":["exploit_opening","shield_expert","rotation","phalanx"],
	"Swift":["backstabber","double_strike","duelist","footwork"],
	"Power":["vigorous_assault","reach_advantage","underdog","killing_frenzy"],
	"Tough":["colossus","steel_brow","nine_lives","indomitable"],
	"Fast":["pathfinder","quick_hands","anticipation","overwhelm"],
	"Trained":["fast_adaptation","rotation","underdog","gifted","finesse"],
	"Vigorous":["fortified_mind","brawny","mind_over_body","deep_breath"]}
const ATTRS = ["health","stamina","resolve","initiative","skill","ranged_skill","defense","ranged_defense"]
const GIFT = {"health":4,"stamina":4,"resolve":4,"initiative":5,"skill":3,"ranged_skill":4,"defense":3,"ranged_defense":4}

static func catalog() -> Dictionary: return DATA.data
static func has(u: Dictionary, id: String) -> bool: return id in u.get("perks",[])
static func modern(s: Dictionary) -> bool: return s.get("perk_version",0) == 1
static func pool(groups: Array) -> Array:
	var out = CORE.duplicate()
	for group in groups:
		for id in GROUPS[group]:
			if not id in out: out.append(id)
	out.sort_custom(func(a,b): return catalog()[a].tier < catalog()[b].tier if catalog()[a].tier != catalog()[b].tier else a < b)
	return out

static func initialize(s: Dictionary, groups: Array = []) -> void:
	if modern(s): return
	var rng = RandomNumberGenerator.new()
	rng.seed = int(s.get("person_seed",0))+731993
	if groups.is_empty():
		groups = ["Spear","Sword","Polearm"]
		for category in [["Light","Medium","Heavy"],["Shield","Swift","Power"],["Tough","Fast","Trained","Vigorous"]]:
			var choices = category.duplicate()
			for i in 2: groups.append(choices.pop_at(rng.randi_range(0,choices.size()-1)))
	s["perk_version"] = 1; s["perk_groups"] = groups.duplicate(); s["perk_pool"] = pool(groups)
	s["gifted_choices"] = []

static func learn_reason(s: Dictionary, id: String, earned_points: int) -> String:
	if not id in s.perk_pool: return "Outside this recruit's personal pool."
	if id in s.perks: return "Already learned."
	if s.perks.size() >= earned_points: return "Earn another level for a perk point."
	if s.perks.size() < catalog()[id].tier-1: return "Spend %d points anywhere to unlock this tier." % (catalog()[id].tier-1)
	if has(s,"gifted") and s.gifted_choices.size() < 3: return "Finish the three Gifted choices first."
	return ""

static func valid(s: Dictionary) -> bool:
	if not modern(s): return not s.has("perk_version")
	if s.has("perks") and not s.perks is Array: return false
	if not s.get("perk_groups") is Array or s.perk_groups.size() != 9: return false
	var seen = []
	for g in s.perk_groups:
		if not g is String or not GROUPS.has(g) or g in seen: return false
		seen.append(g)
	for cat in [["Spear","Sword","Polearm"],["Light","Medium","Heavy"],["Shield","Swift","Power"],["Tough","Fast","Trained","Vigorous"]]:
		if seen.filter(func(g): return g in cat).size() != (3 if cat[0] == "Spear" else 2): return false
	if s.get("perk_pool") != pool(s.perk_groups): return false
	for field in ["gifted_choices"]:
		if not s.get(field) is Array: return false
	if s.gifted_choices.size() > 3 or (not has(s,"gifted") and not s.gifted_choices.is_empty()): return false
	seen = []
	for attr in s.gifted_choices:
		if not attr in ATTRS or attr in seen: return false
		seen.append(attr)
	if has(s,"gifted") and s.gifted_choices.size() < 3 and s.perks.back() != "gifted": return false
	var bought = 0
	for id in s.get("perks",[]):
		if not id in s.perk_pool or catalog()[id].tier > bought+1: return false
		bought += 1
	return true

static func medium(u: Dictionary) -> float:
	var w = float(u.get("load",0))
	return maxf(0,1.0-maxf(maxf(25-w,0),w-35)/10.0)
static func armor_load(u: Dictionary, initiative: bool = false) -> int:
	return ceili(float(u.get("load",0))*(0.7 if has(u,"brawny") else 1.0)*(1.0-0.2*medium(u) if initiative and has(u,"perfect_fit") else 1.0))
static func fatigue_cost(u: Dictionary, base: int, weapon: bool = true, reaction: bool = false, extra: float = 1.0) -> int:
	var factor = extra
	if weapon:
		if has(u,Arsenal.family(u.weapon)+"_mastery"): factor *= 0.75
		if not reaction and has(u,"perfect_fit"): factor *= 1.0-0.1*medium(u)
	if has(u,"finesse"): factor *= 0.85
	if has(u,"mind_over_body"): factor *= 1.0-minf(0.2,maxf(0,(float(u.resolve)-50)*0.005))
	return maxi(1,ceili(base*maxf(0.5,factor)-0.000001)) if base > 0 else 0
static func hp_factor(u: Dictionary) -> float:
	var value = 1.0
	if has(u,"nimble"): value = minf(value,0.4+0.03*maxf(0,float(u.load)-15))
	if has(u,"poise"): value = minf(value,1.0-0.3*medium(u))
	if u.get("perk_state",{}).get("indomitable",false): value = minf(value,0.5)
	return value
static func armor_factor(u: Dictionary) -> float:
	var value = 1.0
	if has(u,"poise"): value = minf(value,1.0-0.15*medium(u))
	if has(u,"battle_forged"): value = minf(value,1.0-minf(0.35,0.0005*(u.helmet+u.armor+u.padding)))
	if u.get("perk_state",{}).get("indomitable",false): value = minf(value,0.5)
	return value
static func state() -> Dictionary:
	return {"adaptation":0,"feint":-1,"opening":-1,"opening_end":0,"double":false,"reach":0,"frenzy_end":0,"activation":0,"quick_used":false,"vigor_used":false,"origin_q":-1,"origin_r":-1,"nine_used":false,"indomitable":false,"overwhelm":0}
static func valid_state(s: Variant) -> bool:
	if not s is Dictionary or s.size() != state().size(): return false
	for k in state():
		if typeof(s.get(k)) != typeof(state()[k]): return false
	for k in ["feint","opening"]:
		if s[k] < -1 or s[k] > 11: return false
	return s.adaptation in [0,8,16,24] and s.reach in [0,5,10] and s.overwhelm in [0,1,2] and s.activation >= 0 and s.activation <= 31 and s.frenzy_end >= 0 and s.frenzy_end <= 32 and s.opening_end >= 0 and s.opening_end <= 32 and s.origin_q >= -1 and s.origin_q < 13 and s.origin_r >= -1 and s.origin_r < 9
