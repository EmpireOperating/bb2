extends "res://hollow_campaign/world_view.gd"
## Presentation-only successor. Session/domain remain the sole command authority.
const UI = preload("res://ui_polish/style.gd")
const PlayerWorkflows = preload("res://company_town/player_workflows.gd")
const PaintedSkin = preload("res://iron_oath/skin.gd")
var _painting_button := false
var _paint_button_primary := false
var _paint_button_enabled := true
var _paint_button_id := ""
var recovery_page := 0
var _keyboard_id := ""
var _keyboard_paint := false
var _keyboard_surface := ""
var _surface_focus := {}
const TownView = preload("res://company_town/town_view.gd")
var town = TownView.new()
var town_legacy = preload("res://company_town/town_legacy.gd").new()
var _arrival_presence := ""
var _arrival_pending := ""
var _arrival_initialized := false
var _arrival_moving := false
var _arrival_destination := ""
var _overworld_resources: Control
var _town_resources: Control

var _person_details: Panel
var _person_details_sid := -1
var _person_details_campaign
# Transient owner/choices from the last actual progression paint, not save data.
var _progression_paint := {}
const CompanionArt = preload("res://engraved_people/actors.gd")
const COMPANIONS_PER_PAGE := 3
var _companion_page := -1
const StatBreakdown = preload("res://stat_clarity/breakdown.gd")
var stat_hover
const InjuryStatus = preload("res://stat_clarity/injuries.gd")

func injury_status(person: Dictionary) -> Dictionary:
 return InjuryStatus.describe(person)

func _draw_person() -> void:
 if person_offer.is_empty() and (camp_selected < 0 or camp_selected >= campaign.soldiers.size()):return
 super._draw_person()
 if not person_offer.is_empty():return
 var person: Dictionary = campaign.soldiers[camp_selected]
 var status := injury_status(person)
 # Replace only the existing service/vitals box, leaving all stat and action
 # rectangles untouched. Names stay visible even at full (injury-reduced) HP.
 panel(Rect2(140,204,430,140),Color("202e21"))
 label_fit("%d battles · %d kills · %s" % [person.battles,person.kills,"living" if person.alive else "fallen day %d" % person.fallen_day],Vector2(158,229),394,15,PAPER,true)
 label_at("%d / %d HP" % [person.hp,campaign.max_hp(person)],Vector2(158,251),14,MUTED)
 label_fit(status.temporary if person.alive else "Fallen · no active recovery",Vector2(158,273),394,14,RED if status.active else MUTED)
 label_fit("Scars: "+", ".join(status.scars) if not status.scars.is_empty() else "No permanent scars",Vector2(158,293),394,12,GOLD if not status.scars.is_empty() else MUTED)
 if person.alive and campaign.has_method("campaign_mood"):
  var mood: Dictionary = campaign.campaign_mood(person.id)
  label_fit(mood.text,Vector2(158,309),394,13,PAPER)
  _progression_paint["campaign_mood"] = mood.text
 var has_mood: bool = _progression_paint.has("campaign_mood")
 var next: int = Progression.next_xp(person)
 label_at("Next rank: %d / %d XP" % [person.xp,next] if next > 0 else "Maximum rank · service remains recorded",Vector2(158,326 if has_mood else 316),12,GOLD)
 bar(Vector2(158,338 if has_mood else 332),394,person.xp,next if next > 0 else person.xp,BLUE,5)
 _draw_rename_button()

func stat_breakdown(person: Dictionary, attr: String, offer: bool = false) -> Dictionary:
 return StatBreakdown.describe(self,person,attr,offer)
var _rename_dialog: Panel
var _rename_pending := {}
var _rename_paint := {}

func _rename_open() -> bool:
 return is_instance_valid(_rename_dialog) and _rename_dialog.visible

func _rename_owner_current(owner: Dictionary) -> bool:
 if owner.is_empty() or not is_visible_in_tree() or blocked() or host == null or host.session.campaign != campaign: return false
 if campaign != owner.campaign or camp_selected != owner.sid or not person_offer.is_empty() or _surface() not in ["person","person_rename"]: return false
 if campaign.over() or camp_selected < 0 or camp_selected >= campaign.soldiers.size(): return false
 var person: Dictionary = campaign.soldiers[camp_selected]
 return person.alive and is_same(person,owner.person) and person.id == owner.id and person.person_seed == owner.seed and person.companion_roll.person_id == owner.person_id and person.name == owner.name

func _retire_rename() -> void:
 _rename_pending.clear()
 if is_instance_valid(_rename_dialog):
  var focused: Control = get_viewport().gui_get_focus_owner()
  if focused != null and _rename_dialog.is_ancestor_of(focused):focused.release_focus()
  _rename_dialog.hide()

func _sync_rename() -> void:
 if _rename_open() and not _rename_owner_current(_rename_pending):_retire_rename()

func _open_rename() -> void:
 if _surface() != "person" or not _rename_owner_current(_rename_paint) or not buttons.get("person_rename",{}).get("enabled",false): return
 if not is_instance_valid(_rename_dialog):
  _rename_dialog=preload("res://companion_rename/dialog.gd").new()
  add_child(_rename_dialog);_rename_dialog.position=Vector2(440,320);_rename_dialog.size=Vector2(560,236)
  _rename_dialog.save_requested.connect(func():action("person_rename_save"))
  _rename_dialog.cancel_requested.connect(func():action("person_rename_cancel"))
 _rename_pending=_rename_paint.duplicate() # Keep literal person reference, not a copy.
 _rename_dialog.present(_rename_pending.name)
 refresh()

