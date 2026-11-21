extends RefCounted
## Read-only BB2 -> pinned complete Hollow March presentation boundary.
const Resolver = preload("res://hollow_experiment/donor/approved_six_presentation.gd")
const WornResolver = preload("res://hollow_experiment/worn_resolver.gd")
const MODEL_SHA := "48b72c24bb5b29a3dd97432f29ddba02216458e9ab7c0200ceb693d9e7e2db8f"
const APPEARANCES := ["shieldbearer","duelist","polearm","archer","medic","occultist"]
var resolver = Resolver.new()
var admission: Dictionary
const CACHE_LIMIT := 16
var _cache: Dictionary = {}
var _cache_order: Array[String] = []
var _builds := 0

func _init() -> void:
	admission = resolver.configure("res://hollow_experiment/donor/data/normalized.json","res://hollow_experiment/donor/data/pack",MODEL_SHA)

const WEAPONS := {"sword":"short_sword","axe":"hm_trial_v1:old24-medic_heavy","spear":"hm_trial_v1:old24-polearm_weapon","bow":"hm_trial_v1:old24-archer_weapon"}
const SHIELDS := {"shield":"hm_trial_v1:offhands-02-round-wooden-shield","round_shield":"hm_trial_v1:offhands-02-round-wooden-shield"}
const BODY := {"linen":"hm_trial_v1:old24-scout_coat","red_gambeson":"hm_trial_v1:old24-scout_coat","mail":"march_mail","brigandine":"hm_trial_v1:old24-banded_mail"}
const HEAD := {"nasal":"iron_cap","kettle":"hm_trial_v1:headwear-04-kettle-helm"}
const PROXY_NOTES := {
	"linen":"Quilted linen shown as donor cloth Scout Coat outfit.",
	"red_gambeson":"Russet gambeson shown as donor cloth Scout Coat outfit; shared source colors.",
	"brigandine":"Brigandine shown as Banded Mail outfit, not brigandine plate paint.",
	"nasal":"Nasal helm shown as iron skullcap without nasal guard.",
	"sword":"Arming sword shown with short-sword silhouette.",
	"axe":"Bearded axe shown as surgical hatchet (medic: fighting axe).",
	"spear":"One-handed BB2 boar spear shown in donor two-handed pose; equipped shield paint omitted.",
	"shield":"Heater shield shown as round wooden shield."
}

func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
	if not admission.get("ok",false): return admission.duplicate(true)
	var appearance: String = APPEARANCES[posmod(int(unit.get("visual_id",0)),6)]
	var detached := {"person_id":"bb2:"+str(unit.get("visual_id",0)),"appearance":appearance,"slots":{}}
	var signature := {}
	var issues: Array = []
	var arms: Dictionary = unit.get("arms",{})
	var physical: Dictionary = arms.get("weapon",{})
	var definition := str(unit.get("weapon",physical.get("definition","")))
	if not definition.is_empty():
		# Explicit battle definition wins, but never relabel a stale physical UID.
		var source: Dictionary = physical if physical.get("definition","") == definition else {}
		var mapped: String = WEAPONS.get(definition,"")
		if definition == "axe" and appearance == "medic": mapped = "hm_trial_v1:additional_fighting_axe"
		var entry := _record("weapon",definition,source,catalog,mapped)
		signature.weapon = entry
		if _admit(entry,issues):
			detached.slots.mainhand = {"uid":entry.item,"definition_id":mapped,"physical_hand":null if definition in ["spear","bow"] else "right"}
	physical = arms.get("shield",{})
	if not physical.is_empty():
		var shield_id := str(physical.get("definition",""))
		var entry := _record("shield",shield_id,physical,catalog,SHIELDS.get(shield_id,""))
		signature.shield = entry
		if not bool(unit.get("shield",true)) or entry.broken:
			entry.visible = false; entry.painted = false
			entry.visibility_reason = "Broken or inactive actual shield; no shield paint."
		elif definition == "spear":
			entry.visible = false; entry.painted = false
			entry.visibility_reason = "No accepted one-hand spear fit; complete donor two-hand pose excludes shield paint."
			issues.append({"slot":"shield","uid":entry.item,"definition":shield_id,"reason":entry.visibility_reason})
		elif _admit(entry,issues):
			detached.slots.offhand = {"uid":entry.item,"definition_id":entry.donor_definition,"physical_hand":"left"}
	physical = arms.get("ammo",{})
	if not physical.is_empty():
		var ammo_id := str(physical.get("definition",""))
		var entry := _record("ammo",ammo_id,physical,catalog,"")
		entry.broken = false # Ammunition condition is remaining rounds, not armor damage.
		entry.visibility_reason = "Actual BB2 %s (%d/%d ammunition): quiver/ammo paint omitted; ammunition remains mechanical." % [catalog.get(ammo_id,{}).get("name",ammo_id),entry.condition,entry.maximum]
		signature.ammo = entry
		issues.append({"slot":"ammo","uid":entry.item,"definition":ammo_id,"reason":entry.visibility_reason})
	var owner := _armor(unit,catalog,detached,signature,issues)
	var result: Dictionary = _present(detached,signature)
	result["outfit_owner"] = owner.duplicate(true)
	result["detached"] = detached.duplicate(true)
	result["signature"] = signature
	result["issues"] = issues
	result["notes"] = []
	for entry in signature.values():
		if entry.proxy: result.notes.append(entry.fallback_reason)
		if not entry.visibility_reason.is_empty(): result.notes.append(entry.visibility_reason)
	if result.get("ok",false): result.issues.append_array(result.plan.issues)
	return result

