extends RefCounted
## Generated careers for development trials. Never called by normal campaign startup.
const C = preload("res://src/campaign.gd")
const B = preload("res://src/battle.gd")
const P = preload("res://src/perks.gd")
const A = preload("res://src/arsenal.gd")
const Armor = preload("res://src/armor.gd")
const ROLES = ["shield","duelist","polearm","bow","crossbow","hybrid"]
const BUDGET = {3:400,6:600,11:800}
const ARMOUR = {
	"Light":[["light_quilt","leather","cap"],["light_quilt","short_mail","arming_cap","mail_curtain","cap"]],
	"Medium":[["linen","mail","nasal"],["gambeson","mail","leather","arming_cap","mail_coif","nasal"],["gambeson","long_mail","leather","arming_cap","mail_coif","bascinet"]],
	"Heavy":[["gambeson","mail","arming_cap","mail_coif","nasal"],["gambeson","heavy_mail","breastplate","arming_cap","mail_coif","bascinet"],["gambeson","heavy_mail","breastplate","shoulders","fur_mantle","arming_cap","mail_coif","bascinet","cheek_guards"]]}
const PICKS = {
	"shield":["colossus","shield_expert","brawny","rotation","indomitable","battle_forged","phalanx","spear_mastery","balance","poise","steel_brow","fortified_mind","underdog"],
	"duelist":["colossus","feint","dodge","sword_mastery","double_strike","nimble","duelist","en_garde","relentless","footwork","perfect_fit","poise"],
	"polearm":["colossus","leverage","brawny","polearm_mastery","reach_advantage","long_reach","killing_frenzy","perfect_fit","poise","battle_forged","footwork"],
	"bow":["colossus","target_practice","anticipation","bow_mastery","patient_hunter","hip_shooter","nimble","bullseye","head_hunter","footwork","overwhelm","perfect_fit","poise"],
	"crossbow":["colossus","power_shot","anticipation","crossbow_mastery","head_hunter","iron_sights","bullseye","perfect_fit","poise","footwork","nimble","killing_frenzy"],
	"hybrid":["colossus","hybridization","dodge","throwing_mastery","head_hunter","opportunist","duelist","nimble","footwork","sword_mastery","spear_mastery","perfect_fit","poise"]}
const TRAIN = {"shield":["health","defense","skill"],"duelist":["health","skill","defense"],"polearm":["health","skill","stamina"],"bow":["health","ranged_skill","stamina"],"crossbow":["health","ranged_skill","stamina"],"hybrid":["health","skill","ranged_skill"]}

static func eligible(s: Dictionary, role: String) -> bool:
	var required = {"shield":["Shield"],"duelist":["Sword","Swift"],"polearm":["Polearm"],"bow":["Bow"],"crossbow":["Crossbow"],"hybrid":["Throwing"]}[role]
	return required.all(func(g): return g in s.perk_groups)

static func cohort(count: int = 3) -> Dictionary:
	var result = {}
	for role in ROLES: result[role] = []
	for seed_number in range(1,101):
		var c = C.new(); c.setup(seed_number)
		for s in c.soldiers:
			for role in ROLES:
				if result[role].size() < count and not result[role].any(func(entry): return entry.seed == seed_number) and eligible(s,role): result[role].append({"seed":seed_number,"id":s.id,"name":s.name,"background":s.background,"person_seed":s.person_seed})
		if ROLES.all(func(role): return result[role].size() == count): break
	return result

static func kit(role: String, level: int, groups: Array, catalog: Dictionary, learned: Array = []) -> Dictionary:
	var armour = "Heavy" if role == "shield" and "Heavy" in groups else "Medium" if role in ["shield","polearm","crossbow"] and "Medium" in groups else "Light" if "Light" in groups else "Medium"
	if role == "duelist" and not "nimble" in learned: armour = "Medium"
	var weapons = {"shield":["heavy_spear","spear"],"duelist":["falchion","sword"],"polearm":["glaive","polearm"],"bow":["warbow","bow","shortbow"],"crossbow":["heavy_crossbow","crossbow"],"hybrid":["javelins"]}[role]
	for weapon in weapons:
		var parts = ARMOUR[armour].duplicate(); parts.reverse()
		for components in parts:
			var out = {"weapon":weapon,"shield":role == "shield","carry":["sword","throwing_axes"] if role == "hybrid" else ["dagger",""] if role in ["bow","crossbow"] else ["", ""],"parts":components.duplicate(),"armour":armour,"budget":BUDGET[level]}
			if role == "hybrid" and level == 3: out.carry = ["shortsword","javelins"]
			if role == "duelist" and not "duelist" in learned: out.shield = true
			var cost = int(catalog[weapon].price)+(int(catalog.shield.price) if out.shield else 0)
			for definition in components+out.carry+[A.ammo_type(weapon)]:
				if not definition.is_empty(): cost += int(catalog[definition].price)
			out["cost"] = cost; out["reserve"] = BUDGET[level]-cost
			if cost <= BUDGET[level]: return out
	return {}

static func train(c, id: int, role: String, level: int) -> bool:
	var s: Dictionary = c.soldiers[id]; var original = s.perk_pool.duplicate(); var xp = c.Progression.THRESHOLDS[level-1]
	var n = 0
	while s.xp < xp:
		c.Progression.grant(s,"battle_build_trial_%d" % n,mini(45,xp-s.xp),1,"Declared career trial XP; stats use saved ordinary growth."); n += 1
	for rank in level-1:
		if not c.develop(id,TRAIN[role]): return false
		var bought = false
		for perk in PICKS[role]+["fast_adaptation","pathfinder","fortified_mind","steel_brow","quick_hands"]+s.perk_pool:
			if perk != "gifted" and c.learn_perk(id,perk): bought = true; break
		if not bought: return false
	return s.perk_pool == original and s.perks.size() == level-1 and c.Progression.points(s) == 0

