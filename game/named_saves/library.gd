extends RefCounted
## Data-only portable CAMP envelope. No resources or code are deserialized.
const FORMAT := 1
const COMPATIBILITY := "ashen-company-camp-v34-v1"
# Only these authored builds share this current supported CAMP schema.
const SUPPORTED_ORIGINS := ["ashen-company-next-build-07","ashen-company-next-build-08","ashen-company-next-build-09"]
const MAX_BYTES := 16777216
var root_path: String
var last_error := ""
# An isolated host supplies its manual checkpoint. Never enumerate the shared
# library or rebind another build's provenance in this mode.
var owned_checkpoint: String
func _init(local_checkpoint: String = "") -> void:
 owned_checkpoint = local_checkpoint
 if not owned_checkpoint.is_empty():
  root_path = ProjectSettings.globalize_path("user://named-saves")
  return
 root_path = OS.get_environment("BB2_SAVE_LIBRARY")
 if root_path.is_empty():root_path = _default_root(OS.get_name()=="Windows")
static func _default_root(windows: bool) -> String:
 var base: String
 if windows:
  base = OS.get_environment("APPDATA")
  if base.is_empty():base = OS.get_data_dir()
  base = base.replace("\\","/")
 else:
  base = OS.get_environment("XDG_DATA_HOME")
  if base.is_empty():base = OS.get_environment("HOME").path_join(".local/share")
 return base.path_join("ashen-company/saves")
func _error(message: String) -> Dictionary:
 last_error=message
 return {"ok":false,"error":message}
func _row(_s, envelope: Dictionary, candidate, text: String, identity: Dictionary) -> Dictionary:
 return {"id":envelope.id,"name":envelope.name,"created":envelope.created,"updated":envelope.updated,"build":envelope.build,"schema":34,"day":candidate.day,"company":"%s · %d companions" % [identity.name,candidate.soldiers.filter(func(p):return p.alive).size()],"location":candidate.node().name,"valid":true,"revision":text.sha256_text(),"compatibility":COMPATIBILITY}
func _decode(s, text: String, id: String) -> Dictionary:
 var parser:=JSON.new()
 if text.to_utf8_buffer().size()>MAX_BYTES or parser.parse(text)!=OK:return _error("Invalid save envelope.")
 var parsed=parser.data
 if not parsed is Dictionary:return _error("Invalid save envelope.")
 var e: Dictionary=s.campaign.battle.normalize_json_numbers(parsed)
 if e.size()!=9 or s._canonical(e)!=text:return _error("Noncanonical save envelope.")
 if not e.get("format") is int or e.format!=FORMAT or not e.get("compatibility") is String or e.compatibility!=COMPATIBILITY:return _error("Incompatible save format/schema.")
 for key in ["id","name","build","checkpoint","digest"]:
  if not e.get(key) is String:return _error("Invalid save metadata.")
 for key in ["created","updated"]:
  if not e.get(key) is int or e[key]<0 or e[key]>4102444800:return _error("Invalid save date.")
 if not name_reason(e.name).is_empty() or e.build.is_empty() or e.build.length()>128:return _error("Invalid save metadata.")
 if not owned_checkpoint.is_empty():
  if e.build!=s.checkpoint_origin():return _error("Save belongs to a different build.")
 elif e.build not in SUPPORTED_ORIGINS:return _error("Unsupported portable source build.")
 if e.id!=id or e.checkpoint.sha256_text()!=e.digest:return _error("Invalid save identity/digest.")
 if parser.parse(e.checkpoint)!=OK or s._canonical(parser.data)!=e.checkpoint:return _error("Invalid source checkpoint.")
 var cp=parser.data
 if not cp is Dictionary or cp.size()!=4 or cp.get("origin")!=e.build or not cp.get("digest") is String or not cp.get("payload") is String:return _error("Invalid source checkpoint.")
 # Rebind only inside the explicitly supported portable envelope. The stored
 # checkpoint and its complete digest remain intact; current validators still
 # validate every campaign field and the generated map binding.
 if owned_checkpoint.is_empty():cp.origin=s.checkpoint_origin()
 var rebound: String=s._canonical(cp)
 var state: Dictionary=s.checkpoint_state(rebound)
 if state.is_empty():return _error("Corrupt or incompatible campaign/map binding/identity.")
 var candidate=state.candidate
 return {"ok":true,"candidate":candidate,"company_identity":state.company_identity,"checkpoint":rebound,"envelope":e,"row":_row(s,e,candidate,text,state.company_identity)}
