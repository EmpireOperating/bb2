extends RefCounted
## Compose relief, obstruction cores and passable routes in the
## opening's native hex frame. Presentation consumes ordinary authored tiles.
const Axis = preload("res://outdoor_fields/axis_layout.gd")
const SIZE := 32
const AREA := SIZE * SIZE
const STEPS := [Vector2i(-1,0),Vector2i(1,0),Vector2i(-1,-1),Vector2i(0,-1),Vector2i(-1,1),Vector2i(0,1)]
enum { FIRM, GROVE, SCREE, TRACK }
const MATERIALS := ["", "forest", "rocks", "road"]
const FOREST_CAMP_CENTER := Vector2i(15,15)
const GATE_ARMS := [Vector2i(0,-4),Vector2i(0,-3),Vector2i(0,-2),
 Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,-5),Vector2i(2,-5),
 Vector2i(1,2),Vector2i(2,1)]

class Landform:
 var at: Vector2
 var along: Vector2
 var across: Vector2
 var crest: int
 var core: float
 var material: int

 func contour(p: Vector2) -> float:
  var delta := p-at
  var u := delta.dot(along)
  var v := delta.dot(across)
  # A slight skew breaks the perfect elliptical outline at landform scale.
  return u*u+v*v+0.10*u*v*v

class Route:
 var row: float
 var reach: float
 var width: float
 var bend: float
 var phase: float
 var verge: float

 func at(u: float) -> float:
  return lerpf(row+bend*sin(u*.23+phase),verge,smoothstep(9.0,23.0,absf(u)))

static func _rng(n: int, salt: int) -> RandomNumberGenerator:
 var rng := RandomNumberGenerator.new()
 rng.seed = n ^ salt
 return rng

static func _landform(rng: RandomNumberGenerator, at: Vector2, half_size: Vector2, crest: int, core: float, material: int) -> Landform:
 var f := Landform.new()
 var slope := Vector2.from_angle(rng.randf_range(-0.65,0.65))
 f.at=at
 f.along=slope/half_size.x
 f.across=slope.orthogonal()/half_size.y
 f.crest=crest
 f.core=core
 f.material=material
 return f

static func _landforms(rng: RandomNumberGenerator, ridge: bool) -> Array[Landform]:
 var forms: Array[Landform] = []
 var material := SCREE if ridge else GROVE
 var shoulder := 1.0 if rng.randf()<.5 else -1.0
 var focal_row := rng.randf_range(-1.4,1.4)
 if rng.randf() < (.26 if ridge else .20):focal_row+=shoulder*rng.randf_range(4.0,7.3)
 forms.append(_landform(rng,Vector2(rng.randf_range(-1.5,1.5),focal_row),
  Vector2(rng.randf_range(2.8,4.4),rng.randf_range(4.9,7.1)),2,rng.randf_range(.35,.52),material))
 # A second landform can overlap the first, enclose a glade, or leave a
 # saddle between two heights. These are stamps with shape, not map modes.
 if rng.randf()<.80:
  forms.append(_landform(rng,Vector2(rng.randf_range(-4.6,4.6),shoulder*rng.randf_range(3.6,7.9)),
   Vector2(rng.randf_range(2.2,4.5),rng.randf_range(2.5,4.8)),2,rng.randf_range(.22,.45),material))
 for side: float in [-1.0,1.0]:
  # Approach shelves on both sides retain accessible relief even when the
  # middle is open. Their independently rolled angles and widths matter.
  forms.append(_landform(rng,Vector2(side*rng.randf_range(6.0,9.5),rng.randf_range(-6.8,6.8)),
   Vector2(rng.randf_range(3.2,5.5),rng.randf_range(3.7,6.0)),2,rng.randf_range(.09,.20),material))
  for i in rng.randi_range(1,2):
   forms.append(_landform(rng,Vector2(rng.randf_range(-14.0,14.0),side*rng.randf_range(8.5,14.0)),
    Vector2(rng.randf_range(3.1,6.6),rng.randf_range(3.1,6.1)),2 if ridge or i==0 else 1,rng.randf_range(.18,.34),material))
 return forms

