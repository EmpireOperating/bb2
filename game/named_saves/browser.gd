extends Control
## A real-Control modal above the retained painted world. The host owns lifetime.
const UI=preload("res://ui_polish/style.gd")
var host
var load_only := false # Set by the launch host before mounting this browser.
var rows: Array=[]
var selected_id := "@checkpoint"
var controls: Dictionary={}
var name_entry: LineEdit
var list: ItemList
var details: Label
var status: Label
var pending: Dictionary={}
var confirm_panel: VBoxContainer
var confirm_text: Label
var file_dialog: FileDialog
var import_source: Dictionary={}
func _ready() -> void:
 name="SaveLibrary"
 theme=UI.theme()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 var shade:=ColorRect.new();shade.color=Color(0.025,0.03,0.04,0.98);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(margin)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,32)
 var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",UI.Press.box("binding",24,24));margin.add_child(card)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);card.add_child(column)
 var heading:=Label.new();heading.text="Load company" if load_only else "Save & load company";UI.label(heading,28);column.add_child(heading)
 var explanation:=Label.new();explanation.text="Named saves are kept across compatible builds. Manual checkpoint never overwrites them. CAMP only — return from battle first."
 if not host.save_library.owned_checkpoint.is_empty():explanation.text="Named saves belong to this build. The manual checkpoint never overwrites them. CAMP only — return from battle first."
 if load_only:explanation.text="Choose a saved company to continue. Loading does not change your save files."
 explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;UI.label(explanation,16,UI.MUTED);column.add_child(explanation)
 list=ItemList.new();list.size_flags_vertical=Control.SIZE_EXPAND_FILL;list.custom_minimum_size.y=170;list.add_theme_constant_override("v_separation",10);column.add_child(list)
 controls["list"]=list;list.item_selected.connect(_select)
 details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;UI.label(details,15);column.add_child(details)
 var actions:=HBoxContainer.new();column.add_child(actions)
 _button(actions,"load","Load selected…",func():_request("load"))
 _button(actions,"rename","Rename selected",_rename)
 _button(actions,"overwrite","Overwrite selected…",func():_request("overwrite"))
 _button(actions,"delete","Delete selected…",func():_request("delete"))
 var names:=HBoxContainer.new();column.add_child(names)
 name_entry=LineEdit.new();name_entry.placeholder_text="Name a new save, or edit the selected name";name_entry.max_length=64;name_entry.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_entry.custom_minimum_size.y=44
 names.add_child(name_entry);controls["name_entry"]=name_entry
 _button(names,"create","Create named save",_create)
 name_entry.text_submitted.connect(func(_text):_create())
 status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;UI.label(status,16,UI.GOLD);column.add_child(status)
 confirm_panel=VBoxContainer.new();column.add_child(confirm_panel)
 confirm_text=Label.new();confirm_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;UI.label(confirm_text,17,UI.GOLD);confirm_panel.add_child(confirm_text)
 var confirmation_actions:=HBoxContainer.new();confirm_panel.add_child(confirmation_actions)
 _button(confirmation_actions,"cancel","Cancel",_cancel)
 _button(confirmation_actions,"confirm","Confirm",_confirm)
 confirm_panel.hide()
 var footer:=HBoxContainer.new();column.add_child(footer)
 _button(footer,"import","Import checkpoint…",_choose_import)
 _button(footer,"cancel_import","Cancel import",_cancel_import)
 _button(footer,"refresh","Refresh",func():refresh())
 _button(footer,"folder","Open save folder",_folder)
 _button(footer,"close","Close · Esc",func():host._close_save_browser())
 if load_only:
  names.hide()
  for id in ["rename","overwrite","delete","import","cancel_import","folder"]:controls[id].hide()
  controls.close.text="Back to title · Esc"
 refresh()
 if load_only:list.grab_focus()
 else:name_entry.grab_focus()
func _button(parent: Node, id: String, text: String, callback: Callable) -> Button:
 var button:=Button.new();button.text=text;UI.button(button,id=="create");button.custom_minimum_size.y=44;button.pressed.connect(callback);parent.add_child(button);controls[id]=button
 return button
func _folder() -> void:
 if load_only:return
 if not host.save_library._safe_root(true):_tell(host.save_library.last_error);return
 var error:=OS.shell_open(host.save_library.root_path)
 _tell("Save folder: "+host.save_library.root_path if error==OK else "Could not open folder. Copy this path: "+host.save_library.root_path)
