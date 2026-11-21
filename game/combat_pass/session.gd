extends "res://terrain_pass/session.gd"
## Existing company, maps, equipment and checkpoint envelope; successor origin only.
const COMBAT_USER_DIR = "ashen-company-combat-completion"
func gear_slots(sid: int) -> Array:
 var rows=super.gear_slots(sid)
 var person=_person(sid)
 if person.is_empty():return rows
 for slot in Arsenal.bag_slots(person):
  var row=_item_row(_slot_item(person,slot))
  row["key"]=slot;row["label"]="Carried "+slot.trim_prefix("carry");rows.append(row)
 return rows
func available_items(sid: int,slot: String) -> Array:
 if not slot in Arsenal.CARRIED:return super.available_items(sid,slot)
 var person=_person(sid)
 if person.is_empty() or not person.alive or campaign.phase!="camp" or campaign.over() or not slot in Arsenal.bag_slots(person):return []
 var rows=[]
 for id in campaign.stash(slot):
  if campaign.items[id].definition in SUPPORTED and Arsenal.allowed(slot,campaign.items[id].definition,campaign.catalog):rows.append(_item_row(id))
 return rows
func equip(sid: int,item_id: String,slot: String) -> bool:
 if not slot in Arsenal.CARRIED:return super.equip(sid,item_id,slot)
 if not available_items(sid,slot).any(func(row):return row.item_id==item_id):return _fail("Carried item is unavailable or incompatible.")
 return _success() if campaign.equip(sid,item_id,slot) else _fail("Campaign refused carried equipment.")
func unequip(sid: int,slot: String) -> bool:
 if not slot in Arsenal.CARRIED:return super.unequip(sid,slot)
 return _success() if campaign.unequip(sid,slot) else _fail("Campaign refused carried removal.")
func _checkpoint_path(path: String) -> String:
 if not ProjectSettings.get_setting("application/config/use_custom_user_dir",false) or ProjectSettings.get_setting("application/config/custom_user_dir_name","")!=COMBAT_USER_DIR or OS.get_user_data_dir().get_file()!=COMBAT_USER_DIR:
  _fail("Checkpoint requires the isolated Combat Completion user directory.");return ""
 var pattern=RegEx.new();pattern.compile("^user://[A-Za-z0-9][A-Za-z0-9_-]{0,63}\\.json$")
 var matched=pattern.search(path)
 if matched==null or matched.get_string()!=path:
  _fail("Use a simple user://name.json checkpoint.");return ""
 var directory=DirAccess.open(OS.get_user_data_dir())
 if directory==null or directory.is_link(path.get_file()) or directory.dir_exists(path.get_file()):
  _fail("Checkpoint directory unavailable or target is a link/directory.");return ""
 return ProjectSettings.globalize_path(path)