static func _route(rng: RandomNumberGenerator, row: float, width: float, reach: float) -> Route:
 var r := Route.new()
 r.row=row
 r.width=width
 r.reach=reach
 r.bend=rng.randf_range(.35,1.1)
 r.phase=rng.randf_range(0,TAU)
 r.verge=rng.randf_range(-2.8,2.8)
 return r

static func _routes(rng: RandomNumberGenerator) -> Array[Route]:
 var side := 1.0 if rng.randf()<.5 else -1.0
 var routes: Array[Route] = []
 # The approach, opposite pass and central glade vary independently of
 # the relief. Vary wear width and the far outlet, not merely the row.
 if rng.randf()<.40:
  routes.append(_route(rng,rng.randf_range(-.7,.7),rng.randf_range(1.8,2.9),11.0))
 routes.append(_route(rng,side*rng.randf_range(3.7,5.0),rng.randf_range(1.25,2.1),rng.randf_range(8.0,12.0)))
 var other := rng.randf_range(3.6,5.4) if rng.randf()<.58 else rng.randf_range(8.0,10.0)
 routes.append(_route(rng,-side*other,rng.randf_range(1.2,2.0),rng.randf_range(8.0,13.0)))
 return routes

static func compose(n: int, family: String, title: String, road: bool, fixed_center: Vector2i = Vector2i.ZERO) -> Dictionary:
 var ridge := family=="ridge"
 var opening_rng := _rng(n,0x1a73e549)
 var center := Vector2i(opening_rng.randi_range(14,17),opening_rng.randi_range(14,17))
 if fixed_center!=Vector2i.ZERO:center=fixed_center
 var origin := Axis.axial(center)
 var axis := Axis.ordinary(center)
 var pads := {}
 for p: Vector2i in Axis.company_pad(axis)+Axis.enemy_pad(axis)+Axis.first_band(axis):pads[p]=true
 var relief_rng := _rng(n,0x60a655cb)
 var forms := _landforms(relief_rng,ridge)
 var routes := _routes(_rng(n,0x138e6fa7))
 var bypass: Route = routes.back()
 if absf(bypass.row)>7.0:
  # A wide swing leaves a connected wooded/stony shoulder on its inside.
  # Without this landform, the empty space left by a missing near pass
  # would often become a second equally cheap passage by accident.
  forms.append(_landform(relief_rng,Vector2(relief_rng.randf_range(-1.7,1.7),bypass.row*relief_rng.randf_range(.45,.64)),
   Vector2(relief_rng.randf_range(2.8,4.1),relief_rng.randf_range(4.1,5.5)),2,relief_rng.randf_range(.43,.60),SCREE if ridge else GROVE))
 var goal := Axis.offset(origin+Vector2i(0,roundi(routes[0].at(0))))

 # One column cache in true axial q (range -15..31). Road uses the primary
 # route, including past the fight; other trails taper into the landscape.
 var lane_rows := PackedVector3Array()
 lane_rows.resize(48)
 for col in lane_rows.size():
  var u := float(col-16-origin.x)
  var y := Vector3(INF,INF,INF)
  for r in routes.size():
   if (r==0 and road) or absf(u)<=routes[r].reach:y[r]=routes[r].at(u)
  lane_rows[col]=y

 var height := PackedByteArray()
 var surface := PackedByteArray()
 var solid := PackedByteArray()
 height.resize(AREA);surface.resize(AREA);solid.resize(AREA)
 for y in SIZE:
  for x in SIZE:
   var i := y*SIZE+x
   var p := Vector2i(x,y)
   var q := x-(y>>1)
   var u := q-origin.x
   var local := Vector2(u,y-origin.y+u*.5)
   var path := lane_rows[q+16]
   var on_road := road and absf(local.y-path.x)<=1.05
   if on_road:surface[i]=TRACK
   if pads.has(p) or p==goal or on_road:continue
   var corridor := false
   for r in routes.size():
    if absf(local.y-path[r])<=routes[r].width:corridor=true;break
   # Saddles stay low between the fronts. The same trail can climb a
   # near-side terrace rather than scraping away the whole approach shelf.
   if corridor and absi(u)<6:continue
   var hardness := 0.0
   for f: Landform in forms:
    # The stamps are local; avoid sampling distant ones in the hot loop.
    if absf(local.x-f.at.x)>9.5 or absf(local.y-f.at.y)>9.5:continue
    var contour := f.contour(local)
    if contour>=1.0:continue
    height[i]=maxi(height[i],f.crest if contour<.65 else 1)
    if contour<.82 and (f.material==GROVE or contour<.52):surface[i]=f.material
    hardness=maxf(hardness,f.core-contour)
   if corridor:surface[i]=FIRM
   elif hardness>0.0 and x>0 and x<SIZE-1 and y>0 and y<SIZE-1:solid[i]=1

 # A one-hex skirt makes every neighboring walkable height transition legal.
 # A single bounded graph repair opens short breaches instead of discarding
 # the seed, erasing relief, or falling back to a different deployment axis.
 _grade_and_link(height,solid)
 var tiles := {}
 var presentation := {"biome":"ridge" if ridge else "woodland","road":[],"stream":[],"bridges":[],"keep":[],"opening_axis":axis}
 for y in SIZE:
  for x in SIZE:
   var i := y*SIZE+x
   var k := "%d,%d"%[x,y]
   var tag: String = MATERIALS[surface[i]] if surface[i]!=FIRM else "hill" if height[i]>0 else "grass"
   var tile := {"terrain":tag,"height":height[i]}
   if solid[i]:
    tile.terrain="rocks" if ridge else "forest"
    tile.obstacle="boulder" if ridge else "tree"
    tile.blocked=true
    tile.vision_blocking=true
   if surface[i]==TRACK:presentation.road.append(k)
   tiles[k]=tile
 return {"id":family+"_field","title":title,"width":SIZE,"height":SIZE,"goal":goal,"spawns":Axis.descriptor_spawns(axis),"tiles":tiles,"presentation":presentation}

