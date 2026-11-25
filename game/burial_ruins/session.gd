extends RefCounted
## One stock full campaign. This adapter owns only generated terrain and CAMP IO.
signal changed
const Campaign = preload("res://src/campaign.gd")
var campaign = _new_campaign()
func _new_campaign():
 return Campaign.new()
var last_error := ""
var selected_map_id := "generated_woodland_road"
var _deployed_map: Dictionary = {}
var _deployed_generation: Dictionary = {}
var deployed_map: Dictionary:
 get: return _deployed_map.duplicate(true)
var deployed_generation: Dictionary:
 get: return _deployed_generation.duplicate(true)
func setup(seed: int = 7391) -> void:
 campaign = _new_campaign()
 campaign.setup(seed,seed,true,true,true,true,true,true,true,true,true,true,true,true,false,true,true,true,true)
 campaign.enable_dungeons()
 selected_map_id = "generated_woodland_road"
 _deployed_map = {}; _deployed_generation = {}
 _success()
func _features(c) -> bool:
 return c.roster_version == 1 and c.progression_version == 1 and c.traffic.enabled and c.bandits.enabled and c.farm.enabled and c.farm.regional and c.guards.enabled and c.camp_life.enabled and c.endless and c.economy.enabled and c.news.enabled and not c.rebuilding.enabled and c.overworld.tracks.enabled and c.recon.enabled and c.raiders.enabled and c.founding.enabled and c.dungeons.enabled() and c.region.get("generator") == 3
func _validated_snapshot(raw: Variant):
 if not raw is Dictionary or not raw.get("phase") is String or raw.phase != "camp" or raw.get("battle") != null or not raw.get("version") is int or raw.version != 34: return null
 if not raw.get("soldiers") is Array or not raw.get("items") is Dictionary or not raw.get("active") is Dictionary or not raw.get("encounter") is Dictionary: return null
 # Guard current-feature authority before the stock validator's literal branches.
 for key in ["balance_pending","combat_pending","growth_pending","perks_pending","recovery_pending","ammo_pending"]:
  if not raw.get(key) is bool or raw[key]: return null
 for key in ["region","world","overworld","traffic","bandits","farm","guards","camp_life","camp_recon","raider_needs","camp_founding","economy","regional_news","dungeons"]:
  if not raw.get(key) is Dictionary: return null
  # Stock module restores compare versions before checking their Variant types.
  if key != "region" and not raw[key].get("version") is int: return null
 if not raw.region.get("generator") is int or raw.region.generator != 3: return null
 if not raw.encounter.is_empty():
  if not raw.encounter.get("kind") is String: return null
  if raw.encounter.kind in ["scout","camp"]:
   for key in ["kind","id","site","title","objective"]:
    if not raw.encounter.get(key) is String: return null
   for key in ["generation","threat","pay"]:
    if not raw.encounter.get(key) is int: return null
  elif raw.encounter.kind != "dungeon": return null
 if not _dungeon_shape(raw): return null
 # Active job discriminators are consumed by CampRecon before stock job validation.
 # Type-check first; retain stock semantic/escrow/participant validation below.
 if not raw.active.is_empty():
  for key in ["id","title","brief","origin","target","objective","kind","shipment","client"]:
   if not raw.active.get(key) is String: return null
  for key in ["pay","threat","deadline","generation"]:
   if not raw.active.get(key) is int: return null
  if not raw.active.get("participants") is Array: return null
  for id in raw.active.participants:
   if not id is int: return null
  if raw.active.kind not in ["clear","recover","courier","freight_escort"]: return null
  if raw.active.kind=="recover" and not raw.economy.get("freight",{}).get("shipments",{}).get(raw.active.shipment,{}).has("seizer"):return null
 for person in raw.soldiers:
  if not person is Dictionary or not person.get("gear") is Dictionary or not person.get("alive") is bool: return null
  if not person.alive: continue
  # Empty equipment is an existing assembly with empty parts, never no owner.
  for group in ["body","head"]:
   var id = person.gear.get(group)
   if not id is String or id.is_empty() or not raw.items.get(id) is Dictionary: return null
   var item: Dictionary = raw.items[id]
   if not item.get("definition") is String or item.definition != group+"_kit" or not item.get("parts") is Dictionary: return null
 var candidate = _new_campaign()
 if raw.active.get("kind")=="courier" and not _hosts_courier(candidate): return null
 if raw.active.get("kind")=="freight_escort" and not _hosts_freight_escort(candidate): return null
 if not candidate.restore(raw) or not _features(candidate): return null
 if _canonical(candidate.snapshot()) != _canonical(raw): return null
 return candidate
# Presentation estimates only: no snapshot, restore, authority cache or admission.
# A subclass with extra cheap display policy may override these preview methods;
# execution ALWAYS calls the original public virtual reasons afresh.
func contract_accept_preview_reason(id: String) -> String:
 if campaign.phase != "camp" or campaign.over(): return "A living company in CAMP is required."
 if not campaign.active.is_empty(): return "Finish or abandon the active contract first."
 if not campaign.encounter.is_empty() or campaign.overworld.pending != "" or campaign.dungeons.active != "": return "Resolve the pending contact or dungeon first."
 return _contract_offer_reason(campaign,id)
func _hosts_courier(c) -> bool:
 return c.has_method("courier_enabled") and c.courier_enabled()
