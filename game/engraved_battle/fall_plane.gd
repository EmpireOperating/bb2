extends MeshInstance3D
## One temporary painted projection. It is not an actor, a body item, or a collider.
const RETIRE := 0.64
# Feet, shin, knee, hip, chest, head. Coordinates are in standing-body heights.
const HEIGHTS := [0.0,0.18,0.34,0.54,0.77,1.0]
const ACROSS := [0.0,0.20,0.36,0.50,0.64,0.80,1.0]
const TIMES := [0.0,0.107,0.219,0.322,0.375]
const POSES := [
 [Vector2(0,0),Vector2(0,0.18),Vector2(0,0.34),Vector2(0,0.54),Vector2(0,0.77),Vector2(0,1.0)],
 [Vector2(0,0),Vector2(-0.045,0.14),Vector2(-0.12,0.23),Vector2(0.025,0.36),Vector2(0.15,0.549),Vector2(0.226,0.775)],
 [Vector2(-0.055,0.015),Vector2(-0.16,0.10),Vector2(-0.16,0.244),Vector2(0.052,0.255),Vector2(0.19,0.35),Vector2(0.31,0.455)],
 [Vector2(-0.25,0.022),Vector2(-0.19,0.08),Vector2(-0.075,0.20),Vector2(0.098,0.168),Vector2(0.235,0.257),Vector2(0.317,0.341)],
 [Vector2(-0.242,0.028),Vector2(-0.184,0.096),Vector2(-0.073,0.217),Vector2(0.107,0.171),Vector2(0.231,0.271),Vector2(0.310,0.358)]
]
# Separate front/back travel for shin, bent knee, hip, shoulders and head.
const DEPTHS := [0.02,0.11,0.16,-0.02,-0.08,-0.04]
const VOLUME := [0.024,0.040,0.063,0.105,0.121,0.073]
static var _shadow_ink: ImageTexture
var age:=0.0
var _size:=Vector2.ZERO
var _foot:=Vector2.ZERO
var _body_pixels:=1.0
var _pixels:=0.005
var _direction:=1.0
var _flip:=false
var _anchor:=Vector3.ZERO
var _source:Texture2D
var _center:=Vector3.ZERO
var _normals:=PackedVector3Array()
var _limits:=PackedFloat32Array()
var _shadow:Sprite3D

# Freeze only the on-screen ink and registration at the actual contact.
func start(sprite:Sprite3D,camera:Camera3D,impact:Vector3,center:Vector3,hex:PackedVector3Array) -> void:
 _source=sprite.texture;_size=_source.get_size()
 _foot=Vector2(_size.x*0.5-sprite.offset.x,_size.y*0.5+sprite.offset.y)
 _pixels=sprite.pixel_size*sprite.global_basis.get_scale().y
 _body_pixels=maxf(1.0,_foot.y-_size.y*0.085)
 _anchor=sprite.global_position
 _center=center
 for i in hex.size():
  var mid:Vector3=(hex[i]+hex[(i+1)%hex.size()])*0.5-center
  mid.y=0.0;_normals.append(mid.normalized());_limits.append(mid.length())
 _flip=sprite.flip_h
 var along:=camera.global_basis.x.dot(impact.normalized())
 _direction=signf(along) if absf(along)>0.10 else (1.0 if _flip else -1.0)
 var mat := (sprite.material_override as ShaderMaterial).duplicate() as ShaderMaterial
 mat.set_shader_parameter("source_texture",_source)
 material_override=mat
 cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 _make_shadow()
 advance(0.0,camera)

