extends "res://next_build/session.gd"
## Preview-only, separately versioned coordinate profile over retained authority.
const StraightDeployment=preload("res://frontline_ui/deployment.gd")
const CryptGenerator=preload("res://dungeon_maps/generator.gd")
const CryptDeployment=preload("res://dungeon_maps/deployment.gd")
const LEGACY_CRYPT_PENDING := &"validated_seeded_crypt_v2_encounter"
func _valid_field_packet(packet: Dictionary) -> bool:
 return load("res://procedural_woodland/generator.gd").validate(packet)==""
func _install_camp_field(candidate, packet: Dictionary, _spawns: Array) -> bool:
 if not _valid_field_packet(packet):return false
 var d: Dictionary=packet.descriptor
 var positions: Array=StraightDeployment.ambush(candidate,d) if candidate.battle.ambush else StraightDeployment.ordinary(candidate,d,d.spawns[0],d.spawns[6])
 if positions.size()!=24:return false
 # Retain the predecessor's presentation identity fields, not new company IDs.
 for u in candidate.battle.units:
  if u.side==0:u["company_id"]=candidate.deployment[u.id];u["visual_id"]=candidate.deployment[u.id]
  else:u["visual_id"]=12+u.id
 if candidate.battle.ambush:return StraightDeployment.install(candidate.battle,d,positions)
 return _install_ordinary_opening(candidate,d,positions)
func _crypt_recipe(c) -> String:
 # Pin the restored encounter object, not the room ID or age of the company.
 # Leaving/re-entering the same room creates a new encounter object.
 if c.has_meta(LEGACY_CRYPT_PENDING) and is_same(c.get_meta(LEGACY_CRYPT_PENDING),c.encounter):return CryptGenerator.RECIPE
 return CryptGenerator.CANONICAL_RECIPE
func _generate_dungeon_packet(request: Dictionary) -> Dictionary:
 # Actual burial entry derives the request on a validated detached copy;
 # the version choice belongs to the live, already-bound CAMP encounter.
 return CryptGenerator.generate(request.field,request.seed,_crypt_recipe(campaign))
func _checkpoint_binding(c) -> Dictionary:
 if c.encounter.get("kind")!="dungeon":return super._checkpoint_binding(c)
 # Decode also calls this on an independent candidate; do not consult the
 # live company's pin when choosing a recipe for the candidate's binding.
 var request := dungeon_request(c)
 if request.is_empty():return {}
 var packet := CryptGenerator.generate(request.field,request.seed,_crypt_recipe(c))
 return _dungeon_metadata(packet) if CryptGenerator.validate(packet,request.field,request.seed) else {}
func checkpoint_state(text: String) -> Dictionary:
 var state := super.checkpoint_state(text)
 if not state.is_empty():return state
 # The existing parser still owns size, canonical form, origin, digest and
 # company identity. Admit only a whole, reconstructible historical binding.
 var payload := _checkpoint_payload(text)
 if payload.is_empty() or payload.binding.get("recipe")!=CryptGenerator.RECIPE:return {}
 var candidate = _validated_snapshot(payload.campaign)
 if candidate==null:return {}
 var request := dungeon_request(candidate)
 if request.is_empty():return {}
 var packet := CryptGenerator.generate(request.field,request.seed,CryptGenerator.RECIPE)
 if _canonical(payload.binding)!=_canonical(_dungeon_metadata(packet)):return {}
 candidate.set_meta(LEGACY_CRYPT_PENDING,candidate.encounter)
 return {"candidate":candidate,"company_identity":payload.get("company_identity",Identity.DEFAULT).duplicate()}
func _install_burial_field(candidate, packet: Dictionary) -> bool:
 var request: Dictionary=dungeon_request(candidate)
 if request.is_empty() or packet.get("recipe")!=_crypt_recipe(campaign) or not CryptGenerator.validate(packet,request.field,request.seed):return false
 var d: Dictionary=packet.descriptor
 if packet.recipe==CryptGenerator.CANONICAL_RECIPE:
  # These coordinates are part of the ground recipe, not a best-effort move
  # on a finished map. Never dispatch the outdoor legacy opening hook here.
  return StraightDeployment.install(candidate.battle,d,CryptDeployment.canonical_profile(candidate,packet))
 var positions: Array=StraightDeployment.ordinary(candidate,d,Vector2i(4,5)+d.presentation.player_offset,Vector2i(12,5)+d.presentation.enemy_offset)
 return _install_ordinary_opening(candidate,d,positions)
func _install_ordinary_opening(candidate, d: Dictionary, positions: Array) -> bool:
 return StraightDeployment.install(candidate.battle,d,positions)
