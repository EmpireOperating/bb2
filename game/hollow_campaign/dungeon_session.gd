extends "res://burial_ruins/session.gd"
## Geometry/request/action adapter only; canonical IO stays in the Hollow origin.
const DUNGEON_RECIPE := "seeded_crypt_v1"
## Private production binding; deliberately not part of public observations.
func dungeon_request(c = null) -> Dictionary:
 if c == null: c = campaign
 var d = c.dungeons
 if not d.active is String or d.active.is_empty() or not d.sites.has(d.active): return {}
 var e: Dictionary = c.encounter
 if not _typed_fields(e,{"kind":TYPE_STRING,"site":TYPE_STRING,"floor":TYPE_INT,"room":TYPE_INT}) or e.kind != "dungeon" or e.site != d.active or e.floor != d.floor_index or e.room != d.room_index: return {}
 var site: Dictionary = d.sites[d.active]
 if d.floor_index < 0 or d.floor_index >= site.floors.size(): return {}
 var floor: Dictionary = site.floors[d.floor_index]
 if d.room_index < 0 or d.room_index >= floor.rooms.size(): return {}
 var room: Dictionary = floor.rooms[d.room_index]
 if not room.get("field") is String or room.field not in DUNGEON_FIELDS or room.roster.is_empty() or room.cleared: return {}
 var key := JSON.stringify([DUNGEON_RECIPE,c.region.seed,d.active,site.seed,floor.index,floor.seed,room.id,room.seed,room.field])
 return {"field":room.field,"seed":int(key.sha256_text().left(8).hex_to_int() & 0x7fffffff)}

const DUNGEON_FIELDS := ["crypt","crypt_barrow","crypt_gallery","crypt_throne","crypt_mound","crypt_garrison","crypt_royal"]
func burial_enter_reason(site: String) -> String:
 var c = campaign
 if not c.overworld.places.has(site) or not c.overworld.discovered(c.overworld.places[site]): return "Select a known dungeon marker."
 # Physical public eligibility precedes fresh site/room truth.
 if c.location != site or not c.overworld.at_site(site): return "Reach the entrance first."
 if not c.dungeons.sites.has(site): return "Select a supported dungeon marker."
 if c.dungeons.sites[site].floors[0].rooms[0].field not in DUNGEON_FIELDS: return "Unsupported dungeon field."
 if c.overworld.pending != "": return "Resolve the pending scout first."
 return c.dungeon_enter_reason(site)
func _burial_context_reason() -> String:
 var c = campaign
 if c.phase != "camp" or c.dungeons.active == "": return "An active dungeon expedition in CAMP is required."
 var site: String = c.dungeons.active
 if c.location != site or not c.overworld.at_site(site): return "Reach the entrance first."
 if not c.overworld.places.has(site) or not c.overworld.discovered(c.overworld.places[site]) or not c.dungeons.sites.has(site): return "Select a known dungeon marker."
 if c.dungeons.room().field not in DUNGEON_FIELDS: return "Unsupported dungeon field."
 if c.overworld.pending != "": return "Resolve the pending scout first."
 return ""
func burial_action_reason(action: String, target: int = -1) -> String:
 if action not in BURIAL_ACTIONS: return "Unsupported burial action."
 var reason := _burial_context_reason()
 if reason != "": return reason
 var c = campaign
 if action == "leave": return "" if c.encounter.is_empty() or c.encounter.get("kind") == "dungeon" else "Resolve the current encounter first."
 if not c.encounter.is_empty(): return "Fight or leave the occupied chamber."
 if c.over(): return "A living company is required."
 if action == "move": return c.dungeon_move_reason(target)
 if action.begins_with("choice_"): return c.dungeon_choice_reason(action.trim_prefix("choice_"))
 var room: Dictionary = c.dungeons.room()
 match action:
  "search": return "" if room.cleared and not room.looted and not room.loot.is_empty() and c.Dungeons.can_search(room) else "No accessible unlooted cache here."
  "rest": return "" if room.cleared else "Clear the chamber before resting."
  "up": return "" if room.kind == "entry" and c.dungeons.floor_index > 0 else "No upward stairs here."
  "down": return "" if room.kind == "stairs" and room.cleared and c.dungeons.floor_index+1 < c.dungeons.sites[c.dungeons.active].floors.size() else "No downward stairs here."
  "inspect_vault", "unlock_vault":
   var key: String = c.vault_id(target)
   if target not in c.dungeons.links(c.dungeons.room_index) or not c.dungeons.vault_keys.locked(key): return "No locked connecting treasury."
   if action == "unlock_vault":
    if not c.dungeons.vault_keys.records[key].held: return c.dungeons.vault_keys.missing_key_reason(key)
    if c.active_ids().is_empty(): return "Assign companions to the formation before entering the treasury."
    if c.food < c.dungeon_scout_cost(): return "Bring more scouting food to enter the treasury."
   return ""
 return "Unsupported burial action."
