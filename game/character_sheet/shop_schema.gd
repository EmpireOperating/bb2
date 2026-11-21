extends SceneTree
const Offers = preload("res://company_town/equipment_offer.gd")
const Arsenal = preload("res://src/arsenal.gd")
var checks := 0
var failures: Array = []
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures.append(message);print("FAIL ",message)
func _initialize() -> void:
 var s = load("res://next_build/session.gd").new();s.setup(7391)
 var c = s.campaign
 var before: String = s._canonical(c.snapshot())
 var catalogue: String = s._canonical(c.catalog)
 var profiles: String = s._canonical(c.battle.weapons)
 for definition: String in c.catalog:
  var d: Dictionary = c.catalog[definition]
  if d.get("assembly",false): continue
  var offer := {"id":"read-only-schema:"+definition,"definition":definition,"price":17}
  var immutable: String = s._canonical(offer)
  var lines := Offers.lines(offer,c.catalog,c.battle.weapons)
  var text := "\n".join(lines)
  check(not text.is_empty() and lines.size() <= 2,definition+" readable bounded property lines")
  check(not "0/0" in text and not "BROKEN" in text and not "immutable roll" in text,definition+" offer does not invent owned condition/roll")
  if d.slot == "weapon":
   var w: Dictionary = c.battle.weapons[d.get("weapon",definition)]
   check("Base damage %d–%d" % [w.min,w.max] in text,definition+" real min/max")
   check("Armor dmg %d%%" % roundi(float(w.armor)*100) in text,definition+" real armor multiplier")
   check("Penetration %d%%" % roundi(float(w.pierce)*100) in text,definition+" real pierce")
   check("Accuracy %+d" % w.skill in text,definition+" real accuracy")
   check("Reach %d–%d" % [w.min_range,w.reach] in text,definition+" real range")
   check("%d AP / %d fatigue" % [w.ap,w.fatigue] in text,definition+" base basic costs")
   check("Hands %d" % w.hands in text,definition+" actual hands")
   if not str(w.get("ammo","")).is_empty():check("Uses "+str(w.ammo) in text,definition+" actual ammo requirement")
   if int(d.get("durability",0)) > 0:check("Bundle %d" % d.durability in text,definition+" thrown supply is not armor")
  elif d.slot == "shield":
   var unit := {"shield":true,"perks":[],"arms":{"shield":{"definition":definition}}}
   c.battle.armor_catalog = c.catalog
   check("Melee defense %+d" % c.battle.shield_defence(unit,false) in text,definition+" actual shield melee including legacy defaults")
   check("Ranged defense %+d" % c.battle.shield_defence(unit,true) in text,definition+" actual shield ranged including legacy defaults")
   check("Base durability %d" % d.durability in text and not "protection" in text,definition+" shield durability not body protection")
  elif d.slot == "ammo":
   check("Rounds %d" % d.durability in text and str(d.ammo).capitalize() in text,definition+" actual ammo type/capacity")
   check(not "durability" in text and not "protection" in text,definition+" rounds are not protection")
  elif int(d.get("durability",0)) > 0:
   check("Base protection / durability %d" % d.durability in text,definition+" actual armor maximum not invented defense")
  if Arsenal.LOAD.has(definition):check("Load %d" % Arsenal.LOAD[definition] in text,definition+" real arm load")
  elif d.has("weight"):check("Load %d" % d.weight in text,definition+" real armor/support weight")
  check(s._canonical(offer) == immutable,definition+" exact offer nonmutation")
 var cases := {"sword_gloves":"Melee skill +4","archer_gloves":"Ranged skill +4","light_boots":"Initiative +4","trail_boots":"Move fatigue -1/edge","travel_cloak":"Recovery +1","scholar_cloak":"Ranged defense +3","breather_belt":"Stamina +4","pouch_belt":"Reserve capacity +1"}
 for definition: String in cases:
  check(cases[definition] in "\n".join(Offers.lines({"definition":definition},c.catalog,c.battle.weapons)),definition+" actual support utility")
 check("Reserve load -1/slot" in "\n".join(Offers.lines({"definition":"pouch_belt"},c.catalog,c.battle.weapons)),"pouch after-halving reserve load utility")
 check("No armor protection" in "\n".join(Offers.lines({"definition":"sword_gloves"},c.catalog,c.battle.weapons)),"zero maximum utility is not broken armor")
 for offer in [{},{"definition":"missing"}]:
  check(Offers.lines(offer,c.catalog,c.battle.weapons) == PackedStringArray(["Properties unavailable."]),"missing/empty offer safe unavailable")
 var partial := {"partial":{"slot":"weapon","weapon":"partial","durability":null,"weight":null}}
 check(Offers.lines({"definition":"partial"},partial,{"partial":{"min":null,"max":null,"armor":null,"fatigue":null}}) == PackedStringArray(["Properties unavailable."]),"missing/null values do not become false zero stats")
 check("rolls assigned on purchase" in Offers.BASE_NOTE,"base values clearly distinguished from future physical roll")
 check(s._canonical(c.snapshot()) == before and s._canonical(c.catalog) == catalogue and s._canonical(c.battle.weapons) == profiles,"all projections preserve entire campaign catalogue and profiles")
 print("SHOP_SCHEMA checks=",checks," failures=",failures.size())
 quit(int(not failures.is_empty()))
