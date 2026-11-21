extends RefCounted
## Fitted ink only. The caller retains the displayed contact texture, flip,
## foot registration and lifetime. No board, actor, or equipment changes.
const Actors = preload("res://engraved_people/actors.gd")
const SIZE := Vector2i(480, 464)
const FOOT := Vector2i(240, 411)
const ENVELOPE := Rect2i(88, 0, 304, 413)
const HOLD_ENVELOPE := Rect2i(90, 0, 300, 413)
# Compact payloads leave two lateral pixels for any below-sole boot AA.
const COMPACT_GEAR := Rect2i(91, 0, 298, 411)
const CACHE_LIMIT := 8
const RingboundMaul = preload("res://engraved_people/ringbound_maul.gd")
const FIELDS := ["stance", "body", "head", "cloak", "belt", "hands", "feet", "weapon",
	"shield", "head_wear", "body_wear", "shield_wear"]
const HIP := Vector2(240, 253)
const NECK := Vector2(242, 139)
# From the fitted idle plate, in original canvas coordinates. The first beat
# holds both boots. The near knee and the head are separately keyed at settle.
const BODY := [ # pelv., chest roll, head roll
	[Vector2(234, 271), 11.0, 7.0], [Vector2(217, 317), 34.0, 27.0],
	[Vector2(184, 345), 70.0, 62.0], [Vector2(177, 349), 81.0, 103.0],
]
const NEAR_LEG := [Vector2(217, 271), Vector2(207, 332), Vector2(195, 389)]
const FAR_LEG := [Vector2(266, 270), Vector2(282, 333), Vector2(285, 389)]
const NEAR_LEG_KEYS := [ # knee, ankle, foot turn
	[Vector2(218, 341), Vector2(195, 389), 0.0],
	[Vector2(220, 373), Vector2(169, 386), -25.0],
	[Vector2(136, 376), Vector2(113, 387), -38.0],
	[Vector2(117, 371), Vector2(141, 388), -9.0],
]
const FAR_LEG_KEYS := [
	[Vector2(284, 345), Vector2(285, 389), 0.0],
	[Vector2(279, 365), Vector2(262, 386), -9.0],
	[Vector2(221, 378), Vector2(169, 382), -25.0],
	[Vector2(221, 383), Vector2(163, 383), -51.0],
]
const NEAR_GRIP := [Vector2(206, 162), Vector2(194, 198), Vector2(169, 216)]
const FAR_SHIELD := [Vector2(283, 161), Vector2(291, 196), Vector2(316, 226)]
const NEAR_FREE := [Vector2(199, 161), Vector2(180, 198), Vector2(178, 242)]
const FAR_FREE := [Vector2(285, 157), Vector2(301, 197), Vector2(306, 242)]
const FAR_BOW := [Vector2(285, 157), Vector2(308, 197), Vector2(315, 234)]
const HAFT_REAR := [Vector2(188, 160), Vector2(177, 200), Vector2(192, 222)]
const HAFT_LEAD := [Vector2(278, 161), Vector2(290, 192), Vector2(308, 213)]
const NEAR_SWING := [ # elbow, wrist, wrist+weapon turn
	[Vector2(191, 218), Vector2(164, 237), 15.0],
	[Vector2(203, 278), Vector2(177, 297), 12.0],
	[Vector2(245, 318), Vector2(254, 348), -47.0],
	[Vector2(231, 342), Vector2(252, 369), -55.0],
]
const SHIELD_CATCH := [
	[Vector2(308, 233), Vector2(333, 258), 5.0],
	[Vector2(316, 307), Vector2(333, 333), 24.0],
	[Vector2(307, 355), Vector2(327, 357), 65.0],
	[Vector2(251, 365), Vector2(280, 359), 80.0],
]
const NEAR_CATCH := [
	[Vector2(188, 218), Vector2(187, 263), 2.0],
	[Vector2(215, 272), Vector2(236, 312), -14.0],
	[Vector2(268, 328), Vector2(276, 379), -15.0],
	[Vector2(232, 340), Vector2(272, 375), -41.0],
]
const FAR_CATCH := [
	[Vector2(305, 222), Vector2(313, 263), 3.0],
	[Vector2(313, 292), Vector2(322, 330), -11.0],
	[Vector2(305, 352), Vector2(323, 379), -25.0],
	[Vector2(276, 379), Vector2(301, 382), -38.0],
]
const BOW_SLUMP := [
	[Vector2(305, 220), Vector2(321, 252), 9.0],
	[Vector2(306, 293), Vector2(284, 322), 30.0],
	[Vector2(276, 365), Vector2(231, 362), 67.0],
	[Vector2(246, 374), Vector2(231, 349), 82.0],
]
const HAFT_SLUMP := [ # paired hand rig; project along the real shaft axis
	[Vector2(236, 239), 8.0, 0.69, Vector2(176, 216), Vector2(300, 216)],
	[Vector2(235, 303), 6.0, 0.70, Vector2(206, 268), Vector2(307, 284)],
	[Vector2(235, 361), 2.0, 0.68, Vector2(218, 322), Vector2(295, 351)],
	[Vector2(234, 376), 10.0, 0.67, Vector2(229, 334), Vector2(292, 368)],
]
static var _cache: Dictionary = {}

