extends "res://src/campaign.gd"
## Full current Campaign ancestry. Physical records remain the single authority.
const Forge = preload("res://layer_forge/rules.gd")
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
 out.forge_rewards = forge_enabled()
 return out
func recovered_armor_is_loose() -> bool:
 return true
func reserve_weapon_definition() -> String:
 return "hm_trial_v1:old24-medic_weapon"
func _init():
 catalog = Catalog.equipment()
func equipment_catalog_for_validation(_balance: bool) -> Dictionary:
 return Catalog.equipment()
func forge_enabled() -> bool:
 return Forge.enabled()
func owned_layer_keys(group: String) -> Array:
 return Forge.LAYERS.get(group,[]) if forge_enabled() else super.owned_layer_keys(group)
func owned_assembly_conflict(parts: Dictionary, group: String, definitions: Dictionary) -> String:
 return Forge.conflict(parts,group) if forge_enabled() else super.owned_assembly_conflict(parts,group,definitions)
func kit_parts(kit: String) -> Dictionary:
 var parts: Dictionary = super.kit_parts(kit)
 if not forge_enabled() or parts.is_empty(): return parts
 var ordered := {}
 for layer: String in owned_layer_keys(catalog[items[kit].definition].slot): ordered[layer] = parts[layer]
 return ordered
func visible_equipment_slots() -> Array:
 return Forge.VISIBLE if forge_enabled() else VISIBLE_SLOTS
func armor_lab_enabled() -> bool:
 return Catalog.armor_lab_profile()
func item_def(id: String) -> Dictionary:
 var d: Dictionary = super.item_def(id)
 if not d.get("lab_outfit",false): return d
 # Rarity's saved cosmetic utility roll is immutable, but never contributes.
 d = d.duplicate()
 d.effects = {}
 return d
func validation_slots() -> Array:
 return SLOTS if forge_enabled() else SLOTS+SUPPORT_SLOTS
func valid_gear_size(person: Dictionary) -> bool:
 return person.gear.size() == validation_slots().size()
func capacity_for_items(person: Dictionary, inventory: Dictionary, definitions: Dictionary) -> int:
 return super.capacity_for_items(person,inventory,definitions) if forge_enabled() else Effects.capacity(person,inventory,definitions)
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
 if candidate.has("companion_role"):
  if forge_enabled(): FoundingGear.outfit_arms(seed_value,offer)
  else: FoundingGear.outfit(seed_value,offer,catalog)
 if forge_enabled(): _forge_offer(offer,candidate,soldiers.size() if soldiers.size()<3 and not hired.has(candidate.get("id","")) else -1)
 elif armor_lab_enabled(): _lab_offer_base(offer)
 super.add_person(offer)
 soldiers[-1]["companion_roll"] = original_roll(candidate.person_seed,-1,candidate.get("companion_role",""))
 # Creation only, not a refresh/healing path: current HP starts at rolled max.
 soldiers[-1].hp = max_hp(soldiers[-1])
 if forge_enabled(): return
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
  if forge_enabled(): _forge_offer(offer,candidate,-1)
  elif not random_kit: offer["support_loadout"] = SupportAcquisition.recruit(seed_value,offer,catalog)
  if armor_lab_enabled() and _lab_offer_base(offer): offer.price += int(catalog[Catalog.LAB_BASE].price)
  out.append(offer)
 return out
func _forge_offer(offer: Dictionary, source: Dictionary, founder_index: int) -> void:
 offer.armor_loadout = Forge.companion(catalog,seed_value,source,founder_index)
 offer.erase("support_loadout")
 offer.loadout.under = offer.armor_loadout.body.base
 offer.loadout.body = offer.armor_loadout.body.mail
 offer.loadout.head = offer.armor_loadout.head.shell if not offer.armor_loadout.head.shell.is_empty() else offer.armor_loadout.head.padding
 for group: String in Forge.LAYERS:
  for definition: String in offer.armor_loadout[group].values():
   if not definition.is_empty(): offer.price += int(catalog[definition].price)
func _lab_offer_base(offer: Dictionary) -> bool:
 var body: Dictionary = offer.armor_loadout.body
 var missing: bool = body.base.is_empty()
 if missing: body.base = Catalog.LAB_BASE
 offer.loadout.under = body.base
 offer.loadout.body = body.outer if not body.outer.is_empty() else body.mail
 return missing
