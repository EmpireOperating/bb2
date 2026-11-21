extends "res://terrain_pass/battlefield.gd"
## Combat controls only. Accepted world, camera, actors and ownership are inherited.
var carry_choice: OptionButton
var _mode_actor := -2
var _mode_round := -1
var _last_quote := {}
func _init() -> void:
 controller=load("res://combat_pass/controller.gd").new()
func _build_hud() -> void:
 super._build_hud()
 var details=unit_label.get_parent()
 var info=details.get_parent()
 info.offset_right=346;info.offset_top=-282
 unit_label.add_theme_font_size_override("font_size",14)
 target_label.add_theme_font_size_override("font_size",14)
 var old_actions=action_buttons.attack.get_parent()
 var columns=old_actions.get_parent()
 var panel=columns.get_parent()
 panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 panel.offset_left=358;panel.offset_right=-16;panel.offset_top=-282;panel.offset_bottom=-16
 var old_roster=roster_buttons.values()[0].get_parent()
 var roster=HFlowContainer.new();columns.add_child(roster);columns.move_child(roster,0)
 for button in roster_buttons.values():
  button.reparent(roster);button.custom_minimum_size=Vector2(72,28);button.add_theme_font_size_override("font_size",13)
 old_roster.queue_free()
 var modes=HFlowContainer.new();columns.add_child(modes);columns.move_child(modes,1)
 for mode in ["basic","special"]:
  action_buttons[mode]=_button(mode.capitalize(),func():_choose(mode));modes.add_child(action_buttons[mode])
 action_buttons.attack.reparent(modes);action_buttons.end.reparent(modes)
 # Inherited callbacks bypass our modal admission. Replace, do not add a second
 # handler: one gesture must produce at most one command.
 for key in ["attack","end"]:
  for connection in action_buttons[key].pressed.get_connections():
   action_buttons[key].pressed.disconnect(connection.callable)
 action_buttons.attack.pressed.connect(func():_execute(controller.action))
 action_buttons.end.pressed.connect(func():
  if _commands_available():controller.end_player_turn())
 old_actions.queue_free()
 var utility=HFlowContainer.new();columns.add_child(utility);columns.move_child(utility,2)
 for action in ["guard","recover","wait"]:
  action_buttons[action]=_button(action.capitalize(),func():_execute(action));utility.add_child(action_buttons[action])
 carry_choice=OptionButton.new();carry_choice.custom_minimum_size=Vector2(170,32);carry_choice.clip_text=true;utility.add_child(carry_choice)
 carry_choice.item_selected.connect(func(index):controller.carry_slot=carry_choice.get_item_metadata(index);refresh())
 action_buttons["switch"]=_button("Switch",func():_execute("switch"));utility.add_child(action_buttons["switch"])
 var perks=HFlowContainer.new();columns.add_child(perks);columns.move_child(perks,3)
 for action in ["footwork","rotation","indomitable"]:
  action_buttons[action]=_button(action.capitalize(),func():_execute(action) if action=="indomitable" else _choose(action));perks.add_child(action_buttons[action])
 for key in ["attack","end","basic","special","guard","recover","wait","switch","footwork","rotation","indomitable"]:
  action_buttons[key].custom_minimum_size.y=30;action_buttons[key].add_theme_font_size_override("font_size",14)
 notice_label.add_theme_font_size_override("font_size",13)
 log_label.add_theme_font_size_override("font_size",12)
 for container in help_panel.get_children():
  for child in container.get_children():
   if child is Label:
    child.text="COMBAT FIELD GUIDE\n\nOnly the named active brother may act.\nClick a reachable hex to move. Choose Basic [1] / Special [2],\nthen click a legal enemy once to attack. Execute / Enter is optional.\nShieldwall [B], Recover [R], Wait [Space / Q], End [F].\nChoose a carried item, then Switch. Pack it in camp first.\nLearned Footwork / Rotation: select the action, click a hex / ally,\nthen Execute. Escape cancels targeting. Indomitable acts directly.\n\nCosts and hit odds come from Battle. Damage ranges are ON HIT;\nmisses, morale and reaction chains are not guaranteed.\nForest/walls/bodies use the existing blocking rules; no new scatter.\n\nEquipment [I] pauses for read-only inspection.\nWASD / arrows / middle drag pan; wheel zoom; Home close; O overview.\nWithdraw orders everyone to a passable exit edge under threat.\nRouted fighters stay targetable until dead or physically escaped."
