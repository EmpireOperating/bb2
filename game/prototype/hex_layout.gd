extends RefCounted
## Pointy-top odd-row offset coordinates, exactly matching Battle.axial/offset.
const HEIGHT_STEP := 0.65
const RADIUS := 1.0
static func world(p: Vector2i, height: float = 0.0) -> Vector3:
	return Vector3(sqrt(3.0) * (p.x + 0.5 * (p.y & 1)), height * HEIGHT_STEP, 1.5 * p.y)
static func from_world(v: Vector3) -> Vector2i:
	var q := (sqrt(3.0)/3.0*v.x - v.z/3.0)
	var r := 2.0/3.0*v.z
	var x := roundi(q)
	var z := roundi(r)
	var y := roundi(-q-r)
	var dx := absf(x-q)
	var dz := absf(z-r)
	var dy := absf(y+q+r)
	if dx > dy and dx > dz: x = -y-z
	elif dz > dy: z = -x-y
	return Vector2i(x + (z-(z&1))/2, z)
static func corners(p: Vector2i, height: float = 0.0, radius: float = RADIUS) -> PackedVector3Array:
	var vertices := PackedVector3Array()
	var center := world(p,height)
	for i in 6:
		var angle := deg_to_rad(30.0+60.0*i)
		vertices.append(center + Vector3(cos(angle)*radius,0,sin(angle)*radius))
	return vertices
