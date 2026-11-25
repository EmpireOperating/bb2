extends RefCounted
## Paint only. No action state, timing, equip changes, rotation, or offsets.
const RingboundMaul = preload("res://engraved_people/ringbound_maul.gd")
const Wear = preload("res://engraved_people/named_wear.gd")
const PATH := "res://engraved_people/utility-cuts"
const FRAME_COUNT := 2
const HELD_FRAME := 1
const SIZE := Vector2i(480,464)
const KINDS := ["brace","riposte","guard","recover","switch","guard_spear","indomitable"]
const REQUIRED_RECIPE := ["stance","body","head","cloak","belt","hands","feet","weapon","shield","head_wear","body_wear","shield_wear"]
static var _data: Dictionary
static var _atlas: Image
static var _textures: Dictionary

static func _ready() -> bool:
 if _atlas!=null:return true
 if not FileAccess.file_exists(PATH+".json") or not FileAccess.file_exists(PATH+".png"):return false
 var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH+".json"))
 if not parsed is Dictionary or parsed.get("version")!=1:return false
 for field:String in ["fits","rows","shields","cuts"]:
  if not parsed.get(field) is Dictionary:return false
 var ink:=Image.new()
 if ink.load_png_from_buffer(FileAccess.get_file_as_bytes(PATH+".png"))!=OK:return false
 ink.convert(Image.FORMAT_RGBA8)
 _data=parsed
 _atlas=ink
 return true

static func _head_shift(row:Dictionary) -> Vector2i:
 var xy:Array=row.get("head",[0,0])
 return Vector2i(int(xy[0]),int(xy[1]))

static func _paint(im:Image, rect:Array, shift:Vector2i) -> void:
 im.blend_rect(_atlas,Rect2i(int(rect[2]),int(rect[3]),int(rect[4]),int(rect[5])),Vector2i(int(rect[0]),int(rect[1]))+shift)

static func _promote(cuts:Array, prefixes:Array, anchor:String) -> void:
 for prefix:String in prefixes:
  for cut:String in cuts.duplicate():
   if cut.begins_with(prefix):
    cuts.erase(cut)
    cuts.insert(cuts.find(anchor),cut)

