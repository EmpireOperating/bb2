extends "res://caravan_hunt/custody.gd"
## Buyers own paid cargo; World/Traffic own the same physical wagons as food freight.
const MAX_LOAD = 4
const INTERVAL = 3
const UNPACK_DAYS = 2


func setup(day: int, world) -> void:
 enabled=true;state={"version":1,"started":day,"next_dispatch":{},"shipments":{}}
 for route in routes(world):state.next_dispatch[route]=day

func routes(world) -> Array:
 var out: Array=[]
 for route in world.config.routes:
  out.append("material:"+route.id+":out");out.append("material:"+route.id+":back")
 return out

func incoming(c,town: String,kind: String) -> int:
 var amount=0
 for id in state.shipments:
  var s: Dictionary=state.shipments[id]
  if s.destination==town and s.kind==kind and c.world.caravans[id].status in ["waiting","transit","escort"]:amount+=s.amount
 return amount

func best_order(c,origin: String,require_vehicle: bool=true) -> Dictionary:
 if not enabled or require_vehicle and c.world.wagon_stock[origin]<1:return {}
 var e=c.economy;var best: Dictionary={};var high=-INF
 # This quote is read-only. Never share demand across dispatch/re-quote mutations.
 var demand: Dictionary={}
 for id in routes(c.world):
  var route=c.world.route_data(id);var destination: String=route.path[2]
  if route.path[0]!=origin or c.day<state.next_dispatch[id]:continue
  if state.shipments.keys().any(func(k):return c.world.caravans[k].route==id and c.world.caravans[k].status in ["waiting","transit","escort"]):continue
  for kind in e.TRADE_GOODS:
   # Specialised producers supply consumers, rather than bouncing the same stock back.
   if e.Industry.RAW[e.role(c.world,origin)].get(kind,0)<=e.Industry.RAW[e.role(c.world,destination)].get(kind,0):continue
   if kind=="silk" and not e.industry.prosperous(c,destination):continue
   var needed: int=_quote_needed(c,destination,kind,demand)
   var reserve: int=maxi(e.TARGET[kind],_quote_needed(c,origin,kind,demand))
   var available: int=e.stock(c,origin,kind)-reserve
   var target: int=e.TARGET[kind]+needed
   var missing: int=target-e.stock(c,destination,kind)-incoming(c,destination,kind)
   var amount=mini(MAX_LOAD,mini(available,missing))
   if amount<1:continue
   var source_target: int=e.TARGET[kind]+_quote_needed(c,origin,kind,demand)
   var raw_cost=0.0
   for i in amount:raw_cost+=e.unit_price(c,origin,kind,e.stock(c,origin,kind)-i,source_target)*0.75
   var cost=ceili(raw_cost);var fee=6+2*(route.days[0]+route.days[1])
   if e.towns[destination].cash<cost+fee+24:continue
   var local_value: float=e.unit_price(c,destination,kind,e.stock(c,destination,kind),target)*amount
   if local_value<cost+fee and needed<=e.stock(c,destination,kind):continue
   var score: float=(local_value-cost-fee)+(80 if needed>e.stock(c,destination,kind) else 0)+missing
   if score>high:
    high=score;best={"route":id,"origin":origin,"destination":destination,"kind":kind,"amount":amount,"cost":cost,"fee":fee}
 return best

func _quote_needed(c,town: String,kind: String,demand: Dictionary) -> int:
 if not demand.has(town):
  var totals: Dictionary={}
  for job in c.economy.industry.orders(c,town,false):
   if c.economy.industry.funds(c,town,job)>=job.fee:
    for input in job.inputs:totals[input]=totals.get(input,0)+job.inputs[input]
  demand[town]=totals
 return mini(demand[town].get(kind,0),12)