func name_reason(name: String) -> String:
 if name.strip_edges().is_empty() or name.length()>64:return "Use a name of 1–64 characters."
 for i in name.length():
  if name.unicode_at(i)<32 or name.unicode_at(i)==127 or name[i] in ["/","\\"]:return "Names cannot contain slashes or control characters."
 return ""
func _unique_reason(s, name: String, except_id: String = "") -> String:
 var reason:=name_reason(name)
 if not reason.is_empty():return reason
 for row in entries(s):
  if row.id!=except_id and row.name.strip_edges().nocasecmp_to(name.strip_edges())==0:return "That name already exists. Choose another name or explicitly overwrite the selected save."
 return ""
func create(s, name: String) -> Dictionary:
 return _mutate(func():return _create(s,name))
func _create(s, name: String, id: String = "", created: int = 0, revision: String = "") -> Dictionary:
 if not _safe_root(true):return _error(last_error)
 var reason:=_unique_reason(s,name,id)
 if not reason.is_empty():return _error(reason)
 if s.campaign.phase!="camp":return _error("Return to CAMP before saving. Battles and aftermath are not serialized.")
 var checkpoint: String=s.checkpoint_text()
 if checkpoint.is_empty():return _error("Invalid current campaign, binding or identity; nothing saved.")
 if id.is_empty():id=Crypto.new().generate_random_bytes(16).hex_encode()
 var now:=int(Time.get_unix_time_from_system())
 var e: Dictionary={"format":FORMAT,"compatibility":COMPATIBILITY,"id":id,"name":name,"created":now if created==0 else created,"updated":now,"build":s.checkpoint_origin(),"checkpoint":checkpoint,"digest":checkpoint.sha256_text()}
 var text: String=s._canonical(e)
 var decoded:=_decode(s,text,id)
 if not decoded.ok:return decoded
 var written:=_write(id,text,revision)
 if not written.ok:return written
 last_error=""
 return {"ok":true,"row":decoded.row}
func entries(s) -> Array:
 var rows: Array=[]
 last_error=""
 if not _safe_root(false):return rows
 var dir:=DirAccess.open(root_path)
 if dir==null:return rows
 for filename in dir.get_files():
  var id:=filename.get_basename()
  if filename.get_extension()!="json" or not _valid_id(id):continue
  var result:=_read(s,id)
  if result.ok:rows.append(result.row)
  else:rows.append({"id":id,"name":"Unavailable save · "+id.left(8),"valid":false,"error":result.error,"updated":0,"revision":""})
 rows.sort_custom(func(a,b):return a.updated>b.updated if a.updated!=b.updated else a.id<b.id)
 last_error=""
 return rows
func _read(s, id: String, revision: String = "") -> Dictionary:
 if not _safe_target(id):return _error(last_error)
 var filename:=root_path.path_join(id+".json")
 var file:=FileAccess.open(filename,FileAccess.READ)
 if file==null:return _error("Save unavailable.")
 if file.get_length()>MAX_BYTES:
  file.close();return _error("Save exceeds bounded size.")
 var text:=file.get_as_text();file.close()
 if not revision.is_empty() and revision!=text.sha256_text():return _error("Save changed since selection. Refresh and try again.")
 return _decode(s,text,id)
func load_slot(s, id: String, revision: String = "") -> Dictionary:
 if s.campaign.phase!="camp":return _error("Return to CAMP before loading. Battles and aftermath are not serialized.")
 var result:=_read(s,id,revision)
 if not result.ok:return result
 if not s.restore_checkpoint_text(result.checkpoint):return _error(s.last_error)
 last_error=""
 return {"ok":true,"row":result.row}
func _valid_id(id: String) -> bool:
 return id.length()==32 and id==id.to_lower() and id.is_valid_hex_number(false)
