extends Node
## One-shot foley from presentation cues, not from action payment or raw popups.
const ROOT:="res://audio/shortbow/"
const GAIN:={"release":-4.0,"body":-4.0,"block":-4.0,"break":-5.0,"pass":-8.0}
const VOICES:=4
static var _wavs:Dictionary={}

func play_cue(cue:String) -> void:
 if not GAIN.has(cue) or get_child_count()>=VOICES:return
 if not _wavs.has(cue):
  var path:=ROOT+cue+".wav"
  if not FileAccess.file_exists(path):return
  var sample:=AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes(path))
  if sample==null:return
  sample.resource_name=cue
  _wavs[cue]=sample
 var voice:=AudioStreamPlayer.new()
 voice.stream=_wavs[cue];voice.volume_db=GAIN[cue]
 add_child(voice)
 voice.finished.connect(voice.queue_free,CONNECT_ONE_SHOT)
 voice.play()
