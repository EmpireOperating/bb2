extends RefCounted
## Public reports are snapshots. Caravans carry copies; the company learns only
## what it hears in a town. This component never changes world resources or fog.
const Economy = preload("res://src/economy.gd")
const MAX_SHORTFALL = 12 # A report of 12+ is a lower bound, not a larger market quote.
const MAX_BOARD = 36
const MAX_JOURNAL = 48
const OLD_HOURS = 72
const KINDS = ["roads","farm","missing","shortage","lean","plenty","surplus","quiet"]
var enabled = false
var boards: Dictionary = {}
var packets: Dictionary = {}
var leads: Dictionary = {}
var directions: Dictionary = {}
var pinned = "" # Saved bookmark; never a map position.
var navigation = preload("res://src/landmark_directions.gd").new()

static func clock(c) -> int:
 return (c.day-1)*1440+roundi(c.overworld.hour*60)
static func key(r: Dictionary) -> String:
 return r.town+"|"+r.kind+"|"+r.subject
func setup(c) -> void:
 enabled = true
 boards.clear();packets.clear();leads.clear();directions.clear();pinned=""
 for town in c.world.TOWNS:boards[town]={}
func record(town: String,kind: String,subject: String,value: int,when: int) -> Dictionary:
 return {"town":town,"kind":kind,"subject":subject,"value":value,"observed":when}
func trim(book: Dictionary,limit: int) -> void:
 var ids=book.keys();ids.sort_custom(func(a,b):return book[a].report.observed>book[b].report.observed)
 for id in ids.slice(limit):book.erase(id)
# The chassis can remain wrecked after the sealed goods reach the buyer.
# Consult the physical receipt only for that buyer, never to rewrite a rumour abroad.
func buyer_has_goods(c,town: String,id: String) -> bool:
 var freight=c.economy.freight
 if not freight.physical(id):return false
 var lot: Dictionary=freight.state.shipments[id]
 return lot.destination==town and lot.receiver==town

func observe(c,town: String) -> void:
 if not enabled:return
 var stamp=clock(c);var local=[]
 var threats=c.world.adjacent_sites(town).filter(func(site):return c.world.camps[site].active and not c.world.protected_road(site))
 if not threats.is_empty():local.append(record(town,"roads","",threats.size(),stamp))
 var farm=c.farm.for_town(town)
 if farm!=null and (farm.damage>0 or not farm.raid.is_empty()):local.append(record(town,"farm","",1,stamp))
 # Merchants know their own overdue shipments, not the raiders' hidden locations.
 for wagon in c.world.caravans.values():
  var route=c.world.route_data(wagon.route)
  if route.path[2]==town and wagon.status in ["transit","seized","plundered","escort"] and c.day>wagon.depart_day+int(route.days[0])+int(route.days[1])+1:
   if not buyer_has_goods(c,town,wagon.id):local.append(record(town,"missing",wagon.id,1,stamp))
 if c.economy.enabled:local.append_array(economic_reports(c,town,stamp))
 if local.is_empty():local.append(record(town,"quiet","",0,stamp))
 var book:Dictionary=boards[town]
 for id in book.keys():
  if book[id].report.town==town or stamp-book[id].report.observed>14*1440:book.erase(id)
 for report in local:book[key(report)]={"report":report,"via":town,"carrier":"","received":stamp}
 trim(book,MAX_BOARD)
