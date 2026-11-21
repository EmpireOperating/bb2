extends "res://map_visibility/session.gd"
## Selection/persistence only. Inherited Campaign owns deployment and settlement.
const PROCEDURAL_USER_DIR := "ashen-company-procedural-woodland"
const PROCEDURAL_CHECKPOINT := "user://procedural-woodland-camp.json"
const PROCEDURAL_FORMAT := 1
const GENERATED_MAP := "generated_woodland_road"
var generation_seed := 73
var _deployed_generation: Dictionary = {}
var deployed_generation: Dictionary:
 get: return _deployed_generation.duplicate(true)

var _generated_packet: Dictionary = {}
var _deploying := false

func setup(seed: int = 7391) -> void:
 selected_map_id = "ruined_crossing"; generation_seed = 73
 _generated_packet = {}; _deployed_map = {}; _deployed_generation = {}
 super.setup(seed)

func _generator():
 # Do not import/generate at fixed-map startup. The recipe is an optional branch.
 return load("res://procedural_woodland/generator.gd")

func _packet(seed_value: Variant) -> Dictionary:
 if not seed_value is int or seed_value < 0 or seed_value > 2147483647: return {}
 var generator = _generator()
 if generator == null: return {}
 var packet: Dictionary = generator.generate(seed_value)
 if not generator.validate(packet).is_empty() or packet.get("seed") != seed_value or packet.get("recipe") != "woodland_road_v1": return {}
 return packet.duplicate(true)

func select_generated(seed_value: Variant) -> bool:
 if campaign.phase != "camp": return _fail("Choose the next seed in camp.")
 var packet := _packet(seed_value)
 if packet.is_empty(): return _fail("Invalid seed or generated Woodland Road; selection unchanged.")
 _generated_packet = packet
 selected_map_id = GENERATED_MAP; generation_seed = seed_value
 return _success()

func select_map(id: String) -> bool:
 if id == GENERATED_MAP: return select_generated(generation_seed)
 return super.select_map(id)

func selected_generation() -> Dictionary:
 if selected_map_id != GENERATED_MAP or _generated_packet.is_empty(): return {}
 return {"recipe":_generated_packet.recipe,"seed":_generated_packet.seed,"fingerprint":_generated_packet.fingerprint}

func _selected_descriptor() -> Dictionary:
 if selected_map_id != GENERATED_MAP: return super._selected_descriptor()
 var generator = _generator()
 if generator == null or _generated_packet.get("seed") != generation_seed or not generator.validate(_generated_packet).is_empty(): return {}
 return _generated_packet.descriptor.duplicate(true)

func start_battle() -> bool:
 _deploying = true
 var ok := super.start_battle()
 _deploying = false
 return ok

func _success() -> bool:
 # Inherited start_battle emits changed only after its detached Campaign swap.
 # Capture metadata before that signal so passive readers see one publication.
 if _deploying: _deployed_generation = selected_generation()
 return super._success()

func _selection() -> Dictionary:
 return {"map":selected_map_id,"recipe":"woodland_road_v1" if selected_map_id == GENERATED_MAP else "","seed":generation_seed}

func _admit_selection(raw: Variant) -> Dictionary:
 if not raw is Dictionary or raw.size() != 3 or not raw.get("map") is String or not raw.get("recipe") is String or not raw.get("seed") is int: return {}
 if raw.seed < 0 or raw.seed > 2147483647: return {}
 if raw.map == GENERATED_MAP:
  if raw.recipe != "woodland_road_v1": return {}
  var packet := _packet(raw.seed)
  if packet.is_empty(): return {}
  return {"selection":raw.duplicate(true),"packet":packet}
 if raw.recipe != "" or raw.map not in ["ruined_crossing","woodland_road"]: return {}
 if not LargeMaps.validate(LargeMaps.create(raw.map)).is_empty(): return {}
 return {"selection":raw.duplicate(true),"packet":{}}

func _checkpoint_path(path: String) -> String:
 if not ProjectSettings.get_setting("application/config/use_custom_user_dir",false) or ProjectSettings.get_setting("application/config/custom_user_dir_name","") != PROCEDURAL_USER_DIR or OS.get_user_data_dir().get_file() != PROCEDURAL_USER_DIR:
  _fail("Checkpoint requires the isolated Procedural Woodland directory."); return ""
 var pattern := RegEx.new(); pattern.compile("^user://[A-Za-z0-9][A-Za-z0-9_-]{0,63}\\.json$")
 var matched := pattern.search(path)
 if matched == null or matched.get_string() != path:
  _fail("Use a simple user://name.json checkpoint."); return ""
 var directory := DirAccess.open(OS.get_user_data_dir())
 if directory == null or directory.is_link(path.get_file()) or directory.dir_exists(path.get_file()):
  _fail("Checkpoint directory unavailable or target is a link/directory."); return ""
 return ProjectSettings.globalize_path(path)