func _hosts_freight_escort(c) -> bool:
 return c.has_method("freight_escort_enabled") and c.freight_escort_enabled()
func _contract_offer_reason(c, id: String) -> String:
 for job in c.offers():
  if job.id != id: continue
  if job.kind=="courier" and _hosts_courier(c):return ""
  if job.kind=="freight_escort" and _hosts_freight_escort(c):return ""
  if job.kind=="recover" and c.economy.freight.physical(job.shipment):return ""
  if job.kind != "clear": return "Only funded camp-clearing contracts are hosted in this slice."
  return ""
 return "This funded clear offer is not currently available."
func contract_attack_preview_reason() -> String:
 return _contract_reason(campaign)
func camp_attack_preview_reason(site: String = "") -> String:
 return _camp_reason(campaign,campaign.location if site.is_empty() else site)
func contract_accept_reason(id: String) -> String:
 if campaign.phase != "camp" or campaign.over(): return "A living company in CAMP is required."
 if not campaign.active.is_empty(): return "Finish or abandon the active contract first."
 if not campaign.encounter.is_empty() or campaign.overworld.pending != "" or campaign.dungeons.active != "": return "Resolve the pending contact or dungeon first."
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null: return "Invalid current campaign; unchanged."
 return _contract_offer_reason(candidate,id)
func accept_contract(id: String) -> bool:
 var reason := contract_accept_reason(id)
 if reason != "": return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null or not candidate.accept_job(id): return _fail("Stock funded acceptance refused; unchanged.")
 var kind = candidate.active.get("kind")
 if kind not in ["clear","recover"] and not (kind=="courier" and _hosts_courier(candidate)) and not (kind=="freight_escort" and _hosts_freight_escort(candidate)): return _fail("Unsupported current contract; unchanged.")
 if _validated_snapshot(candidate.snapshot()) == null: return _fail("Unsupported current contract; unchanged.")
 campaign = candidate
 return _success()
func _contract_reason(c) -> String:
 if c.phase != "camp" or c.over() or c.active_ids().is_empty(): return "A living field company in CAMP is required."
 if not c.encounter.is_empty() or c.overworld.pending != "" or c.dungeons.active != "": return "Resolve the pending contact or dungeon first."
 if c.active.get("kind") is String and c.active.kind=="courier" and _hosts_courier(c): return "Take the sealed packet to its receiving town. No battle required."
 if c.active.is_empty() or not c.active.get("kind") is String or c.active.kind != "clear": return "A supported funded clear contract is required."
 if not c.active.get("target") is String: return "Invalid contract target."
 var site: String = c.active.target
 # Public physical arrival precedes every query of the remote camp's fresh truth.
 if c.location != site or not c.overworld.at_site(site): return "Approach the contract camp before taking the field."
 if not c.can_deploy(): return "The stock contract target or deadline no longer admits deployment."
 return ""
func contract_attack_reason() -> String:
 var reason := _contract_reason(campaign)
 if reason != "": return reason
 if _validated_snapshot(campaign.snapshot()) == null: return "Invalid current campaign; unchanged."
 return ""
func start_contract_battle() -> bool:
 var reason := contract_attack_reason()
 if reason != "": return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null: return _fail("Invalid current campaign; unchanged.")
 var site: String = candidate.active.target
 var job: Dictionary = candidate.active.duplicate(true)
 var generation: int = candidate.world.camps[site].generation
 # Stock deploy refreshes these two fields (campaign.gd:747,753-754,1582-1584).
 # Derive exact expected values before deployment; preserve every other job field.
 job.participants = candidate.CompanyRoster.active(candidate).duplicate()
 job.threat = maxi(1,candidate.world.camps[site].strength)
 var escrow: Dictionary = candidate.economy.escrow.duplicate(true)
 var packet := _camp_packet(candidate,site)
 var spawns: Array = _outdoor_spawns(packet)
 if spawns.size() != 24: return _fail("Generated stock24 contract profile refused; unchanged.")
 # Never attack_camp: it redirects active jobs and is not this entrance's authority.
 if not candidate.deploy(): return _fail("Stock contract deployment refused; unchanged.")
 if candidate.phase != "battle" or candidate.active != job or candidate.economy.escrow != escrow or not candidate.encounter.is_empty() or candidate.recon.engagement.get("site") != site or candidate.recon.engagement.get("generation") != generation: return _fail("Stock contract binding mismatch; unchanged.")
 if not _install_camp_field(candidate,packet,spawns): return _fail("Generated contract field refused; unchanged.")
 _deployed_map = packet.descriptor.duplicate(true); _deployed_generation = _camp_metadata(packet)
 campaign = candidate
 return _success()
func _outdoor_spawns(packet: Dictionary) -> Array:
 return load("res://world_loop/deployment.gd").profile(packet)

func _contact_key(c) -> String:
 var e: Dictionary = c.encounter
 return JSON.stringify(["woodland_contact_v1",c.region.seed,e.kind,e.id,e.site,e.generation])
func _contact_packet(c) -> Dictionary:
 if c.encounter.is_empty() or c.encounter.get("kind") != "scout": return {}
 var seed_number: int = _contact_key(c).sha256_text().left(7).hex_to_int()
 var generator = load("res://procedural_woodland/generator.gd")
 return generator.generate(seed_number)
func _metadata(packet: Dictionary) -> Dictionary:
 return {"recipe":"woodland_contact_v1/"+packet.recipe,"seed":packet.seed,"fingerprint":packet.fingerprint}
