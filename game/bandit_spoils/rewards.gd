extends RefCounted
## Personal supplies only. Existing reserves, carried food and freight stay conserved.
const KEYS = ["crowns","food","tools","medicine"]
const CAPS = {"crowns":40,"food":6,"tools":3,"medicine":0}
static func empty() -> Dictionary:
 return {"crowns":0,"food":0,"tools":0,"medicine":0}
static func roll(seed_value: int, identity: Variant, salt: String, modulus: int) -> int:
 # Domain-separated stable digest, never combat/world RNG or encounter count.
 return int(JSON.stringify(["bandit_spoils_v1",seed_value,identity,salt]).sha256_text().substr(0,8).hex_to_int()) % modulus
static func human(u: Dictionary) -> bool:
 return u.side == 1 and u.name != "Empty rank" and u.get("faction","") != "undead" and u.get("undead_kind","") == ""
static func cohort(c) -> Dictionary:
 var out := {}
 if c.encounter.get("kind") == "dungeon":return out
 var engagement: Dictionary = c.recon.engagement
 for u: Dictionary in c.battle.units:
  if u.hp <= 0 or not human(u):continue
  var index: int = u.id-c.battle.player_slots()
  var party: String = c.encounter.get("id","") if c.encounter.get("kind") == "scout" else ""
  var member_index := index
  var identity := ""
  if not engagement.is_empty() and index < engagement.rows.size():
   var row: Dictionary = engagement.rows[index];party = row.party;member_index = row.index
   if party == "":identity = "resident/%s/%d/%d" % [engagement.site,engagement.generation,row.index]
  if party != "" and c.bandits.bands.has(party):
   var band: Dictionary = c.bandits.bands[party]
   if band.has("members") and member_index < band.members.size():identity = "member/"+band.members[member_index]
  if identity == "" and not c.active.is_empty():identity = "contract/%s/%d" % [c.active.id,index]
  if identity != "":out[u.id] = identity
 return out
static func dead(battle) -> Array:
 var out := []
 var started: Dictionary = battle.get_meta("bandit_spoils_cohort",{})
 for u: Dictionary in battle.units:
  if u.hp == 0 and human(u) and started.has(u.id):out.append(started[u.id])
 out.sort()
 return out
static func pockets(seed_value: int, members: Array) -> Dictionary:
 var out := empty()
 for identity: String in members:
  out.crowns += 2+roll(seed_value,identity,"coins",3)
  out.food += int(roll(seed_value,identity,"ration",4) == 0)
  out.tools += int(roll(seed_value,identity,"tools",5) == 0)
 for key: String in KEYS:out[key] = mini(out[key],CAPS[key])
 return out
static func stash(seed_value: int, camp_key: String) -> Dictionary:
 var out := empty()
 out.crowns = 8+roll(seed_value,camp_key,"camp_coins",5)
 out.food = 2+roll(seed_value,camp_key,"camp_food",3)
 out.tools = 1+roll(seed_value,camp_key,"camp_tools",2)
 return out
static func report() -> Dictionary:
 return {"version":1,"members":[],"camp":"","pockets":empty(),"camp_stash":empty(),"camp_stores":empty(),"carried_food":0,"total":empty(),"materials":{}}
static func build(seed_value: int, members: Array, camp_key: String, stores: Dictionary, carried_food: int) -> Dictionary:
 var out := report();out.members = members.duplicate();out.camp = camp_key;out.carried_food = carried_food
 out.pockets = pockets(seed_value,members)
 out.camp_stores.food = stores.get("food",0);out.camp_stores.crowns = stores.get("crowns",0)+stores.get("haul",0)
 out.materials = stores.get("materials",{}).duplicate()
 var recovered_food: int = out.camp_stores.food+carried_food
 var pocket_food: int = out.pockets.food
 out.pockets.food = maxi(0,pocket_food-recovered_food)
 if camp_key != "":
  out.camp_stash = stash(seed_value,camp_key)
  out.camp_stash.crowns = maxi(0,out.camp_stash.crowns-out.camp_stores.crowns)
  out.camp_stash.food = maxi(0,pocket_food+out.camp_stash.food-recovered_food)-out.pockets.food
 for key: String in KEYS:out.total[key] = out.pockets[key]+out.camp_stash[key]+out.camp_stores[key]+(carried_food if key == "food" else 0)
 return out
static func settle(c, members: Array, camp_key: String, recovered_food: int) -> Dictionary:
 members = members.filter(func(id):return id not in c.bandit_members)
 var stores: Dictionary = c.economy.camp_claims.get(camp_key,{})
 var out := build(c.seed_value,members,camp_key,stores,maxi(0,recovered_food-int(stores.get("food",0))))
 for key: String in KEYS:c.set(key,c.get(key)+out.pockets[key]+out.camp_stash[key])
 c.bandit_members.append_array(members);c.bandit_members.sort()
 if camp_key != "":c.bandit_stashes[camp_key] = out.camp_stash.duplicate()
 return out
static func amounts(raw: Variant) -> bool:
 if not raw is Dictionary or raw.size() != KEYS.size():return false
 for key: String in KEYS:
  if not raw.get(key) is int or raw[key] < 0:return false
 return true
