extends SceneTree
const People = preload("res://src/people.gd")
const Previous = preload("res://src/legacy_people_v20.gd")
const Perks = preload("res://src/perks.gd")
const Arsenal = preload("res://src/arsenal.gd")
var checks := 0
var failures: Array = []
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok: failures.append(label); print("FAIL: ",label)
func _initialize() -> void:
 var counts := {1:0,2:0,3:0}
 var inclusion := {}
 var totals := {}
 var mismatches := 0
 var identity_drift := 0
 var gear_tree_drift := 0
 var oracle_drift := 0
 var tickets := {}
 for seed_number in range(1,161):
  var pop: Dictionary = People.new().population(seed_number)
  var prior: Dictionary = Previous.new().population(seed_number)
  for id in pop.pools:
   var p: Dictionary = pop.pools[id]
   if not inclusion.has(p.name):
    inclusion[p.name] = {}; totals[p.name] = 0
    for attr in People.ATTRS: inclusion[p.name][attr] = 0
   totals[p.name] += 1
   var stars: Array = p.aptitudes.values().filter(func(v):return v > 0)
   check(stars.size() == 3,"three distinct ordinary talents")
   for attr in People.ATTRS:
    if p.aptitudes[attr] > 0:
     inclusion[p.name][attr] += 1; counts[p.aptitudes[attr]] += 1
   if p.name == "Deserter" and p.aptitudes.resolve != 0: mismatches += 1
   for key in ["person","name","person_seed","age","hp","skill","defense","stamina","initiative","base_ranged_skill","base_ranged_defense","resolve"]:
    if p[key] != prior.pools[id][key]: identity_drift += 1
   # Use the retained old base rolls plus the unchanged CURRENT perk/equipment
   # providers: v20 itself predates the expanded perk catalogue/modest kits.
   var expected: Dictionary = prior.pools[id].duplicate(true)
   for key in ["perk_version","perk_groups","perk_pool","gifted_choices"]: expected.erase(key)
   Perks.initialize_background(expected)
   Arsenal.background_offer(expected,Perks.background_weights(expected,"weapons"))
   People.modest_gear(expected)
   for key in ["perk_version","perk_groups","perk_pool","gifted_choices","weapon","loadout","carried_loadout","ammo_loadout"]:
    if p[key] != expected[key]: gear_tree_drift += 1
   if p.name != "Deserter" and (p.aptitudes != prior.pools[id].aptitudes or p.growth_offers != prior.pools[id].growth_offers): oracle_drift += 1
   # Independent replay of the documented draw policy, including all 100
   # possible star tickets. Never use a favorable-reroll fixture or fake values.
   var rng: int = p.person_seed
   for draw in People.ATTRS.size()+4: rng = (rng*48271)%2147483647
   var candidates: Array = People.ATTRS.filter(func(a):return a != "resolve" or p.name != "Deserter")
   var aptitude := {}
   for attr in People.ATTRS: aptitude[attr] = 0
   for draw in 3:
    rng = (rng*48271)%2147483647
    var attr: String = candidates.pop_at(rng%candidates.size())
    rng = (rng*48271)%2147483647
    var ticket: int = 1+rng%100; tickets[ticket] = true
    aptitude[attr] = 1 if ticket <= 60 else 2 if ticket <= 90 else 3
   if p.aptitudes != aptitude: oracle_drift += 1
 check(mismatches == 0,"Deserter excludes Resolve talent; actual forbidden rolls=%d" % mismatches)
 check(identity_drift == 0,"town names, seeds and base stats retain the original roll stream")
 check(gear_tree_drift == 0,"ordinary current perk trees, weapon rolls and modest equipment unchanged")
 check(oracle_drift == 0 and tickets.size() == 100,"exact uniform-pop/60-90 thresholds match independent replay; all 100 star tickets witnessed")
 for bg in inclusion:
  var eligible := 7 if bg == "Deserter" else 8
  var expected: float = 3.0 / eligible
  for attr in People.ATTRS:
   if bg == "Deserter" and attr == "resolve": continue
   check(abs(float(inclusion[bg][attr])/totals[bg]-expected) < 0.09,"uniform eligible inclusion: %s/%s" % [bg,attr])
 var total: int = counts[1]+counts[2]+counts[3]
 check(abs(float(counts[1])/total-0.6) < 0.025 and abs(float(counts[2])/total-0.3) < 0.025 and abs(float(counts[3])/total-0.1) < 0.02,"ordinary stars retain 60/30/10 policy")
 print("ORDINARY_DISTRIBUTION ",JSON.stringify({"stars":counts,"background_people":totals,"inclusion":inclusion}))
 print(JSON.stringify({"test":"talents_ordinary","checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
