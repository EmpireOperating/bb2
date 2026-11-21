extends Node2D
## Passive campaign projection. Never generates geography, navigation or discovery.
const ART_NAMES = ["fir_01", "fir_02", "fir_03", "fir_04", "oak_01", "oak_02", "rocks_01", "rocks_02", "rocks_03", "shrub_01", "shrub_02", "log_01", "town_01", "farm_01", "mound_01", "tower_01", "bridge_01", "wagon_01", "camp_01", "ruin_01", "cave_01"]
const FOG_CODE = """
shader_type canvas_item;
uniform sampler2D knowledge : filter_nearest, repeat_disable;
uniform vec2 party_uv;
uniform vec2 map_size = vec2(2560.0,1600.0);
uniform float vision_radius = 340.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
// Blue is eroded by a complete neighbour ring on the CPU. Interpolating
// that interior mask can only feather into already explored cells.
float inward_reveal(vec2 uv) {
 vec2 size = vec2(textureSize(knowledge,0));
 vec2 p = uv*size-0.5, cell=floor(p), t=fract(p);
 float a=texture(knowledge,(cell+vec2(0.5,0.5))/size).b;
 float b=texture(knowledge,(cell+vec2(1.5,0.5))/size).b;
 float c=texture(knowledge,(cell+vec2(0.5,1.5))/size).b;
 float d=texture(knowledge,(cell+vec2(1.5,1.5))/size).b;
 return mix(mix(a,b,t.x),mix(c,d,t.x),t.y);
}
void fragment() {
 vec2 k = texture(knowledge,UV).rg;
 float n = noise(UV*vec2(29.0,20.0))*0.65 + noise(UV*vec2(83.0,51.0))*0.35;
 float d = length((UV-party_uv)*map_size);
 float inner = 1.0-smoothstep(vision_radius-45.0,vision_radius,d);
 // Unknown cells remain fully opaque: soft clouds never reveal unseen truth.
 float a = k.r < 0.5 ? 1.0 : mix(1.0,mix(0.53,0.0,inner*k.g),inward_reveal(UV));
 // Smoked rag paper: the plate tone is independent of hidden geography.
 vec2 pos=UV*map_size;
 float ruled=smoothstep(0.74,0.98,cos((pos.x*0.46+pos.y)*0.80+1.2*n));
 vec3 mist=mix(vec3(0.31,0.32,0.27),vec3(0.44,0.44,0.37),n)-vec3(0.014)*ruled;
 COLOR=vec4(mist,a);
}
"""

const W = 116
const H = 60
const CELL = 16.0
const MAP_SIZE = Vector2(W * CELL,H * CELL)
const ORIGIN = Vector2(40,216)
var canvas
var landscape
var ground_texture: ImageTexture
var textures = {}
var missing_art: Array[String] = []
var terrain: Array = []
var elevation: Array = []
var seed_value = 0
var stamps: Array = []
var fog_image: Image
var fog_texture: ImageTexture
var fog_sprite: Sprite2D
var fog_material: ShaderMaterial
var knowledge_key = ""
var water_meshes: Array = []
var water_currents: Array = []
var river_polygons: Array = []
var road_meshes: Array = []
var painted_bridges: Array = []
var bridge_metadata: Dictionary = {}
var ground_build_count = 0
var generation_serial = 0
var geography = ""
var geography_snapshot: Dictionary = {}
var explored_snapshot: Dictionary = {}
var knowledge_position = Vector2.INF
var knowledge_sight = -1.0
var fog_base = PackedByteArray()
var relief_grid = PackedFloat32Array()
var forest_grid = PackedFloat32Array()
var forest_noise = FastNoiseLite.new()
var drawn_generation = -1
var presented_generation = -1
var c:
 get: return canvas.campaign
func _ready() -> void:
 texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
 RenderingServer.frame_post_draw.connect(_post_draw)
func _post_draw() -> void:
 if DisplayServer.get_name() != "headless" and drawn_generation == generation_serial:
  presented_generation = drawn_generation
