extends RefCounted
## Presentation of already validated physical armor_parts. No fitting or stat rules.
const Catalog = preload("res://hollow_campaign/catalog.gd")
const Named = preload("res://src/named_equipment.gd")
const NamedMail = preload("res://layer_forge/named_mail.gd")
const PROFILE := "ashen-company-layer-forge"
const ROOT := "res://layer_forge/art/"
const SIZE := Vector2i(480,464)
const BODY_ORDER := ["base","mail","outer","cloth","cloak","reinforce","seal"]
const HEAD_ORDER := ["padding","shell","face","decor","favor","seal"]
# Virtual cuts participate in the existing pose order, never the old atlas.
const BACK := "@forge/back"
const BODY_FRONT := "@forge/body"
const HEAD_FRONT := "@forge/head"
const NEAR := 1
const FAR := 2
# Fitted sleeve paint is registered to the single-grip carry. Do not leave
# those cuffs hanging in space when the active arm changes pose.
const NEAR_INSET := 182
const FAR_LIMIT := 296
const FOREARM_LIMIT := 249
const RAW_ID_CHARS := "abcdefghijklmnopqrstuvwxyz0123456789_"
const MAX_FILE_BYTES := 1048576
const SOURCE_LIMIT := 80 # Shared bounded cache for primary/optional cuts, including misses.
const WEAR_LIMIT := 32
static var _catalog: Dictionary = {}
static var _source: Dictionary = {}
static var _wear: Dictionary = {}

static func applies(unit: Dictionary) -> bool:
 return (ProjectSettings.get_setting("application/config/use_custom_user_dir",false)
  and ProjectSettings.get_setting("application/config/custom_user_dir_name","")==PROFILE
  and unit.get("side",-1) in [0,1]
  and unit.get("faction","")!="undead" and str(unit.get("undead_kind","")).is_empty())

static func bind(d: Dictionary, parts: Variant, claimed_mail: String = "") -> void:
 # No Forge description ever carries the authored legacy torso, helmet, cloak,
 # gloves, belt, or footwear. The actor recipe retains its neutral feet/sleeves.
 d.recipe.body=BODY_FRONT
 d.recipe.cloak=BACK
 d.recipe.head_wear=HEAD_FRONT
 d.recipe.forge_body=[]
 d.recipe.forge_head=[]
 if not parts is Array or parts.is_empty():return
 if _catalog.is_empty():_catalog=Catalog.equipment()
 var slots: Dictionary = {}
 var seen_uids: Dictionary = {}
 for part: Variant in parts:
  if not part is Dictionary:continue
  var group: Variant=part.get("group")
  var layer: Variant=part.get("layer")
  var definition: Variant=part.get("definition")
  var uid: Variant=part.get("item",part.get("id"))
  if not group is String or not layer is String or not definition is String or not uid is String or uid.is_empty():continue
  if group not in ["body","head"] or layer not in (BODY_ORDER if group=="body" else HEAD_ORDER):continue
  var slot: String=group+"/"+layer
  # Duplicate slots/UIDs are impossible in validated data. Never pick a winner
  # by input order if a malformed projection does reach presentation.
  if slots.has(slot):slots[slot]={}
  else:slots[slot]=part
  seen_uids[uid]=int(seen_uids.get(uid,0))+1
 for group: String in ["body","head"]:
  var order: Array=BODY_ORDER if group=="body" else HEAD_ORDER
  for layer: String in order:
   var slot: String=group+"/"+layer
   var part: Dictionary=slots.get(slot,{})
   if part.is_empty():continue
   var uid: String=part.get("item",part.get("id"))
   if seen_uids[uid]!=1 or (part.has("id") and part.id!=uid):continue
   _bind_piece(d,part,group,layer,slot,uid,claimed_mail)

