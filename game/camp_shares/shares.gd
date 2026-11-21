extends RefCounted
## Cash only. Freight owns the goods and traffic; camp life, recon and bandits own people.
const PERIOD := 5
const HIRE := 6
var accounts := {}
var sales := {} # Shipment ID -> legacy visitor buy-back or physical seizer receipt.

func account(c, site: String) -> Dictionary:
 var key: String = c.camp_life.key(site,c.world.camps[site].generation)
 if not accounts.has(key): accounts[key] = {"cash":0,"shares":0,"hiring":0,"claimed":0,"lost":0,"misses":0,"departures":0}
 return accounts[key]

# Called when a second, moving wagon actually reaches the camp's road stop. Its
# factor can use its own endpoint merchant's cash to buy that merchant's load back.
func market_stop(c, visitor: String) -> bool:
 if not c.raiders.enabled or c.raiders.rules_version != 6: return false
 var visiting: Dictionary = c.world.caravans[visitor]
 var road: Dictionary = c.world.route_data(visiting.route); var site: String = road.path[1]
 var v: Dictionary = c.traffic.wagons[visitor]; var camp: Dictionary = c.world.camps[site]
 if visiting.status != "transit" or visiting.index != 1 or v.raider != "" or v.position.distance_to(c.overworld.places[site]) > 10: return false
 if not camp.active or c.world.protected_road(site) or c.guards.cover(c,c.overworld.places[site],200): return false
 if not c.recon.roster(c,site).any(func(row):return row.health > 0): return false
 for id in c.economy.freight.state.shipments:
  var order: Dictionary = c.economy.freight.state.shipments[id]
  var trace: Dictionary = c.traffic.traces.get(id,{})
  if trace.get("site") != site or trace.get("generation") != camp.generation: continue
  if order.phase != "camp" or order.camp != site or order.generation != camp.generation or sales.has(id): continue
  if c.active.get("kind") == "recover" and c.active.get("shipment") == id: continue
  var buyer: String = order.destination
  if buyer not in [road.path[0],road.path[2]]: continue
  var price := maxi(1,int(order.cost)/2)
  if c.economy.towns[buyer].cash < price or not c.world.recover_shipment(id): continue
  c.economy.industry.debit(c,buyer,price)
  var merchant: Dictionary = c.economy.towns[buyer]
  merchant["haul_paid"] = merchant.get("haul_paid",0)+price
  account(c,site).cash += price
  sales[id] = {"site":site,"generation":camp.generation,"buyer":buyer,"visitor":visitor,"price":price,"day":c.day}
  c.world.log_event("%s pays %dc at %s for the return of %s (%s). The loaded wagon resumes its journey." % [c.node(buyer).name,price,c.node(site).name,c.world.short_id(id),c.world.cargo_text(id)])
  return true
 return false

# The manifest is the mission: no duplicate store, timer or saved target. Resume
# from its phase and the original scout's real position after a checkpoint.
func fence_order(c, party: Dictionary) -> Dictionary:
 if not c.raiders.enabled or c.raiders.rules_version!=6 or c.raiders.displaced(c,party.id): return {}
 var f=c.economy.freight
 if not f.enabled or party.defeated or c.overworld.pending==party.id or c.guards.engaged(party.id): return {}
 if c.world.protected_road(party.site) or c.guards.cover(c,party.position,200): return {}
 var secured: String=""; var carried: String=""
 for id in f.state.shipments:
  var lot: Dictionary=f.state.shipments[id]
  if lot.get("seizer")!=party.id or lot.camp!=party.site or lot.generation!=party.generation: continue
  if lot.phase=="fencing": carried=id; break
  if secured=="" and lot.phase=="secured" and not _signed(c,id): secured=id
 var id: String=carried if carried!="" else secured
 if id=="" or sales.has(id) or _signed(c,id): return {}
 if carried=="" and party.position.distance_to(c.overworld.places[party.site])>10: return {}
 var lot: Dictionary=f.state.shipments[id]
 # These are the waybill's two markets, not a scan of every town in the world.
 var markets: Array=[lot.destination,lot.origin]
 var home: Vector2=c.overworld.places[lot.camp]
 if home.distance_to(c.overworld.places[lot.origin])<home.distance_to(c.overworld.places[lot.destination]): markets.reverse()
 for town in markets:
  var price: int=f.sale_price(c,lot,town)
  if price<=0 or c.economy.towns[town].cash<price: continue
  if carried=="" and not f.load_for_sale(c,id): return {}
  var market: Vector2=c.overworld.places[town]
  if party.position.distance_to(market)<=10:
   if c.guards.cover(c,market,200): return {}
   var received: int=f.sell_secured(c,id,town)
   if received>0:
    var key: String=c.camp_life.key(lot.camp,lot.generation)
    accounts[key].cash+=received
    var merchant: Dictionary=c.economy.towns[town]
    merchant["haul_paid"]=merchant.get("haul_paid",0)+received
    sales[id]={"site":lot.camp,"generation":lot.generation,"buyer":town,"seizer":party.id,"price":received,"day":c.day}
   return {}
  c.bandits.change_mode(c.bandits.bands[party.id],party,"scouting")
  return {"position":market,"pace":17.0}
 return {}