func prepare() -> void:
 # Native structural equality avoids serializing the immutable geography on
 # every frame, but still detects in-place edits and transaction replacements.
 if geography != "" and c.region == geography_snapshot:
  update_knowledge()
  return
 geography = "cached"
 geography_snapshot = c.region.duplicate(true)
 seed_value = int(c.region.seed)
 terrain = c.region.terrain.duplicate()
 elevation.clear()
 for t in terrain: elevation.append(0.75 if int(t)==6 else 0.48 if int(t)==2 else 0.12)
 if landscape == null:
  landscape = preload("res://campaign_overworld/landscape.gd").new()
  landscape.show_behind_parent = true
  landscape.position = ORIGIN
  add_child(landscape)
  for name in preload("res://campaign_overworld/landscape.gd").MATERIAL_NAMES + ART_NAMES:
   var path = "res://engraved_world/plates/%s.png" % name
   # Loose art keeps its authored mip chain. Packed projects can load imported textures instead.
   if not FileAccess.file_exists(path):
    if ResourceLoader.exists(path): textures[name] = load(path)
    else: missing_art.append(name)
    continue
   var image = Image.new()
   if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or image.is_empty(): missing_art.append(name); continue
   image.generate_mipmaps(); textures[name] = ImageTexture.create_from_image(image)
 _build_ground()
 build_corridors()
 build_scenery()
 setup_fog()
 knowledge_key = ""
 update_knowledge()
 generation_serial += 1
 drawn_generation = -1; presented_generation = -1
func _draw() -> void:
 if ground_texture == null: return
 drawn_generation = generation_serial
 for i in range(water_meshes.size()): draw_mesh(water_meshes[i],textures.get("ground_water") if i%4==3 else null)
 for stroke in water_currents: draw_polyline(stroke.points,stroke.color,stroke.width,true)
 for mesh in road_meshes: draw_mesh(mesh,null)
 for bridge in painted_bridges:
  if bridge.knowledge==0: continue
  if bridge.has("paint"): draw_mesh(bridge.paint.mesh,textures.get(bridge.paint_key))
 for stamp in stamps:
  if stamp.get("paint_knowledge",stamp.knowledge)==0: continue
  _draw_stamp(stamp)
func _build_ground() -> void:
 # A reusable small field, not a painted map backdrop: each pixel samples the
 # authoritative generated elevation and biome, with continuous seeded noise.
 # Broad geography-bound hill feet, sampled continuously by both material
 # and illumination. Only this generation owns the small filtered grid.
 relief_grid = _blur_grid(elevation)
 var forest_cells: Array = []
 for t in terrain: forest_cells.append(1.0 if int(t)==1 else 0.0)
 forest_grid = _blur_grid(forest_cells)
 forest_noise.seed = seed_value ^ 810731
 forest_noise.frequency = 0.008
 forest_noise.fractal_octaves = 2
 var image = Image.create(W * 2, H * 2, false, Image.FORMAT_RGBA8)
 var mask = Image.create(W * 2, H * 2, false, Image.FORMAT_RGBA8)
 var broad = FastNoiseLite.new()
 broad.seed = seed_value
 broad.frequency = 0.0045
 broad.fractal_octaves = 4
 var grain = FastNoiseLite.new()
 grain.seed = seed_value ^ 189127
 grain.frequency = 0.115
 grain.fractal_octaves = 2
 for y in range(H * 2):
  for x in range(W * 2):
   var p = Vector2(x * 8.0 + 4.0, y * 8.0 + 4.0)
   var sample = _field(p)
   var elevation = sample.x
   var forest = _forest_at(p)
   var relief = _relief_at(p)
   mask.set_pixel(x, y, Color(elevation, forest, relief, 1))
   var slope = _relief_at(p - Vector2(48, 36)) - _relief_at(p + Vector2(48, 36))
   var n = broad.get_noise_2dv(p)
   var g = grain.get_noise_2dv(p)
   var color = Color("85865a").lerp(Color("8d8759"), clampf(elevation * 0.7 + n * 0.4, 0, 1))
   color = color.lerp(Color("566548"), forest * 0.42)
   color = color.lerp(Color("a39468"), smoothstep(0.20, 0.62, relief) * 0.62)
   var light = clampf(1.0 + slope * 1.65 + n * 0.12 + g * 0.075, 0.77, 1.21)
   color = Color(color.r * light, color.g * light, color.b * light, 1)
   image.set_pixel(x, y, color)
 image.generate_mipmaps()
 ground_texture = ImageTexture.create_from_image(image)
 landscape.configure(ground_texture, mask, textures, MAP_SIZE)
 ground_build_count += 1
