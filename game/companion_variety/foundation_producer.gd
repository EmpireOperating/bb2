extends "res://crossbows/art/binding.gd"
## A consumer-only foundation identity stage. Original plan.base remains sealed.
## Real full-foundation variants enter the SAME inherited negative-z compositor,
## below foreground gear and outside every equipment wear/tint owner.
const Faces = preload("res://companion_variety/face_identity.gd")
func _image(layer: Dictionary) -> Dictionary:
 if layer.get("face_foundation_source",false):return Faces.image(layer)
 return super._image(layer)
func compose_image(plan: Dictionary) -> Dictionary:
 if not plan.has("foundation_identity"):return super.compose_image(plan)
 var paint := plan.duplicate(true)
 var source: Dictionary = paint.foundation_identity.duplicate(true)
 source["face_foundation_source"] = true
 source["placement"] = paint.base.placement.duplicate()
 paint.base = source
 return super.compose_image(paint)
func face_plan(donor, detached: Dictionary) -> Dictionary:
 var fits = preload("res://painted_merge/weapon_fits/extension.gd").new()
 var resolved: Dictionary = fits.plan_for(donor,detached) if fits.needed(detached) else donor.resolve(detached)
 if not resolved.get("ok",false):return resolved
 var face := Faces.foundation(detached,resolved.plan.base)
 if not face.ok:return face
 resolved.plan["foundation_identity"] = face.foundation
 if wants(_signature):
  var baseline := compose_image(resolved.plan)
  if not baseline.get("ok",false):return baseline
  return _extras(resolved.plan,_signature,detached.appearance,baseline.image,donor)
 return resolved
func present_face(owner, detached: Dictionary, signature: Dictionary) -> Dictionary:
 _signature=signature
 _model=owner.resolver._model;_files=owner.resolver._files;_pack=owner.resolver._pack;_images=owner.resolver._images
 tints.clear()
 for entry: Dictionary in signature.values():
  if not entry.visible or entry.maximum<=0 or entry.definition in Assets.IDS:continue
  var art_key: String = _model.bindings.get(entry.donor_definition,"")
  tints[art_key]=Color.WHITE.lerp(Color("363127"),(1.0-clampf(float(entry.condition)/float(entry.maximum),0.0,1.0))*0.64)
 var resolved := face_plan(owner.resolver,detached)
 if not resolved.get("ok",false):return resolved
 # Required original AND selected sources are checked even on warm recipe hits.
 for layer: Dictionary in [resolved.plan.base]+resolved.plan.layers:
  var source := _image(layer)
  if not source.get("ok",false):source["source_path"]=layer.path;return source
 var selected := Faces.image(resolved.plan.foundation_identity)
 if not selected.ok:return selected
 var recipe := {"appearance":resolved.plan.appearance,"frame":resolved.plan.frame,"base":resolved.plan.base,"foundation_identity":resolved.plan.foundation_identity,"layers":resolved.plan.layers,"restore_untouched_base":resolved.plan.restore_untouched_base,"tints":tints}
 var key := JSON.stringify(recipe,"",true)
 if owner._cache.has(key):
  owner._cache_order.erase(key);owner._cache_order.append(key)
 else:
  var composed := compose_image(resolved.plan)
  if not composed.ok:return composed
  var mip: Image=composed.image.duplicate();mip.generate_mipmaps()
  owner._cache[key]={"image":composed.image,"texture":ImageTexture.create_from_image(mip)}
  owner._cache_order.append(key);owner._builds+=1
  while owner._cache_order.size()>owner.CACHE_LIMIT:owner._cache.erase(owner._cache_order.pop_front())
 return {"ok":true,"plan":resolved.plan,"image":owner._cache[key].image.duplicate(),"texture":owner._cache[key].texture,"cache_key":key}
