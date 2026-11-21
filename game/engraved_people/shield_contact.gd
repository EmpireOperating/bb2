extends RefCounted
## Presentation-only sleeve, grip and shield registrations in character pixels.
const PATH := "res://engraved_people/shield-contact"
const BEATS := [0.038,0.103,0.148,0.189,0.234,0.281,0.32]
static var _atlas:Image
static var _data:Dictionary={}

static func ready() -> bool:
 if _atlas!=null:return true
 var j:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH+".json"))
 if not j is Dictionary or j.offsets.size()!=BEATS.size():return false
 var im:=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes(PATH+".png"))!=OK:return false
 _atlas=im;_data=j
 return true

static func item(unit:Dictionary,signature:Dictionary,recipe:Dictionary) -> String:
 if recipe.get("stance","")!="single" or recipe.get("shield","").is_empty():return ""
 var arms:Dictionary=unit.get("arms",{}).get("shield",{})
 var layer:Dictionary=signature.get("shield",{})
 var uid:String=arms.get("id","")
 return uid if int(arms.get("condition",0))>0 and layer.get("visible",false) and String(layer.get("item",""))==uid else ""

static func frame(t:float) -> int:
 for i in BEATS.size():
  if t<BEATS[i]:return i
 return -1

static func profile(shield:String) -> int:
 if shield in ["shield/buckler","shield/t1-buckler"]:return 2
 return 1 if shield=="shield/t1-round-wooden-shield" else 0

static func offset(i:int,lane:int) -> Vector2i:
 return Vector2i(_data.profiles[lane][i][0],_data.profiles[lane][i][1])

static func stamp_sleeve(dst:Image,cut:String,shift:Vector2i,i:int,lane:int) -> bool:
 var row:int=_data.keys.find(cut)
 if row<0:return false
 row+=lane*_data.keys.size()
 var size:=Vector2i(_data.size[0],_data.size[1])
 var xy:=Vector2i(_data.xy[0],_data.xy[1])
 dst.blend_rect(_atlas,Rect2i(Vector2i(size.x*i,size.y*row),size),xy+shift)
 return true
