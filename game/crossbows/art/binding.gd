extends "res://painted_merge/weapon_fits/extension.gd"
## Additive fitted paint. Existing producers own outfit, frame, tint and compositor.
const Assets = preload("res://crossbows/art/assets.gd")
const WEAPONS := ["crossbow","heavy_crossbow"]
var _grip_image: Image
var _base_image: Image
var _enemy_cache := {}

static func wants(signature: Dictionary) -> bool:
 for entry: Dictionary in signature.values():
  if entry.get("definition","") in Assets.IDS:return true
 return false

static func validate(unit: Dictionary, catalog: Dictionary, enemy: bool=false) -> String:
 var slots: Dictionary=unit.get("arms",{}) if enemy else unit.get("equipment_slots",{})
 var weapon: Dictionary=slots.get("weapon" if enemy else "mainhand",{})
 var ammo: Dictionary=slots.get("ammo",{})
 if weapon.get("definition","") not in WEAPONS and ammo.get("definition","")!="bolts":return ""
 var seen := {}
 var records: Array=slots.values()
 if enemy:records.append_array(unit.get("armor_parts",[]))
 for item: Dictionary in records:
  if item.is_empty():continue
  var uid=item.get("id",item.get("item",""))
  if not uid is String or uid.is_empty():return "CROSSBOW_PHYSICAL_UID_REQUIRED"
  if seen.has(uid):return "CROSSBOW_DUPLICATE_PHYSICAL_UID"
  seen[uid]=true
 for pair: Array in [["weapon" if enemy else "mainhand","weapon"],["ammo","ammo"]]:
  var item: Dictionary=slots.get(pair[0],{})
  var definition: String=item.get("definition","")
  if definition not in Assets.IDS:continue
  var actual: Dictionary=catalog.get(definition,{})
  if actual.get("slot")!=("ammo" if pair[1]=="ammo" else "weapon") or actual.get(pair[1])!=definition:return "CROSSBOW_CATALOG_IDENTITY_MISMATCH"
  if not enemy and unit.get("arms",{}).has(pair[1]):
   var other: Dictionary=unit.arms[pair[1]]
   if other.get("id",other.get("item",""))!=item.get("id",item.get("item","")) or other.get("definition")!=definition:return "CROSSBOW_ARMS_IDENTITY_MISMATCH"
 if weapon.get("definition","") in WEAPONS:
  if not slots.get("shield" if enemy else "offhand",{}).is_empty():return "CROSSBOW_TWOHAND_OFFHAND"
  if unit.has("weapon") and unit.weapon!=weapon.definition:return "CROSSBOW_CURRENT_WEAPON_MISMATCH"
 return ""

func _image(layer: Dictionary) -> Dictionary:
 if layer.get("crossbow_context_base",false):return {"ok":true,"image":_base_image}
 if not layer.get("crossbow_fit",false):return super._image(layer)
 var image:=Assets.image(layer)
 if image==null:return _fail("CROSSBOW_REQUIRED_SOURCE_INVALID")
 if layer.get("crossbow_hand",false):return {"ok":true,"image":_grip_image}
 return {"ok":true,"image":image}

func _row(source: Dictionary, entry: Dictionary, at: Array, z: int) -> Dictionary:
 var row:=source.duplicate(true)
 row.merge({"crossbow_fit":true,"placement":at.duplicate(),"z":z,"owner_art_key":"crossbow:"+str(entry.definition),"definition":entry.definition,"item":entry.item,"slot":entry.slot},true)
 return row

func _extras(plan: Dictionary, signature: Dictionary, app: String, baseline: Image, donor=null) -> Dictionary:
 var book:=Assets.manifest()
 if book.is_empty():return _fail("CROSSBOW_MANIFEST_INVALID")
 var fits: Dictionary=book.fits.get(app,{})
 if fits.is_empty():return _fail("CROSSBOW_APPEARANCE_UNREGISTERED")
 var at: Array=plan.frame.base_origin
 var main: Dictionary=signature.get("mainhand",signature.get("weapon",{}))
 var ammo: Dictionary=signature.get("ammo",{})
 if main.get("definition","") in WEAPONS:
  var weapon:=_row(fits[main.definition],main,at,200)
  var held:=Assets.image(fits[main.definition])
  # Retain checked support source admission, without restoring fingers above the
  # user-approved complete weapon-over-hand paint.
  if held==null or Assets.image(fits.hand_restore)==null:return _fail("CROSSBOW_REQUIRED_SOURCE_INVALID")
  var canvas: Array=plan.frame.canvas
  canvas[0]=maxi(int(canvas[0]),int(at[0])+held.get_width())
  canvas[1]=maxi(int(canvas[1]),int(at[1])+held.get_height())
  if plan.frame.has("world_bounds"):
   plan.frame.world_bounds=[-at[0],-at[1],canvas[0]-at[0],canvas[1]-at[1]]
  plan.layers.append(weapon)
  main.visible=true;main.painted=true;main.broken=false;main.fallback=false;main.asset=weapon.path;main.visibility_reason=""
 if ammo.get("definition","")=="bolts":
  var row:=_row(fits.bolts,ammo,at,198)
  if Assets.image(row)==null:return _fail("CROSSBOW_REQUIRED_SOURCE_INVALID")
  plan.layers.append(row)
  ammo.visible=true;ammo.painted=true;ammo.broken=false;ammo.fallback=false;ammo.asset=row.path;ammo.visibility_reason=""
 for i in plan.layers.size():plan.layers[i]["_crossbow_order"]=i
 plan.layers.sort_custom(func(a,b):return a.z<b.z if a.z!=b.z else a._crossbow_order<b._crossbow_order)
 for layer: Dictionary in plan.layers:layer.erase("_crossbow_order")
 return {"ok":true,"plan":plan}

