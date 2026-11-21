extends "res://map_visibility/terrain.gd"
## Decorative grass only. No authority, occupancy queries, RNG consumption or wind.
const TuftMesh = preload("res://grassland_visuals/tuft_mesh.gd")
const MAX_TUFTS := 2857 # 59,997 triangles, even on a larger admitted descriptor.
const FOOTPRINT := .17
const PALETTE := [Color("65764b"),Color("788653"),Color("566c49"),Color("85865b"),Color("6c7d50")]
var _grass_seed := 0

func _grass_sample(cell: Vector2i, salt: int) -> float:
 return float(hash([_grass_seed,cell.x,cell.y,salt]) & 0x7fffffff)/2147483647.0

func _authored_landscape(keys: Array) -> void:
 super._authored_landscape(keys)
 _grass_seed = hash(_descriptor) & 0x7fffffff
 var patches := FastNoiseLite.new()
 patches.seed = _grass_seed
 patches.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
 patches.frequency = .095
 patches.fractal_type = FastNoiseLite.FRACTAL_NONE
 var builder := TuftMesh.new()
 var count := 0
 for key: String in keys:
  var tile: Dictionary = _tiles[key]
  if tile.get("blocked",false) or not tile.terrain in ["grass","forest"] or _road_keys.has(key) or _bridge_keys.has(key): continue
  var cell := _cell(key)
  var center: Vector3 = world_anchors[key]
  var density := lerpf(.25,1.0,smoothstep(-.45,.35,patches.get_noise_2d(center.x,center.z)))
  if tile.terrain == "forest": density *= .72
  # Individual gaps sit inside broad spatial patches, not a uniform per-hex carpet.
  if _grass_sample(cell,73) < .10: continue
  var phase := _grass_sample(cell,71)*TAU
  for i in 5:
   if count >= MAX_TUFTS: break
   if _grass_sample(cell,101+i*19) > density: continue
   var angle := phase+float(i)*2.399963+(_grass_sample(cell,131+i*31)-.5)*.60
   var radius := .55+_grass_sample(cell,151+i*37)*.10
   var base := center+Vector3(cos(angle)*radius,.006,sin(angle)*radius)
   if not _clear_grass_footprint(key,cell,base): continue
   var height := .29+_grass_sample(cell,191+i*41)*.15
   var tint: Color = PALETTE[mini(PALETTE.size()-1,int(_grass_sample(cell,211+i*43)*PALETTE.size()))]
   builder.tuft(base,height,_grass_sample(cell,251+i*47)*TAU,tint)
   count += 1
 var grass := _mesh(_generated,"GrasslandTufts",builder,_scenic_material("meadow",.25))
 grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _clear_grass_footprint(key: String, cell: Vector2i, base: Vector3) -> bool:
 # Query accepted shared road paint across the entire fan, not only tile labels.
 if _field_mask(key,base).r > .01: return false
 for i in 8:
  var angle := float(i)*TAU/8.0
  if _field_mask(key,base+Vector3(cos(angle)*FOOTPRINT,0,sin(angle)*FOOTPRINT)).r > .01: return false
 # Keep all blades inset from a real height discontinuity or board boundary.
 var corners := Layout.corners(cell)
 var center := Layout.world(cell)
 for i in 6:
  var a: Vector3 = corners[i]
  var b: Vector3 = corners[(i+1)%6]
  var midpoint := (a+b)*.5
  var neighbor := Layout.from_world(midpoint+(midpoint-center).normalized()*.05)
  var neighbor_key := "%d,%d" % [neighbor.x,neighbor.y]
  if _tiles.has(neighbor_key) and is_equal_approx(_surface_height(cell),_surface_height(neighbor)): continue
  var point := Vector2(base.x,base.z)
  if point.distance_to(Geometry2D.get_closest_point_to_segment(point,Vector2(a.x,a.z),Vector2(b.x,b.z))) < FOOTPRINT+.08: return false
 return true