func _blur_grid(values: Array) -> PackedFloat32Array:
 var horizontal = PackedFloat32Array()
 var result = PackedFloat32Array()
 horizontal.resize(W*H)
 result.resize(W*H)
 for y in range(H):
  for x in range(W):
   var total = 0.0
   for k in range(-4,5): total += float(values[y*W+clampi(x+k,0,W-1)])*float(5-absi(k))
   horizontal[y*W+x]=total/25.0
 for y in range(H):
  for x in range(W):
   var total = 0.0
   for k in range(-4,5): total += horizontal[clampi(y+k,0,H-1)*W+x]*float(5-absi(k))
   result[y*W+x]=total/25.0
 return result

func _sample_grid(values: PackedFloat32Array, p: Vector2) -> float:
 var f = p/CELL-Vector2(0.5,0.5)
 var c = Vector2i(f.floor())
 var t = f-Vector2(c)
 var x0=clampi(c.x,0,W-1)
 var x1=clampi(c.x+1,0,W-1)
 var y0=clampi(c.y,0,H-1)*W
 var y1=clampi(c.y+1,0,H-1)*W
 return lerpf(lerpf(values[y0+x0],values[y0+x1],t.x),lerpf(values[y1+x0],values[y1+x1],t.x),t.y)

func _relief_at(p: Vector2) -> float:
 return _sample_grid(relief_grid,p)

func _forest_at(p: Vector2) -> float:
 # This field never consults party/actors or visibility. Broad openings
 # affect both the floor's quiet canopy shadow and actual crown placement.
 var opening = smoothstep(0.10,0.27,forest_noise.get_noise_2dv(p))
 return _sample_grid(forest_grid,p)*(1.0-opening)

func _field(p: Vector2) -> Vector2:
 var f = p / CELL - Vector2(0.5, 0.5)
 var base = Vector2i(f.floor())
 var t = f - Vector2(base)
 # The center-sampled elevation stays bilinear, including slope probes.
 var values: Array[Vector2] = []
 for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
  var c = Vector2i(clampi(base.x + d.x, 0, W - 1), clampi(base.y + d.y, 0, H - 1))
  var idx = c.y * W + c.x
  values.append(Vector2(float(elevation[idx]), 1.0 if int(terrain[idx]) == 1 else 0.0))
 return values[0].lerp(values[1], t.x).lerp(values[2].lerp(values[3], t.x), t.y)


func terrain_at(at: Vector2i) -> int:
 return int(terrain[at.y*W+at.x]) if Rect2i(0,0,W,H).has_point(at) else -1
func setup_fog() -> void:
 if fog_sprite != null: return
 fog_image = Image.create(W,H,false,Image.FORMAT_RGBA8)
 fog_texture = ImageTexture.create_from_image(fog_image)
 fog_sprite = Sprite2D.new()
 fog_sprite.centered = false; fog_sprite.position = ORIGIN; fog_sprite.scale = Vector2.ONE*CELL
 fog_sprite.texture = fog_texture
 var shader = Shader.new(); shader.code = FOG_CODE
 fog_material = ShaderMaterial.new(); fog_material.shader = shader
 fog_material.set_shader_parameter("knowledge",fog_texture)
 fog_material.set_shader_parameter("map_size",MAP_SIZE)
 fog_sprite.material = fog_material
 add_child(fog_sprite)
func knowledge(rect: Rect2) -> int:
 if not rect_discovered(rect): return 0
 # Current sight is the canonical campaign radius, never donor's free exploration.
 var start = Vector2i(((rect.position-ORIGIN)/CELL).floor())
 var end = Vector2i(((rect.end-ORIGIN)/CELL).ceil())
 for y in range(start.y,end.y):
  for x in range(start.x,end.x):
   if c.overworld.cell_point(Vector2i(x,y)).distance_to(c.overworld.position)>c.overworld.sight(): return 1
 return 2
