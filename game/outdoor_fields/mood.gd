extends RefCounted
## Campaign mood is independent of the tactical morale state and both RNG streams.
const MINIMUM := 0
const NEUTRAL := 315
const MAXIMUM := 700
const SOUR := 230
const INTERVAL := 240 # Campaign minutes.
const DRIFT := 2
const ALE := 100
const VICTORY := 35
const DEFEAT := -45
const RETREAT := -25
const REASONS := {"ale":"Tavern ale", "win":"Battle won", "defeat":"Battle lost", "retreat":"Company withdrew"}

static func value_at(row: Dictionary, minute: int) -> int:
 if row.is_empty():return NEUTRAL
 @warning_ignore("integer_division")
 var elapsed := maxi(0,minute-int(row.minute))/INTERVAL
 var value: int = row.value
 var drift := elapsed*DRIFT
 return maxi(NEUTRAL,value-drift) if value>NEUTRAL else mini(NEUTRAL,value+drift)

static func confidence(value: int) -> int:
 if value>=600:return 75
 if value>=500:return 50
 return 25 if value>=400 else 0

static func describe(row: Dictionary, minute: int) -> Dictionary:
 var value := value_at(row,minute)
 var odds := confidence(value)
 var label := "Happy" if odds>0 else "Demoralized" if value<=SOUR else "Neutral"
 var reason: String = "" if value==NEUTRAL else REASONS[row.reason]
 return {"value":value,"label":label,"confidence":odds,"reason":reason,
  "text":"Mood: "+label+ (" · "+reason if not reason.is_empty() else "")}

static func valid(raw: Dictionary) -> bool:
 var state = raw.campaign_mood
 if not state is Dictionary or state.size()!=2 or not state.get("version") is int or state.version!=1 or not state.get("people") is Dictionary:return false
 var people: Dictionary = state.people
 if people.is_empty() or people.size()>20 or not raw.get("soldiers") is Array or not raw.get("day") is int or raw.day<1 or raw.day>6405119470038038 or not raw.get("overworld") is Dictionary:return false
 var hour = raw.overworld.get("hour")
 if not (hour is float or hour is int) or not is_finite(float(hour)) or hour<0 or hour>=24:return false
 var now: int = (raw.day-1)*1440+roundi(hour*60)
 for key: Variant in people:
  if not key is String or not key.is_valid_int():return false
  var id: int = key.to_int()
  if key!=str(id) or id<0 or id>=raw.soldiers.size():return false
  var person = raw.soldiers[id]
  if not person is Dictionary or not person.get("id") is int or person.id!=id or not person.get("alive") is bool or not person.alive:return false
  var row = people[key]
  if not row is Dictionary or row.size()!=3 or not row.get("value") is int or row.value<MINIMUM or row.value>MAXIMUM or row.value==NEUTRAL:return false
  if not row.get("minute") is int or row.minute<0 or row.minute>now:return false
  if not row.get("reason") is String or not REASONS.has(row.reason):return false
 return true
