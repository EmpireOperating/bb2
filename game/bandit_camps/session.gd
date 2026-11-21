extends RefCounted
## One stock full campaign. This adapter owns only generated terrain and CAMP IO.
signal changed
const Campaign = preload("res://src/campaign.gd")
var campaign = Campaign.new()
var last_error := ""
var selected_map_id := "generated_woodland_road"
var _deployed_map: Dictionary = {}
var _deployed_generation: Dictionary = {}
var deployed_map: Dictionary:
 get: return _deployed_map.duplicate(true)
var deployed_generation: Dictionary:
 get: return _deployed_generation.duplicate(true)
func setup(seed: int = 7391) -> void:
 campaign = Campaign.new()
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
 for person in raw.soldiers:
  if not person is Dictionary or not person.get("gear") is Dictionary or not person.get("alive") is bool: return null
  if not person.alive: continue
  # Empty equipment is an existing assembly with empty parts, never no owner.
  for group in ["body","head"]:
   var id = person.gear.get(group)
   if not id is String or id.is_empty() or not raw.items.get(id) is Dictionary: return null
   var item: Dictionary = raw.items[id]
   if not item.get("definition") is String or item.definition != group+"_kit" or not item.get("parts") is Dictionary: return null
 var candidate = Campaign.new()
 if not candidate.restore(raw) or not _features(candidate): return null
 if _canonical(candidate.snapshot()) != _canonical(raw): return null
 return candidate
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
 if not c.active.is_empty(): return "Finish or abandon the active contract first."
 if not c.encounter.is_empty() or c.overworld.pending != "" or c.dungeons.active != "": return "Resolve the pending contact or dungeon first."
 if not c.world.camps.has(site) or not c.overworld.places.has(site): return "Select a known camp."
 var camp: Dictionary = c.world.camps[site]
 if not camp.get("active") is bool or not camp.get("generation") is int or not camp.active: return "This camp is not active."
 if not c.overworld.discovered(c.overworld.places[site]): return "The camp is unknown."
 if c.location != site or not c.overworld.at_site(site): return "Approach the camp before assaulting it."
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
 var packet := _camp_packet(candidate,site)
 var spawns: Array = load("res://world_loop/deployment.gd").profile(packet)
 if spawns.size() != 24: return _fail("Generated stock24 camp profile refused; unchanged.")
 if not candidate.attack_camp(): return _fail("Stock camp assault refused; unchanged.")
 var e: Dictionary = candidate.encounter
 if candidate.phase != "battle" or not candidate.active.is_empty() or e.get("kind") != "camp" or e.get("site") != site or e.get("id") != site or e.get("generation") != generation: return _fail("Stock camp binding mismatch; unchanged.")
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
 if _camp_reason(c,c.location) != "": return {}
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
 var bridge = load("res://world_loop/deployment.gd")
 var spawns: Array = bridge.profile(packet)
 if spawns.size() != 24: return _fail("Generated stock24 profile refused; unchanged.")
 if not candidate.deploy(): return _fail("Stock deployment refused; unchanged.")
 var b = candidate.battle
 var d: Dictionary = packet.descriptor
 if b.player_slots() != 12 or b.units.size() != 24 or not b.configure_board(d.width,d.height,d.goal): return _fail("Stock24 battlefield extent refused; unchanged.")
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
 if not b.configure_visibility(): return _fail("Generated visibility refused; unchanged.")
 _deployed_map = d.duplicate(true); _deployed_generation = _metadata(packet)
 campaign = candidate
 return _success()
func resolve_battle() -> bool:
 return _success() if campaign.resolve_battle() else _fail("Only an unresolved finished battle can settle.")
func retreat_battle() -> bool:
 return _success() if campaign.retreat_from_battle() else _fail("Only an unfinished active battle can retreat.")
func return_to_camp() -> bool:
 return _success() if campaign.return_to_camp() else _fail("Only aftermath can return to CAMP.")
const USER_DIR := "ashen-company-bandit-camps"
const CHECKPOINT := "user://bandit-camps-camp.json"
const MAX_SAVE_BYTES := 8388608
func _checkpoint_path(path: String) -> String:
 if not ProjectSettings.get_setting("application/config/use_custom_user_dir",false) or ProjectSettings.get_setting("application/config/custom_user_dir_name","") != USER_DIR or OS.get_user_data_dir().get_file() != USER_DIR:
  _fail("Checkpoint requires the isolated Bandit Camps directory."); return ""
 var pattern := RegEx.new(); pattern.compile("^user://[A-Za-z0-9][A-Za-z0-9_-]{0,63}\\.json$")
 var matched := pattern.search(path)
 if matched == null or matched.get_string() != path:
  _fail("Use a simple user://name.json checkpoint."); return ""
 var directory := DirAccess.open(OS.get_user_data_dir())
 if directory == null or directory.is_link(path.get_file()) or directory.dir_exists(path.get_file()):
  _fail("Checkpoint unavailable or target is a link/directory."); return ""
 return ProjectSettings.globalize_path(path)
func _decode_checkpoint(text: String):
 var parser := JSON.new()
 if text.to_utf8_buffer().size() > MAX_SAVE_BYTES or parser.parse(text) != OK: return null
 var envelope = parser.data
 if not envelope is Dictionary or envelope.size() != 4 or _canonical(envelope) != text: return null
 envelope = campaign.battle.normalize_json_numbers(envelope)
 if not envelope.get("format") is int or envelope.format != 1 or not envelope.get("origin") is String or envelope.origin != USER_DIR or not envelope.get("payload") is String or not envelope.get("digest") is String: return null
 if envelope.payload.sha256_text() != envelope.digest or parser.parse(envelope.payload) != OK or _canonical(parser.data) != envelope.payload: return null
 var payload = campaign.battle.normalize_json_numbers(parser.data)
 if not payload is Dictionary or payload.size() != 2 or not payload.get("binding") is Dictionary or not payload.has("campaign"): return null
 var candidate = _validated_snapshot(payload.campaign)
 if candidate == null: return null
 var packet := _contact_packet(candidate)
 var binding: Dictionary = _camp_selection(candidate) if packet.is_empty() else _metadata(packet)
 if _canonical(payload.binding) != _canonical(binding): return null
 return candidate
func save_camp(path: String = CHECKPOINT) -> bool:
 if campaign.phase != "camp": return _fail("Only CAMP checkpoints are saved; no battle or aftermath serialization.")
 var absolute := _checkpoint_path(path)
 if absolute.is_empty(): return false
 var raw: Dictionary = campaign.snapshot()
 if _validated_snapshot(raw) == null: return _fail("Invalid current campaign; previous checkpoint retained.")
 var payload := _canonical({"campaign":raw,"binding":selected_generation()})
 var text := _canonical({"format":1,"origin":USER_DIR,"payload":payload,"digest":payload.sha256_text()})
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
