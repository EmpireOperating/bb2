extends RefCounted
## Registered ink in sprite pixels, not simulation or equipment data.
const FLIGHT := "res://map_visibility/bolt-ink.png"
const WIDTH := 77.0
const RISE := 18.0
const SOURCE_PIVOT := Vector2(158.5,19.5)
const LOCAL_TIP := Vector2i(77,10)
const TIPS := {"weapon/crossbow":Vector2i(395,191),"weapon/heavy-crossbow":Vector2i(395,192)}
const DEFINITIONS := {"crossbow":"weapon/crossbow","heavy_crossbow":"weapon/heavy-crossbow"}
static var _rest:Image

static func fitted(recipe:Dictionary) -> bool:
 return recipe.get("stance","")=="stock" and TIPS.has(recipe.get("weapon"))

static func stamp(im:Image,tip:Vector2i) -> bool:
 if _rest==null:
  var ink:=Image.new()
  if ink.load_png_from_buffer(FileAccess.get_file_as_bytes("res://engraved_people/stock-bolt.png"))!=OK:return false
  _rest=ink
 im.blend_rect(_rest,Rect2i(Vector2i.ZERO,_rest.get_size()),tip-LOCAL_TIP)
 return true
