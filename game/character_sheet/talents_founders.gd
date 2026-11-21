extends SceneTree
const People = preload("res://src/people.gd")
const Perks = preload("res://src/perks.gd")
const Arsenal = preload("res://src/arsenal.gd")
const ROLES = ["two_handed","shield","ranged"]
# The raw People templates above acquisition stay fixed. The owned starter rolls below do not.
const START_HELD = [["pike","hm_trial_v1:old24-polearm_weapon","hm_trial_v1:old24-polearm_heavy"],["short_sword","cudgel","hm_trial_v1:old24-duelist_weapon"],["short_bow","hm_trial_v1:old24-archer_weapon","crossbow"]]
const START_ARMOR = ["hm_trial_v1:old24-scout_coat","travel_leather","hm_trial_v1:headwear-02-leather-cap","hm_trial_v1:headwear-03-iron-skullcap","hollow_campaign:padded_hood"]
const NAMES = ["Companion (2H)","Companion (Shield)","Companion (Ranged)"]
const TALENTS = [{"skill":2,"defense":1,"resolve":1},{"health":2,"stamina":1,"resolve":1},{"ranged_skill":2,"ranged_defense":1,"initiative":1}]
const RANGES = [
 [[60,65],[95,105],[40,45],[95,110],[57,62],[32,42],[2,5],[2,5]],
 [[50,60],[95,105],[40,45],[100,110],[57,62],[37,47],[5,10],[5,10]],
 [[50,60],[90,100],[35,45],[105,115],[52,57],[48,52],[0,5],[0,5]]]
var checks := 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok and not failures.has(label): failures.append(label); print("FAIL: ",label)
func _initialize() -> void:
 var signatures := {}
 var examples: Array = []
 for seed_number in range(1,101):
  var pop: Dictionary = People.new().population(seed_number)
  check(pop == People.new().population(seed_number),"complete population deterministic")
  check(pop.founders.size() == 3,"exactly three founders, not six randomized keepers")
  for index in 3:
   var p: Dictionary = pop.founders[index]
   check(p.name == NAMES[index] and p.get("companion_role") == ROLES[index],"visible real Companion identity/role %d" % index)
   var expected := {}
   for attr in People.ATTRS: expected[attr] = TALENTS[index].get(attr,0)
   check(p.aptitudes == expected,"exact vanilla Companion talent profile %d" % index)
   var bases_ok := true
   for i in People.ATTRS.size():
    var value: int = p[People.OFFER_FIELDS[People.ATTRS[i]]]
    bases_ok = bases_ok and value >= RANGES[index][i][0] and value <= RANGES[index][i][1]
   check(bases_ok,"researched inclusive base ranges %d" % index)
   check(People.validate(p) and p.growth_offers == People.roll_growth(p),"growth initialized after final founder talents/stats")
   check(p.aptitudes.values().filter(func(v):return v > 0).size() == 3,"three distinct founder talents")
   check(Perks.valid(p),"valid existing perk rules, no new free learned perks")
   var group: String = {"two_handed":"Spear","shield":"Sword","ranged":"Bow"}[ROLES[index]]
   check(group in p.perk_groups,"authored founder weapon route matches modest held family")
   check(p.loadout.body in ["","jerkin"] and p.loadout.head in ["","simple_helm"] and p.wage in [3,4,5,6],"modest armor and existing bounded wage")
   check(p.loadout.weapon == p.weapon and p.ammo_loadout == Arsenal.ammo_type(p.weapon),"honest weapon and matching ammo")
   if index == 0: check(p.weapon == "pike" and p.weapon in Arsenal.TWO_HANDS and p.loadout.shield == "","2H founder holds modest current pike, not free elite sword")
   elif index == 1: check(p.weapon == "shortsword" and p.loadout.shield == "buckler","shield founder keeps affordable real one-hand/shield")
   else: check(p.weapon == "shortbow" and p.loadout.shield == "" and p.carried_loadout == ["knife",""] and p.ammo_loadout == "arrows","ranged founder has real bow, reserve knife and arrows")
   signatures[str(index)+JSON.stringify(p.aptitudes)+JSON.stringify([p.hp,p.skill,p.stamina,p.resolve,p.base_ranged_skill])] = true
  if seed_number in [1,7,73]: examples.append({"seed":seed_number,"founders":pop.founders})
 check(signatures.size() > 250,"founder bases vary, not fabricated fixed strong outcomes")
 # Exercise the actual packaged session factory and retained acquisition/rarity seams.
 for seed_number in [1,7,7391]:
  var app = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
  var session = app._create_session(); session.setup(seed_number)
  var c = session.campaign
  check(c.soldiers.size() == 3 and c.crowns == 300 and c.food == 24 and c.tools == 20 and c.medicine == 6 and c.ammunition == 60,"current three-founder economy unchanged")
  for index in 3:
   var p: Dictionary = c.soldiers[index]
   check(p.background == NAMES[index] and p.title == NAMES[index].to_upper() and p.get("companion_role") == ROLES[index],"player-visible founder background survives real add_person")
   var exact_bases := {}
   for attr in People.ATTRS: exact_bases[attr] = p[People.FIELDS[attr]]
   check(p.companion_roll.bases == exact_bases,"existing rarity reconstruction uses final Companion bases")
   var gear: Dictionary = p.gear
   var definition: String = c.items[gear.weapon].definition
   check(definition in START_HELD[index] and Arsenal.family(definition).capitalize() in p.perk_groups,"eligible actual held definition with matching training")
   check((gear.shield == "") == (index != 1),"legal current one/two-hand shield truth")
   if index == 2:
    check(c.items.get(gear.carry1,{}).get("definition") == "hm_trial_v1:old24-medic_weapon" and c.items.get(gear.ammo,{}).get("definition") == Arsenal.ammo_type(definition) and c.items.get(gear.ammo,{}).get("condition",0) > 0,"physical ranged carry/ammo present and usable")
   var armor: Array = c.battle_parts(p)
   if seed_number == 1: print("CURRENT_STARTER_GEAR ",JSON.stringify({"index":index,"items":c.items,"gear":gear,"armor":armor}))
   for part:Dictionary in armor:
    var uid:String=part.item
    if part.layer in c.SUPPORT_SLOTS:
     check(c.items.has(uid) and c.slot_uid(p,part.layer)==uid and c.items[uid].definition==part.definition and c.slot_allowed(part.definition,part.layer),"support part originates in its actual owned slot")
    else:check(part.definition in START_ARMOR,"no free mail or elite protective outfit")
  check(c.recruits().any(func(p):return p.price <= c.crowns),"at least one lawful hire remains affordable")
  var before: String = session._canonical(c.snapshot())
  for index in 3: session.preview_unit(index)
  check(session._canonical(c.snapshot()) == before,"inspection is read-only, no reroll or perk reset")
  app.free()
 FileAccess.open("user://talents-founders-examples.json",FileAccess.WRITE).store_string(JSON.stringify(examples))
 print(JSON.stringify({"test":"talents_founders","checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
