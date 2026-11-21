extends RefCounted
const Roster = preload("res://src/company_roster.gd")
var opened = false
var selected = -1
var pressed = ""
var drag_id = -1
var origin = Vector2.ZERO
func draw(m) -> void:
 var c=m.campaign
 m.buttons.clear();m.draw_rect(Rect2(0,0,1440,900),Color("101815"))
 m.label_at("COMPANY FORMATION",Vector2(35,55),30,m.PAPER,true)
 m.label_at("%d / 20 company  ·  %d / 12 deployed  ·  %d reserves"%[c.alive_count(),c.active_ids().size(),c.reserve_ids().size()],Vector2(35,87),16,m.GOLD)
 m.button("lineup_save","F5 SAVE",Rect2(1095,32,130,44))
 m.button("lineup_close","CLOSE / ESC",Rect2(1240,32,165,44),true,true)
 m.label_at("ENEMY AHEAD ↑   ·   Drag companions between positions, or select one and click a destination.",Vector2(35,125),14,m.MUTED)
 for row in 2:
  m.label_at("FRONT LINE" if row==0 else "BACK LINE",Vector2(35,153+row*145),12,m.GOLD)
  for col in 9:
   var slot=row*9+col
   var rect=Rect2(35+col*153,164+row*145,143,118)
   card(m,"lineup_slot_%d"%slot,c.formation[slot],rect,"%d"%(col+1))
 m.label_at("RESERVES · recover normally; earn no combat XP",Vector2(35,470),15,m.BLUE)
 m.panel(Rect2(30,484,1380,226),Color("152019"))
 var reserves=c.reserve_ids()
 if reserves.is_empty():m.centered("Drop a companion here to keep them out of the next battle.",Vector2(720,600),16,m.MUTED)
 for i in reserves.size():card(m,"lineup_reserve_%d"%reserves[i],reserves[i],Rect2(40+(i%10)*136,494+(i/10)*105,126,96),"")
 var editable=Roster.editable(c)
 var status="Current formation deploys automatically. Use Save / F5 to checkpoint it."
 if not editable:status="Formation is locked while an encounter is pending. Resolve it before changing the lineup."
 elif c.active_ids().is_empty():status="Assign at least one companion to the field before you can fight."
 m.label_at(status,Vector2(35,744),14,m.MUTED if editable and not c.active_ids().is_empty() else m.RED)
 m.label_at("All %d companions cost %d crowns + %d rations per day."%[c.alive_count(),c.wage_cost(),c.alive_count()],Vector2(35,775),14,m.GOLD)
 if selected>=0:
  m.label_at("Selected: "+c.soldiers[selected].name,Vector2(35,832),21,m.PAPER,true)
  m.button("lineup_bench","MOVE TO RESERVES",Rect2(520,799,260,46),editable and selected in c.active_ids())
  m.button("lineup_inspect","EQUIPMENT & STATS",Rect2(795,799,270,46))
  m.button("lineup_clear","CLEAR SELECTION",Rect2(1080,799,325,46))
 if m.notice_time>0:m.centered(m.notice,Vector2(720,880),14,m.GOLD)
 if drag_id>=0 and origin.distance_to(m.get_global_mouse_position())>6:
  var p=m.get_global_mouse_position();m.panel(Rect2(p+Vector2(8,8),Vector2(150,34)),Color("283325"),m.GOLD)
  m.label_at(c.soldiers[drag_id].name, p+Vector2(18,31),16,m.PAPER)
func card(m,key:String,id:int,rect:Rect2,empty_label:String) -> void:
 m.panel(rect,Color("303927") if id==selected and id>=0 else Color("1a251d"),m.GOLD if id==selected and id>=0 else Color("48513b"))
 m.buttons[key]={"rect":rect,"enabled":true}
 if id<0:
  m.centered(empty_label+" · Empty",Vector2(rect.get_center().x,rect.position.y+60),14,m.MUTED);return
 var s=m.campaign.soldiers[id]
 m._draw_soldier(m.camp_portrait(s),rect.position+Vector2(29,37),0.67)
 m.label_at(s.name.left(12),rect.position+Vector2(9,rect.size.y-25),17,m.PAPER,true)
 m.label_at("%d / %d HP"%[s.hp,m.campaign.max_hp(s)],rect.position+Vector2(9,rect.size.y-8),11,m.BLUE if s.wound_days==0 else m.RED)
 m.label_at("Lv %d"%m.Progression.level(s),rect.position+Vector2(66,27),12,m.GOLD)
 m.label_at(m.campaign.item_def(s.gear.weapon).get("weapon","").left(10),rect.position+Vector2(66,46),10,m.MUTED)
func input(m,event:InputEvent) -> bool:
 if not opened:return false
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:action(m,"lineup_close")
  elif event.keycode==KEY_F5:m.action("save")
  elif event.keycode==KEY_F9:m.action("load")
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  var p=m.get_global_mouse_position()
  if event.pressed:
   pressed="";drag_id=-1;origin=p
   for key in m.buttons:
    if m.buttons[key].rect.has_point(p) and m.buttons[key].enabled:
     pressed=key
     if key.begins_with("lineup_slot_"):drag_id=m.campaign.formation[int(key.trim_prefix("lineup_slot_"))]
     elif key.begins_with("lineup_reserve_"):drag_id=int(key.trim_prefix("lineup_reserve_"))
     break
  else:
   if drag_id>=0 and origin.distance_to(p)>6:
    var changed=false
    for key in m.buttons:
     if key.begins_with("lineup_slot_") and m.buttons[key].rect.has_point(p):changed=Roster.place(m.campaign,drag_id,int(key.trim_prefix("lineup_slot_")));break
    if Rect2(30,484,1380,226).has_point(p):changed=Roster.reserve(m.campaign,drag_id)
    selected=drag_id;commit(m,changed)
   elif not pressed.is_empty() and m.buttons.has(pressed) and m.buttons[pressed].rect.has_point(p):action(m,pressed)
   pressed="";drag_id=-1
 m.queue_redraw();return true
func commit(m,changed:bool) -> void:
 if changed:m.write_save(false);m.tell("Formation updated · unsaved until Save / F5.")
 else:m.tell("Cannot move there: field limit is 12; formations lock during encounters.")
func action(m,key:String) -> bool:
 if not key.begins_with("lineup_"):return false
 var c=m.campaign
 if key=="lineup_open":
  if c.phase!="camp":return true
  var enabling:bool=c.roster_version==0
  if enabling and not Roster.enable(c):m.tell("Resolve this encounter before enabling company formation.");return true
  opened=true;selected=-1
  if enabling:m.write_save(false)
 elif key=="lineup_close":opened=false;drag_id=-1
 elif key=="lineup_save":m.action("save")
 elif key=="lineup_clear":selected=-1
 elif key=="lineup_inspect" and selected>=0:m.camp_selected=selected;m.roll_page=c.roll_ids().find(selected)/6;m.world_view=false;opened=false
 elif key=="lineup_bench" and selected>=0:commit(m,Roster.reserve(c,selected))
 elif key.begins_with("lineup_reserve_"):selected=int(key.trim_prefix("lineup_reserve_"))
 elif key.begins_with("lineup_slot_"):
  var slot=int(key.trim_prefix("lineup_slot_"))
  if selected<0:selected=c.formation[slot]
  elif c.formation[slot]==selected:selected=-1
  else:commit(m,Roster.place(c,selected,slot))
 return true
