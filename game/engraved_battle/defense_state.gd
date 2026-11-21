extends RefCounted
## Priority is visual only. The real guard/perk state controls the whole hold.
static func kind(unit:Dictionary) -> String:
 if int(unit.get("hp",0))<=0 or unit.get("escaped",false) or unit.get("routed",false):return ""
 var shield:Dictionary=unit.get("arms",{}).get("shield",{})
 if unit.get("guard",false) and not str(shield.get("id","")).is_empty() and int(shield.get("condition",0))>0:return "guard"
 if unit.get("perk_state",{}).get("indomitable",false)==true:return "indomitable"
 return ""

static func paint_kind(active:String,spearwall:bool) -> String:
 if not spearwall:return active
 # Do not hide the existing forward-spear warning behind Indomitable.
 if active=="indomitable":return ""
 return "guard_spear" if active=="guard" else active
