extends "res://src/campaign.gd"
## Full current Campaign ancestry. Physical records remain the single authority.
const Rarity = preload("res://hollow_campaign/rarity.gd")
const Catalog = preload("res://hollow_campaign/catalog.gd")
const Effects = preload("res://hollow_campaign/equipment_effects.gd")
const Acquisition = preload("res://painted_merge/acquisition.gd")
const FoundingGear = preload("res://founding_gear/policy.gd")
const RandomKit = preload("res://random_company/kit.gd")
const Stock = preload("res://shop_stock/domain.gd")
var merchant_stock: Dictionary = {}
var random_recruit_start_week := -1
const SupportAcquisition = preload("res://support_equipment/policy.gd")
const VISIBLE_SLOTS = ["mainhand","offhand","head","body","hands","feet","cloak","belt","ammo"]
const SUPPORT_SLOTS = ["hands","feet","cloak","belt"]
func acquisition_policy():
 return Acquisition
func create_dungeons(definitions: Dictionary):
 var out = super.create_dungeons(definitions)
 out.support_acquisition = SupportAcquisition
 return out
func recovered_armor_is_loose() -> bool:
 return true
func reserve_weapon_definition() -> String:
 return "hm_trial_v1:old24-medic_weapon"
func _init():
 catalog = Catalog.equipment()
func equipment_catalog_for_validation(_balance: bool) -> Dictionary:
 return Catalog.equipment()
func validation_slots() -> Array:
 return SLOTS+SUPPORT_SLOTS
func valid_gear_size(person: Dictionary) -> bool:
 return person.gear.size() == SLOTS.size()+SUPPORT_SLOTS.size()
func capacity_for_items(person: Dictionary, inventory: Dictionary, definitions: Dictionary) -> int:
 return Effects.capacity(person,inventory,definitions)
func carry_capacity(person: Dictionary) -> int:
 return capacity_for_items(person,items,catalog)
func original_roll(person_seed: int, campaign_seed: int = -1, companion_role: String = "") -> Dictionary:
 var generator = People.new(); generator.state = person_seed
 var original: Dictionary = generator.generate("provenance",false,companion_role)
 var bases := {}
 for stat in People.ATTRS: bases[stat] = int(original[People.OFFER_FIELDS[stat]])
 return Rarity.roll_person(seed_value if campaign_seed < 0 else campaign_seed,person_seed,bases)
func random_company_enabled() -> bool:
 return false
func create_population() -> Dictionary:
 if not random_company_enabled(): return super.create_population()
 var population: Dictionary = People.new().population(seed_value,world.TOWNS,true)
 for candidate: Dictionary in population.founders:
  candidate[RandomKit.OFFER_KIT] = RandomKit.roll(seed_value,candidate,catalog)
 return population
func prepare_new_recruit(offer: Dictionary, created_week: int) -> void:
 if not random_company_enabled(): return
 if random_recruit_start_week < 0: random_recruit_start_week = created_week
 offer[RandomKit.OFFER_KIT] = RandomKit.roll(seed_value,offer,catalog)
func add_person(candidate: Dictionary) -> void:
 var random_kit := candidate.has(RandomKit.OFFER_KIT)
 var offer := RandomKit.project(candidate,catalog) if random_kit else Acquisition.candidate(candidate,catalog)
 if candidate.has("companion_role"): FoundingGear.outfit(seed_value,offer,catalog)
 super.add_person(offer)
 soldiers[-1]["companion_roll"] = original_roll(candidate.person_seed,-1,candidate.get("companion_role",""))
 # Creation only, not a refresh/healing path: current HP starts at rolled max.
 soldiers[-1].hp = max_hp(soldiers[-1])
 var selected := {}
 if random_kit: selected = offer.support_loadout
 # Preserve the exact accessory policy for already-generated offers.
 elif candidate.get("id","") in hired and recruit_pools.has(candidate.get("id","")):
  selected = SupportAcquisition.recruit(seed_value,candidate,catalog)
 for slot in SUPPORT_SLOTS:
  var definition: String = selected.get(slot,"")
  soldiers[-1].gear[slot] = add_item(definition) if not definition.is_empty() else ""
