extends RefCounted
## Read-only physical equipment and registered undead plates. No kind lookup.
const MANIFEST := "res://painted_merge/undead/manifest.json"
const MANIFEST_SHA := "f930ece991d2de116fe2fd3af46e662b01555d2116644ab4f7388a3ac9f1718b"
## U–01 shares the First Muster physical canvas and body height, not living anatomy.
const BONE_BLOCK := {"path":"res://engraved_battle/hostiles/unburied-u01.png","dimensions":[480,464],"sha256":"d6a8b5ee925db9a06fdcd4186145b030094b6d6e7015e24578fb8552da853f01"}
const DECAY_PLATES := [
 BONE_BLOCK,
 {"path":"res://engraved_battle/hostiles/unburied-sinew.png","dimensions":[480,464],"sha256":"9f439291a7090db9584c11737929abe8e88245758ccf48fa184a711a43f67df8"},
 {"path":"res://engraved_battle/hostiles/unburied-flesh.png","dimensions":[480,464],"sha256":"acd31873cc2117b47adc4becc71e5061c430744ce2d0017675708a05f3994a06"},
]
const BONE_FRAME := {"canvas":[480,464],"base_origin":[0,0],"foot_anchor":[240,411]}
const BONE_GEOMETRY := {"stance_x":240,"foot_y":411,"base_alpha_top":39,"body_height":1.94}
const Named = preload("res://src/named_equipment.gd")
const Arms = preload("res://src/arsenal.gd")
var _manifest: Dictionary = {}
var _images: Dictionary = {}
var _cache: Dictionary = {}

func _record(slot: String, item: Dictionary, catalog: Dictionary) -> Dictionary:
 var definition:=str(item.get("definition",""))
 var maximum:=int(item.get("maximum",Named.definition(item,catalog).get("durability",0)))
 var condition:=int(item.get("condition",maximum))
 return {"slot":slot,"definition":definition,"item":str(item.get("id",item.get("item",""))),"condition":condition,"maximum":maximum,"broken":maximum>0 and condition<=0,"painted":false,"visible":false,"asset":"","fallback":false,"visibility_reason":"","instance_roll":item.get("instance_roll",{}).duplicate(true)}

func _omit(entry: Dictionary, reason: String, issues: Array) -> void:
 entry.visibility_reason=reason
 issues.append({"kind":"omitted","slot":entry.slot,"definition":entry.definition,"item":entry.item,"condition":entry.condition,"maximum":entry.maximum,"reason":reason})

func _layer(source: Dictionary, entry: Dictionary, offset: Array, tint: bool=true) -> Dictionary:
 var color:=Color.WHITE
 if tint and entry.get("maximum",0)>0:
  color=color.lerp(Color("363127"),(1.0-clampf(float(entry.condition)/entry.maximum,0.0,1.0))*0.64)
 return {"path":source.path,"sha256":source.sha256,"dimensions":source.dimensions,"z":int(source.get("z",0)),"offset":offset.duplicate(),"tint":[color.r,color.g,color.b],"slot":entry.get("slot","foundation"),"definition":entry.get("definition",""),"item":entry.get("item","")}

