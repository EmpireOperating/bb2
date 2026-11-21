extends "res://combat_pass/controller.gd"
## UI knowledge boundary, never an alternative combat authority.
func sanitize_target() -> void:
 if selected>=0 and (selected>=battle.units.size() or battle.units[selected].side!=0):
  selected=-1;target=-1;target_hex=Vector2i(-1,-1);notice="Select a company brother."
 if target>=0 and not battle.unit_visible(0,target):
  target=-1;target_hex=Vector2i(-1,-1);notice="Contact lost."
 if target_hex!=Vector2i(-1,-1) and not battle.tile_visible(0,target_hex):target_hex=Vector2i(-1,-1)

func select_unit(id: int) -> bool:
 if id<0 or id>=battle.units.size() or battle.units[id].side!=0:return false
 sanitize_target()
 return super.select_unit(id)

func select_target(id: int) -> bool:
 if not battle.unit_visible(0,id) or battle.units[id].side==0 or not battle.living(battle.units[id]):return false
 target=id;notice=explanation();changed.emit();return true

func quote() -> Dictionary:
 sanitize_target()
 return public_quote(battle.action_quote(selected,action,target,target_hex,carry_slot))

func public_quote(q: Dictionary) -> Dictionary:
 var out=q.duplicate(true)
 # Battle qualifies hit/damage with its public-neighborhood forecast policy.
 if battle.visibility_enabled and out.action in ["basic","special"]:
  if not out.legal and target>=0:out.reason="No legal attack from this position."
 return out

func execute(value: String,slot: String="") -> bool:
 sanitize_target()
 if selected<0 or battle.side!=0:return false
 var q: Dictionary=public_quote(battle.action_quote(selected,value,target,target_hex,slot if not slot.is_empty() else carry_slot))
 var ok: bool=battle.perform_action(selected,value,target,target_hex,slot if not slot.is_empty() else carry_slot)
 notice=("%s resolved. See the combat log."%q.name) if ok else q.reason
 if ok and value not in ["basic","special"]:reset_action()
 changed.emit();return ok

func end_player_turn() -> bool:
 if battle.side!=0 or battle.active_id<0 or battle.units[battle.active_id].side!=0:return false
 return super.end_player_turn()

func move_to(cell: Vector2i) -> bool:
 sanitize_target()
 if battle.visibility_enabled and not battle.tile_visible(0,cell):
  notice="Move within current party sight to explore.";changed.emit();return false
 return super.move_to(cell)
