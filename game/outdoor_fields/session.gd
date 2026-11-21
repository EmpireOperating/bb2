extends "res://single_body/session.gd"
const Fields=preload("res://outdoor_fields/generator.gd")
const Stock=preload("res://world_loop/deployment.gd")
const LevelOpening=preload("res://outdoor_fields/level_opening_v1.gd")
const Axis=preload("res://outdoor_fields/axis_layout.gd")
const LEGACY_OPENING := &"outdoor_historical_pending"
func _new_campaign():return preload("res://outdoor_fields/campaign.gd").new()

func _install_camp_field(candidate, packet: Dictionary, spawns: Array) -> bool:
 if not Fields.axial_recipe(packet.get("recipe")):return super._install_camp_field(candidate,packet,spawns)
 if not Fields.valid(packet):return false
 var d: Dictionary=packet.descriptor
 var positions:=Axis.positions(candidate,d)
 if positions.size()!=24:return false
 for u: Dictionary in candidate.battle.units:
  if u.side==0:u["company_id"]=candidate.deployment[u.id];u["visual_id"]=candidate.deployment[u.id]
  else:u["visual_id"]=12+u.id
 return super._install_ordinary_opening(candidate,d,positions)

func _install_ordinary_opening(candidate,d:Dictionary,positions:Array) -> bool:
 if d.presentation.has("opening_axis"):return super._install_ordinary_opening(candidate,d,positions)
 # Older CAMP saves without local fields keep their legacy deployment as well
 # as the exact geometry/encounter binding. Ambush never enters this hook.
 var plan := LevelOpening.choose(candidate,d,positions) if candidate.local_fields else {}
 if plan.is_empty():return super._install_ordinary_opening(candidate,d,positions)
 if not super._install_ordinary_opening(candidate,d,plan.positions):return false
 if plan.player_shift!=Vector2i.ZERO:
  candidate.battle.set_meta(LevelOpening.CAMERA_SHIFT_META,plan.player_shift)
 return true

func _camp_packet(c,site:String) -> Dictionary:
 return _camp_packet_for(c,site,_admitting_recipe(c) if site==c.location else "")

func _camp_packet_for(c,site:String,recipe:String) -> Dictionary:
 if recipe==Fields.LEGACY_VERSION and not c.local_fields:return super._camp_packet(c,site)
 var ground:String=c.overworld.terrain(c.overworld.places[site])
 var role:String=c.world.camp_role(site)
 # The river district is the western constituent only. Other Fords (including
 # legacy geography) keep their ordinary river recipe.
 if site=="ford" and c.region.get("river_district")==1:
  role=["stone_span","reed_shoal","spring_cut"][posmod(c.region.seed,3)]
 return _local_packet(c,role,ground,c.overworld.cell(c.overworld.places[site]),"camp",site,site,c.world.camps[site].generation,false,recipe)

func _contact_packet(c) -> Dictionary:
 return _contact_packet_for(c,_admitting_recipe(c))

func _contact_packet_for(c,recipe:String) -> Dictionary:
 if recipe==Fields.LEGACY_VERSION and not c.local_fields:return super._contact_packet(c)
 if c.encounter.get("kind")!="scout":return {}
 # The company's contact cell is authoritative, NOT the band's home camp.
 var ow=c.overworld;var ground:String=ow.terrain(ow.position);var e:Dictionary=c.encounter
 var role:String={"bridge":"ford","water":"ford","forest":"forest","hills":"ridge","mountains":"ridge"}.get(ground,"plains")
 return _local_packet(c,role,ground,ow.cell(ow.position),"scout",e.site,e.id,e.generation,c.bandits.bands[e.id].mode=="hunting",recipe)

func _local_packet(c,role:String,ground:String,cell:Vector2i,kind:String,site:String,id:String,generation:int,ambush:bool,recipe:String) -> Dictionary:
 # Geography/encounter seed inputs stay the same across terrain recipes.
 var key:=JSON.stringify([Fields.LEGACY_VERSION,c.seed_value,c.region.seed,kind,site,id,generation,cell.x,cell.y,ground,role,ambush])
 var n:=key.sha256_text().left(8).hex_to_int() & 0x7fffffff
 if recipe.is_empty():recipe=Fields.VERSION if Fields.composed_family(role) and not ambush else Fields.AXIS_VERSION
 return Fields.generate(n,role,ground in ["road","bridge"],ambush,recipe)

