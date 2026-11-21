extends Node3D
## Small, noninteractive continuation of a witnessed projectile–shield contact.
const People=preload("res://engraved_people/actors.gd")
const ColorIdentity=preload("res://sprite_study/color_identity.gdshader")
const DEFLECT:=0.20
const SPLIT:=0.28
var age:=0.0
var lifetime:=DEFLECT
var victim:int
var actor_instance:int
var cell:Vector2i
var _parts:Array[Dictionary]=[]

func prime(point:Vector3,cam:Camera3D,shot:MeshInstance3D,ink:Dictionary,side:float,scale:float,broken:bool)->void:
 set_meta("ranged_shield_contact",true)
 global_position=point
 var basis:=cam.global_basis
 if broken:
  var plate:=People.shield_plate(ink.part,ink.worn)
  if plate!=null:
   lifetime=SPLIT
   if side<0:plate.flip_x()
   var size:=plate.get_size()
   # Tear the actual worn face on two unequal sides of a jagged seam.
   for i in range(2):
    var fragment:Image=plate.duplicate()
    for y in range(size.y):
     var edge:=floori(size.x*(0.39+0.20*float(y)/size.y))+(3 if (y/13)%2==0 else -3)
     for x in range(size.x):
      if (i==0 and x>=edge) or (i==1 and x<edge):fragment.set_pixel(x,y,Color.TRANSPARENT)
    var box:=fragment.get_used_rect()
    if box.size.x<=0 or box.size.y<=0:continue
    var cropped:=fragment.get_region(box);cropped.generate_mipmaps()
    var cut:=QuadMesh.new();cut.size=Vector2(box.size)*scale
    var mid:=Vector2(box.position)+Vector2(box.size)*0.5-Vector2(size)*0.5
    var material:=ShaderMaterial.new();material.shader=ColorIdentity;material.render_priority=1
    material.set_shader_parameter("source_texture",ImageTexture.create_from_image(cropped))
    var direction:float=-1.0 if i==0 else 1.0
    _part(cut,material,Vector2(mid.x,-mid.y)*scale,Vector2(direction*(1.05 if i==0 else 1.40),0.48),0.0,direction*3.4)
 var along:=shot.global_basis.x
 var start:=atan2(along.dot(basis.y),along.dot(basis.x))
 var back:float=-1.0 if along.dot(basis.x)>0.0 else 1.0
 _part(shot.mesh,shot.material_override,Vector2.ZERO,Vector2(back*(1.75 if not broken else 1.26),1.65 if not broken else 0.84),start,back*7.2)
 advance(0.0,cam)

func _part(mesh:Mesh,material:Material,origin:Vector2,speed:Vector2,start:float,spin:float)->void:
 var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=material
 node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(node)
 _parts.append({"node":node,"origin":origin,"speed":speed,"start":start,"spin":spin})

func advance(dt:float,cam:Camera3D)->void:
 age+=maxf(0.0,dt)
 var basis:=cam.global_basis
 for part:Dictionary in _parts:
  var xy:Vector2=part.origin+part.speed*age+Vector2(0,-11.0*age*age)
  var x:=basis.x.rotated(basis.z,part.start+age*part.spin)
  var y:=basis.z.cross(x)
  var shrink:=lerpf(1.0,0.62,smoothstep(lifetime*0.66,lifetime,age))
  var node:MeshInstance3D=part.node
  node.global_transform=Transform3D(Basis(x*shrink,y*shrink,basis.z),global_position+basis.x*xy.x+basis.y*xy.y+basis.z*0.056)
