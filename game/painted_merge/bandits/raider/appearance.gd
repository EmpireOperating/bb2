extends "res://painted_merge/bandits/appearance.gd"
## Reuse checked image, physical-record, tint and mask primitives, not Highwayman paint.
const RAIDER_MANIFEST := "res://painted_merge/bandits/raider/manifest.json"
const RAIDER_MANIFEST_SHA := "5306c718310d8e131ae6f049f54a2851e3dabd69296046764a86fa82f9d08374"
const RAIDER_RECIPE := "res://painted_merge/bandits/raider/recipe.json"

func _extension_owner_errors(unit: Dictionary) -> Array:
 var errors: Array=[]
 var rows: Array=unit.get("arms",{}).values()+unit.get("armor_parts",[])
 for row: Dictionary in rows:
  if row.get("definition","") not in ["hm_trial_v1:old24-quarry_estoc","hm_trial_v1:cloaks-04-waxed-cape"]:continue
  var uid=row.get("id",row.get("item",""))
  if not uid is String or uid.is_empty():
   errors.append("Exact Raider extension requires a literal nonempty physical UID");continue
  var count: int=0
  for other: Dictionary in rows:
   var other_uid=other.get("id",other.get("item",""))
   if other_uid is String and other_uid==uid:count+=1
  if count!=1:errors.append("Exact Raider extension refuses duplicate physical UID ownership")
 return errors

