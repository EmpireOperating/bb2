extends "res://contract_pay/session.gd"
## Canonical current-domain IO, with optional digest-covered company identity.
## No donor Campaign or obsolete filesystem/origin implementation is inherited.
const Identity = preload("res://company_banners/identity.gd")
var _identity: Dictionary = Identity.DEFAULT.duplicate()
var company_identity: Dictionary:
 get:return _identity.duplicate()
func checkpoint_origin() -> String:
 return "ashen-company-next-build-09"
func setup(seed: int = 7391) -> void:
 _identity=Identity.DEFAULT.duplicate()
 super.setup(seed)
func new_company(seed: int, company_name: String, banner: String) -> bool:
 if campaign.phase!="camp" or seed<=0 or seed>2147483646:return _fail("A world seed from 1 to 2147483646 and CAMP are required.")
 var reason := Identity.name_error(company_name)
 if not reason.is_empty():return _fail(reason)
 if banner not in Identity.IDS:return _fail("Choose one of the six company banners.")
 _identity={"name":company_name.strip_edges(),"banner":banner}
 super.setup(seed)
 return true
func _checkpoint_payload(text: String) -> Dictionary:
 var parser := JSON.new()
 if text.to_utf8_buffer().size()>MAX_SAVE_BYTES or parser.parse(text)!=OK:return {}
 var envelope=parser.data
 if not envelope is Dictionary or envelope.size()!=4 or _canonical(envelope)!=text:return {}
 envelope=campaign.battle.normalize_json_numbers(envelope)
 if not envelope.get("format") is int or envelope.format!=1 or not envelope.get("origin") is String or envelope.origin!=checkpoint_origin() or not envelope.get("payload") is String or not envelope.get("digest") is String:return {}
 if envelope.payload.sha256_text()!=envelope.digest or parser.parse(envelope.payload)!=OK or _canonical(parser.data)!=envelope.payload:return {}
 var payload=campaign.battle.normalize_json_numbers(parser.data)
 if not payload is Dictionary or payload.size()!=(3 if payload.has("company_identity") else 2) or not payload.get("binding") is Dictionary or not payload.has("campaign"):return {}
 if payload.has("company_identity") and not Identity.valid(payload.company_identity):return {}
 return payload
func checkpoint_state(text: String) -> Dictionary:
 # Pure decode: callers may inspect/preview without replacing either authority.
 var payload := _checkpoint_payload(text)
 if payload.is_empty():return {}
 var candidate=_validated_snapshot(payload.campaign)
 if candidate==null or _canonical(payload.binding)!=_canonical(_checkpoint_binding(candidate)):return {}
 return {"candidate":candidate,"company_identity":payload.get("company_identity",Identity.DEFAULT).duplicate()}
func _decode_checkpoint(text: String):
 return checkpoint_state(text).get("candidate")
func checkpoint_text() -> String:
 if campaign.phase!="camp" or not Identity.valid(_identity):return ""
 var raw: Dictionary=campaign.snapshot()
 if _validated_snapshot(raw)==null:return ""
 var payload: String=_canonical({"campaign":raw,"binding":selected_generation(),"company_identity":_identity})
 var text: String=_canonical({"format":1,"origin":checkpoint_origin(),"payload":payload,"digest":payload.sha256_text()})
 return text if not checkpoint_state(text).is_empty() else ""
func restore_checkpoint_text(text: String) -> bool:
 # Publish the validated pair silently. The host owns presentation replacement;
 # ordinary load emits changed only after both objects have been committed.
 if campaign.phase!="camp":return _fail("Return to CAMP before loading.")
 var state := checkpoint_state(text)
 if state.is_empty():return _fail("Corrupt, incompatible or invalid checkpoint; company unchanged.")
 _identity=state.company_identity.duplicate()
 campaign=state.candidate;_deployed_map={};_deployed_generation={};last_error=""
 return true
func save_camp(path: String = "user://integration09-camp.json") -> bool:
 if campaign.phase != "camp": return _fail("Only CAMP checkpoints are saved; no battle or aftermath serialization.")
 var absolute := _checkpoint_path(path)
 if absolute.is_empty(): return false
 var text := checkpoint_text()
 if text.is_empty(): return _fail("Invalid current campaign, binding or identity; previous checkpoint retained.")
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
func load_camp(path: String = "user://integration09-camp.json") -> bool:
 if campaign.phase != "camp": return _fail("Return to CAMP before loading.")
 var absolute := _checkpoint_path(path)
 if absolute.is_empty(): return false
 var file := FileAccess.open(absolute,FileAccess.READ)
 if file == null: return _fail("CAMP checkpoint unavailable.")
 if file.get_length() > MAX_SAVE_BYTES:
  file.close(); return _fail("Checkpoint exceeds bounded size.")
 var text := file.get_as_text(); file.close()
 if not restore_checkpoint_text(text): return false
 return _success()