static func member_exists(d: Dictionary, identity: String) -> bool:
 if identity.begins_with("member/"):
  var member := identity.trim_prefix("member/")
  var bandits = d.get("bandits",{})
  if not bandits is Dictionary or not bandits.get("bands") is Dictionary:return false
  for band in bandits.bands.values():
   if not band is Dictionary or not band.get("fallen") is Array:return false
   for fallen in band.fallen:
    if not fallen is String:return false
   if member in band.fallen:return true
  return false
 var parts := identity.split("/")
 if parts.size() == 4 and parts[0] == "resident" and parts[2].is_valid_int() and parts[3].is_valid_int():
  var generation := int(parts[2]);var index := int(parts[3])
  if identity != "resident/%s/%d/%d" % [parts[1],generation,index] or generation < 1 or index < 0:return false
  var recon = d.get("camp_recon",{})
  if not recon is Dictionary or not recon.get("garrisons") is Dictionary:return false
  var garrison = recon.garrisons.get("%s/%d" % [parts[1],generation])
  if not garrison is Dictionary or not garrison.get("health") is Array:return false
  var health: Array = garrison.health
  # Campaign.restore normalizes integral JSON floats before this extension.
  return index < health.size() and health[index] is int and health[index] == 0
 if parts.size() == 3 and parts[0] == "contract" and parts[2].is_valid_int():
  # Recon owns every camp defender in the hosted current-feature campaign.
  # A completed job is not proof that any fallback tactical slot existed/died.
  if d.has("camp_recon"):return false
  var used = d.get("used_jobs",[])
  if not used is Array:return false
  for job in used:
   if not job is String:return false
  var index := int(parts[2])
  return index >= 0 and index < 12 and str(index) == parts[2] and parts[1] in used
 return false
static func valid(d: Dictionary) -> bool:
 # Current schema only. No migration or relaxation of economy conservation.
 var state = d.get("bandit_spoils")
 if not state is Dictionary or state.size() != 3 or not state.get("version") is int or state.version != 1 or not state.get("camps") is Dictionary or not state.get("members") is Array:return false
 if not d.get("seed") is int or not d.get("world") is Dictionary or not d.world.get("camps") is Dictionary or not d.get("aftermath") is Dictionary:return false
 var seen := {}
 for identity in state.members:
  if not identity is String or seen.has(identity) or not member_exists(d,identity):return false
  seen[identity] = true
 var ordered: Array = state.members.duplicate();ordered.sort()
 if ordered != state.members:return false
 var economy = d.get("economy",{})
 if not economy is Dictionary or not economy.get("camp_claims",{}) is Dictionary:return false
 var claims: Dictionary = economy.get("camp_claims",{})
 # Current-schema claims and stash entitlements are earned in the same clear.
 # Validate the complete history before any latest-report outcome shortcut.
 if state.camps.size() != claims.size():return false
 for key in state.camps:
  if not key is String or not claims.get(key) is Dictionary or not amounts(state.camps[key]):return false
  var parts: PackedStringArray = key.split("/")
  if parts.size() != 2 or not parts[1].is_valid_int() or not d.world.camps.get(parts[0]) is Dictionary:return false
  var generation := int(parts[1]);var camp: Dictionary = d.world.camps[parts[0]]
  if key != "%s/%d" % [parts[0],generation] or generation < 1 or not camp.get("generation") is int or not camp.get("active") is bool or generation > camp.generation or (generation == camp.generation and camp.get("active") != false):return false
  var claim: Dictionary = claims[key]
  if not claim.get("food") is int or not claim.get("crowns") is int or not claim.get("materials",{}) is Dictionary:return false
  var target := stash(d.seed,key);var actual: Dictionary = state.camps[key]
  if not claim.get("haul",0) is int or claim.get("haul",0)<0 or (claim.has("haul") and (not d.get("raider_needs") is Dictionary or d.raider_needs.get("version")!=6)):return false
  if actual.crowns != maxi(0,target.crowns-claim.crowns-claim.get("haul",0)) or actual.tools != target.tools or actual.medicine != 0 or actual.food > target.food:return false
 if d.aftermath.is_empty():return state.camps.is_empty() and state.members.is_empty()
 var a: Dictionary = d.aftermath;var r = a.get("resource_spoils")
 if not r is Dictionary or r.size() != report().size() or not r.get("version") is int or r.version != 1:return false
 if not r.get("members") is Array or not r.get("camp") is String or not r.get("materials") is Dictionary or not r.get("carried_food") is int or r.carried_food < 0:return false
 for key in ["pockets","camp_stash","camp_stores","total"]:
  if not amounts(r.get(key)):return false
 if not a.get("result") is String or not a.get("retreat") is bool:return false
 if a.result != "victory" or a.retreat:return r == report()
 var ids := {}
 for identity in r.members:
  if not identity is String or not seen.has(identity) or ids.has(identity):return false
  ids[identity] = true
 var sorted: Array = r.members.duplicate();sorted.sort()
 if sorted != r.members:return false
 if r.camp != "" and (not state.camps.has(r.camp) or state.camps[r.camp] != r.camp_stash):return false
 var carried_limit := 0
 var supply = d.world.get("raider_supply",{})
 if not supply is Dictionary or not supply.get("packs",{}) is Dictionary:return false
 for pack in supply.get("packs",{}).values():
  if not pack is Dictionary or not pack.get("recovered") is int:return false
  carried_limit += pack.recovered
 if r.carried_food > carried_limit:return false
 return r == build(d.seed,r.members,r.camp,claims.get(r.camp,{}),r.carried_food)