func _submit_rename() -> void:
 if not _rename_owner_current(_rename_pending):_retire_rename();return
 var sid: int = _rename_pending.sid
 var value: String = _rename_dialog.input.text
 var reason: String = campaign.companion_name_reason(value)
 if not reason.is_empty():
  _rename_dialog.error_label.text=reason
  _rename_dialog.error_label.add_theme_color_override("font_color",UI.DANGER)
  _rename_dialog.input.grab_focus()
  return
 _retire_rename() # Consume before synchronous changed/checkpoint listeners.
 host.session.rename_person(sid,value)
 refresh()

func _draw_rename_button() -> void:
 if _surface() != "person" or not person_offer.is_empty() or camp_selected < 0 or camp_selected >= campaign.soldiers.size():return
 var person: Dictionary = campaign.soldiers[camp_selected]
 _rename_paint={"campaign":campaign,"sid":camp_selected,"person":person,"id":person.id,"seed":person.person_seed,"person_id":person.companion_roll.person_id,"name":person.name}
 button("person_rename","Rename",Rect2(1175,146,125,38),_rename_owner_current(_rename_paint))

func _person_details_open() -> bool:
 return is_instance_valid(_person_details) and _person_details.visible

func _person_details_current() -> bool:
 return _person_details_open() and is_visible_in_tree() and not blocked() and campaign == _person_details_campaign and camp_selected == _person_details_sid and person_offer.is_empty() and _surface() == "person_details"

func _retire_person_details() -> void:
 if is_instance_valid(_person_details):
  var focused: Control = get_viewport().gui_get_focus_owner()
  if focused != null and _person_details.is_ancestor_of(focused):focused.release_focus()
  _person_details.hide()
 _person_details_sid = -1;_person_details_campaign = null

func _sync_person_details() -> void:
 if _person_details_open() and not _person_details_current():_retire_person_details()

func _open_person_details() -> void:
 pass # Retired route: only the existing Company Details button owns rarity UI.

func _close_person_details() -> void:
 if not _person_details_current():return
 _retire_person_details()
 _keyboard_surface = "person";_keyboard_id = "person_details"
 _surface_focus["person"] = "person_details"
 refresh()

func set_active(active: bool) -> void:
 if not active:
  if is_instance_valid(stat_hover):stat_hover.retire()
  _retire_rename();_retire_person_details();town.services.retire_market()
 super.set_active(active)

func _notification(what: int) -> void:
 if what==NOTIFICATION_DISABLED and town!=null:town.services.retire_market()

func blocked() -> bool:
 return super.blocked() or (host != null and host.aftermath_panel.visible)

func _town_location() -> String:
 if campaign == null or campaign.phase != "camp" or not campaign.in_town() or not campaign.overworld.path.is_empty() or not campaign.overworld.destination.is_empty(): return ""
 return campaign.location if campaign.overworld.at_site(campaign.location) else ""

func _clear_surface() -> bool:
 return iron.sheet.is_empty() and not vault_journal and not intro and not help and confirmation.is_empty() and not (lineup.opened or perks_view or person_view or armor_view or arms_view or salvage_view or loot_view or service_view or bonds_view or politics_view or trade_view or guide_view or planner_view or record_view or tactics_view or news_view or inspection_view)

func inventory_available() -> bool:
 return visible and not blocked() and _clear_surface()

func town_is_open() -> bool:
 return not town.site.is_empty() and town.site == _town_location() and campaign.encounter.is_empty() and campaign.dungeons.active.is_empty() and not campaign.over()

func company_returns_to_town() -> bool:
 return town_is_open()

func open_current_town() -> bool:
 var local := _town_location()
 if local.is_empty() or not inventory_available() or not campaign.encounter.is_empty() or not campaign.dungeons.active.is_empty() or campaign.over(): return false
 town.open(local); _arrival_presence = local; _arrival_pending = ""
 world_view = true; world_selected = local; iron.detail = false
 refresh(); return true

func close_town() -> void:
 town.close(); _arrival_pending = ""; world_view = true; iron.detail = false; refresh()

func _sync_town_arrival() -> void:
 var local := _town_location()
 var ow=campaign.overworld
 if local.is_empty() and campaign.phase=="camp" and ow.path.is_empty() and ow.destination.is_empty() and known_site(campaign.location) and campaign.node(campaign.location).get("kind")=="camp" and ow.at_site(campaign.location):
  local=campaign.location
 if not _arrival_initialized:
  _arrival_initialized=true; _arrival_pending=_town_location()
 # at_site is a 14-unit eligibility radius, not an arrival event. Observe the
 # existing named route completing at its exact endpoint, including same-town
 # returns. An unnamed route or Stop within that radius cannot invent arrival.
 if not ow.path.is_empty() or not campaign.traffic.follow_wagon.is_empty():
  _arrival_moving=true; _arrival_destination=ow.destination; _arrival_pending=""
 elif _arrival_moving:
  _arrival_moving=false
  if not _arrival_destination.is_empty() and local==_arrival_destination and ow.paused and ow.position==ow.places[local]:
   _arrival_pending=local
  _arrival_destination=""
 _arrival_presence=local
 if not town.site.is_empty() and not town_is_open(): town.close()
 if not local.is_empty() and host != null and host.has_method("_settle_arrived_contract_payment"):
  host._settle_arrived_contract_payment(self)
 if not _arrival_pending.is_empty() and local == _arrival_pending and inventory_available() and world_view and not iron.detail and _surface()=="world" and campaign.encounter.is_empty() and campaign.dungeons.active.is_empty() and not campaign.over():
  if local==_town_location(): open_current_town()
  else:
   _arrival_pending=""; action("iron_here")