## Exactly four source-facing textures or none. The cached Array itself stays
## private so a caller cannot remove/reorder poses for another actor.
static func frames(recipe: Dictionary) -> Array[Texture2D]:
	var approved := _frame_set(recipe)
	if not approved.is_empty():
		return approved
	var extension := _extension_lane(recipe)
	if not extension.is_empty():
		var extended := _frame_set(recipe, extension)
		if not extended.is_empty():
			return extended
	# Refit only a declined, known rig. Never reinterpret a successful pose.
	if not extension.is_empty() or _admitted(recipe):
		return _frame_set(recipe, extension, true)
	return approved

static func _frame_set(recipe: Dictionary, extension := "", compact := false) -> Array[Texture2D]:
	var none: Array[Texture2D] = []
	if not (_admitted(recipe) if extension.is_empty() else _recipe_valid(recipe)) or not Actors._ready_sheet():
		return none
	var paint := []
	for field: String in FIELDS + ["face", "under_body", "under_wear", "ammo", "ammo_fill"]:
		paint.append(recipe.get(field))
	# Both physical mauls share the same part and arm rig but not the same carry ink.
	if RingboundMaul.matches(recipe):paint.append("ringbound_iron")
	var key := JSON.stringify(paint if extension.is_empty() else [extension, paint, recipe.get("seated_bolt", false)])
	if compact:
		key = "compact/" + key
	if _cache.has(key):
		return _cache[key].duplicate()
	var source := _source_layers(recipe, extension)
	if source.is_empty():
		_remember(key, none)
		return none
	if compact:
		source.compact = true
	var images: Array[Image] = []
	var seen: Array[int] = []
	for i in BODY.size():
		var parts := _pose(source, i)
		var im := _composite(parts, i)
		if im == null or ((compact or not extension.is_empty()) and not _extension_ink_fits(im.get_used_rect())):
			_remember(key, none)
			return none
		var mark := hash(im.get_data())
		if mark in seen:
			_remember(key, none)
			return none
		seen.append(mark)
		images.append(im)
	var built: Array[Texture2D] = []
	for i in images.size():
		var im := images[i]
		var ink := im.get_used_rect()
		im.generate_mipmaps()
		var tex := ImageTexture.create_from_image(im)
		tex.set_meta("human_collapse", {"frame": i, "ink": ink})
		built.append(tex)
	_remember(key, built)
	return built.duplicate()

static func _remember(key: String, value: Array[Texture2D]) -> void:
	if _cache.size() >= CACHE_LIMIT:
		_cache.erase(_cache.keys()[0])
	_cache[key] = value

static func _recipe_valid(r: Dictionary) -> bool:
	if not r.get("face") is int or r.face < 0 or r.face >= 8:
		return false
	for field: String in FIELDS:
		if not r.get(field) is String:
			return false
	for field: String in ["under_body", "under_wear", "ammo"]:
		if not r.get(field, "") is String:
			return false
	if not r.body.begins_with("torso/") or (r.head != "" and not r.head.begins_with("head/")):
		return false
	for field: String in ["cloak", "belt", "shield", "weapon", "ammo"]:
		var part: String = r.get(field, "")
		if part != "" and not part.begins_with(field + "/"):
			return false
	for field: String in ["body", "head", "shield", "under"]:
		var wear: String = r.get(field + "_wear", "")
		var owner: String = r.get("under_body" if field == "under" else field, "")
		if wear != "" and (owner == "" or wear != "wear/" + ("body" if field == "under" else field)):
			return false
	var under: String = r.get("under_body", "")
	if under != "" and (not under.begins_with("torso/") or r.body != "torso/breastplate"):
		return false
	var fill: Variant = r.get("ammo_fill", 0)
	if not fill is int or fill < 0 or fill > 4 or (fill > 0 and r.get("ammo", "") == ""):
		return false
	return true

static func _admitted(r: Dictionary) -> bool:
	if not _recipe_valid(r):
		return false
	if r.stance not in ["single", "haft"] or r.get("seated_bolt", false) != false:
		return false
	if r.stance == "haft" and (r.shield != "" or r.weapon == "weapon/t1-billhook"):
		# This billhook has an alternate idle atlas, not the shared source carry.
		return false
	if r.weapon in Actors.DATA.data.single_left_bows and r.shield != "":
		return false
	for binding: Dictionary in Actors.DATA.data.bindings.values():
		if binding.slot == "weapon" and binding.part == r.weapon and binding.stance == r.stance:
			return true
	return false

