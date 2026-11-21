extends RefCounted
## Reversible player-workflow policy only. Never changes physical armor or saves.
const LAYERED_ARMOR_PARKED := true
const ARMOR_REASON := "Layered armour editing is parked in this build. Use Equipment for ordinary body and head items. Existing assemblies are retained intact."
static func company_route_parked(id: String) -> bool:
 return LAYERED_ARMOR_PARKED and id == "armor"
static func editor_route_parked(id: String, gear_slot: String) -> bool:
 if not LAYERED_ARMOR_PARKED:return false
 return id in ["iron_armour","slot_body","slot_head"] or id.begins_with("arm_") or (gear_slot in ["body","head"] and (id.begins_with("equip_") or id == "unequip"))
static func assembly_sale_parked(campaign, id: String, mode: String, uid: String) -> bool:
 return LAYERED_ARMOR_PARKED and id == "salvage_apply" and mode == "sell" and campaign != null and campaign.item_def(uid).get("assembly",false)