func _signed(c,id: String) -> bool:
 return c.active.get("kind")=="recover" and c.active.get("shipment")==id

func can_hire(c, site: String, count: int) -> bool:
 var a := account(c,site)
 return not c.world.protected_road(site) and not c.guards.cover(c,c.overworld.places[site],200) and count > 0 and a.misses == 0 and a.cash >= count*HIRE + c.raiders.population(c,site)+count and c.raiders.can_invest(c,site,count*(c.camp_life.RECRUIT_FOOD+c.raiders.BUFFER_DAYS))

func commission(c, site: String, count: int) -> void:
 var a := account(c,site); a.cash -= count*HIRE; a.hiring += count*HIRE

func can_expand(c, r: Dictionary, b: Dictionary) -> bool:
 if b.has("lineage") or b.capacity >= 6-c.recon.resident_count(c.world.camp_role(r.site),3): return false
 return c.raiders.living(c,r.party) == b.capacity and not c.world.protected_road(r.site) and not c.guards.cover(c,c.overworld.places[r.site],200)

func enlist(c, r: Dictionary, b: Dictionary) -> void:
 # Transfer one already-trained person at home, never a new party or a revived ID.
 var slot: int = b.capacity
 if not b.has("base_capacity"): b["base_capacity"] = slot
 b.members[slot] = "%s/m%d" % [r.party,b.next_member]; b.next_member += 1
 b.health[slot] = 1000; b.capacity += 1; r.reserve -= 1; r.assigned += 1
 c.world.log_event("A trained recruit joins %s's field party; it now must feed %d." % [c.node(r.site).name,b.capacity])

func payday(c, r: Dictionary) -> void:
 if (c.day-r.started)%PERIOD != 0: return
 var a := account(c,r.site); var due: int = c.raiders.population(c,r.site)
 if due == 0: return
 if a.cash >= due:
  a.cash -= due; a.shares += due; a.misses = 0
  c.world.log_event("%s distributes %d crowns in shares." % [c.node(r.site).name,due]); return
 a.misses += 1
 c.world.log_event("%s misses payday: %dc due for %d people; %dc in the purse." % [c.node(r.site).name,due,due,a.cash])
 if a.misses < 2: return
 # Keep the self-sufficient core. Repeat misses shed reserves first, then a real
 # resident, then a field hand (only when actually present and disengaged).
 if r.reserve > 0:
  r.reserve -= 1; r.deserted += 1
 else:
  var g: Dictionary = c.recon.garrisons[c.recon.key(r.site,r.generation)]
  var b: Dictionary = c.bandits.bands[r.party]
  if c.recon.home_party(c,r.site) == r.party and c.raiders.living(c,r.party)>1 and c.overworld.pending != r.party and not c.traffic.missions.has(r.party) and not c.farm.engaged(r.party):
   for i in range(b.capacity-1,-1,-1):
    if b.health[i] == 0: continue
    if not b.has("departed"): b["departed"] = []
    b.departed.append(b.members[i]); b.health[i] = 0; break
  else:
   var slot: int = g.health.find_custom(func(hp):return hp > 0)
   if slot == -1 or due <= 1: return
   g.health[slot] = 0
 a.departures += 1
 c.world.log_event("After missed shares a raider deserts %s." % c.node(r.site).name)