func advance(dt:float,camera:Camera3D) -> void:
 age+=maxf(0.0,dt)
 global_transform=Transform3D(camera.global_basis.orthonormalized(),_anchor)
 _shadow.global_transform=Transform3D(Basis(camera.global_basis.x,Vector3.UP.cross(camera.global_basis.x)*0.73,Vector3.UP),_center+Vector3.UP*0.025)
 var settling:=smoothstep(0.04,0.32,age)
 _shadow.modulate.a=0.66*settling
 if age-dt>=TIMES[-1] and dt>0.0:return
 var step:=0
 while step+1<TIMES.size()-1 and age>=TIMES[step+1]:step+=1
 var blend:=clampf(inverse_lerp(TIMES[step],TIMES[step+1],age),0.0,1.0)
 # Take the weight quickly, then accelerate into the drop rather than float.
 if step==0:blend=1.0-pow(1.0-blend,2.0)
 elif step==2:blend=pow(blend,1.5)
 else:blend=smoothstep(0.0,1.0,blend)
 var spine:=PackedVector2Array()
 for i in HEIGHTS.size():
  var point:Vector2=POSES[step][i].lerp(POSES[step+1][i],blend)
  spine.append(Vector2(point.x*_direction,point.y))
 var form:=smoothstep(0.045,0.285,age)
 var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
 var stride:=ACROSS.size()
 # Include the full registered sheet, incl. weapon tips and transparent margins.
 for i in range(-1,HEIGHTS.size()+1):
  var j:=clampi(i,0,HEIGHTS.size()-1)
  var from:=maxi(j-1,0);var to:=mini(j+1,HEIGHTS.size()-1)
  var tangent:Vector2=(spine[to]-spine[from])/(HEIGHTS[to]-HEIGHTS[from])
  # Independent normal at each cross-section; retain the shoulder width.
  var raw_axis:=Vector2(tangent.y,-tangent.x).normalized()
  var axis:=Vector2.RIGHT.lerp(raw_axis,0.29 if j<3 else 0.55).normalized()
  if i<0 or i>=HEIGHTS.size():axis=Vector2.RIGHT.lerp(axis,0.55)
  var h:float=HEIGHTS[j]
  if i<0:h=(_foot.y-_size.y)/_body_pixels
  elif i>=HEIGHTS.size():h=_foot.y/_body_pixels
  var center:Vector2=spine[j]+tangent*(h-HEIGHTS[j])
  var v:=clampf((_foot.y-h*_body_pixels)/_size.y,0.0,1.0)
  for col in stride:
   var u:float=ACROSS[col]
   var x:float=(u*_size.x-_foot.x)/_body_pixels
   var section:Vector2=center+axis*x
   var dome:=sqrt(maxf(0.0,1.0-pow(x/0.31,2.0)))
   var z:float=(DEPTHS[j]+VOLUME[j]*dome)*form
   vertices.append(_vertex(Vector3(section.x,section.y,z),form))
   uv.append(Vector2(1.0-u if _flip else u,v))
   if i>=HEIGHTS.size() or col+1==stride:continue
   var a:=vertices.size()-1
   indices.append_array(PackedInt32Array([a,a+1,a+stride+1,a,a+stride+1,a+stride]))
 var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
 var ink:=ArrayMesh.new();ink.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 mesh=ink

func _vertex(p:Vector3,form:float) -> Vector3:
 var point:=to_global(p*(_body_pixels*_pixels))
 var radial:=point-_center;radial.y=0.0
 var reach:=1.0
 for k in _normals.size():
  var size:=radial.dot(_normals[k])
  if size>_limits[k]:reach=minf(reach,_limits[k]/size)
 # Project onto an inset of the actual convex hex in world X/Z. Adjacent
 # vertices share edges; their triangles are then confined as well.
 point.x=_center.x+radial.x*reach;point.z=_center.z+radial.z*reach
 point.y=lerpf(point.y,maxf(_center.y+0.019,point.y),form)
 return to_local(point)

func _make_shadow() -> void:
 if _shadow_ink==null:
  var im:=Image.create_empty(48,48,false,Image.FORMAT_RGBA8)
  for y in 48:
   for x in 48:
    var f:=Vector2(x-23.5,y-23.5).length()/23.5
    im.set_pixel(x,y,Color(0.075,0.060,0.046,(1.0-smoothstep(0.23,0.98,f))*0.55))
  im.generate_mipmaps();_shadow_ink=ImageTexture.create_from_image(im)
 _shadow=Sprite3D.new();_shadow.name="ContactShadow";_shadow.texture=_shadow_ink
 _shadow.pixel_size=1.32/48.0;_shadow.scale=Vector3(1.0,0.73,1.0)
 _shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(_shadow)


