extends "res://prototype/battle_controller.gd"
## Local targeting only; every price, refusal and mutation is Battle-owned.
var action := "basic"
var target_hex := Vector2i(-1,-1)
var carry_slot := "carry1"
func reset_action() -> void:
 action="basic";target_hex=Vector2i(-1,-1)
func select_unit(id: int) -> bool:
 if action=="rotation" and selected>=0 and id!=selected and id>=0 and id<battle.units.size():
  target_hex=battle.pos(battle.units[id]);notice=quote().reason;changed.emit();return true
 reset_action()
 return super.select_unit(id)
func select_target(id: int) -> bool:
 if not super.select_target(id):return false
 notice=explanation();changed.emit();return true
func choose_action(value: String) -> void:
 action=value;target_hex=Vector2i(-1,-1);notice=explanation();changed.emit()
func quote() -> Dictionary:
 return battle.action_quote(selected,action,target,target_hex,carry_slot)
func explanation() -> String:
 var q=quote()
 if not q.legal:return q.reason
 return "%s · %d AP / %d fatigue"%[q.name,q.ap,q.fatigue]
func move_to(p: Vector2i) -> bool:
 if action in ["footwork","rotation"]:
  target_hex=p;notice=explanation();changed.emit();return false
 return super.move_to(p)
func attack_target() -> bool:return execute(action)
func execute(value: String,slot: String="") -> bool:
 if selected<0 or battle.side!=0 or battle.units[selected].side!=0:return false
 var q=battle.action_quote(selected,value,target,target_hex,slot if not slot.is_empty() else carry_slot)
 var ok: bool=battle.perform_action(selected,value,target,target_hex,slot if not slot.is_empty() else carry_slot)
 notice=("%s resolved. See the combat log."%q.name) if ok else q.reason
 if ok and value not in ["basic","special"]:reset_action()
 changed.emit();return ok
func end_player_turn() -> bool:
 if battle.active_id<0:return false
 selected=battle.active_id
 return execute("end")
