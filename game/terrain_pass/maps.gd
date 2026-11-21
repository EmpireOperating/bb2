extends RefCounted
## Pure authored content: no Battle, campaign, equipment, or random source.
const WIDTH := 13
const HEIGHT := 9
const TERRAIN := ["grass","hill","road","stone","ford","forest","mud","rough","rubble","rocks","swamp","sand","shallow_water","water","deep_water","wall"]
static func ids() -> Array:
 return ["ruined_crossing","woodland_road"]

static func create(id: String) -> Dictionary:
 if id not in ids(): return {}
 var crossing := id == "ruined_crossing"
 var tiles := {}
 var road: Array = []
 var stream: Array = []
 var keep: Array = []
 for r in HEIGHT:
  for q in WIDTH:
   var terrain := "grass"
   var height := 0
   if crossing:
    if (q <= 4 and r <= 2) or (q >= 8 and r <= 3): height = 1
    if (q >= 2 and q <= 3 and r <= 1) or (q >= 9 and q <= 11 and r <= 2): height = 2
    if q == 6: terrain = "water"
    elif q in [5,7] and r != 4: terrain = "mud"
    if r == 4:
     terrain = "ford" if q == 6 else "road"
     road.append(_key(Vector2i(q,r)))
    if q == 6 and r in [2,6]: terrain = "shallow_water"
    if q in [9,10,11] and r <= 2: terrain = "stone"
   else:
    if r <= 1 or r >= 7 or (q in [0,12] and r != 4): terrain = "forest"
    if q >= 3 and q <= 9 and r <= 2: height = 1
    if q >= 5 and q <= 7 and r <= 1: height = 2
    if r == (3 if q >= 4 and q <= 7 else 4):
     terrain = "road"
     road.append(_key(Vector2i(q,r)))
   tiles[_key(Vector2i(q,r))] = {"terrain":terrain,"height":height}
 if crossing:
  for r in range(-2,11): stream.append(Vector2i(6,r))
  for p in [Vector2i(9,0),Vector2i(10,0),Vector2i(11,0),Vector2i(9,1),Vector2i(11,1),Vector2i(11,2)]:
   _obstacle(tiles,p,"wall")
   keep.append(_key(p))
  for p in [Vector2i(8,1),Vector2i(12,2),Vector2i(10,3)]: tiles[_key(p)].terrain = "rubble"
  for p in [Vector2i(0,1),Vector2i(1,7),Vector2i(12,7)]: _obstacle(tiles,p,"tree")
 else:
  for p in [Vector2i(0,0),Vector2i(2,0),Vector2i(4,0),Vector2i(9,0),Vector2i(11,1),Vector2i(0,2),Vector2i(12,2),Vector2i(1,7),Vector2i(3,8),Vector2i(6,7),Vector2i(9,8),Vector2i(11,7)]: _obstacle(tiles,p,"tree")
  for p in [Vector2i(4,1),Vector2i(9,2)]: _obstacle(tiles,p,"boulder")
 var spawns := [Vector2i(4,4),Vector2i(4,3),Vector2i(4,5),Vector2i(2,4),Vector2i(3,3),Vector2i(3,5),Vector2i(8,4),Vector2i(8,3),Vector2i(8,5),Vector2i(10,4),Vector2i(9,5),Vector2i(9,3)]
 return {"id":id,"title":"Ruined Crossing" if crossing else "Woodland Road","tiles":tiles,"spawns":spawns,"presentation":{"biome":"crossing" if crossing else "woodland","road":road,"stream":stream,"bridges":["6,4"] if crossing else [],"keep":keep}}

static func _key(p: Vector2i) -> String:
 return "%d,%d" % [p.x,p.y]

static func _obstacle(tiles: Dictionary, p: Vector2i, kind: String) -> void:
 var tile: Dictionary = tiles[_key(p)]
 tile.terrain = "wall" if kind == "wall" else "forest" if kind == "tree" else "rocks"
 tile["obstacle"] = kind
 tile["blocked"] = true
 tile["vision_blocking"] = true

