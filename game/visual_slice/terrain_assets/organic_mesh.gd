extends "res://prototype/terrain_assets/mesh_builder.gd"
## Low-poly silhouette geometry with actual painted materials; never collision.
func boulder(center: Vector3, size: Vector3, phase: float, color: Color) -> void:
	var lower := PackedVector3Array()
	var upper := PackedVector3Array()
	for i in 6:
		var a := float(i)*TAU/6.0+phase
		var radius := .46+sin(float(i)*2.71+phase)*.07
		lower.append(center+Vector3(cos(a)*size.x*radius,-size.y*.47,sin(a)*size.z*radius))
		upper.append(center+Vector3(cos(a+.06)*size.x*radius*.82,size.y*(.29+sin(float(i)*1.73+phase)*.11),sin(a+.06)*size.z*radius*.82))
	for i in 6:
		var j := (i+1)%6
		quad(lower[i],lower[j],upper[j],upper[i],color)
		triangle(center+Vector3.UP*size.y*.48,upper[i],upper[j],color.lightened(.04))

func leaf_card(center: Vector3, basis: Basis, scale_value: float, color: Color) -> void:
	var outline := PackedVector2Array([Vector2(-.10,0),Vector2(-.085,-.06),Vector2(-.035,-.055),Vector2(0,-.15),Vector2(.035,-.055),Vector2(.085,-.06),Vector2(.10,0),Vector2(.055,.065),Vector2(0,.13),Vector2(-.055,.065)])
	for i in outline.size():
		var a: Vector2=outline[i]*scale_value
		var b: Vector2=outline[(i+1)%outline.size()]*scale_value
		triangle(center,center+basis*Vector3(a.x,.006,a.y),center+basis*Vector3(b.x,.006,b.y),color)
