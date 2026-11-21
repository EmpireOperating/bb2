extends Control
## Read-only shared company/field vitals. Armour is head + body + padding;
## shields remain a separate item mechanic, never invented protection here.
const HEALTH_INK = Color("ed7770")
const HEALTH_FILL = Color("b8423d")
const ARMOR_INK = Color("bec6ce")
const ARMOR_FILL = Color("8e9aa4")
var health_label: Label
var armor_label: Label
var health_bar: ProgressBar
var armor_bar: ProgressBar
func _init() -> void:
 name="Vitals";mouse_filter=Control.MOUSE_FILTER_IGNORE
 health_label=_label("HealthLabel",HEALTH_INK)
 armor_label=_label("ArmorLabel",ARMOR_INK)
 health_bar=_bar("HealthBar",HEALTH_FILL,Color("301b1d"))
 armor_bar=_bar("ArmorBar",ARMOR_FILL,Color("272d33"))
 resized.connect(_layout)
func _label(id: String, ink: Color) -> Label:
 var label:=Label.new();label.name=id;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_size_override("font_size",12)
 label.add_theme_color_override("font_color",ink)
 label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 label.max_lines_visible=1;add_child(label);return label
func _bar(id: String, fill_color: Color, background: Color) -> ProgressBar:
 var bar:=ProgressBar.new();bar.name=id;bar.show_percentage=false
 bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var bg:=StyleBoxFlat.new();bg.bg_color=background;bg.set_corner_radius_all(2)
 var fill:=bg.duplicate();fill.bg_color=fill_color
 bar.add_theme_stylebox_override("background",bg);bar.add_theme_stylebox_override("fill",fill)
 add_child(bar);return bar
func present(unit: Dictionary) -> void:
 var hp:=int(unit.get("hp",0));var max_hp:=int(unit.get("max_hp",0))
 var body:=int(unit.get("armor",0))+int(unit.get("padding",0))
 var max_body:=int(unit.get("max_armor",0))+int(unit.get("max_padding",0))
 var head:=int(unit.get("helmet",0));var max_head:=int(unit.get("max_helmet",0))
 health_label.text="HP %d / %d"%[hp,max_hp]
 armor_label.text="ARM %d / %d"%[body+head,max_body+max_head] if max_body+max_head>0 else "ARM —"
 health_bar.max_value=maxi(1,max_hp);health_bar.value=hp
 armor_bar.max_value=maxi(1,max_body+max_head);armor_bar.value=body+head
 tooltip_text="Health %d / %d\nArmour %d / %d\nHead %d / %d · Body %d / %d\nArmour combines head and body; shield condition is separate."%[hp,max_hp,body+head,max_body+max_head,head,max_head,body,max_body]
 _layout()
func clear() -> void:
 health_label.text="";armor_label.text="";tooltip_text=""
 health_bar.value=0;armor_bar.value=0
 health_bar.max_value=1;armor_bar.max_value=1
func _layout() -> void:
 if health_label==null:return
 var row:=size.y/2.0
 var font_size:=13 if size.y>=50 else 12
 for label in [health_label,armor_label]:label.add_theme_font_size_override("font_size",font_size)
 var text_height:=maxf(15,row-7)
 health_label.position=Vector2.ZERO;health_label.size=Vector2(size.x,text_height)
 health_bar.position=Vector2(0,row-5);health_bar.size=Vector2(size.x,4)
 armor_label.position=Vector2(0,row);armor_label.size=Vector2(size.x,text_height)
 armor_bar.position=Vector2(0,size.y-5);armor_bar.size=Vector2(size.x,4)