func dispatch(c,order: Dictionary) -> String:
 # Requote immediately so a stale plan cannot oversell stock or overdraw a buyer.
 if order.is_empty():return ""
 var current=best_order(c,order.get("origin","")) if order.get("origin") in c.world.TOWNS else {}
 if current!=order:return ""
 var id: String=c.world.launch_material(order.route,order.kind,order.amount)
 if id.is_empty():return ""
 var g: Dictionary=c.economy.towns[order.origin].goods[order.kind]
 g.stock-=order.amount;g.exported+=order.amount
 c.economy.industry.debit(c,order.destination,order.cost+order.fee)
 c.economy.industry.credit(c,order.origin,order.cost)
 var entry=order.duplicate();entry.erase("route")
 entry["day"]=c.day;entry["phase"]="shipping";entry["camp"]="";entry["generation"]=0;entry["unpacked_day"]=0
 state.shipments[id]=entry;state.next_dispatch[order.route]=c.day+INTERVAL
 c.world.log_event("%s buys %s from %s for %dc plus %dc freight. %s departs tomorrow."%[c.node(order.destination).name,c.world.cargo_text(id),c.node(order.origin).name,order.cost,order.fee,c.world.short_id(id)])
 return id

func plan(c) -> void:
 if not enabled:return
 for town in c.world.TOWNS:dispatch(c,best_order(c,town))

func sync(c) -> void:
 if not enabled:return
 for id in state.shipments:
  var s: Dictionary=state.shipments[id];var wagon: Dictionary=c.world.caravans[id]
  if s.has("seizer"):
   sync_manifest(c,id,s);continue
  if s.phase in ["delivered","looted"]:continue
  if wagon.status=="delivered":
   var g: Dictionary=c.economy.towns[s.destination].goods[s.kind]
   g.stock+=s.amount;g.imported+=s.amount;s.phase="delivered";s.camp="";s.generation=0;s.unpacked_day=0
   c.world.log_event("%s unloads %s at %s. The materials enter local stores."%[c.world.short_id(id),c.world.cargo_text(id),c.node(s.destination).name])
  elif wagon.status=="seized" and c.day>=wagon.seized_day+UNPACK_DAYS:
   if s.phase!="camp":
    s.phase="camp";s.camp=c.world.route_data(wagon.route).path[1];s.generation=c.world.camps[s.camp].generation;s.unpacked_day=c.day
    c.world.log_event("Raiders unpack %s from %s into %s. Recovery work remains available while the goods are held."%[c.world.cargo_text(id),c.world.short_id(id),c.node(s.camp).name])
  elif wagon.status in ["transit","escort","waiting"] and s.phase=="camp":
   s.phase="shipping";s.camp="";s.generation=0;s.unpacked_day=0

func claim_camp(c,site: String,generation: int) -> Dictionary:
 sync(c)
 claim_secured(c,site,generation)
 var loot: Dictionary={}
 for id in state.shipments:
  var s: Dictionary=state.shipments[id];var wagon: Dictionary=c.world.caravans[id]
  if s.phase!="camp" or s.camp!=site or s.generation!=generation or wagon.status!="seized":continue
  # A signed recovery reserves that shipment for its buyer.
  if c.active.get("kind")=="recover" and c.active.get("shipment")==id:continue
  s.phase="looted";wagon.status="plundered"
  c.economy.cargo[s.kind]+=s.amount;c.economy.cargo_looted[s.kind]+=s.amount
  loot[s.kind]=loot.get(s.kind,0)+s.amount
 if not loot.is_empty():c.note("Captured trade stores: "+describe(loot)+". Cargo placed in company stores.")
 return loot

func describe(goods: Dictionary) -> String:
 var out: Array=[]
 for kind in goods:out.append("%d %s"%[goods[kind],kind])
 return ", ".join(out)

# A terminal return receipt is permanent and already bound to its buyer by restore.
# Use those receipts as the saved town ledger, including in older freight saves;
# never reconstruct an award from faction ownership, cargo quantity or journal text.
const RETURN_RENOWN := 4
func town_renown(town: String) -> int:
 if not enabled:return 0
 var total:=0
 for s in state.shipments.values():
  if s.destination==town and s.phase in ["returned","paid_return"]:total+=RETURN_RENOWN
 return total

func snapshot() -> Dictionary:return state.duplicate(true)

