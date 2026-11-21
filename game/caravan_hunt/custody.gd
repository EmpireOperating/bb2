extends RefCounted
## Material shipment IDs, not a fungible second company inventory, own sealed loads.
var enabled = false
var state: Dictionary = {}
const HUNT_PHASES = ["band", "secured", "company", "returned", "paid_return", "sold", "lost", "fencing", "fenced"]

func physical(id: String) -> bool:
 return enabled and state.shipments.get(id,{}).has("seizer")

func visible_wrecks(c) -> Array:
 var rows := []
 if not enabled or not c.dungeons.active.is_empty():return rows
 for id in c.traffic.traces:
  var t: Dictionary = c.traffic.traces[id]
  if not c.overworld.discovered(t.position) or c.overworld.position.distance_to(t.position)>c.overworld.sight():continue
  var days: int = c.day-t.day
  var age := "today" if days==0 else "yesterday" if days==1 else "%d days ago" % days
  var clue:="Wrecked wagon · %s. Search for footprints nearby; old tracks fade." % age
  if t.inspected and physical(id) and c.overworld.position.distance_to(t.position)<=20:
   var s: Dictionary=state.shipments[id]
   clue="Waybill: %d %s for %s. Wrecked %s." % [s.amount,s.kind,c.node(s.destination).name,age]
   var prints=c.overworld.tracks
   for mark in prints.marks.values():
    if mark.position.distance_to(t.position)<=32 and prints.visible(c,mark):
     clue+=" Nearby prints: %s, heading %s." % [prints.freshness(mark),prints.DIRECTIONS[mark.heading]];break
  rows.append({"id":id,"position":t.position,"clue":clue})
 return rows

func held_manifests(c) -> Array:
 var rows := []
 if enabled:
  for id in state.shipments:
   var s: Dictionary = state.shipments[id]
   if s.phase!="company":continue
   var signed: bool=c.active.get("kind")=="recover" and c.active.get("shipment")==id
   var price:=0
   if not signed and c.in_town() and c.location!=s.destination:
    var quote:=sale_price(c,s,c.location)
    if c.economy.towns[c.location].cash>=quote:price=quote
   rows.append({"id":id,"description":"%d %s" % [s.amount,s.kind],"destination":s.destination,"sale_crowns":price,"signed":signed})
 return rows

func capture_material(c,id: String,scout_id: String) -> bool:
 if not enabled or c.traffic.missions.get(scout_id)!=id:return false
 var s: Dictionary = state.shipments.get(id,{})
 if s.get("phase")!="shipping" or c.world.caravans[id].status!="transit":return false
 var scout: Dictionary = c.overworld.scouts[scout_id];var wagon: Dictionary = c.traffic.wagons[id]
 if scout.defeated or wagon.raider!=scout_id or wagon.remaining!=0 or scout.position.distance_to(wagon.position)>=18:return false
 # The chassis is wrecked here, not delivered to a route waypoint. The same
 # manifest survives, carried by the actual scout even if it flees or is displaced.
 var chassis: Dictionary = c.world.caravans[id]
 chassis.status="plundered";chassis.index=1;chassis.seized_day=c.day;chassis.remaining=0
 s.phase="band";s.seizer=scout_id;s.camp=scout.site;s.generation=scout.generation
 s.receiver="";s.price=0
 return true

func sync_manifest(c,id: String,s: Dictionary) -> void:
 var camp: Dictionary = c.world.camps[s.camp]
 if s.phase in ["band","fencing"]:
  var scout: Dictionary = c.overworld.scouts[s.seizer]
  if scout.defeated:s.phase="lost"
  elif s.phase=="band" and c.day>=c.world.caravans[id].seized_day+2 and c.overworld.pending!=scout.id and camp.active and camp.generation==s.generation and scout.position.distance_to(c.overworld.places[s.camp])<=10:
   s.phase="secured";s.unpacked_day=c.day
 elif s.phase=="secured" and (not camp.active or camp.generation!=s.generation):s.phase="lost"

func retrieve_band(c,id: String) -> Array:
 var recovered := []
 if not enabled or c.phase!="battle" or c.battle.result!="victory":return recovered
 var engaged: bool=c.encounter.get("kind")=="scout" and c.encounter.get("id")==id
 for row in c.recon.engagement.get("rows",[]):
  if row.party==id and row.health>0:engaged=true;break
 if not engaged:return recovered
 for wid in state.shipments:
  var s: Dictionary = state.shipments[wid]
  if s.phase in ["band","fencing"] and s.seizer==id:
   s.phase="company";recovered.append("%d %s" % [s.amount,s.kind])
 return recovered

func claim_secured(c,site: String,generation: int) -> void:
 if c.phase!="battle" or c.battle.result!="victory" or c.location!=site or not c.overworld.at_site(site):return
 var job:Dictionary=c.battle_job()
 if job.get("kind") not in ["camp","clear","legacy"] or job.get("site",job.get("target"))!=site or job.get("generation")!=generation:return
 for s in state.shipments.values():
  if s.phase=="secured" and s.camp==site and s.generation==generation:
   s.phase="company";c.note("Recovered a sealed load: %d %s for %s." % [s.amount,s.kind,c.node(s.destination).name])

func open_recovery(id: String) -> bool:
 return physical(id) and state.shipments[id].phase in ["band","secured","company","fencing"]

