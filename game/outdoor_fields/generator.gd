extends RefCounted
## Local relief, routes and obstruction clusters on the same board consumed by Battle.
## Version this recipe rather than changing already-bound encounter geometry.
const LEGACY_VERSION := "march_ground_v1"
const AXIS_VERSION := "march_ground_v2"
const VERSION := "march_ground_v3"
const RECIPES := [LEGACY_VERSION,AXIS_VERSION,VERSION]
const SIZE := 32
const NAMES := {"ford":"River Crossing", "ridge":"Broken Ridge", "forest":"Wooded Hollow", "plains":"Open Heath"}
const REACH_TITLES := {"stone_span":"Tollhouse Span", "reed_shoal":"Reed Gate Shoal", "spring_cut":"Packhorse Heights"}
const Fingerprint = preload("res://procedural_woodland/generator.gd")
const Axis = preload("res://outdoor_fields/axis_layout.gd")
const Composer = preload("res://outdoor_fields/layout_composer.gd")

static func binding(p:Dictionary,kind:String) -> Dictionary:
 return {"recipe":p.recipe+"/"+kind+"/"+p.family,"seed":p.seed,"fingerprint":p.fingerprint}

static func composed_family(family:String) -> bool:
 return family in ["forest","ridge"]

static func axial_recipe(recipe:Variant) -> bool:
 return recipe in [AXIS_VERSION,VERSION]

static func generate(n:int,family:String,road:bool,ambush:bool,recipe:String=LEGACY_VERSION) -> Dictionary:
 if n<0 or n>0x7fffffff or (not NAMES.has(family) and not REACH_TITLES.has(family)):return {}
 if recipe not in RECIPES:return {}
 if recipe==VERSION and (ambush or not composed_family(family)):return {}
 var d := Composer.compose(n,family,NAMES[family],road) if recipe==VERSION else _build(n,family,road,ambush,recipe==AXIS_VERSION)
 if axial_recipe(recipe) and Axis.reserved(d).is_empty():return {}
 return {"recipe":recipe,"family":family,"seed":n,"road":road,"ambush":ambush,"descriptor":d,"fingerprint":Fingerprint.descriptor_fingerprint(d)}

static func valid(p:Dictionary) -> bool:
 if p.size()!=7 or p.get("recipe") not in RECIPES or not p.get("seed") is int or not p.get("family") is String or not p.get("road") is bool or not p.get("ambush") is bool:return false
 return p==generate(p.seed,p.family,p.road,p.ambush,p.recipe)

static func key(p:Vector2i) -> String:return "%d,%d"%[p.x,p.y]
static func axial(p:Vector2i) -> Vector2i:return Vector2i(p.x-(p.y>>1),p.y)
static func offset(a:Vector2i) -> Vector2i:return Vector2i(a.x+(a.y>>1),a.y)
static func floor_tile(tag:String,h:int=0) -> Dictionary:return {"terrain":tag,"height":h}

# Reserve the actual 18-slot player template, enemy roles and stock24 admission
# footprint, not a featureless rectangle across the middle of every battle.
static func deployment_ground(a:Vector2i,b:Vector2i,ambush:bool,center:Vector2i) -> Dictionary:
 var pad:={}
 for anchor:Vector2i in [a,b]:
  var back:=-1 if anchor==a else 1
  for dy in range(-4,5):
   for rank in 2:pad[offset(axial(anchor)+Vector2i(back*rank,dy))]=true
  for dx in 3:
   for dy in range(-2,3):pad[anchor+Vector2i(back*dx,dy)]=true
 if ambush:
  # Common translation of the native cluster/wings (stock centre 5,5).
  for y in range(2,8):
   for x in range(2,8):pad[offset(axial(Vector2i(x,y))-axial(Vector2i(5,5))+axial(center))]=true
 return pad

