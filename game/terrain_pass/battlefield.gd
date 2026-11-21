extends "res://company_loop/battlefield.gd"
## Presentation adapter only: same controller, camera, company actor and simulation.
const TerrainRules = preload("res://src/terrain_rules.gd")
func _create_terrain() -> Node3D:
 return load("res://terrain_pass/terrain.gd").new()

func _build_hud() -> void:
 super._build_hud()
 for container in help_panel.get_children():
  for child in container.get_children():
   if child is Label:
    child.text = "TERRAIN FIELD GUIDE\n\nOnly the named active fighter may act.\nClick your active bro, then a blue hex to move.\nClick an enemy, then Attack / Enter. F / Space ends activation.\nEquipment / I is read-only; changes happen in camp.\nWASD / arrows / middle drag pan; wheel / +/- zoom.\nHome close view; O overview; G grid; H / Esc closes help.\n\nOrdinary movement crosses at most one height level.\nUp AND down cost extra AP/fatigue; hover shows real costs.\nForest floor is passable; explicit trees/walls/boulders block.\nLeaving enemy engagement risks a paid opportunity strike.\nMelee height limit: 1; ranged limit: 4, with downhill range.\n\nLOS still uses intermediate hard-blocking hexes and bodies.\nHeight LOS, partial cover and scatter are NOT vanilla-certified.\nNo swamp combat multipliers are adopted.\n\nWithdraw confirms a real loss; wounds and gear damage persist.\nCamp autosaves; quitting a battle resumes your last camp."

func _update_hud() -> void:
 super._update_hud()
 if kit_label: kit_label.text = "%s · TERRAIN RULES · owned company" % session.deployed_map.get("title","")
 if controller.selected >= 0 and controller.target >= 0 and not battle.can_attack(controller.selected,controller.target):
  target_label.text += "\n"+battle.attack_block_reason(controller.selected,controller.target)

func _hex_marker(p: Vector2i, color: Color, fill: bool) -> void:
 var tile: Dictionary = battle.tiles[battle.key(p)]
 if not TerrainRules.tile_reason(tile).is_empty(): color = Color(0.69,0.39,0.28,0.23)
 super._hex_marker(p,color,fill)

func _update_hover() -> void:
 if not battle.tiles.has(battle.key(hover)):
  hover_text = ""
  return
 var tile: Dictionary = battle.tiles[battle.key(hover)]
 hover_text = "%s · elevation %d · hex %d,%d" % [String(tile.terrain).capitalize(),tile.height,hover.x,hover.y]
 var reason := TerrainRules.tile_reason(tile)
 if not reason.is_empty(): hover_text += " · BLOCKED: "+tile.get("obstacle",tile.terrain)
 elif controller.selected >= 0:
  var options: Dictionary = battle.movement_map(controller.selected)
  if options.has(battle.key(hover)):
   var move: Dictionary = options[battle.key(hover)]
   hover_text += " · %d AP / %d fatigue" % [move.cost,move.fatigue]
  else: hover_text += " · "+battle.movement_block_reason(controller.selected,hover)
 if notice_label: notice_label.text = hover_text

func observation() -> Dictionary:
 var out := super.observation()
 out["selected_map_id"] = session.selected_map_id
 out["deployed_map_id"] = session.deployed_map.get("id","")
 out["map_title"] = session.deployed_map.get("title","")
 out["terrain_rules_enabled"] = battle.terrain_rules_enabled
 for observed in out.units:
  var unit: Dictionary = battle.units[observed.id]
  observed["fatigue"] = unit.fatigue
  observed["fatigue_max"] = battle.fatigue_max(unit)
  observed["company_id"] = unit.get("company_id",-1)
  var state: Dictionary = unit.get("perk_state",{})
  observed["activation_origin"] = [state.get("origin_q",-1),state.get("origin_r",-1)]
 out["terrain_profile"] = "researched-ordinary-terrain; intermediate-hard-blocking-LOS-unqualified"
 out["tile_profiles"] = {}
 for key in battle.tiles:
  var tile: Dictionary = battle.tiles[key].duplicate(true)
  tile["obstacle"] = tile.get("obstacle","")
  tile["blocked"] = tile.get("blocked",false)
  tile["vision_blocking"] = tile.get("vision_blocking",false)
  tile["cover"] = tile.get("cover",false)
  var base: Array = TerrainRules.COSTS.get(tile.terrain,[999,999])
  tile["profile"] = {"ap":base[0],"fatigue":base[1],"reason":TerrainRules.tile_reason(tile)}
  out.tile_profiles[key] = tile
 out["movement_options"] = {}
 out["attack_reasons"] = {}
 if controller.selected >= 0:
  var options: Dictionary = battle.movement_map(controller.selected)
  for key in options:
   var move: Dictionary = options[key]
   out.movement_options[key] = {"ap":move.cost,"fatigue":move.fatigue,"path":move.path.map(func(p): return [p.x,p.y])}
  for unit in battle.units:
   if unit.side != battle.units[controller.selected].side and battle.living(unit):
    out.attack_reasons[str(unit.id)] = battle.attack_block_reason(controller.selected,unit.id)
 out["terrain_geometry"] = terrain.geometry_stats.duplicate(true)
 return out
