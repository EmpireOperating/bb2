extends RefCounted
## Local, timed observations; combat draws from the same finite field-party roster.
const VERSION = 1
const COUNT_TICKS = 10 # Thirty game minutes.
const TYPE_TICKS = 20 # One game hour.
const HOME_RADIUS = 10.0
const WATCH_RADIUS = 160.0
const TYPES = ["thugs", "outlaws", "raiders", "veteran deserters"]
const SIZES = ["no defenders seen", "a few defenders (1–3)", "several defenders (4–6)"]
const MOVEMENTS = ["", "A party left the camp", "A party returned to camp", "A new party assembled at camp"]
var enabled = false
var garrisons: Dictionary = {}
var reports: Dictionary = {}
var watch: Dictionary = {}
var engagement: Dictionary = {}

static func key(site: String, generation: int) -> String:
	return "%s/%d" % [site,generation]

static func resident_slots(c, site: String, generation: int, strength: int) -> int:
	return maxi(0,resident_count(c.world.camp_role(site),strength)-(resident_count(c.world.camp_role(site),1) if c.world.physical_founding and generation > 1 else 0))

static func resident_count(role: String, strength: int) -> int:
	var balance = preload("res://src/campaign_balance.gd")
	return balance.count(role,strength,"clear")-balance.count(role,maxi(1,strength-1),"scout")

func setup(c, active: bool) -> void:
	enabled = active and c.camp_life.enabled and c.overworld.tracks.enabled and c.progression_version == 1
	garrisons.clear(); reports.clear(); watch.clear(); engagement.clear()
	sync(c)

func sync(c) -> void:
	if not enabled: return
	for r in c.camp_life.records.values():
		var id = key(r.site,r.generation)
		var camp: Dictionary = c.world.camps[r.site]
		if not garrisons.has(id):
			var strength: int = camp.strength if camp.generation == r.generation else c.world.config.camps[r.site].strength if r.generation == 1 else 1
			garrisons[id] = {"strength":strength,"health":[]}
		var g: Dictionary = garrisons[id]
		# Existing food-funded threat growth adds residents; old casualties never refill.
		if camp.active and camp.generation == r.generation: g.strength = camp.strength
		while g.health.size() < resident_slots(c,r.site,r.generation,g.strength): g.health.append(1000)

func present_party(c, site: String) -> String:
	if not c.world.camps[site].active: return ""
	var id: String = c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)].party
	var s: Dictionary = c.overworld.scouts[id]
	if s.defeated or s.position.distance_to(c.overworld.places[site]) > HOME_RADIUS: return ""
	return id

func home_party(c, site: String) -> String:
	var id = present_party(c,site)
	return id if id != "" and not c.guards.engaged(id) else ""

func roster(c, site: String) -> Array:
	var out: Array = []
	if not enabled or not c.world.camps.has(site) or not c.world.camps[site].active: return out
	var g: Dictionary = garrisons[key(site,c.world.camps[site].generation)]
	for i in g.health.size(): out.append({"party":"","index":i,"health":g.health[i]})
	var id = home_party(c,site)
	if id != "":
		var b: Dictionary = c.bandits.bands[id]
		for i in b.capacity: out.append({"party":id,"index":i,"health":b.health[i]})
	return out

func battle_target(c) -> String:
	if not enabled: return ""
	var job: Dictionary = c.encounter if not c.encounter.is_empty() else c.active
	if job.get("kind") not in ["camp","clear","legacy"]: return ""
	var site: String = job.get("site",job.get("target",""))
	return site if c.world.SITES.has(site) else ""

func prepare(c) -> void:
	watch.clear(); engagement.clear()
	var site = battle_target(c)
	if site == "": return
	sync(c)
	engagement = {"site":site,"generation":c.world.camps[site].generation,"rows":roster(c,site)}

func populate(c) -> void:
	if engagement.is_empty(): return
	for i in c.battle.enemy_slots():
		var u: Dictionary = c.battle.units[c.battle.player_slots()+i]
		if i >= engagement.rows.size() or engagement.rows[i].health == 0:
			u.hp = 0; u.name = "Empty rank"; continue
		var row: Dictionary = engagement.rows[i]
		var threat: int = c.world.camps[engagement.site].strength if row.party == "" else c.bandits.bands[row.party].threat
		var role: String = c.world.camp_role(c.overworld.scouts[c.bandits.bands[row.party].get("lineage",row.party)].site) if row.party != "" else c.world.camp_role(engagement.site)
		c.CampaignBalance.equip(c,u,threat,row.index,"clear" if row.party == "" else "scout",role)
		u.ranged_skill = u.skill if u.weapon in c.Arsenal.RANGED else 40+(u.id*7)%15
		u.hp = maxi(1,ceili(u.max_hp*row.health/1000.0))

