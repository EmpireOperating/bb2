extends "res://ui_polish/world_view.gd"
## Save / F5 checkpoints explicitly; Save As and Load open the portable library.
var _dungeon_save_notice: PanelContainer
var _dungeon_save_timer: Timer

func _ready() -> void:
 super._ready()
 iron=load("res://named_saves/iron_ui.gd").new()
 refresh()
func blocked() -> bool:
 return super.blocked() or (host!=null and host._save_browser_open())
func save_surface_available() -> bool:
 return visible and not blocked() and _surface() in ["world","company","town","sheet:menu"]
func checkpoint_surface_available() -> bool:
 return visible and not blocked() and _surface() not in ["help","confirmation","person_rename","person_details"]
func action(id: String) -> void:
 if blocked():return
 if id == "save" and not checkpoint_surface_available():return
 if id in ["save_as","load"]:
  if save_surface_available():host._open_save_browser("save" if id=="save_as" else "load")
  return
 super.action(id)
func write_save(show_notice: bool = true) -> bool:
 if show_notice and not checkpoint_surface_available():return false
 if show_notice and is_instance_valid(_dungeon_save_notice):_dungeon_save_notice.hide()
 var ok := super.write_save(show_notice)
 if show_notice and ok and not campaign.dungeons.active.is_empty():_show_dungeon_save_notice()
 return ok

func _show_dungeon_save_notice() -> void:
 if not is_instance_valid(_dungeon_save_notice):
  _dungeon_save_notice = PanelContainer.new()
  _dungeon_save_notice.name = "DungeonSaveNotice"
  _dungeon_save_notice.theme = UI.theme()
  _dungeon_save_notice.position = Vector2(525,850)
  _dungeon_save_notice.size = Vector2(390,38)
  _dungeon_save_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var message := Label.new()
  message.text = "Dungeon checkpoint saved"
  message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  message.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _dungeon_save_notice.add_child(message)
  add_child(_dungeon_save_notice)
  _dungeon_save_timer = Timer.new()
  _dungeon_save_timer.name = "DungeonSaveNoticeTimer"
  _dungeon_save_timer.one_shot = true
  _dungeon_save_timer.ignore_time_scale = true
  _dungeon_save_timer.timeout.connect(_dungeon_save_notice.hide)
  add_child(_dungeon_save_timer)
 _dungeon_save_notice.show()
 _dungeon_save_timer.start(3.0)
func _input(event: InputEvent) -> void:
 if blocked():return
 # The inherited UI handles F5/F9 after rename/Details/modifier/surface gates.
 super._input(event)
func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
 super.button(id,title,rect,enabled,primary)
 if id=="load" and not blocked():buttons[id].enabled=true
