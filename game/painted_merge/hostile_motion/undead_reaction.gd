extends RefCounted
## Source-bound whole-body cuts. The existing 480×464 / (240,411) registration
## is shared by the three exposed undead plates and never translated here.
const SOURCE := "res://engraved_battle/hostiles/"
const ART := "res://painted_merge/hostile_motion/"
const CELL := Vector2i(480,464)
const INDEX := "res://painted_merge/hostile_motion/undead-reaction-index.json"
const HIT_ENDS := [0.042,0.105,0.171,0.237]
const FALL_STARTS := [0.0,0.064,0.157,0.290]
static var _cache: Dictionary = {}

static func hit_index(age:float) -> int:
 for i in HIT_ENDS.size():
  if age<HIT_ENDS[i]:return i
 return -1

static func fall_index(age:float) -> int:
 for i in range(3,0,-1):
  if age>=FALL_STARTS[i]:return i
 return 0

static func load_frames(plate:String,lethal:bool) -> Array[Texture2D]:
 var key:=plate.get_file().get_basename()
 if plate!=SOURCE+key+".png" or key not in ["unburied-u01","unburied-sinew","unburied-flesh"]:return []
 if not _cache.has(plate):
  var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(INDEX))
  if not data is Dictionary or not data.has(key):return []
  var signature:Dictionary=data[key]
  var path:=ART+key+"-reaction.png"
  if FileAccess.get_sha256(plate)!=signature.source or FileAccess.get_sha256(path)!=signature.sheet:return []
  var sheet:=Image.new()
  if sheet.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK or sheet.get_size()!=CELL*Vector2i(4,2) or sheet.get_format()!=Image.FORMAT_RGBA8:return []
  var hit:Array[Texture2D]=[];var fall:Array[Texture2D]=[]
  for i in 8:
   var frame:=sheet.get_region(Rect2i(Vector2i(i%4,i>>2)*CELL,CELL))
   var ink:=frame.get_used_rect()
   if ink.size.x<20 or ink.size.y<20 or ink.position.x<=0 or ink.position.y<=0 or ink.end.x>=CELL.x or ink.end.y>413:return []
   frame.generate_mipmaps()
   var tex:=ImageTexture.create_from_image(frame)
   tex.set_meta("undead_reaction",{"plate":plate,"kind":"hit" if i<4 else "lethal","frame":i%4,"ink":ink})
   if i<4:hit.append(tex)
   else:fall.append(tex)
  _cache[plate]={"hit":hit,"lethal":fall}
 return _cache[plate].lethal if lethal else _cache[plate].hit