func update_knowledge() -> void:
 var ow = c.overworld
 var sight: float = ow.sight()
 # Keep a value snapshot, not a reference or cardinality/hash-only key:
 # replacing a same-sized explored set must invalidate the eroded mask too.
 var discovery_changed: bool = knowledge_key == "" or ow.explored != explored_snapshot
 if not discovery_changed and ow.position == knowledge_position and sight == knowledge_sight: return
 knowledge_key = "cached"
 knowledge_position = ow.position
 knowledge_sight = sight
 if discovery_changed:
  explored_snapshot = ow.explored.duplicate()
  var known_cells = PackedByteArray()
  known_cells.resize(W*H)
  for y in H:
   for x in W:
    known_cells[y*W+x] = int(ow.discovered(ow.cell_point(Vector2i(x,y))))
  fog_base.resize(W*H*4)
  fog_base.fill(0)
  for y in H:
   for x in W:
    var i = y*W+x
    var interior = bool(known_cells[i])
    for ny in range(maxi(0,y-1),mini(H,y+2)):
     for nx in range(maxi(0,x-1),mini(W,x+2)):
      if not known_cells[ny*W+nx]: interior = false
    fog_base[i*4] = known_cells[i]*255
    fog_base[i*4+2] = int(interior)*255
    fog_base[i*4+3] = 255
 # Only green depends on current position/radius. Copy-on-write packed bytes
 # leave undiscovered pixels and the exact original red/blue erosion intact.
 var pixels = fog_base.duplicate()
 var home: Vector2i = ow.cell(ow.position)
 var reach = int(ceil(sight/CELL))+1
 for y in range(maxi(0,home.y-reach),mini(H,home.y+reach+1)):
  for x in range(maxi(0,home.x-reach),mini(W,home.x+reach+1)):
   var i = (y*W+x)*4
   if pixels[i] and ow.cell_point(Vector2i(x,y)).distance_to(ow.position)<=sight: pixels[i+1]=255
 fog_image.set_data(W,H,false,Image.FORMAT_RGBA8,pixels)
 fog_texture.update(fog_image)
 fog_material.set_shader_parameter("party_uv",(c.overworld.position-ORIGIN)/MAP_SIZE)
 fog_material.set_shader_parameter("vision_radius",c.overworld.sight())
 for item in stamps+painted_bridges: item.knowledge=knowledge(item.bounds)
 # Town artwork alone may appear progressively beneath the unchanged opaque
 # fog child. Keep .knowledge (and therefore marker/label/hit geometry) on
 # the original whole-bounds gate; never extend this exception to scenery.
 for stamp in stamps:
  if stamp.place.get("kind","") != "town": continue
  var anchor = Vector2(stamp.place.x,stamp.place.y)
  stamp["paint_knowledge"] = maxi(stamp.knowledge,1) if ow.discovered(anchor) else 0
 queue_redraw()
func rect_discovered(rect: Rect2) -> bool:
 if not Rect2(ORIGIN,MAP_SIZE).encloses(rect): return false
 var start = Vector2i(((rect.position-ORIGIN)/CELL).floor())
 var end = Vector2i(((rect.end-ORIGIN)/CELL).ceil())
 for y in range(start.y,end.y):
  for x in range(start.x,end.x):
   if not c.overworld.discovered(ORIGIN+(Vector2(x,y)+Vector2.ONE*0.5)*CELL): return false
 return true
func cell_mesh(types: Array, district: int, tint: Color) -> ArrayMesh:
 var vertices = PackedVector3Array(); var uv = PackedVector2Array(); var colors = PackedColorArray(); var indices = PackedInt32Array()
 for y in H:
  for x in range(district*58,(district+1)*58):
   if terrain_at(Vector2i(x,y)) not in types: continue
   var start = vertices.size()
   for offset in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
    var q = ORIGIN+(Vector2(x,y)+offset)*CELL
    vertices.append(Vector3(q.x,q.y,0)); uv.append(q/192.0)
    colors.append(tint.lightened(sin(q.x/53.0+q.y/71.0)*0.035))
   indices.append_array(PackedInt32Array([start,start+1,start+2,start,start+2,start+3]))
 var arrays = []; arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_TEX_UV]=uv; arrays[Mesh.ARRAY_COLOR]=colors; arrays[Mesh.ARRAY_INDEX]=indices
 var mesh = ArrayMesh.new()
 if not vertices.is_empty(): mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 return mesh
