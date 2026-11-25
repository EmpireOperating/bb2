extends Control
## One passive resource row and one forecast, shared by Company, map and town.
const Press=preload("res://engraved_ui/press.gd")
const Recovery=preload("res://src/recovery.gd")
const PAINT := "res://company_town/assets/resources/"
const RESOURCES := [
 ["Crowns","crowns-32","Crowns · company purse"],
 ["Food","rations-32","Food · rations for the company"],
 ["Tools","repair-hammers-32","Tools · supplies for equipment repairs"],
 ["Medicine","medicine-painted-32","Medicine · supplies for treating injuries"],
 ["Ammo","ammunition-painted-32","Ammunition · supplies for ranged weapons"]
]
# Font size, icon width, row gap, icon-to-number gap. Use the tighter sizes
# only when unusually large exact counts need them in the fixed HUD width.
const FITS := [Vector4i(16,24,12,4),Vector4i(14,24,8,4),Vector4i(12,24,8,4),Vector4i(12,16,4,2),Vector4i(11,16,4,2)]
var entries := {}
var row: HBoxContainer

func _init(align_right: bool = false) -> void:
 name = "ResourceHeader"
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 row = HBoxContainer.new()
 row.name = "Resources"
 row.alignment = BoxContainer.ALIGNMENT_END if align_right else BoxContainer.ALIGNMENT_BEGIN
 row.add_theme_constant_override("separation",12)
 row.custom_minimum_size.y = 24
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(row);row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for spec in RESOURCES:
  var entry := HBoxContainer.new();entry.name = spec[0]
  entry.add_theme_constant_override("separation",4)
  entry.mouse_filter = Control.MOUSE_FILTER_PASS # Hover, never a command or focus target.
  row.add_child(entry)
  var icon := TextureRect.new();icon.name = "Icon"
  icon.texture = load(PAINT+spec[1]+".png")
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size = Vector2(24,24)
  icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  entry.add_child(icon);Press.mount_icon(icon,true)
  var value := _number();value.name = "Value";entry.add_child(value)
  entries[spec[0]] = entry
 resized.connect(_fit_numbers)

func _number() -> Label:
 var label := Label.new()
 label.add_theme_font_size_override("font_size",16)
 label.add_theme_color_override("font_color",Press.TYPE)
 label.add_theme_color_override("font_shadow_color",Color(0,0,0,.85))
 label.add_theme_constant_override("shadow_offset_x",1)
 label.add_theme_constant_override("shadow_offset_y",1)
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return label

func present(c) -> void:
 var values := [c.crowns,c.food,c.tools,c.medicine,c.ammunition]
 for i in RESOURCES.size():
  var entry: HBoxContainer = entries[RESOURCES[i][0]]
  var value: Label = entry.get_node("Value")
  value.text = str(values[i])
  value.add_theme_color_override("font_color",Press.VERMILION if values[i] == 0 else Press.TYPE)
  entry.tooltip_text = "%s: %d" % [RESOURCES[i][2],values[i]]
 _upkeep_tooltips(c)
 _fit_numbers()

func _upkeep_tooltips(c) -> void:
 var daily_wages: int = c.wage_cost()
 var mouths: int = c.alive_count()
 entries.Crowns.tooltip_text += "\nWages: %d crowns / day" % daily_wages
 if c.arrears > 0:entries.Crowns.tooltip_text += "\n%d crowns in arrears" % c.arrears
 entries.Crowns.tooltip_text += "\n"+(_full_days(maxi(0,c.crowns-c.arrears),daily_wages)+" of wages" if daily_wages > 0 else "No daily wages")
 entries.Food.tooltip_text += "\n"+(_full_days(c.food,mouths)+" at %d rations / day" % mouths if mouths > 0 else "No daily ration use")
 var tools := Recovery.tools_needed(c)
 entries.Tools.tooltip_text += "\nFull repair: %s\nWorn repairables + marked stash" % _tool_amount(tools)
 if tools > c.tools:
  entries.Tools.tooltip_text += "\nFrom current stock: %s\nShort by %s" % [_tool_amount(c.tools),_tool_amount(tools-c.tools)]
 var medicine := Recovery.medicine_needed(c)
 entries.Medicine.tooltip_text += "\nFull treatment: %d medicine\nTemporary wounds · food required" % medicine
 if medicine > c.medicine:
  entries.Medicine.tooltip_text += "\nFrom current stock: %d medicine\nShort by %d medicine" % [c.medicine,medicine-c.medicine]

func _full_days(stock: int, per_day: int) -> String:
 var days := floori(float(stock)/per_day)
 return "%d full day%s" % [days,"" if days == 1 else "s"]

func _tool_amount(count: int) -> String:
 return "%d tool%s" % [count,"" if count == 1 else "s"]

func _fit_numbers() -> void:
 if not is_inside_tree() or size.x <= 0:return
 var font: Font = entries.Crowns.get_node("Value").get_theme_font("font")
 var fit: Vector4i
 for candidate: Vector4i in FITS:
  fit = candidate
  var width: float = fit.z*(entries.size()-1)
  for entry in entries.values():width += fit.y+fit.w+ceilf(font.get_string_size(entry.get_node("Value").text,HORIZONTAL_ALIGNMENT_LEFT,-1,fit.x).x)
  if width <= size.x:break
 for entry: HBoxContainer in entries.values():
  entry.add_theme_constant_override("separation",fit.w)
  entry.get_node("Icon").custom_minimum_size.x = fit.y
  entry.get_node("Value").add_theme_font_size_override("font_size",fit.x)
 row.add_theme_constant_override("separation",fit.z)
 row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