# Return the filesystem anchor followed by normalized ancestor components.
# Windows accepts local drive paths only; never UNC, device or drive-relative paths.
static func _path_parts(path: String, windows: bool) -> PackedStringArray:
 if path.is_empty() or path.contains("\\") or path.simplify_path()!=path:return PackedStringArray()
 var anchor := "/"
 var relative := path.trim_prefix("/")
 if windows:
  if path.length()<4 or path.substr(1,2)!=":/" or not "abcdefghijklmnopqrstuvwxyz".contains(path[0].to_lower()):return PackedStringArray()
  anchor = path.left(3)
  relative = path.substr(3)
 elif not path.begins_with("/") or path.begins_with("//"):return PackedStringArray()
 var parts := PackedStringArray([anchor])
 for component in relative.split("/"):
  if component.is_empty() or component in [".",".."]:return PackedStringArray()
  if windows:
   if component.ends_with(".") or component.ends_with(" "):return PackedStringArray()
   for i in component.length():
    if component.unicode_at(i)<32 or component.unicode_at(i)==127 or component[i] in ["<",">",":","\"","|","?","*"]:return PackedStringArray()
   var device := component.get_slice(".",0).strip_edges().to_upper()
   if device in ["CON","PRN","AUX","NUL","CLOCK$","CONIN$","CONOUT$"]:return PackedStringArray()
   if device.length()==4 and device.left(3) in ["COM","LPT"] and device.right(1) in ["1","2","3","4","5","6","7","8","9","¹","²","³"]:return PackedStringArray()
  parts.append(component)
 return parts
func _safe_root(create_directory: bool) -> bool:
 var parts := _path_parts(root_path,OS.get_name()=="Windows")
 if parts.is_empty():
  _error("Save folder must be an absolute, normalized private directory.");return false
 var current: String=parts[0]
 for component in parts.slice(1):
  var parent:=DirAccess.open(current)
  if parent!=null and (parent.is_link(component) or parent.file_exists(component)):
   _error("Save folder or ancestor is a link/file; refused.");return false
  current=current.path_join(component)
 if create_directory and DirAccess.make_dir_recursive_absolute(root_path)!=OK:
  _error("Cannot create save folder.");return false
 return true
func _safe_target(id: String) -> bool:
 if not _valid_id(id):
  _error("Invalid opaque save identifier.");return false
 if not _safe_root(false):return false
 var dir:=DirAccess.open(root_path)
 if dir==null:
  _error("Save folder unavailable.");return false
 var filename:=id+".json"
 if dir.is_link(filename) or dir.dir_exists(filename):
  _error("Save target is a link/directory; refused.");return false
 return true
func inspect_checkpoint(s, path: String) -> Dictionary:
 if not owned_checkpoint.is_empty() and path!=ProjectSettings.globalize_path(owned_checkpoint):
  return _error("Only this build's own manual checkpoint can be imported.")
 var parts := _path_parts(path,OS.get_name()=="Windows")
 if parts.is_empty():return _error("Choose an absolute checkpoint file.")
 var current: String=parts[0]
 for component in parts.slice(1):
  var parent:=DirAccess.open(current)
  if parent==null or parent.is_link(component):return _error("Checkpoint source or ancestor is a link/unavailable; refused.")
  current=current.path_join(component)
 if DirAccess.dir_exists_absolute(path):return _error("Choose a checkpoint file, not a folder.")
 var file:=FileAccess.open(path,FileAccess.READ)
 if file==null:return _error("Cannot read selected checkpoint.")
 if file.get_length()>s.MAX_SAVE_BYTES:file.close();return _error("Checkpoint exceeds bounded size.")
 var text:=file.get_as_text();file.close()
 var candidate=s._decode_checkpoint(text)
 if candidate==null and not owned_checkpoint.is_empty():return _error("Invalid current-build CAMP checkpoint.")
 if candidate==null:return _error("Only a current Integration08 CAMP checkpoint is directly importable; supported Build07 portability is through named envelopes. Corrupt, battle, ancient or incompatible data was refused.")
 return {"ok":true,"candidate":candidate,"checkpoint":text,"revision":text.sha256_text(),"day":candidate.day,"location":candidate.node().name}
