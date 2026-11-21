extends RefCounted
## Presentation-only port of the accepted cohesion road paint.
## Campaign owns every path; this adapter never changes terrain or navigation.
var painter
var road_segments: Array = []
var river_source = PackedVector2Array()
var river_layers: Array = []
var river_meshes: Array = []
var river_currents: Array = []
var painted_river_points = PackedVector2Array()
func _terrain(at: Vector2i) -> int: return painter.terrain_at(at)
func _hash(i: int, salt: int) -> float: return painter._hash(i,salt)
func build_rivers() -> Dictionary:
 var meshes: Array = []; var currents: Array = []; var polygons: Array = []
 for district in 2:
  river_source = PackedVector2Array()
  var low = painter.ORIGIN.x+district*58*painter.CELL
  for raw in painter.c.region.river:
   if raw[0]>=low and raw[0]<low+58*painter.CELL:
    river_source.append(Vector2(raw[0],raw[1]))
  if river_source.size()<2: continue
  _build_river_paint()
  meshes.append_array(river_meshes); currents.append_array(river_currents)
  polygons.append(river_layers[2])
 return {"meshes":meshes,"currents":currents,"polygons":polygons}
func land_safe(p: Vector2) -> bool:
 var at = painter.c.overworld.cell(p)
 return Rect2i(0,0,painter.W,painter.H).has_point(at) and painter.terrain_at(at) not in [3,5,6]
func _road_link_safe(a: Vector2, b: Vector2) -> bool:
 var steps = maxi(1, ceili(a.distance_to(b)/3.0))
 for i in range(steps+1):
  var p = a.lerp(b,float(i)/steps)
  var nearest = INF
  for segment in painter.c.overworld.roads:
   nearest = minf(nearest,p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1])))
  if nearest > 8.0: return false
  for k in 8:
   if not land_safe(p+Vector2.from_angle(k*TAU/8)*7.5): return false
 return true
func build_roads() -> Array:
 var result: Array = []
 for road in painter.c.region.road_paths:
  var segment = PackedVector2Array()
  for raw in road.points:
   var point = Vector2(raw[0],raw[1])
   if not land_safe(point):
    if segment.size()>1:
     var painted = _paint_road(segment)
     road_segments.append(painted); result.append(_road_mesh(painted,result.size()))
    segment = PackedVector2Array()
   else: segment.append(point)
  if segment.size()>1:
   var painted = _paint_road(segment)
   road_segments.append(painted); result.append(_road_mesh(painted,result.size()))
 return result

func _simplify_road(points: PackedVector2Array) -> PackedVector2Array:
 if points.size() <= 2:
  return points
 var farthest = 1
 var deviation = -1.0
 for i in range(1, points.size() - 1):
  var d = points[i].distance_to(Geometry2D.get_closest_point_to_segment(points[i], points[0], points[-1]))
  if d > deviation:
   deviation = d
   farthest = i
 if deviation <= 12.0 and _road_link_safe(points[0], points[-1]):
  return PackedVector2Array([points[0], points[-1]])
 if deviation < 0.1: farthest = points.size() / 2
 var left = _simplify_road(points.slice(0, farthest + 1))
 left.append_array(_simplify_road(points.slice(farthest)).slice(1))
 return left


func _paint_road(points: PackedVector2Array) -> PackedVector2Array:
 var simple = _simplify_road(points)
 var rounded = _smooth_polyline(simple, 3)
 for i in range(1, rounded.size()):
  if not _road_link_safe(rounded[i - 1], rounded[i]):
   return simple # Never round a bank corner through physical water.
 return rounded


