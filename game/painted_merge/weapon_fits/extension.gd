extends "res://hollow_experiment/worn_resolver.gd"
## Additive source-bound route; never edits/configures the immutable donor model.
## The inherited compositor retains negative-z and untouched-hidden-RGB semantics.
const ROOT := "res://painted_merge/weapon_fits"
const MANIFEST := ROOT+"/manifest.json"
const MANIFEST_SHA := "a6c67e5d462efdbcdf23bd3e299ed5ec3092679c0a519045f3b295f80aba9194"
const APPS := ["shieldbearer","duelist","polearm","archer","occultist"]
const IDS := ["hm_trial_v1:additional_fighting_axe","hm_trial_v1:twohand_sword"]
var _extension: Dictionary = {}
var _extra_images: Dictionary = {}

static func needed(detached: Dictionary) -> bool:
 if detached.get("appearance","") not in APPS: return false
 for item in detached.get("slots",{}).values():
  if item is Dictionary and item.get("definition_id","") in IDS:return true
 return false

func admit() -> Dictionary:
 # Check the manifest on cache hits too. Its exact hash pins all inert metadata.
 if FileAccess.get_sha256(MANIFEST) != MANIFEST_SHA:return _fail("FIT_MANIFEST_HASH_MISMATCH")
 if _extension.is_empty():
  var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
  if not parsed is Dictionary or parsed.get("schema","") != "bb2-parent-reviewed-weapon-fits-v1":return _fail("FIT_MANIFEST_SCHEMA")
  _extension = parsed
 return {"ok":true}

func _image(layer: Dictionary) -> Dictionary:
 if not layer.get("extension_source",false):return super._image(layer)
 var admitted := admit()
 if not admitted.ok:return admitted
 var rel = layer.get("path","");var digest = layer.get("sha256","")
 if not rel is String or not digest is String or digest.length()!=64 or not digest.is_valid_hex_number(false) or rel!="blobs/"+digest+".png":return _fail("UNSAFE_FIT_ASSET_PATH")
 if _extension.files.get(rel)!=digest:return _fail("FIT_ASSET_NOT_ADMITTED")
 var path := ROOT.path_join(rel)
 if FileAccess.get_sha256(path)!=digest:return _fail("FIT_ASSET_HASH_MISMATCH")
 if not _extra_images.has(digest):
  var image := Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK or image.get_format()!=Image.FORMAT_RGBA8:return _fail("FIT_NOT_RGBA")
  _extra_images[digest]=image
 var raw: Image=_extra_images[digest]
 var tint: Color=tints.get(layer.get("owner_art_key",""),Color.WHITE)
 if tint==Color.WHITE:return {"ok":true,"image":raw}
 var bytes:=raw.get_data()
 for i in range(0,bytes.size(),4):
  bytes[i]=int(roundf(bytes[i]*tint.r));bytes[i+1]=int(roundf(bytes[i+1]*tint.g));bytes[i+2]=int(roundf(bytes[i+2]*tint.b))
 return {"ok":true,"image":Image.create_from_data(raw.get_width(),raw.get_height(),false,Image.FORMAT_RGBA8,bytes)}

