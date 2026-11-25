extends Control
## Draft-only modal. Only the owner can publish a validated new company.
signal cancelled
signal submitted(company_name:String,banner:String,seed:int)
const UI=preload("res://ui_polish/style.gd")
const Identity=preload("res://company_banners/identity.gd")
const Art=preload("res://company_banners/art.gd")
const MOTTO=["From the ashes, we rise.","Honour beneath the antlers.","Iron in the blood.","A light against the dark.","Beauty, bound in thorns.","Courage on silver wings."]
var name_field:LineEdit
var seed_field:LineEdit
var error_label:Label
var create_button:Button
var cancel_button:Button
var cards:Dictionary={}
var selected_banner:="ash_raven"
var from_title := false
var _controls:Dictionary={}
func _ready()->void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP;theme=UI.theme()
 var shade:=ColorRect.new();shade.color=Color(0.02,0.025,0.025,0.9);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(center)
 var panel:=PanelContainer.new();panel.custom_minimum_size=Vector2(1280,780)
 panel.add_theme_stylebox_override("panel",UI.Press.box("binding",26,26));center.add_child(panel)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);panel.add_child(column)
 var eyebrow:=Label.new();eyebrow.text="FIRST MUSTER  /  LETTERS OF FOUNDATION";UI.label(eyebrow,13,UI.GOLD);column.add_child(eyebrow)
 var heading:=Label.new();heading.text="Found your company";UI.label(heading,32);heading.add_theme_font_override("font",load("res://assets/serif.ttf"));column.add_child(heading)
 var subtitle:=Label.new();subtitle.text="Choose the name and painted banner your companions will carry across the world.";UI.label(subtitle,16,UI.MUTED);column.add_child(subtitle)
 var entry:=HBoxContainer.new();entry.add_theme_constant_override("separation",24);column.add_child(entry)
 var name_column:=VBoxContainer.new();name_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;entry.add_child(name_column)
 var caption:=Label.new();caption.text="COMPANY NAME";UI.label(caption,13,UI.GOLD);name_column.add_child(caption)
 name_field=LineEdit.new();name_field.placeholder_text="e.g. The Oath-Bound";name_field.text="The Ashen Company"
 name_field.custom_minimum_size=Vector2(0,46);name_field.add_theme_font_size_override("font_size",21);name_column.add_child(name_field);_controls.name=name_field
 var seed_column:=VBoxContainer.new();seed_column.custom_minimum_size.x=220;entry.add_child(seed_column)
 caption=Label.new();caption.text="WORLD SEED";UI.label(caption,13,UI.GOLD);seed_column.add_child(caption)
 seed_field=LineEdit.new();seed_field.custom_minimum_size=Vector2(220,46);seed_field.max_length=10;seed_column.add_child(seed_field);_controls.seed=seed_field
 caption=Label.new();caption.text="CHOOSE YOUR STANDARD";UI.label(caption,13,UI.GOLD);column.add_child(caption)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);column.add_child(row)
 for i in Identity.IDS.size():
  var id:String=Identity.IDS[i]
  var card:=Button.new();card.name=id;card.toggle_mode=true;card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.custom_minimum_size=Vector2(188,370)
  card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;card.pressed.connect(select_banner.bind(id));row.add_child(card);cards[id]=card;_controls[id]=card
  var padding:=MarginContainer.new();padding.mouse_filter=Control.MOUSE_FILTER_IGNORE;padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for side in ["left","right","top","bottom"]:padding.add_theme_constant_override("margin_"+side,8)
  card.add_child(padding)
  var stack:=VBoxContainer.new();stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_theme_constant_override("separation",6);padding.add_child(stack)
  var image:=TextureRect.new();image.texture=Art.texture(id);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  image.custom_minimum_size=Vector2(160,286);image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(image)
  var title:=Label.new();title.text=Identity.TITLES[i];title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;UI.label(title,18);title.add_theme_font_override("font",load("res://assets/serif.ttf"));stack.add_child(title)
  var motto:=Label.new();motto.text=MOTTO[i];motto.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;UI.label(motto,11,UI.MUTED);stack.add_child(motto)
  var status:=Label.new();status.name="Selection";status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;UI.label(status,12,UI.GOLD);stack.add_child(status)
  card.set_meta("selection",status)
 var warning:=Label.new();warning.text="Founding does not change existing saves. Use Save / F5 in camp to save this company." if from_title else "Starting fresh replaces unsaved progress. Existing checkpoint and named saves stay unchanged.\nSave/F5 checkpoints the new company; named saves change only through the save library. Cancel keeps your company as it is.";UI.label(warning,14,UI.MUTED);column.add_child(warning)
 error_label=Label.new();error_label.custom_minimum_size.y=23;UI.label(error_label,14,UI.DANGER);column.add_child(error_label)
 var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",16);column.add_child(footer)
 var hint:=Label.new();hint.text="Spaces, apostrophes & hyphens welcome · 1–40 characters";UI.label(hint,13,UI.MUTED);hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(hint)
 cancel_button=Button.new();cancel_button.text="Cancel · Esc";cancel_button.custom_minimum_size=Vector2(160,46);UI.button(cancel_button);footer.add_child(cancel_button);_controls.cancel=cancel_button;cancel_button.pressed.connect(func():cancelled.emit())
 create_button=Button.new();create_button.text="Found company";create_button.custom_minimum_size=Vector2(200,46);UI.button(create_button,true);footer.add_child(create_button);_controls.create=create_button;create_button.pressed.connect(_submit)
 name_field.text_changed.connect(func(_value):_validate());seed_field.text_changed.connect(func(_value):_validate())
 name_field.text_submitted.connect(func(_value):_validate();seed_field.grab_focus())
 select_banner(selected_banner);_validate();name_field.grab_focus();name_field.select_all()
