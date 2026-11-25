extends RefCounted
## Read-only summaries of canonical physical items. Full provenance stays unchanged.
const Equipment = preload("res://hollow_campaign/appearance.gd")
const Named = preload("res://src/named_equipment.gd")
static func identity(item: Dictionary, catalog: Dictionary) -> String:
 if item.is_empty():return "Empty"
 var tier := Equipment.item_tier(item,catalog)
 if tier == "invalid":return "Invalid equipment metadata"
 var d: Dictionary = Named.definition(item,catalog)
 if d.is_empty():return "Equipment data unavailable"
 var text := str(d.get("name","Unknown item"))+" · "+(tier.capitalize() if not tier.is_empty() else "Unrated")
 var maximum := int(item.get("maximum",d.get("durability",0)))
 if maximum > 0:
  var ammo := Equipment.is_round_supply(d)
  text += " · %s %d/%d" % ["Rounds" if ammo else "Condition",item.get("condition",maximum),maximum]
  if int(item.get("condition",maximum)) <= 0:text += " · EMPTY" if ammo else " · BROKEN"
 return text
static func summary(item: Dictionary, catalog: Dictionary) -> String:
 if item.is_empty():return "Empty"
 var lines := PackedStringArray([identity(item,catalog)])
 # Select existing authoritative effect lines, not inferred rarity bonuses.
 for line: String in Equipment.item_details(item,catalog).split("\n"):
  if line.begins_with("Damage "):
   lines.append("Damage "+line.split(" → ")[-1].split(" · ")[0])
   var definition: Dictionary = catalog[item.definition]
   var weapon: Dictionary = Named.weapon(item,Equipment._weapons.get(definition.get("weapon",item.definition),{}))
   if not weapon.is_empty():
    lines.append("Armor damage %s%%" % String.num(float(weapon.armor)*100,2).trim_suffix(".0"))
    lines.append("Armor penetration %s%%" % String.num(float(weapon.pierce)*100,2).trim_suffix(".0"))
  elif line.begins_with("Protection "):
   lines.append("Protection "+line.split(" → ")[-1].split(" · ")[0])
  elif line.begins_with("Shield bonuses") or line.begins_with("Intact shield:") or line.begins_with("Accuracy ") or line.begins_with("Load "):
   lines.append(line)
  elif line.begins_with("Pocket capacity"):
   lines.append(line.split(";")[0])
  elif line.begins_with("Utility is active"):
   lines.append("Utility active at zero condition")
  else:
   for prefix: String in Equipment.EFFECT_LABELS.values():
    if line.begins_with(prefix+" "):
     lines.append(line);break
 return "\n".join(lines)
static func stats(unit: Dictionary, battle) -> String:
 if unit.is_empty():return "No current fighter."
 var s := Equipment.inventory_stats(unit,battle)
 return "Body %d/%d · Head %d/%d\nMelee %d · Ranged %d\nDefense %d / %d · pre-shield\nFatigue %d/%d · Initiative %d\nEquipment load %d · Recovery %d" % [int(unit.get("armor",0))+int(unit.get("padding",0)),int(unit.get("max_armor",0))+int(unit.get("max_padding",0)),unit.get("helmet",0),unit.get("max_helmet",0),s.get("skill",0),s.get("ranged_skill",0),s.get("defense",0),s.get("ranged_defense",0),s.get("fatigue",0),s.fatigue_max,s.effective_initiative,s.equipment_load,s.recovery]
static func omission(diagnostics: Dictionary) -> String:
 return "Some equipped layers have no exact paint · Details" if not diagnostics.get("issues",[]).is_empty() else ""
static func scroll_key(scroll: ScrollContainer, event: InputEventKey) -> bool:
 var code: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
 if not code in [KEY_HOME,KEY_END,KEY_PAGEUP,KEY_PAGEDOWN]:return false
 if event.pressed:
  var bar := scroll.get_v_scroll_bar()
  if code == KEY_HOME:scroll.scroll_vertical = 0
  elif code == KEY_END:scroll.scroll_vertical = ceili(bar.max_value)
  else:scroll.scroll_vertical += roundi(scroll.size.y*.85)*(1 if code == KEY_PAGEDOWN else -1)
 return true
static func cycle(scope: Control, backward: bool = false) -> void:
 var buttons: Array[Button] = []
 for node in scope.find_children("*","Button",true,false):
  if node.is_visible_in_tree() and not node.disabled and node.focus_mode != Control.FOCUS_NONE:buttons.append(node)
 if buttons.is_empty():return
 var index := buttons.find(scope.get_viewport().gui_get_focus_owner())
 buttons[posmod(index+(-1 if backward else 1),buttons.size())].grab_focus()