func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
 var result: Dictionary={"ok":false,"texture":null,"signature":{},"issues":[],"errors":[],"plan":{}}
 if not FileAccess.file_exists(MANIFEST) or FileAccess.get_sha256(MANIFEST)!=MANIFEST_SHA:
  result.errors.append("Required skeletal manifest missing or changed");return result
 if _manifest.is_empty():
  _manifest=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
 var signature: Dictionary=result.signature
 var issues: Array=result.issues
 var arms: Dictionary=unit.get("arms",{})
 for slot: String in arms:
  if not arms[slot].is_empty():signature[slot]=_record(slot,arms[slot],catalog)
 var owners: Dictionary={}
 var ranks: Dictionary={"base":0,"padding":0,"mail":1,"outer":2,"shell":2}
 for part: Dictionary in unit.get("armor_parts",[]):
  var slot:=str(part.get("group",""))+"/"+str(part.get("layer",""))
  var entry:=_record(slot,part,catalog)
  signature[slot]=entry
  var group:=str(part.get("group",""))
  if group in ["body","head"] and ranks.has(part.get("layer","")):
   if not owners.has(group) or ranks[part.layer]>ranks[str(owners[group].slot).get_slice("/",1)]:owners[group]=entry
 # Exposed undead is a presentation policy, never an equipment transaction.
 # The room factory fills consecutive opponent slots (6 or 12 onward).
 # Cycle plates by immutable battle ID so a trio cannot roll the same skin.
 # No RNG draw, new save field, kind mapping or wear-dependent reroll.
 var id: int=int(unit.get("id",-1))
 var base: Dictionary=DECAY_PLATES[posmod(id,DECAY_PLATES.size())] if id>=0 else BONE_BLOCK
 var frame: Dictionary=BONE_FRAME.duplicate(true)
 var origin: Array=frame.base_origin
 var layers: Array=[_layer(base,{},origin,false)]
 for slot: String in signature:
  _omit(signature[slot],"Exposed undead: internal combat equipment retained, deliberately not painted. Pictured gear is not recovered.",issues)
 layers.sort_custom(func(a,b):return a.z<b.z)
 result.plan={"frame":frame,"geometry":BONE_GEOMETRY.duplicate(true),"layers":layers.duplicate(true),"base":base.duplicate(true)}
 var paints: Array=[]
 for row: Dictionary in layers:
  var paint:=row.duplicate(true);paint.erase("item");paints.append(paint)
 var cache_key:=JSON.stringify([frame,paints])
 # Revalidate exact required files before EVERY cache hit. Cache only paint,
 # never identity-bearing signatures/plans or earlier admission decisions.
 var images: Array=[]
 for row: Dictionary in layers:
  var image:=_image(row)
  if image==null:result.errors.append("Required skeletal PNG missing, changed or invalid: "+str(row.path))
  images.append(image)
 if result.errors.is_empty():
  if _cache.has(cache_key):result.texture=_cache[cache_key]
  else:
   var canvas:=Vector2i(int(frame.canvas[0]),int(frame.canvas[1]))
   var output:=Image.create(canvas.x,canvas.y,false,Image.FORMAT_RGBA8)
   output.fill(Color.TRANSPARENT)
   for i in layers.size():
    var row: Dictionary=layers[i];var image: Image=images[i]
    if row.tint!=[1.0,1.0,1.0]:image=_tinted(image,row.tint)
    var at:=Vector2i(int(row.offset[0]),int(row.offset[1]))
    if i==0:output.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),at)
    else:output.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),at)
   output.generate_mipmaps()
   result.texture=ImageTexture.create_from_image(output)
   if _cache.size()>=48:_cache.erase(_cache.keys()[0])
   _cache[cache_key]=result.texture
 result.ok=result.texture!=null
 if not result.ok:
  for entry: Dictionary in signature.values():entry.visible=false;entry["composite_blocked"]=true
 return result

func _image(row: Dictionary) -> Image:
 if not FileAccess.file_exists(row.path) or FileAccess.get_sha256(row.path)!=row.sha256:return null
 if _images.has(row.path):return _images[row.path]
 var image:=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes(row.path))!=OK:return null
 if image.get_size()!=Vector2i(int(row.dimensions[0]),int(row.dimensions[1])) or image.get_format()!=Image.FORMAT_RGBA8:return null
 _images[row.path]=image
 return image

func _tinted(image: Image, tint: Array) -> Image:
 var bytes:=image.get_data()
 var rect:=image.get_used_rect()
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x):
   var offset: int=(y*image.get_width()+x)*4
   if bytes[offset+3]==0:continue
   for channel in 3:bytes[offset+channel]=roundi(bytes[offset+channel]*float(tint[channel]))
 return Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes)