static func equip(c, id: int, equipment: Dictionary) -> void:
	var s: Dictionary = c.soldiers[id]
	s.gear.weapon = c.add_item(equipment.weapon); s.gear.shield = c.add_item("shield") if equipment.shield else ""
	var ammo = A.ammo_type(equipment.weapon); s.gear.ammo = c.add_item(ammo) if not ammo.is_empty() else ""
	for i in 2: s.gear["carry%d" % (i+1)] = c.add_item(equipment.carry[i]) if not equipment.carry[i].is_empty() else ""
	for group in ["body","head"]:
		var parts = Armor.empty_parts(group)
		for definition in equipment.parts:
			var d: Dictionary = c.catalog[definition]
			if d.group == group: parts[d.layer] = c.add_item(definition)
		s.gear[group] = c.add_assembly(group,parts)

static func profile(source: Dictionary, role: String, level: int) -> Dictionary:
	var c = C.new(); c.setup(source.seed); var s: Dictionary = c.soldiers[source.id]
	var starting = {}
	for key in ["base_hp","stamina","resolve","initiative","base_skill","base_defense","base_ranged_skill","base_ranged_defense"]: starting[key] = s[key]
	var ok = train(c,s.id,role,level); var equipment = kit(role,level,s.perk_groups,c.catalog,s.perks)
	if equipment.is_empty(): return {"ok":false}
	equip(c,s.id,equipment)
	var copy = C.new(); ok = ok and copy.restore(c.snapshot()) and copy.snapshot() == c.snapshot()
	c.accept_job(c.offers()[0].id); c.travel("ford"); ok = ok and c.deploy()
	var u: Dictionary = c.battle.units[s.id].duplicate(true)
	return {"ok":ok,"source":source,"role":role,"level":level,"stars":s.aptitudes.duplicate(),"groups":s.perk_groups.duplicate(),"perks":s.perks.duplicate(),"training":s.training.duplicate(true),"starting_stats":starting,"unit":u,"kit":equipment,"capacity":c.battle.fatigue_max(u),"fresh_initiative":c.battle.initiative_value(u)}

static func fixture_unit(b, id: int, level: int, threat: String) -> void:
	# Fixed opposition/support controls, explicitly authored rather than generated careers.
	var u: Dictionary = b.units[id]; var tier = [3,6,11].find(level)
	u.hp = 65+tier*15; u.max_hp = u.hp; u.skill = 60+tier*10; u.defense = 5+tier*7
	u.ranged_skill = 50+tier*10; u.ranged_defense = 5; u.stamina = 110+tier*10; u.initiative = 105; u.resolve = 55+tier*5
	u.name = threat+str(id); u.temperament = "none"; u.perks = []; u.perk_state = P.state(); u.fatigue = 0; u.morale_state = 0; u.morale = 85
	var role = "duelist" if threat == "rushers" else "shield" if threat in ["shields","support"] else "polearm"
	var groups = ["Sword","Spear","Polearm","Light","Medium","Shield","Swift","Tough","Trained"]
	if threat == "heavy": groups = ["Sword","Spear","Polearm","Medium","Heavy","Shield","Power","Tough","Trained"]
	var gear = kit(role,level,groups,b.armor_catalog)
	if threat == "rushers": gear.shield = false
	if threat == "heavy":
		gear = kit("shield",level,groups,b.armor_catalog); gear.weapon = "hammer" if id%2 else "maul"; gear.shield = false
	var temporary = {"perks":[]}; P.initialize(temporary,groups)
	for n in level-1:
		for perk in (["colossus","shield_expert","brawny","rotation","indomitable","battle_forged","phalanx"] if threat != "rushers" else ["colossus","feint","dodge","sword_mastery","double_strike","nimble","duelist"])+P.CORE+temporary.perk_pool:
			if perk != "gifted" and P.learn_reason(temporary,perk,level-1).is_empty(): temporary.perks.append(perk); break
	u.perks = temporary.perks.duplicate()
	if P.has(u,"colossus"): u.max_hp = floori(u.max_hp*1.25); u.hp = u.max_hp
	u.weapon = gear.weapon; u.shield = gear.shield; b.initialize_arms(u); u.armor_parts = []
	for definition in gear.parts:
		var d: Dictionary = b.armor_catalog[definition]
		u.armor_parts.append({"item":"control_%d_%s" % [id,definition],"definition":definition,"group":d.group,"layer":d.layer,"pool":"helmet" if d.group == "head" else "padding" if d.layer == "base" else "armor","condition":int(d.durability),"maximum":int(d.durability),"weight":int(d.weight)})
	for field in Armor.totals(u.armor_parts): u[field] = Armor.totals(u.armor_parts)[field]

static func place(b, profile_data: Dictionary, threat: String, side: int) -> int:
	for u in b.units: u.hp = 0
	for tile in b.tiles.values(): tile.terrain = "grass"; tile.height = 0
	var star = side*6
	for id in [0,1,2,6,7,8]:
		fixture_unit(b,id,profile_data.level,"support" if id/6 == side else threat)
		b.units[id].q = 3 if id < 6 else 9; b.units[id].r = 3+id%6
	var u: Dictionary = profile_data.unit.duplicate(true); u.id = star; u.side = side; u.comrades = []
	u.q = (2 if side == 0 else 10) if profile_data.role in ["bow","crossbow","polearm","hybrid"] else 3 if side == 0 else 9
	u.r = 3; u.damage_taken = 0; u.kills = 0; u.ap = 0; u.fatigue = 0; u.morale_state = 0; u.morale = 85; u.perk_state = P.state()
	b.units[star] = u; b.start_round()
	return star
