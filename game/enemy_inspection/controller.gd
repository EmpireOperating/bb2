extends "res://map_visibility/controller.gd"
## Transient input intent; Battle alone owns movement and payment.
signal intent_retired

const MovementPlan = preload("res://src/tactical_movement_plan.gd")
const ReloadArsenal = preload("res://src/arsenal.gd")
var admission: Callable
var _movement:Dictionary={}
var _movement_stamp:PackedByteArray
var _movement_battle
var _movement_actor:Dictionary
var _movement_stale:=false
func _public_movement_stamp() -> PackedByteArray:
 if battle==null or selected<0 or selected>=battle.units.size():return PackedByteArray()
 var public_units:Array=[];var public_tiles:Array=[];var keys:Array=battle.tiles.keys();keys.sort()
 for unit in battle.units:
  if battle.unit_visible(0,unit.id):public_units.append(unit)
 for k:String in keys:
  var bits:=k.split(",");var cell:=Vector2i(int(bits[0]),int(bits[1]))
  if battle.tile_visible(0,cell):public_tiles.append([k,battle.tiles[k]])
 return var_to_bytes([selected,battle.active_id,battle.round_no,battle.side,battle.result,battle.individual,battle.waited.has(selected),battle.activated.has(selected),battle.finished.has(selected),battle.terrain_rules_enabled,battle.perk_rules,battle.weapon_rules,battle.core_rules,battle.inventory_rules,battle.visibility_enabled,battle.visibility_profile,battle._board_size,battle._board_goal,public_units,public_tiles])
func sync_movement() -> bool:
 if _movement.is_empty():return false
 if not available():cancel_movement();return true
 if _movement_stale:return false
 if battle!=_movement_battle or selected!=_movement.actor or selected<0 or selected>=battle.units.size() or not is_same(battle.units[selected],_movement_actor) or _public_movement_stamp()!=_movement_stamp:
  _movement_stale=true;return true
 return false
func _publish_movement(value:Dictionary) -> void:
 _movement=value;_movement_battle=battle;_movement_actor=battle.units[selected]
 _movement_stamp=_public_movement_stamp();_movement_stale=false
func reset_action() -> void:
 cancel_movement();super.reset_action();intent_retired.emit()
func available() -> bool:
 return not admission.is_valid() or admission.call()
func cancel_movement() -> void:
 _movement={};_movement_battle=null;_movement_actor={};_movement_stamp=PackedByteArray();_movement_stale=false
func movement_preview() -> Dictionary:
 sync_movement()
 if _movement.is_empty() or _movement_stale:return {"valid":false,"actor":-1,"origin":{},"path":[],"waypoints":[],"cost":0,"fatigue":0,"known_danger":false,"danger_text":"","risk_steps":[]}
 var out:=_movement.duplicate(true)
 out.origin={"q":out.origin.x,"r":out.origin.y}
 out.path=MovementPlan.cells(out.path);out.waypoints=MovementPlan.cells(out.waypoints)
 return out
func movement_click(cell:Vector2i) -> bool:
 if not available():return false
 if action in ["footwork","rotation"]:return move_to(cell)
 if not battle.can_act(selected) or battle.units[selected].side!=0:return false
 if cell==battle.pos(battle.units[selected]):cancel_movement();changed.emit();return false
 sync_movement()
 if _movement_stale:
  var old_points:Array=_movement.waypoints.duplicate()
  var same_endpoint:bool=_movement.path.back()==cell
  cancel_movement()
  var replacement:Dictionary=MovementPlan.plan(battle,selected,old_points if same_endpoint else [cell])
  if not replacement.is_empty():_publish_movement(replacement)
  notice="Route changed · review footprints and click destination again."
  changed.emit();return false
 if not _movement.is_empty() and _movement.path.back()==cell:
  var path:Array=_movement.path.duplicate();cancel_movement()
  var accepted:bool=battle.move_unit_path(selected,path)
  notice="Movement resolved." if accepted else "Route changed; preview again."
  changed.emit();return accepted
 var waypoints:Array=_movement.waypoints.duplicate() if not _movement.is_empty() else []
 var proposed:Dictionary
 if not _movement.is_empty() and cell in _movement.path:
  var index:int=_movement.path.find(cell)
  var retained:Array=[];var cursor:=0
  for point in waypoints:
   var satisfied:int=_movement.path.find(point,cursor)
   if satisfied<0 or satisfied>index:break
   retained.append(point);cursor=satisfied+1
  waypoints=retained
  if waypoints.is_empty() or waypoints.back()!=cell:waypoints.append(cell)
  proposed=MovementPlan.quote_path(battle,selected,_movement.path.slice(0,index+1),waypoints)
 else:
  waypoints.append(cell)
  proposed=MovementPlan.plan(battle,selected,waypoints)
 if proposed.is_empty():
  notice="Cannot finish appended route this activation (AP / fatigue / visible ground)."
 else:
  _publish_movement(proposed)
  notice="%d AP / %d fatigue · click destination again to move."%[_movement.cost,_movement.fatigue]
  if _movement.known_danger:notice+=" "+_movement.danger_text
 changed.emit();return false
func select_unit(id:int) -> bool:
 if not available():return false
 cancel_movement();return super.select_unit(id)
func select_target(id:int) -> bool:
 if not available():return false
 cancel_movement();return super.select_target(id)
func choose_action(value:String) -> void:
 if available():cancel_movement();super.choose_action(value)
func move_to(cell:Vector2i) -> bool:
 if not available():return false
 cancel_movement();return super.move_to(cell)
func is_reload_action(value:String) -> bool:
 return value=="special" and battle!=null and selected>=0 and selected<battle.units.size() and battle.units[selected].side==0 and ReloadArsenal.family(battle.units[selected].weapon)=="crossbow"
func quote() -> Dictionary:
 if is_reload_action(action):
  return battle.action_quote(selected,"special")
 return super.quote()
func execute(value:String,slot:String="") -> bool:
 if not available():return false
 cancel_movement()
 if not is_reload_action(value):return super.execute(value,slot)
 # Reload has no target. Leave enemy selection and the shot's sight rules alone.
 var q:Dictionary=battle.action_quote(selected,"special")
 var ok:bool=battle.perform_action(selected,"special")
 if ok:reset_action()
 notice="Crossbow reloaded." if ok else q.reason
 changed.emit()
 return ok
func end_player_turn() -> bool:
 if not available():return false
 cancel_movement();return super.end_player_turn()
func enemy_step() -> void:
 if available():cancel_movement();super.enemy_step()