func _camp_packet(c, site: String) -> Dictionary:
 var key := JSON.stringify(["woodland_camp_v1",c.region.seed,"camp",site,site,c.world.camps[site].generation])
 var seed_number: int = key.sha256_text().left(7).hex_to_int()
 return load("res://procedural_woodland/generator.gd").generate(seed_number)
func _camp_metadata(packet: Dictionary) -> Dictionary:
 return {"recipe":"woodland_camp_v1/"+packet.recipe,"seed":packet.seed,"fingerprint":packet.fingerprint}
func _camp_reason(c, site: String) -> String:
 if c.phase != "camp" or c.over() or c.active_ids().is_empty(): return "A living field company in CAMP is required."
 if not c.active.is_empty() and c.active.get("target") == site and not c.economy.freight.physical(c.active.shipment): return "Use the contract entrance for this camp."
 if not c.encounter.is_empty() or c.overworld.pending != "" or c.dungeons.active != "": return "Resolve the pending contact or dungeon first."
 if not c.world.camps.has(site) or not c.overworld.places.has(site): return "Select a known camp."
 if not c.overworld.discovered(c.overworld.places[site]): return "The camp is unknown."
 # Public physical arrival must precede fresh private activity/generation reads.
 if c.location != site or not c.overworld.at_site(site): return "Approach the camp before assaulting it."
 var camp: Dictionary = c.world.camps[site]
 if not camp.get("active") is bool or not camp.get("generation") is int or not camp.active: return "This camp is not active."
 return ""
func camp_attack_reason(site: String = "") -> String:
 if site == "": site = campaign.location
 var reason := _camp_reason(campaign,site)
 if reason != "": return reason
 if _validated_snapshot(campaign.snapshot()) == null: return "Invalid current campaign; unchanged."
 return ""
func start_camp_battle(site: String = "") -> bool:
 if site == "": site = campaign.location
 var reason := camp_attack_reason(site)
 if reason != "": return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null: return _fail("Invalid current campaign; unchanged.")
 var generation: int = candidate.world.camps[site].generation
 var job: Dictionary = candidate.active.duplicate(true)
 var escrow: Dictionary = candidate.economy.escrow.duplicate(true)
 var payment: Dictionary = candidate.snapshot().get("contract_payment",{}).duplicate(true)
 var packet := _camp_packet(candidate,site)
 var spawns: Array = _outdoor_spawns(packet)
 if spawns.size() != 24: return _fail("Generated stock24 camp profile refused; unchanged.")
 if not candidate.attack_camp(): return _fail("Stock camp assault refused; unchanged.")
 var e: Dictionary = candidate.encounter
 if candidate.phase != "battle" or candidate.active != job or candidate.economy.escrow != escrow or candidate.snapshot().get("contract_payment",{}) != payment or e.get("kind") != "camp" or e.get("site") != site or e.get("id") != site or e.get("generation") != generation or candidate.recon.engagement.get("site") != site or candidate.recon.engagement.get("generation") != generation: return _fail("Stock camp binding mismatch; unchanged.")
 if not _install_camp_field(candidate,packet,spawns): return _fail("Generated camp field refused; unchanged.")
 _deployed_map = packet.descriptor.duplicate(true); _deployed_generation = _camp_metadata(packet)
 campaign = candidate
 return _success()
func _install_camp_field(candidate, packet: Dictionary, spawns: Array) -> bool:
 var b = candidate.battle
 var d: Dictionary = packet.descriptor
 if b.player_slots() != 12 or b.units.size() != 24 or not b.configure_board(d.width,d.height,d.goal): return false
 b.tiles = d.tiles.duplicate(true)
 for u in b.units:
  var p: Vector2i = spawns[u.id]; u.q = p.x; u.r = p.y
  if u.side == 0:
   u["company_id"] = candidate.deployment[u.id]; u["visual_id"] = candidate.deployment[u.id]
  else: u["visual_id"] = 12+u.id
 if b.active_id >= 0:
  var u: Dictionary = b.units[b.active_id]
  var state: Dictionary = b.vital_state(u); state.origin_q = u.q; state.origin_r = u.r
 b.terrain_rules_enabled = true
 b.set_meta("authored_map",d.duplicate(true))
 return b.configure_visibility()
func _camp_selection(c) -> Dictionary:
 if not c.active.is_empty():
  if _contract_reason(c) != "": return {}
 elif _camp_reason(c,c.location) != "": return {}
 return _camp_metadata(_camp_packet(c,c.location))
func selected_generation() -> Dictionary:
 if campaign.phase != "camp": return _deployed_generation.duplicate(true)
 # Generation is derived only from an admitted real pending contact.
 if campaign.encounter.is_empty(): return _camp_selection(campaign)
 if not campaign.encounter.get("kind") is String or campaign.encounter.kind != "scout" or campaign.overworld.pending != campaign.encounter.get("id"): return {}
 var packet := _contact_packet(campaign)
 return {} if packet.is_empty() else _metadata(packet)
