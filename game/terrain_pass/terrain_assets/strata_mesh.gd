extends "res://visual_slice/terrain_assets/organic_mesh.gd"
## Reuse the accepted irregular rock topology; rotate its actual anisotropic
## geometry, not merely the phase of its six-sided outline.
func ledge(center: Vector3, size: Vector3, yaw: float, phase: float, color: Color) -> void:
	var shape := preload("res://visual_slice/terrain_assets/organic_mesh.gd").new()
	shape.boulder(Vector3.ZERO,size,phase,color)
	var arrays: Array = shape.finish().surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var rotation := Basis(Vector3.UP,yaw)
	for i in range(0,indices.size(),3):
		triangle(center+rotation*vertices[indices[i]],center+rotation*vertices[indices[i+1]],center+rotation*vertices[indices[i+2]],colors[indices[i]])
