extends "res://terrain_pass/main.gd"
func _init() -> void:checkpoint_path="user://combat-camp.json"
func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Combat Completion")
func _create_session():return load("res://combat_pass/session.gd").new()
func _create_battlefield() -> Node3D:return load("res://combat_pass/battlefield.gd").new()
