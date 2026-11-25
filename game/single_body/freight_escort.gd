extends RefCounted
## Scope: the outbound Ravencross–Hollowfall cloth route. Owns no stock or treasury.
const KIND := "freight_escort"
const ORIGIN := "ashwick"
const TARGET := "dunmere"
const ROUTE := "material:cairn_road:out"
const PAY := 50
const TERM := 4 # From dispatch; departure is the next day.

static func matches(w: Dictionary, lot: Dictionary) -> bool:
 return w.get("route")==ROUTE and w.get("cargo")==0 and not w.get("recovered",true) and not lot.has("seizer") and lot.get("origin")==ORIGIN and lot.get("destination")==TARGET and lot.get("kind")=="cloth" and lot.get("amount") is int and lot.amount==4 and w.get("material")=={"kind":lot.kind,"amount":lot.amount}

static func quote(id: String, client: String, name: String, lot: Dictionary) -> Dictionary:
 return {"id":KIND+"_"+id,"kind":KIND,"shipment":id,"origin":ORIGIN,"target":TARGET,"client":client,
  "title":"Escort to "+name,"brief":"Follow this wagon to %s. Payment is reserved for an intact delivery with the company at the dock." % name,
  "objective":"escort","pay":PAY,"threat":1,"generation":lot.day,"deadline":lot.day+TERM,"manifest":lot.duplicate(true)}

static func valid_signed(d: Dictionary) -> bool:
 var j: Dictionary=d.active
 if not j.get("shipment") is String or not d.get("day") is int or not d.get("soldiers") is Array or not d.get("used_jobs") is Array:return false
 if not d.get("opening_rules") is bool or not d.opening_rules or not d.get("ending") is String or d.ending!="":return false
 var world = d.get("world")
 var economy = d.get("economy")
 var region = d.get("region")
 var payment = d.get("contract_payment")
 if not world is Dictionary or not economy is Dictionary or not region is Dictionary or not payment is Dictionary:return false
 if not payment.get("pending") is Dictionary or not payment.pending.is_empty() or economy.get("legacy_job")!="":return false
 if not world.get("caravans") is Dictionary or not world.get("towns") is Dictionary or not economy.get("freight") is Dictionary or not economy.freight.get("shipments") is Dictionary or not region.get("locations") is Array:return false
 var w = world.caravans.get(j.shipment)
 var lot = economy.freight.shipments.get(j.shipment)
 var origin = world.towns.get(ORIGIN)
 if not w is Dictionary or not lot is Dictionary or not origin is Dictionary or not origin.get("owner") is String:return false
 if not matches(w,lot) or lot.get("phase")!="shipping" or w.get("status") not in ["waiting","transit"] or not lot.get("day") is int or d.day<lot.day or d.day>lot.day+TERM:return false
 var name := ""
 for p in region.locations:
  if p is Dictionary and p.get("id")==TARGET and p.get("name") is String:name=p.name;break
 if name.is_empty():return false
 var expected := quote(j.shipment,origin.owner,name,lot)
 if j.size()!=expected.size()+1 or expected.id in d.used_jobs:return false
 for key: String in expected:
  if typeof(j.get(key))!=typeof(expected[key]) or j[key]!=expected[key]:return false
 if not j.get("participants") is Array or j.participants.is_empty() or j.participants.size()>12:return false
 var seen := {}
 for i in j.participants:
  if not i is int or i<0 or i>=d.soldiers.size() or seen.has(i):return false
  seen[i]=true
 return true # The inherited Economy restore still validates the exact native escrow.

static func signed_match(c, phase: String) -> bool:
 var job: Dictionary=c.active
 var id: String=job.shipment
 var w: Dictionary=c.world.caravans.get(id,{})
 var lot: Dictionary=c.economy.freight.state.shipments.get(id,{})
 if not matches(w,lot) or lot.get("phase")!=phase:return false
 var original := lot.duplicate(); original.phase="shipping"
 return original==job.manifest and c.economy.legacy_job=="" and c.economy.escrow=={"id":job.id,"client":job.client,"pay":job.pay}

static func receipt_valid(c, id: String) -> bool:
 var w: Dictionary=c.world.caravans.get(id,{})
 var lot: Dictionary=c.economy.freight.state.shipments.get(id,{})
 return matches(w,lot) and w.status=="delivered" and w.index==2 and w.delivered_day>=lot.day and w.delivered_day<=c.day and lot.phase=="delivered" and c.used_jobs.count(KIND+"_"+id)==1
