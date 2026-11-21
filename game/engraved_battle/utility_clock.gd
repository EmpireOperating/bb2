extends RefCounted
## Visual time only. Brace is just its entry beat; Battle owns the held pose.
const HOLD := ["riposte","guard","indomitable"]
const LENGTH := {"brace":0.096,"riposte":0.26,"guard":0.28,"indomitable":0.33,"recover":0.62,"switch":0.39}
var kind: String = ""
var slot: String = ""
var uid: String = ""
var elapsed: float = 0.0

func begin(event:Dictionary) -> void:
 kind=event.kind;slot=event.slot;uid=event.uid;elapsed=0.0

func clear() -> void:
 kind="";slot="";uid="";elapsed=0.0

func matches(unit:Dictionary) -> bool:
 if kind.is_empty() or int(unit.get("hp",0))<=0 or unit.get("routed",false) or unit.get("escaped",false):return false
 var item:Dictionary=unit.get("arms",{}).get(slot,{})
 if str(item.get("id",""))!=uid:return false
 match kind:
  "riposte":return unit.get("stance","")==kind and int(unit.get("reactions",0))>0
  "guard":return unit.get("guard",false) and (uid.is_empty() or int(item.get("condition",0))>0)
  "indomitable":return unit.get("perk_state",{}).get("indomitable",false)==true
  _:return elapsed<float(LENGTH.get(kind,0.0))

func sample(unit:Dictionary, visible:bool, delta:float=0.0) -> bool:
 if kind.is_empty():return false
 if is_finite(delta):elapsed=minf(float(LENGTH[kind]),elapsed+maxf(0.0,delta))
 if not visible or not matches(unit):clear()
 return true

func progress() -> float:
 return clampf(elapsed/maxf(.01,float(LENGTH.get(kind,1.0))),0.0,1.0)
