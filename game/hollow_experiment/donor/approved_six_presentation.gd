extends RefCounted
## SOURCE ONLY: execution/parser/native/adoption UNRUN in this delivery.
## Detached read-only presentation; both Board and paperdoll consume this same plan/image.
const FULL = ["gloves-02-grip-gloves", "gloves-04-mail-gloves"]
const GLOVES = ["gloves-01-linen-handwraps", "gloves-02-grip-gloves", "gloves-03-draw-gloves", "gloves-04-mail-gloves"]
var _model: Dictionary = {}
var _pack: String = ""
var _files: Dictionary = {}
var _images: Dictionary = {} # immutable content identity only; never people/UIDs/eligibility

func configure(model_path: String, pack_root: String, expected_model_sha256: String) -> Dictionary:
	_model = {}; _files = {}; _images = {}; _pack = ""
	if expected_model_sha256.length() != 64 or FileAccess.get_sha256(model_path) != expected_model_sha256:
		return _fail("NORMALIZED_HASH_MISMATCH")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(model_path))
	if not parsed is Dictionary or parsed.get("schema") != "hm-normalized-presentation-v1":
		return _fail("UNKNOWN_NORMALIZED_SCHEMA")
	var manifest_path = pack_root.path_join("MANIFEST.json")
	if FileAccess.get_sha256(manifest_path) != parsed.get("source_manifest_sha256"):
		return _fail("SOURCE_MANIFEST_HASH_MISMATCH")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary or not manifest.get("files") is Dictionary:
		return _fail("MANIFEST_REQUIRED")
	_pack = pack_root; _files = manifest["files"].duplicate(true); _model = parsed.duplicate(true)
	return {"ok": true}

func _fail(reason: String) -> Dictionary:
	return {"ok": false, "error": reason}

func _intersects(a, b) -> bool:
	for k in a:
		if k in b: return true
	return false

func _enabled(layer: Dictionary, keys: Array, glove) -> bool:
	for k in layer["all"]:
		if k not in keys: return false
	return not _intersects(layer["none"], keys) and not (layer["unless_full"] and glove in FULL)

func _glove(keys: Array):
	for k in keys:
		if k in GLOVES: return k
	return null

