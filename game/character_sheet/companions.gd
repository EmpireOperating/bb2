extends RefCounted
## Fresh founders only. Vanilla talent/base packages; custom modest kits/perk
## routes for this game's existing economy and perk catalogue (not BB origin gear).
const Perks = preload("res://src/perks.gd")
const ROLES = ["two_handed","shield","ranged"]
const PROFILES = {
 "two_handed":{"name":"Companion (2H)","talents":{"skill":2,"defense":1,"resolve":1},
  "ranges":[[60,65],[95,105],[40,45],[95,110],[57,62],[32,42],[2,5],[2,5]],
  "groups":["Spear","Sword","Polearm","Crossbow","Light","Medium","Power","Swift","Tough","Trained"]},
 "shield":{"name":"Companion (Shield)","talents":{"health":2,"stamina":1,"resolve":1},
  "ranges":[[50,60],[95,105],[40,45],[100,110],[57,62],[37,47],[5,10],[5,10]],
  "groups":["Sword","Spear","Mace","Throwing","Light","Medium","Shield","Power","Tough","Vigorous"]},
 "ranged":{"name":"Companion (Ranged)","talents":{"ranged_skill":2,"ranged_defense":1,"initiative":1},
  "ranges":[[50,60],[90,100],[35,45],[105,115],[52,57],[48,52],[0,5],[0,5]],
  "groups":["Bow","Throwing","Crossbow","Spear","Light","Medium","Marksman","Swift","Fast","Trained"]}
}
static func initialize_created(p: Dictionary, role: String, attrs: Array, fields: Dictionary) -> void:
 # This is construction, never an upgrade/inspection/load path. No second tree.
 assert(not p.has("growth_version") and not p.has("perk_version"))
 var profile: Dictionary = PROFILES[role]
 p.name = profile.name; p["companion_role"] = role
 var rng: int = 1+posmod(int(p.person_seed)+730201,2147483646)
 for i in attrs.size():
  var attr: String = attrs[i]
  var bounds: Array = profile.ranges[i]
  rng = (rng*48271)%2147483647
  p[fields[attr]] = bounds[0]+rng%(bounds[1]-bounds[0]+1)
  p.aptitudes[attr] = profile.talents.get(attr,0)
 # Explicit authored founder affinities, using the unchanged normal pool rules.
 # No already-created person's saved groups, learned perks or pool are reset.
 p["perk_version"] = 6; p["perk_groups"] = profile.groups.duplicate()
 p["perk_pool"] = Perks.pool(p.perk_groups,true); p["gifted_choices"] = []
static func modest_kit(p: Dictionary) -> void:
 var role: String = p.get("companion_role","")
 if role.is_empty(): return
 p.weapon = {"two_handed":"pike","shield":"shortsword","ranged":"shortbow"}[role]
 p.loadout.weapon = p.weapon
 p.loadout.shield = "buckler" if role == "shield" else ""
 p.carried_loadout = ["knife",""] if role == "ranged" else ["",""]
 p.ammo_loadout = "arrows" if role == "ranged" else ""
