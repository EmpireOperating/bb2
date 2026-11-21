extends "res://company_loop/main.gd"
## Keep the accepted application lifecycle; change only authored factories/origin.
func _init() -> void:
 checkpoint_path = "user://terrain-camp.json"
func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Terrain Rules")
func _create_session():
 return load("res://terrain_pass/session.gd").new()
func _create_camp_panel() -> Control:
 return load("res://terrain_pass/camp_panel.gd").new()
func _create_battlefield() -> Node3D:
 return load("res://terrain_pass/battlefield.gd").new()
func _deploy() -> void:
 if is_instance_valid(camp_panel) and camp_panel.map_chooser.visible: return
 super._deploy()
func observation() -> Dictionary:
 var out := super.observation()
 out["terrain_pass"] = true
 if session != null:
  var deployed: Dictionary = session.deployed_map
  out["selected_map_id"] = session.selected_map_id
  out["deployed_map_id"] = deployed.get("id","")
  out["map_title"] = deployed.get("title","") if session.campaign.phase in ["battle","aftermath"] else load("res://terrain_pass/maps.gd").create(session.selected_map_id).get("title","")
 return out
