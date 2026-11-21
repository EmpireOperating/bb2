extends RefCounted
## Versioned, isolated population RNG. Browsing and combat never consume it.
const ATTRS = ["health","skill","defense","endurance","resolve"]
const LABELS = {"health":"Health","skill":"Attack skill","defense":"Defence","endurance":"Recovery","resolve":"Resolve"}
const FIELDS = {"health":"base_hp","skill":"base_skill","defense":"base_defense","endurance":"endurance","resolve":"resolve"}
const TEMPERAMENTS = {
	"aggressive":{"name":"Aggressive","effect":"+5 attack accuracy; attacks cost 4 extra fatigue."},
	"cautious":{"name":"Cautious","effect":"-4 attack accuracy; enemies have -5 accuracy against this soldier."},
	"loner":{"name":"Independent","effect":"+8 accuracy without adjacent allies; -4 with an adjacent ally."},
	"gregarious":{"name":"Sociable","effect":"+6 accuracy beside an ally; -4 without one."},
	"stoic":{"name":"Stoic","effect":"Morale shocks reduced by 3; recovers 3 less fatigue each turn."},
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
	var hp = roll(71,86)+bg.hp-(4 if experienced else 0)
	var skill = roll(64,75)+bg.skill+(3 if experienced else 0)
	var defense = roll(11,20)+bg.defense+(2 if experienced else 0)
	var endurance = roll(22,29)+bg.endurance-(2 if experienced else 0)
	var resolve = roll(-2,2)+bg.resolve
	var mobility = roll(2,4)
	var temperament: String = TEMPERAMENTS.keys()[roll(0,5)]
	var aptitudes: Dictionary = {}
	for attr in ATTRS: aptitudes[attr] = 0
	var first = roll(0,4)
	var second = (first+roll(1,4))%5
	aptitudes[ATTRS[first]] = roll(1,3)
	aptitudes[ATTRS[second]] = roll(1,3)
	var weapon: String = bg.weapons[roll(0,bg.weapons.size()-1)]
	var body = "mail" if (experienced or roll(0,2) == 0) else "leather"
	var loadout = {"weapon":weapon,"body":body,"under":"gambeson" if roll(0,3) == 0 else "linen","head":"nasal" if experienced and roll(0,1) == 0 else "cap","shield":"shield" if weapon != "bow" and roll(0,3) != 0 else ""}
	var wage = clampi(3+(skill-63)/6+(defense-11)/8+(1 if body == "mail" else 0),3,6 if starter else 8)
	var price = 65+wage*15+(35 if body == "mail" else 0)+aptitudes[ATTRS[first]]*8
	return {"person":person_name,"name":bg.name,"trait":TEMPERAMENTS[temperament].name,"hp":hp,"skill":skill,"defense":defense,"wage":wage,"price":price,"weapon":weapon,"loadout":loadout,"person_seed":identity_seed,"age":age,"endurance":endurance,"mobility":mobility,"resolve":resolve,"temperament":temperament,"aptitudes":aptitudes,"development":[]}

static func neutral(s: Dictionary) -> void:
	for pair in [["person_seed",0],["age",0],["endurance",25],["mobility",3],["resolve",0],["temperament","none"],["development",[]]]:
		s[pair[0]] = pair[1]
	s["aptitudes"] = {"health":0,"skill":0,"defense":0,"endurance":0,"resolve":0}

static func copy_identity(from: Dictionary, to: Dictionary) -> void:
	for key in ["person_seed","age","endurance","mobility","resolve","temperament","aptitudes","development"]:
		to[key] = from[key].duplicate(true) if from[key] is Array or from[key] is Dictionary else from[key]

static func growth(s: Dictionary, attr: String) -> int:
	var talent: int = s.aptitudes[attr]
	match attr:
		"health": return 4+talent*2
		"skill": return 2+talent
		"defense": return 1+talent
		"endurance": return 1+talent
		"resolve": return 1+talent/2
	return 0

static func recovery(s: Dictionary) -> int:
	return maxi(1,s.endurance-int(s.get("load",0))/12-(3 if s.temperament == "stoic" else 0)-(5 if "damaged_lung" in s.get("scars",[]) else 0))

static func move_rate(s: Dictionary) -> int:
	return maxi(1,s.mobility+int(s.get("load",0))/24-(1 if s.temperament == "restless" else 0))

static func validate(s: Dictionary) -> bool:
	for spec in [["person_seed",0,2147483646],["age",0,65],["endurance",15,48],["mobility",2,4],["resolve",-5,12]]:
		if not s.get(spec[0]) is int or s[spec[0]] < spec[1] or s[spec[0]] > spec[2]: return false
	if s.age != 0 and s.age < 18: return false
	if not s.get("temperament") is String or not TEMPERAMENTS.has(s.temperament): return false
	if not s.get("aptitudes") is Dictionary or s.aptitudes.size() != ATTRS.size(): return false
	for attr in ATTRS:
		if not s.aptitudes.get(attr) is int or s.aptitudes[attr] < 0 or s.aptitudes[attr] > 3: return false
	if not s.get("development") is Array or s.development.size() > 3: return false
	for attr in s.development:
		if not attr is String or not attr in ATTRS: return false
	return true

static func validate_offer(p: Variant) -> bool:
	if not p is Dictionary or not validate(p): return false
	for field in ["id","person","name","trait","weapon"]:
		if not p.get(field) is String or p[field].is_empty() or p[field].length() > 100: return false
	for spec in [["hp",60,100],["skill",60,85],["defense",8,30],["wage",3,8],["price",80,300]]:
		if not p.get(spec[0]) is int or p[spec[0]] < spec[1] or p[spec[0]] > spec[2]: return false
	if not p.get("loadout") is Dictionary or p.loadout.size() != 5 or p.loadout.get("weapon") != p.weapon: return false
	for slot in {"weapon":["sword","axe","spear","bow","mace","hammer","dagger","polearm","crossbow"],"body":["mail","leather"],"under":["linen","gambeson"],"head":["cap","nasal"],"shield":["","shield"]}:
		if not p.loadout.get(slot) in {"weapon":["sword","axe","spear","bow","mace","hammer","dagger","polearm","crossbow"],"body":["mail","leather"],"under":["linen","gambeson"],"head":["cap","nasal"],"shield":["","shield"]}[slot]: return false
	return (not p.weapon in ["bow","crossbow","polearm"] or p.loadout.shield == "") and p.development.is_empty()
