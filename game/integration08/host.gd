extends "res://local_markets/main.gd"
## Named-save host adapter; configured next_build scene adds company foundation.
func _create_session():
 checkpoint_path="user://integration08-camp.json"
 return load("res://company_banners/session.gd").new()
var save_library=_create_save_library()
func _create_save_library():
 return preload("res://named_saves/library.gd").new()
var save_browser: Control
var _save_world_mode: int=Node.PROCESS_MODE_INHERIT
var _save_prior_focus: Control
func _save_browser_open() -> bool:
 return is_instance_valid(save_browser)
func _open_company() -> void:
 if not session.changed.is_connected(_session_changed):session.changed.connect(_session_changed)
 if not is_instance_valid(world):
  world=load("res://named_saves/world_view.gd").new()
  world.host=self;world.campaign=session.campaign;add_child(world)
 world.set_active(not is_instance_valid(outfitting))
func _open_save_browser(_mode: String = "save") -> void:
 if _save_browser_open() or session==null or error_panel.visible or aftermath_panel.visible or is_instance_valid(field) or is_instance_valid(_battle_loading) or is_instance_valid(outfitting) or is_instance_valid(_parked_company):return
 if session.campaign.phase!="camp" or not is_instance_valid(world) or not world.save_surface_available():return
 _save_world_mode=world.process_mode
 _save_prior_focus=get_viewport().gui_get_focus_owner()
 world.process_mode=Node.PROCESS_MODE_DISABLED
 save_browser=load("res://named_saves/browser.gd").new();save_browser.host=self
 _canvas.add_child(save_browser)
func _load_library_row(row: Dictionary) -> Dictionary:
 if not _save_browser_open() or session.campaign.phase!="camp" or error_panel.visible:return {"ok":false,"error":"Return to the CAMP save browser before loading."}
 if row.get("revision","").is_empty():return {"ok":false,"error":"Refresh and select a valid save revision."}
 if row.id=="@checkpoint":
  var result: Dictionary=save_browser.checkpoint()
  if not result.ok:return result
  if result.row.revision!=row.revision:return {"ok":false,"error":"Manual checkpoint changed since selection. Refresh and try again."}
  if not session.restore_checkpoint_text(result.checkpoint):return {"ok":false,"error":session.last_error}
 else:
  var result: Dictionary=save_library.load_slot(session,row.id,row.revision)
  if not result.ok:return result
 # Paired publication is IO-free. A named branch is not the current manual
 # checkpoint until explicit Save; checkpoint-row Load alone is checkpoint-clean.
 _close_save_browser()
 saved_ok=row.id=="@checkpoint";_loading_failed=false
 _replace_world()
 return {"ok":true}
func _close_save_browser() -> void:
 if not _save_browser_open():return
 var browser:=save_browser;save_browser=null
 _canvas.remove_child(browser);browser.queue_free()
 if is_instance_valid(world):world.process_mode=_save_world_mode;world.refresh()
 if is_instance_valid(_save_prior_focus) and _save_prior_focus.is_visible_in_tree():_save_prior_focus.grab_focus()
func _input(event: InputEvent) -> void:
 if _save_browser_open():return # Native GUI receives text; world is disabled.
 super._input(event)
func _unhandled_key_input(event: InputEvent) -> void:
 if _save_browser_open():get_viewport().set_input_as_handled();return
 super._unhandled_key_input(event)
func _load_checkpoint() -> void:
 if not _save_browser_open():_open_save_browser("load")
func _new_company(seed: int) -> void:
 if not _save_browser_open():super._new_company(seed)
func _deploy() -> void:
 if not _save_browser_open():super._deploy()
func _deploy_camp() -> void:
 if not _save_browser_open():super._deploy_camp()
func _accept_contract(id: String) -> void:
 if not _save_browser_open():super._accept_contract(id)
func _open_outfitting() -> void:
 if not _save_browser_open():super._open_outfitting()
func observation() -> Dictionary:
 var out: Dictionary=super.observation()
 out["checkpoint_origin"]=session.checkpoint_origin()
 out["named_saves"]=save_browser.observation() if _save_browser_open() else {"open":false,"modal":false,"folder":save_library.root_path}
 return out
