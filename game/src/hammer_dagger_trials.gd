extends RefCounted
## Developer fixtures only. Production startup never calls this script.
const T = preload("res://src/build_trials.gd")
const C = preload("res://src/campaign.gd")
const P = preload("res://src/perks.gd")
const NEW_PERKS = ["smackdown","hammer_mastery","deep_impact","between_the_ribs","dagger_mastery","swift_stabs"]

static func cohort(count: int = 3) -> Dictionary:
	var out = {"hammer":[],"dagger":[]}
	for seed_number in range(1,101):
		var c = C.new(); c.setup(seed_number)
		for family in out:
			if out[family].size() >= count: continue
			for s in c.soldiers:
				if family.capitalize() in s.perk_groups and "Shield" in s.perk_groups and "Swift" in s.perk_groups:
					out[family].append({"seed":seed_number,"id":s.id,"name":s.name,"background":s.background,"person_seed":s.person_seed}); break
		if out.hammer.size() == count and out.dagger.size() == count: break
	return out

static func train(c, id: int, family: String, shield: bool, level: int) -> bool:
	var s: Dictionary = c.soldiers[id]; var original = s.perk_pool.duplicate()
	var xp = c.Progression.THRESHOLDS[level-1]; var n = 0
	while s.xp < xp:
		c.Progression.grant(s,"battle_hammer_dagger_trial_%d" % n,mini(45,xp-s.xp),1,"Declared trial XP; saved normal growth and earned perk budgets."); n += 1
	var armor = "Medium" if shield and "Medium" in s.perk_groups else "Light" if "Light" in s.perk_groups else "Medium"
	var defense_perk = "nimble" if armor == "Light" else "poise"
	var picks = ["colossus","smackdown" if family == "hammer" else "between_the_ribs",family+"_mastery","swift_stabs" if family == "dagger" else "deep_impact"]
	picks.append_array(["shield_expert","phalanx",defense_perk,"indomitable","rotation"] if shield else ["duelist",defense_perk,"dodge","relentless","footwork"])
	for rank in level-1:
		if not c.develop(id,["health","skill","defense"]): return false
		var bought = false
		for perk in picks+P.CORE+s.perk_pool:
			if perk in ["gifted","nimble","poise","battle_forged"] and perk != defense_perk: continue
			if c.learn_perk(id,perk): bought = true; break
		if not bought: return false
	return original == s.perk_pool and s.perks.size() == level-1 and c.Progression.points(s) == 0

static func kit(c, family: String, shield: bool, level: int, groups: Array) -> Dictionary:
	var armor = "Medium" if shield and "Medium" in groups else "Light" if "Light" in groups else "Medium"
	var parts: Array = T.ARMOUR[armor].duplicate(); parts.reverse()
	for components in parts:
		var price: int = c.catalog[family].price+(c.catalog.shield.price if shield else 0)
		for definition in components: price += int(c.catalog[definition].price)
		if price <= T.BUDGET[level]:
			return {"weapon":family,"shield":shield,"carry":["",""],"parts":components.duplicate(),"cost":price,"budget":T.BUDGET[level],"armour":armor}
	return {}

static func profile(source: Dictionary, family: String, shield: bool, level: int) -> Dictionary:
	var c = C.new(); c.setup(source.seed); var s: Dictionary = c.soldiers[source.id]
	var ok = train(c,s.id,family,shield,level); var equipment = kit(c,family,shield,level,s.perk_groups)
	if equipment.is_empty(): return {"ok":false}
	T.equip(c,s.id,equipment)
	var copy = C.new(); ok = ok and copy.restore(c.snapshot()) and copy.snapshot() == c.snapshot()
	c.accept_job(c.offers()[0].id); c.travel("ford"); ok = ok and c.deploy()
	return {"ok":ok,"source":source,"role":family,"shield":shield,"level":level,"groups":s.perk_groups.duplicate(),"stars":s.aptitudes.duplicate(),"training":s.training.duplicate(true),"perks":s.perks.duplicate(),"kit":equipment,"unit":c.battle.units[s.id].duplicate(true)}