func _outdoor_scope(c) -> Array:
 # A visit, not a permanent company/site version. A fresh Overworld tick or
 # new encounter cannot silently reuse the old map even at the same camp.
 return [c.seed_value,c.region.seed,c.encounters,c.day,c.overworld.hour,c.overworld.position,c.overworld.pending,c.location,c.active.get("id"),c.active.get("generation"),c.encounter.get("id"),c.encounter.get("generation")]

func _historical_recipe(c) -> String:
 if not c.has_meta(LEGACY_OPENING):return ""
 var pin: Dictionary = c.get_meta(LEGACY_OPENING)
 if c.phase=="camp" and pin.scope==_outdoor_scope(c) and is_same(pin.job,c.active) and is_same(pin.encounter,c.encounter):return pin.recipe
 return ""

func _admitting_recipe(c) -> String:
 # All three actual outdoor entrances generate on a detached validated copy
 # before stock deploy. Only the exact current visit can inherit its pin.
 var recipe := _historical_recipe(campaign)
 return recipe if not recipe.is_empty() and _outdoor_scope(c)==_outdoor_scope(campaign) else ""

func _checkpoint_binding(c) -> Dictionary:
 if c.encounter.get("kind")=="dungeon":return super._checkpoint_binding(c)
 return _outdoor_binding(c,_historical_recipe(c))

func _outdoor_binding(c,recipe:String) -> Dictionary:
 # Pure: inspecting a named save cannot consult the live company's pin.
 var contact := _contact_packet_for(c,recipe)
 if not contact.is_empty():return _metadata(contact)
 if not c.active.is_empty():
  if _contract_reason(c)!="":return {}
 elif _camp_reason(c,c.location)!="":return {}
 return _camp_metadata(_camp_packet_for(c,c.location,recipe))

func checkpoint_state(text:String) -> Dictionary:
 var state := super.checkpoint_state(text)
 if not state.is_empty():return state
 var payload := _checkpoint_payload(text)
 if payload.is_empty() or not payload.binding.get("recipe") is String:return {}
 var recipe: String = payload.binding.recipe
 var version := Fields.LEGACY_VERSION
 var parts := recipe.split("/")
 var local := parts.size()==3 and parts[1] in ["camp","scout"]
 if local and parts[0]==Fields.AXIS_VERSION and Fields.composed_family(parts[2]):
  version=Fields.AXIS_VERSION
 elif not (local and parts[0]==Fields.LEGACY_VERSION):
  if recipe not in ["woodland_camp_v1/woodland_road_v1","woodland_contact_v1/woodland_road_v1"]:return {}
  local=false
 var c = _validated_snapshot(payload.campaign)
 if c==null or c.local_fields!=local or c.encounter.get("kind")=="dungeon":return {}
 var rebuilt := _outdoor_binding(c,version)
 if rebuilt.is_empty() or _canonical(payload.binding)!=_canonical(rebuilt):return {}
 c.set_meta(LEGACY_OPENING,{"scope":_outdoor_scope(c),"job":c.active,"encounter":c.encounter,"recipe":version})
 return {"candidate":c,"company_identity":payload.get("company_identity",Identity.DEFAULT).duplicate()}

func _valid_field_packet(packet:Dictionary) -> bool:
 if packet.get("recipe") in Fields.RECIPES:return Fields.valid(packet)
 return super._valid_field_packet(packet)
func _outdoor_spawns(packet:Dictionary) -> Array:
 if packet.get("recipe") not in Fields.RECIPES:return super._outdoor_spawns(packet)
 if not Fields.valid(packet):return []
 if Fields.axial_recipe(packet.recipe):
  var reserved:=Axis.reserved(packet.descriptor)
  if packet.ambush:return reserved
  return reserved.slice(0,12)+reserved.slice(18)
 return Stock.from_descriptor(packet.descriptor)
func _camp_metadata(packet:Dictionary) -> Dictionary:
 if packet.is_empty():return {}
 if packet.get("recipe") not in Fields.RECIPES:return super._camp_metadata(packet)
 return Fields.binding(packet,"camp")
func _metadata(packet:Dictionary) -> Dictionary:
 if packet.get("recipe") not in Fields.RECIPES:return super._metadata(packet)
 return Fields.binding(packet,"scout")
