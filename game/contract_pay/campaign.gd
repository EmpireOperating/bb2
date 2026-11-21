extends "res://local_markets/campaign.gd"
## An earned receivable owns the original funded escrow, never an active camp.
var payment_pending: Dictionary = {}
func create_economy():
 var out = preload("res://contract_pay/economy.gd").new()
 out.industry = preload("res://local_markets/industry.gd").new()
 return out
func update_threat() -> void:
 # A separate camp encounter owns this field, not the unrelated signed job.
 # Reconciliation still performs stock expiry/obsolete-target release.
 if encounter.get("kind") == "camp" and not active.is_empty() and encounter.get("site") != active.get("target"): return
 super.update_threat()
func finish_job_payment(won: bool) -> int:
 if won and active.get("kind") == "clear" and economy.enabled:
  payment_pending = {"job":active.duplicate(true),"completed_day":day}
  return 0
 return super.finish_job_payment(won)
func finish_job_message(won: bool, reward: int) -> String:
 if won and not payment_pending.is_empty(): return active.title+": "+payment_direction()
 return super.finish_job_message(won,reward)
func payment_direction() -> String:
 if payment_pending.is_empty(): return ""
 var job: Dictionary = payment_pending.job
 return "Objective complete. Reward DUE: return to %s to collect %d crowns at the Contract Board." % [node(job.origin).name,job.pay]
func contract_direction() -> String:
 return super.contract_direction() if payment_pending.is_empty() else payment_direction()
func resolve_battle() -> bool:
 var earned_before: bool = not payment_pending.is_empty()
 if not super.resolve_battle(): return false
 if not earned_before and not payment_pending.is_empty(): aftermath.effect += " " + payment_direction()
 return true
func snapshot() -> Dictionary:
 var out: Dictionary = super.snapshot()
 out["contract_payment"] = {"version":1,"pending":payment_pending.duplicate(true)}
 return out
func restore(raw: Variant) -> bool:
 if not raw is Dictionary: return false
 var d: Dictionary = battle.normalize_json_numbers(raw)
 if not _payment_shape(d): return false
 if not super.restore(d): return false
 payment_pending = d.contract_payment.pending.duplicate(true)
 return true
func _payment_shape(d: Dictionary) -> bool:
 var state = d.get("contract_payment")
 if not state is Dictionary or state.size()!=2: return false
 if not state.get("version") is int or state.version!=1 or not state.get("pending") is Dictionary: return false
 var p: Dictionary = state.pending
 if p.is_empty(): return true
 if p.size()!=2 or not p.get("job") is Dictionary or not p.get("completed_day") is int: return false
 var j: Dictionary = p.job
 for key in ["id","kind","origin","target","client","title","brief","shipment","objective"]:
  if not j.get(key) is String: return false
 for key in ["pay","generation","deadline","threat"]:
  if not j.get(key) is int: return false
 if j.size()!=14 or j.kind!="clear" or j.shipment!="" or j.pay<1 or j.generation<1 or j.threat<1 or j.threat>3 or j.objective not in ["hold","eliminate","defend"]: return false
 if not d.get("day") is int or p.completed_day<1 or p.completed_day>d.day or j.deadline<p.completed_day or j.deadline>p.completed_day+8: return false
 if not d.get("active") is Dictionary or not d.active.is_empty() or not d.get("used_jobs") is Array or d.used_jobs.count(j.id)!=1: return false
 if not d.get("completed") is int or not d.get("wins") is int or d.completed<1 or d.wins<1: return false
 if not d.get("soldiers") is Array or not j.get("participants") is Array or j.participants.size()>12: return false
 var seen := {}
 for id in j.participants:
  if not id is int or id<0 or id>=d.soldiers.size() or seen.has(id): return false
  seen[id]=true
 if not d.get("world") is Dictionary or not d.world.get("towns") is Dictionary or not d.world.get("camps") is Dictionary: return false
 if not d.world.towns.get(j.origin) is Dictionary or not d.world.camps.get(j.target) is Dictionary: return false
 var town: Dictionary = d.world.towns[j.origin];var camp: Dictionary = d.world.camps[j.target]
 if not town.get("owner") is String or town.owner!=j.client or not camp.get("generation") is int or camp.generation<j.generation: return false
 if j.id!="clear_%s_%d" % [j.target,j.generation]: return false
 if not d.get("economy") is Dictionary or not d.economy.get("camp_claims") is Dictionary: return false
 # Earned current payments are always funded; the ancestor's legacy exception
 # must never turn a pending receivable into an unreserved payout.
 if d.economy.get("legacy_job")!="" or not d.economy.get("escrow") is Dictionary: return false
 var escrow: Dictionary = d.economy.escrow
 if escrow.size()!=3 or escrow.get("id")!=j.id or escrow.get("client")!=j.client or escrow.get("pay")!=j.pay: return false
 if not d.economy.camp_claims.get(j.target+"/"+str(j.generation)) is Dictionary: return false
 return true
