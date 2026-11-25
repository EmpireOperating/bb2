extends "res://single_body/campaign.gd"

const TAVERN_COST_PER_PERSON := 4
const TAVERN_CHANCE := 35
const Mood := preload("res://outdoor_fields/mood.gd")
var _tavern_round: Dictionary = {}
var _mood_people: Dictionary = {} # Sparse records by the campaign's append-only soldier ID.

func tavern_quote(site: String) -> Dictionary:
 var attendees: Array = soldiers.filter(func(s):return s.alive).map(func(s):return s.id)
 var price := TAVERN_COST_PER_PERSON*attendees.size()
 var reason := ""
 if phase!="camp" or over() or attendees.is_empty():reason="No living company in camp."
 elif not encounter.is_empty() or overworld.pending!="" or dungeons.active!="" or not exploration.task.is_empty() or traffic.pursuit!="":reason="Resolve the pending encounter first."
 elif site!=location or not in_town() or not overworld.paused or not overworld.path.is_empty() or overworld.destination!="" or overworld.rest_left!=0 or overworld.position!=overworld.places.get(site):reason="Arrive in town first."
 elif _tavern_round.get("day",0)==day:reason="One round per company day."
 elif crowns<price:reason="Not enough crowns."
 return {"site":site,"day":day,"encounters":encounters,"attendees":attendees,"price":price,"reason":reason}

func buy_tavern_round(quote: Dictionary) -> bool:
 if not quote.get("site") is String:return false
 var live := tavern_quote(quote.site)
 if quote!=live or not live.reason.is_empty():return false
 var raised: Array[int] = []
 for id: int in live.attendees:
  # Independent domain-separated draw per attendee; never touch any RNG cursor.
  var key := "tavern-round-v1/%d/%d/%d" % [seed_value,day,id]
  if key.sha256_text().left(8).hex_to_int()%100<TAVERN_CHANCE:
   raised.append(id)
   _change_mood(id,Mood.ALE,"ale")
 crowns-=live.price
 _tavern_round={"day":day,"raised":raised}
 return true

func tavern_result_today() -> Dictionary:
 # Older receipts are cooldown history, not evidence of persistent mood.
 return _tavern_round.duplicate(true) if _tavern_round.get("day",0)==day and _tavern_round.has("raised") and not _tavern_round.has("encounters") else {}

func campaign_mood(id: int) -> Dictionary:
 return Mood.describe(_mood_people.get(str(id),{}),news.clock(self))

func _change_mood(id: int, delta: int, reason: String) -> void:
 var key := str(id)
 var now: int = news.clock(self)
 var value := clampi(Mood.value_at(_mood_people.get(key,{}),now)+delta,Mood.MINIMUM,Mood.MAXIMUM)
 if value==Mood.NEUTRAL:_mood_people.erase(key)
 else:_mood_people[key]={"value":value,"minute":now,"reason":reason}

func _init() -> void:
 super()
 battle.mace_stun_rules = true # Also price/describe prospective equipment in camp.

func deploy() -> bool:
 if not super.deploy():return false
 # A detached deployment projects mood without spending it. The same job,
 # generation and encounter ordinal always draw the same roll for this person.
 if not _mood_people.is_empty():
  var job: Dictionary = battle_job()
  var minute: int = news.clock(self)
  for i in deployment.size():
   var id: int = deployment[i]
   if id<0:continue
   var u: Dictionary = battle.units[i]
   if not battle.living(u) or u.morale_state!=0:continue # Preserve Haunted's opening.
   var value := Mood.value_at(_mood_people.get(str(id),{}),minute)
   var chance := Mood.confidence(value)
   if value<=Mood.SOUR:u.morale_state=-1
   elif chance>0:
    var key := JSON.stringify(["campaign-mood-opening-v1",seed_value,encounters,job.kind,job.id,job.generation,id])
    if key.sha256_text().left(8).hex_to_int()%100<chance:u.morale_state=1
   u.morale=battle.morale_number(u.morale_state)
 var levels: Array[int] = []
 for id: int in deployment:
  levels.append(Progression.level(soldiers[id]) if id >= 0 else 0)
 battle.enable_tactical_morale(levels)
 battle.mace_stun_rules=local_fields
 return true

