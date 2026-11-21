extends "res://grassland_visuals/battlefield.gd"
## Accepted terrain/fog/controller path; only the actor presentation is adapted.
const CampaignActor = preload("res://world_loop/character.gd")
func _ready() -> void:
 super._ready()
 if not built: return
 # The frozen inherited _ready hardcodes CompanyActor. Replace its finite rows
 # immediately, before input/process; no old node, tween or signal ownership.
 for unit in battle.units:
  var id := int(unit.id)
  if not actors.has(id): continue
  var old: Node3D = actors[id]
  var pose := old.transform
  var shown := old.visible
  if actor_tweens.has(id): actor_tweens[id].kill(); actor_tweens.erase(id)
  actors.erase(id)
  remove_child(old); old.free()
  var actor = CampaignActor.new()
  add_child(actor)
  actor.configure(unit,battle.armor_catalog)
  actor.transform = pose; actor.visible = shown
  actor.set_selected(id == controller.selected)
  actors[id] = actor
 refresh()
func toggle_inspection() -> void:
 super.toggle_inspection()
 if not inspector_open(): return
 var actor = actors.get(controller.selected)
 if actor == null: return
 var notes := PackedStringArray()
 for issue: Dictionary in actor.equipment_issues():
  notes.append("%s: %s [UID %s; condition %d%s] — %s" % ["Omitted" if issue.kind == "omitted" else "Visual proxy",issue.definition,str(issue.item),issue.condition,"/%d" % issue.maximum if issue.maximum > 0 else " (no durability)",issue.reason])
 if not notes.is_empty(): inspector.art_note.text += "\n"+"\n".join(notes)

func observation() -> Dictionary:
 var result := super.observation()
 # Extend ONLY rows already admitted by the inherited party-sight projection.
 for row: Dictionary in result.units:
  if actors.has(int(row.id)): row["equipment_issues"] = actors[int(row.id)].equipment_issues()
 if inspector_open() and actors.has(controller.selected):
  result.inspector["equipment_issues"] = actors[controller.selected].equipment_issues()
 return result
