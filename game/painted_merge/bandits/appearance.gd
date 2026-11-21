extends "res://painted_merge/undead/appearance.gd"
## Reuse the accepted physical-record, tint and checked-cache primitives only.
## All paint is the literal accepted Highwayman source-space recipe, never living art.
const HW_MANIFEST := "res://painted_merge/bandits/manifest.json"
const HW_MANIFEST_SHA := "4843bfab3c6602edccf3ecaf3f073c570ec9423148a8baf210885966ef20edcd"
const RECIPE := "res://painted_merge/bandits/recipe.json"
var _recipe: Dictionary = {}

func _paint(path: String, owner: Dictionary, offset: Array, z: int, tint: bool=true) -> Dictionary:
 var source: Dictionary=_manifest.sources[path].duplicate(true);source.z=z
 var row:=_layer(source,owner,offset,tint)
 row.merge({"condition":owner.get("condition",0),"maximum":owner.get("maximum",0),"mask":source.mask})
 return row

func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
 var result: Dictionary={"ok":false,"texture":null,"signature":{},"issues":[],"errors":[],"plan":{}}
 if not FileAccess.file_exists(HW_MANIFEST) or FileAccess.get_sha256(HW_MANIFEST)!=HW_MANIFEST_SHA:
  result.errors.append("Required Highwayman manifest missing or changed");return result
 if _manifest.is_empty():_manifest=JSON.parse_string(FileAccess.get_file_as_string(HW_MANIFEST))
 if not FileAccess.file_exists(RECIPE) or FileAccess.get_sha256(RECIPE)!=_manifest.recipe_sha256:
  result.errors.append("Required accepted Highwayman recipe missing or changed");return result
 if _recipe.is_empty():_recipe=JSON.parse_string(FileAccess.get_file_as_string(RECIPE))
 var signature: Dictionary=result.signature;var issues: Array=result.issues;var selected: Dictionary={}
 for slot: String in unit.get("arms",{}):
  var item: Dictionary=unit.arms[slot]
  if item.is_empty():continue
  var entry:=_record(slot,item,catalog);signature[slot]=entry
  if slot in ["weapon","shield"]:selected["mainhand" if slot=="weapon" else "offhand"]=entry
 for part: Dictionary in unit.get("armor_parts",[]):
  var slot:=str(part.get("group",""))+"/"+str(part.get("layer",""))
  var entry:=_record(slot,part,catalog);signature[slot]=entry
  if part.get("layer","") in ["hands","feet","cloak","belt"]:
   var support_slot: String=str(part.layer)
   if selected.has(support_slot):result.errors.append("Duplicate physical Highwayman support slot: "+support_slot)
   selected[support_slot]=entry
   continue
  var group:=str(part.get("group",""))
  if group in ["body","head"]:
   if selected.has(group):result.errors.append("Duplicate physical Highwayman slot: "+group)
   selected[group]=entry
 if selected.has("mainhand") and selected.has("offhand") and str(unit.get("weapon","")) in Arms.TWO_HANDS:
  result.errors.append("Actual two-handed weapon refuses any selected offhand, even broken; authority unchanged.")
 var visible: Dictionary={}
 for slot: String in selected:
  var entry: Dictionary=selected[slot];var fit: Dictionary=_recipe.support_items.get(entry.definition,{}) if slot in ["hands","feet","cloak","belt"] else _recipe.items.get(entry.definition,{})
  if entry.item.is_empty():_omit(entry,"Missing physical UID; no borrowed Highwayman paint.",issues)
  elif fit.get("slot","")!=slot:_omit(entry,"No exact Highwayman definition/slot fit; no proxy.",issues)
  elif slot=="mainhand" and str(unit.get("weapon",""))!=entry.definition:_omit(entry,"Actual weapon and physical UID definition disagree; no substitute.",issues)
  elif slot=="offhand" and (entry.broken or not bool(unit.get("shield",true))):_omit(entry,"Broken or inactive actual shield has no paint.",issues)
  else:visible[slot]=entry
 var frame_key: String="pike" if visible.get("mainhand",{}).get("definition","")=="pike" else "round-shield" if visible.get("offhand",{}).get("definition","")=="hm_trial_v1:offhands-02-round-wooden-shield" else "ordinary"
 var frame: Dictionary=_recipe.frames[frame_key].duplicate(true);var origin: Array=frame.base_origin
 var weapon: Dictionary=visible.get("mainhand",{})
 var closed: bool=weapon.get("definition","") in _recipe.closed_hand.activation_definitions
 var mask: Dictionary=_paint(_recipe.closed_hand.keep_mask,weapon,[0,0],0,false) if closed else {}
 var foundation: Dictionary=_paint(_recipe.foundation.path,{},origin,0,false)
 foundation.foundation=true
 var layers: Array=[foundation]
 for slot: String in visible:
  var entry: Dictionary=visible[slot]
  if slot in ["hands","feet","cloak","belt"]:
   var rows: Array=_support_layers(entry,origin,closed,str(selected.get("body",{}).get("definition","")),issues)
   if not rows.is_empty():
    layers.append_array(rows);entry.painted=true;entry.visible=true;entry.asset=rows[0].path
   continue
  var fit: Dictionary=_recipe.items[entry.definition]
  var own: Array=_recipe.frames[fit.frame].base_origin
  var at: Array=[int(origin[0])-int(own[0]),int(origin[1])-int(own[1])]
  layers.append(_paint(fit.layer,entry,at,int(fit.z)))
  entry.painted=true;entry.visible=true;entry.asset=_manifest.sources[fit.layer].path
  if slot=="mainhand":
   if closed:layers.append(_paint(_recipe.closed_hand.path,entry,origin,70,false))
   elif fit.has("finger_foreground"):layers.append(_paint(fit.finger_foreground,entry,at,int(fit.finger_z),false))
 for slot: String in signature:
  var entry: Dictionary=signature[slot]
  if not entry.visible and entry.visibility_reason.is_empty():_omit(entry,"Carried reserve/ammunition is not an equipped painted slot.",issues)
 for i in layers.size():layers[i].order=i
 layers.sort_custom(func(a,b):return a.z<b.z if a.z!=b.z else a.order<b.order)
 result.plan={"frame":frame,"frame_key":frame_key,"geometry":_manifest.geometry.duplicate(true),"layers":layers.duplicate(true),"base":_manifest.sources[_recipe.foundation.path].duplicate(true),"foundation_keep_mask":mask.duplicate(true),"closed_hand":closed}
 # Identity lives in the fresh plan/signature; the bounded cache stores paint alone.
 var paints: Array=[]
 for row: Dictionary in layers:
  var paint:=row.duplicate(true);paint.erase("item");paints.append(paint)
 var mask_key:=mask.duplicate(true);mask_key.erase("item")
 var key:=JSON.stringify([frame,paints,mask_key])
 var images: Array=[]
 for row: Dictionary in layers:
  var image:=_image(row);images.append(image)
  if image==null:result.errors.append("Required Highwayman PNG missing, changed or invalid: "+str(row.path))
 var keep: Image=null
 if closed:
  keep=_image(mask)
  if keep==null:result.errors.append("Required Highwayman foundation keep mask missing, changed or invalid")
 if result.errors.is_empty():
  if _cache.has(key):result.texture=_cache[key]
  else:
   var output:=Image.create(int(frame.size[0]),int(frame.size[1]),false,Image.FORMAT_RGBA8);output.fill(Color.TRANSPARENT)
   for i in layers.size():
    var row: Dictionary=layers[i];var image: Image=images[i]
    if row.get("foundation",false) and closed:image=_masked_foundation(image,keep)
    if row.tint!=[1.0,1.0,1.0]:image=_tinted(image,row.tint)
    var at:=Vector2i(int(row.offset[0]),int(row.offset[1]))
    # A rear cloak precedes the foundation: blend rather than erase it.
    output.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),at)
   if frame_key=="ordinary":
    var original: Image=_image(foundation)
    if closed:original=_masked_foundation(original,keep)
    output=_restore_hidden_rgba(output,original)
   if layers.size()==1:output=images[0].duplicate()
   output.generate_mipmaps();result.texture=ImageTexture.create_from_image(output)
   if _cache.size()>=48:_cache.erase(_cache.keys()[0])
   _cache[key]=result.texture
 result.ok=result.texture!=null
 if not result.ok:
  for entry: Dictionary in signature.values():entry.visible=false;entry["composite_blocked"]=true
 return result

