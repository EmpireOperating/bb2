extends PanelContainer
## One read-only hover card. The field owns picking, sight and placement.
const Named = preload("res://src/named_equipment.gd")
const Arsenal = preload("res://src/arsenal.gd")
const Scars = preload("res://src/progression.gd")
const CardSkin = preload("res://iron_oath/skin.gd")
const BODY := Color("d7b97b")
const HEAD := Color("b5d4e5")
const HP := Color("f18b80")
var _title: Label
var _vitals: Array[Label] = []
var _stats: Label
var _gear: Label
var _effects: Label
var _stamp: Array = []

func _ready() -> void:
 name="CombatUnitHover"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 z_index=99 # Forecast remains a separate, higher-priority cue.
 custom_minimum_size.x=322
 add_theme_stylebox_override("panel",CardSkin.panel(10))
 var stack:=VBoxContainer.new()
 stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
 stack.add_theme_constant_override("separation",5)
 add_child(stack)
 _title=_label(stack,18,Color("f4dfad"))
 _title.add_theme_font_override("font",preload("res://assets/serif.ttf"))
 var vitals:=HBoxContainer.new()
 vitals.mouse_filter=Control.MOUSE_FILTER_IGNORE
 vitals.add_theme_constant_override("separation",5)
 stack.add_child(vitals)
 for color in [HEAD,BODY,HP]:
  var label:=_label(vitals,14,color)
  label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  _vitals.append(label)
 _stats=_label(stack,13,Color("ebdfcc"))
 _gear=_label(stack,14,Color("f5ebd8"))
 _effects=_label(stack,14,Color("f0ce91"))
 hide()

func _label(parent:Container, pixels:int, color:Color) -> Label:
 var label:=Label.new()
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 # Hidden containers have not sorted their children. Seed the real wrapping
 # width before assigning copy so the first placement can measure its height.
 label.custom_minimum_size.x=96 if parent is HBoxContainer else 302
 label.size.x=label.custom_minimum_size.x
 label.add_theme_font_size_override("font_size",pixels)
 label.add_theme_color_override("font_color",color)
 parent.add_child(label)
 return label

func clear_card() -> void:
 if _stamp.is_empty():return
 hide();_stamp.clear()
 for label in [_title,_stats,_gear,_effects]+_vitals:label.text=""

func present(battle, u:Dictionary, soldier:Dictionary) -> void:
 var stamp:=[hash(u),battle.active_id,battle.result,int(soldier.get("wound_days",0))]
 if stamp==_stamp:return
 _stamp=stamp
 var role:="Ally" if u.side==0 else "Enemy"
 if u.id==battle.active_id and battle.result.is_empty():role+=" · Acting"
 _title.text="%s  ·  %s"%[u.name,role]
 _vitals[0].text="Head %d/%d"%[u.helmet,u.max_helmet]
 _vitals[1].text="Body %d/%d"%[u.armor+u.padding,u.max_armor+u.max_padding]
 _vitals[2].text="HP %d/%d"%[u.hp,u.max_hp]
 _stats.text="AP %d/%d  ·  Fatigue %d/%d  ·  Init %d"%[u.ap,battle.MAX_AP,u.fatigue,battle.fatigue_max(u),battle.initiative_value(u)]
 _gear.text=_gear_copy(battle,u)
 _effects.text=_effect_copy(battle,u,soldier)
 reset_size()

static func _item_name(item:Dictionary, catalog:Dictionary, fallback:String) -> String:
 return str(Named.definition(item,catalog).get("name",fallback))

