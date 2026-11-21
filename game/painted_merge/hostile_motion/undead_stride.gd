extends RefCounted
## Registered 480×464 whole-body cuts, selected by the resolved live base plate.
## The non-looping cadence covers the existing 0.42 s endpoint tween; exact idle
## restoration belongs to that tween's completion, not a second animation clock.
const SOURCE := "res://engraved_battle/hostiles/"
const ART := "res://painted_merge/hostile_motion/"
const CELL := Vector2i(480,464)
const HASHES := {
 "unburied-u01":"59a2fdcaf122cd38f38cf49809a12448bf1df1c768343aa7cf42645862b90232",
 "unburied-sinew":"9f0229536552308e781c33ff4803dfb7f9196061ef61f446dde62486e1f9584f",
 "unburied-flesh":"046b59e7aaca2b7dca14adf9b8aee1f175ac658d87eab47a5668b7f268c48bf8",
}
const ENDS := [0.038,0.098,0.144,0.188,0.253,0.304,0.354]
static var _cache: Dictionary = {}

static func frame_at(seconds: float) -> int:
 for i in ENDS.size():
  if seconds<ENDS[i]:return i
 return ENDS.size()

static func load_frames(key: String) -> Array[Texture2D]:
 var name:=key.get_file().get_basename()
 if key!=SOURCE+name+".png" or not HASHES.has(name):return []
 if _cache.has(key):return _cache[key]
 var path:=ART+name+"-walk.png"
 if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=HASHES[name]:return []
 var sheet:=Image.new()
 if sheet.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK or sheet.get_size()!=CELL*Vector2i(4,2) or sheet.get_format()!=Image.FORMAT_RGBA8:return []
 var frames: Array[Texture2D]=[]
 for i in 8:
  var frame:=sheet.get_region(Rect2i(Vector2i(i%4,i>>2)*CELL,CELL))
  frame.generate_mipmaps();frames.append(ImageTexture.create_from_image(frame))
 _cache[key]=frames
 return frames
