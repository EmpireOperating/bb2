extends RefCounted
## Pure adapter for the existing mound. No campaign/RNG/content authority.
const B = preload("res://src/battle.gd")
const Themes = preload("res://src/dungeon_themes.gd")
const SITE := "dungeon_barrow_0"
const RECIPE := "stock_crypt_mound24_v1"
static func _descriptor() -> Dictionary:
 var b = B.new()
 # Geometry is seed-independent, sourced through the frozen stock theme writer.
 b.map_id = "crypt_mound"; b.roster_rules = true
 Themes.configure_battle(b)
 for tile in b.tiles.values():
  tile["blocked"] = tile.terrain == "wall"
  tile["vision_blocking"] = tile.terrain == "wall"
  tile["obstacle"] = "wall" if tile.terrain == "wall" else ""
 return {"id":"crypt_mound","title":"Burial chamber","width":17,"height":11,"goal":Vector2i(8,5),"tiles":b.tiles,"presentation":{"biome":"crypt","road":[],"stream":[],"bridges":[],"keep":[]}}
static func _safe(d: Dictionary, p: Vector2i) -> bool:
 var key := "%d,%d" % [p.x,p.y]
 return p.x >= 0 and p.y >= 0 and p.x < 17 and p.y < 11 and d.tiles.has(key) and not d.tiles[key].blocked
static func _fingerprint(d: Dictionary, spawns: Array) -> String:
 return JSON.stringify([RECIPE,d,spawns]).sha256_text()
static func packet(c) -> Dictionary:
 if c == null or c.phase != "battle" or c.dungeons.active != SITE or c.encounter.get("kind") != "dungeon" or c.encounter.get("site") != SITE: return {}
 var b = c.battle
 if b.map_id != "crypt_mound" or b.width() != 17 or b.height() != 11 or b.units.size() != 24 or b.player_slots() != 12: return {}
 var d := _descriptor()
 # Require actual stock tiles before normalizing explicit blocker flags.
 for key in d.tiles:
  if not b.tiles.has(key) or b.tiles[key].get("terrain") != d.tiles[key].terrain or b.tiles[key].get("height") != 0: return {}
 var spawns: Array[Vector2i] = []; var used := {}; var repair := []
 # Reserve ALL already valid rows before repairing any earlier invalid rank.
 for i in 24:
  var u: Dictionary = b.units[i]
  if u.get("id") != i or u.get("side") != (0 if i < 12 else 1) or not u.get("q") is int or not u.get("r") is int: return {}
  var p := Vector2i(u.q,u.r); spawns.append(p)
  if _safe(d,p) and not used.has(p): used[p] = true
  else: repair.append(i)
 for i in repair:
  var found := false
  # Side-local; centre ranks first, advancing only within the original side.
  for q in ([4,3,2,1,0,5,6] if i < 12 else [10,11,12,13,14,15,16,9,8]):
   for r in [5,4,6,3,7,2,8]:
    var p := Vector2i(q,r)
    if not _safe(d,p) or used.has(p): continue
    spawns[i] = p; used[p] = true; found = true; break
   if found: break
  if not found: return {}
 var p := {"descriptor":d,"spawns":spawns,"metadata":{"recipe":RECIPE,"fingerprint":_fingerprint(d,spawns)}}
 return p if validate(p) else {}
static func validate(p: Dictionary) -> bool:
 if p.size() != 3 or not p.get("descriptor") is Dictionary or not p.get("spawns") is Array or not p.get("metadata") is Dictionary: return false
 var d: Dictionary = p.descriptor
 # Whole exact geometry comparison also refuses hostile types before comparisons.
 if var_to_bytes(d) != var_to_bytes(_descriptor()) or p.spawns.size() != 24: return false
 var used := {}
 for i in 24:
  var at = p.spawns[i]
  if not at is Vector2i or not _safe(d,at) or used.has(at): return false
  if i < 12 and at.x >= 8 or i >= 12 and at.x < 8: return false
  used[at] = true
 var m: Dictionary = p.metadata
 return m.size() == 2 and m.get("recipe") is String and m.recipe == RECIPE and m.get("fingerprint") is String and m.fingerprint == _fingerprint(d,p.spawns)
static func metadata(p: Dictionary) -> Dictionary:
 return p.metadata.duplicate(true) if validate(p) else {}
