extends "res://company_loop/character.gd"
## Presentation only: physical definitions, UIDs, wear and mechanics stay authoritative.
const VISUAL_PROXIES := {
 "militia_spear": {"slot":"weapon","family":"spear","source":"weapon_spear","definition":"spear","asset":"weapon_spear","reason":"Same-family visual proxy: militia_spear uses the accepted spear silhouette; exact militia-spear art is not authored."},
 "shortsword": {"slot":"weapon","family":"sword","source":"weapon_sword","definition":"sword","asset":"weapon_sword","reason":"Same-family visual proxy: shortsword uses accepted sword paint; blade length/design is not exact shortsword art."},
 "hatchet": {"slot":"weapon","family":"axe","source":"weapon_axe","definition":"axe","asset":"weapon_axe","reason":"Same-family visual proxy: hatchet uses accepted one-handed axe paint; size/design is not exact hatchet art."},
 "shortbow": {"slot":"weapon","family":"bow","source":"weapon_bow","definition":"bow","asset":"weapon_bow","reason":"Same-family visual proxy: shortbow uses accepted bow paint; bow length/design is not exact shortbow art."},
 "buckler": {"slot":"shield","family":"buckler","source":"shield_buckler","definition":"round_shield","asset":"shield_round","reason":"Same-family visual proxy: buckler uses accepted round-shield paint; size/design is not exact buckler art."}
}
func refresh(unit: Dictionary, catalog: Dictionary) -> void:
 super.refresh(unit,catalog)
 var sprite := get_node_or_null("Illustration/Composite") as Sprite3D
 if sprite != null: sprite.flip_h = int(unit.get("side",0)) == 1

func _add_layer(slot: String, asset: String, family: String, definition: String, item: Dictionary, catalog_color: Color, priority: int, fallback: bool = false) -> void:
 var proxy: Dictionary = VISUAL_PROXIES.get(definition,{})
 var admitted: bool = not fallback and not proxy.is_empty() and slot == proxy.slot and family == proxy.family and asset == proxy.source
 super._add_layer(slot,proxy.asset if admitted else asset,family,proxy.definition if admitted else definition,item,catalog_color,priority,fallback)
 if not admitted: return
 # The inherited exact-art gate sees only the bounded paint selection. Restore
 # actual identity in the public signature (and its physical weapon support).
 for key in [slot,"weapon_grip"] if slot == "weapon" else [slot]:
  _signature[key].merge({"definition":definition,"visual_proxy":true,"proxy_definition":proxy.definition,"proxy_reason":proxy.reason,"fallback":true,"fallback_reason":proxy.reason},true)

func equipment_issues() -> Array:
 var issues: Array = []
 for slot: String in _signature:
  var entry: Dictionary = _signature[slot]
  if entry.get("support_for","") != "" or str(entry.get("definition","")).is_empty(): continue
  var proxy: bool = entry.get("visual_proxy",false)
  if not proxy and entry.get("painted",false): continue
  issues.append({"kind":"visual_proxy" if proxy else "omitted","slot":slot,
   "definition":entry.definition,"item":entry.item,"condition":entry.condition,"maximum":entry.maximum,
   "asset":entry.asset,"proxy_definition":entry.get("proxy_definition",""),
   "reason":entry.get("proxy_reason",entry.get("fallback_reason","Not authored in this bounded subset."))})
 return issues

func render_diagnostics() -> Dictionary:
 var result := super.render_diagnostics()
 result["equipment_issues"] = equipment_issues()
 return result