func _process(delta: float) -> void:
 town.services.sync_market(self,town)
 _sync_rename();_sync_person_details()
 if not visible or blocked(): return
 _sync_town_arrival()
 super._process(delta)
 _sync_town_arrival()

func known_site(id: String) -> bool:
 # Dungeon rumours do not grant a spatial map target in unexplored terrain.
 if campaign.dungeons.sites.has(id):
  return campaign.overworld.places.has(id) and campaign.overworld.discovered(campaign.overworld.places[id])
 return super.known_site(id)

func rebind(value) -> void:
 if is_instance_valid(stat_hover):stat_hover.retire()
 town.services.retire_market()
 if value != campaign:town.services.reset_market()
 _retire_rename();_rename_paint.clear()
 _retire_person_details()
 if value != campaign:
  _progression_paint.clear(); growth_selection.clear(); perk_choice = ""
 # Session commands publish validated replacement Campaigns. Rebinding that
 # same occupied site is not a new arrival; new/load constructs a new world.
 if not town.site.is_empty() and (value.phase!="camp" or value.location!=town.site or not value.overworld.at_site(town.site)):
  town.close()
 super.rebind(value)
 if campaign.dungeons.sites.has(world_selected) and not known_site(world_selected):
  world_selected = ""; iron.detail = false; refresh()

func world_controls_available() -> bool:
 return not _person_details_open() and not town_is_open() and super.world_controls_available()

func _draw_job_reminder(x: float, y: float) -> void:
 if campaign.has_method("payment_direction") and not campaign.payment_pending.is_empty():
  var job: Dictionary=campaign.payment_pending.job
  label_fit("OBJECTIVE COMPLETE · %d crowns DUE" % job.pay,Vector2(x,y),355,13,GOLD)
  var automatic: bool = campaign.has_method("pays_contracts_on_arrival") and campaign.pays_contracts_on_arrival()
  label_fit("Return to "+campaign.node(job.origin).name+(" · paid on arrival" if automatic else " · Contract Board"),Vector2(x,y+27),355,13,MUTED)
  return
 super._draw_job_reminder(x,y)

func _draw_world() -> void:
 if town_is_open(): town.draw(self)
 else: super._draw_world()


func _ready() -> void:
 stat_hover = preload("res://stat_clarity/hover.gd").new();stat_hover.world = self;add_child(stat_hover)
 # Inside existing chrome, left of the companion count; no map paint changes.
 _overworld_resources = _mount_resource_row("OverworldResources",Rect2(24,20,456,24))
 _town_resources = _mount_resource_row("TownResources",TownView.RESOURCE_ROW)
 iron = load("res://ui_polish/iron_ui.gd").new()
 super._ready()
 visibility_changed.connect(func():
  if not is_visible_in_tree():
   _retire_rename();_retire_person_details();town.services.retire_market())

func _mount_resource_row(id: String, rect: Rect2) -> Control:
 var header = preload("res://resource_header/header.gd").new()
 header.name = id
 header.theme = UI.theme()
 header.position = rect.position
 header.size = rect.size
 header.hide();add_child(header)
 return header

func write_save(show_notice: bool = true) -> bool:
 var ok: bool = super.write_save(show_notice)
 if show_notice and ok: tell("Company saved to the between-battle checkpoint.")
 return ok

func _fitting_navigation_available() -> bool:
 return inventory_available()

func _companion_menu_active() -> bool:
 return is_visible_in_tree() and process_mode != Node.PROCESS_MODE_DISABLED and not blocked() and host != null and host.world == self and host.session.campaign == campaign and not host.aftermath_panel.visible and not is_instance_valid(host.field) and campaign.phase == "camp" and person_offer.is_empty() and not perk_lab_mode