func _road_mesh(points: PackedVector2Array, salt: int) -> ArrayMesh:
 var samples = PackedVector2Array([points[0]])
 for i in range(1, points.size()):
  var steps = maxi(1, ceili(points[i - 1].distance_to(points[i]) / 7.0))
  for j in range(1, steps + 1):
   samples.append(points[i - 1].lerp(points[i], float(j) / steps))
 var vertices = PackedVector3Array()
 var colors = PackedColorArray()
 var indices = PackedInt32Array()
 for i in range(samples.size()):
  var tangent = (samples[mini(i + 1, samples.size() - 1)] - samples[maxi(0, i - 1)]).normalized()
  var side = Vector2(-tangent.y, tangent.x)
  var weather = 0.5+0.5*sin(samples[i].x/51.0+samples[i].y/83.0+salt*1.7)
  var width = 5.9 + weather * 1.0
  var tint = Color("dcc49a").lerp(Color("e7d2a3"),weather*0.5)
  # Wear is a small cross-road value change, not a sequence of dark
  # perpendicular rungs. The centre keeps some earth/grass showing.
  for lane in range(9):
   var offset = [-1.0,-0.78,-0.50,-0.30,0.0,0.30,0.50,0.78,1.0][lane]
   var p = samples[i] + side * width * float(offset)
   vertices.append(Vector3(p.x, p.y, 0))
   var c = Color("766149") if lane in [1,7] else Color("b49265") if lane in [3,5] else tint
   c.a = [0.0,0.96,0.78,0.62,0.90,0.62,0.78,0.96,0.0][lane]
   if lane>0 and lane<8: c.a = minf(1.0,c.a+weather*0.04)
   colors.append(c)
  if i > 0:
   for lane in range(8):
    var a = (i - 1) * 9 + lane
    indices.append_array(PackedInt32Array([a, a + 1, a + 9, a + 1, a + 10, a + 9]))
 var arrays = []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_COLOR] = colors
 arrays[Mesh.ARRAY_INDEX] = indices
 var mesh = ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
 return mesh


func _smooth_polyline(points: PackedVector2Array, passes: int) -> PackedVector2Array:
 var output = points.duplicate()
 for iteration in range(passes):
  if output.size() < 3:
   break
  var rounded = PackedVector2Array([output[0]])
  for i in range(output.size() - 1):
   rounded.append(output[i].lerp(output[i + 1], 0.25))
   rounded.append(output[i].lerp(output[i + 1], 0.75))
  rounded.append(output[-1])
  output = rounded
 return output


func _build_river_paint() -> void:
 river_layers.clear()
 river_meshes.clear()
 river_currents.clear()
 # Each bank is sampled from its OWN physical edge, then low-pass filtered
 # along the monotone river axis. Never offset along a tight local normal.
 var source: PackedVector2Array = river_source
 var span = source[-1] - source[0]
 var along = Vector2.RIGHT if absf(span.x) > absf(span.y) else Vector2.DOWN
 var cross_axis = Vector2.DOWN if along == Vector2.RIGHT else Vector2.RIGHT
 var edges: Array[Vector2] = []
 for p in source:
  var pair = Vector2.ZERO
  for side in range(2):
   var sign_value = 1.0 if side == 0 else -1.0
   var extent = 16.0
   var query = p
   for d in range(0, 129, 2):
    var t = _terrain(painter.c.overworld.cell(query + cross_axis * d * sign_value))
    if t not in [3,5] and d > 8: break
    extent = d
   pair[side] = p.dot(cross_axis) + sign_value * (extent + 1.0)
  edges.append(pair)
 var smooth_edges: Array[Vector2] = []
 for i in range(edges.size()):
  var total = Vector2.ZERO
  for j in range(-4,5): total += edges[clampi(i+j,0,edges.size()-1)] * float(5-absi(j))
  smooth_edges.append(total/25.0)
 var road_probes = PackedVector2Array()
 for road in road_segments:
  for j in range(1,road.size()):
   var steps = maxi(1,ceili(road[j-1].distance_to(road[j])/5.0))
   for k in range(steps+1): road_probes.append(road[j-1].lerp(road[j],float(k)/steps))
 painted_river_points = _smooth_polyline(source,3)
 for layer in range(4):
  var plus = PackedVector2Array()
  var minus = PackedVector2Array()
  for p in painted_river_points:
   var distance = p.dot(along)
   var f = clampf((distance-source[0].dot(along)) / painter.CELL, 0, source.size()-1)
   var index = floori(f)
   var edge = smooth_edges[index].lerp(smooth_edges[mini(index+1,source.size()-1)], f-index)
   # Slow, independent lobes: shallow shelves and vegetation differ on
   # either bank instead of making a nested constant-width contour map.
   var phase = float(posmod(painter.seed_value,101))
   var a = sin(distance/53.0+phase)*2.5 + sin(distance/119.0)*2.0
   var b = sin(distance/71.0-phase)*2.5 + cos(distance/97.0)*2.0
   var extra_a = [9.0+sin(distance/37.0)*3.0,3.5+sin(distance/61.0)*2.0,0.0,-1.5][layer]
   var extra_b = [10.0+cos(distance/49.0)*3.0,3.5+cos(distance/43.0)*2.0,0.0,-1.5][layer]
   var positive = edge.x+a
   var negative = edge.y+b
   for q in road_probes:
    var d = absf(q.dot(along)-distance)
    if d>64.0: continue
    var c = q.dot(cross_axis)
    if c>p.dot(cross_axis): positive=minf(positive,c-7.0+d*d/12.0)
    else: negative=maxf(negative,c+7.0-d*d/12.0)
   plus.append(p + cross_axis * (positive+extra_a-p.dot(cross_axis)))
   minus.append(p + cross_axis * (negative-extra_b-p.dot(cross_axis)))
  # Round road-avoidance envelopes in the same shared spatial domain;
  # the seven-pixel road inset above leaves room for this small filter.
  var rounded_plus = plus.duplicate()
  var rounded_minus = minus.duplicate()
  for i in range(plus.size()):
   var a = 0.0
   var b = 0.0
   for j in range(-4,5):
    var k = clampi(i+j,0,plus.size()-1)
    a += plus[k].dot(cross_axis)*float(5-absi(j))
    b += minus[k].dot(cross_axis)*float(5-absi(j))
   rounded_plus[i] += cross_axis*(a/25.0-plus[i].dot(cross_axis))
   rounded_minus[i] += cross_axis*(b/25.0-minus[i].dot(cross_axis))
  rounded_minus.reverse()
  rounded_plus.append_array(rounded_minus)
  river_layers.append(rounded_plus)
 river_meshes.append(_river_margin_mesh(river_layers[0],river_layers[1],Color("6c7250"),0))
 river_meshes.append(_river_margin_mesh(river_layers[1],river_layers[2],Color("77755b"),1))
 river_meshes.append(_polygon_mesh(river_layers[2],Color("435d59")))
 river_meshes.append(_polygon_mesh(river_layers[3],Color(0.95,0.98,0.96,0.97)))
 var run = 0.0
 var stroke_index = 0
 for i in range(1,painted_river_points.size()-1):
  run += painted_river_points[i-1].distance_to(painted_river_points[i])
  if run < 22.0 + _hash(stroke_index,121)*20.0: continue
  run = 0
  stroke_index += 1
  var p = painted_river_points[i]
  var tangent = (painted_river_points[i+1]-painted_river_points[i-1]).normalized()
  var normal = Vector2(-tangent.y,tangent.x)
  var q = p + normal * ((_hash(stroke_index,122)-0.5)*48.0)
  var length = 6.0 + _hash(stroke_index,123)*17.0
  var curve = (_hash(stroke_index,124)-0.5)*6.0
  var points = PackedVector2Array()
  var safe = true
  for j in range(5):
   var t = float(j)/4.0
   var v = q+tangent*(t-0.5)*length+normal*sin(t*PI)*curve
   points.append(v)
   if not Geometry2D.is_point_in_polygon(v,river_layers[3]): safe=false
  if safe: river_currents.append({"points":points,"color":Color(0.92,0.90,0.75,0.42+_hash(stroke_index,125)*0.18),"width":0.65+_hash(stroke_index,126)*0.5})


