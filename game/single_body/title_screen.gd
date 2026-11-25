extends Control
## Branded, native-control entry screen. No campaign or persistence operations.
signal new_requested
signal load_requested
signal quit_requested

const UI = preload("res://ui_polish/style.gd")
const FRONTISPIECE = preload("res://engraved_imprint/frontispiece.png")
const SERIF = preload("res://assets/serif.ttf")
var new_button: Button
var load_button: Button
var quit_button: Button
var _save_hint: Label

func _ready() -> void:
 name = "TitleScreen"
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 theme = UI.theme()
 var background := ColorRect.new()
 background.color = UI.BG
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(center)
 var binding := PanelContainer.new()
 binding.custom_minimum_size.x = 858
 binding.add_theme_stylebox_override("panel", UI.Press.box("binding", 32, 26))
 center.add_child(binding)
 var contents := VBoxContainer.new()
 contents.add_theme_constant_override("separation", 15)
 binding.add_child(contents)
 _label(contents, "E N G R A V E D   /   C A M P A I G N", 14, UI.GOLD)
 var heading := _label(contents, "The Ashen Company", 56, UI.TEXT)
 heading.add_theme_font_override("font", SERIF)
 var frame := PanelContainer.new()
 frame.add_theme_stylebox_override("panel", UI.panel(UI.SURFACE, UI.LINE, 2))
 contents.add_child(frame)
 var engraving := AtlasTexture.new()
 engraving.atlas = FRONTISPIECE
 # Use only the illustration: the heading above stays real, accessible text.
 engraving.region = Rect2(37, 123, 886, 267)
 engraving.filter_clip = true
 var art := TextureRect.new()
 art.texture = engraving
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.custom_minimum_size.y = 235
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 frame.add_child(art)
 var actions := VBoxContainer.new()
 actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 actions.custom_minimum_size.x = 312
 actions.add_theme_constant_override("separation", 9)
 contents.add_child(actions)
 new_button = _button(actions, "NewCompany", "New Company", new_requested.emit, true)
 load_button = _button(actions, "LoadCompany", "Load", load_requested.emit)
 quit_button = _button(actions, "Quit", "Quit", quit_requested.emit)
 _save_hint = _label(contents, "", 15, UI.MUTED)
 _save_hint.custom_minimum_size.y = 24

func set_load_available(available: bool) -> void:
 load_button.disabled = not available
 _save_hint.text = "" if available else "No saved company yet."

func _label(parent: Node, text: String, size: int, color: Color) -> Label:
 var label := Label.new()
 label.text = text
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 UI.label(label, size, color)
 parent.add_child(label)
 return label

func _button(parent: Node, id: String, text: String, action: Callable, primary: bool = false) -> Button:
 var button := Button.new()
 button.name = id
 button.text = text
 button.custom_minimum_size.y = 48
 button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 UI.button(button, primary)
 button.add_theme_font_size_override("font_size", 18)
 button.pressed.connect(action)
 parent.add_child(button)
 return button