func sale_price(c,s: Dictionary,town: String) -> int:
 var e=c.economy;var stock: int=e.stock(c,town,s.kind);var value:=0.0
 var demand: int=e.TARGET[s.kind]+e.industry.needed(c,town,s.kind)
 for i in s.amount:value+=e.unit_price(c,town,s.kind,stock+i+1,demand)
 return floori(0.75*value)

static func valid_manifest(data: Dictionary,world,id: String,s: Dictionary,wagon: Dictionary,t: Dictionary) -> bool:
 if s.get("phase") not in HUNT_PHASES or wagon.status!="plundered" or not s.seizer is String or s.seizer!=t.get("seizer"):return false
 var party=data.overworld.scouts.get(s.seizer)
 if not party is Dictionary or t.site!=s.camp or t.generation!=s.generation or t.day!=wagon.seized_day or t.position!=data.traffic.wagons[id].position:return false
 if t.site!=world.route_data(wagon.route).path[1] or t.generation<1 or wagon.seized_day<wagon.depart_day:return false
 if s.phase in ["band","fencing"] and party.defeated:return false
 if s.phase=="band" and s.unpacked_day!=0:return false
 if s.phase in ["secured","fencing","fenced"] and s.unpacked_day==0:return false
 if s.unpacked_day!=0 and (s.unpacked_day<wagon.seized_day+2 or s.unpacked_day>data.day):return false
 if s.phase=="secured" and (not world.camps[s.camp].active or s.generation!=world.camps[s.camp].generation):return false
 if s.phase in ["company","returned","paid_return","sold"] and not party.defeated and not data.economy.camp_claims.has("%s/%d"%[s.camp,s.generation]):return false
 if not s.get("receiver") is String or not s.get("price") is int or s.price<0:return false
 if s.phase in ["returned","paid_return"] and (s.receiver!=s.destination or s.price!=0):return false
 if s.phase=="paid_return" and "recover_"+id not in data.used_jobs:return false
 if s.phase in ["sold","fenced"]:
  if s.receiver not in world.TOWNS or s.price<1 or s.phase=="sold" and s.receiver==s.destination:return false
 elif s.phase not in ["returned","paid_return"] and (s.receiver!="" or s.price!=0):return false
 return true

func _deliver(c,s: Dictionary,town: String,phase: String,price: int) -> void:
 # Every disposition is terminal. The player cannot sell these again via the ordinary market.
 s.phase=phase;s.receiver=town;s.price=price
 var g: Dictionary = c.economy.towns[town].goods[s.kind]
 g.stock+=s.amount;g.imported+=s.amount
 if price>0:c.economy.industry.debit(c,town,price)

func settle_manifest(c,id: String,action: String) -> bool:
 if not physical(id) or state.shipments[id].phase!="company" or action not in ["return","sell"]:return false
 if c.phase!="camp" or c.over() or not c.in_town() or c.dungeons.active!="" or not c.encounter.is_empty():return false
 var ow=c.overworld
 if not ow.paused or not ow.path.is_empty() or ow.destination!="" or ow.pending!="" or ow.rest_left!=0 or ow.position!=ow.places[c.location] or not c.exploration.task.is_empty() or c.traffic.pursuit!="":return false
 var s: Dictionary = state.shipments[id];var town: String = c.location
 var signed: bool = c.active.get("kind")=="recover" and c.active.get("shipment")==id
 if action=="sell":
  if signed or town==s.destination:return false
  var price:=sale_price(c,s,town)
  if price<1 or c.economy.towns[town].cash<price:return false
  _deliver(c,s,town,"sold",price);c.crowns+=price
  c.note("Sold the sealed %s load for %d crowns at %s." % [s.kind,price,c.node(town).name])
 else:
  if town!=s.destination:return false
  if signed and (c.day>c.active.deadline or c.economy.escrow.get("id")!=c.active.id or c.economy.escrow.get("pay")!=c.active.pay):return false
  _deliver(c,s,town,"paid_return" if signed else "returned",0)
  c.note("Returned %d %s to %s's stores." % [s.amount,s.kind,c.node(town).name])
  if signed:c.finish_job(true)
 return true

# Payroll can send the seizing party to an actual market. No money is raised
# by a timer or a valuation of stores. The caller credits the receipt once.
func load_for_sale(c,id: String) -> bool:
 if not physical(id):return false
 var s: Dictionary=state.shipments[id];var party: Dictionary=c.overworld.scouts[s.seizer]
 if s.phase!="secured" or party.defeated or c.overworld.pending==party.id or not c.world.camps[s.camp].active or c.world.camps[s.camp].generation!=s.generation or party.position.distance_to(c.overworld.places[s.camp])>10:return false
 s.phase="fencing";return true

func sell_secured(c,id: String,town: String) -> int:
 if not physical(id) or not town in c.world.TOWNS:return 0
 var s: Dictionary=state.shipments[id];var party: Dictionary=c.overworld.scouts[s.seizer]
 if s.phase!="fencing" or party.defeated or c.overworld.pending==party.id or party.position.distance_to(c.overworld.places[town])>10:return 0
 var price:=sale_price(c,s,town)
 if price<1 or c.economy.towns[town].cash<price:return 0
 _deliver(c,s,town,"fenced",price);c.reconcile_contract();return price
