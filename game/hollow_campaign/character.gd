extends "res://hollow_experiment/character.gd"
## One fitted cache for camp/player field actors. Undead stay on Burial's actor.
const CurrentAppearance = preload("res://hollow_campaign/appearance.gd")
static var _current_appearance = CurrentAppearance.new()
func _init() -> void:
 appearance = _current_appearance
func equipment_issues() -> Array:
 var out: Array = []
 for issue: Dictionary in _diagnostics.get("issues",[]):
  var entry: Dictionary = _signature.get(str(issue.get("slot","")),{})
  out.append({"kind":"omitted","slot":issue.get("slot",""),"definition":issue.get("definition",issue.get("definition_id","")),"item":issue.get("uid",""),"condition":entry.get("condition",0),"maximum":entry.get("maximum",0),"reason":issue.get("reason","")})
 return out
func appearance_diagnostics() -> Dictionary:
 return {"treatment":"fitted_hollow_current_equipment","painted_skull":false,"gear_recolored":false,"limitations":"Finite fitted appearance set; unsupported exact stock gear omitted with UID diagnostics, never substituted mechanically."}