func restore(raw: Variant,data: Dictionary,world,economy) -> bool:
 if not raw is Dictionary or raw.get("version")!=1 or not raw.get("started") is int or raw.started<1 or raw.started>data.day:return false
 if not raw.get("next_dispatch") is Dictionary or not raw.get("shipments") is Dictionary:return false
 if raw.next_dispatch.size()!=routes(world).size():return false
 for route in routes(world):
  if not raw.next_dispatch.get(route) is int or raw.next_dispatch[route]<raw.started or raw.next_dispatch[route]>data.day+INTERVAL:return false
 var exports={};var imports={};var loot={};var spent={};var earned={}
 for town in world.TOWNS:exports[town]={};imports[town]={};spent[town]=0;earned[town]=0
 var count=0
 for wagon in world.caravans.values():
  if wagon.has("material"):count+=1
 if count!=raw.shipments.size():return false
 for id in raw.shipments:
  var s=raw.shipments[id]
  if not s is Dictionary or not world.caravans.has(id) or not world.caravans[id].has("material"):return false
  var wagon: Dictionary=world.caravans[id];var route=world.route_data(wagon.route)
  if s.get("origin")!=route.path[0] or s.get("destination")!=route.path[2] or s.get("kind") not in economy.TRADE_GOODS:return false
  for key in ["amount","cost","fee","day","generation","unpacked_day"]:
   if not s.get(key) is int or s[key]<0:return false
  if s.amount<1 or s.amount>MAX_LOAD or s.amount!=wagon.material.amount or s.kind!=wagon.material.kind or s.cost<1 or s.cost>economy.BASE[s.kind]*s.amount*2:return false
  if s.fee!=6+2*(route.days[0]+route.days[1]) or s.day<raw.started or s.day>data.day or wagon.depart_day!=s.day+1:return false
  if not s.get("camp") is String:return false
  # A material record is the sole owner: never admit an extra inventory/list
  # layered on top of an otherwise valid receipt.
  if s.has("seizer") and s.size()!=14:return false
  var trace: Dictionary=data.get("traffic",{}).get("traces",{}).get(id,{})
  if s.has("seizer")!=trace.has("seizer"):return false
  if s.has("seizer"):
   if not valid_manifest(data,world,id,s,wagon,trace):return false
   if s.receiver!="":
    imports[s.receiver][s.kind]=imports[s.receiver].get(s.kind,0)+s.amount
    spent[s.receiver]+=s.price
  elif s.get("phase") not in ["shipping","camp","delivered","looted"]:return false
  elif s.phase=="delivered":
   if wagon.status!="delivered":return false
   imports[s.destination][s.kind]=imports[s.destination].get(s.kind,0)+s.amount
  elif s.phase=="looted":
   if wagon.status!="plundered":return false
   loot[s.kind]=loot.get(s.kind,0)+s.amount
   var claim=data.economy.camp_claims.get("%s/%d"%[s.camp,s.generation],{})
   if claim.get("materials",{}).get(s.kind,0)<s.amount:return false
  elif s.phase=="camp":
   if s.camp not in world.SITES or wagon.status!="seized" or not world.camps[s.camp].active or world.camps[s.camp].generation!=s.generation:return false
  elif wagon.status not in ["waiting","transit","escort","seized"]:return false
  if s.phase in ["camp","looted"]:
   if s.camp!=route.path[1] or s.generation<1 or s.generation>world.camps[s.camp].generation or s.unpacked_day<wagon.seized_day+UNPACK_DAYS or s.unpacked_day>data.day:return false
  elif s.phase in ["shipping","delivered"] and (s.camp!="" or s.generation!=0 or s.unpacked_day!=0):return false
  exports[s.origin][s.kind]=exports[s.origin].get(s.kind,0)+s.amount
  spent[s.destination]+=s.cost+s.fee;earned[s.origin]+=s.cost
 for town in world.TOWNS:
  if economy.towns[town].paid<spent[town] or economy.towns[town].receipts<earned[town]:return false
  for kind in economy.STORED:
   var g: Dictionary=economy.towns[town].goods[kind]
   if g.exported!=exports[town].get(kind,0) or g.imported!=imports[town].get(kind,0):return false
 for kind in economy.TRADE_GOODS:
  if economy.cargo_looted[kind]!=loot.get(kind,0):return false
 for claim_key in economy.camp_claims:
  var expected={}
  for s in raw.shipments.values():
   if s.phase=="looted" and "%s/%d"%[s.camp,s.generation]==claim_key:expected[s.kind]=expected.get(s.kind,0)+s.amount
  if economy.camp_claims[claim_key].get("materials",{})!=expected:return false
 enabled=true;state=raw.duplicate(true);return true
