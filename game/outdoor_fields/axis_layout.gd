extends RefCounted
## Geometry only. Odd-row OFFSET at the descriptor boundary; axial within pads.
const Terrain = preload("res://src/terrain_rules.gd")
const Roster = preload("res://src/company_roster.gd")
const HORIZONTAL := Vector2i(2,-1)
const RANK := Vector2i(0,1)
const MUSTER_STEPS := 2 # each side is four native hexes from the middle

static func axial(p: Vector2i) -> Vector2i:
 return Vector2i(p.x-(p.y>>1),p.y)

static func offset(a: Vector2i) -> Vector2i:
 return Vector2i(a.x+(a.y>>1),a.y)

static func ordinary(center: Vector2i) -> Dictionary:
 var middle := axial(center)
 return {"player":offset(middle-HORIZONTAL*MUSTER_STEPS),"enemy":offset(middle+HORIZONTAL*MUSTER_STEPS)}

static func hunting(center: Vector2i) -> Dictionary:
 var wings := ordinary(center)
 return {"player":center,"enemy":wings.enemy,"left":wings.player,"right":wings.enemy}

static func company_cell(anchor: Vector2i, slot: int) -> Vector2i:
 return offset(axial(anchor)+Vector2i(-(slot/9),slot%9-4))

static func enemy_cell(anchor: Vector2i, ordinal: int) -> Vector2i:
 # Native expanded roster has two ranks of six, beginning at (12,2) OFFSET.
 return offset(axial(anchor)+Vector2i(ordinal/6,ordinal%6-3))

static func company_pad(axis: Dictionary) -> Array[Vector2i]:
 var out: Array[Vector2i] = []
 if axis.has("left"):
  # Surprise keeps a compact march cluster; the first brother is centered.
  for i in 12:
   out.append(offset(axial(axis.player)+Vector2i([0,-1,1][i%3],[0,1,-1,2][i/3])))
  return out
 for slot in Roster.SLOTS:out.append(company_cell(axis.player,slot))
 return out

static func enemy_pad(axis: Dictionary) -> Array[Vector2i]:
 var out: Array[Vector2i] = []
 if axis.has("left"):
  # Stock assigns even IDs to the rear/left, odd to the front/right. Keep
  # living and empty role identities, with each wing on its own rank axis.
  for i in 12:
   var wing: Vector2i = axis.left if i%2==0 else axis.right
   out.append(offset(axial(wing)+Vector2i(0,[0,-1,1,-2,2,3][i/2])))
  return out
 for i in 12:out.append(enemy_cell(axis.enemy,i))
 return out

static func first_band(axis: Dictionary, reach: String = "") -> Array[Vector2i]:
 # Reserve a few level first steps, not a flat corridor between formations.
 var out: Array[Vector2i] = []
 if axis.has("left"):
  for delta: Vector2i in [Vector2i(0,-2),Vector2i(-2,1),Vector2i(2,-1),Vector2i(-3,1),Vector2i(3,-1)]:
   out.append(offset(axial(axis.player)+delta))
  return out
 for column in range(-2,3):
  # The reed channel nips into the last two approach files (not the ranks).
  if reach!="reed_shoal" or column<=0:out.append(offset(axial(axis.player)+Vector2i(1,column)))
  out.append(offset(axial(axis.enemy)+Vector2i(-1,column)))
 return out

static func descriptor_spawns(axis: Dictionary) -> Array[Vector2i]:
 # Twelve descriptor references are a subset of the pads, with anchors at 0/6.
 if axis.has("left"):
  var players := company_pad(axis)
  var enemies := enemy_pad(axis)
  var refs: Array[Vector2i] = players.slice(0,6)
  refs.append_array([enemies[1],enemies[0],enemies[2],enemies[3],enemies[4],enemies[5]])
  return refs
 var out: Array[Vector2i] = []
 for anchor: Vector2i in [axis.player,axis.enemy]:
  var back := -1 if anchor==axis.player else 1
  for delta: Vector2i in [Vector2i.ZERO,-RANK,RANK,Vector2i(back,0),Vector2i(back,-1),Vector2i(back,1)]:
   out.append(offset(axial(anchor)+delta))
 return out

static func legal(d: Dictionary, cell: Vector2i) -> bool:
 if cell==d.goal or cell.x<=0 or cell.y<=0 or cell.x>=d.width-1 or cell.y>=d.height-1:return false
 var tile: Dictionary = d.tiles.get("%d,%d"%[cell.x,cell.y],{})
 return tile.get("height")==0 and not tile.has("escape_side") and tile.get("terrain") not in ["ford","shallow_water"] and Terrain.tile_reason(tile).is_empty()

static func reserved(d: Dictionary) -> Array:
 var axis: Dictionary = d.presentation.opening_axis
 var out := company_pad(axis)+enemy_pad(axis)
 var seen := {}
 for at: Vector2i in out+first_band(axis,d.presentation.get("reach","")):
  if seen.has(at) or not legal(d,at):return []
  seen[at]=true
 return out

static func positions(c, d: Dictionary) -> Array:
 var b = c.battle
 if b.units.size()!=24 or b.player_slots()!=12 or c.deployment.size()!=12 or c.formation.size()!=18:return []
 if b.ambush!=d.presentation.opening_axis.has("left"):return []
 var slots := reserved(d)
 if b.ambush:return slots if slots.size()==24 else []
 if slots.size()!=30:return []
 var result := []
 result.resize(24)
 var used := {}
 for i in 12:
  var company_id: int = c.deployment[i]
  if company_id<0:continue
  var slot: int = c.formation.find(company_id)
  if slot<0 or used.has(slot):return []
  used[slot]=true
  result[i]=slots[slot]
 for i in 12:
  if result[i]!=null:continue
  for rank in 2:
   for column: int in Roster.CENTER_ORDER:
    var slot := rank*9+column
    if used.has(slot):continue
    used[slot]=true
    result[i]=slots[slot]
    break
   if result[i]!=null:break
 # Center living roles within each reserved rank; the low-ID end of a
 # six-cell pad is not the center of a one- or two-person detachment.
 var unused := []
 var claimed := {}
 for rank in 2:
  var first := 6
  var last := -1
  for column in 6:
   var id := 12+6*rank+column
   if b.living(b.units[id]):
    first=mini(first,column)
    last=column
   else:unused.append(id)
  if last<0:continue
  var shift := (5-(last-first))/2-first
  for column in range(first,last+1):
   var id := 12+6*rank+column
   if not b.living(b.units[id]):continue
   var p: Vector2i = slots[18+6*rank+column+shift]
   result[id]=p
   claimed[p]=true
 var empty_cursor := 0
 for i in range(18,30):
  var p: Vector2i = slots[i]
  if claimed.has(p):continue
  result[unused[empty_cursor]]=p
  empty_cursor+=1
 return result