func start_battle() -> bool:
 if campaign.phase != "camp" or campaign.over() or campaign.active_ids().is_empty(): return _fail("A living full campaign in CAMP is required.")
 if campaign.encounter.is_empty() or campaign.encounter.get("kind") != "scout" or campaign.overworld.pending != campaign.encounter.get("id"): return _fail("Only a real pending roaming scout contact is hosted; other entrances are unavailable.")
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null: return _fail("Invalid current campaign/contact; unchanged.")
 var packet := _contact_packet(candidate)
 var spawns: Array = _outdoor_spawns(packet)
 if spawns.size() != 24: return _fail("Generated stock24 profile refused; unchanged.")
 if not candidate.deploy(): return _fail("Stock deployment refused; unchanged.")
 # Share the existing virtual installation seam with funded/camp deployment.
 # Derived preview profiles may change coordinates, never encounter authority.
 if not _install_camp_field(candidate,packet,spawns): return _fail("Generated visibility/field refused; unchanged.")
 _deployed_map = packet.descriptor.duplicate(true); _deployed_generation = _metadata(packet)
 campaign = candidate
 return _success()
func resolve_battle() -> bool:
 return _success() if campaign.resolve_battle() else _fail("Only an unresolved finished battle can settle.")
func retreat_battle() -> bool:
 return _success() if campaign.retreat_from_battle() else _fail("Only an unfinished active battle can retreat.")
func return_to_camp() -> bool:
 return _success() if campaign.return_to_camp() else _fail("Only aftermath can return to CAMP.")
const USER_DIR := "ashen-company-painted-merge"
const CHECKPOINT := "user://hollow-campaign-camp.json"
const MAX_SAVE_BYTES := 8388608
func checkpoint_origin() -> String:
 return USER_DIR
func _checkpoint_path(path: String) -> String:
 if not ProjectSettings.get_setting("application/config/use_custom_user_dir",false) or ProjectSettings.get_setting("application/config/custom_user_dir_name","") != checkpoint_origin() or OS.get_user_data_dir().get_file() != checkpoint_origin():
  _fail("Checkpoint requires the isolated Burial Ruins directory."); return ""
 var pattern := RegEx.new(); pattern.compile("^user://[A-Za-z0-9][A-Za-z0-9_-]{0,63}\\.json$")
 var matched := pattern.search(path)
 if matched == null or matched.get_string() != path:
  _fail("Use a simple user://name.json checkpoint."); return ""
 var directory := DirAccess.open(OS.get_user_data_dir())
 if directory == null or directory.is_link(path.get_file()) or directory.dir_exists(path.get_file()):
  _fail("Checkpoint unavailable or target is a link/directory."); return ""
 return ProjectSettings.globalize_path(path)
func _checkpoint_binding(candidate) -> Dictionary:
 var packet := _contact_packet(candidate)
 return _camp_selection(candidate) if packet.is_empty() else _metadata(packet)
func _decode_checkpoint(text: String):
 var parser := JSON.new()
 if text.to_utf8_buffer().size() > MAX_SAVE_BYTES or parser.parse(text) != OK: return null
 var envelope = parser.data
 if not envelope is Dictionary or envelope.size() != 4 or _canonical(envelope) != text: return null
 envelope = campaign.battle.normalize_json_numbers(envelope)
 if not envelope.get("format") is int or envelope.format != 1 or not envelope.get("origin") is String or envelope.origin != checkpoint_origin() or not envelope.get("payload") is String or not envelope.get("digest") is String: return null
 if envelope.payload.sha256_text() != envelope.digest or parser.parse(envelope.payload) != OK or _canonical(parser.data) != envelope.payload: return null
 var payload = campaign.battle.normalize_json_numbers(parser.data)
 if not payload is Dictionary or payload.size() != 2 or not payload.get("binding") is Dictionary or not payload.has("campaign"): return null
 var candidate = _validated_snapshot(payload.campaign)
 if candidate == null: return null
 var binding: Dictionary = _checkpoint_binding(candidate)
 if _canonical(payload.binding) != _canonical(binding): return null
 return candidate
func save_camp(path: String = CHECKPOINT) -> bool:
 if campaign.phase != "camp": return _fail("Only CAMP checkpoints are saved; no battle or aftermath serialization.")
 var absolute := _checkpoint_path(path)
 if absolute.is_empty(): return false
 var raw: Dictionary = campaign.snapshot()
 if _validated_snapshot(raw) == null: return _fail("Invalid current campaign; previous checkpoint retained.")
 var payload := _canonical({"campaign":raw,"binding":selected_generation()})
 var text := _canonical({"format":1,"origin":checkpoint_origin(),"payload":payload,"digest":payload.sha256_text()})
 if text.to_utf8_buffer().size() > MAX_SAVE_BYTES: return _fail("Checkpoint exceeds bounded size.")
 var temporary := absolute+".pending-"+str(OS.get_process_id())+"-"+str(Time.get_ticks_usec())
 var directory := DirAccess.open(OS.get_user_data_dir())
 if directory.is_link(temporary.get_file()) or directory.file_exists(temporary.get_file()) or directory.dir_exists(temporary.get_file()): return _fail("Temporary checkpoint exists.")
 var file := FileAccess.open(temporary,FileAccess.WRITE)
 if file == null: return _fail("Cannot open temporary checkpoint.")
 file.store_string(text); file.flush()
 var write_error := file.get_error(); file.close()
 if write_error != OK or FileAccess.get_file_as_string(temporary) != text or _decode_checkpoint(text) == null:
  DirAccess.remove_absolute(temporary); return _fail("Checkpoint write/validation failed; previous checkpoint retained.")
 if directory.is_link(absolute.get_file()) or directory.dir_exists(absolute.get_file()) or DirAccess.rename_absolute(temporary,absolute) != OK:
  DirAccess.remove_absolute(temporary); return _fail("Atomic replacement failed; previous checkpoint retained.")
 if FileAccess.get_file_as_string(absolute) != text: return _fail("Checkpoint read-back failed.")
 last_error = ""
 return true # Silent: never recurse through host changed/autosave.
