extends RefCounted
## V5 camp geometry only. Work metadata identifies a cell; Battle owns any
## future material, action, damage and remnant state. Leave older maps alone.
const Axis = preload("res://outdoor_fields/axis_layout.gd")
const Composer = preload("res://outdoor_fields/layout_composer.gd")
const TIMBER := "timber_stockade"
const RIDGE := "ridge_outpost"
const NO_WORK_CELL := Vector2i(-1,-1)
const CENTER := Vector2i(16,15)
const PLANK := Vector2i(0,1)
const MASONRY := Vector2i(0,-3)
const NEIGHBORS := [Vector2i(1,0),Vector2i(1,-1),Vector2i(0,-1),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,1)]

# Offsets are axial from CENTER. The fixed frontages identify the site across
# seeds; only the small aprons and the inherited surrounding landscape vary.
const PALISADE := [Vector2i(0,-4),Vector2i(0,-3),Vector2i(0,-1),Vector2i(0,0),
 PLANK,Vector2i(0,2),Vector2i(0,3),Vector2i(1,-5),Vector2i(2,-5),Vector2i(3,-6),
 Vector2i(4,-6),Vector2i(1,3),Vector2i(3,2),Vector2i(4,2)]
const BREASTWORK := [Vector2i(-1,-4),Vector2i(0,-4),MASONRY,Vector2i(0,-2),
 Vector2i(1,-2),Vector2i(1,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(0,2),
 Vector2i(1,3),Vector2i(2,2),Vector2i(3,1)]

static func compose(n: int, family: String, road: bool) -> Dictionary:
 var timber := family=="forest"
 var d := Composer.compose(n,family,"Pinewatch Refuge" if timber else "Broken Crown Hold",road,CENTER)
 d.presentation["landmark"]=TIMBER if timber else RIDGE
 d.presentation["work_cell"]=_key(PLANK if timber else MASONRY)
 var footprint := {}
 if timber:_stockade(d,footprint,n%3)
 else:_outpost(d,footprint,n%3)
 _finish_joins(d,footprint)
 return d

static func work_cell(d: Dictionary) -> Vector2i:
 var p: Dictionary = d.get("presentation",{})
 var at: Vector2i
 match p.get("landmark"):
  TIMBER:at=PLANK
  RIDGE:at=MASONRY
  _:return NO_WORK_CELL
 var k := _key(at)
 var tile: Dictionary = d.get("tiles",{}).get(k,{})
 if p.get("work_cell")!=k or tile.get("obstacle")!="wall" or tile.get("terrain")!="wall" or not tile.get("blocked",false) or not tile.get("vision_blocking",false):
  return NO_WORK_CELL
 return _cell(at)

static func _stockade(d: Dictionary, footprint: Dictionary, variant: int) -> void:
 _stamp(d,footprint,PALISADE,"wall",0,"wall")
 # North gate off the formation axis; paired gateposts flank the one-hex opening.
 for at: Vector2i in [Vector2i(0,-3),Vector2i(0,-1)]:d.presentation.keep.append(_key(at))
 _stamp(d,footprint,[Vector2i(-2,-1),Vector2i(-1,-2),Vector2i(0,-2),Vector2i(1,-2),
  Vector2i(2,-2),Vector2i(2,-1)],"grass")
 # The south postern turns behind the return, with trees screening its apron.
 _stamp(d,footprint,[Vector2i(-2,4),Vector2i(-1,4),Vector2i(0,4),Vector2i(1,4),
  Vector2i(2,3),Vector2i(2,2),Vector2i(2,1),Vector2i(2,0)],"grass")
 _stamp(d,footprint,[Vector2i(-1,3),Vector2i(2,4)],"forest",0,"tree")
 # Level working room on both sides of the single thin plank bay.
 _stamp(d,footprint,[Vector2i(-2,1),Vector2i(-1,1),Vector2i(1,1)],"grass")
 match variant:
  0: # Worn straight-in approach; the low postern skirts debris.
   _stamp(d,footprint,[Vector2i(-2,0),Vector2i(-1,-1)],"grass")
   _stamp(d,footprint,[Vector2i(-2,4),Vector2i(0,4)],"rubble")
  1: # A foreground copse breaks the straight lane; the gate is still open.
   _stamp(d,footprint,[Vector2i(-2,0),Vector2i(-1,-1)],"forest",0,"tree")
   _stamp(d,footprint,[Vector2i(-2,-1)],"forest")
  2: # Quick southern footpath and a rough northern diagonal.
   _stamp(d,footprint,[Vector2i(-2,0),Vector2i(-2,3)],"grass")
   _stamp(d,footprint,[Vector2i(-1,-1),Vector2i(-1,-2)],"rubble")
   _stamp(d,footprint,[Vector2i(-1,-3)],"forest",0,"tree")
 d.goal=_cell(Vector2i(2,-1))

static func _outpost(d: Dictionary, footprint: Dictionary, variant: int) -> void:
 _stamp(d,footprint,BREASTWORK,"wall",1,"wall")
 # Follow the angled shoulder up to the southern notch, then turn on the
 # shelf behind the breastwork. The enemy muster remains on the level.
 _stamp(d,footprint,[Vector2i(-2,3),Vector2i(-1,3),Vector2i(0,3),Vector2i(1,2),
  Vector2i(2,1),Vector2i(2,0),Vector2i(2,-1),Vector2i(2,-2),Vector2i(2,-3),Vector2i(1,-3)],"stone",1)
 # A long north traverse rounds the masonry at the rim. The weak north bay
 # shortens that alternative without making tools necessary to enter.
 _stamp(d,footprint,[Vector2i(-3,-1),Vector2i(-3,-2),Vector2i(-3,-3),Vector2i(-2,-4),
  Vector2i(-1,-5),Vector2i(0,-5),Vector2i(1,-5),Vector2i(2,-5),Vector2i(2,-4)],"hill",1)
 _stamp(d,footprint,[Vector2i(-2,-2),Vector2i(-1,-2),Vector2i(-1,-3)],"hill",1)
 match variant:
  0: # Broad early climb, rough shoulder below it.
   _stamp(d,footprint,[Vector2i(-2,2)],"hill",1)
   _stamp(d,footprint,[Vector2i(-2,4)],"rocks")
  1: # A tight late climb between the scree bank and the wall.
   _stamp(d,footprint,[Vector2i(-2,2)],"rocks",1,"boulder")
   _stamp(d,footprint,[Vector2i(-2,3)],"rough")
   _stamp(d,footprint,[Vector2i(-2,4)],"grass")
  2: # A higher flank leads in from the south, above the shingle floor.
   _stamp(d,footprint,[Vector2i(-2,2)],"rocks")
   _stamp(d,footprint,[Vector2i(-2,3)],"grass")
   _stamp(d,footprint,[Vector2i(-2,4),Vector2i(-1,4)],"hill",1)
 d.goal=_cell(Vector2i(2,0))

static func _cell(at: Vector2i) -> Vector2i:
 return Axis.offset(Axis.axial(CENTER)+at)

static func _key(at: Vector2i) -> String:
 var p := _cell(at)
 return "%d,%d"%[p.x,p.y]

static func _stamp(d: Dictionary, footprint: Dictionary, cells: Array, surface: String, level: int = 0, obstacle: String = "") -> void:
 for at: Vector2i in cells:
  var tile := {"terrain":surface,"height":level}
  if not obstacle.is_empty():tile.merge({"obstacle":obstacle,"blocked":true,"vision_blocking":true})
  d.tiles[_key(at)]=tile
  footprint[at]=true

static func _finish_joins(d: Dictionary, footprint: Dictionary) -> void:
 # Only grade the one-hex seam where a newly cut floor meets preserved relief.
 # No new obstacles outside the stamp, no whole-map cleanup or terrain reroll.
 for at: Vector2i in footprint:
  if d.tiles[_key(at)].height!=0 or d.tiles[_key(at)].get("blocked",false):continue
  for step: Vector2i in NEIGHBORS:
   var neighbor: Dictionary = d.tiles[_key(at+step)]
   if neighbor.height==2 and not neighbor.get("blocked",false):neighbor.height=1
 d.presentation.road=d.presentation.road.filter(func(k):return d.tiles[k].terrain=="road")
