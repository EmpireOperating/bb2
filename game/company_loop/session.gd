extends RefCounted
## Bounded company/outfitting adapter. Campaign, Battle, Armor and Arsenal own rules.
signal changed
const Campaign = preload("res://src/campaign.gd")
const Armor = preload("res://src/armor.gd")
const Arsenal = preload("res://src/arsenal.gd")
const Scenario = preload("res://prototype/scenario.gd")
const SUPPORTED = ["linen","red_gambeson","mail","brigandine","nasal","kettle","sword","axe","spear","bow","shield","round_shield","arrows"]
const SLOT_LABELS = {"weapon":"Weapon","shield":"Shield","body/base":"Base garment","body/mail":"Mail","body/outer":"Outer protection","head/shell":"Helmet","ammo":"Ammunition"}
const KITS = [
 ["sword","shield","linen","mail","","nasal"],
 ["axe","round_shield","red_gambeson","","brigandine","kettle"],
 ["spear","shield","linen","","","nasal"],
 ["bow","","linen","","",""],
 ["spear","round_shield","red_gambeson","mail","","kettle"],
 ["sword","shield","red_gambeson","","brigandine","nasal"],
]
# Content override only: retain stock enemy identities/stats and replace physical
# spawn equipment before Campaign starts initiative. No turn/stat/combat override.
class CrossingCampaign extends Campaign:
 const ENEMY_KITS = [
  ["sword","round_shield","red_gambeson","mail","nasal"],
  ["spear","shield","linen","","kettle"],
  ["axe","round_shield","linen","",""],
  ["bow","","linen","",""],
 ]
 func equip_enemy(unit: Dictionary, threat: int) -> void:
  super.equip_enemy(unit,threat)
  var kit: Array = ENEMY_KITS[(unit.id-battle.player_slots())%ENEMY_KITS.size()]
  var arms = Arsenal.empty_arms()
  var definitions = {"weapon":kit[0],"shield":kit[1],"ammo":Arsenal.ammo_type(kit[0])}
  for slot in definitions:
   var definition: String = definitions[slot]
   if definition == "": continue
   arms[slot] = {"id":"enemy_%d_%d_%s" % [encounters,unit.id,slot],"definition":definition,"condition":int(catalog[definition].durability),"loaded":false}
  unit.arms = arms
  battle.sync_arms(unit)
  unit.armor_parts = []
  for definition in [kit[2],kit[3],kit[4]]:
   if definition == "": continue
   var d: Dictionary = catalog[definition]
   unit.armor_parts.append({"item":"enemy_%d_%d_%s_%s" % [encounters,unit.id,d.group,d.layer],"definition":definition,"group":d.group,"layer":d.layer,"pool":"helmet" if d.group == "head" else "padding" if d.layer == "base" else "armor","condition":int(d.durability),"maximum":int(d.durability),"weight":Armor.part_weight({"definition":definition},catalog)})
  for key in Armor.totals(unit.armor_parts): unit[key] = Armor.totals(unit.armor_parts)[key]

var campaign = CrossingCampaign.new()
var last_error: String = ""

func setup(seed: int = 7391) -> void:
 campaign = CrossingCampaign.new()
 campaign.setup(seed)
 # Actual generated identities/stats, not cloned founders. Explicit demo grant.
 var recruits = campaign.recruit_pools.keys()
 recruits.sort()
 for id in recruits.slice(0,3):
  campaign.add_person(campaign.recruit_pools[id].duplicate(true))
  campaign.hired.append(id)
 # Only initial content is curated. IDs are never reset or reused after this point.
 campaign.items.clear()
 for person in campaign.soldiers:
  for slot in person.gear: person.gear[slot] = ""
  var kit: Array = KITS[person.id]
  person.gear.weapon = campaign.add_item(kit[0])
  if kit[1] != "": person.gear.shield = campaign.add_item(kit[1])
  if kit[0] == "bow": person.gear.ammo = campaign.add_item("arrows")
  for group in ["body","head"]:
   var parts = Armor.empty_parts(group)
   var authored = {"base":kit[2],"mail":kit[3],"outer":kit[4]} if group == "body" else {"shell":kit[5]}
   for layer in authored:
    if authored[layer] != "": parts[layer] = campaign.add_item(authored[layer])
   person.gear[group] = campaign.add_assembly(group,parts)
 for definition in SUPPORTED: campaign.add_item(definition)
 campaign.note("Company Loop demo: six generated companions and a bounded authored armoury. No existing save imported.")
 _success()