static func _bind_piece(d: Dictionary, part: Dictionary, group: String, layer: String, slot: String, uid: String, claimed_mail: String) -> void:
 var id: String=part.definition
 var condition: Variant=part.get("condition")
 var maximum: Variant=part.get("maximum")
 var entry := {"definition":id,"item":uid,"condition":condition if condition is int else 0,"maximum":maximum if maximum is int else 0,"visible":false,"painted":false}
 d.signature[slot]=entry
 var stencil := _stem(id,group)
 # Owned parts carry a possibly rolled maximum; compare the same effective
 # definition the domain used to project it, never the ordinary base maximum.
 var named_mail: bool = part.has("named") and NamedMail.valid_projection(part,_catalog,claimed_mail)
 var definition: Dictionary=Named.definition(part,_catalog) if not stencil.is_empty() and (not part.has("named") or named_mail) else {}
 if definition.get("group")!=group or definition.get("slot")!=group or definition.get("layer")!=layer or not condition is int or not maximum is int or maximum<0 or condition<0 or condition>maximum or maximum!=int(definition.get("durability",-1)):
  _omit(d,slot,entry,"No validated Forge definition/wear for this physical layer.")
  return
 var front := NamedMail.FRONT if named_mail else stencil+".png"
 var back := "" if named_mail else stencil+"_back.png"
 var cut := _source_cut(front)
 if cut.is_empty():
  _omit(d,slot,entry,"Missing or invalid Named mail PNG; no ordinary substitute." if named_mail else "Missing or invalid Forge wear PNG; no legacy substitute.")
  return
 var behind: Dictionary = {} if back.is_empty() else _source_cut(back)
 var has_front: bool=cut.has("image")
 var has_back: bool=behind.has("image")
 if not has_front and not has_back:
  _omit(d,slot,entry,"Forge wear PNG has no visible ink.")
  return
 var stage: int=0 if maximum==0 or condition>maximum/2.0 else 2 if condition==0 else 1
 entry.visible=true;entry.painted=true;entry.asset=front if has_front else back
 if has_front and group=="head" and layer in ["padding","shell"]:
  # These opaque scalp fittings use the donor's shorn anatomy (not a helmet
  # cut). Bare or missing fittings leave the original neutral hair intact.
  d.recipe.head=HEAD_FRONT
  d.recipe.head_wear=""
 # Only pixels enter the texture key. Diagnostics keep exact condition and UID;
 # same-paint exchanges and wear changes within one visual band share a texture.
 var wardrobe: Array=d.recipe["forge_"+group]
 wardrobe.append({"front":front if has_front else "","back":back if has_back else "","wear":stage,"layer":layer})

static func _omit(d: Dictionary, slot: String, entry: Dictionary, reason: String) -> void:
 d.issues.append({"slot":slot,"uid":entry.item,"definition":entry.definition,"reason":reason})

static func _stem(id: String, group: String) -> String:
 if not id.begins_with("forge:"):return ""
 var raw := id.substr(6)
 if raw.is_empty() or raw.length()>64 or raw.ends_with("_back") or raw.ends_with("_icon"):return ""
 for i: int in raw.length():
  if not RAW_ID_CHARS.contains(raw[i]):return ""
 return ROOT+group+"/"+raw

static func _be32(bytes: PackedByteArray, offset: int) -> int:
 return (int(bytes[offset])<<24)|(int(bytes[offset+1])<<16)|(int(bytes[offset+2])<<8)|int(bytes[offset+3])

static func _read_cut(path: String) -> Dictionary:
 if not FileAccess.file_exists(path):return {}
 var file := FileAccess.open(path,FileAccess.READ)
 if file==null:return {}
 var size := file.get_length()
 if size<33 or size>MAX_FILE_BYTES:return {}
 var bytes := file.get_buffer(size)
 if bytes.size()!=size:return {}
 # Check IHDR before decoding, so a tiny wrong-size PNG cannot allocate a
 # large canvas. Assets are raw ZIP members, not imported Texture2Ds.
 if _be32(bytes,0)!=0x89504e47 or _be32(bytes,4)!=0x0d0a1a0a or _be32(bytes,8)!=13 or _be32(bytes,12)!=0x49484452:return {}
 if _be32(bytes,16)!=SIZE.x or _be32(bytes,20)!=SIZE.y or bytes[24]!=8 or bytes[25]!=6:return {}
 var im := Image.new()
 if im.load_png_from_buffer(bytes)!=OK or im.get_size()!=SIZE:return {}
 im.convert(Image.FORMAT_RGBA8)
 var ink := im.get_used_rect()
 if not ink.has_area():return {"rect":ink} # Valid transparent front can accompany a back.
 return {"rect":ink,"image":im.get_region(ink)}

