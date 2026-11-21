extends "res://local_markets/session.gd"
func _new_campaign():
 return preload("res://contract_pay/campaign.gd").new()
func contract_accept_reason(id: String) -> String:
 if not campaign.payment_pending.is_empty(): return "Collect the earned payment at the issuing town first."
 return super.contract_accept_reason(id)
func payment_collect_reason(quote: Dictionary) -> String:
 var c = campaign
 if c.phase!="camp" or c.over() or c.alive_count()==0: return "A living company in CAMP is required."
 if not c.encounter.is_empty() or c.overworld.pending!="" or c.dungeons.active!="" or not c.exploration.task.is_empty() or c.traffic.pursuit!="": return "Resolve the pending contact or expedition first."
 if _validated_snapshot(c.snapshot())==null: return "Invalid current campaign; unchanged."
 if c.payment_pending.is_empty() or quote!=c.payment_pending: return "The displayed payment is no longer current."
 var origin: String = c.payment_pending.job.origin
 if c.location!=origin or not c.in_town() or not c.overworld.paused or not c.overworld.path.is_empty() or c.overworld.destination!="" or c.overworld.rest_left!=0 or c.overworld.position!=c.overworld.places[origin]: return "Physically arrive at the issuing town to collect payment."
 return ""
func collect_contract_payment(quote: Dictionary) -> bool:
 var reason := payment_collect_reason(quote)
 if not reason.is_empty(): return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate==null: return _fail("Invalid current campaign; unchanged.")
 var job: Dictionary = candidate.payment_pending.job
 candidate.economy.release(candidate,true)
 candidate.crowns += job.pay
 candidate.payment_pending.clear()
 candidate.note("Collected %d contract crowns at %s for %s. Payment received." % [job.pay,candidate.node(job.origin).name,job.title])
 if _validated_snapshot(candidate.snapshot())==null: return _fail("Payment validation refused; unchanged.")
 campaign = candidate
 return _success()
