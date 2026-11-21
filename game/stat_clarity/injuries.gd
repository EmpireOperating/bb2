extends RefCounted
const Progression = preload("res://src/progression.gd")
## Current injuries are the existing wound_days projection, never a new record.
static func describe(person: Dictionary) -> Dictionary:
 if person.is_empty():return {"active":false,"temporary":"","scars":[],"tooltip":"","summary":""}
 var living: bool = bool(person.get("alive",false))
 var wounded: bool = int(person.get("wound_days",0)) > 0
 var scars: Array[String] = []
 var lines: Array[String] = []
 if not living:lines.append("Fallen · historical injuries; no active recovery.")
 if wounded:
  lines.append("Deep wound · temporary injury\n-12 maximum health before Colossus; -10 melee skill; -10 ranged skill.")
  if living:
   lines.append("%d treatment stages remaining (saved injury days). Each stage requires 24 treatment hours and 1 medicine; sufficient company food is required for progress. Temple care doubles treatment progress. Full HP does not clear the injury." % int(person.wound_days))
 else:lines.append("No temporary injury.")
 for id: String in person.get("scars",[]):
  if not Progression.SCARS.has(id):continue
  var scar: Dictionary = Progression.SCARS[id]
  scars.append(scar.name);lines.append(scar.name+" · permanent scar\n"+scar.effect+" Permanent; medicine and temple care do not remove it.")
 if scars.is_empty():lines.append("No permanent scars.")
 return {"active":living and (wounded or not scars.is_empty()),"temporary":"Deep wound" if wounded else "No temporary injury","scars":scars,"tooltip":"\n\n".join(lines),"summary":("Deep wound" if wounded else "")+(" · " if wounded and not scars.is_empty() else "")+", ".join(scars)}