func _present(detached: Dictionary, signature: Dictionary) -> Dictionary:
	var resolved: Dictionary = resolver.resolve(detached)
	if not resolved.get("ok",false): return resolved
	var worker = WornResolver.new()
	worker._model = resolver._model
	worker._files = resolver._files
	worker._pack = resolver._pack
	worker._images = resolver._images
	for entry in signature.values():
		if not entry.visible or entry.maximum <= 0: continue
		var worn := 1.0-clampf(float(entry.condition)/float(entry.maximum),0.0,1.0)
		var key: String = resolver._model.bindings.get(entry.donor_definition,"")
		worker.tints[key] = Color.WHITE.lerp(Color("363127"),worn*0.64)
	# Validate source bytes on EVERY request, including cache hits, so stale
	# textures can never conceal missing/changed actual paint.
	for layer in [resolved.plan.base]+resolved.plan.layers:
		var source: Dictionary = resolver._image(layer)
		if not source.get("ok",false):
			source["source_path"] = layer.path
			return source
	var recipe := {"appearance":resolved.plan.appearance,"frame":resolved.plan.frame,"base":resolved.plan.base,"layers":resolved.plan.layers,"restore_untouched_base":resolved.plan.restore_untouched_base,"tints":worker.tints}
	var key := JSON.stringify(recipe,"",true)
	if _cache.has(key):
		_cache_order.erase(key)
		_cache_order.append(key)
	else:
		var composed: Dictionary = worker.compose_image(resolved.plan)
		if not composed.get("ok",false): return composed
		var mip_image: Image = composed.image.duplicate()
		mip_image.generate_mipmaps()
		_cache[key] = {"image":composed.image,"texture":ImageTexture.create_from_image(mip_image)}
		_cache_order.append(key)
		_builds += 1
		while _cache_order.size() > CACHE_LIMIT: _cache.erase(_cache_order.pop_front())
	return {"ok":true,"plan":resolved.plan,"image":_cache[key].image.duplicate(),"texture":_cache[key].texture,"cache_key":key}

static func diagnostics_text(diagnostics: Dictionary) -> String:
	var lines := PackedStringArray(["VISUAL MAPPING · EXPERIMENTAL"])
	for note in diagnostics.get("notes",[]): lines.append("• "+str(note))
	for issue: Dictionary in diagnostics.get("issues",[]):
		lines.append("• OMITTED %s · %s · UID %s: %s" % [issue.get("slot",""),issue.get("definition",issue.get("definition_id","")),issue.get("uid",""),issue.get("reason","")])
	return "\n".join(lines)

