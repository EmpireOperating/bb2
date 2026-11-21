extends RefCounted
## Read-only physical readiness; never infer battle state from camp previews.
const Arsenal = preload("res://src/arsenal.gd")
const Named = preload("res://src/named_equipment.gd")
static func is_crossbow(item: Dictionary, catalog: Dictionary) -> bool:
 return catalog.has(item.get("definition","")) and Named.valid(item,catalog) and Arsenal.family(str(item.get("definition",""))) == "crossbow"
static func readiness(item: Dictionary, ammo: Dictionary, catalog: Dictionary, camp: bool = false) -> String:
 if not is_crossbow(item,catalog):return ""
 var state := "LOADED" if item.get("loaded") == true else "UNLOADED" if item.get("loaded") == false else "Readiness not recorded"
 if camp:state += " · CAMP record"
 elif item.get("loaded") == false:state += " · Reload required"
 var supply := "Bolts 0 · no bolt case equipped"
 if not ammo.is_empty():
  var d: Dictionary = Named.definition(ammo,catalog) if Named.valid(ammo,catalog) else {}
  if ammo.get("definition","") != Arsenal.ammo_type(item.definition):supply = "Bolts 0 · mismatched ammunition"
  elif d.is_empty():supply = "Bolts unavailable · invalid ammunition metadata"
  else:supply = "Bolts %d/%d%s" % [ammo.get("condition",0),d.get("durability",0)," · EMPTY" if int(ammo.get("condition",0)) <= 0 else ""]
 return state+"\n"+supply


static func inspection(item: Dictionary, ammo: Dictionary, unit: Dictionary, battle, catalog: Dictionary, camp: bool = false) -> String:
 if not is_crossbow(item,catalog):return ""
 var lines := PackedStringArray([readiness(item,ammo,catalog,camp)])
 if unit.is_empty():return "\n".join(lines)
 # Stash candidate costs must describe this physical item, not the held weapon.
 # This detached preview grants no encounter readiness or command admission.
 var preview := unit.duplicate(true)
 preview.weapon = catalog[item.definition].get("weapon",item.definition)
 preview.arms.weapon = item.duplicate(true)
 lines.append("Selected fighter preview" if camp else "Current fighter costs")
 for special: bool in [false,true]:
  var cost: Dictionary = battle.action_cost(preview,special)
  lines.append("%s %d AP / %d fatigue" % [battle.special_info(preview.weapon).name if special else Arsenal.primary(preview.weapon),cost.ap,cost.fatigue])
 return "\n".join(lines)

static func summary(item: Dictionary, ammo: Dictionary, unit: Dictionary, battle, catalog: Dictionary, camp: bool = false) -> String:
 var text: String = load("res://ui_polish/inventory_presentation.gd").summary(item,catalog)
 if not is_crossbow(item,catalog):return text
 # The canonical summary already contains the effective Named armor percentages.
 return text+"\n"+inspection(item,ammo,unit,battle,catalog,camp)


static func present_inspector(view, unit: Dictionary, catalog: Dictionary, battle) -> void:
 # Read physical arms after the passive slot painter: finalized slots may omit
 # loaded/roll metadata. Reuse its card selection + rarity rather than replacing it.
 var equipment = load("res://hollow_campaign/appearance.gd")
 var ammo: Dictionary = unit.get("arms",{}).get("ammo",{})
 for slot: String in ["mainhand"]+view.carry_cards.keys():
  var item: Dictionary = unit.get("arms",{}).get("weapon" if slot=="mainhand" else slot,{})
  if not is_crossbow(item,catalog):continue
  var card = view.inventory_cards.mainhand if slot=="mainhand" else view.carry_cards[slot]
  view._card(card,slot,item,catalog,null)
  card.caption.text=card.caption.text.get_slice("\n",0)+"\n"+readiness(item,ammo,catalog)
  card.caption.max_lines_visible=3;card.caption.custom_minimum_size.y=54
  card.custom_minimum_size.y=116
  var detail := summary(item,ammo,unit,battle,catalog)
  card.tooltip_text=detail+"\n\n"+equipment.item_details(item,catalog)
  card.set_meta("inspection_text",card.tooltip_text)
  if slot=="mainhand":view.slot_labels.mainhand.text="MAINHAND\n"+card.tooltip_text
  else:view.carried_notes.text+="\n\n"+slot.to_upper()+"\n"+detail

static func present_combat(view, id: int) -> void:
 # Rebuild from current selection each repaint. Never cache a quote or physical UID.
 for key: String in ["basic","special"]:view.action_buttons[key].add_theme_constant_override("icon_max_width",76)
 if id < 0 or id >= view.battle.units.size():return
 var battle = view.battle
 var unit: Dictionary = battle.units[id]
 if unit.side != 0 or not battle.unit_visible(0,id):return
 var item: Dictionary = unit.get("arms",{}).get("weapon",{})
 if not is_crossbow(item,battle.armor_catalog):return
 var state := readiness(item,unit.arms.get("ammo",{}),battle.armor_catalog)
 var current := ""
 for action: String in ["basic","special"]:
  # Shoot uses the selected target; Reload always uses the targetless command.
  var local: Dictionary = battle.action_quote(id,action)
  var q: Dictionary = local if action == "special" else battle.action_quote(id,action,view.controller.target,view.controller.target_hex,view.controller.carry_slot)
  var shown: Dictionary = q if action == "special" else view.controller.public_quote(q)
  # Retain the visibility boundary for target-dependent failures. These two
  # physical-own-resource refusals disclose no target/hidden-board information.
  if q.reason == local.reason or q.reason in ["No matching ammunition.","Crossbow needs reloading."]:shown.reason = q.reason
  if action == "basic" and int(q.ap) == 0 and not q.legal:
   shown.ap = local.ap;shown.fatigue = local.fatigue
  var name: String = Arsenal.primary(unit.weapon) if action == "basic" else battle.special_info(unit.weapon).name
  var cost := "%d AP / %d fatigue" % [shown.ap,shown.fatigue]
  var button: Button = view.action_buttons[action]
  button.text = "%s [%d]\n%d AP · %d FAT" % [name,1 if action == "basic" else 2,shown.ap,shown.fatigue]
  button.add_theme_constant_override("icon_max_width",32)
  # No target is an invitation to arm Shoot, not authority to execute it.
  button.disabled = (not q.legal and q.reason != "Choose a living enemy.") or (action == "basic" and (not item.get("loaded",false) or battle.ammo_count(unit) <= 0))
  button.tooltip_text = name+" · "+cost+"\n"+state+"\n"+(shown.reason if not q.legal else "Choose this skill, then click a legal enemy to shoot." if action == "basic" else "Click Reload or press [2] to reload now. No target needed.")
  if view.controller.action == action:current = name+" · "+cost+(" · "+shown.reason if not q.legal else "")
 view.target_label.tooltip_text += "\n"+state+"\n"+view.action_buttons.basic.tooltip_text+"\n"+view.action_buttons.special.tooltip_text
 view.target_label.text = state.replace("\n"," · ")+"\n"+(current if not current.is_empty() else view.target_label.text)
 view.combat_selected_identity.tooltip_text += "\n"+state

