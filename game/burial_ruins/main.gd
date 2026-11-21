extends "res://town_contracts/main.gd"
## Thin phase host: the session is the only expedition/battle authority.
func _create_session():
 checkpoint_path = "user://burial-ruins-camp.json"
 return load("res://burial_ruins/session.gd").new()

func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Burial Ruins")

func _open_company() -> void:
 if not session.changed.is_connected(_session_changed): session.changed.connect(_session_changed)
 if not is_instance_valid(world):
  world = load("res://burial_ruins/world_view.gd").new()
  world.host = self
  world.campaign = session.campaign
  add_child(world)
 world.set_active(true)

func _burial_available() -> bool:
 return session != null and session.campaign != null and session.campaign.phase == "camp" and not error_panel.visible and is_instance_valid(world) and world.burial_controls_available()

func _enter_burial(site: String) -> void:
 if not _burial_available(): return
 if not session.enter_burial(site):
  world.tell(session.last_error); world.refresh(); return
 _finish_burial_change()

func _burial_action(action: String, target: int = -1) -> void:
 if not _burial_available(): return
 if not session.burial_action(action,target):
  world.tell(session.last_error); world.refresh(); return
 _finish_burial_change()
 if action == "inspect_vault": world.dungeon_door = target

func _deploy() -> void:
 if session != null and session.campaign != null and session.campaign.encounter.get("kind") == "dungeon":
  if not _burial_available() or is_instance_valid(field): return
  if not session.start_burial_battle():
   world.tell(session.last_error); world.refresh(); return
  _mount_field()
  return
 super._deploy()

func _create_battlefield() -> Node3D:
 if session.campaign.encounter.get("kind") == "dungeon":
  return load("res://burial_ruins/battlefield.gd").new()
 return super._create_battlefield()

func _finish_burial_change() -> void:
 # Synchronous changed already rebound the published, unsaved Campaign.
 world.world_view = true
 world.world_selected = session.campaign.location
 world.dungeon_door = -1
 world.refresh()
