extends SceneTree
const People = preload("res://src/people.gd")
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
 var oracle_path := "user://talents-current.oracle"
 if "read" in OS.get_cmdline_user_args():
  var parsed = JSON.parse_string(FileAccess.get_file_as_string(oracle_path))
  check(parsed is Dictionary,"independent writer oracle exists")
  if parsed is Dictionary:
   check(parsed.pid != OS.get_process_id(),"cold reader has distinct PID")
   check(session.load_camp(app.checkpoint_path),"actual current session reader accepts atomic writer checkpoint")
   check(session._canonical(session.campaign.snapshot()) == parsed.snapshot,"full campaign oracle equality after cold load")
   check(FileAccess.get_file_as_string(app.checkpoint_path) == parsed.bytes,"reader leaves original checkpoint bytes untouched")
   var before: String = session._canonical(session.campaign.snapshot())
   for i in session.campaign.soldiers.size(): session.preview_unit(i)
   check(session._canonical(session.campaign.snapshot()) == before,"cold inspection never rerolls stats/talents/perks or saved growth")
 else:
  var raw: Dictionary = c.snapshot()
  var candidate = c.get_script().new()
  check(raw.get("generation_policy") is int and raw.get("generation_policy") == 1,"explicit narrow generation policy in current snapshot")
  check(candidate.restore(raw) and session._canonical(candidate.snapshot()) == session._canonical(raw),"fresh exact complete snapshot admission")
  var before: String = session._canonical(c.snapshot())
  session.changed.connect(func():signals_seen += 1)
  for value in [null,false,true,[],{},"1",0,2,1.5]:
   var bad: Dictionary = raw.duplicate(true); bad["generation_policy"] = value
   var input: String = session._canonical(bad)
   check(not c.restore(bad) and session._canonical(c.snapshot()) == before and session._canonical(bad) == input,"malformed policy rejected with no campaign/input mutation: "+str(value))
  var unsupported: Dictionary = raw.duplicate(true); unsupported.erase("generation_policy")
  check(not c.restore(unsupported) and session._canonical(c.snapshot()) == before,"pre-policy save explicitly refused, not reinterpreted or migrated")
  for value in [null,false,[],{},"unknown"]:
   var bad: Dictionary = raw.duplicate(true); bad.soldiers[0]["companion_role"] = value
   check(not c.restore(bad) and session._canonical(c.snapshot()) == before,"malformed founder role rejected without mutation: "+str(value))
  check(signals_seen == 0,"read-only refusal emits no session change")
  # A real affordable hire preserves exact offered identity/growth/tree and gear.
  var offer: Dictionary = c.recruits().filter(func(p):return p.price <= c.crowns)[0]
  var price: int = offer.price
  check(c.hire(offer.id),"lawful current affordable recruit hired")
  var hired: Dictionary = c.soldiers[-1]
  for key in ["person_seed","age","aptitudes","growth_offers","training","perk_groups","perk_pool","gifted_choices","companion_roll"]:
   check(hired[key] == offer[key],"hiring preserves offer "+key)
  check(hired.name == offer.person and hired.background == offer.name and c.crowns == 300-price and not hired.has("companion_role"),"ordinary hire not converted to founder; actual price paid")
  check(c.recruit_pools[offer.id].aptitudes == offer.aptitudes,"stored hired offer never rerolled")
  # Real wear and ammo consumption in owned records, not reset on save/load.
  var shield_uid: String = c.soldiers[1].gear.shield
  c.items[shield_uid].condition -= 1
  var ammo_uid: String = c.soldiers[2].gear.ammo
  c.items[ammo_uid].condition -= 1
  check(candidate.restore(c.snapshot()) and session._canonical(candidate.snapshot()) == session._canonical(c.snapshot()),"hired company with actual worn shield and spent arrow exact roundtrip")
  check(session.save_camp(app.checkpoint_path),"real current atomic session writer succeeds")
  if FileAccess.file_exists(app.checkpoint_path):
   var f := FileAccess.open(oracle_path,FileAccess.WRITE)
   f.store_string(JSON.stringify({"pid":OS.get_process_id(),"snapshot":session._canonical(c.snapshot()),"bytes":FileAccess.get_file_as_string(app.checkpoint_path)})); f.close()
 print(JSON.stringify({"test":"talents_persistence","pid":OS.get_process_id(),"checks":checks,"failures":failures,"last_error":session.last_error}))
 app.free(); quit(0 if failures.is_empty() else 1)