# V4 only: a west-facing broken gate and two return walls enclose an open
# yard. Keep the masonry at fixed hexes so the ruin reads as one place.
static func forest_camp(n: int, road: bool) -> Dictionary:
 var d := compose(n,"forest","Broken Gate",road,FOREST_CAMP_CENTER)
 d.presentation["landmark"]="forest_broken_gate"
 var origin := Axis.axial(FOREST_CAMP_CENTER)
 for u in range(-5,7):
  for v in range(-7,8):
   if absf(v+u*.5)>5.5:continue
   var k := _camp_key(origin,Vector2i(u,v))
   d.tiles[k]={"terrain":"grass","height":0}
 for at: Vector2i in GATE_ARMS:
  var k := _camp_key(origin,at)
  d.tiles[k]={"terrain":"wall","height":0,"obstacle":"wall","blocked":true,"vision_blocking":true}
  if at in [Vector2i(0,-2),Vector2i(0,0)]:d.presentation.keep.append(k)
 d.goal=Axis.offset(origin+Vector2i(2,-1))
 _camp_ground(d,origin,[Vector2i(1,-1),Vector2i(2,-1)],"stone")
 # Change the costs and sight lines of the approaches, never the stones.
 # The breach is a passage in all three cases, not a rotating door.
 match n%3:
  0: # Worn gate apron: the quick, exposed route into the court.
   _camp_ground(d,origin,[Vector2i(-2,0),Vector2i(-2,1),Vector2i(-1,0),Vector2i(0,-1)],"stone")
   _camp_ground(d,origin,[Vector2i(-2,-3),Vector2i(-1,-3),Vector2i(0,-5),Vector2i(-1,4),Vector2i(1,4)],"forest",0,"tree")
  1: # Leaf-screened hook: south return is low and quick; debris slows the gate.
   _camp_ground(d,origin,[Vector2i(-2,0),Vector2i(-1,0),Vector2i(0,-1)],"rubble")
   _camp_ground(d,origin,[Vector2i(-2,-2),Vector2i(-1,-3),Vector2i(0,-5),Vector2i(1,0),Vector2i(1,1),Vector2i(0,4)],"forest",0,"tree")
  2: # High spur: standable ledge over the north return, rough lower ground.
   _camp_ground(d,origin,[Vector2i(-2,0),Vector2i(-1,0),Vector2i(0,-1)],"rubble")
   _camp_ground(d,origin,[Vector2i(-2,-2),Vector2i(-2,-3),Vector2i(-1,-3),Vector2i(-1,-4),
    Vector2i(-1,-5),Vector2i(0,-5),Vector2i(0,-6),Vector2i(1,-6),Vector2i(2,-6),Vector2i(3,-6)],"hill",1)
   _camp_ground(d,origin,[Vector2i(-2,3),Vector2i(-1,3),Vector2i(0,4)],"forest",0,"tree")
 d.presentation.road=d.presentation.road.filter(func(k):return d.tiles[k].terrain=="road")
 # Grade the stamp's joins into the inherited landscape. Lowering only high
 # edge cells keeps native one-level edges without changing its path rules.
 for k: String in d.tiles:
  if d.tiles[k].height!=2:continue
  var x := int(k.get_slice(",",0))
  var y := int(k.get_slice(",",1))
  for step: Vector2i in STEPS:
   var neighbor := "%d,%d"%[x+step.x+((y&1) if step.y else 0),y+step.y]
   if d.tiles.get(neighbor,{}).get("height",2)==0:d.tiles[k].height=1;break
 return d

