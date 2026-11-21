extends RefCounted
## Presentation only. A literal physically occupied town owns this lifetime.
const UI = preload("res://ui_polish/style.gd")
const Services = preload("res://company_town/town_services.gd")
# Existing resource art plus a painted ammunition cutout.
const RESOURCE_ART = [preload("res://company_town/assets/resources/crowns-32.png"),preload("res://company_town/assets/resources/rations-32.png"),preload("res://company_town/assets/resources/repair-hammers-32.png"),preload("res://company_town/assets/resources/medicine-painted-32.png"),preload("res://company_town/assets/resources/ammunition-painted-32.png")]
var services = Services.new()
var site := ""
var section := "home"
var page := 0
var _texture: Texture2D
var painted := {}
const SERVICES = [["market","Provisions & trade"],["equipment","Arms & armour"],["recruits","Recruitment"],["contracts","Contract board"],["news","News & rumours"],["treatment","Temple care"]]

func open(id: String) -> void:
 services.retire_buy()
 services.sales.reset()
 services.commands.clear(); services.seen_offers.clear(); services.selected_offer=""
 site = id; section = "home"; page = 0
func close() -> void:
 services.retire_buy()
 services.sales.reset()
 services.commands.clear(); services.seen_offers.clear(); services.selected_offer=""
 site = ""; section = "home"; page = 0; painted.clear()
func change_section(id: String) -> void:
 services.retire_buy()
 services.sales.reset()
 services.commands.clear()
 section = id; page = 0
func _payment_available(app, c) -> bool:
 # Passive live-state projection only. Collect still runs the full Session
 # snapshot/funding admission; never reconstruct a whole campaign per paint.
 if not c.has_method("payment_direction") or c.payment_pending.is_empty(): return false
 if not app is Node or app.host==null or app.host.world!=app or app.host.session.campaign!=c: return false
 if c.phase!="camp" or c.over() or c.alive_count()==0 or not c.active.is_empty(): return false
 if not c.encounter.is_empty() or c.overworld.pending!="" or c.dungeons.active!="" or not c.exploration.task.is_empty() or c.traffic.pursuit!="": return false
 var origin: String = c.payment_pending.job.origin
 var ow = c.overworld
 return site==origin and c.location==origin and c.in_town() and ow.paused and ow.path.is_empty() and ow.destination=="" and ow.rest_left==0 and ow.position==ow.places[origin]

func draw(app) -> void:
 painted.clear()
 if _texture == null:
  var image := Image.new()
  if ResourceLoader.exists("res://engraved_world/plates/square.png"):
   _texture = load("res://engraved_world/plates/square.png")
  elif image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://company_town/assets/town_square.png")) == OK:
   _texture = ImageTexture.create_from_image(image)
 var c = app.campaign
 var place: Dictionary = c.node(site)
 app.buttons.clear()
 app.draw_rect(Rect2(0,0,1440,900),UI.BG)
 if _texture != null:
  # Cover rather than stretch; this is decoration, never map authority.
  var source := Rect2(Vector2.ZERO,_texture.get_size())
  var ratio := 1440.0/900.0
  if source.size.x/source.size.y > ratio:
   var width := source.size.y*ratio
   source.position.x = (source.size.x-width)/2.0; source.size.x = width
  else:
   var height := source.size.x/ratio
   source.position.y = (source.size.y-height)/2.0; source.size.y = height
  app.draw_texture_rect_region(_texture,Rect2(0,0,1440,900),source)
 app.draw_rect(Rect2(0,0,1440,188),Color(0.03,0.035,0.04,0.88))
 app.label_at("THE COMPANY ARRIVES  /  SETTLEMENT",Vector2(36,30),12,UI.GOLD)
 app.label_fit(place.name,Vector2(36,78),950,38,UI.TEXT,true)
 app.label_fit(place.description,Vector2(38,114),1030,16,UI.TEXT)
 app.button("company","Company",Rect2(1100,30,146,44))
 app.button("town_leave","Leave · Map",Rect2(1260,30,146,44))
 var state: Dictionary = c.world.towns[site]
 var standing: String="%s · %s (%+d) · %d food in town" % [c.world.faction_name(state.owner),c.attitude(state.owner),c.reputation[state.owner],state.stock]
 if c.economy.freight.enabled:standing+=" · Local renown: %+d" % c.economy.freight.town_renown(site)
 app.label_fit(standing,Vector2(38,169),1300,16,UI.TEXT)
 app.panel(Rect2(24,198,280,474),Color(0.08,0.09,0.1,0.96),UI.LINE)
 app.label_at("AROUND THE SQUARE",Vector2(44,231),12,UI.GOLD)
 var payment_available := _payment_available(app,c)
 for i in SERVICES.size():
  var row: Array = SERVICES[i]
  app.button("town_service_"+row[0],row[1],Rect2(42,250+i*64,244,48),true,section==row[0])
  if row[0]=="contracts" and payment_available:
   app.label_at("!",Vector2(267,473),22,UI.GOLD,true)
 if section != "home":
  app.panel(Rect2(326,198,1090,606),Color(0.07,0.08,0.09,0.97),UI.LINE)
  app.label_at(SERVICES.filter(func(row):return row[0]==section)[0][1],Vector2(354,246),29,UI.TEXT,true)
  app.button("town_home","Return to town",Rect2(1184,217,204,44))
  services.draw(app,self)
 app.panel(Rect2(0,826,1440,74),Color(0.06,0.07,0.08,0.98),UI.LINE)
 var resource_labels := ["%d crowns" % c.crowns,"%d rations" % c.food,"%d tools" % c.tools,"%d medicine" % c.medicine,"%d ammunition" % c.ammunition]
 var x := 36.0
 for i in resource_labels.size():
  if i < RESOURCE_ART.size():
   app.draw_texture_rect(RESOURCE_ART[i],Rect2(x,831,28,28),false)
   x += 32
  app.label_at(resource_labels[i],Vector2(x,856),17,UI.TEXT)
  x += app.font.get_string_size(resource_labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+20
 app.label_fit(app.notice if app.notice_time>0 else "Recovery and repairs continue as overworld time passes; food, medicine and tools still matter.",Vector2(36,885),1360,14,UI.GOLD if app.notice_time>0 else UI.MUTED)
 painted = {"site":site,"section":section,"name":place.name,"description":place.description,"art":_texture.resource_path if _texture != null and not _texture.resource_path.is_empty() else "res://company_town/assets/town_square.png","page":page,"local":true}