static func _source_layers(r: Dictionary, extension := "") -> Dictionary:
	var lane := "haft" if r.stance == "haft" else "shield" if r.shield != "" else "bow" if r.weapon in Actors.DATA.data.single_left_bows else "free"
	var layers := {"lane": lane, "armed": r.weapon != "" and lane != "bow"}
	var arm_prefix: String = "sleeve/%s/" % r.stance
	var hand_prefix: String = "hand/%s/" % r.stance
	var leg: String = "legs/%s/-1" % r.feet
	var ammo: String = r.get("ammo", "")
	var fill: int = r.get("ammo_fill", 0)
	var stack := "%s/%d" % [ammo, fill] if fill > 0 else ""
	var carry: Dictionary = {}
	var carry_sheet: Image
	if extension == "billhook":
		# Bind the exact row the mounted idle/stride renderer uses, including
		# the separate under-shaft palm islands and both cuff/glove variants.
		var idle_recipe := r.duplicate()
		idle_recipe.erase("billhook_hook")
		if not Actors.can_strike(idle_recipe):
			return {}
		carry = Actors._strike_cuts["billhook_overhead"].back()
		carry_sheet = Actors._strike_sheets["billhook_overhead"]
	var cuts: Array = [r.cloak, ammo, stack, leg] + Actors._cuts(r, false)
	for cut: String in cuts:
		if cut.is_empty():
			continue
		var group := "body"
		if cut == r.cloak:
			group = "cloak"
		elif cut in [ammo, stack]:
			group = "ammo"
		elif cut == leg:
			group = "legs"
		elif cut == r.head or cut == r.head_wear or cut.begins_with("face/"):
			group = "head"
		elif cut.begins_with("single/right/"):
			group = "near_sleeve" if "/sleeve/" in cut else "near_grip"
		elif cut.begins_with("single/left/"):
			group = "far_sleeve" if "/sleeve/" in cut else "far_grip"
		elif cut.begins_with("sleeve/haft/"):
			group = "near_sleeve" if cut.begins_with("sleeve/haft/back/") else "far_sleeve"
		elif cut.begins_with("hand/haft/"):
			group = "near_grip" if cut.begins_with("hand/haft/back") else "far_grip"
		elif cut.begins_with("palm/haft"):
			group = "palm"
		elif not extension.is_empty() and cut.begins_with(arm_prefix):
			group = "near_sleeve" if cut.begins_with(arm_prefix + "back/") else "far_sleeve"
		elif not extension.is_empty() and cut.begins_with(hand_prefix):
			group = "near_grip" if cut.begins_with(hand_prefix + "back") else "far_grip"
		elif cut in [r.shield, r.shield_wear]:
			group = "shield"
		elif cut == r.weapon:
			group = "weapon"
		var src: Dictionary
		if extension == "billhook" and group in ["near_sleeve", "far_sleeve", "near_grip", "far_grip", "palm", "weapon"]:
			src = _read_atlas_cut(cut, carry.get(cut), carry_sheet)
		else:
			if group == "weapon" and RingboundMaul.matches(r):
				src = RingboundMaul.collapse_source()
				if not src.is_empty():layers.weapon_fit_reference = _read_cut(cut)
			if src.is_empty():src = _read_cut(cut)
		if src.is_empty():
			return {}
		if not layers.has(group):
			layers[group] = []
		layers[group].append(src)
	if not layers.has_all(["legs", "near_sleeve", "far_sleeve", "near_grip", "far_grip", "head", "body"]):
		return {}
	if extension == "stock" and r.get("seated_bolt", false):
		var bolt := _stock_bolt(r.weapon)
		if bolt.is_empty():
			return {}
		layers.bolt = [bolt]
	layers.near_arm = HAFT_REAR if lane == "haft" else NEAR_GRIP if layers.armed else NEAR_FREE
	layers.far_arm = HAFT_LEAD if lane == "haft" else FAR_BOW if lane == "bow" else FAR_SHIELD if lane == "shield" else FAR_FREE
	if not extension.is_empty():
		layers.extension = extension
		if extension != "empty":
			var arms: Array = EXTENSION_ARMS[extension]
			layers.near_arm = arms[0]
			layers.far_arm = arms[1]
	layers.near_limb = _split_arm(layers.near_sleeve[0], layers.near_arm)
	layers.far_limb = _split_arm(layers.far_sleeve[0], layers.far_arm)
	layers.near_leg = _split_leg(layers.legs[0], true)
	layers.far_leg = _split_leg(layers.legs[0], false)
	return layers

static func _read_cut(key: String) -> Dictionary:
	return _read_atlas_cut(key, Actors.DATA.data.cuts.get(key), Actors._sheet)

static func _read_atlas_cut(key: String, p: Variant, sheet: Image) -> Dictionary:
	if not p is Array or p.size() != 6:
		return {}
	var tile := Rect2i(int(p[2]), int(p[3]), int(p[4]), int(p[5]))
	if sheet == null or not tile.has_area() or not Rect2i(Vector2i.ZERO, sheet.get_size()).encloses(tile):
		return {}
	var im: Image = sheet.get_region(tile)
	if not im.get_used_rect().has_area():
		return {}
	return {"key": key, "at": Vector2i(int(p[0]), int(p[1])), "im": im}

static func _roll(from: Vector2, to: Vector2, degrees: float) -> Transform2D:
	var xf := Transform2D(deg_to_rad(degrees), Vector2.ZERO)
	xf.origin = to - xf * from
	return xf