func load_camp(path: String = CHECKPOINT) -> bool:
 if campaign.phase != "camp": return _fail("Return to CAMP before loading.")
 var absolute := _checkpoint_path(path)
 if absolute.is_empty(): return false
 var file := FileAccess.open(absolute,FileAccess.READ)
 if file == null: return _fail("CAMP checkpoint unavailable.")
 if file.get_length() > MAX_SAVE_BYTES:
  file.close(); return _fail("Checkpoint exceeds bounded size.")
 var text := file.get_as_text(); file.close()
 var candidate = _decode_checkpoint(text)
 if candidate == null: return _fail("Corrupt, incompatible or invalid checkpoint; company unchanged.")
 campaign = candidate; _deployed_map = {}; _deployed_generation = {}
 return _success()
const SLOT_LABELS := {"weapon":"Weapon","shield":"Shield","body/base":"Base garment","body/mail":"Mail","body/outer":"Outer protection","head/shell":"Helmet","carry1":"Carried arm 1","carry2":"Carried arm 2","carry3":"Carried arm 3","carry4":"Carried arm 4","ammo":"Ammunition"}
func preview_unit(sid: int) -> Dictionary:
 if sid < 0 or sid >= campaign.soldiers.size(): return {}
 var person: Dictionary = campaign.soldiers[sid]
 var unit: Dictionary = campaign.preview_unit(person)
 unit["weapon"] = unit.arms.weapon.get("definition","")
 unit["id"] = sid; unit["company_id"] = sid; unit["visual_id"] = sid; unit["side"] = 0
 unit["armor_parts"] = campaign.battle_parts(person)
 var stats: Dictionary = campaign.armor_stats(person)
 for key in stats: unit[key] = stats[key]
 unit["max_hp"] = campaign.max_hp(person); unit["skill"] = campaign.effective_skill(person)
 unit["ranged_skill"] = campaign.effective_ranged_skill(person)
 unit["defense"] = person.base_defense; unit["ranged_defense"] = person.base_ranged_defense
 return unit
func gear_slots(sid: int) -> Array:
 if sid < 0 or sid >= campaign.soldiers.size(): return []
 var person: Dictionary = campaign.soldiers[sid]
 var rows := []
 for slot in SLOT_LABELS:
  var id: String = person.gear.get(slot,"")
  if "/" in slot:
   var pair: PackedStringArray = slot.split("/")
   id = campaign.kit_parts(person.gear.get(pair[0],"")).get(pair[1],"")
  var item: Dictionary = campaign.items.get(id,{})
  var definition: Dictionary = campaign.item_def(id)
  rows.append({"key":slot,"label":SLOT_LABELS[slot],"item_id":id,"definition":item.get("definition",""),"name":definition.get("name","Empty"),"condition":item.get("condition",0),"maximum":int(definition.get("durability",0))})
 return rows
func _canonical(value: Variant) -> String:
 return JSON.stringify(campaign.battle.normalize_json_numbers(value))
func _success() -> bool:
 last_error = ""; changed.emit(); return true
func _fail(reason: String) -> bool:
 last_error = reason; return false


# Shape-only preflight: semantics remain entirely with current stock restore.
func _typed_fields(d: Variant, fields: Dictionary) -> bool:
 if not d is Dictionary: return false
 for key in fields:
  if not d.has(key) or typeof(d[key]) != fields[key]: return false
 return true
