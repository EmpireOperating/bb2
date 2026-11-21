extends RefCounted
## Allowlisted absolute plate recipes. No synthesized fallback for unknown paint.
const Registry = preload("res://painted_merge/hostile_motion/registry.gd")
const FAMILIES = Registry.FAMILIES
static var _cache: Dictionary = {}

static func load_frames(key:String) -> Array:
 if _cache.has(key):return _cache[key]
 var spec:Dictionary=FAMILIES.get(key,{})
 if spec.is_empty() or not FileAccess.file_exists(spec.path) or FileAccess.get_sha256(spec.path)!=spec.sha256:return []
 var source:=Image.new()
 if source.load_png_from_buffer(FileAccess.get_file_as_bytes(spec.path))!=OK:return []
 var size:=Vector2i(int(spec.width),int(spec.height))
 var columns:int=int(spec.columns)
 var count:int=spec.ends.size()
 if size.x<=0 or size.y<=0 or columns<1 or count<2:return []
 if source.get_size()!=Vector2i(size.x*columns,size.y*ceili(float(count)/columns)):return []
 var frames:Array=[]
 # Stop frames use the original preview object, not a duplicate atlas texture.
 for index in count-1:
  var frame:=source.get_region(Rect2i(Vector2i(index%columns,floori(float(index)/columns))*size,size))
  frame.generate_mipmaps();frames.append(ImageTexture.create_from_image(frame))
 _cache[key]=frames
 return frames
