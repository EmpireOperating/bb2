extends RefCounted
## Private heavy crossbow preview bank. Placement stays silent.
const GAIN := {"release":0.0,"pull":0.0,"body":-1.5,"block":-1.0,"pass":-2.0}
static var _samples:Dictionary={}

static func play(owner:Node3D,cue:String) -> void:
 if not owner.is_visible_in_tree() or not GAIN.has(cue):return
 var node_name:="Crossbow"+cue.capitalize()
 if owner.has_node(NodePath(node_name)):return
 if not _samples.has(cue):
  var path:="res://audio/crossbow/"+cue+".wav"
  var stream:=AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes(path))
  if stream==null:return
  stream.resource_name=cue
  _samples[cue]=stream
 var voice:=AudioStreamPlayer.new()
 voice.name=node_name;voice.stream=_samples[cue];voice.volume_db=GAIN[cue]
 owner.add_child(voice)
 voice.finished.connect(voice.queue_free,CONNECT_ONE_SHOT)
 voice.play()

static func retire_pull(owner:Node3D) -> void:
 var voice:=owner.get_node_or_null("CrossbowPull") as AudioStreamPlayer
 if voice==null:return
 voice.stop();owner.remove_child(voice);voice.queue_free()