func claim(c, site: String) -> void:
 var a := account(c,site)
 if a.cash > 0:
  c.economy.camp_claims["%s/%d" % [site,c.world.camps[site].generation]]["haul"] = a.cash
  c.crowns += a.cash; a.claimed += a.cash
  c.note("Recovered the camp purse: %d crowns." % a.cash); a.cash = 0

func restore(raw: Variant,w,e,life,traffic) -> bool:
 if not raw is Dictionary or raw.size()!=2 or not raw.get("sales") is Dictionary or not raw.get("accounts") is Dictionary or raw.accounts.size()!=life.records.size(): return false
 var earned := {}; var paid := {}; var freight_spend := {}
 for order in e.freight.state.shipments.values():
  freight_spend[order.destination]=freight_spend.get(order.destination,0)+order.cost+order.fee
  # Count every actual disposition once, including player sales and historical
  # freight-only fences. The latter do not earn a retrospective payroll credit.
  if order.get("phase")=="sold" or order.get("phase")=="fenced":
   freight_spend[order.receiver]=freight_spend.get(order.receiver,0)+order.price
 for id in raw.sales:
  var sale = raw.sales[id]; var order = e.freight.state.shipments.get(id)
  if not order is Dictionary or not sale is Dictionary or sale.size()!=6: return false
  var cargo: Dictionary = w.caravans[id]; var trace: Dictionary = traffic.traces.get(id,{})
  if not sale.get("generation") is int or sale.get("site")!=trace.get("site") or sale.generation!=trace.get("generation"): return false
  if not sale.get("day") is int or sale.day<cargo.seized_day+e.freight.UNPACK_DAYS or sale.day>w.day or not sale.get("price") is int: return false
  if order.has("seizer"):
   if order.phase!="fenced" or sale.get("seizer")!=order.seizer or trace.get("seizer")!=order.seizer: return false
   if sale.site!=order.camp or sale.generation!=order.generation or sale.day<order.unpacked_day: return false
   if sale.get("buyer")!=order.receiver or sale.buyer not in [order.origin,order.destination] or sale.price!=order.price: return false
  else:
   if not sale.get("visitor") is String or not w.caravans.has(sale.visitor) or sale.visitor==id: return false
   var visitor: Dictionary = w.caravans[sale.visitor]; var road: Dictionary = w.route_data(visitor.route)
   if sale.site!=w.route_data(cargo.route).path[1] or sale.site!=road.path[1] or visitor.depart_day>sale.day: return false
   if sale.get("buyer")!=order.destination or sale.buyer not in [road.path[0],road.path[2]] or not cargo.recovered or not cargo.guarded or cargo.status not in ["transit","delivered"]: return false
   if sale.price!=maxi(1,int(order.cost)/2): return false
   freight_spend[sale.buyer]=freight_spend.get(sale.buyer,0)+sale.price
  var k: String = life.key(sale.site,sale.generation)
  if not life.records.has(k): return false
  earned[k] = earned.get(k,0)+sale.price; paid[sale.buyer] = paid.get(sale.buyer,0)+sale.price
 for town in e.towns:
  var t: Dictionary = e.towns[town]
  if not t.get("haul_paid",0) is int or t.get("haul_paid",0)!=paid.get(town,0) or freight_spend.get(town,0)>t.paid: return false
 for k in life.records:
  var a = raw.accounts.get(k); var r: Dictionary = life.records[k]
  if not a is Dictionary or a.size()!=7: return false
  for field in ["cash","shares","hiring","claimed","lost","misses","departures"]:
   if not a.get(field) is int or a[field]<0: return false
  if (r.closed and a.cash!=0) or (not r.closed and a.lost!=0): return false
  if a.cash+a.shares+a.hiring+a.claimed+a.lost!=earned.get(k,0) or a.hiring!=HIRE*(r.recruit_spent/life.RECRUIT_FOOD): return false
  if a.claimed!=e.camp_claims.get("%s/%d"%[r.site,r.generation],{}).get("haul",0): return false
  var periods: int = (r.last_day-r.started)/PERIOD
  if a.misses>periods or a.departures>periods or a.shares>16*periods: return false
 accounts=raw.accounts.duplicate(true); sales=raw.sales.duplicate(true); return true

func snapshot() -> Dictionary:
 return {"accounts":accounts.duplicate(true),"sales":sales.duplicate(true)}