func _river_margin_mesh(outer: PackedVector2Array, inner: PackedVector2Array, tint: Color, salt: int) -> ArrayMesh:
 var vertices = PackedVector3Array()
 var colors = PackedColorArray()
 var indices = PackedInt32Array()
 for i in range(outer.size()):
  var p = outer[i]
  var q = inner[i]
  var variation = 0.5+0.5*sin(p.x/33.0+p.y/47.0+salt*2.7)
  vertices.append(Vector3(p.x,p.y,0))
  vertices.append(Vector3(q.x,q.y,0))
  colors.append(Color(tint,0.0))
  colors.append(Color(tint,0.12+variation*0.32))
  if i>0:
   var a = (i-1)*2
   indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
 var arrays=[]
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices
 arrays[Mesh.ARRAY_COLOR]=colors
 arrays[Mesh.ARRAY_INDEX]=indices
 var mesh=ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 return mesh


func _polygon_mesh(polygon: PackedVector2Array, color: Color) -> ArrayMesh:
 var mesh = ArrayMesh.new()
 var indices = Geometry2D.triangulate_polygon(polygon)
 if indices.is_empty():
  push_error("Generated river bank is not triangulatable")
  return mesh
 var vertices = PackedVector3Array()
 var colors = PackedColorArray()
 var uvs = PackedVector2Array()
 for p in polygon:
  vertices.append(Vector3(p.x, p.y, 0))
  uvs.append(p / 192.0)
  colors.append(color)
 var arrays = []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_COLOR] = colors
 arrays[Mesh.ARRAY_INDEX] = indices
 arrays[Mesh.ARRAY_TEX_UV] = uvs
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
 return mesh