# Two independent bone maps, preserving thickness across their axes. The
# shorter longitudinal projection is flexion into the depth of the plate.
static func _bone(a: Vector2, b: Vector2, p: Vector2, q: Vector2) -> Transform2D:
	var in_axis := (b - a).normalized()
	var out_axis := (q - p).normalized()
	var ratio := p.distance_to(q) / a.distance_to(b)
	var from := Transform2D(in_axis, Vector2(-in_axis.y, in_axis.x), a)
	var to := Transform2D(out_axis * ratio, Vector2(-out_axis.y, out_axis.x), p)
	return to * from.affine_inverse()

# A small rounded overlap at a hinge avoids an open seam. The outer and
# inner pieces are still the actual source paint, not a filled silhouette.
static func _slice(src: Dictionary, side: int, pivot: Vector2, normal: Vector2, limit: float, below: bool) -> Dictionary:
	var original: Image = src.im
	var at: Vector2i = src.at
	var w := original.get_width()
	var h := original.get_height()
	var pixels := original.get_data()
	for y in h:
		for x in w:
			var global_x := at.x + x
			var i := (y * w + x) * 4 + 3
			if pixels[i] == 0:
				continue
			var v := Vector2(global_x + 0.5, at.y + y + 0.5) - pivot
			var d := v.dot(normal)
			var width := limit
			if limit > 0.0:
				width -= minf(5.0, absf(v.cross(normal)) * 0.23)
			if (side != 0 and (global_x < 239) != (side < 0)) or (d < -width if below else d > width):
				pixels[i] = 0
	var masked := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, pixels)
	var ink := masked.get_used_rect()
	if not ink.has_area():
		return {}
	return {"key": src.key, "at": at + ink.position, "im": masked.get_region(ink)}

static func _warp(src: Dictionary, xf: Transform2D) -> Dictionary:
	if src.is_empty():
		return {}
	var im: Image = src.im
	var at := Vector2(src.at)
	var w := im.get_width()
	var h := im.get_height()
	var bounds := Rect2(at, Vector2(w, h))
	if xf.x.is_equal_approx(Vector2.RIGHT) and xf.y.is_equal_approx(Vector2.DOWN) and xf.origin.is_equal_approx(xf.origin.round()):
		return {"key": src.key, "at": Vector2i((at + xf.origin).round()), "im": im}
	var a: Vector2 = xf * bounds.position
	var b: Vector2 = xf * Vector2(bounds.end.x, bounds.position.y)
	var c: Vector2 = xf * bounds.end
	var d: Vector2 = xf * Vector2(bounds.position.x, bounds.end.y)
	# Rasterize the *full* projected piece, including off-canvas ink. The
	# compositor refuses it if it crosses the envelope; it never crops it.
	var begin := Vector2i(a.min(b).min(c).min(d).floor())
	var end := Vector2i(a.max(b).max(c).max(d).ceil())
	var dim := end - begin
	if dim.x <= 0 or dim.y <= 0 or dim.x > SIZE.x * 2 or dim.y > SIZE.y * 2:
		return {}
	var inv := xf.affine_inverse()
	# Packed RGBA texels keep the gather to one read and one write. Integer
	# point samples preserve the engraved pigments; mipmaps handle downscale.
	var input := im.get_data().to_int32_array()
	var output := PackedInt32Array()
	output.resize(dim.x * dim.y)
	var du := inv.x.x
	var dv := inv.x.y
	var start := inv * (Vector2(begin) + Vector2(0.5, 0.5)) - at
	for y in dim.y:
		var u := start.x + inv.y.x * y
		var v := start.y + inv.y.y * y
		var j := y * dim.x
		for x in dim.x:
			var ix := floori(u)
			var iy := floori(v)
			if ix >= 0 and ix < w and iy >= 0 and iy < h:
				var rgba := input[iy * w + ix]
				if rgba >> 24 != 0:
					output[j] = rgba
			u += du
			v += dv
			j += 1
	return {"key": src.key, "at": begin, "im": Image.create_from_data(dim.x, dim.y, false, Image.FORMAT_RGBA8, output.to_byte_array())}

static func _pieces(rows: Array[Dictionary], source: Dictionary, group: String, xf: Transform2D) -> void:
	for src: Dictionary in source.get(group, []):
		_add(rows, group, src, xf)

static func _add(rows: Array[Dictionary], group: String, src: Dictionary, xf: Transform2D) -> void:
	var piece := _warp(src, xf)
	piece["group"] = group
	rows.append(piece)

static func _split_leg(src: Dictionary, near: bool) -> Array:
	var armature: Array = NEAR_LEG if near else FAR_LEG
	var knee: Vector2 = armature[1]
	var ankle: Vector2 = armature[2]
	var side := -1 if near else 1
	var thigh := _slice(src, side, knee, Vector2.DOWN, 7.0, false)
	var long_shin := _slice(src, side, knee, Vector2.DOWN, 7.0, true)
	var shin := _slice(long_shin, side, ankle, Vector2.DOWN, 4.0, false) if not long_shin.is_empty() else {}
	var foot := _slice(src, side, ankle, Vector2.DOWN, 4.0, true)
	return [thigh, shin, foot]