func _tell(message: String) -> void:status.text=message
func checkpoint() -> Dictionary:
 var s=host.session
 var dir:=DirAccess.open(OS.get_user_data_dir())
 if dir==null or dir.is_link(host.checkpoint_path.get_file()) or dir.dir_exists(host.checkpoint_path.get_file()):return {"ok":false,"error":"Manual checkpoint target is a link/directory or unavailable."}
 var file:=FileAccess.open(host.checkpoint_path,FileAccess.READ)
 if file==null:return {"ok":false,"error":"No current build manual checkpoint yet."}
 if file.get_length()>s.MAX_SAVE_BYTES:file.close();return {"ok":false,"error":"Manual checkpoint exceeds bounded size."}
 var text:=file.get_as_text();file.close()
 var state: Dictionary=s.checkpoint_state(text)
 if state.is_empty():return {"ok":false,"error":"Current build manual checkpoint is corrupt/incompatible. It has not been overwritten."}
 var candidate=state.candidate
 return {"ok":true,"candidate":candidate,"checkpoint":text,"row":{"id":"@checkpoint","name":"Current build manual checkpoint","valid":true,"day":candidate.day,"company":state.company_identity.name,"location":candidate.node().name,"build":s.checkpoint_origin(),"schema":34,"updated":int(FileAccess.get_modified_time(host.checkpoint_path)),"revision":text.sha256_text()}}
func refresh(choose: String = "") -> void:
 if not pending.is_empty():return
 if not choose.is_empty():selected_id=choose
 var auto:=checkpoint()
 rows=[auto.row if auto.ok else {"id":"@checkpoint","name":"Current build manual checkpoint","valid":false,"error":auto.error,"updated":0,"revision":""}]
 rows.append_array(host.save_library.entries(host.session))
 if not host.save_library.last_error.is_empty():_tell(host.save_library.last_error)
 list.clear()
 var selected:=0
 for i in rows.size():
  var row: Dictionary=rows[i]
  var summary: String=row.name
  if row.valid:summary+=" · Day %d · %s · %s" % [row.day,row.location,Time.get_datetime_string_from_unix_time(row.updated).replace("T"," ")+" UTC"]
  else:summary+=" · Unavailable — "+row.error
  list.add_item(summary)
  if row.id==selected_id:selected=i
 if load_only and not rows[selected].valid:
  for i in rows.size():
   if rows[i].valid:selected=i;break
 list.select(selected);_select(selected)
func _select(index: int) -> void:
 if not pending.is_empty():return
 if index<0 or index>=rows.size():return
 var row: Dictionary=rows[index];selected_id=row.id
 if row.valid:
  details.text="%s · %s · campaign schema %d\nSave folder: %s" % [row.company,row.build,row.schema,host.save_library.root_path]
 else:details.text=row.error+"\nSave folder: "+host.save_library.root_path
 if row.id!="@checkpoint" and import_source.is_empty():name_entry.text=row.name if row.valid else ""
 _update_buttons()
func _create() -> void:
 if load_only or not pending.is_empty():return
 var result: Dictionary
 if import_source.is_empty():result=host.save_library.create(host.session,name_entry.text)
 else:result=host.save_library.import_checkpoint(host.session,import_source.path,name_entry.text,import_source.revision)
 if not result.ok:_tell(result.error);return
 _cancel_import()
 refresh(result.row.id);_tell("Named copy saved. Manual checkpoint will never overwrite it.")
func _choose_import() -> void:
 if load_only or not pending.is_empty():return
 if not host.save_library.owned_checkpoint.is_empty():
  _import_selected(ProjectSettings.globalize_path(host.save_library.owned_checkpoint));return
 if not is_instance_valid(file_dialog):
  file_dialog=FileDialog.new();file_dialog.title="Import current Integration08 CAMP checkpoint (source is read-only)"
  file_dialog.access=FileDialog.ACCESS_FILESYSTEM;file_dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
  file_dialog.filters=PackedStringArray(["*.json ; CAMP checkpoint JSON"])
  file_dialog.use_native_dialog=false;file_dialog.show_hidden_files=true
  add_child(file_dialog);file_dialog.file_selected.connect(_import_selected)
 file_dialog.popup_centered_ratio(0.8)
func _import_selected(path: String) -> void:
 if load_only or not pending.is_empty():return
 var result: Dictionary=host.save_library.inspect_checkpoint(host.session,path)
 if not result.ok:_tell(result.error);return
 import_source={"path":path,"revision":result.revision}
 name_entry.text="";name_entry.placeholder_text="Choose a name for this imported company"
 _tell("Selected Day %d · %s. Enter a new save name, then Import as named save. Current company and source file remain untouched." % [result.day,result.location])
 _update_buttons();name_entry.grab_focus()
func _cancel_import() -> void:
 import_source.clear();name_entry.placeholder_text="Name a new save, or edit the selected name";_update_buttons()
