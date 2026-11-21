extends RefCounted
## Level-opening profile v1. Uses only the accepted board and predecessor's
## actual slots. No generator edits, randomness, combat work or save metadata.
const Straight = preload("res://frontline_ui/deployment.gd")
const Terrain = preload("res://src/terrain_rules.gd")
const CAMERA_SHIFT_META := &"level_opening_v1_player_shift"
const PLAYER_RADIUS := 2  # Keep the party in the accepted initial framing.
const HOSTILE_RADIUS := 6
const SPAN_PERCENT := 25

static func hex_length(a: Vector2i) -> int:
 return maxi(maxi(absi(a.x),absi(a.y)),absi(a.x+a.y))

static func legal(d: Dictionary, at: Vector2i, side: int, stream: Dictionary) -> bool:
 if not Straight.safe(d,at) or at==d.goal:return false
 var tile: Dictionary = d.tiles["%d,%d" % [at.x,at.y]]
 if tile.has("escape_side") or tile.terrain in ["ford","shallow_water"] or not Terrain.tile_reason(tile).is_empty():return false
 var divider: int = stream.get(at.y,d.goal.x)
 if at.x>=divider if side==0 else at.x<=divider:return false
 # Keep the crypt entrances, portal approaches and recess mouths out of
 # muster pads. These are the authored interior spans in seeded_crypt_v2.
 var family: String = d.presentation.get("family","") if d.id.begins_with("crypt") else ""
 if at.x in range(8,17):
  if family in ["garrison","royal"] or (family=="mound" and at.y in [2,10]):return false
 return true

static func shifts(b, d: Dictionary, cells: Array[Vector2i], side: int, radius: int, stream: Dictionary) -> Array[Vector2i]:
 var options: Array[Vector2i] = []
 for r in range(-radius,radius+1):
  for q in range(-radius,radius+1):
   var delta := Vector2i(q,r)
   if hex_length(delta)>radius:continue
   var found := true
   for cell in cells:
    if not legal(d,b.offset(cell+delta),side,stream):
     found=false
     break
   if found:options.append(delta)
 return options

static func nearest(gaps: Array, shift: Vector2i) -> int:
 var best := 999
 for gap: Vector2i in gaps:best=mini(best,hex_length(gap+shift))
 return best

static func earlier(a: Array, b: Array) -> bool:
 for i in a.size():
  if a[i]!=b[i]:return a[i]<b[i]
 return false

static func choose(c, d: Dictionary, previous: Array) -> Dictionary:
 var b = c.battle
 if b.ambush or previous.size()!=24:return {}
 var players: Array[Vector2i] = []
 var enemies: Array[Vector2i] = []
 var sums := [Vector2i.ZERO,Vector2i.ZERO]
 var anchor := Vector2i.ZERO
 for u: Dictionary in b.units:
  if not b.living(u):continue
  var at: Vector2i = b.axial(previous[u.id])
  sums[u.side]+=at
  if u.side==0:
   var slot: int = c.formation.find(c.deployment[u.id])
   if slot<0:return {}
   if players.is_empty():anchor=at+Vector2i(int(slot/9),4-slot%9)
   players.append(at)
  else:enemies.append(at)
 if players.is_empty() or enemies.is_empty():return {}
 var template: Array[Vector2i] = []
 for rank in 2:
  for column in 9:template.append(anchor+Vector2i(-rank,column-4))
 var stream := {}
 if d.presentation.get("biome")=="crossing":
  for at: Vector2i in d.presentation.stream:stream[at.y]=at.x
 # Preserve the exact friendly river approach (starting sight, bridge/shoal
 # access and first stride). Only the opposite bank is searched in a crossing.
 var p_options := shifts(b,d,template,0,PLAYER_RADIUS if stream.is_empty() else 0,stream)
 var e_options := shifts(b,d,enemies,1,HOSTILE_RADIUS,stream)
 var gap_set := {}
 for p in players:
  for e in enemies:gap_set[e-p]=true
 var gaps := gap_set.keys()
 var old_gap := nearest(gaps,Vector2i.ZERO)
 var population := players.size()*enemies.size()
 var base: Vector2i = sums[1]*players.size()-sums[0]*enemies.size()
 if base.x<=0:return {}
 # The fixed camera's screen-horizontal ground vector is axial (2,-1).
 # With its yaw/pitch, screen dx is proportional to q and dy to q+2*r.
 # Compare abs(dy/dx) exactly, with common population denominators cancelled.
 var best_cross := absi(base.x+2*base.y)
 var best_forward := base.x
 var best_tie := [0,0,0,0,0,0,0,0]
 var picked: Array[Vector2i] = [Vector2i.ZERO,Vector2i.ZERO]
 var distances := {}
 for p in p_options:
  for e in e_options:
   var relative := e-p
   var delta := base+relative*population
   var span := absi(delta.x-base.x)
   if delta.x<=0 or 100*span>SPAN_PERCENT*base.x:continue
   var cross := absi(delta.x+2*delta.y)
   var angle_order := cross*best_forward-best_cross*delta.x
   if angle_order>0:continue
   if not distances.has(relative):distances[relative]=nearest(gaps,relative)
   var distance: int = distances[relative]
   if distance<maxi(6,old_gap-1) or distance>old_gap+2:continue
   var tie := [span,absi(distance-old_gap),hex_length(p)+hex_length(e),hex_length(p),p.y,p.x,e.y,e.x]
   if angle_order==0 and not earlier(tie,best_tie):continue
   best_cross=cross
   best_forward=delta.x
   best_tie=tie
   picked=[p,e]
 if picked[0]==Vector2i.ZERO and picked[1]==Vector2i.ZERO:return {}
 var result := previous.duplicate()
 var used := {}
 var unplaced := []
 for u: Dictionary in b.units:
  var at: Vector2i = b.offset(b.axial(previous[u.id])+picked[u.side])
  if u.side==1 and not b.living(u):
   unplaced.append([u.id,at])
  else:
   result[u.id]=at
   used[at]=true
 # Only active hostile roles constrain the rank translation. Park empty
 # rows after all real occupants, preferring translated then original cells.
 for row: Array in unplaced:
  var id: int = row[0]
  var at: Vector2i = row[1]
  if used.has(at) or not legal(d,at,1,stream):at=previous[id]
  if used.has(at) or not legal(d,at,1,stream):
   at=Vector2i(-1,-1)
   for other: Vector2i in Straight.candidates(b,d,row[1]):
    if not used.has(other) and legal(d,other,1,stream):
     at=other
     break
  if at.x<0:return {}
  result[id]=at
  used[at]=true
 return {"positions":result,"player_shift":picked[0]} if used.size()==24 else {}
