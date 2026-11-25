extends "res://contract_pay/campaign.gd"
const StaticRoles = preload("res://single_body/roles.gd")
const EncounterEquipment = preload("res://single_body/loot.gd")
const Courier = preload("res://single_body/courier.gd")
const FreightEscort = preload("res://single_body/freight_escort.gd")
var _escort_receipt := "" # A notice marker only; the original manifest owns stock.
var _restoring_courier: Dictionary = {} # Only while the inherited restore is on the stack.
# Absence in an 08 checkpoint means stay on its original generation policy,
# including the next redeploy. Do not infer age from encounters/day or rewrite it.
# A constructor default is only for fresh authority; validated detached copies
# replace it with the checkpoint's edition before any deployment.
var human_kit_edition:int=StaticRoles.Kits.initial_edition(Forge.enabled())
var human_kits_enabled:bool:
 get:return human_kit_edition>0
var human_kit_wear:Dictionary={}
var equipment_claims:Dictionary={}
func starting_raider_rules() -> int:
 return 6
func generate_expanded_region(geography_seed: int) -> Dictionary:
 return ExpandedRegion.new().generate(geography_seed,true)
func pays_contracts_on_arrival() -> bool:
 return true
func payment_direction() -> String:
 if payment_pending.is_empty():return ""
 var job: Dictionary = payment_pending.job
 return "Objective complete. Reward DUE: return to %s for automatic payment of %d crowns." % [node(job.origin).name,job.pay]
func deploy()->bool:
 if not super.deploy():return false
 battle.set_meta("encounter_equipment_key",EncounterEquipment.key_for(self))
 battle.set_meta("encounter_equipment_started",battle.units.filter(func(u):return u.side==1 and u.hp>0 and u.name!="Empty rank").map(func(u):return u.id))
 return true
func recover_enemy_equipment()->Array:
 # Replace corpse equipment salvage at its existing single settlement call.
 return EncounterEquipment.recover(self)
func resolve_battle()->bool:
 var worn_assemblies: Array[String] = []
 if (armor_lab_enabled() or forge_enabled()) and phase == "battle" and battle.result == "victory":
  for person: Dictionary in soldiers:
   if person.alive: worn_assemblies.append_array([person.gear.body,person.gear.head])
 if not super.resolve_battle():return false
 # The core win preserves fallen allies' gear. Release the physical layers
 # from their retired containers so they are reachable in the Lab stash.
 for kit: String in worn_assemblies:
  if items.has(kit) and owner(kit) == -1:
   items.erase(kit)
   recovery.stored.erase(kit)
 for u:Dictionary in battle.units:
  if not u.has("human_kit_identity"):continue
  var key:String=u.human_kit_identity
  if battle.result=="victory" or u.hp<=0:human_kit_wear.erase(key)
  else:human_kit_wear[key]={"grade":u.human_kit_grade,"arms":u.arms.duplicate(true),"conditions":u.armor_parts.map(func(p):return p.condition)}
 return true
func snapshot()->Dictionary:
 var out:Dictionary=super.snapshot()
 if human_kit_edition>0:out["human_kits"]={"version":human_kit_edition,"survivors":human_kit_wear.duplicate(true)}
 out["encounter_equipment"]={"version":1,"claims":equipment_claims.duplicate(true)}
 if _escort_receipt!="":out["freight_escort_receipt"]=_escort_receipt
 if traffic.follow_wagon!="":out["freight_escort_follow"]=traffic.follow_wagon
 return out
func restore(raw:Variant)->bool:
 if not raw is Dictionary:return false
 var d:Dictionary=battle.normalize_json_numbers(raw)
 var edition:int=StaticRoles.Kits.checkpoint_edition(d,forge_enabled())
 if edition<0 or (edition>0 and not valid_human_kits(d,edition)):return false
 if not EncounterEquipment.valid(d,forge_enabled(),edition):return false
 var courier: Dictionary = {}
 var escort: Dictionary = {}
 var receipt = d.get("freight_escort_receipt","")
 var follow = d.get("freight_escort_follow","")
 if not receipt is String or not follow is String or ((receipt!="" or follow!="") and not freight_escort_enabled()):return false
 if d.get("active") is Dictionary and d.active.get("kind") is String and d.active.kind==Courier.KIND:
  if not courier_enabled() or not Courier.valid_signed(d):return false
  courier=d.active
  # The inherited active-job validator is camp-only. All unrelated stock
  # validators still run; give Economy the exact signed job for its escrow
  # check. Never publish this transient projection or alter the input snapshot.
  d.active={}
  _restoring_courier=courier
 elif d.get("active") is Dictionary and d.active.get("kind")==FreightEscort.KIND:
  if not freight_escort_enabled() or receipt!="" or not FreightEscort.valid_signed(d):return false
  escort=d.active
  d.active={}
  _restoring_courier=escort # Reuse the same one-shot native escrow restore context.
 var restored := super.restore(d)
 _restoring_courier={}
 if not restored:return false
 if not courier.is_empty():active=courier
 if not escort.is_empty():active=escort
 if receipt!="" and not FreightEscort.receipt_valid(self,receipt):return false
 if follow!="":
  if not _allows_escort_follow(follow) or not overworld.path.is_empty() or overworld.destination!=FreightEscort.TARGET or traffic.pursuit!="" or not exploration.task.is_empty():return false
 traffic.follow_wagon=follow
 _escort_receipt=receipt
 human_kit_edition=edition
 human_kit_wear=d.human_kits.survivors.duplicate(true) if edition>0 else {}
 equipment_claims=d.encounter_equipment.claims.duplicate(true)
 return true