func _dungeon_shape(raw: Dictionary) -> bool:
 var e: Dictionary = raw.encounter
 if not e.is_empty() and e.kind == "dungeon":
  if not _typed_fields(e,{"kind":TYPE_STRING,"id":TYPE_STRING,"site":TYPE_STRING,"title":TYPE_STRING,"objective":TYPE_STRING,"floor":TYPE_INT,"room":TYPE_INT,"generation":TYPE_INT,"threat":TYPE_INT,"pay":TYPE_INT}): return false
 var d: Dictionary = raw.dungeons
 if not _typed_fields(d,{"version":TYPE_INT,"active":TYPE_STRING,"floor":TYPE_INT,"room":TYPE_INT,"previous":TYPE_INT,"sites":TYPE_DICTIONARY,"vault_keys":TYPE_DICTIONARY}) or d.version != 6: return false
 for id in d.sites:
  if not id is String: return false
  var site = d.sites[id]
  if not _typed_fields(site,{"seed":TYPE_INT,"tier":TYPE_INT,"place":TYPE_DICTIONARY,"floors":TYPE_ARRAY,"rumour":TYPE_BOOL,"entered":TYPE_BOOL,"completed":TYPE_BOOL}): return false
  if site.has("discovery") and not site.discovery is String: return false
  if not _typed_fields(site.place,{"id":TYPE_STRING,"kind":TYPE_STRING,"name":TYPE_STRING,"description":TYPE_STRING,"x":TYPE_INT,"y":TYPE_INT}): return false
  for floor in site.floors:
   if not _typed_fields(floor,{"index":TYPE_INT,"seed":TYPE_INT,"exit":TYPE_INT,"rooms":TYPE_ARRAY}): return false
   for room in floor.rooms:
    if not _typed_fields(room,{"id":TYPE_INT,"x":TYPE_INT,"y":TYPE_INT,"seed":TYPE_INT,"shortcut":TYPE_INT,"kind":TYPE_STRING,"reward":TYPE_STRING,"field":TYPE_STRING,"hazard":TYPE_STRING,"resolution":TYPE_STRING,"links":TYPE_ARRAY,"roster":TYPE_ARRAY,"loot":TYPE_DICTIONARY,"wear":TYPE_ARRAY,"risk":TYPE_BOOL,"seen":TYPE_BOOL,"visited":TYPE_BOOL,"cleared":TYPE_BOOL,"looted":TYPE_BOOL}): return false
    for link in room.links:
     if not link is int: return false
    for kind in room.roster:
     if not kind is String: return false
    for key in room.loot:
     if not key is String or not room.loot[key] is int: return false
    for wear in room.wear:
     if not _typed_fields(wear,{"hp":TYPE_INT,"arms":TYPE_DICTIONARY,"parts":TYPE_ARRAY}): return false
     for arm in wear.arms.values():
      if not arm is Dictionary: return false
      if not arm.is_empty() and not _typed_fields(arm,{"id":TYPE_STRING,"definition":TYPE_STRING,"condition":TYPE_INT,"loaded":TYPE_BOOL}): return false
     for part in wear.parts:
      if not _typed_fields(part,{"item":TYPE_STRING,"definition":TYPE_STRING,"group":TYPE_STRING,"layer":TYPE_STRING,"pool":TYPE_STRING,"condition":TYPE_INT,"maximum":TYPE_INT,"weight":TYPE_INT}): return false
 if not _typed_fields(d.vault_keys,{"opportunities":TYPE_INT,"records":TYPE_DICTIONARY}): return false
 for row in d.vault_keys.records.values():
  if not _typed_fields(row,{"held":TYPE_BOOL,"opened":TYPE_BOOL,"noticed":TYPE_BOOL,"source":TYPE_STRING}): return false
 return true

const SUPPORTED_BURIAL := "dungeon_barrow_0"
const Chamber = preload("res://burial_ruins/chamber.gd")
const BURIAL_ACTIONS := ["move","search","rest","leave","up","down","inspect_vault","unlock_vault","choice_disarm","choice_force","choice_clear","choice_dig","choice_search"]
func burial_enter_reason(site: String) -> String:
 var c = campaign
 if not c.overworld.places.has(site) or not c.overworld.discovered(c.overworld.places[site]): return "Select a known burial marker."
 if site != SUPPORTED_BURIAL: return "Only Thorn Burial Mound is hosted in Burial Ruins."
 if c.location != site or not c.overworld.at_site(site): return "Reach the entrance first."
 if c.overworld.pending != "": return "Resolve the pending scout first."
 return c.dungeon_enter_reason(site)
func enter_burial(site: String) -> bool:
 var reason := burial_enter_reason(site)
 if reason != "": return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null or not candidate.enter_dungeon(site): return _fail("Stock burial entry refused; unchanged.")
 var admitted = _validated_snapshot(candidate.snapshot())
 if admitted == null: return _fail("Stock burial entry refused; unchanged.")
 _room_admitted = admitted
 campaign = candidate
 return _success()
func _burial_context_reason() -> String:
 var c = campaign
 if c.phase != "camp" or c.dungeons.active != SUPPORTED_BURIAL: return "An active Thorn Burial Mound expedition in CAMP is required."
 if c.location != SUPPORTED_BURIAL or not c.overworld.at_site(SUPPORTED_BURIAL): return "Reach the entrance first."
 if c.overworld.pending != "": return "Resolve the pending scout first."
 return ""
func burial_action_reason(action: String, target: int = -1) -> String:
 if action not in BURIAL_ACTIONS: return "Unsupported burial action."
 var reason := _burial_context_reason()
 if reason != "": return reason
 var c = campaign
 if action == "leave": return "" if c.encounter.is_empty() or c.encounter.get("kind") == "dungeon" else "Resolve the current encounter first."
 if not c.encounter.is_empty(): return "Fight or leave the occupied chamber."
 if c.over(): return "A living company is required."
 if action == "move": return c.dungeon_move_reason(target)
 if action.begins_with("choice_"): return c.dungeon_choice_reason(action.trim_prefix("choice_"))
 var room: Dictionary = c.dungeons.room()
 match action:
  "search": return "" if room.cleared and not room.looted and not room.loot.is_empty() and c.Dungeons.can_search(room) else "No accessible unlooted cache here."
  "rest": return "" if room.cleared else "Clear the chamber before resting."
  "up": return "" if room.kind == "entry" and c.dungeons.floor_index > 0 else "No upward stairs here."
  "down": return "" if room.kind == "stairs" and room.cleared and c.dungeons.floor_index+1 < c.dungeons.sites[SUPPORTED_BURIAL].floors.size() else "No downward stairs here."
  "inspect_vault", "unlock_vault":
   if target not in c.dungeons.links(c.dungeons.room_index) or not c.dungeons.vault_keys.locked(c.vault_id(target)): return "No locked connecting treasury."
   if action == "unlock_vault" and (c.active_ids().is_empty() or not c.dungeons.vault_keys.records[c.vault_id(target)].held or c.food < c.dungeon_scout_cost()): return "Need the matching key, formed companions and scouting food."
   return ""
 return "Unsupported burial action."
