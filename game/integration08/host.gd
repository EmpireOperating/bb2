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
var _back_to_game: Button
var _resume_checkpoint_world := false
var _checkpoint_quit_dialog: ConfirmationDialog
var _quit_prior_pause := false
var _quit_prior_focus: Control

func _ready() -> void:
 super._ready()
 get_tree().auto_accept_quit = false
 get_tree().root.close_requested.connect(_quit_without_checkpoint)

func _build_overlays() -> void:
 super._build_overlays()
 var column := error_label.get_parent().get_parent()
 _back_to_game = Button.new()
 _back_to_game.text = "Back to Game"
 _back_to_game.custom_minimum_size.y = 44
 GameUI.button(_back_to_game)
 _back_to_game.pressed.connect(_dismiss_checkpoint_error)
 column.add_child(_back_to_game)
 # Keep the inherited Retry first and explicit Quit last.
 column.move_child(_back_to_game, column.get_child_count() - 2)
 _back_to_game.hide()

func _show_error(message: String) -> void:
 if not error_panel.visible:
  _resume_checkpoint_world = is_instance_valid(world) and world.visible and world.can_process()
 _back_to_game.visible = _resume_checkpoint_world and not _loading_failed
 if _back_to_game.visible:
  message = "Could not checkpoint your company. Your unsaved progress is still in memory.\n\n" + save_error
 super._show_error(message)

func _dismiss_checkpoint_error() -> void:
 if not error_panel.visible or not _back_to_game.visible or _loading_failed or _saving or not is_instance_valid(world):return
 error_panel.hide()
 _resume_checkpoint_world = false
 world.set_active(true)
 world.tell("Checkpoint not saved. Current progress is still in memory.")
 world.refresh()
 if is_instance_valid(_overlay_prior_focus) and _overlay_prior_focus.is_visible_in_tree():_overlay_prior_focus.grab_focus()

func _retry_checkpoint() -> void:
 super._retry_checkpoint()
 if saved_ok and is_instance_valid(world):world.save_failed = false

func _quit_without_checkpoint() -> void:
 # From the title or a failed startup read, there is no live play to discard.
 if not is_instance_valid(world):
  get_tree().quit()
  return
 if is_instance_valid(_checkpoint_quit_dialog) and _checkpoint_quit_dialog.visible:return
 if not is_instance_valid(_checkpoint_quit_dialog):
  _checkpoint_quit_dialog = ConfirmationDialog.new()
  _checkpoint_quit_dialog.title = "Quit the game?"
  _checkpoint_quit_dialog.dialog_text = "Progress since your last save will be lost. Quit without saving?"
  _checkpoint_quit_dialog.ok_button_text = "Quit without saving"
  _checkpoint_quit_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
  _checkpoint_quit_dialog.transient = true
  _checkpoint_quit_dialog.exclusive = true
  _checkpoint_quit_dialog.confirmed.connect(get_tree().quit)
  _checkpoint_quit_dialog.canceled.connect(_cancel_checkpoint_quit)
  add_child(_checkpoint_quit_dialog)
 _quit_prior_pause = get_tree().paused
 _quit_prior_focus = get_viewport().gui_get_focus_owner()
 get_tree().paused = true
 _checkpoint_quit_dialog.popup_centered(Vector2i(500, 0))
 _checkpoint_quit_dialog.get_cancel_button().grab_focus()

func _cancel_checkpoint_quit() -> void:
 get_tree().paused = _quit_prior_pause
 if is_instance_valid(_quit_prior_focus) and _quit_prior_focus.is_visible_in_tree():_quit_prior_focus.grab_focus()
 _quit_prior_focus = null

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
 if is_instance_valid(_back_to_game) and _back_to_game.is_visible_in_tree() and event is InputEventKey and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
  get_viewport().set_input_as_handled()
  if event.pressed and not event.echo:_dismiss_checkpoint_error()
  return
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
 if is_instance_valid(_back_to_game) and _back_to_game.is_visible_in_tree():
  var back := _control_observation(_back_to_game)
  out.overlay_controls["back_to_game"] = back
  out.buttons["back_to_game"] = back.center
 out["checkpoint_origin"]=session.checkpoint_origin()
 out["named_saves"]=save_browser.observation() if _save_browser_open() else {"open":false,"modal":false,"folder":save_library.root_path}
 return out
