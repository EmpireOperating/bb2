extends RefCounted
## Private bounties, separate from simulated camp garrisons and food cargo.
## Fixed troops and weekly identities; neither party size nor gear sets difficulty.
const KINDS = ["road_hunt","road_arms","road_blockade"]
const TOWNS = ["ashwick","stonecross","dunmere"]
const JOBS = {
 "road_hunt":{"title":"Hunt the outlaw gang","label":"4 outlaws + 1 thug","grades":[1,1,1,1,0],"pay":440,"week":1,"brief":"Intercept a wanted gang near %s. Defeat all five for the bounty; this is separate from the camp garrison."},
 "road_arms":{"title":"Recover stolen arms","label":"5 outlaws + 1 raider","grades":[2,1,1,1,1,1],"pay":650,"week":1,"brief":"Recover a merchant's stolen arms near %s. Defeat all six; the shipment is returned to its owner and your company keeps battlefield salvage."},
 "road_blockade":{"title":"Break the mercenary blockade","label":"4 outlaws + 3 raiders + 1 veteran","grades":[3,2,2,1,2,1,1,1],"pay":980,"week":2,"brief":"Break a hired warband's blockade near %s. Defeat all eight for payment. This force is separate from the camp garrison."}
}
static func is_road(kind: String) -> bool:return kind in KINDS
static func target(region: Dictionary, town: String, week: int, kind: String) -> String:
 var towns: Array = region.world_config.towns.keys() if region.get("generator") == 3 else TOWNS
 var sites=[]
 for road in region.roads:
  if road[0]==town and road[1] not in sites:sites.append(road[1])
  elif road[1]==town and road[0] not in sites:sites.append(road[0])
 sites.sort()
 return "" if sites.is_empty() else sites[posmod(week+towns.find(town)+KINDS.find(kind),sites.size())]
static func identity(kind: String,town: String,week: int) -> String:return "%s_%s_%d"%[kind,town,week]
static func offers(c) -> Array:
 var out=[]
 if c.progression_version!=1 or not c.in_town() or c.over():return out
 var week=(c.day-1)/7
 for kind in KINDS:
  var d=JOBS[kind]
  if week<d.week or (d.grades.size()>6 and c.roster_version!=1):continue
  var id=identity(kind,c.location,week)
  if id in c.used_jobs:continue
  var site=target(c.region,c.location,week,kind)
  if site=="":continue
  var client=c.world.towns[c.location].owner
  var pay=ceili(float(d.pay)*(100.0+c.reputation[client]/2.0)/100.0)
  out.append({"id":id,"kind":kind,"origin":c.location,"target":site,"shipment":"","generation":week+1,"client":client,"title":d.title,"brief":d.brief%c.node(site).name,"pay":pay,"threat":KINDS.find(kind)+1,"objective":"eliminate","deadline":c.job_deadline(6)})
 return out
static func valid(job: Dictionary, saved: Dictionary, region: Dictionary, roster: bool, endless: bool = false) -> bool:
 var kind=job.kind
 if not is_road(kind) or saved.get("progression_version",0)!=1:return false
 var d=JOBS[kind];var week=job.generation-1
 if week<d.week or week>(saved.day-1)/7 or (not endless and week>4) or (d.grades.size()>6 and not roster):return false
 if job.id!=identity(kind,job.origin,week) or job.target!=target(region,job.origin,week,kind):return false
 if job.title!=d.title or job.threat!=KINDS.find(kind)+1 or job.objective!="eliminate" or job.shipment!="":return false
 # Reputation may change after signing; the signed quote stays fixed.
 var quoted=false
 for rep in range(-30,61):
  if job.pay==ceili(float(d.pay)*(100.0+rep/2.0)/100.0):quoted=true;break
 return quoted and job.deadline>=(week*7+7 if endless else mini(30,week*7+7)) and job.deadline<=(week*7+13 if endless else mini(30,week*7+13))
