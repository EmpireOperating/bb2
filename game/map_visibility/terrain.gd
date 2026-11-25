extends "res://terrain_pass/terrain.gd"
## Keep inherited geometry, art and exact mask arithmetic. Only narrow spatial
## candidates before evaluating compact-support floor/road kernels.
const BIN_SIZE := 2.0
var _floor_bins: Dictionary = {}
var _road_bins: Dictionary = {}
var mask_stats: Dictionary = {}
var _draw_terrain_work := false
var _work := {}
var _intact_mount_tiles := {}

func build(battle) -> void:
 _work.clear()
 _intact_mount_tiles.clear()
 if _draw_terrain_work:
  var authored:Dictionary=battle.get_meta("authored_map",{}).get("tiles",{})
  for cell:Vector2i in battle.terrain_work_cells():
   var key:String=battle.key(cell)
   if not authored.has(key):continue
   var original:Dictionary=authored[key]
   # Mount the authored silhouette regardless of private damage, then reveal
   # only witnessed clearances. Presentation never consumes remaining HP.
   if battle.tiles.get(key)!=original:_intact_mount_tiles[key]=original
   _work[key]={"cell":cell,"kind":battle.terrain_work_at(cell).kind,"last_tile":original}
 super.build(battle)
 _tiles=battle.tiles
 _intact_mount_tiles.clear()
 # Stage low, non-occluding debris before the Fog collector binds meshes.
 for object:Dictionary in occluders:
  if not _work.has(object.tile):continue
  var row:Dictionary=_work[object.tile]
  row.object=object
  row.remnant=_work_remnant(object.tile,row.kind)
  row.remnant.hide()

func _work_remnant(_key:String,_kind:String) -> Node3D:
 return null # Implemented only by opted-in terrain painters.

func work_tile_keys() -> Array:
 return _work.keys()

func remembered_work_tile(key:String,fallback:Dictionary) -> Dictionary:
 return _work[key].last_tile if _work.has(key) else fallback

func refresh_terrain_work(battle) -> void:
 for key:String in _work:
  var row:Dictionary=_work[key]
  if not row.has("object") or row.get("cleared",false) or not battle.terrain_work_clear_known(0,row.cell):continue
  row.last_tile=battle.tiles[key].duplicate()
  row.object.root.hide()
  faded_occluders.erase(row.object.root)
  occluders.erase(row.object)
  row.remnant.show()
  row.cleared=true
  _terrain_work_retired(battle,row)

func _terrain_work_retired(_battle,_row:Dictionary) -> void:
 pass

func _prepare_masks(keys: Array) -> void:
 if not _intact_mount_tiles.is_empty():
  _tiles=_tiles.duplicate()
  _tiles.merge(_intact_mount_tiles,true)
 super._prepare_masks(keys)
 _floor_bins.clear(); _road_bins.clear()
 mask_stats = {"queries":0,"floor_candidates":0,"road_candidates":0,"floor_max":0,"road_max":0}
 for i in _floor_samples.size(): _insert(_floor_bins,_floor_samples[i].p,i)
 for i in _road_shapes.size(): _insert(_road_bins,_road_shapes[i].p,i)

func _bin(p: Vector2) -> Vector2i:
 return Vector2i(floori(p.x/BIN_SIZE),floori(p.y/BIN_SIZE))

func _insert(bins: Dictionary, point: Vector2, index: int) -> void:
 var key := _bin(point)
 if not bins.has(key): bins[key] = []
 bins[key].append(index)

func _nearby(bins: Dictionary, point: Vector2, radius: float) -> Array:
 var lo := _bin(point-Vector2.ONE*radius)
 var hi := _bin(point+Vector2.ONE*radius)
 var found: Array = []
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1): found.append_array(bins.get(Vector2i(x,y),[]))
 # Preserve the inherited summation order exactly, including floating rounding.
 found.sort()
 return found

func _field_mask(_key: String, point: Vector3) -> Color:
 var p := Vector2(point.x,point.z).snapped(Vector2.ONE*.00001)
 if _mask_cache.has(p): return _mask_cache[p]
 var floor_candidates := _nearby(_floor_bins,p,1.75)
 var road_candidates := _nearby(_road_bins,p,1.001)
 mask_stats.queries += 1
 mask_stats.floor_candidates += floor_candidates.size()
 mask_stats.road_candidates += road_candidates.size()
 mask_stats.floor_max = maxi(mask_stats.floor_max,floor_candidates.size())
 mask_stats.road_max = maxi(mask_stats.road_max,road_candidates.size())
 var floor_mask := Vector3.ZERO
 var total := 0.0
 for index in floor_candidates:
  var sample: Dictionary = _floor_samples[index]
  var distance: float = p.distance_to(sample.p)
  if distance >= 1.75: continue
  var weight := pow(1.75-distance,2.0)
  floor_mask += sample.mask*weight
  total += weight
 if total > 0.0: floor_mask /= total
 var road := 0.0
 for index in road_candidates:
  var shape: Dictionary = _road_shapes[index]
  var offset: Vector2 = p-shape.p
  if offset.length() > 1.001: continue
  var distance := offset.length()
  for end: Vector2 in shape.exits:
   distance = minf(distance,p.distance_to(Geometry2D.get_closest_point_to_segment(p,shape.p,end)))
  var mask := 1.0-smoothstep(.35,.72,distance)
  for normal: Vector2 in shape.closed:
   mask *= smoothstep(0.0,.25,sqrt(3.0)*.5-offset.dot(normal))
  road = maxf(road,mask)
 var result := Color(road,floor_mask.x,floor_mask.y,floor_mask.z)
 _mask_cache[p] = result
 return result
