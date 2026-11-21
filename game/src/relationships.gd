extends RefCounted
## Social consequences use recorded service, upkeep and paid camp decisions.
const Progression = preload("res://src/progression.gd")
const COMRADE = 3
var pairs: Dictionary = {}
var settled: Array = []
var days: Array = []
var hardship_streak = 0

static func initialize_soldier(s: Dictionary) -> void:
	s["strain"] = 0
	s["grief"] = []

static func pair_key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a,b),maxi(a,b)]

func trust(a: int, b: int) -> int:
	return pairs.get(pair_key(a,b),{}).get("trust",0)

func title(a: int, b: int) -> String:
	var value = trust(a,b)
	return "Comrades" if value >= COMRADE else ("Strained" if value < 0 else ("Familiar" if value > 0 else "Unproven"))

func change(soldiers: Array, a: int, b: int, amount: int, id: String, day: int, reason: String) -> bool:
	var key = pair_key(a,b)
	if not pairs.has(key): pairs[key] = {"a":mini(a,b),"b":maxi(a,b),"trust":0,"history":[]}
	var pair: Dictionary = pairs[key]
	for entry in pair.history:
		if entry.id == id: return false
	var old: int = pair.trust
	pair.trust = clampi(old+amount,-3,6)
	var delta: int = pair.trust-old
	pair.history.append({"id":id,"day":day,"delta":delta,"text":reason})
	for ids in [[a,b],[b,a]]:
		Progression.record(soldiers[ids[0]],"bond_"+key+"_"+id,day,"bond","%s: trust %+d (%d). %s" % [soldiers[ids[1]].name,delta,pair.trust,reason])
	return true

func settle(soldiers: Array, deployment: Array, battle, day: int, encounter: int, retreat: bool) -> void:
	if encounter in settled: return
	settled.append(encounter)
	# Existing grief eases only after subsequent completed, survived battles.
	for id in deployment:
		if id < 0 or not soldiers[id].alive or retreat: continue
		var s: Dictionary = soldiers[id]
		for loss in s.grief:
			loss.remaining -= 1
			if loss.remaining == 0: Progression.record(s,"grief_eased_%d" % loss.person,day,"grief","Grief for %s eases after further service. The bond remains in their record." % soldiers[loss.person].name)
		s.grief = s.grief.filter(func(loss): return loss.remaining > 0)
	# A comrade lost this battle creates grief before new survivor trust is added.
	for id in deployment:
		if id < 0 or not soldiers[id].alive: continue
		for lost in deployment:
			if lost < 0 or soldiers[lost].alive or soldiers[lost].fallen_day != day or trust(id,lost) < COMRADE: continue
			if soldiers[id].grief.any(func(loss): return loss.person == lost): continue
			soldiers[id].grief.append({"person":lost,"remaining":3})
			Progression.record(soldiers[id],"loss_%d" % lost,day,"grief","Lost comrade %s. -4 starting morale for the next 3 completed battles; total grief penalty capped at 8." % soldiers[lost].name)
	for i in deployment.size():
		var a: int = deployment[i]
		if a < 0 or not soldiers[a].alive: continue
		for j in range(i+1,deployment.size()):
			var b: int = deployment[j]
			if b < 0 or not soldiers[b].alive: continue
			var held = [i,j] in battle.shared_line
			var amount = -1 if retreat else (2 if held else 1)
			var reason = "Retreated together; confidence in each other shaken." if retreat else ("Survived together and held an ordered line under threat." if held else "Survived the same completed battle.")
			change(soldiers,a,b,amount,"battle_%d" % encounter,day,reason)

