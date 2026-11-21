extends "res://world_loop/character.gd"
## Undead foundation-only pallor. No new anatomy/catalog or gear substitutions.
const BurialCompositor = preload("res://burial_ruins/assets/compositor.gd")
static var _burial_compositor = BurialCompositor.new()
var _undead := false
var _undead_kind := ""
func refresh(unit: Dictionary, catalog: Dictionary) -> void:
 _undead_kind = str(unit.get("undead_kind",""))
 _undead = unit.get("faction","") == "undead" or not _undead_kind.is_empty()
 compositor = _burial_compositor if _undead else _company_compositor
 super.refresh(unit,catalog)
 if not _undead: return
 var asset := "burial_"+CompanyCompositor.foundation_asset(_identity,_helmet_context)
 _signature.foundation.merge({"asset":asset+".png","art_family":asset,"asset_root":"res://burial_ruins/assets/","appearance_treatment":"foundation_skin_pallor_v1"},true)
 _signature.foundation["asset_error"] = _asset_errors.get(asset,"")
func _add_layer(slot: String, asset: String, family: String, definition: String, item: Dictionary, catalog_color: Color, priority: int, fallback: bool = false) -> void:
 super._add_layer(slot,asset,family,definition,item,catalog_color,priority,fallback)
 if _undead and (slot == "foundation" or slot == "head/shell" and _signature[slot].painted):
  _stack[0].asset = "burial_"+CompanyCompositor.foundation_asset(_identity,_helmet_context)
func appearance_diagnostics() -> Dictionary:
 return {"treatment":"foundation_skin_pallor_v1" if _undead else "accepted_player_unchanged","undead_kind":_undead_kind,"painted_skull":false,"gear_recolored":false,"limitations":"Reused living anatomy with foundation-skin corpse pallor only; no painted skull or full undead catalog. Equipped club and stitched leather remain omitted with explicit equipment issues." if _undead else ""}
func render_diagnostics() -> Dictionary:
 var result := super.render_diagnostics()
 result["appearance"] = appearance_diagnostics()
 return result