func valid_human_kits(d:Dictionary,edition:int)->bool:
 var state:Dictionary=d.human_kits
 if state.survivors.is_empty():return true
 if not d.get("seed") is int:return false
 var groups:Dictionary=StaticRoles.Kits.source_groups(d)
 for key:Variant in state.survivors:
  if not key is String or not groups.has(key):return false
  if not StaticRoles.Kits.valid_wear(state.survivors[key],d.seed,key,StaticRoles.role_for(d.seed,key),groups[key],catalog,forge_enabled(),edition):return false
 return true
func configure_enemy_unit(unit: Dictionary) -> void:
 StaticRoles.install(self,unit)
 if armor_lab_enabled() and not unit.armor_parts.is_empty():
  # Older issued human kit recipes use the armor subtotal for their single
  # body item. Keep identity/wear, but put Lab base garments in the real base
  # damage pool so scalar loss and physical wear cannot diverge.
  for part: Dictionary in unit.armor_parts:
   if part.group == "body" and part.layer == "base": part.pool = "padding"
  unit.merge(Armor.totals(unit.armor_parts),true)
 super.configure_enemy_unit(unit)

func courier_enabled() -> bool:
 return forge_enabled()

func create_economy():
 var out = super.create_economy()
 if _restoring_courier:out._courier_restore_context=_restoring_courier
 return out

func offers() -> Array:
 var jobs := super.offers()
 var escort := _freight_escort_offer()
 if not escort.is_empty():
  jobs=jobs.filter(func(j):return j.kind!="escort" or j.shipment!=escort.shipment)
  jobs.append(escort)
 if not courier_enabled() or not opening_rules or not economy.enabled or over() or not active.is_empty() or not payment_pending.is_empty():return jobs
 if not economy.escrow.is_empty() or economy.legacy_job!="" or Courier.ID in used_jobs or active_ids().is_empty():return jobs
 if not Courier.stopped_at(self,Courier.ORIGIN):return jobs
 var client: String=world.towns[Courier.ORIGIN].owner
 if world.factions[client].treasury<Courier.PAY:return jobs
 # Leave the clear rows in order and ahead of this offer. In the opening
 # region it fits on their page, ahead of any unhosted legacy escort rows.
 var index := 0
 while index<jobs.size() and jobs[index].kind=="clear":index+=1
 jobs.insert(index,Courier.offer(client,node(Courier.TARGET).name,day))
 return jobs

func update_threat() -> void:
 if active.get("kind")==FreightEscort.KIND:return
 if active.get("kind")==Courier.KIND:return # This job has no camp or combat threat.
 super.update_threat()

func finish_job(won: bool) -> int:
 if active.get("kind")==FreightEscort.KIND:
  if won:return 0 # Only the live same-tick dock can pay.
  traffic.cancel_follow(overworld)
 if won and active.get("kind")==Courier.KIND:return 0 # Only the named arrival edge can succeed.
 return super.finish_job(won)

func tick_overworld(seconds: float) -> bool:
 var arriving: bool=active.get("kind")==Courier.KIND and overworld.destination==Courier.TARGET and not overworld.paused and not overworld.path.is_empty()
 var from: Vector2=overworld.position
 var changed := super.tick_overworld(seconds)
 if active.get("kind")==FreightEscort.KIND:
  var id: String=active.shipment
  var w: Dictionary=world.caravans.get(id,{})
  if w.get("status")=="delivered":
   var at_dock: bool=traffic.follow_wagon==id and traffic.follow_dock and Courier.stopped_at(self,FreightEscort.TARGET) and traffic.wagons[id].position==overworld.position
   if at_dock and w.index==2 and w.delivered_day==day and day<=active.deadline and not over() and FreightEscort.signed_match(self,"delivered"):
    _escort_receipt=id
    traffic.cancel_follow(overworld)
    super.finish_job(true) # The native release and settlement, with no second unload.
   else:finish_job(false)
   changed=true
  elif not FreightEscort.signed_match(self,"shipping") or w.get("status") not in ["waiting","transit"]:
   finish_job(false)
   changed=true
  elif not encounter.is_empty() or overworld.pending!="":traffic.cancel_follow(overworld)
 if arriving and changed and from!=overworld.position and active.get("kind")==Courier.KIND and not over() and day<=active.deadline and Courier.stopped_at(self,Courier.TARGET):
  if economy.enabled and economy.legacy_job=="" and economy.escrow=={"id":active.id,"client":active.client,"pay":active.pay}:
   super.finish_job(true) # Stock release, purse, journal, participation and one-shot used_jobs.
 return changed

