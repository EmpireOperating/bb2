extends RefCounted
## Selection/command boundary only. All rules and AI belong to the unchanged Battle.
signal changed
var battle
var selected := -1
var target := -1
var notice := "Select a mercenary, then a blue hex to move."
func attach(value) -> void:
	battle = value
	selected = -1
	target = -1
func select_unit(id: int) -> bool:
	if id < 0 or id >= battle.units.size() or battle.units[id].side != 0 or not battle.living(battle.units[id]): return false
	selected = id
	target = -1
	notice = "%s selected." % battle.units[id].name
	changed.emit()
	return true
func select_target(id: int) -> bool:
	if id < 0 or id >= battle.units.size() or battle.units[id].side != 1 or not battle.living(battle.units[id]): return false
	target = id
	notice = battle.attack_block_reason(selected,id) if selected >= 0 else "Select one of your mercenaries first."
	changed.emit()
	return true
func move_to(p: Vector2i) -> bool:
	if selected < 0: return false
	var accepted: bool = battle.move_unit(selected,p)
	notice = "%s advances." % battle.units[selected].name if accepted else battle.movement_block_reason(selected,p)
	changed.emit()
	return accepted
func attack_target() -> bool:
	if selected < 0 or target < 0: return false
	var accepted: bool = battle.attack(selected,target)
	notice = "Attack resolved. See the combat log." if accepted else battle.attack_block_reason(selected,target)
	changed.emit()
	return accepted
func end_player_turn() -> bool:
	if battle.side != 0 or not battle.result.is_empty(): return false
	battle.end_turn()
	notice = "The raiders are acting…"
	changed.emit()
	return true
func enemy_step() -> void:
	if not battle.auto_step_needed(): return
	battle.ai_step()
	notice = "Your company can act." if battle.side == 0 else "The raiders are acting…"
	changed.emit()
