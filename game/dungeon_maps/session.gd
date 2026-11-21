extends "res://burial_ruins/session.gd"
## Successor IO owns its real writer origin and defaults, not inherited constants.
const OWN_USER_DIR := "ashen-company-dungeon-maps"
const OWN_CHECKPOINT := "user://dungeon-maps-camp.json"
func _checkpoint_path(path: String) -> String:
 if not ProjectSettings.get_setting("application/config/use_custom_user_dir",false) or ProjectSettings.get_setting("application/config/custom_user_dir_name","") != OWN_USER_DIR or OS.get_user_data_dir().get_file() != OWN_USER_DIR:
  _fail("Checkpoint requires the isolated Dungeon Maps directory."); return ""
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
 if not envelope.get("format") is int or envelope.format != 1 or not envelope.get("origin") is String or envelope.origin != OWN_USER_DIR or not envelope.get("payload") is String or not envelope.get("digest") is String: return null
 if envelope.payload.sha256_text() != envelope.digest or parser.parse(envelope.payload) != OK or _canonical(parser.data) != envelope.payload: return null
 var payload = campaign.battle.normalize_json_numbers(parser.data)
 if not payload is Dictionary or payload.size() != 2 or not payload.get("binding") is Dictionary or not payload.has("campaign"): return null
 var candidate = _validated_snapshot(payload.campaign)
 if candidate == null: return null
 var binding: Dictionary = _checkpoint_binding(candidate)
 if _canonical(payload.binding) != _canonical(binding): return null
 return candidate
func save_camp(path: String = OWN_CHECKPOINT) -> bool:
 if campaign.phase != "camp": return _fail("Only CAMP checkpoints are saved; no battle or aftermath serialization.")
 var absolute := _checkpoint_path(path)
 if absolute.is_empty(): return false
 var raw: Dictionary = campaign.snapshot()
 if _validated_snapshot(raw) == null: return _fail("Invalid current campaign; previous checkpoint retained.")
 var payload := _canonical({"campaign":raw,"binding":selected_generation()})
 var text := _canonical({"format":1,"origin":OWN_USER_DIR,"payload":payload,"digest":payload.sha256_text()})
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
func load_camp(path: String = OWN_CHECKPOINT) -> bool:
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

# Stable seed-binding salt: v2 exit bands must not reroll interior architecture.
# Actual geometry recipe/fingerprint comes from generator.RECIPE in packet metadata.
const DUNGEON_RECIPE := "seeded_crypt_v1"
## Private production binding; deliberately not part of public observations.
func dungeon_request(c = null) -> Dictionary:
 if c == null: c = campaign
 var d = c.dungeons
 if not d.active is String or d.active.is_empty() or not d.sites.has(d.active): return {}
 var e: Dictionary = c.encounter
 if not _typed_fields(e,{"kind":TYPE_STRING,"site":TYPE_STRING,"floor":TYPE_INT,"room":TYPE_INT}) or e.kind != "dungeon" or e.site != d.active or e.floor != d.floor_index or e.room != d.room_index: return {}
 var site: Dictionary = d.sites[d.active]
 if d.floor_index < 0 or d.floor_index >= site.floors.size(): return {}
 var floor: Dictionary = site.floors[d.floor_index]
 if d.room_index < 0 or d.room_index >= floor.rooms.size(): return {}
 var room: Dictionary = floor.rooms[d.room_index]
 if not room.get("field") is String or room.field not in DUNGEON_FIELDS or room.roster.is_empty() or room.cleared: return {}
 var key := JSON.stringify([DUNGEON_RECIPE,c.region.seed,d.active,site.seed,floor.index,floor.seed,room.id,room.seed,room.field])
 return {"field":room.field,"seed":int(key.sha256_text().left(8).hex_to_int() & 0x7fffffff)}

const DUNGEON_FIELDS := ["crypt","crypt_barrow","crypt_gallery","crypt_throne","crypt_mound","crypt_garrison","crypt_royal"]
func burial_enter_reason(site: String) -> String:
 var c = campaign
 if not c.overworld.places.has(site) or not c.overworld.discovered(c.overworld.places[site]): return "Select a known dungeon marker."
 # Physical public eligibility precedes fresh site/room truth.
 if c.location != site or not c.overworld.at_site(site): return "Reach the entrance first."
 if not c.dungeons.sites.has(site): return "Select a supported dungeon marker."
 if c.dungeons.sites[site].floors[0].rooms[0].field not in DUNGEON_FIELDS: return "Unsupported dungeon field."
 if c.overworld.pending != "": return "Resolve the pending scout first."
 return c.dungeon_enter_reason(site)
