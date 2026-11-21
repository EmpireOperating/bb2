extends "res://painted_merge/undead/appearance.gd"
const People=preload("res://engraved_people/actors.gd")
const Roles=preload("res://single_body/roles.gd")
const Kits=preload("res://single_body/human_kits.gd")
func _road_kit(unit:Dictionary,catalog:Dictionary,identity:String)->Dictionary:
 # The physical slots own the art. Spare weapons and covered layers stay on the sheet.
 var face:int=("road-face-v1/"+identity).sha256_buffer()[0]%8
 var fitted:Dictionary=People.describe_with_face(unit,face)
 var tex:Texture2D=People._render(fitted.recipe,-1,false)
 var sig:Dictionary={};var issues:Array=[]
 var slots:Dictionary=unit.get("arms",{}).duplicate()
 for part:Dictionary in unit.get("armor_parts",[]):slots[str(part.group)+"/"+str(part.layer)]=part
 for key:String in slots:
  if slots[key].is_empty():continue
  var rec:Dictionary=_record(key,slots[key],catalog);sig[key]=rec
  var layer:Dictionary=fitted.signature.get(key,{})
  if layer.get("visible",false):
   rec.visible=true;rec.painted=true;rec.asset=People.DATA.data.bindings[rec.definition].part
  else:
   var why:String="Not visible in the worn kit."
   for note:Dictionary in fitted.issues:
    if note.slot==key:why=note.reason;break
   _omit(rec,why,issues)
 var base={"path":People.CUTS,"kind":"rolled_physical_kit"}
 var plan={"role":unit.get("bandit_role",""),"base":base,"layers":[base],"frame":{"size":[480,464],"base_origin":[0,0],"stance_anchor":[240,411]},"geometry":{"stance_x":240,"foot_y":411,"base_alpha_top":39,"body_height":1.94}}
 return {"ok":tex!=null,"texture":tex,"signature":sig,"issues":issues,"errors":[] if tex!=null else ["Could not fit road band."],"plan":plan,"source_kind":"rolled_physical_kit","walk_recipe":fitted.recipe}

func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
 var identity=unit.get("human_kit_identity","")
 var human:bool=unit.get("side",-1)==1 and unit.get("faction","")!="undead" and str(unit.get("undead_kind","")).is_empty()
 if human and identity is String and not identity.is_empty():return _road_kit(unit,catalog,identity)
 var role: String = unit.get("bandit_role","")
 # Some valid deployments have no persistent roll key. Use their existing
 # visual ID for face selection only. Neither title nor role changes the kit.
 if human and (role in Roles.IDS or (not unit.has("bandit_role") and unit.get("title","") in Kits.GRADES)):
  return _road_kit(unit,catalog,"board/%s" % unit.get("visual_id",unit.get("id",0)))
 return {"ok":false,"texture":null,"signature":{},"issues":[],"errors":["Unknown Engraved bandit identity"],"plan":{}}