func _commands_available() -> bool:
 return built and not help_open and not inspector_open() and not (is_instance_valid(retreat_confirm) and retreat_confirm.visible)
func _choose(action: String) -> void:
 if _commands_available():controller.choose_action(action)
func _execute(action: String) -> void:
 if _commands_available():controller.execute(action)
func _sync_action_activation() -> void:
 if not built or (battle.active_id==_mode_actor and battle.round_no==_mode_round):return
 _mode_actor=battle.active_id;_mode_round=battle.round_no
 controller.reset_action();controller.target=-1
 if battle.active_id>=0 and battle.units[battle.active_id].side==0:controller.selected=battle.active_id
func refresh() -> void:
 _sync_action_activation()
 super.refresh()
 if built and controller.action in ["footwork","rotation"] and battle.tiles.has(battle.key(controller.target_hex)):
  _hex_marker(controller.target_hex,Color(0.95,0.72,0.2,0.5),false)
func _update_hud() -> void:
 super._update_hud()
 if not is_instance_valid(carry_choice):return
 if kit_label:kit_label.text="%s · COMBAT · owned company"%session.deployed_map.get("title","")
 var id: int=controller.selected
 if id<0:return
 var u: Dictionary=battle.units[id]
 var active: bool=battle.can_act(id) and battle.side==0 and battle.fighting(u)
 unit_label.text="%s · %s\nHP %d/%d · AP %d · Initiative %d\nArmor %d · Head %d\nFatigue %d/%d · Morale %d\n%s"%[u.name,String(u.weapon).capitalize(),u.hp,u.max_hp,u.ap,battle.initiative_value(u),u.armor+u.padding,u.helmet,u.fatigue,battle.fatigue_max(u),u.morale,"Shieldwall" if u.guard else u.get("stance","")]
 carry_choice.clear()
 var selected_index=0
 for slot in battle.Arsenal.bag_slots(u):
  var item: Dictionary=u.arms.get(slot,{})
  var index=carry_choice.item_count
  carry_choice.add_item("%s: %s"%[slot,String(item.get("definition","empty")).capitalize()])
  carry_choice.set_item_metadata(index,slot)
  if slot==controller.carry_slot:selected_index=index
 carry_choice.select(selected_index)
 controller.carry_slot=carry_choice.get_item_metadata(selected_index)
 for action in ["guard","recover","wait","switch","indomitable"]:
  var q: Dictionary=battle.action_quote(id,action,-1,Vector2i(-1,-1),controller.carry_slot)
  action_buttons[action].text="%s · %d AP"%[q.name,q.ap] if q.ap>0 else q.name
  action_buttons[action].disabled=not active or not q.legal
  action_buttons[action].tooltip_text=q.reason if not q.legal else "%d AP / %d fatigue%s"%[q.ap,q.fatigue,"; ends this activation" if action=="recover" else ""]
 for action in ["basic","special","footwork","rotation"]:
  action_buttons[action].disabled=not active or (action in ["footwork","rotation"] and not action in u.perks)
  action_buttons[action].modulate=Color("eac783") if controller.action==action else Color.WHITE
  action_buttons[action].tooltip_text=("Choose this skill, then click a legal enemy once to attack. Execute / Enter is optional." if action=="basic" or (action=="special" and battle.special_info(u.weapon).target) else "Choose a target if needed, then Execute / Enter.") if not action_buttons[action].disabled else "Not available to this active brother."
 action_buttons.basic.text=battle.Arsenal.primary(u.weapon)+" [1]"
 action_buttons.special.text=battle.special_info(u.weapon).name+" [2]"
 _last_quote=controller.quote()
 action_buttons.attack.text="Execute %s"%_last_quote.name
 action_buttons.attack.disabled=not active or not _last_quote.legal
 target_label.text=_quote_text(_last_quote)
 var explanation: Array[String]=[target_label.text]
 for part in _last_quote.hit.get("parts",[]):explanation.append("%s %+d"%[part.name,part.value])
 if controller.action=="special":explanation.append(battle.special_info(u.weapon).text)
 action_buttons.attack.tooltip_text="\n".join(explanation)
 action_buttons.end.disabled=battle.side!=0 or battle.result!=""
