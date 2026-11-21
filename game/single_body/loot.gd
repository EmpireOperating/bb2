extends RefCounted
## One ordinary claim per persistent encounter. Marked casualties supply physical gear.
## Real enemy ammunition remains conserved separately; Named awards stay upstream.
const Salvage = preload("res://single_body/kit_salvage.gd")
const POOL=["short_sword","cudgel","pike","hm_trial_v1:headwear-02-leather-cap","travel_leather","hm_trial_v1:offhands-02-round-wooden-shield","hm_trial_v1:footwear-03-wrapped-shoes","hm_trial_v1:gloves-01-linen-handwraps"]
static func roll(seed_value:int,key:String,salt:String,modulus:int)->int:
 return JSON.stringify(["bb2-encounter-equipment-v1",seed_value,key,salt]).sha256_text().left(8).hex_to_int()%modulus
static func definitions(seed_value:int,key:String)->Array:
 var out:Array=[]
 for index in 1+roll(seed_value,key,"count",2):out.append(POOL[roll(seed_value,key,"item/%d"%index,POOL.size())])
 return out
static func key_for(c)->String:
 if c.encounter.get("kind")=="dungeon":return JSON.stringify(["dungeon",c.dungeons.active,c.dungeons.floor_index,c.dungeons.room_index])
 if c.encounter.get("kind")=="scout":return JSON.stringify(["scout",c.encounter.id])
 if c.encounter.get("kind")=="camp":return JSON.stringify(["camp",c.encounter.site,int(c.encounter.generation)])
 if c.active.get("kind") in ["clear","legacy"]:return JSON.stringify(["camp",c.active.target,int(c.active.generation)])
 return JSON.stringify(["contract",c.active.get("id","")])
static func recover(c)->Array:
 var b=c.battle;var key:String=b.get_meta("encounter_equipment_key","")
 if b.result!="victory" or c.retreat or key.is_empty() or c.equipment_claims.has(key):return []
 var dead:=0
 var grades:Dictionary={};var pieces:Dictionary={}
 var started:Array=b.get_meta("encounter_equipment_started",[])
 for u:Dictionary in b.units:
  if u.id not in started or u.hp>0:continue
  dead+=1
  if c.human_kits_enabled and not str(u.get("human_kit_identity","")).is_empty():
   grades[u.human_kit_identity]=u.human_kit_grade
   pieces.merge(Salvage.pieces(u.human_kit_identity,u.arms,u.armor_parts,c.catalog))
  if not c.ammo_pending:
   for item:Dictionary in u.arms.values():
    if not item.is_empty():c.ammunition+=int(item.condition)*c.Arsenal.ammo_supply_cost(item.definition)
 if dead==0:return []
 var drops:Array=[];var loot:Array=[]
 if not grades.is_empty():
  var ids:Array=pieces.keys();ids.sort()
  for index in mini(ids.size(),1+roll(c.seed_value,key,"count",2)):
   var id:String=ids.pop_at(roll(c.seed_value,key,"physical/%d"%index,ids.size()))
   var row:Dictionary=pieces[id];var uid:String=c.add_item(row.definition,row.condition)
   row["item"]=uid
   if c.Arsenal.family(row.definition)=="crossbow":c.items[uid].loaded=row.loaded
   drops.append(row);loot.append({"source":"Encounter spoils","item":uid,"name":c.item_name(uid)})
  # Even if all gear broke, spend this encounter's claim (including its ammo).
  c.equipment_claims[key]={"casualties":dead,"kit_grades":grades,"drops":drops}
  return loot
 var index:=0
 for definition:String in definitions(c.seed_value,key):
  var uid:String=c.add_item(definition)
  var maximum:int=c.item_def(uid).durability
  c.items[uid].condition=maximum*(55+roll(c.seed_value,key,"condition/%d"%index,31))/100
  drops.append({"item":uid,"definition":definition})
  loot.append({"source":"Encounter spoils","item":uid,"name":c.item_name(uid)})
  index+=1
 c.equipment_claims[key]={"casualties":dead,"drops":drops}
 return loot
static func valid_key(key:String)->bool:
 var parts:Variant=JSON.parse_string(key)
 if not parts is Array or parts.is_empty() or not parts[0] is String:return false
 if parts[0]=="camp":return parts.size()==3 and parts[1] is String and not parts[1].is_empty() and (parts[2] is int or parts[2] is float) and float(parts[2])==floor(float(parts[2])) and parts[2]>=1
 if parts[0]=="dungeon":return parts.size()==4 and parts[1] is String and not parts[1].is_empty() and (parts[2] is int or parts[2] is float) and (parts[3] is int or parts[3] is float) and parts[2]>=0 and parts[3]>=0 and float(parts[2])==floor(float(parts[2])) and float(parts[3])==floor(float(parts[3]))
 return parts[0] in ["scout","contract"] and parts.size()==2 and parts[1] is String and not parts[1].is_empty()
static func valid(d:Dictionary)->bool:
 var state:Variant=d.get("encounter_equipment")
 if not state is Dictionary or state.size()!=2 or not state.get("version") is int or state.version!=1 or not state.get("claims") is Dictionary:return false
 if not d.get("seed") is int or not d.get("next_item") is int or not d.get("items") is Dictionary or not d.get("aftermath") is Dictionary:return false
 var seen:Dictionary={};var credited:Dictionary={};var context:Dictionary={}
 for key:Variant in state.claims:
  if not key is String or not valid_key(key):return false
  var claim:Variant=state.claims[key]
  if not claim is Dictionary or not claim.get("casualties") is int or claim.casualties<1 or claim.casualties>12 or not claim.get("drops") is Array:return false
  if claim.has("kit_grades"):
   if claim.drops.size()>1+roll(d.seed,key,"count",2) or not Salvage.valid_claim(d,key,claim,credited,context):return false
  else:
   var expected:Array=definitions(d.seed,key)
   if claim.size()!=2 or claim.drops.size()!=expected.size():return false
   for index in expected.size():
    var row:Variant=claim.drops[index]
    if not row is Dictionary or row.size()!=2 or not row.get("definition") is String or row.definition!=expected[index]:return false
  for row:Dictionary in claim.drops:
   if not row.get("item") is String or row.item.is_empty() or seen.has(row.item):return false
   var serial:String=row.item.trim_prefix("item_")
   if not serial.is_valid_int() or int(serial)<1 or int(serial)>=d.next_item or row.item!="item_%03d"%int(serial):return false
   seen[row.item]=row.definition
   if d.items.has(row.item):
    var item:Variant=d.items[row.item]
    if not item is Dictionary or item.get("definition")!=row.definition or item.has("named") or not item.has("instance_roll"):return false
 # The latest ordinary report is a view of already-owned claimed drops.
 if not d.aftermath.is_empty():
  if not d.aftermath.get("loot") is Array:return false
  var rows:Dictionary={}
  for row:Variant in d.aftermath.loot:
   if not row is Dictionary or not row.get("item") is String or not row.get("source") is String or rows.has(row.item):return false
   rows[row.item]=true
   if row.source=="Encounter spoils" and not seen.has(row.item):return false
 return true