func plan_for(donor, detached: Dictionary) -> Dictionary:
 var admitted:=admit()
 if not admitted.ok:return admitted
 # Preserve exact donor admission: UID, duplicate UID/hand, slot, two-hand rules.
 var resolved: Dictionary=donor.resolve(detached)
 if not resolved.get("ok",false):return resolved
 var a: Dictionary=_extension.appearances.get(detached.get("appearance",""),{})
 if a.is_empty():return _fail("NO_FIT_APPEARANCE")
 var item: Dictionary=detached.slots.get("mainhand",{})
 var fit: Dictionary=a.fits.get(item.get("definition_id",""),{})
 if fit.is_empty():return _fail("FIT_REQUIRES_MAINHAND")
 var requested=item.get("physical_hand",null)
 if requested!=null and requested!=fit.physical_hand:return _fail("MISSING_PHYSICAL_HAND_FIT")
 if resolved.plan.base.sha256!=a.base_sha256:return _fail("FIT_BASE_MISMATCH")
 var plan: Dictionary=resolved.plan
 plan.frame=a.frame.duplicate(true)
 var origin: Array=plan.frame.base_origin;var size: Array=plan.frame.canvas
 plan.frame.world_bounds=[-origin[0],-origin[1],size[0]-origin[0],size[1]-origin[1]]
 plan.base.placement=origin.duplicate()
 for layer: Dictionary in plan.layers:
  layer.placement=[layer.placement[0]+a.translation[0],layer.placement[1]+a.translation[1]]
 var glove := ""
 for row: Dictionary in plan.selected:
  if row.key in GLOVES:glove=row.key
 # Replace only the currently held physical hand. Other-hand shield/context
 # partitions and every existing wardrobe condition stay donor-owned.
 if not glove.is_empty():
  var old_hand_paths: Array=[]
  for source: Dictionary in donor._model.appearances[plan.appearance].records[glove].layers:
   if source.hand==fit.physical_hand:old_hand_paths.append(source.payload.path)
  plan.layers=plan.layers.filter(func(l):return not (l.get("owner_art_key","")==glove and l.path in old_hand_paths))
  for part: String in ["rear","front"]:plan.layers.append(fit.gloves[glove][part].duplicate(true))
 plan.layers.append(fit.weapon.duplicate(true))
 if glove not in FULL:plan.layers.append(fit.skin.duplicate(true))
 for i in plan.layers.size():plan.layers[i]["_fit_ordinal"]=i
 plan.layers.sort_custom(func(x,y):return x.z<y.z if x.z!=y.z else x._fit_ordinal<y._fit_ordinal)
 for layer: Dictionary in plan.layers:layer.erase("_fit_ordinal")
 plan.selected.append({"uid":item.uid,"definition_id":item.definition_id,"slot":"mainhand","key":fit.key,"physical_hand":fit.physical_hand,"kind":"parent_reviewed_weapon_fit"})
 plan.issues=plan.issues.filter(func(issue):return issue.get("slot","")!="mainhand")
 return {"ok":true,"plan":plan}

func present_current(owner, detached: Dictionary, signature: Dictionary) -> Dictionary:
 var resolved:=plan_for(owner.resolver,detached)
 if not resolved.ok:return resolved
 _model=owner.resolver._model;_files=owner.resolver._files;_pack=owner.resolver._pack;_images=owner.resolver._images
 tints.clear()
 for entry in signature.values():
  if not entry.visible or entry.maximum<=0:continue
  var worn:=1.0-clampf(float(entry.condition)/float(entry.maximum),0.0,1.0)
  var key: String=_model.bindings.get(entry.donor_definition,"")
  tints[key]=Color.WHITE.lerp(Color("363127"),worn*0.64)
 for layer in [resolved.plan.base]+resolved.plan.layers:
  var source:=_image(layer)
  if not source.ok:source["source_path"]=layer.path;return source
 var recipe:={"appearance":resolved.plan.appearance,"frame":resolved.plan.frame,"base":resolved.plan.base,"layers":resolved.plan.layers,"restore_untouched_base":resolved.plan.restore_untouched_base,"tints":tints}
 var key:=JSON.stringify(recipe,"",true)
 if owner._cache.has(key):
  owner._cache_order.erase(key);owner._cache_order.append(key)
 else:
  var composed:=compose_image(resolved.plan)
  if not composed.ok:return composed
  var mip: Image=composed.image.duplicate();mip.generate_mipmaps()
  owner._cache[key]={"image":composed.image,"texture":ImageTexture.create_from_image(mip)}
  owner._cache_order.append(key);owner._builds+=1
  while owner._cache_order.size()>owner.CACHE_LIMIT:owner._cache.erase(owner._cache_order.pop_front())
 return {"ok":true,"plan":resolved.plan,"image":owner._cache[key].image.duplicate(),"texture":owner._cache[key].texture,"cache_key":key}
