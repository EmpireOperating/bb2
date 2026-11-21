extends RefCounted
## Authoring maps contain only indices into the exact live, already-worn paint.
## Compose the existing validated draw stack; palette, masks and UIDs stay live.
const ROOT := "res://painted_merge/hostile_motion/highwayman/"
const SOURCE := "res://painted_merge/bandits/assets/"
const CANVAS := Vector2i(704,887)
const SOLE := Vector2(333,866)
const TIMING := {
 "walk":[0.042,0.102,0.149,0.207,0.269,0.335,0.386],
 "attack":[0.060,0.137,0.237,0.319],
 "hit":[0.043,0.095,0.153,0.216],
}
const FALL_CUTS := 4
const MAX_MAP := 36000000
const SHORT_BLADE := ["sword.png","knife.png","cudgel.png","hatchet.png"]
static var _index:Dictionary={}
static var _maps:Dictionary={}
var _appearance
var _plan:Dictionary={}
var _valid:=false
var _layer_pixels:Dictionary={}
var _poses:Dictionary={}

# JSON numbers are float Variants. Array equality also compares element type;
# compare finite numeric coordinates exactly, never truncate to a pixel.
static func _xy(value:Variant,x:int,y:int) -> bool:
 if not value is Array or value.size()!=2:return false
 if typeof(value[0]) not in [TYPE_INT,TYPE_FLOAT] or typeof(value[1]) not in [TYPE_INT,TYPE_FLOAT]:return false
 return value[0]==x and value[1]==y

func bind(appearance,plan:Dictionary) -> void:
 if _plan==plan:return
 _appearance=appearance;_plan=plan
 _poses.clear();_layer_pixels.clear()
 _valid=false
 if plan.get("frame_key","") not in ["ordinary","round-shield"]:return
 var frame:Dictionary=plan.get("frame",{})
 var width:=704 if plan.frame_key=="round-shield" else 591
 if not _xy(frame.get("base_origin"),0,0) or not _xy(frame.get("stance_anchor"),333,866) or not _xy(frame.get("size"),width,887):return
 if plan.get("base",{}).get("path","")!=SOURCE+"layers/base.png":return
 if _index.is_empty():
  var data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"index.json"))
  if not data is Dictionary or not _xy(data.get("canvas"),704,887) or not _xy(data.get("anchor"),333,866):return
  _index=data
 for row:Dictionary in plan.layers:
  var path:String=row.path
  var hash:String=_index.refs.get(path.trim_prefix(SOURCE),"")
  if not path.begins_with(SOURCE) or hash.is_empty() or row.sha256!=hash or not _xy(row.offset,0,0):return
 if plan.get("closed_hand",false) and plan.get("foundation_keep_mask",{}).get("path","")!=SOURCE+"layers/hand-context-keep.png":return
 _valid=true

func admits(style:String) -> bool:
 if not _valid:return false
 if style!="attack":return true
 # No proxy for an unpainted/unfitted held weapon or a two-hand pike.
 for row:Dictionary in _plan.layers:
  if row.slot=="weapon" and row.path.get_file() in SHORT_BLADE:return _plan.closed_hand
 return false

static func frame_at(style:String,age:float) -> int:
 var ends:Array=TIMING.get(style,[])
 for i in ends.size():
  if age<ends[i]:return i
 return -1

static func _mapping(style:String) -> PackedInt32Array:
 if _maps.has(style):return _maps[style]
 var spec:Dictionary=_index.cuts.get(style,{})
 if spec.is_empty():return []
 var path:=ROOT+style+".gz"
 var size:=int(spec.bytes)
 if size<=0 or size>MAX_MAP or FileAccess.get_sha256(path)!=spec.sha256:return []
 var packed:=FileAccess.get_file_as_bytes(path).decompress(size,FileAccess.COMPRESSION_GZIP)
 if packed.size()!=size:return []
 var words:=packed.to_int32_array()
 _maps[style]=words
 return words

func _pixels(row:Dictionary) -> PackedInt32Array:
 var path:String=row.path
 if _layer_pixels.has(path):return _layer_pixels[path]
 # The same exact helpers used for the parent rest texture, and no writes to
 # their returned Image: both wear and source-native hand cuts are retained.
 var img:Image=_appearance._image(row)
 if img==null:return []
 if row.get("foundation",false) and _plan.closed_hand:
  var keep:Image=_appearance._image(_plan.foundation_keep_mask)
  if keep==null:return []
  img=_appearance._masked_foundation(img,keep)
 if row.tint!=[1.0,1.0,1.0]:img=_appearance._tinted(img,row.tint)
 var values:=img.get_data().to_int32_array()
 _layer_pixels[path]=values
 return values

func pose(style:String,frame:int) -> Texture2D:
 if frame<0 or not admits(style):return null
 var cached:Array=_poses.get(style,[])
 if frame<cached.size() and cached[frame]!=null:return cached[frame]
 var src:=_mapping(style)
 if src.is_empty():return null
 var out:=Image.create(CANVAS.x,CANVAS.y,false,Image.FORMAT_RGBA8)
 var spec:Dictionary=_index.cuts[style].layers
 for row:Dictionary in _plan.layers:
  var name:String=row.path.trim_prefix(SOURCE)
  var entries:Array=spec.get(name,[])
  if frame>=entries.size():return null
  var info:Array=entries[frame]
  var at:=Vector2i(int(info[1]),int(info[2]));var wh:=Vector2i(int(info[3]),int(info[4]))
  var start:=int(info[0])/4
  if start<0 or wh.x<=0 or wh.y<=0 or not Rect2i(Vector2i.ZERO,CANVAS).encloses(Rect2i(at,wh)) or start+wh.x*wh.y>src.size():return null
  var values:=_pixels(row)
  if values.is_empty():return null
  var paint:=PackedInt32Array();paint.resize(wh.x*wh.y)
  for i in paint.size():
   var key:=src[start+i]
   if key>0:paint[i]=values[key-1]
  var stamp:=Image.create_from_data(wh.x,wh.y,false,Image.FORMAT_RGBA8,paint.to_byte_array())
  out.blend_rect(stamp,Rect2i(Vector2i.ZERO,wh),at)
 var bounds:=out.get_used_rect()
 if not bounds.has_area():return null
 out.generate_mipmaps()
 var tex:=ImageTexture.create_from_image(out)
 tex.set_meta("legacy_pose",{"style":style,"frame":frame,"ink":bounds})
 if cached.size()<=frame:cached.resize(frame+1)
 cached[frame]=tex;_poses[style]=cached
 return tex

func fall_frames() -> Array[Texture2D]:
 var out:Array[Texture2D]=[]
 for i in FALL_CUTS:
  var cut:=pose("fall",i)
  if cut==null:return []
  out.append(cut)
 return out

static func set_texture(sprite:Sprite3D,tex:Texture2D,base_size:Vector2,base_offset:Vector2) -> void:
 if sprite==null or tex==null or sprite.texture==tex:return
 var center_shift:float=(tex.get_width()-base_size.x)*0.5
 sprite.offset=base_offset+Vector2(-center_shift if sprite.flip_h else center_shift,0)
 sprite.texture=tex
 sprite.material_override.set_shader_parameter("source_texture",tex)
 if sprite.has_meta("pick_alpha"):sprite.remove_meta("pick_alpha")