func _success() -> bool:
 last_error = ""
 changed.emit()
 return true

func _fail(reason: String) -> bool:
 last_error = reason
 return false

func _person(sid: int) -> Dictionary:
 return campaign.soldiers[sid] if sid >= 0 and sid < campaign.soldiers.size() else {}

func preview_unit(sid: int) -> Dictionary:
 var person = _person(sid)
 if person.is_empty(): return {}
 var unit = campaign.preview_unit(person)
 # Campaign preview defaults a missing weapon to sword; a fallen member owns none.
 unit["weapon"] = unit.arms.weapon.get("definition","")
 unit["id"] = sid
 unit["company_id"] = sid
 unit["visual_id"] = sid
 unit["side"] = 0
 unit["armor_parts"] = campaign.battle_parts(person)
 for key in campaign.armor_stats(person): unit[key] = campaign.armor_stats(person)[key]
 unit["max_hp"] = campaign.max_hp(person)
 unit["skill"] = campaign.effective_skill(person)
 unit["ranged_skill"] = campaign.effective_ranged_skill(person)
 unit["defense"] = person.base_defense
 unit["ranged_defense"] = person.base_ranged_defense
 return unit

func _slot_item(person: Dictionary, slot: String) -> String:
 if "/" not in slot: return person.gear.get(slot,"")
 var pair = slot.split("/")
 return campaign.kit_parts(person.gear[pair[0]]).get(pair[1],"")

func _item_row(id: String) -> Dictionary:
 var definition = campaign.item_def(id)
 return {"item_id":id,"definition":campaign.items.get(id,{}).get("definition",""),"name":definition.get("name","Empty"),"condition":campaign.items.get(id,{}).get("condition",0),"maximum":int(definition.get("durability",0))}

func gear_slots(sid: int) -> Array:
 var person = _person(sid)
 if person.is_empty(): return []
 var rows = []
 for slot in SLOT_LABELS:
  var row = _item_row(_slot_item(person,slot))
  row["key"] = slot; row["label"] = SLOT_LABELS[slot]
  rows.append(row)
 return rows

func available_items(sid: int, slot: String) -> Array:
 var person = _person(sid)
 if person.is_empty() or not person.alive or campaign.phase != "camp" or campaign.over() or not SLOT_LABELS.has(slot): return []
 var rows = []
 if "/" in slot:
  var pair = slot.split("/")
  for id in campaign.components(pair[0],pair[1]):
   if campaign.items[id].definition in SUPPORTED and campaign.component_preview(sid,pair[0],pair[1],id).ok: rows.append(_item_row(id))
 else:
  if slot == "shield" and campaign.item_def(person.gear.weapon).get("weapon","") in Arsenal.TWO_HANDS: return []
  for id in campaign.stash(slot):
   if campaign.items[id].definition in SUPPORTED and Arsenal.allowed(slot,campaign.items[id].definition,campaign.catalog): rows.append(_item_row(id))
 return rows

func equip(sid: int, item_id: String, slot: String) -> bool:
 if not SLOT_LABELS.has(slot): return _fail("Unknown equipment slot.")
 if not available_items(sid,slot).any(func(row): return row.item_id == item_id):
  return _fail("Item unavailable, already owned/fitted, incompatible, or company not in camp.")
 var ok = false
 if "/" in slot:
  var pair = slot.split("/")
  ok = campaign.fit_component(sid,pair[0],pair[1],item_id)
 else: ok = campaign.equip(sid,item_id,slot)
 return _success() if ok else _fail("Campaign equipment validator refused the change.")

