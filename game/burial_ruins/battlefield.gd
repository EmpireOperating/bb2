extends "res://world_loop/battlefield.gd"
## Only admitted authored crypts replace terrain. All camera/combat/fog stays inherited.
func _create_terrain() -> Node3D:
 var descriptor: Dictionary = battle.get_meta("authored_map",{}) if battle != null else {}
 if descriptor.get("presentation",{}).get("biome","") == "crypt":
  return load("res://burial_ruins/terrain.gd").new()
 return super._create_terrain()

func _ready() -> void:
 super._ready()
 if not built: return
 # Inherited factory is frozen. Retire only undead actors, retaining players'
 # exact resolver/cache/Texture2D and every inherited signal/controller owner.
 for unit in battle.units:
  if unit.get("faction","") != "undead" and str(unit.get("undead_kind","")).is_empty(): continue
  var id := int(unit.id)
  if not actors.has(id): continue
  var old: Node3D = actors[id]
  var pose := old.transform
  var shown := old.visible
  if actor_tweens.has(id): actor_tweens[id].kill(); actor_tweens.erase(id)
  actors.erase(id); remove_child(old); old.free()
  var actor = load("res://burial_ruins/character.gd").new()
  add_child(actor); actor.configure(unit,battle.armor_catalog)
  actor.transform = pose; actor.visible = shown
  actor.set_selected(id == controller.selected); actors[id] = actor
 refresh()

func _update_hud() -> void:
 super._update_hud()
 var id: int = controller.target
 if not built or id < 0 or not battle.unit_visible(0,id) or not actors.has(id): return
 var actor = actors[id]
 if not actor.has_method("appearance_diagnostics"): return
 var omitted := PackedStringArray()
 for issue: Dictionary in actor.equipment_issues():
  if issue.kind == "omitted" and not str(issue.definition) in omitted: omitted.append(str(issue.definition))
 target_label.text += "\nArt: corpse pallor / reused anatomy, not a painted skull."
 if not omitted.is_empty(): target_label.text += " unpainted: "+", ".join(omitted)+"."

func observation() -> Dictionary:
 var result := super.observation()
 # Only the inherited already-visible rows; no hidden unit enumeration.
 for row: Dictionary in result.units:
  var actor = actors.get(int(row.id))
  row["appearance"] = actor.appearance_diagnostics() if actor != null and actor.has_method("appearance_diagnostics") else {"treatment":"accepted_player_unchanged","painted_skull":false,"gear_recolored":false,"limitations":""}
 if inspector_open() and actors.has(controller.selected) and actors[controller.selected].has_method("appearance_diagnostics"):
  result.inspector["appearance"] = actors[controller.selected].appearance_diagnostics()
 return result
