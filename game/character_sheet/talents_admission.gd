extends SceneTree
const People = preload("res://src/people.gd")
const Career = preload("res://src/career.gd")
var checks := 0
var failures: Array = []
var signals_seen := 0
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok: failures.append(label); print("FAIL: ",label)
func _initialize() -> void:
 var app = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 var session = app._create_session(); session.setup(7391)
 var c = session.campaign
 var raw: Dictionary = c.snapshot()
 var before: String = session._canonical(raw)
 var identity: int = c.get_instance_id()
 session.changed.connect(func():signals_seen += 1)
 var bad_path := "user://talents-refusal.json"
 for value in [null,false,true,[],{},"1",0,2,1.5,"missing"]:
  var bad: Dictionary = raw.duplicate(true)
  if value is String and value == "missing": bad.erase("generation_policy")
  else: bad["generation_policy"] = value
  var payload: String = session._canonical({"campaign":bad,"binding":session.selected_generation()})
  var text: String = session._canonical({"format":1,"origin":session.checkpoint_origin(),"payload":payload,"digest":payload.sha256_text()})
  var file := FileAccess.open(bad_path,FileAccess.WRITE); file.store_string(text); file.close()
  check(not session.load_camp(bad_path),"digest-valid malformed/unsupported generation policy refused by real reader: "+str(value))
  check(session.campaign.get_instance_id() == identity and session._canonical(session.campaign.snapshot()) == before and FileAccess.get_file_as_string(bad_path) == text and signals_seen == 0,"refusal preserves exact live authority, input file and signals: "+str(value))
  check("incompatible" in session.last_error and "unchanged" in session.last_error,"unsupported checkpoint has a clear visible refusal")
 # Existing persisted people are authoritative. This explicit saved-record fixture
 # violates the new-person exclusion but is never rerolled or silently coerced.
 var deserter: Dictionary = {}
 for p in c.recruit_pools.values():
  if p.name == "Deserter": deserter = p; break
 check(not deserter.is_empty(),"seeded existing Deserter fixture available")
 if not deserter.is_empty():
  for attr in People.ATTRS: deserter.aptitudes[attr] = 0
  deserter.aptitudes.resolve = 1; deserter.aptitudes.skill = 2; deserter.aptitudes.health = 1
  deserter.growth_offers = People.roll_growth(deserter)
  var persisted: Dictionary = c.snapshot()
  var candidate = c.get_script().new()
  check(candidate.restore(persisted) and candidate.recruit_pools[deserter.id] == deserter,"existing valid Deserter talent/growth retained exactly, no retroactive exclusion")
  # Earning a real legal level must not rederive the founder's base package.
  var founder: Dictionary = c.soldiers[0]
  c.Progression.grant(founder,"battle_talents_fixture",40,c.day,"Declared progression verification fixture.")
  var groups: Array = founder.perk_groups.duplicate()
  var offers: Array = founder.growth_offers.duplicate(true)
  check(c.develop(0,["health","skill","defense"]) and c.learn_perk(0,"colossus"),"real earned founder training and perk purchase")
  var trained: Dictionary = c.snapshot()
  check(candidate.restore(trained) and session._canonical(candidate.snapshot()) == session._canonical(trained),"trained founder saves exact stats, HP, perks, XP/history and growth")
  check(founder.perk_groups == groups and founder.growth_offers == offers,"training retains authored pool and future saved offers")
  check(session.save_camp("user://talents-trained.json"),"real current writer accepts trained/retained existing people")
 # Independent future-week generator; never call it as part of load.
 # Explicit detached temporal fixture: no money, supplies or world is fabricated.
 var future := {"endless":true,"day":50,"seed_value":7391,"world":c.world,"recruit_pools":c.recruit_pools.duplicate(true)}
 var prior: Dictionary = future.recruit_pools.duplicate(true)
 Career.ensure_recruits(future)
 var expanded: Dictionary = future.recruit_pools.duplicate(true)
 Career.ensure_recruits(future)
 check(expanded == future.recruit_pools,"future weekly generation idempotent")
 check(prior.keys().all(func(id):return future.recruit_pools[id] == prior[id]),"future weeks do not replace any existing offer")
 var new_count := 0
 var excluded := 0
 for id in expanded:
  if prior.has(id): continue
  new_count += 1
  var p: Dictionary = expanded[id]
  check(People.validate_offer(p) and p.aptitudes.values().filter(func(v):return v > 0).size() == 3,"future recruit valid with three talents")
  if p.name == "Deserter" and p.aptitudes.resolve > 0: excluded += 1
 check(new_count == c.world.TOWNS.size()*3*2 and excluded == 0,"weeks 5 through 7 use current ordinary exclusions without founder packages")
 print(JSON.stringify({"test":"talents_admission","checks":checks,"failures":failures}))
 app.free(); quit(0 if failures.is_empty() else 1)
