extends RefCounted
const Perks = preload("res://src/legacy_perks_v18.gd")
const Arsenal = preload("res://src/legacy_arsenal_v18.gd")
## Versioned, isolated population RNG. Browsing and combat never consume it.
const ATTRS = ["health","stamina","resolve","initiative","skill","ranged_skill","defense","ranged_defense"]
const LABELS = {"health":"Health","stamina":"Stamina","resolve":"Resolve","initiative":"Initiative","skill":"Melee skill","ranged_skill":"Ranged skill","defense":"Melee defence","ranged_defense":"Ranged defence"}
const FIELDS = {"health":"base_hp","skill":"base_skill","defense":"base_defense","ranged_skill":"base_ranged_skill","ranged_defense":"base_ranged_defense","stamina":"stamina","initiative":"initiative","resolve":"resolve"}
const OFFER_FIELDS = {"health":"hp","skill":"skill","defense":"defense","ranged_skill":"base_ranged_skill","ranged_defense":"base_ranged_defense","stamina":"stamina","initiative":"initiative","resolve":"resolve"}
const TEMPERAMENTS = {
	"aggressive":{"name":"Aggressive","effect":"+5 attack accuracy; attacks cost 4 extra fatigue."},
	"cautious":{"name":"Cautious","effect":"-4 attack accuracy; +5 melee and ranged defence."},
	"loner":{"name":"Independent","effect":"+8 accuracy without adjacent allies; -4 with an adjacent ally."},
	"gregarious":{"name":"Sociable","effect":"+6 accuracy beside an ally; -4 without one."},
	"stoic":{"name":"Stoic","effect":"+10 resolve on morale checks; -5 initiative."},
	"restless":{"name":"Restless","effect":"Movement costs 1 less fatigue per AP (minimum 1); guarding costs 5 extra fatigue."},
	"none":{"name":"Earlier service","effect":"No temperament was recorded. Existing combat behaviour is preserved."}
}
const BACKGROUNDS = [
	{"name":"Militia","hp":0,"skill":2,"defense":5,"endurance":0,"resolve":1,"weapons":["spear","sword","axe"]},
	{"name":"Poacher","hp":-5,"skill":5,"defense":-3,"endurance":1,"resolve":-1,"weapons":["bow","bow","spear"]},
	{"name":"Woodcutter","hp":9,"skill":-3,"defense":-2,"endurance":3,"resolve":0,"weapons":["axe","axe","spear"]},
	{"name":"Deserter","hp":0,"skill":5,"defense":3,"endurance":-2,"resolve":-2,"weapons":["sword","spear","axe"]},
	{"name":"Caravan guard","hp":2,"skill":1,"defense":3,"endurance":1,"resolve":2,"weapons":["spear","sword","bow"]},
	{"name":"Farmhand","hp":6,"skill":-2,"defense":0,"endurance":2,"resolve":0,"weapons":["spear","axe","sword"]},
	{"name":"Gravedigger","hp":3,"skill":-1,"defense":1,"endurance":0,"resolve":3,"weapons":["spear","axe","sword"]},
	{"name":"Outrider","hp":-2,"skill":3,"defense":0,"endurance":1,"resolve":0,"weapons":["bow","sword","spear"]}
]
# Inclusive starting ranges in ATTRS order. These are prototype backgrounds;
# militia, poacher and farmhand use the pinned BB baseline ranges.
const START_RANGES = {
 "Militia":[[50,60],[93,105],[33,45],[100,110],[52,62],[38,47],[2,7],[2,7]],
 "Poacher":[[50,60],[93,100],[25,45],[100,110],[49,57],[47,49],[0,5],[0,5]],
 "Woodcutter":[[60,70],[100,115],[30,40],[95,105],[50,60],[32,42],[0,5],[0,5]],
 "Deserter":[[50,60],[90,100],[20,30],[95,105],[52,62],[32,42],[3,8],[0,5]],
 "Caravan guard":[[55,65],[95,110],[35,45],[100,110],[50,60],[35,45],[2,7],[0,5]],
 "Farmhand":[[62,70],[100,120],[28,37],[100,110],[47,57],[32,42],[0,5],[0,5]],
 "Gravedigger":[[55,65],[90,105],[40,50],[95,110],[47,57],[32,42],[0,5],[0,5]],
 "Outrider":[[50,60],[95,105],[30,40],[105,120],[50,60],[45,60],[0,5],[2,7]]
}
const GROWTH_RANGES = {"health":[2,4],"stamina":[2,4],"resolve":[2,4],"initiative":[3,5],"skill":[1,3],"ranged_skill":[2,4],"defense":[1,3],"ranged_defense":[2,4]}
const NAMES = ["Runa","Hagen","Ulric","Greta","Wendel","Ida","Konrad","Mara","Otmar","Frida","Bertold","Anselm","Alva","Baldur","Cora","Dagmar","Elmar","Falk","Gerta","Hilda","Ivar","Jora","Kurt","Lena","Marta","Nils","Orla","Petra","Ralf","Sigrid","Torsten","Ulla","Vera","Walther","Ylva","Zora","Arne","Berta","Claus","Dieter","Elsa","Freda","Gunnar","Hedda","Ilse","Jost","Klara","Leif","Maren","Norbert","Oskar","Pavel","Rika","Sven","Tilda","Ulf","Volker","Willa","Yorick","Zita","Adela","Bruno","Caspar","Dora","Erik","Fenna","Gero","Helga","Inga","Jannik","Kuno","Lotte","Mikkel","Nora","Oda","Per","Rolf","Sanna","Tove","Viggo"]
var state = 1
func roll(low: int, high: int) -> int:
	state = (state*48271)%2147483647
	return low+state%(high-low+1)