func _draw_companion_switcher(surface: String) -> void:
 var roster: Array = campaign.soldiers.filter(func(person): return person.alive)
 if roster.is_empty(): return
 var page_count := ceili(float(roster.size())/COMPANIONS_PER_PAGE)
 if _companion_page < 0:
  var selected_index := roster.find_custom(func(person): return person.id == camp_selected)
  _companion_page = floori(float(maxi(0,selected_index))/COMPANIONS_PER_PAGE)
 _companion_page = mini(_companion_page,page_count-1)
 var prefix := surface+"_companion_"
 var origin := Vector2(600,174) if surface == "person" else Vector2(828,128)
 label_at("COMPANIONS"+(" · %d / %d" % [_companion_page+1,page_count] if page_count > 1 else ""),origin-Vector2(0,6),11,GOLD)
 var x := origin.x
 var width := 182.0
 if page_count > 1:
  for step in [-1,1]:
   var arrow := prefix+("prev" if step < 0 else "next")
   button(arrow,"‹" if step < 0 else "›",Rect2(origin+Vector2(0 if step < 0 else 532,0),Vector2(30,44)))
   buttons[arrow]["companion_page"] = posmod(_companion_page+step,page_count)
  x += 36; width = 160.0
 var start := _companion_page*COMPANIONS_PER_PAGE
 for i in range(start,mini(start+COMPANIONS_PER_PAGE,roster.size())):
  var person: Dictionary = roster[i]
  var id := prefix+str(person.id)
  var current: bool = person.id == camp_selected
  var rect := Rect2(x,origin.y,width,44)
  button(id,"",rect,true,current)
  buttons[id]["title"] = person.name
  buttons[id]["companion_sid"] = person.id
  var portrait := CompanionArt.portrait(host.session.preview_unit(person.id))
  if portrait != null: draw_texture_rect(portrait,Rect2(rect.position+Vector2(4,4),Vector2(36,36)),false)
  label_fit(person.name,rect.position+Vector2(48,27),width-56,15,GOLD if current else PAPER)
  x += width+6

func _switch_progression_companion(id: String) -> void:
 if not _companion_menu_active() or not _admit_progression(id): return
 var row: Dictionary = buttons[id]
 if row.has("companion_page"):
  _companion_page = row.companion_page
  queue_redraw()
  return
 var sid: int = row.get("companion_sid",-1)
 if sid < 0 or sid >= campaign.soldiers.size() or sid == camp_selected: return
 var person: Dictionary = campaign.soldiers[sid]
 if person.id != sid or not person.alive: return
 growth_selection.clear(); perk_choice = ""; perk_filter = "All"
 super.action("camp_unit_%d" % sid) # Same camp selection and refresh as the existing roster.

func _admit_progression(id: String) -> bool:
 var surface := "person" if id.begins_with("grow_") or id.begins_with("person_companion_") or id in ["person_clear","person_train","person_perks"] else "service" if id.begins_with("learn_") else "perk"
 # A view flag alone is not a painted control. Bind the enabled hit target to
 # its exact current person/offer and keep the existing modal/save fences.
 if _progression_paint.is_empty() or _surface() != surface or _progression_paint.surface != surface: return false
 if _progression_paint.campaign != campaign or _progression_paint.sid != camp_selected or _progression_paint.offer != person_offer: return false
 if id not in _progression_paint.actions or not buttons.get(id,{}).get("enabled",false): return false
 var growth := id.begins_with("grow_") or id == "person_train"
 var paid := id == "person_train" or id == "perk_buy" or id.begins_with("perk_gift_") or id.begins_with("learn_")
 if not growth and not paid: return true # Inspection, filtering and closing.
 if not person_offer.is_empty() or camp_selected < 0 or camp_selected >= campaign.soldiers.size(): return false
 var person: Dictionary = campaign.soldiers[camp_selected]
 if growth and (Progression.pending(person) != _progression_paint.pending or person.training != _progression_paint.training): return false
 if id == "person_train" and growth_selection != _progression_paint.growth: return false
 if paid and (person.perks != _progression_paint.perks or person.get("gifted_choices",[]) != _progression_paint.gifts): return false
 if id == "perk_buy" and perk_choice != _progression_paint.choice: return false
 # Consume before inherited dispatch/save callbacks. A duplicate cannot reuse
 # this paint to train the next pending level or spend another perk point.
 if paid: _progression_paint.actions.erase(id)
 return true