func build_corridors() -> void:
 water_meshes.clear(); road_meshes.clear(); painted_bridges.clear()
 var cohesion = preload("res://campaign_overworld/cohesion.gd").new()
 cohesion.painter = self
 road_meshes = cohesion.build_roads()
 # Each district is projected separately; never join the concatenated streams.
 var rivers = cohesion.build_rivers()
 water_meshes = rivers.meshes
 water_currents = rivers.currents
 river_polygons = rivers.polygons
 bridge_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://campaign_overworld/assets/landscape-art.json")).get("bridges",{})
 for bridge in c.region.bridges:
  var p = Vector2(bridge.position[0],bridge.position[1])
  var at = c.overworld.cell(p)
  var axis = Vector2.DOWN if bridge.vertical else Vector2.RIGHT
  var side = Vector2(-axis.y,axis.x)
  var step = Vector2i(axis); var across = Vector2i(side)
  if terrain_at(at) != 5: continue
  var low = at; var high = at
  while terrain_at(low-step)==5: low -= step
  while terrain_at(high+step)==5: high += step
  # Require a complete physical rectangle when an unusual wider crossing exists.
  var width_low = 0; var width_high = 0
  while bridge_row(low,high,across*(width_low-1),step): width_low -= 1
  while bridge_row(low,high,across*(width_high+1),step): width_high += 1
  var a = c.overworld.cell_point(low)-axis*CELL*0.5
  var b = c.overworld.cell_point(high)+axis*CELL*0.5
  var anchor = (a+b)*0.5+side*(width_low+width_high)*CELL*0.5
  var half_width = (width_high-width_low+1)*CELL*0.5
  var deck = PackedVector2Array([a+side*(width_low*CELL-CELL/2),b+side*(width_low*CELL-CELL/2),b+side*(width_high*CELL+CELL/2),a+side*(width_high*CELL+CELL/2)])
  var bounds = Rect2(deck[0],Vector2.ZERO)
  for corner in deck: bounds = bounds.expand(corner)
  var g = {"anchor":anchor,"axis":axis,"side":side,"half_span":a.distance_to(b)*0.5,"half_width":half_width,"deck":deck,"bounds":bounds.grow(9),"knowledge":0}
  var key = "bridge_v" if bridge.vertical else "bridge_h"
  if textures.has(key) and bridge_metadata.has(key):
   var paint = _bridge_paint_geometry(g,textures[key],bridge_metadata[key])
   if not paint.is_empty():
    g["paint"]=paint; g["paint_key"]=key; g.bounds=g.bounds.merge(paint.bounds)
  painted_bridges.append(g)
func bridge_row(low: Vector2i, high: Vector2i, offset: Vector2i, step: Vector2i) -> bool:
 var at = low
 while true:
  if terrain_at(at+offset)!=5: return false
  if at==high: return true
  at+=step
 return false
func _bridge_paint_geometry(geometry: Dictionary, texture: Texture2D, metadata: Dictionary) -> Dictionary:
 if geometry.is_empty(): return {}
 var ends: Array = metadata.get("deck_endpoints",[metadata.get("axis_a",[]),metadata.get("axis_b",[])])
 if ends.size()!=2 or ends[0].size()!=2 or ends[1].size()!=2: return {}
 var a = Vector2(ends[0][0],ends[0][1])
 var b = Vector2(ends[1][0],ends[1][1])
 var span = a.distance_to(b)
 var width = float(metadata.get("source_deck_width",metadata.get("deck_width",0)))
 if span<1 or width<1: return {}
 var u = (b-a)/span
 var v = Vector2(-u.y,u.x)
 var along: Vector2 = geometry.axis*(geometry.half_span*2.0/span)
 var across: Vector2 = geometry.side*(geometry.half_width*2.0/width)
 var transform = Transform2D(along*u.x+across*v.x,along*u.y+across*v.y,Vector2.ZERO)
 transform.origin = geometry.anchor-geometry.axis*geometry.half_span-transform*a
 var size = Vector2(texture.get_size())
 var corners = PackedVector2Array()
 var bounds = Rect2(transform*Vector2.ZERO,Vector2.ZERO)
 for corner in [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]:
  var p = transform*corner
  corners.append(p)
  bounds = bounds.expand(p)
 var vertices = PackedVector3Array()
 for corner in corners: vertices.append(Vector3(corner.x,corner.y,0))
 var arrays = []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
 arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
 var mesh = ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 return {"transform":transform,"corners":corners,"bounds":bounds.grow(3),"mesh":mesh}


func _terrain(at: Vector2i) -> int:
 return terrain_at(at)
func _near_place(p: Vector2, factor: float = 1.0) -> bool:
 for place in c.region.locations:
  if p.distance_to(Vector2(place.x,place.y))<85*factor: return true
 if c.farm.enabled:
  for farm in c.farm.all():
   if p.distance_to(farm.position)<60*factor: return true
 return false
