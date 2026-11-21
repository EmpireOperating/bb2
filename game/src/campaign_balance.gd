extends RefCounted
## Campaign progression version 1. No player-level or party-equipment scaling.
const PRICES = {"short_mail":160,"mail":260,"long_mail":380,"heavy_mail":520,"leather":80,"brigandine":300,"scale_vest":260,"breastplate":420,"patched_plate":120,"cap":60,"nasal":120,"kettle":110,"bascinet":210,"visor":65,"cheek_guards":40,"mail_coif":60,"mail_curtain":40,"shoulders":70,"collar":45}
static func grade(site: String, strength: int, index: int, kind: String) -> int:
 if site=="ford":return 1 if strength==3 and index==0 and kind!="scout" else 0
 if site=="forest":return 2 if strength==3 and index==0 and kind!="scout" else 1
 if kind=="scout":return 2 if index==0 else 1
 return 3 if index==0 else 2 if strength==3 or index<3 else 1
static func count(site: String, strength: int, kind: String) -> int:
 if kind=="scout":return 2 if strength<3 or site=="ford" else 3
 if kind=="recover":return 3 if strength<3 else 4
 return mini(4,2+strength) if site=="ford" else mini(5,2+strength) if site=="forest" else mini(6,3+strength)
static func label(site: String, strength: int, kind: String) -> String:
 if site=="ford":return "Thugs + leader" if strength==3 and kind!="scout" else "Thugs"
 if site=="forest":return "Outlaws + raider" if strength==3 and kind!="scout" else "Outlaws"
 return "Raider scouts" if kind=="scout" else "Veteran deserters"
static func equip(c, u: Dictionary, threat: int, source_index: int = -1, source_kind: String = "", source_role: String = "") -> void:
 var logical_id=source_index+6 if source_index >= 0 else u.id-c.battle.player_slots()+6
 var n=posmod(c.seed_value+c.encounters*17+logical_id*29,2147483646)
 var kind=c.battle_job().get("kind","clear") if source_kind == "" else source_kind
 var role=c.battle_site() if source_role == "" else source_role
 var g=c.RoadContracts.JOBS[kind].grades[logical_id-6] if c.RoadContracts.is_road(kind) else grade(role,threat,logical_id-6,kind)
 var weapons=[["club","hatchet","militia_spear","knife"],["shortsword","militia_spear","hatchet","club"],["sword","spear","axe","mace"],["sword","hammer","polearm","axe"]][g]
 var weapon=weapons[n%weapons.size()]
 # Current finite camps split residents and scouts: neither sub-roster reaches
 # historical index 4. The third resident of a supplied deserter camp is ranged.
 var finite_crossbow: bool = source_index==2 and c.recon.enabled and kind=="clear" and role=="ridge" and threat>=2
 if finite_crossbow:
  weapon="heavy_crossbow" if threat>=3 and n%3==0 else "crossbow"
 elif logical_id==10:
  weapon="shortbow" if g<2 else ("heavy_crossbow" if threat>=3 and n%3==0 else "crossbow") if role=="ridge" else "bow"
 if c.acquisition_policy() != null and c.acquisition_policy().has_method("human_weapon"):
  # The second forest resident exists at current strength 2; index 2 appears
  # only after food-funded growth. Keep the ridge's crossbow exception intact.
  var finite_bow: bool = source_index==1 and c.recon.enabled and kind=="clear" and role=="forest"
  weapon = c.acquisition_policy().human_weapon(g,n,weapon,finite_bow)
 u.title=["Bandit thug","Outlaw","Raider","Veteran deserter"][g]
 u.skill=[46,54,62,69][g]+n%5;u.defense=[0,4,9,14][g];u.ranged_defense=[0,2,4,6][g]
 u.hp=[45,50,57,65][g]+n%6;u.max_hp=u.hp;u.resolve=[30,38,46,55][g];u.stamina=95+g*5;u.initiative=100-g*3
 var arms=c.Arsenal.empty_arms()
 var definitions={"weapon":weapon,"shield":"","carry1":"","carry2":"","ammo":c.Arsenal.ammo_type(weapon)}
 if not weapon in c.Arsenal.TWO_HANDS and (g>=2 or n%3==0):definitions.shield="shield" if g>=2 else "round_shield" if g==1 else "buckler"
 if weapon in c.Arsenal.RANGED:definitions.carry1="knife" if g<2 else "dagger"
 if c.acquisition_policy() != null:
  definitions = c.acquisition_policy().arms(definitions)
  if c.acquisition_policy().has_method("human_ammo"): c.acquisition_policy().human_ammo(definitions,g,n)
 for slot in definitions:
  var definition:String=definitions[slot]
  if definition=="":continue
  arms[slot]={"id":"enemy_%d_%d_%s"%[c.encounters,u.id,slot],"definition":definition,"condition":int(c.catalog[definition].durability),"loaded":c.Arsenal.family(definition)=="crossbow"}
 u.arms=arms;c.battle.sync_arms(u)
 var outfit={"body":c.Armor.empty_parts("body"),"head":c.Armor.empty_parts("head")}
 outfit.body.base="tunic" if g==0 and n%2==0 else "light_quilt" if g<=1 else "linen"
 if g==0:
  outfit.body.outer="jerkin" if n%4==0 else "";outfit.head.padding="felt_cap" if n%3==0 else ""
 elif g==1:
  outfit.body.outer="jerkin" if n%2==0 else "leather";outfit.head.shell="simple_helm" if n%2==0 else "cap"
 elif g==2:
  outfit.body["mail" if n%2==0 else "outer"]="short_mail" if n%2==0 else "leather";outfit.head.shell="nasal" if n%3==0 else "cap"
 else:
  outfit.body.mail="mail";outfit.body.outer="brigandine";outfit.head.shell="bascinet";outfit.head.padding="arming_cap"
 outfit.body.cloth=["","sash","red_surcoat"][n%3]
 if c.acquisition_policy() != null: outfit = c.acquisition_policy().outfit(outfit,g,c.catalog)
 u.armor_parts=[]
 for group in outfit:
  for layer in outfit[group]:
   var definition:String=outfit[group][layer]
   if definition=="":continue
   var d:Dictionary=c.catalog[definition]
   u.armor_parts.append({"item":"enemy_%d_%d_%s_%s"%[c.encounters,u.id,group,layer],"definition":definition,"group":group,"layer":layer,"pool":"helmet" if group=="head" else "padding" if layer=="base" else "armor","condition":int(d.durability)*(65+n%26 if g<2 else 85+n%16)/100,"maximum":int(d.durability),"weight":int(d.weight)})
 var stats=c.Armor.totals(u.armor_parts)
 for key in stats:u[key]=stats[key]
