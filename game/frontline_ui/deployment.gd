extends RefCounted
## Derived coordinates only. Accepted descriptors, tile truth and stock turns are
## immutable inputs. Company columns include holes; tactical IDs are not columns.
const PROFILE := "straight_company_axial24_v1"
const CENTER_ORDER := [4,3,5,2,6,1,7,0,8]
static func safe(d: Dictionary, p: Vector2i) -> bool:
 if p.x<0 or p.y<0 or p.x>=d.width or p.y>=d.height: return false
 var t: Dictionary=d.tiles.get("%d,%d"%[p.x,p.y],{})
 return not t.is_empty() and not t.get("blocked",false) and t.get("terrain","") not in ["water","deep_water","wall"] and t.get("height",-1)==0
static func formation_cell(b, anchor: Vector2i, slot: int) -> Vector2i:
 return b.offset(b.axial(anchor)+Vector2i(-int(slot/9),slot%9-4))
static func candidates(b, d: Dictionary, base: Vector2i) -> Array:
 var out:=[]
 # Bounded side-local translation, never terrain repair or rank compression.
 for r in range(maxi(0,base.y-4),mini(d.height,base.y+5)):
  for q in range(maxi(0,base.x-4),mini(d.width,base.x+5)):out.append(Vector2i(q,r))
 out.sort_custom(func(a,c):
  var da: int=b.distance(a,base); var dc: int=b.distance(c,base)
  if da!=dc:return da<dc
  if absi(a.y-base.y)!=absi(c.y-base.y):return absi(a.y-base.y)<absi(c.y-base.y)
  return a.y<c.y if a.y!=c.y else a.x<c.x)
 return out
static func ordinary(c, d: Dictionary, player_base: Vector2i, enemy_base: Vector2i) -> Array:
 var b=c.battle
 if b.ambush or b.units.size()!=24 or c.deployment.size()!=12 or c.formation.size()!=18:return []
 var player_anchor:=Vector2i(-1,-1); var enemy_anchor:=Vector2i(-1,-1)
 var player_options:=[]; var enemy_options:=[]
 for anchor: Vector2i in candidates(b,d,player_base):
  var valid:=true
  for slot in 18:
   var p:=formation_cell(b,anchor,slot)
   valid=valid and safe(d,p) and p.x<d.goal.x
  if valid:player_options.append(anchor)
 for anchor: Vector2i in candidates(b,d,enemy_base):
  var valid:=true; var seen:={}
  for i in range(12,24):
   var u: Dictionary=b.units[i]
   var p: Vector2i=b.offset(b.axial(anchor)+Vector2i(u.q-12,u.r-5))
   # Empty stock enemy rows can overlap dungeon role positions. Repair those
   # only after living rows claim the exact role/rank/gap coordinates.
   if b.living(u):valid=valid and safe(d,p) and p.x>d.goal.x and not seen.has(p);seen[p]=true
  if valid:enemy_options.append(anchor)
 for pa: Vector2i in player_options:
  for ea: Vector2i in enemy_options:
   var separation:=true
   for u in b.units.slice(12):
    if b.living(u) and b.axial(ea).x+u.q-12-b.axial(pa).x<6:separation=false
   if separation:player_anchor=pa;enemy_anchor=ea;break
  if player_anchor.x>=0:break
 if player_anchor.x<0:return []
 var result:=[];result.resize(24);var used:={};var used_slots:={};var empty:=[]
 for i in 12:
  var sid: int=c.deployment[i]
  if sid<0:empty.append(i);continue
  var slot: int=c.formation.find(sid)
  if slot<0 or used_slots.has(slot):return []
  var p:=formation_cell(b,player_anchor,slot)
  result[i]=p;used[p]=true;used_slots[slot]=true
 for i in empty:
  for row in 2:
   var found:=false
   for col in CENTER_ORDER:
    var slot: int=row*9+col
    if used_slots.has(slot):continue
    var p:=formation_cell(b,player_anchor,slot)
    result[i]=p;used[p]=true;used_slots[slot]=true;found=true;break
   if found:break
 var repair:=[]
 for living_pass in [true,false]:
  for i in range(12,24):
   var u: Dictionary=b.units[i]
   if b.living(u)!=living_pass:continue
   var p: Vector2i=b.offset(b.axial(enemy_anchor)+Vector2i(u.q-12,u.r-5))
   if safe(d,p) and p.x>d.goal.x and not used.has(p):result[i]=p;used[p]=true
   elif living_pass:return []
   else:repair.append(i)
 for i in repair:
  var found:=false
  for p: Vector2i in candidates(b,d,enemy_anchor):
   if safe(d,p) and p.x>d.goal.x and not used.has(p):result[i]=p;used[p]=true;found=true;break
  if not found:return []
 return result if used.size()==24 else []
static func ambush(c, d: Dictionary) -> Array:
 var b=c.battle
 if not b.ambush or b.units.size()!=24:return []
 var chosen:=Vector2i(-1,-1)
 var origin: Vector2i=b.axial(Vector2i(5,5))
 for anchor: Vector2i in candidates(b,d,d.goal):
  var seen:={};var valid:=true
  for u in b.units:
   if not b.living(u):continue
   var p: Vector2i=b.offset(b.axial(b.pos(u))-origin+b.axial(anchor))
   if not safe(d,p) or seen.has(p):valid=false;break
   seen[p]=true
  if valid:chosen=anchor;break
 if chosen.x<0:return []
 var result:=[];result.resize(24);var used:={};var repair:=[]
 for living_pass in [true,false]:
  for u in b.units:
   if b.living(u)!=living_pass:continue
   var p: Vector2i=b.offset(b.axial(b.pos(u))-origin+b.axial(chosen))
   if safe(d,p) and not used.has(p):result[u.id]=p;used[p]=true
   elif living_pass:return []
   else:repair.append({"id":u.id,"base":p})
 for row in repair:
  var found:=false
  for p: Vector2i in candidates(b,d,row.base):
   if safe(d,p) and not used.has(p):result[row.id]=p;used[p]=true;found=true;break
  if not found:return []
 return result if used.size()==24 else []
static func install(b, d: Dictionary, positions: Array) -> bool:
 if positions.size()!=24 or not b.configure_board(d.width,d.height,d.goal):return false
 b.tiles=d.tiles.duplicate(true)
 for i in 24:b.units[i].q=positions[i].x;b.units[i].r=positions[i].y
 if b.active_id>=0:
  var u: Dictionary=b.units[b.active_id];var state: Dictionary=b.vital_state(u)
  state.origin_q=u.q;state.origin_r=u.r
 b.terrain_rules_enabled=true;b.set_meta("authored_map",d.duplicate(true))
 var boss: bool=b.boss_tactics;var plan: Dictionary=b.enemy_plan.duplicate(true)
 var ok: bool=b.configure_visibility()
 b.boss_tactics=boss;b.enemy_plan=plan
 return ok
