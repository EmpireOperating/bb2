extends RefCounted
## Tiny offline mesh accumulator: many chipped stones become one draw surface.
var _tool := SurfaceTool.new()
var _count := 0

func _init() -> void:
	_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

func triangle(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (c - a).cross(b - a).normalized()
	for point: Vector3 in [a, b, c]:
		_tool.set_normal(normal)
		_tool.set_color(color)
		_tool.set_uv(Vector2(point.x + point.z, point.y + point.z))
		_tool.add_vertex(point)
	_count += 1

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	triangle(a, b, c, color)
	triangle(a, c, d, color)

func stone(center: Vector3, size: Vector3, yaw: float, color: Color) -> void:
	var bevel := minf(0.035, minf(size.x, size.z) * 0.18)
	var half := size * 0.5
	var ring := PackedVector3Array([
		Vector3(-half.x + bevel, 0, -half.z), Vector3(half.x - bevel, 0, -half.z),
		Vector3(half.x, 0, -half.z + bevel), Vector3(half.x, 0, half.z - bevel),
		Vector3(half.x - bevel, 0, half.z), Vector3(-half.x + bevel, 0, half.z),
		Vector3(-half.x, 0, half.z - bevel), Vector3(-half.x, 0, -half.z + bevel),
	])
	var basis := Basis(Vector3.UP, yaw)
	var lower := PackedVector3Array()
	var shoulder := PackedVector3Array()
	var top := PackedVector3Array()
	for point: Vector3 in ring:
		lower.append(center + basis * (point + Vector3.DOWN * half.y))
		shoulder.append(center + basis * (point + Vector3.UP * (half.y - bevel)))
		top.append(center + basis * (point * 0.93 + Vector3.UP * half.y))
	for i in 8:
		var j := (i + 1) % 8
		triangle(center + Vector3.UP * half.y, top[i], top[j], color.lightened(0.04))
		quad(top[i], shoulder[i], shoulder[j], top[j], color)
		quad(shoulder[i], lower[i], lower[j], shoulder[j], color.darkened(0.07))

func extrude_quad(points: PackedVector2Array, front: float, back: float, color: Color) -> void:
	var a := PackedVector3Array()
	var b := PackedVector3Array()
	for point: Vector2 in points:
		a.append(Vector3(point.x, point.y, front))
		b.append(Vector3(point.x, point.y, back))
	quad(a[0], a[1], a[2], a[3], color)
	quad(b[3], b[2], b[1], b[0], color)
	for i in 4:
		var j := (i + 1) % 4
		quad(a[i], b[i], b[j], a[j], color.darkened(0.06))

func branch(start: Vector3, end: Vector3, radius_a: float, radius_b: float, color: Color) -> void:
	var axis := (end - start).normalized()
	var across := axis.cross(Vector3.RIGHT if absf(axis.x) < 0.9 else Vector3.FORWARD).normalized()
	var other := axis.cross(across)
	for i in 7:
		var a := TAU * float(i) / 7.0
		var b := TAU * float(i + 1) / 7.0
		var side_a := across * cos(a) + other * sin(a)
		var side_b := across * cos(b) + other * sin(b)
		quad(start + side_a * radius_a, end + side_a * radius_b, end + side_b * radius_b, start + side_b * radius_a, color)
		triangle(end, end + side_b * radius_b, end + side_a * radius_b, color)

func leaf_cluster(center: Vector3, size: Vector3, phase: float, color: Color) -> void:
	for band in 5:
		var a := PI * float(band) / 5.0
		var b := PI * float(band + 1) / 5.0
		for side in 8:
			var c := TAU * float(side) / 8.0
			var d := TAU * float(side + 1) / 8.0
			var p0 := _leaf_point(a, c, phase) * size + center
			var p1 := _leaf_point(b, c, phase) * size + center
			var p2 := _leaf_point(b, d, phase) * size + center
			var p3 := _leaf_point(a, d, phase) * size + center
			var leaf_color := color.lightened(float((band + side) % 3) * 0.028)
			if band == 0:
				triangle(p0, p1, p2, leaf_color)
			elif band == 4:
				triangle(p0, p1, p3, leaf_color)
			else:
				quad(p0, p1, p2, p3, leaf_color)

func _leaf_point(latitude: float, longitude: float, phase: float) -> Vector3:
	var radius := 1.0 + sin(longitude * 3.0 + latitude * 7.0 + phase) * 0.13
	return Vector3(sin(latitude) * cos(longitude), cos(latitude), sin(latitude) * sin(longitude)) * radius

func grass_tuft(center: Vector3, height: float, phase: float, color: Color) -> void:
	for i in 5:
		var angle := phase + float(i) * 2.4
		var across := Vector3(cos(angle), 0, sin(angle)) * 0.022
		var base := center + Vector3(sin(angle * 1.7), 0, cos(angle * 2.3)) * 0.025
		var tip := base + Vector3(sin(angle) * 0.037, height * (0.65 + float(i % 3) * 0.16), cos(angle) * 0.037)
		triangle(base - across, tip, base + across, color.lightened(float(i % 2) * 0.06))

func leaf_litter(center: Vector3, phase: float, color: Color) -> void:
	for i in 7:
		var angle := phase + float(i) * 2.39996
		var base := center + Vector3(cos(angle) * 0.058, float(i % 2) * 0.003, sin(angle) * 0.058)
		var along := Vector3(cos(angle), 0, sin(angle)) * 0.035
		var across := Vector3(-sin(angle), 0, cos(angle)) * 0.016
		quad(base - along, base - across + Vector3.UP * 0.006, base + along, base + across, color)

func finish() -> ArrayMesh:
	if _count == 0:
		return ArrayMesh.new()
	_tool.index()
	return _tool.commit()
