extends RefCounted
## Public-knowledge, AP/FAT-bounded label search across ALL ordered waypoints.
## BB1-inspired finite danger preference (4), NOT extra paid AP or safety guarantee.
const DANGER_PREFERENCE=4
static func cells(path:Array) -> Array:
 return path.map(func(p):return {"q":p.x,"r":p.y})
static func hazards(b, u:Dictionary, a:Vector2i, n:Vector2i, final:bool) -> Dictionary:
 var out={"departure":false,"brace":false,"exposure":false}
 for id in b.known_enemy_ids(u.side):
  if not b.unit_visible(u.side,id):continue
  var foe:Dictionary=b.units[id]
  if not b.terrain_can_react(foe):continue
  var leaves:bool=b.terrain_controls(foe,a);var enters:bool=b.terrain_controls(foe,n)
  out.departure=out.departure or (b.terrain_rules_enabled and leaves)
  out.exposure=out.exposure or (enters and not final)
  out.brace=out.brace or b.spearwall_threatens(foe,u,a,n)
 return out
static func ranked(a:Dictionary,z:Dictionary) -> bool:
 var av:int=a.cost+DANGER_PREFERENCE*a.risk;var zv:int=z.cost+DANGER_PREFERENCE*z.risk
 if av!=zv:return av<zv
 if a.risk!=z.risk:return a.risk<z.risk
 if a.fatigue!=z.fatigue:return a.fatigue<z.fatigue
 return a.tie<z.tie
static func quote_path(b, id:int, path:Array, waypoints:Array) -> Dictionary:
 # Describe an already displayed prefix without finding a different route.
 if not b.can_act(id) or path.is_empty():return {}
 var u:Dictionary=b.units[id];var previous:Vector2i=b.pos(u)
 var cost:=0;var fatigue:=0;var risk_steps:Array=[];var departure:=false;var brace:=false;var exposure:=false
 for index in path.size():
  var cell:Vector2i=path[index]
  var edge:Dictionary=b.movement_edge(u,previous,cell)
  if not edge.reason.is_empty():return {}
  cost+=edge.ap;fatigue+=edge.fatigue
  var danger:Dictionary=hazards(b,u,previous,cell,index==path.size()-1)
  departure=departure or danger.departure;brace=brace or danger.brace;exposure=exposure or danger.exposure
  if danger.departure or danger.brace or danger.exposure:risk_steps.append(index)
  previous=cell
 if cost>u.ap or fatigue+u.fatigue>b.fatigue_max(u):return {}
 var warnings:Array=[]
 if departure:warnings.append("Opportunity attack on departure")
 if brace:warnings.append("Enemy Spearwall")
 if exposure:warnings.append("Controlled intermediate ground")
 return {"valid":true,"actor":id,"origin":b.pos(u),"waypoints":waypoints.duplicate(),"path":path.duplicate(),"cost":cost,"fatigue":fatigue,"known_danger":not warnings.is_empty(),"danger_text":"; ".join(warnings),"risk_steps":risk_steps}
static func plan(b, id:int, waypoints:Array) -> Dictionary:
 if not b.can_act(id) or waypoints.is_empty():return {}
 var u:Dictionary=b.units[id];var origin:Vector2i=b.pos(u)
 var occupied:Dictionary={}
 for other in b.units:
  if other.id!=id and b.unit_visible(u.side,other.id) and b.living(other):occupied[b.key(b.pos(other))]=true
 for p in waypoints:
  if not p is Vector2i:return {}
  if p==origin or not b.tile_visible(u.side,p) or occupied.has(b.key(p)):return {}
 var first={"p":origin,"next":0,"cost":0,"fatigue":0,"risk":0,"path":[],"risk_steps":[],"departure":false,"brace":false,"exposure":false,"tie":""}
 var labels:Dictionary={str([origin,0]):[first]};var frontier:Array=[first];var complete:Array=[]
 while not frontier.is_empty():
  frontier.sort_custom(ranked)
  var label:Dictionary=frontier.pop_front();var state:=str([label.p,label.next])
  if not label in labels[state]:continue
  if label.next==waypoints.size():complete.append(label);continue
  for n:Vector2i in b.neighbors(label.p):
   if not b.tile_visible(u.side,n) or occupied.has(b.key(n)) or n==origin:continue
   # Retain legacy nonterrain engagement admission without querying hidden foes.
   if not b.terrain_rules_enabled and not u.routed:
    var locked:=false
    for foe in b.known_enemy_ids(u.side):
     if b.terrain_controls(b.units[foe],label.p):locked=true;break
    if locked:continue
   var edge:Dictionary=b.movement_edge(u,label.p,n)
   if not edge.reason.is_empty():continue
   var ap:int=label.cost+edge.ap;var fat:int=label.fatigue+edge.fatigue
   if ap>u.ap or fat+u.fatigue>b.fatigue_max(u):continue
   var next:int=label.next+(1 if n==waypoints[label.next] else 0)
   var danger:=hazards(b,u,label.p,n,next==waypoints.size())
   var risk:int=label.risk+int(danger.departure)+int(danger.brace)+int(danger.exposure)
   var k:=str([n,next]);var existing:Array=labels.get(k,[])
   var tie:String=label.tie+"%03d,%03d;"%[n.y,n.x]
   if existing.any(func(v):return v.cost<=ap and v.fatigue<=fat and v.risk<=risk and (v.cost<ap or v.fatigue<fat or v.risk<risk or v.tie<=tie)):continue
   var candidate={"p":n,"next":next,"cost":ap,"fatigue":fat,"risk":risk,"path":label.path+[n],"risk_steps":label.risk_steps.duplicate(),"departure":label.departure or danger.departure,"brace":label.brace or danger.brace,"exposure":label.exposure or danger.exposure,"tie":tie}
   if danger.departure or danger.brace or danger.exposure:candidate.risk_steps.append(label.path.size())
   labels[k]=existing.filter(func(v):return not (ap<=v.cost and fat<=v.fatigue and risk<=v.risk))
   labels[k].append(candidate);frontier.append(candidate)
 if complete.is_empty():return {}
 complete.sort_custom(ranked);var best:Dictionary=complete[0]
 var warnings:Array=[]
 if best.departure:warnings.append("Opportunity attack on departure")
 if best.brace:warnings.append("Enemy Spearwall")
 if best.exposure:warnings.append("Controlled intermediate ground")
 return {"valid":true,"actor":id,"origin":origin,"waypoints":waypoints.duplicate(),"path":best.path,"cost":best.cost,"fatigue":best.fatigue,"known_danger":not warnings.is_empty(),"danger_text":"; ".join(warnings),"risk_steps":best.risk_steps}