func set_seed(value:int)->void:
 seed_field.text=str(value);_validate()
func select_banner(id:String)->void:
 if id not in Identity.IDS:return
 selected_banner=id
 for key in cards:
  var card:Button=cards[key];var chosen:bool=key==id
  card.set_pressed_no_signal(chosen)
  card.add_theme_stylebox_override("normal",UI.Press.box("active" if chosen else "leaf",4,4))
  card.add_theme_stylebox_override("pressed",UI.Press.box("active",4,4))
  card.add_theme_stylebox_override("hover",UI.Press.box("prime",4,4))
  var focus:=UI.panel(Color.TRANSPARENT,UI.TEXT,4);focus.set_border_width_all(2);card.add_theme_stylebox_override("focus",focus)
  card.get_meta("selection").text="◆  SELECTED" if chosen else " "
 _validate()
func _validate()->void:
 if not is_instance_valid(name_field) or not is_instance_valid(seed_field) or not is_instance_valid(create_button):return
 var reason:=Identity.name_error(name_field.text)
 if reason.is_empty() and (not seed_field.text.is_valid_int() or int(seed_field.text)<=0 or int(seed_field.text)>2147483646):reason="Use a world seed from 1 to 2147483646."
 if reason.is_empty() and selected_banner not in Identity.IDS:reason="Choose a company banner."
 error_label.text=reason;create_button.disabled=not reason.is_empty()
func _submit()->void:
 _validate()
 if create_button.disabled:return
 submitted.emit(name_field.text,selected_banner,int(seed_field.text))
func observation()->Dictionary:
 var controls:Dictionary={}
 for id in _controls:
  var c:Control=_controls[id];var r:=c.get_global_rect()
  controls[id]={"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"center":[r.get_center().x,r.get_center().y],"visible":c.is_visible_in_tree(),"enabled":not c.disabled if c is Button else c.editable}
 return {"open":is_visible_in_tree(),"name":name_field.text,"banner":selected_banner,"banner_ids":Identity.IDS.duplicate(),"seed":seed_field.text,"error":error_label.text,"controls":controls}
