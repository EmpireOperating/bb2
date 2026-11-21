extends "res://contract_pay/campaign.gd"
const StaticRoles = preload("res://single_body/roles.gd")
const EncounterEquipment = preload("res://single_body/loot.gd")
# Absence in an 08 checkpoint means stay on its original generation policy,
# including the next redeploy. Do not infer age from encounters/day or rewrite it.
var human_kits_enabled:bool=true
var human_kit_wear:Dictionary={}
var equipment_claims:Dictionary={}
func starting_raider_rules() -> int:
 return 6
func generate_expanded_region(geography_seed: int) -> Dictionary:
 return ExpandedRegion.new().generate(geography_seed,true)
func deploy()->bool:
 if not super.deploy():return false
 battle.set_meta("encounter_equipment_key",EncounterEquipment.key_for(self))
 battle.set_meta("encounter_equipment_started",battle.units.filter(func(u):return u.side==1 and u.hp>0 and u.name!="Empty rank").map(func(u):return u.id))
 return true
func recover_enemy_equipment()->Array:
 # Replace corpse equipment salvage at its existing single settlement call.
 return EncounterEquipment.recover(self)
func resolve_battle()->bool:
 if not super.resolve_battle():return false
 for u:Dictionary in battle.units:
  if not u.has("human_kit_identity"):continue
  var key:String=u.human_kit_identity
  if battle.result=="victory" or u.hp<=0:human_kit_wear.erase(key)
  else:human_kit_wear[key]={"grade":u.human_kit_grade,"arms":u.arms.duplicate(true),"conditions":u.armor_parts.map(func(p):return p.condition)}
 return true
func snapshot()->Dictionary:
 var out:Dictionary=super.snapshot()
 if human_kits_enabled:out["human_kits"]={"version":1,"survivors":human_kit_wear.duplicate(true)}
 out["encounter_equipment"]={"version":1,"claims":equipment_claims.duplicate(true)}
 return out
func restore(raw:Variant)->bool:
 if not raw is Dictionary:return false
 var d:Dictionary=battle.normalize_json_numbers(raw)
 if d.has("human_kits") and not valid_human_kits(d):return false
 if not EncounterEquipment.valid(d) or not super.restore(d):return false
 human_kits_enabled=d.has("human_kits")
 human_kit_wear=d.human_kits.survivors.duplicate(true) if human_kits_enabled else {}
 equipment_claims=d.encounter_equipment.claims.duplicate(true)
 return true
func valid_human_kits(d:Dictionary)->bool:
 var state=d.human_kits
 if not state is Dictionary or state.size()!=2 or not state.get("version") is int or state.version!=1 or not state.get("survivors") is Dictionary:return false
 if state.survivors.is_empty():return true
 if not d.get("seed") is int:return false
 var groups:Dictionary=StaticRoles.Kits.source_groups(d)
 for key:Variant in state.survivors:
  if not key is String or not groups.has(key):return false
  if not StaticRoles.Kits.valid_wear(state.survivors[key],d.seed,key,StaticRoles.role_for(d.seed,key),groups[key],catalog):return false
 return true
func configure_enemy_unit(unit: Dictionary) -> void:
 StaticRoles.install(self,unit)
 super.configure_enemy_unit(unit)
