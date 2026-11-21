extends "res://hollow_campaign/dungeon_session.gd"
func _new_campaign():
 return preload("res://hollow_campaign/campaign.gd").new()
func rename_person(sid: int, value: String) -> bool:
 return _success() if campaign.rename_person(sid,value) else false
func preview_unit(sid: int) -> Dictionary:
 var unit: Dictionary = super.preview_unit(sid)
 if not unit.is_empty(): campaign.configure_player_unit(campaign.soldiers[sid],unit)
 return unit
func equip(sid: int, uid: String, slot: String) -> bool:
 return _success() if campaign.equip(sid,uid,slot) else _fail("Physical fitting refused; unchanged.")
func unequip(sid: int, slot: String) -> bool:
 return _success() if campaign.unequip(sid,slot) else _fail("Physical removal refused; unchanged.")
func move_equipment(sid: int, uid: String, source: String, target: String) -> bool:
 var reason: String = campaign.equipment_move_reason(sid,uid,source,target)
 if not reason.is_empty(): return _fail(reason)
 return _success() if campaign.move_equipment(sid,uid,source,target) else _fail("Physical move refused; unchanged.")
func slot_rows(sid: int) -> Array:
 if sid < 0 or sid >= campaign.soldiers.size(): return []
 var out := []
 for slot in campaign.VISIBLE_SLOTS:
  var uid: String = campaign.slot_uid(campaign.soldiers[sid],slot)
  var item: Dictionary = campaign.items.get(uid,{})
  var d: Dictionary = campaign.item_def(uid)
  out.append({"key":slot,"label":slot.capitalize(),"item_id":uid,"definition":item.get("definition",""),"name":d.get("name","Empty"),"condition":item.get("condition",0),"maximum":int(d.get("durability",0))})
 return out
func available_items(sid: int, slot: String) -> Array:
 if sid < 0 or sid >= campaign.soldiers.size(): return []
 var out := []
 for uid in campaign.items:
  if campaign.owner(uid) < 0 and campaign.parent_kit(uid).is_empty() and campaign.slot_allowed(campaign.items[uid].definition,slot): out.append(uid)
 return out