func population(seed_number: int) -> Dictionary:
	state = 1+posmod(seed_number,2147483646)
	var names = NAMES.duplicate()
	var founders: Array = []
	var pools: Dictionary = {}
	for i in 36:
		var name: String = names.pop_at(roll(0,names.size()-1))
		var person = generate(name,i < 6)
		if i < 6: founders.append(person)
		else:
			var index = i-6
			var town: String = ["ashwick","stonecross","dunmere"][index/10]
			var week = (index%10)/2
			person["id"] = "%s_recruit_%d_%d" % [town,week,index%2]
			pools[person.id] = person
	# Viability changes equipment only, never replaces the rolled people or talents.
	var bows = 0
	var shields = 0
	var mail = 0
	for person in founders:
		if person.weapon == "bow":
			bows += 1
			if bows > 2: person.weapon = "spear"; person.loadout.weapon = "spear"
		if person.weapon != "bow" and shields < 3: person.loadout.shield = "shield"; shields += 1
		if person.loadout.body == "mail": mail += 1
	for person in founders:
		if mail >= 2: break
		if person.loadout.body != "mail": person.loadout.body = "mail"; mail += 1
	return {"founders":founders,"pools":pools}

func generate(person_name: String, starter: bool) -> Dictionary:
	var identity_seed = state
	var bg: Dictionary = BACKGROUNDS[roll(0,BACKGROUNDS.size()-1)]
	var age = roll(18,49)
	var experienced = age >= 34
	var stats = {}
	for i in ATTRS.size(): stats[ATTRS[i]] = roll(START_RANGES[bg.name][i][0],START_RANGES[bg.name][i][1])
	var hp: int = stats.health
	var skill: int = stats.skill
	var defense: int = stats.defense
	var endurance = 25 # Retained only for historical schema compatibility.
	var resolve: int = stats.resolve
	var stamina: int = stats.stamina
	var initiative: int = stats.initiative
	var ranged_skill: int = stats.ranged_skill
	var ranged_defense: int = stats.ranged_defense
	var mobility = roll(2,4)
	var temperament: String = TEMPERAMENTS.keys()[roll(0,5)]
	var aptitudes: Dictionary = {}
	for attr in ATTRS: aptitudes[attr] = 0
	var candidates = ATTRS.duplicate()
	for i in 3:
		var attr: String = candidates.pop_at(roll(0,candidates.size()-1))
		var chance = roll(1,100)
		aptitudes[attr] = 1 if chance <= 60 else (2 if chance <= 90 else 3)
	var weapon: String = bg.weapons[roll(0,bg.weapons.size()-1)]
	var body = "mail" if (experienced or roll(0,2) == 0) else "leather"
	var loadout = {"weapon":weapon,"body":body,"under":"gambeson" if roll(0,3) == 0 else "linen","head":"nasal" if experienced and roll(0,1) == 0 else "cap","shield":"shield" if weapon != "bow" and roll(0,3) != 0 else ""}
	var wage = clampi(3+(skill-63)/6+(defense-11)/8+(1 if body == "mail" else 0),3,6 if starter else 8)
	var price = 65+wage*15+(35 if body == "mail" else 0)+aptitudes.values().max()*8
	var person = {"stat_rules":true,"stamina":stamina,"initiative":initiative,"base_ranged_skill":ranged_skill,"base_ranged_defense":ranged_defense,"person":person_name,"name":bg.name,"trait":TEMPERAMENTS[temperament].name,"hp":hp,"skill":skill,"defense":defense,"wage":wage,"price":price,"weapon":weapon,"loadout":loadout,"person_seed":identity_seed,"age":age,"endurance":endurance,"mobility":mobility,"resolve":resolve,"temperament":temperament,"aptitudes":aptitudes,"development":[]}

	initialize_growth(person)
	return person

