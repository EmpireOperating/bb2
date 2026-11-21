extends Panel
## Transient painted editor. The mounted world owns context and command admission.
signal save_requested
signal cancel_requested
const UI = preload("res://ui_polish/style.gd")
var input := LineEdit.new()
var save_button := Button.new()
var cancel_button := Button.new()
var error_label := Label.new()
func _init() -> void:
 theme=UI.theme();mouse_filter=Control.MOUSE_FILTER_STOP
 var title:=Label.new();title.text="Rename companion";UI.label(title,24,UI.GOLD)
 add_child(title);title.position=Vector2(24,20)
 add_child(input);input.position=Vector2(24,64);input.size=Vector2(512,44)
 input.add_theme_stylebox_override("normal",UI.panel(UI.BG,UI.LINE,10))
 input.add_theme_stylebox_override("focus",UI.panel(UI.BG,UI.GOLD,10))
 add_child(error_label);error_label.position=Vector2(24,116);error_label.size=Vector2(512,44)
 UI.label(error_label,14,UI.MUTED);error_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 error_label.text="Only their display name changes."
 add_child(cancel_button);cancel_button.text="Cancel · Esc";UI.button(cancel_button)
 cancel_button.position=Vector2(224,170);cancel_button.size=Vector2(150,42)
 add_child(save_button);save_button.text="Save · Enter";UI.button(save_button,true)
 save_button.position=Vector2(386,170);save_button.size=Vector2(150,42)
 save_button.pressed.connect(func():save_requested.emit())
 cancel_button.pressed.connect(func():cancel_requested.emit())
func present(value: String) -> void:
 input.text=value;error_label.text="1–100 characters · one line · no control characters. Only their display name changes."
 error_label.add_theme_color_override("font_color",UI.MUTED)
 show();input.grab_focus();input.select_all()
