extends "res://map_visibility/main.gd"
func _init() -> void: checkpoint_path="user://procedural-woodland-camp.json"
func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Procedural Woodland")
func _create_session(): return load("res://procedural_woodland/session.gd").new()
func _create_camp_panel() -> Control: return load("res://procedural_woodland/camp_panel.gd").new()
func _create_battlefield() -> Node3D: return load("res://grassland_visuals/battlefield.gd").new()
func observation() -> Dictionary:
 var out := super.observation()
 out["procedural_woodland"] = true
 if session != null and session.campaign != null:
  var deployed: bool = session.campaign.phase in ["battle","aftermath"]
  out["generation"] = session.deployed_generation.duplicate(true) if deployed else session.selected_generation()
  if deployed: out["map_title"] = session.deployed_map.get("title","")
  elif session.selected_map_id == "generated_woodland_road": out["map_title"] = "Generated Woodland Road · seed %d" % session.generation_seed
  else: out["map_title"] = load("res://map_visibility/maps.gd").create(session.selected_map_id).get("title","")
 return out