static func compose(r:Dictionary, kind:String, frame:int, plates:Dictionary, plan:Callable, stamp:Callable) -> Texture2D:
 if kind not in KINDS or frame<0 or frame>=FRAME_COUNT or not r.get("face") is int or r.face<0 or r.face>=8:return null
 for field:String in REQUIRED_RECIPE:
  if not r.get(field) is String:return null
 for field:String in ["under_body","under_wear","ammo"]:
  if r.has(field) and not r[field] is String:return null
 if not _ready():return null
 if _data.fits.get(r.weapon,"missing")!=r.stance:return null
 if not r.shield.is_empty() and (r.stance!="single" or r.weapon in plates.single_left_bows or not _data.shields.guard.has(r.shield)):return null
 var both:=kind=="guard_spear"
 var fortified:=kind=="indomitable"
 if (kind=="guard" or both) and r.shield.is_empty():return null
 var lane:="brace" if both else ("switch_shield" if kind=="switch" and not r.shield.is_empty() else kind)
 var rows:Array=[{},{}] if fortified else _data.rows[lane].get("" if kind=="guard" else r.weapon,[])
 if rows.size()!=FRAME_COUNT:return null
 # The far weapon arm keeps the authored forward hold during Shieldwall's
 # rise and hold; the independent shield forearm uses the fitted Guard cuts.
 var row:Dictionary=rows[1 if both else frame]
 var shield_rows:Array=_data.shields.get("guard" if both or fortified else kind,{}).get(r.shield,[])
 var shield_row:Dictionary=shield_rows[frame] if shield_rows.size()==FRAME_COUNT else {}
 var key:=JSON.stringify([r,kind,frame])
 if _textures.has(key):return _textures[key]
 var current:Array=plan.call(r,false)
 var legs:="legs/%s/-1" % r.feet
 var ammo:String=r.get("ammo","")
 var ammo_fill:=int(r.get("ammo_fill",0)) if r.get("ammo_fill",0) is int else 0
 var stack:String="%s/%d" % [ammo,ammo_fill] if not ammo.is_empty() and ammo_fill>0 else ""
 for cut:String in [r.cloak,ammo,stack,legs]+current:
  if not cut.is_empty() and not plates.cuts.has(cut):return null
 var paint:Dictionary=row.get("ink",{}).duplicate()
 paint.merge(shield_row.get("ink",{}),true)
 var face:="face/%d/%s" % [r.face,"hair" if r.head.is_empty() else "shorn"]
 var shift:=Vector2i(0,int(plates.hip_y[0]))
 var load:=Vector2i(-4,3) if frame==0 else Vector2i(-9,9)
 if not fortified:load=Vector2i.ZERO
 var head_shift:Vector2i=(Vector2i(-7,7) if frame==0 else Vector2i(-18,19)) if fortified else _head_shift(row)
 var prefixes:Array=row.get("above_belt",[])+shield_row.get("above_belt",[])
 _promote(current,prefixes,face)
 if row.get("over_shield",false) and not r.shield.is_empty():
  for cut:String in current:
   if cut.begins_with("single/right/grip/sleeve/"):
    current.erase(r.shield)
    if not r.shield_wear.is_empty():current.erase(r.shield_wear)
    var at:=current.find(cut)
    current.insert(at,r.shield)
    if not r.shield_wear.is_empty():current.insert(at+1,r.shield_wear)
    break
 var im:=Image.create_empty(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
 # Inherited idle order. Cloak and carriers ride behind stationary legs.
 stamp.call(im,r.cloak,shift)
 stamp.call(im,ammo,shift)
 stamp.call(im,stack,shift)
 stamp.call(im,legs,Vector2i.ZERO)
 var seated:bool=r.get("seated_bolt",false)==true and row.has("bolt_socket")
 for cut:String in current:
  if cut.is_empty():continue
  # Load the torso/arms forward without scaling the legs or cutting pieces
  # off the actual gear. The belt and lowest layers remain registered.
  var upper:=load if cut!=r.belt else Vector2i.ZERO
  if cut==r.weapon and RingboundMaul.stamp(im,r,lane if paint.has(cut) else "carry",frame if paint.has(cut) else 0,shift+upper):continue
  if paint.has(cut):
   var id:int=int(paint[cut])
   if id>=0 and not Wear.stamp(im,cut,shift+upper,r,"utility/%s/%d" % [lane,1 if both else frame]):
    _paint(im,_data.cuts[str(id)],shift+upper)
  else:
   var stamp_shift:=shift+head_shift if cut in [face,r.head,r.head_wear] else shift+upper
   stamp.call(im,cut,stamp_shift)
  if cut==r.weapon and seated:_paint(im,_data.cuts[str(int(paint["$bolt"]))],shift)
 im.generate_mipmaps()
 var texture:=ImageTexture.create_from_image(im)
 texture.set_meta("engraved_head",Wear.head_recipe(r))
 texture.set_meta("utility_pose",{"kind":"guard" if both else kind,"spearwall":both,"frame":frame,"frames":FRAME_COUNT,"held":HELD_FRAME,"weapon":r.weapon,"shield":r.shield})
 if not r.shield.is_empty():
  var plate:Array=plates.cuts[r.shield]
  var d:Array=shield_row.get("offset",[0,0])
  var center:=Vector2(float(plate[0])+float(plate[4])*0.5+float(d[0]),float(plate[1])+float(plate[5])*0.5+float(d[1]))+Vector2(shift+load)
  texture.set_meta("fitted_shield",{"part":r.shield,"center":center,"worn":not r.shield_wear.is_empty()})
 if row.has("bolt_socket"):
  var bolt:Array=row.bolt_socket
  var socket:=Vector2(float(bolt[0]),float(bolt[1]))+Vector2(shift)
  texture.set_meta("stock_bolt_socket",socket)
  if seated:texture.set_meta("stock_bolt_tip",socket)
 if _textures.size()>=40:_textures.erase(_textures.keys()[0])
 _textures[key]=texture
 return texture
