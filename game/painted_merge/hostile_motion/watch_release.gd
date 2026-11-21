extends RefCounted
## Fixed expose-plate bow discharge. No paint for the invisible equipment.
const PLATE := "res://engraved_battle/hostiles/unburied-u01.png"
const PLATE_SHA := "d6a8b5ee925db9a06fdcd4186145b030094b6d6e7015e24578fb8552da853f01"
const ATLAS := "res://painted_merge/hostile_motion/watch-captain-release.png"
const ATLAS_SHA := "b66663cecec0e9fad2980b797a117ab2d7cb3a942f5bdc4aa473a46ce321315a"
const WEAPON := "hm_trial_v1:old24-archer_heavy"
const CELL := Vector2i(480,464)
# Existing instant contact is the first cut; the remaining cuts are follow-through.
const ENDS := [0.048,0.116,0.202,0.286]
static var _cuts: Array[Texture2D] = []

static func frames(plate:String) -> Array[Texture2D]:
 if plate!=PLATE:return []
 if not _cuts.is_empty():return _cuts
 if FileAccess.get_sha256(PLATE)!=PLATE_SHA or FileAccess.get_sha256(ATLAS)!=ATLAS_SHA:return []
 var sheet:=Image.new()
 if sheet.load_png_from_buffer(FileAccess.get_file_as_bytes(ATLAS))!=OK or sheet.get_size()!=Vector2i(CELL.x*ENDS.size(),CELL.y) or sheet.get_format()!=Image.FORMAT_RGBA8:return []
 for i in ENDS.size():
  var cut:=sheet.get_region(Rect2i(Vector2i(CELL.x*i,0),CELL))
  cut.generate_mipmaps();_cuts.append(ImageTexture.create_from_image(cut))
 return _cuts

static func index_at(age:float) -> int:
 for i in ENDS.size():
  if age<ENDS[i]:return i
 return -1
