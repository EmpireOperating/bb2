extends "res://burial_ruins/main.gd"
## Retained phase host and field factory; only the real startup factory changes.
func _create_session():
 checkpoint_path = "user://dungeon-maps-camp.json"
 return load("res://dungeon_maps/session.gd").new()

func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Dungeon Maps")
