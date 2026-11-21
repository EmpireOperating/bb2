extends RefCounted
## Fixed authored reference maps. No campaign, equipment or random source.
const WIDTH := 32
const HEIGHT := 32
const TERRAIN := ["grass","hill","road","stone","ford","forest","mud","rough","rubble","rocks","swamp","sand","shallow_water","water","deep_water","wall"]
static func ids() -> Array:
 return ["ruined_crossing","woodland_road"]

static func create(id: String) -> Dictionary:
 if id not in ids(): return {}
 var crossing := id == "ruined_crossing"
 var tiles := {}
 for r in HEIGHT:
  for q in WIDTH:
   var tag := "grass"
   var h := 0
   if crossing:
    # Broad terraced north banks and two low southern spurs, not an empty rim.
    if r <= 9 and (q <= 13 or q >= 19): h = 1
    if r <= 5 and ((q >= 3 and q <= 9) or (q >= 22 and q <= 28)): h = 2
    if r >= 24 and r <= 28 and ((q >= 4 and q <= 10) or (q >= 24 and q <= 29)): h = 1
    if h > 0: tag = "hill"
    if (q <= 8 and r >= 18 and r <= 22) or (q >= 24 and r >= 11 and r <= 13): tag = "forest"
    if q in [15,17]: tag = "mud"; h = 0
    if q == 16: tag = "water"; h = 0
    if q == 16 and r in [11,19]: tag = "shallow_water"
    # Connected bridge highway and ford approach lanes north/south of it.
    if r == 15: tag = "ford" if q == 16 else "road"; h = 0
    if r in [11,19] and q >= 10 and q <= 22 and q != 16: tag = "road"; h = 0
    if q >= 22 and q <= 28 and r >= 5 and r <= 9: tag = "stone"
    if q >= 23 and q <= 28 and r in [10,11]: tag = "rubble"
   else:
    # Several authored groves, with floor distinct from hard tree obstacles.
    if r <= 10 or r >= 21 or q <= 7 or q >= 25: tag = "forest"
    if r >= 8 and r <= 11 and q >= 8 and q <= 24: tag = "forest"
    if r <= 8 and q >= 7 and q <= 25: h = 1
    if r <= 4 and q >= 11 and q <= 21: h = 2
    # Lower woodland skirts connect to the northern terrace by one-level ramps.
    if r >= 25 and r <= 28 and q >= 5 and q <= 11: h = 1
    var road_r := 14 if q >= 5 and q <= 10 else 16 if q >= 23 and q <= 27 else 15
    if r == road_r: tag = "road"; h = 0
    # Join the gentle bend across row transitions in odd-row topology.
    if q in [5,10,23,27] and r == 15: tag = "road"; h = 0
    if r == 11 and q >= 8 and q <= 24: tag = "rough"
   tiles[_key(Vector2i(q,r))] = {"terrain":tag,"height":h}
 if crossing:
  for p in [Vector2i(22,5),Vector2i(23,5),Vector2i(24,5),Vector2i(25,5),Vector2i(26,5),Vector2i(27,5),Vector2i(28,5),Vector2i(22,6),Vector2i(28,6),Vector2i(22,7),Vector2i(28,7),Vector2i(28,8),Vector2i(27,9)]: _obstacle(tiles,p,"wall")
  for p in [Vector2i(3,3),Vector2i(7,8),Vector2i(10,6),Vector2i(2,19),Vector2i(5,20),Vector2i(8,21),Vector2i(25,12),Vector2i(29,11),Vector2i(27,25),Vector2i(4,27),Vector2i(11,29),Vector2i(29,29)]: _obstacle(tiles,p,"tree")
  for p in [Vector2i(5,5),Vector2i(25,3),Vector2i(9,26),Vector2i(26,27)]: _obstacle(tiles,p,"boulder")
 else:
  for r in [1,4,7,23,26,29]:
   for q in [1,4,7,10,13,18,21,24,27,30]: _obstacle(tiles,Vector2i(q,r),"tree")
  for r in [10,13,17,20]:
   for q in [1,3,6,26,29,31]: _obstacle(tiles,Vector2i(q,r),"tree")
  for p in [Vector2i(9,9),Vector2i(13,10),Vector2i(21,9),Vector2i(24,10),Vector2i(11,22),Vector2i(18,23),Vector2i(22,21),Vector2i(7,19)]: _obstacle(tiles,p,"tree")
  for p in [Vector2i(8,6),Vector2i(22,7),Vector2i(9,25),Vector2i(23,26)]: _obstacle(tiles,p,"boulder")
 var presentation := {"biome":"crossing" if crossing else "woodland","road":[],"stream":[],"bridges":["16,15"] if crossing else [],"keep":[]}
 for key in tiles:
  if tiles[key].terrain in ["road","ford"]: presentation.road.append(key)
  if tiles[key].terrain == "wall": presentation.keep.append(key)
 if crossing:
  for r in range(-2,34): presentation.stream.append(Vector2i(16,r))
 return {"id":id,"title":"Ruined Crossing" if crossing else "Woodland Road","tiles":tiles,"spawns":[Vector2i(13,15),Vector2i(13,14),Vector2i(13,16),Vector2i(12,15),Vector2i(12,14),Vector2i(12,16),Vector2i(19,15),Vector2i(19,14),Vector2i(19,16),Vector2i(20,15),Vector2i(20,16),Vector2i(20,14)],"presentation":presentation,"width":WIDTH,"height":HEIGHT,"goal":Vector2i(16,15)}

