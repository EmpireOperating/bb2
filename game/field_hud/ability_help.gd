extends RefCounted
## Explanations of current Layer Forge rules. Numbers that vary by fighter,
## target or kit come from the same read-only Battle queries as the controls.
const Arsenal = preload("res://src/arsenal.gd")
const Perks = preload("res://src/perks.gd")
const CrossbowHud = preload("res://crossbows/ui.gd")
const ACTIONS := ["basic","special","guard","recover","wait","shield_bash","footwork","rotation","indomitable","rally_the_troops","end","reserves"]

static func copy(field, action:String) -> String:
 var battle=field.battle
 var id:int=battle.active_id if action=="end" else field.controller.selected
 var title:String=field.action_buttons[action].text.split("\n")[0].split(" · ")[0]
 if action=="reserves":
  return "Pockets\nSwitch to a carried item on the active fighter’s turn.\nEach pocket shows its own AP and fatigue cost.\n"+("No switch is available; fill pockets in camp." if field.action_buttons.reserves.disabled else "Select a pocket to see its item and restrictions.")
 if id<0 or id>=battle.units.size() or battle.units[id].side!=0:
  return title+"\nSelect an active company fighter."
 var u:Dictionary=battle.units[id]
 var q:Dictionary=battle.action_quote(id,action)
 var reason:String=q.reason
 var detail:=""
 match action:
  "basic","special":
   var special:=action=="special"
   var targeted:bool=q.target_kind=="enemy"
   var target:int=field.controller.target
   if targeted and battle.unit_visible(0,target):
    var aimed:Dictionary=battle.action_quote(id,action,target)
    if aimed.legal and not aimed.hit.is_empty():q=aimed
    elif reason=="Choose a living enemy.":reason=field.controller.public_quote(aimed).reason
   detail=_weapon_copy(battle,u,special)
   var family:=Arsenal.family(u.weapon)
   # The no-target quote asks for an enemy before inspecting ammunition.
   # These are the active fighter's own resources, never a hidden target query.
   if targeted and not u.weapon.is_empty() and u.weapon in Arsenal.RANGED:
    if reason=="Choose a living enemy." or reason=="No legal attack from this position.":
     if battle.ammo_count(u)<=0:reason="No matching ammunition."
     elif family=="crossbow" and not u.arms.weapon.get("loaded",false):reason="Crossbow needs reloading."
    if family=="crossbow":detail+="\n"+CrossbowHud.readiness(u.arms.weapon,u.arms.ammo,battle.armor_catalog).replace("\n"," · ")
    else:detail+="\nAmmunition remaining: %d."%battle.ammo_count(u)
   if special and family=="crossbow":detail+="\n"+CrossbowHud.readiness(u.arms.weapon,u.arms.ammo,battle.armor_catalog).replace("\n"," · ")
   if targeted and reason=="Choose a living enemy.":reason=""
   if targeted:detail+="\nChoose the skill, then click a legal enemy once."
   elif special and family=="crossbow":detail+="\nClick Reload or press [2]; no target needed."
   elif not u.weapon.is_empty():detail+="\nChoose the stance, then Execute."
  "guard":
   title="Shieldwall [B]"
   detail="Adds your shield’s defence bonus a second time. Each adjacent active wall can add +5 defence, up to +20. Requires a working shield."
   if u.shield:detail+="\nYour extra shield defence: +%d melee / +%d ranged."%[battle.shield_defence(u,false),battle.shield_defence(u,true)]
  "recover":
   var deep:bool=battle.perk_rules and (Perks.has(u,"deep_breath") or Perks.has(u,"endurance"))
   detail="Removes %d%% of accumulated fatigue (remaining fatigue rounds down) and ends this activation. Requires 9 AP."%(65 if deep else 50)
  "wait":
   title="Wait [Space / Q]"
   detail="Defer this activation without recovering. Keeps your remaining AP and fatigue. Once per round; another activation must remain."
  "shield_bash":
   title="Bash · Knock Back"
   var accuracy:=40 if battle.perk_rules and Perks.has(u,"shield_expert") else 25
   detail="Against an adjacent enemy: +%d action accuracy. On hit, push one hex, break their stance and add 10 fatigue. No HP or armour damage. Needs a working shield and a visible, passable landing."%accuracy
   if q.ready:reason=""
  "footwork","rotation":
   var cell:Vector2i=field.controller.target_hex
   if field.controller.action==action and battle.tile_visible(0,cell):q=battle.action_quote(id,action,-1,cell)
   reason=q.reason
   if cell==Vector2i(-1,-1) or field.controller.action!=action:
    if reason in ["Destination is not currently visible.","Choose an adjacent passable hex."]:reason=""
   detail="Step to an adjacent visible, empty, passable hex without opportunity attacks. Clears your stance. Choose a hex, then Execute." if action=="footwork" else "Swap with a standing ally on an adjacent visible, passable hex without opportunity attacks. Both lose their stances; the ally pays nothing. Choose an ally, then Execute."
  "indomitable":
   detail="Until your next first activation, take half direct weapon HP and armour damage. Resists hostile pushes, pulls and stagger; voluntary movement and allied Rotation still work."
  "rally_the_troops":
   detail="Other allies within 4 hexes roll Resolve with 40% of yours. Non-fleeing allies lose 10 chance per hex. Raises morale to at most Steady, or Fleeing to Wavering. Once per activation."
  "end": detail="Finish this activation and give up remaining AP. Unlike Wait, you do not return to this round’s queue."
 var cost:="%d AP / %d fatigue"%[q.ap,q.fatigue]
 if action=="end":cost="Spends all remaining AP"
 return "%s\n%s\n%s%s"%[title,cost,("Cannot use now: "+reason+"\n") if not reason.is_empty() else "",detail]