func action(id: String) -> void:
 _sync_rename()
 town.services.sync_market(self,town)
 if not visible or blocked(): return
 # Details is observational. Refuse *all* underlying callbacks, including
 # save/load, progression and world commands, before iron/domain dispatch.
 if _rename_open():
  if id == "person_rename_cancel":_retire_rename();refresh()
  elif id == "person_rename_save":_submit_rename()
  return
 if id in ["person_rename_save","person_rename_cancel"]:return
 if id == "person_rename":_open_rename();return
 if _person_details_open():
  if not _person_details_current():_retire_person_details();return
  if id == "person_details_close":_close_person_details()
  return
 if id in ["person_details","person_details_close"]:return # Retired callbacks are inert.
 if id.begins_with("person_companion_") or id.begins_with("perk_companion_"):
  _switch_progression_companion(id); return
 if id.begins_with("grow_") or id.begins_with("perk_") or id.begins_with("learn_") or id in ["person_clear","person_train","person_perks"]:
  if not _admit_progression(id): return
 # A hidden dungeon has no map hit target; reject direct/stale callbacks too.
 if id.begins_with("place_") and campaign.dungeons.sites.has(id.trim_prefix("place_")) and not known_site(id.trim_prefix("place_")): return
 if id.begins_with("vault_locate_") and not known_site(id.trim_prefix("vault_locate_")): return
 if PlayerWorkflows.editor_route_parked(id,gear_slot): return # Before iron.action can close a sheet.
 if PlayerWorkflows.assembly_sale_parked(campaign,id,salvage_mode,salvage_choice): return
 if id == "salvage_repair" and not _stored_repair_available(): return
 # Programmatic callbacks receive the same top-surface fences as pointer input.
 if not confirmation.is_empty() and id not in ["cancel","confirm"]: return
 if (help or intro) and id!="begin": return
 if town_legacy.consumed.has(id): return
 # Refuse before inherited iron.action can close the current sheet.
 if town_legacy.handles(self,id) and not town_legacy.available(self,id): return
 if id in ["temple","person_hire"] and not town_legacy.admit(self,id): return
 if id=="salvage_close": town_legacy.sale_review.clear(); sale_confirmation=-1
 if id.begins_with("buy_"):
  town.services.action(self,town,"town_buy_"+id.trim_prefix("buy_")); return
 if id.begins_with("hire_"):
  town.services.action(self,town,"town_hire_"+id.trim_prefix("hire_")); return
 if id.begins_with("accept_"):
  town.services.action(self,town,"town_sign_"+id.trim_prefix("accept_")); return
 if id in ["contracts","recruits","resources","iron_supplies","iron_cargo","iron_town_home"]:
  if not inventory_available(): return
  if not town_is_open() and not open_current_town(): return
  town.change_section("contracts" if id=="contracts" else "recruits" if id=="recruits" else "home" if id=="iron_town_home" else "market")
  refresh(); return
 if id.begins_with("place_") and id.trim_prefix("place_")==_town_location():
  open_current_town(); return
 if id == "town_ammunition":
  if town_is_open() and _clear_surface() and _surface()=="town" and buttons.get(id,{}).get("enabled",false):
   town.change_section("market");_keyboard_paint=true;_keyboard_id="town_market_good_ammo";refresh()
  return
 if id in ["town_prev","town_next"]:
  if town_is_open() and _clear_surface():
   _page_town(clampi(town.page+(-1 if id=="town_prev" else 1)*town.services.page_step(town),0,town.services.page_limit(town)))
  return
 if id.begins_with("town_market_") or id.begins_with("town_buy_") or id.begins_with("town_sell_") or id.begins_with("town_hire_") or id.begins_with("town_profile_") or id.begins_with("town_treat_") or id.begins_with("town_sign_") or id.begins_with("town_hear_") or id in ["town_collect_payment","town_tavern_round"]:
  town.services.action(self,town,id); return
 if id == "town_leave":
  if town_is_open() and _clear_surface(): close_town()
  return
 if id == "town_home":
  if town_is_open() and _clear_surface(): town.change_section("home"); refresh()
  return
 if id.begins_with("town_service_"):
  var section := id.trim_prefix("town_service_")
  if town_is_open() and _clear_surface() and TownView.SERVICES.any(func(row):return row[0]==section): town.change_section(section); refresh()
  return
 if id == "iron_here" and not _town_location().is_empty():
  open_current_town(); return
 if id in ["company","loadout","iron_inventory","iron_camp","planner","slot_weapon","slot_shield"]:
  if not inventory_available() or host == null: return
  host._open_outfitting()
  return
 if id == "world_stop":
  _arrival_pending=""; _arrival_moving=false; _arrival_destination=""
 super.action(id)

# Retained adapters are callable directly as well as through action(). Keep
# their paid branches on the same rendered-quote admission path.
func _stored_repair_available() -> bool:
 return visible and not blocked() and _surface() == "salvage"

func salvage_action(id: String) -> bool:
 if PlayerWorkflows.assembly_sale_parked(campaign,id,salvage_mode,salvage_choice): return false
 if id == "salvage_repair" and not _stored_repair_available(): return false
 if town_legacy.consumed.has(id): return false
 if town_legacy.handles(self,id) and not town_legacy.admit(self,id): return false
 return super.salvage_action(id)

func open_armor(group: String, mode: String = "parts") -> void:
 if PlayerWorkflows.LAYERED_ARMOR_PARKED: return
 super.open_armor(group,mode)

func armor_action(id: String) -> bool:
 if PlayerWorkflows.LAYERED_ARMOR_PARKED: return false
 if town_legacy.consumed.has(id): return false
 if town_legacy.handles(self,id) and not town_legacy.admit(self,id): return false
 return super.armor_action(id)

func armory_action(id: String) -> bool:
 if town_legacy.consumed.has(id): return false
 if town_legacy.handles(self,id) and not town_legacy.admit(self,id): return false
 return super.armory_action(id)

# Paint through the inherited observer/admission chain: its literal label points,
# full button titles, geometry and dungeon/contract eligibility remain intact.
func _ink(color: Color) -> Color:
 if color == PAPER: return UI.TEXT
 if color == MUTED: return UI.MUTED
 if color == GOLD: return UI.GOLD
 if color == RED: return UI.DANGER
 if color == BLUE: return UI.BLUE
 return color

func label_at(s: String, p: Vector2, size: int = 16, color: Color = PAPER, display: bool = false) -> void:
 # Replace only the two old map resource labels, not town/Company prose.
 if is_instance_valid(_overworld_resources) and _overworld_resources.visible and p in [Vector2(30,40),Vector2(254,40)]:return
 if person_view and person_offer.is_empty() and p == Vector2(140,151):
  var fit := fitted_text(s,1015,size,display)
  super.label_at(fit.text,p,fit.size,_ink(color),display)
 else:super.label_at(s,p,size,_ink(color),display)

func centered(s: String, p: Vector2, size: int = 16, color: Color = PAPER, display: bool = false) -> void:
 var ink:=_ink(color)
 if _painting_button and not buttons.get(_paint_button_id,{}).get("enabled",_paint_button_enabled):ink=UI.MUTED
 super.centered(s,p,size,ink,display)