func reserve_named_reward(key: String, definition: String, reward_seed: int, source: String) -> Dictionary:
 if forge_enabled():
  if catalog.get(Acquisition.reward(definition,catalog),{}).get("slot") != "weapon": return {}
  if named_rewards.has(key):
   var row = named_rewards[key]
   if not row is Dictionary or not row.get("item") is Dictionary or catalog.get(row.item.get("definition"),{}).get("slot") != "weapon": return {}
 return super.reserve_named_reward(key,definition,reward_seed,source)

func claim_named_reward(key: String) -> String:
 if forge_enabled() and named_rewards.has(key):
  var row = named_rewards[key]
  if not row is Dictionary or not row.get("item") is Dictionary or catalog.get(row.item.get("definition"),{}).get("slot") != "weapon": return ""
 return super.claim_named_reward(key)

func recover_item(item: Dictionary, condition: int) -> String:
 if forge_enabled() and item.has("named") and catalog.get(item.get("definition"),{}).get("slot") != "weapon": return ""
 return super.recover_item(item,condition)

func add_item(definition: String, condition: int = -1) -> String:
 if not catalog.has(definition): return ""
 if forge_enabled() and definition not in Forge.ASSEMBLY.values() and not Forge.tradeable(definition,catalog): return ""
 if armor_lab_enabled() and not _lab_physical_allowed(definition,catalog): return ""
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
 if slot not in visible_equipment_slots()+Arsenal.CARRIED or not catalog.has(definition): return false
 if forge_enabled() and slot in ["body","head"]: return false
 var d: Dictionary = catalog[definition]
 if d.get("assembly",false): return false
 if slot in Arsenal.CARRIED: return Arsenal.allowed(slot,definition,catalog)
 if slot == "body": return not armor_lab_enabled() and d.get("group") == "body" and d.get("layer") in Catalog.LAB_BODY_LAYERS
 if slot == "head": return d.get("group") == "head" and d.get("layer") == "shell"
 return d.get("slot") == {"mainhand":"weapon","offhand":"shield"}.get(slot,slot)
func equipment_change_reason(person: Dictionary, slot: String, uid: String) -> String:
 return _equipment_change_reason(person,slot,uid)
func _equipment_change_reason(person: Dictionary, slot: String, uid: String, moving_uid: String = "") -> String:
 if slot not in visible_equipment_slots()+Arsenal.CARRIED: return "Unknown public equipment slot."
 if forge_enabled() and slot in ["body","head"]: return "Choose a specific armor layer."
 if slot == "body" and armor_lab_enabled(): return "Choose a specific body layer."
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
 if slot in Arsenal.CARRIED and Arsenal.CARRIED.find(slot) >= capacity:
  return "This companion does not have that pocket." if forge_enabled() else "The chosen belt does not allow this pocket."
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
 if forge_enabled() and (source in ["body","head"] or target in ["body","head"]): return "Choose a specific armor layer."
 if armor_lab_enabled() and (source == "body" or target == "body"): return "Choose a specific body layer."
 if source == target: return "Choose a different destination."
 var person: Dictionary = soldiers[sid]
 if source.is_empty(): return equipment_change_reason(person,target,uid)
 if source not in visible_equipment_slots()+Arsenal.CARRIED or slot_uid(person,source) != uid or owner(uid) != sid: return "The source item or owner has changed."
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
func component_preview(sid: int, group: String, layer: String, uid: String = "", definition: String = "") -> Dictionary:
 if forge_enabled():
  var reason := ""
  var design_id: String = items.get(uid,{}).get("definition",definition)
  if layer not in owned_layer_keys(group): reason = "Choose a Forge position."
  elif not design_id.is_empty() and not Forge.is_layer(design_id,catalog): reason = "Only Forge pieces fit in this kit."
  elif items.get(uid,{}).has("named") and not forge_named_mail_owned(uid): reason = "That Named layer has no valid company claim."
  elif uid.is_empty() and definition.is_empty() and sid >= 0 and sid < soldiers.size() and kit_parts(soldiers[sid].gear.get(group,"")).get(layer,"").is_empty(): reason = "This layer is already empty."
  if not reason.is_empty(): return {"ok":false,"reason":reason,"before":{},"after":{},"appearance":{}}
 if armor_lab_enabled():
  var reason := ""
  if group == "body":
   if layer not in Catalog.LAB_BODY_LAYERS: reason = "Choose Base, Mail or Outer."
   elif items.get(uid,{}).get("definition",definition) in Catalog.LAB_RETIRED_OUTER: reason = "That legacy leather is not a Lab outer layer."
   elif uid.is_empty() and definition.is_empty():
    if layer == "base": reason = "Replace the base garment; it cannot be removed."
    elif sid >= 0 and sid < soldiers.size() and kit_parts(soldiers[sid].gear.body).get(layer,"").is_empty(): reason = "This layer is already empty."
  elif group == "head" and layer != "shell": reason = "Choose the single helmet slot."
  if not reason.is_empty(): return {"ok":false,"reason":reason,"before":{},"after":{},"appearance":{}}
 return super.component_preview(sid,group,layer,uid,definition)
