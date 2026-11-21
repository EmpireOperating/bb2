extends RefCounted
## First bounded woodland-road recipe. No engine, Campaign or global RNG authority.
const Maps = preload("res://map_visibility/maps.gd")
const RECIPE_ID := "woodland_road_v1"
const MIN_SEED := 0
const MAX_SEED := 2147483647
const SIZE := 32

static func generate(seed: Variant) -> Dictionary:
 if not _valid_seed(seed): return {}
 var descriptor := _build(seed)
 var packet := {"recipe":RECIPE_ID,"seed":seed,"descriptor":descriptor,"fingerprint":descriptor_fingerprint(descriptor),"metrics":_metrics(descriptor)}
 if validate(packet) != "": return {}
 return packet

static func validate(packet: Variant) -> String:
 if not packet is Dictionary or packet.size() != 5 or not packet.has_all(["recipe","seed","descriptor","fingerprint","metrics"]): return "Invalid packet fields."
 if not packet.recipe is String or packet.recipe != RECIPE_ID or not _valid_seed(packet.seed): return "Unsupported recipe or seed."
 if not packet.descriptor is Dictionary: return "Missing descriptor."
 var d: Dictionary = packet.descriptor
 if not _descriptor_shape(d): return "Invalid bounded recipe descriptor."
 var reason := Maps.validate(d)
 if reason != "": return reason
 if not packet.fingerprint is String or packet.fingerprint != descriptor_fingerprint(d): return "Layout fingerprint mismatch."
 var actual := _metrics(d)
 if not packet.metrics is Dictionary or packet.metrics.size() != actual.size(): return "Invalid metrics fields."
 for field in actual:
  if not packet.metrics.get(field) is int or packet.metrics[field] != actual[field]: return "Dishonest layout metric: "+field
 reason = _layout_reason(d,actual)
 if reason != "": return reason
 # Bind the requested seed to the actual recipe geometry, not merely its label.
 # This is a bounded rebuild, never a retry, seed substitution or fallback.
 if packet.fingerprint != descriptor_fingerprint(_build(packet.seed)): return "Descriptor does not belong to recipe seed."
 return ""

static func _descriptor_shape(d: Dictionary) -> bool:
 if d.size() != 8 or not d.has_all(["id","title","width","height","tiles","spawns","goal","presentation"]): return false
 if not d.id is String or d.id != "woodland_road" or not d.title is String or d.title.is_empty() or d.title.length() > 128: return false
 if not d.width is int or not d.height is int or d.width != SIZE or d.height != SIZE: return false
 if not d.tiles is Dictionary or d.tiles.size() != SIZE*SIZE or not d.spawns is Array or d.spawns.size() != 12: return false
 for tile in d.tiles.values():
  if not tile is Dictionary or not tile.has_all(["terrain","height"]) or tile.size() not in [2,5]: return false
  if not tile.terrain is String or tile.terrain not in ["grass","forest","road"] or not tile.height is int: return false
  if tile.size() == 5:
   if not tile.has_all(["obstacle","blocked","vision_blocking"]) or not tile.obstacle is String or tile.obstacle != "tree": return false
   if not tile.blocked is bool or not tile.vision_blocking is bool or not tile.blocked or not tile.vision_blocking: return false
 var p = d.presentation
 if not p is Dictionary or p.size() != 5 or not p.has_all(["biome","road","stream","bridges","keep"]) or not p.biome is String or p.biome != "woodland": return false
 if not p.road is Array or p.road.size() < SIZE or p.road.size() > 64: return false
 for field in ["stream","bridges","keep"]:
  if not p[field] is Array or not p[field].is_empty(): return false
 return true

static func _neighbors(p: Vector2i) -> Array:
 var parity := p.y & 1
 var result := []
 for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(parity-1,-1),Vector2i(parity,-1),Vector2i(parity-1,1),Vector2i(parity,1)]:
  var n: Vector2i = p+offset
  if n.x >= 0 and n.x < SIZE and n.y >= 0 and n.y < SIZE: result.append(n)
 return result

static func _reach(nodes: Dictionary,start: Vector2i,removed: Dictionary = {}) -> Dictionary:
 var reached := {start:start}
 var queue := [start]
 var index := 0
 while index < queue.size():
  var p: Vector2i = queue[index]; index += 1
  for n in _neighbors(p):
   if not nodes.has(n) or reached.has(n) or removed.has(n) or absi(nodes[n]-nodes[p]) > 1: continue
   reached[n] = p; queue.append(n)
 return reached

static func _layout_reason(d: Dictionary,m: Dictionary) -> String:
 if m.height1 < 30 or m.height2 < 20 or m.trees < 20 or m.trees > 180: return "Insufficient woodland or stepped elevation."
 var nodes := {}; var roads := {}; var rows := {}; var west: Variant = null; var east := false
 var forest := 0; var grass := 0
 for r in SIZE:
  for q in SIZE:
   var p := Vector2i(q,r)
   var t: Dictionary = d.tiles[_key(p)]
   if t.terrain == "forest": forest += 1
   if t.terrain == "grass": grass += 1
   if not t.get("blocked",false): nodes[p] = t.height
   if t.terrain == "road":
    roads[p] = t.height; rows[r] = true
    if q == 0: west = p
    if q == SIZE-1: east = true
 if forest < 160 or grass < 120: return "Insufficient coherent woodland/open space."
 var a: Vector2i = d.spawns[0]; var b: Vector2i = d.spawns[6]
 if a.x < 10 or b.x > 22 or a.y < 13 or a.y > 18: return "Deployment must stay central."
 for spawn in d.spawns:
  if nodes[spawn] != 0: return "Deployment must be level."
  for n in _neighbors(spawn):
   if not nodes.has(n) or nodes[n] != 0: return "Deployment approach must be protected."
 if west == null or not east or rows.size() < 3 or _reach(roads,west).size() != roads.size(): return "Road must connect west/east with a bend."
 var parents := _reach(nodes,a)
 if parents.size() != nodes.size() or not parents.has(b): return "Unreachable walkable terrain."
 var removed := {}
 var cursor: Vector2i = parents[b]
 while cursor != a:
  removed[cursor] = true; cursor = parents[cursor]
 if removed.is_empty() or not _reach(nodes,a,removed).has(b): return "Deployment needs two independent approaches."
 return ""