# People.validate_offer already bounds generated personal names at 100. Current
# owned-person restore accepts String names, independently of seed-based rolls.
# Match that bound without imposing ASCII, uniqueness or rewriting nicknames.
const COMPANION_NAME_LIMIT := 100
func companion_name_reason(value: String) -> String:
 if value.is_empty() or value.length() > COMPANION_NAME_LIMIT:return "Use 1–100 characters."
 var content := false
 for i in value.length():
  var code := value.unicode_at(i)
  if code < 32 or (code >= 127 and code <= 159) or code in [0x2028,0x2029]:return "Use one line, without control characters."
  if code not in [0x20,0xa0,0x1680,0x202f,0x205f,0x3000] and not (code >= 0x2000 and code <= 0x200a):content=true
 return "" if content else "Enter a nonblank name."
# Display name only: identity/provenance, random streams and history stay literal.
func rename_person(sid: int, value: String) -> bool:
 if phase != "camp" or over() or sid < 0 or sid >= soldiers.size(): return false
 var person: Dictionary = soldiers[sid]
 if not person.alive or person.name == value or not companion_name_reason(value).is_empty(): return false
 person.name = value
 return true
func recruits() -> Array:
 var out := []
 for candidate: Dictionary in super.recruits():
  var random_kit := candidate.has(RandomKit.OFFER_KIT)
  var offer := RandomKit.project(candidate,catalog) if random_kit else Acquisition.candidate(candidate,catalog)
  offer["companion_roll"] = original_roll(offer.person_seed)
  if not random_kit: offer["support_loadout"] = SupportAcquisition.recruit(seed_value,offer,catalog)
  out.append(offer)
 return out
func add_item(definition: String, condition: int = -1) -> String:
 if not catalog.has(definition): return ""
 var uid: String = super.add_item(definition,condition)
 if not catalog[definition].get("assembly",false):
  items[uid]["instance_roll"] = Rarity.roll_item(seed_value,uid,definition)
  items[uid].condition = int(item_def(uid).durability) if condition < 0 else clampi(condition,0,int(item_def(uid).durability))
 return uid
func slot_uid(person: Dictionary, slot: String) -> String:
 if slot in ["body","head"]:
  for layer in (["outer","mail","base","reinforce","cloth","cloak"] if slot == "body" else ["shell","mail","padding","face","decor"]):
   var uid: String = kit_parts(person.gear.get(slot,"")).get(layer,"")
   if not uid.is_empty(): return uid
  return ""
 return person.gear.get({"mainhand":"weapon","offhand":"shield"}.get(slot,slot),"")
func slot_allowed(definition: String, slot: String) -> bool:
 if slot not in VISIBLE_SLOTS+Arsenal.CARRIED or not catalog.has(definition): return false
 var d: Dictionary = catalog[definition]
 if d.get("assembly",false): return false
 if slot in Arsenal.CARRIED: return Arsenal.allowed(slot,definition,catalog)
 if slot == "body": return d.get("group") == "body" and d.get("layer") in ["base","mail","outer"]
 if slot == "head": return d.get("group") == "head" and d.get("layer") == "shell"
 return d.get("slot") == {"mainhand":"weapon","offhand":"shield"}.get(slot,slot)
func equipment_change_reason(person: Dictionary, slot: String, uid: String) -> String:
 return _equipment_change_reason(person,slot,uid)