func job_danger(job: Dictionary) -> String:
 if job.get("kind")==FreightEscort.KIND:return "%s · 4 cloth · bandits may intercept" % world.short_id(job.shipment)
 if job.get("kind")==Courier.KIND:return "No battle required · ordinary road danger still applies"
 return super.job_danger(job)

func contract_direction() -> String:
 if active.get("kind")==FreightEscort.KIND:return "Follow %s to %s by day %d." % [world.short_id(active.shipment),node(active.target).name,active.deadline]
 if active.get("kind")==Courier.KIND:return "Deliver the sealed packet to %s by day %d." % [node(active.target).name,active.deadline]
 return super.contract_direction()

func finish_job_message(won: bool, reward: int) -> String:
 if not won and active.get("kind")==FreightEscort.KIND:return "%s escort closed unpaid. 0 crowns earned." % world.short_id(active.shipment)
 if won and active.get("kind")==FreightEscort.KIND:return "%s delivered intact at %s. Received %d crowns." % [world.short_id(active.shipment),node(active.target).name,reward]
 if won and active.get("kind")==Courier.KIND:return "Delivered the sealed packet to %s. Received %d crowns." % [node(active.target).name,reward]
 return super.finish_job_message(won,reward)

func freight_escort_enabled() -> bool:
 return forge_enabled()

func _freight_escort_offer() -> Dictionary:
 if not freight_escort_enabled() or not opening_rules or not economy.enabled or not traffic.enabled or over() or not active.is_empty() or not payment_pending.is_empty() or _escort_receipt!="":return {}
 if not economy.escrow.is_empty() or economy.legacy_job!="" or active_ids().is_empty() or not Courier.stopped_at(self,FreightEscort.ORIGIN):return {}
 var client: String=world.towns[FreightEscort.ORIGIN].owner
 if world.factions[client].treasury<FreightEscort.PAY or reputation[client]<=-12 or world.protected_road("ridge"):return {}
 for id: String in world.caravans:
  var w: Dictionary=world.caravans[id]
  var lot: Dictionary=economy.freight.state.shipments.get(id,{})
  if w.status!="waiting" or w.index!=0 or w.guarded or w.depart_day!=day+1 or not FreightEscort.matches(w,lot) or lot.phase!="shipping" or lot.day!=day:continue
  if traffic.wagons.get(id,{}).get("position")!=overworld.position:continue
  var job := FreightEscort.quote(id,client,node(FreightEscort.TARGET).name,lot)
  if job.id not in used_jobs:return job
 return {}

func _allows_escort_follow(id: String) -> bool:
 if not freight_escort_enabled() or id=="" or active.get("kind")!=FreightEscort.KIND or active.shipment!=id or day>active.deadline:return false
 if phase!="camp" or over() or not encounter.is_empty() or overworld.pending!="" or overworld.rest_left!=0 or dungeons.active!="" or active_ids().is_empty():return false
 var v: Dictionary=traffic.wagons.get(id,{})
 return not v.is_empty() and v.status in ["waiting","transit"] and not v.carried and v.position.distance_to(overworld.position)<=overworld.sight() and FreightEscort.signed_match(self,"shipping")

func can_follow_freight(id: String) -> bool:
 return _allows_escort_follow(id) and traffic.wagons[id].remaining==0

func begin_freight_follow(id: String) -> bool:
 if not can_follow_freight(id) or not begin_travel(traffic.wagons[id].position):return false
 traffic.follow_wagon=id
 overworld.path.clear()
 overworld.destination=FreightEscort.TARGET
 return true

func begin_travel(target: Vector2, site: String = "") -> bool:
 if not super.begin_travel(target,site):return false
 traffic.follow_wagon="" # The successful new normal order already owns destination.
 return true

func begin_rest() -> bool:
 if not super.begin_rest():return false
 traffic.follow_wagon=""
 return true

func fresh_freight_delivery(site: String) -> String:
 if site!=FreightEscort.TARGET or location!=site or _escort_receipt=="":return ""
 var w: Dictionary=world.caravans[_escort_receipt]
 if day-w.delivered_day>=3:return ""
 return "Fresh delivery · %s from %s · 4 cloth · day %d" % [world.short_id(_escort_receipt),node(FreightEscort.ORIGIN).name,w.delivered_day]