static func _leg(rows: Array[Dictionary], parts: Array, chest: Transform2D, near: bool, step: int) -> void:
	var armature: Array = NEAR_LEG if near else FAR_LEG
	var keys: Array = (NEAR_LEG_KEYS if near else FAR_LEG_KEYS)[step]
	var hip: Vector2 = armature[0]
	var knee: Vector2 = armature[1]
	var ankle: Vector2 = armature[2]
	var to_knee: Vector2 = keys[0]
	var to_ankle: Vector2 = keys[1]
	var group := "near_" if near else "far_"
	_add(rows, group + "thigh", parts[0], _bone(hip, knee, chest * hip, to_knee))
	_add(rows, group + "shin", parts[1], _bone(knee, ankle, to_knee, to_ankle))
	_add(rows, group + "boot", parts[2], _roll(ankle, to_ankle, keys[2]))

static func _split_arm(src: Dictionary, arm: Array) -> Array:
	var s: Vector2 = arm[0]
	var e: Vector2 = arm[1]
	var w: Vector2 = arm[2]
	var normal := ((e - s).normalized() + (w - e).normalized()).normalized()
	return [_slice(src, 0, e, normal, 8.0, false), _slice(src, 0, e, normal, 8.0, true)]

static func _sleeve(rows: Array[Dictionary], parts: Array, arm: Array, chest: Transform2D,
		elbow: Vector2, wrist: Vector2, group: String) -> void:
	var s: Vector2 = arm[0]
	var e: Vector2 = arm[1]
	var w: Vector2 = arm[2]
	_add(rows, group + "_upper", parts[0], _bone(s, e, chest * s, elbow))
	_add(rows, group + "_fore", parts[1], _bone(e, w, elbow, wrist))