func _equipment_change_reason(person: Dictionary, slot: String, uid: String, moving_uid: String = "") -> String:
 if slot not in VISIBLE_SLOTS+Arsenal.CARRIED: return "Unknown public equipment slot."
 if phase != "camp" or over() or not person.get("alive",false): return "Equipment changes require a living companion in CAMP."
 if uid.is_empty():
  if slot_uid(person,slot).is_empty(): return "This slot is already empty."
 else:
  if not items.has(uid) or (owner(uid) >= 0 and uid != moving_uid) or not parent_kit(uid).is_empty(): return "Physical item is unavailable or already assigned."
  if not slot_allowed(items[uid].definition,slot): return "This physical item does not fit the selected slot."
  if slot == "offhand" and item_def(person.gear.weapon).get("weapon","") in Arsenal.TWO_HANDS: return "The held weapon requires both hands."
 var prospective: Dictionary = person.duplicate(true)
 prospective.gear[{"mainhand":"weapon","offhand":"shield"}.get(slot,slot)] = uid
 var capacity: int = carry_capacity(prospective)
 if slot in Arsenal.CARRIED and Arsenal.CARRIED.find(slot) >= capacity: return "The chosen belt does not allow this reserve slot."
 for index in range(capacity,Arsenal.CARRIED.size()):
  if not prospective.gear.get(Arsenal.CARRIED[index],"").is_empty(): return "Empty excess reserves before reducing capacity; no item will be dropped."
 return ""
func equip(sid: int, uid: String, slot: String = "") -> bool:
 if sid < 0 or sid >= soldiers.size() or uid.is_empty(): return false
 var person: Dictionary = soldiers[sid]
 if not equipment_change_reason(person,slot,uid).is_empty(): return false
 _fit_slot(person,slot,uid)
 return true
func _fit_slot(person: Dictionary, slot: String, uid: String) -> void:
 if slot in ["body","head"]:
  var parts: Dictionary = Armor.empty_parts(slot)
  parts[catalog[items[uid].definition].layer] = uid
  items[person.gear[slot]].parts = parts
 else:
  person.gear[{"mainhand":"weapon","offhand":"shield"}.get(slot,slot)] = uid
  if slot == "mainhand" and item_def(uid).get("weapon","") in Arsenal.TWO_HANDS: person.gear.shield = ""
 recovery.stored.erase(uid)
func unequip(sid: int, slot: String) -> bool:
 if sid < 0 or sid >= soldiers.size(): return false
 var person: Dictionary = soldiers[sid]
 if not equipment_change_reason(person,slot,"").is_empty(): return false
 _clear_slot(person,slot)
 return true
func _clear_slot(person: Dictionary, slot: String) -> void:
 if slot in ["body","head"]: items[person.gear[slot]].parts = Armor.empty_parts(slot)
 else: person.gear[{"mainhand":"weapon","offhand":"shield"}.get(slot,slot)] = ""
func equipment_move_reason(sid: int, uid: String, source: String, target: String) -> String:
 if sid < 0 or sid >= soldiers.size() or uid.is_empty() or not items.has(uid): return "Physical item or companion is unavailable."
 if source == target: return "Choose a different destination."
 var person: Dictionary = soldiers[sid]
 if source.is_empty(): return equipment_change_reason(person,target,uid)
 if source not in VISIBLE_SLOTS+Arsenal.CARRIED or slot_uid(person,source) != uid or owner(uid) != sid: return "The source item or owner has changed."
 if target.is_empty(): return equipment_change_reason(person,source,"")
 var prospective: Dictionary = person.duplicate(true)
 prospective.gear[{"mainhand":"weapon","offhand":"shield"}.get(source,source)] = ""
 return _equipment_change_reason(prospective,target,uid,uid)
func move_equipment(sid: int, uid: String, source: String, target: String) -> bool:
 if not equipment_move_reason(sid,uid,source,target).is_empty(): return false
 # Admission above is read-only. No signal/callback can observe partial ownership.
 var person: Dictionary = soldiers[sid]
 if not source.is_empty(): _clear_slot(person,source)
 if not target.is_empty(): _fit_slot(person,target,uid)
 return true
