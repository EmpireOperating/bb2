extends RefCounted
## Four special-only fitted strips. No combat authority, wear or feedback here.
const RingboundMaul = preload("res://engraved_people/ringbound_maul.gd")
const Wear = preload("res://engraved_people/named_wear.gd")
const PATH := "res://engraved_people/melee-special-cuts"
const BEFORE := {
 "split_shield":[0.23,0.59,0.77,1.0],
 "staggering_blow":[0.26,0.62,0.81,1.0],
 "shatter_armour":[0.19,0.49,0.79,1.0],
 "puncture":[0.22,0.57,0.78,1.0],
}
const AFTER := {
 "split_shield":[0.052,0.125,0.196],
 "staggering_blow":[0.050,0.108,0.190],
 "shatter_armour":[0.080,0.168,0.267],
 "puncture":[0.043,0.092,0.167],
}
const CONTACT := 4
const CACHE_LIMIT := 64
const CANVAS := Vector2i(480,464)
const FAMILY := {"axe":"split_shield","mace":"staggering_blow","hammer":"shatter_armour","dagger":"puncture"}
static var _data: Dictionary = {}
static var _sheet: Image
static var _cache: Dictionary = {}

static func _ready() -> bool:
 if _sheet!=null:return true
 if not FileAccess.file_exists(PATH+".json") or not FileAccess.file_exists(PATH+".png"):return false
 var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH+".json"))
 if not data is Dictionary or data.get("version")!=1:return false
 var im:=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes(PATH+".png"))!=OK:return false
 im.convert(Image.FORMAT_RGBA8)
 _data=data;_sheet=im
 return true

static func frame(kind:String,t:float,contact:float) -> int:
 if contact<=0.0 or not BEFORE.has(kind):return -1
 for i in CONTACT:
  if t<contact*float(BEFORE[kind][i]):return i
 for i in 3:
  if t<contact+float(AFTER[kind][i]):return CONTACT+i
 return -1

static func fits_item(unit:Dictionary,signature:Dictionary,uid:String) -> bool:
 var equipped:Dictionary=unit.get("arms",{}).get("weapon",{})
 var drawn:Dictionary=signature.get("weapon",{})
 return not uid.is_empty() and drawn.get("visible",false) and drawn.get("item","")==uid and equipped.get("id","")==uid and drawn.get("definition","")==equipped.get("definition","")

## Select from finite prepainted edge paths using a witnessed plate, never a
## target body socket. This is presentation of the already legal strike.
static func select(recipe:Dictionary,kind:String,sprite:Sprite3D,camera:Camera3D,flipped:bool,plate_world:Vector3) -> Dictionary:
 if recipe.is_empty() or not BEFORE.has(kind) or not _ready():return {}
 var part:String=recipe.get("weapon","")
 if _data.fits[kind].get(part,"")!=recipe.get("stance","none"):return {}
 var lanes:Dictionary=_data.parts[part]
 if kind!="split_shield":return {"kind":kind,"lane":"base"}
 if not is_instance_valid(sprite) or not is_instance_valid(camera) or sprite.texture==null or sprite.pixel_size<=0.0 or not plate_world.is_finite():return {}
 var basis:=camera.global_basis
 var delta:=plate_world-sprite.global_position
 var x:=delta.dot(basis.x)/sprite.pixel_size-sprite.offset.x
 var y:=sprite.offset.y-delta.dot(basis.y)/sprite.pixel_size-float(sprite.texture.get_meta("painted_top_pad",0))*0.5
 var aim:=Vector2(CANVAS)*0.5+Vector2(-x if flipped else x,y)
 var lane:=""
 var best:=INF
 for key:String in lanes:
  var row:Dictionary=lanes[key][CONTACT]
  var hit:=Vector2(row.edge[0],row.edge[1])
  var cost:=aim.distance_squared_to(hit)
  if cost<best:best=cost;lane=key
 return {"kind":kind,"lane":lane} if not lane.is_empty() else {}

