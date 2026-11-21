extends SceneTree
const Session = preload("res://next_build/session.gd")
const People = preload("res://src/people.gd")
const Arsenal = preload("res://src/arsenal.gd")
var checks := 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok: failures.append(label); print("FAIL: ",label)
func _initialize() -> void:
 var rows: Array = []
 # ExpandedRegion.validate admits 1..999999999, not the larger People modulus.
 for seed_number in [1,7,23,73,197,395,7391,10001,104729,999983,15485863,999999999]:
  var s = Session.new(); s.setup(seed_number)
  var c = s.campaign
  var twin = Session.new(); twin.setup(seed_number)
  var before: String = s._canonical(c.snapshot())
  check(before == twin._canonical(twin.campaign.snapshot()),"actual current full campaign determinism seed %d" % seed_number)
  check(s._validated_snapshot(c.snapshot()) != null,"actual current full validator seed %d" % seed_number)
  check(c.soldiers.size() == 3 and c.wage_cost() <= 18 and c.crowns == 300 and c.food == 24,"three modest affordable founders seed %d" % seed_number)
  check(c.recruits().any(func(p):return p.price <= c.crowns),"ordinary hire affordable without grants seed %d" % seed_number)
  for i in 3:
   var p: Dictionary = c.soldiers[i]
   var preview: Dictionary = s.preview_unit(i)
   check(People.validate(p) and People.fatigue_max(preview) >= 50 and c.max_hp(p) >= 50,"useful real capacity/health seed %d role %d" % [seed_number,i])
   check(Arsenal.family(preview.weapon).capitalize() in p.perk_groups,"real held family is in the saved personal pool")
  check(s._canonical(c.snapshot()) == before,"cohort validation and inspection have no live mutation")
  rows.append({"seed":seed_number,"crowns":c.crowns,"food":c.food,"wages":c.wage_cost(),"recruits":c.recruits().map(func(p):return {"id":p.id,"price":p.price}),"founders":c.soldiers.map(func(p):return {"name":p.name,"background":p.background,"role":p.companion_role,"talents":p.aptitudes,"groups":p.perk_groups,"gear":p.gear})})
 var unsupported = Session.new(); unsupported.setup(2147483646)
 check(not unsupported.campaign.ExpandedRegion.new().validate(unsupported.campaign.region) and unsupported._validated_snapshot(unsupported.campaign.snapshot()) == null,"retained world policy explicitly rejects out-of-range map seed; no seed coercion")
 FileAccess.open("user://talents-cohort.json",FileAccess.WRITE).store_string(JSON.stringify(rows))
 print(JSON.stringify({"test":"talents_cohort","checks":checks,"failures":failures,"scope":"12 actual current campaigns, no gear/money/seed rerolls; capacity and persistence viability, not human combat balance"}))
 quit(0 if failures.is_empty() else 1)
