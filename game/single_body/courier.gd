extends RefCounted
## One letter route; the signed job itself represents custody. No cargo record.
const KIND := "courier"
const ORIGIN := "ashwick"
const TARGET := "stonecross"
const ID := "courier_ashwick_stonecross"
const PAY := 75
const DAYS := 3

static func offer(client: String, destination: String, signed_day: int) -> Dictionary:
 return {"id":ID,"kind":KIND,"origin":ORIGIN,"target":TARGET,"client":client,
  "title":"Courier to "+destination,"brief":"Carry a sealed packet to the council in %s. The agreed pay is reserved when you sign." % destination,
  "objective":"deliver","shipment":"","threat":0,"pay":PAY,"generation":signed_day,"deadline":signed_day+DAYS}

static func stopped_at(c, site: String) -> bool:
 if c.phase!="camp" or c.location!=site or not c.in_town() or not c.encounter.is_empty() or c.dungeons.active!="":return false
 var ow = c.overworld
 return ow.paused and ow.path.is_empty() and ow.destination=="" and ow.pending=="" and ow.rest_left==0 and ow.position==ow.places.get(site) and c.exploration.task.is_empty() and c.traffic.pursuit==""

static func valid_signed(d: Dictionary) -> bool:
 # Only current, funded CAMP can use the detached restore adapter. Unknown
 # types/jobs and pending clear receivables never take this branch.
 if not d.get("version") is int or d.version!=34 or not d.get("day") is int:return false
 if not d.get("phase") is String or d.phase!="camp" or d.get("battle")!=null or not d.get("opening_rules") is bool or not d.opening_rules:return false
 if not d.get("ending") is String or not d.ending.is_empty() or not d.get("used_jobs") is Array or ID in d.used_jobs:return false
 var economy = d.get("economy")
 var payment = d.get("contract_payment")
 if not economy is Dictionary or not economy.get("version") is int or economy.version!=3 or not economy.get("legacy_job") is String or not economy.legacy_job.is_empty():return false
 if not payment is Dictionary or not payment.get("pending") is Dictionary or not payment.pending.is_empty():return false
 var w = d.get("world")
 if not w is Dictionary or not w.get("towns") is Dictionary:return false
 var origin = w.towns.get(ORIGIN)
 if not origin is Dictionary or not origin.get("owner") is String or not w.towns.get(TARGET) is Dictionary:return false
 # Match the same generated place name as Campaign.node(), not mutable town stock.
 var region = d.get("region")
 if not region is Dictionary or not region.get("locations") is Array:return false
 var destination := ""
 for place in region.locations:
  if place is Dictionary and place.get("id") is String and place.id==TARGET and place.get("name") is String:
   destination=place.name
   break
 if destination.is_empty():return false
 var j: Dictionary=d.active
 if not j.get("generation") is int or j.generation<1 or j.generation>d.day or j.generation<d.day-DAYS:return false
 var expected := offer(origin.owner,destination,j.generation)
 if j.size()!=expected.size()+1:return false
 for key: String in expected:
  if typeof(j.get(key))!=typeof(expected[key]) or j[key]!=expected[key]:return false
 if not j.get("participants") is Array or j.participants.is_empty() or j.participants.size()>12 or not d.get("soldiers") is Array:return false
 var seen := {}
 for id in j.participants:
  if not id is int or id<0 or id>=d.soldiers.size() or seen.has(id):return false
  seen[id]=true
 # Do not reconstruct or waive escrow: the unchanged Economy validator must
 # see this exact job and validate the existing reserved/paid/refunded ledger.
 return true
