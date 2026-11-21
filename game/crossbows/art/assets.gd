extends RefCounted
## Exact stock-definition art only; no family/cosmetic aliases or authority writes.
const MANIFEST := "res://crossbows/art/manifest.json"
const MANIFEST_SHA := "4a089c90837816448e6759ba1bccbb871fa27a2bb216d40ee62fb10eea6a4143"
const IDS := ["crossbow","heavy_crossbow","bolts"]
static var _textures := {}
static var _images := {}
static func manifest() -> Dictionary:
 var bytes := _bytes(MANIFEST,65536)
 if bytes.is_empty() or _sha(bytes)!=MANIFEST_SHA:return {}
 var parsed = JSON.parse_string(bytes.get_string_from_utf8())
 if not parsed is Dictionary or parsed.get("schema")!="bb2-crossbow-art-v1":return {}
 return parsed
static func _bytes(path: String, limit: int) -> PackedByteArray:
 if not FileAccess.file_exists(path):return PackedByteArray()
 var file := FileAccess.open(path,FileAccess.READ)
 if file==null or file.get_length()>limit:return PackedByteArray()
 return file.get_buffer(file.get_length())
static func _sha(bytes: PackedByteArray) -> String:
 if bytes.is_empty():return ""
 var hash := HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
 return hash.finish().hex_encode()
static func image(row: Dictionary) -> Image:
 var path: String=row.get("path","")
 if not path.begins_with("res://crossbows/art/") or ".." in path:return null
 var bytes := _bytes(path,16777216)
 if bytes.is_empty() or _sha(bytes)!=row.get("sha256",""):return null
 var key: String=path+":"+row.sha256
 if not _images.has(key):
  var decoded := Image.new()
  if decoded.load_png_from_buffer(bytes)!=OK or decoded.get_format()!=Image.FORMAT_RGBA8:return null
  var dims: Array=row.get("dimensions",[])
  if dims.size()!=2 or decoded.get_size()!=Vector2i(int(dims[0]),int(dims[1])):return null
  if _images.size()>=64:_images.erase(_images.keys()[0])
  _images[key]=decoded
 return _images[key].duplicate()
static func item_icon(item: Dictionary, catalog: Dictionary) -> Dictionary:
 var definition = item.get("definition")
 if not definition is String or definition not in IDS:return {}
 var book := manifest()
 if book.is_empty():return {}
 var row: Dictionary=book.icons.get(definition,{})
 var actual = catalog.get(definition)
 if row.is_empty() or not actual is Dictionary:return {}
 if actual.get("slot")!=row.slot or actual.get(row.identity_field)!=row.identity_value:return {}
 var source := image(row)
 if source==null:return {}
 var key: String=row.path+":"+row.sha256
 if not _textures.has(key):source.generate_mipmaps();_textures[key]=ImageTexture.create_from_image(source)
 return {"texture":_textures[key],"source_kind":"generic_concept","source_path":row.path,"definition":definition,"donor_definition":"","art_key":"crossbow-painted-"+definition}