static func validate(d: Dictionary) -> String:
 if d.size() != 5 or not d.get("id") is String or d.id not in ids() or not d.get("title") is String or d.title.is_empty(): return "Unknown map, extra fields, or missing title."
 if not d.get("tiles") is Dictionary or d.tiles.size() != WIDTH*HEIGHT: return "Map requires a complete 13x9 board."
 var roads := {}; var walls := {}; var wet := {}; var passable := {}
 for r in HEIGHT:
  for q in WIDTH:
   var key := _key(Vector2i(q,r))
   var t = d.tiles.get(key)
   if not t is Dictionary or not t.get("terrain") is String or t.terrain not in TERRAIN or not t.get("height") is int or t.height < 0 or t.height > 2: return "Invalid terrain or elevation at "+key
   for field in t:
    if field not in ["terrain","height","obstacle","blocked","vision_blocking","cover"]: return "Unknown tile field at "+key
   for field in ["blocked","vision_blocking","cover"]:
    if t.has(field) and not t[field] is bool: return "Invalid obstacle flags at "+key
   var obstacle = t.get("obstacle","")
   if not obstacle is String or obstacle not in ["","tree","wall","boulder"]: return "Unknown obstacle at "+key
   if obstacle != "":
    if not t.get("blocked",false) or not t.get("vision_blocking",false): return "Obstacle requires physical and vision blockers at "+key
    if t.terrain != {"tree":"forest","wall":"wall","boulder":"rocks"}[obstacle]: return "Obstacle/floor mismatch at "+key
   elif t.get("blocked",false) or t.get("vision_blocking",false) or t.terrain == "wall": return "Hard blocker requires an explicit obstacle at "+key
   if t.terrain in ["road","ford"]: roads[key] = true
   if t.terrain == "wall": walls[key] = true
   if t.terrain in ["water","deep_water","shallow_water","ford"]: wet[key] = true
   if not t.get("blocked",false) and t.terrain not in ["water","deep_water","wall"]: passable[key] = Vector2i(q,r)
 if not d.get("spawns") is Array or d.spawns.size() != 12: return "Map requires twelve tactical spawn slots."
 var seen := {}
 for spawn in d.spawns:
  if not spawn is Vector2i or seen.has(spawn) or not passable.has(_key(spawn)): return "Invalid, duplicate, or blocked spawn slot."
  seen[spawn] = true
 if not d.get("presentation") is Dictionary: return "Missing presentation descriptor."
 var p: Dictionary = d.presentation
 if p.size() != 5 or p.get("biome") != ("crossing" if d.id == "ruined_crossing" else "woodland"): return "Wrong map biome or presentation fields."
 for field in ["road","stream","bridges","keep"]:
  if not p.get(field) is Array: return "Missing presentation field: "+field
 for pair in [["road",roads],["keep",walls]]:
  var marked := {}
  for key in p[pair[0]]:
   if not key is String or marked.has(key) or not pair[1].has(key): return "Invalid or duplicate "+pair[0]+" footprint."
   marked[key] = true
  if marked.size() != pair[1].size(): return "Incomplete "+pair[0]+" footprint."
 var stream := {}
 for cell in p.stream:
  if not cell is Vector2i or stream.has(_key(cell)) or cell.x < -2 or cell.x > WIDTH+1 or cell.y < -2 or cell.y > HEIGHT+1: return "Invalid stream cell."
  var key := _key(cell)
  if d.tiles.has(key) and not wet.has(key): return "Stream contradicts board terrain."
  stream[key] = true
 for key in wet:
  if not stream.has(key): return "Water missing from stream footprint."
 var bridges := {}
 for key in p.bridges:
  if not key is String or bridges.has(key) or not roads.has(key) or not stream.has(key) or d.tiles[key].terrain != "ford": return "Bridge must match road and ford over stream."
  bridges[key] = true
 if d.id == "woodland_road":
  if not p.stream.is_empty() or not p.bridges.is_empty() or not p.keep.is_empty(): return "Woodland may not carry crossing scenery."
 elif not bridges.has("6,4") or p.keep.is_empty(): return "Crossing requires its bridge and ruined keep."
 # Static content gate only. Deployment tests independently walk actual enabled
 # Battle edges. This uses odd-row topology and the authored one-level ramp cap.
 var reached := {_key(d.spawns[0]):true}
 var queue: Array = [d.spawns[0]]
 while not queue.is_empty():
  var cell: Vector2i = queue.pop_front()
  var parity := cell.y & 1
  for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(parity-1,-1),Vector2i(parity,-1),Vector2i(parity-1,1),Vector2i(parity,1)]:
   var next: Vector2i = cell+offset
   var key := _key(next)
   if not passable.has(key) or reached.has(key) or absi(d.tiles[_key(cell)].height-d.tiles[key].height) > 1: continue
   reached[key] = true
   queue.append(next)
 if reached.size() != passable.size(): return "Walkable terrain must be connected by one-level approaches."
 return ""