static func compose(recipe:Dictionary,gesture:Dictionary,index:int,plates:Dictionary,plan:Callable,stamp:Callable) -> Texture2D:
 var lane:String=gesture.get("lane","")
 var kind:String=gesture.get("kind","")
 var part:String=recipe.get("weapon","")
 if not _ready() or not BEFORE.has(kind) or _data.fits[kind].get(part,"")!=recipe.get("stance","none"):return null
 var rows:Array=_data.parts[part].get(lane,[])
 if index<0 or index>=rows.size():return null
 var key:=JSON.stringify([recipe,kind,lane,index])
 if _cache.has(key):return _cache[key]
 var row:Dictionary=rows[index]
 var pad:=Vector2i(row.pad[0],row.pad[1])
 var shift:=pad+Vector2i(0,int(plates.hip_y[0]))
 var im:=Image.create_empty(CANVAS.x+2*pad.x,CANVAS.y+pad.y,false,Image.FORMAT_RGBA8)
 stamp.call(im,recipe.cloak,shift)
 if recipe.has("ammo"):
  stamp.call(im,recipe.ammo,shift)
  if recipe.ammo_fill>0:stamp.call(im,recipe.ammo+"/"+str(recipe.ammo_fill),shift)
 stamp.call(im,"legs/%s/-1" % recipe.feet,pad)
 var order:Array=plan.call(recipe,false)
 if recipe.stance=="single" and not recipe.shield.is_empty():
  # Preserve the exact off-hand plate/wear above the body, below the striking sleeve and hand.
  for cut:String in order:
   if not cut.begins_with("single/right/grip/sleeve/"):continue
   order.erase(recipe.shield)
   if not recipe.shield_wear.is_empty():order.erase(recipe.shield_wear)
   var sleeve_index:=order.find(cut)
   order.insert(sleeve_index,recipe.shield)
   if not recipe.shield_wear.is_empty():order.insert(sleeve_index+1,recipe.shield_wear)
   break
 if recipe.stance=="paired":
  # The rear sleeve leaves its resting stack to follow the paired grip over
  # the chest. During the load it also crosses the face/helmet silhouette.
  var line:="face/%d/%s"%[recipe.face,"hair" if recipe.head.is_empty() else "shorn"]
  for cut:String in order:
   if not cut.begins_with("sleeve/paired/back/"):continue
   order.erase(cut)
   var front:=order.find(line)
   if index in [1,2,3]:
    for lead:String in order:
     if lead.begins_with("sleeve/paired/front/"):front=order.find(lead);break
   order.insert(front,cut)
   break
 for cut:String in order:
  if cut==part and RingboundMaul.stamp(im,recipe,kind,index,shift):continue
  if not row.ink.has(cut):stamp.call(im,cut,shift);continue
  if Wear.stamp(im,cut,shift,recipe,"melee/%s/%d" % [lane,index]):continue
  var p:Array=_data.cuts[int(row.ink[cut])]
  im.blend_rect(_sheet,Rect2i(p[2],p[3],p[4],p[5]),Vector2i(p[0],p[1])+shift)
 im.generate_mipmaps()
 var tex:=ImageTexture.create_from_image(im)
 tex.set_meta("engraved_head",Wear.head_recipe(recipe))
 tex.set_meta("melee_special_pose",{"kind":kind,"lane":lane,"role":row.role,"frame":index,"edge":Vector2(row.edge[0],row.edge[1])+Vector2(shift),"grip":Vector2(row.grip[0],row.grip[1])+Vector2(shift)})
 if pad.x>0:tex.set_meta("painted_side_pad",pad.x)
 if pad.y>0:tex.set_meta("painted_top_pad",pad.y)
 if not recipe.shield.is_empty():
  var p:Array=plates.cuts[recipe.shield]
  tex.set_meta("fitted_shield",{"part":recipe.shield,"center":Vector2(p[0],p[1])+Vector2(p[4],p[5])*0.5+Vector2(shift),"worn":not recipe.shield_wear.is_empty()})
 if _cache.size()>=CACHE_LIMIT:_cache.erase(_cache.keys()[0])
 _cache[key]=tex
 return tex
