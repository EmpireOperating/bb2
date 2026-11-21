extends "res://map_visibility/battlefield.gd"
## Additive terrain presentation; all combat, cameras, cues and fog stay inherited.
func _create_terrain() -> Node3D:
 return load("res://grassland_visuals/terrain.gd").new()