# A private detached authority, not an identity/cardinality validity cache. Every
# reuse compares the entire current snapshot to its exact admitted content. It is
# never published: live edits (including same-sized edits) force full admission.
var _room_admitted = null
func _room_fast_policy() -> bool:
 # New/overridden campaign semantics and public validators keep the old boundary.
 if campaign.get_script().resource_path not in ["res://src/campaign.gd","res://hollow_campaign/campaign.gd","res://local_markets/campaign.gd","res://contract_pay/campaign.gd"]: return false
 var script = get_script()
 var declaration = RegEx.new(); declaration.compile("(?m)^func\\s+_validated_snapshot\\s*\\(")
 while script != null and script.resource_path != "res://burial_ruins/session.gd":
  # get_script_method_list includes inherited methods in Godot 4.4. Inspect
  # declarations instead; unavailable source conservatively keeps full validation.
  if script.source_code.is_empty() or declaration.search(script.source_code) != null: return false
  script = script.get_base_script()
 return script != null
func _room_copy_value(value, copies: Dictionary):
 if value is Dictionary or value is Array:
  var out = value.duplicate()
  for key in value.keys() if value is Dictionary else range(value.size()): out[key] = _room_copy_value(value[key],copies)
  return out
 if not value is Object or value == null: return value
 if value is Script: return value # immutable program, never authority
 var id: int = value.get_instance_id()
 if copies.has(id): return copies[id]
 if value is RandomNumberGenerator:
  var rng = RandomNumberGenerator.new(); rng.seed = value.seed; rng.state = value.state
  copies[id] = rng; return rng
 if value is AStar2D:
  var graph = AStar2D.new()
  for point in value.get_point_ids():
   graph.add_point(point,value.get_point_position(point),value.get_point_weight_scale(point)); graph.set_point_disabled(point,value.is_point_disabled(point))
  for point in value.get_point_ids():
   for neighbor in value.get_point_connections(point):
    if not graph.are_points_connected(point,neighbor,false): graph.connect_points(point,neighbor,false)
  copies[id] = graph; return graph
 if value is AStarGrid2D:
  var graph = AStarGrid2D.new()
  for key in ["region","cell_size","offset","diagonal_mode","default_compute_heuristic","default_estimate_heuristic","jumping_enabled"]: graph.set(key,value.get(key))
  graph.update()
  for y in range(value.region.position.y,value.region.end.y):
   for x in range(value.region.position.x,value.region.end.x):
    var point = Vector2i(x,y)
    graph.set_point_solid(point,value.is_point_solid(point)); graph.set_point_weight_scale(point,value.get_point_weight_scale(point))
  copies[id] = graph; return graph
 if value.get_script() == null:
  copies["ok"] = false; return null
 var out = value.get_script().new()
 copies[id] = out
 for property in value.get_property_list():
  if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: out.set(property.name,_room_copy_value(value.get(property.name),copies))
 return out
func _room_copy(source):
 var copies = {"ok":true}
 var out = _room_copy_value(source,copies)
 return out if copies.ok else null
func _room_transition_valid(before: Dictionary, candidate, target: int) -> bool:
 var after: Dictionary = candidate.snapshot()
 # Bounded first optimization: exact ordinary moves without midnight, repairs,
 # contract expiry, discoveries, or other cross-domain changes. Those still run
 # the complete public validator, as do all non-move actions.
 var affected = ["dungeons","overworld","bandits","farm","recovery","food","encounter"]
 if before.keys() != after.keys(): return _validated_snapshot(after) != null
 for key in before:
  if key not in affected and before[key] != after[key]: return _validated_snapshot(after) != null
 var expected = _room_copy(_room_admitted.dungeons)
 if expected == null: return false
 expected.previous = expected.room_index; expected.room_index = target; expected.reveal()
 if expected.snapshot() != after.dungeons: return false
 var next: Dictionary = before.dungeons.sites[before.dungeons.active].floors[before.dungeons.floor].rooms[target]
 if after.food != before.food-(candidate.dungeon_scout_cost() if not next.visited else 0): return false
 if not candidate.Recovery.valid(after.recovery,after.soldiers,after.items): return false
 if not after.encounter.is_empty():
  if not candidate.valid_dungeon_context(after,candidate.dungeons,candidate.overworld): return false
 elif not candidate.dungeons.room().cleared: return false
 var spatial = candidate.Overworld.new()
 if not spatial.restore(after.overworld,candidate.dungeons.spatial_region(candidate.region),candidate.world) or spatial.snapshot() != after.overworld: return false
 if not spatial.paused or not spatial.path.is_empty() or spatial.pending != "" or spatial.rest_left != 0 or not spatial.at_site(after.location): return false
 # Farm geometry depends only on admitted immutable geography/configuration.
 # Reuse those exact layouts; keep every Farmstead semantic/ledger/raid check.
 if after.farm.get("version") != 2 or after.farm.farms.keys() != before.farm.farms.keys(): return false
 var taken = {}
 for prior in _room_admitted.farm.all():
  var farm = candidate.farm.Farmstead.new(); farm.town = prior.town; farm.regional = true; farm.geometry = prior.geometry.duplicate(true)
  if not farm.restore(after.farm.farms[prior.town],spatial,candidate.world) or farm.snapshot() != after.farm.farms[prior.town]: return false
  if not farm.raid.is_empty():
   if taken.has(farm.raid.party): return false
   taken[farm.raid.party] = true
 var bandits = candidate.Bandits.new()
 if not bandits.restore(after.bandits,spatial,candidate.traffic,candidate.progression_version,candidate.opening_rules,candidate.farm,candidate.guards) or bandits.snapshot() != after.bandits: return false
 # These unchanged modules' validators consume the changed scouts/farms/bands.
 var traffic = candidate.Traffic.new()
 if not traffic.restore(after.traffic,spatial,candidate.world): return false
 var guards = candidate.Guards.new()
 if not guards.restore(after.guards,spatial,candidate.world,candidate.farm,false): return false
 var life = candidate.CampLife.new(); life.acquisition = candidate.acquisition_policy()
 if not life.restore(after.camp_life,after,spatial,candidate.world,bandits,candidate.catalog,candidate.region): return false
 var context = {"world":candidate.world,"overworld":spatial,"camp_life":life,"bandits":bandits,"guards":guards,"dungeons":candidate.dungeons,"progression_version":candidate.progression_version,"phase":candidate.phase,"encounter":candidate.encounter,"active":candidate.active}
 var recon = candidate.CampRecon.new()
 if not recon.restore(after.camp_recon,context): return false
 context.recon = recon
 var raiders = candidate.RaiderNeeds.new()
 if not raiders.restore(after.raider_needs,context): return false
 context.raiders = raiders
 var founding = candidate.CampFounding.new()
 return founding.restore(after.camp_founding,context)
