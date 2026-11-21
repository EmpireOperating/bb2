extends RefCounted
## Alternate weapon-only ink. The stock part still owns motion, depth and fit.
const PART := "weapon/head-maul62"
const PATH := "res://engraved_people/ringbound-cuts"
const COUNTS := {"carry":1,"maul_overhead":11,"shatter_armour":7,"recover":2,"switch":2,"collapse":1}
static var _atlas: Image
static var _rows := {}
static var _attempted := false

static func matches(recipe: Dictionary) -> bool:
 # Set by Actors._read only for the exact physical authored definition.
 return recipe.get("tier_one_maul_motion",false)==true and recipe.get("weapon","")==PART and recipe.get("stance","")=="paired"

static func _ready() -> bool:
 if _attempted:return _atlas!=null
 _attempted=true
 if not FileAccess.file_exists(PATH+".json") or not FileAccess.file_exists(PATH+".png"):return false
 var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH+".json"))
 if not raw is Dictionary or raw.size()!=COUNTS.size():return false
 var atlas:=Image.new()
 if atlas.load_png_from_buffer(FileAccess.get_file_as_bytes(PATH+".png"))!=OK:return false
 atlas.convert(Image.FORMAT_RGBA8)
 var limits:=Rect2i(Vector2i.ZERO,atlas.get_size())
 var rows: Dictionary={}
 for group: String in COUNTS:
  var cuts: Variant=raw.get(group)
  if not cuts is Array or cuts.size()!=COUNTS[group]:return false
  var ready: Array=[]
  for row: Variant in cuts:
   if not row is Array or row.size()!=6:return false
   for value: Variant in row:
    if not (value is int or value is float) or not is_finite(value) or value!=int(value):return false
   var rect:=Rect2i(int(row[2]),int(row[3]),int(row[4]),int(row[5]))
   if not rect.has_area() or not limits.encloses(rect):return false
   ready.append({"at":Vector2i(int(row[0]),int(row[1])),"rect":rect})
  rows[group]=ready
 _rows=rows;_atlas=atlas
 return true

static func stamp(im: Image, recipe: Dictionary, group: String, index: int, shift: Vector2i) -> bool:
 if not matches(recipe) or not COUNTS.has(group) or index<0 or index>=COUNTS[group] or not _ready():return false
 var row: Dictionary=_rows[group][index]
 var at: Vector2i=row.at+shift
 var rect: Rect2i=row.rect
 if not Rect2i(Vector2i.ZERO,im.get_size()).encloses(Rect2i(at,rect.size)):return false
 im.blend_rect(_atlas,rect,at)
 return true

static func collapse_source() -> Dictionary:
 if not _ready():return {}
 var row: Dictionary=_rows.collapse[0]
 return {"key":PART,"at":row.at,"im":_atlas.get_region(row.rect)}