func setup(seed_number: int = 7391, map_seed: int = -1, progression: bool = false, live_trade: bool = false, living_bands: bool = false, company_roster: bool = false, rural_supply: bool = false, physical_patrols: bool = false, hinterlands: bool = false, renewing_camps: bool = false, open_campaign: bool = false, world_economy: bool = false, expanded_region: bool = false, regional_news: bool = false, regional_recovery: bool = false, fading_tracks: bool = false, camp_reconnaissance: bool = false, raider_survival: bool = false, camp_founding: bool = false) -> void:
 merchant_stock = Stock.fresh(maxi(1,seed_number))
 random_recruit_start_week = -1
 super.setup(seed_number,map_seed,progression,live_trade,living_bands,company_roster,rural_supply,physical_patrols,hinterlands,renewing_camps,open_campaign,world_economy,expanded_region,regional_news,regional_recovery,fading_tracks,camp_reconnaissance,raider_survival,camp_founding)
 Stock.arrive(self,merchant_stock)
 # Optional founding accessories are normal physical allocations *after* opening
 # merchant custody. Their count cannot shift the reserve or opening shop rolls.
 for person in soldiers:
  if not person.has("companion_role"): continue
  var selected := FoundingGear.accessories(seed_value,person,catalog)
  for slot in SUPPORT_SLOTS:
   if not selected[slot].is_empty(): person.gear[slot] = add_item(selected[slot])
func ensure_market() -> void:
 super.ensure_market()
 if not merchant_stock.is_empty(): Stock.arrive(self,merchant_stock)
func merchant_offers() -> Array:
 return Stock.offers(self,merchant_stock)
func armorer_stock(group: String, layer: String) -> Array:
 return merchant_offers().filter(func(o):return o.kind == "component" and catalog[o.definition].get("group") == group and catalog[o.definition].get("layer") == layer)
func weapons_stock() -> Array:
 return merchant_offers().filter(func(o):return o.kind == "weapon")
func buy_weapon(id: String) -> String:
 return Stock.buy(self,merchant_stock,id,"weapon")
func buy_component(id: String) -> String:
 return Stock.buy(self,merchant_stock,id,"component")
func battle_parts(person: Dictionary, group: String = "", parts: Dictionary = {}) -> Array:
 var out: Array = super.battle_parts(person,group,parts)
 for part in out:
  part["hollow_slot"] = part.group
  if items[part.item].has("instance_roll"): part["instance_roll"] = items[part.item].instance_roll.duplicate(true)
 for slot in SUPPORT_SLOTS:
  var uid: String = person.gear.get(slot,"")
  if not items.has(uid): continue
  var item: Dictionary = items[uid]; var d: Dictionary = item_def(uid)
  var part := {"item":uid,"definition":item.definition,"group":"body","layer":slot,"pool":"armor","condition":item.condition,"maximum":int(d.durability),"weight":Armor.part_weight(item,catalog),"hollow_slot":slot}
  for key in ["named","instance_roll"]:
   if item.has(key): part[key] = item[key].duplicate(true)
  out.append(part)
 return out
func prepare_deployment() -> void:
 battle.equipment_catalog_override = catalog.duplicate(true)
 battle.defer_initial_round = true
func configure_player_unit(person: Dictionary, unit: Dictionary) -> void:
 unit["hollow_systems"] = true
 unit["hollow_capacity"] = carry_capacity(person)
 unit["company_id"] = person.id; unit["visual_id"] = person.id
 unit["companion_roll"] = person.companion_roll.duplicate(true)
 unit["max_hp"] = max_hp(person)
 unit["skill"] = effective_skill(person); unit["ranged_skill"] = effective_ranged_skill(person)
 for stat in ["defense","ranged_defense","stamina","initiative","resolve"]: unit[stat] = int(person[People.FIELDS[stat]])+rarity_delta(person,stat)
 Effects.install(unit,catalog)
 battle.armor_catalog = catalog.duplicate(true)
 battle.refresh_equipment_slots(unit)