# Inspect this market only. Freight plans are excluded: quoting a prospective
# shipment consults other towns and is not evidence of local workshop demand.
func economic_reports(c,town: String,stamp: int) -> Array:
 var e=c.economy;var market: Dictionary=c.world.towns[town];var out: Array=[]
 if c.Market.tier(market.stock,c.world.factions[market.owner].treasury,market.demand,market.pressure)==3:
  out.append(record(town,"plenty","food",market.stock,stamp))
 elif market.stock<5*market.demand:
  out.append(record(town,"lean","food",market.stock,stamp))
 var needs: Dictionary={}
 for job in e.industry.orders(c,town,false):
  if e.industry.funds(c,town,job)<job.fee:continue
  for good in job.inputs:needs[good]=needs.get(good,0)+job.inputs[good]
 var deficits: Array=[];var surplus: Dictionary={};var largest:=0
 var grain_lead: Dictionary={}
 for good in e.STORED:
  var stock: int=e.stock(c,town,good);var free: int=stock-needs.get(good,0)
  if free<0:deficits.append(record(town,"shortage",good,-free,stamp))
  elif good in e.TRADE_GOODS and free>=2*e.TARGET[good]:
   # Give the existing surplus slot to a grain lead when it also helps
   # ration buyers. Archive only the grain fact, never a standing offer.
   if good=="grain" and market.stock>=e.BUNDLE["food"] and e.grain_ration_relief(c,town)>0:
    grain_lead=record(town,"surplus",good,stock,stamp)
   elif free-e.TARGET[good]>largest:
    largest=free-e.TARGET[good];surplus=record(town,"surplus",good,stock,stamp)
 deficits.sort_custom(func(a,b):return a.value>b.value if a.value!=b.value else a.subject<b.subject)
 for deficit in deficits.slice(0,2):
  deficit.value=mini(deficit.value,MAX_SHORTFALL)
  out.append(deficit)
 if not grain_lead.is_empty():out.append(grain_lead)
 elif not surplus.is_empty():out.append(surplus)
 return out
func depart(c,id: String) -> void:
 if not enabled or packets.has(id):return
 var wagon:Dictionary=c.world.caravans[id]
 if wagon.index!=0 or wagon.status not in ["transit","escort"]:return
 var route=c.world.route_data(wagon.route);var origin:String=route.path[0]
 observe(c,origin)
 packets[id]={"from":origin,"to":route.path[2],"departed":clock(c),"reports":boards[origin].values().map(func(e):return e.report.duplicate(true))}
func arrive(c,id: String) -> void:
 if not enabled or not packets.has(id) or c.world.caravans[id].status!="delivered":return
 var packet:Dictionary=packets[id];var book:Dictionary=boards[packet.to]
 var latest={};var current={}
 for report in packet.reports:latest[report.town]=maxi(latest.get(report.town,0),report.observed)
 for e in book.values():current[e.report.town]=maxi(current.get(e.report.town,-1),e.report.observed)
 for old in book.keys():
  var report:Dictionary=book[old].report
  if latest.has(report.town) and report.observed<latest[report.town]:book.erase(old)
 for report in packet.reports:
  # A late wagon cannot resurrect an old topic after a newer town account.
  if report.observed<latest[report.town] or report.observed<=current.get(report.town,-1):continue
  var id_key=key(report)
  if not book.has(id_key) or book[id_key].report.observed<report.observed:
   book[id_key]={"report":report.duplicate(true),"via":packet.from,"carrier":id,"received":clock(c)}
 trim(book,MAX_BOARD);packets.erase(id)
func lost(id: String) -> void:
 packets.erase(id)
func hear(c) -> int:
 if not enabled or not c.in_town() or c.phase!="camp" or c.over() or not c.encounter.is_empty():return -1
 var town:String=c.location;var now=clock(c);observe(c,town)
 var destinations=[town]
 for route in c.world.config.routes:
  if town==route.path[0] and route.path[2] not in destinations:destinations.append(route.path[2])
  if town==route.path[2] and route.path[0] not in destinations:destinations.append(route.path[0])
 var count=0;var latest={};var current={}
 for e in boards[town].values():latest[e.report.town]=maxi(latest.get(e.report.town,0),e.report.observed)
 for e in leads.values():current[e.report.town]=maxi(current.get(e.report.town,-1),e.report.observed)
 for id in leads.keys():
  var r:Dictionary=leads[id].report
  if (r.town==town and not boards[town].has(id)) or (latest.has(r.town) and r.observed<latest[r.town]):leads.erase(id)
 for id in boards[town]:
  var envelope:Dictionary=boards[town][id];var report:Dictionary=envelope.report
  if report.town not in destinations:destinations.append(report.town)
  if report.observed<latest[report.town] or (report.town!=town and report.observed<=current.get(report.town,-1)):continue
  if not leads.has(id) or leads[id].report!=report:
   var heard=envelope.duplicate(true);heard["heard"]=now;heard["at"]=town
   leads[id]=heard;count+=1
 for destination in destinations:
  # Locals describe routes from where the conversation actually happens.
  # Only places they mention are refreshed; reading notes never changes them.
  directions[destination]={"at":town,"heard":now}
 trim(leads,MAX_JOURNAL)
 return count