# Battle-only overlay on the v7 stamp. Do not attach this to the bound
# descriptor: old pending Forest checkpoints must reconstruct exact bytes.
static func broken_gate_work_cells(n: int) -> Dictionary:
 var origin := Axis.axial(FOREST_CAMP_CENTER)
 var tree := Vector2i(-2,3) if n%3==2 else Vector2i(-1,-3)
 return {"wood":Axis.offset(origin+tree),"stone":Axis.offset(origin+Vector2i(0,-3))}

static func _camp_ground(d: Dictionary, origin: Vector2i, area: Array, tag: String, height: int = 0, obstacle: String = "") -> void:
 for at: Vector2i in area:
  var tile := {"terrain":tag,"height":height}
  if not obstacle.is_empty():tile.merge({"blocked":true,"vision_blocking":true,"obstacle":obstacle})
  d.tiles[_camp_key(origin,at)]=tile

static func _camp_key(origin: Vector2i, at: Vector2i) -> String:
 var p := Axis.offset(origin+at)
 return "%d,%d"%[p.x,p.y]

static func _grade_and_link(height: PackedByteArray, solid: PackedByteArray) -> void:
 var seen := PackedByteArray()
 seen.resize(AREA)
 var queue := PackedInt32Array()
 queue.resize(AREA)
 var end := 1
 var read := 0
 seen[0]=1 # No solid tiles on the edge; this entire ring supplies exits.
 for i in AREA:
  if height[i]!=2:continue
  var x := i%SIZE
  var y := i/SIZE
  for step: Vector2i in STEPS:
   var xx := x+step.x+((y&1) if step.y else 0)
   var yy := y+step.y
   if xx<0 or xx>=SIZE or yy<0 or yy>=SIZE:continue
   if height[yy*SIZE+xx]==0:height[i]=1;break
 for i in AREA:
  while read<end:
   var at := queue[read]
   read+=1
   var x := at%SIZE
   var y := at/SIZE
   for step: Vector2i in STEPS:
    var xx := x+step.x+((y&1) if step.y else 0)
    var yy := y+step.y
    if xx<0 or xx>=SIZE or yy<0 or yy>=SIZE:continue
    var to := yy*SIZE+xx
    if seen[to] or solid[to]:continue
    seen[to]=1
    queue[end]=to
    end+=1
  if seen[i] or solid[i]:continue
  # The row always ends at a reached exit. Choose the nearest place to
  # breach the reachable side of the pocket, retaining native terrain AP.
  var west := i-1
  var east := i+1
  while not seen[west]:west-=1
  while not seen[east]:east+=1
  var step := -1 if i-west<=east-i else 1
  var at := i
  while not seen[at]:
   solid[at]=0
   at+=step
  seen[i]=1
  queue[end]=i
  end+=1
