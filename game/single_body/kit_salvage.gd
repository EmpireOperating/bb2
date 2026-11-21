extends RefCounted
## Immutable corpse token -> newly owned UID. No kit generation at award time.
const Roles = preload("res://single_body/roles.gd")
const Catalog = preload("res://hollow_campaign/catalog.gd")
const A = preload("res://src/arsenal.gd")

static func collect(out:Dictionary, unit:String, slot:String, id:String, part:Dictionary, catalog:Dictionary) -> void:
 var definition:String=part.definition
 # Stowed quivers and throwing bundles use the same separate supply ledger.
 # 0/0 weapons and utility pieces don't wear out; 0/N protection is broken.
 if part.has("named") or A.ammo_supply_cost(definition)>0 or catalog[definition].slot=="ammo":return
 if part.condition==0 and catalog[definition].durability>0:return
 var row:Dictionary={"source_item":id,"unit":unit,"slot":slot,"definition":definition,"condition":part.condition}
 if A.family(definition)=="crossbow":row["loaded"]=part.loaded
 out[id]=row

static func pieces(unit:String, arms:Dictionary, parts:Array, catalog:Dictionary) -> Dictionary:
 var out:Dictionary={}
 for slot:String in arms:
  var arm:Dictionary=arms[slot]
  if not arm.is_empty():collect(out,unit,slot,arm.id,arm,catalog)
 for part:Dictionary in parts:collect(out,unit,part.hollow_slot,part.item,part,catalog)
 return out

# Called only for the explicit physical-claim shape. Bind its sources to the
# historic dead roster and the issued item tokens, not to present inventory wear
# (which can be repaired, damaged, equipped or sold after the claim).
static func valid_claim(d:Dictionary, key:String, claim:Dictionary, credited:Dictionary, context:Dictionary) -> bool:
 if not d.has("human_kits") or claim.size()!=3 or not claim.kit_grades is Dictionary:return false
 if claim.kit_grades.is_empty() or claim.kit_grades.size()>claim.casualties:return false
 if not d.get("bandit_spoils") is Dictionary or not d.bandit_spoils.get("members") is Array:return false
 var encounter:Array=JSON.parse_string(key);var party:String
 if encounter[0]=="camp":
  var site_key:String=preload("res://src/camp_life.gd").key(encounter[1],int(encounter[2]))
  if key!=JSON.stringify(["camp",encounter[1],int(encounter[2])]):return false
  if not d.get("camp_life") is Dictionary or not d.camp_life.get("records") is Dictionary:return false
  var record:Variant=d.camp_life.records.get(site_key)
  if not record is Dictionary or not record.get("party") is String:return false
  party=record.party
 elif encounter[0]=="scout" and key==JSON.stringify(encounter):party=encounter[1]
 else:return false
 if context.is_empty():
  context.groups=Roles.Kits.source_groups(d);context.catalog=Catalog.equipment()
 var issued:Dictionary={}
 for unit:Variant in claim.kit_grades:
  if not unit is String or not context.groups.has(unit) or unit not in d.bandit_spoils.members or credited.has(unit):return false
  if unit.begins_with("resident/"):
   if encounter[0]!="camp" or not unit.begins_with("resident/%s/%d/"%[encounter[1],int(encounter[2])]):return false
  else:
   var band:Variant=d.bandits.bands.get(party)
   if not band is Dictionary or unit.trim_prefix("member/") not in band.fallen:return false
  var group:String=context.groups[unit];var grade:Variant=claim.kit_grades[unit]
  if not grade is int or grade not in {"ford":[0,1],"forest":[1,2],"ridge":[1,2,3]}[group]:return false
  var kit:Dictionary=Roles.Kits.recipe(d.seed,unit,Roles.role_for(d.seed,unit),group,grade,context.catalog)
  issued.merge(pieces(unit,kit.arms,kit.parts,context.catalog));credited[unit]=true
 for row:Variant in claim.drops:
  if not row is Dictionary or not row.get("source_item") is String or not issued.has(row.source_item):return false
  var original:Dictionary=issued[row.source_item];issued.erase(row.source_item)
  if row.size()!=original.size()+1 or row.get("unit")!=original.unit or row.get("definition")!=original.definition:return false
  if not row.get("condition") is int or row.condition<0 or row.condition>original.condition:return false
  if row.condition==0 and context.catalog[row.definition].durability>0:return false
  if not row.get("slot") is String:return false
  if original.slot in A.SLOTS:
   if row.slot not in A.SLOTS or not A.allowed(row.slot,row.definition,context.catalog):return false
  elif row.slot!=original.slot:return false
  if original.has("loaded") and not row.get("loaded") is bool:return false
 return true
