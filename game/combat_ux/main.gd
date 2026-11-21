extends "res://local_markets/main.gd"
func _create_session():
 checkpoint_path = "user://combat-ux-camp.json"
 return load("res://combat_ux/session.gd").new()
func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Combat UX")
