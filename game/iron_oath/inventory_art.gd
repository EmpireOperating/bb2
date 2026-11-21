extends RefCounted
## A portrait is a read-only region of the actual fitted actor texture.
# Conservative source-coordinate envelopes of all six frozen heads, including
# hair/beards and every admitted hood/cap/helm. Resolved base_origin owns any
# expanded-canvas translation; names, weapons and stance feet are not face anchors.
const HEAD_FRAMES := {"archer":Rect2(65,10,78,75),"duelist":Rect2(114,13,82,78),"medic":Rect2(89,1,86,93),"occultist":Rect2(63,10,80,77),"polearm":Rect2(93,25,73,73),"shieldbearer":Rect2(98,8,82,88)}
static func portrait(texture: Texture2D, diagnostics: Dictionary) -> Texture2D:
 if texture == null:return null
 var frame: Dictionary = diagnostics.get("plan",{}).get("frame",{})
 var origin: Array = frame.get("base_origin",[0,0])
 var body: Array = frame.get("body_size",[256,320])
 var region := Rect2(float(origin[0])+float(body[0])*.20,float(origin[1]),float(body[0])*.62,float(body[1])*.39)
 region = region.intersection(Rect2(Vector2.ZERO,texture.get_size()))
 var atlas := AtlasTexture.new();atlas.atlas = texture;atlas.region = region
 var family := str(diagnostics.get("plan",{}).get("appearance",""))
 if HEAD_FRAMES.has(family):
  var head:Rect2=HEAD_FRAMES[family];head.position+=Vector2(origin[0],origin[1])
  atlas.set_meta("protected_head",head)
 return atlas

const ICON_LIMIT := 128 # 53 ordinary + 34 Named bindings / 32 Named paintings; never per-owner.
const CONCEPT_MANIFEST := "res://item_art/manifest.json"
const CONCEPT_MANIFEST_SHA256 := "29a9e04fa26ad3ef308872f17e40c2d17bb98bb73ebfbaed3450a3c2695a215d"
const STOCK_QUIVERS := ["arrows","bodkin_quiver","deep_quiver"]
const Named = preload("res://src/named_equipment.gd")
const NAMED_MANIFEST := "res://named_gear/manifest.json"
const NAMED_MANIFEST_SHA256 := "d60f232c3c70ca3e9de859c912ed97da3809ee1d12a8857d4b4a19115ec50e5b"
static var _icons := {}
static var _concepts := {}
static var _named_concepts := {}
## Standalone artwork follows the literal definition and validated Named craftsmanship.
## Ordinary rarity, actor, condition, owner and UI selection never choose artwork.
## Legacy resolver/appearance arguments remain accepted but intentionally unused.
static func item_icon(item: Dictionary, catalog: Dictionary, _resolver = null, _appearance = "") -> Dictionary:
 var definition = item.get("definition")
 if not definition is String or definition.is_empty():return {}
 var is_named := item.has("named")
 if is_named and not Named.valid(item,catalog):return {}
 if not is_named and definition in ["crossbow","heavy_crossbow","bolts"]:
  return preload("res://crossbows/art/assets.gd").item_icon(item,catalog)
 var manifest_path: String = NAMED_MANIFEST if is_named else CONCEPT_MANIFEST
 var manifest_hash: String = NAMED_MANIFEST_SHA256 if is_named else CONCEPT_MANIFEST_SHA256
 var schema: String = "bb2-named-item-art-v1" if is_named else "bb2-generic-item-art-v1"
 # Hash the same bounded bytes we parse; revalidate the manifest even on warm hits.
 if not FileAccess.file_exists(manifest_path):return {}
 var manifest_file := FileAccess.open(manifest_path,FileAccess.READ)
 if manifest_file == null or manifest_file.get_length() > 65536:return {}
 var manifest_bytes := manifest_file.get_buffer(manifest_file.get_length())
 if manifest_bytes.is_empty():return {} # HashingContext.update rejects empty chunks.
 var hash := HashingContext.new()
 hash.start(HashingContext.HASH_SHA256);hash.update(manifest_bytes)
 if hash.finish().hex_encode() != manifest_hash:return {}
 var concepts: Dictionary = _named_concepts if is_named else _concepts
 if concepts.is_empty():
  var manifest = JSON.parse_string(manifest_bytes.get_string_from_utf8())
  if not manifest is Dictionary or manifest.get("schema") != schema:return {}
  if not manifest.get("definitions") is Dictionary:return {}
  concepts = manifest.definitions
  if is_named:_named_concepts = concepts
  else:_concepts = concepts
 var entry: Dictionary = concepts.get(definition,{})
 if entry.is_empty():return {} # Literal allowlist only: no stock/family substitutions.
 var actual = catalog.get(definition)
 if not actual is Dictionary:return {}
 if entry.get("catalog_binding","") == "stock_arrow_quiver":
  if definition not in STOCK_QUIVERS or actual.has("donor_definition"):return {}
  if not actual.get("slot") is String or actual.slot != "ammo":return {}
  if not actual.get("ammo") is String or actual.ammo != "arrows":return {}
 elif entry.get("catalog_binding","") == "authored_ringbound_maul":
  # This is a native authored definition, not a donor alias or the legacy maul.
  if is_named or definition != "hm_trial_v1:twohand_maul" or actual.get("campaign_adopted",false)!=true or actual.has("donor_definition"):return {}
  if not actual.get("slot") is String or actual.slot!="weapon":return {}
  if not actual.get("weapon") is String or actual.weapon!=definition:return {}
 else:
  if not actual.get("donor_definition") is String:return {}
  if actual.donor_definition != entry.donor_definition:return {}
 var path: String = entry.source_path
 if not FileAccess.file_exists(path):return {}
 var source_file := FileAccess.open(path,FileAccess.READ)
 if source_file == null or source_file.get_length() > 16777216:return {}
 var bytes := source_file.get_buffer(source_file.get_length())
 if bytes.is_empty():return {}
 hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
 if hash.finish().hex_encode() != entry.source_sha256:return {}
 # Validate the current source before looking up its shared immutable Texture2D.
 var key: String = path+":"+entry.source_sha256
 if not _icons.has(key):
  var image := Image.new()
  if image.load_png_from_buffer(bytes) != OK:return {}
  if image.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]:return {}
  if image.get_width() != int(entry.source_dimensions[0]) or image.get_height() != int(entry.source_dimensions[1]):return {}
  image.generate_mipmaps() # No crop, alpha extraction, color conversion or composition.
  _icons[key] = ImageTexture.create_from_image(image)
  if _icons.size() > ICON_LIMIT:_icons.erase(_icons.keys()[0])
 return {"texture":_icons[key],"source_kind":"named_concept" if is_named else "generic_concept","source_path":path,"definition":definition,"donor_definition":entry.donor_definition,"art_key":entry.art_key}