static func _build(n:int,family:String,road:bool,ambush:bool,canonical:bool) -> Dictionary:
 var reach:=family if REACH_TITLES.has(family) else ""
 if not reach.is_empty():family="ford"
 var rng:=RandomNumberGenerator.new();rng.seed=n
 var center:=Vector2i(rng.randi_range(14,17),rng.randi_range(13,18))
 var a:=center+Vector2i(-4,0);var b:=center+Vector2i(4,0)
 # At a river ambush both wings deploy on the same bank. Terrain stays intact.
 var stream_x:=center.x+(8 if ambush else -1 if not reach.is_empty() else 0)
 var pad:=deployment_ground(a,b,ambush,center)
 var spawns:=[]
 for anchor:Vector2i in [a,b]:
  var dx:=-1 if anchor==a else 1
  for delta:Vector2i in [Vector2i.ZERO,Vector2i.UP,Vector2i.DOWN,Vector2i(dx,0),Vector2i(dx,dx),Vector2i(dx,-dx)]:spawns.append(anchor+delta)
 var phase:=rng.randf_range(0,TAU);var bend:=rng.randf_range(0,TAU)
 var bridge_y:=center.y+rng.randi_range(-2,2)
 var shallows:=[bridge_y-rng.randi_range(3,6),bridge_y+rng.randi_range(3,6)]
 # Each district leaves a different opening on the approach bank. One wade is
 # within scouting sight; the other is a longer flank, not a second free bridge.
 match reach:
  "stone_span":bridge_y=center.y-1;shallows=[bridge_y-3,bridge_y+5]
  "reed_shoal":bridge_y=center.y-4;shallows=[center.y,bridge_y+8]
  "spring_cut":bridge_y=center.y-3;shallows=[center.y+1,bridge_y-4]
 var spine:=center.x+rng.randi_range(-1,1);var saddle:=center.y+rng.randi_range(-3,3)
 var muster := center
 if canonical:
  if family=="ridge":muster.y=saddle
  if family=="ford" and not ambush:
   # Fit the opposing pads to the actual river before placing terrain. Give
   # the span a road approach; keep the reed and spring wades closer than
   # their bridges. Full extreme columns stay on their own banks.
   stream_x=center.x
   match reach:
    "stone_span":muster.y=bridge_y-2
    "reed_shoal":
     # The native nearest approach from behind the front rank reaches the
     # southern gravel tip, not the tile directly behind an occupied slot.
     muster.y=shallows[0]-2
     shallows[0]+=1
    "spring_cut":muster.y=shallows[0]-1
    _:muster.y=bridge_y-1
 var opening := {}
 if canonical:
  opening=Axis.hunting(muster) if ambush else Axis.ordinary(muster)
  pad={}
  for p: Vector2i in Axis.company_pad(opening)+Axis.enemy_pad(opening)+Axis.first_band(opening,reach):pad[p]=true
  spawns=Axis.descriptor_spawns(opening)
 var road_rows:={};var previous:=bridge_y
 for x in SIZE:
  var row:=bridge_y+roundi(2.8*sin(.24*x+phase)*clampf((absf(x-stream_x)-3)/5.0,0,1))
  for y in range(mini(previous,row),maxi(previous,row)+1):road_rows[Vector2i(x,y)]=true
  previous=row
 # A continuous odd-row river: each next water hex shares a native edge.
 var channel:=[];var last:=stream_x
 var corridor_center := muster.y if canonical else center.y
 var corridor_radius := 8 if canonical else 5
 for y in SIZE:
  var desired:=stream_x+roundi(3.2*sin(.22*y+bend)*clampf((absf(y-corridor_center)-corridor_radius)/5.0,0,1))
  if canonical and not ambush and reach=="reed_shoal":
   # Put the near reed wade one hex into the western bank. The bend enters
   # on an odd row, then naturally rejoins the continuous channel to its east.
   var shallow: int = shallows[0]
   var bend_start := shallow if shallow&1 else shallow-1
   if y in [bend_start,bend_start+1]:desired=stream_x-1
  last=desired if y==0 else clampi(desired,last-(y&1),last+((y+1)&1))
  channel.append(last)
 var thickets:=[]
 # One inward-facing grove near the fighting lanes, then larger irregular groves.
 thickets.append(Vector3(center.x+rng.randi_range(-2,2),center.y+rng.randi_range(-3,3),4.5))
 for i in (14 if family=="forest" else 5):thickets.append(Vector3(rng.randi_range(0,31),rng.randi_range(0,31),rng.randf_range(3,7)))
 var pres:={"biome":{"forest":"woodland","ford":"crossing","plains":"heath","ridge":"ridge"}[family],"road":[],"stream":[],"bridges":[],"keep":[]}
 var tiles:={};var goal:=muster
 if canonical:pres["opening_axis"]=opening
 if canonical and ambush:goal=muster+Vector2i(1,3)
 if family=="ford" and not ambush:goal=Vector2i(stream_x,bridge_y)
 for y in SIZE:
  for x in SIZE:
   var p:=Vector2i(x,y);var k:=key(p);var h:=0;var tag:="grass"
   var grove:=false
   for clump:Vector3 in thickets:
    if Vector2((x-clump.x)*.85,y-clump.y).length()<clump.z:grove=true;break
   var dx:=absf(x-spine-2.2*sin(y*.21+bend));var gap:=absf(y-saddle)
   var relief:=4.8-dx+1.6*sin(y*.34+phase)
   if family=="ridge":
    h=clampi(ceili(minf(relief,gap-1.0)*.57),0,2);tag="rocks" if h==2 else "hill" if h else "grass"
   elif family=="ford":
    # Gravel shoulders above the floodplain: firing positions beside, not on,
    # the wades. Mud, shallows and the hard channel have distinct native costs.
    var bank:=absi(x-channel[y]);var shoulder:=3.3-absf(bank-4.6)+1.8*sin(.38*y+phase)
    h=clampi(ceili(shoulder*.48),0,2) if bank>=2 else 0
    # The bridge approach cuts a low notch through each bank; the adjacent
    # shoulders still offer high ground without hiding the entire river at muster.
    if bank<=8 and absi(y-bridge_y)<=2:h=0
    if not reach.is_empty() and absi(y-int(shallows[0]))<=1 and bank<=5:h=0
    # A narrow overlooking shelf, or the wet fringe of a broad gravel shoal.
    if reach=="spring_cut" and x<=channel[y] and bank<=6:
     if y>=bridge_y-1 and y<=center.y+1:h=0
     elif x in [stream_x-2,stream_x-3]:h=1
    tag="hill" if h else "mud" if bank<=2 and sin(y*.51+bend)>.1 else "grass"
    if reach=="reed_shoal" and h==0 and bank in [1,2] and absi(y-center.y)>1:tag="mud"
   else:
    h=clampi(ceili((relief-2.4)*.55),0,2) if gap>3 else 0
    if grove and family=="forest":tag="forest"
    elif h:tag="hill"
   if pad.has(p) or p==goal:h=0
   if tag=="hill" and h==0:tag="grass"
   if family=="ford" and x==channel[y]:
    tag="ford" if y==bridge_y else "shallow_water" if y in shallows else "water";h=0;pres.stream.append(p)
    if tag=="ford":pres.bridges.append(k)
   elif (road or family=="ford") and road_rows.has(p):tag="road";h=mini(h,1)
   if tag in ["road","ford"]:pres.road.append(k)
   tiles[k]=floor_tile(tag,h)
 # Cut a one-level skirt wherever a shelf meets a low bank, saddle or
 # formation pad. Only level 2 next to 0 changes, so order cannot matter.
 for y in SIZE:
  for x in SIZE:
   var p:=Vector2i(x,y);var t:Dictionary=tiles[key(p)]
   if t.height!=2:continue
   var par:=y&1
   for step:Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i(par-1,-1),Vector2i(par,-1),Vector2i(par-1,1),Vector2i(par,1)]:
    if tiles.get(key(p+step),{}).get("height",2)==0:t.height=1;break
 # Place small contiguous copses and scree outcrops with guaranteed gaps between
 # clusters. Vary their positions within their regions rather than gridding trees.
 for y0 in range(0,SIZE,4):
  for x0 in range(0,SIZE,4):
   var start:=Vector2i(x0+rng.randi_range(0,1),y0+rng.randi_range(0,1))
   for i in rng.randi_range(1,3):
    var p:Vector2i=start+[Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN][i]
    var t:Dictionary=tiles[key(p)]
    if p.x in [0,SIZE-1] or p.y in [0,SIZE-1]:continue
    if pad.has(p) or p==goal or t.terrain in ["road","ford","water","shallow_water","mud"]:continue
    if family=="ford" and absi(p.x-channel[p.y])<2:continue
    var kind:=""
    if t.terrain=="forest":kind="tree"
    elif family in ["ridge","ford"] and t.height>0:kind="boulder"
    elif family=="plains" and i<2 and (p.x*17+p.y*7+n)%11<2:kind="tree" if t.height==0 else "boulder"
    if kind!="":
     t.terrain="forest" if kind=="tree" else "rocks";t.obstacle=kind;t.blocked=true;t.vision_blocking=true
 if not reach.is_empty():pres["reach"]=reach
 return {"id":family+"_field","title":REACH_TITLES.get(reach,NAMES[family]),"width":SIZE,"height":SIZE,"goal":goal,"spawns":spawns,"tiles":tiles,"presentation":pres}
