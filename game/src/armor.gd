extends RefCounted
const Forge = preload("res://layer_forge/rules.gd")
const Named = preload("res://src/named_equipment.gd")
const NamedMail = preload("res://layer_forge/named_mail.gd")
## Assemblies own component references; each physical piece has one parent at most.
const LAYERS = {"body":["base","mail","outer","reinforce","cloth","cloak"],"head":["padding","mail","shell","face","decor"]}
const LABELS = {"base":"Base garment","mail":"Mail","outer":"Outer protection","reinforce":"Reinforcement","cloth":"Overclothes","cloak":"Cloak / mantle","padding":"Padding","shell":"Helmet shell","face":"Face protection","decor":"Decoration"}
const DAMAGE_ORDER = {"armor":["cloak","reinforce","outer","mail","cloth"],"padding":["base"],"helmet":["face","shell","mail","padding","decor"]}
const GROUPS = {"armor":"body","padding":"body","helmet":"head"}

static func empty_parts(group: String) -> Dictionary:
	var out = {}
	for layer in LAYERS[group]: out[layer] = ""
	return out

static func conflict(defs: Dictionary, group: String, catalog: Dictionary) -> String:
	if group != "head": return ""
	var shell: String = defs.get("shell","")
	for layer in ["face","decor"]:
		var d: Dictionary = catalog.get(defs.get(layer,""),{})
		if d.has("requires") and not shell in d.requires: return "%s needs %s. Remove it before changing the shell." % [d.name,", ".join(d.requires.map(func(id): return catalog[id].name))]
		if d.get("needs_shell",false) and shell.is_empty(): return "%s requires a helmet shell." % d.name
	return ""

static func valid_loadout(value: Variant, catalog: Dictionary) -> bool:
	if not value is Dictionary or value.size() != 2: return false
	for group in LAYERS:
		if not value.get(group) is Dictionary or value[group].size() != LAYERS[group].size(): return false
		for layer in LAYERS[group]:
			var id = value[group].get(layer)
			if not id is String: return false
			if not id.is_empty() and (not catalog.has(id) or catalog[id].get("group") != group or catalog[id].get("layer") != layer): return false
		if not conflict(value[group],group,catalog).is_empty(): return false
	return true

static func offer_loadout(p: Dictionary, varied: bool) -> Dictionary:
	var out = {"body":empty_parts("body"),"head":empty_parts("head")}
	out.body.base = p.loadout.under
	out.body["outer" if p.loadout.body in ["leather","jerkin"] else "mail"] = p.loadout.body
	out.head.shell = p.loadout.head
	if p.get("modest_kit",false):
		out.head.padding = "felt_cap" if p.loadout.head == "" else ""
		out.body.cloth = ["","sash","blue_tabard"][int(p.person_seed/7)%3]
		return out
	if varied:
		var n = p.person_seed
		# Independent identity-based choices: viewing an offer never advances any RNG.
		out.body.base = [p.loadout.under,"light_quilt","red_gambeson","green_jack"][n%4]
		out.body.cloth = ["","blue_tabard","red_surcoat","sash"][(n/7)%4]
		out.body.cloak = ["","","forest_cloak","red_cape","fur_mantle"][(n/19)%5]
		out.head.padding = ["","arming_cap","padded_hood"][(n/43)%3]
		out.head.mail = ["","","mail_coif","mail_curtain"][(n/73)%4]
		out.head.decor = ["","","blue_wrap"][(n/131)%3]
	return out

static func part_weight(item: Dictionary, catalog: Dictionary) -> int:
	return 0 if item.get("legacy_weight",false) else Named.weight(item,int(catalog[item.definition].get("weight",0)))

static func totals(parts: Array) -> Dictionary:
	var out = {"armor":0,"padding":0,"helmet":0,"max_armor":0,"max_padding":0,"max_helmet":0,"load":0}
	for part in parts:
		out[part.pool] += part.condition
		out["max_"+part.pool] += part.maximum
		out.load += part.weight
	return out

static func display_pool(stats: Dictionary, group: String) -> Dictionary:
	# One body protection value. Separate component subtotals remain for saves/repairs.
	if group == "body": return {"current":int(stats.armor+stats.padding),"maximum":int(stats.max_armor+stats.max_padding)}
	return {"current":int(stats.helmet),"maximum":int(stats.max_helmet)}

