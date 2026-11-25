extends "res://single_body/session.gd"
const Fields=preload("res://outdoor_fields/generator.gd")
const Stock=preload("res://world_loop/deployment.gd")
const LevelOpening=preload("res://outdoor_fields/level_opening_v1.gd")
const Axis=preload("res://outdoor_fields/axis_layout.gd")
const Layout=preload("res://outdoor_fields/layout_composer.gd")
const Forge = preload("res://layer_forge/rules.gd")
const LEGACY_OPENING := &"outdoor_historical_pending"
const PRE_WORK_CRYPT := &"crypt_historical_work_pending"
func _new_campaign():return preload("res://outdoor_fields/campaign.gd").new()
func checkpoint_origin() -> String:
 if campaign.forge_enabled(): return Forge.PROFILE
 return campaign.Catalog.LAB_PROFILE if campaign.armor_lab_enabled() else super.checkpoint_origin()

func _install_camp_field(candidate, packet: Dictionary, spawns: Array) -> bool:
 if not Fields.axial_recipe(packet.get("recipe")):return super._install_camp_field(candidate,packet,spawns)
 if not Fields.valid(packet):return false
 var d: Dictionary=packet.descriptor
 var positions:=Axis.positions(candidate,d)
 if positions.size()!=24:return false
 for u: Dictionary in candidate.battle.units:
  if u.side==0:u["company_id"]=candidate.deployment[u.id];u["visual_id"]=candidate.deployment[u.id]
  else:u["visual_id"]=12+u.id
 if not super._install_ordinary_opening(candidate,d,positions):return false
 # This is the detached Battle of an already validated packet. Leave the
 # canonical descriptor, recipe and fingerprint used by CAMP IO alone.
 var geometry: String=Fields.geometry_recipe(packet.recipe)
 if geometry==Fields.FOREST_CAMP_VERSION:
  var work := Layout.broken_gate_work_cells(packet.seed)
  if not candidate.battle.configure_terrain_work(work):return false
  candidate.battle.configure_broken_gate_defense(Layout.FOREST_CAMP_CENTER,work.stone)
 elif geometry==Fields.FORT_CAMP_VERSION:
  var weak_cell := Fields.FortLayouts.work_cell(d)
  if weak_cell==Fields.FortLayouts.NO_WORK_CELL:return false
  var kind := "plank" if d.presentation.landmark==Fields.FortLayouts.TIMBER else "wall"
  if not candidate.battle.configure_fort_terrain_work(weak_cell,kind):return false
 if Fields.WORK_RECIPES.has(packet.recipe):
  return _enroll_structures(candidate.battle,d,"plank" if d.presentation.get("landmark")==Fields.FortLayouts.TIMBER else "wall")
 return true

func _enroll_structures(battle,d:Dictionary,wall_kind:String,interior:bool=false) -> bool:
 var cells := {}
 for key: String in d.tiles:
  var tile: Dictionary=d.tiles[key]
  if not tile.get("blocked",false) or not tile.get("vision_blocking",false):continue
  var obstacle: String=tile.get("obstacle","")
  if obstacle not in ["tree","wall"]:continue
  var cell := Vector2i(int(key.get_slice(",",0)),int(key.get_slice(",",1)))
  # Crypt rings and exits are architecture, not optional interior partitions.
  if interior and (cell.x<=0 or cell.y<=0 or cell.x>=d.width-1 or cell.y>=d.height-1 or tile.has("escape_side")):continue
  cells[cell]="wood" if obstacle=="tree" else wall_kind
 return battle.configure_structural_terrain_work(cells)

func _crypt_recipe(c) -> String:
 var recipe := super._crypt_recipe(c)
 if recipe!=CryptGenerator.CANONICAL_RECIPE:return recipe
 if c.has_meta(PRE_WORK_CRYPT) and is_same(c.get_meta(PRE_WORK_CRYPT),c.encounter):return recipe
 return CryptGenerator.WORK_RECIPE

