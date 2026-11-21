extends RefCounted
## Shared presentation tokens only. No game state, commands or persistence.
const Press = preload("res://engraved_ui/press.gd")
const PaintedSkin = preload("res://iron_oath/skin.gd")
const BG := Color("172019")
const SURFACE := Color("202c24")
const RAISED := Color("2b362c")
const LINE := Color("596854")
const TEXT := Color("f1e6c6")
const MUTED := Color("bac2a9")
const GOLD := Color("e5c180")
const DANGER := Color("f0a188")
const HEALTH := Color("9dc5ad")
const BLUE := Color("a1cbd6")
static var _theme: Theme

static func panel(background: Color = SURFACE, edge: Color = LINE, padding: int = 12) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color=background;box.border_color=edge
 box.set_border_width_all(1);box.set_corner_radius_all(2)
 box.content_margin_left=padding;box.content_margin_right=padding
 box.content_margin_top=padding;box.content_margin_bottom=padding
 return box

static func theme() -> Theme:
 if _theme!=null:return _theme
 var value := Theme.new()
 var font:Font=load("res://assets/sans.ttf")
 if font!=null:value.default_font=font
 value.default_font_size=15
 for type in ["Label","Button","CheckButton","OptionButton","LineEdit","RichTextLabel"]:
  value.set_color("font_color",type,TEXT)
  value.set_color("font_disabled_color",type,Color("b3b9a9"))
 value.set_color("font_hover_color","Button",TEXT)
 value.set_color("font_pressed_color","Button",TEXT)
 value.set_color("font_focus_color","Button",TEXT)
 value.set_stylebox("panel","PanelContainer",PaintedSkin.panel())
 value.set_stylebox("panel","Panel",PaintedSkin.panel())
 value.set_stylebox("normal","Button",PaintedSkin.button())
 value.set_stylebox("hover","Button",PaintedSkin.button(false,true))
 value.set_stylebox("pressed","Button",PaintedSkin.button(false,true))
 value.set_stylebox("disabled","Button",PaintedSkin.button(false,false,true))
 value.set_stylebox("focus","Button",Press.focus())
 value.set_stylebox("panel","PopupPanel",panel(BG,LINE,12))
 value.set_stylebox("panel","TooltipPanel",panel(BG,MUTED,12))
 value.set_color("font_color","TooltipLabel",TEXT)
 value.set_font_size("font_size","TooltipLabel",14)
 value.set_constant("separation","VBoxContainer",8)
 value.set_constant("separation","HBoxContainer",8)
 value.set_stylebox("scroll","VScrollBar",panel(BG,BG,0))
 value.set_stylebox("grabber","VScrollBar",panel(LINE,LINE,0))
 value.set_stylebox("grabber_highlight","VScrollBar",panel(MUTED,MUTED,0))
 value.set_stylebox("grabber_pressed","VScrollBar",panel(GOLD,GOLD,0))
 value.set_stylebox("panel","ItemList",Press.box("leaf",4,4))
 for state in ["selected","selected_focus"]:value.set_stylebox(state,"ItemList",Press.box("active",4,4))
 value.set_color("font_color","ItemList",TEXT);value.set_color("font_selected_color","ItemList",TEXT)
 value.set_stylebox("normal","LineEdit",panel(BG,LINE,8))
 value.set_stylebox("focus","LineEdit",panel(BG,GOLD,8))
 _theme=value
 return value

static func button(control: Button, primary: bool = false) -> void:
 control.theme=theme();control.focus_mode=Control.FOCUS_ALL
 control.add_theme_font_size_override("font_size",15)
 control.add_theme_color_override("font_color",TEXT)
 control.add_theme_color_override("font_hover_color",TEXT)
 control.add_theme_color_override("font_pressed_color",TEXT)
 control.add_theme_color_override("font_focus_color",TEXT)
 control.add_theme_color_override("font_disabled_color",Color("b3b9a9"))
 control.add_theme_stylebox_override("normal",PaintedSkin.button(primary))
 control.add_theme_stylebox_override("hover",PaintedSkin.button(primary,true))
 control.add_theme_stylebox_override("pressed",PaintedSkin.button(primary,true))
 control.add_theme_stylebox_override("disabled",PaintedSkin.button(primary,false,true))
 control.add_theme_stylebox_override("focus",Press.focus())

static func label(control: Label, font_size: int = 15, color: Color = TEXT) -> void:
 control.theme=theme()
 control.add_theme_font_size_override("font_size",font_size)
 control.add_theme_color_override("font_color",color)
 control.mouse_filter=Control.MOUSE_FILTER_IGNORE
