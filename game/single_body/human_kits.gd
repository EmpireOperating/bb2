extends RefCounted
## Campaign human kit policy 1. Only called at the final ordinary role seam.
const A = preload("res://src/arsenal.gd")
const Armor = preload("res://src/armor.gd")
const Designs = preload("res://painted_merge/acquisition.gd")
const Support = preload("res://support_equipment/policy.gd")
const GRADES = ["Bandit thug", "Outlaw", "Raider", "Veteran deserter"]
# Same grade, different supply: crossing thugs / woodland outlaws / deserters.
const WELL_SUPPLIED = {"ford":15,"forest":40,"ridge":65}
const WEAPON_PAIRS = {
 "raider":["hm_trial_v1:old24-medic_heavy","hm_trial_v1:additional_fighting_axe"],
 "archer":["short_bow","hm_trial_v1:old24-archer_weapon","hm_trial_v1:old24-archer_heavy"],
 "shieldbearer":["short_sword","hm_trial_v1:old24-gatewarden_blade"],
 "leader":["hm_trial_v1:old24-duelist_weapon","hm_trial_v1:old24-duelist_heavy"],
 "pikeman":["pike","hm_trial_v1:old24-polearm_weapon","hm_trial_v1:old24-ward_spear"],
 # One active two-handed sword design. Vary its protection, not its action family.
 "two_hander":["hm_trial_v1:twohand_sword","hm_trial_v1:twohand_sword"]}

static func group_for(c,u:Dictionary) -> String:
 var job:Dictionary = c.battle_job()
 if c.recon.engagement.is_empty() and job.kind!="scout":return ""
 var party:String = job.id if job.kind=="scout" else ""
 if not c.recon.engagement.is_empty():
  party=c.recon.engagement.rows[u.id-c.battle.player_slots()].party
 if not party.is_empty():
  var lineage:String=c.bandits.bands[party].get("lineage",party)
  return c.world.camp_role(c.overworld.scouts[lineage].site)
 return c.battle_site()

static func roll(seed_value:int, key:String, salt:String, size:int) -> int:
 return JSON.stringify(["ashen-human-kits-v1",seed_value,key,salt]).sha256_text().left(8).hex_to_int()%size

static func has_salvaged_helm(seed_value:int,key:String) -> bool:
 var bits:=key.split("/")
 # A camp and its scouts share one ticket keyed to source generation. Members
 # keep their founding lineage even if they later move to a different camp.
 if bits.size()==4 and bits[0]=="resident" and bits[3]=="0":
  return roll(seed_value,bits[1]+"_"+bits[2],"salvaged helm",16)==0
 if bits.size()==3 and bits[0]=="member" and bits[2]=="m1":
  return roll(seed_value,bits[1],"salvaged helm",16)==1
 return false

static func recipe(seed_value:int, key:String, role:String, group:String, grade:int, catalog:Dictionary) -> Dictionary:
 var supply:int = WELL_SUPPLIED[group]
 # A single weighted outfit choice correlates weapon issue, shield and protection.
 var issued:bool = roll(seed_value,key,"issue",100)<clampi(supply+grade*9,5,90)
 var weapons:Array = WEAPON_PAIRS[role]
 var weapon:String = weapons[mini(weapons.size()-1,(2 if grade>=2 else 1) if issued else 0)]
 var shield:String = (Designs.SHIELDS.shield if issued else Designs.SHIELDS.buckler) if role=="shieldbearer" else ""
 var defs:Dictionary = {"weapon":weapon,"shield":shield,"carry1":"","ammo":""}
 if role=="archer":
  defs.carry1="hm_trial_v1:old24-medic_weapon"
  # A distinct supply draw: light weapons circulate; heavy stocks are issued to better supplied bands.
  if roll(seed_value,key,"stock",100)<(12 if group=="ford" else 24 if group=="forest" else 38):
   weapon="heavy_crossbow" if issued and grade>=2 else "crossbow"
   defs.weapon=weapon;defs.ammo="bolts"
  else:defs.ammo=(["bodkin_quiver","deep_quiver"][roll(seed_value,key,"quiver",2)] if issued and grade>=1 else "arrows")
 var armor_grade:int = maxi(0,grade-(0 if issued else 1))
 var head:String = Designs.HEADS[armor_grade] if issued or grade>0 else ""
 # Only the first persistent member of a modest source band can own its prize.
 # Never promote its grade or whole outfit. No exceptional/special item roll.
 if grade<=1 and has_salvaged_helm(seed_value,key):head=Designs.SKULLCAP
 var token:String="enemy_kit/"+key+"/"
 var arms:Dictionary=A.empty_arms()
 for slot:String in defs:
  var id:String=defs[slot]
  if id!="":arms[slot]={"id":token+slot,"definition":id,"condition":int(catalog[id].durability),"loaded":false}
 var percent:int=(65+roll(seed_value,key,"wear",26)) if grade<2 else (85+roll(seed_value,key,"wear",16))
 var unit:Dictionary={"weapon":weapon,"armor_parts":[]}
 for id:String in [Designs.BODIES[armor_grade],head]:
  if id.is_empty():continue
  var d:Dictionary=catalog[id]
  unit.armor_parts.append({"item":token+d.group,"definition":id,"group":d.group,"layer":d.layer,"pool":"helmet" if d.group=="head" else "armor","condition":int(d.durability)*percent/100,"maximum":int(d.durability),"weight":int(d.weight),"hollow_slot":d.group})
 Support.append_enemy(unit,catalog,seed_value,["human-kit-v1",key],grade,percent,token+"support")
 return {"arms":arms,"parts":unit.armor_parts}