func _burial_context_reason() -> String:
 var c = campaign
 if c.phase != "camp" or c.dungeons.active == "": return "An active dungeon expedition in CAMP is required."
 var site: String = c.dungeons.active
 if c.location != site or not c.overworld.at_site(site): return "Reach the entrance first."
 if not c.overworld.places.has(site) or not c.overworld.discovered(c.overworld.places[site]) or not c.dungeons.sites.has(site): return "Select a known dungeon marker."
 if c.dungeons.room().field not in DUNGEON_FIELDS: return "Unsupported dungeon field."
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
  "down": return "" if room.kind == "stairs" and room.cleared and c.dungeons.floor_index+1 < c.dungeons.sites[c.dungeons.active].floors.size() else "No downward stairs here."
  "inspect_vault", "unlock_vault":
   if target not in c.dungeons.links(c.dungeons.room_index) or not c.dungeons.vault_keys.locked(c.vault_id(target)): return "No locked connecting treasury."
   if action == "unlock_vault" and (c.active_ids().is_empty() or not c.dungeons.vault_keys.records[c.vault_id(target)].held or c.food < c.dungeon_scout_cost()): return "Need the matching key, formed companions and scouting food."
   return ""
 return "Unsupported burial action."
func burial_attack_reason() -> String:
 var reason := _burial_context_reason()
 if reason != "": return reason
 var c = campaign; var e: Dictionary = c.encounter
 if c.over() or c.active_ids().is_empty(): return "A living formed company is required."
 if e.get("kind") != "dungeon" or e.get("site") != c.dungeons.active or e.get("floor") != c.dungeons.floor_index or e.get("room") != c.dungeons.room_index: return "No current supported occupied chamber."
 if c.dungeons.room().cleared or not c.can_deploy(): return "The stock chamber no longer admits deployment."
 return ""

func _generate_dungeon_packet(request: Dictionary) -> Dictionary:
 return load("res://dungeon_maps/generator.gd").generate(request.field,request.seed)
func _dungeon_metadata(packet: Dictionary) -> Dictionary:
 return {"recipe":packet.recipe,"field":packet.field,"fingerprint":packet.fingerprint}
func _checkpoint_binding(c) -> Dictionary:
 if c.encounter.get("kind") == "dungeon":
  var request := dungeon_request(c)
  if request.is_empty(): return {}
  var packet := _generate_dungeon_packet(request)
  if not load("res://dungeon_maps/generator.gd").validate(packet,request.field,request.seed): return {}
  return _dungeon_metadata(packet)
 var contact := _contact_packet(c)
 return _camp_selection(c) if contact.is_empty() else _metadata(contact)
func selected_generation() -> Dictionary:
 if campaign.phase != "camp": return _deployed_generation.duplicate(true)
 return _checkpoint_binding(campaign)
func start_burial_battle() -> bool:
 return start_dungeon_battle()
func start_dungeon_battle() -> bool:
 var reason := burial_attack_reason()
 if reason != "": return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null: return _fail("Invalid current dungeon campaign; unchanged.")
 var request := dungeon_request(candidate)
 if request.is_empty(): return _fail("No current supported occupied chamber; unchanged.")
 # Whole map admission precedes all stock deployment mutations on the detached copy.
 var packet := _generate_dungeon_packet(request)
 if not load("res://dungeon_maps/generator.gd").validate(packet,request.field,request.seed): return _fail("Generated dungeon packet refused; unchanged.")
 var job: Dictionary = candidate.active.duplicate(true)
 var escrow: Dictionary = candidate.economy.escrow.duplicate(true)
 if not candidate.deploy(): return _fail("Stock dungeon deployment refused; unchanged.")
 if candidate.active != job or candidate.economy.escrow != escrow or not candidate.recon.engagement.is_empty() or not _install_burial_field(candidate,packet): return _fail("Generated dungeon installation refused; unchanged.")
 _deployed_map = packet.descriptor.duplicate(true)
 _deployed_generation = _dungeon_metadata(packet)
 campaign = candidate
 return _success()
func _install_burial_field(candidate, packet: Dictionary) -> bool:
 var request := dungeon_request(candidate)
 if request.is_empty(): return false
 return load("res://dungeon_maps/deployment.gd").install(candidate.battle,packet,request.field,request.seed)