func burial_action(action: String, target: int = -1) -> bool:
 var reason := burial_action_reason(action,target)
 if reason != "": return _fail(reason)
 var raw: Dictionary = campaign.snapshot()
 var fast: bool = action == "move" and _room_admitted != null and _room_fast_policy() and raw == _room_admitted.snapshot()
 var candidate = _room_copy(_room_admitted) if fast else _validated_snapshot(raw)
 if candidate == null: return _fail("Invalid current burial campaign; unchanged.")
 var ok := false
 match action:
  "move": ok = candidate.dungeon_move(target)
  "search": ok = candidate.dungeon_search()
  "rest": ok = candidate.dungeon_rest()
  "leave": ok = candidate.leave_dungeon()
  "up": ok = candidate.dungeon_stairs(false)
  "down": ok = candidate.dungeon_stairs(true)
  "inspect_vault": ok = candidate.inspect_vault(target)
  "unlock_vault": ok = candidate.unlock_vault(target)
  _: ok = candidate.dungeon_choice(action.trim_prefix("choice_"))
 if not ok: return _fail("Stock burial action refused; unchanged.")
 var admitted
 if fast:
  if not _room_transition_valid(raw,candidate,target): return _fail("Stock burial action refused; unchanged.")
  admitted = _room_copy(candidate)
 else:
  admitted = _validated_snapshot(candidate.snapshot())
 if admitted == null: return _fail("Stock burial action refused; unchanged.")
 _room_admitted = admitted
 campaign = candidate
 return _success()
func burial_attack_reason() -> String:
 var reason := _burial_context_reason()
 if reason != "": return reason
 var c = campaign; var e: Dictionary = c.encounter
 if c.over() or c.active_ids().is_empty(): return "A living formed company is required."
 if e.get("kind") != "dungeon" or e.get("site") != SUPPORTED_BURIAL or e.get("floor") != c.dungeons.floor_index or e.get("room") != c.dungeons.room_index: return "No current supported occupied chamber."
 if c.dungeons.room().cleared or not c.can_deploy(): return "The stock chamber no longer admits deployment."
 return ""
func start_burial_battle() -> bool:
 var reason := burial_attack_reason()
 if reason != "": return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null: return _fail("Invalid current burial campaign; unchanged.")
 var job: Dictionary = candidate.active.duplicate(true)
 var escrow: Dictionary = candidate.economy.escrow.duplicate(true)
 if not candidate.deploy(): return _fail("Stock burial deployment refused; unchanged.")
 var packet := Chamber.packet(candidate)
 if candidate.active != job or candidate.economy.escrow != escrow or not candidate.recon.engagement.is_empty() or not _install_burial_field(candidate,packet): return _fail("Burial chamber installation refused; unchanged.")
 _deployed_map = packet.descriptor.duplicate(true); _deployed_generation = Chamber.metadata(packet)
 campaign = candidate
 return _success()
func _install_burial_field(candidate, packet: Dictionary) -> bool:
 if not Chamber.validate(packet): return false
 var b = candidate.battle; var d: Dictionary = packet.descriptor
 if b.units.size() != 24 or b.player_slots() != 12 or not b.configure_board(d.width,d.height,d.goal): return false
 b.tiles = d.tiles.duplicate(true)
 for u in b.units:
  var at: Vector2i = packet.spawns[u.id]; u.q = at.x; u.r = at.y
 if b.active_id >= 0:
  var u: Dictionary = b.units[b.active_id]; var state: Dictionary = b.vital_state(u)
  state.origin_q = u.q; state.origin_r = u.r
 b.terrain_rules_enabled = true
 b.set_meta("authored_map",d.duplicate(true))
 var boss: bool = b.boss_tactics
 var ok: bool = b.configure_visibility()
 b.boss_tactics = boss
 return ok
