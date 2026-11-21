extends "res://burial_ruins/world_view.gd"
## Retain Company formation/service/progression. Replace fitting entry only.
func _ready() -> void:
 region_camera = preload("res://campaign_overworld/camera.gd").new()
 lineup = preload("res://company_town/formation_view.gd").new()
 super._ready()
func observation() -> Dictionary:
 var out = super.observation()
 if region_camera.canvas != null:
  out["painted_overworld"] = region_camera.canvas.painted_observation()
 return out
func inventory_available() -> bool:
 return visible and not blocked() and not world_view and iron.sheet.is_empty() and not intro and not help and confirmation.is_empty() and not (lineup.opened or perks_view or person_view or armor_view or arms_view or salvage_view or loot_view or service_view or bonds_view or politics_view or trade_view or guide_view or planner_view or record_view or tactics_view or news_view or inspection_view)
func blocked() -> bool:
 return super.blocked() or (host != null and is_instance_valid(host.outfitting))
func action(id: String) -> void:
 if id == "loadout":
  if inventory_available() and host != null: host._open_outfitting()
  return
 super.action(id)
func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
 super.button(id,"INVENTORY · OUTFIT & CARRIED ARMS" if id == "loadout" else title,rect,enabled,primary)
