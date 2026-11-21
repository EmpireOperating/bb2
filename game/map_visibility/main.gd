extends "res://combat_pass/main.gd"
func _init() -> void: checkpoint_path="user://map-visibility-camp.json"
func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Battlefield & Fog")
func _create_session(): return load("res://map_visibility/session.gd").new()
func _create_battlefield() -> Node3D: return load("res://map_visibility/battlefield.gd").new()
