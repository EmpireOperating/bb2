extends RefCounted
## Persistent identity rules; combat reads chosen perks and scars at deployment.
const THRESHOLDS = [0,40,100,180]
const RANKS = ["Recruit","Blooded","Seasoned","Veteran"]
const PERK_ORDER = ["shield_drill","weapon_drill","endurance","steadfast"]
const PERKS = {
	"shield_drill":{"name":"Shield drill","effect":"Shield defence and its Shieldwall bonus increase by 25%. Earlier saved battles retain their original effect."},
	"weapon_drill":{"name":"Weapon handling","effect":"+5 attack accuracy. Weapon attacks cost 4 less fatigue, minimum 1. Works with any weapon."},
	"endurance":{"name":"Second wind","effect":"Unlocks Recover: spend all 9 AP to remove half accumulated fatigue. Earlier saved battles retain their original effect."},
	"steadfast":{"name":"Steadfast","effect":"+15 resolve on morale checks. Applies to wounds, nearby deaths and confidence checks. Earlier saved battles retain their original effect."}
}
const SCARS = {
	"clouded_eye":{"name":"Clouded eye","effect":"Permanent -4 melee and ranged skill."},
	"damaged_lung":{"name":"Damaged lung","effect":"Start-of-turn fatigue recovery reduced by 5."},
	"haunted":{"name":"Haunted","effect":"Starts new battles wavering. Earlier saved battles retain their original effect."}
}

static func level(s: Dictionary) -> int:
	var rank = 1
	for threshold in THRESHOLDS:
		if s.xp >= threshold: rank += 1
	return mini(4,rank-1)

static func rank_name(s: Dictionary) -> String:
	return RANKS[level(s)-1]

static func points(s: Dictionary) -> int:
	return level(s)-1-s.perks.size()

static func next_xp(s: Dictionary) -> int:
	return THRESHOLDS[level(s)] if level(s) < 4 else 0

static func record(s: Dictionary, id: String, day: int, kind: String, text: String) -> void:
	for entry in s.history:
		if entry.id == id: return
	s.history.append({"id":id,"day":day,"kind":kind,"text":text})

static func initialize(s: Dictionary, day: int, place: String, imported: bool = false) -> void:
	s["xp"] = 0
	s["xp_ledger"] = {}
	s["perks"] = []
	s["scars"] = []
	s["history"] = []
	if imported:
		var earned = 20*s.battles+5*s.kills
		if earned > 0:
			s.xp = earned
			s.xp_ledger["legacy"] = earned
		if not s.alive: record(s,"earlier_death",s.fallen_day,"death","Fell in earlier service. Their name and recorded achievements remain.")
		record(s,"earlier_service",day,"legacy","Earlier service: %d battles, %d kills; %d XP credited. Detailed events were not recorded in older builds." % [s.battles,s.kills,earned])
	else: record(s,"joined",day,"joined","Joined at %s as %s. %d crowns per day." % [place,s.background,s.wage])

static func grant(s: Dictionary, key: String, amount: int, day: int, description: String) -> bool:
	if not s.alive or amount <= 0 or s.xp_ledger.has(key): return false
	var before = level(s)
	s.xp_ledger[key] = amount
	s.xp += amount
	record(s,"xp_"+key,day,"experience","%s +%d XP." % [description,amount])
	for rank in range(before+1,level(s)+1):
		record(s,"rank_%d" % rank,day,"rank","Reached level %d: %s. One perk and one attribute choice earned." % [rank,RANKS[rank-1]])
	return true

static func scar(s: Dictionary, battle_unit: Dictionary, day: int, encounter: int, place: String) -> String:
	# Critical survival, not merely arriving wounded or carrying a previous injury.
	if not s.alive or s.scars.size() >= 2 or battle_unit.damage_taken < 30 or battle_unit.hp*4 > battle_unit.max_hp: return ""
	var kind = "clouded_eye" if battle_unit.worst_head else ("haunted" if battle_unit.routed or battle_unit.escaped else "damaged_lung")
	if kind in s.scars: return ""
	s.scars.append(kind)
	record(s,"scar_%d" % encounter,day,"scar","Survived %s critically hurt: %s. %s" % [place,SCARS[kind].name,SCARS[kind].effect])
	return kind

static func validate(s: Dictionary, day: int) -> bool:
	if not s.get("xp") is int or s.xp < 0 or s.xp > 10000 or not s.get("xp_ledger") is Dictionary: return false
	if not s.get("perks") is Array or not s.get("scars") is Array or not s.get("history") is Array: return false
	if s.perks.size() > level(s)-1 or s.scars.size() > 2 or s.history.size() > 2048 or s.xp_ledger.size() > 300: return false
	var total = 0
	for key in s.xp_ledger:
		var value = s.xp_ledger[key]
		if not key is String or not (key == "legacy" or key.begins_with("battle_") or key.begins_with("contract_")) or not value is int or value <= 0: return false
		if key != "legacy" and value > 45: return false
		total += value
	if total != s.xp: return false
	for pair in [[s.perks,PERKS],[s.scars,SCARS]]:
		var seen = {}
		for id in pair[0]:
			if not id is String or not pair[1].has(id) or seen.has(id): return false
			seen[id] = true
	var ids = {}
	for e in s.history:
		if not e is Dictionary or not e.get("id") is String or not e.get("text") is String or not e.get("day") is int: return false
		if not e.get("kind") in ["joined","legacy","death","experience","rank","training","scar","battle","deed","healed","bond","grief","hardship","camp"]: return false
		if ids.has(e.id) or e.id.is_empty() or e.day < 1 or e.day > day or e.text.length() > 400: return false
		ids[e.id] = true
	return true
