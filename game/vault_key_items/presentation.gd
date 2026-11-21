extends RefCounted
## Read-only view of the canonical key ledger. Never a physical equipment UID.
const ART_PATH := "res://vault_key_items/art/vault-key.png"
const MANIFEST_PATH := "res://vault_key_items/art/manifest.json"
static var _texture: Texture2D
static var _source_hash := ""

static func artwork() -> Texture2D:
 # Validate current bytes even on a warm hit; absence never poisons the cache.
 if not FileAccess.file_exists(MANIFEST_PATH) or not FileAccess.file_exists(ART_PATH):return null
 var manifest_file := FileAccess.open(MANIFEST_PATH,FileAccess.READ)
 if manifest_file == null or manifest_file.get_length() < 1 or manifest_file.get_length() > 65536:return null
 var parser := JSON.new()
 if parser.parse(manifest_file.get_as_text()) != OK:return null
 var manifest = parser.data
 if not manifest is Dictionary or manifest.get("schema") != "bb2-vault-key-art-v1" or manifest.get("source_path") != ART_PATH:return null
 if not manifest.get("source_sha256") is String:return null
 var dimensions = manifest.get("source_dimensions")
 if not dimensions is Array or dimensions.size() != 2:return null
 for dimension in dimensions:
  if typeof(dimension) not in [TYPE_INT,TYPE_FLOAT]:return null
  if not is_finite(float(dimension)) or float(dimension) != floorf(float(dimension)) or dimension < 1 or dimension > 8192:return null
 if dimensions[0] != dimensions[1]:return null
 var source_file := FileAccess.open(ART_PATH,FileAccess.READ)
 if source_file == null or source_file.get_length() < 24 or source_file.get_length() > 16777216:return null
 var bytes := source_file.get_buffer(source_file.get_length())
 if bytes.size() < 24 or bytes.slice(0,8) != PackedByteArray([137,80,78,71,13,10,26,10]):return null
 var hash := HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
 var digest := hash.finish().hex_encode()
 if digest != manifest.source_sha256:return null
 var expected_size := Vector2i(int(dimensions[0]),int(dimensions[1]))
 if _texture != null and _source_hash == digest and _texture.get_size() == Vector2(expected_size):return _texture
 var image := Image.new()
 if image.load_png_from_buffer(bytes) != OK or image.is_empty() or image.get_size() != expected_size:return null
 _texture = ImageTexture.create_from_image(image);_source_hash = digest
 return _texture

static func row(c, id: String) -> Dictionary:
 var record: Dictionary = c.dungeons.vault_keys.records.get(id,{})
 if not record.get("held",false):return {}
 var target: Dictionary = c.dungeons.Keys.targets(c.dungeons.sites).get(id,{})
 if target.is_empty():return {}
 var site: String = c.dungeons.sites[target.site].place.name
 return {"kind":"vault_key","key_id":id,"name":"Vault Key — "+site,"destination":site,"opened":record.opened,"status":"Vault opened" if record.opened else "Held in company keyring"}

static func owned(c) -> Array:
 var rows: Array = []
 for id: String in c.dungeons.vault_keys.records:
  var entry := row(c,id)
  if not entry.is_empty():rows.append(entry)
 return rows

static func details(entry: Dictionary) -> String:
 return "%s\n%s\n\nCompany key item · read-only\nOpens the matching treasury in this dungeon.\nThe key names its dungeon but gives no directions. Find the entrance through maps or exploration.\n\nKeys stay in the company keyring after the vault is opened. They cannot be equipped, sold or dragged." % [entry.destination,entry.status]
