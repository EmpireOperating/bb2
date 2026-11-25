extends "res://single_body/main.gd"
## Launch routing only. Founding and save validation stay with the active session.
const TitleScreen = preload("res://single_body/title_screen.gd")
const FoundationForm = preload("res://company_banners/foundation.gd")
const SaveBrowser = preload("res://named_saves/browser.gd")
var _title_menu: Control

func _show_launch_title() -> bool:
 var args := OS.get_cmdline_user_args()
 if "--smoke" in args or "--skip-title" in args: return false
 _title_menu = TitleScreen.new()
 _title_menu.new_requested.connect(_open_title_foundation)
 _title_menu.load_requested.connect(_open_save_browser.bind("load"))
 _title_menu.quit_requested.connect(get_tree().quit)
 _canvas.add_child(_title_menu)
 _return_to_title()
 return true

func _has_save_sources() -> bool:
 var dir := DirAccess.open(OS.get_user_data_dir())
 var file := checkpoint_path.get_file()
 if dir == null or dir.file_exists(file) or dir.dir_exists(file) or dir.is_link(file): return true
 # Availability is a cheap listing only, not validation or loading. Keep the
 # browser reachable for an unsafe target so its existing refusal is visible.
 if not save_library._safe_root(false): return true
 var named := DirAccess.open(save_library.root_path)
 if named != null:
  for filename in named.get_files():
   if filename.get_extension() == "json" and save_library._valid_id(filename.get_basename()): return true
 return false

func _return_to_title(load_focus: bool = false) -> void:
 _title_menu.set_load_available(_has_save_sources())
 _title_menu.show()
 var button: Button = _title_menu.load_button if load_focus and not _title_menu.load_button.disabled else _title_menu.new_button
 button.grab_focus()

func _open_title_foundation() -> void:
 if not is_instance_valid(_title_menu) or not _title_menu.visible: return
 _title_menu.hide()
 company_foundation = FoundationForm.new()
 company_foundation.name = "CompanyFoundation"
 company_foundation.from_title = true
 _canvas.add_child(company_foundation)
 company_foundation.set_seed(randi_range(1, 2147483646))
 company_foundation.cancelled.connect(_cancel_company_foundation.bind(company_foundation))
 company_foundation.submitted.connect(_submit_title_foundation.bind(company_foundation))

func _submit_title_foundation(company_name: String, banner: String, seed: int, owner: Control) -> void:
 if not is_instance_valid(_title_menu) or owner != company_foundation: return
 if not session.new_company(seed, company_name, banner):
  company_foundation.error_label.text = session.last_error
  return
 _retire_company_foundation()
 _replace_world()

func _retire_company_foundation() -> void:
 super._retire_company_foundation()
 if is_instance_valid(_title_menu): _return_to_title()

func _open_save_browser(mode: String = "save") -> void:
 if not is_instance_valid(_title_menu):
  super._open_save_browser(mode)
  return
 if mode != "load" or not _title_menu.visible or _title_menu.load_button.disabled: return
 _title_menu.hide()
 save_browser = SaveBrowser.new()
 save_browser.host = self
 save_browser.load_only = true
 _canvas.add_child(save_browser)

func _close_save_browser() -> void:
 if not _save_browser_open(): return
 super._close_save_browser()
 if is_instance_valid(_title_menu): _return_to_title(true)

func _replace_world() -> void:
 if is_instance_valid(_title_menu):
  # Remove the title from the tree, not just its pixels, before camp owns input.
  _canvas.remove_child(_title_menu)
  _title_menu.queue_free()
  _title_menu = null
 super._replace_world()

func observation() -> Dictionary:
 if not is_instance_valid(_title_menu): return super.observation()
 var rect := get_viewport().get_visible_rect()
 var tx := get_viewport().get_final_transform()
 return {"phase": "title", "checkpoint_path": checkpoint_path, "checkpoint_origin": session.checkpoint_origin(),
  "viewport": [rect.size.x, rect.size.y], "screen_transform": [tx.x.x, tx.x.y, tx.y.x, tx.y.y, tx.origin.x, tx.origin.y],
  "title_menu": {"visible": _title_menu.visible, "new_company": _control_observation(_title_menu.new_button),
   "load": _control_observation(_title_menu.load_button), "quit": _control_observation(_title_menu.quit_button)},
  "company_foundation": company_foundation.observation() if _foundation_open() else {"open": false},
  "named_saves": save_browser.observation() if _save_browser_open() else {"open": false}}
