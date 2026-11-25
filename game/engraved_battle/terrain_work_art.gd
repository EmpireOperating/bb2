extends RefCounted
## Low illustrative remnants. No input/collision or in-world health rails.
const Builder = preload("res://prototype/terrain_assets/mesh_builder.gd")
const Organic = preload("res://visual_slice/terrain_assets/organic_mesh.gd")
const ACROSS := Vector3(.8660254,0,-.5)
const NEAR := Vector3(.5,0,.8660254)

static func wall_flank(mesh, courses: int, yaw: float, stone: Color) -> void:
 for row in clampi(courses,3,4):
  var left:float=-.927+float(row)*.019
  var right:float=-.252+float(row)*.015
  var block:=ACROSS*((left+right)*.5)+Vector3.UP*(.116+float(row)*.229)
  mesh.stone(block,Vector3(right-left,.227,.284),yaw,stone.lightened(.055 if row%2==0 else .015))

static func stump(cell: Vector2i) -> RefCounted:
 var mesh:=Builder.new()
 var foot:=-ACROSS*.15-NEAR*.30 # Leave the standing center free.
 var tips:=PackedVector3Array()
 var base:=PackedVector3Array()
 var phase:=float(posmod(cell.x*9+cell.y*5,12))*.3
 for i in 10:
  var angle:=phase+TAU*float(i)/10.0
  var ray:=Vector3(cos(angle),0,sin(angle))
  var radius:=.26+cos(angle*3)*.026
  tips.append(foot+ray*radius+Vector3.UP*(.35+sin(angle*2)*.033))
  base.append(foot+ray*(radius+.055+.09*float(i%3==0))+Vector3.UP*.018)
 var heart:=foot+Vector3(-.018,.346,.025)
 for i in tips.size():
  var j:=(i+1)%tips.size()
  var shade:=float((i*7)%5)*.037
  mesh.quad(base[i],tips[i],tips[j],base[j],Color("604430").lightened(shade))
  # The jagged dark cambium, two growth lines and pale core share edges.
  var inner:=tips[i].lerp(heart,.13);var inner_next:=tips[j].lerp(heart,.13)
  mesh.quad(tips[i],inner,inner_next,tips[j],Color("926134").lightened(shade))
  for ring in [[.15,.43,"eebf7d"],[.43,.50,"a36c3c"],[.50,.70,"f4ce92"],[.70,.77,"b98249"]]:
   var a:float=ring[0];var b:float=ring[1]
   mesh.quad(inner.lerp(heart,a),inner.lerp(heart,b),inner_next.lerp(heart,b),inner_next.lerp(heart,a),Color(ring[2]))
  mesh.triangle(inner,inner.lerp(heart,.15),inner_next,Color("dbab6c"))
  mesh.triangle(inner_next,inner.lerp(heart,.15),inner_next.lerp(heart,.15),Color("dbab6c"))
  mesh.triangle(inner.lerp(heart,.77),heart,inner_next.lerp(heart,.77),Color("e7ba7d"))
  if i%2==0:
   var root:=foot.lerp(base[i],1.31);root.y=.035
   mesh.branch(root,foot.lerp(tips[i],.47),.038,.080,Color("755133"))
 for i in 4:
  var at:=foot+ACROSS*(.22+i*.075)+NEAR*(.20+.06*(i%2))
  mesh.triangle(at+Vector3.UP*.017,at+ACROSS*.091+Vector3.UP*.031,at+NEAR*.057+Vector3.UP*.020,Color("d9a668"))
 return mesh

static func rubble(cell: Vector2i) -> RefCounted:
 var mesh:=Organic.new()
 # A scatter of broken courses, not a scaled-down blocking wall.
 var phase:=float(posmod(cell.x+cell.y*7,7))*.14
 mesh.stone(-ACROSS*.719+NEAR*.011+Vector3.UP*.122,Vector3(.415,.235,.23),PI/6.0-.13,Color("ddcdb6"))
 mesh.stone(-ACROSS*.55-NEAR*.27+Vector3.UP*.086,Vector3(.32,.16,.22),PI/6.0+.36,Color("aaa394"))
 mesh.stone(ACROSS*.68+NEAR*.065+Vector3.UP*.087,Vector3(.33,.166,.24),PI/6.0+.23,Color("c7c1ad"))
 for i in 8:
  var angle:=phase+float(i)*2.399963
  var offset:=(ACROSS*cos(angle)+NEAR*sin(angle))*(.22+.11*float(i%4))
  var heft:=.17+.036*float((i*3)%4)
  mesh.boulder(offset+Vector3.UP*.048,Vector3(heft,.105,heft*.76),angle,Color("a9aa96").lightened(.09*float(i%3)))
 return mesh
