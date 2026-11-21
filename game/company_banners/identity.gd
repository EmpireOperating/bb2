extends RefCounted
## Stable identity vocabulary, independent of artwork provenance/manifests.
const IDS := ["ash_raven","gilded_stag","iron_wolf","ivory_sun","thorn_rose","silver_griffin"]
const TITLES := ["Ash Raven","Gilded Stag","Iron Wolf","Ivory Sun","Thorn Rose","Silver Griffin"]
const DEFAULT := {"name":"The Ashen Company","banner":"ash_raven"}
const MAX_NAME := 40
static func name_error(value: String) -> String:
 # Refuse controls before trimming: tabs/newlines must not become valid names.
 for i in value.length():
  var c := value.unicode_at(i)
  if c < 32 or (c >= 127 and c <= 159) or c in [0x200B,0x200E,0x200F,0x2028,0x2029,0xFEFF] or (c >= 0x202A and c <= 0x202E) or (c >= 0x2066 and c <= 0x2069):
   return "Use a name without control characters."
 var clean := value.strip_edges()
 if clean.is_empty():return "Give your company a name."
 if clean.length() > MAX_NAME:return "Use no more than %d characters." % MAX_NAME
 return ""
static func valid(raw: Variant) -> bool:
 return raw is Dictionary and raw.size()==2 and raw.get("name") is String and raw.get("banner") is String and name_error(raw.name).is_empty() and raw.name==raw.name.strip_edges() and raw.banner in IDS
static func path(id: String) -> String:
 return "res://engraved_world/standards/%s.png" % id if id in IDS else ""