static func _gear_copy(battle,u:Dictionary) -> String:
 var catalog:Dictionary=battle.armor_catalog
 var arms:Dictionary=u.get("arms",{})
 var weapon:Dictionary=arms.get("weapon",{})
 var family:=Arsenal.family(u.weapon)
 var lines:=PackedStringArray()
 var main:Dictionary=battle.weapon_stats(u)
 var hand:="Weapon: "+_item_name(weapon,catalog,main.name)
 if main.reach>0:
  var reach:int=battle.weapon_reach(u)
  var minimum:int=main.get("min_range",1)
  hand+=" · %s hex%s"%[str(reach) if minimum==reach else "%d–%d"%[minimum,reach],"" if reach==1 else "es"]
 if family=="crossbow":hand+=" · "+("Loaded" if weapon.get("loaded",false) else "Unloaded")
 lines.append(hand)
 if u.weapon in Arsenal.RANGED:
  var count:int=battle.ammo_count(u)
  if family=="throwing":lines.append("%d throws left"%count)
  else:lines.append("%s: %d"%[_item_name(arms.get("ammo",{}),catalog,"Bolts" if family=="crossbow" else "Arrows"),count])
 var shield:Dictionary=arms.get("shield",{})
 if not shield.is_empty():
  var cap:int=shield.get("maximum",Named.definition(shield,catalog).get("durability",0))
  var condition:int=shield.get("condition",0)
  lines.append("Shield: %s %d/%d%s"%[_item_name(shield,catalog,"Shield"),condition,cap," (broken)" if condition<=0 else ""])
 # Show the main protective piece plus the count of other worn layers, not
 # an inventory dump. The numerators above already include every layer.
 for group in ["head","body"]:
  var primary:Dictionary={}
  var count:=0
  for part:Dictionary in u.get("armor_parts",[]):
   if part.get("group","")!=group or int(part.get("maximum",0))<=0:continue
   count+=1
   if int(part.maximum)>int(primary.get("maximum",0)):primary=part
  if count>0:
   lines.append("%s: %s%s"%["Helmet" if group=="head" else "Armour",_item_name(primary,catalog,"Worn layer")," +%d layer%s"%[count-1,"" if count==2 else "s"] if count>1 else ""])
 return "\n".join(lines)

static func _effect_copy(battle,u:Dictionary,soldier:Dictionary) -> String:
 var lines:=PackedStringArray()
 var mood:="Morale: "+String(battle.morale_name(u)).capitalize()
 if u.morale_state!=0 and battle.core_rules:mood+=" · %+d%% attack/defence"%(10*int(u.morale_state))
 if u.routed:mood+=" · Cannot fight; seeks escape"
 lines.append(mood)
 if u.guard and u.shield:
  lines.append("Shieldwall: +%d melee / +%d ranged defence from guard."%[battle.shield_defence(u,false),battle.shield_defence(u,true)])
 if battle.spearwall_active(u):lines.append("Spearwall: strikes foes entering control; hits can repel.")
 if u.stance=="riposte" and u.reactions>0:
  lines.append("Riposte: %d counter%s left on adjacent melee misses."%[u.reactions,"" if u.reactions==1 else "s"])
 if u.stagger>0:lines.append("Staggered: −2 AP applied; −2 AP next activation.")
 for status in ["stunned","dying","sleeping","entangled","horrified"]:
  if u.get(status,false):lines.append(String(status).capitalize()+": no melee control or opportunity attacks.")
 var state:Dictionary=battle.vital_state(u)
 if battle.perk_rules:
  if state.indomitable:lines.append("Indomitable: half weapon damage taken; resists forced movement and stagger.")
  if state.overwhelm>0:lines.append("Overwhelmed: −%d%% melee/ranged skill until activation ends."%(10*state.overwhelm))
  if state.frenzy_end>0:lines.append("Killing Frenzy: +20% weapon damage.")
  if state.reach>0:lines.append("Reach Advantage: +%d melee defence."%state.reach)
  if state.adaptation>0:lines.append("Fast Adaptation: +%d accuracy until a paid hit."%state.adaptation)
 if battle.impact_active(u):lines.append("Weakened: −10 accuracy / −20% damage.")
 var days:int=soldier.get("wound_days",0)
 if days>0:lines.append("Deep wound (%dd): −12 base max HP, −10 melee/ranged skill."%days)
 for scar:String in u.get("scars",[]):
  var info:Dictionary=Scars.SCARS.get(scar,{})
  if not info.is_empty():lines.append("%s: %s"%[info.name,info.effect.get_slice(" Earlier saved",0)])
 return "\n".join(lines)
