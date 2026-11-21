extends RefCounted
## Read-only projection of the saved birth roll. Never samples or applies stats.
const Rarity = preload("res://hollow_campaign/rarity.gd")
const People = preload("res://src/people.gd")
const Companions = preload("res://character_sheet/companions.gd")

# Resolve the actual creation profile, never the companion's mutable name or
# current equipment/class. Unknown or incompatible provenance stays unknown.
static func starting_profile(person: Dictionary) -> Dictionary:
 var background: Variant = person.get("background","")
 if not background is String:return {}
 if person.has("companion_role"):
  var role: Variant = person.companion_role
  if not role is String or not Companions.PROFILES.has(role):return {}
  var profile: Dictionary = Companions.PROFILES[role]
  return {"name":profile.name,"ranges":profile.ranges} if background == profile.name else {}
 if People.START_RANGES.has(background):return {"name":background,"ranges":People.START_RANGES[background]}
 return {}

static func describe(person: Dictionary) -> Dictionary:
 var roll: Variant = person.get("companion_roll")
 if not Rarity.valid_person(roll):return {}
 # Rarity also supports arbitrary supplied bases; this view only knows the
 # canonical person attributes. Never guess a missing/foreign stat or owner.
 if roll.bases.size() != People.ATTRS.size():return {}
 for attr: String in People.ATTRS:
  if not roll.bases.has(attr):return {}
 if person.has("person_seed") and (not person.person_seed is int or person.person_seed != roll.person_id):return {}
 var rows: Array = []
 var possible_ranges: Array = []
 var profile: Dictionary = starting_profile(person)
 var ceiling: int = Rarity.PERSON_CEILINGS[roll.tier]
 var above_count := 0
 var common: int = Rarity.PERSON_CEILINGS.common
 for attr: String in People.ATTRS:
  var base: int = roll.bases[attr];var rolled: int = roll.values[attr]
  var gain: int = rolled-base
  var comparison := "Common max %d · " % (base+common)
  if gain > common:
   above_count += 1;comparison += "+%d above Common" % (gain-common)
  else:comparison += "within Common range"
  rows.append([People.LABELS[attr],"%d → %d" % [base,rolled],"+%d" % gain,comparison])
  var possible := "Range unavailable"
  if not profile.is_empty():
   var bounds: Array = profile.ranges[People.ATTRS.find(attr)]
   if base >= bounds[0] and base <= bounds[1]:possible = "Possible %d–%d" % [bounds[0],bounds[1]+ceiling]
  possible_ranges.append(possible)
 return {"tier":roll.tier,"rows":rows,"above_count":above_count,"possible_ranges":possible_ranges,"range_background":profile.get("name","Range source unavailable"),"bonus_ceiling":ceiling}