func resolve(detached: Dictionary) -> Dictionary:
	if _model.is_empty(): return _fail("NOT_CONFIGURED")
	if not detached.get("person_id") is String or detached["person_id"].is_empty(): return _fail("PERSON_ID_REQUIRED")
	var app = detached.get("appearance")
	if not app is String or not _model["appearances"].has(app): return _fail("UNKNOWN_APPEARANCE")
	var a: Dictionary = _model["appearances"][app]
	var slots = detached.get("slots", {})
	if not slots is Dictionary: return _fail("SLOTS_REQUIRED")
	var chosen: Array = []; var issues: Array = []; var seen: Array = []; var occupied: Array = []
	var slot_names: Array = slots.keys(); slot_names.sort()
	for slot in slot_names:
		var v = slots[slot]
		if v == null: continue
		if not v is Dictionary or not v.get("uid") is String or v["uid"].is_empty(): return _fail("OPAQUE_UID_REQUIRED")
		if v["uid"] in seen: return _fail("DUPLICATE_UID")
		seen.append(v["uid"])
		var did = v.get("definition_id")
		var issue = {"slot": slot, "uid": v["uid"], "definition_id": did}
		if not did is String or not _model["definitions"].has(did):
			issue["reason"] = "UNKNOWN_LITERAL_DEFINITION"; issues.append(issue); continue
		var de: Dictionary = _model["definitions"][did]; var hands = int(de["hands"])
		if (hands != 0 and slot not in ["mainhand", "offhand"]) or (hands == 0 and slot != de["slot"]): return _fail("WRONG_MECHANICAL_SLOT")
		if hands == 2 and (slot != "mainhand" or slots.get("offhand") != null): return _fail("TWOHAND_CONSUMES_BOTH")
		var default_hand = ("right" if slot == "mainhand" else "left") if hands == 1 else null
		var h = v.get("physical_hand", default_hand)
		if h not in [null, "left", "right"]: return _fail("UNKNOWN_PHYSICAL_HAND")
		if hands == 1 and h in occupied: return _fail("DUPLICATE_PHYSICAL_HAND")
		if hands == 1: occupied.append(h)
		var key = _model["bindings"][did]
		if key == null:
			issue["reason"] = "NO_EXACT_SOURCE_BINDING"; issues.append(issue); continue
		var token = ("1:" if hands != 0 else "0:") + (str(h) if h != null else "none")
		var route: Dictionary = a["routes"].get(key, {}).get(token, {"error": "NO_APPEARANCE_SOURCE"})
		if route.has("error"):
			issue["physical_hand"] = h; issue["reason"] = route["error"]; issues.append(issue); continue
		var selected = route.duplicate(true)
		selected.merge({"uid": v["uid"], "definition_id": did, "slot": slot, "key": key}, true); chosen.append(selected)
	var built: Dictionary = _medic(a, chosen) if a["mode"] == "medic" else _generic(a, chosen)
	if not built["ok"]: return built
	var frame: Dictionary = built["frame"]; var origin: Array = frame["base_origin"]; var size: Array = frame["canvas"]
	frame["world_bounds"] = [-origin[0], -origin[1], size[0] - origin[0], size[1] - origin[1]]
	var selected_public: Array = []
	for r in chosen:
		var item: Dictionary = {}
		for k in ["uid", "definition_id", "slot", "physical_hand", "key", "kind"]: item[k] = r[k]
		selected_public.append(item)
	var base: Dictionary = a["base"].duplicate(true); base["placement"] = origin.duplicate()
	return {"ok": true, "plan": {"base": base, "schema": "hm-detached-layer-plan-v1", "person_id": detached["person_id"], "appearance": app, "frame": frame, "layers": built["layers"], "selected": selected_public, "issues": issues, "restore_untouched_base": a["mode"] == "shieldbearer", "surface_contract": "SAME_PLAN_BOARD_AND_PAPERDOLL", "authority": "DERIVED_READ_ONLY_NOT_SAVED"}}

func _add(out: Array, layer: Dictionary, key: String, z = null, index = null, with_size: bool = false) -> void:
	var p: Dictionary = layer["payload"].duplicate(true)
	p["owner_art_key"] = key
	if z != null: p["z"] = z
	if index != null: p["index"] = index
	if with_size: p["_size"] = layer["size"]
	# Explicit ordinal makes equal-z source order independent of sort stability.
	p["_ordinal"] = out.size(); out.append(p)

func _generic(a: Dictionary, chosen: Array) -> Dictionary:
	var keys: Array = []; var allkeys: Array = []; var held: Dictionary = {}; var out: Array = []
	for r in chosen:
		allkeys.append(r["key"])
		if r["kind"] == "original": keys.append(r["key"])
		if r["physical_hand"] in ["left", "right"] and r["slot"] in ["mainhand", "offhand"]: held[r["physical_hand"]] = r
	var glove = _glove(allkeys); var ordered = chosen.duplicate()
	ordered.sort_custom(func(x, y): return x["key"] < y["key"])
	for r in ordered:
		var key: String = r["key"]; var rec: Dictionary = a["records"][key]
		if r["kind"] == "opposite":
			for i in range(r["layers"].size()):
				var l: Dictionary = r["layers"][i]
				if a["mode"] == "shieldbearer":
					if i == 0 or glove not in FULL: _add(out, l, key, null, null, true)
				elif _enabled(l, allkeys + ["opposite:" + key], glove): _add(out, l, key, null, null, true)
			continue
		for l in rec["layers"]:
			var z = null
			if key == glove:
				var h = l["hand"]
				if held.has(h) and held[h]["kind"] == "opposite": continue
				if a["mode"] == "occultist" and held.has(h):
					var v: Dictionary = held[h]; var ctx = a["records"][v["key"]]["contexts"].get(glove)
					if ctx != null and not ctx.is_empty():
						for part in ["rear", "front"]: _add(out, ctx[part], key, null, null, true)
						continue
					if v["key"].begins_with("offhands-"): z = 32
			if _enabled(l, keys, glove): _add(out, l, key, z, null, true)
	if glove != null:
		for r in held.values():
			if r["kind"] != "opposite": continue
			var gp = r["gloves"].get(glove)
			if gp == null: return _fail("MISSING_EXACT_GLOVE_CONTEXT")
			for part in ["rear", "front"]: _add(out, gp[part], glove, null, null, true)
	out.sort_custom(func(x, y): return x["z"] < y["z"] if x["z"] != y["z"] else x["_ordinal"] < y["_ordinal"])
	var frame: Dictionary = a["frame"].duplicate(true)
	for l in out:
		var size = l["_size"]; l.erase("_size"); l.erase("_ordinal")
		var origin = l.get("frame_origin_in_base", [0, 0])
		l["placement"] = ([0, 0] if size == frame["canvas"] else frame["base_origin"].duplicate()) if a["mode"] == "shieldbearer" else [origin[0] + frame["base_origin"][0], origin[1] + frame["base_origin"][1]]
	return {"ok": true, "layers": out, "frame": frame}

