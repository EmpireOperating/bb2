extends "res://integration08/host.gd"
const Identity=preload("res://company_banners/identity.gd")
var company_foundation:Control
var _foundation_campaign
var _foundation_world
var _foundation_prior_focus:Control
func _create_session():
 checkpoint_path="user://integration08-camp.json"
 return load("res://company_banners/session.gd").new()
func _open_company()->void:
 if not session.changed.is_connected(_session_changed):session.changed.connect(_session_changed)
 if not is_instance_valid(world):
  world=load("res://company_banners/world_view.gd").new()
  world.host=self;world.campaign=session.campaign;add_child(world)
 world.set_active(not is_instance_valid(outfitting))
func _foundation_open()->bool:
 return is_instance_valid(company_foundation)
func _foundation_available()->bool:
 if _save_browser_open():return false
 if session==null or session.campaign==null or session.campaign.phase!="camp" or error_panel.visible or aftermath_panel.visible or _loading_failed:return false
 if is_instance_valid(field) or is_instance_valid(_battle_loading) or is_instance_valid(outfitting) or is_instance_valid(_parked_company) or is_instance_valid(_memorial):return false
 if not is_instance_valid(world) or not world.visible or world.process_mode==Node.PROCESS_MODE_DISABLED:return false
 return world._surface() in ["world","sheet:menu"] and not world.intro and not world.help and world.confirmation.is_empty()
func _open_company_foundation(seed:int=0)->void:
 if _foundation_open() or _save_browser_open() or not _foundation_available() or world.blocked():return
 _foundation_campaign=session.campaign;_foundation_world=world
 _foundation_prior_focus=get_viewport().gui_get_focus_owner()
 company_foundation=load("res://company_banners/foundation.gd").new();company_foundation.name="CompanyFoundation"
 _canvas.add_child(company_foundation)
 company_foundation.set_seed(seed if seed>0 else world.fresh_seed())
 company_foundation.cancelled.connect(_cancel_company_foundation.bind(company_foundation))
 company_foundation.submitted.connect(_submit_company_foundation.bind(company_foundation))
 world.refresh()
func _retire_company_foundation()->void:
 if _foundation_open():
  company_foundation.hide();company_foundation.queue_free();company_foundation=null
 _foundation_campaign=null;_foundation_world=null
 if is_instance_valid(_foundation_prior_focus):_foundation_prior_focus.grab_focus()
 _foundation_prior_focus=null
 if is_instance_valid(world):world.refresh()
func _cancel_company_foundation(owner:Control=null)->void:
 if owner!=null and owner!=company_foundation:return
 _retire_company_foundation()
func _submit_company_foundation(company_name:String,banner:String,seed:int,owner:Control)->void:
 if owner!=company_foundation or not _foundation_open() or not _foundation_available() or world!=_foundation_world or session.campaign!=_foundation_campaign:return
 if not session.new_company(seed,company_name,banner):
  company_foundation.error_label.text=session.last_error;return
 _retire_company_foundation();_replace_world()
func _new_company(seed:int)->void:
 _open_company_foundation(seed)
func _load_checkpoint()->void:
 if _foundation_open():return
 super._load_checkpoint()
func _open_outfitting()->void:
 if _foundation_open():return
 super._open_outfitting()
func _deploy()->void:
 if _foundation_open():return
 super._deploy()
func _deploy_camp()->void:
 if _foundation_open():return
 super._deploy_camp()
func _accept_contract(id:String)->void:
 if _foundation_open():return
 super._accept_contract(id)
func _open_save_browser(mode: String = "save") -> void:
 if _foundation_open():return
 super._open_save_browser(mode)
func _unhandled_key_input(event: InputEvent) -> void:
 if _foundation_open():get_viewport().set_input_as_handled();return
 super._unhandled_key_input(event)
func _input(event:InputEvent)->void:
 if _foundation_open():
  if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
   _cancel_company_foundation();get_viewport().set_input_as_handled()
  return
 super._input(event)
func observation()->Dictionary:
 var out:=super.observation()
 out["company_identity"]=session.company_identity if session!=null else Identity.DEFAULT.duplicate()
 out["company_foundation"]=company_foundation.observation() if _foundation_open() else {"open":false,"controls":{},"banner_ids":Identity.IDS.duplicate()}
 return out