func settle(c, won: bool) -> void:
	if engagement.is_empty(): return
	var g: Dictionary = garrisons[key(engagement.site,engagement.generation)]
	var involved: Dictionary = {}
	for i in engagement.rows.size():
		var row: Dictionary = engagement.rows[i]; var u: Dictionary = c.battle.units[c.battle.player_slots()+i]
		var hp = mini(row.health,floori(1000.0*u.hp/u.max_hp))
		if row.party == "": g.health[row.index] = hp
		else:
			c.bandits.bands[row.party].health[row.index] = hp; involved[row.party] = true
	for id in involved:
		var b: Dictionary = c.bandits.bands[id]; var s: Dictionary = c.overworld.scouts[id]
		c.bandits.record_members(id)
		if won:c.economy.freight.retrieve_band(c,id)
		c.raiders.settle_band(c,id,won)
		if won or b.health.all(func(hp):return hp == 0):
			s.defeated = true; c.bandits.change_mode(b,s,"defeated")
		else:
			b.rest = c.bandits.LOSS_REST_TICKS; b.fear = 0
			c.bandits.change_mode(b,s,"returning")
			c.bandits.abandon_freight(c,s,"The surviving camp defenders abandon their freight and recover at home.")
	# A participant knows the battle's outcome; this does not grant remote updates.
	reports[engagement.site] = {"generation":engagement.generation,"seen":c.overworld.tracks.clock,"size":0 if won else size_band(roster(c,engagement.site)),"types":[],"types_seen":0,"occupied":not won,"movement":0,"movement_size":0,"movement_seen":0}
	engagement.clear()

static func size_band(rows: Array) -> int:
	var count = rows.filter(func(row):return row.health > 0).size()
	return 0 if count == 0 else 1 if count <= 3 else 2

func reason(c, site: String) -> String:
	if not enabled or not c.world.SITES.has(site): return "Camp reconnaissance is unavailable."
	if c.phase != "camp" or c.over() or not c.encounter.is_empty() or c.dungeons.active != "" or c.active_ids().is_empty(): return "Your company cannot watch a camp now."
	if c.active.get("kind") == "escort": return "Finish or abandon the escort before keeping watch."
	var ow = c.overworld
	if not ow.discovered(ow.places[site]) or ow.position.distance_to(ow.places[site]) > minf(WATCH_RADIUS,ow.sight()): return "Move closer, within sight of the camp."
	return ""

func begin(c, site: String) -> bool:
	if reason(c,site) != "": return false
	c.exploration.cancel(c); c.traffic.pursuit = ""
	c.overworld.path.clear(); c.overworld.destination = ""; c.overworld.rest_left = 0
	watch = {"site":site,"generation":c.world.camps[site].generation,"progress":0,"home":present_party(c,site),"party":c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)].party}
	c.overworld.paused = false
	c.note("Watching %s. Half an hour for a rough count; an hour to identify enemy types. Nearby bands can still spot you." % c.node(site).name)
	return true

func step(c, background: bool = false) -> void:
	if not enabled or watch.is_empty(): return
	if background or reason(c,watch.site) != "" or not c.overworld.path.is_empty() or c.overworld.rest_left > 0:
		watch.clear(); return
	var site: String = watch.site; var generation: int = c.world.camps[site].generation
	if watch.generation != generation:
		watch = {"site":site,"generation":generation,"progress":0,"home":present_party(c,site),"party":c.camp_life.records[c.camp_life.key(site,c.world.camps[site].generation)].party}
	watch.progress += 1
	var home = present_party(c,site)
	var movement = 0
	if home != watch.home:
		movement = 1 if home == "" and not c.overworld.scouts[watch.home].defeated else 3 if home != "" and home != watch.party else 2 if home != "" else 0
		if movement != 0:
			if not reports.has(site) or reports[site].generation != generation: reports[site] = blank_report(generation,c.overworld.tracks.clock)
			var r: Dictionary = reports[site]
			var id: String = watch.home if movement == 1 else home
			var count: int = c.bandits.bands[id].health.filter(func(hp):return hp > 0).size()
			r.movement = movement; r.movement_size = 1 if count <= 3 else 2; r.movement_seen = c.overworld.tracks.clock
			c.note("%s: %s." % [c.node(site).name,MOVEMENTS[movement]])
		watch.home = home
	watch.party = c.camp_life.records[c.camp_life.key(site,generation)].party
	if watch.progress % COUNT_TICKS != 0: return
	var rows = roster(c,site)
	var report: Dictionary = reports.get(site,blank_report(generation,c.overworld.tracks.clock))
	if report.generation != generation: report = blank_report(generation,c.overworld.tracks.clock)
	report.seen = c.overworld.tracks.clock; report.size = size_band(rows); report.occupied = c.world.camps[site].active
	if watch.progress >= TYPE_TICKS:
		report.types = []; report.types_seen = report.seen
		for row in rows:
			if row.health == 0: continue
			var strength: int = c.world.camps[site].strength if row.party == "" else c.bandits.bands[row.party].threat
			var role: String = c.world.camp_role(c.overworld.scouts[c.bandits.bands[row.party].get("lineage",row.party)].site) if row.party != "" else c.world.camp_role(site)
			var grade: int = c.CampaignBalance.grade(role,strength,row.index,"clear" if row.party == "" else "scout")
			if grade not in report.types: report.types.append(grade)
		report.types.sort()
	reports[site] = report
	if watch.progress == COUNT_TICKS: c.note("First estimate at %s: %s." % [c.node(site).name,SIZES[report.size]])
	if watch.progress >= TYPE_TICKS+COUNT_TICKS: watch.progress = TYPE_TICKS # Refresh each further half-hour.

