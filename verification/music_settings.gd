extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
 if not condition:
  printerr("FAIL: " + message)
  failures += 1

func _initialize() -> void:
 call_deferred("run")

func key(code: int) -> void:
 var event := InputEventKey.new()
 event.pressed = true
 event.keycode = code
 event.physical_keycode = code
 root.push_input(event)

func mount():
 var app = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 root.add_child(app)
 await process_frame
 await process_frame
 return app

func retire(app) -> void:
 app.set_process(false)
 app._road_music.stop()
 app._road_gap.stop()
 await create_timer(0.30).timeout
 app.queue_free()
 await process_frame
 await process_frame

func run() -> void:
 var app = await mount()
 var world = app.world
 world.intro = false
 world.iron.sheet = "menu"
 world.refresh()
 await process_frame
 await process_frame
 check(world.buttons.has("audio_travel") and world.buttons.has("audio_fight"), "campaign Menu paints independently actionable Travel and Fight controls")
 if not world.buttons.has("audio_travel"):
  app.queue_free()
  await process_frame
  quit(1)
  return
 check(app.travel_music_enabled and app.fight_music_enabled, "fresh profile defaults to both on")
 app._sync_road_music()
 check(app._road_track_active and not app._road_music.stream_paused, "approved travel stream plays on camp route")
 world._keyboard_id = "audio_travel"
 key(KEY_ENTER)
 await process_frame
 check(not app.travel_music_enabled and app.fight_music_enabled, "keyboard activation changes only Travel")
 check(not app._road_track_active and not app._road_music.playing and app._road_gap.is_stopped(), "Travel toggle immediately stops current voice and clears pending gap")
 world.action("audio_fight")
 check(not app.travel_music_enabled and not app.fight_music_enabled, "Fight can be muted while Travel is muted")
 world.action("audio_travel")
 check(app.travel_music_enabled and not app.fight_music_enabled and app._road_track_active, "Travel plays independently when Fight is muted")
 await retire(app)
 app = await mount()
 check(app.travel_music_enabled and not app.fight_music_enabled, "fresh host instance loads persistent flags")
 await retire(app)
 print("MUSIC SETTINGS failures=%d" % failures)
 quit(1 if failures else 0)
