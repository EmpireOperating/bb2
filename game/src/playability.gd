extends RefCounted
## Read-only planning and optional instruction. Never grants resources or actions.

const LESSONS = ["move", "line", "attack", "recover", "retreat"]
var enabled = false
var learned: Array = []

func snapshot() -> Dictionary:
	return {"enabled":enabled,"learned":learned.duplicate()}

func restore(data: Variant) -> void:
	# Guidance is optional UI metadata. Older saves resume without interruption.
	enabled = false
	learned.clear()
	if not data is Dictionary or not data.get("enabled") is bool or not data.get("learned") is Array: return
	if data.learned.size() > LESSONS.size(): return
	for id in data.learned:
		if not id in LESSONS or id in learned: learned.clear(); return
		learned.append(id)
	enabled = data.enabled

func mark(id: String) -> void:
	if id in LESSONS and not id in learned: learned.append(id)

func observe_command(command: Array, b) -> void:
	if command.is_empty(): return
	var kind: String = command[0]
	if kind == "weapon" and command.size() > 3 and command[1] < b.player_slots() and command[3] >= 0: mark("attack")
	if kind in ["move","attack","recover","withdraw"] and command.size() > 1 and command[1] is int and command[1] < b.player_slots():
		mark("retreat" if kind == "withdraw" else kind)
	if kind == "guard" and command.size() > 1 and command[1] < b.player_slots(): mark("line")
	if kind == "order" and command.size() > 2 and command[2] == "line":
		for id in command[1]:
			if id < b.player_slots() and b.line_support(b.units[id]) > 0: mark("line")
	if kind in ["move","advance"]:
		for u in b.units:
			if u.side == 0 and b.line_support(u) > 0: mark("line")

func lesson(c) -> Dictionary:
	if c.over(): return {"title":"The company’s story","text":"Review the roll and memorial. New company replaces this save.","target":"company"}
	if c.phase == "aftermath": return {"title":"Bring the survivors home","text":"Deaths, wounds and damaged armour carry forward. Return to camp, inspect the roll, then let time, tools and medicine restore the company.","target":"camp"}
	if c.phase == "battle":
		if not "move" in learned: return {"title":"1 · Move with a purpose","text":"The gold portrait acts now. Click a lit empty hex toward your objective. Hover first: terrain and height change AP cost. Movement fatigue varies by person; the hover shows the exact cost.","target":"unit0"}
		if not "line" in learned and c.battle.core_rules: return {"title":"2 · Raise your shield","text":"On a shield bearer’s activation, use Shieldwall for 4 AP and the displayed fatigue. It doubles the shield bonus; adjacent active Shieldwalls add support. Formation orders alone grant no defence.","target":"guard"}
		if not "line" in learned: return {"title":"2 · Link your shields","text":"On a shield bearer’s activation, open Formation orders → Shield line. Adjacent ordered shields provide extra defence. The order costs 2 AP + 4 fatigue each; line movement costs one extra AP per hex. Keep your ordered shield bearers adjacent.","target":"formations"}
		if not "attack" in learned: return {"title":"3 · Read a strike","text":"Hover an enemy for hit odds. Click an enemy in range to attack. Space waits; F ends this fighter’s activation. Objective: "+c.battle.objective_text(),"target":"combat_details"}
		if not "recover" in learned and c.battle.core_rules: return {"title":"4 · Manage fatigue","text":"Recover spends 9 AP to remove half your fatigue (65% with Second Wind). Normal activation recovery is automatic. I opens a paused companion sheet; Space waits, F ends the activation.","target":"recover"}
		if not "recover" in learned: return {"title":"4 · Manage fatigue","text":"Select a tired soldier with at least 4 AP, then Recover. It removes up to 35 fatigue (50 with Second wind) and ends that soldier's turn. Fatigue lowers next-round initiative and limits available actions.","target":"recover"}
		if not "retreat" in learned: return {"title":"5 · Know your way out","text":"Withdraw moves one engaged soldier: 4 AP, 12 fatigue, and a strike from every adjacent foe. Retreat from contract leaves the whole battle unpaid. Open its confirmation to review the cost; Keep going cancels safely.","target":"retreat"}
		return {"title":"Take command","text":c.battle.objective_text()+" Keep shields linked, watch fatigue and leave a retreat route. These are real losses and costs.","target":"end"}
	if c.economy.enabled and c.active.is_empty() and c.in_town() and c.offers().is_empty(): return {"title":"Find a market or a new threat","text":c.work_hint(),"target":"resources"}
	if c.completed > 0:
		return {"title":"Prepare for the next job","text":"Open Company plan for treatment, repairs, unspent training and food/wage reserves. Next contract pay is uncertain until the work is done. Hire only when you can afford the daily wage too.","target":"planner"}
	if not c.encounter.is_empty(): return {"title":"The company is intercepted","text":"Take the field, or review the company’s equipment first. This encounter is separate from your accepted contract.","target":"deploy"}
	if not c.in_town() and c.active.is_empty(): return {"title":"Explore the Marches","text":"Click open ground to choose your route. Space pauses; 1, 2 and 3 choose travel speed. Watch for raider scouts and return to a town for supplies.","target":"world_pause"}
	if c.active.is_empty(): return {"title":"Take your first contract","text":"Start with Clear %s on %s's contract board. Consider hiring a fourth companion. Check pay, deadline and enemy count; keep money for wages and supplies." % [c.node("ford").name,c.node("ashwick").name],"target":"contracts"}
	if c.location != c.active.target or not c.overworld.at_site(c.active.target): return {"title":"Check the road before leaving","text":c.contract_direction()+" Follow the visible road and explore. Unknown terrain and routes stay hidden until you approach. Wages and rations settle at midnight.","target":"world"}
	return {"title":"Prepare, then deploy","text":"Check wounds and armour in Company plan. After a scout fight, consider returning to town to heal and repair before assaulting the camp. Resting near enemies can attract patrols.","target":"deploy"}