func _iron_frame(color: Color) -> StyleBoxTexture:
 var style: StyleBoxTexture
 if _painting_button:
  var admitted: bool = buttons.get(_paint_button_id,{}).get("enabled",_paint_button_enabled)
  style = PaintedSkin.button(_paint_button_primary,color == Color("383632"),not admitted)
 else:
  style = PaintedSkin.panel()
 style.modulate_color.a = color.a
 return style

func panel(rect: Rect2, color: Color = Color("1c1f22"), border: Color = Color("494640")) -> void:
 draw_style_box(_iron_frame(color),rect)
 # Preserve semantic warning/selection edges, but not the old flat fill.
 if border == GOLD or border == UI.GOLD:
  draw_rect(rect.grow(-2),UI.GOLD,false,1)
 elif border == RED or border == UI.DANGER or border.r > border.g*1.3:
  draw_rect(rect.grow(-2),UI.DANGER,false,1)

func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
 # Suppress before inherited paint/target registration, not merely after draw.
 if id == "person_details":return
 if PlayerWorkflows.editor_route_parked(id,gear_slot): enabled = false
 if PlayerWorkflows.assembly_sale_parked(campaign,id,salvage_mode,salvage_choice): enabled = false
 # Let every inherited observer and admission guard run exactly as before.
 var accent: bool = primary and id in ["loadout","plan_rest","confirm","deploy","travel","world_pause","world_speed_1","world_speed_2","world_speed_4"]
 _painting_button = true
 _paint_button_primary = accent or primary # Retain selected nav/speed states on the printed key.
 _paint_button_enabled = enabled
 _paint_button_id = id
 super.button(id,title,rect,enabled,accent)
 town_legacy.capture(self,id,buttons[id].enabled)
 _painting_button = false
 _paint_button_id = ""

func _surface() -> String:
 if not confirmation.is_empty(): return "confirmation"
 if help or intro: return "help"
 if not iron.sheet.is_empty(): return "sheet:"+iron.sheet
 if lineup.opened: return "lineup"
 if news_view: return "news"
 if perks_view: return "perk"
 if salvage_view: return "salvage"
 if guide_view: return "guide"
 if vault_journal: return "vault"
 if planner_view: return "plan"
 if arms_view: return "arms"
 if armor_view: return "arm"
 if person_view: return "person_rename" if _rename_open() else "person_details" if _person_details_open() else "person"
 if bonds_view: return "bond"
 if service_view: return "service"
 if politics_view: return "politics"
 if trade_view: return "trade"
 if record_view: return "record"
 if dungeon_door >= 0: return "door"
 if town_is_open(): return "town"
 return "world" if world_view else "company"

func _surface_accepts(id: String, surface: String) -> bool:
 match surface:
  "person_rename": return false
  "person_details": return false # Real Controls own its focus and scrolling.
  "town": return id.begins_with("town_") or id in ["company","abandon"]
  "confirmation": return id in ["cancel","confirm"]
  "help": return id == "begin"
  "service": return id in ["service_close","history_prev","history_next","person_open","personal_perks"] or id.begins_with("learn_")
  "politics": return id == "politics_close" or id.begins_with("fund_") or id.begins_with("report_")
  "trade": return id in ["trade_close","trade_prev","trade_next"] or id.begins_with("inspect_") or id.begins_with("report_")
  "person": return id.begins_with("person_") or id.begins_with("grow_")
  "arms": return id.begins_with("arms_") or id.begins_with("wa_")
  "door": return id.begins_with("dungeon_choice_") or id == "dungeon_close"
 if surface in ["lineup","news","perk","salvage","guide","vault","plan","arm","bond","record"]: return id.begins_with(surface+"_")
 return true

func _keyboard_actions() -> Array:
 var surface := _surface()
 return buttons.keys().filter(func(id):
  var rect: Rect2 = buttons[id].rect
  return buttons[id].enabled and _surface_accepts(id,surface) and rect.has_area() and Rect2(0,0,1440,900).encloses(rect))

func _sync_keyboard_focus() -> void:
 var surface := _surface()
 var ids := _keyboard_actions()
 if surface != _keyboard_surface:
  _surface_focus[_keyboard_surface] = _keyboard_id
  _keyboard_surface = surface
  _keyboard_id = _surface_focus.get(surface,"")
  if surface == "confirmation": _keyboard_id = "cancel"
 if _keyboard_id not in ids:
  _keyboard_id = str(ids[0]) if not ids.is_empty() else ""

