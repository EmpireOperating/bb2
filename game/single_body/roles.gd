extends RefCounted
## Final population seam, before effect bases/initiative. No RNG consumption.
const Kits = preload("res://single_body/human_kits.gd")
const IDS := ["raider","archer","shieldbearer","two_hander","pikeman","leader"]
const WEAPONS := {"raider":"hm_trial_v1:additional_fighting_axe","archer":"short_bow","shieldbearer":"sword","two_hander":"hm_trial_v1:twohand_sword","pikeman":"pike","leader":"sword"}
static func role_for(seed_value:int, identity:String) -> String:
 var index:int=JSON.stringify(["bb2-static-role-v1",seed_value,identity]).sha256_text().left(8).hex_to_int()%IDS.size()
 return IDS[index]
static func install(c, u: Dictionary) -> void:
 if u.side != 1 or u.name == "Empty rank" or u.get("faction","") == "undead" or not str(u.get("undead_kind","")).is_empty():return
 # Physical installation is creation-only. Refresh must preserve spent ammo,
 # broken shields, original grade/title and captured unmodified effect bases.
 if u.has("bandit_role"):return
 if c.encounter.get("kind")=="dungeon" or u.get("named",false) or u.get("boss",false) or u.get("unique",false):return
 var identities: Dictionary = c.ResourceSpoils.cohort(c)
 var identity: String = identities.get(u.id,"%s/%d/%d" % [c.battle_site(),c.encounter.get("generation",c.active.get("generation",1)),u.id-c.battle.player_slots()])
 var role:String = role_for(c.seed_value,identity)
 u["bandit_role"] = role
 u["bandit_grade"] = u.title
 u.title = "Bandit " + role.replace("_"," ") + " · " + str(u.title)
 if role == "leader":
  # Existing veteran archetype, not new abilities; preserve finite HP fraction.
  var fraction: float = float(u.hp)/maxi(1,int(u.max_hp))
  u.max_hp = maxi(int(u.max_hp),65);u.hp = maxi(1,roundi(u.max_hp*fraction)) if fraction>0 else 0
  u.skill = maxi(int(u.skill),69);u.defense = maxi(int(u.defense),14)
  u.resolve = maxi(int(u.resolve),55)
 if c.human_kits_enabled and (identity.begins_with("resident/") or identity.begins_with("member/")) and Kits.GRADES.has(u.bandit_grade):
  var group:String=Kits.group_for(c,u)
  if Kits.WELL_SUPPLIED.has(group):
   Kits.install(c,u,identity,role,group,Kits.GRADES.find(u.bandit_grade))
   if role=="archer":u.ranged_skill=u.skill
   return
 var weapon: String = WEAPONS[role]
 u.arms = c.Arsenal.empty_arms()
 var definitions := {"weapon":weapon,"shield":"hm_trial_v1:offhands-02-round-wooden-shield" if role == "shieldbearer" else "","ammo":c.Arsenal.ammo_type(weapon)}
 if role == "archer":definitions["carry1"]="knife"
 for slot: String in definitions:
  var definition: String = definitions[slot]
  if definition.is_empty():continue
  u.arms[slot] = {"id":"enemy_%d_%d_%s" % [c.encounters,u.id,slot],"definition":definition,"condition":int(c.catalog[definition].durability),"loaded":false}
 c.battle.sync_arms(u)
 if role == "archer":u.ranged_skill = u.skill