static func blank_report(generation: int, clock: int) -> Dictionary:
	return {"generation":generation,"seen":clock,"size":-1,"types":[],"types_seen":0,"occupied":true,"movement":0,"movement_size":0,"movement_seen":0}

func label(c, site: String) -> String:
	if not reports.has(site): return "DEFENDERS UNKNOWN"
	var r: Dictionary = reports[site]
	return "LAST SEEN: "+("CLEARED" if not r.occupied else "UNCOUNTED" if r.size == -1 else ["NO DEFENDERS", "1–3 DEFENDERS", "4–6 DEFENDERS"][r.size])

func snapshot() -> Dictionary:
	return {"version":VERSION,"garrisons":garrisons.duplicate(true),"reports":reports.duplicate(true),"watch":watch.duplicate(true),"engagement":engagement.duplicate(true)}

func restore(raw: Variant, c) -> bool:
	if not raw is Dictionary or raw.size() != 5 or raw.get("version") != VERSION: return false
	if not c.camp_life.enabled or not c.overworld.tracks.enabled or c.progression_version != 1: return false
	for field in ["garrisons","reports","watch","engagement"]:
		if not raw.get(field) is Dictionary: return false
	if raw.garrisons.size() != c.camp_life.records.size(): return false
	for r in c.camp_life.records.values():
		var g = raw.garrisons.get(key(r.site,r.generation))
		if not g is Dictionary or g.size() != 2 or not g.get("strength") is int or g.strength not in range(1,4) or not g.get("health") is Array: return false
		if g.health.size() != resident_slots(c,r.site,r.generation,g.strength): return false
		if c.world.camps[r.site].generation == r.generation and c.world.camps[r.site].active and g.strength != c.world.camps[r.site].strength: return false
		for hp in g.health:
			if not hp is int or hp < 0 or hp > 1000: return false
	var clock: int = c.overworld.tracks.clock
	for site in raw.reports:
		var r = raw.reports[site]
		if not c.world.SITES.has(site) or not r is Dictionary or r.size() != 9: return false
		for field in ["generation","seen","size","types_seen","movement","movement_size","movement_seen"]:
			if not r.get(field) is int: return false
		if r.generation < 1 or r.generation > c.world.camps[site].generation or r.seen < 0 or r.seen > clock or r.types_seen < 0 or r.types_seen > r.seen or r.movement_seen < 0 or r.movement_seen > clock: return false
		if r.size not in range(-1,3) or not r.get("occupied") is bool or r.movement not in range(4) or r.movement_size not in range(3): return false
		if not r.get("types") is Array or r.types.size() > 4: return false
		for grade in r.types:
			if not grade is int or grade not in range(4) or r.types.count(grade) != 1: return false
		if r.types_seen == 0 and not r.types.is_empty(): return false
		if r.movement == 0 and (r.movement_seen != 0 or r.movement_size != 0): return false
		if r.movement != 0 and r.movement_size == 0: return false
		if not r.occupied and r.size != 0: return false
	if not raw.watch.is_empty():
		var w: Dictionary = raw.watch
		if w.size() != 5 or not w.get("site") is String or not c.world.SITES.has(w.site) or not w.get("generation") is int or w.generation != c.world.camps[w.site].generation: return false
		if not w.get("progress") is int or w.progress < 0 or w.progress >= TYPE_TICKS+COUNT_TICKS or not w.get("home") is String: return false
		if not w.get("party") is String or not c.overworld.scouts.has(w.party) or c.overworld.scouts[w.party].site != w.site or c.overworld.scouts[w.party].generation != w.generation: return false
		if w.home != "" and (not c.overworld.scouts.has(w.home) or c.overworld.scouts[w.home].site != w.site or c.overworld.scouts[w.home].generation != w.generation): return false
		if c.phase != "camp" or not c.encounter.is_empty() or c.dungeons.active != "" or not c.overworld.path.is_empty() or c.overworld.rest_left != 0 or c.active.get("kind") == "escort": return false
		if c.overworld.position.distance_to(c.overworld.places[w.site]) > WATCH_RADIUS: return false
	enabled = true; garrisons = raw.garrisons.duplicate(true); reports = raw.reports.duplicate(true); watch = raw.watch.duplicate(true); engagement = raw.engagement.duplicate(true)
	return true

func valid_engagement(c) -> bool:
	var site = battle_target(c)
	if c.phase != "battle" or site == "": return engagement.is_empty()
	if engagement.size() != 3 or engagement.get("site") != site or engagement.get("generation") != c.world.camps[site].generation or not engagement.get("rows") is Array: return false
	if engagement.rows != roster(c,site): return false
	for i in c.battle.enemy_slots():
		var u: Dictionary = c.battle.units[c.battle.player_slots()+i]
		if i >= engagement.rows.size() or engagement.rows[i].health == 0:
			if u.hp != 0 or u.name != "Empty rank": return false
	return true
