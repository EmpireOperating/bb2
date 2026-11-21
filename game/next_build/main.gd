extends "res://company_banners/main.gd"
## Cumulative candidate only; retained campaign, UI and finite market authority.
func _create_session():
 checkpoint_path = "user://integration09-camp.json"
 return load("res://company_banners/session.gd").new()
func _collect_contract_payment(quote: Dictionary) -> void:
 if session==null or not is_instance_valid(world) or error_panel.visible or is_instance_valid(field) or is_instance_valid(outfitting) or is_instance_valid(_parked_company):return
 if not world.visible or world.blocked() or not world.town_is_open() or not world._clear_surface() or world.town.section!="contracts":return
 # Reject stale callbacks before any filesystem write or save-error overlay.
 if not session.payment_collect_reason(quote).is_empty():return
 if not session.collect_contract_payment(quote):
  world.tell(session.last_error);world.refresh()
func _ready() -> void:
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Next Build 09 + Faces")
