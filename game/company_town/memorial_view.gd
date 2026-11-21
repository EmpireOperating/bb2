extends Control
## Read-only remembered people. No command, save or campaign-state mutation.
signal close_requested
const UI=preload("res://ui_polish/style.gd")
const IronSkin=preload("res://iron_oath/skin.gd")
var host
var text:RichTextLabel
var close_button:Button
var margin:MarginContainer
func _ready()->void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 theme=UI.theme()
 var backdrop:=TextureRect.new();backdrop.texture=IronSkin.texture("camp")
 backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 backdrop.modulate=Color(0.33,0.33,0.33,1);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(backdrop);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 margin=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",IronSkin.panel(24));margin.add_child(card)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",18);card.add_child(column)
 var header:=HBoxContainer.new();column.add_child(header)
 var title:=Label.new();title.text="Remembered companions";UI.label(title,30);title.add_theme_font_override("font",load("res://assets/serif.ttf"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
 close_button=Button.new();close_button.text="Return to Company [Esc]";UI.button(close_button);close_button.custom_minimum_size=Vector2(240,44);close_button.pressed.connect(_close);header.add_child(close_button)
 var caption:=Label.new();caption.text="Their names and service remain part of the company.";UI.label(caption,17,UI.MUTED);column.add_child(caption)
 text=RichTextLabel.new();text.bbcode_enabled=false;text.scroll_active=true;text.focus_mode=Control.FOCUS_ALL;text.size_flags_vertical=Control.SIZE_EXPAND_FILL;text.add_theme_font_size_override("normal_font_size",19);column.add_child(text)
 resized.connect(_layout);_layout();close_button.grab_focus()
func _layout()->void:
 if margin==null:return
 var horizontal:=maxi(28,int((size.x-1120)/2))
 for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,horizontal)
 for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,40)
func show_company(c)->void:
 var entries:Array[String]=[]
 for person:Dictionary in c.soldiers:
  if person.alive:continue
  var entry:String="%s\n%s · Day %d\n%d battles · %d kills · %d XP" % [person.name,person.get("title",""),person.fallen_day,person.battles,person.kills,person.xp]
  for i in range(person.history.size()-1,-1,-1):
   var record:Dictionary=person.history[i]
   entry+="\n\nDay %d · %s\n%s" % [record.day,str(record.kind).capitalize(),record.text]
  entries.append(entry)
 text.text="No companions have fallen.\n\nMay this page stay empty." if entries.is_empty() else "\n\n────────────────────────────\n\n".join(entries)
func _blocked()->bool:
 return not is_visible_in_tree() or host==null or host.error_panel.visible or host.aftermath_panel.visible
func _close()->void:
 if not _blocked():close_requested.emit()
func _input(event:InputEvent)->void:
 if _blocked() or not event is InputEventKey or not event.pressed:return
 if event.keycode==KEY_ESCAPE:
  if not event.echo:_close()
  get_viewport().set_input_as_handled()
 elif event.keycode==KEY_TAB:
  if not event.echo:
   if get_viewport().gui_get_focus_owner()==close_button:text.grab_focus()
   else:close_button.grab_focus()
  get_viewport().set_input_as_handled()
func observation()->Dictionary:
 var r:=close_button.get_global_rect()
 return {"open":is_visible_in_tree(),"text":text.text,"close":{"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"enabled":not _blocked()}}