func configure_enemy_unit(unit: Dictionary) -> void:
 # All finite-band/recon/crypt population scalars are final at this seam.
 unit["hollow_systems"] = true
 if unit.get("faction","") != "undead" and unit.name != "Empty rank":
  var grade := 0
  var condition_percent := 100
  for part in unit.armor_parts:
   grade = maxi(grade,Acquisition.BODIES.find(part.definition))
   if part.maximum > 0: condition_percent = mini(condition_percent,int(part.condition)*100/int(part.maximum))
  var identity := ["human",encounters,encounter.get("kind","contract"),encounter.get("id",active.get("id","")),encounter.get("generation",active.get("generation",0)),unit.id]
  SupportAcquisition.append_enemy(unit,catalog,seed_value,identity,grade,condition_percent,"enemy_%d_%d_support_v1" % [encounters,unit.id])
 unit["hollow_capacity"] = 4 if Perks.has(unit,"bags_and_belts") else 2
 for part in unit.armor_parts:
  part["hollow_slot"] = part.layer if part.layer in SUPPORT_SLOTS else part.group
  if part.layer == "belt" and not Perks.has(unit,"bags_and_belts") and (part.maximum == 0 or part.condition > 0): unit.hollow_capacity += int(catalog[part.definition].get("capacity",0))
 Effects.install(unit,catalog)
 battle.refresh_equipment_slots(unit)
func preview_unit(person: Dictionary, stats: Dictionary = {}) -> Dictionary:
 var unit: Dictionary = super.preview_unit(person,stats)
 unit["armor_parts"] = battle_parts(person)
 for key in armor_stats(person): unit[key] = armor_stats(person)[key]
 configure_player_unit(person,unit)
 return unit
func rarity_delta(person: Dictionary, stat: String) -> int:
 var roll: Dictionary = person.get("companion_roll",{})
 return int(roll.get("values",{}).get(stat,0))-int(roll.get("bases",{}).get(stat,0))
func max_hp(person: Dictionary) -> int:
 var adjusted: Dictionary = person.duplicate()
 adjusted.base_hp = int(person.base_hp)+rarity_delta(person,"health")
 return super.max_hp(adjusted)
func effective_skill(person: Dictionary) -> int:
 return super.effective_skill(person)+rarity_delta(person,"skill")
func effective_ranged_skill(person: Dictionary) -> int:
 return super.effective_ranged_skill(person)+rarity_delta(person,"ranged_skill")
func snapshot() -> Dictionary:
 var out: Dictionary = super.snapshot()
 out["hollow_campaign"] = 1
 out["merchant_stock"] = merchant_stock.duplicate(true)
 if random_recruit_start_week >= 0: out[RandomKit.FIRST_WEEK] = random_recruit_start_week
 return out
func restore(raw: Variant) -> bool:
 if not raw is Dictionary: return false
 var d: Dictionary = battle.normalize_json_numbers(raw)
 if not preload("res://hollow_campaign/checkpoint_admission.gd").valid(d): return false
 var definitions := Catalog.equipment()
 if not RandomKit.valid_offers(d,definitions,random_company_enabled()): return false
 if not Stock.valid(d.get("merchant_stock"),d,definitions,has_method("shelf_offers")): return false
 for person in d.soldiers:
  if person.has("companion_role") and (not person.companion_role is String or not People.Companions.PROFILES.has(person.companion_role)): return false
  if person.companion_roll != original_roll(person.person_seed,d.seed,person.get("companion_role","")): return false
 for item in d.items.values():
  if item.has("instance_roll") and item.instance_roll.seed != d.seed: return false
 if not super.restore(d): return false
 merchant_stock = d.merchant_stock.duplicate(true)
 random_recruit_start_week = d.get(RandomKit.FIRST_WEEK,-1)
 return true