static func _source_cut(path: String) -> Dictionary:
 if _source.has(path):return _source[path]
 if _source.size()>=SOURCE_LIMIT:_source.erase(_source.keys()[0])
 var loaded := _read_cut(path)
 _source[path]=loaded
 return loaded

static func _weathered(path: String, stage: int, clean: Image) -> Image:
 if stage==0:return clean
 var key := "%s:%d" % [path,stage]
 if _wear.has(key):return _wear[key]
 var rgba := clean.get_data()
 # Subtle grime at half wear, stronger darkening when spent. Preserve every
 # alpha cell, especially a spent foundation that still clothes the wearer.
 var gain: float=0.78 if stage==1 else 0.55
 for i: int in range(0,rgba.size(),4):
  rgba[i]=int(rgba[i]*gain)
  rgba[i+1]=int(rgba[i+1]*gain)
  rgba[i+2]=int(rgba[i+2]*gain)
 var ink := Image.create_from_data(clean.get_width(),clean.get_height(),false,Image.FORMAT_RGBA8,rgba)
 if _wear.size()>=WEAR_LIMIT:_wear.erase(_wear.keys()[0])
 _wear[key]=ink
 return ink

static func _blend(im: Image, ink: Image, dst: Rect2i, clip: Rect2i) -> void:
 var clipped := dst.intersection(clip)
 if clipped.has_area():im.blend_rect(ink,Rect2i(clipped.position-dst.position,clipped.size),clipped.position)

static func stamp_accessory(im: Image, recipe: Dictionary, layer: String, suffix: String, shift: Vector2i) -> bool:
 # Only an already-bound Body I/VI owner can supply optional material.
 # A missing cut adds no issue or new recipe state. The existing path and
 # wear band identify all this owner's pixels, including their accessories.
 for row: Dictionary in recipe.get("forge_body",[]):
  if row.layer!=layer:continue
  var stem: String=row.front.trim_suffix(".png") if not row.front.is_empty() else row.back.trim_suffix("_back.png")
  var path := stem+suffix+".png"
  var cut := _source_cut(path)
  if not cut.has("image"):return false
  var dst: Rect2i=cut.rect
  dst.position+=shift
  _blend(im,_weathered(path,row.wear,cut.image),dst,Rect2i(Vector2i.ZERO,im.get_size()))
  return true
 return false

static func _paint(im: Image, rows: Array, field: String, shift: Vector2i, sleeves: int = -1) -> void:
 var bounds := Rect2i(Vector2i.ZERO,im.get_size())
 for row: Dictionary in rows:
  var path: String=row[field]
  if path.is_empty():continue
  var cut := _source_cut(path)
  if not cut.has("image"):continue
  var dst: Rect2i=cut.rect
  dst.position+=shift
  if not dst.intersects(bounds):continue
  var ink := _weathered(path,row.wear,cut.image)
  if sleeves<0 or sleeves==(NEAR|FAR) or row.layer not in ["base","reinforce"]:
   _blend(im,ink,dst,bounds)
   continue
  var left: int=NEAR_INSET if (sleeves&NEAR)==0 else 0
  var right: int=FAR_LIMIT if (sleeves&FAR)==0 else SIZE.x
  var upper := Rect2i(shift+Vector2i(left,0),Vector2i(right-left,FOREARM_LIMIT))
  var lower := Rect2i(shift+Vector2i(0,FOREARM_LIMIT),Vector2i(SIZE.x,SIZE.y-FOREARM_LIMIT))
  _blend(im,ink,dst,upper.intersection(bounds))
  _blend(im,ink,dst,lower.intersection(bounds))

static func stamp(im: Image, key: String, shift: Vector2i, recipe: Dictionary, sleeves: int) -> bool:
 match key:
  BACK:
   _paint(im,recipe.get("forge_body",[]),"back",shift)
   _paint(im,recipe.get("forge_head",[]),"back",shift)
  BODY_FRONT:_paint(im,recipe.forge_body,"front",shift,sleeves)
  HEAD_FRONT:_paint(im,recipe.forge_head,"front",shift)
  _:return false
 return true