func _draw() -> void:
 if is_instance_valid(_overworld_resources):
  var resource_surface := _surface() if is_visible_in_tree() and can_process() and not blocked() and world_view and _clear_surface() and campaign.dungeons.active.is_empty() else ""
  _overworld_resources.visible = resource_surface == "world"
  _town_resources.visible = resource_surface == "town"
  # Re-project the current campaign on every paint; no cached supply authority.
  if _overworld_resources.visible:_overworld_resources.present(campaign)
  elif _town_resources.visible:_town_resources.present(campaign)
 town.services.sync_market(self,town)
 _sync_rename();_sync_person_details()
 var previous_surface: String = _progression_paint.get("surface","")
 if not _progression_paint.is_empty() and (_progression_paint.campaign != campaign or _progression_paint.sid != camp_selected or _progression_paint.offer != person_offer):
  growth_selection.clear(); perk_choice = "" # Choices never migrate to another person.
  _companion_page = -1
 _progression_paint = {"campaign":campaign,"sid":camp_selected,"offer":person_offer,"surface":"","actions":[]}
 _ui_perk_cards = {}
 town_legacy.quotes.clear(); town_legacy.consumed.clear()
 super._draw()
 if not visible or blocked(): return
 # The retained camp draw returns before the battle-only record branch.
 # Paint the same record owner here, only when it is the top surface.
 if campaign.phase == "camp" and _surface() == "record":
  buttons.clear(); _draw_record()
 if _person_details_open() or _rename_open():return
 var surface := _surface()
 if surface in ["person","perk","service"] and buttons.has("perk_close" if surface == "perk" else "person_close" if surface == "person" else "service_close"):
  if surface != previous_surface: _companion_page = -1
  if surface in ["person","perk"] and _companion_menu_active(): _draw_companion_switcher(surface)
  var person: Dictionary = campaign.soldiers[camp_selected] if person_offer.is_empty() else campaign.recruit_pools[person_offer]
  _progression_paint.merge({
   "surface":surface,
   "actions":buttons.keys().filter(func(id):return buttons[id].enabled and _surface_accepts(id,surface)),
   "pending":-1 if not person_offer.is_empty() else Progression.pending(person),
   "training":person.get("training",[]).duplicate(true),"growth":growth_selection.duplicate(),
   "choice":perk_choice,"perks":person.get("perks",[]).duplicate(),"gifts":person.get("gifted_choices",[]).duplicate()
  },true)
 _sync_keyboard_focus()
 # Registration corners stay INSIDE the focused command, only on keyboard navigation.
 if _keyboard_paint and buttons.has(_keyboard_id) and _surface_accepts(_keyboard_id,surface):
  draw_style_box(UI.Press.focus(),buttons[_keyboard_id].rect.grow(-2))

func _draw_record() -> void:
 # Setup and CAMP restore both initialize a demonstration Battle. Deployment
 # survives CAMP saves, but its battle payload does not; require a retained
 # result in CAMP rather than treating counters or arbitrary log text as play.
 if not campaign.deployment.is_empty() and (campaign.phase != "camp" or not battle.result.is_empty()):
  super._draw_record(); return
 draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.95))
 panel(Rect2(145,90,1150,720),Color("17231b"),GOLD)
 label_at("BATTLE RECORD · NEWEST FIRST",Vector2(180,141),23,PAPER,true)
 button("record_close","CLOSE / ESC",Rect2(1068,115,190,41))
 label_at("No battle record yet" if campaign.deployment.is_empty() else "No retained battle record in this checkpoint.",Vector2(180,202),15,PAPER)
 record_page = 0
 button("record_prev","< NEWER",Rect2(180,738,155,36),false)
 centered("1 / 1 · no retained events",Vector2(720,762),12,GOLD)
 button("record_next","OLDER >",Rect2(1100,738,155,36),false)

func _page_town(next: int) -> void:
 if next==town.page:return
 town.services.retire_market();town.services.commands.clear();town.page=next;refresh()