func cache_diagnostics() -> Dictionary:
	return {"limit":CACHE_LIMIT,"composites":_cache.size(),"builds":_builds,"recipes":_cache_order.duplicate(),"sources":resolver._images.size()}

func _armor(unit: Dictionary, catalog: Dictionary, detached: Dictionary, signature: Dictionary, issues: Array) -> Dictionary:
	for source in unit.get("armor_parts",[]):
		if not source is Dictionary: continue
		var slot := str(source.get("group",""))+"/"+str(source.get("layer",""))
		if signature.has(slot): continue # Same first-physical-slot policy as BB2.
		var definition := str(source.get("definition",""))
		var mapped: String = BODY.get(definition,"") if slot.begins_with("body/") else HEAD.get(definition,"") if slot == "head/shell" else ""
		var entry := _record(slot,definition,source,catalog,mapped)
		signature[slot] = entry
		if not _admit(entry,issues): continue
		if slot == "head/shell": detached.slots.head = {"uid":entry.item,"definition_id":mapped}
	var owner := {}
	for slot in ["body/outer","body/mail","body/base"]:
		if signature.get(slot,{}).get("visible",false):
			owner = signature[slot]; break
	if owner.is_empty(): return owner
	for slot in ["body/outer","body/mail","body/base"]:
		if not signature.has(slot): continue
		var entry: Dictionary = signature[slot]
		entry["owns_lower_body"] = slot == owner.slot
		entry["owns_gloves"] = slot == owner.slot
		if slot != owner.slot and entry.visible:
			entry.visible = false; entry["suppressed_by"] = owner.slot
			entry.visibility_reason = "Inner protection retained; covered by complete "+str(owner.definition)+" outfit."
	detached.slots.body = {"uid":owner.item,"definition_id":owner.donor_definition}
	for support in ["hands","feet"]:
		var donor: String
		if support == "hands": donor = "sword_gloves" if owner.definition in ["linen","red_gambeson"] else "hm_trial_v1:gloves-04-mail-gloves"
		else: donor = "light_boots" if owner.definition in ["linen","red_gambeson"] else "hm_trial_v1:footwear-04-reinforced-boots"
		var entry: Dictionary = owner.duplicate(true)
		entry.merge({"slot":"outfit/"+support,"support_for":owner.slot,"donor_definition":donor,"asset":donor,"art_family":donor,"proxy":false,"fallback":false,"fallback_reason":"","visibility_reason":"Outfit-owned "+support+" support, not a separate physical item or protection slot."},true)
		signature[entry.slot] = entry
		# Resolver-only unique token; signature retains the ACTUAL owner's UID.
		detached.slots[support] = {"uid":"\u001foutfit:"+support+":"+str(owner.item),"definition_id":donor}
	return owner

func _record(slot: String, definition: String, source: Dictionary, catalog: Dictionary, mapped: String) -> Dictionary:
	var maximum := int(source.get("maximum",catalog.get(definition,{}).get("durability",0)))
	var condition := int(source.get("condition",maximum))
	return {"slot":slot,"definition":definition,"item":str(source.get("item",source.get("id",""))),"condition":condition,"maximum":maximum,
		"broken":maximum > 0 and condition <= 0,"donor_definition":mapped,"asset":mapped,"art_family":mapped,"painted":not mapped.is_empty(),"visible":not mapped.is_empty(),
		"proxy":PROXY_NOTES.has(definition),"fallback":PROXY_NOTES.has(definition) or mapped.is_empty(),"fallback_reason":PROXY_NOTES.get(definition,""),"visibility_reason":""}

func _admit(entry: Dictionary, issues: Array) -> bool:
	var reason := ""
	if entry.donor_definition.is_empty(): reason = "No mapped donor art for actual BB2 definition."
	elif entry.item.is_empty(): reason = "Actual physical item UID missing or stale; no cosmetic identity invented."
	if reason.is_empty(): return true
	entry.visible = false; entry.painted = false; entry.visibility_reason = reason
	issues.append({"slot":entry.slot,"uid":entry.item,"definition":entry.definition,"reason":reason})
	return false
