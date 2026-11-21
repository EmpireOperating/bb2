extends RefCounted
## Separate stock24 spawn profile. Accepted packet/anchors are never rewritten.
const Generator = preload("res://procedural_woodland/generator.gd")
const PROFILE := "woodland_stock24_v1"
static func profile(packet: Dictionary) -> Array:
 if Generator.validate(packet) != "": return []
 return from_descriptor(packet.descriptor)

# Caller has admitted its versioned recipe; enforce the shared stock24 geometry.
static func from_descriptor(d: Dictionary) -> Array:
 var result := []
 for side in 2:
  for i in 6: result.append(d.spawns[side*6+i])
  var anchor: Vector2i = d.spawns[side*6]
  var back := -1 if side == 0 else 1
  for offset in [Vector2i(0,-2),Vector2i(0,2),Vector2i(back,-2),Vector2i(back,2),Vector2i(back*2,-1),Vector2i(back*2,1)]: result.append(anchor+offset)
 return result if validate(d,result) == "" else []
static func validate(d: Dictionary,spawns: Array) -> String:
 if spawns.size() != 24: return "Stock24 profile requires all24 slots."
 var seen := {}
 for i in 24:
  var p = spawns[i]
  if not p is Vector2i or seen.has(p): return "Duplicate or invalid stock24 spawn."
  seen[p] = true
  var key := "%d,%d" % [p.x,p.y]
  if p.x < 0 or p.y < 0 or p.x >= d.width or p.y >= d.height or not d.tiles.has(key): return "Spawn outside board."
  var t: Dictionary = d.tiles[key]
  if t.get("blocked",false) or t.height != 0: return "Spawn must be walkable and level."
  if (i < 12 and p.x >= d.goal.x) or (i >= 12 and p.x <= d.goal.x): return "Wrong opposing front."
  if i%12 < 6 and p != d.spawns[(i/12)*6+i%12]: return "Accepted anchor changed."
 for a in spawns.slice(0,12):
  for b in spawns.slice(12):
   if absi(a.x-b.x) < 6: return "Unsafe front separation."
 return ""
