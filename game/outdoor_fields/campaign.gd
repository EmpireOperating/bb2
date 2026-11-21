extends "res://single_body/campaign.gd"
# No in-battle serialization. Absent on earlier CAMP saves (including pending
# encounters): retain that company's exact legacy geometry and checkpoint binding.
var local_fields := true
func random_company_enabled() -> bool:
 return true
func create_dungeons(definitions: Dictionary):
 var out = super.create_dungeons(definitions)
 out.intrinsic_undead_enabled = true
 return out
func snapshot() -> Dictionary:
 var data:Dictionary=super.snapshot()
 if local_fields:data["outdoor_fields"]=1
 return data
func restore(raw:Variant) -> bool:
 if not raw is Dictionary:return false
 if raw.has("outdoor_fields") and (not raw.outdoor_fields is int or raw.outdoor_fields!=1):return false
 if not super.restore(raw):return false
 local_fields=raw.has("outdoor_fields")
 return true