static func _weapon_copy(battle,u:Dictionary,special:bool) -> String:
 var w:Dictionary=battle.weapon_stats(u)
 var family:=Arsenal.family(u.weapon)
 if family.is_empty():return "Equip a weapon to attack."
 var gap:int=battle.weapon_reach(u,special)
 var minimum:int=w.get("min_range",1)
 var reach:="Reach: %d hex%s."%[gap,"" if gap==1 else "es"] if gap==minimum else "Reach: %d–%d hexes."%[minimum,gap]
 if not special:
  var text:="%d–%d weapon damage before mitigation. %+d weapon accuracy, %d%% armour damage, %d%% penetration. %s"%[w.min,w.max,w.skill,roundi(float(w.armor)*100),roundi(float(w.pierce)*100),reach]
  if u.weapon in Arsenal.RANGED:
   var penalty:=3 if family=="crossbow" else 2 if family=="throwing" else 4
   var ammo:String={"crossbow":"bolt and leaves the crossbow unloaded","throwing":"throw from the held bundle","bow":"arrow"}.get(family,"round")
   text+="\nUses one %s. −%d accuracy per hex after the first. Needs a clear shot%s."%[ammo,penalty,"" if family=="throwing" and not battle.terrain_rules_enabled else " and cannot fire while engaged"]
  elif gap==2:
   text+="\nAt distance two, needs an open or allied lane."
   var mastery:="spear_mastery" if family=="spear" else "polearm_mastery"
   if battle.perk_rules and family in ["spear","polearm"] and not Perks.has(u,mastery):text+=" −15 accuracy at one hex."
  return text
 match family:
  "dagger":return "−20 accuracy. Body-only hit deals 80% of weapon damage directly to HP without wearing armour or padding. "+reach
  "mace":
   if battle.mace_stun_rules:return str(battle.special_info(u.weapon).text)+" "+reach
   return "−10 accuracy; 75% damage. A hit applies −2 AP now and −2 AP next activation. Does not stack; Indomitable resists. "+reach
  "hammer":return "−5 accuracy. Body-only hit: double armour wear, half HP damage. "+reach
  "axe":
   var loss:int=battle.split_shield_damage(u)
   return "Automatically hits an adjacent working shield for %d condition (%d vs Shield Expert). No HP or body armour damage."%[loss,battle.split_shield_damage(u,{"perks":["shield_expert"]})]
  "bow":return "+1 hex of range, +10 accuracy; −2 per hex after the first. +10% regular damage without extra armour wear. Uses one arrow. Cannot shoot while engaged. "+reach
  "crossbow":return "Readies this physical crossbow, without consuming a bolt. Needs an unloaded crossbow, matching bolts and no adjacent enemy."
  "throwing":return "−5 accuracy; +20%% armour damage. Uses one throw from the held bundle; shields are allowed. %s %s"%["Cannot throw while engaged." if battle.terrain_rules_enabled else "Can throw while engaged.",reach]
  "polearm":return "At exactly two hexes: −10 accuracy; 65% damage. On hit, pull the target one hex into a free, passable hex. Indomitable resists the pull."
  "sword":return "With a one-handed sword, counter up to two missed adjacent melee attacks. Each counter costs %d fatigue. Ends on movement, attack, switch or next activation."%battle.reaction_cost(u)
  "spear":
   var bonus:=" Spearwaller adds +20% damage before the half-damage multiplier." if battle.perk_rules and Perks.has(u,"spearwaller") else ""
   return "Strike enemies entering your control at half damage; hits can repel. A breach ends the wall unless mastered. Requires no engagement unless you have Spear Mastery. Ends on your next activation."+bonus
 return str(battle.special_info(u.weapon).text)

static func wrap(text:String,font:Font,pixels:int) -> String:
 # Godot's stock TooltipLabel does not wrap itself. Keep the native hover
 # (including disabled controls) and constrain its width without a new input node.
 var rows:=PackedStringArray()
 for line in text.split("\n"):
  var row:=""
  for word in line.split(" ",false):
   var next:=word if row.is_empty() else row+" "+word
   if not row.is_empty() and font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x>346.0:
    rows.append(row);row=word
   else:row=next
  rows.append(row)
 return "\n".join(rows)