func _input(event: InputEvent) -> void:
 var market: bool = town.section=="market" and campaign!=null and _surface()=="town"
 if event is InputEventMouseButton or (market and event is InputEventMouseMotion):_keyboard_paint = false
 elif event is InputEventKey and event.pressed and (event.keycode==KEY_TAB or (market and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN])):_keyboard_paint = true
 var had_rename := _rename_open()
 _sync_rename()
 if had_rename:
  if not _rename_open():get_viewport().set_input_as_handled();return
  if event is InputEventKey:
   var key: int = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
   if key in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_TAB]:
    if event.pressed and not event.echo:
     if key == KEY_ESCAPE:action("person_rename_cancel")
     elif key in [KEY_ENTER,KEY_KP_ENTER]:action("person_rename_save")
     else:
      var controls: Array = [_rename_dialog.input,_rename_dialog.save_button,_rename_dialog.cancel_button]
      var at: int = controls.find(get_viewport().gui_get_focus_owner())
      controls[posmod(at+(-1 if event.shift_pressed else 1),controls.size())].grab_focus()
    get_viewport().set_input_as_handled()
  elif event is InputEventMouse and not _rename_dialog.get_global_rect().has_point(event.position):get_viewport().set_input_as_handled()
  return # Only real dialog Controls receive text/pointer; never inherited hotkeys.
 if not visible or blocked(): return
 if _person_details_open():
  if not _person_details_current():
   _retire_person_details();get_viewport().set_input_as_handled();return
  if event is InputEventKey:
   if event.pressed and not event.echo:
    var key: int = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
    var focused: Control = get_viewport().gui_get_focus_owner()
    if key == KEY_ESCAPE:action("person_details_close")
    elif key == KEY_TAB:
     if focused == _person_details.close_button:_person_details.scroll.grab_focus()
     else:_person_details.close_button.grab_focus()
    elif key in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and focused == _person_details.close_button:
     action("person_details_close")
    elif key in [KEY_HOME,KEY_END,KEY_PAGEUP,KEY_PAGEDOWN,KEY_UP,KEY_DOWN]:
     var scroll: ScrollContainer = _person_details.scroll
     if key == KEY_HOME:scroll.scroll_vertical = 0
     elif key == KEY_END:scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
     else:scroll.scroll_vertical += (-1 if key in [KEY_UP,KEY_PAGEUP] else 1)*int(scroll.size.y-40 if key in [KEY_PAGEUP,KEY_PAGEDOWN] else 48)
   get_viewport().set_input_as_handled();return
  # Leave pointer/wheel delivery inside the panel to native GUI scrolling and
  # Close; nothing ever reaches the inherited immediate-mode hit dispatcher.
  if event is InputEventMouse and not _person_details.get_global_rect().has_point(event.position):get_viewport().set_input_as_handled()
  return
 if event is InputEventKey and event.pressed and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed:
  if not event.echo and event.keycode in [KEY_F5,KEY_F9]:
   action("save" if event.keycode==KEY_F5 else "load")
   get_viewport().set_input_as_handled();return
  if _surface()=="town" and not event.echo and event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN,KEY_HOME,KEY_END]:
   var limit: int = town.services.page_limit(town)
   var next: int = 0 if event.keycode==KEY_HOME else limit if event.keycode==KEY_END else clampi(town.page+(-1 if event.keycode==KEY_PAGEUP else 1)*town.services.page_step(town),0,limit)
   _page_town(next); get_viewport().set_input_as_handled(); return
  var scope := _surface()
  if (event.keycode == KEY_I or event.physical_keycode == KEY_I) and campaign.phase == "camp" and scope in ["world","town","company"] and inventory_available():
   if not event.echo:action("company")
   get_viewport().set_input_as_handled();return
  if not event.echo:
   if event.keycode == KEY_ESCAPE and scope != "world" and scope != "company":
    if scope == "sheet:menu" and iron.about:
     iron.about = false; _keyboard_id = "iron_about"; refresh()
    elif scope.begins_with("sheet:"): action("iron_close")
    elif scope == "town": action("town_leave" if town.section == "home" else "town_home")
    elif scope == "help": action("begin")
    elif scope == "confirmation": action("cancel")
    elif scope == "door": action("dungeon_close")
    else: action(scope+"_close")
    get_viewport().set_input_as_handled(); refresh(); return
   var traverse: bool = event.keycode == KEY_TAB or (scope != "world" and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN])
   var activate: bool = event.keycode in [KEY_ENTER,KEY_KP_ENTER] or (scope != "world" and event.keycode == KEY_SPACE)
   if traverse or activate:
    _sync_keyboard_focus()
    var ids := _keyboard_actions()
    if not ids.is_empty():
     if traverse:
      var backwards: bool = event.shift_pressed or event.keycode in [KEY_LEFT,KEY_UP]
      _keyboard_id = str(ids[posmod(ids.find(_keyboard_id)+(-1 if backwards else 1),ids.size())])
     elif _keyboard_id in ids: action(_keyboard_id)
    get_viewport().set_input_as_handled(); refresh(); return
  elif event.keycode in [KEY_TAB,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and scope != "world":
   get_viewport().set_input_as_handled(); return
 if _surface() == "town":
  # Allow passive GUI hover/leave only; the immediate-mode town still owns all
  # buttons and wheels, and no town motion reaches the inherited map input.
  if event is InputEventMouseMotion:return
  if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and Rect2(326,198,1090,606).has_point(event.position):
   _page_town(clampi(town.page+(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1)*town.services.page_step(town,true),0,town.services.page_limit(town)))
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
   for id in buttons:
    if buttons[id].enabled and buttons[id].rect.has_point(event.position): action(id); break
  get_viewport().set_input_as_handled(); return
 super._input(event)

func observation() -> Dictionary:
 var out := super.observation()
 out["town_ui"] = town.painted.duplicate(true) if visible and not blocked() and town_is_open() else {}
 out["menu_ui"] = {"surface":_surface(),"focused":_keyboard_id if visible and not blocked() else "","recovery_page":recovery_page}
 return out

func _draw_camp() -> void:
 # The persistent host workspace owns Company; never rebuild a second hub.
 _draw_world()

func _draw_briefing() -> void:
 buttons.clear()
 draw_rect(Rect2(0,0,1440,900),Color(0.025,0.035,0.03,0.96))
 panel(Rect2(220,108,1000,684),UI.SURFACE,UI.LINE)
 label_at("Controls & rules",Vector2(260,173),34,UI.TEXT,true)
 var rows = [
  ["ON THE ROAD","WASD / drag to pan · wheel to zoom · Home to follow.","Space pauses time · 1 / 2 / 3 set pace · right-click stops travel."],
  ["YOUR COMPANY","I opens Company: equipment, character, perks and formation.","Town services: local trade, recruitment, contracts and temple care."],
  ["IN BATTLE","Select an action, inspect its cost and target, then Execute.","F / Space ends activation · I inspects a companion."],
  ["CHECKPOINTS","Save / F5 creates a manual checkpoint. Nothing auto-saves.","Load rolls back to that checkpoint. Save after returning to keep a battle outcome."]]
 for i in rows.size():
  var y := 239+i*112
  label_at(rows[i][0],Vector2(260,y),13,UI.MUTED)
  label_at(rows[i][1],Vector2(260,y+34),17,UI.TEXT)
  label_at(rows[i][2],Vector2(260,y+64),16,UI.MUTED)
 button("begin","Continue · Esc",Rect2(920,714,260,44),true,true)