func sighted(c,id: String) -> bool:
 return c.overworld.places.has(id) and c.overworld.discovered(c.overworld.places[id])
func known_towns(c) -> Array:
 var result=directions.keys()
 for town in c.world.TOWNS:
  if sighted(c,town) and town not in result:result.append(town)
 return result
# Historical 0.42 simulation helper only. Never consumed by player-facing UI.
func area(c,town: String) -> Dictionary:
 if not directions.has(town):return {}
 var p:Vector2=c.overworld.places[town];var origin:Vector2=c.overworld.ORIGIN
 var cell=(p-origin)/128.0
 var center=origin+Vector2(floorf(cell.x)*128+64,floorf(cell.y)*128+64)
 return {"center":center,"radius":96.0}
func bearing(c,town: String) -> String:
 if not directions.has(town):return "No directions recorded"
 return navigation.summary(c,directions[town].at,town)
func route_notes(c,town: String) -> Array:
 if not directions.has(town):return ["No directions recorded."]
 return navigation.instructions(c,directions[town].at,town)
func rows(c) -> Array:
 return sorted_rows(leads)
func town_rows(c) -> Array:
 if not enabled or not c.in_town() or not c.overworld.at_site(c.location):return []
 # The board may still hold yesterday's edition (including in an older save).
 return sorted_rows(boards[c.location]).filter(func(e):return e.report.kind!="missing" or e.report.town!=c.location or not buyer_has_goods(c,c.location,e.report.subject))
func sorted_rows(book: Dictionary) -> Array:
 var out=book.values().duplicate(true)
 out.sort_custom(func(a,b):return a.report.observed>b.report.observed if a.report.observed!=b.report.observed else key(a.report)<key(b.report))
 return out
func title(c,report: Dictionary) -> String:
 match report.kind:
  "plenty":return "Prosperous market · %d rations in store" % report.value
  "roads":return "Trouble on the roads"
  "farm":return "Farm under attack or damaged"
  "missing":return "Shipment overdue: "+c.world.short_id(report.subject)
  "lean":return "Food running low · %d rations left" % report.value
  "shortage":return "Funded work short of %s%d %s" % ["at least " if report.value==MAX_SHORTFALL else "",report.value,c.economy.NAMES[report.subject].to_lower()]
  "surplus":
   if report.subject=="grain":return "Grain surplus reported · %d in store then · check local ration prices" % report.value
   return "%s in surplus · %d in store" % [c.economy.NAMES[report.subject],report.value]
 return "No pressing trouble reported"
func age(c,report: Dictionary) -> String:
 var hours=maxi(0,(clock(c)-report.observed)/60)
 return "%d hour%s old"%[hours,"" if hours==1 else "s"] if hours<24 else "%d day%s old"%[hours/24,"" if hours/24==1 else "s"]
func snapshot() -> Dictionary:
 return {"version":1,"boards":boards.duplicate(true),"packets":packets.duplicate(true),"leads":leads.duplicate(true),"directions":directions.duplicate(true),"pinned":pinned}