func plan_for(donor, detached: Dictionary) -> Dictionary:
 # Payload has deliberately not mapped crossbows to an old bow/weapon donor.
 var resolved: Dictionary=super.plan_for(donor,detached) if preload("res://painted_merge/weapon_fits/extension.gd").needed(detached) else donor.resolve(detached)
 if not resolved.get("ok",false):return resolved
 _model=donor._model;_files=donor._files;_pack=donor._pack;_images=donor._images
 # Current worn tints are set before producing the contextual hand.
 var baseline:=compose_image(resolved.plan)
 if not baseline.get("ok",false):return baseline
 return _extras(resolved.plan,_signature,detached.appearance,baseline.image,donor)

var _signature := {}
func present_crossbow(owner, detached: Dictionary, signature: Dictionary) -> Dictionary:
 _signature=signature
 # Match the existing producer's condition treatment, excluding ammo quantity.
 _model=owner.resolver._model;_files=owner.resolver._files;_pack=owner.resolver._pack;_images=owner.resolver._images
 tints.clear()
 for entry: Dictionary in signature.values():
  if not entry.visible or entry.maximum<=0 or entry.definition in Assets.IDS:continue
  var key: String=_model.bindings.get(entry.donor_definition,"")
  tints[key]=Color.WHITE.lerp(Color("363127"),(1.0-clampf(float(entry.condition)/float(entry.maximum),0.0,1.0))*0.64)
 var paint_signature:=signature.duplicate(true)
 for entry: Dictionary in paint_signature.values():
  if entry.definition in Assets.IDS:entry.maximum=0
 var result:=present_current(owner,detached,paint_signature)
 if not result.get("ok",false):
  result.texture=null
  for entry: Dictionary in signature.values():entry.visible=false;entry.painted=false
 return result

func _block_enemy(result: Dictionary) -> Dictionary:
 result.ok=false;result.texture=null
 for entry: Dictionary in result.signature.values():entry.visible=false;entry.painted=false
 return result

func present_enemy(owner, unit: Dictionary, catalog: Dictionary, app: String) -> Dictionary:
 var reason:=validate(unit,catalog,true)
 if not reason.is_empty():return {"ok":false,"texture":null,"signature":{},"plan":{},"issues":[],"errors":[reason]}
 var clean:=unit.duplicate(true)
 var physical: Dictionary=unit.get("arms",{})
 if physical.get("weapon",{}).get("definition","") in WEAPONS:clean.arms.erase("weapon");clean.weapon=""
 if physical.get("ammo",{}).get("definition","")=="bolts":clean.arms.erase("ammo")
 var result: Dictionary=owner.describe(clean,catalog)
 if not result.get("ok",false):return result
 for slot: String in ["weapon","ammo"]:
  if physical.get(slot,{}).get("definition","") in Assets.IDS:result.signature[slot]=owner._record(slot,physical[slot],catalog)
 var original_plan: Dictionary=result.plan
 _base_image=result.texture.get_image();_base_image.clear_mipmaps()
 _model={"context":"unchanged checked enemy producer"}
 var canvas: Array=original_plan.frame.size
 var base:={"crossbow_context_base":true,"placement":[0,0],"path":"checked-existing-enemy-composite","sha256":str(result.texture.get_instance_id())}
 var plan:={"base":base,"frame":{"canvas":canvas,"base_origin":original_plan.frame.base_origin},"layers":[],"restore_untouched_base":true}
 var extra:=_extras(plan,result.signature,app,_base_image)
 if not extra.get("ok",false):
  result.errors.append(extra.error);return _block_enemy(result)
 original_plan.frame.size=extra.plan.frame.canvas.duplicate()
 var key:=JSON.stringify([base,extra.plan.frame,extra.plan.layers])
 # Revalidate all registered sources above even on warm paint-cache hits.
 if not _enemy_cache.has(key):
  var composed:=compose_image(extra.plan)
  if not composed.get("ok",false):
   result.errors.append(composed.error);return _block_enemy(result)
  composed.image.generate_mipmaps();_enemy_cache[key]=ImageTexture.create_from_image(composed.image)
  if _enemy_cache.size()>32:_enemy_cache.erase(_enemy_cache.keys()[0])
 result.texture=_enemy_cache[key]
 for layer: Dictionary in extra.plan.layers:
  var row:=layer.duplicate(true);row.offset=row.placement;original_plan.layers.append(row)
 return result
