extends "res://next_build/main.gd"
const MANUAL_CHECKPOINT := "user://single-body-camp.json"
func _create_save_library():
 return preload("res://named_saves/library.gd").new(MANUAL_CHECKPOINT)
func _create_session():
 checkpoint_path=MANUAL_CHECKPOINT
 return load("res://outdoor_fields/session.gd").new()
func _ready() -> void:
 _load_music_settings()
 super._ready()
 DisplayServer.window_set_title("The Ashen Company — Engraved")
 _setup_battle_music()
 _setup_road_music()

const MUSIC_SETTINGS_PATH := "user://music-settings.cfg"
var travel_music_enabled := true
var fight_music_enabled := true
var music_settings_error := false

func _load_music_settings() -> void:
 var config := ConfigFile.new()
 if config.load(MUSIC_SETTINGS_PATH) != OK:return
 var travel: Variant = config.get_value("music", "travel", true)
 var fight: Variant = config.get_value("music", "fight", true)
 if travel is bool:travel_music_enabled = travel
 if fight is bool:fight_music_enabled = fight

func toggle_music(kind: String) -> void:
 if kind not in ["travel", "fight"]:return
 var travel := not travel_music_enabled if kind == "travel" else travel_music_enabled
 var fight := not fight_music_enabled if kind == "fight" else fight_music_enabled
 var config := ConfigFile.new()
 config.set_value("music", "travel", travel)
 config.set_value("music", "fight", fight)
 var temp := MUSIC_SETTINGS_PATH + ".tmp"
 var written := config.save(temp)
 if written == OK:written = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(MUSIC_SETTINGS_PATH))
 music_settings_error = written != OK
 if music_settings_error:return
 travel_music_enabled = travel
 fight_music_enabled = fight
 _sync_road_music()
 _sync_battle_music()

# Presentation only: one player for the current admitted field, not for each turn.
const MUSIC_GAP_SECONDS := 30.0
var _battle_music: AudioStreamPlayer
var _music_gap: Timer
var _music_field: Node3D

func _setup_battle_music() -> void:
 var track := AudioStreamMP3.load_from_file("res://audio/music/iron-cadence.mp3")
 if track == null:return
 track.loop = false
 _battle_music = AudioStreamPlayer.new()
 _battle_music.name = "BattleMusic"
 _battle_music.bus = &"Music"
 _battle_music.stream = track
 add_child(_battle_music)
 _music_gap = Timer.new()
 _music_gap.name = "BattleMusicGap"
 _music_gap.one_shot = true
 _music_gap.wait_time = MUSIC_GAP_SECONDS
 _music_gap.ignore_time_scale = true
 add_child(_music_gap)
 _battle_music.finished.connect(_begin_music_gap)
 _music_gap.timeout.connect(_replay_battle_music)

func _music_field_is_live() -> bool:
 return not is_instance_valid(_battle_loading) and is_instance_valid(field) and field.is_inside_tree() and not field.is_queued_for_deletion() and field.built and session != null and session.campaign != null and session.campaign.phase == "battle" and field.battle != null and field.battle == session.campaign.battle and field.battle.result.is_empty()

func _process(delta: float) -> void:
 super._process(delta)
 _sync_road_music()
 _sync_battle_music()

func _sync_battle_music() -> void:
 if _battle_music == null:return
 var current: Node3D = field if fight_music_enabled and _music_field_is_live() else null
 if current == _music_field:return
 _battle_music.stop()
 _music_gap.stop()
 _music_field = current
 if _music_field != null:_battle_music.play()

func _begin_music_gap() -> void:
 if fight_music_enabled and _music_field_is_live() and field == _music_field:_music_gap.start()

func _replay_battle_music() -> void:
 if fight_music_enabled and _music_field_is_live() and field == _music_field:_battle_music.play()

# Road music: presentation state belongs to this host.
const ROAD_GAP_SECONDS := 600.0
# Add approved MP3 paths here; the one player takes them in order.
const ROAD_TRACK_PATHS := ["res://audio/music/the-road-unseen.mp3"]
var _road_tracks: Array[AudioStreamMP3] = []
var _road_next_track := 0
var _road_music: AudioStreamPlayer
var _road_gap: Timer
# The mixer can finish before its signal is delivered on the main thread.
var _road_track_active := false

func _setup_road_music() -> void:
 for path: String in ROAD_TRACK_PATHS:
  var track := AudioStreamMP3.load_from_file(path)
  if track == null:continue
  track.loop = false
  _road_tracks.append(track)
 if _road_tracks.is_empty():return
 _road_music = AudioStreamPlayer.new()
 _road_music.name = "RoadMusic"
 _road_music.bus = &"Music"
 _road_music.stream = _road_tracks[0]
 add_child(_road_music)
 _road_gap = Timer.new()
 _road_gap.name = "RoadMusicGap"
 _road_gap.one_shot = true
 _road_gap.wait_time = ROAD_GAP_SECONDS
 _road_gap.ignore_time_scale = true
 _road_gap.process_mode = Node.PROCESS_MODE_ALWAYS
 add_child(_road_gap)
 _road_music.finished.connect(_on_road_track_finished)

func _road_music_eligible() -> bool:
 if _loading_failed or error_panel.visible or aftermath_panel.visible or is_instance_valid(field) or is_instance_valid(_battle_loading):return false
 if _battle_music != null and _battle_music.playing:return false
 if session == null or session.campaign == null or not is_instance_valid(world) or not world.is_inside_tree() or world.is_queued_for_deletion():return false
 var c = session.campaign
 # Camp owns travel, town and non-fighting burial exploration, even while
 # its menus temporarily obscure it. A pending encounter is not normal camp.
 return c.phase == "camp" and world.campaign == c and c.encounter.is_empty() and not c.over()

func _begin_battle_loading(camp_route: bool) -> void:
 # Revoke the road voice before the inherited loader's first await.
 if _road_track_active:_road_music.stream_paused = true
 super._begin_battle_loading(camp_route)

func _sync_road_music() -> void:
 if _road_music == null:return
 if not travel_music_enabled:
  if _road_track_active:
   _road_music.stop()
   _road_music.stream_paused = false
   _road_track_active = false
  if not _road_gap.is_stopped():_road_gap.stop()
  return
 var eligible := _road_music_eligible()
 if _road_track_active:
  if _road_music.stream_paused == eligible:_road_music.stream_paused = not eligible
 elif eligible and _road_gap.is_stopped():
  _road_music.stream = _road_tracks[_road_next_track]
  _road_next_track = (_road_next_track + 1) % _road_tracks.size()
  _road_music.stream_paused = false
  _road_track_active = true
  _road_music.play()

func _on_road_track_finished() -> void:
 _road_track_active = false
 if travel_music_enabled:_road_gap.start()