func valid_report(r,now: int,world) -> bool:
 if not r is Dictionary or r.size()!=5 or r.get("town") not in world.TOWNS or r.get("kind") not in KINDS or not r.get("subject") is String:return false
 if not r.get("observed") is int or r.observed<0 or r.observed>now or not r.get("value") is int:return false
 match r.kind:
  "missing":return world.caravans.has(r.subject) and world.route_data(world.caravans[r.subject].route).path[2]==r.town and r.value==1
  "shortage":return r.subject in Economy.STORED and r.value>0 and r.value<=MAX_SHORTFALL
  "surplus":return r.subject in Economy.TRADE_GOODS and r.value>=2*Economy.TARGET[r.subject]
  "lean":return r.subject=="food" and r.value>=0 and r.value<world.towns[r.town].demand*5
  "plenty":return r.subject=="food" and r.value>=world.towns[r.town].demand*12
  "roads":return r.subject=="" and r.value>0 and r.value<=world.SITES.size()
  "farm":return r.subject=="" and r.value==1
  "quiet":return r.subject=="" and r.value==0
 return false
func valid_envelope(e,at: String,now: int,world,journal: bool) -> bool:
 if not e is Dictionary or e.size()!=(6 if journal else 4) or not valid_report(e.get("report"),now,world):return false
 if not e.get("received") is int or e.received<e.report.observed or e.received>now or e.get("via") not in world.TOWNS or not e.get("carrier") is String:return false
 if e.carrier=="":
  if e.via!=at or e.report.town!=at or e.received!=e.report.observed:return false
 else:
  if not world.caravans.has(e.carrier):return false
  var wagon:Dictionary=world.caravans[e.carrier];var route=world.route_data(wagon.route)
  if wagon.status!="delivered" or route.path[0]!=e.via or route.path[2]!=at:return false
 if journal and (e.get("at")!=at or not e.get("heard") is int or e.heard<e.received or e.heard>now):return false
 return true
func restore(raw,world,now: int) -> bool:
 if not raw is Dictionary or raw.size()!=6 or raw.get("version")!=1:return false
 for field in ["boards","packets","leads","directions"]:
  if not raw.get(field) is Dictionary:return false
 if raw.boards.size()!=world.TOWNS.size() or raw.leads.size()>MAX_JOURNAL or raw.directions.size()>world.TOWNS.size():return false
 for town in world.TOWNS:
  if not raw.boards.get(town) is Dictionary or raw.boards[town].size()>MAX_BOARD:return false
  for id in raw.boards[town]:
   var e=raw.boards[town][id]
   if not valid_envelope(e,town,now,world,false) or id!=key(e.report):return false
 for id in raw.packets:
  var packet=raw.packets[id]
  if not world.caravans.has(id) or not packet is Dictionary or packet.size()!=4 or not packet.get("reports") is Array or packet.reports.size()>MAX_BOARD:return false
  var wagon:Dictionary=world.caravans[id];var route=world.route_data(wagon.route)
  if wagon.status not in ["transit","seized","escort"] or packet.get("from")!=route.path[0] or packet.get("to")!=route.path[2] or not packet.get("departed") is int or packet.departed<0 or packet.departed>now:return false
  var seen={}
  for report in packet.reports:
   if not valid_report(report,packet.departed,world) or seen.has(key(report)):return false
   seen[key(report)]=true
 for id in raw.leads:
  var e=raw.leads[id]
  if not e is Dictionary or e.get("at") not in world.TOWNS or not valid_envelope(e,e.at,now,world,true) or id!=key(e.report):return false
 for town in raw.directions:
  var d=raw.directions[town]
  if town not in world.TOWNS or not d is Dictionary or d.size()!=2 or d.get("at") not in world.TOWNS or not d.get("heard") is int or d.heard<0 or d.heard>now:return false
 for e in raw.leads.values():
  if not raw.directions.has(e.report.town):return false
 if not raw.get("pinned") is String or (raw.pinned!="" and not raw.directions.has(raw.pinned)):return false
 enabled=true;boards=raw.boards.duplicate(true);packets=raw.packets.duplicate(true);leads=raw.leads.duplicate(true);directions=raw.directions.duplicate(true);pinned=raw.pinned
 return true