func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
 var result: Dictionary={"ok":false,"texture":null,"signature":{},"issues":[],"errors":[],"plan":{}}
 if not FileAccess.file_exists(RAIDER_MANIFEST) or FileAccess.get_sha256(RAIDER_MANIFEST)!=RAIDER_MANIFEST_SHA:
  result.errors.append("Required Raider manifest missing or changed");return result
 if _manifest.is_empty():_manifest=JSON.parse_string(FileAccess.get_file_as_string(RAIDER_MANIFEST))
 if not FileAccess.file_exists(RAIDER_RECIPE) or FileAccess.get_sha256(RAIDER_RECIPE)!=_manifest.recipe_sha256:
  result.errors.append("Required accepted Raider recipe missing or changed");return result
 if _recipe.is_empty():_recipe=JSON.parse_string(FileAccess.get_file_as_string(RAIDER_RECIPE))
 result.errors.append_array(_extension_owner_errors(unit))
 var signature: Dictionary=result.signature;var issues: Array=result.issues;var selected: Dictionary={}
 for slot: String in unit.get("arms",{}):
  var item: Dictionary=unit.arms[slot]
  if item.is_empty():continue
  var entry:=_record(slot,item,catalog);signature[slot]=entry
  if slot in ["weapon","shield"]:selected["mainhand" if slot=="weapon" else "offhand"]=entry
 for part: Dictionary in unit.get("armor_parts",[]):
  var slot:=str(part.get("group",""))+"/"+str(part.get("layer",""))
  var entry:=_record(slot,part,catalog);signature[slot]=entry
  if part.get("layer","")=="cloak":
   if selected.has("cloak"):result.errors.append("Duplicate physical Raider support slot: cloak")
   selected["cloak"]=entry
   continue
  if part.get("layer","") in ["hands","feet","belt"]:
   _omit(entry,"Actual support equipment has no exact Raider paint; physical owner retained without proxy.",issues)
   continue
  var group:=str(part.get("group",""))
  if group in ["body","head"]:
   if selected.has(group):result.errors.append("Duplicate physical Raider slot: "+group)
   selected[group]=entry
 if selected.has("offhand") and (str(unit.get("weapon","")) in Arms.TWO_HANDS or selected.get("mainhand",{}).get("definition","") in Arms.TWO_HANDS):
  result.errors.append("Actual two-handed weapon refuses any selected offhand, even broken; authority unchanged.")
 var visible: Dictionary={};var routes: Dictionary={}
 for key: String in _recipe.routes:
  var route: Dictionary=_recipe.routes[key];routes[route.definition_id]=key
 for slot: String in selected:
  var entry: Dictionary=selected[slot];var key: String=routes.get(entry.definition,"")
  var fit: Dictionary=_recipe.routes.get(key,{})
  if entry.item.is_empty():_omit(entry,"Missing physical UID; no borrowed Raider paint.",issues)
  elif fit.get("owner","")!=slot:_omit(entry,"No exact Raider definition/slot fit; no proxy.",issues)
  elif slot=="mainhand" and str(unit.get("weapon",""))!=entry.definition:_omit(entry,"Actual weapon and physical UID definition disagree; no substitute.",issues)
  elif slot=="offhand" and (entry.broken or not bool(unit.get("shield",true))):_omit(entry,"Broken or inactive actual shield has no paint.",issues)
  else:visible[slot]={"entry":entry,"key":key}
 var frame: Dictionary={"size":_recipe.frame.source_canvas.duplicate(),"base_origin":_recipe.frame.source_base_origin.duplicate(),"stance_anchor":_recipe.frame.source_stance_ground.duplicate()}
 var origin: Array=frame.base_origin
 var weapon: Dictionary=visible.get("mainhand",{})
 var hand_route: String=""
 if not weapon.is_empty():hand_route=str(_recipe.routes[weapon.key].get("conditional_hand",""))
 var hand: Dictionary=_recipe.hand_routes.get(hand_route,{})
 var mask: Dictionary=_paint(hand.keep_mask,weapon.entry,[0,0],0,false) if not hand.is_empty() else {}
 var foundation: Dictionary=_paint(_recipe.layers.foundation.path,{},origin,0,false)
 foundation.foundation=true
 var layers: Array=[foundation]
 for slot: String in visible:
  var entry: Dictionary=visible[slot].entry;var key: String=visible[slot].key
  var fit: Dictionary=_recipe.routes[key]
  if fit.has("layers"):
   for row: Dictionary in fit.layers:
    layers.append(_paint(row.layer,entry,row.offset,int(row.z),bool(row.tint)))
   entry.asset=_manifest.sources[fit.layers[0].layer].path
  else:
   var layer: Dictionary=_recipe.layers[key if slot not in ["body","head"] else fit.definition_id]
   layers.append(_paint(fit.layer,entry,layer.frame_origin,int(fit.z)))
   entry.asset=_manifest.sources[fit.layer].path
  entry.painted=true;entry.visible=true
  if slot=="mainhand" and not hand.is_empty():layers.append(_paint(hand.registered_layer,entry,origin,int(hand.z),false))
 for entry: Dictionary in signature.values():
  if not entry.visible and entry.visibility_reason.is_empty():_omit(entry,"Carried reserve/ammunition is not an equipped painted slot.",issues)
 layers.sort_custom(func(a,b):return a.z<b.z)
 result.plan={"frame":frame,"geometry":_manifest.geometry.duplicate(true),"layers":layers.duplicate(true),"base":_manifest.sources[_recipe.layers.foundation.path].duplicate(true),"foundation_keep_mask":mask.duplicate(true),"hand_route":hand_route}
 # Cache paint only; fresh literal physical owners remain in signature and plan.
 var paints: Array=[]
 for row: Dictionary in layers:
  var paint:=row.duplicate(true);paint.erase("item");paints.append(paint)
 var mask_key:=mask.duplicate(true);mask_key.erase("item")
 var key:=JSON.stringify([frame,paints,mask_key])
 var images: Array=[]
 for row: Dictionary in layers:
  var image:=_image(row);images.append(image)
  if image==null:result.errors.append("Required Raider PNG missing, changed or invalid: "+str(row.path))
 var keep: Image=null
 if not hand.is_empty():
  keep=_image(mask)
  if keep==null:result.errors.append("Required Raider foundation keep mask missing, changed or invalid")
 if result.errors.is_empty():
  if _cache.has(key):result.texture=_cache[key]
  else:
   var output:=Image.create(int(frame.size[0]),int(frame.size[1]),false,Image.FORMAT_RGBA8);output.fill(Color.TRANSPARENT)
   var rear: bool=layers.any(func(row):return row.z<0)
   for i in layers.size():
    var row: Dictionary=layers[i];var image: Image=images[i]
    if row.get("foundation",false) and keep!=null:image=_masked_foundation(image,keep)
    if row.tint!=[1.0,1.0,1.0]:image=_tinted(image,row.tint)
    var at:=Vector2i(int(row.offset[0]),int(row.offset[1]))
    # Keep original whole RGBA without rear cloth; do not erase a rear cape.
    if row.get("foundation",false) and not rear:output.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),at)
    else:output.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),at)
   output.generate_mipmaps();result.texture=ImageTexture.create_from_image(output)
   if _cache.size()>=48:_cache.erase(_cache.keys()[0])
   _cache[key]=result.texture
 result.ok=result.texture!=null
 if not result.ok:
  for entry: Dictionary in signature.values():entry.visible=false;entry["composite_blocked"]=true
 return result