func _medic(a: Dictionary, chosen: Array) -> Dictionary:
	var p: Dictionary = a["medic"]; var keys: Array = []; var held: Dictionary = {}
	var legacy: bool = false; var has_instance: bool = false; var mixed: bool = false
	for r in chosen:
		keys.append(r["key"])
		if r["physical_hand"] in ["left", "right"]: held[r["physical_hand"]] = r
		if _model["definitions"][r["definition_id"]]["hands"] == 2 and r["key"] not in p["selection_frame_overrides"]: legacy = true
		has_instance = has_instance or r["instance"]; mixed = mixed or r["mixed"]
	var glove = _glove(keys); var upright: bool = _intersects(keys, p["selection_frame_overrides"])
	var instances: bool = not legacy or has_instance; var out: Array = []
	for r in chosen:
		var key: String = r["key"]; var rec: Dictionary = a["records"][key]
		if key == glove and (upright or instances or mixed):
			for h in ["right", "left"]:
				var original: Dictionary = rec["original_layers"][0 if h == "right" else 1]; var hv = held.get(h)
				if upright:
					if h == "right": _add(out, original, key, 80, 0)
					else:
						_add(out, p["glove_partitions"][key][h]["rear"], key, 50, 0)
						_add(out, p["glove_partitions"][key][h]["front"], key, 80, 0)
				elif hv == null: _add(out, original, key, 80 if h == "right" else 32, 0)
				else:
					var parts: Dictionary = hv["parts"].get(key, {}).get(h, {})
					if parts.is_empty() and h == "left" and hv["mixed"]:
						_add(out, p["glove_partitions"][key][h]["rear"], key, 50, 0)
						_add(out, p["glove_partitions"][key][h]["front"], key, 80, 0)
					elif parts.is_empty() and h == "right":
						for part in ["rear", "front"]: _add(out, p["glove_partitions"][key][h][part], key, 80, 0)
					elif parts.is_empty(): _add(out, original, key, 32, 0)
					else:
						for l in parts.values(): _add(out, l, key, null, 0)
			continue
		for i in range(r["layers"].size()):
			var l: Dictionary = r["layers"][i]
			if not _enabled(l, keys, glove): continue
			var raw: Dictionary = l["payload"]; var full: bool = glove in p["full_gloves_suppress_bare_foreground_in_approved_mixed_profile"]
			var skin: bool = raw.get("role") == "original_skin"; var hr: bool = rec["slot"] in ["mainhand", "offhand"]
			if full and ((upright and key in p["selection_frame_overrides"] and skin) or (not upright and (instances or mixed) and hr and (skin or (r["layers"].size() == 2 and i == 1)))): continue
			var z = raw["z"]
			for rule in p["conditional_z_overrides"]:
				if key == rule["record_key"] and i == rule["layer_index"] and _intersects(keys, rule["when_any_keys"]):
					if raw["path"] != rule["path"]: return _fail("DEPTH_PATH_MISMATCH")
					z = rule["z"]
			_add(out, l, key, z, i)
	out.sort_custom(func(x, y):
		for k in ["z", "owner_art_key", "index", "path", "_ordinal"]:
			if x[k] != y[k]: return x[k] < y[k]
		return false)
	var frame: Dictionary = a["frame"].duplicate(true)
	if upright:
		var uf: Dictionary = p["frames"]["upright"]; var shift: Array = uf["base_origin"]; frame.merge(uf, true)
		frame["foot_anchor"] = [a["frame"]["foot_anchor"][0] + shift[0], a["frame"]["foot_anchor"][1] + shift[1]]
		frame["body_ground_reference"] = [128 + shift[0], 320 + shift[1]]
	for l in out:
		l.erase("_ordinal"); l["placement"] = [0, 0] if l["path"] in p["asset_frame_overrides"] else frame["base_origin"].duplicate()
	return {"ok": true, "frame": frame, "layers": out}