func _road_distance(p: Vector2) -> float:
 var at = c.overworld.cell(p)
 var result = INF
 for y in range(maxi(0,at.y-5),mini(H,at.y+6)):
  for x in range(maxi(0,at.x-5),mini(W,at.x+6)):
   if terrain_at(Vector2i(x,y)) in [4,5]: result=minf(result,p.distance_to(c.overworld.cell_point(Vector2i(x,y))))
 return result
func _landscape_rect_safe(rect: Rect2) -> bool:
 var paint = rect.grow(9)
 if not Rect2(ORIGIN,MAP_SIZE).encloses(paint): return false
 var first = c.overworld.cell(paint.position)
 var last = c.overworld.cell(paint.end)
 for y in range(first.y,last.y+1):
  for x in range(first.x,last.x+1):
   if terrain_at(Vector2i(x,y)) not in [0,1,2,6]: return false
   if _near_place(c.overworld.cell_point(Vector2i(x,y))): return false
 return true

func build_scenery() -> void:
 stamps.clear()
 for y in range(2, H - 2):
  for x in range(2, W - 2):
   var index = y * W + x
   var terrain = terrain_at(Vector2i(x,y))
   var h = _hash(index, 7)
   var p: Vector2 = c.overworld.cell_point(Vector2i(x,y)) + Vector2((_hash(index, 8) - 0.5) * 17, (_hash(index, 9) - 0.5) * 14)
   if _near_place(p):
    continue
   var key = ""
   var width = 0.0
   var height = 0.0
   var mass = _forest_at(p-ORIGIN) if terrain==1 else 0.0
   if terrain == 1 and mass>0.13 and h < 0.16+mass*0.42:
    key = "fir_0%d" % (1 + int(_hash(index,12)*4.0))
    height = lerpf(35.0,110.0,clampf(mass*0.65+_hash(index,10)*0.35,0,1))
    width = height*0.56
   elif terrain == 0 and h < 0.022:
    key = "oak_0%d" % (1 + index % 2)
    width = lerpf(45.0, 63.0, _hash(index, 10))
    height = width * 1.02
   elif terrain in [2,6] and h < 0.07:
    key = "rocks_0%d" % (1 + index % 3)
    width = lerpf(38.0, 82.0, _hash(index, 10))
    height = width * 0.63
   elif terrain == 1 and h > 0.84 and h < 0.90:
    key = "shrub_0%d" % (1 + index % 2)
    width = lerpf(26.0, 42.0, _hash(index, 10))
    height = width * 0.65
   elif terrain == 0 and h > 0.990:
    key = "log_01" if index % 3 == 0 else "shrub_02"
    width = lerpf(24.0, 37.0, _hash(index, 10))
    height = width * 0.5
   if key.is_empty(): continue
   if not textures.has(key): continue
   var canopy_width = height * textures[key].get_width()/float(textures[key].get_height()) if key.begins_with("fir_") else width
   if _road_distance(p) < maxf(22.0,canopy_width*0.5+8.1): continue
   var dims = Vector2(canopy_width,height)
   if not _landscape_rect_safe(Rect2(p-Vector2(dims.x*0.5,dims.y),dims)): continue
   _add_stamp(key, p, dims, index, {})
   if key.begins_with("fir_"):
    stamps[-1]["paint_tint"] = Color.WHITE.lerp(Color(0.76,0.83,0.75,1),smoothstep(0.22,0.80,mass))
 _build_landscape_stamps()
 for place in c.region.locations:
  if place.kind not in ["town"]: continue
  _add_stamp("town_01",Vector2(place.x,place.y)+Vector2(0,60),Vector2(200,150),0,place)
 if c.farm.enabled:
  for farm in c.farm.all(): _add_stamp("farm_01",farm.position+Vector2(0,8),Vector2(116,80),0,{"id":"farm:"+farm.town,"kind":"farm"})
 stamps.sort_custom(func(a,b):return a.foot.y<b.foot.y)
