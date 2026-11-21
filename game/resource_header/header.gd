extends Control
## Read-only Company supplies. Painted symbols own the visible names; tooltips explain them.
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
var entries := {}
var wages: Label
var column: VBoxContainer
var purse: HBoxContainer
var supplies: HBoxContainer
var _company := false
func _init(company: bool = false) -> void:
 _company = company
 name = "ResourceHeader"
 mouse_filter = Control.MOUSE_FILTER_PASS
 column = VBoxContainer.new()
 column.add_theme_constant_override("separation",0)
 add_child(column);column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 purse = HBoxContainer.new();purse.name = "Purse"
 if not _company:
  supplies = HBoxContainer.new();supplies.name = "Supplies"
 for row in ([purse] if _company else [purse,supplies]):
  row.alignment = BoxContainer.ALIGNMENT_END
  row.add_theme_constant_override("separation",12)
  row.custom_minimum_size.y = 24
  row.mouse_filter = Control.MOUSE_FILTER_PASS
  column.add_child(row)
 for i in RESOURCES.size():
  var entry := HBoxContainer.new();entry.name = RESOURCES[i][0]
  entry.add_theme_constant_override("separation",4)
  entry.mouse_filter = Control.MOUSE_FILTER_PASS
  (purse if _company or RESOURCES[i][0] in ["Crowns","Ammo"] else supplies).add_child(entry)
  var icon := TextureRect.new();icon.name = "Icon"
  icon.texture = load(PAINT+RESOURCES[i][1]+".png")
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size = Vector2(24,24)
  icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  entry.add_child(icon);Press.mount_icon(icon,true)
  var value := _number();value.name = "Value";entry.add_child(value)
  entries[RESOURCES[i][0]] = entry
 wages = _number();wages.name = "Wages"
 wages.add_theme_font_size_override("font_size",14)
 wages.add_theme_color_override("font_color",Press.BRASS)
 wages.mouse_filter = Control.MOUSE_FILTER_PASS
 purse.add_child(wages)
 if _company:
  # Keep one line of icons/amounts; daily upkeep belongs on the Crowns hover.
  purse.size_flags_vertical = Control.SIZE_EXPAND_FILL
  wages.hide()
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
  entry.get_node("Value").text = str(values[i])
  entry.get_node("Value").add_theme_color_override("font_color",Press.VERMILION if values[i] == 0 else Press.TYPE)
  entry.tooltip_text = "%s: %d" % [RESOURCES[i][2],values[i]]
 wages.text = "%d / day" % c.wage_cost()
 wages.tooltip_text = "Daily company wages: %d crowns / day" % c.wage_cost()
 if _company:_company_tooltips(c)
 _fit_numbers()
func _company_tooltips(c) -> void:
 var daily_wages: int = c.wage_cost()
 var mouths: int = c.alive_count()
 entries.Crowns.tooltip_text += "\nWages: %d crowns / day" % daily_wages
 if c.arrears > 0:entries.Crowns.tooltip_text += "\n%d crowns in arrears" % c.arrears
 entries.Crowns.tooltip_text += "\n"+(_full_days(maxi(0,c.crowns-c.arrears),daily_wages)+" of wages" if daily_wages > 0 else "No daily wages")
 entries.Food.tooltip_text += "\n"+(_full_days(c.food,mouths)+" at %d rations / day" % mouths if mouths > 0 else "No daily ration use")
 var needed := Recovery.tools_needed(c)
 entries.Tools.tooltip_text += "\nFull repair: %s (worn repairables + marked stash)" % _tool_amount(needed)
 if needed > c.tools:entries.Tools.tooltip_text += "\nShort by "+_tool_amount(needed-c.tools)
func _full_days(stock: int, per_day: int) -> String:
 var days := floori(float(stock)/per_day)
 return "%d full day%s" % [days,"" if days == 1 else "s"]
func _tool_amount(count: int) -> String:
 return "%d tool%s" % [count,"" if count == 1 else "s"]
func _fit_numbers() -> void:
 if not is_inside_tree() or size.x <= 0:return
 # Keep exact digits and full-size paintings; only unusually large stocks need smaller type.
 var font: Font = wages.get_theme_font("font")
 var font_size := 16
 var separation := 12
 for candidate in [16,14,12]:
  font_size = candidate
  separation = 8 if candidate < 16 else 12
  if _company:
   var width: float = separation*(entries.size()-1)
   for entry in entries.values():width += 28+ceilf(font.get_string_size(entry.get_node("Value").text,HORIZONTAL_ALIGNMENT_LEFT,-1,candidate).x)
   if width <= size.x:break
   continue
  var supply_width: float = separation*2
  for key in ["Food","Tools","Medicine"]:
   supply_width += 28+ceilf(font.get_string_size(entries[key].get_node("Value").text,HORIZONTAL_ALIGNMENT_LEFT,-1,candidate).x)
  var purse_width: float = separation*2+ceilf(font.get_string_size(wages.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x)
  for key in ["Crowns","Ammo"]:
   purse_width += 28+ceilf(font.get_string_size(entries[key].get_node("Value").text,HORIZONTAL_ALIGNMENT_LEFT,-1,candidate).x)
  if maxf(supply_width,purse_width) <= size.x:break
 for entry: HBoxContainer in entries.values():entry.get_node("Value").add_theme_font_size_override("font_size",font_size)
 purse.add_theme_constant_override("separation",separation)
 if not _company:supplies.add_theme_constant_override("separation",separation)
 column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
