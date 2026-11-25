extends RefCounted
## Pure versioned odd-row crypt geometry. No Battle, Campaign, IO or ambient RNG.
const FIELDS = ["crypt","crypt_barrow","crypt_gallery","crypt_throne","crypt_mound","crypt_garrison","crypt_royal"]
const RECIPE = "seeded_crypt_v2"
const CANONICAL_RECIPE := "seeded_crypt_horizontal_v3"
const WORK_RECIPE := "seeded_crypt_horizontal_v3_work_v1"
const Opening = preload("res://dungeon_maps/canonical_opening.gd")
const WIDTH = 25
const HEIGHT = 13
static func _request(field: Variant, seed: Variant) -> bool:
 return field is String and field in FIELDS and seed is int and seed >= 0 and seed <= 2147483647
static func generate(field_id: Variant, seed: Variant, recipe: Variant = RECIPE) -> Dictionary:
 if not _request(field_id,seed) or not recipe is String: return {}
 if recipe == RECIPE: return _build(field_id,seed)
 if recipe not in [CANONICAL_RECIPE,WORK_RECIPE]: return {}
 var packet := Opening.geometry(field_id,seed)
 packet["recipe"]=recipe
 packet["field"]=field_id
 packet["seed"]=seed
 var d: Dictionary=packet.descriptor
 packet["fingerprint"]=var_to_bytes([CANONICAL_RECIPE,d.width,d.height,d.goal,d.tiles,d.presentation,packet.spawns]).hex_encode().sha256_text()
 return packet
static func _key(p: Vector2i) -> String:
 return "%d,%d" % [p.x,p.y]
static func _build(field: String, seed: int) -> Dictionary:
 var rng := RandomNumberGenerator.new(); rng.seed = seed
 var walls := {}
 for y in HEIGHT:
  for x in WIDTH:
   if y == 0 or y == HEIGHT-1: walls[Vector2i(x,y)] = true
 # Explicit architectural aliases retain the exact caller's field identity.
 var family: String = {"crypt":"royal","crypt_barrow":"mound","crypt_gallery":"garrison","crypt_throne":"royal","crypt_mound":"mound","crypt_garrison":"garrison","crypt_royal":"royal"}[field]
 if family == "mound":
  # Burial recesses along opposing sides leave a broad central chamber.
  for y in [2,10]:
   var opening := rng.randi_range(9,13)
   for x in range(8,17):
    if x < opening or x > opening+1:
     if rng.randi_range(0,3) != 0: walls[Vector2i(x,y)] = true
 elif family == "garrison":
  # Parallel barrack galleries, independent cross-doors and short returns.
  for y in [4,8]:
   var opening := rng.randi_range(9,14)
   for x in range(8,17):
    if x < opening or x > opening+1: walls[Vector2i(x,y)] = true
   var end: int = 8 if rng.randi_range(0,1) == 0 else 16
   walls[Vector2i(end,y-1)] = true
   walls[Vector2i(end,y+1)] = true
 else:
  # Royal cross-wall: broad portal, recessed side tombs and a second screen.
  var column := rng.randi_range(10,14)
  var door := rng.randi_range(4,7)
  for y in range(2,11):
   if y < door or y > door+2: walls[Vector2i(column,y)] = true
  for x in range(9,16):
   if rng.randi_range(0,1) == 0: walls[Vector2i(x,2)] = true
   if rng.randi_range(0,1) == 0: walls[Vector2i(x,10)] = true
  for y in [3,4,8,9]: walls[Vector2i(16,y)] = true
 var tiles := {}; var wall_count := 0
 for y in HEIGHT:
  for x in WIDTH:
   var blocked := walls.has(Vector2i(x,y))
   if blocked: wall_count += 1
   tiles[_key(Vector2i(x,y))] = {"terrain":"wall" if blocked else "stone","height":0,"blocked":blocked,"vision_blocking":blocked,"obstacle":"wall" if blocked else "","cover":false}
 # Broad, real edge thresholds. Interior architecture and RNG stay v1-exact.
 for team in [0,1]:
  for y in range(1,HEIGHT-1):
   tiles[_key(Vector2i(0 if team == 0 else WIDTH-1,y))]["escape_side"] = team
 var players := []
 for q in [6,5]:
  for r in range(1,10): players.append(Vector2i(q,r))
 var spawns := players.slice(0,9)
 for r in [5,6,7]: spawns.append(Vector2i(5,r))
 for r in range(2,11): spawns.append(Vector2i(18,r))
 for r in [5,6,7]: spawns.append(Vector2i(19,r))
 var d := {"id":field,"title":"Seeded "+family+" crypt","width":WIDTH,"height":HEIGHT,"goal":Vector2i(12,6),"tiles":tiles,"presentation":{"biome":"crypt","road":[],"stream":[],"bridges":[],"keep":[],"family":family,"formation_policy":"stock_oddrow24_v1","player_anchors":players,"player_offset":Vector2i(2,0),"enemy_offset":Vector2i(7,0)}}
 # Goal is fixed, and a royal cross-wall must never occupy it.
 d.tiles[_key(d.goal)] = {"terrain":"stone","height":0,"blocked":false,"vision_blocking":false,"obstacle":"","cover":false}
 wall_count = d.tiles.values().filter(func(t): return t.blocked).size()
 return {"recipe":RECIPE,"field":field,"seed":seed,"descriptor":d,"spawns":spawns,"fingerprint":_fingerprint(d,spawns),"metrics":{"tiles":WIDTH*HEIGHT,"walls":wall_count,"floors":WIDTH*HEIGHT-wall_count,"formation_cells":18,"spawns":24}}
static func _fingerprint(d: Dictionary, spawns: Array) -> String:
 return var_to_bytes([RECIPE,d.width,d.height,d.goal,d.tiles,d.presentation,spawns]).hex_encode().sha256_text()
static func validate(packet: Variant, expected_field: Variant, expected_seed: Variant) -> bool:
 if not _request(expected_field,expected_seed) or not packet is Dictionary: return false
 var expected := generate(expected_field,expected_seed,packet.get("recipe"))
 # Reconstruct from the request, not attacker metrics/hash. Walk only the
 # bounded canonical schema; never serialize untrusted objects/deep containers.
 return not expected.is_empty() and _matches(packet,expected)
static func _matches(value: Variant, expected: Variant) -> bool:
 if typeof(value) != typeof(expected): return false
 if expected is Dictionary:
  if value.size() != expected.size(): return false
  for key in expected:
   if not value.has(key) or not _matches(value[key],expected[key]): return false
  return true
 if expected is Array:
  if value.size() != expected.size(): return false
  for i in expected.size():
   if not _matches(value[i],expected[i]): return false
  return true
 # The expected schema contains only these finite, exactly typed scalar kinds.
 if typeof(expected) not in [TYPE_BOOL,TYPE_INT,TYPE_STRING,TYPE_VECTOR2I]: return false
 return value == expected