func _decode_checkpoint(text: String):
 var parser := JSON.new()
 if text.to_utf8_buffer().size() > MAX_SAVE_BYTES or parser.parse(text) != OK: return null
 var envelope = parser.data
 if not envelope is Dictionary or envelope.size() != 4 or _canonical(envelope) != text: return null
 envelope = campaign.battle.normalize_json_numbers(envelope)
 if not envelope.get("format") is int or envelope.format != PROCEDURAL_FORMAT or not envelope.get("origin") is String or envelope.get("origin") != PROCEDURAL_USER_DIR or not envelope.get("payload") is String or not envelope.get("digest") is String: return null
 if envelope.payload.sha256_text() != envelope.digest or parser.parse(envelope.payload) != OK or _canonical(parser.data) != envelope.payload: return null
 var payload = campaign.battle.normalize_json_numbers(parser.data)
 if not payload is Dictionary or payload.size() != 2 or not payload.has("campaign") or not payload.has("selection"): return null
 var admitted := _admit_selection(payload.selection)
 if admitted.is_empty(): return null
 var candidate = _validated_snapshot(payload.campaign)
 if candidate == null: return null
 admitted["campaign"] = candidate
 return admitted

func save_camp(path: String) -> bool:
 if campaign.phase != "camp": return _fail("Only CAMP checkpoints are saved; battle and aftermath are never serialized.")
 var absolute := _checkpoint_path(path)
 if absolute.is_empty(): return false
 var raw: Dictionary = campaign.snapshot()
 if _validated_snapshot(raw) == null or _admit_selection(_selection()).is_empty(): return _fail("Invalid company or battlefield selection; previous checkpoint retained.")
 var payload := _canonical({"campaign":raw,"selection":_selection()})
 var text := _canonical({"format":PROCEDURAL_FORMAT,"origin":PROCEDURAL_USER_DIR,"payload":payload,"digest":payload.sha256_text()})
 if text.to_utf8_buffer().size() > MAX_SAVE_BYTES: return _fail("Checkpoint exceeds bounded size.")
 var temporary := absolute+".pending-"+str(Time.get_ticks_usec())
 var directory := DirAccess.open(OS.get_user_data_dir())
 if directory.is_link(temporary.get_file()) or directory.file_exists(temporary.get_file()) or directory.dir_exists(temporary.get_file()): return _fail("Temporary checkpoint already exists.")
 var file := FileAccess.open(temporary,FileAccess.WRITE)
 if file == null: return _fail("Unable to open temporary checkpoint.")
 file.store_string(text); file.flush()
 var write_error := file.get_error(); file.close()
 if write_error != OK or FileAccess.get_file_as_string(temporary) != text:
  DirAccess.remove_absolute(temporary); return _fail("Checkpoint write failed; previous checkpoint retained.")
 if directory.is_link(absolute.get_file()) or directory.dir_exists(absolute.get_file()) or DirAccess.rename_absolute(temporary,absolute) != OK:
  DirAccess.remove_absolute(temporary); return _fail("Atomic checkpoint replacement failed; previous checkpoint retained.")
 if FileAccess.get_file_as_string(absolute) != text: return _fail("Checkpoint read-back verification failed.")
 last_error = ""
 return true

func load_camp(path: String) -> bool:
 if campaign.phase != "camp": return _fail("Return to camp before loading.")
 var absolute := _checkpoint_path(path)
 if absolute.is_empty(): return false
 var file := FileAccess.open(absolute,FileAccess.READ)
 if file == null: return _fail("Camp checkpoint unavailable.")
 if file.get_length() > MAX_SAVE_BYTES:
  file.close(); return _fail("Checkpoint exceeds bounded size.")
 var text := file.get_as_text(); file.close()
 var admitted = _decode_checkpoint(text)
 if admitted == null: return _fail("Corrupt, incompatible or invalid checkpoint; company and selection unchanged.")
 campaign = admitted.campaign
 selected_map_id = admitted.selection.map
 generation_seed = admitted.selection.seed
 _generated_packet = admitted.packet
 _deployed_map = {}; _deployed_generation = {}
 return _success()