func burial_attack_reason() -> String:
 var reason := _burial_context_reason()
 if reason != "": return reason
 var c = campaign; var e: Dictionary = c.encounter
 if c.over() or c.active_ids().is_empty(): return "A living formed company is required."
 if e.get("kind") != "dungeon" or e.get("site") != c.dungeons.active or e.get("floor") != c.dungeons.floor_index or e.get("room") != c.dungeons.room_index: return "No current supported occupied chamber."
 if c.dungeons.room().cleared or not c.can_deploy(): return "The stock chamber no longer admits deployment."
 return ""

func _generate_dungeon_packet(request: Dictionary) -> Dictionary:
 return load("res://dungeon_maps/generator.gd").generate(request.field,request.seed)
func _dungeon_metadata(packet: Dictionary) -> Dictionary:
 return {"recipe":packet.recipe,"field":packet.field,"fingerprint":packet.fingerprint}
func _checkpoint_binding(c) -> Dictionary:
 if c.encounter.get("kind") == "dungeon":
  var request := dungeon_request(c)
  if request.is_empty(): return {}
  var packet := _generate_dungeon_packet(request)
  if not load("res://dungeon_maps/generator.gd").validate(packet,request.field,request.seed): return {}
  return _dungeon_metadata(packet)
 var contact := _contact_packet(c)
 return _camp_selection(c) if contact.is_empty() else _metadata(contact)
func selected_generation() -> Dictionary:
 if campaign.phase != "camp": return _deployed_generation.duplicate(true)
 return _checkpoint_binding(campaign)
func start_burial_battle() -> bool:
 return start_dungeon_battle()
func start_dungeon_battle() -> bool:
 var reason := burial_attack_reason()
 if reason != "": return _fail(reason)
 var candidate = _validated_snapshot(campaign.snapshot())
 if candidate == null: return _fail("Invalid current dungeon campaign; unchanged.")
 var request := dungeon_request(candidate)
 if request.is_empty(): return _fail("No current supported occupied chamber; unchanged.")
 # Whole map admission precedes all stock deployment mutations on the detached copy.
 var packet := _generate_dungeon_packet(request)
 if not load("res://dungeon_maps/generator.gd").validate(packet,request.field,request.seed): return _fail("Generated dungeon packet refused; unchanged.")
 var job: Dictionary = candidate.active.duplicate(true)
 var escrow: Dictionary = candidate.economy.escrow.duplicate(true)
 if not candidate.deploy(): return _fail("Stock dungeon deployment refused; unchanged.")
 if candidate.active != job or candidate.economy.escrow != escrow or not candidate.recon.engagement.is_empty() or not _install_burial_field(candidate,packet): return _fail("Generated dungeon installation refused; unchanged.")
 _deployed_map = packet.descriptor.duplicate(true)
 _deployed_generation = _dungeon_metadata(packet)
 campaign = candidate
 return _success()
func _install_burial_field(candidate, packet: Dictionary) -> bool:
 var request := dungeon_request(candidate)
 if request.is_empty(): return false
 return load("res://dungeon_maps/deployment.gd").install(candidate.battle,packet,request.field,request.seed)
