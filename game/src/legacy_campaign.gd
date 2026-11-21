extends RefCounted
## Persistent company state. Resolving a battle is a single, idempotent transition.
const Battle = preload("res://src/legacy_battle_v5.gd")
const SLOTS = ["weapon", "body", "under", "head", "shield"]
const CONTRACTS = [
	{"title":"The Blackwater Ford", "brief":"Take the crossing before the March Company closes the road.", "pay":240},
	{"title":"The Toll Keeper", "brief":"A fresh garrison has seized the ford. Clear it for the grain wagons.", "pay":300},
	{"title":"The Last Crossing", "brief":"The march captain returns with veterans. Hold the road one final time.", "pay":380}
]
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy_equipment_v10.json"))
var battle = Battle.new()
var soldiers: Array = []
var items: Dictionary = {}
var next_item = 1
var day = 1
var crowns = 360
var tools = 60
var medicine = 18
var completed = 0
var seed_value = 7391
var phase = "camp"
var journal: Array = []
var aftermath: Dictionary = {}
var retreat = false

func setup(seed_number: int = 7391) -> void:
	seed_value = maxi(1, seed_number)
	battle.setup(seed_value)
	soldiers.clear()
	items.clear()
	next_item = 1
	day = 1
	crowns = 360
	tools = 60
	medicine = 18
	completed = 0
	phase = "camp"
	journal.clear()
	aftermath.clear()
	retreat = false
	for i in 6:
		var u: Dictionary = battle.units[i]
		var gear = {"weapon":add_item(u.weapon), "body":add_item("mail" if i in [0, 1, 4] else "leather"), "under":add_item("linen"), "head":add_item("cap"), "shield":add_item("shield") if u.shield else ""}
		soldiers.append({"id":i, "name":u.name, "title":u.title, "base_hp":u.max_hp, "base_skill":u.skill, "base_defense":u.defense, "hp":u.hp, "alive":true, "wound_days":0, "kills":0, "battles":0, "fallen_day":0, "gear":gear})
	for definition in ["sword", "spear", "axe", "bow", "heavy_mail", "leather", "gambeson", "nasal", "shield"]: add_item(definition)
	note("The Ashen Company takes the road. Six names on the roll.")

func add_item(definition: String, condition: int = -1) -> String:
	var id = "item_%03d" % next_item
	next_item += 1
	var maximum = int(catalog[definition].durability)
	items[id] = {"id":id, "definition":definition, "condition":maximum if condition < 0 else clampi(condition, 0, maximum)}
	return id

func alive_count() -> int:
	var count = 0
	for s in soldiers:
		if s.alive: count += 1
	return count

func over() -> bool:
	return completed >= CONTRACTS.size() or alive_count() == 0

func contract() -> Dictionary:
	return CONTRACTS[mini(completed, CONTRACTS.size()-1)]

func max_hp(s: Dictionary) -> int:
	return int(s.base_hp) - (12 if s.wound_days > 0 else 0)

func effective_skill(s: Dictionary) -> int:
	return int(s.base_skill) - (10 if s.wound_days > 0 else 0)

func item_def(id: String) -> Dictionary:
	return catalog[items[id].definition] if items.has(id) else {}

func owner(id: String) -> int:
	for s in soldiers:
		for slot in SLOTS:
			if id != "" and s.gear[slot] == id: return int(s.id)
	return -1

func stash(slot: String) -> Array:
	var out: Array = []
	for id in items:
		if owner(id) == -1 and item_def(id).slot == slot: out.append(id)
	return out

func equip(soldier_id: int, item_id: String) -> bool:
	if phase != "camp" or soldier_id < 0 or soldier_id >= soldiers.size() or not items.has(item_id): return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or owner(item_id) != -1: return false
	var definition = item_def(item_id)
	var slot: String = definition.slot
	if slot == "shield" and item_def(s.gear.weapon).get("weapon", "") == "bow": return false
	s.gear[slot] = item_id
	if slot == "weapon" and definition.weapon == "bow": s.gear.shield = ""
	note("%s equips %s." % [s.name, definition.name])
	return true

func unequip(soldier_id: int, slot: String) -> bool:
	if phase != "camp" or not slot in SLOTS or slot == "weapon" or soldier_id < 0 or soldier_id >= soldiers.size(): return false
	var s: Dictionary = soldiers[soldier_id]
	if not s.alive or s.gear[slot] == "": return false
	s.gear[slot] = ""
	return true

func durability(s: Dictionary, slot: String) -> int:
	return int(items[s.gear[slot]].condition) if items.has(s.gear[slot]) else 0

func maximum(s: Dictionary, slot: String) -> int:
	return int(item_def(s.gear[slot]).get("durability", 0))

func repair_cost(soldier_id: int) -> int:
	if soldier_id < 0 or soldier_id >= soldiers.size() or not soldiers[soldier_id].alive: return 0
	var missing = 0
	var s: Dictionary = soldiers[soldier_id]
	for slot in ["body", "under", "head"]: missing += maximum(s, slot) - durability(s, slot)
	return ceili(float(missing)/12)