func _build_landscape_stamps() -> void:
 var occupied: Array[Rect2] = []
 # Hash-selected coarse candidates avoid the old per-cell pebble carpet.
 for i in range(1900):
  var foot = ORIGIN+Vector2(80+_hash(i,701)*(MAP_SIZE.x-160),100+_hash(i,702)*(MAP_SIZE.y-140))
  var terrain_type = _terrain(c.overworld.cell(foot-Vector2(0,25)))
  var kind = "ridge"
  var key = "hill_0%d" % (1+i%2)
  var width = lerpf(150,235,_hash(i,703))
  if terrain_type not in [2,6]:
   if i%3 != 0: continue
   var near_water = false
   for offset in [Vector2(40,0),Vector2(-40,0),Vector2(0,40),Vector2(0,-40)]:
    if _terrain(c.overworld.cell(foot+offset)) == 3: near_water = true
   if not near_water: continue
   kind = "bank"
   key = "bank_0%d" % (1+i%2)
   width = lerpf(40,68,_hash(i,703))
  if not textures.has(key):
   key = "rocks_0%d" % (1+i%3) if kind == "ridge" else "shrub_02"
  if not textures.has(key): continue
  var texture: Texture2D = textures[key]
  var size = Vector2(width,width*texture.get_height()/float(texture.get_width()))
  var rect = Rect2(foot-Vector2(size.x*0.5,size.y),size)
  if kind == "ridge" and _terrain(c.overworld.cell(rect.get_center())) not in [2,6]: continue
  if not _landscape_rect_safe(rect): continue
  var overlap = false
  for other in occupied:
   if rect.grow(30).intersects(other): overlap = true; break
  if overlap: continue
  _add_stamp(key,foot,size,i,{})
  stamps[-1]["landscape_kind"] = kind
  occupied.append(rect)

func _add_stamp(key: String, foot: Vector2, dimensions: Vector2, salt: int, place: Dictionary) -> void:
 if textures.has(key):
  var aspect = textures[key].get_width() / float(textures[key].get_height())
  if key.begins_with("fir_"):
   dimensions.x = dimensions.y * aspect
  else:
   dimensions.y = dimensions.x / aspect
 if not place.is_empty():
  # Retain the real landmark anchor; fit edge towns inside known-world bounds.
  var horizontal = 2.0*minf(foot.x-ORIGIN.x-12.0,ORIGIN.x+MAP_SIZE.x-foot.x-12.0)
  var vertical = foot.y-ORIGIN.y-12.0
  var fit = minf(1.0,minf(horizontal/dimensions.x,vertical/dimensions.y))
  dimensions *= maxf(0.01,fit)
 var rect = Rect2(foot - Vector2(dimensions.x * 0.5, dimensions.y), dimensions)
 var bounds = rect.grow(6)
 stamps.append({"key":key,"foot":foot,"rect":rect,"bounds":bounds.grow(3),"salt":salt,"place":place,"knowledge":0})
func _draw_stamp(stamp: Dictionary) -> void:
 var key: String = stamp.key
 if not textures.has(key):
  return # Missing supplied paintings remain an honest omission, never stub art.
 var tint = (Color.WHITE if int(stamp.get("paint_knowledge",stamp.knowledge)) == 2 else Color(0.80, 0.82, 0.76, 1)) * stamp.get("paint_tint",Color.WHITE)
 var foot: Vector2 = stamp.foot
 var rect: Rect2 = stamp.rect
 var size_factor = 0.28 if stamp.place.is_empty() else 0.40
 _draw_ellipse(foot + Vector2(5, -1), Vector2(rect.size.x * size_factor, 7), Color(0.15, 0.20, 0.13, 0.16))
 draw_texture_rect(textures[key], rect, false, tint)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
 var polygon = PackedVector2Array()
 for i in range(20):
  var angle = TAU * i / 20.0
  polygon.append(center + Vector2(cos(angle), sin(angle)) * radius)
 draw_colored_polygon(polygon, color)


func resource_tokens() -> Dictionary:
 # Fixed conceptual slots only: never enumerate hidden objects/counts in public.
 return {"ground":str(ground_texture.get_instance_id()),"material":str(landscape.ground_sprite.material.get_instance_id()),"roads":str(road_meshes[0].get_instance_id()),"water":str(water_meshes[0].get_instance_id()),"bridge":str(painted_bridges[0].paint.mesh.get_instance_id()) if not painted_bridges.is_empty() and painted_bridges[0].has("paint") else "","paint":str(textures["town_01"].get_instance_id()) if textures.has("town_01") else "","fog":str(fog_texture.get_instance_id())}
func _hash(i: int, salt: int) -> float:
 # Integer-local decoration source: no global/world RNG calls, including draw.
 var n = posmod(i * 374761393 + seed_value * 668265263 + salt * 6041729, 2147483647)
 n = posmod((n ^ (n >> 13)) * 1274126177, 2147483647)
 return float(n) / 2147483647.0

