extends "res://prototype/terrain_assets/mesh_builder.gd"
## Same shared mesh accumulator, with interpolated descriptor material masks.
func masked_triangle(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	var normal := (c-a).cross(b-a).normalized()
	var points := [a,b,c]
	var colors := [ca,cb,cc]
	for i in 3:
		_tool.set_normal(normal)
		_tool.set_color(colors[i])
		_tool.set_uv(Vector2(points[i].x,points[i].z))
		_tool.add_vertex(points[i])
	_count += 1
