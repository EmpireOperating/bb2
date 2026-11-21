extends "res://hollow_campaign/main.gd"
func _create_session():
 checkpoint_path = "user://local-markets-camp.json"
 return load("res://local_markets/session.gd").new()
func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Local Markets")
func observation() -> Dictionary:
 var out: Dictionary=super.observation()
 out["checkpoint_origin"]=session.checkpoint_origin()
 return out