func unequip(sid: int, slot: String) -> bool:
 if not SLOT_LABELS.has(slot): return _fail("Unknown equipment slot.")
 var ok = false
 if "/" in slot:
  var pair = slot.split("/")
  var preview = campaign.component_preview(sid,pair[0],pair[1])
  if not preview.ok: return _fail(preview.reason)
  ok = campaign.fit_component(sid,pair[0],pair[1],"")
 else: ok = campaign.unequip(sid,slot)
 return _success() if ok else _fail("Cannot remove this slot (weapons must be replaced), or no change is possible.")

func start_battle() -> bool:
 if campaign.phase != "camp" or campaign.over() or campaign.alive_count() == 0 or not campaign.active.is_empty():
  return _fail("Deployment requires a living company in camp with no active job.")
 # Explicit repeatable demo content at the real ford, not a campaign travel UI.
 # No time advance, rest, repair, stat boost or cosmetic loadout substitution.
 campaign.active = {"id":"company_loop_%d" % campaign.encounters,"kind":"legacy","origin":"ashwick","target":"ford","shipment":"","client":campaign.world.towns.ashwick.owner,"generation":campaign.world.camps.ford.generation,"title":"Ruined Crossing","brief":"Company Loop demo: defeat the crossing band. Retreat closes this deployment unpaid.","pay":120,"threat":2,"objective":"eliminate","deadline":campaign.job_deadline(8),"participants":campaign.active_ids()}
 campaign.location = "ford"
 campaign.overworld.position = campaign.overworld.places.ford
 campaign.overworld.path.clear()
 campaign.overworld.destination = ""
 campaign.overworld.paused = true
 if not campaign.deploy(): return _fail("Campaign deployment refused.")
 # Read only terrain/spawn fields from the accepted scenario. Its side-turn
 # fixture and comparative gear never become the company battle.
 var content = Scenario.create(campaign.seed_value)
 campaign.battle.tiles = content.tiles.duplicate(true)
 for unit in campaign.battle.units:
  unit.q = content.units[unit.id].q
  unit.r = content.units[unit.id].r
  if unit.side == 0:
   unit["company_id"] = campaign.deployment[unit.id]
   unit["visual_id"] = campaign.deployment[unit.id]
  else: unit["visual_id"] = 6+unit.id
 return _success()

func resolve_battle() -> bool:
 return _success() if campaign.resolve_battle() else _fail("Only an unresolved finished battle can settle.")

func retreat_battle() -> bool:
 return _success() if campaign.retreat_from_battle() else _fail("Only an unfinished active battle can retreat.")

func return_to_camp() -> bool:
 return _success() if campaign.return_to_camp() else _fail("Only aftermath can return to camp.")

# Deliberately narrow private checkpoint format. No generic campaign import.
const USER_DIR_NAME = "ashen-company-company-loop"
const SAVE_FORMAT = 1
const MAX_SAVE_BYTES = 8388608

func _checkpoint_path(path: String) -> String:
 if not ProjectSettings.get_setting("application/config/use_custom_user_dir",false) or ProjectSettings.get_setting("application/config/custom_user_dir_name","") != USER_DIR_NAME:
  _fail("Checkpoint requires the isolated Company Loop custom user directory.")
  return ""
 var pattern = RegEx.new()
 pattern.compile("^user://[A-Za-z0-9][A-Za-z0-9_-]{0,63}\\.json$")
 var matched = pattern.search(path)
 if matched == null or matched.get_string() != path:
  _fail("Use a simple user://name.json checkpoint (no directories, traversal or absolute paths).")
  return ""
 var directory = DirAccess.open(OS.get_user_data_dir())
 if directory == null or directory.is_link(path.get_file()) or directory.dir_exists(path.get_file()):
  _fail("Checkpoint directory unavailable, or target is a link/directory.")
  return ""
 return ProjectSettings.globalize_path(path)

func _canonical(value: Variant) -> String:
 return JSON.stringify(campaign.battle.normalize_json_numbers(value))