func daily(soldiers: Array, day: int, fed: bool, paid: bool, rested: bool) -> void:
	if day in days: return
	days.append(day)
	var hardship = not fed or not paid
	hardship_streak = hardship_streak+1 if hardship else 0
	var people = soldiers.filter(func(s): return s.alive)
	var reason = "Hunger and unpaid wages" if not fed and not paid else ("Hunger" if not fed else "Unpaid wages")
	for s in people:
		var old: int = s.strain
		s.strain = clampi(old+(0 if fed else 1)+(0 if paid else 1)-(1 if rested and not hardship else 0),0,6)
		if s.strain != old:
			Progression.record(s,"strain_%d" % day,day,"hardship","%s: strain %d to %d. Each point costs 2 starting morale." % [reason if hardship else "Fed, paid rest",old,s.strain])
	if hardship_streak >= 2:
		for i in people.size():
			for j in range(i+1,people.size()): change(soldiers,people[i].id,people[j].id,-1,"hardship_%d" % day,day,"%s for %d consecutive days strains the company." % [reason,hardship_streak])

static func grief_penalty(s: Dictionary) -> int:
	return mini(8,s.grief.size()*4)

static func starting_morale(s: Dictionary) -> int:
	return (75 if "haunted" in s.scars else 85)-s.strain*2-grief_penalty(s)

func comrades(id: int, soldiers: Array) -> Array:
	return soldiers.filter(func(s): return s.id != id and s.alive and trust(id,s.id) >= COMRADE).map(func(s): return s.id)

func snapshot() -> Dictionary:
	return {"pairs":pairs.duplicate(true),"settled":settled.duplicate(),"days":days.duplicate(),"hardship_streak":hardship_streak}

func restore(data: Variant, soldiers: Array, day: int, encounters: int) -> bool:
	if not data is Dictionary or not data.get("pairs") is Dictionary or data.pairs.size() > soldiers.size()*(soldiers.size()-1)/2: return false
	if not data.get("hardship_streak") is int or data.hardship_streak < 0 or data.hardship_streak > day: return false
	for field in ["settled","days"]:
		if not data.get(field) is Array or data[field].size() > (encounters if field == "settled" else day): return false
		var seen = {}
		for value in data[field]:
			if not value is int or value < 1 or value > (encounters if field == "settled" else day) or seen.has(value): return false
			seen[value] = true
	if data.hardship_streak > data.days.size(): return false
	for key in data.pairs:
		var pair = data.pairs[key]
		if not key is String or not pair is Dictionary: return false
		for field in ["a","b","trust"]:
			if not pair.get(field) is int: return false
		if pair.a < 0 or pair.b >= soldiers.size() or pair.a >= pair.b or key != pair_key(pair.a,pair.b) or pair.trust < -3 or pair.trust > 6: return false
		if not pair.get("history") is Array or pair.history.is_empty(): return false
		var seen = {}; var total = 0; var previous_day = 0
		for entry in pair.history:
			if not entry is Dictionary or not entry.get("id") is String or entry.id.is_empty() or seen.has(entry.id): return false
			if not entry.get("day") is int or entry.day < 1 or entry.day > day or entry.day < previous_day: return false
			if not entry.get("delta") is int or entry.delta < -2 or entry.delta > 2 or not entry.get("text") is String or entry.text.length() > 400: return false
			seen[entry.id] = true; previous_day = entry.day; total += entry.delta
			if total < -3 or total > 6: return false
		if total != pair.trust: return false
	for s in soldiers:
		if not s.get("strain") is int or s.strain < 0 or s.strain > 6 or not s.get("grief") is Array or s.grief.size() > soldiers.size(): return false
		var seen = {}
		for loss in s.grief:
			if not loss is Dictionary or not loss.get("person") is int or not loss.get("remaining") is int: return false
			if loss.person < 0 or loss.person >= soldiers.size() or loss.person == s.id or seen.has(loss.person) or soldiers[loss.person].alive or loss.remaining < 1 or loss.remaining > 3: return false
			if data.pairs.get(pair_key(s.id,loss.person),{}).get("trust",0) < COMRADE: return false
			seen[loss.person] = true
	pairs = data.pairs.duplicate(true); settled = data.settled.duplicate(); days = data.days.duplicate(); hardship_streak = data.hardship_streak
	return true