func repair(soldier_id: int) -> bool:
	if phase != "camp": return false
	var cost = repair_cost(soldier_id)
	if cost == 0 or tools < cost: return false
	var s: Dictionary = soldiers[soldier_id]
	for slot in ["body", "under", "head"]:
		if items.has(s.gear[slot]): items[s.gear[slot]].condition = maximum(s, slot)
	tools -= cost
	note("%s's armour repaired: %d tools." % [s.name, cost])
	return true

func rest_cost() -> int:
	return alive_count()*6

func rest_day() -> bool:
	if phase != "camp" or alive_count() == 0 or crowns < rest_cost(): return false
	var cost = rest_cost()
	crowns -= cost
	day += 1
	var treated = 0
	for s in soldiers:
		if not s.alive: continue
		var injured = s.wound_days > 0 or s.hp < max_hp(s)
		if injured and medicine > 0:
			medicine -= 1
			treated += 1
			s.wound_days = maxi(0, int(s.wound_days)-1)
			s.hp = mini(max_hp(s), int(s.hp)+18)
		elif s.wound_days == 0:
			s.hp = mini(max_hp(s), int(s.hp)+6)
		else:
			# Severe wounds need medicine to progress; untreated HP still recovers slowly.
			s.hp = mini(max_hp(s), int(s.hp)+6)
	note("Day %d: rest costs %d crowns; %d men treated." % [day, cost, treated])
	return true

func buy_supply(kind: String) -> bool:
	if phase != "camp" or not kind in ["tools", "medicine"]: return false
	var cost = 36 if kind == "tools" else 30
	if crowns < cost: return false
	crowns -= cost
	if kind == "tools": tools += 12
	else: medicine += 6
	note("Bought %s for %d crowns." % [kind, cost])
	return true

func deploy() -> bool:
	if phase != "camp" or over(): return false
	battle.setup(seed_value + completed*101)
	for i in 6:
		var s: Dictionary = soldiers[i]
		var u: Dictionary = battle.units[i]
		u.hp = int(s.hp) if s.alive else 0
		u.max_hp = max_hp(s)
		u.skill = effective_skill(s)
		u.defense = s.base_defense
		u.weapon = item_def(s.gear.weapon).get("weapon", "sword")
		u.shield = s.gear.shield != ""
		for pair in [["armor", "body"], ["padding", "under"], ["helmet", "head"]]:
			u[pair[0]] = durability(s, pair[1])
			u["max_"+pair[0]] = maximum(s, pair[1])
	for i in range(6, 12):
		battle.units[i].armor += completed*10
		battle.units[i].max_armor += completed*10
		battle.units[i].skill += completed*2
	battle.events.clear()
	battle.log_event(contract().title + ": hold the ford or break their company.")
	phase = "battle"
	retreat = false
	return true

func retreat_from_battle() -> bool:
	if phase != "battle" or not battle.result.is_empty(): return false
	# Clear, voluntary loss: casualties and equipment damage already suffered persist.
	# A retreat spends this contract and receives no pay; it never rerolls the same job.
	retreat = true
	battle.result = "defeat"
	battle.log_event("The company gives up the crossing and retreats.")
	return resolve_battle()

func resolve_battle() -> bool:
	if phase != "battle" or battle.result.is_empty(): return false
	var won = battle.result == "victory"
	var rows: Array = []
	var newly_fallen = 0
	var new_wounds = 0
	var reward = int(contract().pay) if won else 0
	for i in 6:
		var s: Dictionary = soldiers[i]
		if not s.alive: continue
		var u: Dictionary = battle.units[i]
		var start_hp = int(s.hp)
		s.hp = int(u.hp)
		s.kills += int(u.kills)
		s.battles += 1
		for pair in [["armor", "body"], ["padding", "under"], ["helmet", "head"]]:
			if items.has(s.gear[pair[1]]): items[s.gear[pair[1]]].condition = int(u[pair[0]])
		var status = "Survived"
		if u.hp == 0:
			s.alive = false
			s.fallen_day = day
			newly_fallen += 1
			status = "Fallen"
			for slot in SLOTS:
				if not won: items.erase(s.gear[slot])
				s.gear[slot] = ""
		elif start_hp - int(u.hp) >= 20 or u.hp <= s.base_hp/3:
			s.wound_days = maxi(int(s.wound_days), 3)
			s.hp = mini(int(s.hp), max_hp(s))
			new_wounds += 1
			status = "Deep wound"
		elif u.routed or u.escaped: status = "Returned shaken"
		rows.append({"id":i, "name":s.name, "status":status, "hp":s.hp, "kills":int(u.kills)})
	crowns += reward
	if won:
		tools += 12
		medicine += 4
		add_item(["nasal", "heavy_mail", "gambeson"][completed])
	aftermath = {"title":contract().title, "result":battle.result, "retreat":retreat, "pay":reward, "fallen":newly_fallen, "wounded":new_wounds, "rows":rows, "day":day, "round":battle.round_no}
	note("%s: %s; %d fallen, %d wounded. %d crowns earned." % [contract().title, "withdrawal" if retreat else battle.result, newly_fallen, new_wounds, reward])
	completed += 1
	day += 1
	phase = "aftermath"
	return true

