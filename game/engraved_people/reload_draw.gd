extends RefCounted
## Left-arm sprite animation. Does not own Reload or the loaded flag.
const DURATION := 0.78
const SEAT_FRAME := 10
const BOUNDARIES := [0.045,0.09,0.14,0.20,0.26,0.305,0.36,0.42,0.48,0.55,0.61,0.68,DURATION]
const PATH := "res://engraved_people/reload-sleeves"
static var _sheet:Image
static var _meta:Dictionary={}

static func ready() -> bool:
 if _sheet!=null:return true
 var rows:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH+".json"))
 if not rows is Dictionary or rows.offsets.size()!=BOUNDARIES.size():return false
 var im:=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes(PATH+".png"))!=OK:return false
 _meta=rows;_sheet=im
 return true

static func frame(elapsed:float) -> int:
 for i in BOUNDARIES.size():
  if elapsed<BOUNDARIES[i]:return i
 return -1

static func hand_offset(draw:int) -> Vector2i:
 var p:Array=_meta.offsets[draw]
 return Vector2i(p[0],p[1])

static func stamp_sleeve(im:Image,cut:String,shift:Vector2i,draw:int) -> bool:
 var row:int=_meta.cuts.find(cut)
 if row<0:return false
 var size:=Vector2i(_meta.size[0],_meta.size[1])
 var xy:=Vector2i(_meta.xy[0],_meta.xy[1])
 im.blend_rect(_sheet,Rect2i(Vector2i(draw*size.x,row*size.y),size),xy+shift)
 return true