func _image(row: Dictionary) -> Image:
 if not row.get("mask",false):return super._image(row)
 if not FileAccess.file_exists(row.path) or FileAccess.get_sha256(row.path)!=row.sha256:return null
 if _images.has(row.path):return _images[row.path]
 var image:=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes(row.path))!=OK:return null
 if image.get_size()!=Vector2i(int(row.dimensions[0]),int(row.dimensions[1])) or image.get_format()!=Image.FORMAT_L8:return null
 _images[row.path]=image;return image

func _masked_foundation(image: Image, keep: Image) -> Image:
 var bytes:=image.get_data();var mask:=keep.get_data()
 for i in mask.size():bytes[i*4+3]=int(bytes[i*4+3])*int(mask[i])/255
 return Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes)


func _support_layers(entry: Dictionary, origin: Array, closed: bool, body: String, issues: Array) -> Array:
 var fit: Dictionary=_recipe.support_items[entry.definition]
 var rows: Array=[]
 if fit.has("contexts"):
  if not fit.contexts.has(body):
   _omit(entry,"No accepted utility-belt fit for the actual body context; no bare fallback.",issues)
   return rows
  rows.append(_paint(fit.contexts[body],entry,origin,int(fit.z)))
 else:
  for source: Dictionary in fit.layers:
   if source.get("hand","")=="closed" and not closed:continue
   if source.get("hand","")=="open" and closed:continue
   rows.append(_paint(source.layer,entry,origin,int(source.z)))
 return rows

func _restore_hidden_rgba(output: Image, original: Image) -> Image:
 var bytes:=output.get_data();var source:=original.get_data()
 for i in range(0,bytes.size(),4):
  if bytes[i+3]==0 and source[i+3]==0:
   bytes[i]=source[i];bytes[i+1]=source[i+1];bytes[i+2]=source[i+2]
 return Image.create_from_data(output.get_width(),output.get_height(),false,Image.FORMAT_RGBA8,bytes)
