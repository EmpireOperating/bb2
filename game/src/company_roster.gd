extends RefCounted
## Campaign positions are company IDs; tactical IDs are assigned only at deployment.
const VERSION = 1
const LIMIT = 20
const FIELD_LIMIT = 12
const COLUMNS = 9
const SLOTS = 18
const CENTER_ORDER = [4,3,5,2,6,1,7,0,8]
static func empty() -> Array:
 var out=[];out.resize(SLOTS);out.fill(-1);return out
static func active(c) -> Array:
 if c.roster_version==0:return c.soldiers.filter(func(s):return s.alive).map(func(s):return s.id)
 return c.formation.filter(func(id):return id>=0 and c.soldiers[id].alive)
static func reserves(c) -> Array:
 var field=active(c)
 return c.soldiers.filter(func(s):return s.alive and s.id not in field).map(func(s):return s.id)
static func editable(c) -> bool:
 return c.phase=="camp" and not c.over() and c.encounter.is_empty()
static func add(c,id:int) -> void:
 if c.roster_version==0 or active(c).size()>=FIELD_LIMIT:return
 var ranged=c.item_def(c.soldiers[id].gear.weapon).get("weapon","") in c.Arsenal.RANGED
 for row in ([1,0] if ranged else [0,1]):
  for column in CENTER_ORDER:
   var slot=row*COLUMNS+column
   if c.formation[slot]<0:c.formation[slot]=id;return
static func prune(c) -> void:
 if c.roster_version==0:return
 for i in c.formation.size():
  if c.formation[i]>=0 and not c.soldiers[c.formation[i]].alive:c.formation[i]=-1
static func enable(c) -> bool:
 if not editable(c):return false
 if c.roster_version==VERSION:return true
 c.roster_version=VERSION;c.formation=empty()
 for s in c.soldiers:
  if s.alive:add(c,s.id)
 return true
static func place(c,id:int,slot:int) -> bool:
 if not editable(c) or c.roster_version!=VERSION or id<0 or id>=c.soldiers.size() or not c.soldiers[id].alive or slot<0 or slot>=SLOTS:return false
 var old=c.formation.find(id);var displaced:int=c.formation[slot]
 if old==slot:return true
 if old<0 and displaced<0 and active(c).size()>=FIELD_LIMIT:return false
 if old>=0:c.formation[old]=displaced
 c.formation[slot]=id
 return true
static func reserve(c,id:int) -> bool:
 if not editable(c) or c.roster_version!=VERSION:return false
 var slot=c.formation.find(id)
 if slot<0:return false
 c.formation[slot]=-1
 if active(c).is_empty():c.overworld.paused=true
 return true
static func valid(d:Variant,soldiers:Array) -> bool:
 if not d is Array or d.size()!=SLOTS:return false
 var seen={}
 for id in d:
  if not id is int or id < -1 or id>=soldiers.size():return false
  if id<0:continue
  if not soldiers[id].alive or seen.has(id):return false
  seen[id]=true
 return seen.size()<=FIELD_LIMIT
static func position(slot:int) -> Vector2i:
 return Vector2i(4 if slot<COLUMNS else 3,1+slot%COLUMNS)
static func deploy(c) -> void:
 if c.roster_version==0:return
 for i in c.deployment.size():
  var id:int=c.deployment[i]
  if id<0:continue
  var p=Vector2i(4+i%3,3+i/3) if c.battle.ambush else position(c.formation.find(id))
  c.battle.units[i].q=p.x;c.battle.units[i].r=p.y
 if c.battle.ambush:
  for i in c.battle.enemy_slots():
   var u=c.battle.units[c.battle.player_slots()+i]
   u.q=2 if i%2==0 else 7;u.r=2+i/2