static func install(c,u:Dictionary,key:String,role:String,group:String,grade:int) -> void:
 var prior:Dictionary=c.human_kit_wear.get(key,{})
 if not prior.is_empty():grade=prior.grade
 var gear:Dictionary=recipe(c.seed_value,key,role,group,grade,c.catalog)
 if not prior.is_empty():
  gear.arms=prior.arms.duplicate(true)
  for i in gear.parts.size():gear.parts[i].condition=prior.conditions[i]
 u.human_kit_identity=key
 u.human_kit_grade=grade
 u.human_kit_group=group
 u.arms=gear.arms;u.armor_parts=gear.parts;u.support_acquisition_v1=true
 u.merge(Armor.totals(u.armor_parts),true)
 c.battle.sync_arms(u)

# Bind persisted wear to an actual historical garrison slot / personal lineage,
# never a tactical rank. Upstream restore still validates those world records.
static func source_groups(d:Dictionary) -> Dictionary:
 var out:Dictionary={}
 for parent in ["region","camp_recon","bandits","overworld"]:
  if not d.get(parent) is Dictionary:return {}
 if not d.region.get("world_config") is Dictionary or not d.region.world_config.get("camps") is Dictionary:return {}
 if not d.camp_recon.get("garrisons") is Dictionary or not d.bandits.get("bands") is Dictionary or not d.overworld.get("scouts") is Dictionary:return {}
 var camps:Dictionary=d.region.world_config.camps
 for key:Variant in d.camp_recon.garrisons:
  var g=d.camp_recon.garrisons[key]
  if not key is String or not g is Dictionary or not g.get("health") is Array:return {}
  var camp=camps.get(key.get_slice("/",0))
  if not camp is Dictionary or not WELL_SUPPLIED.has(camp.get("map")):return {}
  for i in g.health.size():out["resident/%s/%d"%[key,i]]=camp.map
 for id:Variant in d.bandits.bands:
  var band=d.bandits.bands[id]
  if not band is Dictionary or not band.get("members") is Array or not band.get("fallen") is Array or not band.get("departed",[]) is Array:return {}
  var scout=d.overworld.scouts.get(band.get("lineage",id))
  if not scout is Dictionary:return {}
  var camp=camps.get(scout.get("site"))
  if not camp is Dictionary or not WELL_SUPPLIED.has(camp.get("map")):return {}
  for member:Variant in band.members+band.fallen+band.get("departed",[]):
   if not member is String:return {}
   if member!="":out["member/"+member]=camp.map
 return out

static func valid_wear(raw:Variant,seed_value:int,key:String,role:String,group:String,catalog:Dictionary) -> bool:
 if not raw is Dictionary or raw.size()!=3 or not raw.get("grade") is int or raw.grade<0 or raw.grade>3:return false
 if raw.grade not in {"ford":[0,1],"forest":[1,2],"ridge":[1,2,3]}[group]:return false
 if not raw.get("conditions") is Array or not A.valid_arms(raw.get("arms"),catalog):return false
 var initial:Dictionary=recipe(seed_value,key,role,group,raw.grade,catalog)
 if raw.arms.size()!=initial.arms.size() or raw.conditions.size()!=initial.parts.size():return false
 for i in initial.parts.size():
  var hp=raw.conditions[i]
  if not hp is int or hp<0 or hp>initial.parts[i].condition:return false
 # Combat may move bow and backup between legal slots, or exhaust an ammo stack.
 # No new item, upgraded definition, impossible loaded flag or repaired durability on restore.
 var originals:Dictionary={}
 for item:Dictionary in initial.arms.values():
  if not item.is_empty():originals[item.id]=item
 for item:Dictionary in raw.arms.values():
  if item.is_empty():continue
  var source:Dictionary=originals.get(item.id,{})
  if source.is_empty() or item.size()!=4 or source.definition!=item.definition or (item.loaded and A.family(item.definition)!="crossbow") or item.condition>source.condition:return false
  originals.erase(item.id)
 return originals.is_empty()