func _install_burial_field(candidate,packet:Dictionary) -> bool:
 if packet.get("recipe")!=CryptGenerator.WORK_RECIPE:return super._install_burial_field(candidate,packet)
 var request := dungeon_request(candidate)
 if request.is_empty() or packet.recipe!=_crypt_recipe(campaign) or not CryptGenerator.validate(packet,request.field,request.seed):return false
 var d: Dictionary=packet.descriptor
 return StraightDeployment.install(candidate.battle,d,CryptDeployment.canonical_profile(candidate,packet)) and _enroll_structures(candidate.battle,d,"wall",true)

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
 var forest_camp := kind=="camp" and site=="forest" and role=="forest" and not ambush
 var fort_camp := kind=="camp" and not ambush and _fort_assault(c,site,role)
 if Fields.geometry_recipe(recipe)==Fields.FOREST_CAMP_VERSION and not forest_camp:return {}
 if Fields.geometry_recipe(recipe)==Fields.FORT_CAMP_VERSION and not fort_camp:return {}
 if recipe.is_empty():
  if forest_camp:recipe=Fields.FOREST_CAMP_VERSION
  elif fort_camp:recipe=Fields.FORT_CAMP_VERSION
  else:recipe=Fields.VERSION if Fields.composed_family(role) and not ambush else Fields.AXIS_VERSION
  recipe=Fields.WORK_RECIPES.find_key(recipe)
 return Fields.generate(n,role,ground in ["road","bridge"],ambush,recipe)

func _fort_assault(c, site: String, family: String) -> bool:
 # These are the two existing expanded-region sites, not biome-wide rules
 # and not paid jobs or any kind of roaming contact from those same camps.
 return c.active.is_empty() and ((site=="wild_0" and family=="forest") or (site=="wild_1" and family=="ridge"))

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
 if recipe==CryptGenerator.CANONICAL_RECIPE:
  var candidate = _validated_snapshot(payload.campaign)
  if candidate==null:return {}
  var request := dungeon_request(candidate)
  if request.is_empty():return {}
  var packet := CryptGenerator.generate(request.field,request.seed,recipe)
  if _canonical(payload.binding)!=_canonical(_dungeon_metadata(packet)):return {}
  candidate.set_meta(PRE_WORK_CRYPT,candidate.encounter)
  return {"candidate":candidate,"company_identity":payload.get("company_identity",Identity.DEFAULT).duplicate()}
 var version := Fields.LEGACY_VERSION
 var parts := recipe.split("/")
 var local := parts.size()==3 and parts[1] in ["camp","scout"]
 var composed_camp := local and parts[0]==Fields.VERSION and parts[1]=="camp" and Fields.composed_family(parts[2])
 if composed_camp:
  version=Fields.VERSION
 elif local and parts[0] in [Fields.AXIS_VERSION,Fields.VERSION,Fields.FOREST_CAMP_VERSION,Fields.FORT_CAMP_VERSION]:
  version=parts[0]
 elif not (local and parts[0]==Fields.LEGACY_VERSION):
  if recipe not in ["woodland_camp_v1/woodland_road_v1","woodland_contact_v1/woodland_road_v1"]:return {}
  local=false
 var c = _validated_snapshot(payload.campaign)
 if c==null or c.local_fields!=local or c.encounter.get("kind")=="dungeon":return {}
 # Before structural work, ordinary v3 camps also wrote the bare v3 binding.
 # Outside the previously admitted superseded sites, require that the normal
 # current route resolves to the same v3 geometry through the new work alias.
 if composed_camp and not (c.location=="forest" and parts[2]=="forest") and not _fort_assault(c,c.location,parts[2]):
  var ordinary := _outdoor_binding(c,"")
  var work_version: String=Fields.WORK_RECIPES.find_key(Fields.VERSION)
  if ordinary.get("recipe")!=work_version+"/camp/"+parts[2]:return {}
 var rebuilt := _outdoor_binding(c,version)
 if rebuilt.is_empty() or _canonical(payload.binding)!=_canonical(rebuilt):return {}
 c.set_meta(LEGACY_OPENING,{"scope":_outdoor_scope(c),"job":c.active,"encounter":c.encounter,"recipe":version})
 return {"candidate":c,"company_identity":payload.get("company_identity",Identity.DEFAULT).duplicate()}

func _valid_field_packet(packet:Dictionary) -> bool:
 if Fields.supported_recipe(packet.get("recipe")):return Fields.valid(packet)
 return super._valid_field_packet(packet)
func _outdoor_spawns(packet:Dictionary) -> Array:
 if not Fields.supported_recipe(packet.get("recipe")):return super._outdoor_spawns(packet)
 if not Fields.valid(packet):return []
 if Fields.axial_recipe(packet.recipe):
  var reserved:=Axis.reserved(packet.descriptor)
  if packet.ambush:return reserved
  return reserved.slice(0,12)+reserved.slice(18)
 return Stock.from_descriptor(packet.descriptor)
func _camp_metadata(packet:Dictionary) -> Dictionary:
 if packet.is_empty():return {}
 if not Fields.supported_recipe(packet.get("recipe")):return super._camp_metadata(packet)
 return Fields.binding(packet,"camp")
func _metadata(packet:Dictionary) -> Dictionary:
 if not Fields.supported_recipe(packet.get("recipe")):return super._metadata(packet)
 return Fields.binding(packet,"scout")
