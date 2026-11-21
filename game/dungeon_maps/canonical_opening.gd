extends RefCounted
## Seeded crypt v3 geometry. Reserve the full rank templates and real floor
## approaches first. Walls cannot occupy a template, threshold, or main passage.
const WIDTH := 25
const HEIGHT := 18
const ACROSS := Vector2i(2,-1)
const DEPTH := 6
const PLAYER := Vector2i(5,12)
const COLUMNS := 9
const CENTER_ORDER := [4,3,5,2,6,1,7,0,8]
const FAMILIES := {"crypt":"royal","crypt_barrow":"mound","crypt_gallery":"garrison","crypt_throne":"royal","crypt_mound":"mound","crypt_garrison":"garrison","crypt_royal":"royal"}

static func axial(p: Vector2i) -> Vector2i:
 return Vector2i(p.x-(p.y>>1),p.y)

static func offset(a: Vector2i) -> Vector2i:
 return Vector2i(a.x+(a.y>>1),a.y)

static func player_cell(anchor: Vector2i, column: int, rear: bool) -> Vector2i:
 return offset(axial(anchor)+Vector2i(-int(rear),column-4))

static func enemy_cell(anchor: Vector2i, rank: int, column: int) -> Vector2i:
 # Every rank is a true (0,1) chain. Recenter whole distant ranks in
 # half-step increments, without compacting role gaps along either rank.
 return offset(axial(anchor)+Vector2i(rank,column-4-(rank>>1)))

static func enemy_front_q(field: String) -> int:
 # Stock source columns: dungeons.gd (aliases), dungeon_themes.gd (themes).
 if field == "crypt_mound":return 10
 if field in ["crypt_garrison","crypt_royal"]:return 11
 return 12

static func _wall(walls: Dictionary, reserve: Dictionary, p: Vector2i) -> void:
 if not reserve.has(p):walls[p]=true

static func _gallery(walls: Dictionary, reserve: Dictionary, r: int, first: int, last: int, door: int) -> void:
 for q in range(first,last+1):
  if q != door and q != door+1:_wall(walls,reserve,Vector2i(q,r))

static func geometry(field: String, seed: int) -> Dictionary:
 var rng := RandomNumberGenerator.new()
 rng.seed=seed
 var player_axial := axial(PLAYER)
 var enemy := offset(player_axial+ACROSS*DEPTH)
 var goal := offset(player_axial+ACROSS*(DEPTH>>1))
 var reserve := {}; var players := []; var enemies := []; var exit_sides := {}
 for rear in [false,true]:
  for col in COLUMNS:
   var point := player_cell(PLAYER,col,rear)
   players.append(point);reserve[point]=true
 # Reserve every potential front/rear/shooter rank cell. Range includes a
 # forward overflow rank; no assumptions about the living enemy count.
 for rank in [0,1,2,3,-1]:
  for col in COLUMNS:
   var point := enemy_cell(enemy,rank,col)
   enemies.append(point);reserve[point]=true
 # Perimeter doors open onto continuous floor, not isolated escape hexes.
 for entry in [[PLAYER,0,0],[enemy,WIDTH-1,1]]:
  var at: Vector2i=entry[0];var edge: int=entry[1]
  for row in range(at.y-2,at.y+3):
   var point := Vector2i(edge,row)
   exit_sides[point]=entry[2];reserve[point]=true
  for x in range(mini(edge,at.x),maxi(edge,at.x)+1):reserve[Vector2i(x,at.y)]=true
 # Genuine adjacent stair steps approximate the horizontal line on a hex grid.
 for step in range(DEPTH+1):
  var at := player_axial+ACROSS*step
  reserve[offset(at)]=true
  if step < DEPTH:reserve[offset(at+Vector2i(1,0))]=true
 var walls := {}
 for y in HEIGHT:
  for x in WIDTH:
   if y in [0,HEIGHT-1] or x in [0,WIDTH-1]:_wall(walls,reserve,Vector2i(x,y))
 var family: String=FAMILIES[field]
 match family:
  "mound":
   # Two burial banks face a broad common hall; returns shape side recesses.
   var up := rng.randi_range(3,4);var down := rng.randi_range(13,14)
   _gallery(walls,reserve,up,rng.randi_range(5,6),12,rng.randi_range(7,10))
   _gallery(walls,reserve,down,8,rng.randi_range(16,18),rng.randi_range(10,13))
   _wall(walls,reserve,Vector2i(6,up-1));_wall(walls,reserve,Vector2i(16,down+1))
  "garrison":
   # Separate cross-doors in the lengthwise barricades. Wings are connected
   # both at the ends and through the doors, with offset short returns.
   for row in [rng.randi_range(4,5),rng.randi_range(11,12)]:
    var left := rng.randi_range(6,7);var right := rng.randi_range(14,16)
    _gallery(walls,reserve,row,left,right,rng.randi_range(8,12))
    _wall(walls,reserve,Vector2i(left,row-1));_wall(walls,reserve,Vector2i(right,row+1))
  "royal":
   # A cross-wall runs up a real vertical rank, pierced by a broad portal.
   # Its ends have bypasses; the deeper screen backs recessed side tombs.
   var rank := axial(goal).x+rng.randi_range(-1,1)
   var door := rng.randi_range(goal.y-2,goal.y)
   for row in range(3,15):
    if row < door or row > door+2:_wall(walls,reserve,offset(Vector2i(rank,row)))
   _gallery(walls,reserve,3,5,10,rng.randi_range(6,8))
   _gallery(walls,reserve,14,13,rng.randi_range(18,20),rng.randi_range(14,17))
   for p in [Vector2i(17,13),Vector2i(19,12),Vector2i(19,13)]:_wall(walls,reserve,p)
 var tiles := {}
 for y in HEIGHT:
  for x in WIDTH:
   var p := Vector2i(x,y);var blocked := walls.has(p)
   var tile := {"terrain":"wall" if blocked else "stone","height":0,"blocked":blocked,"vision_blocking":blocked,"obstacle":"wall" if blocked else "","cover":false}
   if exit_sides.has(p):tile["escape_side"]=exit_sides[p]
   tiles["%d,%d" % [x,y]]=tile
 var d := {"id":field,"title":"Seeded "+family+" crypt","width":WIDTH,"height":HEIGHT,"goal":goal,"tiles":tiles,"presentation":{"biome":"crypt","road":[],"stream":[],"bridges":[],"keep":[],"family":family,"formation_policy":"canonical_axial24_v1","opening_axis":{"player":PLAYER,"enemy":enemy},"player_anchors":players,"enemy_anchors":enemies}}
 var spawns := []
 for col in CENTER_ORDER:spawns.append(players[col])
 for col in CENTER_ORDER.slice(0,3):spawns.append(players[COLUMNS+col])
 for col in CENTER_ORDER:spawns.append(enemies[col])
 for col in CENTER_ORDER.slice(0,3):spawns.append(enemies[COLUMNS+col])
 return {"descriptor":d,"spawns":spawns,"metrics":{"tiles":WIDTH*HEIGHT,"walls":walls.size(),"floors":WIDTH*HEIGHT-walls.size(),"formation_cells":players.size(),"spawns":spawns.size()}}