static func condition_state(current: int, maximum: int) -> String:
	if maximum == 0: return "NO ARMOUR"
	if current == 0: return "BROKEN"
	return "DAMAGED" if current < maximum else "FULL"

static func comparison(before: Dictionary, after: Dictionary, group: String) -> Dictionary:
	var a = display_pool(before,group); var b = display_pool(after,group)
	return {"before":a,"after":b,"now_change":b.current-a.current,"max_change":b.maximum-a.maximum}

static func tier(load_value: int) -> int:
	return load_value/12

static func explain_load(load_value: int) -> String:
	return "%d load: +%d attack/guard fatigue, -%d turn recovery, +%d movement fatigue/AP." % [load_value,tier(load_value),tier(load_value),load_value/24]

static func valid_battle_parts(value: Variant, catalog: Dictionary, claimed_mail: String = "") -> bool:
	if not value is Array or value.size() > Forge.LAYERS.body.size()+Forge.LAYERS.head.size(): return false
	var ids = {}; var slots = {}
	var forge_parts := 0
	var fitted := {"body":{},"head":{}}
	for p in value:
		if not p is Dictionary or not p.get("item") is String or not p.get("definition") is String or not catalog.has(p.definition): return false
		if not Named.valid(p,catalog): return false
		var d: Dictionary = Named.definition(p,catalog)
		if not d.has("group") or not d.has("layer"): return false
		var slot = d.group+"/"+d.layer
		if ids.has(p.item) or slots.has(slot): return false
		if Forge.is_layer(p.definition,catalog):
			if p.has("named") and not NamedMail.valid_projection(p,catalog,claimed_mail): return false
			if not d.layer in Forge.LAYERS.get(d.group,[]): return false
			forge_parts += 1
			fitted[d.group][d.layer] = p.definition
		ids[p.item] = true; slots[slot] = true
		var pool = "helmet" if d.group == "head" else ("padding" if d.layer == "base" else "armor")
		if p.get("pool") != pool or p.get("group") != d.group or p.get("layer") != d.layer: return false
		for field in ["condition","maximum","weight"]:
			if not p.get(field) is int or p[field] < 0: return false
		if p.has("named") and p.weight != int(d.get("weight",0)): return false
		if p.maximum != d.durability or p.condition > p.maximum or not p.weight in [0,int(d.get("weight",0))]: return false
	if forge_parts == 0: return value.size() <= 11  # Legacy rules and ceiling unchanged.
	return forge_parts == value.size() and Forge.conflict(fitted.body,"body").is_empty() and Forge.conflict(fitted.head,"head").is_empty()

static func damage_parts(u: Dictionary, pool: String, damage: int) -> void:
	var order: Array = DAMAGE_ORDER[pool].duplicate()
	if u.get("hollow_systems",false) and pool == "armor": order.append_array(["hands","feet","belt"])
	for layer in order:
		for p in u.armor_parts:
			if p.pool != pool or p.layer != layer: continue
			var loss = mini(damage,p.condition)
			p.condition -= loss; damage -= loss
			if damage <= 0: return
	# Keep established wear priority. New Forge pieces in other positions can
	# still own protection, so spend any remaining wear on them in rail order.
	if damage <= 0: return
	var group: String = GROUPS[pool]
	for layer: String in Forge.LAYERS[group]:
		if layer in order: continue
		for p in u.armor_parts:
			if p.pool != pool or p.layer != layer or p.get("group","") != group: continue
			if not str(p.get("definition","")).begins_with("forge:"): continue
			var loss = mini(damage,p.condition)
			p.condition -= loss; damage -= loss
			if damage <= 0: return

static func damage_body(u: Dictionary, damage: int) -> Dictionary:
	# Resolve the hit once against the sum; distribute that wear outside-in.
	# The base garment has no additional absorption stage.
	var outer_loss = mini(damage,int(u.armor))
	var base_loss = mini(damage-outer_loss,int(u.padding))
	u.armor -= outer_loss
	u.padding -= base_loss
	damage_parts(u,"armor",outer_loss)
	damage_parts(u,"padding",base_loss)
	return {"armor":outer_loss,"padding":base_loss}
