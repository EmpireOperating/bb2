extends RefCounted
## Encounter-local orders for the two inner posts of the Broken Gate stamp.
## No deployment, scheduler, movement, or presentation authority of its own.
const GATE_ROUNDS := 5
const POST_RADIUS := 5
const BREACH_RADIUS := 4
const BREACH_FOLLOWING_ROUNDS := 2
const NO_POST := Vector2i(-1,-1)

var _center: Vector2i
var _front: Vector2i
var _north: Vector2i
var _weak_wall: Vector2i
var _cover: Vector2i
var _front_guard: int
var _north_guard: int
var _cover_until := 0

func _init(battle, center: Vector2i, weak_wall: Vector2i) -> void:
 _center = battle.axial(center)
 # The front guard threatens the threshold without plugging it. The reserve
 # supports from deeper inside; the gate pillar blinds the nearer shoulder.
 _front = battle.offset(_center + Vector2i(1,-1))
 _north = battle.offset(_center + Vector2i(2,-2))
 _weak_wall = weak_wall
 _cover = battle.offset(battle.axial(weak_wall) + Vector2i(1,0))
 _front_guard = _nearest_guard(battle,_front,-1)
 _north_guard = _nearest_guard(battle,_north,_front_guard)

func _nearest_guard(battle, post: Vector2i, except: int) -> int:
 var best := -1
 var value := POST_RADIUS+1
 for unit: Dictionary in battle.units:
  if unit.side != 1 or unit.id == except or not battle.fighting(unit): continue
  if battle.weapon_stats(unit).get("ranged",false) or unit.weapon.is_empty(): continue
  var from: Vector2i = battle.pos(unit)
  if not _court(battle,from): continue
  var distance: int = battle.distance(from,post)
  if distance < value:
   value = distance
   best = unit.id
 return best

func _court(battle, cell: Vector2i) -> bool:
 # Stay on the courtyard side of the ruin, inside the existing stamp.
 var d: Vector2i = battle.axial(cell) - _center
 return d.x >= 1 and d.x <= 6 and absi(2*d.y+d.x) <= 11

func observe_wall_fall(battle, cell: Vector2i) -> void:
 if cell != _weak_wall or _north_guard < 0 or battle.withdrawing: return
 var guard: Dictionary = battle.units[_north_guard]
 var from: Vector2i = battle.pos(guard)
 if not battle.fighting(guard) or not _court(battle,from): return
 if battle.distance(from,cell) > BREACH_RADIUS or battle.distance(from,_north) > 2: return
 # Sample the cached authority BEFORE the terrain changes. No relay from
 # allies, post-collapse ray, worker identity, or check on later activations.
 if battle.unit_can_see_tile(_north_guard,cell):
  _cover_until = battle.round_no + BREACH_FOLLOWING_ROUNDS

func post_for(battle, unit: Dictionary) -> Vector2i:
 if unit.id != _front_guard and unit.id != _north_guard: return NO_POST
 if not battle.individual or battle.withdrawing or unit.id != battle.active_id or not battle.fighting(unit): return NO_POST
 var from: Vector2i = battle.pos(unit)
 if not _court(battle,from): return NO_POST
 if unit.id == _north_guard and _cover_until > 0:
  return _cover if battle.round_no <= _cover_until and battle.distance(from,_weak_wall) <= BREACH_RADIUS else NO_POST
 if battle.round_no > GATE_ROUNDS: return NO_POST
 var post := _front if unit.id == _front_guard else _north
 return post if battle.distance(from,post) <= POST_RADIUS else NO_POST

func approach(battle, unit: Dictionary, post: Vector2i) -> Array:
 # Stock affordable fog/ZOC/occupancy routes, not an alternate pathfinder.
 # Prefer progress toward the post, then less AP and less fatigue.
 var best: Array = []
 var distance: int = battle.distance(battle.pos(unit),post)
 if distance == 0: return best
 var leash_center := _weak_wall if post == _cover else post
 var leash_radius := BREACH_RADIUS if post == _cover else POST_RADIUS
 var cost := 0
 var fatigue := 0
 for route: Dictionary in battle.movement_map(unit.id).values():
  var d: int = battle.distance(route.path.back(),post)
  if d > distance or (d == distance and (best.is_empty() or route.cost > cost or (route.cost == cost and route.fatigue >= fatigue))): continue
  if not route.path.all(func(cell): return _court(battle,cell) and battle.distance(cell,leash_center) <= leash_radius): continue
  best = route.path
  distance = d
  cost = route.cost
  fatigue = route.fatigue
 return best
