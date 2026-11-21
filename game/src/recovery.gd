extends RefCounted
## Hourly recovery; fractional time and tool offcuts persist across saves.
const POINTS_PER_TOOL := 12

static func fresh() -> Dictionary:
	return {"ticks":0,"tool_credit":0,"patients":{},"stored":[]}

static func patient(state: Dictionary, sid: int) -> Dictionary:
	var key = str(sid)
	if not state.patients.has(key): state.patients[key] = {"hours":0,"paid":false,"temple":false}
	return state.patients[key]

static func repair_items(c, sid: int) -> Array:
	var ids: Array = c.battle_parts(c.soldiers[sid]).map(func(p): return p.item)
	for slot in ["shield"]+c.Arsenal.CARRIED:
		var id: String = c.soldiers[sid].gear.get(slot,"")
		if c.item_def(id).get("slot") == "shield": ids.append(id)
	return ids.filter(func(id): return c.items[id].condition < c.item_def(id).durability)

static func _stored_queue(c) -> Array:
	return c.recovery.stored.filter(func(id): return c.items.has(id) and c.owner(id) < 0 and c.parent_kit(id).is_empty() and c.stored_repair_cost(id) > 0)

static func _stored_items(c, queue: Array) -> Array:
	var ids := []
	for id in queue:
		ids.append_array(c.kit_parts(id).values().filter(func(part): return part != "") if c.item_def(id).get("assembly",false) else [id])
	return ids

static func tools_needed(c) -> int:
	# Price the same queues as hourly recovery, not every item in the stash.
	var ids := _stored_items(c,_stored_queue(c))
	for s in c.soldiers:
		if s.alive: ids.append_array(repair_items(c,s.id))
	var missing := 0
	for id in ids: missing += maxi(0,int(c.item_def(id).durability)-int(c.items[id].condition))
	return ceili(float(maxi(0,missing-c.recovery.tool_credit))/POINTS_PER_TOOL)

static func point(c, ids: Array) -> bool:
	for id in ids:
		if not c.items.has(id) or c.items[id].condition >= c.item_def(id).durability: continue
		if c.recovery.tool_credit == 0:
			if c.tools <= 0: return false
			c.tools -= 1; c.recovery.tool_credit = POINTS_PER_TOOL
		c.items[id].condition += 1; c.recovery.tool_credit -= 1
		return true
	return false

static func step(c, ticks: int, resting: bool) -> void:
	c.recovery.ticks += ticks
	while c.recovery.ticks >= 20:
		c.recovery.ticks -= 20
		var repair_queues = []
		for s in c.soldiers:
			if not s.alive: continue
			repair_queues.append(repair_items(c,s.id))
			var p = patient(c.recovery,s.id)
			if c.food < c.alive_count(): continue
			s.hp = mini(c.max_hp(s),s.hp+(2 if resting else 1))
			if s.wound_days <= 0:
				p.hours = 0; p.paid = false; p.temple = false; continue
			if not p.paid:
				if c.medicine <= 0: continue
				c.medicine -= 1; p.paid = true
			p.hours += 2 if p.temple else 1
			if p.hours >= 24:
				p.hours = 0; p.paid = false; s.wound_days -= 1
				if s.wound_days == 0:
					p.temple = false
					c.Progression.record(s,"healed_%d" % c.day,c.day,"healed","Deep wound healed over time. Permanent scars remain.")
		# Each living mercenary repairs their worn kit. Stores share one queue.
		c.recovery.stored = _stored_queue(c)
		repair_queues.append(_stored_items(c,c.recovery.stored))
		for pass_index in (6 if resting else 4):
			for ids in repair_queues: point(c,ids)

static func status(c, sid: int) -> String:
	var s: Dictionary = c.soldiers[sid]
	if not s.alive: return "Fallen"
	var rest: bool = c.overworld.rest_left > 0
	var lines = []
	if s.hp < c.max_hp(s): lines.append("HP: %dh" % ceili(float(c.max_hp(s)-s.hp)/(2 if rest else 1)) if c.food >= c.alive_count() else "HP: needs food")
	var missing = 0
	for id in repair_items(c,sid): missing += c.item_def(id).durability-c.items[id].condition
	if missing > 0: lines.append("Armour: ~%dh%s" % [ceili(float(missing)/(6 if rest else 4))," · tools short" if c.tools*POINTS_PER_TOOL+c.recovery.tool_credit < missing else ""])
	if s.wound_days > 0:
		var p: Dictionary = c.recovery.patients.get(str(sid),{"hours":0,"paid":false,"temple":false})
		lines.append("Injury: %dh%s" % [ceili(float(s.wound_days*24-p.hours)/(2 if p.temple else 1))," · medicine needed" if c.medicine <= 0 and not p.paid else ""])
	return " · ".join(lines) if not lines.is_empty() else "Healthy · equipment repaired"

static func valid(state: Variant, soldiers: Array, items: Dictionary) -> bool:
	if not state is Dictionary or state.size() != 4: return false
	if not state.get("ticks") is int or state.ticks < 0 or state.ticks >= 20: return false
	if not state.get("tool_credit") is int or state.tool_credit < 0 or state.tool_credit > 11: return false
	if not state.get("patients") is Dictionary or state.patients.size() > soldiers.size() or not state.get("stored") is Array: return false
	for id in state.patients:
		if not id is String or not id.is_valid_int() or int(id) < 0 or int(id) >= soldiers.size(): return false
		var p = state.patients[id]
		if not p is Dictionary or p.size() != 3 or not p.get("hours") is int or p.hours < 0 or p.hours >= 24 or not p.get("paid") is bool or not p.get("temple") is bool: return false
		if p.hours > 0 and not p.paid: return false
	var unique = {}
	for id in state.stored:
		if not id is String or not items.has(id) or unique.has(id): return false
		unique[id] = true
	return true