static func readiness(c) -> Array:
	var rows: Array = []
	for s in c.soldiers:
		if not s.alive: continue
		var issues: Array = []
		if s.hp < c.max_hp(s): issues.append("%d/%d HP" % [s.hp,c.max_hp(s)])
		if s.wound_days > 0: issues.append("%d injury days" % s.wound_days)
		var repair: int = c.repair_cost(s.id)
		if repair > 0: issues.append("%d repair tools" % repair)
		var ammo: int = c.ammo_refill_cost(s.id)
		if ammo > 0: issues.append("%d ammo to refill" % ammo)
		var points: int = c.Progression.points(s)
		if points > 0: issues.append("%d perk points" % points)
		var development: int = c.Progression.training_levels(s)
		if development > 0: issues.append("%d levels to train" % development)
		if "haunted" in s.scars: issues.append("starts wavering")
		if s.strain > 0 or c.Relationships.grief_penalty(s) > 0: issues.append("-%d resolve from strain/grief" % (s.strain*2+c.Relationships.grief_penalty(s)))
		rows.append({"id":s.id,"name":s.name,"text":" · ".join(issues) if not issues.is_empty() else "Ready for service","attention":not issues.is_empty()})
	return rows

static func forecast(c, target: String = "", rest: bool = false) -> Dictionary:
	var report = {"ok":false,"reason":"No legal journey.","rows":[]}
	if c.phase != "camp" or c.over(): report.reason = "The company cannot advance from this state."; return report
	var days: int = 1 if rest else c.travel_days(target)
	if days <= 0 or (not c.endless and c.day+days > 31): return report
	if not rest and c.active.get("kind","") == "escort" and c.next_escort_stop() != target:
		report.reason = "An escort must follow its route and defeat its ambush first."
		return report
	var copy = c.get_script().new()
	if not copy.restore(c.snapshot()): report.reason = "The current company could not be forecast."; return report
	var ok: bool = copy.rest_day() if rest else copy.travel(target)
	if not ok: return report
	var paid_job: bool = copy.wins > c.wins
	var reward: int = c.active.get("pay",0) if paid_job else 0
	var contract_status = "No active contract."
	if not c.active.is_empty():
		if paid_job: contract_status = "Delivery completes: %d crowns paid before arrival upkeep." % reward
		elif not copy.active.is_empty(): contract_status = "Contract due day %d · %d days left on arrival." % [copy.active.deadline,copy.active.deadline-copy.day]
		elif copy.reputation[c.active.client] < c.reputation[c.active.client]: contract_status = "Contract closes unpaid: expiry or company ending."
		else: contract_status = "World events resolve this job; no company payment."
	return {"ok":true,"reason":"","day":copy.day,"location":copy.location,"crowns":copy.crowns,"food":copy.food,"arrears":copy.arrears,"unpaid_days":copy.unpaid_days,"ending":copy.ending,"wages_paid":c.crowns+reward-copy.crowns,"food_used":c.food-copy.food,"rations_needed":days*c.alive_count(),"medicine_used":c.medicine-copy.medicine,"reward":reward,"contract":contract_status,"hunger":c.food < days*c.alive_count(),"rows":readiness(copy)}