func return_to_camp() -> bool:
	if phase != "aftermath": return false
	phase = "camp"
	return true

func note(message: String) -> void:
	journal.append(message)
	if journal.size() > 60: journal.pop_front()

func snapshot() -> Dictionary:
	return {"version":2, "seed":seed_value, "day":day, "crowns":crowns, "tools":tools, "medicine":medicine, "completed":completed, "phase":phase, "next_item":next_item, "soldiers":soldiers.duplicate(true), "items":items.duplicate(true), "journal":journal.duplicate(), "aftermath":aftermath.duplicate(true), "retreat":retreat, "battle":battle.snapshot() if phase in ["battle", "aftermath"] else null}

func restore(raw: Variant) -> bool:
	# Validate using temporary objects. Never partially mutate a live company.
	if not raw is Dictionary: return false
	var d: Dictionary = battle.normalize_json_numbers(raw)
	for field in ["version", "seed", "day", "crowns", "tools", "medicine", "completed", "next_item"]:
		if not d.has(field) or not d[field] is int: return false
	if d.version != 2 or d.seed < 1 or d.day < 1 or d.crowns < 0 or d.tools < 0 or d.medicine < 0 or d.completed < 0 or d.completed > 3 or d.next_item < 1: return false
	if not d.get("phase", "") in ["camp", "battle", "aftermath"]: return false
	if not d.get("soldiers") is Array or d.soldiers.size() != 6 or not d.get("items") is Dictionary: return false
	if not d.get("journal") is Array or not d.get("aftermath") is Dictionary or not d.get("retreat") is bool: return false
	for message in d.journal:
		if not message is String: return false
	for id in d.items:
		var item = d.items[id]
		if not id is String or not item is Dictionary or item.get("id") != id: return false
		if not catalog.has(item.get("definition", "")) or not item.get("condition") is int: return false
		if item.condition < 0 or item.condition > catalog[item.definition].durability: return false
		if not id.begins_with("item_") or not id.trim_prefix("item_").is_valid_int() or int(id.trim_prefix("item_")) >= d.next_item: return false
	var assigned: Dictionary = {}
	for i in 6:
		var s = d.soldiers[i]
		if not s is Dictionary or s.get("id", -1) != i or not s.get("alive") is bool or not s.get("gear") is Dictionary: return false
		for field in ["name", "title"]:
			if not s.get(field) is String: return false
		for field in ["id", "base_hp", "base_skill", "base_defense", "hp", "wound_days", "kills", "battles", "fallen_day"]:
			if not s.get(field) is int or s[field] < 0: return false
		if s.base_hp <= 12 or s.hp > max_hp(s) or s.wound_days > 3 or s.alive != (s.hp > 0): return false
		for slot in SLOTS:
			if not s.gear.get(slot) is String: return false
			var id: String = s.gear[slot]
			if id == "":
				if s.alive and slot == "weapon": return false
				continue
			if not s.alive or not d.items.has(id) or assigned.has(id) or catalog[d.items[id].definition].slot != slot: return false
			assigned[id] = true
		if s.alive and d.items[s.gear.weapon].definition == "bow" and s.gear.shield != "": return false
	var candidate = Battle.new()
	candidate.setup(d.seed)
	if d.phase in ["battle", "aftermath"]:
		if not candidate.restore(d.get("battle")): return false
		if d.phase == "battle" and (not candidate.result.is_empty() or d.completed >= 3): return false
		if d.phase == "aftermath":
			if candidate.result.is_empty() or d.completed == 0: return false
			for field in ["title", "result", "retreat", "pay", "fallen", "wounded", "rows", "day", "round"]:
				if not d.aftermath.has(field): return false
			if not d.aftermath.title is String or d.aftermath.result != candidate.result: return false
			if not d.aftermath.day is int or not d.aftermath.round is int: return false
			if not d.aftermath.rows is Array: return false
			for row in d.aftermath.rows:
				if not row is Dictionary: return false
				for field in ["id", "hp", "kills"]:
					if not row.get(field) is int: return false
				for field in ["name", "status"]:
					if not row.get(field) is String: return false
				if row.id < 0 or row.id >= 6 or row.hp < 0 or row.kills < 0: return false
			if not d.aftermath.pay is int or not d.aftermath.fallen is int or not d.aftermath.wounded is int or not d.aftermath.retreat is bool: return false
	seed_value = d.seed
	day = d.day
	crowns = d.crowns
	tools = d.tools
	medicine = d.medicine
	completed = d.completed
	phase = d.phase
	next_item = d.next_item
	soldiers = d.soldiers
	items = d.items
	journal = d.journal
	aftermath = d.aftermath
	retreat = d.retreat
	battle = candidate
	return true