func import_checkpoint(s, path: String, name: String, revision: String) -> Dictionary:
 return _mutate(func():
  if s.campaign.phase!="camp":return _error("Return to CAMP before importing.")
  if revision.is_empty():return _error("Choose and preview a checkpoint before importing.")
  var reason:=_unique_reason(s,name)
  if not reason.is_empty():return _error(reason)
  var source:=inspect_checkpoint(s,path)
  if not source.ok:return source
  if source.revision!=revision:return _error("Selected checkpoint changed since preview; choose it again.")
  var id:=Crypto.new().generate_random_bytes(16).hex_encode()
  var now:=int(Time.get_unix_time_from_system())
  var e: Dictionary={"format":FORMAT,"compatibility":COMPATIBILITY,"id":id,"name":name,"created":now,"updated":now,"build":s.checkpoint_origin(),"checkpoint":source.checkpoint,"digest":source.revision}
  var text: String=s._canonical(e)
  var decoded:=_decode(s,text,id)
  if not decoded.ok:return decoded
  var written:=_write(id,text)
  if not written.ok:return written
  return {"ok":true,"row":decoded.row})
func _mutate(operation: Callable) -> Dictionary:
 if not _safe_root(true):return _error(last_error)
 var lock_path:=root_path.path_join(".write-lock")
 if DirAccess.make_dir_absolute(lock_path)!=OK:return _error("Save library is busy or has an interrupted writer (.write-lock). Close other games; inspect the folder before removing a stale lock.")
 var result: Dictionary=operation.call()
 DirAccess.remove_absolute(lock_path)
 return result
func _revision_matches(path: String, revision: String) -> bool:
 if revision.is_empty():return not FileAccess.file_exists(path)
 var file:=FileAccess.open(path,FileAccess.READ)
 if file==null:return false
 if file.get_length()>MAX_BYTES:file.close();return false
 var text:=file.get_as_text();file.close()
 return text.sha256_text()==revision
func overwrite(s, id: String, revision: String) -> Dictionary:
 return _mutate(func():
  if revision.is_empty():return _error("Select and confirm a save revision before overwriting.")
  var old:=_read(s,id,revision)
  if not old.ok:return old
  return _create(s,old.row.name,id,old.row.created,revision))
func rename_slot(s, id: String, name: String, revision: String) -> Dictionary:
 return _mutate(func():
  if revision.is_empty():return _error("Select a save revision before renaming.")
  var old:=_read(s,id,revision)
  if not old.ok:return old
  var reason:=_unique_reason(s,name,id)
  if not reason.is_empty():return _error(reason)
  var e: Dictionary=old.envelope
  e.name=name;e.updated=int(Time.get_unix_time_from_system())
  var text: String=s._canonical(e)
  var decoded:=_decode(s,text,id)
  if not decoded.ok:return decoded
  var written:=_write(id,text,revision)
  if not written.ok:return written
  return {"ok":true,"row":decoded.row})
func delete_slot(id: String, revision: String) -> Dictionary:
 return _mutate(func():
  if revision.is_empty() or not _safe_target(id):return _error("Select a valid file revision before deleting.")
  var path:=root_path.path_join(id+".json")
  if not _revision_matches(path,revision):return _error("Save changed since selection; nothing deleted.")
  if DirAccess.remove_absolute(path)!=OK or FileAccess.file_exists(path):return _error("Could not delete the selected save.")
  return {"ok":true})
func _write(id: String, text: String, revision: String = "") -> Dictionary:
 if not _safe_target(id):return _error(last_error)
 if text.to_utf8_buffer().size()>MAX_BYTES:return _error("Save exceeds bounded size.")
 var target:=root_path.path_join(id+".json")
 if not _revision_matches(target,revision):return _error("Save changed since selection; unchanged.")
 var pending:=root_path.path_join(".pending-"+Crypto.new().generate_random_bytes(16).hex_encode())
 var file:=FileAccess.open(pending,FileAccess.WRITE)
 if file==null:return _error("Cannot open temporary save.")
 file.store_string(text);file.flush()
 var error:=file.get_error();file.close()
 if error!=OK or FileAccess.get_file_as_string(pending)!=text or not _safe_target(id) or not _revision_matches(target,revision) or DirAccess.rename_absolute(pending,target)!=OK:
  DirAccess.remove_absolute(pending);return _error("Atomic save publication failed; previous files retained.")
 if FileAccess.get_file_as_string(target)!=text:return _error("Save read-back failed.")
 return {"ok":true}