static func neutral(s: Dictionary) -> void:
	for pair in [["person_seed",0],["age",0],["endurance",25],["mobility",3],["resolve",0],["temperament","none"],["development",[]]]:
		s[pair[0]] = pair[1]
	s["aptitudes"] = {"health":0,"skill":0,"defense":0,"endurance":0,"resolve":0}

static func copy_identity(from: Dictionary, to: Dictionary) -> void:
	for key in ["person_seed","age","endurance","mobility","resolve","temperament","aptitudes","development","stat_rules","stamina","initiative","base_ranged_skill","base_ranged_defense","growth_version","growth_offers","training","legacy_training"]:
		to[key] = from[key].duplicate(true) if from[key] is Array or from[key] is Dictionary else from[key]

static func growth_range(s: Dictionary, attr: String) -> Array:
	var stars: int = s.aptitudes[attr]
	var base: Array = GROWTH_RANGES[attr]
	return [base[0]+(2 if stars == 3 else stars),base[1]+(1 if stars == 3 else 0)]

static func roll_growth(s: Dictionary) -> Array:
	# Independent RNG: neither population generation nor combat consumes these rolls.
	var rng = 1+posmod(int(s.person_seed)+170017,2147483646)
	var offers: Array = []
	for i in 10:
		var row = {}
		for attr in ATTRS:
			var bounds = growth_range(s,attr)
			rng = (rng*48271)%2147483647
			row[attr] = bounds[0]+rng%(bounds[1]-bounds[0]+1)
		offers.append(row)
	return offers

static func initialize_growth(s: Dictionary, imported: bool = false) -> void:
	if s.get("growth_version",0) == 1: return
	if imported:
		var rng = 1+posmod(int(s.person_seed)+170039,2147483646)
		var candidates = ATTRS.filter(func(a): return s.aptitudes[a] == 0)
		var count = s.aptitudes.values().filter(func(v): return v > 0).size()
		while count < 3:
			rng = (rng*48271)%2147483647
			var attr: String = candidates.pop_at(rng%candidates.size())
			rng = (rng*48271)%2147483647
			var chance = 1+rng%100
			s.aptitudes[attr] = 1 if chance <= 60 else (2 if chance <= 90 else 3)
			count += 1
	s["growth_version"] = 1
	s["growth_offers"] = roll_growth(s)
	s["legacy_training"] = s.development.duplicate() if imported else []
	s["training"] = []
	for i in 10: s.training.append([s.legacy_training[i]] if i < s.legacy_training.size() else [])

static func pending_index(s: Dictionary, earned_levels: int = 10) -> int:
	if s.get("growth_version",0) != 1: return -1
	for i in mini(10,earned_levels):
		if s.training[i].size() < 3: return i
	return -1

static func growth(s: Dictionary, attr: String) -> int:
	if s.get("growth_version",0) != 1: return preload("res://src/legacy_people_v16.gd").growth(s,attr)
	var index = pending_index(s)
	return s.growth_offers[index][attr] if index >= 0 else 0

static func validate_growth(s: Dictionary) -> bool:
	if s.get("growth_version") != 1 or not s.get("growth_offers") is Array or not s.get("training") is Array or not s.get("legacy_training") is Array: return false
	if s.growth_offers != roll_growth(s) or s.training.size() != 10 or s.legacy_training.size() > 3: return false
	for attr in s.legacy_training:
		if not attr in ATTRS: return false
	var actual: Array = []
	var unfinished = false
	for i in 10:
		var row = s.training[i]
		if not row is Array or row.size() > 3: return false
		var unique = {}
		for attr in row:
			if not attr is String or not attr in ATTRS or unique.has(attr): return false
			unique[attr] = true
			actual.append(attr)
		if i < s.legacy_training.size():
			if row.is_empty() or row[0] != s.legacy_training[i] or row.size() == 2: return false
		elif row.size() not in [0,3]: return false
		if unfinished and row.size() == 3: return false
		if row.size() < 3: unfinished = true
	var recorded: Array = s.development.duplicate()
	actual.sort(); recorded.sort()
	return actual == recorded

