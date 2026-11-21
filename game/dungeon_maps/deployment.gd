extends RefCounted
## Adapts an already stock-deployed Battle, never creates units or opens a turn.
const Generator = preload("res://dungeon_maps/generator.gd")
const Battle = preload("res://src/battle.gd")
const Opening = preload("res://dungeon_maps/canonical_opening.gd")

## For an already admitted canonical packet on the configured campaign. The
## stock deploy still owns every body, role, loadout, initiative and RNG draw.
static func canonical_profile(candidate, packet: Dictionary) -> Array:
 var b = candidate.battle
 if b.ambush or b.units.size()!=24 or b.player_slots()!=12 or candidate.deployment.size()!=12 or candidate.formation.size()!=18: return []
 var d: Dictionary=packet.descriptor
 var player_pad: Array=d.presentation.player_anchors
 var enemy_pad: Array=d.presentation.enemy_anchors
 var axis: Dictionary=d.presentation.opening_axis
 var positions := []; positions.resize(24)
 var used := {}; var vacant := []
 for i in 12:
  var id: int=candidate.deployment[i]
  if id<0:vacant.append(i);continue
  var slot: int=candidate.formation.find(id)
  if slot<0 or used.has(player_pad[slot]):return []
  positions[i]=player_pad[slot];used[positions[i]]=true
 if not _fill_vacancies(positions,vacant,packet.spawns.slice(0,12)+player_pad,used):return []
 vacant.clear()
 var front_q := Opening.enemy_front_q(packet.field)
 for i in range(12,24):
  var u: Dictionary=b.units[i]
  if not b.living(u):vacant.append(i);continue
  var p := Opening.enemy_cell(axis.enemy,u.q-front_q,u.r-1)
  if not enemy_pad.has(p) or used.has(p):return []
  positions[i]=p;used[p]=true
 if not _fill_vacancies(positions,vacant,packet.spawns.slice(12)+enemy_pad,used):return []
 return positions

static func _fill_vacancies(positions: Array, vacant: Array, preferred: Array, used: Dictionary) -> bool:
 var cursor := 0
 for i in vacant:
  while cursor<preferred.size() and used.has(preferred[cursor]):cursor+=1
  if cursor==preferred.size():return false
  var p: Vector2i=preferred[cursor]
  positions[i]=p;used[p]=true
 return true

static func _safe(d: Dictionary, p: Vector2i, side: int) -> bool:
 if p.x < 1 or p.y < 1 or p.x >= d.width-1 or p.y >= d.height-1: return false
 if (side == 0 and p.x > 7) or (side == 1 and p.x < 17): return false
 return not d.tiles["%d,%d" % [p.x,p.y]].blocked
static func profile(battle, packet: Variant, expected_field: Variant, expected_seed: Variant) -> Array:
 if not Generator.validate(packet,expected_field,expected_seed) or packet.recipe!=Generator.RECIPE or not battle is Battle: return []
 if not battle.roster_rules is bool or not battle.roster_rules or not battle.perk_rules is bool or not battle.boss_tactics is bool or not battle.enemy_plan is Dictionary: return []
 if not battle.map_id is String or battle.map_id != expected_field or battle.units.size() != 24 or battle.player_slots() != 12: return []
 var d: Dictionary = packet.descriptor
 var result := []; result.resize(24)
 var used := {}; var repair := []
 # Living rows own their selected formation/role coordinates before dead/empty
 # rows are considered. No earlier empty rank may steal a later living anchor.
 for living_pass in [true,false]:
  for i in 24:
   var u = battle.units[i]
   if not u is Dictionary: return []
   for key in ["id","side","q","r","hp"]:
    if not u.get(key) is int: return []
   if u.id != i or u.side != (0 if i < 12 else 1) or not u.get("escaped") is bool: return []
   var alive: bool = u.hp > 0 and not u.escaped
   if alive != living_pass: continue
   var offset: Vector2i = d.presentation.player_offset if i < 12 else d.presentation.enemy_offset
   var at := Vector2i(u.q,u.r)+offset
   if _safe(d,at,u.side) and not used.has(at):
    result[i] = at; used[at] = true
   elif alive:
    # A living collision/unknown layout is not permission to flatten formation.
    return []
   else: repair.append(i)
 for i in repair:
  var candidates: Array = d.presentation.player_anchors if i < 12 else []
  if i >= 12:
   for q in [18,19,20,21,22,23,17]:
    for r in [6,5,7,4,8,3,9,2,10,1,11]: candidates.append(Vector2i(q,r))
  var found := false
  for at in candidates:
   if not used.has(at) and _safe(d,at,0 if i < 12 else 1):
    result[i] = at; used[at] = true; found = true; break
  if not found: return []
 return result
static func install(battle, packet: Variant, expected_field: Variant, expected_seed: Variant) -> bool:
 var positions := profile(battle,packet,expected_field,expected_seed)
 if positions.size() != 24: return false
 if not battle.active_id is int or battle.active_id < -1 or battle.active_id >= 24: return false
 if battle.active_id >= 0 and battle.perk_rules and not battle.units[battle.active_id].get("perk_state") is Dictionary: return false
 var d: Dictionary = packet.descriptor
 var before := _capture(battle)
 if not battle.configure_board(d.width,d.height,d.goal):
  _restore(battle,before); return false
 battle.tiles = d.tiles.duplicate(true)
 for i in 24:
  battle.units[i].q = positions[i].x; battle.units[i].r = positions[i].y
 if battle.active_id >= 0 and battle.perk_rules:
  var u: Dictionary = battle.units[battle.active_id]
  u.perk_state.origin_q = u.q; u.perk_state.origin_r = u.r
 battle.terrain_rules_enabled = true
 battle.set_meta("authored_map",d.duplicate(true))
 var boss: bool = battle.boss_tactics
 var plan: Dictionary = battle.enemy_plan.duplicate(true)
 var ok: bool = battle.configure_visibility()
 battle.boss_tactics = boss
 battle.enemy_plan = plan
 if not ok: _restore(battle,before)
 return ok
static func _copy(value: Variant) -> Variant:
 return value.duplicate(true) if value is Array or value is Dictionary else value
static func _capture(battle) -> Dictionary:
 var state := {}; var metadata := {}
 for property in battle.get_property_list():
  if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: state[property.name] = _copy(battle.get(property.name))
 for name in battle.get_meta_list(): metadata[name] = _copy(battle.get_meta(name))
 return {"state":state,"metadata":metadata}
static func _restore(battle, before: Dictionary) -> void:
 for name in before.state: battle.set(name,before.state[name])
 for name in battle.get_meta_list(): battle.remove_meta(name)
 for name in before.metadata: battle.set_meta(name,before.metadata[name])
