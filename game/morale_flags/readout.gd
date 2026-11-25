extends RefCounted
## Passive label for identities currently admitted to party sight. No saved score,
## recent event, roll or last-known position determines the reading.
static func current_name(battle, id: int) -> String:
 if not battle.unit_visible(0,id):return "—"
 var unit: Dictionary=battle.units[id]
 if not battle.living(unit) or unit.get("morale_state") not in [-3,-2,-1,0,1]:return "—"
 return String(battle.morale_name(unit)).capitalize()
