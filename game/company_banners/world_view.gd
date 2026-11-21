extends "res://named_saves/world_view.gd"
var receiving_desk=preload("res://living_roads/receiving_desk.gd").new()
func _ready()->void:
 super._ready()
 var retired=region_camera.canvas
 region_camera.viewport.remove_child(retired);retired.free()
 region_camera.canvas=load("res://company_banners/canvas.gd").new()
 region_camera.canvas.host=self;region_camera.canvas.camera=region_camera
 region_camera.viewport.add_child(region_camera.canvas)
 refresh()
func observation()->Dictionary:
 var out:=super.observation()
 out["company_identity"]=host.session.company_identity
 out["player_banner"]=region_camera.canvas.player_banner_observation()
 return out
func blocked()->bool:
 return (host!=null and host._foundation_open()) or super.blocked()
func action(id:String)->void:
 if id.begins_with("town_manifest_"):
  receiving_desk.dispatch(self,id);return
 if id in ["new","new_top"]:
  if host!=null and visible and not blocked():host._open_company_foundation()
  return
 # The inherited freight handler selects a wagon but, unlike other map targets,
 # never opens its detail leaf. Only disclose it for a visible, enabled map hit.
 if id.begins_with("convoy_"):
  var row:Dictionary=buttons.get(id,{})
  var admitted:bool=world_controls_available() and row.get("map_target",false) and row.get("enabled",false)
  super.action(id)
  if admitted and world_selected=="wagon:"+id.trim_prefix("convoy_"):
   iron.detail=true;refresh()
  return
 super.action(id)
func _draw_world()->void:
 super._draw_world()
 if host!=null and town_is_open() and town.section=="home" and _surface()=="town" and _clear_surface() and campaign.economy.freight.has_method("held_manifests"):
  receiving_desk.draw(self,campaign,town.site,campaign.economy.freight.held_manifests(campaign))
 else:receiving_desk.clear()
 if host==null or not host.session.get("company_identity") is Dictionary or town_is_open():return
 # Add the identity in spare footer space, not over location/resources/time.
 label_fit(host.session.company_identity.name,Vector2(402,870),410,15,GOLD,true)
