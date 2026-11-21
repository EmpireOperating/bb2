extends SceneTree
var checks := 0
var failures: Array = []
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:failures.append(why);print("FAIL: ",why)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var app = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate();root.add_child(app)
 for i in 5:await process_frame
 check(OS.get_user_data_dir().get_file()=="ashen-company-character-sheet-01","preview isolated from existing next-build saves")
 check(app.checkpoint_path=="user://next-build-camp.json","real unchanged canonical writer filename")
 check(app.saved_ok and not app.error_panel.visible and FileAccess.file_exists(app.checkpoint_path),"real mounted startup atomic write admitted")
 check(app.session.campaign.snapshot().get("generation_policy")==1,"explicit new-generation policy")
 check(app.session.campaign.soldiers.size()==3,"three fresh Companion founders")
 check(app.world.get_script().resource_path=="res://ui_polish/world_view.gd","production mounts composed presenter")
 var file = FileAccess.open("user://preview-namespace.oracle",FileAccess.WRITE)
 file.store_string(JSON.stringify({"user_data":OS.get_user_data_dir(),"checkpoint":ProjectSettings.globalize_path(app.checkpoint_path),"pid":OS.get_process_id()}));file.close()
 app.free()
 for i in 3:await process_frame
 print(JSON.stringify({"test":"candidate_entrypoint","checks":checks,"failures":failures}));quit(int(not failures.is_empty()))
