extends RefCounted
## Short-lived observations of actual movement, never a link to a living party.
const VERSION = 1
const LIFE = 80 # Four game hours; each world step is three minutes.
const FRESH = 20
const FAINT = 50
const FRESH_RANGE = 224.0 # Observation only, in world units, not party sight.
const FRESH_SCOUT_RANGE = 256.0
const MARK_MARGIN = 16.0 # Bounds the existing boot ink, selection ring and click rect.
const SPACING = 12000 # Twelve world units, accumulated as millimetres.
const MAX_MARKS = 512
const SCOUT_PACE = 0.70
const SEARCH_TICKS = 5 # Fifteen minutes; paused toggling cannot grant free information.
const DIRECTIONS = ["east","southeast","south","southwest","west","northwest","north","northeast"]
const SIZES = ["a few people (1–3)","several people (4–6)","a large group (7 or more)"]
var enabled = false
var scouting = false
var focus = 0
var clock = 0
var next_id = 1
var marks: Dictionary = {}
var cursors: Dictionary = {}

func setup(active: bool) -> void:
	enabled = active; scouting = false; focus = 0; clock = 0; next_id = 1; marks.clear(); cursors.clear()

func advance(ow, observing: bool = true) -> void:
	if not enabled: return
	clock += 1
	focus = mini(SEARCH_TICKS,focus+1) if scouting and observing else 0
	for id in marks.keys():
		if clock-marks[id].born >= LIFE: marks.erase(id)
	for id in cursors.keys():
		if not ow.scouts.has(id) or ow.scouts[id].defeated or clock-cursors[id].last >= LIFE: cursors.erase(id)

func record(ow, id: String, before: Vector2, after: Vector2, count: int) -> void:
	if not enabled or count <= 0 or before.distance_to(after) < 0.001: return
	if not ow.valid_point(before) or not ow.valid_point(after): return
	# Position fixtures, spawns or future teleport mechanics cannot draw a false trail.
	if before.distance_to(after) > 4.0: cursors.erase(id); return
	var previous: Dictionary = cursors.get(id,{"position":before,"distance":0,"last":clock})
	var distance: int = previous.distance if previous.position.distance_to(before) < 0.01 else 0
	distance += roundi(before.distance_to(after)*1000)
	if distance >= SPACING:
		var key = "track_%07d" % next_id; next_id += 1
		marks[key] = {"position":after,"heading":posmod(roundi((after-before).angle()/(PI/4)),8),"group":0 if count <= 3 else 1 if count <= 6 else 2,"born":clock}
		distance %= SPACING
		while marks.size() > MAX_MARKS: marks.erase(marks.keys()[0])
	cursors[id] = {"position":after,"distance":distance,"last":clock}

func opacity(mark: Dictionary) -> float:
	return clampf(0.90*pow(1.0-float(clock-mark.born)/LIFE,1.35),0.0,0.90)

func visible(c, mark: Dictionary) -> bool:
	if not enabled or c.dungeons.active != "" or clock-mark.born >= LIFE: return false
	var ow = c.overworld
	if not ow.discovered(mark.position): return false
	var focused: bool = scouting and focus == SEARCH_TICKS
	var fade: float = 0.35+0.65*opacity(mark)/0.90
	var dark: bool = ow.hour < 6 or ow.hour >= 20
	var distance: float = ow.position.distance_to(mark.position)
	var radius: float = (72.0 if focused else 42.0)*fade
	if dark: radius *= 0.70
	if distance <= radius: return true # Keep the existing close inspection rule.
	var age: int = clock-mark.born
	if age < 0 or age >= FRESH: return false
	var extended_radius: float = (FRESH_SCOUT_RANGE if focused else FRESH_RANGE)*fade
	if dark: extended_radius *= 0.70
	if distance > extended_radius: return false
	# Marks and their hit areas sit above fog. Extend only if their entire
	# footprint is on explored ground, not just the centre cell.
	var lo: Vector2i = ow.cell(mark.position-Vector2.ONE*MARK_MARGIN)
	var hi: Vector2i = ow.cell(mark.position+Vector2.ONE*MARK_MARGIN)
	var bounds := Rect2i(Vector2i.ZERO,ow.SIZE)
	if not bounds.has_point(lo) or not bounds.has_point(hi): return false
	for y in range(lo.y,hi.y+1):
		for x in range(lo.x,hi.x+1):
			if not ow.discovered(ow.cell_point(Vector2i(x,y))): return false
	return true