func forge_set_group(uid: String) -> String:
 if not forge_enabled(): return ""
 var record: Dictionary = items.get(uid,{})
 for group: String in Forge.ASSEMBLY:
  if record.get("definition") == Forge.ASSEMBLY[group] and Forge.has_pieces(record.get("parts",{})): return group
 return ""
func forge_sets(group: String) -> Array:
 if not forge_enabled() or not Forge.ASSEMBLY.has(group): return []
 var out := stash(group).filter(func(uid): return forge_set_group(uid) == group)
 out.sort()
 return out
func forge_set_preview(sid: int, group: String, uid: String = "") -> Dictionary:
 var out := {"ok":false,"reason":"Choose a Forge armor region.","before":{},"after":{}}
 if not forge_enabled() or not Forge.ASSEMBLY.has(group): return out
 out.reason = "Equipment changes require a living companion in CAMP."
 if phase != "camp" or over() or sid < 0 or sid >= soldiers.size() or not soldiers[sid].alive: return out
 var person: Dictionary = soldiers[sid]
 var worn: String = person.gear[group]
 if uid.is_empty():
  out.reason = "There is no worn set in this region."
  if forge_set_group(worn) != group: return out
 else:
  out.reason = "Choose a loose intact set for this region."
  if forge_set_group(uid) != group or owner(uid) >= 0 or not parent_kit(uid).is_empty(): return out
  for child: String in kit_parts(uid).values():
   if items.get(child,{}).has("named") and not forge_named_mail_owned(child):
    out.reason = "That Named layer has no valid company claim."
    return out
 # Compare the actual part projection as well as totals; a change in two
 # pieces that cancels out in protection must still stale the UI intent.
 out.worn = worn
 out.before_parts = battle_parts(person)
 out.after_parts = battle_parts(person,group,kit_parts(uid))
 out.before = Armor.totals(out.before_parts)
 out.after = Armor.totals(out.after_parts)
 out.reason = ""
 out.ok = true
 return out
func fit_forge_set(sid: int, group: String, uid: String) -> bool:
 var quote := forge_set_preview(sid,group,uid)
 if not quote.ok: return false
 var person: Dictionary = soldiers[sid]
 var worn: String = quote.worn
 if uid.is_empty():
  # Each living companion retains an internal (possibly empty) regional kit.
  # Only that empty holder is new; the detached root and all leaves keep IDs.
  person.gear[group] = add_assembly(group)
  note("%s removed their %s set to the stash." % [person.name,group])
 else:
  person.gear[group] = uid
  recovery.stored.erase(uid)
  if forge_set_group(worn).is_empty():
   items.erase(worn)
   recovery.stored.erase(worn)
  note("%s fitted a complete %s set." % [person.name,group])
 return true
func swap_kit(a: int, b: int, group: String) -> bool:
 return false if forge_enabled() else super.swap_kit(a,b,group)
func components(group: String, layer: String) -> Array:
 if forge_enabled():
  if layer not in owned_layer_keys(group): return []
  return super.components(group,layer).filter(func(uid):return Forge.is_layer(items[uid].definition,catalog))
 if not armor_lab_enabled(): return super.components(group,layer)
 if (group == "body" and layer not in Catalog.LAB_BODY_LAYERS) or (group == "head" and layer != "shell"): return []
 return super.components(group,layer).filter(func(uid): return items[uid].definition not in Catalog.LAB_RETIRED_OUTER)
