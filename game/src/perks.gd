extends RefCounted
## Saved personal pools and shared arithmetic. No combat/population RNG consumption.
const Arsenal = preload("res://src/arsenal.gd")
const DATA = preload("res://data/perks.json")
const BACKGROUND_BIASES = preload("res://data/recruit_backgrounds.json")
const CATEGORIES = {"weapons":["Spear","Sword","Polearm","Bow","Crossbow","Throwing","Axe","Mace","Hammer","Dagger"],"armour":["Light","Medium","Heavy"],"styles":["Shield","Swift","Power","Marksman"],"character":["Tough","Fast","Trained","Vigorous"]}
const MELEE = ["Spear","Sword","Polearm","Axe","Mace","Hammer","Dagger"]
const RANGED = ["Bow","Crossbow","Throwing"]
const CORE = ["colossus","pathfinder","fast_adaptation","fortified_mind","steel_brow","quick_hands"]
const RALLY := "rally_the_troops"
const GROUPS = {
	"Hammer":["smackdown","hammer_mastery","deep_impact"],
	"Dagger":["between_the_ribs","dagger_mastery","swift_stabs"],
	"Axe":["smashing_shields","axe_mastery","killing_frenzy"],
	"Mace":["concussive_strikes","mace_mastery","push_the_advantage"],
	"Bow":["target_practice","bow_mastery","patient_hunter","hip_shooter"],
	"Crossbow":["power_shot","crossbow_mastery","iron_sights"],
	"Throwing":["hybridization","throwing_mastery","opportunist"],
	"Marksman":["anticipation","overwhelm","footwork","head_hunter","bullseye","killing_frenzy"],
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
static func modern(s: Dictionary) -> bool: return s.get("perk_version",0) in [1,2,3,4,5,6]
static func pool(groups: Array, bags: bool = false) -> Array:
	var out = CORE.duplicate()
	if bags: out.append("bags_and_belts")
	for group in groups:
		for id in GROUPS[group]:
			if not id in out: out.append(id)
	out.sort_custom(func(a,b): return catalog()[a].tier < catalog()[b].tier if catalog()[a].tier != catalog()[b].tier else a < b)
	return out

static func background_weights(s: Dictionary, category: String) -> Dictionary:
	var bg: String = s.get("background",s.get("name",""))
	var favored: Array = BACKGROUND_BIASES.data.get(bg,{}).get(category,[])
	var result = {}
	for group in CATEGORIES[category]: result[group] = 2 if group in favored else 1
	return result

static func draw_groups(rng: RandomNumberGenerator, weights: Dictionary, count: int) -> Array:
	var remaining = weights.duplicate(); var result = []
	for i in count:
		var total = 0
		for value in remaining.values(): total += int(value)
		var choice = rng.randi_range(1,total)
		for group in remaining:
			choice -= int(remaining[group])
			if choice <= 0:
				result.append(group); remaining.erase(group); break
	return result

static func initialize_background(s: Dictionary) -> void:
	if modern(s): return
	var rng = RandomNumberGenerator.new(); rng.seed = int(s.get("person_seed",0))+200731993
	var groups = []
	for category in CATEGORIES:
		var choices = draw_groups(rng,background_weights(s,category),4 if category == "weapons" else 2)
		# Condition the four-group draw on both routes being present. No individual
		# group, background, weapon, stat or talent is required.
		if category == "weapons":
			while not choices.any(func(g): return g in MELEE) or not choices.any(func(g): return g in RANGED):
				choices = draw_groups(rng,background_weights(s,category),4)
		groups.append_array(choices)
	s["perk_version"] = 6; s["perk_groups"] = groups; s["perk_pool"] = pool(groups,true); s["gifted_choices"] = []

static func initialize(s: Dictionary, groups: Array = [], starting_weapon: String = "") -> void:
	if modern(s): return
	var rng = RandomNumberGenerator.new()
	rng.seed = int(s.get("person_seed",0))+731993
	if groups.is_empty():
		groups = ["Spear","Sword","Polearm"]
		var ranged = s.get("weapon",starting_weapon) in Arsenal.RANGED
		if ranged: groups = ["Bow","Crossbow","Throwing",["Spear","Sword","Polearm"][rng.randi_range(0,2)]]
		for category in [["Light","Medium","Heavy"],["Shield","Swift","Power"],["Tough","Fast","Trained","Vigorous"]]:
			var choices = category.duplicate()
			if ranged and category[0] == "Shield":
				groups.append("Marksman"); groups.append(choices[rng.randi_range(0,2)])
			else:
				for i in 2: groups.append(choices.pop_at(rng.randi_range(0,choices.size()-1)))
	s["perk_version"] = 2; s["perk_groups"] = groups.duplicate(); s["perk_pool"] = pool(groups)
	s["gifted_choices"] = []

static func _rally_offered(s: Dictionary) -> bool:
	# A common Tier 3 option for current careers, not a reroll or an edit to
	# the authoritative personal pool saved for any existing version.
	return s.get("perk_version",0) == 6 and s.get("growth_version",0) == 1

static func offered_perks(s: Dictionary) -> Array:
	var out: Array = s.get("perk_pool",[]).duplicate()
	if _rally_offered(s):
		var i := 0
		while i < out.size() and (catalog()[out[i]].tier < 3 or (catalog()[out[i]].tier == 3 and out[i] < RALLY)): i += 1
		out.insert(i,RALLY)
	return out

static func learn_reason(s: Dictionary, id: String, earned_points: int) -> String:
	if not id in s.perk_pool and not (id == RALLY and _rally_offered(s)): return "Outside this recruit's personal pool."
	if id in s.perks: return "Already learned."
	if s.perks.size() >= earned_points: return "Earn another level for a perk point."
	if s.perks.size() < catalog()[id].tier-1: return "Spend %d points anywhere to unlock this tier." % (catalog()[id].tier-1)
	if has(s,"gifted") and s.gifted_choices.size() < 3: return "Finish the three Gifted choices first."
	return ""

static func valid(s: Dictionary) -> bool:
	if not modern(s): return not s.has("perk_version")
	if s.has("perks") and not s.perks is Array: return false
	if not s.get("perk_groups") is Array or not s.perk_groups.size() in [9,10]: return false
	var seen = []
	for g in s.perk_groups:
		if not g is String or not GROUPS.has(g) or g in seen: return false
		seen.append(g)
	if s.perk_version <= 3 and seen.any(func(g): return g in ["Axe","Mace"]): return false
	if s.perk_version <= 4 and seen.any(func(g): return g in ["Hammer","Dagger"]): return false
	if s.perk_version in [3,4,5,6]:
		if seen.size() != 10: return false
		if not seen.any(func(g): return g in MELEE) or not seen.any(func(g): return g in RANGED): return false
		for category in CATEGORIES:
			if seen.filter(func(g): return g in CATEGORIES[category]).size() != (4 if category == "weapons" else 2): return false
	else:
		var ranged = "Marksman" in seen
		if ranged:
			if s.perk_version != 2 or s.perk_groups.size() != 10: return false
			if seen.filter(func(g): return g in ["Bow","Crossbow","Throwing"]).size() != 3: return false
			if seen.filter(func(g): return g in ["Spear","Sword","Polearm"]).size() != 1: return false
		else:
			if seen.filter(func(g): return g in ["Spear","Sword","Polearm"]).size() != 3 or s.perk_groups.size() != 9: return false
		for cat in [["Light","Medium","Heavy"],["Shield","Swift","Power","Marksman"],["Tough","Fast","Trained","Vigorous"]]:
			if seen.filter(func(g): return g in cat).size() != 2: return false
	if s.get("perk_pool") != pool(s.perk_groups,s.perk_version >= 6): return false
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
		if (not id in s.perk_pool and not (id == RALLY and _rally_offered(s))) or catalog()[id].tier > bought+1: return false
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
	return {"adaptation":0,"feint":-1,"opening":-1,"opening_end":0,"double":false,"reach":0,"frenzy_end":0,"activation":0,"quick_used":false,"vigor_used":false,"origin_q":-1,"origin_r":-1,"nine_used":false,"indomitable":false,"overwhelm":0,"bow_shots":0,"throws_used":0,"head_ready":false}
static func valid_state(s: Variant, count: int = 12, width: int = 13, height: int = 9) -> bool:
	if not s is Dictionary or s.size() != state().size(): return false
	for k in state():
		if typeof(s.get(k)) != typeof(state()[k]): return false
	for k in ["feint","opening"]:
		if s[k] < -1 or s[k] >= count: return false
	return s.adaptation in [0,8,16,24] and s.reach in [0,5,10] and s.overwhelm in [0,1,2] and s.activation >= 0 and s.activation <= 31 and s.frenzy_end >= 0 and s.frenzy_end <= 32 and s.opening_end >= 0 and s.opening_end <= 32 and s.origin_q >= -1 and s.origin_q < width and s.origin_r >= -1 and s.origin_r < height and s.bow_shots >= 0 and s.bow_shots <= 3 and s.throws_used >= 0 and s.throws_used <= 2