func resolve_battle() -> bool:
 if not super.resolve_battle():return false
 # The normal settlement owns the result, participant identities and deaths.
 # Never read the surviving unit's tactical morale back into the company.
 var reason := "retreat" if aftermath.retreat else "win" if aftermath.result=="victory" else "defeat" if aftermath.result=="defeat" else ""
 var delta := Mood.VICTORY if reason=="win" else Mood.RETREAT if reason=="retreat" and aftermath.fallen==0 else Mood.DEFEAT
 for row: Dictionary in aftermath.rows:
  if not soldiers[row.id].alive:_mood_people.erase(str(row.id))
  elif not reason.is_empty():_change_mood(row.id,delta,reason)
 return true
# No in-battle serialization. Absent on earlier CAMP saves (including pending
# encounters): retain that company's exact legacy geometry and checkpoint binding.
var local_fields := true
func random_company_enabled() -> bool:
 return true
func create_dungeons(definitions: Dictionary):
 var out = super.create_dungeons(definitions)
 out.intrinsic_undead_enabled = true
 return out
func snapshot() -> Dictionary:
 var out:Dictionary=super.snapshot()
 if not _tavern_round.is_empty():
  # Preserve canonical old optional bytes; the new save needs only the cooldown.
  out["tavern_round"]=_tavern_round.duplicate(true) if _tavern_round.has("encounters") else {"day":_tavern_round.day}
 if not _mood_people.is_empty():out["campaign_mood"]={"version":1,"people":_mood_people.duplicate(true)}
 if local_fields:out["outdoor_fields"]=1
 if armor_lab_enabled():out["armor_lab"]=1
 if forge_enabled():out["layer_forge"]=Forge.SCHEMA
 return out
func restore(raw:Variant) -> bool:
 if not raw is Dictionary:return false
 if raw.has("tavern_round") and not _valid_tavern_round(raw):return false
 if raw.has("campaign_mood") and not Mood.valid(raw):return false
 if raw.has("outdoor_fields") and (not raw.outdoor_fields is int or raw.outdoor_fields!=1):return false
 if forge_enabled():
  if not raw.get("layer_forge") is int or raw.layer_forge!=Forge.SCHEMA or not raw.has("outdoor_fields"):return false
 elif raw.has("layer_forge"):return false
 if armor_lab_enabled():
  if not raw.get("armor_lab") is int or raw.armor_lab!=1 or not raw.has("outdoor_fields"):return false
 elif raw.has("armor_lab"):return false
 if not super.restore(raw):return false
 _tavern_round=raw.get("tavern_round",{}).duplicate(true)
 _mood_people=raw.campaign_mood.people.duplicate(true) if raw.has("campaign_mood") else {}
 local_fields=raw.has("outdoor_fields")
 if phase=="camp":battle.mace_stun_rules=local_fields
 return true

func _valid_tavern_round(raw: Dictionary) -> bool:
 var state: Variant = raw.tavern_round
 if not state is Dictionary or not raw.get("day") is int:return false
 if not state.get("day") is int or state.day<1 or state.day>raw.day:return false
 if state.size()==1:return true
 if state.size()!=3 or not raw.get("encounters") is int or not raw.get("soldiers") is Array:return false
 if not state.get("encounters") is int or state.encounters<0 or state.encounters>raw.encounters:return false
 if not state.get("raised") is Array or state.raised.size()>20:return false
 var previous := -1
 for id: Variant in state.raised:
  if not id is int or id<=previous or id>=raw.soldiers.size():return false
  previous=id
 return true
