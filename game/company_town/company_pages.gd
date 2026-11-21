extends Panel
## Read-only Character Details. The approved Character painter owns all training.
const IronSkin = preload("res://iron_oath/skin.gd")
const UI = preload("res://ui_polish/style.gd")
const Rarity = preload("res://hollow_campaign/rarity.gd")
const RollDetails = preload("res://character_details/roll_details.gd")
const EquipmentRolls = preload("res://character_details/equipment_rolls.gd")
signal close_requested
var workspace
var close_button: Button
var scroll: ScrollContainer
var column: VBoxContainer
var heading: Label
var character_text := ""
# Retained observer contract; no duplicate history page or paid actions here.
var navigation_buttons := {}
var _key := ""

func _ready() -> void:
 theme = UI.theme();mouse_filter = Control.MOUSE_FILTER_STOP
 add_theme_stylebox_override("panel",IronSkin.panel(14))
 heading = label("Character · Rarity rolls",self,27)
 close_button = Button.new();close_button.text = "Close Details / Esc"
 UI.button(close_button);close_button.pressed.connect(func():close_requested.emit());add_child(close_button)
 scroll = ScrollContainer.new();scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
 scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 scroll.focus_mode = Control.FOCUS_ALL;scroll.follow_focus = true;add_child(scroll)
 scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_NONE
 column = VBoxContainer.new();column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",18);scroll.add_child(column)
 resized.connect(_layout);_layout()

func _layout() -> void:
 if scroll == null:return
 heading.position = Vector2(24,20);heading.size = Vector2(maxf(0,size.x-340),42)
 close_button.position = Vector2(size.x-294,20);close_button.size = Vector2(270,44)
 scroll.position = Vector2(24,84);scroll.size = size-Vector2(48,110)
 # A hidden horizontal bar must not propagate a long label's minimum to the
 # parent. Recompute the wrap width when the virtual surface is resized.
 column.custom_minimum_size.x = maxf(0,scroll.size.x-scroll.get_v_scroll_bar().get_combined_minimum_size().x-12)

func label(text: String, parent: Node, font_size: int = 17, gold: bool = false) -> Label:
 var node := Label.new();node.text = text;node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 node.size_flags_horizontal = Control.SIZE_EXPAND_FILL;node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",UI.GOLD if gold else UI.TEXT)
 if font_size >= 23:node.add_theme_font_override("font",load("res://assets/serif.ttf"))
 parent.add_child(node);return node

func card() -> VBoxContainer:
 var panel := PanelContainer.new();panel.add_theme_stylebox_override("panel",IronSkin.panel(16))
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL;column.add_child(panel)
 var contents := VBoxContainer.new();contents.add_theme_constant_override("separation",10);panel.add_child(contents)
 return contents

func block(title: String, text: String) -> void:
 var contents := card()
 label(title,contents,17,true);label(text,contents)
 character_text += "\n\n"+title+"\n"+text

func roll_table(rows: Array, possible_ranges: Array = [], ceiling: int = -1) -> void:
 var contents := card()
 label("IMMUTABLE BIRTH ROLLS",contents,17,true)
 var grid := GridContainer.new();grid.columns = 4
 grid.add_theme_constant_override("h_separation",24);grid.add_theme_constant_override("v_separation",8)
 contents.add_child(grid)
 var widths := [180,160,110,380]
 for index in 4:
  var header := label(["ATTRIBUTE","ORIGINAL → ROLLED","BIRTH GAIN","COMMON · SAME BASE"][index],grid,14,true)
  header.custom_minimum_size.x = widths[index]
 for row_index in rows.size():
  var row: Array = rows[row_index]
  for index in 4:
   var text: String = row[index]
   if index == 1 and row_index < possible_ranges.size():text += "\n"+possible_ranges[row_index]
   if index == 2 and ceiling >= 0:text += "\nRange +0–%d" % ceiling
   var cell := label(text,grid,17)
   cell.custom_minimum_size = Vector2(widths[index],36)
   cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   if index == 2:cell.add_theme_color_override("font_color",UI.GOLD if row[index] != "+0" else UI.MUTED)
   if index == 3:cell.add_theme_color_override("font_color",UI.GOLD if "above Common" in row[index] else UI.MUTED)
  character_text += "\n"+" · ".join(row)
  if row_index < possible_ranges.size():character_text += " · "+possible_ranges[row_index]
 if ceiling >= 0:character_text += "\nRange +0–%d birth gain" % ceiling


func clear() -> void:
 navigation_buttons.clear();character_text = ""
 for child in column.get_children():column.remove_child(child);child.queue_free()