func _quote_text(q: Dictionary) -> String:
 var text="%s · %d AP / %d fatigue"%[q.name,q.ap,q.fatigue]
 if not q.legal:return text+"\n"+q.reason
 if not q.hit.is_empty():
  text+="\nHit %d%%"%q.hit.chance
  if controller.selected>=0 and battle.units[controller.selected].weapon in battle.Arsenal.RANGED:text+=" · Ammo %d"%q.ammo
 if q.damage.get("kind")=="shield":text+=" · Shield −%d"%q.damage.shield
 elif q.damage.get("kind")=="hit":
  text+="\nOn hit: %d–%d HP · %d–%d armor\nBefore morale / reactions."%[q.damage.hp_min,q.damage.hp_max,q.damage.armor_min,q.damage.armor_max]
 return text
func _update_hover() -> void:
 super._update_hover()
 if built and controller.action in ["footwork","rotation"] and controller.selected>=0:
  var q: Dictionary=battle.action_quote(controller.selected,controller.action,-1,hover)
  notice_label.text="Click to target · "+(_quote_text(q) if q.legal else q.reason)
func _input(event: InputEvent) -> void:
 # Own the complete turn-key gesture before GUI ui_accept/focused buttons.
 if event is InputEventKey and event.physical_keycode in [KEY_SPACE,KEY_F] and _commands_available():
  if event.pressed and not event.echo and not (event.ctrl_pressed or event.alt_pressed or event.shift_pressed or event.meta_pressed):
   if event.physical_keycode==KEY_SPACE:_execute("wait")
   else:controller.end_player_turn()
  get_viewport().set_input_as_handled();return
 super._input(event)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.physical_keycode in [KEY_1,KEY_2,KEY_B,KEY_R,KEY_Q,KEY_ENTER,KEY_KP_ENTER] and (event.ctrl_pressed or event.alt_pressed or event.shift_pressed or event.meta_pressed):
  get_viewport().set_input_as_handled();return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and _commands_available():
  var id: int=pick_unit(event.position)
  if id>=0 and battle.units[id].side!=0:
   # World targeting commits attacks only; initiative portraits remain inspection.
   # select_target owns sight admission and execute revalidates the live quote.
   if controller.select_target(id) and controller.action in ["basic","special"]:
    var q: Dictionary=controller.quote()
    if q.target_kind=="enemy" and q.legal:_execute(controller.action)
   get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo and _commands_available():
  match event.physical_keycode:
   KEY_1:_choose("basic");return
   KEY_2:_choose("special");return
   KEY_B:_execute("guard");return
   KEY_R:_execute("recover");return
   KEY_Q:_execute("wait");return
   KEY_ESCAPE:
    if controller.action!="basic":controller.choose_action("basic");return
 super._unhandled_input(event)
func observation() -> Dictionary:
 var out=super.observation()
 out["combat_pass"]=true;out["action"]=controller.action;out["action_quote"]=_last_quote.duplicate(true)
 out["action_controls"]={}
 for key in action_buttons:
  var button: Button=action_buttons[key]
  var rect=button.get_global_rect()
  out.action_controls[key]={"text":button.text,"disabled":button.disabled,"visible":button.is_visible_in_tree(),"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}
 return out