static func _key(p: Vector2i) -> String:
 return "%d,%d" % [p.x,p.y]

static func _obstacle(tiles: Dictionary, p: Vector2i, kind: String) -> void:
 var tile: Dictionary = tiles[_key(p)]
 tile.terrain = {"tree":"forest","wall":"wall","boulder":"rocks"}[kind]
 tile["obstacle"] = kind
 tile["blocked"] = true
 tile["vision_blocking"] = true

static func validate(d: Dictionary) -> String:
 if d.size() != 8 or not d.get("id") is String or d.id not in ids() or not d.get("title") is String or d.title.is_empty(): return "Unknown map, fields or title."
 for field in ["width","height"]:
  if not d.get(field) is int or d[field] < 16 or d[field] > 64: return "Board dimensions must be integers from 16 to 64."
 var w: int = d.width; var h: int = d.height
 if not d.get("goal") is Vector2i or d.goal.x < 0 or d.goal.y < 0 or d.goal.x >= w or d.goal.y >= h: return "Goal outside board."
 if not d.get("tiles") is Dictionary or d.tiles.size() != w*h: return "Map requires a complete rectangular board."
 var roads := {}; var walls := {}; var wet := {}; var passable := {}
 for r in h:
  for q in w:
   var key := _key(Vector2i(q,r))
   var t = d.tiles.get(key)
   if not t is Dictionary or not t.get("terrain") is String or t.terrain not in TERRAIN or not t.get("height") is int or t.height < 0 or t.height > 2: return "Invalid terrain/elevation at "+key
   for field in t:
    if field not in ["terrain","height","obstacle","blocked","vision_blocking","cover"]: return "Unknown tile field at "+key
   for field in ["blocked","vision_blocking","cover"]:
    if t.has(field) and not t[field] is bool: return "Invalid obstacle flags at "+key
   var obstacle = t.get("obstacle","")
   if not obstacle is String or obstacle not in ["","tree","wall","boulder"]: return "Unknown obstacle at "+key
   if obstacle != "":
    if not t.get("blocked",false) or not t.get("vision_blocking",false): return "Obstacle requires physical and sight blocking at "+key
    if t.terrain != {"tree":"forest","wall":"wall","boulder":"rocks"}[obstacle]: return "Obstacle/floor mismatch at "+key
   elif t.get("blocked",false) or t.get("vision_blocking",false) or t.terrain == "wall": return "Hard blocker requires explicit scenery at "+key
   if t.terrain in ["road","ford"]: roads[key] = true
   if t.terrain == "wall": walls[key] = true
   if t.terrain in ["water","deep_water","shallow_water","ford"]: wet[key] = true
   if not t.get("blocked",false) and t.terrain not in ["water","deep_water","wall"]: passable[key] = Vector2i(q,r)
 if not passable.has(_key(d.goal)): return "Goal must be walkable."
 if not d.get("spawns") is Array or d.spawns.size() != 12: return "Twelve tactical slots required, independently of living roster."
 var seen := {}
 for spawn in d.spawns:
  if not spawn is Vector2i or seen.has(spawn) or not passable.has(_key(spawn)): return "Invalid, duplicate or blocked spawn slot."
  seen[spawn] = true
 # Normal face-to-face ranks: retain inherited slot order, not ambush placement.
 var a: Vector2i = d.spawns[0]; var b: Vector2i = d.spawns[6]
 var rank := [Vector2i.ZERO,Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(-1,1)]
 var enemy := [Vector2i.ZERO,Vector2i(0,-1),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(1,-1)]
 for i in 6:
  if d.spawns[i] != a+rank[i] or d.spawns[i+6] != b+enemy[i]: return "Invalid normal formation strips."
 if b.x <= a.x or b.y != a.y: return "Opposing fronts must face across the board."
 for i in 3:
  for j in range(6,9):
   if _distance(d.spawns[i],d.spawns[j]) < 6: return "Front ranks require six hex steps."
 if not d.get("presentation") is Dictionary: return "Missing presentation descriptor."
 var p: Dictionary = d.presentation
 if p.size() != 5 or p.get("biome") != ("crossing" if d.id == "ruined_crossing" else "woodland"): return "Wrong biome/presentation fields."
 for field in ["road","stream","bridges","keep"]:
  if not p.get(field) is Array: return "Missing presentation array: "+field
 for pair in [["road",roads],["keep",walls]]:
  var marked := {}
  for key in p[pair[0]]:
   if not key is String or marked.has(key) or not pair[1].has(key): return "Invalid/duplicate "+pair[0]+" footprint."
   marked[key] = true
  if marked.size() != pair[1].size(): return "Incomplete "+pair[0]+" footprint."
 var stream := {}
 for cell in p.stream:
  if not cell is Vector2i or stream.has(_key(cell)) or cell.x < -2 or cell.x > w+1 or cell.y < -2 or cell.y > h+1: return "Invalid stream cell."
  var key := _key(cell)
  if d.tiles.has(key) and not wet.has(key): return "Stream contradicts board terrain."
  stream[key] = true
 for key in wet:
  if not stream.has(key): return "Water missing from stream footprint."
 var bridges := {}
 for key in p.bridges:
  if not key is String or bridges.has(key) or not roads.has(key) or not stream.has(key) or d.tiles[key].terrain != "ford": return "Bridge requires matching road/ford/stream."
  bridges[key] = true
 if d.id == "woodland_road":
  if not p.stream.is_empty() or not p.bridges.is_empty() or not p.keep.is_empty(): return "Woodland cannot carry crossing scenery."
 elif not bridges.has(_key(d.goal)) or p.keep.is_empty(): return "Crossing requires central bridge and ruined keep."
 var reached := {_key(d.spawns[0]):true}
 var queue: Array = [d.spawns[0]]
 var index := 0
 while index < queue.size():
  var cell: Vector2i = queue[index]; index += 1
  var parity := cell.y & 1
  for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(parity-1,-1),Vector2i(parity,-1),Vector2i(parity-1,1),Vector2i(parity,1)]:
   var next: Vector2i = cell+offset
   var key := _key(next)
   if not passable.has(key) or reached.has(key) or absi(d.tiles[_key(cell)].height-d.tiles[key].height) > 1: continue
   reached[key] = true; queue.append(next)
 if reached.size() != passable.size(): return "Walkable terrain must connect through one-level approaches."
 return ""

static func _distance(a: Vector2i, b: Vector2i) -> int:
 var aq := a.x - (a.y - (a.y & 1))/2
 var bq := b.x - (b.y - (b.y & 1))/2
 var dq: int = aq-bq; var dr := a.y-b.y
 return maxi(absi(dq),maxi(absi(dr),absi(dq+dr)))