func refresh() -> void:
 # Compatibility with the parked Company presenter; the mounted world calls
 # present() directly and does not construct a second workspace or character.
 if workspace == null or workspace.session == null or workspace.section != "character":return
 var person: Dictionary = workspace._person()
 if person.is_empty():return
 var c = workspace.session.campaign
 var key: String = JSON.stringify(person)+JSON.stringify(c.relationships.snapshot())+JSON.stringify(workspace._unit)
 if key == _key:return
 _key = key;present(person,c,workspace._unit)

func equipped_rolls(person: Dictionary, c) -> void:
 var equipment: Array = EquipmentRolls.describe(person,c)
 var section := label("EQUIPPED · ABOVE COMMON",column,23,true)
 section.tooltip_text = "Currently worn or held by this companion. Common equipment and reserves are omitted."
 character_text += "\n\n"+section.text
 if equipment.is_empty():
  var empty := label("No above-Common equipment is currently worn or held.",column,17)
  character_text += "\n"+empty.text
 else:
  var explanation := label("Common 0–8% · Rare 0–18% · Legendary 0–25%. Tier and stat draws are independent; ceil rounding can leave results in Common overlap. Bonuses apply only where applicable; condition does not change immutable roll quality.",column,16)
  explanation.add_theme_color_override("font_color",UI.MUTED)
  character_text += "\n"+explanation.text
 for item: Dictionary in equipment:
  var contents := card()
  var title := label(item.slot+" · "+item.name,contents,20)
  title.tooltip_text = "Physical item: "+item.uid
  var badge := label(item.badge,contents,17)
  badge.add_theme_color_override("font_color",Rarity.tier_color(item.tier) if not item.tier.is_empty() else UI.MUTED)
  character_text += "\n"+title.text+" · "+badge.text
  if not item.state.is_empty():
   var state := label(item.state,contents,15);state.add_theme_color_override("font_color",UI.MUTED)
   character_text += "\n"+state.text
  if not item.note.is_empty():
   label(item.note,contents,17);character_text += "\n"+item.note
  if item.rows.is_empty():continue
  var grid := GridContainer.new();grid.columns = 4
  grid.add_theme_constant_override("h_separation",24);grid.add_theme_constant_override("v_separation",8);contents.add_child(grid)
  var widths := [180,220,110,320]
  for index in 4:
   var header := label(["STAT","ORIGINAL → ROLLED","SAVED ROLL","COMMON · SAME ITEM"][index],grid,14,true)
   header.custom_minimum_size.x = widths[index]
  for row: Dictionary in item.rows:
   for index in 4:
    var cell := label(row.cells[index],grid,17)
    cell.custom_minimum_size = Vector2(widths[index],36)
    cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    if index in [1,3]:cell.add_theme_color_override("font_color",UI.GOLD if row.above else UI.MUTED)
   character_text += "\n"+" · ".join(row.cells)

func present(person: Dictionary, _c, _unit: Dictionary) -> void:
 clear();scroll.scroll_vertical = 0
 var details: Dictionary = RollDetails.describe(person)
 if details.is_empty():
  block("ROLL DETAILS UNAVAILABLE","The saved birth-roll record is missing or invalid. No tier or bonuses can be reconstructed from current attributes.")
 else:
  var summary := card()
  var identity := HBoxContainer.new();identity.add_theme_constant_override("separation",24);summary.add_child(identity)
  label(str(person.get("name","Companion")),identity,23)
  var badge := PanelContainer.new();badge.add_theme_stylebox_override("panel",IronSkin.panel(10));identity.add_child(badge)
  var tier := label("Saved tier: "+details.tier.capitalize(),badge,17)
  tier.custom_minimum_size.x = 210;tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  tier.add_theme_color_override("font_color",Rarity.tier_color(details.tier))
  var count := "%d / 8 birth rolls exceed the Common allowance for the same original bases." % details.above_count
  label(count,summary,17)
  var range_note: String = details.range_background+" · Possible = the full birth range for this background and saved tier. Higher within that range is a stronger starting roll; it is not a percentile."
  label(range_note,summary,16)
  character_text += "\n"+str(person.get("name","Companion"))+" · "+tier.text+"\n"+count+"\n"+range_note
  roll_table(details.rows,details.possible_ranges,details.bonus_ceiling)
  block("TIER DRAW ≠ STAT QUALITY","80% Common · 18% Rare · 2% Legendary — a separate tier roll, not a quality score.\nBirth bonus per attribute: Common +0–2 · Rare +0–4 · Legendary +0–7. Rare or Legendary can roll entirely within Common range.\nThese are the immutable birth roll, not current trained attributes. Talent stars, later training, equipment, perks and temporary modifiers are separate.")
 equipped_rolls(person,_c)
 _layout()