static func _pose(source: Dictionary, i: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var compact: bool = source.get("compact", false)
	var body: Array = BODY[i]
	var hip: Vector2 = body[0]
	if (source.has("extension") or compact) and i >= 2:
		# The wide strapped hems retain their full ink above the planted sole.
		hip.y -= 8.0 if i == 2 else 5.0
	var chest := _roll(HIP, hip, body[1])
	var neck := chest * NECK + (Vector2(-7, 20) if i == 3 else Vector2.ZERO)
	var skull := _roll(NECK, neck, body[2])
	var drape := chest
	if i >= 2:
		# The shoulder seam stays put as the trailing fabric falls under it.
		var pin := Vector2(228, 153)
		drape = _roll(pin, chest * pin, body[1] - 14.0)
		drape.y *= 0.82 if i == 3 else 0.88
		drape.origin = chest * pin - drape.basis_xform(pin)
	var cloak: Array[Dictionary] = []
	_pieces(cloak, source, "cloak", drape)
	if compact and i > 0 and not cloak.is_empty() and not COMPACT_GEAR.encloses(_row_ink(cloak)):
		# Keep the shoulder sewn down. The long hem turns into depth as the
		# body folds; do not translate the whole mantle or crop its trailing ink.
		var pin := Vector2(228, 153)
		drape = _roll(pin, chest * pin, body[1] - 6.0)
		drape.y *= [1.0, 0.89, 0.83, 0.76][i]
		drape.origin = chest * pin - drape.basis_xform(pin)
		cloak.clear()
		_pieces(cloak, source, "cloak", drape)
	rows.append_array(cloak)
	_pieces(rows, source, "ammo", chest)
	_leg(rows, source.far_leg, chest, false, i)
	var raised_calves: Array[Dictionary] = []
	if i >= 2:
		_leg(raised_calves, source.near_leg, chest, true, i)
		# The thigh root stays inside the tunic. Only the shin and boot
		# curl over the hem in the last two cuts.
		rows.append(raised_calves.pop_front())
	else:
		_leg(rows, source.near_leg, chest, true, i)

	var bare: bool = source.get("extension", "") == "empty"
	if source.has("extension") and not bare:
		_pose_linked(rows, source, chest, skull, i, raised_calves)
		return rows
	var lane: String = source.lane
	if lane == "haft":
		_pose_haft(rows, source, chest, skull, i, raised_calves)
		return rows
	var near: Array = (NEAR_SWING if source.armed else NEAR_CATCH)[i]
	var far: Array = (SHIELD_CATCH if lane == "shield" else BOW_SLUMP if lane == "bow" else FAR_CATCH)[i]
	if bare and i >= 2:
		near = EMPTY_NEAR_LAND[i - 2]
		if lane == "free":
			far = EMPTY_FAR_LAND[i - 2]
	var near_xf := _roll(source.near_arm[2], near[1], near[2])
	var far_xf := _roll(source.far_arm[2], far[1], far[2])
	var payload: Array[Dictionary] = []
	var weapon_nudge := Vector2.ZERO
	if compact and (source.armed or lane == "bow"):
		if lane == "bow" and source.weapon[0].key == "weapon/t1-ash-longbow":
			# The extended limb tip needs an inward cant on the give, and a
			# diagonal landing rather than a horizontal sweep across the hex.
			far_xf = _roll(source.far_arm[2], far[1], far[2] + [-5.0, -5.0, 20.0, 9.0][i])
		_pieces(payload, source, "weapon", far_xf if lane == "bow" else near_xf)
		_pieces(payload, source, "far_grip" if lane == "bow" else "near_grip", far_xf if lane == "bow" else near_xf)
		weapon_nudge = _compact_nudge(payload)
	var shield_layers: Array[Dictionary] = []
	_pieces(shield_layers, source, "shield", far_xf)
	# The actual shield, wear and hand translate as one unit. No rim rescale.
	var nudge := _brace_rim(shield_layers, i, compact) if lane == "shield" else Vector2.ZERO
	far_xf.origin += nudge
	# The free bracing hand comes forward only at landing; the bow is still
	# caught by its own hand and keeps its original stave and string.
	var late_far := lane == "free" and i >= 2
	if not late_far:
		var move := weapon_nudge if lane == "bow" else nudge
		_sleeve(rows, source.far_limb, source.far_arm, chest, far[0] + move * 0.5, far[1] + move, "far")
		if compact and lane == "bow":
			rows.append_array(payload)
		else:
			if lane == "bow":
				_pieces(rows, source, "weapon", far_xf)
			_pieces(rows, source, "far_grip", far_xf)
	_pieces(rows, source, "body", chest)
	rows.append_array(raised_calves)
	if i >= 2:
		rows.append_array(shield_layers)
	if late_far:
		_sleeve(rows, source.far_limb, source.far_arm, chest, far[0], far[1], "far")
		_pieces(rows, source, "far_grip", far_xf)
	if bare or compact:
		_linked_head(rows, source, skull, i)
	else:
		_pieces(rows, source, "head", skull)
	var near_move := weapon_nudge if source.armed else Vector2.ZERO
	_sleeve(rows, source.near_limb, source.near_arm, chest, near[0] + near_move * 0.5, near[1] + near_move, "near")
	if compact and source.armed:
		rows.append_array(payload)
	else:
		if source.armed:
			_pieces(rows, source, "weapon", near_xf)
		_pieces(rows, source, "near_grip", near_xf)
	if i < 2:
		rows.append_array(shield_layers)
	return rows

static func _pose_haft(rows: Array[Dictionary], source: Dictionary, chest: Transform2D,
		skull: Transform2D, i: int, raised_calves: Array[Dictionary]) -> void:
	var key: Array = HAFT_SLUMP[i]
	var pivot := Vector2(257, 222)
	var along := Transform2D(deg_to_rad(-6.0), Vector2.ZERO)
	var short_axis := Transform2D(Vector2(float(key[2]), 0), Vector2.DOWN, Vector2.ZERO)
	var shaft := _roll(Vector2.ZERO, key[0], key[1]) * along * short_axis * along.inverse()
	shaft.origin -= shaft.basis_xform(pivot)
	var back: Vector2 = shaft * HAFT_REAR[2]
	var front: Vector2 = shaft * HAFT_LEAD[2]
	_sleeve(rows, source.near_limb, HAFT_REAR, chest, key[3], back, "near")
	_pieces(rows, source, "body", chest)
	rows.append_array(raised_calves)
	_pieces(rows, source, "head", skull)
	_sleeve(rows, source.far_limb, HAFT_LEAD, chest, key[4], front, "far")
	_pieces(rows, source, "palm", shaft)
	_pieces(rows, source, "weapon", shaft)
	_pieces(rows, source, "near_grip", shaft)
	_pieces(rows, source, "far_grip", shaft)

static func _brace_rim(layers: Array[Dictionary], i: int, compact := false) -> Vector2:
	var rim := Rect2i()
	for row: Dictionary in layers:
		if not row.has("im"):
			return Vector2.ZERO
		var ink: Rect2i = row.im.get_used_rect()
		ink.position += row.at
		rim = rim.merge(ink) if rim.has_area() else ink
	if not rim.has_area():
		return Vector2.ZERO
	var limit := COMPACT_GEAR if compact else HOLD_ENVELOPE if i == 3 else ENVELOPE
	var dx := 0
	if rim.end.x > limit.end.x:
		dx = limit.end.x - rim.end.x
	elif rim.position.x < limit.position.x:
		dx = limit.position.x - rim.position.x
	var dy := FOOT.y - rim.end.y if i >= 2 else 0
	# No unconstrained socket translation to force an exceptional fit.
	if absi(dx) > 20 or absi(dy) > 23:
		return Vector2.ZERO
	var shift := Vector2i(dx, dy)
	for row: Dictionary in layers:
		row.at += shift
	return Vector2(shift)

static func _row_ink(rows: Array[Dictionary]) -> Rect2i:
	var total := Rect2i()
	for row: Dictionary in rows:
		var piece: Image = row.get("im")
		if piece == null:
			return Rect2i()
		var ink := piece.get_used_rect()
		if not ink.has_area():
			return Rect2i()
		ink.position += row.at
		total = total.merge(ink) if total.has_area() else ink
	return total

static func _compact_nudge(rows: Array[Dictionary], footprint: Array[Dictionary] = []) -> Vector2:
	var ink := _row_ink(rows if footprint.is_empty() else footprint)
	var limit := COMPACT_GEAR
	if not ink.has_area() or ink.size.x > limit.size.x or ink.size.y > limit.size.y:
		return Vector2.ZERO
	var target := ink.position.clamp(limit.position, limit.end - ink.size)
	var shift := target - ink.position
	if absi(shift.x) > 24 or absi(shift.y) > 32:
		return Vector2.ZERO
	for row: Dictionary in rows:
		row.at += shift
	return Vector2(shift)

static func _composite(rows: Array[Dictionary], i: int) -> Image:
	var im := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	var envelope := HOLD_ENVELOPE if i == 3 else ENVELOPE
	for row: Dictionary in rows:
		var piece: Image = row.get("im")
		if piece == null:
			return null
		var ink := piece.get_used_rect()
		var dst := Vector2i(row.at) + ink.position
		if not ink.has_area() or not envelope.encloses(Rect2i(dst, ink.size)):
			return null
		im.blend_rect(piece, ink, dst)
	return im if im.get_used_rect().has_area() else null

# Additive fittings. These source sockets are in atlas destination (actor) pixels,
# before the body transform; near is the anatomical right / back grip.
const STOCK_BOLT_INK := "res://engraved_people/stock-bolt.png"
const EMPTY_NEAR_LAND := [ # separate forearm + relaxed hand cut, not a weapon fist
	[Vector2(250,334), Vector2(275,378), -15.0],
	[Vector2(225,344), Vector2(274,388), -63.0],
]
const EMPTY_FAR_LAND := [
	[Vector2(301,345), Vector2(323,376), -25.0],
	[Vector2(281,372), Vector2(306,386), -53.0],
]
const PAIRED_ARMS := [
	[Vector2(204,158), Vector2(229,198), Vector2(257,236)],
	[Vector2(286,154), Vector2(322,170), Vector2(312,202)],
]
const PAIRED_AXIS := [Vector2(286,228), -42.0]
const EXTENSION_ARMS := {
	"sword": [
		[Vector2(198,161), Vector2(203,221), Vector2(258,241)],
		[Vector2(266,154), Vector2(260,194), Vector2(295,211)],
	],
	"maul": PAIRED_ARMS, "old_sword": PAIRED_ARMS, "axe": PAIRED_ARMS,
	"stock": [
		[Vector2(198,159), Vector2(209,206), Vector2(239,231)],
		[Vector2(277,159), Vector2(279,205), Vector2(315,213)],
	],
	"billhook": [
		[Vector2(192,156), Vector2(150,190), Vector2(174,223)],
		[Vector2(275,155), Vector2(295,196), Vector2(251,218)],
	],
	"shaft": [HAFT_REAR, HAFT_LEAD],
}
const EXTENSION_AXES := {
	"sword": [Vector2(284,228), -42.0], # Between both actual hilt gloves.
	"maul": PAIRED_AXIS, "old_sword": PAIRED_AXIS, "axe": PAIRED_AXIS,
	"stock": [Vector2(283,219), -16.0],
	"billhook": [Vector2(236,223), -7.0],
	"shaft": [Vector2(220,222), -6.0],
}
const EXTENSION_KEYS := { # grip centre, turn, axial projection, near & far elbow
	"sword": [
		[Vector2(232,245), -13.0, 1.0, Vector2(185,225), Vector2(297,222)],
		[Vector2(216,308), -8.0, 1.0, Vector2(195,275), Vector2(274,285)],
		[Vector2(217,355), 33.0, 0.70, Vector2(218,323), Vector2(267,351)],
		[Vector2(211,370), 39.0, 0.69, Vector2(223,341), Vector2(267,372)],
	],
	"maul": [
		[Vector2(240,248), -2.0, 1.0, Vector2(198,218), Vector2(295,217)],
		[Vector2(234,310), 13.0, 1.0, Vector2(202,277), Vector2(286,276)],
		[Vector2(214,348), 54.0, 1.0, Vector2(213,315), Vector2(274,338)],
		[Vector2(217,351), 53.0, 1.0, Vector2(224,325), Vector2(278,352)],
	],
	"old_sword": [
		[Vector2(232,245), -13.0, 1.0, Vector2(188,219), Vector2(289,220)],
		[Vector2(216,308), -8.0, 1.0, Vector2(193,275), Vector2(270,280)],
		[Vector2(217,355), 33.0, 0.75, Vector2(213,323), Vector2(267,349)],
		[Vector2(211,380), 39.0, 0.75, Vector2(217,344), Vector2(269,367)],
	],
	"axe": [
		[Vector2(240,248), -5.0, 1.0, Vector2(193,217), Vector2(296,219)],
		[Vector2(223,310), 5.0, 1.0, Vector2(193,278), Vector2(282,280)],
		[Vector2(214,346), 34.0, 0.96, Vector2(218,315), Vector2(272,341)],
		[Vector2(217,344), 42.0, 0.96, Vector2(221,320), Vector2(275,348)],
	],
	"stock": [
		[Vector2(241,241), 10.0, 1.0, Vector2(191,224), Vector2(279,233)],
		[Vector2(239,300), 14.0, 1.0, Vector2(195,280), Vector2(286,292)],
		[Vector2(233,362), -18.0, 1.0, Vector2(201,351), Vector2(281,340)],
		[Vector2(237,367), -10.0, 1.0, Vector2(214,359), Vector2(278,360)],
	],
	"billhook": [
		[Vector2(182,246), 1.0, 0.69, Vector2(148,209), Vector2(249,213)],
		[Vector2(186,303), 0.0, 0.69, Vector2(153,264), Vector2(231,266)],
		[Vector2(183,369), 6.0, 0.66, Vector2(176,342), Vector2(235,342)],
		[Vector2(181,364), 8.0, 0.69, Vector2(185,340), Vector2(239,350)],
	],
	"shaft": [
		[Vector2(236,242), 8.0, 0.65, Vector2(183,217), Vector2(305,214)],
		[Vector2(238,302), 9.0, 0.65, Vector2(199,271), Vector2(306,279)],
		[Vector2(235,362), 7.0, 0.64, Vector2(214,318), Vector2(295,347)],
		[Vector2(235,376), 9.0, 0.64, Vector2(219,340), Vector2(288,356)],
	],
}

static func _extension_lane(r: Dictionary) -> String:
	var seated: Variant = r.get("seated_bolt", false)
	if not seated is bool:
		return ""
	if not seated and r.get("stance") == "single" and r.get("weapon") == "":
		return "empty"
	if r.get("shield") != "":
		return ""
	if Actors.StockBolt.fitted(r):
		return "stock"
	if seated:
		return ""
	if r.get("stance") == "sword_pair" and r.get("weapon") == "weapon/t1-two-handed-sword":
		return "sword"
	if r.get("stance") == "paired":
		match r.get("weapon"):
			"weapon/head-maul62": return "maul"
			"weapon/great": return "old_sword"
			"weapon/great-axe": return "axe"
	if r.get("stance") == "haft":
		if r.get("weapon") == "weapon/t1-billhook": return "billhook"
		# Only a known previously admitted shaft can try the shorter projection,
		# and only after the original path has already failed for this exact kit.
		if _admitted(r): return "shaft"
	return ""

static func _stock_bolt(part: String) -> Dictionary:
	var ink := Image.new()
	if ink.load_png_from_buffer(FileAccess.get_file_as_bytes(STOCK_BOLT_INK)) != OK:
		return {}
	ink.convert(Image.FORMAT_RGBA8)
	return {"key": STOCK_BOLT_INK, "at": Actors.StockBolt.TIPS[part] - Actors.StockBolt.LOCAL_TIP, "im": ink}

static func _extension_ink_fits(ink: Rect2i) -> bool:
	# The caller still checks against the actual tile. 151 px at 1.94/372
	# fits its 0.91-radius hex inset (0.78808), including below-sole AA.
	var extent := maxi(FOOT.x - ink.position.x, ink.end.x - FOOT.x)
	return extent + maxi(0, ink.end.y - FOOT.y) <= 151

static func _pose_linked(rows: Array[Dictionary], source: Dictionary, chest: Transform2D,
		skull: Transform2D, i: int, raised_calves: Array[Dictionary]) -> void:
	var rig: String = source.extension
	var key: Array = EXTENSION_KEYS[rig][i]
	var axis: Array = EXTENSION_AXES[rig]
	var basis := Transform2D(deg_to_rad(axis[1]), Vector2.ZERO)
	var short_axis := Transform2D(Vector2(float(key[2]), 0), Vector2.DOWN, Vector2.ZERO)
	var grip := _roll(Vector2.ZERO, key[0], key[1]) * basis * short_axis * basis.inverse()
	grip.origin -= grip.basis_xform(axis[0])
	var payload: Array[Dictionary] = []
	_pieces(payload, source, "palm", grip)
	_pieces(payload, source, "weapon", grip)
	_pieces(payload, source, "bolt", grip)
	_pieces(payload, source, "near_grip", grip)
	_pieces(payload, source, "far_grip", grip)
	var footprint: Array[Dictionary] = []
	if source.get("compact", false) and not source.get("weapon_fit_reference", {}).is_empty():
		# Alternate ink must not drive the inherited two-hand socket correction.
		footprint = payload.filter(func(row: Dictionary) -> bool: return row.group != "weapon")
		_add(footprint, "weapon", source.weapon_fit_reference, grip)
	var move := _compact_nudge(payload, footprint) if source.get("compact", false) else Vector2.ZERO
	_pieces(rows, source, "body", chest)
	rows.append_array(raised_calves)
	_sleeve(rows, source.near_limb, source.near_arm, chest, key[3] + move * 0.5, grip * source.near_arm[2] + move, "near")
	_sleeve(rows, source.far_limb, source.far_arm, chest, key[4] + move * 0.5, grip * source.far_arm[2] + move, "far")
	_linked_head(rows, source, skull, i)
	rows.append_array(payload)

static func _linked_head(rows: Array[Dictionary], source: Dictionary, xf: Transform2D, i: int) -> void:
	var head: Array[Dictionary] = []
	_pieces(head, source, "head", xf)
	if i == 3:
		# The rim and scuffs translate together; no helmet is resized or erased.
		var depth := FOOT.y
		for row: Dictionary in head:
			if not row.has("im"):
				continue
			var bottom: int = row.at.y + row.im.get_used_rect().end.y
			depth = maxi(depth, bottom)
		if depth - FOOT.y <= 16:
			for row: Dictionary in head:
				if row.has("at"):
					row.at.y -= depth - FOOT.y
	rows.append_array(head)