func freshness(mark: Dictionary) -> String:
	var age: int = clock-mark.born
	return "Fresh · under an hour" if age < FRESH else "Fading · a few hours old" if age < FAINT else "Faint · almost gone"

func size_hint(mark: Dictionary) -> String:
	return "Too faded to judge the group size." if clock-mark.born >= FAINT else "Looks like "+SIZES[mark.group]+"."

func toggle(c) -> bool:
	if not enabled or c.phase != "camp" or c.over() or not c.encounter.is_empty() or c.dungeons.active != "": return false
	scouting = not scouting; focus = 0
	c.note("Scouting: move at 70% pace. After fifteen minutes, notice prints farther away. They still fade within four hours." if scouting else "Normal travel pace. Watch for fresh footprints close to the company.")
	return true

func snapshot() -> Dictionary:
	var result = {"version":VERSION,"clock":clock,"next_id":next_id,"scouting":scouting,"focus":focus,"marks":marks.duplicate(true),"cursors":cursors.duplicate(true)}
	for row in result.marks.values()+result.cursors.values(): row.position = [row.position.x,row.position.y]
	return result

func restore(raw: Variant, ow, world) -> bool:
	if not raw is Dictionary or raw.size() != 7 or raw.get("version") != VERSION or not raw.get("scouting") is bool: return false
	if not raw.get("focus") is int or raw.focus < 0 or raw.focus > SEARCH_TICKS or not raw.scouting and raw.focus != 0: return false
	if not raw.get("clock") is int or raw.clock < 0 or raw.clock > world.day*480: return false
	if not raw.get("next_id") is int or raw.next_id < 1 or raw.next_id > 1+raw.clock*maxi(1,ow.scouts.size()): return false
	if not raw.get("marks") is Dictionary or raw.marks.size() > MAX_MARKS or not raw.get("cursors") is Dictionary or raw.cursors.size() > ow.scouts.size(): return false
	for id in raw.marks:
		if not id is String or not id.begins_with("track_") or not id.trim_prefix("track_").is_valid_int(): return false
		var number = int(id.trim_prefix("track_"))
		if number < 1 or number >= raw.next_id or id != "track_%07d" % number: return false
		var row = raw.marks[id]
		if not row is Dictionary or row.size() != 4 or not ow.valid_xy(row.get("position")): return false
		if not row.get("born") is int or row.born < 1 or row.born > raw.clock or raw.clock-row.born >= LIFE: return false
		if not row.get("heading") is int or row.heading not in range(8) or not row.get("group") is int or row.group not in range(3): return false
	for id in raw.cursors:
		if not ow.scouts.has(id): return false
		var row = raw.cursors[id]
		if not row is Dictionary or row.size() != 3 or not ow.valid_xy(row.get("position")): return false
		if not row.get("last") is int or row.last < 1 or row.last > raw.clock or raw.clock-row.last >= LIFE: return false
		if not row.get("distance") is int or row.distance < 0 or row.distance >= SPACING: return false
	enabled = true; scouting = raw.scouting; focus = raw.focus; clock = raw.clock; next_id = raw.next_id
	marks = raw.marks.duplicate(true); cursors = raw.cursors.duplicate(true)
	for row in marks.values()+cursors.values(): row.position = Vector2(row.position[0],row.position[1])
	return true