func setup(seed_number: int = 7391, map_seed: int = -1, progression: bool = false, live_trade: bool = false, living_bands: bool = false, company_roster: bool = false, rural_supply: bool = false, physical_patrols: bool = false, hinterlands: bool = false, renewing_camps: bool = false, open_campaign: bool = false, world_economy: bool = false, expanded_region: bool = false, regional_news: bool = false, regional_recovery: bool = false, fading_tracks: bool = false, camp_reconnaissance: bool = false, raider_survival: bool = false, camp_founding: bool = false) -> void:
 merchant_stock = Stock.fresh(maxi(1,seed_number))
 random_recruit_start_week = -1
 super.setup(seed_number,map_seed,progression,live_trade,living_bands,company_roster,rural_supply,physical_patrols,hinterlands,renewing_camps,open_campaign,world_economy,expanded_region,regional_news,regional_recovery,fading_tracks,camp_reconnaissance,raider_survival,camp_founding)
 Stock.arrive(self,merchant_stock)
 if forge_enabled(): return
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
 var claimed_mail := ""
 for part in out:
  part["hollow_slot"] = part.group
  if items[part.item].has("instance_roll"): part["instance_roll"] = items[part.item].instance_roll.duplicate(true)
  if part.definition == NamedMail.PART and part.has("named"): claimed_mail = part.item
 if forge_enabled():
  if not claimed_mail.is_empty() and not Armor.valid_battle_parts(out,catalog,claimed_mail):
   return out.filter(func(part): return part.item != claimed_mail)
  return out
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
 unit["company_id"]=person.id; unit["visual_id"]=person.id
 if forge_enabled():
  unit.erase("forge_named_mail_uid")
  for part: Dictionary in unit.armor_parts:
   # battle_parts checked the owning ledger and physical projection first.
   if part.definition == NamedMail.PART and part.has("named"): unit["forge_named_mail_uid"] = part.item
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
 if not forge_enabled() and unit.get("faction","") != "undead" and unit.name != "Empty rank":
  var grade := 0
  var condition_percent := 100
  for part in unit.armor_parts:
   grade = maxi(grade,Acquisition.BODIES.find(part.definition))
   if part.maximum > 0: condition_percent = mini(condition_percent,int(part.condition)*100/int(part.maximum))
  var identity := ["human",encounters,encounter.get("kind","contract"),encounter.get("id",active.get("id","")),encounter.get("generation",active.get("generation",0)),unit.id]
  SupportAcquisition.append_enemy(unit,catalog,seed_value,identity,grade,condition_percent,"enemy_%d_%d_support_v1" % [encounters,unit.id])
 unit["hollow_capacity"] = 4 if Perks.has(unit,"bags_and_belts") else 2
 for part in unit.armor_parts:
  # Forge Body V is a region leaf, not the old standalone support cloak.
  part["hollow_slot"] = part.layer if part.layer in SUPPORT_SLOTS and part.definition!=Forge.RIVETED_MANTLE else part.group
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
 if armor_lab_enabled() and not _lab_loadouts_valid(d,definitions): return false
 if forge_enabled():
  if not Forge.valid_inventory(d,definitions) or d.get("population_kind") != "generated": return false
  var reservations = d.get("named_rewards",{})
  if not reservations is Dictionary: return false
  for key in reservations:
   var row = reservations[key]
   if not row is Dictionary or not row.get("item") is Dictionary or not row.item.get("definition") is String: return false
   if definitions.get(row.item.definition,{}).get("slot") == "weapon": continue
   if key != NamedMail.KEY or not d.get("next_item") is int or not NamedMail.valid_claim(row,d.items,d.next_item,definitions): return false
  # No predecessor-mode recruitment roll replay in a fresh Forge envelope.
  var first = d.get(RandomKit.FIRST_WEEK)
  if not first is int or first != 0: return false
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
func _lab_loadouts_valid(d: Dictionary, definitions: Dictionary) -> bool:
 var attached := {}
 for person: Dictionary in d.soldiers:
  if not person.alive: continue
  var base = d.items[person.gear.body].parts.get("base")
  if not base is String or base.is_empty(): return false
  attached[person.gear.body] = true
  attached[person.gear.head] = true
 for uid in d.items:
  var item: Dictionary = d.items[uid]
  if item.get("legacy_weight",false) or not _lab_physical_allowed(item.definition,definitions): return false
  if item.definition not in ["body_kit","head_kit"]: continue
  if not attached.has(uid) or not item.get("parts") is Dictionary: return false
  var layers := Catalog.LAB_BODY_LAYERS if item.definition == "body_kit" else ["shell"]
  for layer in item.parts:
   if layer not in layers and item.parts[layer] != "": return false
 return true
func _lab_physical_allowed(definition: String, definitions: Dictionary) -> bool:
 var design: Dictionary = definitions.get(definition,{})
 if design.is_empty() or definition in Catalog.LAB_RETIRED_OUTER: return false
 if design.get("lab_outfit",false): return true
 if design.get("group") == "body": return design.layer in Catalog.LAB_BODY_LAYERS
 if design.get("group") == "head": return design.layer == "shell"
 return true
