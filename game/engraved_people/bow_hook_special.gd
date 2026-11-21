extends RefCounted
## Paid strike presentation only. No costs, rolls, world movement or sound here.
const AIMED := "aimed_shot"
const SIGHT_ROW := 3
const AIMED_BEATS := ["gather","set","draw","sight","release","recover","lower","carry"]
const FERRY := "ferryman_hook"
const FERRY_DEF := "hm_trial_v1:old24-ferryman_hook"
const FERRY_PART := "weapon/t1-ferrymans-hook"
# Stay on the inherited Ferryman contact and the existing forced-slide clock.
const FERRY_CONTACT := 0.242
const FERRY_ENDS := [0.058,0.141,FERRY_CONTACT,0.317,0.391,0.462,0.528,0.587,0.618]
const FERRY_BEATS := ["gather","scoop","reach","catch","pull","haul","clear","lower","carry"]

static func ferry_frame(t:float) -> int:
 for i in FERRY_ENDS.size():
  if t<float(FERRY_ENDS[i]):return i
 return -1

static func aimed_frame(t:float, parent_ends:Array) -> int:
 var early:Array = [0.050,0.112,0.198] if parent_ends[3]<0.4 else [0.055,0.125,0.219]
 for i in parent_ends.size():
  if t<float(early[i] if i<SIGHT_ROW else parent_ends[i]):return i
 return -1

static func matches(style:String,layer:Dictionary,live:Dictionary,uid:String) -> bool:
 if uid.is_empty() or not layer.get("visible",false) or layer.get("item","")!=uid or live.get("id","")!=uid:return false
 var definition:String=live.get("definition","")
 return layer.get("definition","none")==definition and (style==AIMED or (style==FERRY and definition==FERRY_DEF))