static func recovery(s: Dictionary) -> int:
	if s.get("stat_rules",false): return 15-(5 if "damaged_lung" in s.get("scars",[]) else 0)
	return maxi(1,s.endurance-int(s.get("load",0))/12-(3 if s.temperament == "stoic" else 0)-(5 if "damaged_lung" in s.get("scars",[]) else 0))

static func move_rate(s: Dictionary) -> int:
	if s.get("stat_rules",false): return 1 if s.temperament == "restless" else 2
	return maxi(1,s.mobility+int(s.get("load",0))/24-(1 if s.temperament == "restless" else 0))

static func equipment_load(s: Dictionary) -> int:
	return Perks.armor_load(s)+Arsenal.load(s.get("arms",{}))

static func fatigue_max(s: Dictionary) -> int:
	return maxi(15,int(s.get("stamina",100))-equipment_load(s)) if s.get("stat_rules",false) else 100

static func initiative_value(s: Dictionary) -> int:
	return maxi(0,int(s.get("initiative",100))-equipment_load(s)-int(s.get("fatigue",0))-(5 if s.get("temperament","") == "stoic" else 0))

static func upgrade(s: Dictionary, offer: bool = false) -> void:
	# No rerolls. Existing general skill/defence becomes both specialisations.
	if s.get("stat_rules",false): return
	s["legacy_resolve"] = s.resolve
	s["stat_rules"] = true
	s["base_ranged_skill"] = s.get("skill",s.get("base_skill",65))
	s["base_ranged_defense"] = s.get("defense",s.get("base_defense",10))
	s["stamina"] = 100+(int(s.endurance)-25)*2
	s["initiative"] = 100
	s.resolve = 40+int(s.resolve)*3
	var old: Dictionary = s.aptitudes.duplicate()
	s.aptitudes = {}
	for attr in ATTRS: s.aptitudes[attr] = old.get(attr,0)
	s.aptitudes.ranged_skill = old.get("skill",0)
	s.aptitudes.ranged_defense = old.get("defense",0)
	s.aptitudes.stamina = old.get("endurance",0)
	for i in s.development.size():
		if s.development[i] == "endurance": s.development[i] = "stamina"

static func validate(s: Dictionary) -> bool:
	if s.get("stat_rules") != true: return false
	for spec in [["person_seed",0,2147483646],["age",0,65],["endurance",15,48],["mobility",2,4],["resolve",10,204],["stamina",60,254],["initiative",50,245],["base_ranged_skill",0,204],["base_ranged_defense",0,154]]:
		if not s.get(spec[0]) is int or s[spec[0]] < spec[1] or s[spec[0]] > spec[2]: return false
	if s.age != 0 and s.age < 18: return false
	if not s.get("temperament") is String or not TEMPERAMENTS.has(s.temperament): return false
	if not s.get("aptitudes") is Dictionary or s.aptitudes.size() != ATTRS.size(): return false
	for attr in ATTRS:
		if not s.aptitudes.get(attr) is int or s.aptitudes[attr] < 0 or s.aptitudes[attr] > 3: return false
	if not s.get("development") is Array or s.development.size() > 30: return false
	for attr in s.development:
		if not attr is String or not attr in ATTRS: return false
	return validate_growth(s)

static func validate_offer(p: Variant) -> bool:
	if not p is Dictionary or not validate(p): return false
	for field in ["id","person","name","trait","weapon"]:
		if not p.get(field) is String or p[field].is_empty() or p[field].length() > 100: return false
	for spec in [["hp",40,100],["skill",40,90],["defense",0,35],["wage",3,8],["price",80,300]]:
		if not p.get(spec[0]) is int or p[spec[0]] < spec[1] or p[spec[0]] > spec[2]: return false
	if not p.get("loadout") is Dictionary or p.loadout.size() != 5 or p.loadout.get("weapon") != p.weapon: return false
	for slot in {"weapon":Arsenal.WEAPONS,"body":["mail","leather"],"under":["linen","gambeson"],"head":["cap","nasal"],"shield":["","shield"]}:
		if not p.loadout.get(slot) in {"weapon":Arsenal.WEAPONS,"body":["mail","leather"],"under":["linen","gambeson"],"head":["cap","nasal"],"shield":["","shield"]}[slot]: return false
	return (not p.weapon in Arsenal.TWO_HANDS or p.loadout.shield == "") and p.development.is_empty()
