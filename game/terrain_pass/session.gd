extends "res://company_loop/session.gd"
## Authored terrain adapter over the same Campaign, ownership and settlement.
const Maps = preload("res://terrain_pass/maps.gd")
var selected_map_id := "ruined_crossing"
var _deployed_map: Dictionary = {}
var deployed_map: Dictionary:
 get: return _deployed_map.duplicate(true)

func select_map(id: String) -> bool:
 if campaign.phase != "camp": return _fail("Choose the next battlefield in camp, not during battle or aftermath.")
 var reason := Maps.validate(Maps.create(id))
 if not reason.is_empty(): return _fail(reason)
 selected_map_id = id
 return _success()

func _selected_descriptor() -> Dictionary:
 return Maps.create(selected_map_id)

func start_battle() -> bool:
 if campaign.phase != "camp" or campaign.over() or campaign.alive_count() == 0 or not campaign.active.is_empty():
  return _fail("Deployment requires a living company in camp with no active job.")
 # Validate *before* job/location/deployment mutation. Stage the real Campaign on
 # a stock-validated detached snapshot; publish only a fully installed battle.
 var descriptor := _selected_descriptor()
 var reason := Maps.validate(descriptor)
 if not reason.is_empty(): return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null: return _fail("Company snapshot is invalid; deployment left camp unchanged.")
 candidate.active = {"id":"company_loop_%d" % candidate.encounters,"kind":"legacy","origin":"ashwick","target":"ford","shipment":"","client":candidate.world.towns.ashwick.owner,"generation":candidate.world.camps.ford.generation,"title":descriptor.title,"brief":"Authored terrain sortie: defeat the band. Retreat closes this deployment unpaid.","pay":120,"threat":2,"objective":"eliminate","deadline":candidate.job_deadline(8),"participants":candidate.active_ids()}
 candidate.location = "ford"
 candidate.overworld.position = candidate.overworld.places.ford
 candidate.overworld.path.clear()
 candidate.overworld.destination = ""
 candidate.overworld.paused = true
 if not candidate.deploy(): return _fail("Campaign deployment refused; camp unchanged.")
 var battle = candidate.battle
 if battle.units.size() != descriptor.spawns.size() or battle.player_slots() != 6:
  return _fail("Authored map requires six company and six enemy tactical slots.")
 battle.tiles = descriptor.tiles.duplicate(true)
 for unit in battle.units:
  var spawn: Vector2i = descriptor.spawns[unit.id]
  unit.q = spawn.x
  unit.r = spawn.y
  if unit.side == 0:
   unit["company_id"] = candidate.deployment[unit.id]
   unit["visual_id"] = candidate.deployment[unit.id]
  else: unit["visual_id"] = 6+unit.id
 # Campaign already opened the first activation. Correct only its position-
 # derived origin: no reset_segment/start_round/AP/fatigue/sequence reset.
 if battle.active_id >= 0:
  var unit: Dictionary = battle.units[battle.active_id]
  var state: Dictionary = battle.vital_state(unit)
  state.origin_q = unit.q
  state.origin_r = unit.r
 battle.terrain_rules_enabled = true
 battle.set_meta("authored_map",descriptor.duplicate(true))
 _deployed_map = descriptor.duplicate(true)
 campaign = candidate
 return _success()

const SUCCESSOR_USER_DIR := "ashen-company-terrain-rules"
const CHECKPOINT_PATH := "user://terrain-camp.json"

func _checkpoint_path(path: String) -> String:
 if not ProjectSettings.get_setting("application/config/use_custom_user_dir",false) or ProjectSettings.get_setting("application/config/custom_user_dir_name","") != SUCCESSOR_USER_DIR or OS.get_user_data_dir().get_file() != SUCCESSOR_USER_DIR:
  _fail("Checkpoint requires the isolated Terrain Rules custom user directory.")
  return ""
 var pattern := RegEx.new()
 pattern.compile("^user://[A-Za-z0-9][A-Za-z0-9_-]{0,63}\\.json$")
 var matched := pattern.search(path)
 if matched == null or matched.get_string() != path:
  _fail("Use a simple user://name.json checkpoint (no directories, traversal or absolute paths).")
  return ""
 var directory := DirAccess.open(OS.get_user_data_dir())
 if directory == null or directory.is_link(path.get_file()) or directory.dir_exists(path.get_file()):
  _fail("Checkpoint directory unavailable, or target is a link/directory.")
  return ""
 return ProjectSettings.globalize_path(path)
