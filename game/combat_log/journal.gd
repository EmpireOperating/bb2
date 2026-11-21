extends VBoxContainer
## Read-only presentation of caller-admitted public strings; no Battle reference.
const Style=preload("res://ui_polish/style.gd")
var scroll: ScrollContainer
var body: VBoxContainer
var latest: Button
var entries: Array[String] = []
var following := true
var _held := 0
var _settling := false
var _layout_ticket := 0

func _init() -> void:
 name="CombatLogJournal";size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll=ScrollContainer.new();scroll.name="CombatLogScroll"
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.add_theme_stylebox_override("panel",Style.panel(Style.BG,Style.LINE,0))
 add_child(scroll)
 var inset:=MarginContainer.new();inset.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for edge in ["left","right"]:inset.add_theme_constant_override("margin_"+edge,18)
 for edge in ["top","bottom"]:inset.add_theme_constant_override("margin_"+edge,14)
 scroll.add_child(inset)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",12);inset.add_child(body)
 var footer:=HBoxContainer.new();footer.custom_minimum_size.y=34;add_child(footer)
 var hint:=Label.new();hint.text="Newest entries at the bottom"
 Style.label(hint,13,Style.MUTED);hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(hint)
 latest=Button.new();latest.name="CombatLogLatest";latest.text="Jump to latest ↓"
 Style.button(latest);latest.add_theme_font_size_override("font_size",14)
 latest.focus_mode=Control.FOCUS_ALL;footer.add_child(latest);latest.hide()
 latest.pressed.connect(jump_to_latest)
 scroll.get_v_scroll_bar().value_changed.connect(_scrolled)
 scroll.gui_input.connect(_scroll_input)
 scroll.get_v_scroll_bar().gui_input.connect(_scroll_input)
 scroll.resized.connect(_queue_layout)

func present(messages: Array[String], reopen: bool=false) -> void:
 if reopen:following=true
 if not reopen and messages==entries:return
 _held=scroll.scroll_vertical
 entries=messages.duplicate()
 for child in body.get_children():body.remove_child(child);child.queue_free()
 var shown:Array[String]=entries.duplicate()
 if shown.is_empty():shown.append("No visible combat events yet.")
 for message in shown:
  var row:=RichTextLabel.new();row.bbcode_enabled=false;row.fit_content=true;row.scroll_active=false
  row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.mouse_filter=Control.MOUSE_FILTER_PASS
  row.add_theme_font_size_override("normal_font_size",17)
  row.add_theme_constant_override("line_separation",3)
  var turn:=entries.is_empty() or message.contains(" acts · initiative ") or message.contains(" acts after waiting · initiative ") or message.contains(" waits; remaining AP") or message.begins_with("Round ")
  row.add_theme_color_override("default_color",Style.MUTED if turn else Style.TEXT)
  body.add_child(row)
  if turn:row.add_text(message)
  else:
   for span in spans(message):
    row.push_color(span.color);row.add_text(span.text);row.pop()
 _queue_layout()

func spans(message: String) -> Array:
 # Never parse event strings as BBCode, URLs or image paths. Mark only literal
 # damage tokens; all names, punctuation and unavailable values stay intact.
 var out:Array=[];var cursor:=0
 var numbers:=RegEx.create_from_string("\\b[0-9]+ (HP|armour|helm|mail|padding)\\b")
 for hit in numbers.search_all(message):
  if hit.get_start()>cursor:out.append({"text":message.substr(cursor,hit.get_start()-cursor),"color":Style.TEXT})
  out.append({"text":hit.get_string(),"color":Style.DANGER if hit.get_string().ends_with("HP") else Style.GOLD})
  cursor=hit.get_end()
 if cursor<message.length():out.append({"text":message.substr(cursor),"color":Style.TEXT})
 return out

func jump_to_latest() -> void:
 following=true
 _queue_layout()

func _scrolled(value: float) -> void:
 if _settling:return
 _held=int(value)
 var bar:=scroll.get_v_scroll_bar()
 following=absf(value-maxf(0,bar.max_value-bar.page))<=2
 latest.visible=not following

func _scroll_input(event: InputEvent) -> void:
 if event is InputEventMouseButton or event is InputEventPanGesture or event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
  # User intent wins even if a previous append is still settling containers.
  _remember_user_scroll.call_deferred()

func _remember_user_scroll() -> void:
 var was_settling:=_settling
 _settling=false;_scrolled(scroll.scroll_vertical);_settling=was_settling

func _queue_layout() -> void:
 if not is_inside_tree():return
 _layout_ticket+=1
 var ticket:=_layout_ticket
 _settling=true
 for i in 3:await get_tree().process_frame
 if ticket!=_layout_ticket:return
 scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value) if following else _held
 _settling=false
 latest.visible=not following