static func descriptor_fingerprint(descriptor: Dictionary) -> String:
 var layout := descriptor.duplicate(true)
 layout.erase("title")
 return JSON.stringify(_canonical(layout),"",true,false).sha256_text()

static func _canonical(value: Variant) -> Variant:
 if value is Vector2i: return [value.x,value.y]
 if value is Dictionary:
  var result := {}
  var keys: Array = value.keys()
  keys.sort()
  for key in keys: result[key] = _canonical(value[key])
  return result
 if value is Array:
  var result := []
  for item in value: result.append(_canonical(item))
  return result
 return value

static func _valid_seed(seed: Variant) -> bool:
 return seed is int and seed >= MIN_SEED and seed <= MAX_SEED

static func _key(p: Vector2i) -> String:
 return "%d,%d" % [p.x,p.y]

static func _build(seed_value: int) -> Dictionary:
 # Every draw belongs to this private stream; nothing consumes combat/global RNG.
 var rng := RandomNumberGenerator.new()
 rng.seed = seed_value
 var center := Vector2i(rng.randi_range(14,17),rng.randi_range(13,18))
 var north_edge := rng.randi_range(9,11)
 var south_edge := rng.randi_range(20,22)
 var skirt := rng.randi_range(4,6)
 var terrace_left := rng.randi_range(4,8)
 var terrace_right := rng.randi_range(23,27)
 var terrace_bottom := rng.randi_range(7,9)
 var high_bottom := rng.randi_range(2,4)
 var south_top := rng.randi_range(24,26)
 var south_left := rng.randi_range(4,8)
 var south_right := rng.randi_range(23,27)
 var clearings := [Vector2i(rng.randi_range(9,22),rng.randi_range(5,7)),Vector2i(rng.randi_range(9,22),rng.randi_range(24,26))]
 var tree_q := rng.randi_range(0,2)
 var tree_r := rng.randi_range(0,2)
 var tiles := {}
 for r in SIZE:
  for q in SIZE:
   var height := 0
   if r <= terrace_bottom and q >= terrace_left and q <= terrace_right: height = 1
   if r <= high_bottom and q >= terrace_left+3 and q <= terrace_right-3: height = 2
   if r >= south_top and r <= 29 and q >= south_left and q <= south_right: height = 1
   var terrain := "forest" if r <= north_edge or r >= south_edge or q <= skirt or q >= 31-skirt else "grass"
   for clearing in clearings:
    if absi(q-clearing.x) <= 2 and absi(r-clearing.y) <= 2: terrain = "grass"
   # A shared broad arena protects all slots plus their immediate approach space.
   if q >= center.x-5 and q <= center.x+5 and absi(r-center.y) <= 3:
    height = 0
    terrain = "grass"
   var t := {"terrain":terrain,"height":height}
   # Spaced trees remain scenery in coherent groves, never a noise wall.
   if terrain == "forest" and q % 3 == tree_q and r % 3 == tree_r:
    t["obstacle"] = "tree"; t["blocked"] = true; t["vision_blocking"] = true
   tiles[_key(Vector2i(q,r))] = t
 var bend_w := rng.randi_range(5,9)
 var bend_e := rng.randi_range(23,27)
 var direction := -1 if rng.randi_range(0,1) == 0 else 1
 var west_row := center.y + direction*rng.randi_range(2,3)
 var east_row := center.y - direction*rng.randi_range(2,3)
 var road := []
 for q in SIZE:
  var row := west_row if q < bend_w else east_row if q > bend_e else center.y
  var low := mini(row,center.y) if q in [bend_w-1,bend_w,bend_e,bend_e+1] else row
  var high := maxi(row,center.y) if q in [bend_w-1,bend_w,bend_e,bend_e+1] else row
  for r in range(low,high+1):
   var k := _key(Vector2i(q,r))
   tiles[k] = {"terrain":"road","height":0}
   road.append(k)
 var a := center + Vector2i(-3,0)
 var b := center + Vector2i(3,0)
 return {"id":"woodland_road","title":"Generated Woodland Road — Seed %d" % seed_value,"tiles":tiles,"spawns":[a,a+Vector2i(0,-1),a+Vector2i(0,1),a+Vector2i(-1,0),a+Vector2i(-1,-1),a+Vector2i(-1,1),b,b+Vector2i(0,-1),b+Vector2i(0,1),b+Vector2i(1,0),b+Vector2i(1,1),b+Vector2i(1,-1)],"presentation":{"biome":"woodland","road":road,"stream":[],"bridges":[],"keep":[]},"width":SIZE,"height":SIZE,"goal":center}

static func _metrics(d: Dictionary) -> Dictionary:
 var result := {"walkable":0,"road":0,"trees":0,"height1":0,"height2":0}
 for key in d.tiles:
  var tile: Dictionary = d.tiles[key]
  if not tile.get("blocked",false): result.walkable += 1
  if tile.terrain == "road": result.road += 1
  if tile.get("obstacle","") == "tree": result.trees += 1
  if tile.height == 1: result.height1 += 1
  if tile.height == 2: result.height2 += 1
 return result