func _validated_snapshot(raw: Variant):
 if not raw is Dictionary or raw.get("phase") != "camp" or raw.get("battle") != null or raw.get("version") != 23:
  return null
 if not raw.get("soldiers") is Array or raw.soldiers.size() != 6 or not raw.get("items") is Dictionary or raw.items.size() > 4096:
  return null
 if not raw.get("active") is Dictionary or not raw.active.is_empty(): return null
 # The wrapper admits only this demo's authored equipment, not catalog-wide imports.
 for item in raw.items.values():
  if not item is Dictionary or item.get("definition","") not in SUPPORTED+["body_kit","head_kit"]: return null
 var candidate = CrossingCampaign.new()
 if not candidate.restore(raw): return null
 # Refuse migrations/normalizations that would silently change this checkpoint.
 if _canonical(candidate.snapshot()) != _canonical(raw): return null
 return candidate

func _decode_checkpoint(text: String):
 var parser = JSON.new()
 if text.to_utf8_buffer().size() > MAX_SAVE_BYTES or parser.parse(text) != OK: return null
 var envelope = parser.data
 if not envelope is Dictionary or envelope.size() != 3 or envelope.get("format") != SAVE_FORMAT or not envelope.get("payload") is String or not envelope.get("digest") is String: return null
 # Canonical encoding rejects duplicate JSON keys as well as hand-edited envelopes.
 if _canonical(envelope) != text or envelope.payload.sha256_text() != envelope.digest: return null
 if parser.parse(envelope.payload) != OK or _canonical(parser.data) != envelope.payload: return null
 return _validated_snapshot(parser.data)

func save_camp(path: String) -> bool:
 if campaign.phase != "camp": return _fail("Only the last camp checkpoint can be saved; live battles and aftermath are never saved.")
 var absolute = _checkpoint_path(path)
 if absolute == "": return false
 var raw = campaign.snapshot()
 if _validated_snapshot(raw) == null: return _fail("Campaign snapshot failed validation; previous checkpoint retained.")
 var payload = _canonical(raw)
 var text = JSON.stringify({"format":SAVE_FORMAT,"payload":payload,"digest":payload.sha256_text()})
 if text.to_utf8_buffer().size() > MAX_SAVE_BYTES: return _fail("Checkpoint exceeds the bounded save size.")
 var temporary = absolute+".pending-"+str(Time.get_ticks_usec())
 var directory = DirAccess.open(OS.get_user_data_dir())
 if directory.is_link(temporary.get_file()) or directory.file_exists(temporary.get_file()) or directory.dir_exists(temporary.get_file()): return _fail("Temporary checkpoint already exists.")
 var file = FileAccess.open(temporary,FileAccess.WRITE)
 if file == null: return _fail("Unable to open temporary checkpoint.")
 file.store_string(text)
 file.flush()
 var write_error = file.get_error()
 file.close()
 if write_error != OK or FileAccess.get_file_as_string(temporary) != text:
  DirAccess.remove_absolute(temporary)
  return _fail("Checkpoint write failed; previous checkpoint retained.")
 # Same-directory rename is atomic on the supported Linux runtime.
 if directory.is_link(absolute.get_file()) or DirAccess.rename_absolute(temporary,absolute) != OK:
  DirAccess.remove_absolute(temporary)
  return _fail("Atomic checkpoint replacement failed; previous checkpoint retained.")
 if FileAccess.get_file_as_string(absolute) != text: return _fail("Checkpoint read-back verification failed.")
 last_error = ""
 # Never emit changed here: the parent may autosave in response to changed.
 return true

func load_camp(path: String) -> bool:
 if campaign.phase != "camp": return _fail("Return to camp before loading a checkpoint.")
 var absolute = _checkpoint_path(path)
 if absolute == "": return false
 var file = FileAccess.open(absolute,FileAccess.READ)
 if file == null: return _fail("Camp checkpoint does not exist or cannot be read.")
 if file.get_length() > MAX_SAVE_BYTES:
  file.close()
  return _fail("Checkpoint exceeds the bounded save size.")
 var text = file.get_as_text()
 file.close()
 var candidate = _decode_checkpoint(text)
 if candidate == null: return _fail("Corrupt, incompatible or invalid camp checkpoint; active company unchanged.")
 campaign = candidate
 return _success()