func _selected() -> Dictionary:
 for row in rows:
  if row.id==selected_id:return row
 return {}
func _update_buttons() -> void:
 var row:=_selected()
 var busy:=not pending.is_empty()
 for id in ["create","rename","overwrite","delete","load","refresh","folder","close","import","cancel_import"]:controls[id].disabled=busy
 controls.cancel_import.visible=not load_only and not import_source.is_empty()
 controls.create.text="Create named save" if import_source.is_empty() else "Import as named save"
 name_entry.editable=not busy
 for index in list.item_count:list.set_item_selectable(index,not busy)
 if not busy:
  controls.load.disabled=not row.get("valid",false)
  for id in ["rename","overwrite","delete"]:controls[id].disabled=row.get("id","")=="@checkpoint" or not row.get("valid",false) or not import_source.is_empty()
  if not import_source.is_empty():controls.load.disabled=true
func _rename() -> void:
 if load_only or not pending.is_empty() or controls.rename.disabled:return
 var row:=_selected()
 var result: Dictionary=host.save_library.rename_slot(host.session,row.id,name_entry.text,row.revision)
 if not result.ok:_tell(result.error);return
 refresh(row.id);_tell("Save renamed. Its campaign data is unchanged.")
func _request(kind: String) -> void:
 if load_only and kind!="load":return
 if not pending.is_empty() or not controls.has(kind) or controls[kind].disabled:return
 var row:=_selected()
 pending={"kind":kind,"row":row.duplicate(true)}
 var wording: Dictionary={"load":"Load ‘%s’? Unsaved progress will be lost. The current-build manual checkpoint and named files stay unchanged. Create a named copy of your current company first to keep unsaved progress. Use Save / F5 after loading to replace the manual checkpoint.","overwrite":"Overwrite ‘%s’ with the current company? Its previous campaign contents will be permanently replaced.","delete":"Permanently delete ‘%s’? This cannot be undone."}
 confirm_text.text=("Load ‘%s’? Your save files will stay unchanged." if load_only else wording[kind]) % row.name
 controls.confirm.text={"load":"Load company","overwrite":"Overwrite save","delete":"Delete save"}[kind]
 confirm_panel.show();_update_buttons();controls.cancel.grab_focus()
func _cancel() -> void:
 pending.clear();confirm_panel.hide();_update_buttons();controls.load.grab_focus()
func _confirm() -> void:
 if pending.is_empty():return
 if load_only and (host.save_browser!=self or pending.kind!="load"):return
 var request:=pending;pending={};confirm_panel.hide();_update_buttons()
 var row: Dictionary=request.row
 var result: Dictionary
 if request.kind=="load":
  result=host._load_library_row(row)
  if not result.ok:_tell(result.error)
  return
 if request.kind=="overwrite":result=host.save_library.overwrite(host.session,row.id,row.revision)
 else:result=host.save_library.delete_slot(row.id,row.revision)
 if not result.ok:_tell(result.error);return
 refresh(row.id if request.kind=="overwrite" else "@checkpoint")
 _tell("Selected save overwritten." if request.kind=="overwrite" else "Selected save deleted.")
func _input(event: InputEvent) -> void:
 if event is InputEventKey:
  var code: Key=event.physical_keycode if event.physical_keycode!=KEY_NONE else event.keycode
  if code==KEY_ESCAPE:
   get_viewport().set_input_as_handled()
   if event.pressed and not event.echo:
    if not pending.is_empty():_cancel()
    else:host._close_save_browser()
  elif code in [KEY_F5,KEY_F9]:get_viewport().set_input_as_handled()
func observation() -> Dictionary:
 var out: Dictionary={"open":true,"modal":true,"selected_id":selected_id,"file_picker":is_instance_valid(file_dialog) and file_dialog.visible,"import_source":import_source.get("path",""),"confirmation":pending.get("kind",""),"confirmation_text":confirm_text.text if not pending.is_empty() else "","name":name_entry.text,"message":status.text,"folder":host.save_library.root_path,"controls":{},"rows":[]}
 for id in controls:
  var control: Control=controls[id];var rect:=control.get_global_rect()
  out.controls[id]={"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"visible":control.is_visible_in_tree(),"enabled":not control.disabled if control is BaseButton else true,"text":control.text if control is Button or control is LineEdit else ""}
 for i in rows.size():
  var row: Dictionary=rows[i].duplicate(true)
  var rect:=list.get_item_rect(i);rect.position+=list.global_position-Vector2(0,list.get_v_scroll_bar().value)
  row["rect"]=[rect.position.x,rect.position.y,rect.size.x,rect.size.y]
  row["visible"]=list.get_global_rect().intersects(rect)
  out.rows.append(row)
 return out