func _image(layer: Dictionary) -> Dictionary:
	# Only manifest-bound content-addressed copied PNGs are ever opened.
	var rel = layer.get("path", ""); var digest = layer.get("sha256", "")
	if not rel is String or not digest is String or digest.length() != 64 or not digest.is_valid_hex_number(false) or rel != "blobs/" + digest + ".png": return _fail("UNSAFE_ASSET_PATH")
	if _files.get(rel) != digest: return _fail("ASSET_NOT_ADMITTED")
	var path = _pack.path_join(rel)
	# On-read verification remains mandatory even when content is cached.
	if FileAccess.get_sha256(path) != digest: return _fail("ASSET_HASH_MISMATCH")
	if not _images.has(digest):
		var image = Image.new()
		var error = image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		if error != OK or image.get_format() != Image.FORMAT_RGBA8: return _fail("NOT_RGBA")
		_images[digest] = image
	return {"ok": true, "image": _images[digest]}

func _v(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))

func compose_image(plan: Dictionary) -> Dictionary:
	if _model.is_empty(): return _fail("NOT_CONFIGURED")
	var size = _v(plan["frame"]["canvas"]); var source = _image(plan["base"])
	if not source["ok"]: return source
	var base = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	base.fill(Color(0, 0, 0, 0)); var raw: Image = source["image"]
	# Direct blit preserves hidden RGB of the exact empty base.
	base.blit_rect(raw, Rect2i(Vector2i.ZERO, raw.get_size()), _v(plan["base"]["placement"]))
	var layers: Array = plan["layers"]
	if layers.is_empty(): return {"ok": true, "image": base}
	var out: Image = base.duplicate(); var drawn: bool = layers[0]["z"] >= 0
	if not drawn: out.fill(Color(0, 0, 0, 0))
	var touched = PackedByteArray(); touched.resize(size.x * size.y); touched.fill(0)
	for l in layers:
		if not drawn and l["z"] >= 0:
			out.blend_rect(base, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO); drawn = true
		var loaded = _image(l)
		if not loaded["ok"]: return loaded
		var image: Image = loaded["image"]; var pos: Vector2i = _v(l["placement"])
		out.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), pos)
		if plan["restore_untouched_base"]:
			var bytes: PackedByteArray = image.get_data()
			for y in range(maxi(0, pos.y), mini(size.y, pos.y + image.get_height())):
				for x in range(maxi(0, pos.x), mini(size.x, pos.x + image.get_width())):
					if bytes[((y - pos.y) * image.get_width() + x - pos.x) * 4 + 3] != 0: touched[y * size.x + x] = 1
	if not drawn: out.blend_rect(base, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	if plan["restore_untouched_base"]:
		var result: PackedByteArray = out.get_data(); var original: PackedByteArray = base.get_data()
		for p in range(touched.size()):
			if touched[p] == 0:
				for channel in range(4): result[p * 4 + channel] = original[p * 4 + channel]
		out = Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, result)
	return {"ok": true, "image": out}

func present(detached: Dictionary) -> Dictionary:
	var resolved = resolve(detached)
	if not resolved["ok"]: return resolved
	var composed = compose_image(resolved["plan"])
	if not composed["ok"]: return composed
	# No current-person/UID/texture cache. Both callers receive the same source-native texture.
	return {"ok": true, "plan": resolved["plan"], "image": composed["image"], "texture": ImageTexture.create_from_image(composed["image"]), "foot_anchor": _v(resolved["plan"]["frame"]["foot_anchor"])}
